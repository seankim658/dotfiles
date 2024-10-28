local options = require("plugins.configs.treesitter")

options.indent = {
  enable = true,
  disable = {
    "python"
  }
}

options.highlight = {
  enable = true,
  disable = {
    "tsv",
    "csv"
  }
}

return options
