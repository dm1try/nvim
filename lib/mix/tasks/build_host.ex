defmodule Mix.Tasks.Nvim.BuildHost do
  use Mix.Task

  import Mix.Generator
  @shortdoc "Build host with all complided plugins founded in neovim runtime"

  @nvim_session NVim.Installer
  alias NVim.Test.Session.Embed, as: EmbedNVim

  def run(argv) do
    {opts, _argv} = OptionParser.parse!(argv)

    if File.dir?("../host") do
      session_opts = Keyword.take(opts, [:xdg_home_path, :vim_rc_path])
      EmbedNVim.start_link([session_name: @nvim_session] ++ session_opts)

      create_file "mix.exs", host_mixfile, force: true

      System.cmd "mix", ["deps.get"]
      System.cmd "mix", ["escript.build", "--force"]

      update_neovim_remote_plugins
    else
      Mix.shell.info [:red, "host application is required for this task."]
    end
  end

  defp plugin_apps_in_vim_runtime do
    {:ok, response} = @nvim_session.nvim_eval("globpath(&rtp, 'rplugin/elixir/apps/*')")
    String.split(response, "\n")
  end

  defp update_neovim_remote_plugins do
    {:ok, response} = @nvim_session.nvim_command_output("UpdateRemotePlugins")

    if Regex.match?(~r/elixir host registered plugins/, response) do
      Mix.shell.info [:green, """

      Remote plugins were updated. Restart neovim instances.
      """]
    else
      Mix.shell.info [:red, """

      Problem with updating the remote plugins. See the elixir host log for more information.
      """]
    end
  end

  defp host_mixfile do
    depended_plugins =
      plugin_apps_in_vim_runtime
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
      [{:nvim, "<%= @nvim_version %>"},
      <%= @plugin_deps %>]
    end
  end
  """
end
