-- Loads NVChad's default keymappings first as a base
require "nvchad.mappings"

-- Import utils
local utils = require "utils"

-- My mappings

local map = vim.keymap.set

map("i", "jj", "<ESC>") -- `jj` to exit insert mode
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Float diagnostic" })
map("n", "<leader>j<CR>", "m`o<Esc>``") -- Create newline below cursor without entering insert mode
map("n", "<leader>k<CR>", "m`O<Esc>``", { desc = "New line above" }) -- Create newline above cursor without entering insert mode
map("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tm", ":tabclose<CR>", { desc = "Close tab" })

-- Make j and k work with wrapped lines
map(
  { "n", "x" },
  "j",
  'v:count || mode(1)[0:1] == "no" ? "j" : "gj"',
  { expr = true, desc = "Move down (wrapped-aware)" }
)
map(
  { "n", "x" },
  "k",
  'v:count || mode(1)[0:1] == "no" ? "k" : "gk"',
  { expr = true, desc = "Move up (wrapped-aware)" }
)

-- Window resizing
map("n", "<leader>w+", "<cmd>resize +5<CR>", { desc = "Increase window height" })
map("n", "<leader>w-", "<cmd>resize -5<CR>", { desc = "Decrease window height" })
map("n", "<leader>w<", "<cmd>vertical resize -5<CR>", { desc = "Decrease window width" })
map("n", "<leader>w>", "<cmd>vertical resize +5<CR>", { desc = "Increase window width" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equal window dimensions" })
-- map("n", "<A-1>", "<C-w>+", { desc = "Increase window height" })
-- map("n", "<A-2>", "<C-w>-", { desc = "Decrease window height" })
-- map("n", "<A-3>", "<C-w><", { desc = "Decrease window width" })
-- map("n", "<A-4>", "<C-w>>", { desc = "Increase window width" })
-- map("n", "<A-5>", "<C-w>=", { desc = "Equal window dimensions" })

-- Delete/change without yanking.
map("n", "d", '"_d', { desc = "Delete without yanking" })
map("v", "d", '"_d', { desc = "Delete without yanking" })
map("n", "D", '"_D', { desc = "Delete without yanking" })
map("v", "D", '"_D', { desc = "Delete without yanking" })
map("n", "dd", '"_dd', { desc = "Delete without yanking" })
map("n", "d$", '"_d$', { desc = "Delete without yanking" })
map("n", "diw", '"_diw', { desc = "Delete without yanking" })
map("n", "diW", '"_diW', { desc = "Delete without yanking" })
map("n", "daw", '"_daw', { desc = "Delete without yanking" })
map("n", "daW", '"_daW', { desc = "Delete without yanking" })

map("n", "c", '"_c', { desc = "Change without yanking" })
map("n", "c$", '"_c$', { desc = "Change without yanking" })
map("v", "c", '"_c', { desc = "Change without yanking" })
map("n", "C", '"_C', { desc = "Change without yanking" })
map("v", "C", '"_C', { desc = "Change without yanking" })
map("n", "cc", '"_cc', { desc = "Change without yanking" })
map("n", "ciw", '"_ciw', { desc = "Change without yanking" })
map("n", "ciW", '"_ciW', { desc = "Change without yanking" })
map("n", "caw", '"_caw', { desc = "Change without yanking" })
map("n", "caW", '"_caW', { desc = "Change without yanking" })

map("n", "x", '"_x', { desc = "Delete character without yanking" })
map("v", "x", '"_x', { desc = "Delete character without yanking" })
map("n", "X", '"_X', { desc = "Delete character without yanking" })
map("v", "X", '"_X', { desc = "Delete character without yanking" })

map("n", "s", '"_s', { desc = "Substitute without yanking" })
map("v", "s", '"_s', { desc = "Substitute without yanking" })
map("n", "S", '"_S', { desc = "Substitute without yanking" })
map("v", "S", '"_s', { desc = "Substitute without yanking" })

-- Timestamp mapping
map("n", "<leader>dt", utils.time.insert_timestamp, { desc = "Insert timestamp" })

-- Toggle case on first letter of current word
map("n", "<leader>wc", "b~ea", { desc = "Toggle case on first char of current word and enter insert mode after word" })

-- Close all buffers except current one
map("n", "<leader>bo", utils.buffer.close_other_buffers, { desc = "Close all buffers except currently selected" })

-- Close all buffers that aren't visible in any window
map("n", "<leader>bv", utils.buffer.close_nonvisible_buffers, { desc = "Close all non-visible buffers" })

-- Export diagnostics to markdown
map("n", "<leader>xm", utils.diagnostic.export_as_markdown, { desc = "Export diagnostics as markdown" })

-- Character swapping
map("n", "<leader>sw", function()
  utils.typo.swap_chars()
end, { desc = "Swap characters with next" })

-- Markdown mappings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    --- Bold mappings
    map("n", "<leader>bb", function()
      local word = vim.fn.expand "<cword>"
      if word == "" then
        vim.notify("No word under cursor", vim.log.levels.WARN)
        return
      end

      vim.cmd("normal! ciw**" .. word .. "**")
    end, { buffer = true, desc = "Make word bold (**word**)" })

    map("n", "<leader>bc", function()
      local word = vim.fn.expand "<cword>"
      if word == "" then
        vim.notify("No word under cursor", vim.log.levels.WARN)
        return
      end

      vim.cmd("normal! ciw**" .. word .. ":**")
    end, { buffer = true, desc = "Make word bold with colon (**word:**)" })

    map("v", "<leader>bb", function()
      vim.cmd 'normal! "zy'
      local selected = vim.fn.getreg "z"

      vim.cmd("normal! gvc**" .. selected .. "**")
    end, { buffer = true, desc = "Make selection bold (**text**)" })

    map("v", "<leader>bc", function()
      vim.cmd 'normal! "zy'
      local selected = vim.fn.getreg "z"

      vim.cmd("normal! gvc**" .. selected .. ":**")
    end, { buffer = true, desc = "Make selection bold with colon (**text:**)" })

    --- Italic mappings
    map("n", "<leader>ii", function()
      local word = vim.fn.expand "<cword>"
      if word == "" then
        vim.notify("No word under cursor", vim.log.levels.WARN)
        return
      end

      vim.cmd("normal! ciw*" .. word .. "*")
    end, { buffer = true, desc = "Make word italic (*word*)" })

    map("v", "<leader>ii", function()
      vim.cmd 'normal! "zy'
      local selected = vim.fn.getreg "z"

      vim.cmd("normal! gvc*" .. selected .. "*")
    end, { buffer = true, desc = "Make selection italic (*text*)" })
  end,
})
