defmodule Mix.Tasks.Nvim.BuildHost do
  use Mix.Task

  import Mix.Generator
  @shortdoc "Build host with all complided plugins founded in neovim runtime"

  @nvim_session NVim.Installer
  # TODO: try to disable Xref compiler warnings for this "dynamic" module

  alias NVim.Session.Embed, as: EmbedNVim
  alias MessagePack.RPC

  @host_path "apps/host"

  def run(argv) do
    {opts, _argv} = OptionParser.parse!(argv)

    File.mkdir_p! @host_path

    session_opts =
      opts
      |> Keyword.take([:xdg_home_path, :xdg_data_path, :vim_rc_path, :nvim_rplugin_manifest])
      |> Keyword.put_new(:vim_rc_path, Path.expand("../../init.vim"))

    EmbedNVim.start_link([session_name: @nvim_session] ++ session_opts)

    create_file Path.join([@host_path, "mix.exs"]), host_mixfile(), force: true
    create_file Path.join([@host_path, "config", "config.exs"]), host_config_text(), force: true
  end

  defp plugin_apps_in_vim_runtime do
    case RPC.Session.call(@nvim_session, "nvim_eval", ["globpath(&rtp, 'rplugin/elixir/apps/*')"]) do
      {:ok, ""} -> []
      {:ok, response} -> String.split(response, "\n")
      _ -> []
    end
  end

  defp host_mixfile do
    depended_plugins =
      plugin_apps_in_vim_runtime()
      |> Enum.filter(fn(app)-> Path.basename(app) != "host" end)
      |> Enum.uniq

    plugin_deps =
      depended_plugins
      |> Enum.map(fn(plugin_path)->
          plugin_name = Path.basename(plugin_path)
          ~s({:#{plugin_name}, path: "#{plugin_path}", in_umbrella: true}) end)
      |> Enum.join(",")

    Application.load(:nvim)
    host_mixfile_template(plugin_deps: plugin_deps, nvim_version: Application.spec(:nvim)[:vsn])
  end

  embed_template :host_mixfile, """
  defmodule Host.Mixfile do
    use Mix.Project

    def project do
      [app: :host,
       version: "<%= @nvim_version %>",
       build_path: "../../_build",
       config_path: "../../config/config.exs",
       deps_path: "../../deps",
       lockfile: "../../mix.lock",
       elixir: "~> 1.3",
       deps: deps,
       escript: escript]
    end

    def application do
      [applications: [:logger, :nvim], env: [plugin_module: NVim.Host.Plugin], mod: {NVim.Host, []}]
    end

    defp deps do
      [{:nvim, "~> <%= @nvim_version %>"},
      <%= @plugin_deps %>]
    end
  end
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
end
