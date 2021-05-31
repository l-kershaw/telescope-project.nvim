local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local transform_mod = require('telescope.actions.mt').transform_mod

local project_actions = {}

local project_dirs_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-- Create a new project and add it to the list in the `project_dirs_file`
project_actions.add_project = function(prompt_bufnr)
  local git_root = vim.fn.systemlist("git -C " .. vim.loop.cwd() .. " rev-parse --show-toplevel")[
    1
  ]

  local project_directory = git_root
  if not git_root or string.starts(git_root,'fatal') then
    project_directory = vim.loop.cwd()
  end

  local project_title = project_directory:match("[^/]+$")
  local project_to_add = project_title .. "=" .. project_directory .. "\n"

  local file = assert(
    io.open(project_dirs_file, "a"),
    "No project file exists"
  )

  local project_already_added = false
  for line in io.lines(project_dirs_file) do
    local project_exists_check = line .. "\n" == project_to_add
    if project_exists_check then
      project_already_added = true
      print('This project already exists.')
      return
    end
  end

  if not project_already_added then
    io.output(file)
    io.write(project_to_add)
    print('project added: ' .. project_title)
  end
  io.close(file)
end

-- Rename the selected project within the `project_dirs_file`.
-- Uses a name provided by the user.
project_actions.rename_project = function(prompt_bufnr)
  local oldName = actions.get_selected_entry(prompt_bufnr).ordinal
  local newName = vim.fn.input('Rename ' ..oldName.. ' to: ', oldName)
  local newLines = ""
  for line in io.lines(project_dirs_file) do
    local title, path = line:match("^(.-)=(.-)$")
    if title ~= oldName then
      newLines = newLines .. title .. '=' .. path .. '\n'
    else
      newLines = newLines .. newName .. '=' .. actions.get_selected_entry(prompt_bufnr).value .. '\n'
    end
  end
  local file = assert(
    io.open(project_dirs_file, "w"),
    "No project file exists"
  )
  file:write(newLines)
  file:close()
  print('Project renamed: ' .. actions.get_selected_entry(prompt_bufnr).ordinal .. ' -> ' .. newName)
end

-- Delete the selected project from the `project_dirs_file`
project_actions.delete_project = function(prompt_bufnr)
  local newLines = ""
  for line in io.lines(project_dirs_file) do
    local title, path = line:match("^(.-)=(.-)$")
    if title ~= actions.get_selected_entry(prompt_bufnr).ordinal then
      newLines = newLines .. title .. '=' .. path .. "\n"
    end
  end
  local file = assert(
    io.open(project_dirs_file, "w"),
    "No project file exists"
  )
  file:write(newLines)
  file:close()
  print('Project deleted: ' .. actions.get_selected_entry(prompt_bufnr).ordinal)
end

-- Find files within the selected project using the
-- Telescope builtin `find_files`.
project_actions.find_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.find_files({cwd = dir})
end

-- Browse through files within the selected project using
-- the Telescope builtin `file_browser`.
project_actions.browse_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.file_browser({cwd = dir})
end

-- Search within files in the selected project using
-- the Telescope builtin `live_grep`.
project_actions.search_in_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.live_grep({cwd = dir})
end

-- Search the recently used files within the selected project
-- using the Telescope builtin `oldfiles`.
project_actions.recent_project_files = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions._close(prompt_bufnr, true)
  vim.fn.execute("cd " .. dir, "silent")
  builtin.oldfiles({cwd_only = true})
end

-- Change working directory to the selected project and close the picker.
project_actions.change_working_directory = function(prompt_bufnr)
  local dir = actions.get_selected_entry(prompt_bufnr).value
  actions.close(prompt_bufnr)
  vim.fn.execute("cd " .. dir, "silent")
end

project_actions = transform_mod(project_actions);
return project_actions
