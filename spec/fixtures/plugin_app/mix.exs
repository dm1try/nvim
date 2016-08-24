defmodule PluginApp.Mixfile do
  use Mix.Project

  def project do
    [app: :plugin_app,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger], env: [plugin_module: PluginApp]]
  end

  defp deps do
    []
  end
end
