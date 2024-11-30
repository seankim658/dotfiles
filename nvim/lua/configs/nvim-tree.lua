return {
  "nvim-tree/nvim-tree.lua",
  opts = function()
    local conf = require "nvchad.configs.nvimtree"

    -- Modify the existing view settings
    conf.view.signcolumn = "yes"
    conf.view.width = 32

    -- Add git settings
    conf.git = {
      enable = true,
    }

    -- Modify existing filters
    conf.filters.git_ignored = false

    -- Extend the existing renderer config
    conf.renderer.special_files = {}
    conf.renderer.highlight_modified = "name"

    -- Extend the existing renderer.icons config
    conf.renderer.icons.show = {
      modified = false,
      git = true,
    }
    conf.renderer.icons.git_placement = "after"
    conf.renderer.icons.padding = "  "

    -- Extend the existing git glyphs
    conf.renderer.icons.glyphs.git = {
      unstaged = "M",
      staged = "A",
      unmerged = "U",
      renamed = "R",
      untracked = "U",
      deleted = "D",
      ignored = "!",
    }

    -- Add modified settings
    conf.modified = {
      enable = true,
      show_on_dirs = true,
      show_on_open_dirs = false,
    }

    return conf
  end,
}
