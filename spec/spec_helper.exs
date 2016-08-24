ESpec.start

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    test_session = if tags[:nvim_test_session] do
      {:ok, test_session} = NVim.Test.Session.Embed.start_link(
        session_name: TestSession,
        xdg_home_path: "#{__DIR__}/fixtures/xdg_home",
        vim_rc_path: "#{__DIR__}/fixtures/xdg_home/nvim/init.vim"
      )

      test_session
    end

    {:shared, tags: tags, test_session: test_session}
  end

  config.finally fn(shared) ->
    if shared[:tags] && shared.tags[:nvim_test_session] do
      NVim.Test.Session.Embed.stop(shared.test_session)
    end
  end
end

System.cmd("mix", ["nvim.install", "#{__DIR__}/fixtures/xdg_home/nvim"])

File.cd! "#{__DIR__}/fixtures/xdg_home/nvim/rplugin/elixir/apps/host", fn->
   Mix.shell.info [:yellow, "\tBuilding host application..."]

  System.cmd("mix", ["nvim.build_host",
     "--xdg-home-path", "#{__DIR__}/fixtures/xdg_home",
    "--vim-rc-path", "#{__DIR__}/fixtures/xdg_home/nvim/init.vim"])
    end

