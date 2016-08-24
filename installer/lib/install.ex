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
        create_file Path.join(nvim_config_path, "plugin/elixir_host.vim"), elixir_host_plugin_vim_text, force: true

        remote_plugin_path = Path.join(nvim_config_path, "rplugin/elixir")

        create_directory Path.join(remote_plugin_path, "scripts")
        create_directory Path.join(remote_plugin_path, "apps")
        create_file Path.join(remote_plugin_path, "mix.exs"), apps_mixfile_text, force: true
        create_file Path.join([remote_plugin_path, "config", "config.exs"]), apps_config_text, force: true

        host_path =  Path.join([remote_plugin_path, "apps","host"])

        create_file Path.join(host_path, "mix.exs"), host_mixfile_text, force: true
        create_file Path.join([host_path, "config", "config.exs"]), host_config_text, force: true

        print_successful_info
    end
  end

  defp print_successful_info do
    Mix.shell.info [:green, """

    Elixir host succesfully installed.
    """]
  end

  embed_text :host_mixfile, ~s"""
  defmodule Host.Mixfile do
    use Mix.Project

    def project do
      [app: :host,
       version: "#{Mix.Project.config[:version]}",
       build_path: "../../_build",
       config_path: "../../config/config.exs",
       deps_path: "../../deps",
       lockfile: "../../mix.lock",
       elixir: "~> 1.3",
       deps: deps,
       aliases: aliases,
       escript: escript]
    end

    def application do
      [applications: [:logger, :nvim], env: [plugin_module: NVim.Host.Plugin]]
    end

    def escript do
      [main_module: NVim.Host, emu_args: "-noinput"]
    end

    defp deps do
      [{:nvim, "#{Mix.Project.config[:version]}"}]
    end

    defp aliases do
      ["nvim.build_host": ["deps.get", "nvim.build_host"]]
    end
  end
  """
  embed_text :apps_mixfile, """
  defmodule Elixir.Mixfile do
    use Mix.Project

    def project do
      [apps_path: "apps",
       deps: []]
    end
  end
  """

  embed_text :apps_config, """
  use Mix.Config
  import_config "../apps/*/config/config.exs"
  """

  embed_text :host_config, ~S"""
  use Mix.Config

  config :logger,
    backends: [{LoggerFileBackend, :error_log}],
    level: :error

  config :logger, :error_log,
    path: Path.expand("#{__DIR__}/../neovim_elixir_host.log"),
    level: :error
  """

  embed_text :elixir_host_plugin_vim, """
  let s:nvim_path = expand('<sfile>:p:h:h')
  let s:xdg_home_path = expand('<sfile>:p:h:h:h')

  function! s:RequireElixirHost(host)
    try
      let channel_id = rpcstart(s:nvim_path . '/rplugin/elixir/apps/host/host',[])
      if rpcrequest(channel_id, 'poll') == 'ok'
        return channel_id
      endif
    catch
    endtry
    throw 'Failed to load elixir host.' . expand('<sfile>') .
      \ ' More information can be found in elixir host log file.'
  endfunction

  call remote#host#Register('elixir', '{scripts/*.exs,apps/*}', function('s:RequireElixirHost'))

  function! UpdateElixirPlugins()
    execute '!cd ' . s:nvim_path . '/rplugin/elixir/apps/host && MIX_ENV=prod mix do deps.get, nvim.build_host --xdg-home-path ' . s:xdg_home_path . ' --vim-rc-path ' . s:nvim_path . '/init.vim'
  endfunction
  command! UpdateElixirPlugins call UpdateElixirPlugins()
  """
end
