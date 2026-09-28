# Phase 1: Universal Installer + Platform Foundations - Research

**Researched:** 2026-09-10
**Domain:** Bash strict-mode installer scripting, Linux distro detection (os-release + manager probing + Termux), GNU Stow orchestration, terminal interactive-prompt ladders
**Confidence:** MEDIUM (core mechanics verified by local experiment + on-host man pages; derivative/Termux specifics cited from official docs + community sources)

## Summary

Phase 1 builds a single `bash setup.sh` that replaces `setup.zsh`/`setup.nu` with a strict-mode Bash entry-point (`set -Eeuo pipefail; shopt -s inherit_errexit`), a Termux-aware distro/deps resolver (`verify → install → re-verify` lock), and Stow orchestration (dry-run + 7-package checklist before any write + strict post-verify). No new libraries are needed: the entire stack is Bash 4.4+ builtins, GNU Stow, the platform package manager, and a preinstalled-tool prompt ladder (`gum → whiptail → dialog → fzf → read`).

Three findings materially shape the plan. First, a live lab experiment with the host's Stow 2.3.1 proved that single-file packages **fold** (`.config` becomes one symlink to the repo dir), so post-verify must assert on `readlink -f` resolving into the repo — `test -L` on the leaf file **fails** under folding — and that naive `rm -rf` cleanup inside a folded tree deletes repo content. Second, Termux has **no reliable `/etc/os-release` with `ID=termux`** (upstream issue termux/termux-app#2165 asked for one; detection is via `command -v pkg`, `$TERMUX_VERSION`/`$PREFIX`, `uname -o = Android`), so the roadmap's "including `ID=termux`" wording must be treated as a harmless extra check, never the primary probe — Termux detection goes FIRST, before os-release. Third, neither `whiptail`, `dialog`, `gum`, nor `fzf` checklists support disabled entries, so the CONTEXT-mandated "visible-but-disabled with reason" Termux rows must be **emulated** (OFF + reason in the tag text + post-selection strip/validate) in every backend.

**Primary recommendation:** Port `setup.zsh` function-by-function into `setup.sh` (it is the closest syntactic donor), fixing its five known defects (un guarded `$2`, hard-coded distro allowlist, missing `make`/`gcc`/`fzf`/`zsh` in common, destructive `rm -rf` conflict handling, CWD-relative stow), with Termux probed before os-release and every write gated behind mode → shell → checklist with `--dry-run` preview.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Canonical entry is `setup.sh` (not `install.sh`). ROADMAP + success criteria already name `bash setup.sh`; PROJECT.md's `install.sh` alternative is rejected. — **Reversibility:** costly — ROADMAP success criteria, REQUIREMENTS traceability, README/docs, and user muscle memory all name `setup.sh`; renaming touches every reference.
- **D-02:** Staged delete of legacy bootstrappers in Phase 1: delete `setup.nu` + `setup.zsh` now; keep `teardown.nu` + `teardown.zsh` until Phase 2 ships `bash setup.sh --uninstall`, then delete them.
- **D-03:** No compatibility shims. Deleted scripts are gone outright (recoverable via git history), not thin wrappers.
- **D-04:** Atomic docs fix inside the Phase 1 deletion commit: every README, `nvim/README.md`, and in-code comment reference to the deleted scripts is updated in the same commit — no dangling pointers left for Phase 2's DOCS-01 rewrite to clean up later.
- **D-05:** Bare `bash setup.sh` on a TTY starts the interactive flow (mode → shell → checklist). No-arg never just prints usage when a terminal is present.
- **D-06:** No TTY (piped/CI) without a complete flag set aborts with usage + non-zero exit and performs zero writes. No silent default run in automation.
- **D-07:** Partial flags: given flags stand, missing ones prompt on TTY or abort with usage when no TTY. Missing `--shell` never silently defaults; missing `--mode` never silently defaults.
- **D-08:** `--help` wins wherever it appears: prints usage, changes nothing, exits 0. Unknown flags abort with usage + non-zero exit before any prompt or write. Parsing must hold under `set -Eeuo pipefail` with `${1-}`-style guards (no `unbound variable` crash).
- **D-09:** Checklist lists all 7 packages individually toggleable (`nvim`, `zsh`, `nushell`, `alacritty`, `starship`, `wofi`, `keyd`). No core-locked tier — maximum user override, per the user's manual select/deselect requirement. Checklist backend ladder stays `gum → whiptail → dialog → fzf → read` (already locked by ROADMAP).
- **D-10:** `server` mode pre-unchecks GUI packages (`hyprland`-adjacent extras, `alacritty`, `wofi`, `waybar`-family) but the user can re-check any of them before any write happens.
- **D-11:** Shell choice pre-checks only the chosen shell (`--shell zsh` checks `zsh`, unchecks `nushell` and vice versa). User can override to both or neither in the checklist.
- **D-12:** Termux shows `keyd`/`hyprland`/`wofi` as visible-but-disabled entries with a reason note (user explicitly overrode the hide+note recommendation). They can never be selected on Termux; `nvim`/`zsh`/`starship` remain selectable and link correctly.
- **D-13:** Existing non-symlink targets are quarantined, never overwritten in place and never cause a bare abort: moved to a repo-root gitignored `.stow-conflicts/<timestamp>/` directory preserving relative paths (user verbatim: "create a gitignored conflicts directory and move all the conflicting folders in a separate timestamped folder", location: repo root).
- **D-14:** Quarantine writes a `MANIFEST` mapping original path → quarantined path and prints the restore procedure. `.gitignore` gains the `.stow-conflicts/` entry in Phase 1.
- **D-15:** `stow < 2.4.1` is auto-upgraded via the platform package manager (`pacman -S --needed` / `apt install -y` / `pkg install`) as part of the deps lock. Current host has stow 2.3.1, so this path will execute on real machines; abort-until-2.4.1 and warn-and-continue were both rejected.
- **D-16:** Post-stow verification is strict: `test -L` + `readlink -f` over the linked set (including `~/.config/nvim` and `~/.config/starship.toml` folding) must all pass or the run aborts with an exact link → expected-target report. Warn-and-pass was rejected — no silent half-linked state.

### The agent's Discretion
None — every presented option was decided by the user (no "You decide" selections).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. (`--uninstall` reversibility, keyd `--adopt` gate, Hyprland server guard belong to Phase 2 by roadmap, not raised as new asks; backup/snapshot restore `AUTO-01` stays v2.)

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INST-01 | `bash setup.sh` interactive install (mode → shell) with no preinstalled Nushell/Zsh | Bash-only constructs (`read`, `command -v`, `[[ -t 0 ]]`); shebang `#!/usr/bin/env bash`; ladder backends probed, not assumed |
| INST-02 | `--dry-run` previews every write (`stow --no --verbose`, installs) | `stow --no` is simulate-only [VERIFIED: stow 2.3.1 man]; `[DRY RUN] Would run:` prefix pattern ported from setup.zsh |
| INST-04 | Interactive checklist override after mode+shell (`gum → whiptail → dialog → fzf → read`) | Exact per-backend commands documented; cancel-vs-missing distinction; disabled-row emulation for Termux |
| INST-05 | Robust flag parsing under `set -Eeuo pipefail` + `${1-}` guards | Guard patterns verified live; existing `MODE="$2"` defect identified in setup.zsh |
| DEPS-01 | Derivatives + Termux install without hard error (manager probe → `ID_LIKE` → `ID`, families `arch`/`debian`/`termux`) | Probe order specified; Termux-first rationale; derivative map with assumption flags |
| DEPS-02 | `verify → install → re-verify` lock; `make`+`gcc`+`fzf`+`zsh` in common; core/gui partition; distinct Termux list, no sudo, no keyd | Donor tables located; Termux `pkg` semantics cited; re-verify abort pattern |
| DEPS-03 | Idempotent re-run (`stow --restow`, `--needed`/`-y`); stow ≥2.4.1 upgrade | Idempotency mechanism per manager; 2.4.1 delta shown to be behavior-neutral for this phase |
| STOW-01 | Correct symlinks from repo root only (`stow --dir`, `--no --verbose` preview, `test -L` + `readlink -f` post-verify incl. `starship.toml` folding; outside-root abort) | Folding + conflict behavior verified by live experiment; explicit `--target="$HOME"` recommended over stow default |

## Project Constraints (from AGENTS.md)

- **Shell default:** Zsh is default everywhere; Nushell is backup only — checklist pre-selection (`--shell zsh` checks `zsh`, unchecks `nushell`) must reflect this; docs/comments updated to Zsh-canonical in the atomic D-04 commit.
- **Installer language:** Unified installer must be **Bash** (`#!/usr/bin/env bash`, never `sh` — `shopt`, `[[ ]]`, arrays are bash-only). Available by default; no Nushell/Zsh preinstalled requirement (INST-01).
- **Scope filter:** Do not fix Nushell-only issues — port `setup.nu` logic only where the Zsh path drifted (core dep list); no `uv.nu`/`zoxide.nu`/secret work.
- **OS support:** `ID_LIKE` + package-manager presence (`pacman`/`apt`/`pkg`), not hard-coded IDs — plus Termux env probes first. Hard-coded `["arch","cachyos","ubuntu"]` allowlist (setup.zsh:390, setup.nu:22) is the exact defect being removed.
- **Machine-local:** Out of scope for Phase 1 (Phase 3), but `.stow-conflicts/` gitignore entry (D-14) follows the same git-clean principle.
- **Reversibility:** Phase 1 keeps teardowns; `--uninstall` is Phase 2. Phase 1 must not break `teardown.zsh`/`teardown.nu` (they call plain `stow -D <module>` from repo root — quarantine must not move anything they need).
- **Safety:** No destructive writes without preview/confirmation — quarantine (D-13) replaces setup.zsh's `rm -rf "$target"`; privileged `/etc/keyd` writes are Phase 2, Phase 1 only lists `keyd` in the checklist.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Arg parsing + strict-mode guards | Installer script (local process) | — | Pure Bash; no service involved |
| Distro/family detection | Installer script (reads `/etc/os-release`, env, `command -v`) | — | Host introspection only |
| Dependency install | Platform package manager (`pacman`/`apt`/`pkg` + `sudo` except Termux) | — | Only the native manager owns system packages |
| Symlink deployment | GNU Stow (`--dir` + `--target`) | — | Stow owns folding/splitting; never re-implement |
| Conflict quarantine | Installer script (plain `mv` + `MANIFEST`) | — | Pre-stow filesystem operation, not Stow's job |
| Interactive prompts | Terminal UI ladder (`gum`→`read`) | — | TTY-only; hard-gated by `[[ -t 0 ]]` |
| Post-verify | Installer script (`test -L` + `readlink -f`) | — | Read-only assertions over Stow's output |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Bash | ≥4.4 (host: 5.2.21 [VERIFIED: `bash --version`]) | Installer language | Preinstalled everywhere incl. Termux; `inherit_errexit` needs ≥4.4 [CITED: https://mywiki.wooledge.org/BashFAQ/105] |
| GNU Stow | ≥2.4.1 target; host has 2.3.1 [VERIFIED: `stow --version`] | Symlink farm manager | Already the deployment engine; 2.4.1 delta is behavior-neutral for this phase (see State of the Art) |
| pacman / apt / pkg | platform-native | System package install | Only correct installer per family; `pkg` is a `apt` wrapper on Termux [CITED: https://termux-wiki.vercel.app/package-management] |
| `command -v`, `test`, `readlink`, `mv`, `mkdir` | coreutils/builtin | Probing, verify, quarantine | POSIX/builtin — zero install cost |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| gum | any (`choose --no-limit`) | Rich checklist | First ladder rung if `command -v gum` succeeds [CITED: https://www.commandinline.com/shell-script-gum-tutorial/] |
| whiptail | 0.52.x (host has 0.52.24 [VERIFIED]) | ncurses checklist | Second rung; `--checklist` + fd-swap capture `3>&1 1>&2 2>&3` [CITED: https://linuxcommandlibrary.com/man/whiptail] |
| dialog | any | ncurses checklist | Third rung; same `--checklist` protocol as whiptail |
| fzf | ≥0.27 (host: 0.44.1 [VERIFIED: `fzf --version`]) | `-m` multi-select fallback | Fourth rung when no ncurses tool exists |
| `read` (builtin) | — | Numbered-prompt fallback | Final rung; always available |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Ladder (`gum→…→read`) | Bubbletea/textual TUI | Rejected by REQUIREMENTS Out of Scope — needs build toolchain; ladder covers flow with preinstalled/static binaries |
| GNU Stow | Custom `ln -sf` loop / chezmoi / yadm | Rejected by REQUIREMENTS Out of Scope — custom engine mishandles folding + `keyd -t /` privilege |
| Bash | Python/Nushell installer | Rejected by AGENTS.md — Bash is the only preinstalled guarantee (INST-01) |

**Installation:**
```bash
# No language-ecosystem packages. System tools installed per family inside setup.sh itself:
#   arch:   sudo pacman -S --needed --noconfirm <pkgs>
#   debian: sudo apt install -y <pkgs>
#   termux: pkg install -y <pkgs>   # no sudo on Termux
```

**Version verification:** No npm/PyPI/crates packages are introduced by this phase (Bash builtins + GNU Stow + platform managers only), so registry verification does not apply. Host-probed versions: Bash 5.2.21, Stow 2.3.1, whiptail 0.52.24, fzf 0.44.1, `gum`/`dialog`/`pacman`/`pkg` absent on this Ubuntu host [VERIFIED: `command -v` probe 2026-09-10].

## Package Legitimacy Audit

> No ecosystem-registry packages are installed by this phase. The Package Legitimacy Gate (npm/PyPI/crates) is **not applicable**: all dependencies are system packages resolved through the platform manager (`pacman`/`apt`/`pkg`) or preinstalled-tool probes. The table below records the system-level install surface so the planner can see exactly what `setup.sh` will invoke per family.

| Package | Registry | Purpose | Verdict | Disposition |
|---------|----------|---------|---------|-------------|
| `stow` | pacman/apt/pkg | Symlink deployment | OK (official repos) | Approved — auto-upgrade path per D-15 |
| `neovim`/`nvim` | pacman/apt/pkg | Editor | OK | Approved (binary name differs: `nvim` on arch/debian, `neovim` on Termux — see Assumptions) |
| `zsh`, `git`, `fzf`, `make`, `gcc`, `ripgrep`/`rg` | pacman/apt/pkg | Core deps | OK | Approved — `make`+`gcc`+`fzf`+`zsh` newly added to `common` per DEPS-02 |
| `starship`, `zoxide`, `uv`, `node`, `npm` | pacman/apt/pkg | Prompt/nav/toolchain | OK | Approved (Termux name mapping must be confirmed — see A3) |
| `hyprland`, `alacritty`, `wofi`, `keyd`, `waybar`, `grim`, `slurp`, `wl-copy` | pacman/apt | GUI extras | OK | Approved — never offered as selectable on Termux (D-12) |
| `gum`, `whiptail`, `dialog` | pacman/apt/pkg | Prompt ladder (optional) | OK | Best-effort: probe-only, never hard-required; `read` is the guaranteed fallback |

**Packages removed due to SLOP verdict:** none (no registry packages).
**Packages flagged as suspicious SUS:** none.

## Architecture Patterns

### System Architecture Diagram

```text
fresh clone
    │
    ▼
┌─────────────┐  --help / no-TTY+incomplete / unknown flag   ┌──────────┐
│ parse_args   │ ───────────────────────────────────────────▶ │ usage +  │
│ (${1-} guard)│  exit BEFORE any prompt or write (D-08)      │ exit 0/≠0│
└──────┬──────┘                                              └──────────┘
       │ complete flags or TTY
       ▼
┌──────────────┐  [[ -f $SCRIPT_DIR/setup.sh ]] else abort  ┌───────────┐
│ repo-root    │ ─────────────────────────────────────────▶ │ abort msg │
│ guard        │                                            └───────────┘
└──────┬───────┘
       ▼
┌──────────────┐
│ detect_family│  ① Termux env/pkg probes → "termux"
│              │  ② command -v pacman/apt → arch/debian hint
└──────┬───────┘  ③ ID_LIKE (space-split) → family
       │          ④ ID → family (incl. literal ID=termux if present)
       ▼
┌──────────────┐  common[] (+make,gcc,fzf,zsh)  ┌────────────────────┐
│ dep tables   │  gui[] (arch vs debian; EMPTY   │ termux table: pkg  │
│ per family   │  for termux)                    │ names, no sudo/keyd│
└──────┬───────┘                                └────────────────────┘
       ▼
┌──────────────┐  partition core_missing vs gui_missing
│ verify_deps  │ ──▶ all present? ──▶ skip install
│ (command -v) │
└──────┬───────┘  missing (and not --dry-run)
       ▼
┌──────────────┐  pacman -S --needed / apt install -y / pkg install
│ install_deps │  (+ stow self-upgrade if < 2.4.1)
└──────┬───────┘
       ▼
┌──────────────┐  residue? ──▶ abort "Still missing: …" (non-zero)
│ re-verify    │  (idempotent 2nd run: no-op here)
└──────┬───────┘
       ▼
┌──────────────────────────────────┐
│ mode → shell → checklist ladder  │  gum→whiptail→dialog→fzf→read
│ (BEFORE ANY WRITE; D-05…D-12)    │  --dry-run prints [DRY RUN] Would run:
└──────┬───────────────────────────┘  + stow --no --verbose for selection
       ▼
┌──────────────┐  collision? ──▶ mv → .stow-conflicts/<ts>/ + MANIFEST
│ quarantine   │  (never rm, never --adopt in Phase 1)
│ pre-scan     │
└──────┬───────┘
       ▼
┌──────────────┐  stow --dir="$SCRIPT_DIR" --target="$HOME"
│ stow         │  --restow <selected…>   (keyd: plain -t / path is Phase 2;
│              │                          Phase 1 stows it like others or skips)
└──────┬───────┘
       ▼
┌──────────────┐  readlink -f resolves into $SCRIPT_DIR for every
│ post-verify  │  expected link? else abort with link→expected report (D-16)
│ (strict)     │
└──────────────┘
```

### Recommended Project Structure

```text
./                          # repo root = stow dir
├── setup.sh                # NEW — canonical entry (this phase)
├── .stow-conflicts/        # NEW — gitignored quarantine root (D-13/D-14)
│   └── <timestamp>/        #   per-run dir preserving relative paths + MANIFEST
├── .gitignore              # EDIT — add .stow-conflicts/
├── setup.nu / setup.zsh    # DELETE (this phase, D-02)
├── teardown.nu/.zsh        # KEEP until Phase 2
├── README.md, nvim/.../README.md  # EDIT atomically (D-04)
├── nvim/ zsh/ nushell/ alacritty/ starship/ wofi/ keyd/  # stow packages (untouched)
```

`setup.sh` internal section order (port of setup.zsh, fixed):
`strict header → SCRIPT_DIR resolve → constants (families, dep tables) → log helpers → usage → parse_args → repo-root guard → detect_family → get_deps → verify_deps → install_deps (+stow upgrade) → re-verify → prompt_mode → prompt_shell → prompt_checklist (ladder) → dry-run preview → quarantine_scan → run_stow → post_verify → main`.

### Pattern 1: Strict-mode header + script-dir resolve
**What:** `set -Eeuo pipefail; shopt -s inherit_errexit` plus `SCRIPT_DIR` derived from `BASH_SOURCE`, never from CWD.
**When to use:** Top of `setup.sh`, before anything else.
**Example:**
```bash
#!/usr/bin/env bash
# Source: bash 5.2 on-host behavior [VERIFIED: lab probe 2026-09-10] + Greg's Wiki BashFAQ/105 [CITED: https://mywiki.wooledge.org/BashFAQ/105]
set -Eeuo pipefail
shopt -s inherit_errexit
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Repo-root guard (works regardless of CWD — stronger than [[ -f ./setup.sh ]]):
[[ -f "$SCRIPT_DIR/setup.sh" ]] || { echo "Error: run from the dotfiles repo root (setup.sh not found in $SCRIPT_DIR)." >&2; exit 1; }
```

### Pattern 2: `${1-}`-guarded arg parsing with `--help`-wins
**What:** `while [[ ${#} -gt 0 ]]` loop over `"${1-}"`; flags with values validate `$#` before shifting; `--help` handled anywhere with exit 0; unknown → usage + exit 1 before any prompt/write.
**When to use:** `parse_args` — must survive zero args, `--help` alone, and `--mode` with missing value under `set -u`.
**Example:**
```bash
# Source: wick bash-strict-mode doc [CITED: https://github.com/tests-always-included/wick/blob/master/doc/bash-strict-mode.md], defect observed in setup.zsh:33-59
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "${1-}" in
      --mode)   [[ $# -ge 2 ]] || { echo "Error: --mode needs local|server" >&2; usage >&2; exit 1; }; MODE="$2"; shift 2 ;;
      --shell)  [[ $# -ge 2 ]] || { echo "Error: --shell needs zsh|nushell" >&2; usage >&2; exit 1; }; SHELL_CHOICE="$2"; shift 2 ;;
      --dry-run) DRY_RUN=true; shift ;;
      --help|-h) usage; exit 0 ;;
      *) echo "Unknown option: ${1-}"; usage >&2; exit 1 ;;
    esac
  done
}
```

### Pattern 3: Fallible command substitution inside `if ! …`
**What:** Never bare `VAR=$(cmd)` when a custom error follows — under `set -e` the script dies at the assignment. Wrap: `if ! VAR=$(cmd); then … fi`.
**When to use:** `detect_family` os-release parsing, `stow --version` capture, any probe whose failure needs a message.
**Example:**
```bash
# Source: Brandon Wie, set -e + command substitution [CITED: https://brandonwie.dev/posts/bash-set-e-command-substitution]
if ! STOW_VER_STR=$(stow --version 2>/dev/null); then
  STOW_VER_STR=""
fi
```

### Pattern 4: Family detection — Termux first, then manager, then ID_LIKE, then ID
**What:** Four-tier probe returning `arch | debian | termux`. os-release is sourced only after Termux is excluded; `ID_LIKE` is space-split and matched token-wise (never substring).
**When to use:** `detect_family()` — the DEPS-01 core.
**Example:**
```bash
# Source: os-release(5) spec [CITED: https://www.man7.org/linux/man-pages/man5/os-release.5.html]
# + Termux detection practice [CITED: https://github.com/termux/termux-app/issues/2165]
detect_family() {
  # Tier 1 — Termux (no reliable /etc/os-release; env + pkg binary are ground truth)
  if [[ -n "${TERMUX_VERSION-}" ]] || [[ "${PREFIX-}" == *"com.termux"* ]] || command -v pkg >/dev/null 2>&1; then
    echo "termux"; return 0
  fi
  # Tier 2 — package-manager presence (covers derivatives regardless of ID strings)
  local have_pacman=false have_apt=false
  command -v pacman >/dev/null 2>&1 && have_pacman=true
  command -v apt >/dev/null 2>&1 && have_apt=true
  # Tier 3+4 — ID_LIKE tokens then ID (space-separated per spec, closest-first)
  local id="" id_like=""
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"; id_like="${ID_LIKE:-}"
  fi
  local cand
  for cand in $id_like "$id"; do  # word-splitting ID_LIKE is intentional here
    case "$cand" in
      arch|cachyos|manjaro|endeavouros|garuda) echo "arch"; return 0 ;;
      debian|ubuntu|linuxmint|pop|elementary)  echo "debian"; return 0 ;;
      termux) echo "termux"; return 0 ;;
    esac
  done
  # Manager fallback when os-release is exotic but a known manager exists
  if $have_pacman && ! $have_apt; then echo "arch"; return 0; fi
  if $have_apt && ! $have_pacman; then echo "debian"; return 0; fi
  return 1  # unknown → caller prints manual-install message, non-zero exit
}
```

### Pattern 5: whiptail checklist with fd-swap capture
**What:** `whiptail --checklist` writes selections to **stderr** — capture with `3>&1 1>&2 2>&3`; exit code 0 = confirmed, 1 = cancelled (cancel is a result, never a fall-through trigger).
**When to use:** Second checklist rung; `dialog --checklist` uses the identical protocol.
**Example:**
```bash
# Source: whiptail man [CITED: https://linuxcommandlibrary.com/man/whiptail]
sel=$(whiptail --title "Packages" --checklist "Space to toggle (before any write):" \
  20 70 10 "nvim" "" ON "zsh" "" ON "keyd" "(needs sudo, Phase 2)" OFF \
  3>&1 1>&2 2>&3) || { echo "Checklist cancelled."; exit 1; }
```

### Pattern 6: gum / fzf multi-select rungs
**What:** `gum choose --no-limit --header …` (or `gum filter --no-limit`); `fzf -m --header … --bind enter:accept`. Missing binary → next rung; user cancel (empty stdout / non-zero exit) → honor as empty/cancelled, never cascade.
**When to use:** First rung (gum) and fourth rung (fzf) of the D-09 ladder.
**Example:**
```bash
# Source: gum README/tutorial [CITED: https://www.commandinline.com/shell-script-gum-tutorial/]
if command -v gum >/dev/null 2>&1; then
  mapfile -t SELECTED < <(printf '%s\n' "${CHECK_ITEMS[@]}" | gum choose --no-limit --header "Toggle packages (Space):") \
    || { echo "Checklist cancelled."; exit 1; }
fi
```

### Anti-Patterns to Avoid
- **`MODE="$2"` without arity check:** under `set -u`, `bash setup.sh --mode` dies with `unbound variable` instead of a usage message — the exact defect in setup.zsh:36-38 [VERIFIED: setup.zsh:33-59]. Always `[[ $# -ge 2 ]]` first (Pattern 2).
- **`local out=$(fallible)`:** the `local` builtin masks the command's exit status, defeating `set -e` [CITED: https://mywiki.wooledge.org/BashFAQ/105]. Split: `local out; out=$(fallible)` or `if ! out=$(fallible)`.
- **`rm -rf "$target"` conflict cleanup:** setup.zsh:360 and setup.nu:186 delete user files; inside a **folded** tree the path resolves into the repo and deletes repo content [VERIFIED: lab experiment 2026-09-10]. Quarantine with `mv` (D-13) instead.
- **`test -L` on a folded leaf as the only assertion:** `~/.config/starship.toml` is a regular file inside symlinked `~/.config` when folded — `test -L` fails on success [VERIFIED: lab experiment]. Assert `readlink -f "$target"` starts with `$SCRIPT_DIR/<pkg>/` (plus `test -e`).
- **Substring match on `ID_LIKE`:** `[[ $ID_LIKE == *arch* ]]` false-positives (e.g. hypothetical `search`). Tokenize and `case`-match whole tokens (Pattern 4). (`${ID_LIKE#*debian*}` glob appears in the man page example, but token matching is strictly safer for installer branching.)
- **`read -q` in Bash:** `read -q` is zsh-only (setup.zsh:154 uses it); Bash needs `read -r -p "… " -n 1`. Port carefully.
- **Relying on stow's default target:** default target is the **parent of the stow dir** [VERIFIED: stow 2.3.1 man]. With `--dir="$SCRIPT_DIR"` this equals `$HOME` only when the clone sits directly in `$HOME` — always pass `--target="$HOME"` explicitly.
- **Cascading ladders on user cancel:** an empty selection / Esc is a deliberate result — return it, do not fall through to the next backend (else the user can never cancel).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symlink deployment + folding | Custom `ln -sf` loop | `stow --restow` / `stow -D` | Folding, splitting-open, refolding, and conflict detection are subtle state machines (info stow); custom loops corrupt folded trees — explicitly out of scope in REQUIREMENTS |
| OS identification parsing | Custom INI/regex parser for os-release | `. /etc/os-release` (it is defined as shell-sourcable) + `${ID:-}`/`${ID_LIKE:-}` defaults | Spec guarantees shell-compatible assignments [CITED: man7 os-release.5]; a parser re-implements quoting rules badly |
| Package-manager abstraction | Generic installer framework | 3-branch `case` (`pacman -S --needed` / `apt install -y` / `pkg install`) | Three families, three one-liners; abstraction adds indirection with zero reuse |
| TUI prompts | Bubbletea/textual dialogs | `gum→whiptail→dialog→fzf→read` ladder | Out of scope per REQUIREMENTS; ladder needs no toolchain and degrades to builtins |
| Version comparison for stow | String `[[ $ver > 2.4.1 ]]` | `sort -V` (`printf '%s\n' "$have" "2.4.1" \| sort -V \| head -1`) or `stow --version` numeric parse | Lexicographic compare says 2.10 < 2.4; `sort -V` is coreutils and correct |
| TTY detection | `$TERM` / `$PS1` heuristics | `[[ -t 0 ]]` | Only `-t` tests the actual fd; verified live (`NOTTY` under redirect) |

**Key insight:** Every deceptively-complex piece of this phase (folding, os-release quoting, ncurses fallbacks) already has a battle-tested owner. The installer's job is sequencing and safety rails (quarantine, dry-run, re-verify), not mechanisms.

## Common Pitfalls

### Pitfall 1: Folded-tree `rm` deletes repo content
**What goes wrong:** Cleanup code does `rm -rf ~/.config/<thing>` where `<thing>` sits inside a folded symlink (e.g. `~/.config → ~/dotfiles/starship/.config`). The kernel resolves through the symlink — the delete lands in the repo.
**Why it happens:** Stow folds aggressively: a package contributing a single file under `.config/` yields one directory symlink, not per-file links [VERIFIED: lab — `.config -> ../repo/starship/.config`].
**How to avoid:** Quarantine with `mv "$target" "$QUARANTINE_DIR/<relpath>"` (D-13); never `rm` a path you did not `test -L`-confirm is a symlink you own. `mv` of a symlink moves the link itself — safe.
**Warning signs:** Any `rm -rf` operating on `$HOME`-side paths in review; setup.zsh:360 is the known instance.

### Pitfall 2: `set -u` crashes on `--help` / missing values
**What goes wrong:** `bash setup.sh --help` or `--mode` (no value) aborts with `setup.sh: line N: $2: unbound variable` instead of usage.
**Why it happens:** `set -u` + bare `$1`/`$2` references; the existing parser reads `$2` unconditionally (setup.zsh:37,45) [VERIFIED: setup.zsh:33-59].
**How to avoid:** Loop on `"${1-}"`, arity-check before consuming values (Pattern 2); smoke-test matrix: `--help`, no args+TTY, no args+no-TTY, `--mode` (bare), `--mode bogus`, unknown flag.
**Warning signs:** Any `$1`/`$2`/`$MODE` reference without `-`/`:-` default or prior assignment.

### Pitfall 3: `set -e` silently skips custom error messages
**What goes wrong:** `VER=$(stow --version)` fails → script exits at that line; the friendly "stow missing, will install…" message below never prints.
**Why it happens:** Failing command substitution in an assignment triggers `set -e`; the next line is dead code [CITED: https://brandonwie.dev/posts/bash-set-e-command-substitution].
**How to avoid:** `if ! VAR=$(cmd); then … fi` (Pattern 3) for every probe with a fallback/message.
**Warning signs:** Bare `VAR=$(…)` on a command that can fail (version probes, `readlink`, `git`).

### Pitfall 4: Derivative rejected by hard-coded ID allowlist
**What goes wrong:** Manjaro/EndeavourOS/Garuda/Mint/Pop users hit `Error: only supports Arch/CachyOS/Ubuntu` (setup.zsh:390-394, setup.nu:22-26) [VERIFIED: setup.zsh:387-394].
**Why it happens:** Branching on `ID` equality instead of manager presence + `ID_LIKE` tokens.
**How to avoid:** Pattern 4 probe order; planner must include derivative simulation tests (fake os-release fixtures per derivative — no VM needed).
**Warning signs:** Any `case "$distro" in arch|cachyos|ubuntu)` plist in new code.

### Pitfall 5: Termux detected as Debian (or rejected)
**What goes wrong:** Termux `/etc/os-release` is the **Android host's** (or absent) — ID-based logic classifies Termux as unknown/debian, then runs `sudo apt` (no sudo on Termux) or offers `keyd` (no systemd, no `/etc/keyd`).
**Why it happens:** os-release describes the Android OS, not the Termux prefix; Termux detection signals are env/binary-level (`$TERMUX_VERSION`, `$PREFIX`, `command -v pkg`, `uname -o` = `Android`) [CITED: termux-app#2165 discussion; proot-distro detection].
**How to avoid:** Tier-1 Termux probe before touching os-release; Termux family list with no `sudo`, no `keyd`/`hyprland`/`wofi` selectable (D-12 emulation).
**Warning signs:** Any `sudo` on the Termux code path; `keyd` in the Termux package list.

### Pitfall 6: Post-verify false-fails on folded links (or false-passes on stale links)
**What goes wrong:** `test -L ~/.config/starship.toml` fails even though stow succeeded (folded), aborting a good run — or a stale absolute symlink passes `test -L` while pointing at a deleted repo path.
**Why it happens:** Folding makes the leaf a regular file under a symlinked dir; `-L` alone never checks the target.
**How to avoid:** Per expected link: `test -e` AND `readlink -f` prefix-matches `$SCRIPT_DIR/<pkg>/`. Cover both folded (dir link) and unfolded (file link) outcomes — do not assert a specific one.
**Warning signs:** Verify logic that hard-codes "file must be a symlink".

### Pitfall 7: `inherit_errexit` + pipelines with `head`/`SIGPIPE`
**What goes wrong:** `somecmd | head -n1` under `set -e -o pipefail` intermittently aborts (producer killed by SIGPIPE = failure) [CITED: https://mywiki.wooledge.org/BashFAQ/105].
**How to avoid:** Avoid `| head` on probed output in `setup.sh`; where unavoidable, append `|| true` to the producer or read via `mapfile`/redirection instead.
**Warning signs:** Any `| head|tail|grep -q` pipeline whose left side can SIGPIPE.

## Code Examples

Verified patterns from official sources:

### Parse os-release the spec-compliant way
```bash
# Source: man7 os-release.5 Examples 3–5 [CITED: https://www.man7.org/linux/man-pages/man5/os-release.5.html]
test -e /etc/os-release && os_release='/etc/os-release' || os_release='/usr/lib/os-release'
# shellcheck disable=SC1091
. "${os_release}"
echo "Running on ${PRETTY_NAME:-Linux}"
# Token-wise family test (safer than the man page's glob for branching):
family=""
for tok in ${ID_LIKE-} "${ID:-}"; do
  case "$tok" in arch|manjaro|endeavouros|garuda|cachyos) family="arch"; break ;;
  debian|ubuntu|linuxmint|pop) family="debian"; break ;; esac
done
```

### Stow preview + deploy + conflict surfacing
```bash
# Source: stow 2.3.1 man page on-host [VERIFIED] + Arch stow.8 for 2.4.1 [CITED: https://man.archlinux.org/man/stow.8]
stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg"   # preview: prints LINK/MKDIR lines, changes nothing
stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"         # deploy (prunes obsolete links)
# Conflict (verified verbatim, exit 1):
#   WARNING! stowing starship would cause conflicts:
#     * existing target is neither a link nor a directory: .config/starship.toml
#   All operations aborted.
```

### Strict post-verify over folded or unfolded links
```bash
# Source: lab experiment, stow 2.3.1, 2026-09-10 [VERIFIED]
# (folded: ~/.config -> $SCRIPT_DIR/starship/.config — leaf is NOT a symlink)
assert_linked() { # $1 = home-relative target, $2 = package
  local abs="$HOME/$1" got
  [[ -e "$abs" ]] || { echo "MISSING: $1 (expected from package $2)"; return 1; }
  got="$(readlink -f "$abs")" || { echo "UNRESOLVABLE: $1"; return 1; }
  case "$got" in "$SCRIPT_DIR/$2/"*) echo "ok: $1 -> $got" ;;
    *) echo "MISMATCH: $1 -> $got (expected under $SCRIPT_DIR/$2/)"; return 1 ;; esac
}
assert_linked ".config/starship.toml" "starship"
assert_linked ".config/nvim" "nvim"
```

### Quarantine + MANIFEST (D-13/D-14)
```bash
# Source: pattern derived from locked decision D-13; mv-onto-same-filesystem is atomic POSIX behavior [ASSUMED: same-filesystem holds for $HOME moves]
TS="$(date +%Y%m%d-%H%M%S)"
QDIR="$SCRIPT_DIR/.stow-conflicts/$TS"
mkdir -p "$QDIR"
mv "$HOME/.config/starship.toml" "$QDIR/.config-starship.toml"
printf '%s -> %s\n' "$HOME/.config/starship.toml" "$QDIR/.config-starship.toml" >> "$QDIR/MANIFEST"
echo "Quarantined to $QDIR. Restore with: mv <quarantined-path> <original-path>  (see $QDIR/MANIFEST)"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hard-coded `ID in [arch,cachyos,ubuntu]` allowlist | Manager probe → `ID_LIKE` tokens → `ID` (os-release(5) fallback rule) | This phase (spec predates: os-release standard since ~2012) | Derivatives install instead of erroring |
| `rm -rf` conflicting targets (setup.zsh:360) | Quarantine `mv` to `.stow-conflicts/<ts>/` + MANIFEST | This phase (D-13) | No data loss; restorable |
| `stow` from CWD, default target | `stow --dir="$SCRIPT_DIR" --target="$HOME"` | This phase (STOW-01) | Works from any CWD; target explicit |
| Stow 2.3.1 (host) | Stow 2.4.1 (auto-upgraded, D-15) | Upstream Sep 2024 [CITED: https://lists.libreplanet.org/archive/html/stow-devel/2024-09/msg00000.html] | **No action-relevant change**: 2.4.1 = Perl 5.40 warning fix, `--dotfiles`+ignore fix, `.stowrc` quoting, optional-LaTeX build. Folding/`--adopt`/conflict semantics used here are unchanged — 2.3.1 lab results transfer. Upgrade is still required by D-15, but not because behavior differs. |
| `read -q` (zsh), bare `$2` | `read -r -p`, `${1-}` + arity checks | This phase (Bash port) | Runs under `bash` with `set -u` |

**Deprecated/outdated:**
- `stow -a` short flag for `--adopt`: removed in 2.4.x (only long `--adopt` remains) [CITED: aspiers/stow NEWS]. Phase 1 must not use `--adopt` at all (Phase 2 gate); noted so no ported code references `-a`.
- `uname -a` parsing for distro ID: superseded by os-release + manager probing; keep `uname -o = Android` only as one Termux corroborating signal, not a primary.

## Assumptions Log

> Claims tagged `[ASSUMED]` — planner/discuss-phase must confirm or turn into verification tasks before they become locked decisions.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Derivative `ID`/`ID_LIKE` values: `manjaro`/`ID_LIKE=arch`, `endeavouros`/`ID_LIKE=arch`, `garuda`/`ID_LIKE includes arch`, `linuxmint`/`ID_LIKE="ubuntu debian"`, `pop`/`ID_LIKE="ubuntu debian"` | Architecture Patterns (Pattern 4) | Medium — an unlisted token falls to the manager-presence fallback, which still resolves correctly on real systems (pacman/apt present), so impact is limited to exotic chroots; mitigate with os-release fixture tests per derivative |
| A2 | `stow` package exists in Termux repos under the name `stow` (for the D-15 Termux upgrade path) | Package Audit, DEPS-02 | Medium — if absent, Termux stow-upgrade fails; mitigate: planner adds `pkg show stow`-style probe task with graceful "install stow manually" message |
| A3 | Termux package-name mapping: `neovim` (not `nvim`), no `uv`/`zoxide` renames assumed — names must be confirmed against Termux repos | Standard Stack, DEPS-02 | Medium — wrong names abort the Termux install; mitigate: planner tasks `pkg list-all \| grep` checks or a Termux tester run for each name in the termux table |
| A4 | `pacman -S --needed` / `apt install -y` on already-installed packages are safe no-ops (idempotency basis for DEPS-03) | DEPS-02/03 | Low — universally true in practice; the re-verify step independently proves the end state regardless |
| A5 | `mv` quarantine inside `$HOME` stays on one filesystem (atomic, fast) | Code Examples (quarantine) | Low — `$HOME` on one mount is the norm; cross-mount `mv` still works, just copies; no corrective action needed |
| A6 | Roadmap's "`ID=termux`" may exist on some Termux setups — treated as corroborating, never primary | Pitfall 5, Pattern 4 | Low — Pattern 4 checks the literal token anyway, so both worlds work |

## Open Questions

1. **Should `setup.sh` support `ID=termux` at all, or drop it?**
   - What we know: Termux detection via env/pkg/uname is the community-verified method; no stock Termux ships os-release `ID=termux` (upstream issue only proposed it).
   - What's unclear: whether the roadmap's parenthetical "(including `ID=termux` detection)" reflects a real Termux variant the user has seen.
   - Recommendation: keep the literal `termux)` token check (zero cost, Pattern 4) and ask the user in plan review only if they have a Termux image showing `ID=termux`; otherwise leave as-is.

2. **Which exact package names go in the Termux dep table?**
   - What we know: `pkg` wraps apt; no `sudo`; `keyd`/`hyprland`/`wofi` unavailable.
   - What's unclear: precise Termux repo names for `zoxide`, `uv`, `starship`, `neovim`, `stow`, `fzf`, `gum`/`whiptail` (A2/A3).
   - Recommendation: planner adds one task to resolve names via Termux package listing (or a Termux-holder run) before freezing the table; ship with best-effort names + clear per-package failure messages.

3. **Does `keyd` get stowed at all in Phase 1, or only listed?**
   - What we know: D-09 lists `keyd` as checklist-toggleable; privileged `-t /` safety is Phase 2 (STOW-02).
   - What's unclear: whether selecting `keyd` in Phase 1 performs a plain user-target stow, skips with "coming in Phase 2", or defers entirely.
   - Recommendation: planner picks the least-surprise option (recommend: allow plain `stow keyd` to `$HOME`-relative target only if the package maps there, else "keyd privileged install lands in Phase 2" notice) and records it as a plan decision for review.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Bash | `setup.sh` runtime | ✓ | 5.2.21 | — (>=4.4 needed for `inherit_errexit`) |
| GNU Stow | Deployment | ✓ (upgrade path will trigger) | 2.3.1 → auto-upgrade to ≥2.4.1 via apt | — |
| `apt` | debian-family installs | ✓ | system | — |
| `pacman` / `pkg` | arch / termux installs | ✗ (expected on Ubuntu) | — | Probed at runtime on target hosts, not here |
| `sudo` | Privileged installs | ✓ | system | Not used on Termux path |
| `git` | Zinit pin / repo ops (later) | ✓ | system | — |
| gum | Ladder rung 1 | ✗ | — | whiptail → dialog → fzf → read |
| whiptail | Ladder rung 2 | ✓ | 0.52.24 | — |
| dialog | Ladder rung 3 | ✗ | — | fzf → read |
| fzf | Ladder rung 4 | ✓ | 0.44.1 | `read` numbered fallback |
| `[[ -t 0 ]]`, `readlink -f`, `test -L` | TTY detect, post-verify | ✓ | coreutils/builtin | — (verified live) |

**Missing dependencies with no fallback:** none — every ladder rung degrades to `read`, and `pacman`/`pkg` are only needed on their native hosts.
**Missing dependencies with fallback:** `gum`, `dialog` (ladder covers); Stow 2.3.1 → self-upgrades per D-15.

## Security Domain

> `security_enforcement: true`, ASVS L1 (`security_asvs_level: 1`, block on `high`).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture/Secure Design | yes | Write-gating: interactive checklist + `--dry-run` before any mutation; no-TT​Y+incomplete = zero writes (D-06) |
| V2 Authentication | no | No credentials in Phase 1 (MISTRAL key/secret hygiene is out of scope per REQUIREMENTS v2) |
| V3 Session Management | no | No sessions |
| V4 Access Control | partial | `sudo` only via platform manager installs; **no `/etc` writes in Phase 1** — `keyd -t /` and `--adopt` deferred to Phase 2's STOW-02 gate |
| V5 Input Validation | yes | Strict allowlists: `--mode local\|server`, `--shell zsh\|nushell`, unknown flags abort; os-release values matched against token allowlist, never `eval`'d or interpolated into commands |
| V6 Cryptography | no | No crypto in Phase 1 |
| V10 Malicious Code / Supply chain | partial | No new downloads except platform packages; `stow` upgrade flows through signed platform repos |

### Known Threat Patterns for Bash-installer stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Destructive `rm -rf $var` with unset/empty var under path confusion | Tampering / DoS (data loss) | No `rm -rf` on `$HOME` targets at all — quarantine `mv` only; quote all expansions; `set -u` (already mandated) |
| `source /etc/os-release` code execution if file is attacker-controlled | Tampering | os-release is root-owned vendor file; additionally only `ID`/`ID_LIKE` are read and only allowlist-compared, never executed — document, do not `eval` |
| `sudo pacman/apt` installing trojaned packages on compromised mirror | Tampering | Platform-signed repos by default; out of scope beyond not adding custom mirrors/PPAs in Phase 1 |
| Checklist spoofing / prompt injection via crafted filenames | Spoofing | Checklist items are a hardcoded allowlist of 7 names, never directory listings |
| `--adopt` swallowing host files into repo (CONCERNS.md) | Tampering | Banned in Phase 1 entirely; Phase 2 gate (STOW-02) |

## Sources

### Primary (HIGH confidence — local tool + authoritative reference)
- On-host `stow 2.3.1` man page (`man stow`) — `--dir`/`--target` defaults, `--no` simulate, `--restow`, `--adopt` warning text
- On-host `os-release(5)` man page — `ID_LIKE` space-separated/optional/ordered-closest-first, ID→ID_LIKE fallback rule, shell-sourcable format
- Live lab experiments (2026-09-10, stow 2.3.1): folding (`.config → ../repo/starship/.config`), conflict error verbatim + exit 1, `${1-}`/`[[ -t 0 ]]` strict-mode guards, `command -v` probe results (Bash 5.2.21, whiptail 0.52.24, fzf 0.44.1, gum/dialog/pacman/pkg absent)
- In-repo sources read this session: `setup.zsh` (408 lines), `setup.nu` (193 lines), `teardown.zsh`, `.gitignore`, REQUIREMENTS.md, ROADMAP.md, CONTEXT.md, PROJECT.md, STATE.md, config.json, codebase/CONCERNS.md

### Secondary (MEDIUM confidence — web content cross-checked with official docs)
- man7.org os-release.5 + Arch/Debian/Ubuntu man pages — ID_LIKE semantics [CITED]
- GNU Stow 2.4.1 release notes (stow-devel Sep 2024) + aspiers/stow NEWS — 2.4.1 delta [CITED: https://lists.libreplanet.org/archive/html/stow-devel/2024-09/msg00000.html]
- Arch stow.8 (2.4.1) — folding/splitting/adopt semantics [CITED: https://man.archlinux.org/man/stow.8]
- Greg's Wiki BashFAQ/105 + BashPitfalls — `inherit_errexit`, `local`-masking, SIGPIPE+pipefail [CITED: https://mywiki.wooledge.org/BashFAQ/105]
- wick bash-strict-mode doc — `${1-}`/`${VAR:-}` guards [CITED: https://github.com/tests-always-included/wick/blob/master/doc/bash-strict-mode.md]
- Brandon Wie `set -e` + command substitution — `if ! VAR=$(cmd)` pattern [CITED]
- Termux Wiki package-management + termux-app#2165 + proot-distro detection — `pkg` semantics, no-`ID=termux` finding [CITED]
- gum tutorial/README + whiptail man — ladder commands, fd-swap, cancel semantics [CITED]
- Community distro-detection implementation (vmware_module_builder.py) corroborating the ID/ID_LIKE→family map shape [CITED]

### Tertiary (LOW confidence — training knowledge, flagged in Assumptions Log)
- Exact per-derivative `ID`/`ID_LIKE` strings (A1), Termux repo package names (A2/A3) — need host confirmation during planning/execution

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Bash/Stow/whiptail/fzf versions probed on host; no new packages introduced
- Architecture: HIGH — donor code fully read; probe order and stow semantics verified by experiment + man pages
- Pitfalls: HIGH — three pitfalls reproduced or directly observed (folding, unbound `$2` shape, conflict text); remainder cited from canonical Bash references
- Termux specifics: MEDIUM — strong community-source agreement, but no Termux host available to confirm package names (A2/A3) or os-release absence firsthand
- Derivative ID strings: MEDIUM — spec mechanism verified, exact per-distro strings assumed (A1)

**Research date:** 2026-09-10
**Valid until:** 2026-10-10 (stable domain — Bash/Stow/os-release move slowly; re-check only if Stow ≥2.5 or new Termux os-release lands)
