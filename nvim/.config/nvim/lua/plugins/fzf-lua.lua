return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    opts = {
        -- Dress vim.ui.select with fzf-lua (replaces the legacy select-dressing plugin).
        ui_select = {},
    },
}
