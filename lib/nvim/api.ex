defmodule NVim.API do
  def injects_methods(func_specs, module_name) do
    defmodule module_name do
      funcs = Enum.map func_specs, fn (%{"name" => name, "parameters" => params} = _spec)->
        params = Enum.map params, fn([_type, name])->
          name = if name == "fn" do "_fn" else name end
          name |> String.to_atom |> Macro.var(nil)
        end

        quote do
          def unquote(:"#{name}")(unquote_splicing(params)) do
            MessagePack.RPC.Session.call(unquote(module_name), unquote(name), [unquote_splicing(params)])
          end
        end
      end

      Module.eval_quoted(__MODULE__, funcs)
    end
  end

  def inject(session) do
    {:ok, [_, response] }= MessagePack.RPC.Session.call(session, "nvim_get_api_info",[])

    api_types = Map.fetch!(response,"types")
    inject_nvim_types(api_types)
  end

  defp inject_nvim_types(type_specs) do
    defmodule Elixir.NVim.Types do

    Module.register_attribute __MODULE__, :types, accumulate: true

    mods = Enum.map type_specs, fn ({type, %{"id" => type_id}})->
      @types module_name = Module.concat(NVim, type)

      quote do
        defmodule unquote(module_name) do
          defstruct [:instance_id]

          def pack(%unquote(module_name){instance_id: instance_id}) do
            Msgpax.Ext.new(unquote(type_id), instance_id)
          end
        end

        def unpack(unquote(type_id), instance_id) when is_bitstring(instance_id) do
          {:ok, %unquote(module_name){instance_id: instance_id}}
        end
      end
    end

    packer_interface = quote do
      defimpl Msgpax.Packer, for: unquote(@types) do
        def transform(instance) do
          @for.pack(instance)
          |> @protocol.Msgpax.Ext.transform()
        end
      end
    end
    Module.eval_quoted(__MODULE__, mods ++ [packer_interface])
    end

    NVim.Types
  end
end
