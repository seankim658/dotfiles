local lint = require "lint"

-- Helper function to find Python virtualenv
local function get_python_path(workspace)
  local util = require "lspconfig/util" -- Get LSP utils for path handling
  local path = util.path -- Get path utilities

  -- First check: Is there an active virtualenv?
  if vim.env.VIRTUAL_ENV then
    return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
  end

  -- Second check: Look for virtualenv in workspace directory
  for _, pattern in pairs { "*", ".*" } do
    local match = vim.fn.glob(path.join(workspace, pattern, "pyvenv.cfg"))
    if match ~= "" then
      return path.join(path.dirname(match), "bin", "python")
    end
  end

  -- Fallback: Use system Python
  return vim.fn.exepath "python3" or vim.fn.exepath "python" or "python"
end

-- Function to get mypy command from virtualenv
local function get_mypy_command()
  local python_path = get_python_path(vim.fn.getcwd()) -- Get Python path for current directory
  local mypy_path = vim.fn.fnamemodify(python_path, ":h") .. "/mypy" -- Convert Python path to mypy path

  -- Check if mypy exists in virtualenv
  if vim.fn.filereadable(mypy_path) == 1 then
    return mypy_path
  end
  return "mypy" -- Fallback to system mypy
end

-- Map file types to their linters
lint.linters_by_ft = {
  python = { "mypy", "ruff" },
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  typescriptreact = { "eslint_d" },
}

-- Configure mypy specifically
lint.linters.mypy.cmd = get_mypy_command() -- Use virtualenv mypy if available
lint.linters.mypy.args = {
  "--show-column-numbers", -- Show column numbers in output
  "--hide-error-context", -- Hide code context in errors
  "--no-error-summary", -- Don't show error summary
  -- "--no-pretty", -- Don't use pretty output formatting
}

-- Set up automatic linting
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint() -- Try to lint when:
    -- - File is saved (BufWritePost)
    -- - File is read (BufReadPost)
    -- - Leaving insert mode (InsertLeave)
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
      -- Try to get the cmd (some linters might define it dynamically)
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
