return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.enabled = function()
        local ft = vim.bo.filetype
        if ft == "css" or ft == "scss" or ft == "less" or ft == "postcss" then
          local col = vim.fn.col(".")
          local line = vim.fn.getline(".")
          local char_before = line:sub(col - 1, col - 1)
          if char_before == "{" then
            return false
          end
        end
        return not vim.tbl_contains({ "lua", "markdown" }, vim.bo.filetype)
          or vim.bo.buftype ~= "prompt"
      end
      return opts
    end,
  },
}
