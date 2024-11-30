-- Sets the cache directory for base46 (the NVChad colorscheme engine). Uses 
-- "data" to get Neovim's data directory (usually `~./local/share/nvim`) and 
-- adds a `/base46/` subdirectory.
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
-- set the leader key to <space>
vim.g.mapleader = " "

-- Bootstrap lazy and all plugins. Defines the installation path for the lazy.nvim
-- plugin manager.
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- Checks if lazy.nvim is installed, if not:
-- - Uses `vim.uv.fs_stat to check if the path exists.
-- - If not, clones the lazy.nvim repo.`
--  - Uses blob filter to optimize clone.
--  - Uses the stable branch.
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

-- Adds lazy.nvim to Neovim's runtime path (`rtp`) so it can be used.
vim.opt.rtp:prepend(lazypath)

-- Imports the lazy.nvim configuration from `configs.lazy`.
local lazy_config = require "configs.lazy"

-- Sets up lazy.nvim with:
-- - Loads NVChad core plugins (not lazy).
-- - Imports custom plugins from the `plugins` directory.
-- - Applies the `lazy_config`. 
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- Loads the cached colorscheme files for the default highlighting and statusline colors.
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-- Loads other custom Neovim things.
require "options"
require "nvchad.autocmds"
require("highlights").setup()

-- Schedules the loading of keymappings to happen after Neovim's startup is complete.
vim.schedule(function()
  require "mappings"
end)
