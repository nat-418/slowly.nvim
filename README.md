slowly.nvim 🐢
==============
Slowly is a Neovim plugin manager for people who value simplicity over speed.
It is neither *blazingly fast* nor the most advanced solution, but rather the
bare minimum of what I need. Slowly handles installing, updating, and
reinstalling plugins using `git`. It does not do anything fancy. I used
[packer.nvim](https://github.com/wbthomason/packer.nvim) for awhile,
and if you want the kitchen sink included, you should use Packer instead.

Here's a friendly comparison of Slowly to other plugin managers:

|                  Advantages                   |    Disadvantages     |
| --------------------------------------------- | -------------------  |
| You can acually understand what is happening  | Plugin works slowly  |
| Simple and easy to use                        | Only basic features  |
| Few dependencies, install is copying one file | No flashy animations |

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
`~/.config/nvim/lua/slowly.lua`. Or, put this repository somewhere
on your runtime path. Then write an `~/.config/nvim/init.lua` like this:

```lua
local example_condition = false

require('slowly').setup({ 
  disabled_builtins = {
    'netrw',
    'netrwPlugin',
    'netrwSettings',
    'netrwFileHandlers'
  },
  plugins = {
    {url = 'https://github.com/nvim-lua/plenary.nvim',    start = true},
    {url = 'https://github.com/elihunter173/dirbuf.nvim', start = true},
    {url = 'https://github.com/nat-418/bufala.nvim'},
    {url = 'https://github.com/nat-418/tabbot.nvim'}
  }
})

require('dirbuf').setup {
  show_hidden = false,
  sort_order  = 'directories_first',
  write_cmd   = 'DirbufSync -confirm',
}

if example_condition then
  vim.cmd.packadd('bufala.nvim'); require('bufala').setup()
  vim.cmd.packadd('tabbot.nvim'); require('tabbot').setup()
end
```

In this example we want to replace the old vim default plugin `netrw` with
the excellent [dirbuf.nvim](https://github.com/elihunter173/dirbuf.nvim),
and we want `dirbuf` to be loaded automatically on startup along with
`plenary`—a common dependency required by other plugins. We also install a
few optional plugins and then explicitly load them only when
`example_condition` is met. 

Usage
-----
Slowly provides a single command `:Slowly` with a few subcommands:
* `:Slowly install`   to `git clone` plugins configured in the `setup` options.
* `:Slowly reinstall` to delete all configured plugins and clone them again.
* `:Slowly save`      to make a tarball of installed plugins.
* `:Slowly update`    to `git pull` plugins configured in the `setup` options.
* `:Slowly restore`   to delete all plugins and reload from the `save` tarball

*Note:* `:Slowly update` will automatically `:Slowly save` before
`git pull`-ing. That way if something bad happens as a result of the update,
you can easily do a `:Slowly restore` and quickly get back to a sane state.
Only one save tarball can exist at a time. If you need more advancded
snapshotting and backups, ask your filesystem.

Configuration
-------------
Slowly's `setup` function can accept the following configuration options:
* `disabled_builtins` Builtin Neovim plugins to disable
* `install_path`      defaults to `~/.local/share/nvim/site/pack/slowly/`
* `save_path`         defaults to `~/.cache/nvim/slowly/`
* `plugins`           is a list of plugin tables with the following values:
   - `url`            required field of the fully-qualified `git`  URL string
   - `start`          optional boolean to direct plugin to install in `start/`\*
   - `checkout`       optional string for a tag, branch, or commit to checkout
   - `run`            optional string of a shell script to run after git commands

*Note:* by default, all plugins install to `opt/`.
