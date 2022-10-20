slowly.nvim
===========
Slowly is a Neovim plugin manager for people who value simplicity over speed.
It is neither *blazingly fast* nor the most advanced, but the bare minimum of
what I need. Slowly handles installing, updating, and reinstalling plugins
using `git`. It does not do anything implicitly or offer advanced
configuration options. I wrote this after using [packer.nvim](https://github.com/wbthomason/packer.nvim)
for awhile, and if you want the kitchen sink you should use Packer instead.

Requirements
------------
* A Unix-like environment
* `git`

Installing
----------
Copy the `plugins.lua` file from this repository to
`~/.config/nvim/lua/plugins.lua`. Then write your `init.lua` like this:

```lua
require('plugins').setup({ 
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
the excellent `dirbuf`, and we want `dirbuf` to be loaded automatically on
startup along with `plenary` which is often required by other plugins. 
We also install a few optional plugins and then explicitly load them only
when `example_condition` is met.

Usage
-----
Slowly provides a single command `:Slowly` with three subcommands:
* `:Slowly install` to `git clone` plugins configured in the `setup` options.
* `:Slowly update`  to `git pull`  plugins configured in the `setup` options.
* `:Slowly reinstall` to delete all configured plugins and clone them again.

Configuration
-------------
Slowly's `setup` function can accept the following configuration options:
* `disabled_builtins` Builtin Neovim plugins to disable
* `start_urls` URLs of `git` repositories for plugins you want in `start/`
* `opt_urls` URLs of `git` repositories for plugins you want in `opts/`
* `install_path` defaults to `~/.local/share/nvim/site/pack/slowly/`

