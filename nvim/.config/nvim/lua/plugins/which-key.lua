return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 200,
        -- TABLE form: a bare "<auto>" string is silently dropped by the
        -- which-key spec parser, so the popup would never appear (Pitfall 2).
        triggers = { { "<auto>", mode = "nxso" } },
        -- Group names only: leaf hints render from the existing `desc`
        -- strings every keymap already carries (D-06). No per-key entries,
        -- no deprecated `register()` calls.
        spec = {
            { "<leader>f", group = "find" },
            { "<leader>s", group = "search/todo" },
            { "<leader>e", group = "run" },
            { "<leader>m", group = "markdown/marks" },
            { "<leader>t", group = "toggle/theme" },
            { "<leader>x", group = "trouble/buffer" },
            { "<leader>g", group = "git" },
            { "<leader>c", group = "git-commits" },
        },
    },
}
