-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
-- local globals = require "globals"

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
    local globals = require "globals"
    local current_file = vim.api.nvim_buf_get_name(bufnr)

    if globals.is_file_in_vault(current_file, "main") then
      vim.lsp.buf_detach_client(bufnr, client.id)
      return
    end

    nvlsp.on_attach(client, bufnr)
  end,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  root_dir = function(fname)
    local globals = require "globals"

    if globals.is_file_in_vault(fname, "main") then
      return nil
    end

    -- Otherwise use the default root_dir logic
    return require("lspconfig.util").find_git_ancestor(fname) or vim.fn.getcwd()
  end,
  autostart = function(bufnr)
    local globals = require "globals"
    local fname = vim.api.nvim_buf_get_name(bufnr)

    return not globals.is_file_in_vault(fname, "main")
  end,
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
