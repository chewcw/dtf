require("core")

require("core.utils").load_mappings()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").lazy(lazypath)
end

vim.opt.rtp:prepend(lazypath)
require("plugins")

vim.cmd("colorscheme rasmus2")

-- ----------------------------------------------------------------------------
-- Load ext.lua file if available
-- ----------------------------------------------------------------------------
-- Load external lua file, only for customization done for each
-- neovim environment, for example my own docker container.
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/?.lua"
pcall(require, "ext")
