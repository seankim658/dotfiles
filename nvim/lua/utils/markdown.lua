local M = {}

M.insert_frontmatter = function()
  local frontmatter = [[---

tags:  
created:  

---
]]

  -- Get the total number of linse in the buffer
  local line_count = vim.api.nvim_buf_line_count(0)

  -- Check if the last line is empty
  local last_line = vim.api.nvim_buf_get_lines(0, line_count - 1, line_count, false)[1]
  local needs_blank_line = last_line ~= ""

  -- Insert blank line if needed, then the frontmatter
  if needs_blank_line then
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, { "", "" })
    vim.api.nvim_buf_set_lines(0, line_count + 2, line_count + 2, false, vim.split(frontmatter, "\n"))
    -- Move cursor after the frontmatter
    vim.api.nvim_win_set_cursor(0, { line_count + 2 + 5, 0 })
  else
    -- If last line is already blank, just insert another blank line and then the frontmatter
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, { "" })
    vim.api.nvim_buf_set_lines(0, line_count + 1, line_count + 1, false, vim.split(frontmatter, "\n"))
    -- Move cursor after the frontmatter
    vim.api.nvim_win_set_cursor(0, { line_count + 1 + 5, 0 })
  end

  vim.notify("Added frontmatter to the bottom of the file", vim.log.levels.INFO)
end

return M
