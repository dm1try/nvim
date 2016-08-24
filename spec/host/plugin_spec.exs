defmodule NVim.Host.PluginSpec do
  use ESpec, nvim_test_session: true
  alias MessagePack.RPC.Session

  it "displays host information" do
    {:ok, _} = Session.call(TestSession, "vim_command", ["ElixirHostInfo"])

    :timer.sleep 50 # suc.. but ElixirHostInfo is async

    {:ok, response} = Session.call(TestSession, "vim_command_output", ["messages"])

    last_message = response |> String.split("\n") |> List.last

    expect(last_message).to have("Host version")
    expect(last_message).to have("Running plugins: [NVim.Host.Plugin]")
  end
end
