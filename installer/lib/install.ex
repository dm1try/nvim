defmodule Mix.Tasks.Nvim.Install do
  use Mix.Task

  import Mix.Generator
  @shortdoc "Installs the host to provided nvim config path."

  def run(argv) do
    {_opts, argv} = OptionParser.parse!(argv)

    case argv do
      [] ->
        Mix.raise "Expected NVIM_CONFIG_PATH to be given, please use \"mix nvim.install NVIM_CONFIG_PATH\""
      [nvim_config_path | _] ->
        create_file Path.join(nvim_config_path, "plugin/elixir_host.vim"), elixir_host_plugin_vim_text(), force: true

        remote_plugin_path = Path.join(nvim_config_path, "rplugin/elixir")

        create_directory Path.join(remote_plugin_path, "scripts")
        create_directory Path.join(remote_plugin_path, "apps")
        create_file Path.join(remote_plugin_path, "mix.exs"), apps_mixfile_text(), force: true
        create_file Path.join([remote_plugin_path, "config", "config.exs"]), apps_config_text(), force: true

        case System.cmd("mix", ["do", "deps.get,", "nvim.build_host"], cd: remote_plugin_path) do
          {_result, 0} -> print_successful_info()
          {result, _} -> print_error("#{inspect result}")
          _ -> print_error("Something was going wrong.")
        end
    end
  end

  defp print_successful_info do
    Mix.shell.info [:green, """

    Elixir host succesfully installed.
    """]
  end

  defp print_error(details) do
    Mix.shell.info [:green, """

    The host was NOT installed: #{details}
    """]
  end

  embed_text :apps_mixfile, """
  defmodule Elixir.Mixfile do
    use Mix.Project

    def project do
      [apps_path: "apps",
       deps: [{:nvim, "#{Mix.Project.config[:version]}"}]]
    end
  end
  """

  embed_text :apps_config, """
  use Mix.Config
  config :logger, level: :error
  import_config "../apps/*/config/config.exs"
  """

  embed_text :elixir_host_plugin_vim, """
  let s:elixir_host_app_path = expand('<sfile>:p:h:h') . '/rplugin/elixir/apps/host'

  function! ElixirRequire(host)
    " orig_name != name when :UpdateRemotePlugins is called
    if a:host['orig_name'] != a:host['name']
      call system('cd ' . s:elixir_host_app_path . ' && mix do nvim.build_host, compile --force')
    endif

    return jobstart(['elixir', '--erl', '-noinput','-S', 'mix', 'run', '--no-halt', '--no-compile', '--no-deps-check', '--no-archives-check'], {'cwd': s:elixir_host_app_path, 'rpc': v:true})
endfunction


  call remote#host#Register('elixir', '{scripts/*_plugin.exs,apps/*}', function('ElixirRequire'))
  """
end
