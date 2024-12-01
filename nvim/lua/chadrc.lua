-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "ayu_dark",

  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

M.ui = {
  statusline = {
    theme = "default",
    separator_style = "default",
    modules = {
      formatter = function()
        local conform = require "conform"
        local bufnr = vim.api.nvim_get_current_buf()
        local formatters = conform.list_formatters(bufnr)

        if formatters and #formatters > 0 then
          -- Get the first formatter name
          return "%#St_LspStatus#" .. "󰉼 " .. formatters[1].name
        end
        return ""
      end,
    },
    -- Modify order to include formatter
    order = {
      "mode",
      "file",
      "git",
      "%=",
      "lsp_msg",
      "%=",
      "diagnostics",
      "formatter", -- Add formatter here
      "lsp",
      "cwd",
      "cursor",
    },
  },
}

return M
