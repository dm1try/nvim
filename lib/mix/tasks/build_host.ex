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

    case System.cmd "mix", ["do", "deps.get,","escript.build", "--force"], cd: @host_path do
      {_, 0} -> update_neovim_remote_plugins()
      _ -> :ignore
    end
  end

  defp plugin_apps_in_vim_runtime do
    case RPC.Session.call(@nvim_session, "nvim_eval", ["globpath(&rtp, 'rplugin/elixir/apps/*')"]) do
      {:ok, ""} -> []
      {:ok, response} -> String.split(response, "\n")
      _ -> []
    end
  end

  defp update_neovim_remote_plugins do
    {:ok, response} = RPC.Session.call(@nvim_session, "nvim_command_output", ["UpdateRemotePlugins"])

    if Regex.match?(~r/elixir host registered/, response) do
      Mix.shell.info [:green, """

      Remote plugins were updated. Restart neovim instances.
      """]
    else
      Mix.shell.info [:red, """

      Problem with updating the remote plugins. See the elixir host log for more information.
      #{inspect response}
      """]
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
      [applications: [:logger, :nvim], env: [plugin_module: NVim.Host.Plugin]]
    end

    def escript do
      [main_module: NVim.Host, emu_args: "-noinput"]
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
