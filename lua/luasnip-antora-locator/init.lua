local lfs = require'lfs'

local ls = require('luasnip')
local t = ls.text_node

local M = {}

M.db = {}

local function read_config(config_path)
  assert(io.open(config_path, 'r'))

  local opts = {
    'yq',
    '.',
    config_path,
    '--no-colors',
    '--output-format',
    'json'
  }

  local code, result = vim._system(opts, {text=true})
  return vim.json.decode(result)
end

local getcomponents = coroutine.create(function(dir)
  while true do
    assert(dir and dir ~= '', 'Please pass directory parameter')
    if string.sub(dir, -1) == '/' then
        dir = string.sub(dir, 1, -2)
    end

    local components = {}

    for entry in lfs.dir(dir) do
        if entry ~= '.' and entry ~= '..' then
            entry = dir .. '/' .. entry
            local attr = lfs.attributes(entry)
            if attr.mode == 'directory' then
              local config_path = entry .. '/antora.yml'
              local config_file = lfs.attributes(config_path)
              if config_file and config_file.mode == 'file' then
                local config = read_config(config_path)
                components[config.name] = { dir = entry }
              end
            end
        end
    end
    coroutine.yield(components)
  end
end)

local getmodules = coroutine.create(function(data)
  while true do
    for key, value in pairs(data) do

      for entry in lfs.dir(value.dir) do
        if entry ~= '.' and entry ~= '..' then
          local entry_full = value.dir .. '/' .. entry
          local attr = lfs.attributes(entry_full)
          if attr.mode == 'directory' and entry == 'modules' then
            data[key]['modules'] = {}

            for module in lfs.dir(entry_full) do
              if module ~= '.' and module ~= '..' and lfs.attributes(entry_full .. '/' .. module, "mode") == 'directory' then
                data[key]['modules'][module] = {}
                local module_full = entry_full .. '/' .. module

                for family in lfs.dir(module_full) do
                  if family ~= '.' and family ~= '..' and lfs.attributes(module_full .. '/' .. family, "mode") == 'directory' then
                    data[key]['modules'][module][family:sub(1,-2)] = {}
                    local family_full = module_full .. '/' .. family

                    for element in lfs.dir(family_full) do
                      if element ~= '.' and element ~= '..' then
                        local element_full = family_full .. '/' .. element
                        if lfs.attributes(element_full, "mode") == 'directory' then
                          table.insert(data[key]['modules'][module][family:sub(1,-2)], element .. '/')
                        else
                          table.insert(data[key]['modules'][module][family:sub(1,-2)], element)
                        end
                      end
                    end

                  end
                end

              end
            end

          end
        end
      end

    end
    coroutine.yield(data)
  end
end)

M.root = nil

M.refresh = function()
  local code_components, data = coroutine.resume(getcomponents, M.root)
  assert(code_components, 'Error')
  local code_repositories, repositories = coroutine.resume(getmodules, data)
  assert(code_repositories, 'Error')
  M.db = repositories
end

M.setup = function(root_repo)
  assert(lfs.attributes(root_repo), 'Root is not a valid dir')
  M.root = root_repo or [[C:\]]
  M.refresh()
end

M.components = function()
  local components_list = {}
  for k, _ in pairs(M.db) do
    table.insert(components_list, t(k))
  end
  return components_list
end

M.modules = function(component)
  local modules_list = { t('???') }
  component = unpack(component)
  if M.db[component]['modules'] then
    for k, _ in pairs(M.db[component]['modules']) do
      table.insert(modules_list, t(k))
    end
  end
  return modules_list
end

M.families = function(component, module)
  local families_list = { t('???') }
  component = unpack(component)
  module = unpack(module)
  if M.db[component]['modules'][module] then
    for k, _ in pairs(M.db[component]['modules'][module]) do
      table.insert(families_list, t(k))
    end
  end
  return families_list
end

M.resources = function(component, module, family)
  local resource_list = { t('???') }
  component = unpack(component)
  module = unpack(module)
  family = unpack(family)
  if M.db[component]['modules'][module] and M.db[component]['modules'][module][family] then
    for _, v in pairs(M.db[component]['modules'][module][family]) do
      table.insert(resource_list, t(v))
    end
  end
  return resource_list
end

return M
