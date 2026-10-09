require "nvchad.options"

local option = vim.o

option.relativenumber = true
option.colorcolumn = "150"
vim.opt.fillchars:append { diff = "╱" } -- Hatch the filler lines in diffs

vim.filetype.add {
  extension = {
    jinja = "jinja",
  },
}
