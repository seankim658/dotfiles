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

-- Obsidian mappings
-- Function to check if current file is in Obsidian vault
-- local function is_in_obsidian_vault()
--   local vault_path = globals.get_vault_path "main"
--   if not vault_path then
--     return false
--   end
--
--   local cwd = vim.fn.getcwd()
--
--   vault_path = vault_path:gsub("/$", "")
--   cwd = cwd:gsub("/$", "")
--
--   return cwd == vault_path or vim.startswith(cwd, vault_path .. "/")
-- end
--
-- -- Obsidian mappings - only load when in vault
-- vim.api.nvim_create_autocmd("VimEnter", {
--   pattern = "*",
--   callback = function()
--     print("VimEnter triggered")
--     if is_in_obsidian_vault() then
--       print("In vault - loading mappings")
--       local obsidian_utils = utils.obsidian
--
--       map("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", { buffer = true, desc = "Quick switch notes" })
--
--       -- Note creation and navigation
--       map(
--         "n",
--         "<leader>on",
--         obsidian_utils.new_note,
--         { buffer = true, desc = "Create new Obsidian note (choose folder)" }
--       )
--       map(
--         "n",
--         "<leader>ont",
--         obsidian_utils.new_note_with_template,
--         { buffer = true, desc = "Create new note with template" }
--       )
--       map("n", "<leader>ond", obsidian_utils.new_daily_note, { buffer = true, desc = "Create new daily note" })
--       map("n", "<leader>onp", obsidian_utils.new_project_note, { buffer = true, desc = "Create new project note" })
--       map("n", "<leader>onm", obsidian_utils.new_meeting_note, { buffer = true, desc = "Create new meeting note" })
--       map("n", "<leader>onl", obsidian_utils.new_learning_note, { buffer = true, desc = "Create new learning note" })
--       map("n", "<leader>oni", obsidian_utils.new_idea_note, { buffer = true, desc = "Create new idea note" })
--       map("n", "<leader>ono", obsidian_utils.new_other_note, { buffer = true, desc = "Create new other note" })
--
--       map("n", "<leader>os", obsidian_utils.search_notes, { buffer = true, desc = "Search Obsidian notes" })
--       map("n", "<leader>od", obsidian_utils.open_daily_note, { buffer = true, desc = "Open today's daily note" })
--       map("n", "<leader>ow", obsidian_utils.open_weekly_note, { buffer = true, desc = "Open weekly notes" })
--       map("n", "<leader>ot", "<cmd>ObsidianTags<cr>", { buffer = true, desc = "Search Obsidian tags" })
--
--       -- Note operations
--       map("n", "<leader>or", obsidian_utils.rename_note, { buffer = true, desc = "Rename current note" })
--       map("v", "<leader>oe", obsidian_utils.extract_note, { buffer = true, desc = "Extract selection to new note" })
--       map("n", "<leader>op", obsidian_utils.paste_image, { buffer = true, desc = "Paste image from clipboard" })
--
--       -- Obsidian frontmatter
--       map("n", "<leader>mf", function()
--         obsidian_utils.insert_obsidian_frontmatter()
--       end, { buffer = true, desc = "Insert Obsidian frontmatter" })
--
--       -- Folder-specific search functions
--       map("n", "<leader>osd", function()
--         vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "daily")
--       end, { buffer = true, desc = "Search daily notes" })
--
--       map("n", "<leader>osp", function()
--         vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "projects")
--       end, { buffer = true, desc = "Search project notes" })
--
--       map("n", "<leader>osm", function()
--         vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "meetings")
--       end, { buffer = true, desc = "Search meeting notes" })
--
--       map("n", "<leader>osl", function()
--         vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "learning")
--       end, { buffer = true, desc = "Search learning notes" })
--
--       map("n", "<leader>osi", function()
--         vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "ideas")
--       end, { buffer = true, desc = "Search idea notes" })
--
--       map("n", "<leader>oso", function()
--         vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "other")
--       end, { buffer = true, desc = "Search other notes" })
--
--       vim.notify("Obsidian mappings loaded for vault session", vim.log.levels.INFO)
--     else
--       print("Not in vault directory")
--     end
--   end,
-- })
--
-- -- Markdown specific obsidian mappings
-- vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
--   pattern = "*",
--   callback = function()
--     if is_in_obsidian_vault() and vim.bo.filetype == "markdown" then
--       vim.opt_local.conceallevel = 2
--
--       local obsidian_utils = utils.obsidian
--
--       map("n", "<leader>oT", "<cmd>ObsidianTOC<cr>", { buffer = true, desc = "Table of contents" })
--       map("n", "<leader>ox", "<cmd>ObsidianToggleCheckbox<cr>", { buffer = true, desc = "Toggle checkbox" })
--
--       map("n", "<leader>ol", obsidian_utils.insert_link, { buffer = true, desc = "Insert new Obsidian link" })
--       map("n", "<leader>of", obsidian_utils.follow_link, { buffer = true, desc = "Follow Obsidian link" })
--       map("n", "<leader>ob", obsidian_utils.back_link, { buffer = true, desc = "Show backlinks" })
--
--       map("n", "<leader>or", obsidian_utils.rename_note, { buffer = true, desc = "Rename current note" })
--       map("v", "<leader>oe", obsidian_utils.extract_note, { buffer = true, desc = "Extract selection to new note" })
--       map("n", "<leader>op", obsidian_utils.paste_image, { buffer = true, desc = "Paste image from clipboard" })
--       map("n", "<leader>oo", obsidian_utils.open_in_app, { buffer = true, desc = "Open current note in Obsidian app" })
--
--       map("n", "<leader>mf", function()
--         obsidian_utils.insert_obsidian_frontmatter()
--       end, { buffer = true, desc = "Insert Obsidian frontmatter" })
--     end
--   end,
-- })
