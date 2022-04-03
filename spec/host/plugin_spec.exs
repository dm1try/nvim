defmodule NVim.Host.PluginSpec do
  use ESpec, integration: true

  it "displays host information" do
    {:ok, _} = IntegrationTest.Session.nvim_command("ElixirHostInfo")

    :timer.sleep 50 # suc.. but ElixirHostInfo is async

    {:ok, response} = IntegrationTest.Session.nvim_command_output("messages")

    last_message = response |> String.split("\n") |> List.last

    expect last_message |> to(have "Host version")
    expect last_message |> to(have "Running plugins: [NVim.Host.Plugin]")
  end
end
