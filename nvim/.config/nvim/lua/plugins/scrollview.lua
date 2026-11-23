return {
    "dstein64/nvim-scrollview",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("scrollview").setup({
            excluded_filetypes = { "nerdtree", "NvimTree" },
            current_only = true,
            base = "left",
            column = 1,
            winblend_gui = 100,
            signs_on_startup = { "gitsigns" },
            signs_scrollbar_overlap = "off",
            diagnostics_severities = { vim.diagnostic.severity.ERROR },
        })
        require("scrollview.contrib.gitsigns").setup({
            show_in_folds = true,
            current_only = true,
            priority = 10,
        })
    end,
}
