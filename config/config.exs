use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :error_log}],
  level: :error

config :logger, :error_log,
  path: Path.expand("#{__DIR__}/../tmp/neovim_elixir_host.log"),
  level: :error
