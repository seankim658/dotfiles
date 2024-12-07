return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  opts = function()
    local cmp = require "cmp"
    local conf = require "nvchad.configs.cmp"

    conf.mapping["<CR>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.close()
      end
      fallback()
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
