return {
  "nvim-treesitter/nvim-treesitter",
  opts = function()
    local conf = require "nvchad.configs.treesitter"

    -- Extend ensure_installed list
    conf.ensure_installed = vim.list_extend(conf.ensure_installed, {
      -- web dev
      "html",
      "css",
      "javascript",
      "typescript",
      "tsx",
      -- config/data formats
      "json",
      "yaml",
      "toml",
      -- scripting
      "python",
      "bash",
      -- markup
      "markdown",
      "markdown_inline",
      -- git
      "gitignore",
      "git_config",
      -- systems programming
      "c",
      "rust",
      -- documentation
      "comment",
    })

    -- Override highlight config
    conf.highlight = {
      enable = true,
      use_languagetree = true,
      disable = function(lang, bufnr)
        return lang == "csv" or vim.bo[bufnr].filetype == "csv" or lang == "tsv" or vim.bo[bufnr].filetype == "tsv"
      end,
    }

    -- Override indent config
    conf.indent = {
      enable = true,
      disable = { "python" },
    }

    return conf
  end,
}
