slowly.nvim 🐌
==============
Slowly is a Neovim plugin manager for people who value simplicity over speed.
It is neither *blazingly fast* nor the most advanced solution, but rather the
bare minimum of what I need. Slowly handles installing, updating, and
reinstalling plugins using `git`. It does not do anything fancy. I used
[packer.nvim](https://github.com/wbthomason/packer.nvim) for awhile,
and if you want the kitchen sink included, you should use Packer instead.

Here's a friendly comparison of Slowly to other plugin managers:

|                  Advantages              |       Disadvantages       |
| ---------------------------------------- | ------------------------- |
| Can actually understand whats happening  | Goes slowly, few features |

Requirements
------------
* A Unix-like environment
* Neovim v0.8.0  or newer (or older?)
* `git`      v2.38.0 or newer (or older?)
* `GNU tar`  v1.34   or newer (or older? or BSD?)
* `GNU gzip` v1.12   or newer (or older? or BSD?)

Installing
----------
Copy the `./lua/slowly.lua` file from this repository to
`~/.config/nvim/lua/slowly.lua`. Then write an
`~/.config/nvim/init.lua` like this:

```lua
local example_condition = false

require('slowly').setup({ 
  disabled_builtins = {
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers"
  },
  start_urls = {
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/elihunter173/dirbuf.nvim'
  },
  opt_urls = {
    'https://github.com/nat-418/bufala.nvim',
    'https://github.com/nat-418/tabbot.nvim',
  }
})

require('dirbuf').setup {
  show_hidden = false,
  sort_order  = 'directories_first',
  write_cmd   = "DirbufSync -confirm",
}

if example_condition then
  vim.cmd.packadd('bufala.nvim'); require('bufala').setup()
  vim.cmd.packadd('tabbot.nvim'); require('tabbot').setup()
end
```

In this example we want to replace the old vim default plugin `netrw` with
the excellent `dirbuf.nvim`, and we want `dirbuf` to be loaded automatically on
startup along with `plenary`—a common dependency required by other plugins. 
We also install a few optional plugins and then explicitly load them only
when `example_condition` is met. 

Usage
-----
Slowly provides a single command `:Slowly` with a few subcommands:
* `:Slowly install`   to `git clone` plugins configured in the `setup` options.
* `:Slowly reinstall` to delete all configured plugins and clone them again.
* `:Slowly save`      to make a tarball of plugins configured in the `setup` options.
* `:Slowly update`    to `git pull` plugins configured in the `setup` options.\*
* `:Slowly restore`   to delete all plugins and reload from the `save` tarball

\* `:Slowly update` will automatically `:Slowly save` before `git pull`-ing.

Configuration
-------------
Slowly's `setup` function can accept the following configuration options:
* `disabled_builtins` Builtin Neovim plugins to disable
* `start_urls`        URLs of `git` repositories for plugins to put in `start/`
* `opt_urls`          URLs of `git` repositories for plugins to put in `opts/`
* `install_path`      defaults to `~/.local/share/nvim/site/pack/slowly/`
* `save_path`         defaults to `~/.cache/nvim/slowly/`

