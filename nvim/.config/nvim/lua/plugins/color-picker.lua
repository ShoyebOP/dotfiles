return {
  -- High-performance color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      filetypes = { "*" },
      user_default_options = {
        RGB = true, RRGGBB = true, names = true, RRGGBBAA = true,
        rgb_fn = true, hsl_fn = true, css = true, css_fn = true,
        mode = "background", tailwind = true,
      },
    },
    config = function(_, opts)
      require("colorizer").setup(opts.filetypes, opts.user_default_options)
    end,
  },

  -- Keyboard-centric Color Picker
  {
    "uga-rosa/ccc.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>cp", "<cmd>CccPick<cr>", desc = "Color Picker (HSL Sliders)" },
      {
        "<leader>cP",
        function()
          local ccc = require("ccc")
          local picker = ccc.picker.custom_entries({
            "#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#00FFFF", "#FF00FF", "#FFFFFF", "#000000",
            "#800000", "#008000", "#000080", "#808000", "#008080", "#800080", "#C0C0C0", "#808080",
            "#FFA500", "#A52A2A", "#800000", "#FF7F50", "#FF6347", "#E9967A", "#F08080", "#CD5C5C",
            "#FF4500", "#FF0000", "#FF1493", "#FF69B4", "#FFB6C1", "#FFC0CB", "#DB7093", "#C71585",
            "#8B008B", "#9400D3", "#9932CC", "#BA55D3", "#A020F0", "#8A2BE2", "#9370DB", "#6A5ACD",
            "#483D8B", "#7B68EE", "#4169E1", "#0000FF", "#0000CD", "#00008B", "#000080", "#191970",
            "#333333", "#444444", "#555555", "#666666", "#777777", "#888888", "#999999", "#AAAAAA"
          })
          -- Open the picker with this specific custom grid
          require("ccc.core").new({
            pickers = { picker },
            inputs = { ccc.input.hsl },
            outputs = { ccc.output.hex }
          }):pick()
        end,
        desc = "Color Palette (Grid)",
      },
    },
    opts = function()
      local ccc = require("ccc")
      return {
        highlighter = { auto_enable = false },
        inputs = { ccc.input.hsl },
        outputs = {
          ccc.output.hex,
          ccc.output.css_rgb,
          ccc.output.css_hsl,
        },
        pickers = {
          ccc.picker.hex,
          ccc.picker.css_rgb,
        },
      }
    end,
  },
}
