local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    json = { "fixjson" },
    python = { "ruff_format" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    go = { "gopls" },
    astro = { "prettier_astro" },
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  formatters = {
    prettier_astro = {
      command = "prettier",
      args = { "--plugin", "prettier-plugin-astro", "--stdin-filepath", "$FILENAME" },
      stdin = true,
    },
  },

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

return options
