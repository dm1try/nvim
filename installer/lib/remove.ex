defmodule Mix.Tasks.Nvim.Remove do
  use Mix.Task

  @shortdoc "Removes the host(include ALL installed plugins) for provided nvim config path."

  def run(argv) do
    {_opts, argv} = OptionParser.parse!(argv)

    case argv do
      [] ->
        Mix.raise "Expected NVIM_CONFIG_PATH to be given, please use \"mix nvim.remove NVIM_CONFIG_PATH\""
      [nvim_config_path | _] ->
        File.rm Path.join(nvim_config_path, "plugin/elixir_host.vim")

        File.rm Path.join(nvim_config_path, "rplugin/elixir/mix.exs")
        safely_remove_directory(Path.join(nvim_config_path, "rplugin/elixir/scripts"))

        File.rm_rf Path.join(nvim_config_path, "rplugin/elixir/_build")
        File.rm_rf Path.join(nvim_config_path, "rplugin/elixir/config")
        File.rm_rf Path.join(nvim_config_path, "rplugin/elixir/apps/host")
        safely_remove_directory(Path.join(nvim_config_path, "rplugin/elixir/apps"))

        Mix.shell.info "Elixir host succesfully removed."
    end
  end

  defp safely_remove_directory(path) do
    if directory_empty?(path) do
      File.rm_rf(path)
    else
      Mix.shell.info "#{path} is not removed because is not empty."
    end
  end

  defp directory_empty?(path) do
    Path.join(path, "*") |> Path.wildcard |> Enum.empty?
  end
end
