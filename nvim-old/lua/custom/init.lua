vim.opt.relativenumber = true
vim.opt.colorcolumn = "150"
vim.api.nvim_set_keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=true<cr>",
  { silent = true, noremap = true })
vim.api.nvim_set_keymap("n", "<A-1>", "<C-w>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<A-2>", "<C-w>-", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<A-3>", "<C-w><", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<A-4>", "<C-w>>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<A-5>", "<C-w>=", { noremap = true, silent = true })
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("n", "d", "\"_d")
vim.keymap.set("v", "d", "\"_d")
vim.keymap.set("n", "c", "\"_c")
vim.keymap.set("v", "c", "\"_c")
vim.keymap.set("n", "x", "\"_x")
vim.keymap.set("n", "s", "\"_s")
vim.keymap.set("v", "s", "\"_s")
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false
  }
)
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { noremap = true, silent = true })
vim.cmd [[
  hi NvimTreeGitDeletedIcon guifg=#C74E39 gui=bold
  hi NvimTreeGitDirtyIcon guifg=#CE9178 gui=bold
  hi NvimTreeGitIgnoredIcon guifg=#A9A9A9 gui=bold
  hi NvimTreeGitMergeIcon guifg=#C586C0 gui=bold
  hi NvimTreeGitNewIcon guifg=#B5CEA8 gui=bold
  hi NvimTreeGitRenamedIcon guifg=#B5CEA8 gui=bold
  hi NvimTreeGitStagedIcon guifg=#569CD6 gui=bold
  hi NvimTreeModifiedFile guifg=#6A9955 gui=bold
]]
