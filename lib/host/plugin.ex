defmodule NVim.Host.Plugin do
  use NVim.Plugin

  command elixir_host_info do
    message = """
    Host version: #{Application.spec(:nvim)[:vsn]}
    Running plugins: #{inspect NVim.PluginManager.started_plugins}
    """

    NVim.Session.vim_command "echomsg '#{message}'"
  end
end
