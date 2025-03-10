local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local snippets = {
  s({
    trig = "err",
    name = "Error check",
    dscr = "Go error checking snippet",
  }, {
    t { "if err != nil {", "\t" },
    i(0),
    t { "", "}" },
  }),
}

return snippets
