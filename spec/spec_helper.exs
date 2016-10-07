ESpec.start

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    test_session = if tags[:nvim_test_session] do
      {:ok, test_session} = NVim.Session.Embed.start_link(
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
      NVim.Session.Embed.stop(shared.test_session)
    end
  end
end

NVim.Test.Integration.setup_host("#{__DIR__}/fixtures")
