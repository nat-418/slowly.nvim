local M = {}

local function tilde(path)
  return string.gsub(path, vim.fn.expand('$HOME'), '~')
end

local function git_url2dir(url)
  local first_attempt = string.match(url, ".*/(.*)%.git$")
  if first_attempt == nil then
    local second_attempt = string.match(url, ".*/(.*)$")
    return second_attempt
  end
  return first_attempt
end

M.save = function(install_path, save_path)
  if install_path == nil then return false end
  if save_path  == nil then return false end

  local tarball = save_path .. 'save.tar.gz'

  vim.fn.delete(save_path, 'rf')
  vim.fn.mkdir(save_path, 'p')

  local save = '!cd ' .. install_path .. ' && ' .. 'tar -czf ' .. tarball .. ' .'

  vim.cmd(tilde(save))

  return true
end

M.restore = function(install_path, save_path)
  if install_path == nil then return false end
  if save_path  == nil then return false end

  local tarball = save_path .. 'save.tar.gz'

  if not vim.fn.filereadable(tarball) then
    print('Error: no save tarball found')
    return false
  end

  vim.fn.delete(install_path, 'rf')
  vim.fn.mkdir(install_path, 'p')

  local restore = '!tar -xzf ' .. tarball .. ' -C ' .. install_path

  vim.cmd(tilde(restore))

  return true
end

M.install = function(install_path, urls)
  if install_path == nil then return false end
  if urls         == nil then return false end

  vim.fn.mkdir(install_path, 'p')

  for _, url in ipairs(urls) do
    local dir     = git_url2dir(url)
    local install = '!git -C ' .. install_path .. ' clone --depth 1 ' .. url
    if vim.fn.isdirectory(install_path .. dir) == 0 then
      vim.cmd(tilde(install))
    else
      print('Already installed: ' .. tilde(dir))
    end
  end

  return true
end

M.update = function(install_path, urls)
  if install_path == nil then return false end
  if urls         == nil then return false end

  vim.fn.mkdir(install_path, 'p')

  for _, url in ipairs(urls) do
    local dir    = git_url2dir(url)
    local update = '!cd ' .. install_path .. dir .. ' && git pull'
    if vim.fn.isdirectory(install_path .. dir) == 1 then
      vim.cmd(tilde(update))
    else
      print('Not installed: ' .. tilde(dir))
    end
  end

  return true
end

M.reinstall = function(install_path, urls)
  if install_path == nil then return false end
  if urls         == nil then return false end

  vim.fn.delete(install_path, 'rf')

  M.install(install_path, urls)

  return true
end

M.run = function(subcommand, opts)
  if subcommand == nil or opts == nil then
    print('Error: bad input')
    return false
  end

  local start_path = opts.install_path .. 'start/'
  local opt_path   = opts.install_path .. 'opt/'

  if subcommand == 'save' then
    M.save(opts.install_path, opts.save_path)
  end

  if subcommand == 'restore' then
    M.restore(opts.install_path, opts.save_path)
  end

  if subcommand == 'install' then
    M.install(start_path, opts.start_urls)
    M.install(opt_path,   opts.opt_urls)
  end

  if subcommand == 'update' then
    M.save(opts.install_path, opts.save_path)
    M.update(start_path, opts.start_urls)
    M.update(opt_path,   opts.opt_urls)
  end

  if subcommand == 'reinstall' then
    M.reinstall(start_path, opts.start_urls)
    M.reinstall(opt_path,   opts.opt_urls)
  end

  return false
end

M.setup = function(opts)
  if opts == nil then return false end

  if opts.disabled_plugins == nil then
    opts.disabled_plugins = {}
  end

  if opts.install_path == nil then
    opts.install_path = vim.fn.expand('$HOME/.local/share/nvim/site/pack/slowly/')
    if opts.install_path == nil then return false end
  end

  if opts.save_path == nil then
    opts.save_path = vim.fn.expand('$HOME/.cache/nvim/slowly/')
    if opts.save_path == nil then return false end
  end

  for _, plugin in ipairs(opts.disabled_builtins) do
    vim.g["loaded_" .. plugin] = 1
  end

  vim.api.nvim_create_user_command(
    'Slowly',
    function(args)
      M.run(args.args, opts)
      vim.cmd('silent! helptags ALL')
    end,
    {
      nargs = 1,
      complete = function()
        return {
          'save',
          'restore',
          'install',
          'update',
          'reinstall'
        }
      end
    }
  )
end

return M
