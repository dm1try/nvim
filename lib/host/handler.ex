defmodule NVim.Host.Handler do
  require Logger
  alias NVim.PluginManager

  def on_call(_session, "poll", _params) do
    {:ok, "ok"}
  end

  def on_call(_session, "specs", [plugin_path]) do
    try do
      {:ok, plugin} = PluginManager.lookup(plugin_path)
      {:ok, plugin.specs}
    rescue
      any ->
        Logger.error("Plugin path: #{plugin_path}, error: #{inspect any}")
        {:error, "Troubles with load a plugin. See elixir host log for more information"}
    end
  end

  def on_call(session, method, params) do
    try do
      on_action(session, method, params, sync: true)
    catch
      any ->
        Logger.error("cathc error: #{inspect any}")
    rescue
      error ->
        Logger.error("call error: #{inspect error}")
        {:error, "Error: #{inspect error}"}
    end
  end

  def on_notify(session, method, params) do
    on_action(session, method, params, sync: false)
  end

  defp on_action(_session, method, params, sync: sync) do
    [plugin_path, action_type, action_name | rest] = String.split(method, ":")
    action_name = if rest != [], do: "#{action_name}:#{hd(rest)}", else: action_name

    case PluginManager.lookup(plugin_path) do
      {:ok, plugin} ->
        response = plugin.handle_rpc_method(action_type, action_name, params)
        if sync, do: handle_plugin_response(response)
      _ ->
        Logger.error("Plugin #{plugin_path} was not loaded")
        {:error, "Problem with loading plugin for: #{method}"}
    end
  end

  defp handle_plugin_response({status, _value}= response) when status in [:ok, :error], do: response
  defp handle_plugin_response(_), do: {:error, "Problem with handle action by plugin"}
end
