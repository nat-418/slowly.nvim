local M = {}

local function bail(message)
  print('Slowly Error: ' ..  message)
  return false
end

local function tilde(path)
  return string.gsub(path, vim.fn.expand('$HOME'), '~')
end

local function basename(git_url)
  local first_attempt = string.match(git_url, ".*/(.*)%.git$")
  if first_attempt == nil then
    local second_attempt = string.match(git_url, ".*/(.*)$")
    return second_attempt
  end
  return first_attempt
end

local function subcommands()
  return {'install', 'save', 'restore', 'update', 'reinstall'}
end

M.save = function(opts)
  if opts               == nil then return bail('bad save input')   end
  if opts.install_path  == nil then return bail('bad install path') end
  if opts.save_path     == nil then return bail('bad save path')    end

  local save =
    '!cd ' .. tilde(opts.install_path)
     .. ' && tar -czf ' .. opts.save_path .. 'save.tar.gz .'

  vim.fn.delete(opts.save_path, 'rf')
  vim.fn.mkdir(opts.save_path,  'p')
  vim.cmd(tilde(save))

  return print('Slowly saved plugins to tarball')
end

M.restore = function(opts)
  if opts               == nil then return bail('bad restore input') end
  if opts.install_path  == nil then return bail('bad install path')  end
  if opts.save_path     == nil then return bail('bad save path')     end

  local tarball = opts.save_path .. 'save.tar.gz'
  local restore = '!tar -xzf ' .. tarball .. ' -C ' .. opts.install_path

  if not vim.fn.filereadable(tarball) then
    print('Error: no save tarball found')
    return false
  end

  vim.fn.delete(opts.install_path, 'rf')
  vim.fn.mkdir(opts.install_path,  'p')
  vim.cmd(tilde(restore))

  return print('Slowly restored plugins from tarball')
end

M.install = function(opts)
  if opts               == nil then return bail('bad install input') end
  if opts.install_path  == nil then return bail('bad install path')  end
  if opts.plugins       == nil then return bail('bad plugins table') end

  vim.fn.mkdir(opts.install_path .. 'start/', 'p')
  vim.fn.mkdir(opts.install_path .. 'opt/',   'p')

  local count = 0
  for _, plugin in ipairs(opts.plugins) do
    if plugin.url == nil then return bail('bad plugin URL') end

    local dirname     = basename(plugin.url)
    local destination = opts.install_path .. 'opt/'
    if plugin.start then destination = opts.install_path .. 'start/' end

    local install = '!git -C ' .. destination .. ' clone --depth 1 ' .. plugin.url

    local function isInstalled()
      return vim.fn.isdirectory(destination .. dirname) ~= 0
    end

    if not isInstalled() then
      count = count + 1
      vim.cmd(tilde(install))
    end

    if plugin.checkout ~= nil and not isInstalled() then
      local plugin_path = tilde(destination .. dirname)
      vim.cmd(
        '!cd ' .. plugin_path
        .. ' && git fetch --unshallow || echo "^ safe to ignore"'
        .. ' && git checkout ' .. plugin.checkout
      )
    end
  end

  if count == 0 then
    return print('Slowly installed everything already')
  else
    return print('Slowly finished installing ' .. count .. ' plugins')
  end
end


M.update = function(opts)
  if opts              == nil then return bail('bad update input')  end
  if opts.install_path == nil then return bail('bad install path')  end
  if opts.plugins      == nil then return bail('bad plugins table') end

  vim.fn.mkdir(opts.install_path, 'p')

  local count = 0
  for index, plugin in ipairs(opts.plugins) do
    if plugin.url == nil then return bail('bad plugin URL') end

    count             = index
    local dirname     = basename(plugin.url)
    local destination = opts.install_path .. 'opt/'
    if plugin.start then destination = opts.install_path .. 'start/' end

    local update = '!cd ' .. destination .. dirname .. ' && git pull'

    if vim.fn.isdirectory(destination .. dirname) == 0 then
      print('Not installed: ' .. tilde(dirname))
    else
      vim.cmd(tilde(update))
    end

    if plugin.checkout ~= nil then
      local plugin_path = tilde(destination .. dirname)
      vim.cmd(
        '!cd ' .. plugin_path
        .. ' && git checkout ' .. plugin.checkout
        .. ' || git fetch --unshallow'
        .. ' && git checkout ' .. plugin.checkout
      )
    end
  end

  return print('Slowly finished updating ' .. count .. ' plugins')
end

M.reinstall = function(opts)
  if opts               == nil then return bail('bad reinstall input') end
  if opts.install_path  == nil then return bail('bad install path')    end

  vim.fn.delete(opts.install_path, 'rf')
  return M.install(opts)
end

M.run = function(subcommand, opts)
  if subcommand == nil or opts == nil then return bail('bad run input')  end

  local valid = false
  for _, possible in ipairs(subcommands()) do
    if subcommand == possible then valid = true end
  end

  if valid then return M[subcommand](opts) end

  return bail('not a valid subcommand')
end

M.setup = function(opts)
  if opts == nil or opts.plugins == nil then
    return bail('bad configuration')
  end

  if opts.disabled_plugins ~= nil then
    for _, plugin in ipairs(opts.disabled_builtins) do
      vim.g["loaded_" .. plugin] = 1
    end
  end

  if opts.install_path == nil then
    opts.install_path = vim.fn.expand('$HOME/.local/share/nvim/site/pack/slowly/')
  end

  if opts.save_path == nil then
    opts.save_path = vim.fn.expand('$HOME/.cache/nvim/slowly/')
  end

  return vim.api.nvim_create_user_command('Slowly', function(args)
      M.run(args.args, opts)
      vim.cmd('silent! helptags ALL')
    end, { nargs = 1, complete = subcommands}
  )
end

return M
