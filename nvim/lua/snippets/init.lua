local ls = require "luasnip"

-- Load snippets from other files
require "snippets.python"
require "snippets.go"

-- Optional: clear all snippet sessions when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    if ls.session.current_nodes[vim.api.nvim_get_current_buf()] then
      ls.unlink_current()
    end
  end,
})
