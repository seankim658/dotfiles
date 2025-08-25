local M = {}

M.obsidian_vaults = {
  main = "~/Documents/obsidian_vault/",
}

M.get_vault_path = function(vault_name)
  local path = M.obsidian_vaults[vault_name]
  if not path then
    return nil
  end
  return vim.fn.expand(path)
end

return M
