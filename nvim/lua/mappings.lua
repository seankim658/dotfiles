-- Loads NVChad's default keymappings first as a base.
require "nvchad.mappings"

-- My mappings.

local map = vim.keymap.set

-- map("n", ";", ":", { desc = "CMD enter command mode" }) -- `;` to enter command mode
map("i", "jj", "<ESC>") -- `jj` to exit insert mode

-- Window resizing.
map("n", "<A-1>", "<C-w>+", { desc = "Increase window height" })
map("n", "<A-2>", "<C-w>-", { desc = "Decrease window height" })
map("n", "<A-3>", "<C-w><", { desc = "Decrease window width" })
map("n", "<A-4>", "<C-w>>", { desc = "Increase window width" })
map("n", "<A-5>", "<C-w>=", { desc = "Equal window dimensions" })

-- Delete/change without yanking.
map("n", "d", "\"_d", { desc = "Delete without yanking" })
map("v", "d", "\"_d", { desc = "Delete without yanking" })
map("n", "D", "\"_D", { desc = "Delete without yanking" })
map("v", "D", "\"_D", { desc = "Delete without yanking" })

map("n", "c", "\"_c", { desc = "Change without yanking" })
map("v", "c", "\"_c", { desc = "Change without yanking" })
map("n", "C", "\"_C", { desc = "Change without yanking" })
map("v", "C", "\"_C", { desc = "Change without yanking" })

map("n", "x", "\"_x", { desc = "Delete character without yanking" })
map("v", "x", "\"_x", { desc = "Delete character without yanking" })
map("n", "X", "\"_X", { desc = "Delete character without yanking" })
map("v", "X", "\"_X", { desc = "Delete character without yanking" })

map("n", "s", "\"_s", { desc = "Substitute without yanking" })
map("v", "s", "\"_s", { desc = "Substitute without yanking" })
map("n", "S", "\"_S", { desc = "Substitute without yanking" })
map("v", "S", "\"_s", { desc = "Substitute without yanking" })

map("n", "<leader>ds", vim.diagnostic.open_float, { desc = "Float diagnostic"})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
