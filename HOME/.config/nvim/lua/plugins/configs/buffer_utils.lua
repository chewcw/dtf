local utils_window = require("core.utils_window")

M = {}

M.force_delete_buffer_switch_to_next = function()
  M.force_delete_buffer_create_new()
  M.switch_to_next_buffer_in_cwd()
end

M.force_delete_buffer_switch_to_previous = function()
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

  -- If this is not empty buffer, safely delete the buffer,
  -- otherwise don't delete, to prevent delete the tab accidentally.
  if not is_empty then
    local blank_buffers = M.get_blank_buffers()
    -- If there is any other blank buffer, if yes use that blank buffer.
    -- This is to prevent too many blank buffer opened.
    if blank_buffers ~= nil and #blank_buffers >= 1 then
      vim.api.nvim_set_current_buf(blank_buffers[1])
    else
      -- If none blank buffer, create new one.
      vim.cmd("enew")
    end
    vim.cmd("bdelete! " .. bufnr)
  else
    print("This buffer is empty, not deleting.")
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
  if vim.o.list then
    vim.o.list = false
  else
    vim.o.list = true
  end
end

-- Function to dynamically show newline symbol
M.toggle_newline_symbol = function()
  local newline = "eol:↵"
  if vim.o.listchars:find("eol:") then
    vim.o.listchars = string.gsub(vim.o.listchars, "," .. newline, "")
  else
    vim.o.listchars = vim.o.listchars .. "," .. newline
  end
end

local function get_buffers_in_cwd()
  local cwd = vim.fn.getcwd()
  local buffers = {}

  for _, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local bufname = bufinfo.name
    if bufname ~= "" and vim.startswith(bufname, cwd) then
      table.insert(buffers, bufinfo.bufnr)
    end
  end

  return buffers
end

M.switch_to_next_buffer_in_cwd = function()
  if not vim.o.hlsearch then
    vim.cmd("nohlsearch")
  end
  local buffers = get_buffers_in_cwd()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_index = nil
  for i, bufnr in ipairs(buffers) do
    if bufnr == current_bufnr then
      current_index = i
      break
    end
  end
  if current_index then
    pcall(function()
      local next_index = (current_index % #buffers) + 1
      vim.api.nvim_set_current_buf(buffers[next_index])
    end)
  else
    pcall(function()
      local next_index = #buffers
      vim.api.nvim_set_current_buf(buffers[next_index])
    end)
  end
end

M.switch_to_previous_buffer_in_cwd = function()
  if not vim.o.hlsearch then
    vim.cmd("nohlsearch")
  end
  local buffers = get_buffers_in_cwd()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_index = nil
  for i, bufnr in ipairs(buffers) do
    if bufnr == current_bufnr then
      current_index = i
      break
    end
  end
  if current_index then
    pcall(function()
      local previous_index = (current_index - 2) % #buffers + 1
      vim.api.nvim_set_current_buf(buffers[previous_index])
    end)
  else
    pcall(function()
      local previous_index = 1
      vim.api.nvim_set_current_buf(buffers[previous_index])
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
    -- close current window as we are opening current buffer in new tab anyway
    vim.api.nvim_win_close(current_win_id, false)
  end

  local file_path = file[1]
  local row = file[2] or 1
  local col = file[3] or 1

  -- show tab's cwd
  local original_tab_cwd_visibility = vim.g.toggle_tab_cwd
  vim.g.toggle_tab_cwd = "1"

  -- vim.ui.input({ prompt = "Enter tab number: " }, function(input)
  --   if input then
  --     local tabnr = tonumber(input)
  --     local tabnr_ordinal = vim.api.nvim_tabpage_get_number(tabnr)
  --     if tabnr_ordinal and tabnr_ordinal > 0 and tabnr_ordinal <= vim.fn.tabpagenr("$") then
  --       -- Get the list of tab pages
  --       local tabpages = vim.api.nvim_list_tabpages()
  --       -- Check if the specified tab exists
  --       if tabnr_ordinal < 1 or tabnr_ordinal > #tabpages then
  --         print("Invalid tab number: " .. tabnr_ordinal)
  --         return
  --       end
  --
  --       -- Switch to the specified tab
  --       vim.cmd("tabn " .. tabnr_ordinal)
  --       -- Open the file in the current window of the specified tab
  --       if file and file[1] then
  --         local parent_dir = vim.fn.fnamemodify(file[1], ":h")
  --         if parent_dir then
  --           vim.g.new_tab_buf_cwd = parent_dir
  --         end
  --
  --         vim.cmd("edit " .. file[1])
  --         vim.fn.cursor(file[2], file[3])
  --       end
  --     else
  --       print("Invalid tab number: " .. input)
  --     end
  --   else
  --     print("Input canceled")
  --   end
  -- end)

  require("plugins.configs.telescope_tabs").list_tabs({
    title = "Open in tab",
    on_open = function(tid)
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
    vim.g.toggle_tab_cwd = original_tab_cwd_visibility
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
    -- close current window as we are opening current buffer in new tab anyway
    vim.api.nvim_win_close(current_win_id, false)
  end

  local file_path = file[1]
  local row = file[2] or 1
  local col = file[3] or 1

  if file_path then
    local parent_dir = vim.fn.fnamemodify(file_path, ":p:h")
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

          command = command .. "tabnext" .. tabnr_ordinal .. " | edit " .. file_path
          found_tab = true
          vim.g.new_tab_buf_cwd = vim.fn.fnamemodify(file_path, ":h")
          break
        end
      end
      if not found_tab then
        command = "tabnew " .. file_path
      end
      vim.g.new_tab_buf_cwd = vim.fn.fnamemodify(file_path, ":h")
    end
  end

  if not file_path or file_path == "" then
    print("Invalid file path")
    return
  end
  vim.api.nvim_command(command)
  vim.fn.cursor(row, col)
end

-- Run Git custom user command when the buffer name matches
M.run_git_related_when_the_buffer_name_matches = function()
  local buf_path = vim.api.nvim_buf_get_name(0)
  if buf_path:match("^/tmp/nvim%.ccw/") then
    vim.g.gll_reload_manually_or_open_new = true
    vim.api.nvim_command(":Gll")
    vim.cmd("wincmd k")
    vim.cmd("wincmd q")
    vim.cmd("wincmd p") -- make sure to focus on the Gll window
  elseif buf_path:match("^fugitive://") then
    pcall(function()
      vim.notify("Fetching remote...")
      vim.api.nvim_command("Git fetch")
      vim.notify("Done fetching remote.")
    end)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-r>", true, false, true), "n", true)
  end
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

return M
