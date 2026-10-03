---
phase: 05-editor-autonomy-fzf-lua-migration
reviewed: 2026-10-03T15:55:53Z
depth: deep
files_reviewed: 13
files_reviewed_list:
  - setup.sh
  - nvim/.config/nvim/lua/utils/mason-install-all.lua
  - nvim/.config/nvim/lua/plugins/which-key.lua
  - nvim/.config/nvim/lua/plugins/fzf-lua.lua
  - nvim/.config/nvim/lua/plugins/telescope.lua
  - nvim/.config/nvim/lua/base/keymaps.lua
  - nvim/.config/nvim/lua/plugins/nvim-tree.lua
  - nvim/.config/nvim/lua/plugins/alpha.lua
  - nvim/.config/nvim/lua/plugins/blink-cmp.lua
  - nvim/.config/nvim/lua/plugins/treesitter.lua
  - nvim/.config/nvim/lua/icons/lspkind.lua
  - nvim/.config/nvim/lua/lang/markdown/plugins.lua
  - README.md
findings:
  critical: 0
  warning: 8
  info: 7
  total: 15
status: issues_found
---

# Phase 05: Code Review Report — Editor Autonomy + fzf-lua Migration

**Reviewed:** 2026-10-03T15:55:53Z
**Depth:** deep (per-file review plus cross-file tracing into
`mason-registry`, `mason` headless command path, `lazy.nvim` build-task
semantics, `fzf-lua`/`todo-comments`/`noice` provider sources, and live
headless probes)
**Files Reviewed:** 13
**Status:** issues_found — **advisory only, non-blocking** per phase
instructions. No finding below should gate Phase 06.

## Summary

Intent (from `05-01-PLAN.md` / `05-02-PLAN.md` plus both SUMMARYs) was
reviewed first: headless blocking `MasonInstallAll` with a setup.sh
post-stow trigger, which-key v3 group-only spec, widened uninstall wipe,
full picker migration to fzf-lua with zero legacy references, and
make/gcc demotion to warn-only with compiler-free blink/treesitter
configs.

The migration is structurally sound: zero `telescope` references remain
in `nvim/` code, lockfile churn is correct on disk (fzf-lua + which-key
in, 3 legacy pins out, plenary kept), all 11 fzf-lua builtins referenced
by keymaps were proven to exist via headless probe, the which-key v3
spec shape matches the upstream default exactly, and the headless
`mr.refresh()` sync claim checks out against the mason-registry source
(`refresh` with no callback goes through `a.run_blocking`). Installer
safety primitives are intact: `set -Eeuo pipefail` + `inherit_errexit`
header, negated `if ! nvim ...` guard so the Mason trigger can never
abort the install, quoted fixed-literal `rm -rf`, and the typed-yes gate
still precedes the widened wipe.

The 8 warnings are all real but narrow: one silently-dropped picker
filter, one never-executing build, two lazy-loading/nil edge cases on
picker keys, three installer UX/noise issues around the optional
toolchain, and one docs-vs-behavior gap on wipe scope. None corrupts
data silently except WR-07 (bounded, gated, previewed undo-history
loss), and none is flagged BLOCKER per the advisory-only instruction.

## Warnings

### WR-01: `TodoFzfLua keywords=...` filter is silently discarded

**File:** `nvim/.config/nvim/lua/base/keymaps.lua:165`
**Issue:** The `<leader>sT` binding assumes `TodoFzfLua` accepts
Telescope-style `keywords=TODO,FIX,FIXME` args. Upstream defines the
command as `command! -nargs=* TodoFzfLua lua
require("todo-comments.fzf").todo() <args>` (todo-comments
`plugin/todo.vim`), i.e. the args are appended *after* the closed
`todo()` call. Lua parses `todo() keywords=TODO,FIX,FIXME` as a call
followed by global assignments (`keywords`, `TODO`, `FIX`, `FIXME`),
so the chunk compiles and runs — but `todo()` receives `nil` opts and
shows **all** keywords. Verified: plain and filtered invocations behave
identically, and stray globals are set. This is a functional regression
versus the old `TodoTelescope keywords=...` form, where the Telescope
ex-command parsed args properly.
**Fix:**
```lua
map("n", "<leader>sT", function()
    require("todo-comments.fzf").todo({ keywords = { "TODO", "FIX", "FIXME" } })
end, { desc = "Todo/Fix/Fixme" })
```
(Confirm `todo()` honors `opts.keywords` — its `keywords_filter`
reads `opts.keywords`, per `todo-comments/lua/todo-comments/fzf.lua`.)

### WR-02: Guarded LuaSnip `build` function never builds anything

**File:** `nvim/.config/nvim/lua/plugins/blink-cmp.lua:10-14`
**Issue:** `build` as a function is invoked by lazy.nvim as
`build(self.plugin)` with the return value **discarded**
(`lazy/manage/task/plugin.lua:67-68`). Returning `"make
install_jsregexp"` from the function is a no-op string — jsregexp is
never compiled even on hosts where `make` exists, so the plan's D-10
intent ("hosts with a compiler build jsregexp") is not achieved. No
regression versus the old dead packer `run =` key (also ignored by
lazy), but the new code reads as if the compiler path works when it
cannot.
**Fix:**
```lua
build = vim.fn.executable("make") == 1 and "make install_jsregexp" or nil,
```

### WR-03: Global `<c-f>` / `<c-fg>` crash when cursor is not on a tree node

**File:** `nvim/.config/nvim/lua/plugins/nvim-tree.lua:65-69`
**Issue:** `basedir_from_node()` indexes `node.type` unconditionally,
but `api.tree.get_node_under_cursor()` returns `nil` whenever the tree
is not focused — and these keymaps are registered globally via
`vim.keymap.set("n", ...)`, not buffer-local to the tree. Pressing
`<c-f>` in any normal buffer errors (`attempt to index nil`) instead of
opening the picker. (Same shape existed pre-migration; the rewrite kept
the hazard while making the bindings the only file/grep entry from the
tree.)
**Fix:**
```lua
local function basedir_from_node()
    local node = api.tree.get_node_under_cursor()
    if node == nil or node.absolute_path == nil then
        return vim.fn.getcwd()
    end
    return node.type == "directory" and node.absolute_path
        or vim.fn.fnamemodify(node.absolute_path, ":h")
end
```

### WR-04: Lua-function picker bindings bypass lazy `cmd` loading

**File:** `nvim/.config/nvim/lua/base/keymaps.lua:44-46,54-59`,
`nvim/.config/nvim/lua/plugins/nvim-tree.lua:72-78`,
`nvim/.config/nvim/lua/plugins/alpha.lua:20-22`
**Issue:** The fzf-lua spec loads only on `cmd = "FzfLua"`. Bindings
using `<cmd>FzfLua ...>` self-trigger loading, but every
`require("fzf-lua")` call site (`<leader>fa`, `<leader>f`,
`<leader>th`, nvim-tree `<c-f>`/`<c-fg>`, `ColorschemeWithPreview`)
does not — lazy.nvim does not intercept `require` for unloaded plugins.
If the user's first-ever picker invocation goes through one of these
bindings before the plugin has loaded, it fails with module-not-found.
Narrow window (any `<cmd>FzfLua>` binding loads it permanently after),
but the plan's A1 proof only covered `:FzfLua` invocation, never the
`require` path.
**Fix (either):** add `keys` to the fzf-lua spec so lazy loads on those
keys, e.g. `keys = { "<leader>ff", "<leader>fa", "<leader>f" }`, or
rewrite the lua-function RHS bindings to `<cmd>FzfLua ...>` form.

### WR-05: Optional-toolchain probe false-positives on clang-only hosts and warns when unselected

**File:** `setup.sh:276-296,1987`
**Issue:** Two gaps: (1) `_is_optional_dep` / `warn_optional_toolchain`
probe only the `make`/`gcc` binaries, yet the warning text names
`cc/gcc/clang` as the accepted set — a Termux clang-only host (the exact
case D-10/T-05-07 cares about) still gets a `gcc missing` warning even
though a sufficient compiler exists. (2) `warn_optional_toolchain`
runs unconditionally in `main`, independent of mode/selection, so users
who never selected compiler-adjacent work still see the warning.
Harmless (exit 0 always) but noisy and misleading.
**Fix:**
```bash
_have_compiler() { command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1; }
```
and skip per-tool warnings when `_have_compiler` succeeds; optionally
gate the probe on nvim-selected or toolchain-selected state.

### WR-06: Ticked make/gcc checklist rows silently install nothing

**File:** `setup.sh:24,246-267`
**Issue:** `make`/`gcc` remain in `ALL_TOOLCHAIN` so they are still
offered in the gum/whiptail checklist, but `get_deps` no longer emits
them and `filter_deps_by_selection` only filters `get_deps` output —
ticked optionals are silently dropped and `install_deps` never sees
them. A user ticking `gcc` reasonably expects it installed; instead
nothing happens and only the README documents the advisory semantic.
Acknowledged in 05-02-SUMMARY, but the UI still implies install-on-tick.
**Fix:** Either remove the two rows from the checklist display, mark
them `(advisory — tick does nothing)` in the row labels, or wire
selection through to installing a family-appropriate compiler
(`gcc` / `build-essential` / `clang`).

### WR-07: Widened wipe scope exceeds the README "regenerable" claim

**File:** `setup.sh:977-980`, `nvim/.config/nvim/lua/base/options.lua:52`
**Issue:** The wipe now removes all of `~/.local/share/nvim`, but the
config sets `undofile = true` with the default `undodir`, meaning
persistent undo history (plus shada marks/registers, `session/`,
`site/`) lives under that tree. The README describes the target as
"regenerable lazy checkouts, Mason binaries, site data — reinstall
restores everything," which omits that undo history and shada state are
destroyed and not restorable by reinstall. Gating is correct
(nvim-deselected + typed-yes/`--yes` + dry-run preview + `-d` check),
so this is a disclosure gap, not a safety-mechanism failure.
**Fix:** Extend the README bullet and the pre-wipe echo to name undo
history/shada as destroyed state, e.g. `Removing Neovim data dir:
~/.local/share/nvim (plugins, Mason, undo history, shada — reinstall
restores plugins only)`.

### WR-08: Duplicated collect-missing/install block in mason-install-all

**File:** `nvim/.config/nvim/lua/utils/mason-install-all.lua:17-40,44-67`
**Issue:** The headless sync branch duplicates the interactive
`mr.refresh(callback)` body line-for-line (~24 lines: package loop,
`has_package` guard, `is_installed` check, `MasonInstall` + notifies).
Any future change to package selection or messaging must be made twice;
divergence produces headless-vs-interactive install skew that is hard to
catch (headless path only runs in CI/fresh-install contexts).
**Fix:** Extract a local `install_missing()` helper called from both
branches (headless calls it after sync `mr.refresh()`; interactive
calls it inside the callback).

## Info

### IN-01: Unreachable `DRY_RUN` branch in the live Mason trigger

**File:** `setup.sh:2092-2093`
**Issue:** The `if [[ "$DRY_RUN" == true ]]` echo inside the post-stow
trigger can never execute via `main`, which returns early under
`--dry-run` (~line 2026) before reaching the live path — the working
preview comes from the separate echo at line 2065 (correctly added per
05-01-SUMMARY deviation #1). Dead duplicate; harmless but misleading to
future readers reasoning about dry-run coverage.
**Fix:** Delete the inner `DRY_RUN` branch and leave the preview-section
echo as the single marker source, with a comment pointing at it.

### IN-02: Treesitter `opts` carry config the main branch ignores

**File:** `nvim/.config/nvim/lua/plugins/treesitter.lua:22-33`
**Issue:** `parsers` is computed (including a `require("lang")` and an
in-place `vim.list_extend` on `base_parsers`) but never consumed — the
returned table contains only `incremental_selection`, which main-branch
`setup()` also ignores (it reads only `install_dir`, per
`nvim-treesitter/lua/nvim-treesitter/config.lua`). Net effect is correct
(no bogus keys passed that error), but the file implies incremental
selection and a curated parser set are active when neither is. (The
`auto_install`/`ensure_installed` removal itself was correct — those
keys were equally dead on main and `TSInstallAll` never existed.)
**Fix:** Drop the `parsers` computation and either remove the
`incremental_selection` table or comment it as aspirational/dead on the
main branch.

### IN-03: Orphan `telescope_history` left in the data dir

**File:** `~/.local/share/nvim/telescope_history` (runtime artifact)
**Issue:** The picker swap orphans this file; only the widened
nvim-deselected uninstall wipe removes it. Normal daily use never
cleans it. Trivial clutter, already noted in 05-02-SUMMARY A6 for Phase
6 — recorded here for completeness.
**Fix:** One-time `rm -f ~/.local/share/nvim/telescope_history`
(or fold into Phase 6 self-test scope as suggested).

### IN-04: which-key group spec covers a subset of leader prefixes

**File:** `nvim/.config/nvim/lua/plugins/which-key.lua:13-22`
**Issue:** Groups exist for `f s e m t x g c` but keymaps also use
`<leader>q` (session), `<leader>l` (`lz` lazy, `lp` live-preview),
`<leader>n`/`<leader>N` (noice), `<leader>d` (`dq`), and `<leader>/`.
Those leaders render without a group label. Cosmetic only — spec shape
itself is valid v3.
**Fix:** Add `{ "<leader>q", group = "session" }`, `{ "<leader>l",
group = "lazy/preview" }`, `{ "<leader>n", group = "notifications" }`,
`{ "<leader>d", group = "diffview" }` (or deliberately leave ungrouped
with a comment).

### IN-05: Optional-toolchain notices split across stdout/stderr

**File:** `setup.sh:280-296`
**Issue:** `warn_optional_dep` writes to stderr while the
`+ make (installed, optional)` acknowledgement writes to stdout, so
piped/grepped installer output can interleave inconsistently. Cosmetic.
**Fix:** Send both to stderr (installer chatter convention in this
file), or both to stdout.

### IN-06: Lockfile-pin reproducibility weaker than threat model implies

**File:** `nvim/.config/nvim/lazy-lock.json` (gitignored), `setup.sh`,
`README.md`
**Issue:** T-05-02/T-05-05 mitigation leans on committed pins, but
`lazy-lock.json` is gitignored per project convention (correctly
honored — no force-add, per both SUMMARYs), so fresh clones resolve
`fzf-lua`/`which-key` to latest-main, not the verified commits. Accepted
and documented in-plan; recorded so Phase 6 gates read pin state from
disk, never from git history.
**Fix:** None required; optionally document in README that editor pins
float on fresh clone by design.

### IN-07: Upstream `TodoTelescope` command now dangles

**File:** (upstream) `todo-comments.nvim/plugin/todo.vim`
**Issue:** `TodoTelescope` still registers `Telescope todo-comments
todo`, which errors since Telescope is uninstalled. Only reachable by
manually typing `:TodoTelescope`; no in-repo caller remains (verified
zero hits). Harmless but worth knowing.
**Fix:** None in-repo (upstream file); optionally note in README
troubleshooting, or shadow with a user command that redirects to
`TodoFzfLua`.

## Verified OK (no finding)

- **Headless sync-refresh correctness:** `mr.refresh()` with no
  callback runs `pcall(a.run_blocking, update, sources)`
  (mason-registry `init.lua:205-213`); headless `MasonInstall`
  independently re-refreshes and `run_blocking`-waits on installs with
  `1cq` failure propagation (`mason/api/command.lua:30-105`), which the
  setup.sh `elif ! nvim ...` guard converts into warn-and-continue.
  The double refresh is redundant but harmless (second is cache-short-
  circuited).
- **fzf-lua builtin names:** headless probe confirmed all 11 used
  builtins exist as functions: `files live_grep buffers helptags
  oldfiles marks git_commits git_status blines colorschemes keymaps`.
  `helptags` (not Telescope's `help_tags`) is the correct migrated
  name; `Noice pick` correctly falls through Snacks-disabled →
  telescope-absent → fzf-lua integration (`noice/commands.lua:68-76`).
- **which-key v3 shape:** `preset = "modern"`, numeric `delay = 200`,
  `triggers = { { "<auto>", mode = "nxso" } }` byte-matches the upstream
  default; `spec` group-only entries with zero `register()` calls are
  valid v3.
- **Dead legacy references:** case-insensitive `telescope` search over
  `nvim/` lua, `setup.sh`, and `README.md` returns zero hits; lockfile
  holds zero legacy pins with `plenary` kept; `telescope.lua` deleted
  via `git rm`.
- **Treesitter/blink compiler-free behavior:** `build = ":TSUpdate"`
  routes through lazy's `:`-command builder (no more `TSInstallAll`
  E492 on fresh sync); blink `force_version` prebuilt pin untouched;
  `verify_deps`/`reverify_deps` can no longer see make/gcc so no family
  (including Termux) aborts on their absence.
- **Installer safety:** strict-mode header intact (`set -Eeuo
  pipefail`, `inherit_errexit`); `rm -rf "$HOME/.local/share/nvim"` is
  a quoted fixed literal (symlink-safe: no trailing slash), gated by
  `-d` check + nvim-deselected test + typed-yes/`--yes` gate, with
  matching dry-run preview; `--dry-run` performs zero writes
  (`install_deps`, `warn_optional_toolchain`, Mason preview all
  echo-only).
- **Security scan:** no hardcoded secrets, no `eval`, no dynamic
  shell/`vim.cmd` construction from user input (`MasonInstall`
  concatenation sources package names from the static `lang`
  aggregator only), no new network/auth/file-access surface beyond the
  plan's threat register.

---

_Reviewed: 2026-10-03T15:55:53Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
_Advisory only — no finding blocks Phase 06._
