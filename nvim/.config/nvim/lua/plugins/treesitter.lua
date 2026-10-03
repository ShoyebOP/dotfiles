return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
        local lang_config = require("lang")
        local base_parsers = {
            "diff",
            "printf",
            "query",
            "regex",
            "vim",
            "vimdoc",
            "xml",
            "luadoc",
            "luap",
        }
        -- Retained as the documented on-demand install set: run
        -- :TSInstall <lang> for any entry below (needs tree-sitter CLI
        -- plus a C compiler). No auto-install: parsers provision on demand.
        local parsers = vim.list_extend(base_parsers, lang_config.treesitter_parsers or {})
        return {
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },
        }
    end,
}
