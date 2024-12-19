local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local snippets = {
  s({
    trig = "main",
    name = "Python main",
    dscr = "Insert Python main block",
  }, {
    t { 'if __name__ == "__main__":', "   " },
    t "main()",
    i(0),
  }),
}

return snippets
