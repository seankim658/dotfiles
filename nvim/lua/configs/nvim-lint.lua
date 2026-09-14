local lint = require "lint"

-- Map file types to linters
lint.linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  typescriptreact = { "eslint_d" },
}

-- Automatic linting
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  callback = function()
    -- Lint when:
    --   - File is saved (BufWritePost)
    --   - File is read (BufReadPost)
    --   - Leaving insert mode (InsertLeave)
    require("lint").try_lint()
  end,
})

-- Command to show active linters for current buffer
vim.api.nvim_create_user_command("ShowLinters", function()
  local names = {}

  -- Get filetype of current buffer
  local ft = vim.bo.filetype

  -- Get configured linters for current filetype
  local linters = lint.linters_by_ft[ft]

  if not linters then
    print("No linters configured for filetype: " .. ft)
    return
  end

  -- Check each linter's availability
  for _, linter_name in ipairs(linters) do
    local linter = lint.linters[linter_name]
    if linter then
      local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
      table.insert(names, string.format("%s (%s)", linter_name, cmd or "cmd not found"))
    end
  end

  if #names > 0 then
    print("Active linters for " .. ft .. ": " .. table.concat(names, ", "))
  else
    print("No active linters found for filetype: " .. ft)
  end
end, {})
