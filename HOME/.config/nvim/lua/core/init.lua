local opt = vim.opt
local g = vim.g
local config = require("core.utils").load_config()

-------------------------------------- options ------------------------------------------
opt.laststatus = 2 -- global statusline
opt.showmode = true

opt.clipboard = "unnamedplus"
opt.cursorline = true
opt.cursorlineopt = "number"

-- Indenting
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.autoindent = true
opt.smartindent = true

opt.fillchars = {
  eob = "~",
  vert = "|",
  -- horiz = "―",
  -- vertright = " ",
  -- vertleft = "
  -- horizup = " ",
  -- horizdown = " ",
  -- verthoriz = " ",
  stl = " ",
  fold = " ",
  -- foldopen = "🢒",
  -- foldsep = " ",
  -- foldclose = " ",
}
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

-- Numbers
opt.number = true
opt.relativenumber = true
opt.numberwidth = 1
opt.ruler = false

-- disable nvim intro
opt.shortmess:append("sI")

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 2000
opt.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 250

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
-- opt.whichwrap:append("<>[]hl")

-- https://stackoverflow.com/questions/2288756/how-to-set-working-current-directory-in-vim
opt.autochdir = false

-- misc
opt.scrolloff = 5
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldcolumn = "0"
opt.wildignorecase = true
-- this is the annoying opening parenthesis highlighting when typing closing parenthesis
-- https://stackoverflow.com/a/34716232
opt.showmatch = false
-- this has no effect if the showmatch is disabled
opt.matchtime = 1
opt.breakindent = true
opt.completeopt = "menuone,noselect"

-- vertical line
opt.colorcolumn = "85"

-- wrap
vim.wo.wrap = false
opt.linebreak = true
opt.textwidth = 85

-- fold method
opt.foldmethod = "indent"

-- leader
g.mapleader = " "

-- cursor
opt.guicursor = "n-v-sm:block,i-c-ci-ve:block-blinkwait0-blinkoff400-blinkon250-Cursor/lCursor,r-cr-o:hor30"

-- list mode (show return and space)
-- take note on the function toggle_newline_symbol in plugins.configs.buffer_utils.lua
opt.list = true
opt.listchars:append("lead:·,multispace:·,trail:·,tab:⇥ ,precedes:⇇,extends:⇉")

-- tabline
opt.showtabline = 2

-- virtualedit
opt.virtualedit = "insert,block" -- see also the mapping for cursorcolumn that will change this

-- sessions
opt.sessionoptions = "blank,buffers,curdir,help,tabpages,winsize,winpos,localoptions,globals"

-- diffopt
opt.diffopt = "internal,filler,closeoff,iwhite"

-- disable other default providers
for _, provider in ipairs({ "node", "perl", "python3", "ruby" }) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.env.PATH .. (is_windows and ";" or ":") .. vim.fn.stdpath("data") .. "/mason/bin"

-- abbrevation
require("core.abbrev")

-- statusline
require("core.statusline")

-- tabline
require("core.tabline")

-- ----------------------------------------------------------------------------
-- autocmds
-- ----------------------------------------------------------------------------
local autocmd = vim.api.nvim_create_autocmd

-- dont list quickfix buffers
autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

-- save fold on save and laod fold on open
-- https://stackoverflow.com/a/77180744
-- vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
--   pattern = { "*.*" },
--   desc = "save view (folds), when closing file",
--   command = "mkview",
-- })
-- vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
--   pattern = { "*.*" },
--   desc = "load view (folds), when opening file",
--   command = "silent! loadview",
-- })

-- ----------------------------------------------------------------------------
-- Update status bar MsgArea color
-- ----------------------------------------------------------------------------
-- update command line color in insert mode
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
  callback = function()
    vim.api.nvim_set_hl(0, "MsgArea", {
      bg = require("core.utils_colors").msg_area_colors.insert_mode_msg_area,
    })
  end,
})

-- update command line color in command mode
vim.api.nvim_create_autocmd({ "CmdLineEnter" }, {
  callback = function()
    -- vim.api.nvim_set_hl(0, "MsgArea", {
    -- bg = require("core.colorscheme").colors().cmdline_msg_area,
    -- })
    -- so that when I press ctrl+f in the command line it wouldn't have error
    pcall(function()
      vim.cmd(":TSContextDisable")
    end)
  end,
})
vim.api.nvim_create_autocmd({ "CmdLineLeave" }, {
  callback = function()
    pcall(function()
      vim.cmd(":TSContextEnable")
    end)
    -- vim.api.nvim_set_hl(0, "MsgArea", { bg = "None" })
  end,
})

-- search for any unsaved buffer and show it on the MsgArea
vim.api.nvim_create_autocmd({ "BufModifiedSet", "InsertLeave" }, {
  callback = require("core.utils").search_modified_unsaved_buffers,
})

-- opening and closing telescope picker will also be triggered
-- so this event is to run the function after the telescope picker is closed
vim.api.nvim_create_autocmd({ "WinEnter" }, {
  callback = require("core.utils").search_modified_unsaved_buffers,
})

-- for trouble.nvim plugin there is no NormalNC highlight group
-- this is a hack
-- vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
--   callback = function()
--     local buf_name = vim.api.nvim_buf_get_name(0)
--     local colors = require("core.colorscheme")
--     if string.find(buf_name, "/Trouble") then
--       vim.api.nvim_set_hl(0, "TroubleNormal", { bg = colors.bg_nc })
--     else
--       vim.api.nvim_set_hl(0, "TroubleNormal", { bg = colors.bg })
--     end
--   end,
-- })

-- update command line color in terminal mode
vim.api.nvim_create_autocmd({ "TermEnter" }, {
  callback = function()
    vim.api.nvim_set_hl(0, "MsgArea", {
      bg = require("core.utils_colors").msg_area_colors.term_msg_area,
    })
  end,
})
vim.api.nvim_create_autocmd({ "TermLeave" }, {
  callback = function()
    vim.api.nvim_set_hl(0, "MsgArea", { bg = "None" })
  end,
})

-- Stop lsp, detach gitsigns, and disable treesitter_context in diff mode
function DoSomethingInDiffMode()
  if vim.api.nvim_win_get_option(0, "diff") then
    vim.lsp.stop_client(vim.lsp.get_active_clients())
    pcall(function()
      vim.cmd(":Gitsigns detach_all")
    end)
    pcall(function()
      vim.cmd(":TSContextDisable")
    end)
  end
end

vim.api.nvim_create_autocmd({ "OptionSet" }, {
  callback = DoSomethingInDiffMode,
})

-- Highlight all same words in the buffer under cursor
vim.api.nvim_create_augroup("CursorMovedHighlight", { clear = true })
vim.api.nvim_create_autocmd({ "CursorMoved" }, {
  group = "CursorMovedHighlight",
  callback = function()
    pcall(function()
      if vim.g.toggle_cursor_move_highlight then
        return
      end

      -- ignore this if no lsp_server found
      local buf_clients = vim.lsp.get_active_clients({ bufnr = vim.api.nvim_get_current_buf() })
      if #buf_clients == 0 then
        return
      end

      -- Clear existing highlights in the group
      vim.cmd("silent! syntax clear UnderlinedHighlight")

      -- Get the word under the cursor
      local word = vim.fn.expand("<cword>")
      if word == "" then
        return
      end

      -- Escape the word for use in a Vim pattern
      local escaped_word = vim.fn.escape(word, "\\/.*$^~[]")

      -- Highlight all instances of the word in the current buffer
      vim.cmd(string.format("syntax match UnderlinedHighlight /\\V\\<%s\\>/", escaped_word))
      vim.cmd("highlight link UnderlinedHighlight Highlight")
    end)
  end,
})

-- because of core.utils.toggle_search_highlight function, normal search using following
-- mappings may not have highlights shown, because it has been toggled off, so
-- these mappings made sure hlsearch will always be on.
vim.api.nvim_create_augroup("EnableHlsearch", { clear = true })
vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = "EnableHlsearch",
  callback = function()
    -- Get the content of the command line
    local cmd_line_type = vim.fn.getcmdtype()
    local cmd_line = vim.fn.getcmdline()

    -- Check if the command starts with '/' or '?' and is followed by some characters
    if cmd_line_type == "/" or cmd_line_type == "?" then
      if string.find(cmd_line, "^.+") then
        vim.o.hlsearch = true
      else
        vim.o.hlsearch = false
      end
    end
  end,
})

-- ----------------------------------------------------------------------------
-- user commands
-- ----------------------------------------------------------------------------
-- A user command to copy buffer file path
-- https://www.reddit.com/r/neovim/comments/u221as/comment/i5y9zy2/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
vim.api.nvim_create_user_command("CopyPath", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

-- A user command to update quickfix list after cdo / cfdo
-- https://vi.stackexchange.com/a/13663
vim.api.nvim_create_user_command("UpdateQf", function()
  vim.cmd(
    [[ call setqflist(map(getqflist(), 'extend(v:val, {"text":get(getbufline(v:val.bufnr, v:val.lnum),0)})')) ]]
  )
end, {})

-- Clear the quickfix list
vim.api.nvim_create_user_command("ClearQf", function()
  vim.cmd([[ call setqflist([]) ]])
end, {})

-- Update location list
vim.api.nvim_create_user_command("UpdateLoc", function()
  local current_win = vim.api.nvim_get_current_win()
  local command = [[call setloclist( ]]
      .. current_win
      .. [[, map(getloclist( ]]
      .. current_win
      .. [[), 'extend(v:val, {"text":get(getbufline(v:val.bufnr, v:val.lnum),0)})')) ]]
  vim.cmd(command)
end, {})

-- Clear the location list for current window
vim.api.nvim_create_user_command("ClearLoc", function()
  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("call setloclist(" .. current_win .. ", [])")
end, {})

-- Redirect the output of a Vim or external command into a scratch buffer
-- reference: https://github.com/sbulav/nredir.nvim
vim.api.nvim_create_user_command("Redir", function(opts)
  require("core.utils_redir").nredir(opts.args, "replace")
end, { nargs = 1, complete = "command" })

-- Toggle cursor move highlight
vim.g.toggle_cursor_move_highlight = false
vim.api.nvim_create_user_command("ToggleCursorMoveHighlight", function()
  vim.g.toggle_cursor_move_highlight = not vim.g.toggle_cursor_move_highlight
end, { nargs = 0 })

-- ----------------------------------------------------------------------------
-- set tab size for certain file type
-- ----------------------------------------------------------------------------
-- csharp
local filetype_cs_group = vim.api.nvim_create_augroup("FileTypeCS", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = filetype_cs_group,
  pattern = "cs",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

-- ----------------------------------------------------------------------------
-- do certain thing for certain file type
-- ----------------------------------------------------------------------------
-- razor file
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.razor" },
  callback = function()
    if vim.bo.filetype ~= "cs" then
      -- vim.opt_local.filetype = "html"
      vim.opt_local.tabstop = 4
      vim.opt_local.shiftwidth = 4
      vim.opt_local.expandtab = true
      vim.opt_local.textwidth = 0
      vim.opt_local.colorcolumn = "0"
    end
  end,
})

-- html file
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.html" },
  callback = function()
    vim.opt_local.filetype = "html"
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
    vim.opt_local.textwidth = 0
    vim.opt_local.colorcolumn = "0"
  end,
})

-- markdown
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.md" },
  callback = function()
    vim.opt_local.filetype = "markdown"
    vim.opt_local.textwidth = 0
  end,
})

-- ----------------------------------------------------------------------------
-- Set expandtab for all buffers
-- ----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    vim.bo.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    vim.bo[bufnr].expandtab = true
  end,
})

-- ----------------------------------------------------------------------------
-- Focus left tab when tab closed
-- ----------------------------------------------------------------------------
-- https://stackoverflow.com/a/77006146
vim.api.nvim_create_augroup("TabClosed", { clear = true })
vim.api.nvim_create_autocmd("TabClosed", {
  group = "TabClosed",
  callback = function()
    vim.cmd("tabprevious")
  end,
})

-- ----------------------------------------------------------------------------
-- Set buffer's parent directory as cwd when new tab entered
-- See all functions which setting vim.g.new_tab_buf_cwd
-- ----------------------------------------------------------------------------
vim.api.nvim_create_user_command("TabAutoCwd", function()
  if vim.g.TabAutoCwd == nil or vim.g.TabAutoCwd == "0" then
    vim.g.TabAutoCwd = "1"
    vim.g.TabCwd = "3"
    vim.g.TabCwdByProject = "0" -- This flag only make sense if TabAutoCwd is off
  else
    vim.g.TabAutoCwd = "0"
    vim.g.TabCwd = "7"
  end
  vim.defer_fn(function()
    local onoff = "off"
    if vim.g.TabAutoCwd == "1" then
      onoff = "on"
    end
    vim.notify("TabAutoCwd is now " .. onoff)
  end, 50)
end, { nargs = "*" })

-- ----------------------------------------------------------------------------
-- Set each tab as project workspace, so that buffers from same project but
-- different nested parent folder would be opened in same tab.
-- Only useful when use with TabAutoCwd == off
-- ----------------------------------------------------------------------------
vim.api.nvim_create_user_command("TabCwdByProject", function()
  if vim.g.TabAutoCwd == "0" then
    if vim.g.TabCwdByProject == nil or vim.g.TabCwdByProject == "0" then
      vim.g.TabCwdByProject = "1"
      vim.g.TabCwd = "3"
    else
      vim.g.TabCwdByProject = "0"
      vim.g.TabCwd = "7"
    end
    vim.defer_fn(function()
      local onoff = "off"
      if vim.g.TabCwdByProject == "1" then
        onoff = "on"
      end
      vim.notify("TabCwdByProject is now " .. onoff)
    end, 50)
  end
end, { nargs = "*" })

vim.api.nvim_create_autocmd("TabNewEntered", {
  callback = function()
    if vim.g.TabAutoCwd == "1" then
      if vim.g.new_tab_buf_cwd ~= nil and vim.g.new_tab_buf_cwd ~= "" then
        pcall(function()
          vim.cmd("tcd " .. vim.g.new_tab_buf_cwd)
        end)
        vim.g.new_tab_buf_cwd = ""
      end
    end
  end,
})

-- ----------------------------------------------------------------------------
-- Superscript and subscript
-- ----------------------------------------------------------------------------
-- https://vi.stackexchange.com/a/29067
require("core.digraphs").register_digraphs()

-- ----------------------------------------------------------------------------
-- URL encode and decode
-- ----------------------------------------------------------------------------
vim.api.nvim_create_user_command("UrlEncode", function()
  -- Get the current visual selection range
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  -- Convert the positions to 0-indexed
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3] - 1

  -- Get the current buffer number
  local buf = vim.api.nvim_get_current_buf()
  -- Get the text from the buffer within the specified range
  local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
  -- Join the lines into a single string (if multiple lines)
  local text = table.concat(lines, "\n")
  -- Delete the text within the specified range
  vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, {})
  -- Get the current line
  local line = vim.api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1]
  -- url decoded string
  local replacement = require("core.utils").url_encode(text)
  -- Insert the new text at the specified column without replacing the character following
  local new_line = line:sub(1, start_col) .. replacement .. line:sub(start_col + 1)
  -- Set the modified line back to the buffer
  vim.api.nvim_buf_set_lines(buf, start_row, start_row + 1, false, { new_line })
end, { nargs = 0, range = true })

vim.api.nvim_create_user_command("UrlDecode", function()
  -- Get the current visual selection range
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  -- Convert the positions to 0-indexed
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3] - 1

  -- Get the current buffer number
  local buf = vim.api.nvim_get_current_buf()
  -- Get the text from the buffer within the specified range
  local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
  -- Join the lines into a single string (if multiple lines)
  local text = table.concat(lines, "\n")
  -- Delete the text within the specified range
  vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, {})
  -- Get the current line
  local line = vim.api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1]
  -- url decoded string
  local replacement = require("core.utils").url_decode(text)
  -- Insert the new text at the specified column without replacing the character following
  local new_line = line:sub(1, start_col) .. replacement .. line:sub(start_col + 1)
  -- Set the modified line back to the buffer
  vim.api.nvim_buf_set_lines(buf, start_row, start_row + 1, false, { new_line })
end, { nargs = 0, range = true })

-- ----------------------------------------------------------------------------
-- Toggle tab's cwd
-- ----------------------------------------------------------------------------
vim.api.nvim_create_user_command("TabCwd", function(args)
  if args == nil then
    vim.g.TabCwd = "1"
    -- vim.o.tabline = "%!v:lua.MyTabLine()"
    return
  end
  vim.g.TabCwd = args.args
  -- vim.o.tabline = "%!v:lua.MyTabLine()"
end, { nargs = "*" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.g.TabCwd = "3"
    vim.g.TabAutoCwd = "1"
    vim.g.TabCwdByProject = "0"
  end,
})

-- ----------------------------------------------------------------------------
-- Watch opened tab (for switching to previous opened tab)
-- ----------------------------------------------------------------------------
vim.g.last_tab_id = nil
vim.api.nvim_create_autocmd("TabLeave", {
  group = vim.api.nvim_create_augroup("WatchTabs", { clear = true }),
  callback = function()
    vim.g.last_tab_id = vim.api.nvim_get_current_tabpage()
  end,
})

-- ----------------------------------------------------------------------------
-- Don't add endofline automatically
-- ----------------------------------------------------------------------------
-- https://stackoverflow.com/a/4152785
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   callback = function()
--     vim.cmd("set binary")
--     vim.cmd("set noeol")
--   end,
-- })
--
-- vim.api.nvim_create_autocmd("BufWritePost", {
--   callback = function()
--     vim.cmd("set nobinary")
--     vim.cmd("set eol")
--   end,
-- })

-- ----------------------------------------------------------------------------
-- When switching tab, toggle the term
-- ----------------------------------------------------------------------------
-- If don't do this, the toggleterm state will become weird 🤔
vim.api.nvim_create_autocmd("TabLeave", {
  callback = function()
    if
        vim.g.toggle_term_opened
        and vim.g.toggle_term_direction ~= "float"
        and vim.g.toggle_term_direction ~= "tab"
    then
      require("plugins.configs.toggleterm_utils").toggle_term(vim.g.toggle_term_direction)
    end
  end,
})

-- float type need special treatment 🤨
vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    if vim.g.toggle_term_opened and vim.g.toggle_term_direction == "float" then
      require("plugins.configs.toggleterm_utils").toggle_term(vim.g.toggle_term_direction)
    end
  end,
})

-- ----------------------------------------------------------------------------
-- Disable cmp suggestion window once right after command window opened
-- ----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("CmdwinEnter", {
  callback = function()
    local has_cmp = pcall(require, "cmp")
    if has_cmp then
      require("cmp").close()
    end
  end,
})

-- ----------------------------------------------------------------------------
-- Go into insert mode right after command window opened
-- ----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("CmdwinEnter", {
  callback = function()
    vim.cmd("startinsert")
  end,
})

-- ----------------------------------------------------------------------------
-- Run SessionSearch after VimEnter
-- ----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      pcall(function()
        vim.cmd("SessionSearch")
      end)
    end
  end,
})

-- ----------------------------------------------------------------------------
-- Run SessionSave on VimLeavePre
-- ----------------------------------------------------------------------------
function _G.autosession_quitpre_completion_list(ArgLead, _, _)
  if pcall(require, "auto-session") then
    local autosession = require("auto-session")
    local session_dir = autosession.get_root_dir()
    local session_files = vim.fn.glob(session_dir .. "*", true, true)
    local session_names = {}

    local is_session_file = function(session_path)
      -- if it's a directory, don't include
      if vim.fn.isdirectory(session_path) ~= 0 then
        return false
      end

      -- if it's a file that doesn't end in x.vim, include
      if not string.find(session_path, "x.vim$") then
        return true
      end

      -- the file ends in x.vim, make sure it has SessionLoad on the first line
      local file = io.open(session_path, "r")
      if not file then
        return false
      end

      local first_line = file:read("*line")
      file:close()

      return first_line and string.find(first_line, "SessionLoad") ~= nil
    end

    for _, path in ipairs(session_files) do
      -- don't include extra user command files, aka *x.vim
      local file_name = vim.fn.fnamemodify(path, ":t:r")
      if is_session_file(session_dir .. file_name) then
        table.insert(session_names, file_name)
      end
    end

    return vim.tbl_filter(function(item)
      return item:match("^" .. ArgLead)
    end, session_names)
  end
  return {}
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    pcall(function()
      local user_input = vim.fn.input({
        prompt = "Saving session (Leave blank to quit without saving): ",
        completion = "customlist,v:lua.autosession_quitpre_completion_list",
      })

      local input = user_input:match("^%s*(.-)%s*$") or user_input
      if input ~= "" then
        vim.cmd("SessionSave " .. input)
      end
    end)
  end,
})

-- ----------------------------------------------------------------------------
-- Enable Treesitter Context
-- ----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    if pcall(require, "treesitter-context") then
      if require("treesitter-context").enabled() then
        vim.cmd("TSContextEnable")
      end
    end
  end,
})

-- ----------------------------------------------------------------------------
-- Load ext.lua file if available
-- ----------------------------------------------------------------------------
-- Load external lua file, only for customization done for each
-- neovim environment, for example my own docker container.
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/?.lua"
pcall(require, "ext")

-- ----------------------------------------------------------------------------
-- Enable code lens
-- ----------------------------------------------------------------------------
vim.g.lsp_codelens_started = 1
vim.api.nvim_create_user_command("LspCodeLensRun", function(opts)
  if vim.g.lsp_codelens_started == 1 then
    vim.g.lsp_codelens_started = 0
    vim.lsp.codelens.clear()
    vim.notify("Codelens is now off")
  else
    vim.g.lsp_codelens_started = 1
    vim.lsp.codelens.refresh()
    vim.notify("Codelens is now on")
  end
end, { nargs = "*" })

vim.api.nvim_create_autocmd({ "CmdLineLeave", "InsertLeave" }, {
  callback = function()
    if vim.g.lsp_codelens_started == 1 then
      vim.lsp.codelens.refresh() -- Refresh CodeLens on these events
    end
  end,
})
