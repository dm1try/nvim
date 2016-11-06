# Neovim Elixir host [![Build Status](https://travis-ci.org/dm1try/nvim.svg?branch=master)](https://travis-ci.org/dm1try/nvim)

Implements support for Neovim remote plugins written in Elixir.
## Requirements
  - Neovim >= 1.6-dev
  - Elixir >= 1.3

## Installation

Install the host archive, we will use it to build the host locally.

```
$ mix archive.install https://github.com/dm1try/nvim/releases/download/v0.4.0/nvim.ez
```

Build and install the host by running `nvim.install` and providing the path to nvim config(`~/.config/nvim` by default on linux systems)

```
$ mix nvim.install /path/to/nvim/config
```

## Usage

Currently, each time you somehow update remote plugins you should run `:UpdateElixirPlugins` nvim command.

See `:h remote-plugin-manifest` for the clarification why the manifest is needed(generally, it saves the neovim startup time if remote plugins are installed).

# Plugin Development (Developers only)

```elixir
                   +--------------------------+
+--------+ MsgPack |              +---------+ |
|        |   RPC   | +------+     |         | |
| Neovim <---------> | Host <-----> Plugins | |
|        |         | +------+     |         | |
+--------+         |              +---------+ |
                   +--------------------------+
```
## Structure

Host supports two types of plugins:
  1. Scripts (an elixir script that usually contains simple logic and does not depend on other libs/does not need the versioning/etc).

  2. Applications (an OTP application that is implemented as part of host umbrella project). You can find more information about umbrella projects [here](http://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-apps.html).

Host with plugins lives in `rplugin/elixir` neovim config directory.
Script plugin name must have postfix `plugin` in his name.
> Example `my_plugin.exs`

Typical files tree for such dir:
```bash
~/.config/nvim/rplugin/elixir

├── scripts <~ scripts
├── apps <~ applications AKA "precompiled plugins"
└── mix.exs
```

### Plugin DSL
#### Events
`on_event`(better known as `autocmd` for vim users) defines the callback that triggered by editor when some event
happened. Run `:h autocmd-events` for the list of events.

```elixir
on_event :vim_enter do
  Logger.info("the editor is ready")
end
```
#### Functions
`function` defines the vim function
```elixir
function wrong_sum(left, right) do
  left - right
end
```
use it in the editor `:echo WrongSum(1,2)`

#### Commands
`command` defines the command.

```elixir
command just_echo do
  NVim.Session.vim_command("echo from remote plugin")
end
```
use it in the editor `:JustEcho`

Only single param can be defined for a command.
This param holds an array of strings provided on the command call.
Elixir `OptionParser` is good choice here.

### Session
In the latest example we used `vim_command` method which is part of Neovim remote API.
In the examples below we asume that we import `NVim.Session` in context of plugin.

### State
Each plugin is [GenServer](http://elixir-lang.org/docs/stable/elixir/GenServer.html).
So you can share the state between all actions while the plugin is running:
```elixir
on_event :cursor_moved do
  state = %{state | {move_counts: state[:move_counts] + 1}
end

command :show_moves_count do
  moves_info = "Current moves: #{state[:move_count]}"
  vim_command("echo '#{moves_info}'")
end
```
### Pre-evaluated values
Any vim value can be pre-evaluated before the action will be triggered:
```elixir
on_event :cursor_hold_i,
  pre_evaluate: %{
    "expand('cWORD')" => word_under_cursor
  }
do
  if word_under_cursor == "Elixir" do
    something()
  end
end
```
## Basic scripts
"Hello" from plug:
```elixir
# ~/.config/nvim/rplugin/elixir/scripts/my_plugin.exs
defmodule MyPlug do
  use NVim.Plugin

  command hello_from_plug do
    NVim.Session.vim_command "echo 'hello'"
  end
end
```
## Debugging scripts.
`ElixirHostLog` opens the host log.
 Log severety level can be changed in the host config.
 > `~/.config/nvim/rplugin/elixir/apps/host/config/config.exs` is default path on linux

 `ElixirReloadScript` reloads running script.
 > This works only for the reloading an implementation of already defined command/function/event.
 > This means if you add/remove some definition or change its option(`pre_evaluate` for example) you should restart the editor.

