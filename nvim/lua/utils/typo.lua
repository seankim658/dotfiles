local M = {}

M.swap_chars = function()
  -- Get cursor position
  local line = vim.fn.line "."
  local col = vim.fn.col "."

  -- Get the current line text
  local current_line = vim.api.nvim_get_current_line()
  local line_length = #current_line

  -- Check if we're at the end of the line
  if col >= line_length then
    vim.notify("Cannot swap: already at the end of the line", vim.log.levels.WARN)
    return
  end

  -- Extract the characters to swap
  local char1 = string.sub(current_line, col, col)
  local char2 = string.sub(current_line, col + 1, col + 1)

  -- Create the new line with swapped characters
  local new_line = string.sub(current_line, 1, col - 1) .. char2 .. char1 .. string.sub(current_line, col + 2)

  -- Replace the current line
  vim.api.nvim_set_current_line(new_line)

  -- Keep cursor position after the swapped characters
  vim.api.nvim_win_set_cursor(0, { line, col + 1 })

  vim.notify("Characters swapped: " .. char1 .. char2 .. " → " .. char2 .. char1, vim.log.levels.INFO)
end

return M
