require "nvchad.options"

local option = vim.o

option.relativenumber = true
option.colorcolumn = "150"

vim.filetype.add {
  extension = {
    jinja = "jinja",
  },
}
