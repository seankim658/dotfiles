require("mason-tool-installer").setup {
  ensure_installed = {
    -- LSP servers
    "lua-language-server",
    "html-lsp",
    "css-lsp",
    "bash-language-server",
    "clangd",
    "gopls",
    "astro-language-server",
    "tailwindcss-language-server",
    "svelte-language-server",
    "jinja-lsp",
    "marksman",
    "pyright",
    "typescript-language-server",
    -- Formatters
    "stylua",
    "prettier",
    "black",
    "fixjson",
    -- Linters
    "eslint_d",
    "ruff", -- Setup as an lsp but just provides linting
  },
  -- rust-analyzer is setup directly through rustup (`rustup component add rust-analyzer`)
}
