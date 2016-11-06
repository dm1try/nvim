ESpec.start

Code.compiler_options(ignore_module_conflict: true)

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    test_session = if tags[:nvim_test_session] do
      {:ok, test_session} = NVim.Session.Embed.start_link(session_name: TestSession)
      test_session
    end

    {:shared, tags: tags, test_session: test_session}
  end

  config.before fn(tags) ->
    integration_session = if tags[:integration] do
      {:ok, integration_session} = NVim.Test.Integration.start_host_session("#{__DIR__}/fixtures")
      integration_session
    end

    {:shared, tags: tags, integration_session: integration_session}
  end

  config.finally fn(shared) ->
    if shared[:tags] && shared.tags[:integration] do
      NVim.Session.Embed.stop(shared.integration_session)
    end
  end

  config.finally fn(shared) ->
    if shared[:tags] && shared.tags[:nvim_test_session] do
      NVim.Session.Embed.stop(shared.test_session)
    end
  end
end
