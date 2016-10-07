defmodule NVim.Test.Session.Embed do
  use Supervisor

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
    xdg_home_path = Keyword.get(args, :xdg_home_path)
    vim_rc_path = Keyword.get(args, :vim_rc_path)

    file = Keyword.get(args, :file)

    children = [
      worker(MessagePack.Transports.Port, [
        [link: {:spawn, "nvim --embed #{vim_rc_opt(vim_rc_path)} #{file}"},
         session: session_name,
         settings: port_settings(xdg_home_path, vim_rc_path)],
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

  defp port_settings(xdg_home_path, vim_rc_path)
    when is_nil(xdg_home_path) and is_nil(vim_rc_path), do: []
  defp port_settings(xdg_home_path, vim_rc_path) do
    [ env:
      [
        { 'XDG_CONFIG_HOME', String.to_charlist(xdg_home_path) },
        { 'MYVIMRC', String.to_charlist(vim_rc_path) }
      ]
    ]
  end
end
