local M = {}

-- Close all buffers except current one
M.close_other_buffers = function()
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
end

-- Close all buffers that aren't visible in any window
M.close_nonvisible_buffers = function()
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
end

return M
