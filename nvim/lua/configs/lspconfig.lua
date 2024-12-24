-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local globals = require "globals"

local servers = { "html", "cssls", "bashls", "clangd", "rust_analyzer", "gopls" }
local nvlsp = require "nvchad.configs.lspconfig"

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- configuring single server, example: typescript
-- lspconfig.ts_ls.setup {
--   on_attach = nvlsp.on_attach,
--   on_init = nvlsp.on_init,
--   capabilities = nvlsp.capabilities,
-- }

-- Don't load marksman in my obsidian vault
lspconfig.marksman.setup {
  on_attach = function(client, bufnr)
    -- Get the full path of the current file
    local file_path = vim.fn.expand "%:p"
    -- Get the expanded vault path
    local vault_path = vim.fn.expand(globals.obsidian_vaults.macos)

    -- If file is in vault, don't attach marksman
    if string.match(file_path, "^" .. vault_path) then
      vim.schedule(function()
        vim.cmd "LspStop marksman"
      end)
      return
    end

    -- Otherwise, proceed with normal attachment
    nvlsp.on_attach(client, bufnr)
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

-- Python pyright virtualenv support
local function get_python_path()
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  return vim.fn.exepath "python" or "python"
end

lspconfig.pyright.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  before_init = function(_, config)
    config.settings.python.pythonPath = get_python_path()
  end,
}

-- TypeScript
lspconfig.ts_ls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  init_options = {
    preferences = {
      disableSuggestions = true,
    },
  },
}
