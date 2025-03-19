local M = {}

-- Function to get and insert formatted timestamp
M.insert_timestamp = function()
  local now = os.time()

  -- Format timestamp according to timezone
  local timezone = os.getenv "TZ" or "EST"

  -- Format the day of week, date, and time
  local timestamp = os.date("%A, %d-%b-%y %I:%M:%S%p", now)

  -- Add the timezone
  timestamp = timestamp .. " " .. timezone

  -- Insert the timestamp at the cursor position
  vim.api.nvim_put({ timestamp }, "", true, true)
end

return M
