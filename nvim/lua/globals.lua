local M = {}

M.obsidian_vaults = {
  main = "~/Documents/obsidian_vault/",
}

M.get_vault_path = function(vault_name)
  local path = M.obsidian_vaults[vault_name]
  if not path then
    return nil
  end

  local expanded_path = vim.fn.expand(path)

  expanded_path = vim.fn.resolve(expanded_path)

  if not expanded_path:match "/$" then
    expanded_path = expanded_path .. "/"
  end

  return expanded_path
end

M.is_file_in_vault = function(file_path, vault_name)
  local vault_path = M.get_vault_path(vault_name)
  if not vault_path then
    return false
  end

  if not file_path or file_path == "" then
    return false
  end

  local normalized_file_path = vim.fn.resolve(vim.fn.expand(file_path))

  local stat = vim.loop.fs_stat(normalized_file_path)
  if stat and stat.type == "directory" then
    if not normalized_file_path:match "/$" then
      normalized_file_path = normalized_file_path .. "/"
    end
  end

  return normalized_file_path:find(vault_path, 1, true) == 1
end

return M
