local globals = require "globals"

return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "mechatroner/rainbow_csv",
    ft = { "tsv", "csv" },
  },
  {
    "mfussenegger/nvim-lint",
    event = "VeryLazy",
    config = function()
      require "configs.nvim-lint"
    end,
  },
  {
    "toppair/peek.nvim",
    ft = { "markdown" },
    build = "deno task --quiet build:fast",
    opts = {
      app = "browser",
      theme = "dark",
    },
    keys = {
      { "<leader>mp", "<cmd>PeekOpen<cr>", desc = "Markdown Preview (Peek)" },
      { "<leader>mc", "<cmd>PeekClose<cr>", desc = "Markdown Preview Close (Peek)" },
    },
    init = function()
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
  },
  {
    "folke/trouble.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip").setup {
        history = true,
        updateevents = "TextChanged,TextChangedI",
      }

      require("luasnip.loaders.from_lua").load {
        paths = vim.fn.stdpath "config" .. "/lua/snippets",
      }
    end,
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,

    event = function()
      local vault_path = globals.get_vault_path "main"
      print("Vault path:", vim.inspect(vault_path))

      if vault_path then
        local cwd = vim.fn.getcwd()

        local in_vault_dir = globals.is_file_in_vault(cwd, "main")

        local events = {}

        table.insert(events, "BufReadPre " .. vault_path .. "*.md")
        table.insert(events, "BufNewFile " .. vault_path .. "*.md")

        if in_vault_dir then
          table.insert(events, "VimEnter")
        end

        return events
      end

      return {}
    end,

    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "main",
          path = globals.get_vault_path "main",
        },
      },

      new_notes_location = "current_dir",

      disable_frontmatter = true,

      preferred_link_style = "wiki",

      daily_notes = {
        folder = "daily/",
      },

      templates = {
        subdir = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%I:%M:%S %p %Z",
        substitutions = {
          yesterday = function()
            return os.date("%Y-%m-%d", os.time() - 86400)
          end,
          tomorrow = function()
            return os.date("%Y-%m-%d", os.time() + 86400)
          end,
          timestamp = function()
            return os.date("%A, %d-%b-%y %I:%M:%S%p %Z", os.time())
          end,
        },
      },

      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- Toggle check-boxes.
        ["<leader>ch"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true },
        },
      },

      completion = {
        nvim_cmp = true,
        min_chars = 2,
        create_new = false,
      },

      ui = {
        enable = true,
        update_debounce = 200,
        checkboxes = {
          [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
          ["x"] = { char = "✓", hl_group = "ObsidianDone" },
          [">"] = { char = "→", hl_group = "ObsidianRightArrow" },
          ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
        },
        external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
        reference_text = { hl_group = "ObsidianRefText" },
        highlight_text = { hl_group = "ObsidianHighlightText" },
        tags = { hl_group = "ObsidianTag" },
        block_ids = { hl_group = "ObsidianBlockID" },
        hl_groups = {
          ObsidianTodo = { bold = true, fg = "#f78c6c" },
          ObsidianDone = { bold = true, fg = "#89ddff" },
          ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
          ObsidianTilde = { bold = true, fg = "#ff5370" },
          ObsidianRefText = { underline = true, fg = "#c792ea" },
          ObsidianExtLinkIcon = { fg = "#c792ea" },
          ObsidianTag = { italic = true, fg = "#89ddff" },
          ObsidianBlockID = { italic = true, fg = "#89ddff" },
          ObsidianHighlightText = { bg = "#75662e" },
        },
      },

      attachments = {
        img_folder = "assets/imgs",
        img_name_func = function()
          return string.format("%s-", os.time())
        end,
      },

      yaml_parser = "native",

      note_id_func = function(title)
        return title
      end,

      note_path_func = function(spec)
        local path = spec.dir / tostring(spec.title)
        return path:with_suffix ".md"
      end,

      follow_url_func = function(url)
        vim.fn.jobstart { "open", url }
      end,
    },
  },
  require "configs.cmp",
  require "configs.nvim-tree",
  require "configs.nvim-treesitter",
}
