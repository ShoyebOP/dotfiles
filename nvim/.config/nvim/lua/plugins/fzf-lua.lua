return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    opts = {
        -- Dress vim.ui.select with fzf-lua (replaces telescope-ui-select.nvim).
        ui_select = {},
    },
}
