vim.api.nvim_create_user_command('AntoraLocatorUpdate', function()
  -- require('luasnip.loaders').reload_file([[' ..
  --   os.getenv('XDG_DATA_HOME') ..
  --   [[\nvim-data\site\pack\user\start\cmp-antora-locator\after\plugin\cmp-antora-locator.lua]] ..
  --   ']])')
  require('luasnip-antora-locator').refresh()
end, { desc = 'Refresh LuaSnip Locator Snippet' })

