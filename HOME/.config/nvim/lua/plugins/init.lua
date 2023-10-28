-- All plugins have lazy=true by default,to load a plugin on startup just lazy=false
-- List of all default plugins & their definitions
local default_plugins = {

  {
    "nvim-lua/plenary.nvim",
    branch = "master",
    commit = "0dbe561",
  },

  {
    "NvChad/base46",
    branch = "v2.0",
    commit = "919af1c",
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  {
    "NvChad/ui",
    branch = "v2.0",
    commit = "b3a343e",
    lazy = false,
  },

  -- {
  -- 	"NvChad/nvim-colorizer.lua",
  -- 	init = function()
  -- 		require("core.utils").lazy_load("nvim-colorizer.lua")
  -- 	end,
  -- 	config = function(_, opts)
  -- 		require("colorizer").setup(opts)

  -- 		-- execute colorizer as soon as possible
  -- 		vim.defer_fn(function()
  -- 			require("colorizer").attach_to_buffer(0)
  -- 		end, 0)
  -- 	end,
  -- },

  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      return require("plugins.configs.others").webdevicons
    end,
    config = function(_, opts)
      require("nvim-web-devicons").setup(opts)
    end,
    branch = "master",
    commit = "bc11ee2",
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    init = function()
      require("core.utils").lazy_load("indent-blankline.nvim")
    end,
    opts = function()
      return require("plugins.configs.others").blankline
    end,
    config = function(_, opts)
      require("core.utils").load_mappings("blankline")
      dofile(vim.g.base46_cache .. "blankline")
      require("indent_blankline").setup(opts)
    end,
    branch = "master",
    commit = "9637670",
  },

  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      require("core.utils").lazy_load("nvim-treesitter")
    end,
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = function()
      return require("plugins.configs.treesitter")
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "syntax")
      require("nvim-treesitter.configs").setup(opts)
    end,
    branch = "master",
    commit = "30604fd",
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
          vim.fn.system("git -C " .. '"' .. vim.fn.expand("%:p:h") .. '"' .. " rev-parse")
          if vim.v.shell_error == 0 then
            vim.api.nvim_del_augroup_by_name("GitSignsLazyLoad")
            vim.schedule(function()
              require("lazy").load({ plugins = { "gitsigns.nvim" } })
            end)
          end
        end,
      })
    end,
    opts = function()
      return require("plugins.configs.others").gitsigns
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "git")
      require("gitsigns").setup(opts)
    end,
    branch = "main",
    commit = "d927caa",
  },

  -- lsp stuff
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    opts = function()
      return require("plugins.configs.mason")
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "mason")
      require("mason").setup(opts)

      -- custom nvchad cmd to install all mason binaries listed
      vim.api.nvim_create_user_command("MasonInstallAll", function()
        vim.cmd("MasonInstall " .. table.concat(opts.ensure_installed, " "))
      end, {})

      vim.g.mason_binaries_list = opts.ensure_installed
    end,
    branch = "main",
    commit = "ee6a7f1",
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
        branch = "main",
        commit = "0010ea9",
      },
    },
    init = function()
      require("core.utils").lazy_load("nvim-lspconfig")
    end,
    config = function()
      require("plugins.configs.lspconfig")
    end,
    branch = "master",
    commit = "a27356f",
  },

  -- load luasnips + cmp related in insert mode only
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("plugins.configs.others").luasnip(opts)
        end,
        branch = "master",
        commit = "ea7d7ea",
      },

      -- cmp sources plugins
      {
        {
          "saadparwaiz1/cmp_luasnip",
          branch = "master",
          commit = "1809552",
        },
        {
          "hrsh7th/cmp-nvim-lua",
          branch = "main",
          commit = "f12408b",
        },
        {
          "hrsh7th/cmp-nvim-lsp",
          branch = "main",
          commit = "44b16d1",
        },
        {
          "hrsh7th/cmp-buffer",
          branch = "main",
          commit = "3022dbc",
        },
        {
          "hrsh7th/cmp-path",
          branch = "main",
          commit = "91ff86c",
        },
      },
    },
    opts = function()
      return require("plugins.configs.cmp")
    end,
    config = function(_, opts)
      require("cmp").setup(opts)
    end,
    branch = "main",
    commit = "5dce1b7",
  },

  -- file managing , picker etc
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    init = function()
      require("core.utils").load_mappings("nvimtree")
    end,
    opts = function()
      return require("plugins.configs.nvimtree")
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "nvimtree")
      require("nvim-tree").setup(opts)
      vim.g.nvimtree_side = opts.view.side
    end,
    branch = "master",
    commit = "5897b36",
  },

  {
    "nvim-telescope/telescope.nvim",
    cmd = { "Telescope" },
    init = function()
      -- put this before loading mappings because
      -- when nvim loads the first time, if I press the mapping (<leader>fr) to open
      -- Telescope.resume(), error occurs saying that "telescope" plugin is not found
      -- or sort.
      require("telescope")
      require("core.utils").load_mappings("telescope")
    end,
    opts = function()
      return require("plugins.configs.telescope").options
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "telescope")
      local telescope = require("telescope")
      telescope.setup(opts)
      -- load extensions
      for _, ext in ipairs(opts.extensions_list) do
        telescope.load_extension(ext)
      end
      -- update border style
      require("plugins.configs.telescope").border()
    end,
    branch = "master",
    commit = "6b79d7a",
  },

  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope.nvim",
        branch = "master",
        commit = "6b79d7a",
      },
      {
        "nvim-lua/plenary.nvim",
        branch = "master",
        commit = "0dbe561",
      },
    },
    branch = "master",
    commit = "ad7b637",
  },

  {
    "nvim-telescope/telescope-ui-select.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope.nvim",
        branch = "master",
        commit = "6b79d7a",
      },
      {
        "nvim-lua/plenary.nvim",
        branch = "master",
        commit = "0dbe561",
      },
    },
    branch = "master",
    commit = "62ea5e5",
  },

  {
    "LukasPietzschmann/telescope-tabs",
    dependencies = {
      {
        "nvim-telescope/telescope.nvim",
        branch = "master",
        commit = "6b79d7a",
      },
    },
    branch = "master",
    commit = "a38c8fe",
    -- config = function(_, opts)
    --   require("telescope-tabs").setup(opts)
    -- end,
  },

  {
    "tpope/vim-surround",
    keys = { "v", "cs", "S", "ds", "ysiw" },
    branch = "master",
    commit = "3d188ed",
  },

  {
    "tomtom/tcomment_vim",
    event = { "BufEnter " },
    branch = "master",
    commit = "b4930f9",
  },

  -- {
  --   "easymotion/vim-easymotion",
  --   keys = { "<leader>S" },
  --   init = function()
  --     require("core.utils").load_mappings("easymotion")
  --   end,
  -- },

  {
    "gelguy/wilder.nvim",
    event = "BufEnter",
    opts = function()
      return require("plugins.configs.others").wilder
    end,
    init = function()
      local wilder = require("wilder")
      wilder.set_option(
        "renderer",
        wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
          highlights = {
            border = "Normal",
          },
          border = "single",
        }))
      )
    end,
    config = function(_, opts)
      require("wilder").setup(opts)
    end,
    branch = "master",
    commit = "679f348",
  },

  {
    "jeetsukumaran/vim-markology",
    event = "VeryLazy",
    init = function()
      vim.g.markology_include = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    end,
    branch = "master",
    commit = "9681b3f",
  },

  {
    "akinsho/toggleterm.nvim",
    cmd = { "ToggleTerm" },
    config = true,
    init = function()
      require("core.utils").load_mappings("toggleterm")
    end,
    opts = function()
      return require("plugins.configs.toggleterm")
    end,
    branch = "main",
    commit = "12cba0a",
  },

  {
    "Exafunction/codeium.vim",
    cmd = { "CodeiumEnable" },
    init = function()
      require("core.utils").load_mappings("codeium")
    end,
    branch = "main",
    commit = "70ba94a",
  },

  {
    "natecraddock/workspaces.nvim",
    cmd = { "Telescope workspaces" },
    config = true,
    opts = function()
      return require("plugins.configs.others").workspaces
    end,
    branch = "master",
    commit = "a6fb499",
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    opts = function()
      return require("plugins.configs.others").nvim_autopairs
    end,
    branch = "master",
    commit = "a52fc6e",
  },

  {
    "mg979/vim-visual-multi",
    event = "BufEnter",
    init = function()
      require("core.mappings").vm.init()
    end,
    branch = "master",
    commit = "724bd53",
  },

  {
    "michaeljsmith/vim-indent-object",
    keys = { "v" },
    branch = "master",
    commit = "5c5b24c",
  },

  -- debugging
  {
    "mfussenegger/nvim-dap",
    keys = { "<leader>d" },
    dependencies = {
      require("plugins.configs.nvim-dap").dapui,
      require("plugins.configs.nvim-dap").virtual_text,
      require("plugins.configs.nvim-dap").python,
      require("plugins.configs.nvim-dap").go,
    },
    init = function()
      require("core.utils").load_mappings("nvim_dap")
    end,
    config = function()
      require("plugins.configs.nvim-dap").csharp.setup()
      require("plugins.configs.nvim-dap").rust.setup()
    end,
    branch = "master",
    commit = "31e1ece",
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    lazy = false,
    config = true,
    branch = "master",
    commit = "31692b2",
  },

  -- Only load whichkey after all the gui
  {
    "folke/which-key.nvim",
    keys = { "<leader>", '"', "'", "`", "c", "v", "g" },
    init = function()
      require("core.utils").load_mappings("whichkey")
    end,
    opts = function()
      return require("plugins.configs.others").whichkey
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "whichkey")
      require("which-key").setup(opts)
    end,
    branch = "main",
    commit = "7ccf476",
  },
}

local config = require("core.utils").load_config()

if #config.plugins > 0 then
  table.insert(default_plugins, { import = config.plugins })
end

require("lazy").setup(default_plugins, config.lazy_nvim)
