---
phase: 01-universal-installer-platform-foundations
plan: 05
subsystem: infra
tags: [bash, installer, checklist, deps, dry-run, stow, toolchain, toggle, filtering]

# Dependency graph
requires:
  - phase: 01-universal-installer-platform-foundations
    provides: Executable setup.sh with checklist-before-install and repo refresh (01-04)
provides:
  - Two-step checklist (7 stow configs + 13 toolchain binaries) with filtered verify/install/preview
  - SELECTED_DEPS filtering through get_deps, verify, install, re-verify and unified Preview
  - Stow-required guard and toolchain preview count before stow simulation
affects: [phase-02, installer, distro-handling, stow-orchestration, gap-closure]

# Actuals (#2632)
actuals:
  tokens: 4389
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns: [checklist-before-install, filtered-deps, toolchain-guard, preview-unification]

key-files:
  created: []
  modified: [setup.sh]

key-decisions:
  - "Accept Option (A) make toolchain individually toggleable via second checklist step prompt_toolchain_checklist with ALL_TOOLCHAIN 13 + SELECTED_DEPS, filter get_deps output to SELECTED_DEPS before verify/install/re-verify (minimal viable, gui extras bypass filter)"
  - "Keep existing 7-package flow intact (ALL_PACKAGES, GUI_STOW_PACKAGES, TERMUX_DISABLED, SELECTED_PACKAGES) and insert toolchain selection immediately after it before any package-manager write to preserve checklist-before-install invariant"
  - "Reuse five-backend ladder pattern (gum→whiptail→dialog→fzf→read) for toolchain with all-ON presets and no Termux disabled; cancel code 2 never cascades, 1 skip, 0 success — mirrors package ladder contracts"
  - "Stow-required guard: if stow deselected while not installed warn and re-enable preserving ALL_TOOLCHAIN order; if stow already installed allow deselection"
  - "Filter only toolchain names (ALL_TOOLCHAIN intersection) and always keep gui deps (hyprland/waybar/etc.) when mode==local; guard with SELECTED_DEPS empty fallback to avoid empty filtering"
  - "Unify preview after both checklists: verify filtered set, install_deps preview (sudo apt update + install) plus Toolchain preview count line, then preview_selection stow simulation — together in === Preview ==="

patterns-established:
  - "Checklist-before-install (two-step): mode->shell->detect_family->prompt_checklist (7)->prompt_toolchain_checklist (13)->get_deps (filtered)->verify->Preview->install->reverify->quarantine->stow->post_verify"
  - "Filtered-deps: SELECTED_DEPS ∩ get_deps drives verify_deps/install_deps/reverify_deps; deselected toolchain absent from Missing and Would run"
  - "Toolchain guard: stow re-enable when not installed prevents broken deploy"

requirements-completed: [INST-04, DEPS-02, INST-02]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: "User sees two-step checklist (7 stow + 13 toolchain) before any write, each individually toggleable"
    requirement: "INST-04"
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | awk '/Package Selection/{p=1} /Toolchain Selection/{t=1} /Verifying dependencies/{v=1} END{exit !(p && t && v)}'"
        status: pass
      - kind: manual_procedural
        ref: "HOME=/tmp/fake-nontty PATH=/tmp/noladderbin bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q '13 toolchain offered'"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -E 'Final package selection|Final toolchain selection' | wc -l | grep -q 2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Only selected toolchain deps are verified/installed/re-verified and previewed; deselected absent from Missing and Would run"
    requirement: "DEPS-02"
    verification:
      - kind: manual_procedural
        ref: "bash -c 'source ./setup.sh; SELECTED_DEPS=(starship git); FAMILY=debian; MODE=server; mapfile -t _d < <(get_deps \"$FAMILY\" \"$MODE\"); echo ${_d[*]} | grep -qv neovim && echo ok'"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'Toolchain preview:'"
        status: pass
      - kind: manual_procedural
        ref: "bash -c 'source ./setup.sh; SELECTED_DEPS=(starship git); FAMILY=debian; MODE=local; mapfile -t d < <(get_deps \"$FAMILY\" \"$MODE\"); echo ${d[*]} | grep -q alacritty'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Unified dry-run preview after both checklists shows both depot and stow writes; --yes and non-TTY preserve correct preset behavior for both steps"
    requirement: "INST-02"
    verification:
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q '=== Preview ===' && bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'Would run: stow --dir='"
        status: pass
      - kind: manual_procedural
        ref: "bash setup.sh --mode server --shell zsh --yes --dry-run 2>&1 | grep -q '13 toolchain offered'"
        status: pass
      - kind: manual_procedural
        ref: "HOME=/tmp/fake-verify-filter PATH=/tmp/noladderbin bash setup.sh --mode server --shell zsh --dry-run 2>&1 | grep -q 'Verifying dependencies'"
        status: pass
    human_judgment: false
  - id: D4
    description: "Stow guard prevents broken deploy while allowing explicit toggle when already installed"
    requirement: "DEPS-02"
    verification:
      - kind: manual_procedural
        ref: "bash -c 'source ./setup.sh; PATH=/tmp/empty_test_bin SELECTED_DEPS=(neovim); _toolchain_ensure_stow; echo ${SELECTED_DEPS[*]} | grep -q stow'"
        status: pass
    human_judgment: false

# Metrics
duration: 3 min
completed: 2026-09-11
status: complete
---

# Phase 01 Plan 05: Gap closure — all apps toggleable (deps + stow) Summary

**Two-step interactive checklist — 7 stow configs then 13 toolchain binaries — both before any write, with SELECTED_DEPS filtering through verify/install/re-verify and unified Preview**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-11T19:38:18Z
- **Completed:** 2026-09-11T19:41:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added second checklist step `prompt_toolchain_checklist` with data model `ALL_TOOLCHAIN=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)` (13) and `SELECTED_DEPS`, wiring full five-backend ladder (gum→whiptail→dialog→fzf→read) with all-ON presets, `--yes` bypass, non-TTY presets, and `stow` required-for-deployment guard preserving `ALL_TOOLCHAIN` order
- Inserted toolchain selection immediately after existing `prompt_checklist` and before `get_deps` in `main()` (`=== Toolchain Selection ===` → `prompt_toolchain_checklist` → `Final toolchain selection: ... (offered 13, selected N)` + `13 toolchain offered`) so both stow (7) and toolchain (13) complete before any `apt update`/`pacman -Sy`/`pkg update` write — closes G-01-14b presentation confusion
- Wired `SELECTED_DEPS` filtering through dependency lifecycle: `get_deps` now filters to selected toolchain (gui extras always pass), `filter_deps_by_selection()` computes `filtered_deps` before `verify_deps`, `missing` derived only from selected, `install_deps`/`reverify_deps` operate only on filtered set, `stow` upgrade only queued when `stow` selected, dry-run `=== Preview ===` prints `Would run: sudo apt update` + `Would run: ${install_cmd[*]} ${missing[*]}` for filtered set plus `Toolchain preview: N to install among M selected` plus `preview_selection` stow simulation
- Unified preview and preserved contracts: `--dry-run` zero writes, `--yes` and non-TTY use presets for both steps (`Selected packages (--yes presets):` + `Selected toolchain (--yes presets):` / `non-interactive presets`), `bash -n` clean, outside-root guard, help-wins-anywhere, `ALL_PACKAGES` untouched, no new registry installs

## Task Commits

Each task was committed atomically:

1. **Task 1: Add toolchain toggle data model and second checklist step** - `61d8998` (feat)
2. **Task 2: Wire filtered deps through verify/install/re-verify and unified preview** - `205fb19` (feat)

**Plan metadata:** `pending` (docs: complete plan — next commit)

## Files Created/Modified

- `setup.sh` - Added `ALL_TOOLCHAIN` 13, `SELECTED_DEPS`, `prompt_toolchain_checklist` ladder with five backends and stow guard; inserted toolchain step before `get_deps`; added `filter_deps_by_selection()` and wired filtering through `get_deps`/`verify`/`install`/`reverify` with gui bypass, stow upgrade guard, and `Toolchain preview:` line — 1142 lines, `bash -n` clean, `=== Package Selection ===` before `=== Toolchain Selection ===` before `Verifying dependencies` before `=== Preview ===`

## Decisions Made

- Option (A) accepted over (B) per plan: make deps individually toggleable via second checklist step, not keep deps non-toggleable with notice — honors user's locked decision that all `Verifying dependencies` bullets be toggleable, directly maps 13 binaries to checklist entries, keeps existing 7-package toggle intact for Phase 2 dependencies
- Minimal viable filter: `filter_deps_by_selection()` filters only names in `ALL_TOOLCHAIN`; gui deps (`hyprland waybar grim slurp wl-copy` etc.) bypass filter and remain governed by `MODE==local` alone — simpler than ownership map, composable for future ownership coupling if reviewer prefers DEP_OWNERS
- Reuse existing ladder contracts (cancel 2 never cascades, 1 skip, 0 success) and `--yes`/`! -t 0` bypass idioms for toolchain to preserve CI/non-interactive behavior; `toolchain_read` fallback is production-quality with `,`→space normalization, invalid/out-of-range warnings, `(required for deployment)` note for `stow`, and associative `toggled` map in `ALL_TOOLCHAIN` order
- Place `Toolchain preview: N to install among M selected` before `preview_selection` in dry-run to make toolchain count visible without duplicating install logic; keep `quarantine_scan`/`run_stow`/`post_verify` solely on `SELECTED_PACKAGES`
- Make `get_deps` itself filter when `SELECTED_DEPS` populated to satisfy direct `get_deps` filtering test (`SELECTED_DEPS=(starship git) → get_deps` no longer contains `neovim`) while keeping helper `filter_deps_by_selection` for explicit main filtering — double-filter is idempotent

## Deviations from Plan

None - plan executed exactly as written except for verify helper count alignment (wc -l 2) — reduced duplicate `Final toolchain selection` prints in helpers to a single authoritative print in `main()` so `grep -E "Final package selection|Final toolchain selection" | wc -l` correctly reports 2 (package + toolchain) while still printing `13 toolchain offered` and `Final toolchain selection: ... (offered 13, selected N)` via main. No functional deviation; all automated verifies pass.

## Issues Encountered

- Initial toolchain helper prints duplicated `Final toolchain selection` (helper plus main bare plus main counts = 4 lines) causing `wc -l | grep -q 2` to fail (got 4); fixed by making helpers emit only `Selected via ...` + `13 toolchain offered` and letting `main()` emit the single authoritative `Final toolchain selection: ... (offered 13, selected N)` — count now 2 and `grep -q "13 toolchain offered"` still passes via both helper and main
- Direct `get_deps` filtering test `SELECTED_DEPS=(starship git); get_deps | grep -qv neovim` failed initially because `get_deps` returned unfiltered 13; added filtering inside `get_deps` when `SELECTED_DEPS` non-empty so direct call also respects selection and test passes, while keeping explicit `filter_deps_by_selection` for main

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Gap G-01-14b closed: user can toggle each toolchain binary individually via second checklist; `Verifying dependencies` list now matches toggleable set, presentation confusion eliminated
- Unified dry-run preview after both checklists shows both depot (`Would run: sudo apt update` / `pacman -Sy` / `pkg update`) and stow (`stow --dir=... --restow`) writes; `--yes` and non-TTY preserve correct preset behavior for both steps, zero writes before selection
- Existing Phase 1/2 contracts unbroken: `ALL_PACKAGES` 7 intact, outside-root abort, help-wins-anywhere, `bash -n` clean, no new registry installs, `sort -V` stow upgrade guarded by selection
- Ready for Phase 1 re-verification (19/19 must-haves plus gap-closure) and transition to Phase 2 (uninstall/keyd/server guard); no blockers

---
*Phase: 01-universal-installer-platform-foundations*
*Completed: 2026-09-11*

## Self-Check: PASSED

- Found: setup.sh (1142 lines, ALL_TOOLCHAIN 13, SELECTED_DEPS, prompt_toolchain_checklist, filter_deps_by_selection, 13 toolchain offered, bash -n clean, order Package->Toolchain->Verify->Preview holds)
- Verifications: toolchain step before Verifying (p6<t15<v22<pr40), unified Preview with Would run: stow, --yes presets (13 offered), filter demo (starship git without neovim, gui kept), tty deselect path, toolchain preview line, both selections count 2
- Commits: 61d8998, 205fb19 present in git log
