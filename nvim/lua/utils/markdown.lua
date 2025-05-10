local M = {}

local function title_case(str)
  str = string.gsub(str, "[-_]", " ")
  str = string.gsub(str, "(%a)([%w]*)", function(first, rest)
    return string.upper(first) .. string.lower(rest)
  end)

  return str
end

M.insert_frontmatter = function()
  local filename = vim.fn.expand "%:t:r"
  local title = title_case(filename)

  local datetime = os.date "%Y-%m-%d %H:%M:%S"

  local frontmatter = {
    "---",
    "> title: " .. title,
    ">",
    "> tags: ",
    ">",
    "> created: " .. datetime,
    "---",
  }

  -- Insert at the top of the file
  vim.api.nvim_buf_set_lines(0, 0, 0, false, frontmatter)

  -- Move cursor to the title line
  vim.api.nvim_win_set_cursor(0, { 4, 4 })

  vim.notify("Added frontmatter to the top of the file", vim.log.levels.INFO)
end

return M
