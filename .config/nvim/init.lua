-- ============================================================================
-- NEOVIM CONFIGURATION (Lua)
-- ============================================================================
-- Modern setup with Neorg for notes/journaling/tasks + coding support

-- ============================================================================
-- BASIC SETTINGS
-- ============================================================================

vim.opt.showcmd = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ttyfast = true
vim.opt.syntax = "on"

-- Indentation
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

-- Better defaults
vim.opt.mouse = "a"                     -- Enable mouse
vim.opt.clipboard = "unnamedplus"       -- Use system clipboard
vim.opt.undofile = true                 -- Persistent undo
vim.opt.ignorecase = true               -- Case insensitive search
vim.opt.smartcase = true                -- But case sensitive if capital used
vim.opt.termguicolors = false           -- Use terminal's colors instead

-- ============================================================================
-- KEY MAPPINGS
-- ============================================================================

vim.g.mapleader = " "                   -- Set leader key to space

-- Exit insert mode with jk
vim.keymap.set("i", "jk", "<Esc>")

-- Navigate visual lines instead of logical lines
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- ============================================================================
-- LAZY.NVIM PLUGIN MANAGER SETUP
-- ============================================================================

-- Bootstrap lazy.nvim (auto-install if not present)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- PLUGINS
-- ============================================================================

require("lazy").setup({

  -- ============================================================================
  -- NEORG - Notes, Journal, Tasks, Calendar
  -- ============================================================================
  {
    "nvim-neorg/neorg",
    lazy = false,        -- Load immediately (recommended by Neorg)
    version = "*",       -- Pin to latest stable release
    config = function()
      require("neorg").setup({
        load = {
          ["core.defaults"] = {},  -- Load default behavior
          ["core.concealer"] = {}, -- Pretty icons/concealing
          ["core.dirman"] = {      -- Workspace management
            config = {
              workspaces = {
                notes = "~/neorg/notes",
                journal = "~/neorg/journal",
                work = "~/neorg/work",
              },
              default_workspace = "notes",
            },
          },
          ["core.completion"] = {
            config = { engine = "nvim-cmp" },
          },
          ["core.journal"] = {     -- Journaling support
            config = {
              workspace = "journal",
            },
          },
          ["core.keybinds"] = {    -- Default keybindings
            config = {
              default_keybinds = true,
            },
          },
        },
      })
    end,
  },

  -- ============================================================================
  -- LATEX SUPPORT
  -- ============================================================================
  {
    "lervag/vimtex",
    ft = "tex",
    config = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_compiler_method = "latexmk"
    end,
  },

  -- ============================================================================
  -- TREESITTER - Better Syntax Highlighting
  -- ============================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "bash", "markdown", "latex", "norg" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- ============================================================================
  -- LSP - Language Server Support (Autocomplete, Diagnostics)
  -- ============================================================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",       -- LSP installer
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright" },  -- Python LSP
      })

      -- Python setup using new Neovim 0.11 API
      vim.lsp.config.pyright = {}
      vim.lsp.enable('pyright')

      -- Keybindings for LSP
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
    end,
  },

  -- ============================================================================
  -- COMPLETION
  -- ============================================================================
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",  -- LSP completion source
      "hrsh7th/cmp-buffer",    -- Buffer completion source
      "hrsh7th/cmp-path",      -- Path completion source
      "L3MON4D3/LuaSnip",      -- Snippet engine
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
          { name = "neorg" },
        },
      })
    end,
  },

  -- ============================================================================
  -- TELESCOPE - Fuzzy Finder
  -- ============================================================================
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    },
  },

  -- ============================================================================
  -- FILE EXPLORER
  -- ============================================================================
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    },
    config = function()
      require("nvim-tree").setup({
        view = { width = 30 },
        renderer = { group_empty = true },
      })
    end,
  },

  -- ============================================================================
  -- GIT INTEGRATION
  -- ============================================================================
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },
  { "tpope/vim-fugitive" },

  -- ============================================================================
  -- QUALITY OF LIFE
  -- ============================================================================
  { "tpope/vim-commentary" },   -- Comment with gc
  { "tpope/vim-surround" },     -- Surround text objects
  {
    "windwp/nvim-autopairs",    -- Auto close brackets
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  {
    "folke/which-key.nvim",     -- Keybinding help
    event = "VeryLazy",
    config = function()
      require("which-key").setup()
    end,
  },

  -- ============================================================================
  -- UI ENHANCEMENTS
  -- ============================================================================
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          component_separators = { left = "|", right = "|" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },
})

-- ============================================================================
-- ADDITIONAL SETTINGS
-- ============================================================================

-- Auto-format on save for Python
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})
