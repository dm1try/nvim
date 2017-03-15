defmodule NVim.Installer.Mixfile do
  use Mix.Project

  def project do
    [app: :nvim_installer,
     version: "0.4.2",
     elixir: "~> 1.3"]
  end

  def application do
    [applications: []]
  end
end
