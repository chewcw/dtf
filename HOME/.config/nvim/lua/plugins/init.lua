-- All plugins have lazy=true by default,to load a plugin on startup just lazy=false
-- List of all default plugins & their definitions
local home = os.getenv("HOME")
local default_plugins = {
  {
    "nvim-lua/plenary.nvim",
    -- branch = "master",
    -- commit = "0dbe561",
  },

  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      return require("plugins.configs.others").webdevicons
    end,
    config = function(_, opts)
      require("nvim-web-devicons").setup(opts)
    end,
    -- branch = "master",
    -- commit = "bc11ee2",
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    init = function()
      require("core.utils").lazy_load("indent-blankline.nvim")
    end,
    main = "ibl",
    opts = function()
      return require("plugins.configs.others").blankline
    end,
    config = function(_, opts)
      require("core.utils").load_mappings("blankline")
      require("ibl").setup(opts)
    end,
    -- branch = "master",
    -- commit = "9637670",
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    init = function()
      require("core.utils").lazy_load("nvim-treesitter")
    end,
    -- cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = function()
      return require("plugins.configs.treesitter")
    end,
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "syntax")
      require("nvim-treesitter.configs").setup(opts)
    end,
    -- branch = "master",
    -- commit = "30604fd",
  },

  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
    ft = { "gitcommit", "diff" },
    init = function()
      -- load gitsigns only when a git file is opened
      vim.api.nvim_create_autocmd({ "BufRead" }, {
        group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
        callback = function()
          pcall(function()
            vim.fn.system("git -C " .. '"' .. vim.fn.expand("%:p:h") .. '"' .. " rev-parse")
            if vim.v.shell_error == 0 then
              vim.api.nvim_del_augroup_by_name("GitSignsLazyLoad")
              vim.schedule(function()
                require("lazy").load({ plugins = { "gitsigns.nvim" } })
              end)
            end
          end)
        end,
      })
    end,
    opts = function()
      return require("plugins.configs.others").gitsigns
    end,
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "git")
      require("gitsigns").setup(opts)
    end,
    -- branch = "main",
    -- commit = "d927caa",
  },

  -- lsp stuff
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    opts = function()
      return require("plugins.configs.mason")
    end,
    config = function(_, opts)
      require("mason").setup(opts)

      -- custom cmd to install all mason binaries listed
      vim.api.nvim_create_user_command("MasonInstallAll", function()
        vim.cmd("MasonInstall " .. table.concat(opts.ensure_installed, " "))
      end, {})

      vim.g.mason_binaries_list = opts.ensure_installed
    end,
    -- branch = "main",
    -- commit = "ee6a7f1",
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      --format and linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require("plugins.configs.null-ls")
        end,
        -- branch = "main",
        -- commit = "0010ea9",
      },
      {
        "Hoffs/omnisharp-extended-lsp.nvim",
        -- branch = "main",
        -- commit = "78cda39",
      },
    },
    init = function()
      require("core.utils").lazy_load("nvim-lspconfig")
    end,
    config = function()
      require("plugins.configs.lspconfig")
    end,
    -- branch = "master",
    -- commit = "37f362e",
  },

  -- cmp related
  {
    "hrsh7th/nvim-cmp",
    event = "BufEnter",
    dependencies = {
      -- cmp sources plugins
      {
        {
          "L3MON4D3/LuaSnip",
          dependencies = "rafamadriz/friendly-snippets",
          opts = { history = true, updateevents = "TextChanged,TextChangedI" },
          config = function(_, opts)
            require("plugins.configs.others").luasnip(opts)
          end,
          -- branch = "master",
          -- commit = "ea7d7ea",
        },
        {
          "saadparwaiz1/cmp_luasnip",
          -- branch = "master",
          -- commit = "1809552",
        },
        {
          "hrsh7th/cmp-nvim-lua",
          -- branch = "main",
          -- commit = "f12408b",
        },
        {
          "hrsh7th/cmp-nvim-lsp",
          -- branch = "main",
          -- commit = "44b16d1",
        },
        {
          "hrsh7th/cmp-buffer",
          -- branch = "main",
          -- commit = "3022dbc",
        },
        -- {
        --   "hrsh7th/cmp-path",
        --   branch = "main",
        --   commit = "91ff86c",
        -- },
        {
          "https://codeberg.org/FelipeLema/cmp-async-path",
          -- branch = "main",
          -- commit = "7df7f3",
        },
        {
          "hrsh7th/cmp-cmdline",
          -- branch = "main",
          -- commit = "d250c63",
        },
        {
          "hrsh7th/cmp-emoji",
          -- branch = "main",
          -- commit = "e8398e2",
        },
        {
          "Dynge/gitmoji.nvim",
          -- branch = "main",
          -- commit = "326ddf0",
          ft = "gitcommit",
        },
        {
          "tzachar/cmp-fuzzy-buffer",
        },
        {
          "tzachar/fuzzy.nvim",
        },
      },
    },
    opts = function()
      return require("plugins.configs.cmp").options
    end,
    config = function(_, opts)
      require("cmp").setup(opts.core)
      require("cmp").setup.cmdline(":", opts.cmd)
      require("cmp").setup.cmdline({ "/", "?" }, opts.search)
    end,
    -- branch = "main",
    -- commit = "a110e12",
  },

  -- file managing , picker etc
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    init = function()
      require("core.utils").load_mappings("nvimtree")
    end,
    opts = function()
      return require("plugins.configs.nvimtree")
    end,
    config = function(_, opts)
      require("nvim-tree").setup(opts)
      vim.g.nvimtree_side = opts.view.side
    end,
    -- branch = "master",
    -- commit = "5897b36",
  },

  {
    "nvim-telescope/telescope.nvim",
    cmd = { "Telescope" },
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        -- branch = "main",
        -- commit = "9ef21b2",
      },
      {
        "nvim-telescope/telescope-file-browser.nvim",
        -- branch = "master",
        -- commit = "ad7b637",
      },
      {
        "nvim-telescope/telescope-ui-select.nvim",
        -- branch = "master",
        -- commit = "6e51d7d",
      },
    },
    init = function()
      -- put this before loading mappings because
      -- when nvim loads the first time, if I press the mapping (<leader>fr) to open
      -- Telescope.resume(), error occurs saying that "telescope" plugin is not found
      -- or sort.
      require("telescope")
      require("core.utils").load_mappings("telescope")

      -- https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#previewers
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopePreviewerLoaded",
        callback = function(args)
          -- Set wrap
          -- The logic is if one of the window in this tab is wrap, then wrap the previewer
          local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
          local win_wrap = vim.api.nvim_get_option_value("wrap", { win = wins[1] })
          if win_wrap == true then
            vim.wo.wrap = true
          else
            vim.wo.wrap = false
          end
          -- Show line number
          if args.data.filetype ~= "help" then
            vim.wo.number = true
          end
        end,
      })
    end,
    opts = function()
      return require("plugins.configs.telescope").options
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      -- load extensions
      for _, ext in ipairs(opts.extensions_list) do
        telescope.load_extension(ext)
      end
    end,
    -- branch = "master",
    -- commit = "6b79d7a",
  },

  {
    "kylechui/nvim-surround",
    lazy = false,
    config = function()
      require("nvim-surround").setup({
        keymaps = {
          change = "css", -- the default `cs` somehow sometimes doesn't work
          delete = "dss", -- the default `cs` somehow sometimes doesn't work
        },
      })
    end,
  },

  {
    "tomtom/tcomment_vim",
    event = { "BufEnter " },
    -- branch = "master",
    -- commit = "b4930f9",
    init = function()
      vim.cmd("let g:tcomment_maps = '0'")
      require("core.utils").load_mappings("tcomment")
    end,
  },

  -- {
  --   "easymotion/vim-easymotion",
  --   keys = { "<leader>S" },
  --   init = function()
  --     require("core.utils").load_mappings("easymotion")
  --   end,
  -- },

  -- {
  --   "gelguy/wilder.nvim",
  --   event = "BufEnter",
  --   opts = function()
  --     return require("plugins.configs.others").wilder
  --   end,
  --   init = function()
  --     local wilder = require("wilder")
  --     wilder.set_option(
  --       "renderer",
  --       wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
  --         highlights = {
  --           border = "FloatBorder",
  --         },
  --         pumblend = 20,
  --       }))
  --     )
  --   end,
  --   config = function(_, opts)
  --     require("wilder").setup(opts)
  --   end,
  -- },

  {
    "jeetsukumaran/vim-markology",
    event = "VeryLazy",
    init = function()
      vim.g.markology_include = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    end,
    -- branch = "master",
    -- commit = "9681b3f",
  },

  {
    "akinsho/toggleterm.nvim",
    lazy = false,
    config = true,
    init = function()
      require("core.utils").load_mappings("toggleterm")
    end,
    opts = function()
      return require("plugins.configs.toggleterm")
    end,
    -- branch = "main",
    -- commit = "12cba0a",
  },

  -- {
  --   "Exafunction/codeium.vim",
  --   cmd = { "CodeiumEnable" },
  --   init = function()
  --     vim.g.codeium_no_map_tab = false
  --     vim.g.codeium_idle_delay = 75
  --     require("core.utils").load_mappings("codeium")
  --   end,
  --   -- branch = "main",
  --   -- commit = "9406f13",
  -- },

  {
    "natecraddock/workspaces.nvim",
    cmd = { "Telescope workspaces" },
    config = true,
    opts = function()
      return require("plugins.configs.others").workspaces
    end,
    -- branch = "master",
    -- commit = "a6fb499",
  },

  -- {
  --   "windwp/nvim-autopairs",
  --   event = "InsertEnter",
  --   config = true,
  --   opts = function()
  --     return require("plugins.configs.others").nvim_autopairs
  --   end,
  --   branch = "master",
  --   commit = "a52fc6e",
  -- },

  {
    "mg979/vim-visual-multi",
    event = "BufEnter",
    init = function()
      require("core.mappings").vm.init()
      -- highlight groups
      -- https://github.com/mg979/vim-visual-multi/wiki/Highlight-colors
      vim.cmd("let g:VM_Mono_hl = 'CurSearch'")
      vim.cmd("let g:VM_Extend_hl = 'Visual'")
      vim.cmd("let g:VM_Cursor_hl = 'Visual'")
      vim.cmd("let g:VM_Insert_hl = 'Cursor'")
      vim.cmd("let g:VM_highlight_matches = 'hi! link Search VisualMultiHighlightMatches'")
    end,
    -- branch = "master",
    -- commit = "724bd53",
  },

  {
    "michaeljsmith/vim-indent-object",
    keys = { "v" },
    -- branch = "master",
    -- commit = "5c5b24c",
  },

  -- debugging
  -- {
  --   "mfussenegger/nvim-dap",
  --   keys = { "<leader>d" },
  --   dependencies = {
  --     require("plugins.configs.nvim-dap").dapui,
  --     require("plugins.configs.nvim-dap").virtual_text,
  --     require("plugins.configs.nvim-dap").python,
  --     require("plugins.configs.nvim-dap").go,
  --   },
  --   init = function()
  --     require("core.utils").load_mappings("nvim_dap")
  --   end,
  --   config = function()
  --     require("plugins.configs.nvim-dap").csharp.setup()
  --     require("plugins.configs.nvim-dap").rust.setup()
  --   end,
  --   branch = "master",
  --   commit = "31e1ece",
  -- },

  {
    "nvim-treesitter/nvim-treesitter-context",
    lazy = false,
    -- branch = "master",
    -- commit = "31692b2",
    opts = function()
      return require("plugins.configs.others").treesitter_context
    end,
    config = function(_, opts)
      require("treesitter-context").setup(opts)
    end,
  },

  {
    "tpope/vim-fugitive",
    lazy = false,
    -- branch = "master",
    init = function()
      -- my own command, may need to remove this user command if later vim-fugitive
      -- was uninstalled
      vim.g.gll_records = {}
      vim.g.fugitive_ran = false
      vim.api.nvim_create_user_command("Gll", function(args)
        -- the custom command
        local cmd = [[ Git log --graph --pretty=format:"%h %Cred%an %Cblue%aI %Cred%d%Cgreen%s" ]]
        if args["args"] then
          cmd = cmd .. " " .. args["args"]
        end

        vim.cmd(cmd)

        -- new buf after ran the command
        local new_buf = vim.api.nvim_get_current_buf()
        -- record the args in the buffer name
        -- have to do this temporary variable thing, see https://github.com/nanotee/nvim-lua-guide#caveats-3
        local x = vim.g.gll_records
        x = x or {}
        x[tostring(new_buf)] = { is_gll = true, args = args["args"] }
        vim.g.gll_records = x
      end, { desc = "Git log with format", nargs = "*" })

      -- when the buffer enters, reload the Gll related window automatically
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local buf_name = vim.api.nvim_buf_get_name(buf)
          -- this is here to prevent this scenario:
          -- 1. Reload the Gll manually
          -- 2. The Gll outputs
          -- 3. This autocmd runs
          -- 4. Once again the Gll outputs
          -- causing 2 buffers were created
          vim.defer_fn(function()
            vim.g.gll_reload_manually_or_open_new = false
          end, 500)
          -- find the fugitive related buffer
          vim.defer_fn(function()
            if
                buf_name:match("^/tmp/nvim%.ccw/")
                and not buf_name:match("%.sh$")
                and not buf_name:match("%.edit$")
                and not buf_name:match("%.exit$")
                and not vim.g.gll_reload_manually_or_open_new
            then
              -- have to do this temporary variable thing, see https://github.com/nanotee/nvim-lua-guide#caveats-3
              local x = vim.g.gll_records
              x = x or {}
              if x[tostring(buf)] ~= nil and x[tostring(buf)].is_gll == true and vim.g.fugitive_ran then
                -- retrieve its args if available
                local args = x[tostring(buf)].args
                -- this behavior should be same as the keymapping <A-0>
                -- current buf before running the command
                local current_buf = vim.api.nvim_get_current_buf()
                -- see if there is any record for the current buffer
                -- have to do this temporary variable thing, see https://github.com/nanotee/nvim-lua-guide#caveats-3
                if x[tostring(current_buf)] ~= nil and x[tostring(current_buf)].is_gll == true then
                  -- clear the record, as this reloading is going to replace current
                  -- bufer
                  x[tostring(current_buf)] = nil
                  vim.g.gll_records = x
                end
                require("core.utils_window").save_window_sizes_and_restore(function()
                  -- run the Gll command
                  vim.g.gll_reload_manually_or_open_new = true
                  vim.cmd("Gll " .. args)
                  vim.cmd("wincmd k")
                  vim.cmd("wincmd q")
                  vim.cmd("wincmd p") -- make sure to focus on the Gll window
                  vim.api.nvim_input("<Esc>")
                  vim.g.fugitive_ran = false
                end)
              end
            end
          end, 200)
        end,
      })

      -- when the buffer deleted, if it's a Gll window, clear the Gll records
      -- accordingly
      vim.api.nvim_create_autocmd("BufDelete", {
        pattern = "*",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local buf_name = vim.api.nvim_buf_get_name(buf)

          if
              buf_name:match("^/tmp/nvim%.ccw/")
              and not buf_name:match("%.sh$")
              and not buf_name:match("%.edit$")
              and not buf_name:match("%.exit$")
          then
            -- have to do this temporary variable thing, see https://github.com/nanotee/nvim-lua-guide#caveats-3
            local x = vim.g.gll_records
            x = x or {}
            if x[tostring(buf)] and x[tostring(buf)].is_gll == true then
              x[tostring(buf)] = nil
              vim.g.gll_records = x
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "FugitiveChanged",
        callback = function()
          vim.g.fugitive_ran = true
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "FugitiveEditor",
        callback = function()
          vim.g.fugitive_ran = false
        end,
      })

      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "fugitive://*", "/tmp/nvim.ccw/*" },
        callback = function()
          vim.opt_local.colorcolumn = "0"
          vim.opt_local.cursorline = true
          vim.opt_local.textwidth = 0
          vim.opt_local.foldmethod = "syntax"
        end,
      })
    end,
  },

  -- {
  --   "junegunn/gv.vim",
  --   lazy = false,
  --   -- branch = "master",
  --   -- commit = "b6bb666",
  -- },

  -- {
  --   "NeogitOrg/neogit",
  --   command = { "Neogit" },
  --   config = function(_, opts)
  --     require("neogit").setup(opts)
  --   end,
  --   branch = "master",
  --   commit = "7b4a2c7",
  -- },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    lazy = true,
    -- branch = "master",
    -- commit = "a923f5f",
  },

  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle" },
    lazy = true,
    -- branch = "master",
    -- commit = "36ff7ab",
  },

  -- {
  -- "kevinhwang91/nvim-ufo",
  -- dependencies = {
  --   "kevinhwang91/promise-async",
  --   {
  --     "luukvbaal/statuscol.nvim",
  --     config = function()
  --       local builtin = require("statuscol.builtin")
  --       require("statuscol").setup({
  --         relculright = true,
  --         segments = {
  --           { text = { builtin.foldfunc },      click = "v:lua.ScFa" },
  --           { text = { "%s" },                  click = "v:lua.ScSa" },
  --           { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
  --         },
  --       })
  --     end,
  --     branch = "main",
  --     commit = "3b62975",
  --   },
  -- },
  -- event = "BufReadPost",
  -- lazy = false,
  -- opts = function()
  --   return require("plugins.configs.others").ufo
  -- end,
  -- init = function()
  --   vim.keymap.set("n", "zR", function()
  --     require("ufo").openAllFolds()
  --   end)
  --   vim.keymap.set("n", "zM", function()
  --     require("ufo").closeAllFolds()
  --   end)
  -- end,
  -- config = function(_, opts)
  --   require("ufo").setup(opts)
  -- end,
  -- branch = "main",
  -- commit = "b0741a6",
  -- },

  {
    "folke/trouble.nvim",
    lazy = false,
    init = function()
      require("core.utils").load_mappings("trouble")
    end,
    opts = function()
      return require("plugins.configs.others").trouble
    end,
    -- branch = "main",
    -- commit = "f1168fe",
  },

  {
    "Issafalcon/lsp-overloads.nvim",
    lazy = true,
    cmd = { "LspOverloadsSignatureAutoToggle" },
    config = true,
    -- branch = "main",
    -- commit = "6b02341",
  },

  {
    "sindrets/diffview.nvim",
    lazy = false,
    opts = function()
      local actions = require("diffview.actions")
      return require("plugins.configs.others").diffview(actions)
    end,
    config = function(_, opts)
      require("diffview").setup(opts)
    end,
    -- branch = "main",
    -- commit = "72c6983",
  },

  {
    "rmagatti/auto-session",
    lazy = false,
    opts = function()
      return {
        log_level = "error",
        auto_session_suppress_dirs = {
          "~",
          "~/*",
          "~/Documents/*",
          "~/Documents/dtfs/*",
          "/tmp",
          "/tmp/*",
        },
        cwd_change_handling = {
          restore_upcoming_session = true,
        },
        auto_restore_enabled = false,
        auto_save = false,
        auto_restore = false,
        auto_create = false,
        session_lens = {
          theme_conf = {
            layout_config = {
              width = vim.o.columns,
              height = vim.o.lines,
            },
          },
        },
      }
    end,
  },

  {
    "tpope/vim-repeat",
    keys = { "v", "cs", "S", "ds", "ysiw" },
    -- branch = "master",
    -- commit = "24afe92",
  },

  {
    "gbprod/yanky.nvim",
    event = "BufEnter",
    opts = function()
      return require("plugins.configs.others").yanky
    end,
    config = function(_, opts)
      require("core.utils").load_mappings("yanky")
      require("yanky").setup(opts)
    end,
    -- branch = "main",
    -- commit = "73215b7",
  },

  {
    "chrisbra/unicode.vim",
    cmd = "UnicodeSearch",
    -- branch = "master",
    -- commit = "bc20d0f",
  },

  {
    "inkarkat/vim-EnhancedJumps",
    -- branch = "master",
    -- commit = "84df0d7",
    event = "BufEnter",
    config = function()
      require("core.utils").load_mappings("enhancedJumps")
    end,
    dependencies = {
      {
        "inkarkat/vim-ingo-library",
      },
    },
  },

  {
    "akinsho/bufferline.nvim",
    lazy = false,
    opts = function()
      return require("plugins.configs.bufferline").setup
    end,
    config = function(_, opts)
      require("bufferline").setup(opts)
    end,
  },

  {
    "brenoprata10/nvim-highlight-colors",
    cmd = { "HighlightColors" },
    opts = function()
      return {
        render = "virtual",
        virtual_symbol = "🟓 ",
      }
    end,
    config = function(_, opts)
      require("nvim-highlight-colors").setup(opts)
    end,
  },

  {
    "uga-rosa/ccc.nvim",
    cmd = { "CccPick" },
    config = function()
      require("ccc").setup({})
    end,
  },

  {
    "wfxr/minimap.vim",
    cmd = { "Minimap" },
    build = "cargo install --locked code-minimap",
    init = function()
      vim.g.minimap_auto_start = 0
      vim.g.minimap_git_colors = 1
      vim.g.minimap_highlight_search = 1
      vim.g.minimap_highlight_range = 0
      vim.g.minimap_diffadd_color = "DiffAdd"
      vim.g.minimap_diffremove_color = "DiffRemoved"
      vim.g.minimap_cursor_diffadd_color = "DiffAdd"
      vim.g.minimap_cursor_diffremove_color = "DiffRemoved"
    end,
  },

  {
    "echasnovski/mini.align",
    cmd = { "Align" },
    version = "*",
    opts = function()
      return {
        mappings = {
          start = "<leader>aa",
          start_with_preview = "<leader>aA",
        },
      }
    end,
    config = function(_, opts)
      require("mini.align").setup(opts)
    end,
  },

  {
    "dhruvasagar/vim-table-mode",
    cmd = "TableModeToggle",
    init = function()
      vim.g.table_mode_corner = "|"
    end,
  },

  {
    "jlcrochet/vim-razor",
    ft = { "razor", "cshtml" },
    init = function()
      -- When open in fugitive diff for razor file, maybe because of the syntax is set to
      -- razor, it becomes very slow, so if it's a diff, then set the syntax to `diff`
      vim.api.nvim_create_autocmd("WinEnter", {
        pattern = { "*.razor", "*.cshtml" },
        callback = function()
          local isdiff = vim.api.nvim_get_option_value("diff", { win = 0 })
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if isdiff then
              local buf = vim.api.nvim_win_get_buf(win)
              local israzor = vim.api.nvim_get_option_value("syntax", { buf = buf }) == "razor"
              if israzor then
                vim.api.nvim_set_option_value("syntax", "diff", { buf = buf })
              end
            end
          end
        end,
      })
    end,
  },

  {
    "RutaTang/quicknote.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    init = function()
      vim.api.nvim_create_user_command("Quicknote", function(opts)
        if pcall(require, "quicknote") then
          if opts.args == "new cwd" then
            require("quicknote").NewNoteAtCWD()
          elseif opts.args == "open cwd" then
            require("quicknote").OpenNoteAtCWD()
          elseif opts.args == "delete cwd" then
            require("quicknote").DeleteNoteAtCWD()
          end

          if opts.args == "new line" or opts.args == "new" then
            require("quicknote").NewNoteAtCurrentLine()
          elseif opts.args == "open line" or opts.args == "open" then
            require("quicknote").OpenNoteAtCurrentLine()
          elseif opts.args == "delete line" or opts.args == "delete" then
            require("quicknote").DeleteNoteAtCurrentLine()
          end

          if opts.args == "list" then
            require("quicknote").ListNotesForCurrentBuffer()
          elseif opts.args == "list cwd" then
            require("quicknote").ListNotesForCWD()
          end
        end
      end, { nargs = "*" })

      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        callback = function()
          require("quicknote").ShowNoteSigns()
        end,
      })
    end,
    opts = function()
      return {
        mode = "portable",
        sign = "🗈",
        filetype = "md",
        git_branch_recognizable = true,
      }
    end,
    config = function(_, opts)
      require("core.utils").load_mappings("quicknote")
      require("quicknote").setup(opts)
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    lazy = false,
    opts = function()
      return {
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = "<A-Tab>",
            accept_word = "<A-;>",
            accept_line = "<A-'>",
            dismiss = "<A-q>",
            next = "<A-]>",
            previous = "<A-[>",
          },
        },
      }
    end,
    config = function(_, opts)
      require("copilot").setup(opts)
    end,
  },

  {
    "chewcw/CopilotChat.nvim",
    build = "make tiktoken",
    opts = function()
      return require("plugins.configs.copilot_chat").opts
    end,
    config = function(_, opts)
      require("CopilotChat").setup(opts)
    end,
    lazy = false,
  },

  -- {
  --   "olimorris/codecompanion.nvim",
  --   lazy = false,
  --   opts = function()
  --     return {
  --       strategies = {
  --         chat = {
  --           adapter = "copilot",
  --         },
  --         inline = {
  --           adapter = "copilot",
  --         },
  --         agent = {
  --           adapter = "copilot",
  --         },
  --       },
  --     }
  --   end,
  --   config = function(_, opts)
  --     require("codecompanion").setup(opts)
  --   end,
  -- },

  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    opts = {
      use_default_keymaps = false,
      columns = {
        "icon",
        "permissions",
        "size",
        "mtime",
      },
      constrain_cursor = "name",
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
      float = {
        -- Padding around the floating window
        padding = 0,
        -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        max_width = 0.8,
        max_height = 0.8,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
        -- optionally override the oil buffers window title with custom function: fun(winid: integer): string
        get_win_title = nil,
        -- preview_split: Split direction: "auto", "left", "right", "above", "below".
        preview_split = "auto",
        -- This is the config that will be passed to nvim_open_win.
        -- Change values here to customize the layout
        override = function(conf)
          return conf
        end,
      },
      keymaps = {
        ["<A-_>"] = { "actions.select", opts = { horizontal = true } },
        ["<A-\\>"] = { "actions.select", opts = { vertical = true } },
        ["<A-e>"] = { "actions.select", opts = { tab = true } },
        ["gq"] = { "actions.close", mode = "n" },
        ["\\."] = { "actions.toggle_hidden", mode = "n" },
        ["\\p"] = { "actions.preview" },
        ["\\r"] = "actions.refresh",
        -- Default keymappings
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["<C-l>"] = "actions.select",
        ["-"] = { "actions.parent", mode = "n" },
        ["<C-h>"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = {},
        ["<A-CR>"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g\\"] = { "actions.toggle_trash", mode = "n" },
      },
    },
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    config = function(_, opts)
      require("oil").setup(opts)
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "copilot-chat", "Avante" },
    opts = {
      file_types = { "markdown", "copilot-chat", "Avante" },
    },
  },

  -- {
  --   "HakonHarnes/img-clip.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     default = {
  --       embed_image_as_base64 = false,
  --       prompt_for_file_name = false,
  --       drag_and_drop = {
  --         insert_mode = true,
  --       },
  --       use_absolute_path = true,
  --     },
  --   },
  -- },

  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
      provider = "groq",
      vendors = {
        groq = {
          __inherited_from = "openai",
          api_key_name = "GROQ_API_KEY",
          endpoint = "https://api.groq.com/openai/v1/",
          -- model = "llama-3.3-70b-versatile",
          model = "deepseek-r1-distill-llama-70b",
        },
      },
      mappings = {
        submit = {
          normal = "<A-CR>",
          insert = "<A-CR>",
        },
      },
      windows = {
        edit = {
          start_insert = false,
        },
        ask = {
          start_insert = false,
        },
      },
      behaviour = {
        auto_set_keymaps = false,
      },
      hints = { enabled = false },
      dual_boost = {
        enabled = false,
        first_provider = "groq",
        second_provider = "copilot",
        prompt =
        "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
        timeout = 60000, -- Timeout in milliseconds
      },
    },
    build = "make",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },

  -- Only load whichkey after all the gui
  -- {
  --   "folke/which-key.nvim",
  --   keys = { "<leader>", '"', "'", "`", "c", "v", "g" },
  --   init = function()
  --     require("core.utils").load_mappings("whichkey")
  --   end,
  --   opts = function()
  --     return require("plugins.configs.others").whichkey
  --   end,
  --   config = function(_, opts)
  --     require("which-key").setup(opts)
  --   end,
  --   -- branch = "main",
  --   -- commit = "0099511",
  -- },
}

local config = require("core.utils").load_config()

if #config.plugins > 0 then
  table.insert(default_plugins, { import = config.plugins })
end

require("lazy").setup(default_plugins, config.lazy_nvim)
