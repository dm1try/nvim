defmodule NVim.Mixfile do
  use Mix.Project

  def project do
    [app: :nvim,
     version: "0.1.1",
     preferred_cli_env: [espec: :test],
     elixir: "~> 1.3.0",
     deps: deps,
     package: package,
     description: "Neovim elixir host"]
  end

  defp package do
     [name: :nvim,
     files: ["lib", "mix.exs", "README*"],
     licenses: ["Apache 2.0"]]
  end

  def application do
    [applications: [:logger, :logger_file_backend, :msgpack_rpc]]
  end

  defp deps do
    [{:logger_file_backend, ">= 0.0.0"},
     {:msgpack_rpc, ">= 0.1.1"},
     {:espec, ">= 0.0.0", only: [:test, :dev]},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
