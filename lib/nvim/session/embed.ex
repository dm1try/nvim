defmodule NVim.Session.Embed do
  use Supervisor

  @params_to_env [xdg_home_path: 'XDG_CONFIG_HOME',
                  xdg_data_path: 'XDG_DATA_PATH',
                  vim_rc_path: 'MYVIMRC']

  defmodule NullHandler do
    require Logger

    def on_call(_, method, _) do
      Logger.warn("unexpected call to embed session: #{inspect method}")
    end

    def on_notify(_, method, _) do
      Logger.warn("unexpected notify to embed session: #{inspect method}")
    end
  end

  def start_link(args \\ []) do
    response = Supervisor.start_link(__MODULE__, args)
    # totally ugly :)
    session_name = Keyword.get(args, :session_name, NVim.Session)
    inject_methods(session_name)

    response
  end

  def init(args) do
    session_name = Keyword.get(args, :session_name, NVim.Session)
    port_name = Module.concat(session_name, Port)

    vim_rc_path = Keyword.get(args, :vim_rc_path)
    env_params = Keyword.take(args, Keyword.keys(@params_to_env))

    file = Keyword.get(args, :file)

    children = [
      worker(MessagePack.Transports.Port, [
        [link: {:spawn, "nvim --embed #{vim_rc_opt(vim_rc_path)} #{file}"},
         session: session_name,
         settings: port_settings(env_params)],
        [name: port_name],
      ]),
      worker(MessagePack.RPC.Session, [
        [method_handler: NullHandler, transport: port_name],
        [name: session_name]
      ])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def inject_methods(session) do
    {:ok, [_, response] }= MessagePack.RPC.Session.call(session, "nvim_get_api_info",[])

    function_specs = Map.fetch!(response,"functions")
    NVim.API.injects_methods(function_specs, session)
  end

  def stop(pid) do
    Supervisor.stop(pid)
  end

  defp vim_rc_opt(nil = _vim_rc_path), do: "-u NONE"
  defp vim_rc_opt(vim_rc_path), do: "-u #{vim_rc_path}"

  defp port_settings(env_params) do
    params = Enum.map env_params, fn({key, value})->
      {@params_to_env[key], String.to_charlist(value)}
    end

    [env: params]
  end
end
