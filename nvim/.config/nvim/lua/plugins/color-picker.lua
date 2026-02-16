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
    },
    opts = function()
      local ccc = require("ccc")
      return {
        highlighter = {
          auto_enable = true,
          lsp = true,
        },
        inputs = { ccc.input.hsl },
        outputs = {
          ccc.output.hex,
          ccc.output.css_rgb,
          ccc.output.css_hsl,
        },
        pickers = {
          ccc.picker.hex,
          ccc.picker.css_rgb,
          ccc.picker.css_hsl,
          ccc.picker.css_name,
        },
      }
    end,
  },
}
