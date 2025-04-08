-- DEPRECATED
-- I no longer use obsidian

local M = {}

M.obsidian_vaults = {
  macos = "~/Documents/macos_vault/",
  linux = "~/Documents/linux_vault/",
}

M.get_vault_path = function(vault_name)
  local path = M.obsidian_vaults[vault_name]
  if not path then
    return nil
  end
  return vim.fn.expand(path)
end

return M
