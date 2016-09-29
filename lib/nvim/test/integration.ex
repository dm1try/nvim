defmodule NVim.Test.Integration do
  def setup_host(fixtures_path) do
    nvim_config_path = "#{fixtures_path}/xdg_home/nvim"
    Mix.Tasks.Nvim.Install.run [nvim_config_path]

    File.cd! "#{nvim_config_path}/rplugin/elixir/apps/host", fn->
      Mix.Tasks.Nvim.BuildHost.run [
        "nvim.build_host",
        "--xdg-home-path", "#{fixtures_path}/xdg_home",
        "--vim-rc-path", "#{nvim_config_path}/init.vim"
      ]
    end
  end
end
