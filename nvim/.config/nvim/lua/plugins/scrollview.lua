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

        -- Thin solid separator between the far-left git markers and the
        -- native per-line gitsigns. Signcolumn cells are whole characters and
        -- cannot form a 1px line, and Neovim left-aligns native signs, so the
        -- separator is a dedicated one-column float instead of reserved cells.
        vim.api.nvim_set_hl(0, "ScrollViewSeparator", { link = "LineNr" })
        local sep_group = vim.api.nvim_create_augroup("ScrollViewSeparator", { clear = true })
        local sep_win, sep_bufnr = nil, nil
        local function close_separator()
            if sep_win and vim.api.nvim_win_is_valid(sep_win) then
                vim.api.nvim_win_close(sep_win, true)
            end
            sep_win, sep_bufnr = nil, nil
        end
        local function draw_separator()
            close_separator()
            local height = vim.api.nvim_win_get_height(0)
            sep_bufnr = vim.api.nvim_create_buf(false, true)
            local lines = {}
            for _ = 1, height do
                lines[#lines + 1] = "│"
            end
            vim.api.nvim_buf_set_lines(sep_bufnr, 0, -1, false, lines)
            sep_win = vim.api.nvim_open_win(sep_bufnr, false, {
                relative = "win",
                width = 1,
                height = height,
                row = 0,
                col = 2,
                focusable = false,
                style = "minimal",
                border = "none",
                zindex = 45,
            })
            vim.wo[sep_win].winhighlight = "Normal:ScrollViewSeparator,NormalFloat:ScrollViewSeparator"
        end
        local function refresh_separator()
            if vim.api.nvim_get_current_buf() == sep_bufnr then
                return
            end
            vim.schedule(draw_separator)
        end
        vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "VimResized", "WinScrolled" }, {
            group = sep_group,
            callback = refresh_separator,
        })
        vim.api.nvim_create_autocmd("User", {
            group = sep_group,
            pattern = "ScrollViewRefresh",
            callback = function()
                vim.schedule(draw_separator)
            end,
        })
        vim.api.nvim_create_autocmd("WinClosed", {
            group = sep_group,
            callback = function()
                vim.schedule(function()
                    if not sep_win or not vim.api.nvim_win_is_valid(sep_win) then
                        refresh_separator()
                    end
                end)
            end,
        })
        vim.schedule(draw_separator)
    end,
}
