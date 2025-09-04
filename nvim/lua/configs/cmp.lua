return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  opts = function()
    local cmp = require "cmp"
    local conf = require "nvchad.configs.cmp"

    conf.sources = cmp.config.sources {
      { name = "obsidian" },
      { name = "obsidian_new" },
      { name = "obsidian_tags" },
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "nvim_lua" },
      { name = "path" },
    }

    conf.formatting = {
      format = function(entry, vim_item)
        vim_item.menu = ({
          nvim_lsp = "[LSP]",
          luasnip = "[Snippet]",
          buffer = "[Buffer]",
          nvim_lua = "[Lua]",
          path = "[Path]",
          obsidian = "[Obsidian]",
          obsidian_new = "[Obsidian New]",
          obsidian_tags = "[Obsidian Tags]",
        })[entry.source.name]
        return vim_item
      end,
    }

    conf.mapping["<CR>"] = nil

    conf.mapping["<C-t>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item { count = 5 }
      end
    end, { "i", "s" })

    conf.mapping["<C-l>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_next_item { count = 5 }
      end
    end, { "i", "s" })

    conf.mapping["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        local entry = cmp.get_selected_entry()
        if entry then
          cmp.confirm { select = true }
        else
          cmp.select_next_item()
        end
      elseif require("luasnip").expand_or_jumpable() then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
      else
        fallback()
      end
    end, {
      "i",
      "s",
    })

    return conf
  end,
}
