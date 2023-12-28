local M = {}

local highlight = function(group, color)
  vim.api.nvim_set_hl(0, group, color)
end

local get_highlight = function(group, type)
  return vim.api.nvim_get_hl_by_name(group, {})[type]
end

local colors = function()
  return {
    -- Basic
    bg = "#030a0e",
    bg_nc = "#101416",
    fg = "#bcbcbc",
    -- Normal
    main1 = "#EA907A",
    main2 = "#FBC687",
    main3 = "#F4F7C5",
    main4 = "#AACDBE",
    black = "#010507",
    red = "#e43845",
    green = "#618b79",
    yellow = "#e5c114",
    magenta = "#8a50a2",
    cyan = "#94c9b2",
    white = "#F9F9F9",
    brown = "#FFBF9B",
    dark_blue = "#05294a",
    -- Bright
    bright_black = "#4c4c4b",
    bright_red = "#ffafa5",
    bright_green = "#7aae98",
    bright_yellow = "#ffe35c",
    bright_blue = "#a6cded",
    bright_magenta = "#ac82bd",
    bright_cyan = "#94c9b2",
    bright_white = "#eaeaea",
    bright_brown = "#FFBF9B",
    -- Grays
    gray00 = "#1b1b1a",
    gray01 = "#222221",
    gray02 = "#2a2a29",
    gray03 = "#323231",
    gray04 = "#3a3a39",
    gray05 = "#6a6a69",
    gray06 = "#767675",
    gray07 = "#b6b6b5",
    -- Special
    none = "NONE",
  }
end

local function opt(key, default)
  key = "rasmus_" .. key
  if vim.g[key] == nil then
    return default
  end
  if vim.g[key] == 0 then
    return false
  end

  return vim.g[key]
end

local function style(italic, bold)
  return { bold = bold, italic = italic }
end

local cfg = {
  transparent = opt("transparent", false),
  comment_style = style(opt("italic_comments", false), opt("bold_comments", false)),
  keyword_style = style(opt("italic_keywords", false), opt("bold_keywords", false)),
  boolean_style = style(opt("italic_booleans", false), opt("bold_booleans", false)),
  function_style = style(opt("italic_functions", false), opt("bold_functions", false)),
  variable_style = style(opt("italic_variables", false), opt("bold_variables", false)),
}

M.setup = function()
  vim.api.nvim_command("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.api.nvim_command("syntax reset")
  end

  vim.o.termguicolors = true
  vim.g.colors_name = "rasmus"
  vim.o.background = "dark"

  local c = colors()

  vim.g.terminal_color_0 = c.black
  vim.g.terminal_color_1 = c.red
  vim.g.terminal_color_2 = c.main2
  vim.g.terminal_color_3 = c.yellow
  vim.g.terminal_color_4 = c.main1
  vim.g.terminal_color_5 = c.magenta
  vim.g.terminal_color_6 = c.main4
  vim.g.terminal_color_7 = c.white
  vim.g.terminal_color_8 = c.bright_black
  vim.g.terminal_color_9 = c.bright_red
  vim.g.terminal_color_10 = c.bright_green
  vim.g.terminal_color_11 = c.bright_yellow
  vim.g.terminal_color_12 = c.bright_blue
  vim.g.terminal_color_13 = c.bright_magenta
  vim.g.terminal_color_14 = c.bright_cyan
  vim.g.terminal_color_15 = c.bright_white
  vim.g.terminal_color_background = c.bg
  vim.g.terminal_color_foreground = c.fg

  local groups = {
    -- Base
    -- Editor highlight groups
    Normal = { fg = c.fg, bg = cfg.transparent and c.none or c.bg },
    NormalNC = { fg = c.fg, bg = cfg.transparent and c.none or c.bg_nc },
    SignColumn = { fg = c.fg, bg = c.none },
    EndOfBuffer = { fg = c.gray03 },
    NormalFloat = { fg = get_highlight("FloatBorder", "foreground"), bg = get_highlight("Normal", "background") },
    FloatBorder = { fg = c.gray03, bg = c.bg },
    ColorColumn = { fg = c.none, bg = c.bg_nc },
    Conceal = { fg = c.gray05 },
    Cursor = { fg = c.main4, bg = c.none, reverse = true },
    CursorIM = { fg = c.main4, bg = c.none, reverse = true },
    Directory = { fg = c.main1, bg = c.none, bold = true },

    DiffAdd = { bg = c.bright_green, fg = c.black },
    DiffAdded = { bg = c.bright_green, fg = c.black },
    DiffChange = { fg = c.gray07, bg = c.dark_blue, },
    DiffChanged = { bg = c.dark_blue, fg = c.gray07 },
    DiffChangeDelete = { bg = c.magenta, fg = c.gray07 },
    DiffDelete = { bg = c.red, fg = c.black },
    DiffRemoved = { bg = c.red, fg = c.black },
    DiffText = { fg = c.gray07, bg = c.dark_blue, },
    DiffModified = { bg = c.cyan, fg = c.black },
    DiffNewFile = { bg = c.cyan, fg = c.black },

    ErrorMsg = { fg = c.red },
    Folded = { fg = c.gray05, bg = c.none, italic = true },
    FoldColumn = { fg = c.main1 },
    IncSearch = { reverse = true },
    LineNr = { fg = c.gray05 },
    CursorLineNr = { fg = c.main1 },
    MatchParen = { fg = c.yellow },
    ModeMsg = { fg = c.main4, bold = true },
    MoreMsg = { fg = c.main4, bold = true },
    NonText = { fg = c.gray03 },
    Pmenu = { bg = c.bg },
    PmenuSel = { fg = c.bg, bg = c.gray06 },
    PmenuSbar = { fg = c.fg, bg = c.gray02 },
    PmenuThumb = { fg = c.fg, bg = c.gray05 },
    Question = { fg = c.main2, bold = true },
    QuickFixLine = { fg = c.main1, bg = c.gray01, bold = true, italic = true },
    qfLineNr = { fg = c.main1, bg = c.gray01 },
    Search = { reverse = true },
    SpecialKey = { fg = c.gray03 },
    SpellBad = { fg = c.red, bg = c.none, italic = true, undercurl = true },
    SpellCap = { fg = c.main1, bg = c.none, italic = true, undercurl = true },
    SpellLocal = { fg = c.main4, bg = c.none, italic = true, undercurl = true },
    SpellRare = { fg = c.main4, bg = c.none, italic = true, undercurl = true },
    StatusLine = { link = "Normal" },
    StatusLineNC = { link = "NormalNC" },
    StatusLineTerm = { fg = c.gray07, bg = c.gray01 },
    StatusLineTermNC = { fg = c.gray07, bg = c.gray01 },
    TabLineFill = { fg = c.gray05, bg = c.gray01 },
    TablineSel = { fg = c.bg, bg = c.gray07 },
    Tabline = { fg = c.gray05 },
    Title = { fg = c.main4, bg = c.none, bold = true },
    Visual = { fg = c.none, bg = c.gray03 },
    VisualNOS = { fg = c.none, bg = c.gray03 },
    WarningMsg = { fg = c.yellow, bold = true },
    WildMenu = { fg = c.bg, bg = c.main1, bold = true },
    CursorColumn = { fg = c.none, bg = c.gray02 },
    CursorLine = { fg = c.none, bg = c.none },
    ToolbarLine = { fg = c.fg, bg = c.gray01 },
    ToolbarButton = { fg = c.fg, bg = c.none, bold = true },
    NormalMode = { fg = c.main4, bg = c.none, reverse = true },
    InsertMode = { fg = c.main2, bg = c.none, reverse = true },
    VisualMode = { fg = c.main4, bg = c.none, reverse = true },
    VertSplit = { fg = c.gray02 },
    CommandMode = { fg = c.gray05, bg = c.none, reverse = true },
    Warnings = { fg = c.yellow },
    healthError = { fg = c.red },
    healthSuccess = { fg = c.main2 },
    healthWarning = { fg = c.yellow },
    --common
    Type = { fg = c.main4 },                                                                                     -- int, long, char, etc.
    StorageClass = { fg = c.main4 },                                                                             -- static, register, volatile, etc.
    Structure = { fg = c.fg },                                                                                  -- struct, union, enum, etc.
    Constant = { fg = c.main4 },                                                                                 -- any constant
    Comment = { fg = c.gray05, bg = c.none, bold = cfg.comment_style.bold, italic = cfg.comment_style.italic }, -- italic comments
    Conditional = { fg = c.main1, bg = c.none, bold = cfg.keyword_style.bold, italic = cfg.keyword_style.italic }, -- italic if, then, else, endif, switch, etc.
    Keyword = { fg = c.main2, bg = c.none, bold = cfg.keyword_style.bold, italic = cfg.keyword_style.italic },   -- italic for, do, while, etc.
    Repeat = { fg = c.main1, bg = c.none, bold = cfg.keyword_style.bold, italic = cfg.keyword_style.italic },    -- italic any other keyword
    Boolean = { fg = c.main4, bg = c.none, bold = cfg.boolean_style.bold, italic = cfg.boolean_style.italic },   -- true , false
    Function = { fg = c.main3, bg = c.none, bold = cfg.function_style.bold, italic = cfg.function_style.italic },
    Identifier = { fg = c.main1, bg = c.none },                                                                  -- any variable name
    String = { fg = c.main4, bg = c.none },                                                                      -- Any string
    Character = { fg = c.main4 },                                                                                -- any character constant: 'c', '\n'
    Number = { fg = c.main4 },                                                                                   -- a number constant: 5
    Float = { fg = c.main4 },                                                                                    -- a floating point constant: 2.3e10
    Statement = { fg = c.main2 },                                                                                -- any statement
    Label = { fg = c.main4 },                                                                                    -- case, default, etc.
    Operator = { fg = c.gray07 },                                                                               -- sizeof", "+", "*", etc.
    Exception = { fg = c.yellow },                                                                              -- try, catch, throw
    PreProc = { fg = c.main1 },                                                                                   -- generic Preprocessor
    Include = { fg = c.main1 },                                                                                  -- preprocessor #include
    Define = { fg = c.main4 },                                                                                   -- preprocessor #define
    Macro = { fg = c.main1 },                                                                                    -- same as Define
    Typedef = { fg = c.main4 },                                                                                  -- A typedef
    PreCondit = { fg = c.main4 },                                                                                -- preprocessor #if, #else, #endif, etc.
    Special = { fg = c.gray07, bg = c.none },                                                                     -- any special symbol
    SpecialChar = { fg = c.gray07 },                                                                              -- special character in a constant
    Tag = { fg = c.yellow },                                                                                    -- you can use CTRL-] on this
    Delimiter = { fg = c.gray07 },                                                                              -- character that needs attention like , or .
    SpecialComment = { fg = c.main1 },                                                                           -- special things inside a comment
    Debug = { fg = c.main4 },                                                                                     -- debugging statements
    Underlined = { fg = c.main4, bg = c.none, underline = true },                                                -- text that stands out, HTML links
    Ignore = { fg = c.gray07 },                                                                                 -- left blank, hidden
    Error = { fg = c.red, bg = c.none, bold = true, underline = true },                                         -- any erroneous construct
    Todo = { fg = c.main4, bg = c.none, bold = true, italic = true },                                            -- anything that needs extra attention; mostly the keywords TODO FIXME and XXX
    -- HTML
    htmlArg = { fg = c.fg },
    htmlBold = { fg = c.fg, bg = c.none, bold = true },
    htmlEndTag = { fg = c.fg },
    htmlStyle = { fg = c.main4, bg = c.none },
    htmlLink = { fg = c.main4 },
    htmlSpecialChar = { fg = c.yellow },
    htmlSpecialTagName = { fg = c.main1 },
    htmlTag = { fg = c.fg },
    htmlTagN = { fg = c.yellow },
    htmlTagName = { fg = c.yellow },
    htmlTitle = { fg = c.fg },
    htmlH1 = { fg = c.main1, bold = true },
    htmlH2 = { fg = c.main1, bold = true },
    htmlH3 = { fg = c.main1, bold = true },
    htmlH4 = { fg = c.main1, bold = true },
    htmlH5 = { fg = c.main1, bold = true },
    -- Markdown
    markdownH1 = { fg = c.bright_white, bold = true },
    markdownH2 = { fg = c.bright_white, bold = true },
    markdownH3 = { fg = c.bright_white, bold = true },
    markdownH4 = { fg = c.bright_white, bold = true },
    markdownH5 = { fg = c.bright_white, bold = true },
    markdownH6 = { fg = c.bright_white, bold = true },
    markdownHeadingDelimiter = { fg = c.gray05 },
    markdownHeadingRule = { fg = c.gray05 },
    markdownId = { fg = c.main4 },
    markdownIdDeclaration = { fg = c.main1 },
    markdownIdDelimiter = { fg = c.main4 },
    markdownLinkDelimiter = { fg = c.gray05 },
    markdownLinkText = { fg = c.bright_white },
    markdownListMarker = { fg = c.yellow },
    markdownOrderedListMarker = { fg = c.yellow },
    markdownRule = { fg = c.gray05 },
    markdownUrl = { fg = c.gray06, bg = c.none },
    markdownBlockquote = { fg = c.gray07 },
    markdownBold = { fg = c.fg, bg = c.none, bold = true },
    markdownItalic = { fg = c.fg, bg = c.none, italic = true },
    markdownCode = { fg = c.fg, bg = c.gray02 },
    markdownCodeBlock = { fg = c.fg, bg = c.gray02 },
    markdownCodeDelimiter = { fg = c.fg, bg = c.gray02 },
    -- Dashboard
    DashboardShortCut = { fg = c.main4 },
    DashboardHeader = { fg = c.main4 },
    DashboardCenter = { fg = c.main1 },
    DashboardFooter = { fg = c.main2, italic = true },
    -- TreeSitter highlight groups
    TSAnnotation = { fg = c.main2 },                                                                            -- For C++/Dart attributes, annotations that can be attached to the code to denote some kind of meta information.
    TSAttribute = { fg = c.fg },                                                                                -- (unstable) TODO: docs
    TSBoolean = { fg = c.main4, bg = c.none, bold = cfg.boolean_style.bold, italic = cfg.boolean_style.italic }, -- true or false
    TSCharacter = { fg = c.main4 },                                                                              -- For characters.
    TSComment = { fg = c.gray05, bg = c.none, bold = cfg.comment_style.bold, italic = cfg.comment_style.italic }, -- For comment blocks.
    TSConditional = { fg = c.main1, bold = cfg.keyword_style.bold, italic = cfg.keyword_style.italic },          -- For keywords related to conditionnals.
    TSConstant = { fg = c.fg },                                                                                 -- For constants
    TSConstBuiltin = { fg = c.main4, italic = true },                                                            -- For constants that are built in the language: `nil` in Lua.
    TSConstMacro = { fg = c.main4 },                                                                             -- For constants that are defined by macros: `NULL` in C.
    TSConstructor = { fg = c.gray07 },                                                                          -- For constructor calls and definitions: `= { }` in Lua, and Java constructors.
    TSError = { fg = c.red },                                                                                   -- For syntax/parser errors.
    TSException = { fg = c.yellow },                                                                            -- For exception related keywords.
    TSField = { fg = c.main4 },                                                                                  -- For fields.
    TSFloat = { fg = c.main4 },                                                                                  -- For floats.
    TSFunction = { fg = c.fg, bold = cfg.function_style.bold, italic = cfg.function_style.italic },             -- For fuction (calls and definitions).
    TSFuncBuiltin = { fg = c.fg, bold = cfg.function_style.bold, italic = cfg.function_style.italic },          -- For builtin functions: `table.insert` in Lua.
    TSFuncMacro = { fg = c.main1 },                                                                              -- For macro defined fuctions (calls and definitions): each `macro_rules` in Rust.
    TSInclude = { fg = c.main1, italic = true },                                                                 -- For includes: `#include` in C, `use` or `extern crate` in Rust, or `require` in Lua.
    TSKeyword = { fg = c.main1, bold = cfg.keyword_style.bold, italic = cfg.keyword_style.italic },              -- For keywords that don't fall in previous categories.
    TSKeywordFunction = { fg = c.main1, bold = cfg.function_style.bold, italic = cfg.function_style.italic },    -- For keywords used to define a fuction.
    TSKeywordOperator = { fg = c.yellow },                                                                      -- For operators that are English words, e.g. `and`, `as`, `or`.
    TSKeywordReturn = { fg = c.main1, bold = cfg.keyword_style.bold, italic = cfg.keyword_style.italic },        -- For the `return` and `yield` keywords.
    TSLabel = { fg = c.main4 },                                                                                  -- For labels: `label:` in C and `:label:` in Lua.
    TSMethod = { fg = c.bright_blue, bold = cfg.function_style.bold, italic = cfg.function_style.italic },      -- For method calls and definitions.
    TSNamespace = { fg = c.main1 },                                                                              -- For identifiers referring to modules and namespaces.
    -- TSNone = {}, -- No highlighting. Don't change the values of this highlight group.
    TSNumber = { fg = c.main4 },                                                                                 -- For all numbers
    TSOperator = { fg = c.yellow },                                                                             -- For any operator: `+`, but also `->` and `*` in C.
    TSParameter = { fg = c.fg },                                                                                -- For parameters of a function.
    TSParameterReference = { fg = c.fg },                                                                       -- For references to parameters of a function.
    TSProperty = { fg = c.main1 },                                                                               -- Same as `TSField`.
    TSPunctDelimiter = { fg = c.gray05 },                                                                       -- For delimiters ie: `.`
    TSPunctBracket = { fg = c.gray05 },                                                                         -- For brackets and parens.
    TSPunctSpecial = { fg = c.main2 },                                                                          -- For special punctutation that does not fall in the catagories before.
    TSRepeat = { fg = c.main1, bold = cfg.keyword_style.bold, italic = cfg.keyword_style.italic },               -- For keywords related to loops.
    TSString = { fg = c.main4 },                                                                                 -- For strings.
    TSStringRegex = { fg = c.main2 },                                                                           -- For regexes.
    TSStringEscape = { fg = c.main4 },                                                                           -- For escape characters within a string.
    TSStringSpecial = { fg = c.main2 },                                                                         -- For strings with special meaning that don't fit into the above categories.
    TSSymbol = { fg = c.main2 },                                                                                -- For identifiers referring to symbols or atoms.
    TSTag = { fg = c.main2 },                                                                                  -- Tags like html tag names.
    TSTagAttribute = { fg = c.fg },                                                                             -- For html tag attributes.
    TSTagDelimiter = { fg = c.gray05 },                                                                         -- Tag delimiter like `<` `>` `/`
    TSText = { fg = c.fg },                                                                                     -- For strings considered text in a markup language.
    TSStrong = { fg = c.bright_white, bold = true },                                                            -- For text to be represented in bold.
    TSEmphasis = { fg = c.bright_white, bold = true },                                                          -- For text to be represented with emphasis.
    TSUnderline = { fg = c.bright_white, bg = c.none, underline = true },                                       -- For text to be represented with an underline.
    TSStrike = {},                                                                                              -- For strikethrough text.
    TSTitle = { fg = c.fg, bg = c.none, bold = true },                                                          -- Text that is part of a title.
    TSLiteral = { fg = c.fg },                                                                                  -- Literal text.
    TSURI = { fg = c.main4 },                                                                                    -- Any URL like a link or email.
    TSMath = { fg = c.main1 },                                                                                   -- For LaTeX-like math environments.
    TSTextReference = { fg = c.yellow },                                                                        -- For footnotes, text references, citations.
    TSEnvironment = { fg = c.main1 },                                                                            -- For text environments of markup languages.
    TSEnvironmentName = { fg = c.bright_blue },                                                                 -- For the name/the string indicating the type of text environment.
    TSNote = { fg = c.main1 },                                                                                   -- Text representation of an informational note.
    TSWarning = { fg = c.yellow },                                                                              -- Text representation of a warning note.
    TSDanger = { fg = c.red },                                                                                  -- Text representation of a danger note.
    TSType = { fg = c.fg },                                                                                     -- For types.
    TSTypeBuiltin = { fg = c.main1 },                                                                            -- For builtin types.
    TSVariable = { fg = c.fg, bold = cfg.variable_style.bold, italic = cfg.variable_style.italic },             -- Any variable name that does not have another highlight.
    TSVariableBuiltin = { fg = c.yellow, bold = cfg.variable_style.bold, italic = cfg.variable_style.italic },  -- Variable names that are defined by the languages, like `this` or `self`.
    -- highlight groups for the native LSP client
    LspReferenceText = { fg = c.bg, bg = c.magenta },                                                           -- used for highlighting "text" references
    LspReferenceRead = { fg = c.bg, bg = c.magenta },                                                           -- used for highlighting "read" references
    LspReferenceWrite = { fg = c.bg, bg = c.magenta },                                                          -- used for highlighting "write" references
    -- Diagnostics
    DiagnosticError = { fg = c.red },                                                                           -- base highlight group for "Error"
    DiagnosticWarn = { fg = c.yellow },                                                                         -- base highlight group for "Warning"
    DiagnosticInfo = { fg = c.main1 },                                                                           -- base highlight group from "Information"
    DiagnosticHint = { fg = c.gray05 },                                                                           -- base highlight group for "Hint"
    DiagnosticVirtualTextError = { link = "DiagnosticError" },
    DiagnosticVirtualTextWarn = { link = "DiagnosticWarn" },
    DiagnosticVirtualTextInfo = { link = "DiagnosticInfo" },
    DiagnosticVirtualTextHint = { link = "DiagnosticHint" },
    DiagnosticUnderlineError = { fg = c.red, undercurl = true, sp = c.red },           -- used to underline "Error" diagnostics.
    DiagnosticUnderlineWarn = { fg = c.yellow, undercurl = true, sp = c.yellow },      -- used to underline "Warning" diagnostics.
    DiagnosticUnderlineInfo = { fg = c.main1, undercurl = true, sp = c.main1 },          -- used to underline "Information" diagnostics.
    DiagnosticUnderlineHint = { fg = c.gray05, undercurl = true, sp = c.gray05 },          -- used to underline "Hint" diagnostics.
    -- Diagnostics (old)
    LspDiagnosticsDefaultError = { fg = c.red },                                       -- used for "Error" diagnostic virtual text
    LspDiagnosticsSignError = { fg = c.red },                                          -- used for "Error" diagnostic signs in sign column
    LspDiagnosticsFloatingError = { fg = c.red, bold = true },                         -- used for "Error" diagnostic messages in the diagnostics float
    LspDiagnosticsVirtualTextError = { fg = c.red, bold = true },                      -- Virtual text "Error"
    LspDiagnosticsUnderlineError = { fg = c.red, undercurl = true, sp = c.red },       -- used to underline "Error" diagnostics.
    LspDiagnosticsDefaultWarning = { fg = c.yellow },                                  -- used for "Warning" diagnostic signs in sign column
    LspDiagnosticsSignWarning = { fg = c.yellow },                                     -- used for "Warning" diagnostic signs in sign column
    LspDiagnosticsFloatingWarning = { fg = c.yellow, bold = true },                    -- used for "Warning" diagnostic messages in the diagnostics float
    LspDiagnosticsVirtualTextWarning = { fg = c.yellow, bold = true },                 -- Virtual text "Warning"
    LspDiagnosticsUnderlineWarning = { fg = c.yellow, undercurl = true, sp = c.yellow }, -- used to underline "Warning" diagnostics.
    LspDiagnosticsDefaultInformation = { fg = c.main1 },                                -- used for "Information" diagnostic virtual text
    LspDiagnosticsSignInformation = { fg = c.main1 },                                   -- used for "Information" diagnostic signs in sign column
    LspDiagnosticsFloatingInformation = { fg = c.main1, bold = true },                  -- used for "Information" diagnostic messages in the diagnostics float
    LspDiagnosticsVirtualTextInformation = { fg = c.main1, bold = true },               -- Virtual text "Information"
    LspDiagnosticsUnderlineInformation = { fg = c.main1, undercurl = true, sp = c.main1 }, -- used to underline "Information" diagnostics.
    LspDiagnosticsDefaultHint = { fg = c.gray05 },                                       -- used for "Hint" diagnostic virtual text
    LspDiagnosticsSignHint = { fg = c.gray05 },                                          -- used for "Hint" diagnostic signs in sign column
    LspDiagnosticsFloatingHint = { fg = c.gray05, bold = true },                         -- used for "Hint" diagnostic messages in the diagnostics float
    LspDiagnosticsVirtualTextHint = { fg = c.gray05, bold = true },                      -- Virtual text "Hint"
    LspDiagnosticsUnderlineHint = { fg = c.gray05, undercurl = true, sp = c.main4 },      -- used to underline "Hint" diagnostics.
    -- Plugins highlight groups
    -- LspTrouble
    LspTroubleText = { fg = c.gray04 },
    LspTroubleCount = { fg = c.magenta, bg = c.gray03 },
    LspTroubleNormal = { fg = c.fg, bg = c.bg },
    -- GitSigns
    GitSignsAdd = { fg = c.bright_green },     -- diff mode: Added line |diff.txt|
    GitSignsAddNr = { fg = c.bright_green },   -- diff mode: Added line |diff.txt|
    GitSignsAddLn = { fg = c.bright_green },   -- diff mode: Added line |diff.txt|
    GitSignsChange = { fg = c.bright_yellow }, -- diff mode: Changed line |diff.txt|
    GitSignsChangeNr = { fg = c.bright_yellow }, -- diff mode: Changed line |diff.txt|
    GitSignsChangeLn = { fg = c.bright_yellow }, -- diff mode: Changed line |diff.txt|
    GitSignsDelete = { fg = c.bright_red },    -- diff mode: Deleted line |diff.txt|
    GitSignsDeleteNr = { fg = c.bright_red },  -- diff mode: Deleted line |diff.txt|
    GitSignsDeleteLn = { fg = c.bright_red },  -- diff mode: Deleted line |diff.txt|
    -- Telescope
    TelescopeSelectionCaret = { fg = c.main1, bg = c.gray01 },
    TelescopeBorder = { link = "FloatBorder" },
    TelescopePromptBorder = { link = "FloatBorder" },
    TelescopeResultsBorder = { link = "FloatBorder" },
    TelescopePreviewBorder = { link = "FloatBorder" },
    TelescopeMatching = { fg = c.yellow },
    TelescopePromptPrefix = { fg = c.main1 },
    -- NvimTree
    NvimTreeRootFolder = { fg = c.main4 },
    NvimTreeNormal = { fg = c.fg, bg = cfg.transparent and c.none or c.bg },
    NvimTreeNormalNC = { fg = c.fg, bg = cfg.transparent and c.none or c.bg_nc },
    NvimTreeLineNr = { fg = c.fg, bg = c.none },
    NvimTreeSignColumn = { fg = c.fg, bg = c.none },
    NvimTreeImageFile = { fg = c.magenta },
    NvimTreeExecFile = { fg = c.main2 },
    NvimTreeSpecialFile = {},
    NvimTreeFolderName = { fg = c.main1 },
    NvimTreeOpenedFolderName = { fg = c.bright_blue },
    NvimTreeOpenedFile = { fg = c.bright_blue },
    NvimTreeEmptyFolderName = { fg = c.gray05 },
    NvimTreeFolderIcon = { fg = c.gray07 },
    NvimTreeIndentMarker = { fg = c.gray03 },
    NvimTreeGitDirty = { fg = c.gray07 },
    NvimTreeGitStaged = { fg = c.main4 },
    NvimTreeGitRenamed = { fg = c.yellow },
    NvimTreeGitNew = { fg = c.main2 },
    NvimTreeGitDeleted = { fg = c.red },
    -- WhichKey
    WhichKey = { fg = c.bright_cyan },
    WhichKeyGroup = { fg = c.yellow },
    WhichKeyDesc = { fg = c.main1 },
    WhichKeySeperator = { fg = c.gray05 },
    WhichKeyFloating = { bg = c.gray01 },
    WhichKeyFloat = { link = "FloatBorder" },
    WhichKeyNormal = { link = "Normal" },
    -- Indent Blankline
    IndentBlanklineChar = { fg = c.gray00 },
    IndentBlanklineContextChar = { bg = c.gray00 },
    IndentBlanklineSpaceChar = { link = "IndentBlanklineChar" },
    IndentBlanklineSpaceCharBlankline = { link = "IndentBlanklineChar" },
    IndentBlanklineContextSpaceChar = { default = true },
    -- nvim-cmp
    CmpItemAbbrDeprecated = { fg = c.gray05, strikethrough = true },
    CmpItemAbbrMatch = { fg = c.yellow },
    CmpItemAbbrMatchFuzzy = { fg = c.yellow },
    CmpItemKindVariable = { fg = c.main1 },
    CmpItemKindInterface = { fg = c.main1 },
    CmpItemKindText = { fg = c.main1 },
    CmpItemKindFunction = { fg = c.magenta },
    CmpItemKindMethod = { fg = c.magenta },
    CmpItemKindKeyword = { fg = c.fg },
    CmpItemKindProperty = { fg = c.fg },
    CmpItemKindUnit = { fg = c.fg },
    -- Custom highlight groups for use in statusline plugins
    StatusLineNormalMode = { fg = c.black, bg = c.gray02 },
    StatusLineInsertMode = { fg = c.black, bg = c.gray03 },
    StatusLineVisualMode = { fg = c.black, bg = c.gray04 },
    StatusLineReplaceMode = { fg = c.black, bg = c.gray05 },
    StatusLineTerminalMode = { fg = c.black, bg = c.gray05 },
    StatusLineHint = { fg = c.main4, bg = c.none },
    StatusLineInfo = { fg = c.main1, bg = c.none },
    StatusLineWarn = { fg = c.yellow, bg = c.none },
    StatusLineError = { fg = c.red, bg = c.none },
    -- JSON
    jsonNumber = { fg = c.yellow },
    jsonNull = { fg = c.bright_black },
    jsonString = { fg = c.main2 },
    jsonKeyword = { fg = c.main1 },
    -- Treesitter context
    TreesitterContextSeparator = { fg = c.gray03 },
    TreesitterContext = { fg = c.fg, bg = cfg.transparent and c.none or c.bg },
    TreesitterContextLineNumber = { fg = c.fg, bg = cfg.transparent and c.none or c.bg },
    -- Neogit
    NeogitDiffAdd = { fg = get_highlight("DiffAdd", "foreground"), bg = c.none },
    -- NeogitDiffAdded = { fg = get_highlight("DiffAdded", "foreground") },
    NeogitDiffChange = { fg = get_highlight("DiffChange", "background"), bg = c.none },
    -- NeogitDiffChanged = { fg = get_highlight("DiffChanged", "foreground") },
    NeogitDiffDelete = { fg = get_highlight("DiffDelete", "background"), bg = c.none },
    -- NeogitDiffRemoved = { fg = get_highlight("DiffRemoved", "foreground", bg = c.none) },
    NeogitDiffText = { fg = get_highlight("DiffText", "foreground"), bg = c.none },
    -- NeogitDiffModified = { fg = get_highlight("DiffModified", "foreground") },
    -- NeogitDiffChangeDelete = { fg = get_highlight("DiffChangeDelete", "foreground") },
    -- NeogitDiffNewFile = { fg = get_highlight("DiffNewFile", "foreground") },
    NeogitDiffAddHighlight = {},
    NeogitDiffcontext = {},
    NeogitDiffContextHighlight = {},
    NeogitDiffDeleteHighlight = {},
    NeogitDiffHeaderHighlight = {},
  }

  for group, parameters in pairs(groups) do
    highlight(group, parameters)
  end
end

return M
