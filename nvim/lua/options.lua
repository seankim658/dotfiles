require "nvchad.options"
local globals = require "globals"

local option = vim.o

option.relativenumber = true
option.colorcolumn = "150"

-- vim.diagnostic.config({virtual_text = false}) -- Disable diagnostic virtual text.

-- Obsidian autocmds - loaded early so VimEnter works
local function is_in_obsidian_vault()
  local cwd = vim.fn.getcwd()
  return globals.is_file_in_vault(cwd, "main")
end

-- Load obsidian mappings immediately if starting in vault directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if is_in_obsidian_vault() then
      -- Defer to ensure mappings module is loaded
      vim.defer_fn(function()
        local map = vim.keymap.set

        map("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", { desc = "Quick switch notes" })
        map("n", "<leader>ot", "<cmd>ObsidianTags<cr>", { desc = "Search Obsidian tags" })

        pcall(function()
          local utils = require "utils"
          local obsidian_utils = utils.obsidian

          map("n", "<leader>os", obsidian_utils.search_notes, { desc = "Search Obsidian notes" })
          map("n", "<leader>od", obsidian_utils.open_daily_note, { desc = "Open today's daily note" })

          -- map("n", "<leader>on", obsidian_utils.new_note, { desc = "Create new Obsidian note (choose folder)" })
          map("n", "<leader>ont", obsidian_utils.new_note_with_template, { desc = "Create new note with template" })
          map("n", "<leader>ond", obsidian_utils.new_daily_note, { desc = "Create new daily note" })
          map("n", "<leader>onp", obsidian_utils.new_project_note, { desc = "Create new project note" })
          map("n", "<leader>onm", obsidian_utils.new_meeting_note, { desc = "Create new meeting note" })
          map("n", "<leader>onl", obsidian_utils.new_learning_note, { desc = "Create new learning note" })
          map("n", "<leader>oni", obsidian_utils.new_idea_note, { desc = "Create new idea note" })
          map("n", "<leader>ono", obsidian_utils.new_other_note, { desc = "Create new other note" })

          -- Folder-specific search functions
          map("n", "<leader>osd", function()
            vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "daily")
          end, { desc = "Search daily notes" })

          map("n", "<leader>osp", function()
            vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "projects")
          end, { desc = "Search project notes" })

          map("n", "<leader>osm", function()
            vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "meetings")
          end, { desc = "Search meeting notes" })

          map("n", "<leader>osl", function()
            vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "learning")
          end, { desc = "Search learning notes" })

          map("n", "<leader>osi", function()
            vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "ideas")
          end, { desc = "Search idea notes" })

          map("n", "<leader>oso", function()
            vim.cmd("Telescope find_files cwd=" .. globals.get_vault_path "main" .. "other")
          end, { desc = "Search other notes" })
        end)
      end, 200)
    end
  end,
})

-- Markdown-specific obsidian features
vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
  pattern = "*.md",
  callback = function()
    if is_in_obsidian_vault() then
      vim.opt_local.conceallevel = 2

      vim.defer_fn(function()
        local map = vim.keymap.set

        map("n", "<leader>oT", "<cmd>ObsidianTOC<cr>", { buffer = true, desc = "Table of contents" })
        map("n", "<leader>ox", "<cmd>ObsidianToggleCheckbox<cr>", { buffer = true, desc = "Toggle checkbox" })
        map("n", "<leader>oo", "<cmd>ObsidianOpen<cr>", { buffer = true, desc = "Open current note in Obsidian app" })

        pcall(function()
          local utils = require "utils"
          local obsidian_utils = utils.obsidian

          -- Link operations
          map("n", "<leader>ol", obsidian_utils.insert_link, { buffer = true, desc = "Insert new Obsidian link" })
          map("n", "<leader>of", obsidian_utils.follow_link, { buffer = true, desc = "Follow Obsidian link" })
          map("n", "<leader>ob", obsidian_utils.back_link, { buffer = true, desc = "Show backlinks" })

          -- Note operations
          map("n", "<leader>or", obsidian_utils.rename_note, { buffer = true, desc = "Rename current note" })
          map("v", "<leader>oe", obsidian_utils.extract_note, { buffer = true, desc = "Extract selection to new note" })
          map("n", "<leader>op", obsidian_utils.paste_image, { buffer = true, desc = "Paste image from clipboard" })

          -- Obsidian frontmatter
          map("n", "<leader>mf", function()
            obsidian_utils.insert_obsidian_frontmatter()
          end, { buffer = true, desc = "Insert Obsidian frontmatter" })
        end)
      end, 100)
    end
  end,
})
