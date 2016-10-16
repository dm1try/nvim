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

  command elixir_reload_script do
    with {:ok, buffer} <- nvim_get_current_buf(),
         {:ok, filename} <- nvim_buf_get_name(buffer) do
      try do
        Code.load_file(filename)
        nvim_command "echo 'Reloaded.'"
      rescue
        any ->
          nvim_command "echo 'Problem with reloading: #{inspect any}'"
      end
    else
      error ->
        nvim_command "echo 'Problem with reloading: #{inspect error}'"
    end
  end
end
