return {
  {
    "hrsh7th/nvim-cmp",
    ft = { "css", "scss", "less", "postcss" },
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.completion = opts.completion or {}

      -- Keep normal auto trigger
      opts.completion.autocomplete = {
        cmp.TriggerEvent.TextChanged,
      }

      -- Filter out '{' from trigger characters
      local original_enabled = opts.enabled
      opts.enabled = function()
        local context = require("cmp.config.context")
        local col = vim.fn.col(".")
        local line = vim.fn.getline(".")
        local char_before = line:sub(col - 1, col - 1)

        if char_before == "{" then
          return false
        end

        if type(original_enabled) == "function" then
          return original_enabled()
        elseif type(original_enabled) == "boolean" then
          return original_enabled
        end

        return not context.in_treesitter_capture("comment")
          and not context.in_syntax_group("Comment")
      end

      return opts
    end,
  },
}
