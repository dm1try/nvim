defmodule NVim.PluginManagerSpec do
  use ESpec, async: false
  alias NVim.PluginManager

  before do
    {:ok, _} = PluginManager.start_link
    {:ok, _} = PluginManager.Supervisor.start_link
  end

  finally do
    :ok = GenServer.stop(PluginManager)
    :ok = GenServer.stop(PluginManager.Supervisor)
  end

  context "compiled plugin" do
    let :fixture_plugin_path, do: "spec/fixtures/plugin_app"

    before do
      Mix.Project.in_project :plugin_app, fixture_plugin_path(), fn(_)->
        Mix.Tasks.Compile.run []
      end
    end

    it "lookups the plugin for provided path" do
      {:ok, module} = PluginManager.lookup(fixture_plugin_path())
      expect(module).to eq(PluginApp)
    end

    context "multiple lookups" do
      before do
        PluginManager.lookup(fixture_plugin_path())
      end

      it "lookups the plugin" do
        expect(PluginManager.lookup(fixture_plugin_path())).to eq({:ok, PluginApp})
      end
    end
  end

  context "script plugin" do
    let :fixture_plugin_path, do: "spec/fixtures/plugin_script.exs"

    it "lookups the plugin for provided path" do
      {:ok, module} = PluginManager.lookup(fixture_plugin_path())
      expect(module).to eq(PluginScript)
    end
  end


  describe ".started_plugins" do
    it "returns empty list if no started plugins" do
      expect(PluginManager.started_plugins).to eq([])
    end

    context "some plugins are already started" do
      let :fixture_plugin_path, do: "spec/fixtures/plugin_script.exs"

      before do
        Code.compiler_options(ignore_module_conflict: true)
        PluginManager.lookup("spec/fixtures/plugin_script.exs")
      end

      it "returns list of started plugins" do
        expect(PluginManager.started_plugins).to eq([PluginScript])
      end
    end
  end
end
