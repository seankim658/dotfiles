local options = require("plugins.configs.nvimtree")

options.view.signcolumn = "yes"
options.view.width = 32
if not options.modified then
  options.modified = {}
end
options.modified.enable = true
options.modified.show_on_dirs = true
options.modified.show_on_open_dirs = false
options.git.enable = true
options.filters.git_ignored = false
options.renderer.special_files = {}
options.renderer.highlight_modified = "name"
options.renderer.highlight_git = true
options.renderer.icons.show.modified = false
options.renderer.icons.show.git = true
options.renderer.icons.git_placement = "after"
options.renderer.icons.padding = "  "
options.renderer.icons.glyphs.git = {
  unstaged = "M",
  staged = "A",
  unmerged = "U",
  renamed = "R",
  untracked = "U",
  deleted = "D",
  ignored = "!"
}

return options
