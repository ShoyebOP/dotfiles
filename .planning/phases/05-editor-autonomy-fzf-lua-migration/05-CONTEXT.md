# Phase 5: Editor Autonomy & fzf-lua Migration - Context

**Gathered:** 2026-10-01
**Status:** Ready for planning

## Phase Boundary

Neovim works out-of-box after `bash setup.sh` with auto-installed LSPs, discoverable leader keys, and an `ibhagwan/fzf-lua` picker with no compiled telescope dependency. Covers REQUIREMENTS.md EDIT-01 (Mason auto-install/cleanup), EDIT-02 (which-key popup), EDIT-03 (fzf-lua replaces telescope, make/gcc leave the picker path). Depends on Phase 4 (complete). **Explicitly out of scope:** HLTH-01 `--self-test` TAP harness (owned by Phase 6); `mason-tool-installer` plugin (decided against, see D-01); any Nushell work (PROJECT.md scope filter); any shell/zsh/stow changes (Phases 1–4 locked, do not regress).

## Implementation Decisions

### Mason auto-install mechanism (EDIT-01)

- **D-01:** Installer trigger ONLY — `setup.sh` runs headless `nvim --headless -c "MasonInstallAll"` post-stow. NO `mason-tool-installer` plugin is added; the editor gains no startup auto-install path. Rationale: single explicit install moment keeps startup fast and offline-safe; ROADMAP's deferred backstop layer was discussed and rejected. — **Reversibility:** reversible — remove the setup.sh call; editor behavior unchanged.
- **D-02:** Headless Mason failure = warn and continue, never fail the install. On failure `setup.sh` prints a warning plus the exact retry command (`nvim --headless -c "MasonInstallAll"` or interactive `:MasonInstallAll`) and continues; missing LSPs degrade until the user retries. — **Reversibility:** reversible — exit-code policy is a local edit.
- **D-03:** `:MasonInstallAll` (`nvim/.config/nvim/lua/utils/mason-install-all.lua`) stays as the manual repair path with unchanged semantics (refresh registry → install missing → notify). The existing `build = ":MasonInstallAll"` hook in `lua/plugins/mason.lua` is preserved.
- **D-04:** Uninstall wipe WIDENED — on nvim-deselected uninstall, remove the whole `~/.local/share/nvim` data dir instead of only `mason/`. Live evidence: the dir holds only regenerable state (`lazy/` plugin checkouts, `mason/` binaries, `site/`, picker history); mason-only leaves ~42 plugin checkouts behind, contradicting clean reversal. Keeps the existing typed-`yes` gate (no `--yes` bypass change) and `[DRY RUN]` preview. — **Reversibility:** reversible — reinstall re-clones/re-installs everything; no user config lives in the data dir (config is stowed, undo files are not stored there, shada is in `~/.local/state`).

### which-key popup design (EDIT-02)

- **D-05:** `folke/which-key.nvim` v3 with `preset = "modern"`, `delay = 200`, `triggers = { "<auto>" }` — LazyVim-like popup on `<Space>` (leader) with nested hints for subsequent keys.
- **D-06:** Minimal spec — register leader GROUP names only (file, search/todo, run, workspace, git, etc.); leaf hints come from the existing `desc` strings every keymap already carries. No per-key explicit spec entries. Researcher confirms the v3 API shape (`spec` vs `register`); planner wires group names to match the (possibly remapped) picker keys from D-09.

### fzf-lua migration boundary (EDIT-03)

- **D-07:** FULL removal — delete `lua/plugins/telescope.lua` (all three specs: `telescope.nvim`, `telescope-fzf-native.nvim`, `telescope-ui-select.nvim`) and rewrite every call site: `nvim-tree.lua` telescope integration (`<c-f>`/`<c-fg>` + `view_selection` attach logic), `alpha.lua` `ColorschemeWithPreview` + dashboard buttons (`ff`/`r`/`k`), all `Telescope ...` keymaps in `base/keymaps.lua`, `TodoTelescope` bindings, `Noice telescope` binding, and the spurious `live-preview.nvim → telescope.nvim` dependency in `lua/lang/markdown/plugins.lua`. Zero `require("telescope")` / `:Telescope` references remain. — **Reversibility:** reversible — specs and call sites restore from git; no data migration.
- **D-08:** `plenary.nvim` STAYS — `todo-comments.nvim` declares it as a dependency and it remains installed. Remove it only if the researcher proves zero remaining consumers. The `Telescope = ""` icon key in `lua/icons/lspkind.lua` is cosmetic; researcher decides keep-vs-drop, planner follows.
- **D-09:** Keymap rule — every NON-telescope keymap stays byte-identical unless a conflict forces movement (current keys win on conflict). Telescope-backed bindings are removed and the new fzf-lua bindings prefer fzf-lua's OWN upstream default keys where conflict-free, falling back to the current `<leader>` keys on conflict. All `desc` strings preserved (feeds D-06 which-key). Researcher maps each current picker (`find_files`, `live_grep`, `buffers`, `help_tags`, `oldfiles`, `marks`, `git_commits`, `git_status`, `current_buffer_fuzzy_find`, colorscheme-with-preview, Todo, Noice history) plus resolves the mystery `Telescope terms` picker (no known extension registers it — likely dead config) to its closest FzfLua builtin.

### make/gcc dep fate (EDIT-03)

- **D-10:** Demote `make` + `gcc` from `common` to OPTIONAL with warn-if-missing — never hard-require, never silently break. The picker itself needs neither (no build step, no silent fallback). Remaining consumers: `blink-cmp` (`run = "make install_jsregexp"`, optional jsregexp) and treesitter (`auto_install = true` + `build = ":TSUpdate"`, needs a C compiler for parser builds). Live proof of safety: `gcc` is uninstallable in Termux (no `gcc` package — `clang` is the compiler there; `pkg install gcc` can never satisfy the probe) yet nvim works fine on Termux today. Researcher MUST additionally investigate no-compromise configuration so demotion costs nothing: e.g. treesitter parser behavior without a compiler present (prebuilt/shipped parsers? graceful skip?), blink-cmp without jsregexp (prebuilt binary path?), `clang` as accepted compiler alternative. Planner implements whatever no-compromise config research supports, plus the installer warn-if-missing wording. — **Reversibility:** reversible — re-add to `common`; dep-list edit only.

### Proof and regression

- **D-11:** No silent fallback path for the picker anywhere (no `cond = executable("make")` pattern carried over); `nvim --headless -c "checkhealth"` must report the picker healthy.
- **D-12:** NO self-test/TAP harness in Phase 5 (stays Phase 6 HLTH-01). Phase 5 verification is lightweight and headless: `checkhealth` zero errors (incl. fzf-lua) + installed Mason package list matches `require("lang").mason_packages`. Phase 6 absorbs these checks into its gates later.

### Plan split

- **D-13:** Two plans, sequential — 05-01: Mason auto-install trigger + widened cleanup + which-key popup; 05-02: fzf-lua migration + make/gcc demotion (+ no-compromise treesitter/blink config). 05-02 needs no 05-01 code, but 05-01 goes first so the headless Mason path is proven before the picker surface churns.

### Agent's Discretion

- Researcher picks exact FzfLua builtin per picker binding (D-09), fate of the `lspkind` Telescope icon key (D-08), and the no-compromise treesitter/blink config (D-10).
- Researcher confirms which-key v3 spec API and whether `telescope-ui-select`'s dressing role needs an fzf-lua equivalent (`fzf-lua` ui-select provider).
- Planner decides installer code shape for the headless trigger + warn wording (D-01/D-02) and the widened wipe messaging (D-04), following Phase-1 `DRY_RUN` preview + strict-mode conventions.

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + requirements (locked scope)

- `.planning/ROADMAP.md` — Phase 5 section (goal, EDIT-01/02/03, two-plan split 05-01/05-02, Phase 6 HLTH-01 separation).
- `.planning/REQUIREMENTS.md` EDIT-01 (headless `MasonInstallAll` + deferred backstop — NOTE: backstop explicitly rejected by D-01, installer-trigger-only wins), EDIT-02 (which-key v3 `preset=modern delay=200`), EDIT-03 (telescope* removal + fzf-lua + make/gcc removal-or-demote — NOTE: demote chosen by D-10), traceability table (EDIT-01/02/03 → Phase 5).
- `.planning/PROJECT.md` — Core Value (no manual `MasonInstallAll`), Constraints (Bash installer, reversibility, safety/no-destructive-without-preview, Zsh default untouched).
- `.planning/STATE.md` — current position Phase 5, Deferred Items (no open debt into Phase 5; Phase-4 autocomplete closed PASS).

### Prior context (carry-forward)

- `.planning/phases/04-*/04-CONTEXT.md` — stow `--no-folding` + `mkdir -p ~/.config` guards and the prevention-only/no-auto-repair rule: installer edits in Phase 5 must preserve them; do not touch stow paths.
- `.planning/phases/03-*/03-CONTEXT.md` — HOME-only `~/.zshrc.local` + `pcall(require,"local")` machine-local pattern: unrelated, do not regress.
- `.planning/codebase/CONCERNS.md` — Neovim pain section (manual `:MasonInstallAll`, missing which-key) is the debt this phase closes.

### Existing implementation to change (logic source)

- `nvim/.config/nvim/lua/utils/mason-install-all.lua` (44 lines) — `:MasonInstallAll` command def; semantics stay, setup.sh invokes it headless (D-01/D-03).
- `nvim/.config/nvim/lua/plugins/mason.lua` — `build`/`cmd` table; `build` hook preserved (D-03).
- `nvim/.config/nvim/lua/plugins/telescope.lua` (45 lines) — DELETE entirely (D-07).
- `nvim/.config/nvim/lua/base/keymaps.lua` — Telescope block lines 42–66, `Noice telescope` line 92, `TodoTelescope` lines 171–172; non-picker keys frozen (D-09).
- `nvim/.config/nvim/lua/plugins/nvim-tree.lua` lines 63–104 — telescope integration rewrite (D-07).
- `nvim/.config/nvim/lua/plugins/alpha.lua` lines 20–34 — `ColorschemeWithPreview` + dashboard buttons rewrite (D-07).
- `nvim/.config/nvim/lua/plugins/to-do.lua` line 4 — plenary dep, the reason plenary stays (D-08).
- `nvim/.config/nvim/lua/lang/markdown/plugins.lua` lines 109–115 — drop spurious telescope dep on live-preview (D-07).
- `nvim/.config/nvim/lua/icons/lspkind.lua` line 44 — cosmetic Telescope icon key (D-08, researcher decides).
- `nvim/.config/nvim/lua/plugins/blink-cmp.lua` — `run = "make install_jsregexp"` consumer (D-10).
- `nvim/.config/nvim/lua/plugins/treesitter.lua` — `auto_install = true`, `build = ":TSUpdate | TSInstallAll"` consumer (D-10).
- `nvim/.config/nvim/lua/lang/init.lua` — `mason_packages` aggregator (source of truth for D-12 Mason-list check); per-lang `mason_packages` tables (e.g. `lua/lang/python/python.lua` lines 25–28).
- `setup.sh` — `ALL_TOOLCHAIN` line 24 + per-family `common` lists lines ~194–202 (make/gcc demotion site, D-10); Mason preview lines ~878–885 + cleanup lines ~938–943 (widen to whole data dir, D-04); `run_stow` ~line 959 (headless Mason trigger lands post-stow, D-01/D-02); `verify_deps` dep→binary map ~line 275 (warn-if-missing for optional, D-10). Phase-1 conventions mandatory: `set -Eeuo pipefail`, `${1-}` guards, `DRY_RUN` early-return + `[DRY RUN] Would run:` preview, typed-`yes` gate for the wipe.

## Existing Code Insights

### Reusable Assets

- `setup.sh` `DRY_RUN` early-return + `[DRY RUN] Would run:` preview idiom — mandatory wrapper for the headless Mason trigger and the widened wipe (D-01/D-04).
- `setup.sh` typed-`yes` gate + `--yes` CI bypass on uninstall — reused unchanged for the whole-data-dir wipe (D-04).
- `verify_deps` dep→binary map (`neovim→nvim`, `ripgrep→rg`, `nodejs→node`, else identity) — extend with optional-marking for make/gcc warn-if-missing (D-10).
- Every keymap's `desc` string — feeds which-key group+leaf display with zero extra spec (D-06).
- Termux + no-gcc as a living experiment — proves the editor degrades gracefully without a compiler (D-10 evidence).

### Established Patterns

- `lang/init.lua` aggregator + `deduplicate` — `mason_packages` stays the single source of truth for both the headless install and the D-12 verification check.
- `pcall(require, ...)` + `vim.notify(WARN)` on language-load failure — model for any optional-capability handling (e.g. missing-compiler paths must warn, never crash).
- Phase-1 atomic-docs rule: behavior change ships with its README/in-code comment update in the same commit.
- Stow `--no-folding` + `mkdir -p ~/.config` on every stow call — Phase-5 installer edits must not disturb these lines.

### Integration Points

- Post-stow slot in `setup.sh` main flow (after `run_stow` + `post_verify` succeed) — headless Mason trigger insertion point (D-01).
- Uninstall path Mason block (`~/.local/share/nvim/mason` rm) — widen to whole `~/.local/share/nvim` with preview text update (D-04).
- `lazy-lock.json` — gains `which-key.nvim` + `fzf-lua` pins, loses `telescope*` pins; plenary pin stays (D-07/D-08).
- `checkhealth` — Phase-5 lightweight gate (D-12), absorbed by Phase-6 TAP later.

## Specific Ideas

- User verbatim (Mason failure): "warn and say how to retry in future then continue" (D-02).
- User verbatim (keymaps): "every current keymap should be same if no conflict occurs, only telescope keymaps should removed and the new fzf-lua keymaps should try to use the own default keys" (D-09).
- User verbatim (Termux probe): "one of the two already is not available in termux but still nvim works fine, can you check which one is not available to install in termux before i answer this" — finding: `gcc` has no Termux package (`clang` is the compiler there); `make` installs fine. Recorded as D-10 evidence.
- User verbatim (no-compromise): "demote to optional also check if there is further configuration possible so that there is no compromise with treesitter and blink?" (D-10 research directive).
- User verbatim (cleanup): "why remove only .local/share/nvim/mson why not the whole .local/share/nvim" (D-04).

## Deferred Ideas

- Full `--self-test` TAP harness (stow symlinks, tool versions, `checkhealth`, Mason list, keybinds, PATH, keyd preview) — owned by Phase 6 (HLTH-01), not this phase (D-12).
- `mason-tool-installer` deferred `ensure_installed` backstop — explicitly DECIDED AGAINST in D-01 (not deferred); do not re-propose without new evidence.

---

*Phase: 5-editor-autonomy-fzf-lua-migration*
*Context gathered: 2026-10-01*
