# Phase 05: Editor Autonomy & fzf-lua Migration - Pattern Map

**Mapped:** 2026-10-03
**Files analyzed:** 13 (2 new, 9 modified, 2 reference/unchanged)
**Analogs found:** 12 / 13 (1 lockfile entry shape has no code analog — planner follows lazy.nvim pin convention)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `nvim/.config/nvim/lua/plugins/which-key.lua` (NEW) | config (lazy spec) | event-driven | `nvim/.config/nvim/lua/plugins/to-do.lua` + `noice.lua` | role-match |
| `nvim/.config/nvim/lua/plugins/fzf-lua.lua` (NEW) | config (lazy spec) | request-response | `nvim/.config/nvim/lua/plugins/telescope.lua` (deleted, structural template) | exact |
| `nvim/.config/nvim/lua/utils/mason-install-all.lua` (EDIT) | utility | batch | itself (44 lines, sync-branch patch) | exact |
| `nvim/.config/nvim/lua/base/keymaps.lua` (EDIT) | config (keymap registry) | request-response | itself (lines 42–66, 92, 171–172) | exact |
| `nvim/.config/nvim/lua/plugins/nvim-tree.lua` (EDIT) | config (plugin spec + config fn) | request-response | itself (lines 60–104) | exact |
| `nvim/.config/nvim/lua/plugins/alpha.lua` (EDIT) | config (plugin spec + dashboard) | request-response | itself (lines 20–34) | exact |
| `nvim/.config/nvim/lua/lang/markdown/plugins.lua` (EDIT) | config (lang plugin spec) | request-response | itself (lines 109–115) + `lua/lang/django/plugins.lua` (dep-block shape) | exact |
| `nvim/.config/nvim/lua/icons/lspkind.lua` (EDIT) | utility (icon table) | transform | itself (line 44) | exact |
| `nvim/.config/nvim/lua/plugins/blink-cmp.lua` (EDIT) | config (plugin spec + build) | request-response | itself (lines 1–35, LuaSnip `run=` key) | exact |
| `nvim/.config/nvim/lua/plugins/treesitter.lua` (EDIT) | config (plugin spec + build) | batch | itself (35 lines) | exact |
| `setup.sh` (EDIT: get_deps, trigger, wipe) | config (installer) | batch | itself (DRY_RUN idiom, typed-yes gate, dep→binary map, run_stow slot) | exact |
| `nvim/.config/nvim/lazy-lock.json` (EDIT: pin churn) | config (lockfile) | batch | itself (pin entry shape) | exact |
| `nvim/.config/nvim/lua/plugins/telescope.lua` (DELETE) | config (lazy spec) | request-response | itself (45 lines — doubles as fzf-lua structural template) | exact |

Reference-only (read, do NOT edit): `lua/plugins/mason.lua` (D-03 build hook preserved), `lua/plugins/to-do.lua` (D-08 plenary dep stays), `lua/lang/init.lua` (D-12 source of truth, unchanged).

## Pattern Assignments

### `nvim/.config/nvim/lua/plugins/which-key.lua` (NEW — config, event-driven)

**Analog:** `nvim/.config/nvim/lua/plugins/to-do.lua` (lines 1–5) + `nvim/.config/nvim/lua/plugins/noice.lua` (lines 1–8)

**Spec shape pattern** — every `event = "VeryLazy"` + `opts` table spec in this repo follows this exact skeleton (to-do.lua:1-5, noice.lua:1-8):
```lua
-- Source: nvim/.config/nvim/lua/plugins/to-do.lua:1-5
return {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
```

```lua
-- Source: nvim/.config/nvim/lua/plugins/noice.lua:1-8
return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
    },
    opts = {
```

**New file copies:** single `return { "<owner>/<repo>", event = "VeryLazy", opts = { preset, delay, triggers, spec } }`. No `config` function needed — lazy.nvim auto-calls `setup(opts)`, same as noice.lua/to-do.lua which have no `config` key. Group-only `spec` entries per RESEARCH.md Pattern 2; table-form triggers `{ { "<auto>", mode = "nxso" } }` (never bare `"<auto>"` — Pitfall 2).

**Error handling:** none in analogs — spec files contain no pcall/try; failures surface via `:checkhealth which-key` (D-12 gate).

---

### `nvim/.config/nvim/lua/plugins/fzf-lua.lua` (NEW — config, request-response)

**Analog:** `nvim/.config/nvim/lua/plugins/telescope.lua` (lines 1–18, full 45-line file)

**Spec shape pattern** (telescope.lua:1-18) — copy this skeleton, swap owner/repo/deps/cmd/opts:
```lua
-- Source: nvim/.config/nvim/lua/plugins/telescope.lua:1-18
return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        -- Fuzzy Finder Algorithm which requires local dependencies to be built.
        -- Only load if `make` is available. Make sure you have the system
        -- requirements installed.
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function()
                return vim.fn.executable("make") == 1
            end,
        },
        "nvim-telescope/telescope-ui-select.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    cmd = "Telescope",
    opts = function()
```

**What the new file keeps vs drops:**
- KEEP the `dependencies = { "nvim-tree/nvim-web-devicons" }` line (RESEARCH: devicons survives via explicit dep so icons survive any future blink/nvim-tree change; blink-cmp.lua:41 already declares the same dep — precedent).
- DROP the `cond = executable("make")` guard entirely (D-11 bans silent fallback; fzf-lua has no build step).
- DROP `telescope-ui-select.nvim` — replaced by `opts = { ui_select = {} }` one-flag opt-in (RESEARCH Pattern 1).
- `cmd = "FzfLua"` mirrors `cmd = "Telescope"` (telescope.lua:18); RESEARCH A1 allows fallback to `event = "VeryLazy"` if executor finds cmd-loading doesn't trigger — same `event` key shape as to-do.lua:3.

**Opts-with-function pattern** (telescope.lua:19-21) — use plain `opts` table (no function needed; fzf-lua needs no `require` at opts time):
```lua
-- Source: telescope.lua:19-21 (function-form opts; new file uses simpler table form)
    opts = function()
        local actions = require("telescope.actions")
```

---

### `nvim/.config/nvim/lua/utils/mason-install-all.lua` (EDIT — utility, batch)

**Analog:** itself — full 44-line file read; patch adds headless sync branch, preserves everything else (D-03).

**Imports/aggregator pattern** (lines 1–6) — single source of truth via `lang` aggregator; DO NOT duplicate package list:
```lua
-- Source: nvim/.config/nvim/lua/utils/mason-install-all.lua:1-6
local M = {}

M.get_packages = function()
    local lang_config = require("lang")
    return lang_config.mason_packages or {}
end
```

**Core collect-missing pattern** (lines 11–24) — `has_package` guard + `is_installed` check + warn-and-skip; the headless branch reuses this loop verbatim:
```lua
-- Source: nvim/.config/nvim/lua/utils/mason-install-all.lua:11-24
    mr.refresh(function()
        local packages = M.get_packages()
        local to_install = {}

        for _, package_name in ipairs(packages) do
            if mr.has_package(package_name) then
                local pkg = mr.get_package(package_name)
                if not pkg:is_installed() then
                    table.insert(to_install, package_name)
                end
            else
                vim.notify("Warning: Mason doesn't have package: " .. package_name, vim.log.levels.WARN)
            end
        end
```

**Blocking-install + notify pattern** (lines 26–35) — `:MasonInstall` blocks headless (documented primitive); keep both notify branches:
```lua
-- Source: nvim/.config/nvim/lua/utils/mason-install-all.lua:26-35
        if #to_install > 0 then
            vim.cmd("MasonInstall " .. table.concat(to_install, " "))
            vim.notify(
                "Mason: Installing " .. #to_install .. " packages: " .. table.concat(to_install, ", "),
                vim.log.levels.INFO
            )
        else
            vim.notify("Mason: All packages already installed", vim.log.levels.INFO)
        end
```

**User-command pattern** (lines 38–42) — command name/signature unchanged; headless trigger invokes this same command:
```lua
-- Source: nvim/.config/nvim/lua/utils/mason-install-all.lua:38-42
vim.api.nvim_create_user_command("MasonInstallAll", function()
    M.install_all()
end, {
    desc = "Install all Mason packages defined in language configs",
})
```

**Headless detection idiom** (no in-repo precedent — from RESEARCH Pattern 3, mason upstream `is_headless` def): `local is_headless = #vim.api.nvim_list_uis() == 0`. Sync branch: `require("mason-registry").refresh()` with NO callback (blocks), then same collect loop, then `vim.cmd("MasonInstall …")` (blocks headless). Async `mr.refresh(function() … end)` body stays byte-identical for interactive use.

---

### `nvim/.config/nvim/lua/base/keymaps.lua` (EDIT — config, request-response)

**Analog:** itself — Telescope block lines 42–66, Noice line 92, Todo lines 171–172.

**String-RHS keymap pattern** (lines 43, 50–57) — minimal `map("n", key, "<cmd>…<cr>", { desc })`; fzf-lua plain pickers copy this with only RHS swapped:
```lua
-- Source: nvim/.config/nvim/lua/base/keymaps.lua:43,50-57
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Grep through files" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "List open buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "Jump to marks" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "Git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "Git status" })
```

**Lua-function RHS pattern** (lines 58–66) — REQUIRED where picker takes opts (`<leader>fa` hidden, `<leader>th` colorschemes) or needs `noremap`:
```lua
-- Source: nvim/.config/nvim/lua/base/keymaps.lua:58-66
map(
    "n",
    "<leader>f",
    "<cmd>Telescope current_buffer_fuzzy_find<CR>",
    { desc = "Fuzzy search current buffer", noremap = true }
)
map("n", "<leader>th", function()
    require("telescope.builtin").colorscheme({ enable_preview = true })
end, { desc = "Choose colorscheme with preview" })
```

**Multi-line string-RHS with extra opts** (lines 44–49) — template for `<leader>fa` → `require("fzf-lua").files({ hidden = true })`:
```lua
-- Source: nvim/.config/nvim/lua/base/keymaps.lua:44-49
map(
    "n",
    "<leader>fa",
    "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "Find all files" }
)
```

**Noice/Todo command-RHS pattern** (lines 92, 171–172) — 1:1 command swap, keys+desc frozen:
```lua
-- Source: nvim/.config/nvim/lua/base/keymaps.lua:92,171-172
map("n", "<leader>N", "<cmd>Noice telescope<CR>", { noremap = true, desc = "Noice history" })
map("n", "<leader>st", "<cmd>TodoTelescope<cr>", { desc = "Todo" })
map("n", "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", { desc = "Todo/Fix/Fixme" })
```

**Dead-binding delete pattern** (line 57) — `<leader>pt` (`Telescope terms`, errors today) is DELETED with no replacement; terminal path stays toggleterm `<C-\>`:
```lua
-- Source: nvim/.config/nvim/lua/base/keymaps.lua:57 (DELETE — no fzf-lua equivalent exists)
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "Hidden terminals" })
```

**File header + alias** (lines 1–2): `---@diagnostic disable: undefined-global` + `local map = vim.keymap.set` — preserved, new bindings use the same `map` alias.

---

### `nvim/.config/nvim/lua/plugins/nvim-tree.lua` (EDIT — config, request-response)

**Analog:** itself — config-function lines 60–104.

**Setup-then-keymaps pattern** (lines 60–61, 96–104) — `setup(opts)` first, keymaps at tail of `config` fn; keep shape, swap telescope body for fzf-lua:
```lua
-- Source: nvim/.config/nvim/lua/plugins/nvim-tree.lua:60-61,96-104
    config = function(_, opts)
        require("nvim-tree").setup(opts)
        -- keymaps
        vim.keymap.set("n", "<c-f>", function()
            launch_telescope("find_files")
        end, { desc = "Find files from tree node" })

        vim.keymap.set("n", "<c-fg>", function()
            launch_telescope("live_grep")
        end, { desc = "Live grep from tree node" })
```

**Cwd-scoping pattern** (lines 87–89) — `get_node_under_cursor` → `basedir` logic is KEPT; only the picker call changes (`opts.cwd`/`search_dirs`/`attach_mappings` block lines 82–94 is DELETED — fzf-lua takes `{ cwd = basedir }` and its default file action opens+jumps natively):
```lua
-- Source: nvim/.config/nvim/lua/plugins/nvim-tree.lua:87-89 (KEEP)
            local node = api.tree.get_node_under_cursor()
            local basedir = node.type == "directory" and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ":h")
```

**Delete-entirely pattern** (lines 63–80) — the whole `view_selection`/`actions`/`action_state` block goes; `pcall(require, "telescope")` guard (lines 82–86) goes with it (D-11: no silent fallback — fzf-lua loads unconditionally).

---

### `nvim/.config/nvim/lua/plugins/alpha.lua` (EDIT — config, request-response)

**Analog:** itself — user-command lines 20–22 + dashboard buttons lines 26–34.

**User-command wrapper pattern** (lines 20–22) — keep command NAME, swap body to fzf-lua:
```lua
-- Source: nvim/.config/nvim/lua/plugins/alpha.lua:20-22
        vim.api.nvim_create_user_command("ColorschemeWithPreview", function()
            require("telescope.builtin").colorscheme({ enable_preview = true })
        end, {})
```

**Dashboard button pattern** (lines 26–34) — `dashboard.button(shortcut, label, action)`; only `ff`/`r`/`k` actions change, `n`/`l`/`q` untouched:
```lua
-- Source: nvim/.config/nvim/lua/plugins/alpha.lua:26-34
        dashboard.section.buttons.val = {
            dashboard.button("ff", "  Find file", "<cmd>Telescope find_files<cr>"),
            dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<cr>"),
            dashboard.button("n", "  New file", "<cmd> ene <BAR> startinsert <cr>"),
            dashboard.button("th", "  Themes", "<cmd>ColorschemeWithPreview<cr>"),
            dashboard.button("l", "  Lazy", "<cmd> Lazy <cr>"),
            dashboard.button("k", "  List Keymaps", "<cmd>Telescope keymaps<cr>"),
            dashboard.button("q", "  Quit", "<cmd> qa <cr>"),
        }
```

**Opts-function + devicons-dep pattern** (lines 1–8): `dependencies = { "nvim-tree/nvim-web-devicons" }` — precedent for declaring devicons explicitly in the new fzf-lua spec.

---

### `nvim/.config/nvim/lua/lang/markdown/plugins.lua` (EDIT — config, request-response)

**Analog:** itself (lines 109–115) + `nvim/.config/nvim/lua/lang/django/plugins.lua` (lines 5–11, dependency-block shape).

**Spurious-dep removal pattern** — delete the `dependencies` block, keep event key:
```lua
-- Source: nvim/.config/nvim/lua/lang/markdown/plugins.lua:109-115 (DELETE lines 112-114)
    {
        "brianhuster/live-preview.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvim-telescope/telescope.nvim",
        },
    },
```

**Optional picker-pin precedent** — RESEARCH verifies live-preview ships `M.fzflua` backend with default `picker = ""`; planner MAY add `opts = { picker = "fzflua" }` but default is already telescope-free, so bare deletion is the minimal correct edit. (No in-repo `opts`-on-live-preview precedent — do not invent config keys beyond the verified `picker` flag.)

---

### `nvim/.config/nvim/lua/icons/lspkind.lua` (EDIT — utility, transform)

**Analog:** itself — plain return-table, line 44.

**Icon-table pattern** (lines 43–45) — one-line `Key = "glyph"` entries; D-08 researcher decision is DROP:
```lua
-- Source: nvim/.config/nvim/lua/icons/lspkind.lua:43-45
    Ripgrep = "",
    Telescope = "",
    Grep = "",
```

**Consumer pattern** (blink-cmp.lua:51-62) — `require "icons.lspkind"` indexed by `ctx.kind` with `"󰈚"` fallback, so dropping the unreachable `Telescope` key is safe:
```lua
-- Source: nvim/.config/nvim/lua/plugins/blink-cmp.lua:51-54
                    text = function(ctx)
                        local icons = require "icons.lspkind"
                        local icon = (icons[ctx.kind] or "󰈚")
```

---

### `nvim/.config/nvim/lua/plugins/blink-cmp.lua` (EDIT — config, request-response)

**Analog:** itself — LuaSnip spec lines 1–7 (dead `run=` key).

**Dead `run=` key pattern** (lines 2–7) — lazy.nvim honors `build`, never `run`; replace with guarded function-form `build`:
```lua
-- Source: nvim/.config/nvim/lua/plugins/blink-cmp.lua:2-7
    {
        "L3MON4D3/LuaSnip",
        event = "InsertEnter",
        dependencies = { "rafamadriz/friendly-snippets", event = "InsertEnter" },
        run = "make install_jsregexp",
```

**pcall-optional-config pattern** (lines 15–16) — model for graceful-degradation handling (missing-compiler paths warn, never crash):
```lua
-- Source: nvim/.config/nvim/lua/plugins/blink-cmp.lua:15-16
            local status_ok, lang_config = pcall(require, "lang")
            if status_ok and lang_config.luasnip_extends then
```

**Prebuilt-binary precedent** (lines 135–139) — blink.cmp fuzzy engine already compiler-free via pinned prebuilt binary; no change here, cited as D-10 no-compromise evidence:
```lua
-- Source: nvim/.config/nvim/lua/plugins/blink-cmp.lua:135-139
                fuzzy = {
                    implementation = "rust",
                    prebuilt_binaries = {
                        force_version = "v1.8.0",
                    },
```

Function-form `build` shape: `build = function() if vim.fn.executable("make") == 1 then return "make install_jsregexp" end end` (LazyVim echo-guard precedent per RESEARCH Pitfall 4 — silently skips where no compiler, never errors).

---

### `nvim/.config/nvim/lua/plugins/treesitter.lua` (EDIT — config, batch)

**Analog:** itself — full 35-line file; rewrite to minimal main-branch spec.

**Current (dead) shape** — ALL of `opts` keys + half of `build` are dead on pinned `main` (RESEARCH Pitfall 3):
```lua
-- Source: nvim/.config/nvim/lua/plugins/treesitter.lua:1-5,20-23
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate | TSInstallAll",
    ...
        return {
            auto_install = true,
            ensure_installed = parsers,
            ignore_install = { "awk" },
```

**Aggregator-fed list pattern** (lines 6–19) — `require("lang").treesitter_parsers` + `vim.list_extend` over `base_parsers`; keep the LIST construction (feeds docs/on-demand `:TSInstall`), drop only the dead `setup()` keys it was fed into:
```lua
-- Source: nvim/.config/nvim/lua/plugins/treesitter.lua:6-19
    opts = function()
        local lang_config = require("lang")
        local base_parsers = {
            "diff",
            "printf",
            "query",
            "regex",
            "vim",
            "vimdoc",
            "xml",
            "luadoc",
            "luap",
        }
        local parsers = vim.list_extend(base_parsers, lang_config.treesitter_parsers or {})
```

New shape: `branch = "main"`, `build = ":TSUpdate"`, `event = { "BufReadPost", "BufNewFile" }` kept; dead `opts` (`auto_install`/`ensure_installed`/`ignore_install`) deleted with a comment pointing at on-demand `:TSInstall <lang>`. Do NOT re-add auto-install.

---

### `setup.sh` (EDIT — installer, batch)

**Analog:** itself — three edit sites, each with an established idiom.

**Site 1 — dep lists** (`setup.sh:24`, `setup.sh:194/198/202`): `make`/`gcc` move from `common` to OPTIONAL. Current shape:
```bash
# Source: setup.sh:24,194
ALL_TOOLCHAIN=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
```
Demotion keeps `ALL_TOOLCHAIN`/`UNIFIED_ROWS` membership (checklist still offers them) but `verify_deps`/`install_deps` treat them warn-if-missing. Dep→binary map precedent (setup.sh:275): `case "$dep" in neovim) cmd="nvim" ;; ripgrep) cmd="rg" ;; nodejs) cmd="node" ;; *) cmd="$dep" ;; esac` — extend with optional-marking, identity mapping already covers `make`/`gcc`.

**Warn-not-abort precedent** (setup.sh:326-331, termux per-pkg warning) — template for optional-dep warning wording:
```bash
# Source: setup.sh:324-332
    if [[ "$family" == "termux" ]]; then
        local pkg
        for pkg in "${missing[@]}"; do
            if ! "${install_cmd[@]}" "$pkg"; then
                echo "Warning: failed to install '$pkg' via '${install_cmd[*]} $pkg'." >&2
                echo "  Try manually: ${install_cmd[*]} $pkg" >&2
```

**Site 2 — headless Mason trigger** (insert between `post_verify` and `ensure_local_files`, setup.sh:2042-2045):
```bash
# Source: setup.sh:2042-2045 (insertion slot — trigger lands after post_verify succeeds)
    quarantine_scan
    if ! run_stow; then echo "Error: stow deployment failed." >&2; exit 1; fi
    if ! post_verify; then echo "Error: post-verify failed — deployment incomplete." >&2; exit 1; fi
    ensure_local_files
```
Invariants: gate on nvim selected (`printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim`, same idiom as setup.sh:879/939) AND `command -v nvim`; `DRY_RUN` early-return + `[DRY RUN] Would run:` preview (same idiom as setup.sh:322,857-862); NEVER fail install — `elif ! nvim …; then echo "Warning: …" >&2; fi` (D-02), set -e safe. Strict-mode file header (setup.sh:1-4): `set -Eeuo pipefail`, `${1-}` guards on all function params.

**Site 3 — widened wipe** (setup.sh:878-887 preview + 938-946 live): swap fixed literal `~/.local/share/nvim/mason` → `~/.local/share/nvim`, keep typed-`yes` gate (setup.sh:896-914) and `[DRY RUN]` preview text updated to new path:
```bash
# Source: setup.sh:878-887 (DRY-RUN preview block — update path literal + echo text)
        # Mason preview when nvim deselected (D-02)
        if ! printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim; then
            if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
                echo "Removing Mason artefacts: ~/.local/share/nvim/mason (nvim deselected)" >&2
                echo "[DRY RUN] Would run: rm -rf ~/.local/share/nvim/mason"
```
```bash
# Source: setup.sh:938-946 (live wipe — keep gate above, widen path, keep rmdir-tolerant tail)
    # Mason artefact cleanup only when nvim not selected (D-02)
    if ! printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim; then
        if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
            echo "Removing Mason artefacts: ~/.local/share/nvim/mason (nvim deselected)" >&2
            # DRY_RUN already returned above, so this is live path — remove directly
            rm -rf "$HOME/.local/share/nvim/mason"
            rmdir "$HOME/.local/share/nvim" 2>/dev/null || true
        fi
    fi
```
Safety: path is a fixed `$HOME`-anchored literal, never constructed from user input; the trailing `rmdir … || true` line is deleted (whole dir goes via `rm -rf`).

**Stow-guard non-regression** (setup.sh:959-964): `mkdir -p "$HOME/.config"` + `stow … --no-folding --restow` in `run_stow` — Phase-5 edits must not touch these lines (Phase-4 carry-forward).

---

### `nvim/.config/nvim/lazy-lock.json` (EDIT — lockfile, batch)

**Analog:** itself — pin entry shape `"<repo>": { "branch": "<b>", "commit": "<sha>" }`:
```json
// Source: lazy-lock.json (telescope pins to DELETE, plenary pin STAYS)
"plenary.nvim": { "branch": "master", "commit": "74b06c6c75e4eeb3108ec01852001636d85a932b" },
"telescope.nvim": { "branch": "master", "commit": "506338434fec5ad19cb1f8d45bf92d66c4917393" },
"telescope-fzf-native.nvim": { "branch": "main", "commit": "6fea601bd2b694c6f2ae08a6c6fab14930c60e2c" },
"telescope-ui-select.nvim": { "branch": "master", "commit": "6e51d7da30bd139a6950adf2a47fda6df9fa06d2" },
```
Churn: ADD `fzf-lua` + `which-key.nvim` pins (materialize via headless `:Lazy! sync`), DELETE 3 `telescope*` pins, KEEP `plenary.nvim` pin. Verify `grep -c telescope lazy-lock.json` == 0. Commit in same commit as spec edits (atomic-docs rule).

---

### `nvim/.config/nvim/lua/plugins/telescope.lua` (DELETE — config, request-response)

**Analog:** itself. Full 45-line file deleted (D-07). Verification: `grep -ri telescope nvim/.config/nvim/lua/` returns zero hits after all edits (lspkind key drop included). No data migration; restore from git if reverted. Its spec skeleton is reused as the structural template for `fzf-lua.lua` (see above).

---

## Shared Patterns

### Lazy.nvim spec skeleton
**Source:** `nvim/.config/nvim/lua/plugins/noice.lua:1-8`, `to-do.lua:1-5`, `telescope.lua:1-18`
**Apply to:** both NEW files (`which-key.lua`, `fzf-lua.lua`)
```lua
return {
    "<owner>/<repo>",
    event = "VeryLazy",          -- or cmd = { ... } for command-lazy (telescope.lua:18)
    dependencies = { "..." },    -- only real runtime deps; no spurious entries (D-07)
    opts = { ... },              -- lazy auto-calls setup(opts); no config fn needed
}
```
Rules: no `build` key unless a real build step exists (new specs have none); never `cond = executable("make")` in picker path (D-11); never `run =` (dead packer key — Pitfall 4).

### pcall + vim.notify graceful degradation
**Source:** `nvim/.config/nvim/lua/lang/init.lua:42,96-101`, `blink-cmp.lua:15-16`, `mason-install-all.lua:22`
**Apply to:** `mason-install-all.lua` headless branch, `blink-cmp.lua` guarded build, any optional-capability path
```lua
-- Source: nvim/.config/nvim/lua/lang/init.lua:42,96-101
    local status_ok, lang_config = pcall(require, lang_module)
        vim.notify(
            "Failed to load: " .. lang_module .. "\nError: " .. tostring(lang_config),
            vim.log.levels.WARN
        )
```
Missing-compiler / missing-package paths WARN, never crash, never abort install.

### Installer DRY_RUN preview idiom
**Source:** `setup.sh:322`, `setup.sh:857-862`
**Apply to:** headless Mason trigger + widened wipe preview text
```bash
if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"; return 0; fi
echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"$HOME\" --no-folding --delete $pkg"
```
Every mutation previews before executing; live path unreachable under `--dry-run`.

### Installer warn-and-continue (never fail)
**Source:** `setup.sh:300` (`if ! sudo pacman -Sy; then echo "Warning: … continuing" >&2; fi`), `setup.sh:324-332` (termux per-pkg warning)
**Apply to:** headless Mason trigger exit-code policy (D-02), make/gcc optional warnings (D-10)
```bash
if ! sudo pacman -Sy; then echo "Warning: pacman -Sy failed, continuing" >&2; fi
```

### Keymap desc-as-documentation
**Source:** `nvim/.config/nvim/lua/base/keymaps.lua` (every binding carries `desc`); feeds D-06 which-key
**Apply to:** all rewritten picker bindings — keys may stay identical, RHS changes, `desc` strings preserved byte-identical so which-key leaf hints survive with zero extra spec.

### Aggregator as single source of truth
**Source:** `nvim/.config/nvim/lua/lang/init.lua:14-23` (`M` table + `deduplicate`), `lua/lang/python/python.lua:25-28` (per-lang `mason_packages`)
**Apply to:** headless install + D-12 verification (`require("lang").mason_packages`); no plan duplicates the package list in shell.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| *(none)* | — | — | Every file maps to itself or a same-role spec; lockfile pin shape covered by existing entries. Upstream-only patterns (which-key v3 `spec` table, fzf-lua `ui_select`, Mason sync `refresh()`) come from RESEARCH.md verified source reads (`/tmp/opencode/research05/*`), not from this repo — planner cites RESEARCH.md Pattern 1–3 verbatim for those. |

## Metadata

**Analog search scope:** `nvim/.config/nvim/lua/plugins/`, `nvim/.config/nvim/lua/{base,utils,icons,lang}/`, `setup.sh` (2051 lines, targeted Grep + offset reads), `lazy-lock.json`
**Files scanned:** 13 target files + 4 reference files (mason.lua, to-do.lua, lang/init.lua, django/plugins.lua)
**Pattern extraction date:** 2026-10-03
