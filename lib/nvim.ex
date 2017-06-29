defmodule NVim do
  defmodule Host do
    use Application

    alias MessagePack.{RPC, Transports}
    alias NVim.PluginManager

    import Supervisor.Spec
    require Logger

    @port NVim.Port
    @session NVim.Session

    with {packed_api, _} <- System.cmd("nvim", ["--api-info"]),
         {:ok, %{"functions" => function_specs} = _api_info} <- Msgpax.unpack(packed_api) do

      NVim.API.injects_methods(function_specs, @session)
    end

    def start(_, _) do
      children = [
        worker(Transports.Port, [[link: {:fd, 0, 1}, session: @session],[name: @port]]),
        worker(RPC.Session, [[method_handler: NVim.Host.Handler, transport: @port],[name: @session]]),
        worker(PluginManager,[[name: PluginManager]]),
        supervisor(PluginManager.Supervisor,[])
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
    end
  end
end
