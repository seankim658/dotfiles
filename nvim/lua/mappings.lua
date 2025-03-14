-- Loads NVChad's default keymappings first as a base.
require "nvchad.mappings"

-- My mappings.

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

-- Window resizing.
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

-- Close all buffers except current one
map("n", "<leader>bo", function()
  -- Store current buffer number
  local current_buf = vim.api.nvim_get_current_buf()

  -- Get all buffer numbers
  local buffers = vim.api.nvim_list_bufs()

  for _, buf in ipairs(buffers) do
    if buf ~= current_buf and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end

  vim.notify("Closed all buffers except current one", vim.log.levels.INFO)
end, { desc = "Close all buffers except currently selected" })

-- Close all buffers that aren't visible in any window
map("n", "<leader>bv", function()
  -- Get list of all buffers
  local buffers = vim.api.nvim_list_bufs()

  -- Get list of windows
  local windows = vim.api.nvim_list_wins()

  -- Create a set of visible buffers
  local visible_buffers = {}
  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    visible_buffers[buf] = true
  end

  local closed_count = 0
  for _, buf in ipairs(buffers) do
    if not visible_buffers[buf] and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, { force = false })
      closed_count = closed_count + 1
    end
  end

  vim.notify("Closed " .. closed_count .. " non-visible buffers", vim.log.levels.INFO)
end, { desc = "Close all non-visible buffers" })

-- Function to export diagnostics as markdown
local function export_diagnostics_as_markdown()
  -- Create a temporary file to hold the markdown
  local temp_file = vim.fn.tempname() .. ".md"
  local file = io.open(temp_file, "w")
  if not file then
    vim.notify("Failed to create temporary file", vim.log.levels.ERROR)
    return
  end

  -- Write markdown header
  file:write "# Project Diagnostics\n\n"
  file:write("Generated on: " .. os.date "%Y-%m-%d %H:%M:%S" .. "\n\n")

  -- Get all diagnostics from all buffers
  local diagnostics = {}
  local has_diagnostics = false
  local buf_lookup = {} -- Store bufnr for each filename

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local buf_diagnostics = vim.diagnostic.get(bufnr)
      if buf_diagnostics and #buf_diagnostics > 0 then
        has_diagnostics = true
        local filename = vim.api.nvim_buf_get_name(bufnr)
        filename = vim.fn.fnamemodify(filename, ":~:.")

        -- Store bufnr for this filename
        buf_lookup[filename] = bufnr

        if not diagnostics[filename] then
          diagnostics[filename] = {}
        end

        for _, diag in ipairs(buf_diagnostics) do
          table.insert(diagnostics[filename], {
            lnum = diag.lnum + 1, -- Convert to 1-based line number
            col = diag.col + 1, -- Convert to 1-based column
            message = diag.message,
            severity = diag.severity,
            source = diag.source or "unknown",
            code = diag.code,
          })
        end
      end
    end
  end

  if not has_diagnostics then
    file:write "## No diagnostics found\n\n"
    file:write "No diagnostic issues were found in the currently loaded buffers.\n"
    file:close()
    vim.cmd("split " .. temp_file)
    vim.notify("No diagnostics found", vim.log.levels.INFO)
    return
  end

  -- Sort filenames
  local filenames = {}
  for filename, _ in pairs(diagnostics) do
    table.insert(filenames, filename)
  end
  table.sort(filenames)

  -- Convert severity to string
  local severity_names = {
    [1] = "Error",
    [2] = "Warning",
    [3] = "Information",
    [4] = "Hint",
  }

  -- Write diagnostics by file
  for _, filename in ipairs(filenames) do
    file:write("## File: `" .. filename .. "`\n\n")

    local file_diagnostics = diagnostics[filename]
    table.sort(file_diagnostics, function(a, b)
      return a.lnum < b.lnum
    end)

    -- Get the buffer number for this filename
    local bufnr = buf_lookup[filename]

    for _, diag in ipairs(file_diagnostics) do
      local severity = severity_names[diag.severity] or "Unknown"
      local source_text = diag.source and (" from " .. diag.source) or ""
      local code_text = diag.code and (" [" .. diag.code .. "]") or ""

      file:write(
        "- **"
          .. severity
          .. "**"
          .. source_text
          .. code_text
          .. " at line "
          .. diag.lnum
          .. ", col "
          .. diag.col
          .. ":\n"
      )
      file:write("  ```\n  " .. diag.message:gsub("\n", "\n  ") .. "\n  ```\n\n")

      -- Fetch the line of code if possible
      if bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
        local line_content = vim.api.nvim_buf_get_lines(bufnr, diag.lnum - 1, diag.lnum, false)[1]
        if line_content then
          file:write("  ```\n  " .. line_content .. "\n  ```\n\n")
        end
      end
    end
  end

  file:close()

  -- Open the markdown file in a new buffer
  vim.cmd("split " .. temp_file)
  vim.notify("Exported diagnostics to " .. temp_file, vim.log.levels.INFO)
end

-- Add keybinding for the export function
map("n", "<leader>xm", function()
  export_diagnostics_as_markdown()
end, { desc = "Export diagnostics as markdown" })
