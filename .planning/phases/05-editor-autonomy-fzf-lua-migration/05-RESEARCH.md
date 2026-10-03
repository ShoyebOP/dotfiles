# Phase 05: Editor Autonomy & fzf-lua Migration - Research

**Researched:** 2026-10-03
**Domain:** Neovim plugin ecosystem (lazy.nvim specs, Mason headless install, which-key v3, fzf-lua picker migration, treesitter main-branch, LuaSnip/blink compiler-free config) + Bash installer integration
**Confidence:** HIGH (all load-bearing claims verified by reading upstream sources cloned this session + in-repo source reads)

## Summary

Phase 5 replaces telescope with `ibhagwan/fzf-lua`, adds `folke/which-key.nvim` v3, triggers headless Mason installs from `setup.sh`, and demotes `make`/`gcc` to optional. The migration is unusually safe: every current telescope call-site has a verified 1:1 fzf-lua equivalent (`TodoFzfLua` exists as a first-class command, `:Noice pick` auto-selects fzf-lua once telescope is gone, live-preview.nvim already ships an `fzflua` picker backend), `plenary.nvim` provably stays (only two consumers, one of which is todo-comments), and `nvim-web-devicons` survives via blink.cmp's dependency.

Three findings materially shape the plans. First, the naive D-01 trigger (`nvim --headless -c "MasonInstallAll" -c "qall"`) **silently installs nothing**: our `MasonInstallAll` wraps the *async* `mr.refresh(callback)` form, so `qall` fires before the registry refresh completes. The documented blocking primitive is `:MasonInstall` itself (headless ⇒ `run_blocking`), so the lua side needs a small synchronous-refresh branch for headless use. Second, D-05's `triggers = { "<auto>" }` shorthand is **silently dropped** by which-key's spec parser (bare strings are not valid spec items) — the planner must use table form `{ { "<auto>", mode = "nxso" } }` or omit `triggers` entirely (the default already equals that). Third, the treesitter spec is configured for an API that no longer exists: on the pinned `main` branch, `ensure_installed` / `auto_install` / `ignore_install` / `TSInstallAll` have **zero references** — they are dead keys, and `build = ":TSUpdate | TSInstallAll"` invokes a nonexistent command. The no-compromise D-10 config therefore starts by deleting dead keys, not by adding cleverness.

**Primary recommendation:** Keep every current leader key byte-identical and change only the right-hand side to `:FzfLua …` / `TodoFzfLua` / `:Noice pick` (fzf-lua ships no global invoking keymaps, so there are no "upstream defaults" to collide with and no freed-key conflicts); gate the headless Mason trigger on a synchronous-refresh patch to `mason-install-all.lua`; write the which-key spec with group names only and table-form triggers; demote make/gcc with a guarded function-form LuaSnip build and a fixed treesitter `build = ":TSUpdate"`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Installer trigger ONLY — `setup.sh` runs headless `nvim --headless -c "MasonInstallAll"` post-stow. NO `mason-tool-installer` plugin is added; the editor gains no startup auto-install path. Rationale: single explicit install moment keeps startup fast and offline-safe; ROADMAP's deferred backstop layer was discussed and rejected. — **Reversibility:** reversible — remove the setup.sh call; editor behavior unchanged.
- **D-02:** Headless Mason failure = warn and continue, never fail the install. On failure `setup.sh` prints a warning plus the exact retry command (`nvim --headless -c "MasonInstallAll"` or interactive `:MasonInstallAll`) and continues; missing LSPs degrade until the user retries. — **Reversibility:** reversible — exit-code policy is a local edit.
- **D-03:** `:MasonInstallAll` (`nvim/.config/nvim/lua/utils/mason-install-all.lua`) stays as the manual repair path with unchanged semantics (refresh registry → install missing → notify). The existing `build = ":MasonInstallAll"` hook in `lua/plugins/mason.lua` is preserved.
- **D-04:** Uninstall wipe WIDENED — on nvim-deselected uninstall, remove the whole `~/.local/share/nvim` data dir instead of only `mason/`. Live evidence: the dir holds only regenerable state (`lazy/` plugin checkouts, `mason/` binaries, `site/`, picker history); mason-only leaves ~42 plugin checkouts behind, contradicting clean reversal. Keeps the existing typed-`yes` gate (no `--yes` bypass change) and `[DRY RUN]` preview. — **Reversibility:** reversible — reinstall re-clones/re-installs everything; no user config lives in the data dir (config is stowed, undo files are not stored there, shada is in `~/.local/state`).
- **D-05:** `folke/which-key.nvim` v3 with `preset = "modern"`, `delay = 200`, `triggers = { "<auto>" }` — LazyVim-like popup on `<Space>` (leader) with nested hints for subsequent keys.
- **D-06:** Minimal spec — register leader GROUP names only (file, search/todo, run, workspace, git, etc.); leaf hints come from the existing `desc` strings every keymap already carries. No per-key explicit spec entries. Researcher confirms the v3 API shape (`spec` vs `register`); planner wires group names to match the (possibly remapped) picker keys from D-09.
- **D-07:** FULL removal — delete `lua/plugins/telescope.lua` (all three specs: `telescope.nvim`, `telescope-fzf-native.nvim`, `telescope-ui-select.nvim`) and rewrite every call site: `nvim-tree.lua` telescope integration (`<c-f>`/`<c-fg>` + `view_selection` attach logic), `alpha.lua` `ColorschemeWithPreview` + dashboard buttons (`ff`/`r`/`k`), all `Telescope ...` keymaps in `base/keymaps.lua`, `TodoTelescope` bindings, `Noice telescope` binding, and the spurious `live-preview.nvim → telescope.nvim` dependency in `lua/lang/markdown/plugins.lua`. Zero `require("telescope")` / `:Telescope` references remain. — **Reversibility:** reversible — specs and call sites restore from git; no data migration.
- **D-08:** `plenary.nvim` STAYS — `todo-comments.nvim` declares it as a dependency and it remains installed. Remove it only if the researcher proves zero remaining consumers. The `Telescope = ""` icon key in `lua/icons/lspkind.lua` is cosmetic; researcher decides keep-vs-drop, planner follows.
- **D-09:** Keymap rule — every NON-telescope keymap stays byte-identical unless a conflict forces movement (current keys win on conflict). Telescope-backed bindings are removed and the new fzf-lua bindings prefer fzf-lua's OWN upstream default keys where conflict-free, falling back to the current `<leader>` keys on conflict. All `desc` strings preserved (feeds D-06 which-key). Researcher maps each current picker (`find_files`, `live_grep`, `buffers`, `help_tags`, `oldfiles`, `marks`, `git_commits`, `git_status`, `current_buffer_fuzzy_find`, colorscheme-with-preview, Todo, Noice history) plus resolves the mystery `Telescope terms` picker (no known extension registers it — likely dead config) to its closest FzfLua builtin.
- **D-10:** Demote `make` + `gcc` from `common` to OPTIONAL with warn-if-missing — never hard-require, never silently break. The picker itself needs neither (no build step, no silent fallback). Remaining consumers: `blink-cmp` (`run = "make install_jsregexp"`, optional jsregexp) and treesitter (`auto_install = true` + `build = ":TSUpdate | TSInstallAll"`, needs a C compiler for parser builds). Live proof of safety: `gcc` is uninstallable in Termux (no `gcc` package — `clang` is the compiler there; `pkg install gcc` can never satisfy the probe) yet nvim works fine on Termux today. Researcher MUST additionally investigate no-compromise configuration so demotion costs nothing: e.g. treesitter parser behavior without a compiler present (prebuilt/shipped parsers? graceful skip?), blink-cmp without jsregexp (prebuilt binary path?), `clang` as accepted compiler alternative. Planner implements whatever no-compromise config research supports, plus the installer warn-if-missing wording. — **Reversibility:** reversible — re-add to `common`; dep-list edit only.
- **D-11:** No silent fallback path for the picker anywhere (no `cond = executable("make")` pattern carried over); `nvim --headless -c "checkhealth"` must report the picker healthy.
- **D-12:** NO self-test/TAP harness in Phase 5 (stays Phase 6 HLTH-01). Phase 5 verification is lightweight and headless: `checkhealth` zero errors (incl. fzf-lua) + installed Mason package list matches `require("lang").mason_packages`. Phase 6 absorbs these checks into its gates later.
- **D-13:** Two plans, sequential — 05-01: Mason auto-install trigger + widened cleanup + which-key popup; 05-02: fzf-lua migration + make/gcc demotion (+ no-compromise treesitter/blink config). 05-02 needs no 05-01 code, but 05-01 goes first so the headless Mason path is proven before the picker surface churns.

### the agent's Discretion
- Researcher picks exact FzfLua builtin per picker binding (D-09), fate of the `lspkind` Telescope icon key (D-08), and the no-compromise treesitter/blink config (D-10).
- Researcher confirms which-key v3 spec API and whether `telescope-ui-select`'s dressing role needs an fzf-lua equivalent (`fzf-lua` ui-select provider).
- Planner decides installer code shape for the headless trigger + warn wording (D-01/D-02) and the widened wipe messaging (D-04), following Phase-1 `DRY_RUN` preview + strict-mode conventions.

### Deferred Ideas (OUT OF SCOPE)
- Full `--self-test` TAP harness (stow symlinks, tool versions, `checkhealth`, Mason list, keybinds, PATH, keyd preview) — owned by Phase 6 (HLTH-01), not this phase (D-12).
- `mason-tool-installer` deferred `ensure_installed` backstop — explicitly DECIDED AGAINST in D-01 (not deferred); do not re-propose without new evidence.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EDIT-01 | Neovim LSPs/formatters work after setup without manual `:MasonInstallAll` — installer triggers headless `MasonInstallAll` post-stow; uninstall removes Mason artefacts when nvim deselected | Headless-blocking analysis (Pitfall 1 + Mason code sketch); insertion slot `setup.sh:2043-2044`; widened-wipe path safety (Security Domain) |
| EDIT-02 | which-key popup on `<Space>` (LazyVim-like) via `folke/which-key.nvim` v3 `preset=modern delay=200 spec` | v3 API confirmation (`spec` table, `register()` deprecated); triggers table-form correction; group-only spec starter list; lazy spec shape |
| EDIT-03 | Picker is `ibhagwan/fzf-lua` — telescope + telescope-fzf-native removed; fzf sorter built in (no make/gcc build); make+gcc dropped/demoted; no silent fallback | Complete D-09 picker map (every binding → verified builtin); plenary-keep proof; devicons-survival proof; lspkind-key drop; no-compromise treesitter/blink config; `Telescope terms` resolution (dead → delete) |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- **Zsh default, Bash installer:** Phase 5 touches neither shell path — no `zsh/.zshrc`, `setup.sh` arg-parsing, or checklist changes beyond the Mason trigger call and dep-list demotion. (No Nushell work per scope filter.)
- **Reversibility:** every edit is git-reversible; the widened `~/.local/share/nvim` wipe keeps the typed-`yes` gate and `[DRY RUN]` preview; `lazy-lock.json` pin changes restore via git.
- **Safety (no destructive writes without preview/confirmation):** the widened `rm -rf` MUST stay behind the existing typed-`yes` gate with dry-run preview text updated to the new path; the path is a fixed literal (`$HOME/.local/share/nvim`), never constructed from user input.
- **OS support:** make/gcc demotion must work across `arch`/`debian`/`termux` families; Termux already proves the no-compiler path (clang-only environment).
- **Machine-local:** no new machine-local files in this phase; do not disturb `ensure_local_files` (`setup.sh:2045`) or the `local.lua` pattern.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mason package install (headless trigger) | Installer (Bash) | Editor (Lua command) | `setup.sh` owns process exit-code policy (D-02 warn-and-continue); the editor owns install semantics (`mason-install-all.lua`). The trigger is a one-shot `nvim --headless` invocation, not editor startup logic. |
| Picker UI (files/grep/buffers/…) | Editor (Neovim plugin) | — | Pure in-editor concern; installer only guarantees the `fzf` binary is present (already in `common` deps). |
| `vim.ui.select` dressing | Editor (fzf-lua `ui_select`) | — | Replaces `telescope-ui-select.nvim`; one setup flag, no installer involvement. |
| which-key popup | Editor (Neovim plugin) | — | Pure in-editor concern; group names derive from keymap `desc` strings. |
| Compiler/toolchain demotion | Installer (dep lists) | Editor (guarded builds) | `setup.sh` `get_deps`/`verify_deps` own required-vs-optional policy; lua specs own graceful degradation (guarded `build`, prebuilt binaries). |
| Parser provisioning (treesitter) | Editor (on-demand `:TSInstall`) | — | Explicitly NOT an installer job (scope guard: EDIT-01 covers Mason only; auto-installing parsers would need network+compiler at install time). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ibhagwan/fzf-lua` | rolling `main` (commit-pinned via `lazy-lock.json` at install) | Picker: files/grep/buffers/help/git/colorschemes/keymaps + `vim.ui.select` dressing | fzf sorter built in — zero build step; full verified builtin map covers every current telescope call-site; first-class `TodoFzfLua`/`Noice pick`/live-preview integrations exist upstream |
| `folke/which-key.nvim` | v3 (`M.version = "3.17.0"` observed on main this session [VERIFIED: /tmp/opencode/research05/which-key.nvim/lua/which-key/config.lua:4]) | Leader-key discovery popup | De-facto standard (LazyVim default); v3 `spec` table replaces deprecated `register()`; group-only spec needs zero per-key entries |
| `mason-org/mason.nvim` | v2 (`main`, already in use) | LSP/formatter/linter provisioning | Already the project's provisioner; `:MasonInstall` blocks headless (documented primitive for the D-01 trigger) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `nvim-lua/plenary.nvim` | pinned `74b06c6c7` (stays) | `todo-comments.nvim` dependency | KEEP — removal would break `TodoFzfLua` search backend (rg + plenary job) |
| `nvim-tree/nvim-web-devicons` | already installed (via blink.cmp dep) | File icons in fzf-lua pickers | Declare explicitly in the fzf-lua spec so icons survive any future blink/nvim-tree change |
| `L3MON4D3/LuaSnip` | pinned `a62e1083a` | Snippet engine for blink.cmp | Keep; change dead `run=` key to guarded function-form `build` so jsregexp builds where possible, silently skips where not |
| `saghen/blink.cmp` | `version = '1.*'` + `fuzzy.prebuilt_binaries.force_version = "v1.8.0"` (already configured) | Completion | Already compiler-free (downloads prebuilt fuzzy lib); no change needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Headless `MasonInstallAll` + lua sync patch | setup.sh generates pkg list → direct `:MasonInstall <pkgs>` | Direct call is the documented blocking primitive and needs no lua change, but costs a second headless nvim boot (~seconds) and duplicates the aggregator call; the lua patch keeps the single D-01 command. Planner picks; both verified sound. |
| fzf-lua `setup({})` minimal | `setup({"telescope"})` profile for familiarity | The telescope profile mimics telescope layout, but D-09 says prefer fzf-lua's own defaults and every key is preserved anyway — the profile buys nothing and adds a non-default to explain. Use minimal setup. |
| `mason-tool-installer.nvim` backstop | — | REJECTED by D-01 (do not re-propose). |
| snacks.nvim picker | fzf-lua | snacks is present only as a django dep with `opts = {}` (picker disabled); adopting it would be a new-picker decision outside EDIT-03 scope. |

**Installation:**
```bash
# No registry packages. Editor plugins resolve via lazy.nvim GitHub specs;
# pins land in nvim/.config/nvim/lazy-lock.json on first install (commit it).
# System binaries already in setup.sh common deps: fzf, rg, git, node/npm.
```

**Version verification:** Not applicable via `npm view`/`pip`/`cargo` — this phase installs zero registry packages. Plugin identity was verified by successful `git clone` of the exact spec URLs this session (`github.com/ibhagwan/fzf-lua`, `github.com/folke/which-key.nvim`, plus `mason-org/mason.nvim`, `folke/todo-comments.nvim`, `folke/noice.nvim` for API checks). `lazy-lock.json` gains `which-key.nvim` + `fzf-lua` pins and loses `telescope*` pins at executor time; plenary pin stays.

## Package Legitimacy Audit

> No npm/PyPI/crates packages are installed in this phase, so the registry legitimacy gate is N/A by construction. The equivalent supply-chain surface is lazy.nvim GitHub specs + Mason registry downloads, audited below.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `ibhagwan/fzf-lua` | none (lazy.nvim GitHub spec) | ~5 yrs, active main | n/a (GitHub) | github.com/ibhagwan/fzf-lua (cloned OK this session) | OK | Approved — add spec + commit lazy-lock pin |
| `folke/which-key.nvim` | none (lazy.nvim GitHub spec) | ~6 yrs, v3 stable | n/a (GitHub) | github.com/folke/which-key.nvim (cloned OK this session) | OK | Approved — add spec + commit lazy-lock pin |
| Mason registry packages (pyright/ruff/…) | Mason registry (install-time binaries, not code deps) | n/a | n/a | Mason registry metadata | OK | Approved — unchanged mechanism, installer-triggered |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*No `postinstall`/`build` script risk is introduced: the new specs (`fzf-lua`, `which-key`) carry no `build` key. The only `build` keys in scope are the pre-existing LuaSnip jsregexp compile (guarded per this research) and the treesitter `build` string (fixed to compiler-free `:TSUpdate`). Both run inside Neovim's `:!`/job sandbox at plugin-install time, not at shell level.*

## Architecture Patterns

### System Architecture Diagram

```
bash setup.sh (live run)
  │
  ├─ verify → install → re-verify (make/gcc now OPTIONAL: warn-if-missing, never abort)
  ├─ checklist → quarantine_scan → run_stow → post_verify        [setup.sh:2042-2044]
  │                                                              [VERIFIED: setup.sh:2042-2044]
  ├─ ★ NEW (05-01): nvim --headless -c "MasonInstallAll" -c "qall"
  │     │            (warn-and-continue on nonzero exit; gated on nvim selected)
  │     ▼
  │   MasonInstallAll: mr.refresh() SYNC when headless ──► :MasonInstall <missing>
  │                    (blocks via run_blocking)                  (blocks headless)
  │     └── warns on unknown names (mr.has_package guard, kept) ──► notify summary
  │
  ├─ ensure_local_files → offer_chsh → "Setup complete"          [setup.sh:2045-2048]
  │
  └─ uninstall (nvim deselected): typed-yes gate ──► rm -rf ~/.local/share/nvim (fixed literal)
                                              └─► [DRY RUN] preview text updated to new path

nvim startup (unchanged shape)
  │
  ├─ lazy.nvim ──► lang/init.lua aggregator ──► mason_packages (D-12 source of truth)
  ├─ fzf-lua spec ──► setup({ ui_select = {} }) ──► dresses vim.ui.select
  │     ├── :FzfLua <picker> / lua FzfLua.<picker>(opts)   (keymaps, dashboard, tree)
  │     └── in-window keymaps = fzf-lua upstream defaults (untouched)
  └─ which-key ──► spec = { group-only entries } ──► popup on <Space> (delay 200)
```

### Recommended Project Structure

```
nvim/.config/nvim/lua/plugins/
├── fzf-lua.lua          # NEW (05-02): spec + setup({ ui_select = {} }) + devicons dep
├── which-key.lua        # NEW (05-01): event VeryLazy + opts { preset=modern, delay=200,
│                        #   triggers={{ "<auto>", mode="nxso" }}, spec={ groups } }
├── telescope.lua        # DELETED (05-02)
├── nvim-tree.lua        # EDIT: drop telescope attach_mappings, use FzfLua files/live_grep + cwd
├── alpha.lua            # EDIT: ColorschemeWithPreview → FzfLua colorschemes; buttons ff/r/k
├── to-do.lua            # UNCHANGED (plenary dep stays)
└── blink-cmp.lua        # EDIT: run= → guarded function build (LuaSnip jsregexp)
nvim/.config/nvim/lua/
├── base/keymaps.lua     # EDIT: Telescope block → FzfLua RHS, keys+desc preserved
├── icons/lspkind.lua    # EDIT: drop Telescope icon key
├── utils/mason-install-all.lua  # EDIT: sync refresh when headless (05-01)
└── lang/markdown/plugins.lua    # EDIT: drop telescope dep on live-preview
setup.sh                 # EDIT: get_deps demote make/gcc; post-stow Mason trigger;
                         #   widened wipe + preview text
```

### Pattern 1: fzf-lua lazy spec with ui-select dressing
**What:** Single spec; lazy.nvim auto-calls `setup(opts)`; `ui_select = {}` opt-in replaces `telescope-ui-select.nvim`.
**When to use:** 05-02, new file `lua/plugins/fzf-lua.lua`.
**Example:**
```lua
-- Source: fzf-lua lua/fzf-lua/init.lua:224-234 (setup ui_select opt-in, read this session)
return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- cmd = "FzfLua",  -- [ASSUMED] lazy cmd-loading; verify at exec time, else event = "VeryLazy"
    opts = {
        ui_select = {}, -- registers fzf-lua as vim.ui.select backend (replaces telescope-ui-select)
    },
}
```

### Pattern 2: which-key v3 group-only spec
**What:** `spec` is a `wk.Spec` table processed at setup; `register()` is deprecated; group-only entries `{ "<leader>f", group = "…" }` give LazyVim-like popups while leaf hints come from keymap `desc`s.
**When to use:** 05-01, new file `lua/plugins/which-key.lua`.
**Example:**
```lua
-- Source: which-key lua/which-key/config.lua:31-33 (defaults), init.lua:36-52 (register deprecated)
-- Source: https://github.com/folke/which-key.nvim (lazy example: event VeryLazy, preset/delay/spec)
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 200,
        triggers = { { "<auto>", mode = "nxso" } }, -- TABLE form; bare "<auto>" is silently dropped
        spec = {
            { "<leader>f", group = "find" },
            { "<leader>s", group = "search/todo" },
            { "<leader>e", group = "run" },
            -- …planner finalizes per deleted/kept key audit
        },
    },
}
```

### Pattern 3: Headless-safe MasonInstallAll (sync refresh when headless)
**What:** `Registry.refresh()` with NO callback runs `run_blocking` (sync); with callback it is async. Branch on headless so the D-01 one-shot works while interactive semantics stay identical.
**When to use:** 05-01, edit `lua/utils/mason-install-all.lua` (D-03 semantics preserved: same refresh → install-missing → notify flow).
**Example:**
```lua
-- Source: mason.nvim lua/mason-registry/init.lua:205-218 (sync-without-callback vs async-with-callback)
-- Source: mason.nvim lua/mason/api/command.lua:50-58 (headless => run_blocking)
local is_headless = #vim.api.nvim_list_uis() == 0
if is_headless then
    require("mason-registry").refresh() -- blocks; no callback => run_blocking
    -- ... same collect-missing loop, then vim.cmd("MasonInstall " .. ...) blocks headless
else
    mr.refresh(function() -- ... existing async body unchanged ... end)
end
```

### Anti-Patterns to Avoid
- **Async fire-and-forget behind `-c … -c "qall"`:** any headless command that returns before async work completes (registry refresh, `sleep`-hacks) silently no-ops. Always use a documented blocking primitive.
- **Bare-string which-key triggers (`{ "<auto>" }`):** silently parsed into a modeless mapping — popup never appears, no error. Always table form.
- **Carrying `cond = executable("make")` into the new picker:** banned by D-11; fzf-lua must load unconditionally.
- **Re-adding a startup auto-install backstop:** banned by D-01; installer-trigger only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ensure-installed LSPs at startup | Custom `VimEnter` autocmd / `mason-tool-installer` spec | setup.sh headless `MasonInstallAll` (D-01) | Startup must stay fast + offline-safe; backstop rejected by locked decision |
| Fuzzy sorter for picker | Keep `telescope-fzf-native` compiled sorter | fzf-lua (fzf binary is the sorter) | Native build step is exactly what EDIT-03 eliminates; `fzf` already a core dep |
| `vim.ui.select` dressing | Custom dressing/select wrapper | `fzf-lua` `setup({ ui_select = {} })` | One flag; verified in source [VERIFIED: /tmp/opencode/research05/fzf-lua/lua/fzf-lua/init.lua:224-234] |
| Parser auto-install at setup | setup.sh `:TSInstall` loop | On-demand `:TSInstall <lang>` + docs | Needs tree-sitter-cli + compiler + network; out of EDIT-01 scope; would break offline installs |
| Terminal picker | Custom toggleterm→picker bridge | Nothing (`<leader>pt` deleted; `<C-\>` toggleterm stays) | Neither telescope nor fzf-lua ships a terminal picker; the deleted binding errored anyway |

**Key insight:** Every integration this migration needs already exists upstream as a zero-config path (`TodoFzfLua`, `:Noice pick` auto-select, live-preview `fzflua` backend, fzf-lua `ui_select`). The plans should *delete + redirect*, never build adapters.

## Complete D-09 Picker Map (researcher directive — planner implements verbatim)

All fzf-lua builtins below quoted verbatim from the provider map [VERIFIED: /tmp/opencode/research05/fzf-lua/lua/fzf-lua/init.lua:237-347]. Keys stay byte-identical; only the RHS changes. `desc` strings preserved.

| # | Current (telescope) | Key | FzfLua builtin | Notes |
|---|---------------------|-----|----------------|-------|
| 1 | `find_files` | `<leader>ff` | `files` (`files = { "fzf-lua.providers.files", "files" }`) | plain call |
| 2 | `find_files follow=true no_ignore=true hidden=true` | `<leader>fa` | `files({ hidden = true })` — lua-function RHS required (opts table); `hidden = true` is a documented files-picker flag [CITED: https://github.com/ibhagwan/fzf-lua/blob/main/README.md] | keep desc "Find all files" |
| 3 | `live_grep` | `<leader>fg` | `live_grep` (`live_grep = { "fzf-lua.providers.grep", "live_grep" }`) | needs `rg` (present 14.1.0) |
| 4 | `buffers` | `<leader>fb` | `buffers` (`buffers = { "fzf-lua.providers.buffers", "buffers" }`) | `sort_lastused` default true |
| 5 | `help_tags` | `<leader>fh` | `helptags` (`help_tags = { "fzf-lua.providers.helptags", "helptags" }` — alias exists) | use canonical `helptags` |
| 6 | `oldfiles` | `<leader>fo` | `oldfiles` (`oldfiles = { "fzf-lua.providers.oldfiles", "oldfiles" }`) | — |
| 7 | `marks` | `<leader>ma` | `marks` (`marks = { "fzf-lua.providers.nvim", "marks" }`) | — |
| 8 | `git_commits` | `<leader>cm` | `git_commits` (`git_commits = { "fzf-lua.providers.git", "commits" }`) | — |
| 9 | `git_status` | `<leader>gt` | `git_status` (`git_status = { "fzf-lua.providers.git", "status" }`) | — |
| 10 | `Telescope terms` | `<leader>pt` | DELETE, no replacement | No `terms` builtin/extension exists in telescope (verified against official builtin list [CITED: https://github.com/nvim-telescope/telescope.nvim]); `extensions_list = { "themes", "terms" }` is not a real `setup` key so both entries are dead; `:Telescope terms` errors today. Terminal path stays toggleterm `<C-\>`. fzf-lua also ships no terminal picker. |
| 11 | `current_buffer_fuzzy_find` | `<leader>f` | `blines` (`blines = { "fzf-lua.providers.buffers", "blines" }`) | Closest semantic match (fuzzy over current-buffer lines). Alternative `lgrep_curbuf` is live-grep, not fuzzy — `blines` wins. |
| 12 | `colorscheme({enable_preview=true})` | `<leader>th` + `ColorschemeWithPreview` cmd + alpha `th` button | `colorschemes` (`colorschemes = { "fzf-lua.providers.colorschemes", "colorschemes" }`) | Live-apply preview is native to the picker; keep the user command name, change its body |
| 13 | `TodoTelescope` / `TodoTelescope keywords=TODO,FIX,FIXME` | `<leader>st` / `<leader>sT` | `TodoFzfLua` / `TodoFzfLua keywords=TODO,FIX,FIXME` | 1:1: command takes identical `<args>` [VERIFIED: /tmp/opencode/research05/todo-comments.nvim/plugin/todo.vim:4 `command! -nargs=* TodoFzfLua lua require("todo-comments.fzf").todo() <args>`]. plenary stays as its search backend. |
| 14 | `Noice telescope` | `<leader>N` | `:Noice pick` | Auto-selects snacks→telescope→fzf-lua [VERIFIED: /tmp/opencode/research05/noice.nvim/lua/noice/commands.lua:67-77]; snacks picker is disabled in our config (`opts = {}` [VERIFIED: nvim/.config/nvim/lua/lang/django/plugins.lua:5-11]) and telescope will be gone ⇒ fzf-lua path, zero config. |
| 15 | nvim-tree `<c-f>` / `<c-fg>` + `view_selection` attach | `<c-f>` / `<c-fg>` | `FzfLua files({ cwd = basedir })` / `FzfLua live_grep({ cwd = basedir })` | Drop the entire `view_selection`/`attach_mappings` block: fzf-lua's default file action opens + jumps natively, and `update_focused_file` already follows focus. Keep descs. |
| 16 | alpha buttons `ff`/`r`/`k` | dashboard | `FzfLua files` / `FzfLua oldfiles` / `FzfLua keymaps` | `keymaps = { "fzf-lua.providers.nvim", "keymaps" }` replaces `Telescope keymaps`. `n`/`l`/`q` buttons untouched. |
| 17 | `live-preview.nvim → telescope.nvim` dep | `lua/lang/markdown/plugins.lua:109-115` | Drop `dependencies` block; optionally set `picker = "fzflua"` | live-preview ships a first-class `M.fzflua` backend and its default `picker = ""` never touches telescope [VERIFIED: ~/.local/share/nvim/lazy/live-preview.nvim/lua/livepreview/picker.lua:41-56, config.lua:22-30]. Dep was load-order only, and spurious. |
| 18 | lspkind `Telescope = ""` icon key | `lua/icons/lspkind.lua:44` | DELETE the key | **Researcher decision (D-08): DROP.** `ctx.kind` is always an LSP SymbolKind; the `Telescope` key is unreachable, and dropping it makes `grep -ri telescope lua/` return zero hits (D-07 verification). |

**Conflict audit (D-09 "current keys win"):** no conflicts exist. The deleted telescope keys (`ff fa fg fb fh fo ma cm gt pt f th N st sT`) are freed by the deletion itself and no frozen key claims them (nearest neighbors `fm` format, `sv`/`sh` splits, `sr` search-replace, `tc` treesitter-context, `xt`/`xT` Trouble, `lz` Lazy are all distinct sequences). New bindings therefore reuse the identical leader keys — satisfying both "prefer upstream defaults" (fzf-lua defines no global invoking keymaps, so there is nothing to collide with) and "fall back to current keys on conflict."

## Common Pitfalls

### Pitfall 1: Headless Mason trigger silently installs nothing
**What goes wrong:** `nvim --headless -c "MasonInstallAll" -c "qall"` exits 0 with zero packages installed; installer reports success; user opens nvim with no LSPs.
**Why it happens:** Our command calls `mr.refresh(callback)` — the *callback* form is async (`a.run`) [VERIFIED: /tmp/opencode/research05/mason.nvim/lua/mason-registry/init.lua:205-218]. The user command returns immediately, `qall` executes, Neovim exits before the registry refresh (network fetch) completes. Only `:MasonInstall` itself blocks headless (`registry.refresh()` sync + `run_blocking` [VERIFIED: /tmp/opencode/research05/mason.nvim/lua/mason/api/command.lua:50-58]).
**How to avoid:** Apply the Pattern-3 sync-refresh branch (headless ⇒ `refresh()` without callback, then the existing collect + `MasonInstall` which blocks). Alternative: two headless invocations (print pkg list → direct `:MasonInstall <pkgs>`).
**Warning signs:** Headless run finishes in <2s on a fresh machine (a real install takes tens of seconds); `Mason` shows packages missing afterwards.

### Pitfall 2: Bare-string which-key triggers silently disable the popup
**What goes wrong:** `triggers = { "<auto>" }` parses without error but the popup never appears on `<Space>`.
**Why it happens:** List items in a `wk.Spec` must be tables — the parser only collects `type(v) == "table"` numbered items [VERIFIED: /tmp/opencode/research05/which-key.nvim/lua/which-key/mappings.lua:166] — and the `<auto>` expansion looks for `m.lhs == "<auto>"` on parsed mappings [VERIFIED: /tmp/opencode/research05/which-key.nvim/lua/which-key/config.lua:273]. A bare string loses its mode and never registers auto-trigger modes.
**How to avoid:** Write `triggers = { { "<auto>", mode = "nxso" } }` (exactly the default [VERIFIED: config.lua:31-33]) or omit `triggers` entirely.
**Warning signs:** `:checkhealth which-key` clean but no popup; `require("which-key.config").options.triggers` shows a string item.

### Pitfall 3: Dead treesitter keys + nonexistent `TSInstallAll` build
**What goes wrong:** Fresh lazy install runs `build = ":TSUpdate | TSInstallAll"` → `E492: Not an editor command: TSInstallAll`; `ensure_installed`/`auto_install` silently do nothing, so no parsers ever auto-install despite the config suggesting otherwise.
**Why it happens:** Pinned `nvim-treesitter` is the `main`-branch rewrite: `setup()` deep-merges any keys but only `install_dir` is read [VERIFIED: ~/.local/share/nvim/lazy/nvim-treesitter/lua/nvim-treesitter/config.lua:15-23]; `ensure_installed`/`auto_install`/`TSInstallAll` have zero references; the only commands are `TSInstall/TSInstallFromGrammar/TSUpdate/TSUninstall/TSLog` [VERIFIED: plugin/nvim-treesitter.lua:29-71].
**How to avoid:** 05-02 rewrites `treesitter.lua` to the minimal main-branch spec (`branch="main"`, `build=":TSUpdate"`, no dead opts) with a comment pointing at on-demand `:TSInstall <lang>`. Do NOT re-add auto-install.
**Warning signs:** `:TSUpdate` errors on fresh clone; parsers never appear in `stdpath("data")/site/parser/`.

### Pitfall 4: Dead LuaSnip `run=` key (jsregexp never built — and that's currently fine)
**What goes wrong:** Planner "fixes" demotion by deleting the jsregexp line, or assumes jsregexp is present.
**Why it happens:** lazy.nvim only honors `build`, never `run` (zero `run`-key references in lazy core spec handling; `build` honored [VERIFIED: ~/.local/share/nvim/lazy/lazy.nvim/lua/lazy/core/plugin.lua:288-289, manage/task/plugin.lua:42-54]) — so `run = "make install_jsregexp"` [VERIFIED: nvim/.config/nvim/lua/plugins/blink-cmp.lua:7] never executed. jsregexp is officially optional ("install jsregexp (optional!)" [CITED: https://github.com/L3MON4D3/LuaSnip]); without it ecma-regex triggers degrade to `plain` and snippet transforms become copy [CITED: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md].
**How to avoid:** Replace with function-form `build` that runs `make install_jsregexp` only when `vim.fn.executable("make") == 1`, silently skipping otherwise (LazyVim precedent uses an echo-guard [CITED: https://raw.githubusercontent.com/LazyVim/LazyVim/main/lua/lazyvim/plugins/extras/coding/luasnip.lua]). blink.cmp's own fuzzy engine is unaffected — it downloads a prebuilt Rust binary (needs only curl + network), already pinned via `prebuilt_binaries.force_version`.
**Warning signs:** `:checkhealth luasnip` reporting jsregexp state change; snippet transforms behaving differently between machines (expected: identical-without-jsregexp everywhere now).

### Pitfall 5: D-11 "checkhealth reports picker healthy" has no `:checkhealth fzf-lua`
**What goes wrong:** Plan gates on `checkhealth` showing an fzf-lua section that can never appear.
**Why it happens:** fzf-lua ships no `health.lua` (verified absent in the cloned repo) — it relies on the `fzf` binary + `setup()` succeeding. `:checkhealth` still must be zero-errors overall (which-key, mason, treesitter sections), but picker health needs its own probe.
**How to avoid:** Gate the picker with a headless smoke instead: `nvim --headless -c "lua assert(pcall(require,'fzf-lua')); print('fzf-lua ok')" -c "qall"` plus `command -v fzf`. Phase 6 absorbs this into TAP (D-12).
**Warning signs:** `checkhealth` green but `<leader>ff` errors (e.g. `fzf` binary missing on a new family).

### Pitfall 6: Forgetting `lazy-lock.json` churn
**What goes wrong:** `telescope*` pins linger (reinstall risk) or new `fzf-lua`/`which-key` pins are never committed (unreproducible installs).
**Why it happens:** Lockfile updates only materialize after a real `:Lazy` sync, and plenary's pin must survive.
**How to avoid:** Executor runs headless `:Lazy! sync` (or interactive sync) after the spec edits, then commits the lockfile diff in the same commit (atomic-docs rule); verify `grep -c telescope lazy-lock.json` == 0 and plenary pin present.

## Code Examples

Verified patterns from official sources:

### which-key v3 lazy spec (group-only)
```lua
-- Source: https://github.com/folke/which-key.nvim (lazy example) + config.lua defaults read this session
{
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 200,
        triggers = { { "<auto>", mode = "nxso" } },
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
```

### fzf-lua keymap RHS (lua-function form — required where opts are passed)
```lua
-- Source: https://github.com/ibhagwan/fzf-lua/blob/main/README.md (`:FzfLua files`, lua FzfLua.files())
local map = vim.keymap.set
map("n", "<leader>ff", function() require("fzf-lua").files() end, { desc = "Find files" })
map("n", "<leader>fa", function() require("fzf-lua").files({ hidden = true }) end, { desc = "Find all files" })
map("n", "<leader>fg", function() require("fzf-lua").live_grep() end, { desc = "Grep through files" })
map("n", "<leader>f", function() require("fzf-lua").blines() end, { desc = "Fuzzy search current buffer", noremap = true })
map("n", "<leader>th", function() require("fzf-lua").colorschemes() end, { desc = "Choose colorscheme with preview" })
map("n", "<leader>st", "<cmd>TodoFzfLua<cr>", { desc = "Todo" })
map("n", "<leader>sT", "<cmd>TodoFzfLua keywords=TODO,FIX,FIXME<cr>", { desc = "Todo/Fix/Fixme" })
map("n", "<leader>N", "<cmd>Noice pick<CR>", { noremap = true, desc = "Noice history" })
```

### setup.sh headless Mason trigger shape (planner owns wording; invariants fixed)
```bash
# Slot: setup.sh main flow between post_verify and ensure_local_files [VERIFIED: setup.sh:2043-2045]
# Invariants: DRY_RUN early-return + `[DRY RUN] Would run:` preview; gate on nvim selected
# AND command -v nvim; NEVER fail the install (D-02) — set -e safe form:
if printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim && command -v nvim >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == true ]]; then
        echo '[DRY RUN] Would run: nvim --headless -c "MasonInstallAll" -c "qall"'
    elif ! nvim --headless -c "MasonInstallAll" -c "qall"; then
        echo "Warning: headless Mason install failed — retry with: nvim --headless -c \"MasonInstallAll\" (or :MasonInstallAll inside nvim)" >&2
    fi
fi
```

### D-12 Mason-list verification one-liner (headless, for plan verification steps)
```bash
# Compares Mason-installed packages against the lang aggregator (single source of truth):
nvim --headless -c 'lua local want = require("lang").mason_packages; local reg = require("mason-registry"); local missing = {}; for _, p in ipairs(want) do if reg.has_package(p) and not reg.get_package(p):is_installed() then missing[#missing+1] = p end end; print(#missing == 0 and ("MASON-OK: " .. #want .. " packages") or ("MASON-MISSING: " .. table.concat(missing, ", "))); vim.cmd("qall")'
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| telescope.nvim + `telescope-fzf-native` (needs `make`+compiler) | `ibhagwan/fzf-lua` (fzf binary is the sorter) | EDIT-03 / this phase | Picker path needs no build toolchain at all |
| which-key v2 `require("which-key").register()` | v3 `spec` table in `setup(opts)` / `add()` | which-key v3 rewrite (`register()` now `---@deprecated` [VERIFIED: init.lua:36-45]) | Group-only spec; old `register` shape warns |
| nvim-treesitter `master` (`configs.setup`, `ensure_installed`, `auto_install`) | `main` rewrite (`setup{install_dir}`, `:TSInstall`, no lazy-load support) | Upstream rewrite 2025 (master locked for Nvim 0.11 compat) [CITED: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md] | Current spec keys are dead; `build` string must drop `TSInstallAll` |
| `williamboman/mason.nvim` | `mason-org/mason.nvim` (v2) | Upstream org rename | Already reflected in `mason.lua` spec — no action |
| `:Noice telescope` + telescope extension | `:Noice pick` (auto-selects fzf-lua) | Noice picker abstraction (telescope→fzf-lua fallback chain in `commands.lua`) | Zero-config migration |
| `:TodoTelescope` only | `:TodoFzfLua` added (#312, Aug 2024) [CITED: https://github.com/folke/todo-comments.nvim] | todo-comments fzf support | 1:1 binding swap |

**Deprecated/outdated:**
- `telescope-ui-select.nvim`: replaced by fzf-lua `setup({ ui_select = {} })` — no separate plugin.
- `extensions_list = { "themes", "terms" }` in the deleted spec: never a real telescope key; dies with the file.
- `run = "make install_jsregexp"` (packer key): dead under lazy.nvim; replaced by guarded function-form `build`.

## Assumptions Log

> Claims tagged `[ASSUMED]` — planner/discuss-phase must confirm before locking.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `cmd = "FzfLua"` enables lazy cmd-loading for the fzf-lua spec (fallback: `event = "VeryLazy"` + keys) | Patterns | Minor: plugin loads eagerly instead of on-command; executor verifies with `:Lazy profile` or headless smoke |
| A2 | Debian `fzf 0.44.1` satisfies fzf-lua (no newer-CLI flags required for files/grep/buffers flows) | Env Availability | Low: headless smoke (Pitfall 5 probe) catches it; fallback is documenting a newer-fzf note |
| A3 | `:TSUpdate` with zero args is a safe noop when no parsers are installed (fresh-machine `build`) | Pitfalls | Low-medium: fresh-install build error noise; executor runs it headless once to confirm |
| A4 | blink.cmp falls back gracefully when the prebuilt fuzzy binary can't download (offline first boot) | Env Availability | Low: completion degrades, editor works; executor checks `:checkhealth blink.cmp` offline note |
| A5 | No other config references `telescope-ui-select` behavior (e.g. code-action dressing) beyond `vim.ui.select` | Picker Map | Low: `ui_select = {}` covers all `vim.ui.select` callers generically |
| A6 | `~/.local/share/nvim` contains nothing user-irreplaceable on any supported family (D-04 wipe) | Security | Medium: mitigated by typed-`yes` gate + dry-run preview; executor lists dir contents pre-wipe in verification |

## Open Questions

1. **tree-sitter-cli version floor on target families**
   - What we know: main-branch health requires CLI ≥ 0.26.1 [CITED: nvim-treesitter README]; this machine has 0.20.8 (too old — `:TSInstall` will fail here until CLI is upgraded).
   - What's unclear: which CLI version Arch/Debian repos currently ship (whether on-demand `:TSInstall` works out-of-box for users).
   - Recommendation: 05-02 verification runs `:checkhealth nvim-treesitter` headless and records the result; do NOT add CLI to installer deps in this phase (scope guard) — document `:TSInstall` as on-demand with the CLI+compiler prerequisite.

2. **clang-as-alternative installer wording**
   - What we know: Termux proves the editor works with clang-only; `tree-sitter build` uses `cc` under the hood (respects `CC` env, auto-detects cc/gcc/clang).
   - What's unclear: exact warn-if-missing wording across three families (planner's call per discretion).
   - Recommendation: warn names the accepted set (`cc/gcc/clang`) and the two degraded features (parser builds, jsregexp build), never aborts.

3. **snacks.nvim picker staying disabled**
   - What we know: `:Noice pick` prefers an enabled Snacks picker over fzf-lua; django dep declares snacks with `opts = {}` (disabled).
   - What's unclear: whether any future spec enables the Snacks picker and silently reroutes `:Noice pick`.
   - Recommendation: no action; noted so a future snacks change doesn't surprise. (Not a Phase-5 task.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `nvim` | everything editor | ✓ | 0.12.2 (satisfies treesitter-main ≥0.12) | — (hard requirement, unchanged) |
| `fzf` | fzf-lua sorter/CLI | ✓ | 0.44.1 (debian) | — (already core dep; see A2) |
| `rg` | `live_grep`, `TodoFzfLua` search | ✓ | 14.1.0 | — (already core dep) |
| `fd` | fzf-lua files fast path | ✗ | — | `rg --files` / `find` auto-fallback (non-blocking) |
| `git` | `git_status`/`git_commits`, lazy bootstrap | ✓ | 2.43.0 | — |
| `node`/`npm` | Mason LSP servers (tsserver etc.) | ✓ | v22.22.3 / 10.9.8 | — |
| `make` / `gcc` / `cc` | jsregexp build (optional), parser builds (on-demand) | ✓/✓/✓ locally | present | Demoted to optional per D-10; absent ⇒ warn, skip builds, editor works |
| `clang` | accepted compiler alternative | ✗ (this machine) | — | `gcc` present here; Termux provides `clang` (D-10 evidence) |
| `tree-sitter` CLI | on-demand `:TSInstall` only | ⚠️ present but 0.20.8 < required 0.26.1 | 0.20.8 | Parser (re)install fails until CLI upgraded; editor unaffected (Open Q1) |
| `bat` / `delta` | fzf-lua preview pager | ✗ | — | Builtin buffer previewer (default; non-blocking) |
| Mason registry network | headless `MasonInstallAll` | ✓ (clones succeeded this session) | — | D-02 warn-and-continue + retry command |
| `stow` | deploy (unchanged) | ✓ | 2.3.1 | — (out of scope) |

**Missing dependencies with no fallback:** none for Phase-5 scope (all hard requirements already satisfied).
**Missing dependencies with fallback:** `fd`, `bat`/`delta` (cosmetic); `tree-sitter` CLI too old (only affects on-demand parser builds, not the phase's success criteria).

## Security Domain

> `security_enforcement: true`, ASVS L1. No auth/session/crypto in scope; applicable categories below.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (local dotfiles, no auth surface) |
| V3 Session Management | no | — |
| V4 Access Control | partial | Privileged `/etc/keyd` path untouched; widened wipe gated by existing typed-`yes` (no `--yes` bypass change per D-04) |
| V5 Input Validation | yes | Wipe path is a fixed literal `$HOME/.local/share/nvim` (no user-input interpolation → no traversal); Mason package names come from the trusted `lang` aggregator, filtered by `mr.has_package` with warn-and-skip (prevents headless `1cq` abort on typos); `setup.sh` keeps `set -Eeuo pipefail` + `${1-}` guards |
| V6 Cryptography | no | — (no new secrets; Mason/lazy fetch over HTTPS by default) |

### Known Threat Patterns for Bash-installer + lazy.nvim/Mason stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Over-broad `rm -rf` in uninstall (D-04 widening) | Tampering / Denial of service | Fixed literal path under `$HOME`, typed-`yes` gate, `[DRY RUN]` preview text updated to the new path; executor lists dir pre-wipe (A6) |
| Supply-chain via new plugin specs | Tampering | Both specs are high-reputation upstreams, cloned OK this session; pins committed to `lazy-lock.json` (reproducible, reviewable diff) |
| Headless install failure masked as success | Repudiation | Pitfall-1 fix (blocking refresh) + D-02 warning with exact retry command; D-12 Mason-list check as plan gate |

## Sources

### Primary (tool-verified against authoritative sources — HIGH confidence)
- `ibhagwan/fzf-lua` repo (cloned 2026-10-03): `lua/fzf-lua/init.lua:224-234` (ui_select opt-in), `:237-347` (provider map), `lua/fzf-lua/config.lua:240-245` (fzf_bin fallback); no `health.lua` (verified absent)
- `folke/which-key.nvim` repo (cloned 2026-10-03, v3.17.0): `lua/which-key/config.lua:4,10-33,213-277` (version, defaults, triggers parsing), `lua/which-key/init.lua:26-52` (setup/add, register deprecated), `lua/which-key/mappings.lua:150-193` (table-only spec items)
- `mason-org/mason.nvim` repo (cloned 2026-10-03): `lua/mason/api/command.lua:50-58` (headless run_blocking), `lua/mason-registry/init.lua:205-218` (sync/async refresh), `lua/mason-core/platform.lua:38` (`is_headless` def)
- `folke/todo-comments.nvim` (cloned 2026-10-03): `plugin/todo.vim:4` (TodoFzfLua 1:1)
- `folke/noice.nvim` (cloned 2026-10-03): `lua/noice/commands.lua:67-77` (pick fallback chain)
- Local installs (`~/.local/share/nvim/lazy/`): nvim-treesitter `config.lua:15-23` + `plugin/nvim-treesitter.lua:29-71` (dead keys, command set); live-preview `picker.lua:41-56` + `config.lua:22-30` (fzflua backend, default picker ""); lazy.nvim `core/plugin.lua:288-289` + `manage/task/plugin.lua:42-54` (`build` honored, no `run` key)
- In-repo reads: `setup.sh` (ALL_TOOLCHAIN:24, get_deps common:194-203, verify_deps:268-280, Mason preview:878-887, cleanup:938-946, main flow:2042-2048); `nvim/.config/nvim/lua/{utils/mason-install-all.lua,plugins/{mason,telescope,nvim-tree,alpha,to-do,blink-cmp,treesitter,noice,toggleterm}.lua,base/keymaps.lua,icons/lspkind.lua,lang/{init,settings,markdown/plugins},lang/django/plugins.lua}`

### Secondary (MEDIUM confidence)
- ctx7 `/ibhagwan/fzf-lua` (840 snippets, High reputation): setup/keymap/files/oldfiles/bcommits docs
- ctx7 `/folke/which-key.nvim` (109 snippets, benchmark 95.18): lazy spec, setup APIDOC
- Official mason docs [https://github.com/mason-org/mason.nvim/blob/main/doc/mason.txt] (headless blocking)
- Official telescope README (builtin picker list — confirms no `terms`)
- nvim-treesitter main README (rewrite notice, CLI ≥0.26.1 requirement)
- LuaSnip README + DOC.md (optional jsregexp, degradation semantics); LazyVim luasnip extra (echo-guard build precedent)
- Noice docs (telescope/fzf-lua picker sections); todo-comments README (TodoFzfLua); Trouble README (fzf-lua `ctrl-t` action — available future wiring, not Phase 5)

### Tertiary (LOW confidence)
- WebSearch-only details folded into [ASSUMED] items (A1–A6); none load-bearing.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — both plugins cloned + APIs read line-verified; versions observed in source
- Architecture: HIGH — insertion slots and call chains verified in `setup.sh` + lua sources
- Pitfalls: HIGH — each root-caused to exact source lines, not inferred from docs
- Treesitter/CLI cross-family behavior: MEDIUM — main-branch mechanism verified, distro repo CLI versions not probed (Open Q1)

**Research date:** 2026-10-03
**Valid until:** ~30 days (stable domain; upstream `main` pins move but lazy-lock absorbs drift). Re-check `M.version`/provider map only if lockfile refresh pulls new fzf-lua/which-key commits with breaking changes.
