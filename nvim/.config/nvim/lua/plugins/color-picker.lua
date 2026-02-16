return {
  -- High-performance color highlighter
  {
    "norcalli/nvim-colorizer.lua",
    event = "VeryLazy",
    opts = {
      filetypes = { "*" },
      user_default_options = {
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        names = true, -- "Name" codes like Blue or blue
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        AARRGGBB = true, -- 0xAARRGGBB hex codes
        rgb_fn = true, -- CSS rgb() and rgba() functions
        hsl_fn = true, -- CSS hsl() and hsla() functions
        css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
        mode = "background", -- Set the display mode.
      },
    },
    config = function(_, opts)
      require("colorizer").setup(opts.filetypes, opts.user_default_options)
    end,
  },

  -- UI Library required for Minty
  { "NvChad/volt", lazy = true },

  -- Visual Color Picker
  {
    "NvChad/minty",
    cmd = { "Shades", "Huefi" },
    keys = {
      {
        "<leader>cp",
        function()
          require("minty.huefi").open()
        end,
        desc = "Color Picker (Huefi)",
      },
      {
        "<leader>cS",
        function()
          require("minty.shades").open()
        end,
        desc = "Color Shades",
      },
    },
  },
}
