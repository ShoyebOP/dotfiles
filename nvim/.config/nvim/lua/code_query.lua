local M = {}

function M.query()
    local fzf = require("fzf-lua")
    local snippets_path = vim.fn.stdpath("data") .. "/lazy/friendly-snippets"
    
    -- We use live_grep on the snippets directory because it's the best way 
    -- to find "natural language" descriptions of how to do things.
    -- If they have friendly-snippets, this is like an offline MDN/StackOverflow.
    
    fzf.fzf_exec({
        "[Search Snippets Library]",
        "[Search LSP Workspace Symbols]",
        "[Search Neovim Help/Docs]",
    }, {
        prompt = "Query Source> ",
        winopts = { height = 0.3, width = 0.4 },
        actions = {
            ["default"] = function(selected)
                local choice = selected[1]
                
                if choice == "[Search Snippets Library]" then
                    -- Search all snippet JSONs for descriptions like "center a div"
                    fzf.live_grep({
                        cwd = snippets_path,
                        prompt = "Snippet Search> ",
                        -- We filter for descriptions and prefixes in JSON files
                        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
                    })
                elseif choice == "[Search LSP Workspace Symbols]" then
                    fzf.lsp_live_workspace_symbols()
                elseif choice == "[Search Neovim Help/Docs]" then
                    fzf.help_tags()
                end
            end
        }
    })
end

return M