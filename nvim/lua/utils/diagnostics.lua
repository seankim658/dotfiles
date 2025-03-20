local M = {}

M.export_as_markdown = function()
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

return M
