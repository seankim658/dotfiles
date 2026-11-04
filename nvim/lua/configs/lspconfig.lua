-- NVChad LSP defaults (lua_ls, keymaps, diagnostic UI, etc.)
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"
local util = require "lspconfig.util"

-- Base config shared by all LSPs
local base = {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

-- Set up `server`, merging any per-server overrides onto `base`
local function setup(server, opts)
  lspconfig[server].setup(vim.tbl_deep_extend("force", base, opts or {}))
end

-- Servers that only need the defaults
for _, server in ipairs { "html", "bashls", "clangd", "gopls", "astro", "svelte", "marksman" } do
  setup(server)
end

--- Web ---

-- Ignore Tailwind's custom at-rules instead of warning
setup("cssls", {
  settings = {
    css = {
      validate = true,
      lint = { unknownAtRules = "ignore" },
    },
  },
})

-- Extend Tailwind to extra filetypes
setup("tailwindcss", {
  filetypes = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "astro" },
})

-- Turn off tsserver's soft suggestion diagnostics, those are deferred to eslint_d
setup("ts_ls", {
  init_options = {
    preferences = { disableSuggestions = true },
  },
})

--- Python ---

-- Root at the uv workspace (its single uv.lock) so pyright sees workspace-level
-- config, stubs and .venv. Fall back to pyproject.toml, then .git, for other projects.
local python_root = util.root_pattern("uv.lock", "pyproject.toml", ".git")

-- Return the project's .venv interpreter if one exists
local function project_venv_python(root)
  if not root then
    return nil
  end
  local python = root .. "/.venv/bin/python"
  if vim.fn.executable(python) == 1 then
    return python
  end
  return nil
end

-- Prefer the project's .venv, then the active virtualenv, then system python
local function get_python_path(root)
  local venv_python = project_venv_python(root)
  if venv_python then
    return venv_python
  end
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  local python = vim.fn.exepath "python"
  return python ~= "" and python or "python"
end

-- pyright: type checking + IDE features
setup("pyright", {
  root_dir = python_root,
  before_init = function(_, config)
    config.settings.python.pythonPath = get_python_path(config.root_dir)
  end,
})

-- ruff: linting only
setup("ruff", {
  on_attach = function(client, bufnr)
    client.server_capabilities.hoverProvider = false
    nvlsp.on_attach(client, bufnr)
  end,
})

--- Systems / Templates / Markup ---

-- Rust
setup("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = { features = "all" },
      procMacro = { enable = true },
    },
  },
})

-- Jinja
setup("jinja_lsp", {
  filetypes = { "jinja", "html" },
})
