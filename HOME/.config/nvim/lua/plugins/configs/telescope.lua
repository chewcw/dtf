local telescope_utils = require("plugins.configs.telescope_utils")

local M = {}

local picker_width = vim.o.columns
local picker_height = 0.85

M.options = {
  defaults = {
    -- remember to update telescope_utils file custom_rg as well
    vimgrep_arguments = {
      "rg",
      unpack(telescope_utils.rg_args),
    },
    scroll_strategy = "limit",
    prompt_prefix = "",
    selection_caret = "  ",
    entry_prefix = "  ",
    initial_mode = "normal",
    selection_strategy = "reset",
    sorting_strategy = "ascending",
    -- https://github.com/nvim-telescope/telescope.nvim/issues/848#issuecomment-1437928837
    layout_strategy = "bottom_pane",
    cache_picker = {
      num_pickers = -1,
    },
    preview = true,
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.50,
        results_width = 0.50,
      },
      vertical = {
        mirror = false,
      },
      width = picker_width,
      height = picker_height,
      preview_cutoff = 120,
    },
    fname_width = 50,
    file_sorter = require("telescope.sorters").get_fuzzy_file,
    file_ignore_patterns = {},
    generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
    path_display = { "filename_first" },
    winblend = 0,
    border = true,
    -- borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
    -- borderchars = { "=", "", "", "", "", "", "", "" },
    color_devicons = true,
    set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
    file_previewer = require("telescope.previewers").vim_buffer_cat.new,
    grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
    qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
    -- get_selection_window = function(picker, entry)
    --   -- print(inspect(picker))
    --   local s = picker.original_win_id
    --   vim.ui.input({ prompt = "Pick window: " }, function(input)
    --     s = tonumber(input)
    --   end)
    --   return s
    -- end,
    -- Developer configurations: Not meant for general override
    buffer_previewer_maker = telescope_utils.custom_previewer(),
    mappings = {
      i = {
        ["<C-j>"] = require("telescope.actions").move_selection_next,
        ["<C-k>"] = require("telescope.actions").move_selection_previous,
        ["<C-n>"] = require("telescope.actions").move_selection_next,
        ["<C-p>"] = require("telescope.actions").move_selection_previous,
        ["<C-A-\\>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "vsplit")
        end,
        ["<A-\\>"] = telescope_utils.select_direction("vertical"),
        ["<C-A-_>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "split")
        end,
        ["<A-_>"] = telescope_utils.select_direction("horizontal"),
        ["<C-A-e>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker_and_set_cwd(prompt_bufnr, "tabe")
        end,
        ["<A-e>"] = telescope_utils.open_telescope_file_in_tab(true),
        ["<A-[>"] = require("telescope.actions").preview_scrolling_left,
        ["<A-]>"] = require("telescope.actions").preview_scrolling_right,
        ["<A-u>"] = require("telescope.actions").preview_scrolling_up,
        ["<A-d>"] = require("telescope.actions").preview_scrolling_down,
        ["<C-u>"] = require("telescope.actions").results_scrolling_up,
        ["<C-d>"] = require("telescope.actions").results_scrolling_down,
        ["<A-{>"] = require("telescope.actions").results_scrolling_left,
        ["<A-}>"] = require("telescope.actions").results_scrolling_right,
        ["<C-t>"] = require("trouble.sources.telescope").open,
        ["<C-h>"] = function()
          local keys = vim.api.nvim_replace_termcodes("<C-h>", false, false, true)
          vim.api.nvim_feedkeys(keys, "n", {})
        end,
        ["<C-A-l>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "edit")
        end,
        ["<C-l>"] = require("telescope.actions").select_default,
      },
      n = {
        ["<C-j>"] = require("telescope.actions").move_selection_next,
        ["<C-k>"] = require("telescope.actions").move_selection_previous,
        ["<C-n>"] = require("telescope.actions").move_selection_next,
        ["<C-p>"] = require("telescope.actions").move_selection_previous,
        ["<A-[>"] = require("telescope.actions").preview_scrolling_left,
        ["<A-]>"] = require("telescope.actions").preview_scrolling_right,
        ["<A-u>"] = require("telescope.actions").preview_scrolling_up,
        ["<A-d>"] = require("telescope.actions").preview_scrolling_down,
        ["<C-u>"] = require("telescope.actions").results_scrolling_up,
        ["<C-d>"] = require("telescope.actions").results_scrolling_down,
        ["{"] = require("telescope.actions").results_scrolling_left,
        ["}"] = require("telescope.actions").results_scrolling_right,
        ["<C-t>"] = require("trouble.sources.telescope").open,
        ["<A-\\>"] = telescope_utils.select_direction("vertical"),
        ["<C-A-\\>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "vsplit")
        end,
        ["<A-_>"] = telescope_utils.select_direction("horizontal"),
        ["<C-A-_>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "split")
        end,
        ["<C-A-e>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker_and_set_cwd(prompt_bufnr, "tabe")
        end,
        ["<A-e>"] = telescope_utils.open_telescope_file_in_tab(true),
        -- toggle all
        ["<C-a>"] = require("telescope.actions").toggle_all,
        ["q"] = require("telescope.actions").close,
        ["u"] = function()
          vim.cmd("undo")
        end,
        ["<Esc>"] = function() end, -- don't do anything
        ["<C-A-l>"] = function(prompt_bufnr)
          telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "edit")
        end,
        ["<C-l>"] = require("telescope.actions").select_default,
        ["i"] = (function()
          local insert_mode = function()
            vim.cmd("startinsert")
          end
          return insert_mode
        end)(),
        ["/"] = (function()
          local insert_mode = function()
            vim.cmd("startinsert")
          end
          return insert_mode
        end)(),
        -- select window (which split) to open
        ["<leader>ow"] = telescope_utils.select_window_to_open,
        ["<leader>oT"] = function()
          telescope_utils.open_telescope_file_in_specfic_tab()
        end,
        ["<leader>ot"] = telescope_utils.open_telescope_file_in_tab(false),
        -- toggle preview
        ["\\p"] = require("telescope.actions.layout").toggle_preview,
        -- copy absolute path
        ["<A-y>"] = require("plugins.configs.telescope_utils").copy_absolute_file_path_in_picker(),
        -- open previous picker
        ["<Backspace>"] = require("plugins.configs.telescope_utils").resume_with_cache,
        ["<C-A-d>"] = function() end,
        ["<A-S-d>"] = function() end,
        ["<A-k>"] = function() end,
      },
    },
  },

  extensions_list = { "file_browser", "workspaces", "ui-select", "fzf", "quicknote" },

  extensions = {
    file_browser = {
      path = "%:p:h",
      prompt_title = "File Browser",
      -- cwd = vim.fn.expand("%:p:h"),
      -- cwd_to_path = true,
      grouped = true,
      hijack_netrw = false,
      hidden = true,
      initial_mode = "normal",
      select_buffer = true,
      layout_config = {
        horizontal = {
          prompt_position = "top",
          preview_width = 0.50,
          results_width = 0.50,
        },
        vertical = {
          mirror = false,
        },
        width = picker_width,
        height = picker_height,
        preview_cutoff = 120,
      },
      mappings = {
        i = {
          -- default mappings
          ["<A-c>"] = require("telescope").extensions.file_browser.actions.create,
          ["<S-CR>"] = require("telescope").extensions.file_browser.actions.create_from_prompt,
          ["<A-r>"] = require("telescope").extensions.file_browser.actions.rename,
          ["<A-m>"] = require("telescope").extensions.file_browser.actions.move,
          ["<A-y>"] = require("telescope").extensions.file_browser.actions.copy,
          -- ["<A-d>"] = require("telescope").extensions.file_browser.actions.remove,
          ["<C-o>"] = require("telescope").extensions.file_browser.actions.open,
          ["<C-g>"] = require("telescope").extensions.file_browser.actions.goto_parent_dir,
          ["<C-e>"] = require("telescope").extensions.file_browser.actions.goto_home_dir,
          ["<C-f>"] = require("telescope").extensions.file_browser.actions.toggle_browser,
          -- ["<C-h>"] = require("telescope").extensions.file_browser.actions.toggle_hidden,
          ["<C-a>"] = require("telescope").extensions.file_browser.actions.toggle_all,
          ["<BS>"] = require("telescope").extensions.file_browser.actions.backspace,
          ["<C-h>"] = function()
            local keys = vim.api.nvim_replace_termcodes("<C-h>", false, false, true)
            vim.api.nvim_feedkeys(keys, "n", {})
          end,
          ["<C-A-l>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "edit")
          end,
          ["<C-l>"] = require("telescope.actions").select_default,
          ["<A-CR>"] = telescope_utils.file_browser_set_cwd,
        },
        n = {
          ["q"] = require("telescope.actions").close,
          ["t"] = telescope_utils.file_browser_set_cwd,
          ["<A-CR>"] = telescope_utils.file_browser_set_cwd,
          ["T"] = require("telescope").extensions.file_browser.actions.goto_cwd,
          ["n"] = require("telescope").extensions.file_browser.actions.create_from_prompt,
          ["h"] = function()
            local keys = vim.api.nvim_replace_termcodes("h", false, false, true)
            vim.api.nvim_feedkeys(keys, "n", {})
          end,
          ["l"] = function()
            local keys = vim.api.nvim_replace_termcodes("l", false, false, true)
            vim.api.nvim_feedkeys(keys, "n", {})
          end,
          ["<C-h>"] = require("telescope").extensions.file_browser.actions.goto_parent_dir,
          ["<C-l>"] = require("telescope.actions").select_default,
          ["<C-A-\\>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "vsplit")
          end,
          ["<C-A-_>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "split")
          end,
          ["<C-A-l>"] = (function()
            local enter = function(prompt_bufnr)
              telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "edit")
            end
            return enter
          end)(),
          ["\\."] = require("telescope").extensions.file_browser.actions.toggle_hidden,
          ["<C-a>"] = require("telescope").extensions.file_browser.actions.toggle_all,
          ["s"] = function()
            local keys = vim.api.nvim_replace_termcodes("s", false, false, true)
            vim.api.nvim_feedkeys(keys, "n", {})
          end,
          -- default mappings
          ["c"] = require("telescope").extensions.file_browser.actions.create,
          ["r"] = require("telescope").extensions.file_browser.actions.rename,
          ["m"] = require("telescope").extensions.file_browser.actions.move,
          ["y"] = require("telescope").extensions.file_browser.actions.copy,
          ["d"] = require("telescope").extensions.file_browser.actions.remove,
          ["o"] = function() end,
          ["g"] = function() end,
          ["e"] = require("telescope").extensions.file_browser.actions.goto_home_dir,
          ["w"] = require("telescope").extensions.file_browser.actions.goto_cwd,
          -- ["t"] = require("telescope").extensions.file_browser.actions.change_cwd,
          ["f"] = require("telescope").extensions.file_browser.actions.toggle_browser,
          -- ["h"] = require("telescope").extensions.file_browser.actions.toggle_hidden,
          ["g<Space>"] = require("plugins.configs.telescope_utils").go_to_directory(
            function(input, prompt_bufnr, current_line)
              -- Close the current picker
              require("telescope.actions").close(prompt_bufnr)
              if vim.g.telescope_picker_temporary_cwd_from_file_browser == true then
                -- just precaution
                if vim.g.telescope_picker_type == nil then
                  print("`vim.g.telescope_picker_type` is not set, use default value: find_files")
                  vim.g.telescope_picker_type = "find_files"
                end
                telescope_utils.set_temporary_cwd_from_file_browser(vim.g.telescope_picker_type, input)(
                  prompt_bufnr
                )
              else
                -- Open file_browser with the specified path
                local fb = require("telescope").extensions.file_browser
                fb.file_browser({
                  path = input,
                  default_text = current_line,
                  prompt_title = "File Browser",
                })
              end
            end
          ),
          ["<leader>ot"] = telescope_utils.open_telescope_file_in_tab(false),
          ["g!"] = require("plugins.configs.telescope_utils").exec_shell_command(),
        },
      },
    },

    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },

    workspaces = {
      keep_insert = false,
      path_hl = "String",
    },

    quicknote = {
      defaultScope = "CWD",
    },
  },

  pickers = {
    live_grep = {
      mappings = {
        i = {
          ["<C-f>"] = telescope_utils.ts_select_dir_for_grep_or_find_files("live_grep"),
          ["<A-w>"] = telescope_utils.set_temporary_cwd_from_file_browser("live_grep"),
        },
        n = {
          ["<C-f>"] = telescope_utils.ts_select_dir_for_grep_or_find_files("live_grep"),
          ["W"] = telescope_utils.set_temporary_cwd_from_file_browser("live_grep"),
        },
      },
    },

    find_files = {
      prompt_title = "Find Files in " .. vim.fn.fnamemodify(vim.loop.cwd(), ":p"),
      mappings = {
        i = {
          ["<C-f>"] = telescope_utils.ts_select_dir_for_grep_or_find_files("find_files"),
          ["<A-w>"] = telescope_utils.set_temporary_cwd_from_file_browser("find_files"),
          ["<C-A-l>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "edit")
          end,
          ["<C-A-e>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker_and_set_cwd(prompt_bufnr, "tabe")
          end,
          ["<A-e>"] = telescope_utils.open_telescope_file_in_tab(true),
          ["<C-A-_>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "split")
          end,
          ["<C-A-\\>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "vsplit")
          end,
        },
        n = {
          ["<C-f>"] = telescope_utils.ts_select_dir_for_grep_or_find_files("find_files"),
          ["W"] = telescope_utils.set_temporary_cwd_from_file_browser("find_files"),
          ["<C-A-l>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "edit")
          end,
          ["<C-l>"] = require("telescope.actions").select_default,
          ["<C-A-e>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker_and_set_cwd(prompt_bufnr, "tabe")
          end,
          ["<A-e>"] = telescope_utils.open_telescope_file_in_tab(true),
          ["<C-A-_>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "split")
          end,
          ["<C-A-\\>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "vsplit")
          end,
          ["\\."] = function(prompt_bufnr)
            if vim.g.find_files_type == "all" then
              vim.g.find_files_type = "normal"
              vim.g.telescope_picker_type = "find_files"
              require("plugins.configs.telescope_utils").find_files({
                default_text = require("telescope.actions.state").get_current_line(),
              })
            else
              vim.g.find_files_type = "all"
              vim.g.telescope_picker_type = "find_files"
              require("plugins.configs.telescope_utils").find_all_files({
                default_text = require("telescope.actions.state").get_current_line(),
              })
            end
          end,
          -- ["<leader>fa"] = function(prompt_bufnr)
          --   vim.g.find_files_type = "all"
          --   vim.g.telescope_picker_type = "find_files"
          --   require("plugins.configs.telescope_utils").find_all_files({
          --     default_text = require("telescope.actions.state").get_current_line(),
          --   })
          -- end,
          -- ["<leader>ff"] = function(prompt_bufnr)
          --   vim.g.find_files_type = "normal"
          --   vim.g.telescope_picker_type = "find_files"
          --   require("plugins.configs.telescope_utils").find_files({
          --     default_text = require("telescope.actions.state").get_current_line(),
          --   })
          -- end,
        },
      },
    },

    buffers = {
      sort_lastused = true,
      sort_mru = true,
      -- sorter = telescope_utils.keep_initial_sorting_sorter(),
      mappings = {
        i = {
          ["<A-w>"] = telescope_utils.set_temporary_cwd_from_file_browser("buffers"),
          ["<A-[>"] = require("telescope.actions").preview_scrolling_left,
          ["<A-]>"] = require("telescope.actions").preview_scrolling_right,
          ["<A-u>"] = require("telescope.actions").preview_scrolling_up,
          ["<A-d>"] = require("telescope.actions").preview_scrolling_down,
          ["<C-u>"] = require("telescope.actions").results_scrolling_up,
          ["<C-d>"] = require("telescope.actions").results_scrolling_down,
          ["<A-{>"] = require("telescope.actions").results_scrolling_left,
          ["<A-}>"] = require("telescope.actions").results_scrolling_right,
        },
        n = {
          -- close the buffer
          ["d"] = require("telescope.actions").delete_buffer,
          ["D"] = telescope_utils.force_delete_buffer,
          ["<leader>oT"] = function()
            telescope_utils.open_telescope_file_in_specfic_tab()
          end,
          ["<leader>ot"] = telescope_utils.open_telescope_file_in_tab(false),
          ["W"] = telescope_utils.set_temporary_cwd_from_file_browser("buffers"),
          ["<C-A-\\>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "vsplit")
          end,
          ["<C-A-_>"] = function(prompt_bufnr)
            telescope_utils.open_multiple_files_in_find_files_picker(prompt_bufnr, "split")
          end,
          ["<A-[>"] = require("telescope.actions").preview_scrolling_left,
          ["<A-]>"] = require("telescope.actions").preview_scrolling_right,
          ["<A-u>"] = require("telescope.actions").preview_scrolling_up,
          ["<A-d>"] = require("telescope.actions").preview_scrolling_down,
          ["<C-u>"] = require("telescope.actions").results_scrolling_up,
          ["<C-d>"] = require("telescope.actions").results_scrolling_down,
          ["<A-{>"] = require("telescope.actions").results_scrolling_left,
          ["<A-}>"] = require("telescope.actions").results_scrolling_right,
        },
      },
    },

    jumplist = {
      show_line = false,
    },

    git_status = {
      mappings = {
        n = {
          ["<leader>ow"] = telescope_utils.select_window_to_open,
        },
      },
    },

    oldfiles = {
      sort_lastused = true,
      sort_mru = true,
      -- sorter = telescope_utils.keep_initial_sorting_sorter(),
      tiebreak = function(current_entry, existing_entry, _)
        return current_entry.index > existing_entry.index
      end,
      mappings = {
        i = {
          ["<A-w>"] = telescope_utils.set_temporary_cwd_from_file_browser("oldfiles"),
        },
        n = {
          ["W"] = telescope_utils.set_temporary_cwd_from_file_browser("oldfiles"),
        },
      },
    },

    grep_string = {
      sorter = telescope_utils.keep_initial_sorting_sorter(),
      mappings = {
        i = {
          ["<A-w>"] = telescope_utils.set_temporary_cwd_from_file_browser("grep_string"),
        },
        n = {
          ["W"] = telescope_utils.set_temporary_cwd_from_file_browser("grep_string"),
        },
      },
    },

    lsp_document_symbols = {
      sorter = telescope_utils.keep_initial_sorting_sorter(),
    },

    lsp_workspace_symbols = {
      sorter = telescope_utils.keep_initial_sorting_sorter(),
    },

    pickers = {
      mappings = {
        n = {
          ["<C-l>"] = require("telescope.actions").select_default,
        },
      },
    },
  },
}

return M
