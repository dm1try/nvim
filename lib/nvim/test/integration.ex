defmodule NVim.Test.Integration do
  import Mix.Generator, only: [create_file: 3]

  def setup_host(fixtures_path, init_rc_content \\ "") do
    File.mkdir_p! "#{fixtures_path}/xdg_home"
    File.mkdir_p! "#{fixtures_path}/xdg_data"

    nvim_config_path = "#{fixtures_path}/xdg_home/nvim"

    create_file "#{nvim_config_path}/init.vim", init_rc_content, force: true
    System.cmd "mix", ["nvim.install", nvim_config_path], env: install_env(fixtures_path)
  end

  def start_host_session(fixtures_path, session_name \\ IntegrationTest.Session) do
    NVim.Session.Embed.start_link(session_name: session_name,
                                  xdg_home_path: "#{fixtures_path}/xdg_home",
                                  xdg_data_path: "#{fixtures_path}/xdg_data",
                                  vim_rc_path: "#{fixtures_path}/xdg_home/nvim/init.vim",
                                  nvim_rplugin_manifest: "#{fixtures_path}/xdg_data/rplugin.vim")
  end

  def remove_host(fixtures_path) do
    nvim_config_path = "#{fixtures_path}/xdg_home/nvim"
    System.cmd "mix", ["nvim.remove", nvim_config_path]
  end

  defp install_env(fixtures_path) do
    [{"XDG_DATA_PATH", "#{fixtures_path}/xdg_data"},
     {"NVIM_RPLUGIN_MANIFEST", "#{fixtures_path}/xdg_data/rplugin.vim"}]
  end
end
