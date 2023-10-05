vim.api.nvim_create_user_command('AntoraLocatorUpdate', function()
  require('luasnip-antora-locator').refresh()
end, { desc = 'Refresh LuaSnip Locator Snippet' })

