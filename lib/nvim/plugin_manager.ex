defmodule NVim.PluginManager do
  @moduledoc """
  Manages the plugins
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    plugins = :ets.new(:plugins, [:set, :protected])
    {:ok, plugins}
  end

  def lookup(path) do
    GenServer.call(__MODULE__, {:lookup, path})
  end

  def started_plugins do
    GenServer.call(__MODULE__, :started_plugins)
  end

  def handle_call({:lookup, path}, _from, plugins) do
    try do
      case :ets.lookup(plugins, path) do
        [{^path, module}] ->
          {:reply, {:ok, module}, plugins}
        _ ->
          if File.dir?(path) do
            app_name = path |> Path.split |> List.last |> String.to_atom

            result = Application.ensure_started(app_name)
            Logger.info("Starting plugin application: #{app_name}, result: #{inspect result}")

            module = Application.get_env(app_name, :plugin_module)
            Logger.info("Loading plugin module: #{app_name}, module: #{inspect module}")

            bootstrap_module(module, plugins, path)
            {:reply, {:ok, module}, plugins}
          else
            loaded = Code.load_file(path)
            module = Enum.find_value loaded, fn({mod,_code})->
              function_exported?(mod, :specs, 0) && mod
            end

            if !module, do: raise("Specs not found. Make sure you are using NVim.Plugin in your script")

            Logger.info("Loading script plugin: #{path}, module: #{inspect module}")

            bootstrap_module(module, plugins, path)
            {:reply, {:ok, module}, plugins}
          end
      end
    rescue
      error ->
        {:reply, {:error, "#{inspect error}"}, plugins}
    end
  end

  def handle_call(:started_plugins, _from, plugins) do
    plugins_list = :ets.match(plugins, {:"_", :"$1"}) |> List.flatten

    {:reply, plugins_list, plugins}
  end

  defp bootstrap_module(module, plugins, path) do
    case Supervisor.start_child(NVim.PluginManager.Supervisor,
           Supervisor.Spec.worker(module, [], restart: :transient)) do
      {:ok, _pid} ->
        :ets.insert(plugins, {path, module})
      _ ->
        Logger.warn("problem with bootstraping module: #{inspect module}")
    end
  end
end

defmodule NVim.PluginManager.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    supervise([], strategy: :one_for_one)
  end
end
