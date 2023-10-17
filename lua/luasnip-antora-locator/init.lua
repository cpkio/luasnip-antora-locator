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

local gettags = coroutine.create(function(dir)
  while true do
    local res = {}
    local _dir = string.gsub(dir, '\\', '/')
    local tags = vim.fn.taglist('.*')
    local pathlen = string.len(_dir)

    for _, v in pairs(tags) do
      if v.kind == 't' then
        local found = string.find(v.filename, _dir, 1, true)
        if found then
          local taglocation = string.sub(v.filename, found+pathlen+1)
          local s = string.gsub(taglocation, '/', ' ', 4)
          local pathway = vim.fn.split(s, ' ')
          if pathway[2] == 'modules' then
            table.remove(pathway, 2)
            table.insert(pathway, v.name)
            local c, m, f, file, tag = unpack(pathway)
            f = f:sub(1,-2)

            if not res[c] then
              res[c] = {}
            end

            if not res[c][m] then
              res[c][m] = {}
            end

            if not res[c][m][f] then
              res[c][m][f] = {}
            end

            if not res[c][m][f][file] then
              res[c][m][f][file] = {}
            end

            table.insert(res[c][m][f][file], tag)
          end

        end
      end
    end
    coroutine.yield(res)
  end
end)

local getcomponents = coroutine.create(function(dir)
  while true do
    assert(dir and dir ~= '', 'Please pass directory parameter')
    if string.sub(dir, -1) == '/' then
        dir = string.sub(dir, 1, -2)
    end

    local components = {}

    local code_tags, _tags = coroutine.resume(gettags, dir)
    assert(code_tags, 'Tags load error')

    for entry in lfs.dir(dir) do
        if entry ~= '.' and entry ~= '..' then
            local _entry = entry
            entry = dir .. '/' .. entry
            local attr = lfs.attributes(entry)
            if attr.mode == 'directory' then
              local config_path = entry .. '/antora.yml'
              local config_file = lfs.attributes(config_path)
              if config_file and config_file.mode == 'file' then
                local config = read_config(config_path)
                components[config.name] = { dir = entry, tags = _tags[_entry] }
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

                    local function yieldtree(dir, base)
                      for e in lfs.dir(dir) do
                        if e ~= "." and e ~= ".." then
                          local e_full = dir.."/"..e
                          local b; if #base > 0 then b = base .. '/' .. e else b = e end
                          local a = lfs.attributes(e_full)
                          if a.mode == "directory" then
                            data[key]['modules'][module][family:sub(1,-2)][b .. '/'] = {}
                            yieldtree(e_full, e)
                          else
                            data[key]['modules'][module][family:sub(1,-2)][b] = {}

                            if  data[key]['tags'] and
                                data[key]['tags'][module] and
                                data[key]['tags'][module][family:sub(1,-2)] and
                                data[key]['tags'][module][family:sub(1,-2)][b] then

                                data[key]['modules'][module][family:sub(1,-2)][b] = data[key]['tags'][module][family:sub(1,-2)][b]
                            end

                          end
                        end
                      end
                    end

                    yieldtree(family_full, '')
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
  assert(code_components, 'Components load error')
  local code_repositories, repositories = coroutine.resume(getmodules, data)
  assert(code_repositories, 'Modules and families load error')
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
    for k, v in pairs(M.db[component]['modules'][module][family]) do
      table.insert(resource_list, t(k))
    end
  end
  return resource_list
end

M.tags = function(component, module, family, file)
  local tags_list = { t('') }
  component = unpack(component)
  module = unpack(module)
  family = unpack(family)
  file = unpack(file)
  vim.notify(component .. ' ' .. module .. ' ' .. family .. ' ' .. file)
  if  M.db[component]['modules'][module] and
      M.db[component]['modules'][module][family] and
      M.db[component]['modules'][module][family][file] then

      for _, v in pairs(M.db[component]['modules'][module][family][file]) do
        table.insert(tags_list, t('tag=' .. v) )
      end
  end
  return tags_list
end

return M
