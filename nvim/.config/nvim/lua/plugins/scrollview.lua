return {
    "dstein64/nvim-scrollview",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("scrollview").setup({
            excluded_filetypes = { "nerdtree", "NvimTree" },
            current_only = true,
            base = "left",
            column = 2,
            signs_overflow = "left",
            winblend_gui = 0,
            signs_show_in_folds = true,
            signs_on_startup = { "gitsigns" },
            signs_scrollbar_overlap = "off",
            diagnostics_severities = { vim.diagnostic.severity.ERROR },
        })
        -- Hide only the scrollbar: link its dedicated highlight group to the
        -- editor background. Sign windows keep their own highlight groups, so
        -- the gutter markers stay opaque even though the bar is invisible.
        vim.api.nvim_set_hl(0, "ScrollView", { link = "Normal" })
        -- The plugin's own `highlight default link ScrollView Visual` and the
        -- deferred colorscheme load run after this config function, so
        -- re-assert the link once the event loop has settled (also re-assert
        -- on later colorscheme changes).
        vim.schedule(function()
            vim.api.nvim_set_hl(0, "ScrollView", { link = "Normal" })
        end)
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("ScrollViewHiddenBar", { clear = true }),
            callback = function()
                vim.api.nvim_set_hl(0, "ScrollView", { link = "Normal" })
            end,
        })
        require("scrollview.contrib.gitsigns").setup({
            enabled = true,
            add_priority = 10,
            change_priority = 10,
            delete_priority = 10,
        })
    end,
}
