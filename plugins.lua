local M = {}

M.install = function(install_path, urls)
  if install_path == nil then return false end
  if urls         == nil then return false end

  vim.cmd('!mkdir -p ' .. install_path)

  for _, url in ipairs(urls) do
    local install = 'git -C ' .. install_path .. ' clone --depth 1 ' .. url
    vim.cmd('!' .. install)
  end

  return true
end

M.update = function(install_path, urls)
  if install_path == nil then return false end
  if urls         == nil then return false end

  vim.cmd('!mkdir -p ' .. install_path)

  for _, url in ipairs(urls) do
    local dir    = string.match(url, '([^/]+)$')
    local update = 'cd ' .. install_path .. '/' .. dir .. ' && git pull'

    vim.cmd('!' .. update)
  end

  return true
end

M.reinstall = function(install_path, urls)
  if install_path == nil then return false end
  if urls         == nil then return false end

  vim.cmd('!rm -rf ' .. install_path)

  M.install(install_path, urls)

  return true
end

M.run = function(subcommand, opts)
  if subcommand == nil or opts == nil then
    print('Error: bad input')
    return false
  end

  if subcommand == 'install' then
    M.install(opts.start_path, opts.start_urls)
    M.install(opts.opt_path,   opts.opt_urls)
  end

  if subcommand == 'update' then
    M.update(opts.start_path, opts.start_urls)
    M.update(opts.opt_path,   opts.opt_urls)
  end

  if subcommand == 'reinstall' then
    M.reinstall(opts.start_path, opts.start_urls)
    M.reinstall(opts.opt_path,   opts.opt_urls)
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
  end

  for _, plugin in ipairs(opts.disabled_builtins) do
    vim.g["loaded_" .. plugin] = 1
  end

  vim.api.nvim_create_user_command(
    'Slowly',
    function(args)
      M.run(args.args, {
        start_urls = opts.start_urls,
        opt_urls   = opts.opt_urls,
        start_path = opts.install_path .. 'start/',
        opt_path   = opts.install_path .. 'opt/'
      })
    end,
    {
      nargs = 1,
      complete = function() return {'install', 'update', 'reinstall'} end
    }
  )
end

return M
