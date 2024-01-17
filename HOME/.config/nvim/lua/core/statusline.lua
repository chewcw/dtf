local function bufnr()
  return "[%n]"
end

local function filepath()
  local fpath = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.:h")
  if fpath == "" or fpath == "." then
      return " "
  end

  return string.format(" %%<%s/", fpath)
end

local function filename()
  local fname = vim.fn.expand "%:t"
  if fname == "" then
      return ""
  end
  return fname
end

local function modified()
  return "%m"
end

local function lsp()
  local count = {}
  local levels = {
    errors = "Error",
    warnings = "Warn",
    info = "Info",
    hints = "Hint",
  }

  for k, level in pairs(levels) do
    count[k] = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
  end

  local errors = ""
  local warnings = ""
  local hints = ""
  local info = ""

  if count["errors"] ~= 0 then
    errors = " %#LspDiagnosticsSignError#E" .. count["errors"]
  end
  if count["warnings"] ~= 0 then
    warnings = " %#LspDiagnosticsSignWarning#W" .. count["warnings"]
  end
  if count["hints"] ~= 0 then
    hints = " %#LspDiagnosticsSignHint#H" .. count["hints"]
  end
  if count["info"] ~= 0 then
    info = " %#LspDiagnosticsSignInformation#I" .. count["info"]
  end

  local this_bufnr = vim.api.nvim_get_current_buf()
  local buf_clients = vim.lsp.get_active_clients({ bufnr = this_bufnr })

  local lsp_client_name = ""
  for _, client in ipairs(buf_clients) do
    if client.name == "null-ls" then
      goto continue
    end
    if lsp_client_name == "" then
      lsp_client_name = client.name
    else
      lsp_client_name = lsp_client_name .. "," .. client.name
    end
    ::continue::
  end

  return lsp_client_name .. errors .. warnings .. hints .. info
end

local function filetype()
  return vim.bo.filetype
end

local function lineinfo()
  if vim.bo.filetype == "alpha" then
    return ""
  end
  return " %l:%c "
end

local vcs = function()
  local git_info = vim.b.gitsigns_status_dict
  if not git_info or git_info.head == "" then
    return ""
  end
  local added = git_info.added and ("%#GitSignsAdd#+" .. git_info.added .. " ") or ""
  local changed = git_info.changed and ("%#GitSignsChange#~" .. git_info.changed .. " ") or ""
  local removed = git_info.removed and ("%#GitSignsDelete#-" .. git_info.removed .. " ") or ""
  if git_info.added == 0 then
    added = ""
  end
  if git_info.changed == 0 then
    changed = ""
  end
  if git_info.removed == 0 then
    removed = ""
  end
  return table.concat {
     " ",
     added,
     changed,
     removed,
     " ",
     "%#StatusLineText#",
     git_info.head,
  }
end

local cwd = function()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
end

local tabpage = function()
  return vim.api.nvim_get_current_tabpage()
end

Statusline = {}

Statusline.active = function()
  return table.concat {
    "%#StatusLineText#",
    bufnr(),
    " 🗁 ",
    filepath(),
    filename(),
    modified(),
    "  ",
    vcs(),
    "%=%#StatusLineExtra#",
    " 🚀 ",
    lsp(),
    "%#StatusLineText#",
    " 🗀  ",
    cwd(),
    " 🖉 ",
    lineinfo(),
    " ⭾ ",
    tabpage(),
  }
end

function Statusline.inactive()
  return table.concat({
    bufnr(),
    " 🗁 ",
    " %f",
    modified(),
    "%=%#StatusLineExtra#",
    " ⭾ ",
    tabpage(),
  })
end

function Statusline.short()
  return ""
end

vim.api.nvim_exec([[
  augroup Statusline
  au!
  au WinEnter,BufEnter * setlocal statusline=%!v:lua.Statusline.active()
  au WinLeave,BufLeave * setlocal statusline=%!v:lua.Statusline.inactive()
  au WinEnter,BufEnter,FileType NvimTree_1 setlocal statusline=%!v:lua.Statusline.short()
  au WinLeave,BufLeave,FileType NvimTree_1 setlocal statusline=%!v:lua.Statusline.short()
  augroup END
]], false)
