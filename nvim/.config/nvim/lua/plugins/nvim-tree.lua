return {
    "nvim-tree/nvim-tree.lua",
    priority = 1000,
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = {
        filters = {
            git_ignored = false,
            custom = { "^.git$", ".DS_Store", "thumbs.db", "^.hidden$" },
        },
        live_filter = {
            prefix = "[FILTER]: ",
            always_show_folders = false,
        },
        disable_netrw = true,
        hijack_cursor = true,
        sync_root_with_cwd = true,
        update_focused_file = {
            enable = true,
            update_root = false,
        },
        view = {
            width = 35,
            preserve_window_proportions = true,
        },
        git = {
            enable = true,
            ignore = false,
        },
        renderer = {
            add_trailing = true,
            highlight_git = "all",
            highlight_opened_files = "icon",
            indent_markers = { enable = true },
            icons = {
                glyphs = {
                    default = "󰈚",
                    bookmark = "󰆤",
                    modified = "●",
                    hidden = "󰜌",
                    folder = {
                        default = "",
                        empty = "",
                        empty_open = "",
                        open = "",
                        symlink = "",
                    },
                    git = {
                        unstaged = "✗",
                        staged = "✓",
                        unmerged = "",
                        renamed = "➜",
                        untracked = "★",
                        deleted = "",
                        ignored = "◌",
                    },
                },
            },
        },
    },
    config = function(_, opts)
        require("nvim-tree").setup(opts)

        local api = require("nvim-tree.api")

        local function basedir_from_node()
            local node = api.tree.get_node_under_cursor()
            return node.type == "directory" and node.absolute_path
                or vim.fn.fnamemodify(node.absolute_path, ":h")
        end

        -- keymaps
        vim.keymap.set("n", "<c-f>", function()
            require("fzf-lua").files({ cwd = basedir_from_node() })
        end, { desc = "Find files from tree node" })

        vim.keymap.set("n", "<c-fg>", function()
            require("fzf-lua").live_grep({ cwd = basedir_from_node() })
        end, { desc = "Live grep from tree node" })
    end,
}
