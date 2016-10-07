defmodule NVim.Host.Plugin do
  use NVim.Plugin

  import NVim.Session

  command elixir_host_info do
    message = """
    Host version: #{Application.spec(:nvim)[:vsn]}
    Running plugins: #{inspect NVim.PluginManager.started_plugins}
    """

    nvim_command "echomsg '#{message}'"
  end

  command elixir_host_log do
    log_path = Application.get_env(:logger, :error_log)[:path]
    nvim_command "bot new | res 15 | set wfh | term tail -f #{log_path}"
  end
end
