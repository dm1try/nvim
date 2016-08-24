defmodule Mix.Tasks.Nvim.InstallTest do
  use ExUnit.Case

  test "installs the host to a provided directory" do
    in_tmp_dir("nvim_config", fn(path)->
      output = ExUnit.CaptureIO.capture_io(fn-> Mix.Tasks.Nvim.Install.run [path] end)

        assert_file_exists "#{path}/plugin/elixir_host.vim"
        assert_directory_exists "#{path}/rplugin/elixir/scripts"
        assert_directory_exists "#{path}/rplugin/elixir/apps/host"
        assert_file_exists "#{path}/rplugin/elixir/config/config.exs"
        assert_file_exists "#{path}/rplugin/elixir/mix.exs"

      assert output =~ "Elixir host succesfully installed."
    end)
  end

  defp in_tmp_dir(path, callback) do
    expanded_path = Path.expand("../../tmp/#{path}", __DIR__)
    File.rm_rf! expanded_path
    File.mkdir! expanded_path

    callback.(expanded_path)
  end

  defp assert_file_exists(path) do
    assert File.exists?(path)
  end

  defp assert_directory_exists(path) do
    assert File.dir?(path)
  end
end
