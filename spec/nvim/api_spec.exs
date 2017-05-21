defmodule NVim.ApiSpec do
  use ESpec
  alias MessagePack.RPC
  alias NVim.Session

  @session_name ApiSession

  {:ok, session} = Session.Embed.start_link(session_name: @session_name)
  {:ok, [_channel, %{"functions" => function_specs}] = _api_info} =
    RPC.Session.call(@session_name, "nvim_get_api_info", [])
    NVim.API.injects_methods(function_specs, @session_name)
    Session.Embed.stop(session)

  before do
    {:ok, embed_session} = Session.Embed.start_link(session_name: @session_name)
    {:shared, embed_session: embed_session}
  end

  finally do
    Session.Embed.stop(shared.embed_session)
  end

  it "injects and proxies vim API" do
    expect(@session_name.nvim_get_api_info()).to eq(
      RPC.Session.call(@session_name, "nvim_get_api_info", [])
    )
  end

  it "injects with params" do
    expect(@session_name.nvim_command_output("echo 123")).to eq({:ok, "\n123"})
  end

  it "works with types" do
    import @session_name

    {:ok, buffer} = nvim_get_current_buf()
    expect(buffer_set_line(buffer, 0, "test")).to eq({:ok, nil})
    expect(nvim_get_current_line()).to eq({:ok, "test"})
  end
end
