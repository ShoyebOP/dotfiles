-- ========================================================================== --
-- ==                  SECTION 1: PERFORMANCE & HDD TUNING                 == --
-- ========================================================================== --
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.lazyredraw = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

-- ========================================================================== --
-- ==                      SECTION 2: UI & APPEARANCE                      == --
-- ========================================================================== --
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.showmode = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.clipboard = "unnamedplus"
vim.cmd("syntax on")

-- ========================================================================== --
-- ==                    SECTION 3: KEYBOARD MAPPINGS                      == --
-- ========================================================================== --
vim.g.mapleader = " "
local map = vim.keymap.set

-- [ THE "NO-YANK" CLIPBOARD LOGIC ]
-- These remap the ORIGINAL keys to use the "Black Hole" register ("_)
map({"n", "v"}, "d", '"_d', { desc = "Delete (no-yank)" })
map({"n", "v"}, "D", '"_D', { desc = "Delete line (no-yank)" })
map({"n", "v"}, "c", '"_c', { desc = "Change (no-yank)" })
map({"n", "v"}, "C", '"_C', { desc = "Change line (no-yank)" })
map("n", "x", '"_x', { desc = "Delete char (no-yank)" })

-- Handle double-tap deletes (dd, cc)
map("n", "dd", '"_dd', { desc = "Delete line (no-yank)" })
map("n", "cc", '"_cc', { desc = "Change line (no-yank)" })

-- Manual Cut (The only way to yank while deleting)
map({"n", "v"}, "<leader>d", 'd', { desc = "Cut (yank + delete)" })
map("n", "<leader>dd", 'dd', { desc = "Cut line (yank + delete)" })

-- Paste over selection without yanking the replaced text
map("x", "p", 'P', { desc = "Paste over (no-yank)" })

-- [ Standard Navigation ]
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- [ Utilities ]
map({"n", "i", "v"}, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map("n", "<leader>?", function() require("which-key").show({ global = false }) end, { desc = "Show keymaps" })
map("n", "<leader>ps", "<cmd>Lazy<cr>", { desc = "Plugin Status" })
map("n", "<leader>cq", function() require("code_query").query() end, { desc = "Code Query" })

-- [ LSP Mappings ]
map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code Action" })
map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>ld", "<cmd>FzfLua lsp_definitions<cr>", { desc = "Definition" })
map("n", "<leader>lR", "<cmd>FzfLua lsp_references<cr>", { desc = "References" })
map("n", "<leader>ls", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "Symbols" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover Docs" })

-- ========================================================================== --
-- ==                    SECTION 4: PLUGIN MANAGEMENT                      == --
-- ========================================================================== --
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- UI: Catppuccin, Lualine, Bufferline
    { "catppuccin/nvim", name = "catppuccin", priority = 1000, config = function() vim.cmd.colorscheme "catppuccin-mocha" end },
    { "nvim-lualine/lualine.nvim", dependencies = "nvim-tree/nvim-web-devicons", config = function() require("lualine").setup({ options = { theme = "catppuccin", section_separators = "", component_separators = "|" } }) end },
    { "akinsho/bufferline.nvim", dependencies = "nvim-tree/nvim-web-devicons", config = function() require("bufferline").setup{} end },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

    -- SEARCH & GIT
    { "ibhagwan/fzf-lua", dependencies = "nvim-tree/nvim-web-devicons", keys = { 
        { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" }, 
        { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Find Text" },
        { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find Buffers" },
        { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Find Help" },
    } },
    { "folke/which-key.nvim", event = "VeryLazy", config = function() 
        local wk = require("which-key") 
        wk.setup({ win = { border = "rounded" } })
        wk.add({ 
            { "<leader>f", group = "Find/Files" }, 
            { "<leader>b", group = "Buffers" }, 
            { "<leader>g", group = "Git" }, 
            { "<leader>l", group = "LSP" },
            { "<leader>p", group = "Plugins" },
            { "<leader>c", group = "Code" },
            { "<leader>C", group = "Color" },
        }) 
    end },
    { "kdheepak/lazygit.nvim", keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } } },
    { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },
    { "mattn/emmet-vim", ft = { "html", "css", "javascriptreact", "typescriptreact" } },

    -- COLOR TOOLS
    {
        "NvChad/nvim-colorizer.lua",
        lazy = false, -- Load immediately for reliable buffer attachment
        config = function()
            require("colorizer").setup({
                filetypes = { "*" },
                user_default_options = {
                    RGB = true,
                    RGBA = true,
                    RRGGBB = true,
                    RRGGBBAA = true,
                    AARRGGBB = true,
                    names = true,
                    rgb_fn = true,
                    hsl_fn = true,
                    css = true,
                    css_fn = true,
                    mode = "background",
                    tailwind = true,
                },
            })
        end,
    },
    {
        "uga-rosa/ccc.nvim",
        keys = {
            { "<leader>Cc", "<cmd>CccPick<cr>", desc = "Color Picker" },
            { "<leader>Cv", "<cmd>CccConvert<cr>", desc = "Color Convert" },
            { "<leader>Ct", "<cmd>CccHighlighterToggle<cr>", desc = "Toggle Highlighter" },
        },
        config = function()
            require("ccc").setup({
                highlighter = {
                    auto_enable = false,
                    lsp = true,
                },
            })
        end,
    },

    -- FILE MANAGEMENT
    { "stevearc/oil.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() require("oil").setup() end, keys = { { "-", "<cmd>Oil<cr>", desc = "Open parent directory" } } },

    -- TREESITTER & CLOSERS
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            -- Handle the recent nvim-treesitter refactor where 'configs' was renamed to 'config'
            local ok, ts = pcall(require, "nvim-treesitter.configs")
            if not ok then ts = require("nvim-treesitter.config") end
            
            ts.setup({
                ensure_installed = { "python", "javascript", "html", "css", "lua" },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },
    { 
        "windwp/nvim-ts-autotag", 
        config = function() 
            require("nvim-ts-autotag").setup({
                opts = {
                    enable_close = true,
                    enable_rename = true,
                    enable_close_on_slash = true,
                },
            }) 
        end 
    },
    { 
        "windwp/nvim-autopairs", 
        config = function() 
            local npairs = require("nvim-autopairs")
            npairs.setup({
                check_ts = true,
                ts_config = {
                    lua = { "string" },
                    javascript = { "template_string" },
                }
            }) 
            
            local Rule = require('nvim-autopairs.rule')
            
            -- Simple rule for < > brackets in HTML/React
            npairs.add_rules({
                Rule("<", ">", { "html", "javascriptreact", "typescriptreact", "vue", "xml" })
            })
        end 
    },
    { "echasnovski/mini.surround", version = false, config = function() require("mini.surround").setup() end },
    { "echasnovski/mini.comment", version = false, config = function() require("mini.comment").setup() end },

    -- LSP MANAGEMENT (MASON)
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        config = function() require("mason").setup({ ui = { border = "rounded" } }) end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "hrsh7th/cmp-nvim-lsp", "folke/lazydev.nvim" },
        config = function()
            require("lazydev").setup()
            local lspconfig = require("lspconfig")
            local caps = require('cmp_nvim_lsp').default_capabilities()
            
            -- Capabilities for HTML without LSP snippets to avoid duplication
            local html_caps = vim.deepcopy(caps)
            html_caps.textDocument.completion.completionItem.snippetSupport = false

            require("mason-lspconfig").setup({
                ensure_installed = { "pyright", "html", "cssls", "ts_ls", "lua_ls", "emmet_ls" },
                handlers = {
                    function(server_name)
                        lspconfig[server_name].setup({
                            capabilities = caps,
                        })
                    end,
                    ["html"] = function()
                        lspconfig.html.setup({
                            capabilities = html_caps,
                        })
                    end,
                    ["emmet_ls"] = function()
                        lspconfig.emmet_ls.setup({
                            capabilities = caps,
                            filetypes = { "html", "css", "javascriptreact", "typescriptreact" },
                        })
                    end,
                },
            })
        end
    },
    { "folke/lazydev.nvim", ft = "lua", opts = {} },

    -- AUTOCOMPLETION (CMP)
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = { 
            "hrsh7th/cmp-nvim-lsp", 
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip", 
            "saadparwaiz1/cmp_luasnip", 
            "rafamadriz/friendly-snippets",
            "windwp/nvim-autopairs",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
                formatting = {
                    format = function(entry, vim_item)
                        vim_item.menu = ({
                            nvim_lsp = "[LSP]",
                            luasnip = "[Snippet]",
                            buffer = "[Buffer]",
                            path = "[Path]",
                        })[entry.source.name]
                        return vim_item
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<CR>"] = cmp.mapping.confirm({ 
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true 
                    }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", group_index = 1 },
                    { name = "luasnip", group_index = 1 },
                }, {
                    { name = "buffer", group_index = 2 },
                    { name = "path", group_index = 2 },
                }),
            })

            -- Integrate nvim-autopairs with cmp
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
    },
})
