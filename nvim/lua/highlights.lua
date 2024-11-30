local M = {}

M.setup = function()
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
end

return M
