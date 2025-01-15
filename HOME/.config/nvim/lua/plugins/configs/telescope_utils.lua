local utils_window = require("core.utils_window")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

-- https://github.com/nvim-telescope/telescope.nvim/issues/2024
M.resume_with_cache = function()
  vim.g.last_search = vim.g.last_search or {}
  local status1, telescope = pcall(require, "telescope.builtin")
  local status2, telescope_state = pcall(require, "telescope.state")
  if status1 and status2 then
    if vim.g.last_search == nil then
      telescope.resume()
      local cached_pickers = telescope_state.get_global_key("cached_pickers") or {}
      vim.g.last_search = cached_pickers[1]
    else
      telescope.resume({ picker = vim.g.last_search })
    end
  end
end

-- when find_files or live_grep, the picker only shows files in the same folder
-- this function can let us select the folder as working direcotory
-- so that the picker can show all files or folders under that directory
-- reference https://github.com/nvim-telescope/telescope.nvim/issues/2201#issuecomment-1284691502
M.ts_select_dir_for_grep_or_find_files = function(picker_name)
  local select_cwd = function(_)
    -- this global variable is set in mappings
    -- to identify this is a "all" search - including .gitignore files
    -- or "normal" search - without .gitignore files
    local no_ignore = false
    if vim.g.find_files_type == "all" then
      no_ignore = true
    end

    local fb = require("telescope").extensions.file_browser
    -- this is live grep or find_files?
    -- local grep_or_find_files = require("telescope.builtin").live_grep
    local grep_or_find_files
    if picker_name == "find_files" then
      vim.g.telescope_picker_type = "find_files"
      grep_or_find_files = require("telescope.builtin").find_files
    elseif picker_name == "live_grep" then
      vim.g.telescope_picker_type = "live_grep_custom"
      grep_or_find_files = M.custom_rg
    else
      print("Unsupported picker name")
    end
    local current_line = action_state.get_current_line()

    -- this function is opening the default file_browser
    -- so set below to false
    vim.g.telescope_picker_temporary_cwd_from_file_browser = false

    fb.file_browser({
      files = false,
      depth = true,
      hidden = false,
      cwd = vim.fn.getcwd(),
      select_buffer = true,
      attach_mappings = function(_)
        require("telescope.actions").select_default:replace(function()
          local entry_path = action_state.get_selected_entry().Path
          local dir = entry_path:is_dir() and entry_path or entry_path:parent()
          local relative = dir:make_relative(vim.fn.getcwd())
          local absolute = dir:absolute()
          grep_or_find_files({
            results_title = relative .. "/",
            cwd = absolute,
            default_text = current_line,
            no_ignore = no_ignore,
            follow = true,
            attach_mappings = function(_, map)
              map("n", "W", function()
                M.set_temporary_cwd_from_file_browser("live_grep_custom")
              end)
              return true
            end,
          })
        end)
        return true
      end,
    })
  end
  return select_cwd
end

M.select_window_to_open = function(prompt_bufnr)
  local entry = require("telescope.actions.state").get_selected_entry(prompt_bufnr)

  vim.g.pick_win_id_is_telescope_picker = true

  -- new file
  if type(entry[1]) == "string" and entry.lnum == nil and entry.col == nil and getmetatable(entry) == nil then
    utils_window.open(entry[1], 0, 0)
    -- oldfiles and find_files
  elseif
      type(entry[1]) == "string"
      and entry.lnum == nil
      and entry.col == nil
      and entry.index ~= nil
      and entry.cwd ~= nil
  then
    local filename = entry[1]
    -- relative path
    if filename:sub(1, 1) ~= "/" and not filename:match("^[a-zA-Z]:\\") then
      local cwd = getmetatable(entry).cwd
      filename = cwd .. "/" .. filename
    end

    utils_window.open(filename, 1, 0)
    -- live grep
  elseif
      type(entry[1]) == "string"
      and string.match(entry[1], ":") == ":"
      and entry.lnum ~= nil
      and entry.col ~= nil
      and getmetatable(entry) ~= nil
  then
    local end_of_file_name = string.find(entry[1], ":")
    local file_name = string.sub(entry[1], 1, end_of_file_name - 1)
    local cwd = getmetatable(entry).cwd
    utils_window.open(cwd .. "/" .. file_name, entry.lnum, entry.col - 1)
    -- not a new file i.e. reference, etc.
  elseif entry.value.filename ~= nil and entry.value.lnum ~= nil and entry.value.col ~= nil then
    utils_window.open(entry.value.filename, entry.value.lnum, entry.value.col - 1)
    -- buffer
  elseif entry.filename ~= nil and entry.lnum ~= nil then
    utils_window.open(entry.filename, entry.lnum, 0)
    -- git status
  elseif type(entry[1]) ~= "string" and entry.path ~= nil then
    utils_window.open(entry.path, 0, 0)
  else
    print("invalid")
  end

  vim.g.pick_win_id_is_telescope_picker = false -- reset
end

M.rg_args = {
  "--follow",
  "--color=never",
  "--smart-case",
  "--no-heading",
  "--with-filename",
  "--line-number",
  "--column",
  "--auto-hybrid-regex",
}

-- able to put rg's argument after the search pattern followed by two spaces
-- in the Telescope prompt, check `rg --help` or `man rg` for more information
-- reference: https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/lua/tj/telescope/custom/multi_rg.lua
M.custom_rg = function(opts)
  local conf = require("telescope.config")
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local pickers = require("telescope.pickers")
  local flatten = vim.tbl_flatten

  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
  if opts.search_dirs then
    for i, path in ipairs(opts.search_dirs) do
      opts.search_dirs[i] = vim.fn.expand(path)
    end
  end

  vim.g.telescope_picker_type = "live_grep_custom"

  local custom_grep = finders.new_async_job({
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      local prompt_split = vim.split(prompt, "  ")

      local args = { "rg" }
      table.insert(args, M.rg_args)

      if prompt_split[1] then
        table.insert(args, "-e")
        table.insert(args, prompt_split[1])
      end

      if prompt_split[2] then
        local prompt_split2_split = vim.split(prompt_split[2], " ")
        table.insert(args, prompt_split2_split)
      end

      return flatten({ args, opts.search_dirs })
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })

  local prompt_title = "Live Grep (custom)"
  if opts.cwd and not opts.search_dirs then
    prompt_title = prompt_title .. " in " .. vim.fn.fnamemodify(opts.cwd, ":p")
  elseif opts.search_dirs then
    prompt_title = prompt_title .. " in nested search"
  end

  pickers
      .new(opts, {
        debounce = 100,
        prompt_title = prompt_title,
        finder = custom_grep,
        previewer = conf.values.grep_previewer(opts),
        sorter = require("telescope.sorters").empty(),
        attach_mappings = function(_, map)
          map("i", "<C-f>", M.ts_select_dir_for_grep_or_find_files("live_grep"))
          map("n", "<C-f>", M.ts_select_dir_for_grep_or_find_files("live_grep"))
          map("n", "W", M.set_temporary_cwd_from_file_browser("live_grep_custom"))
          map("n", "<A-e>", M.open_telescope_file_in_tab(true))
          map("n", "<C-g>", M.nested_grep())
          map("n", "<A-y>", M.copy_absolute_file_path_in_picker())
          map("n", "\\.", function(prompt_bufnr)
            -- search for ignore files
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local prompt = current_picker:_get_prompt()
            local spaces = (string.sub(prompt, -2) == "  " and "") or "  "
            local new_prompt = prompt .. spaces .. "-uu"
            current_picker:set_prompt(new_prompt)
          end)
          map("n", "\\i", function(prompt_bufnr)
            -- append --iglob to search for certain directories non case sensitively
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local prompt = current_picker:_get_prompt()
            local spaces = (string.sub(prompt, -2) == "  " and "") or "  "
            local new_prompt = prompt .. spaces .. "--iglob"
            current_picker:set_prompt(new_prompt)
          end)
          map("n", "\\C", function(prompt_bufnr)
            -- append --case-sensitive to search case sensitively
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local prompt = current_picker:_get_prompt()
            local spaces = (string.sub(prompt, -2) == "  " and "") or "  "
            local new_prompt = prompt .. spaces .. "--case-sensitive"
            current_picker:set_prompt(new_prompt)
          end)
          return true
        end,
      })
      :find()
end

-- Function to delete the current buffer and prompt for the next buffer using Telescope
M.delete_and_select_buffer = function()
  local buffer_utils = require("plugins.configs.buffer_utils")
  local current_bufnr = vim.fn.bufnr("%")

  -- Get a list of buffer names before deletion
  local buffer_names_before = vim.fn.getbufinfo({ buflisted = 1 })
  local buffer_numbers_before = {}
  for _, buf in ipairs(buffer_names_before) do
    table.insert(buffer_numbers_before, buf.bufnr)
  end

  local num_buffers = vim.fn.bufnr("$")
  if num_buffers > 1 or vim.fn.buflisted(current_bufnr) == 0 then
    -- Delete the current buffer
    local deleted = buffer_utils.force_delete_buffer_create_new()
    if not deleted then
      return
    end

    -- Get a list of buffer names after deletion
    local buffer_names_after = vim.fn.getbufinfo({ buflisted = 1 })
    local buffer_numbers_after = {}
    for _, buf in ipairs(buffer_names_after) do
      table.insert(buffer_numbers_after, buf.bufnr)
    end

    -- Find the buffer that is still open after deletion
    local next_bufnr
    for _, bufnr in ipairs(buffer_numbers_before) do
      if not vim.tbl_contains(buffer_numbers_after, bufnr) then
        next_bufnr = bufnr
        break
      end
    end

    -- Open the next buffer using Telescope
    if next_bufnr then
      require("telescope.builtin").buffers({
        cwd_only = true,
        attach_mappings = function(_, map)
          map("i", "<CR>", function()
            vim.api.nvim_command("buffer " .. next_bufnr)
            require("telescope.actions").close()
          end)
          map("n", "q", function() -- not selecting buffer, just close the window
            vim.cmd("q!")     -- close the telescope picker
            vim.cmd("wincmd c") -- close the window
          end)
          return true
        end,
      })
    end
  else
    -- If it's the last buffer, create a new blank buffer
    vim.cmd("enew")

    -- Delete the original buffer without closing the window
    buffer_utils.force_delete_buffer_create_new()
  end
end

-- Function to delete the current buffer and prompt for the oldfiles using Telescope
M.delete_and_select_old_buffer = function()
  local buffer_utils = require("plugins.configs.buffer_utils")
  local current_bufnr = vim.fn.bufnr("%")

  -- Get a list of buffer names before deletion
  local buffer_names_before = vim.fn.getbufinfo({ buflisted = 1 })
  local buffer_numbers_before = {}
  for _, buf in ipairs(buffer_names_before) do
    table.insert(buffer_numbers_before, buf.bufnr)
  end

  local num_buffers = vim.fn.bufnr("$")
  if num_buffers > 1 or vim.fn.buflisted(current_bufnr) == 0 then
    -- Delete the current buffer
    local deleted = buffer_utils.force_delete_buffer_create_new()
    if not deleted then
      return
    end

    -- Open oldfiles
    -- vim.cmd("Telescope oldfiles ignore_current_buffer=true cwd_only=true")
    require("telescope.builtin").oldfiles({
      cwd_only = true,
      ignore_current_buffer = true,
      attach_mappings = function(_, map)
        map("n", "q", function() -- not selecting old file, just close the window
          pcall(function()
            vim.cmd("q!")    -- close the telescope picker
            vim.cmd("wincmd c") -- close the window
          end)
        end)
        return true
      end,
    })
  else
    -- If it's the last buffer, create a new blank buffer
    vim.cmd("enew")

    -- Delete the original buffer without closing the window
    buffer_utils.force_delete_buffer_create_new()
  end
end

-- Functions to open lsp using Telescope, handle special case for Omnisharp  -----
M.open_lsp_definitions_conditional = function(opts)
  if vim.fn.expand("%:e") == "cs" then
    require("omnisharp_extended").telescope_lsp_definitions(opts)
    return
  end

  local open_telescope_picker = function()
    require("telescope.builtin").lsp_definitions(opts)
  end
  require("plugins.configs.lsp_utils").go_to("definition", open_telescope_picker)
end

M.open_lsp_references_conditional = function(opts)
  if vim.fn.expand("%:e") == "cs" then
    require("omnisharp_extended").telescope_lsp_references(opts)
    return
  end

  local open_telescope_picker = function()
    require("telescope.builtin").lsp_references(opts)
  end
  require("plugins.configs.lsp_utils").go_to("references", open_telescope_picker)
end

M.open_lsp_type_definition_conditional = function(opts)
  if vim.fn.expand("%:e") == "cs" then
    require("omnisharp_extended").telescope_lsp_type_definition(opts)
    return
  end

  local open_telescope_picker = function()
    require("telescope.builtin").lsp_type_definitions(opts)
  end
  require("plugins.configs.lsp_utils").go_to("typeDefinition", open_telescope_picker)
end

M.open_lsp_implementation_conditional = function(opts)
  if vim.fn.expand("%:e") == "cs" then
    require("omnisharp_extended").telescope_lsp_implementation(opts)
    return
  end

  local open_telescope_picker = function()
    require("telescope.builtin").lsp_implementations(opts)
  end
  require("plugins.configs.lsp_utils").go_to("implementation", open_telescope_picker)
end

M.open_lsp_incoming_calls_conditional = function(opts)
  require("telescope.builtin").lsp_incoming_calls(opts)
end

M.open_lsp_outgoing_calls_conditional = function(opts)
  require("telescope.builtin").lsp_outgoing_calls(opts)
end
-- ----------------------------------------------------------------------------

-- Function to open new split and prompt for the find_files using Telescope
M.open_new_split_and_select_buffer = function(split_type)
  -- Split type
  if split_type == "vertical" then
    vim.cmd("vnew")
  else
    vim.cmd("new")
  end
  local buf_nr = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf_nr })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf_nr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf_nr })
  vim.g.new_split_blank_buffer = vim.api.nvim_get_current_buf()

  -- Open find files
  vim.cmd("let g:find_files_type='normal'")
  vim.g.telescope_picker_type = "find_files"
  require("telescope.builtin").find_files({
    follow = true,
    attach_mappings = function(_, map)
      map("n", "q", function() -- not selecting file, just close the window
        pcall(function()
          vim.cmd("q!")     -- close the telescope picker
          vim.cmd("wincmd c") -- close the window
          vim.cmd("bdelete! " .. buf_nr)
        end)
      end)
      return true
    end,
  })
end

M.open_new_tab_and_select_buffer = function()
  vim.cmd("tabnew")
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = 0 })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = 0 })
  vim.api.nvim_set_option_value("swapfile", false, { buf = 0 })

  -- Open find files
  vim.cmd("let g:find_files_type='normal'")
  vim.g.telescope_picker_type = "find_files"
  require("telescope.builtin").find_files({
    follow = true,
    attach_mappings = function(_, map)
      map("n", "q", function() -- not selecting file, just close the window
        pcall(function()
          vim.cmd("q!")     -- close the telescope picker
          vim.cmd("tabclose") -- close the tab
        end)
      end)
      return true
    end,
  })
end

-- Don't preview binary file
-- https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#dont-preview-binaries
M.custom_previewer = function()
  local previewers = require("telescope.previewers")
  local Job = require("plenary.job")
  local new_maker = function(filepath, bufnr, opts)
    filepath = vim.fn.expand(filepath)
    Job:new({
      command = "file",
      args = { "-b", filepath },
      on_exit = function(j1)
        -- don't preview very large text files with very long lines (65536)
        local text = j1:result()[1]
        if text:match("with very long lines (65536)") or text:match("with no line terminators") then
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "TEXT FILE WITH LONG LINES (65536)" })
          end)
          -- don't preview minified file
        elseif filepath:match("%.min%.") then
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "MINIFIED FILE" })
          end)
        else
          Job:new({
            command = "file",
            args = { "--mime-type", "-b", filepath },
            on_exit = function(j2)
              local binary_mime_patterns = {
                "application/octet-stream",
                "image/",
                "video/",
                "audio/",
                "application/zip",
                "application/x-executable",
                "application/x-pie-executable",
                "application/vnd.microsoft.portable-executable",
              }

              -- don't preview binary file
              for _, pattern in ipairs(binary_mime_patterns) do
                if j2:result()[1]:match(pattern) then
                  vim.schedule(function()
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "BINARY" })
                  end)
                  break
                end
              end

              previewers.buffer_previewer_maker(filepath, bufnr, opts)
            end,
          }):start()
        end
      end,
    }):sync()
  end
  return new_maker
end

M.force_delete_buffer = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local selected_entry = action_state.get_selected_entry()

  if selected_entry then
    vim.api.nvim_buf_delete(selected_entry.bufnr, { force = true })
    current_picker:refresh(current_picker.finder, { reset_prompt = true })
    vim.schedule(function()
      actions._close(prompt_bufnr, true)  -- Close the current Telescope window
      require("telescope.builtin").buffers() -- Reopen the buffer picker
    end)
  end
end

-- Say i am opening live_grep or find_files in a cwd called A, i want to search files
-- in another directory B, i call this function to temporarily select another cwd to
-- B, to search the files I want in B, and then open it.
M.set_temporary_cwd_from_file_browser = function(picker_name, path)
  return function(prompt_bufnr)
    -- Open the file_browser picker
    local fb = require("telescope").extensions.file_browser
    -- below global variable is set because of this scenario:
    -- 1. do global grep
    -- 2. W to open this temporary cwd file browser
    -- 3. g<Space> to go to other direcotory
    -- 4. should go back to this temporary cwd file browser instead of normal file
    -- browser
    vim.g.telescope_picker_temporary_cwd_from_file_browser = true
    vim.g.telescope_picker_type = picker_name

    -- record what has been inserted, to be shown on the second stage picker after
    -- temporary cwd selected
    local current_line = action_state.get_current_line()

    local select_tmp_cwd = function()
      local selection = action_state.get_selected_entry()
      local selected_path = selection.path

      if vim.fn.isdirectory(selected_path) == 1 then
        -- Replace default action to open picker with new cwd
        actions.select_default:replace(function()
          -- Open the specified picker with the selected cwd
          if picker_name == "find_files" then
            if vim.g.find_files_type == "all" then
              builtin.find_files({
                prompt_title = "Find All Files in " .. selected_path,
                cwd = selected_path,
                follow = true,
                no_ignore = true,
                hidden = true,
                default_text = current_line,
              })
            else
              builtin.find_files({
                prompt_title = "Find Files in " .. selected_path,
                cwd = selected_path,
                follow = true,
                default_text = current_line,
              })
            end
          elseif picker_name == "live_grep" then
            builtin.live_grep({ cwd = selected_path, default_text = current_line })
          elseif picker_name == "buffers" then
            builtin.buffers({ cwd = selected_path, default_text = current_line })
          elseif picker_name == "live_grep_custom" then
            M.custom_rg({
              cwd = selected_path,
              default_text = current_line,
            })
            vim.g.temp_cwd = selected_path
          elseif picker_name == "oldfiles" then
            builtin.oldfiles({ cwd = selected_path, default_text = current_line })
          elseif picker_name == "grep_string" then
            builtin.grep_string({ cwd = selected_path, default_text = current_line })
          elseif picker_name == "grep_string_custom" then
            M.grep_string_custom({
              cwd = selected_path,
              search = vim.g.cwd_grep_string_search,
              default_text = current_line,
            })
            -- set these global variable back to nil after done, so that it wouldn't
            -- have side effect in next grep_string_custom
            -- vim.g.cwd_grep_string_search = nil
            -- vim.g.cwd_grep_string_word = nil
          else
            print("Unsupported picker name")
          end
        end)

        -- Trigger the replaced action
        actions.select_default(prompt_bufnr)
      else
        print("Selected item is not a directory")
      end
    end

    fb.file_browser({
      path = path,
      prompt_title = "Select temporary cwd",
      select_buffer = true,
      attach_mappings = function(_, map)
        -- Replace the default select action with custom behavior
        map("i", "<A-CR>", select_tmp_cwd)
        map("n", "<A-CR>", select_tmp_cwd)
        return true
      end,
    })
  end
end

-- Open multiple files at once
-- https://github.com/nvim-telescope/telescope.nvim/issues/1048#issuecomment-993956937
M.open_multiple_files_in_find_files_picker = function(prompt_bufnr, open_cmd)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  -- Telescope picker could be not file selection, like tab switcher, workdir, etc.
  -- that's why i need this condition
  local is_files_condition = (entry.lstat and not entry.is_dir) or entry.filename
  if is_files_condition then
    local num_selections = #picker:get_multi_selection()
    if not num_selections or num_selections <= 1 then
      actions.add_selection(prompt_bufnr)
    end
    actions.send_selected_to_qflist(prompt_bufnr)
    if open_cmd == "tabe" then
      vim.cmd("tabnew")
    elseif open_cmd == "vsplit" then
      vim.cmd("vnew")
    elseif open_cmd == "split" then
      vim.cmd("new")
    end
    vim.cmd("cfdo " .. open_cmd)
    if open_cmd == "tabe" then
      vim.cmd("tabclose")
    elseif open_cmd == "vsplit" or open_cmd == "split" then
      vim.cmd("wincmd q")
    end
    if vim.g.new_split_blank_buffer ~= nil then
      pcall(function()
        vim.cmd("bdelete! " .. vim.g.new_split_blank_buffer)
      end)
      vim.g.new_split_blank_buffer = nil
    end
  else
    require("telescope.actions").select_default(prompt_bufnr)
  end
end

-- Open multiple files at once, this function is the modification of the open_multiple_files_in_find_files_picker,
-- if new tabs were selected, then set their cwd accordingly
M.open_multiple_files_in_find_files_picker_and_set_cwd = function(prompt_bufnr, open_cmd)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local num_selections = #picker:get_multi_selection()
  if not num_selections or num_selections <= 1 then
    actions.add_selection(prompt_bufnr)
  end
  actions.send_selected_to_qflist(prompt_bufnr)
  -- do open_cmd for each quickfix list item
  for _, buffer in ipairs(vim.fn.getqflist()) do
    local buffer_name = vim.api.nvim_buf_get_name(buffer.bufnr)
    if open_cmd == "tabe" then
      if vim.g.TabAutoCwd == "1" then
        vim.g.new_tab_buf_cwd = vim.fn.fnamemodify(buffer_name, ":p:h")
      end
      vim.cmd("tabnew " .. buffer_name)
    elseif open_cmd == "vsplit" then
      vim.cmd("vsplit " .. buffer_name)
    elseif open_cmd == "split" then
      vim.cmd("split " .. buffer_name)
    end
  end
end

M.open_file_in_new_tab_and_set_cwd = function(prompt_bufnr)
  local selection = require("telescope.actions.state").get_selected_entry()
  if not selection then
    require("telescope.actions").select_tab(prompt_bufnr)
    return
  end

  local parent_dir = ""

  local selection_metatable = getmetatable(selection)
  if selection_metatable ~= nil and selection_metatable.cwd ~= nil then
    parent_dir = selection_metatable.cwd
  elseif type(selection.value) == "string" then
    parent_dir = vim.fn.fnamemodify(selection.value, ":p:h")
  elseif selection.filename then
    parent_dir = vim.fn.fnamemodify(selection.filename, ":p:h")
  elseif selection.bufnr then
    local bufnr = selection.bufnr
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    parent_dir = vim.fn.fnamemodify(bufname, ":p:h")
  end

  vim.g.new_tab_buf_cwd = parent_dir
  require("telescope.actions").select_tab(prompt_bufnr)
end

M.go_to_directory = function(callback)
  return function(prompt_bufnr)
    local current_line = action_state.get_current_line()
    -- Prompt for the path input
    local input = vim.fn.input({
      prompt = "Enter absolute path: ",
      completion = "file",
    })
    if input then
      local expanded_input = vim.fn.expand(input) -- to handle something like "~"
      if vim.fn.isdirectory(expanded_input) == 1 then
        callback(input, prompt_bufnr, current_line)
      else
        print("Not directory entered")
      end
    end
  end
end

-- Execute shell command
M.exec_shell_command = function()
  return function(prompt_bufnr)
    local input_buffer = ""
    local cursor_position = 0
    -- Function to handle key inputs
    local function handle_key(key, replaced_string)
      if key == 9 then
        -- Handle <Tab>: `.` (not escaped) with the desired string
        input_buffer = input_buffer:gsub("([^\\])%.", "%1" .. replaced_string)
        vim.api.nvim_echo({ { "> ", "None" }, { input_buffer, "String" } }, false, {})
      elseif key == 8 or key == 127 then
        -- Handle <C-h> and DEL: remove last character
        if #input_buffer > 0 and cursor_position > 0 then
          input_buffer = input_buffer:sub(1, cursor_position - 1) .. input_buffer:sub(cursor_position + 1)
          cursor_position = cursor_position - 1
        end
        vim.api.nvim_echo({ { "> ", "None" }, { input_buffer, "String" } }, false, {})
      elseif key == 13 or key == 10 then
        -- Enter pressed: finish input
        -- Append the result to the shell command
        local command = string.format("sh -c ' %s'", input_buffer)
        os.execute(command)
        return false     -- Exit input loop
      elseif key == 68 then -- Left arrow (key code for left arrow key)
        -- Move cursor left
        if cursor_position > 0 then
          cursor_position = cursor_position - 1
        end
      elseif key == 67 then -- Right arrow (key code for right arrow key)
        -- Move cursor right
        if cursor_position < #input_buffer then
          cursor_position = cursor_position + 1
        end
      else
        pcall(function()
          -- Append normal character
          local char = string.char(key)
          input_buffer = input_buffer:sub(1, cursor_position) .. char .. input_buffer:sub(cursor_position + 1)
          cursor_position = cursor_position + 1
          vim.api.nvim_echo({ { "> ", "None" }, { input_buffer, "String" } }, false, {})
        end)
      end
      return true -- Continue input loop
    end

    local filename = action_state.get_selected_entry().value

    vim.api.nvim_echo({ { "> ", "None" }, { input_buffer, "String" } }, false, {})

    pcall(function()
      while true do
        local key = vim.fn.getchar() -- Get key as a integer keycode
        -- If `.` followed by <Tab>, expand the `.` to the current selected file name.
        if not handle_key(key, filename) then
          break
        end
      end
    end)
  end
end

M.open_toggleterm_and_send_selection_parent_path_to_toggleterm = function()
  return function(prompt_bufnr)
    local cwd = vim.fn.fnamemodify(action_state.get_selected_entry().value, ":p:h")
    if vim.fn.isdirectory(cwd) == 1 then
      -- Close the current picker
      require("telescope.actions").close(prompt_bufnr)
      pcall(function()
        require("plugins.configs.toggleterm_utils").toggle_term("horizontal", true, cwd)
      end)
    else
      print("Not directory")
    end
  end
end

-- This is partially (most) copied from Telescope's grep_string function
-- The reason to have this function is, say scenario:
-- I am currently in directory A, i want to grep string for another directory B.
-- 1. grep_string on any word
-- 2. W to change to another temporary cwd
-- 3. select the temporary cwd B
-- 4. continue to grep string in directory B
--
-- If i use original Telescope grep_string, i wouldn't know the text being grep-ed
-- after switched to the temporary cwd picker, so in this function i will need to set
-- the global variable vim.g.cwd_grep_string_search to the original searched text.
M.grep_string_custom = function(opts, mode)
  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local pickers = require("telescope.pickers")
  local utils = require("telescope.utils")
  local filter = vim.tbl_filter
  local Path = require("plenary.path")
  local conf = require("telescope.config").values

  local has_rg_program = function(picker_name, program)
    if vim.fn.executable(program) == 1 then
      return true
    end

    utils.notify(picker_name, {
      msg = string.format(
        "'ripgrep', or similar alternative, is a required dependency for the %s picker. "
        .. "Visit https://github.com/BurntSushi/ripgrep#installation for installation instructions.",
        picker_name
      ),
      level = "ERROR",
    })
    return false
  end

  local escape_chars = function(string)
    return string.gsub(string, "[%(|%)|\\|%[|%]|%-|%{%}|%?|%+|%*|%^|%$|%.]", {
      ["\\"] = "\\\\",
      ["-"] = "\\-",
      ["("] = "\\(",
      [")"] = "\\)",
      ["["] = "\\[",
      ["]"] = "\\]",
      ["{"] = "\\{",
      ["}"] = "\\}",
      ["?"] = "\\?",
      ["+"] = "\\+",
      ["*"] = "\\*",
      ["^"] = "\\^",
      ["$"] = "\\$",
      ["."] = "\\.",
    })
  end

  local opts_contain_invert = function(args)
    local invert = false
    local files_with_matches = false

    for _, v in ipairs(args) do
      if v == "--invert-match" then
        invert = true
      elseif v == "--files-with-matches" or v == "--files-without-match" then
        files_with_matches = true
      end

      if #v >= 2 and v:sub(1, 1) == "-" and v:sub(2, 2) ~= "-" then
        local non_option = false
        for i = 2, #v do
          local vi = v:sub(i, i)
          if vi == "=" then -- ignore option -g=xxx
            break
          elseif vi == "g" or vi == "f" or vi == "m" or vi == "e" or vi == "r" or vi == "t" or vi == "T" then
            non_option = true
          elseif non_option == false and vi == "v" then
            invert = true
          elseif non_option == false and vi == "l" then
            files_with_matches = true
          end
        end
      end
    end
    return invert, files_with_matches
  end

  local get_open_filelist = function(grep_open_files, cwd)
    if not grep_open_files then
      return nil
    end

    local bufnrs = filter(function(b)
      if 1 ~= vim.fn.buflisted(b) then
        return false
      end
      return true
    end, vim.api.nvim_list_bufs())
    if not next(bufnrs) then
      return
    end

    local filelist = {}
    for _, bufnr in ipairs(bufnrs) do
      local file = vim.api.nvim_buf_get_name(bufnr)
      table.insert(filelist, Path:new(file):make_relative(cwd))
    end
    return filelist
  end

  local vimgrep_arguments = vim.F.if_nil(opts.vimgrep_arguments, conf.vimgrep_arguments)
  if not has_rg_program("grep_string", vimgrep_arguments[1]) then
    return
  end
  local word
  local visual = mode == "v"

  -- ----------------------------------------------------------------------------
  -- Should work in visual mode
  -- ----------------------------------------------------------------------------
  if visual == true then
    -- local saved_reg = vim.fn.getreg("v")
    -- vim.cmd([[noautocmd sil norm! "vy]])
    -- local sele = vim.fn.getreg("v")
    -- vim.fn.setreg("v", saved_reg)
    local sele = require("core.utils").get_last_visual_selection()
    word = vim.F.if_nil(opts.search, sele)
  else
    -- ----------------------------------------------------------------------------
    -- if vim.g.cwd_grep_string_word already has content, just use it.
    -- ----------------------------------------------------------------------------
    if vim.g.cwd_grep_string_word == nil then
      word = vim.F.if_nil(opts.search, vim.fn.expand("<cword>"))
    else
      word = vim.g.cwd_grep_string_word
    end
  end
  local search = opts.use_regex and word or escape_chars(word)

  local additional_args = {}
  if opts.additional_args ~= nil then
    if type(opts.additional_args) == "function" then
      additional_args = opts.additional_args(opts)
    elseif type(opts.additional_args) == "table" then
      additional_args = opts.additional_args
    end
  end

  if opts.file_encoding then
    additional_args[#additional_args + 1] = "--encoding=" .. opts.file_encoding
  end

  if search == "" then
    search = { "-v", "--", "^[[:space:]]*$" }
  else
    search = { "--", search }
  end

  local args
  if visual == true then
    args = utils.flatten({
      vimgrep_arguments,
      additional_args,
      search,
    })
  else
    args = utils.flatten({
      vimgrep_arguments,
      additional_args,
      opts.word_match,
      search,
    })
  end

  opts.__inverted, opts.__matches = opts_contain_invert(args)

  if opts.grep_open_files then
    for _, file in ipairs(get_open_filelist(opts.grep_open_files, opts.cwd)) do
      table.insert(args, file)
    end
  elseif opts.search_dirs then
    for _, path in ipairs(opts.search_dirs) do
      table.insert(args, utils.path_expand(path))
    end
  end

  opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)

  -- ----------------------------------------------------------------------------
  -- Set the global variable
  -- ----------------------------------------------------------------------------
  vim.g.cwd_grep_string_search = search
  vim.g.cwd_grep_string_word = word

  -- ----------------------------------------------------------------------------
  -- Attach mappings to the new picker
  -- ----------------------------------------------------------------------------
  local cwd = (opts ~= nil and opts.cwd ~= nil and opts.cwd) or ""
  local cwd_string = (cwd ~= "" and " in " .. cwd) or ""
  pickers
      .new(opts, {
        prompt_title = "Find Word (" .. word:gsub("\n", "\\n") .. ")" .. cwd_string,
        finder = finders.new_oneshot_job(args, opts),
        previewer = conf.grep_previewer(opts),
        sorter = M.keep_initial_sorting_sorter(),
        push_cursor_on_edit = true,
        attach_mappings = function(_, map)
          map("i", "<A-w>", M.set_temporary_cwd_from_file_browser("grep_string_custom"))
          map("n", "W", M.set_temporary_cwd_from_file_browser("grep_string_custom"))
          map("n", "q", function(prompt_bufnr)
            -- set these global variable back to nil after done, so that it wouldn't
            -- have side effect in next grep_string_custom
            vim.g.cwd_grep_string_search = nil
            vim.g.cwd_grep_string_word = nil
            actions.close(prompt_bufnr)
          end)
          return true
        end,
      })
      :find()
end

M.buffer_with_cwd_picker = function(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local entry_display = require("telescope.pickers.entry_display")
  local Path = require("plenary.path")

  local function get_buffer_info()
    local buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local buf_name = vim.api.nvim_buf_get_name(buf)
        local cwd = vim.fn.fnamemodify(Path:new(buf_name):parent():absolute(), ":t")
        table.insert(buffers, {
          buf = buf,
          name = buf_name,
          cwd = cwd,
        })
      end
    end
    return buffers
  end

  opts = opts or {}
  local buffers = get_buffer_info()

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 4 },     -- Buffer number
      { remaining = true }, -- Buffer name
      { remaining = true }, -- CWD
    },
  })

  local function make_display(entry)
    return displayer({
      entry.buf,
      entry.name,
      entry.cwd,
    })
  end

  pickers
      .new(opts, {
        prompt_title = "Buffers with CWD",
        finder = finders.new_table({
          results = buffers,
          entry_maker = function(entry)
            return {
              value = entry.buf,
              display = make_display,
              ordinal = entry.name .. " " .. entry.cwd,
              buf = entry.buf,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(_, map)
          map("i", "<CR>", actions.select_default + actions.center)
          return true
        end,
      })
      :find()
end

-- https://stackoverflow.com/a/77985695
-- grep in search result
M.nested_grep = function()
  return function(prompt_bufnr)
    require("telescope.actions").send_to_qflist(prompt_bufnr)
    local qflist = vim.fn.getqflist()
    local paths = {}
    local hash = {}
    for k in pairs(qflist) do
      local path = vim.fn.bufname(qflist[k]["bufnr"])
      if not hash[path] then
        paths[#paths + 1] = path
        hash[path] = true
      end
    end
    vim.notify("Grep in ..\n  " .. table.concat(paths, "\n  "))
    require("plugins.configs.telescope_utils").custom_rg({ search_dirs = paths })
  end
end

-- Copy absolute file path
-- https://github.com/nvim-telescope/telescope-file-browser.nvim/issues/327#issuecomment-1793591898
M.copy_absolute_file_path_in_picker = function()
  return function()
    local entry = require("telescope.actions.state").get_selected_entry()
    local cb_opts = vim.opt.clipboard:get()
    if vim.tbl_contains(cb_opts, "unnamed") then
      if entry.path then
        vim.fn.setreg("*", entry.path)
      elseif entry.filename then
        vim.fn.setreg("*", entry.filename)
      end
    end
    if vim.tbl_contains(cb_opts, "unnamedplus") then
      if entry.path then
        vim.fn.setreg("+", entry.path)
      elseif entry.filename then
        vim.fn.setreg("*", entry.filename)
      end
    end
    if entry.path then
      vim.fn.setreg("", entry.path)
    elseif entry.filename then
      vim.fn.setreg("*", entry.filename)
    end
    vim.notify("Absolute path copied to clipboard")
  end
end

M.open_telescope_file_in_specfic_tab = function(prompt_bufnr)
  local selected_entry = require("telescope.actions.state").get_selected_entry()
  local file_path = selected_entry.path or selected_entry[1] or selected_entry.filename
  local current_tab_tabnr_ordinal = vim.api.nvim_tabpage_get_number(0)

  if file_path then
    -- special case, omnisharp_extended file
    if file_path:match("%$metadata%$") then
      require("telescope.actions").select_tab(prompt_bufnr)
      return
    end

    local parent_dir = vim.fn.fnamemodify(file_path, ":h")
    if parent_dir then
      vim.g.new_tab_buf_cwd = parent_dir
    end
  end

  -- selected_entry.filename and row, col are for something like
  -- lsp_definitions, with filename and specific cursor position
  local row = selected_entry.lnum or 1
  local col = selected_entry.col or 1

  if not file_path or file_path == "" then
    print("Invalid file path")
    return
  end

  -- show tab's cwd
  local original_tab_cwd_visibility = vim.g.TabCwd
  vim.g.TabCwd = "1"

  -- vim.ui.input({ prompt = "Enter tab number: " }, function(input)
  --   pcall(function()
  --     if input then
  --       local tabnr = tonumber(input)
  --       local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tabnr)
  --       if tabnr_ordinal and tabnr_ordinal > 0 and tabnr_ordinal <= vim.fn.tabpagenr("$") then
  --         vim.api.nvim_command("tabnext " .. tabnr_ordinal)
  --         vim.api.nvim_command("edit " .. file_path)
  --         vim.fn.cursor(row, col)
  --       else
  --         print("Invalid tab number: " .. input)
  --       end
  --     else
  --       print("Input canceled")
  --     end
  --   end)
  -- end)

  require("plugins.configs.telescope_tabs").list_tabs({
    title = "Open in tab",
    on_open = function(tid)
      local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
      if current_tab_tabnr_ordinal == tabnr_ordinal then
        vim.api.nvim_command(":q!")
      end
      vim.api.nvim_command("tabnext " .. tabnr_ordinal)
      vim.api.nvim_command("edit " .. file_path)
      vim.fn.cursor(row, col)
    end,
  })

  if original_tab_cwd_visibility ~= "1" then
    vim.g.TabCwd = original_tab_cwd_visibility
  end
end

-- open the selected file to exisiting tab automatically
-- by finding the selected file's cwd, if no opened tab was opened,
-- create a new tab with the cwd
M.open_telescope_file_in_tab = function(dont_care_just_open_in_new_tab)
  return function(prompt_bufnr)
    local selected_entry = require("telescope.actions.state").get_selected_entry()
    local file_path = selected_entry.path or selected_entry[1] or selected_entry.filename
    local command = ""
    local found_tab = false
    local current_tab_tabnr_ordinal = vim.api.nvim_tabpage_get_number(0)

    if file_path then
      -- special case, omnisharp_extended file
      if file_path:match("%$metadata%$") then
        require("telescope.actions").select_tab(prompt_bufnr)
        return
      end

      if vim.g.TabAutoCwd == "1" then
        -- auto cwd, open file in new tab with its cwd
        local parent_dir = vim.fn.fnamemodify(file_path, ":p:h")
        if parent_dir then
          -- find all tabs
          for _, tid in ipairs(vim.api.nvim_list_tabpages()) do
            local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
            local win_num = vim.fn.tabpagewinnr(tabnr_ordinal)
            local working_directory = vim.fn.getcwd(win_num, tabnr_ordinal)
            local cwd_name = vim.fn.fnamemodify(working_directory, ":p:h")
            if cwd_name == parent_dir then
              if current_tab_tabnr_ordinal == tabnr_ordinal then
                command = ":q! |"
              end

              -- Check if the new tab is opening fugitive related buffer, if yes then
              -- ignore that tab, open in new tab instead
              local win_id = vim.api.nvim_tabpage_get_win(tid)
              local buf_id = vim.api.nvim_win_get_buf(win_id)
              local buf_name = vim.api.nvim_buf_get_name(buf_id)
              if not buf_name:match("fugitive://") and not buf_name:match("/tmp/nvim.ccw/") then
                command = command .. "tabnext" .. tabnr_ordinal .. " | edit " .. file_path
                found_tab = true
                vim.g.new_tab_buf_cwd = vim.fn.fnamemodify(file_path, ":h")
                break
              end
            end
          end
          if not found_tab then
            command = ":q! |" .. "tabnew " .. file_path
            vim.g.new_tab_buf_cwd = vim.fn.fnamemodify(file_path, ":h")
          end
        end
      else
        if dont_care_just_open_in_new_tab then
          goto next
        end
        -- Not auto cwd and not cwd by project, find if there is any tab opening that file
        if vim.g.TabCwdByProject ~= "1" then
          -- Close the telescope window first, because it occupy current tab
          vim.api.nvim_command(":q!")
          -- First, look for currently opened or active window in each tab (cwd)
          for _, tid in ipairs(vim.api.nvim_list_tabpages()) do
            local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
            local win = vim.api.nvim_tabpage_get_win(tid)
            local buf = vim.api.nvim_win_get_buf(win)
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == file_path then
              if vim.g.toggle_term_opened then
                command = ":q | " -- first need to close this toggleterm
              end
              command = command .. "tabnext " .. tabnr_ordinal .. " | edit " .. file_path
              found_tab = true
              goto next
            end
          end

          -- If there is no active window opened for all tabs,
          -- look for the all open buffers in each tab instead (cwd)
          for _, tid in ipairs(vim.api.nvim_list_tabpages()) do
            local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
            -- Temporarily switch to the tab to get its cwd
            vim.api.nvim_set_current_tabpage(tid)

            local buffers = require("plugins.configs.buffer_utils").get_buffers_in_cwd()
            -- Iterate each buffers in that cwd
            for _, buf in ipairs(buffers) do
              if file_path == buf[2] then
                if vim.g.toggle_term_opened then
                  command = ":q | " -- first need to close this toggleterm
                end
                command = command .. "tabnext " .. tabnr_ordinal .. " | edit " .. file_path
                found_tab = true
                goto next
              end
            end
          end
        else
          -- Not auto cwd but is cwd by project, find if that file is inside any of
          -- the tab's cwd folder tree or not
          local matched_tab_working_dirs = {}
          local matched_tab_ids = {}
          for _, tid in ipairs(vim.api.nvim_list_tabpages()) do
            local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
            -- Temporarily switch to the tab to get its cwd
            vim.api.nvim_set_current_tabpage(tid)

            local win_num = vim.fn.tabpagewinnr(tabnr_ordinal)
            local working_directory = vim.fn.getcwd(win_num, tabnr_ordinal)
            local file_path_is_inside_folder_tree =
                require("plugins.configs.buffer_utils").is_buffer_in_folder_tree(
                  working_directory,
                  file_path
                )
            if file_path_is_inside_folder_tree then
              -- The reason to not return from this loop immediately is because, say I
              -- have tab 1 working directory: A/B/C, tab 2 working directory: A/B, and I
              -- open a file in A/B/C/file, I want the file to be opened in the closest
              -- parent directory tab, which is tab 1, to do that, I need to iterate every
              -- tab and record its working directory.
              table.insert(matched_tab_working_dirs, working_directory)
              table.insert(matched_tab_ids, tabnr_ordinal)
            end
          end

          if #matched_tab_working_dirs > 0 and #matched_tab_ids > 0 then
            local longest_directory_name = ""
            local target_tab_id = 1
            for i, matched_tab_working_dir in ipairs(matched_tab_working_dirs) do
              if #matched_tab_working_dir > #longest_directory_name then
                longest_directory_name = matched_tab_working_dir
                target_tab_id = matched_tab_ids[i]
              end
            end
            if vim.g.toggle_term_opened then
              command = ":q | " -- first need to close this toggleterm
            else
              command = ":q! | " -- close Telescope
            end
            command = command .. "tabnext " .. target_tab_id .. " | edit " .. file_path
            found_tab = true
          end
        end

        ::next::
        if not found_tab then
          command = "tabnew " .. file_path
        end
      end
    end

    -- selected_entry.filename and row, col are for something like
    -- lsp_definitions, with filename and specific cursor position
    local row = selected_entry.lnum or 1
    local col = selected_entry.col or 1

    if not file_path or file_path == "" then
      print("Invalid file path")
      return
    end
    pcall(function()
      vim.api.nvim_command(command)
      vim.fn.cursor(row, col)
    end)
  end
end

M.select_direction = function(direction)
  return function(prompt_bufnr)
    if direction == "vertical" then
      require("telescope.actions").select_vertical(prompt_bufnr)
      return
    end
    require("telescope.actions").select_horizontal(prompt_bufnr)
  end
end

-- If the sort_mru is enabled, when searching should keep the initial sorting instead of
-- sorting basd on matches.
-- https://github.com/nvim-telescope/telescope.nvim/issues/3078#issuecomment-2079989253
M.keep_initial_sorting_sorter = function()
  local sorter = require("telescope.sorters").get_fzy_sorter()
  local fn = sorter.scoring_function

  sorter.scoring_function = function(_, prompt, line)
    local score = fn(_, prompt, line)
    return score > 0 and 1 or -1
  end

  return sorter
end

M.get_modified_buffers = function(global)
  local modified_buffers = {}
  if global then
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        table.insert(modified_buffers, bufname)
      end
    end
  else
    local cwd = vim.fn.getcwd()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if vim.startswith(bufname, cwd) then
          table.insert(modified_buffers, bufname)
        end
      end
    end
  end

  local prompt_title = "Modified buffers"
  if not global then
    prompt_title = prompt_title .. " in " .. vim.fn.getcwd()
  end

  require("telescope.pickers")
      .new({}, {
        prompt_title = prompt_title,
        finder = require("telescope.finders").new_table({
          results = modified_buffers,
        }),
        sorter = require("telescope.config").values.generic_sorter({}),
      })
      :find()
end

M.find_files = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()

  require("telescope.builtin").find_files({
    prompt_title = "Find Files in " .. vim.fn.fnamemodify(opts.cwd, ":p"),
    default_text = opts.default_text,
    follow = true,
    attach_mappings = function(_, map)
      map("n", "\\a", function()
        M.find_all_files({ default_text = action_state.get_current_line() })
      end)
      return true
    end,
  })
end

M.find_all_files = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()

  require("telescope.builtin").find_files({
    prompt_title = "Find All Files in " .. vim.fn.fnamemodify(opts.cwd, ":p"),
    default_text = opts.default_text,
    follow = true,
    no_ignore = true,
    hidden = true,
    attach_mappings = function(_, map)
      map("n", "\\f", function()
        M.find_files({ default_text = action_state.get_current_line() })
      end)
      return true
    end,
  })
end

M.buffers = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()

  require("telescope.builtin").buffers({
    prompt_title = "Buffers in " .. vim.fn.fnamemodify(opts.cwd, ":p"),
    cwd_only = true,
    ignore_current_buffer = true,
    default_text = opts.default_text or "",
    attach_mappings = function(_, map)
      map("n", "\\B", function()
        M.all_buffers({ default_text = action_state.get_current_line() })
      end)
      return true
    end,
  })
end

M.all_buffers = function(opts)
  opts = opts or {}

  require("telescope.builtin").buffers({
    prompt_title = "All buffers",
    cwd_only = false,
    ignore_current_buffer = true,
    default_text = opts.default_text or "",
    attach_mappings = function(_, map)
      map("n", "\\b", function()
        M.buffers({ default_text = action_state.get_current_line() })
      end)
      return true
    end,
  })
end

M.oldfiles = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()

  require("telescope.builtin").oldfiles({
    prompt_title = "Oldfiles" .. " in " .. vim.fn.fnamemodify(opts.cwd, ":p"),
    cwd_only = true,
    default_text = opts.default_text or "",
    attach_mappings = function(_, map)
      map("n", "\\O", function()
        M.all_oldfiles({ default_text = action_state.get_current_line() })
      end)
      return true
    end,
  })
end

M.all_oldfiles = function(opts)
  opts = opts or {}

  require("telescope.builtin").oldfiles({
    prompt_title = "Oldfiles",
    cwd_only = false,
    default_text = opts.default_text or "",
    attach_mappings = function(_, map)
      map("n", "\\o", function()
        M.oldfiles({ default_text = action_state.get_current_line() })
      end)
      return true
    end,
  })
end

M.file_browser_set_cwd = function(prompt_bufnr)
  -- https://github.com/nvim-telescope/telescope-file-browser.nvim/blob/master/lua/telescope/_extensions/file_browser/actions.lua
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local finder = current_picker.finder
  local entry_path = action_state.get_selected_entry().Path
  local fb_utils = require("telescope._extensions.file_browser.utils")
  finder.path = entry_path:is_dir() and entry_path:absolute() or entry_path:parent():absolute()
  finder.cwd = finder.path
  vim.cmd("tcd " .. finder.path)

  fb_utils.redraw_border_title(current_picker)
  current_picker:refresh(finder, {
    new_prefix = fb_utils.relative_path_prefix(finder),
    reset_prompt = true,
    multi = current_picker._multi,
  })
  fb_utils.notify("action.change_cwd", {
    msg = "Set the current working directory for this tab!",
    level = "INFO",
    quiet = finder.quiet,
  })
end

M.list_scratch_buffers = function(opts)
  opts = opts or {}
  -- Collect scratch buffers
  local scratch_buffers = require("plugins.configs.buffer_utils").get_scratch_buffers()

  -- If no scratch buffers, notify user
  if #scratch_buffers == 0 then
    vim.notify("No scratch buffers found", vim.log.levels.INFO)
    return
  end

  -- Create the Telescope picker
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  pickers
      .new(opts, {
        prompt_title = "Scratch Buffers",
        finder = finders.new_table({
          results = scratch_buffers,
          entry_maker = function(entry)
            return {
              value = entry,
              display = string.format("Buffer %d", tostring(entry)),
              ordinal = tostring(entry),
            }
          end,
        }),
        sorter = require("telescope.config").values.generic_sorter({}),
        attach_mappings = function(_, map)
          local select = function(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection and selection.value ~= nil then
              vim.api.nvim_set_current_buf(selection.value)
            end
          end
          -- Open the selected buffer
          map("n", "<C-l>", select)
          map("n", "<CR>", select)
          map("i", "<CR>", select)
          return true
        end,
      })
      :find()
end

return M
