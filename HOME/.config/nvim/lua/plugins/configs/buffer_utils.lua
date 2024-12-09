local utils_window = require("core.utils_window")

M = {}

M.force_delete_buffer_switch_to_next = function()
  local current_bufnr = vim.fn.bufnr("%") -- Get the buffer number of the current buffer
  local buffer_type = vim.api.nvim_get_option_value("buftype", { buf = current_bufnr })
  if buffer_type == "nofile" then
    M.switch_to_next_buffer_in_cwd()
  end

  M.force_delete_buffer_create_new()
  M.switch_to_next_buffer_in_cwd()
end

M.force_delete_buffer_switch_to_previous = function()
  local current_bufnr = vim.fn.bufnr("%") -- Get the buffer number of the current buffer
  local buffer_type = vim.api.nvim_get_option_value("buftype", { buf = current_bufnr })
  if buffer_type == "nofile" then
    M.switch_to_previous_buffer_in_cwd()
  end

  M.force_delete_buffer_create_new()
  M.switch_to_previous_buffer_in_cwd()
end

-- Function to force delete buffer and show new buffer
M.force_delete_buffer_create_new = function()
  pcall(function()
    local current_bufnr = vim.fn.bufnr("%") -- Get the buffer number of the current buffer

    -- If modified ask for permission
    if vim.bo[current_bufnr].modified then
      local choice = vim.fn.confirm("Buffer is modified. Do you want to delete it?")
      if choice == 1 then
        -- Delete the current buffer
        local bufname = vim.api.nvim_buf_get_name(0) -- Get the name of the current buffer
        if bufname == "" then
          M.force_delete_buffer_keep_tab(current_bufnr)
          return true
        end

        M.force_delete_buffer_keep_tab(current_bufnr)
        return true
      end
    else
      -- Buffer is not modified, just delete it
      local bufname = vim.api.nvim_buf_get_name(0) -- Get the name of the current buffer
      if bufname == "" then
        M.force_delete_buffer_keep_tab(current_bufnr)
        return true
      end
      M.force_delete_buffer_keep_tab(current_bufnr)
      return true
    end
    return false
  end)
end

M.force_delete_buffer_keep_tab = function(bufnr)
  -- Check if the buffer number is valid
  if not bufnr or bufnr == 0 then
    print("Invalid buffer number.")
    return
  end

  -- Check if the buffer is empty
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local is_empty = true
  for _, line in ipairs(lines) do
    if line ~= "" then
      is_empty = false
      break
    end
  end

  -- Check the buffer type
  local buffer_type = "nofile"
  buffer_type = vim.api.nvim_get_option_value("buftype", { buf = bufnr })

  local scratch

  -- Check if there is any split window in current tab
  local windows = vim.api.nvim_tabpage_list_wins(0) -- Get the list of windows in the current tab
  local is_split = #windows > 1

  -- If this is not empty buffer, delete the buffer,
  -- otherwise don't delete, to prevent delete the tab accidentally.
  if is_empty and buffer_type == "nofile" then
    if is_split then
      local choice = vim.fn.confirm(
        "This buffer is empty and it's a scratch buffer, not deleting. Close the window instead?"
      )
      if choice == 1 then
        vim.cmd("wincmd q")
      end
    else
      local choice =
          vim.fn.confirm("This buffer is empty and it's a scratch buffer, not deleting. Close the tab instead?")
      if choice == 1 then
        require("core.utils").close_and_focus_previous_tab()
      end
    end
  else
    -- Iterate through all tab pages
    for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
      -- Get all windows in the tab
      windows = vim.api.nvim_tabpage_list_wins(tabpage)
      for _, win in ipairs(windows) do
        -- Check if the window is displaying the buffer to delete
        if vim.api.nvim_win_get_buf(win) == bufnr then
          -- Get all empty scratch buffers
          local empty_scratch_buffers = M.get_empty_scratch_buffers()
          -- If there is any other scratch buffer, if yes use that scratch buffer.
          -- This is to prevent too many scratch buffer opened.
          if empty_scratch_buffers ~= nil and #empty_scratch_buffers >= 1 then
            -- Set the buffer to the first scratch buffer in the list
            scratch = empty_scratch_buffers[1]
            vim.api.nvim_win_set_buf(win, scratch)
            -- There are none scratch buffers in the memory
          else
            -- Create new scratch buffer
            scratch = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_set_option_value("buftype", "nofile", { buf = scratch })
            vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = scratch })
            vim.api.nvim_set_option_value("swapfile", false, { buf = scratch })
            -- Set the buffer to that scratch buffer
            vim.api.nvim_win_set_buf(win, scratch)
          end
        end
      end
    end

    if not vim.api.nvim_buf_is_valid(scratch) then
      scratch = vim.api.nvim_create_buf(false, true)
    end

    -- Open the scratch
    -- So that the window wouldn't be closed
    vim.cmd("buffer " .. scratch)

    -- Delete the buffer
    -- The purpose of using `bdelete` is to keep the buffer in the oldfiles record,
    -- and remove the buffer from the buffer list
    vim.cmd("bdelete! " .. bufnr)
  end
end

M.get_blank_buffers = function()
  local blank_buffers = {}
  for _, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local bufname = bufinfo.name
    if bufname == "" then
      table.insert(blank_buffers, bufinfo.bufnr)
    end
  end
  return blank_buffers
end

M.get_scratch_buffers = function()
  local scratch_buffers = {}
  -- Get a list of all buffers
  local buffers = vim.api.nvim_list_bufs()
  -- Iterate over each buffer and check if it's a scratch buffer
  for _, bufnr in ipairs(buffers) do
    -- Check if the buffer is a scratch buffer
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "nofile" then
      table.insert(scratch_buffers, bufnr)
    end
  end
  return scratch_buffers
end

M.get_empty_scratch_buffers = function()
  local scratch_buffers = {}
  -- Get a list of all buffers
  local buffers = vim.api.nvim_list_bufs()
  -- Iterate over each buffer and check if it's a scratch buffer
  for _, bufnr in ipairs(buffers) do
    -- Check if the buffer is a scratch buffer
    if vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "nofile" then
      -- Check if the buffer is empty
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local is_empty = true
      for _, line in ipairs(lines) do
        if line ~= "" then
          is_empty = false
          break
        end
      end
      if is_empty then
        table.insert(scratch_buffers, bufnr)
      end
    end
  end
  return scratch_buffers
end

-- Function to delete buffer and show new buffer
M.delete_buffer_create_new = function()
  -- Delete the current buffer
  pcall(function()
    local current_bufnr = vim.fn.bufnr("%")    -- Get the buffer number of the current buffer
    local bufname = vim.api.nvim_buf_get_name(0) -- Get the name of the current buffer
    if bufname == "" then
      return
    end
    vim.cmd("enew")
    vim.cmd("bdelete" .. current_bufnr)
  end)
end

M.navigate_to_previous_buffer = function()
  local current_bufnr = vim.fn.bufnr("%")         -- Get the buffer number of the current buffer
  local current_directory = vim.fn.expand("%:p:h") -- Get the directory of the current buffer
  local previous_bufnr

  -- Iterate backwards through the list of buffers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if vim.fn.fnamemodify(bufname, ":p:h") == current_directory then
      if bufnr == current_bufnr then
        break -- Stop when reaching the current buffer
      end
      previous_bufnr = bufnr
    end
  end

  -- If a previous buffer in the same directory is found, navigate to it
  if previous_bufnr then
    vim.cmd("buffer " .. previous_bufnr)
  end
end

-- Function to navigate to the next buffer in the same working directory
M.navigate_to_next_buffer = function()
  local current_bufnr = vim.fn.bufnr("%")         -- Get the buffer number of the current buffer
  local current_directory = vim.fn.expand("%:p:h") -- Get the directory of the current buffer
  local next_bufnr

  -- Iterate forwards through the list of buffers
  local buffers = vim.api.nvim_list_bufs()
  for i = #buffers, 1, -1 do
    local bufnr = buffers[i]
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if vim.fn.fnamemodify(bufname, ":p:h") == current_directory then
      if bufnr == current_bufnr then
        break -- Stop when reaching the current buffer
      end
      next_bufnr = bufnr
    end
  end

  -- If a next buffer in the same directory is found, navigate to it
  if next_bufnr then
    vim.cmd("buffer " .. next_bufnr)
  end
end

-- Function to dynamically show listchars
M.toggle_listchars_symbol = function()
  local current_win = vim.api.nvim_get_current_win()
  -- Get the current window's list setting
  local list = vim.api.nvim_get_option_value("list", { win = current_win })
  -- Iterate over all tabpages
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    -- Iterate over all windows in the current tabpage
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      -- Get the current window's list setting
      local win_list = vim.api.nvim_get_option_value("list", { win = win })
      if win_list == list then
        vim.api.nvim_set_option_value("list", not win_list, { win = win })
      end
    end
  end
end

-- Function to dynamically show newline symbol
M.toggle_newline_symbol = function()
  local newline = "eol:⮠"
  if vim.o.listchars:find("eol:") then
    vim.o.listchars = string.gsub(vim.o.listchars, "," .. newline, "")
    vim.o.showbreak = ""
  else
    vim.o.listchars = vim.o.listchars .. "," .. newline
    vim.o.showbreak = "↳"
  end
end

M.get_buffers_in_cwd = function()
  local cwd = vim.fn.getcwd()
  local buffers = {}

  for _, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local bufname = bufinfo.name
    if bufname ~= "" and vim.startswith(bufname, cwd) then
      table.insert(buffers, { bufinfo.bufnr, bufinfo.name })
    end
  end

  return buffers
end

M.switch_to_next_buffer_in_cwd = function()
  if not vim.o.hlsearch then
    vim.cmd("nohlsearch")
  end
  local buffers = M.get_buffers_in_cwd()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_index = nil
  for i, buf in ipairs(buffers) do
    if buf[1] == current_bufnr then
      current_index = i
      break
    end
  end
  if current_index then
    pcall(function()
      local next_index = (current_index % #buffers) + 1
      vim.api.nvim_set_current_buf(buffers[next_index][1])
    end)
  else
    pcall(function()
      local next_index = #buffers
      vim.api.nvim_set_current_buf(buffers[next_index][1])
    end)
  end
end

M.switch_to_previous_buffer_in_cwd = function()
  if not vim.o.hlsearch then
    vim.cmd("nohlsearch")
  end
  local buffers = M.get_buffers_in_cwd()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_index = nil
  for i, buf in ipairs(buffers) do
    if buf[1] == current_bufnr then
      current_index = i
      break
    end
  end
  if current_index then
    pcall(function()
      local previous_index = (current_index - 2) % #buffers + 1
      vim.api.nvim_set_current_buf(buffers[previous_index][1])
    end)
  else
    pcall(function()
      local previous_index = 1
      vim.api.nvim_set_current_buf(buffers[previous_index][1])
    end)
  end
end

M.open_buffer_in_specific_tab = function(tabnr, bufnr)
  -- Get the list of tab pages
  local tabpages = vim.api.nvim_list_tabpages()
  -- Check if the specified tab exists
  if tabnr < 1 or tabnr > #tabpages then
    print("Invalid tab number: " .. tabnr)
    return
  end

  -- Get the list of buffers
  local buffers = vim.api.nvim_list_bufs()
  -- Check if the specified buffer exists
  local buffer_exists = false
  for _, b in ipairs(buffers) do
    if b == bufnr then
      buffer_exists = true
      break
    end
  end

  if not buffer_exists then
    print("Invalid buffer number: " .. bufnr)
    return
  end

  if vim.g.toggle_term_opened then
    vim.cmd("wincmd q") -- first need to close this toggleterm
    vim.g.toggle_term_opened = false
  end

  -- Switch to the specified tab
  vim.api.nvim_set_current_tabpage(tabpages[tabnr])
  -- Open the specified buffer in the current window of the specified tab
  vim.api.nvim_set_current_buf(bufnr)
end

M.open_file_in_current_window = function(is_visual, count)
  local vimfetch = require("core.utils_vimfetch")
  local file
  if is_visual then
    file = vimfetch.fetch_visual(count)
  else
    file = vimfetch.fetch_cfile(count)
  end

  if file and file[1] then
    -- if this is toggleterm then close it first
    local buf_nr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(buf_nr)
    if buf_name:lower():find("toggleterm") then
      vim.cmd("wincmd q")
      vim.g.toggle_term_opened = false
    end

    vim.api.nvim_command("edit " .. file[1])
    vim.fn.cursor(file[2], file[3])
  end
end

M.open_file_in_new_tab = function(is_visual, count)
  local vimfetch = require("core.utils_vimfetch")
  local file
  if is_visual then
    file = vimfetch.fetch_visual(count)
  else
    file = vimfetch.fetch_cfile(count)
  end

  if file and file[1] then
    local parent_dir = vim.fn.fnamemodify(file[1], ":h")
    if parent_dir then
      vim.g.new_tab_buf_cwd = parent_dir
    end

    vim.api.nvim_command("tabnew " .. file[1])
    vim.fn.cursor(file[2], file[3])
  end
end

M.open_file_or_buffer_in_specific_tab = function(is_visual, count)
  local vimfetch = require("core.utils_vimfetch")

  local file
  if is_visual then
    file = vimfetch.fetch_visual(count)
  else
    file = vimfetch.fetch_cfile(count)
  end

  local current_buf_nr = vim.api.nvim_get_current_buf()
  local current_win_id = vim.fn.bufwinid(current_buf_nr)

  if file == nil or #file == 0 then
    -- if no path on the cursor, then record current buffer to the file variable
    file = {}
    local buf_name = vim.api.nvim_buf_get_name(current_buf_nr)

    -- ignore if this is a term
    if buf_name:match("^term:") then
      return
    end

    -- ignore if this is fugitive
    if buf_name:match("^fugitive:") then
      return
    end

    -- ignore if this is Gll related
    if buf_name:match("/tmp/nvim.ccw/*") then
      return
    end

    file[1] = vim.fn.fnamemodify(buf_name, ":p")
    file[2], file[3] = vim.api.nvim_win_get_cursor(0)
  end

  local file_path = file[1]
  local row = file[2] or 1
  local col = file[3] or 1

  -- show tab's cwd
  local original_tab_cwd_visibility = vim.g.TabCwd
  vim.g.TabCwd = "1"

  require("plugins.configs.telescope_tabs").list_tabs({
    title = "Open in tab",
    on_open = function(tid)
      -- if there are multiple windows in current screen,
      -- close current window as we are opening current buffer in new tab anyway
      if vim.fn.winnr("$") > 1 then
        vim.api.nvim_win_close(current_win_id, false)
      end
      local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
      -- Switch to the specified tab
      vim.cmd("tabn " .. tabnr_ordinal)
      -- Open the file in the current window of the specified tab
      if file and file_path then
        local parent_dir = vim.fn.fnamemodify(file[1], ":h")
        if parent_dir then
          vim.g.new_tab_buf_cwd = parent_dir
        end

        vim.cmd("edit " .. file_path)
        vim.fn.cursor(row, col)
      end
    end,
  })

  if original_tab_cwd_visibility ~= "1" then
    vim.g.TabCwd = original_tab_cwd_visibility
  end
end

M.open_file_or_buffer_in_tab = function(is_visual, count)
  local vimfetch = require("core.utils_vimfetch")

  local file
  if is_visual then
    file = vimfetch.fetch_visual(count)
  else
    file = vimfetch.fetch_cfile(count)
  end

  local command = ""
  local found_tab = false
  local current_buf_nr = vim.api.nvim_get_current_buf()
  local current_win_id = vim.fn.bufwinid(current_buf_nr)

  if file == nil or #file == 0 then
    -- if no path on the cursor, then record current buffer to the file variable
    file = {}
    local buf_name = vim.api.nvim_buf_get_name(current_buf_nr)
    -- ignore if this is a term
    if buf_name:match("^term:") then
      return
    end

    -- ignore if this is fugitive
    if buf_name:match("^fugitive:") then
      return
    end

    -- ignore if this is Gll related
    if buf_name:match("/tmp/nvim.ccw/*") then
      return
    end

    file[1] = vim.fn.fnamemodify(buf_name, ":p")
    file[2], file[3] = vim.api.nvim_win_get_cursor(0)
    -- if there are multiple windows in current screen,
    -- close current window as we are opening current buffer in new tab anyway
    if vim.fn.winnr("$") > 1 then
      vim.api.nvim_win_close(current_win_id, false)
    end
  end

  local file_path = file[1]
  local row = file[2] or 1
  local col = file[3] or 1

  if file_path and file_path ~= "" then
    -- special case, omnisharp_extended file
    if file_path:match("%$metadata%$") then
      if vim.g.toggle_term_opened then
        command = ":q | " -- first need to close this toggleterm
      end
      command = "tabnew | buffer " .. current_buf_nr
      goto continue
    end

    local parent_dir = vim.fn.fnamemodify(file_path, ":p:h")
    if vim.g.TabAutoCwd == "1" then
      if parent_dir then
        -- find all tabs
        for _, tid in ipairs(vim.api.nvim_list_tabpages()) do
          local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
          local win_num = vim.fn.tabpagewinnr(tabnr_ordinal)
          local working_directory = vim.fn.getcwd(win_num, tabnr_ordinal)
          local cwd_name = vim.fn.fnamemodify(working_directory, ":p:h")
          if cwd_name == parent_dir then
            if vim.g.toggle_term_opened then
              command = ":q | " -- first need to close this toggleterm
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
          if vim.g.toggle_term_opened then
            command = ":q | " -- first need to close this toggleterm
          end
          command = "tabnew " .. file_path
        end
        vim.g.new_tab_buf_cwd = vim.fn.fnamemodify(file_path, ":h")
      else
        print("Parent dir not found")
        return
      end
    else
      -- Not auto cwd, find if there is tab opening that file
      for _, tid in ipairs(vim.api.nvim_list_tabpages()) do
        local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tid)
        -- Temporarily switch to the tab to get its cwd
        vim.api.nvim_set_current_tabpage(tid)
        local buffers = M.get_buffers_in_cwd()
        -- Iterate each buffers in that cwd
        for _, buf in ipairs(buffers) do
          if file_path == buf[2] then
            if vim.g.toggle_term_opened then
              command = ":q | " -- first need to close this toggleterm
            end
            command = command .. "tabnext" .. tabnr_ordinal .. "| edit " .. file_path
            found_tab = true
            goto next
          end
        end
      end
      ::next::
      if not found_tab then
        if vim.g.toggle_term_opened then
          command = ":q | " -- first need to close this toggleterm
        end
        command = "tabnew " .. file_path
      end
    end
  else
    print("Invalid file path")
    return
  end

  ::continue::

  vim.api.nvim_command(command)
  vim.g.toggle_term_opened = false
  vim.fn.cursor(row, col)
end

-- Run Git custom user command when the buffer name matches
M.run_git_related_when_the_buffer_name_matches = function()
  local buf_path = vim.api.nvim_buf_get_name(0)
  require("core.utils_window").save_window_sizes_and_restore(function()
    if buf_path:match("^/tmp/nvim%.ccw/") then
      vim.g.gll_reload_manually_or_open_new = true
      vim.api.nvim_command(":Gll")
      vim.cmd("wincmd k")
      vim.cmd("wincmd q")
      vim.cmd("wincmd p") -- make sure to focus on the Gll window
    elseif buf_path:match("^fugitive://") then
      pcall(function()
        vim.notify("Fetching remote...")
        vim.api.nvim_command("Git fetch --all")
        vim.notify("Done fetching remote.")
      end)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-r>", true, false, true), "n", true)
    end
  end)
end

M.focus_window_by_selecting_it = function()
  local target_winid = utils_window.get_target_winid()
  if not target_winid then
    return
  end
  vim.api.nvim_set_current_win(target_winid)
end

M.open_file_or_buffer_in_window = function(is_visual, count)
  local vimfetch = require("core.utils_vimfetch")

  local file
  if is_visual then
    file = vimfetch.fetch_visual(count)
  else
    file = vimfetch.fetch_cfile(count)
  end

  local current_buf_nr = vim.api.nvim_get_current_buf()

  if file == nil or #file == 0 then
    -- if no path on the cursor, then record current buffer to the file variable
    file = {}
    local buf_name = vim.api.nvim_buf_get_name(current_buf_nr)
    -- ignore if this is a term
    if buf_name:match("^term:") then
      return
    end

    -- ignore if this is fugitive
    if buf_name:match("^fugitive:") then
      return
    end

    -- ignore if this is Gll related
    if buf_name:match("/tmp/nvim.ccw/*") then
      return
    end

    file[1] = vim.fn.fnamemodify(buf_name, ":p")
    file[2], file[3] = vim.api.nvim_win_get_cursor(0)
  end

  local file_path = file[1]
  local row = file[2] or 1
  local col = file[3] or 1

  if file_path then
    utils_window.open(file_path, row, col)
  end

  if not file_path or file_path == "" then
    print("Invalid file path")
    return
  end
end

M.new_tab_with_scratch_buffer = function()
  vim.cmd("tabedit")
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = 0 })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = 0 })
  vim.api.nvim_set_option_value("swapfile", false, { buf = 0 })
end

return M
