local M = {}

local function bail(message)
  print('Slowly Error: ' ..  message)
  return false
end

local function sanityCheck(opts)
  if opts               == nil then return bail('bad input options') end
  if opts.install_path  == nil then return bail('bad install path')  end
  if opts.save_path     == nil then return bail('bad save path')     end
  return true
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
  return {'install', 'save', 'restore', 'update', 'reinstall', 'list', 'clean'}
end

M.save = function(opts)
  sanityCheck(opts)

  local save = table.concat({
    'cd', opts.install_path,
     '&& tar -czf', opts.save_path .. 'save.tar.gz .'
  }, ' ')

  vim.fn.delete(opts.save_path, 'rf')
  vim.fn.mkdir(opts.save_path,  'p')
  print('Slowly saving plugins…')
  vim.fn.system(save)

  return print('Slowly saved plugins to tarball')
end

M.restore = function(opts)
  sanityCheck(opts)

  local tarball = opts.save_path .. 'save.tar.gz'
  local restore = 'tar -xzf ' .. tarball .. ' -C ' .. opts.install_path

  if not vim.fn.filereadable(tarball) then
    print('Error: no save tarball found')
    return false
  end

  vim.fn.delete(opts.install_path, 'rf')
  vim.fn.mkdir(opts.install_path,  'p')
  print('Slowly restoring plugins…')
  vim.fn.system(restore)

  return print('Slowly restored plugins from tarball')
end

M.install = function(opts)
  sanityCheck(opts)

  vim.fn.mkdir(opts.install_path .. 'start/', 'p')
  vim.fn.mkdir(opts.install_path .. 'opt/',   'p')

  local count = 0
  for _, plugin in ipairs(opts.plugins) do
    if plugin.url == nil then return bail('bad plugin URL') end

    local dirname     = basename(plugin.url)
    local destination = opts.install_path .. 'opt/'
    if plugin.start then destination = opts.install_path .. 'start/' end

    local install = 'git -C ' .. destination .. ' clone --depth 1 ' .. plugin.url

    local function isInstalled()
      return vim.fn.isdirectory(destination .. dirname) ~= 0
    end

    if not isInstalled() then
      count = count + 1
      print('Installing ' .. dirname)
      print(vim.fn.system(install))
      if plugin.run ~= nil then
        local plugin_path = destination .. dirname
        print('Running ' .. plugin.run)
        print(vim.fn.system('cd ' .. plugin_path .. ' && ' .. plugin.run))
      end
    end

    if plugin.checkout ~= nil and not isInstalled() then
      local plugin_path = destination .. dirname
      print('Checking out ' .. plugin.checkout)
      print(vim.fn.system(table.concat({
        'cd', plugin_path,
        '&& git fetch --unshallow || echo "^ safe to ignore"',
        '&& git checkout', plugin.checkout
      }, ' ')))
    end
  end

  if count > 0 then
    return print('Slowly finished installing ' .. count .. ' plugins')
  end

  return print('Slowly plugins are already installed')
end

M.update = function(opts)
  sanityCheck(opts)

  vim.fn.mkdir(opts.install_path, 'p')

  local count = 0
  for index, plugin in ipairs(opts.plugins) do
    if plugin.url == nil then return bail('bad plugin URL') end

    count             = index
    local dirname     = basename(plugin.url)
    local destination = opts.install_path .. 'opt/'
    if plugin.start then destination = opts.install_path .. 'start/' end

    local update = 'cd ' .. destination .. dirname .. ' && git pull'

    if vim.fn.isdirectory(destination .. dirname) == 0 then
      print(' ')
      print('Not installed: ' .. dirname)
    else
      print(' ')
      print('Updating ' .. dirname .. '…')
      print(vim.fn.system(update))
    end

    if plugin.checkout ~= nil then
      local plugin_path = destination .. dirname
      print('Checking out ' .. plugin.checkout)
      print(vim.fn.system(table.concat({
        'cd', plugin_path, '&& git checkout', plugin.checkout,
        '|| git fetch --unshallow',
        '&& git checkout', plugin.checkout
      }, ' ')))
    end

    if plugin.run ~= nil then
      local plugin_path = destination .. dirname
      print('Running ' .. plugin.run)
      print(vim.fn.system('cd ' .. plugin_path .. ' && ' .. plugin.run))
    end
  end

  if count > 0 then
    return print('Slowly finished updating ' .. count .. ' plugins')
  end

  return print('Slowly already updated all plugins')
end

M.reinstall = function(opts)
  sanityCheck(opts)

  vim.fn.delete(opts.install_path, 'rf')
  return M.install(opts)
end

M.list = function(opts)
  sanityCheck(opts)

  vim.fn.mkdir(opts.install_path, 'p')

  local count = 0
  for index, plugin in ipairs(opts.plugins) do
    if plugin.url == nil then return bail('bad plugin URL') end

    count             = index
    local dirname     = basename(plugin.url)
    local destination = opts.install_path .. 'opt/'
    if plugin.start then destination = opts.install_path .. 'start/' end

    local show = table.concat({
      'cd', destination .. dirname,
      '&& printf "%-32s%-15s%s" "$(basename $PWD)"',
      '"$(git name-rev --name-only HEAD)"',
      '"$(git show -s --format=%s)"'
    }, ' ')

    if vim.fn.isdirectory(destination .. dirname) == 0 then
      print('Not installed: ' .. dirname)
    else
      print(vim.fn.system(show))
    end
  end

  if count > 0 then
    return print('Slowly finished listing ' .. count .. ' plugins')
  end

  return print('Slowly has no plugins to list')
end

M.clean = function(opts)
  sanityCheck(opts)

  vim.fn.mkdir(opts.install_path, 'p')

  local count     = 0
  local installed = vim.fn.globpath(opts.install_path, '*/*')
  for installed_dir in string.gmatch(installed, '%S+') do
    local doomed = true
    for _, plugin in ipairs(opts.plugins) do
      if plugin.url == nil then return bail('bad plugin URL') end

      local dirname     = basename(plugin.url)
      local destination = opts.install_path .. 'opt/'

      if plugin.start then
        destination = opts.install_path .. 'start/'
      end

      if destination .. dirname == installed_dir then
        doomed = false
      end
    end

    if doomed then
      count = count + 1
      vim.fn.delete(installed_dir, 'rf')
      print('Removed ' .. tilde(installed_dir))
    end
  end

  if count > 0 then
    return print('Slowly removed ' .. count .. ' unwanted plugins')
  end

  return print('Slowly directories are already clean')
end

M.run = function(subcommand, opts)
  if subcommand == nil or opts == nil then return bail('bad run input') end

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

  if opts.disabled_builtins ~= nil then
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
