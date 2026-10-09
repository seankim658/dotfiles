-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "chadracula",

  hl_override = {
    -- Comment = { italic = true },
    -- ["@comment"] = { italic = true },

    -- Tint diff lines instead of recoloring their text, so syntax colors stay readable.
    -- A table like { "blue", "black", 88 } mixes 88% of the way from blue to black.
    DiffAdd = { fg = "NONE", bg = { "green", "black", 85 } },
    DiffChange = { fg = "NONE", bg = { "blue", "black", 88 } },
    DiffText = { fg = "NONE", bg = { "blue", "black", 70 } },
    DiffDelete = { fg = "grey", bg = { "red", "black", 85 } },
  },
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

        -- Check if LSP can format
        local clients = vim.lsp.get_active_clients { bufnr = bufnr }
        local can_lsp_format = false
        for _, client in ipairs(clients) do
          if client.server_capabilities.documentFormattingProvider then
            can_lsp_format = true
            break
          end
        end

        if formatters and #formatters > 0 then
          -- Get the first formatter name
          return "%#St_LspStatus#" .. "󰉼 " .. formatters[1].name .. " "
        elseif can_lsp_format then
          return "%#St_LspStatus#" .. "󰉼  LSP "
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
