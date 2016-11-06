defmodule NVim.Mixfile do
  use Mix.Project

  def project do
    [app: :nvim,
     version: "0.3.1",
     preferred_cli_env: [espec: :test],
     elixir: "~> 1.3.0",
     deps: deps,
     package: package,
     description: "Neovim elixir host",
     aliases: aliases]
  end

  defp package do
     [name: :nvim,
     files: ["lib", "installer", "mix.exs", "README*"],
     licenses: ["Apache 2.0"],
     maintainers: ["Dmitry Dedov"],
     links: %{"GitHub" => "https://github.com/dm1try/nvim"}]
  end

  defp aliases do
    [espec: "espec --exclude integration"]
  end

  def application do
    [applications: [:logger, :logger_file_backend, :msgpack_rpc]]
  end

  defp deps do
    [{:logger_file_backend, "~> 0.0.9"},
     {:msgpack_rpc, ">= 0.1.1"},
     {:espec, "~> 1.1.0", only: [:test, :dev]},
     {:ex_doc, "~> 0.14.1", only: :dev}]
  end
end
