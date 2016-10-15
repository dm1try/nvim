defmodule NVim.Plugin do
  @moduledoc """
  GenServer that abstracts common plugin interaction.
  """
  defmacro __using__(_opts) do
    quote do
      use GenServer
      alias MessagePack.RPC.Session

      Module.register_attribute __MODULE__, :nvim_specs, accumulate: false, persist: true
      @nvim_specs []
      require unquote(__MODULE__).DSL
      import unquote(__MODULE__).DSL
      @before_compile unquote(__MODULE__)

      def start_link(args \\ []) do
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
      end

      def handle_rpc_method(type, method, params) do
        GenServer.call(__MODULE__, {:handle_rpc_method, type, method, params})
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def specs, do: @nvim_specs
    end
  end

  defmodule DSL do
    defmacro on_event(event_name, opts \\ [], do: expression) do
      camelized_name = event_name |> Atom.to_string |> Macro.camelize
      pattern = Keyword.get(opts, :pattern, "*")
      sync = Keyword.get(opts, :sync, false)
      spec_opts = %{pattern: pattern} |> add_eval_opts(opts[:pre_evaluate])
      spec =
        %{"type": "autocmd", "name": camelized_name, sync: sync, "opts": spec_opts}
        |> Macro.escape

      handler_params = [
        injected_eval_param(opts[:pre_evaluate])
      ] |> Enum.filter(fn(v)-> v != nil end)

      quote do
        updated_specs = @nvim_specs ++ [unquote(spec)]
        Module.put_attribute __MODULE__, :nvim_specs, updated_specs
        def handle_call({:handle_rpc_method, "autocmd", unquote(camelized_name)<>":"<>pattern, unquote(handler_params)}, _from, var!(state)) do
          result = unquote(expression)
          {:reply, {:ok, result}, var!(state)}
        end
      end
    end

    defmacro function({func_name, _, function_params}, opts \\ [], do: expression) do
      camelized_name = func_name |> Atom.to_string |> Macro.camelize
      sync = Keyword.get(opts, :sync, true)
      spec_opts = %{} |> add_eval_opts(opts[:pre_evaluate])
      spec =
        %{"type": "function", "name": camelized_name, sync: sync, "opts": spec_opts}
        |> Macro.escape

      handler_params = [
        injected_function_params_param(function_params),
        injected_eval_param(opts[:pre_evaluate])
      ] |> Enum.filter(fn(v)-> v != nil end)

      quote do
        updated_specs = @nvim_specs ++ [unquote(spec)]
        Module.put_attribute __MODULE__, :nvim_specs, updated_specs
        def handle_call({:handle_rpc_method, "function", unquote(camelized_name), unquote(handler_params)}, _from, var!(state)) do
          result = unquote(expression)
          {:reply, {:ok, result}, var!(state)}
        end
      end
    end

    defmacro command({command_name, _, command_params}, opts \\ [], do: expression) do
      camelized_name = command_name |> Atom.to_string |> Macro.camelize
      sync = Keyword.get(opts, :sync, false)

      spec_opts =
        %{}
        |> add_command_params_opt(command_params)
        |> add_range_opt(opts[:range])
        |> add_complete_opt(opts[:complete])
        |> add_eval_opts(opts[:pre_evaluate])

      spec =
        %{"type": "command", "name": camelized_name, sync: sync, "opts": spec_opts}
        |> Macro.escape

      handler_params = [
        injected_range_param(opts[:range]),
        injected_command_params_param(command_params),
        injected_eval_param(opts[:pre_evaluate])
      ] |> Enum.filter(fn(v)-> v != nil end)

      quote do
        updated_specs = @nvim_specs ++ [unquote(spec)]
        Module.put_attribute __MODULE__, :nvim_specs, updated_specs
        def handle_call({:handle_rpc_method, "command", unquote(camelized_name), unquote(handler_params)}, _from, var!(state)) do
          result = unquote(expression)
          {:reply, {:ok, result}, var!(state)}
        end
      end
    end

    defp add_command_params_opt(opts, nil = _command_params), do: opts
    defp add_command_params_opt(opts, _command_params), do: Map.put(opts, :nargs, "*")

    defp add_eval_opts(opts, nil), do: opts
    defp add_eval_opts(opts, {_, _, params} = _pre_evaluate_ast) do
      evals = Enum.map_join(params, ",", fn({k, _v}) -> k end)
      Map.put(opts, :eval, "[#{evals}]")
    end

    defp add_range_opt(opts, nil = _range), do: opts
    defp add_range_opt(opts, _range), do: Map.put(opts, :range, "%")

    defp add_complete_opt(opts, nil), do: opts
    defp add_complete_opt(opts, complete), do: Map.put(opts, :complete, to_string(complete))

    defp injected_function_params_param(nil), do: nil
    defp injected_function_params_param(function_params) do
      function_params
      |> Enum.map(fn({k, _, _}) -> Macro.var(k, nil) end)
      |> Enum.to_list
    end

    defp injected_range_param(nil), do: nil
    defp injected_range_param(_range) do
      [Macro.var(:range_start, nil), Macro.var(:range_end, nil)]
    end

    defp injected_command_params_param(nil), do: nil
    defp injected_command_params_param(command_params) do
      [{name, _, _}] = command_params
      Macro.var(name, nil)
    end

    defp injected_eval_param(nil), do: nil
    defp injected_eval_param({_, _, eval_params} = _pre_evaluate_ast) do
      eval_params
      |> Enum.map(fn({_k, v}) -> v end)
      |> Enum.to_list
    end
  end
end
