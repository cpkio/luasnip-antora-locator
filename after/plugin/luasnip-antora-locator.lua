local ls = require('luasnip')

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node

local antora = require('luasnip-antora-locator')

ls.add_snippets('asciidoc', {
  s({ trig = 'xref', desc = 'Antora Locator Snippet. Use Tab and choice switch mappings'}, {
    c(1, {
      t('xref:'),
      t('include::'),
      t('image::')
    }),
    d(2,  function()
            return sn(nil, c(1, antora.components()) )
          end,
          {}),
    t(':'),
    d(3,  function(args)
            return sn(nil, c(1, antora.modules( args[1] )) )
          end,
          { 2 }),
    t(':'),
    d(4,  function(args)
            return sn(nil, c(1, antora.families( args[1], args[2] )) )
          end,
          { 2, 3 }),
    t('$'),
    d(5,  function(args)
            return sn(nil, c(1, antora.resources( args[1], args[2], args[3] )) )
          end,
          { 2, 3, 4 }),
    t('[]'),
    i(0)
  })
})
