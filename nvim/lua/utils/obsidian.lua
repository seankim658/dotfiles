local M = {}
local globals = require "globals"

local function ensure_vault_root()
  local vault_path = globals.get_vault_path "main"
  if vault_path == nil then
    return false
  end
  local current_dir = vim.fn.getcwd()

  local vault_path_no_slash = vault_path:gsub("/$", "")
  if not globals.is_file_in_vault(current_dir, "main") then
    vim.cmd("cd " .. vault_path_no_slash)
  end
end

local function get_subdirectories(path)
  local subdirs = {}
  local handle = vim.loop.fs_scandir(path)

  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end

      if type == "directory" and not name:match "^%." then
        table.insert(subdirs, name)
      end
    end
  end

  table.sort(subdirs)
  return subdirs
end

-- TODO : Should generalize this at some point, assuming telescope for now
local function pick_directory_with_telescope(base_folder, callback)
  local vault_path = globals.get_vault_path "main"
  local full_base_path = vault_path .. base_folder

  local subdirs = get_subdirectories(full_base_path)

  local options = {}

  table.insert(options, {
    display = "📁 " .. base_folder .. "/ (root)",
    value = base_folder,
    is_root = true,
  })

  for _, subdir in ipairs(subdirs) do
    table.insert(options, {
      display = "📁 " .. base_folder .. "/" .. subdir .. "/",
      value = base_folder .. "/" .. subdir,
      is_existing = true,
    })
  end

  table.insert(options, {
    display = "+ Create new subdirectory in " .. base_folder .. "/",
    value = "CREATE_NEW",
    is_create_new = true,
  })

  -- Using telescope
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  pickers
    .new({}, {
      prompt_title = "Select Directory for Note",
      finder = finders.new_table {
        results = options,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection.value.is_create_new then
            vim.ui.input({ prompt = "New subdirectory name: " }, function(new_subdir)
              if new_subdir and new_subdir ~= "" then
                local new_path = base_folder .. "/" .. new_subdir
                vim.fn.mkdir(vault_path .. new_path, "p")
                callback(new_path)
              end
            end)
          else
            callback(selection.value.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Function to create a new note with template
M.new_note = function()
  local folders = {
    "daily",
    "projects",
    "learning",
    "meetings",
    "ideas",
    "references",
    "templates",
    "other",
    ".",
  }

  -- Choose folder first
  vim.ui.select(folders, {
    prompt = "Choose folder: ",
    format_item = function(item)
      return item == "." and "Root directory" or item
    end,
  }, function(chosen_folder)
    if chosen_folder then
      vim.ui.input({ prompt = "Note title: " }, function(title)
        if title then
          ensure_vault_root()

          local full_path
          if chosen_folder == "." then
            full_path = title
          else
            full_path = chosen_folder .. "/" .. title
          end

          vim.cmd("ObsidianNew " .. full_path)
        end
      end)
    end
  end)
end

-- Function to pick template with telescope
local function pick_template_with_telescope(templates, callback)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  local template_options = {}
  for _, template in ipairs(templates) do
    table.insert(template_options, {
      display = "📄 " .. template .. ".md",
      value = template,
    })
  end

  pickers
    .new({}, {
      prompt_title = "Select Learning Template",
      finder = finders.new_table {
        results = template_options,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          callback(selection.value)
        end)
        return true
      end,
    })
    :find()
end

-- Second level templates
local learning_templates = { "learning", "lecture", "reading", "hci-522", "algo-401" }
local meeting_templates = { "meeting", "checa-meeting" }

-- Template based note creation
M.new_note_with_template = function()
  local note_types = {
    {
      name = "Daily",
      folder = "daily",
      template = "daily",
      use_telescope = false,
      filename_format = function()
        return os.date "%Y-%m-%d"
      end,
    },
    {
      name = "Project",
      folder = "projects",
      template = "project",
      use_telescope = true,
      filename_format = function(title)
        return title:gsub("%s+", "-"):lower()
      end,
    },
    {
      name = "Meeting",
      folder = "meetings",
      template = "meeting",
      use_telescope = true,
      use_template_selection = true,
      available_templates = meeting_templates,
      filename_format = function(title)
        return os.date "%Y-%m-%d" .. "-" .. title:gsub("%s+", "-"):lower()
      end,
    },
    {
      name = "Learning",
      folder = "learning",
      template = "learning",
      use_telescope = true,
      use_template_selection = true,
      available_templates = learning_templates,
      filename_format = function(title)
        return title:gsub("%s+", "-"):lower()
      end,
    },
    {
      name = "Idea",
      folder = "ideas",
      template = "idea",
      use_telescope = true,
      filename_format = function(title)
        return title:gsub("%s+", "-"):lower()
      end,
    },
    {
      name = "Other",
      folder = "other",
      template = "other",
      use_telescope = true,
      filename_format = function(title)
        return title:gsub("%s+", "-"):lower()
      end,
    },
    {
      name = "Quick Note (No Template)",
      folder = ".",
      template = nil,
      use_telescope = false,
      filename_format = function(title)
        return title:gsub("%s+", "-"):lower()
      end,
    },
  }

  vim.ui.select(note_types, {
    prompt = "What type of note? ",
    format_item = function(item)
      return item.name
    end,
  }, function(chosen_type)
    if chosen_type then
      vim.ui.input({ prompt = "Note title: " }, function(title)
        if title then
          ensure_vault_root()

          local filename = chosen_type.filename_format(title)
          local full_path

          if chosen_type.folder == "." then
            full_path = filename
          else
            full_path = chosen_type.folder .. "/" .. filename
          end

          if chosen_type.use_template_selection and chosen_type.available_templates then
            pick_template_with_telescope(chosen_type.available_templates, function(selected_template)
              vim.cmd("ObsidianNew " .. full_path)
              vim.defer_fn(function()
                vim.cmd("ObsidianTemplate " .. selected_template)
              end, 100)
            end)
          else
            if chosen_type.template then
              vim.cmd("ObsidianNew " .. full_path)
              -- Wait a moment for the file to be created, then apply template
              vim.defer_fn(function()
                vim.cmd("ObsidianTemplate " .. chosen_type.template)
              end, 100)
            else
              vim.cmd("ObsidianNew " .. full_path)
            end
          end
        end
      end)
    end
  end)
end

-- Quick folder-specific note creation functions
M.new_daily_note = function()
  ensure_vault_root()
  local filename = os.date "%Y-%m-%d"
  local full_path = "daily/" .. filename

  vim.cmd("ObsidianNew " .. full_path)
  vim.defer_fn(function()
    vim.cmd "ObsidianTemplate daily"
  end, 100)
end

M.new_project_note = function()
  pick_directory_with_telescope("projects", function(chosen_path)
    vim.ui.input({ prompt = "Project note title: " }, function(title)
      if title then
        ensure_vault_root()
        local filename = title:gsub("%s+", "-"):lower()
        local full_path = chosen_path .. "/" .. filename

        vim.cmd("ObsidianNew " .. full_path)
        vim.defer_fn(function()
          vim.cmd "ObsidianTemplate project"
        end, 100)
      end
    end)
  end)
end

M.new_meeting_note = function()
  pick_directory_with_telescope("meetings", function(chosen_path)
    vim.ui.input({ prompt = "Meeting note title: " }, function(title)
      if title then
        ensure_vault_root()
        local filename = os.date "%Y-%m-%d" .. "-" .. title:gsub("%s+", "-"):lower()
        local full_path = chosen_path .. "/" .. filename

        pick_template_with_telescope(meeting_templates, function(selected_template)
          vim.cmd("ObsidianNew " .. full_path)
          vim.defer_fn(function()
            vim.cmd("ObsidianTemplate " .. selected_template)
          end, 100)
        end)
      end
    end)
  end)
end

M.new_learning_note = function()
  pick_directory_with_telescope("learning", function(chosen_path)
    vim.ui.input({ prompt = "Learning note title: " }, function(title)
      if title then
        ensure_vault_root()
        local filename = title:gsub("%s+", "-"):lower()
        local full_path = chosen_path .. "/" .. filename

        pick_template_with_telescope(learning_templates, function(selected_template)
          vim.cmd("ObsidianNew " .. full_path)
          vim.defer_fn(function()
            vim.cmd("ObsidianTemplate " .. selected_template)
          end, 100)
        end)
      end
    end)
  end)
end

M.new_idea_note = function()
  pick_directory_with_telescope("ideas", function(chosen_path)
    vim.ui.input({ prompt = "Idea note title: " }, function(title)
      if title then
        ensure_vault_root()
        local filename = title:gsub("%s+", "-"):lower()
        local full_path = chosen_path .. "/" .. filename

        vim.cmd("ObsidianNew " .. full_path)
        vim.defer_fn(function()
          vim.cmd "ObsidianTemplate idea"
        end, 100)
      end
    end)
  end)
end

M.new_other_note = function()
  pick_directory_with_telescope("other", function(chosen_path)
    vim.ui.input({ prompt = "Other note title: " }, function(title)
      if title then
        ensure_vault_root()
        local filename = title:gsub("%s+", "-"):lower()
        local full_path = chosen_path .. "/" .. filename

        vim.cmd("ObsidianNew " .. full_path)
        vim.defer_fn(function()
          vim.cmd "ObsidianTemplate other"
        end, 100)
      end
    end)
  end)
end

-- Function to quickly search notes
M.search_notes = function()
  vim.cmd "ObsidianSearch"
end

-- Function to open daily note
M.open_daily_note = function()
  vim.cmd "ObsidianToday"
end

-- Function to open weekly note
M.open_weekly_note = function()
  vim.cmd "ObsidianDailies -7 7"
end

-- Function to follow link under cursor
M.follow_link = function()
  vim.cmd "ObsidianFollowLink"
end

-- Function to go back to previous note
M.back_link = function()
  vim.cmd "ObsidianBacklinks"
end

-- Function to open note in Obsidian app
M.open_in_app = function()
  vim.cmd "ObsidianOpen"
end

-- Function to insert a new link
M.insert_link = function()
  vim.ui.input({ prompt = "Link text: " }, function(text)
    if text then
      vim.cmd("ObsidianLinkNew " .. text)
    end
  end)
end

-- Function to rename current note
M.rename_note = function()
  vim.ui.input({ prompt = "New name: " }, function(name)
    if name then
      vim.cmd("ObsidianRename " .. name)
    end
  end)
end

-- Function to extract current selection into new note
M.extract_note = function()
  vim.ui.input({ prompt = "Note name: " }, function(name)
    if name then
      vim.cmd("ObsidianExtractNote " .. name)
    end
  end)
end

-- Function to paste image from clipboard
M.paste_image = function()
  vim.cmd "ObsidianPasteImg"
end

-- Custom frontmatter for Obsidian notes
M.insert_obsidian_frontmatter = function()
  local filename = vim.fn.expand "%:t:r"
  local datetime = os.date "%Y-%m-%d"

  local frontmatter = {
    "---",
    "title: " .. filename,
    "created: " .. datetime,
    "tags:",
    "  - ",
    "aliases:",
    "  - ",
    "---",
    "",
  }

  vim.api.nvim_buf_set_lines(0, 0, 0, false, frontmatter)
  vim.api.nvim_win_set_cursor(0, { 5, 4 }) -- Position cursor at tags
  vim.notify("Added Obsidian frontmatter", vim.log.levels.INFO)
end

return M
