# Phase 3: Polished Shell, Theme & Local Overrides - Context

**Gathered:** 2026-09-17
**Status:** Ready for planning

## Phase Boundary

Daily Zsh feels finished — async autocomplete auto-shows as you type, PATH stays duplicate-free across reloads, machine-local tweaks live in HOME-only gitignored files bootstrapped by `setup.sh`, and theme drift is left alone (declared intentional). Phase 3 delivers reshaped SHEL-02 (autocomplete-first, fzf best-effort/deferrable), SHEL-03 (`typeset -U` top-of-file, all PATH lines, keep-first), SHEL-04 + EDIT-04 (HOME-only `~/.zshrc.local` + deployed `local.lua`, gitignored, auto-created empty by installer), and explicitly **no theme work** (THEM-01 closed as intended-drift). Installer spine, unified single-page checklist, uninstall `yes`-guard, keyd gate, Zinit self-clone, and Hyprland removal are locked from Phases 1/2/2.1 and not re-asked. Mason auto-install, which-key, and self-test gates stay Phase 4.

## Implementation Decisions

### Autocomplete-first history wiring (SHEL-02 reshaped)

- **D-01:** Keep BOTH `joshskidmore/zsh-fzf-history-search` and `marlonrichert/zsh-autocomplete` with split ownership: fzf-history-search owns `Ctrl+R`, autocomplete owns `Tab`/`^I` with explicit load order and bindkeys fixed in `zsh/.zshrc:299-305`.
- **D-02:** Priority ladder is locked: (1) autocomplete must work → (2) fix fzf via zinit plugin in `zshrc` if possible → (3) fall back to system-installed fzf binary → (4) skip fzf entirely. fzf init must never be able to break autocomplete; fzf absence is tolerated.
- **D-03:** Always bind `bindkey '^R' fzf-history-widget` (user explicitly overrode conditional binding). If fzf is missing/not working, emit a warning telling the user to install fzf (no silent dead key, no silent fallback to builtin).
- **D-04:** Fixed autocomplete behavior is auto-show list: the async find-as-you-type completion list appears automatically below the prompt as you type with no keypress; `Tab` only enters menu-select. Today's broken symptom (must press `Tab` to see anything) is the bug to fix.
- **D-05:** Keep all three: `zsh-autosuggestions` (ghost text) + `fast-syntax-highlighting` + `marlonrichert/zsh-autocomplete` must coexist. Dropping autosuggestions to fix the clash is rejected. Planner/researcher must fix load/init order so async auto-show works alongside them.

### PATH dedup scope (SHEL-03)

- **D-06:** Put `typeset -U path` near the top of `zsh/.zshrc` so every later `export PATH` automatically dedupes — **Reversibility:** reversible — single-line move reverts cleanly.
- **D-07:** Scope covers ALL PATH mutations in `zsh/.zshrc`, including the 5 top exports (`~/.local/bin`, `~/.local/sbin`, `~/.bun/bin`, `~/.npm-global/bin`), the late `~/.local/share/zinit/polaris/bin` append (~line 232), bun completions, and uv `fpath` additions — with the constraint "make sure nothing breaks".
- **D-08:** Duplicate semantic is keep-first (zsh `typeset -U` default): existing precedence preserved, later dupes dropped.
- **D-09:** Verification is reload + smoke: repeated `source ~/.zshrc` then `echo $PATH | tr : '\n' | sort | uniq -d` is empty, PLUS `z`/`zi`, zoxide, completions, and p10k prompt still work after reload.

### Local overrides shape (SHEL-04 + EDIT-04 reshaped)

- **D-10:** HOME-only sourcing (user override of the ROADMAP dual-file text): only `~/.zshrc.local` in HOME is auto-sourced at the tail of `zsh/.zshrc` (after `zoxide init`, before p10k apply). No repo-side `zsh/.zshrc.local` is sourced. — **Reversibility:** reversible — one guard block reverts; note ROADMAP success criterion #3 text still names both files and needs a planner note.
- **D-11:** Nvim `lua/local.lua` loads via `pcall(require, "local")` at the very end of `init.lua`, after the `vim.schedule` colorscheme block, so machine tweaks always win.
- **D-12:** Gitignore both local files, and `setup.sh` creates both empty local files in their HOME deployed locations after setup completes, so they never enter the repo at all. Ship `*.example` templates in-repo as documentation.

### Theme token + check (THEM-01 dropped)

- **D-13:** Zero theme work in Phase 3. Current per-app mapping (`alacritty catppuccin-mocha` vs `starship catppuccin_latte` vs `nvim tokyodark` vs p10k `catppuccin classic mocha`) is INTENDED drift — no `THEME` token, no `setup.sh apply_theme()`, no warn, no rewrite. Close THEM-01 as intentionally-drifted; planner must not "fix" it and researcher must not flag it as a bug.

### Agent's Discretion

None — every presented option was decided by the user (including two explicit overrides: HOME-only local sourcing, and full theme drop). No "You decide" selections.

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + requirements (locked scope)

- `.planning/ROADMAP.md` Phase 3 section — goal "Daily Zsh feels finished", 5 success criteria (fzf version-branch + one-history-plugin policy + `^R`/`^I` normalization; `typeset -U path`; dual `*.local` sourcing order + `.gitignore` + `*.example`; `pcall(require,"local")` + gitignore + example; single `THEME` token + `apply_theme()` warn), single-plan split (03-01). NOTE: this CONTEXT reshapes #1 (autocomplete-first ladder), #3 (HOME-only per D-10), and drops #5 (intended drift per D-13) — planner must note the deltas, not blindly implement ROADMAP text.
- `.planning/REQUIREMENTS.md` §§ Shell — Zsh (SHEL-02 fuzzy history without conflicts, SHEL-03 PATH dedup, SHEL-04 machine-local `~/.zshrc.local`), Editor (EDIT-04 `lua/local.lua`), Docs/Theme/Health (THEM-01 single token + warn). Traceability table maps SHEL-02/03/04 + EDIT-04 + THEM-01 to Phase 3.
- `.planning/PROJECT.md` — Core Value, Constraints (Zsh default, machine-local gitignored auto-sourced, no destructive writes without preview), Key Decisions table, and Context (Zsh pain: no working history search + `^I` conflict; machine-local `*.local` pattern pending Phase 3).

### Prior context (carry-forward)

- `.planning/phases/01-universal-installer-platform-foundations/01-CONTEXT.md` — D-01..D-16 locked (canonical `setup.sh`, staged deletes, `${1-}` guards, checklist ladder `gum→whiptail→dialog→fzf→read`, quarantine `.stow-conflicts/<ts>/`+`MANIFEST`, `stow <2.4.1` auto-upgrade, strict `test -L`+`readlink -f` post-verify).
- `.planning/phases/02-safe-reversible-server-safe-deployment/02-CONTEXT.md` — D-01..D-15 locked, especially D-03 (`Type 'yes'` guard + `--yes` CI bypass + dry-run preview), D-12 (Zinit self-clone, no installer pin), D-13 (`chsh` end-of-run only, explicit `yes`).
- `.planning/phases/02.1-remove-hyperland-and-hyperland-related-configs-and-make-sure/02.1-CONTEXT.md` — Hyprland 6 removal, unified single-page checklist (6 stow + toolchain, tick = install + stow), Debian keyd asymmetry + manual-build prompt, remnant sweep with no binary cleanup offer.

### Existing implementation to change (logic source)

- `zsh/.zshrc` (393 lines) — 5 scattered `export PATH` lines (36-40) + `polaris/bin` append (~line 232), no `typeset -U`; plugin block lines 290-305 (`zsh-autosuggestions` + `fast-syntax-highlighting` + `joshskidmore/zsh-fzf-history-search` via `zi ice` + `marlonrichert/zsh-autocomplete` with `^I menu-select` atload); `zoxide init` at line ~50; p10k source at line 327 + `apply_catppuccin classic mocha` at 330; NO `^R` binding; NO `.local` sourcing; bun source at tail uses absolute `/home/shoyeb/.bun/_bun` (portability note for planner).
- `zsh/.zprofile` — intentionally empty (Hyprland exec deleted Phase 2); do not re-add anything here.
- `nvim/.config/nvim/init.lua` — tail applies colorscheme in `vim.schedule` after `require("base")`; `pcall(require,"local")` goes after that block per D-11.
- `nvim/.config/nvim/lua/settings.lua` — `colorscheme = "tokyodark"` + 14-language list; NOT a theme token (D-13: leave alone).
- `setup.sh` — `ALL_TOOLCHAIN` includes `fzf` in common (line 24); no `THEME`/`apply_theme` exists (D-13: do not add); local-file creation (D-12) must follow `DRY_RUN` early-return + `[DRY RUN] Would run:` preview rules.
- `.gitignore` — covers nushell history + nvim state but has NO `*.local` and NO `zsh/.zsh_history` entries (D-12 adds them; history purge itself is deferred — see below).
- `starship/.config/starship.toml` (`palette = 'catppuccin_latte'`, `scan_timeout = 1000`) + `starship-minimal.toml` + `alacritty/.config/alacritty/alacritty.toml` (imports `catppuccin-mocha.toml`) + `nvim/.config/nvim/lua/colorschemes/` (`catppuccin.lua`, `gruvbox.lua`, `nightfox.lua`, `tokyodark.lua`) — read-only context for D-13; DO NOT normalize.

### Codebase maps (scouted 2026-09-10, refreshed 2026-09-17)

- `.planning/codebase/CONCERNS.md` — Zsh pain (`zsh-autocomplete` vs `zsh-fzf-history-search` + `^I` remap), PATH length/dedup (`str uniq` suggestion), theme duplication (now declared intended per D-13), shell init ordering (zoxide position, p10k instant prompt at top), `MISTRAL_API_KEY` committed secret (see Deferred Ideas).
- `.planning/codebase/STRUCTURE.md` — stow package layout (`zsh/`, `nvim/`, `starship/`, `alacritty/`), key files (`zsh/.zshrc`, `nvim/.config/nvim/init.lua`, `lua/settings.lua`), naming conventions.

## Existing Code Insights

### Reusable Assets

- `setup.sh` `DRY_RUN` early-return + `[DRY RUN] Would run:` preview + `stow --no --verbose` — mandatory wrapper for D-12 local-file creation.
- `setup.sh` five-backend ladder (`gum→whiptail→dialog→fzf→read`) + cancel-never-cascades — reuse if local-file creation needs any prompt (default should be non-interactive create-empty).
- `nvim/.config/nvim/lua/lang/init.lua` `pcall(require, ...)` + `vim.notify WARN` pattern — model for D-11 `pcall(require, "local")` (silent-missing is correct: absent file = no-op, present-but-erroring file = warn).
- `zsh/.zshrc` conditional-source idiom (`[[ -f ... ]] && source ...` for `.shell_aliases`/`.shell_functions`, p10k) — model for D-10 `~/.zshrc.local` guard.

### Established Patterns

- `set -Eeuo pipefail; shopt -s inherit_errexit` + `${1-}` guards + `--help`-wins pre-scan — mandatory for any new `setup.sh` code.
- `zsh/.zshrc` ordering constraints: p10k instant prompt stays at top; `zoxide init` position fixed; `.local` sourcing goes after `zoxide init`, before p10k apply (D-10).
- `typeset -U path` keep-first semantics — preserves existing precedence while dropping dupes (D-08).
- Phase 1 D-04 atomic-docs rule: every behavior change ships with its README/AGENTS.md/in-code comment update in the same commit.

### Integration Points

- `zsh/.zshrc:299-305` plugin block — the single edit site for D-01..D-05 (load order, version-branched fzf init with warn-if-missing, explicit `bindkey '^R'`, async auto-show config).
- `zsh/.zshrc` PATH lines (36-40, ~232) + completion `fpath` — D-06..D-09 edit sites; verification via repeated `source` + `z`/`zi`/completions/prompt smoke.
- `zsh/.zshrc` tail (after `zoxide init`, before `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh`) — D-10 insertion point.
- `nvim/.config/nvim/init.lua` tail (after `vim.schedule` colorscheme) — D-11 insertion point.
- `setup.sh` post-stow success path — D-12 insertion point (create empty HOME local files; `--dry-run` previews, never writes).
- `fzf` version probe: `fzf --version` `sort -V` compare against `0.48` to branch `source <(fzf --zsh)` vs legacy `/usr/share/fzf/key-bindings.zsh` — only reached when fzf binary exists (D-02 ladder step 2-3).

## Specific Ideas

- User verbatim (priority): "auto complete must work > if possible fix fzf in zshrc > if built in zsh plugin does not work then use the system installed fzf > if that will also won't work then skip fzf".
- User verbatim (fzf deprioritized): "fzf search is not a priority now so if there is any conflict with it we can remove it, the main thing need to work is the autocomplete".
- User verbatim (symptom): "the problem with autocomplete isn't that the keybinds don't work but the Asynchronous find-as-you-type autocompletion was not working i had press tab to see the completion it was not showing auto".
- User verbatim (local): "i want .zshrc.local to be only stay at home" + "edit the setup script so after the setup completion it creates the both the local empty files in the home folder so it never enters the repo at all".
- User verbatim (theme): "no need to warn or do anything it is intended drift" (alacritty mocha / starship latte / nvim tokyodark / p10k mocha).
- User verbatim (deferred): "make sure zsh history is never commited and removed from all the previous commit in remote repo all branches, also there are my mistral and google api key somewhere in the whole repo make sure to remove them too".

## Deferred Ideas

- **History + secret purge across all branches (user-requested, NOT Phase 3 work):** `zsh/.zsh_history` is currently tracked in git and absent from `.gitignore` (verified 2026-09-17; `.gitignore` covers only nushell history). Key-name mentions exist in `nushell/.config/nushell/env.nu` and `AGENTS.md` (filenames only — values never reproduced). Working-tree fix (untrack + gitignore `zsh/.zsh_history`) may ride with D-12 since it is the same "git stays clean" theme; but the requested full purge from all previous commits on all branches plus key rotation is REQUIREMENTS.md SECR-02 (v2-deferred: `filter-repo`/`BFG` + force-push coordination, `sops`/`age`/`pass` + `gitleaks` hook). Do NOT attempt history rewrite in Phase 3 — record for a dedicated secrets/hygiene phase. Never write secret values into planning docs or commits.
- **Debian keyd fully-automated git-build path** (clone → `make` → `sudo make install` inside `setup.sh`) — carried from Phase 2.1 deferred; Phase 2.1 only prompts with the build URL.
- **AUTO-01/AUTO-02 backup snapshot + CI matrix** remain v2 per REQUIREMENTS.md; not re-raised.

---

*Phase: 3-Polished Shell, Theme & Local Overrides*
*Context gathered: 2026-09-17*
