# Phase 01: Universal Installer + Platform Foundations - Pattern Map

**Mapped:** 2026-09-10
**Files analyzed:** 6 (1 create, 2 deletes, 3 edits)
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `setup.sh` (CREATE) | utility (installer entry-point) | batch + file-I/O | `setup.zsh` | exact |
| `setup.zsh` (DELETE) | utility (installer entry-point) | batch + file-I/O | self (donor, Bash-family) | exact |
| `setup.nu` (DELETE) | utility (installer entry-point) | batch + file-I/O | `setup.zsh` (sibling donor) | role-match |
| `.gitignore` (EDIT — add `.stow-conflicts/`) | config | file-I/O | `.gitignore` itself | exact |
| `README.md` (EDIT — atomic D-04 fix) | config (docs) | transform | `README.md` itself | exact |
| `nvim/.config/nvim/README.md` (EDIT — atomic D-04 check) | config (docs) | transform | `nvim/.config/nvim/README.md` itself | exact |

Reference-only (KEEP, not modified in Phase 1 — cited for shared patterns and Phase 2 `--uninstall`):
`teardown.zsh`, `teardown.nu`.

## Pattern Assignments

### `setup.sh` (CREATE — utility, batch + file-I/O)

**Analog:** `setup.zsh` (407 lines; primary Bash-family donor — port function-by-function, fixing 5 known defects). Secondary logic source: `setup.nu` where the Zsh path drifted.

**Strict-mode header + globals pattern** (`setup.zsh` lines 6-12):
```zsh
set -euo pipefail

DRY_RUN=false
MODE=""
STOW_KEYD=""

SCRIPT_NAME="${0:t}"
```
Copy: `set` line position (line 6, before everything), UPPER_SNAKE globals with `""`/`false` defaults, `SCRIPT_NAME` for usage. Fix for `setup.sh`: `set -Eeuo pipefail` + `shopt -s inherit_errexit` (Bash ≥4.4; RESEARCH Pattern 1), and `SCRIPT_NAME="$(basename -- "$0")"` — `${0:t}` is zsh-only. Never use `sh` shebang; must be `#!/usr/bin/env bash`.

**Arg-parsing + usage pattern** (`setup.zsh` lines 14-59):
```zsh
usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Zsh Dotfiles Bootstrapper

OPTIONS:
    --mode MODE          Deployment mode: 'local' (full GUI) or 'server' (headless)
    --dry-run           Show what would be done without making changes
    --stow-keyd Y/N     Whether to stow keyd configuration to /etc/keyd
...
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                MODE="$2"        # <-- DEFECT: unguarded $2, crashes under set -u
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --stow-keyd)
                STOW_KEYD="$2"   # <-- same defect
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}
```
Copy: `while [[ $# -gt 0 ]]` + `case` + heredoc `usage()` + unknown-flag → `usage; exit 1` before any prompt/write. Fix (D-08, RESEARCH Pattern 2): guard every consumption — `case "${1-}"`, `[[ $# -ge 2 ]] || { echo "Error: --mode needs local|server" >&2; usage >&2; exit 1; }`, add `--shell zsh|nushell`, `--help` wins anywhere, `--dry-run` boolean. `setup.nu` equivalent is `def main [--mode: string, --dry-run, --stow-keyd: string]` (`setup.nu` lines 3-7) — Nushell flag syntax, do NOT port literally.

**Distro detection pattern** (`setup.zsh` lines 61-68; `setup.nu` lines 54-62):
```zsh
get_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}
```
```nu
def get-distro [] {
    if ("/etc/os-release" | path exists) {
        let release_data = (open /etc/os-release | lines)
        let id_line = ($release_data | where { $in =~ "^ID=" } | first)
        let id = ($id_line | str replace "ID=" "" | str replace -a '"' "")
        return $id
    }
    return "unknown"
}
```
Copy: `/etc/os-release` → `ID` extraction shape and `"unknown"` fallback. Fix (DEPS-01, RESEARCH Pattern 4): this exact code is the defect being removed — replace with Termux-first 4-tier probe: ① `TERMUX_VERSION`/`PREFIX`*com.termux*/`command -v pkg` → `termux`; ② `command -v pacman`/`apt` presence; ③ space-split `ID_LIKE` token `case`; ④ `ID`. Hard-coded allowlist at `setup.zsh` lines 390-394 / `setup.nu` lines 22-26 must NOT be copied (see Shared Patterns).

**Dep-table pattern** (`setup.zsh` lines 74-105; `setup.nu` lines 77-93):
```zsh
get_deps() {
    local distro="$1"
    local mode="$2"

    local -a common=(
        "stow"
        "nvim"
        "starship"
        "git"
        "zoxide"
        "uv"
        "rg"
        "node"
        "npm"
    )

    local -a gui=()
    case "$distro" in
        arch|cachyos)
            gui=(hyprland alacritty wofi keyd waybar grim slurp wl-copy)
            ;;
        ubuntu)
            gui=(alacritty wofi waybar grim slurp wl-copy)
            ;;
    esac

    if [[ "$mode" == "local" ]]; then
        printf '%s\n' "${common[@]}" "${gui[@]}"
    else
        printf '%s\n' "${common[@]}"
    fi
}
```
Copy: `local distro="$1"` quoting, `local -a common=(...)` array syntax, `case "$distro"` GUI split, `local`+`server` branch returning `common` vs `common+gui`, `printf '%s\n'` emission. Fix (DEPS-02): families become `arch`/`debian`/`termux` (not `arch|cachyos`/`ubuntu`); `common` gains `make` `gcc` `fzf` `zsh`; `termux` table uses `pkg` names (A2/A3: `neovim` not `nvim`), no `sudo`, no `keyd`/`hyprland`/`wofi`. Note drift: `setup.nu` line 79 `common` is identical; `setup.zsh` vs `setup.nu` `run_stow` core modules drift (`[nvim zsh]` vs `[nvim nushell starship]`) — `setup.sh` checklist (D-09, 7 packages) supersedes both.

**Verify (missing-collection) pattern** (`setup.zsh` lines 70-72 + 107-128; `setup.nu` lines 95-105):
```zsh
verify_command() {
    command -v "$1" &>/dev/null
}
```
```zsh
verify_deps() {
    local deps=("$@")
    local -a missing=()
    local -a installed=()

    echo "\nVerifying dependencies..."
    for dep in "${deps[@]}"; do
        if ! verify_command "$dep"; then
            missing+=("$dep")
            echo "  - $dep (missing)"
        else
            installed+=("$dep")
            echo "  + $dep (installed)"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "\nMissing dependencies: ${missing[*]}"
    else
        echo "\nAll dependencies are satisfied."
    fi
}
```
```nu
def verify-deps [deps] {
    print "\nVerifying dependencies..."
    let missing = ($deps | where { (which $in | is-empty) })
    ...
}
```
Copy: `verify_command` probe (`command -v`, `&>/dev/null`), `missing+=` collection loop with `+ installed` / `- missing` per-dep echo, end-state summary. Extend (DEPS-02): partition into `core_missing` vs `gui_missing` (donor for the partition loop is `setup.zsh` lines 163-183 `install_deps_interactive` `case "$dep" in stow|nvim|...` — copy that `case` shape), then re-verify after install and abort `Still missing: …` on residue. Bash equivalent of `which`-probe is `command -v` — never `which`.

**Install pattern** (`setup.zsh` lines 130-161; `setup.nu` lines 107-128):
```zsh
install_deps() {
    local distro="$1"
    local -a missing=("$@")     # NOTE: $1 leaks into missing (argv bug — do not copy literally; shift first)

    local -a install_cmd=()
    case "$distro" in
        arch|cachyos)
            install_cmd=(sudo pacman -S --needed)
            ;;
        ubuntu)
            install_cmd=(sudo apt install -y)
            ;;
        *)
            echo "Unsupported distro for auto-install."
            exit 1
            ;;
    esac

    echo "\nReady to install: ${missing[*]}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"
        return
    fi

    read -q "REPLY?Proceed with installation? (y/n): "   # <-- zsh-only; Bash needs read -r -p
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed "${missing[@]}"          # <-- BUG: hard-codes pacman, ignores install_cmd/apt
    else
        echo "Skipping installation."
    fi
}
```
Copy: `install_cmd` array per-family + `"${install_cmd[*]} ${missing[*]}"` DRY_RUN echo + early `return` before any mutation. Fix: 3-branch `case` (`sudo pacman -S --needed --noconfirm` / `sudo apt install -y` / `pkg install -y`, no `sudo` on Termux), execute via `"${install_cmd[@]}" "${missing[@]}"` (not hard-coded pacman), `read -r -p "… " -n 1` in Bash, `stow` self-upgrade (`< 2.4.1` via `sort -V`) flows through the same lock (D-15). `setup.nu` lines 115-126 add the `stow`-critical abort (`if ("stow" in $missing)`) — preserve that semantic in the re-verify abort.

**Interactive-menu + TTY-gate pattern** (`setup.zsh` lines 163-273, excerpts lines 204-224 + 291-304):
```zsh
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "\n[DRY RUN] Skipping interactive installation prompt."
        ...
        return 0
    fi

    if [[ ! -t 0 ]]; then
        echo "\nNon-interactive terminal detected. Installing core deps automatically..."
        ...
        return 0
    fi
```
```zsh
get_mode_interactive() {
    echo "\nSelect Deployment Mode:"
    echo "1. Local Mode (Full setup including GUI: Hyprland, Alacritty, keyd, etc.)"
    echo "2. Server Mode (Headless setup: Nvim, Zsh, Starship only)"

    while true; do
        read "REPLY?Enter choice (1 or 2): "    # <-- zsh syntax; Bash: read -r -p
        case "$REPLY" in
            1) echo "local" && return ;;
            2) echo "server" && return ;;
            *) echo "Invalid choice. Please enter 1 or 2." ;;
        esac
    done
}
```
Copy: `[[ "$DRY_RUN" == "true" ]]` early-return before prompts, `[[ ! -t 0 ]]` non-interactive branch, numbered `1/2` + `while true` + `case` menu shape, `echo` label lines. Fix: Bash `read -r -p "Enter choice (1 or 2): " REPLY`; D-05/D-06/D-07 semantics — bare TTY run prompts (mode → shell → checklist), no-TTY + incomplete flags aborts with usage + non-zero and zero writes, partial flags keep given values and only fill gaps. Ladder backends themselves (`gum→whiptail→dialog→fzf→read`) have NO analog — see No Analog Found.

**Stow orchestration pattern** (`setup.zsh` lines 306-370; `setup.nu` lines 130-193):
```zsh
run_stow() {
    local mode="$1"
    local stow_keyd_arg="${2:-}"     # <-- ${var:-} default pattern: copy everywhere under set -u

    echo "\nStarting deployment (GNU Stow)..."

    local -a core_modules=(nvim zsh)
    local -a gui_modules=(hyprland alacritty wofi)
    ...
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "   [DRY RUN] Would run: stow --restow $module"
        else
            stow --restow "$module"
        fi
}
```
```zsh
stow_module() {
    local module="$1"
    echo " - Processing $module..."

    local target="$HOME/.config/$module"

    if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
        echo "   ! WARNING: $target is a real file/folder."
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "   [DRY RUN] Would delete: rm -rf $target"
        else
            rm -rf "$target"     # <-- DEFECT: replaced by quarantine mv (D-13); never copy
            echo "   Deleted: $target"
        fi
    fi
    ...
}
```
```nu
    let stow_cmd = if $dry_run { ["stow" "--no" "-v" "--restow" $module] } else { ["stow" "--restow" $module] }
```
Copy: `run_stow`/`stow_module` split, `" - Processing $module..."` log line, `[[ -e && ! -L ]]` collision test, `[DRY RUN] Would run:` prefix, `stow --restow`, `${2:-}` optional-arg guard, `setup.nu` line 191 `stow --no -v` preview flag. Fix (STOW-01/D-13): `stow --dir="$SCRIPT_DIR" --target="$HOME"` (never CWD-relative, never default target), `stow --no --verbose` dry-run preview of the exact post-checklist selection, collision → quarantine `mv` to `.stow-conflicts/<ts>/` + `MANIFEST` (never `rm -rf`, never `--adopt` in Phase 1). `keyd` privileged `-t /` path is Phase 2 — Phase 1 only lists `keyd` in the checklist (RESEARCH OQ-3).

**Main-sequence pattern** (`setup.zsh` lines 372-406; `setup.nu` lines 3-52):
```zsh
main() {
    parse_args "$@"

    if [[ -z "$MODE" ]]; then
        MODE=$(get_mode_interactive)
    fi

    echo "Starting Zsh Bootstrapper..."
    echo "Detected distribution: $(get_distro)"
    echo "Selected mode: $MODE"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "=== DRY RUN MODE: No changes will be applied ==="
    fi

    local distro
    distro=$(get_distro)

    if [[ "$distro" != "arch" && "$distro" != "cachyos" && "$distro" != "ubuntu" ]]; then
        echo "Error: This script only supports Arch Linux (CachyOS) and Ubuntu."
        echo "Please refer to README.md for manual installation instructions."
        exit 1
    fi

    echo "OS validation passed."

    local -a deps
    deps=($(get_deps "$distro" "$MODE"))

    verify_deps "${deps[@]}"

    install_deps_interactive "$distro" "${deps[@]}"

    run_stow "$MODE" "$STOW_KEYD"
}

main "$@"
```
Copy: `parse_args "$@"` first, interactive fallback for empty flags, `Starting …` / `Detected distribution:` / `Selected mode:` / `=== DRY RUN MODE ===` banner order, `OS validation passed.`, `deps → verify → install → run_stow` sequence, `main "$@"` invocation. Fix: `local distro; distro=$(...)` split (never `local x=$(fallible)` — masks exit status under `set -e`), allowlist → `detect_family` with manual-install message + non-zero exit, insert `verify → install → re-verify` lock + mode → shell → checklist gating + repo-root guard + `post_verify` per RESEARCH §Architecture diagram; `deps=($(...))` word-splitting is acceptable here (newline-delimited package names) but `mapfile -t` is safer.

---

### `.gitignore` (EDIT — config, file-I/O)

**Analog:** `.gitignore` itself (11 lines).

**Entry + comment pattern** (lines 1-11):
```gitignore
nushell/.config/nushell/history.txt
nushell/.config/nushell/history.json

# Neovim
nvim/.config/nvim/lazy-lock.json
nvim/.config/nvim/.neoconf.json
nvim/.config/nvim/undo/
nvim/.config/nvim/shada/
nvim/.config/nvim/state/
nvim/.config/nvim/cache/
*.swp
```
Copy: bare relative paths (no leading `/`), trailing `/` for directories, `# Section` comment headers, blank line between groups, machine-generated/state entries only. Phase 1 edit: append a `# Installer quarantine` group with `.stow-conflicts/` (trailing slash, D-14). Keep 4-space-free, LF, final newline. Do NOT touch the `history.*` or `nvim/` entries.

---

### `README.md` (EDIT — config/docs, transform)

**Analog:** `README.md` itself (187 lines).

**Shell-path table pattern** (lines 9-15):
```markdown
| Feature | Nushell Path | Zsh Path |
|---------|-------------|----------|
| Shell | Nushell | Zsh + Zinit |
| Prompt | Starship | Powerlevel10k |
| Setup | Auto (`nu setup.nu`) | Auto (`zsh setup.zsh`) |
```
Copy: pipe-table shape with `| Feature | … |` header. Phase 1 rewrite target (D-04/DOCS-01 direction, planner to finalize wording): `Default: Zsh | Backup: Nushell`, primary example `bash setup.sh --mode local`.

**Bootstrapper-run pattern** (lines 35-49 Nushell; lines 101-115 Zsh):
```markdown
### 3. Run the Bootstrapper
Clone this repository and run:
```bash
nu setup.nu
```

**Options:**
- `--mode`: Select `local` (Full GUI) or `server` (Headless CLI).
- `--dry-run`: Preview changes without applying them.
- `--stow-keyd`: Pass `y` or `n` to automate the privileged `keyd` setup.
```
Copy: `### 3. Run the Bootstrapper` heading level, `Clone this repository and run:` lead-in, ` ```bash ` fence, `**Options:**` bullet list (`--mode`/`--dry-run`/`--stow-keyd` backticked flags). Phase 1: replace `nu setup.nu` / `zsh setup.zsh` blocks with `bash setup.sh` equivalents (add `--shell`, keep `--mode`/`--dry-run`; `--stow-keyd` is Phase 2 scope — planner decides listing vs deferral note).

**Manual-stow pattern** (lines 61-70; lines 144-153):
```bash
stow --restow nvim nushell starship
```
```bash
stow --restow hyprland alacritty wofi
```
```bash
stow --restow nvim zsh
```
Copy: `stow --restow <space-separated packages>` one-liners in `bash` fences under `#### Deploy Configurations` / `Use GNU Stow to symlink the configurations:`. Post-edit target set: `stow --restow nvim zsh starship` (Zsh-default) vs `nvim nushell starship` manual sections.

**Keyd privileged pattern** (lines 72-76; lines 155-159 — reference only, Phase 2 owns the gate):
```bash
sudo stow --adopt -t / keyd
sudo keyd reload
```
Do NOT promote `--adopt` in Phase 1 docs (banned Phase 1; STOW-02 gate in Phase 2).

---

### `nvim/.config/nvim/README.md` (EDIT — config/docs, transform)

**Analog:** itself (27 lines). No `setup.nu`/`setup.zsh` references exist in it today (verified: file covers `required packages` + `mv ~/.config/nvim ~/.config/nvim.bak` + clone + Acknowledgments, lines 6-27):
```markdown
#### required packages

```
neovim python3-pip gcc make nodejs wl-clipboard luarocks tree-sitter-cli
```
```
D-04 requires auditing it in the same commit: if no dangling pointer exists, leave content untouched (record as verified-no-op in the plan); if the planner finds one, apply the same `bash setup.sh` rewrite pattern as root `README.md`. Its `####`-level headings and bare-fence package list are the local style to preserve.

---

### `setup.zsh` + `setup.nu` (DELETEs — utility, batch + file-I/O)

No pattern to copy — deletion targets (D-02/D-03: outright delete, no shims, recoverable via git). Planner notes: the delete and the atomic README/comment fix ride in ONE commit (D-04); `teardown.zsh`/`teardown.nu` survive until Phase 2 and must keep working (they call plain `stow -D <module>` from repo root — quarantine must not move anything they need; RESEARCH §Project Constraints).

## Shared Patterns

### Strict mode + globals (apply to: `setup.sh`)
**Source:** `setup.zsh` lines 6-12 (fix per RESEARCH Pattern 1).
```zsh
set -euo pipefail
DRY_RUN=false
MODE=""
STOW_KEYD=""
```
`setup.sh` form: `set -Eeuo pipefail` + `shopt -s inherit_errexit` + `DRY_RUN=false MODE="" SHELL_CHOICE="" STOW_KEYD=""` + `SCRIPT_DIR` from `BASH_SOURCE` (no analog in repo — new). All expansions quoted; `${1-}`/`${2:-}` guards under `set -u`.

### Arg parsing: usage-heredoc + unknown-abort (apply to: `setup.sh`)
**Source:** `setup.zsh` lines 14-59 + `teardown.zsh` lines 14-54 (same shape).
```zsh
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
```
`--help` exits 0 and changes nothing; unknown flags print usage + exit non-zero BEFORE any prompt/write (D-08).

### Missing-collection before action (apply to: `setup.sh` verify/install)
**Source:** `setup.zsh` lines 107-128; `setup.nu` lines 95-105.
Collect the full `missing` list first, report it, then act — never install inside the probe loop.

### DRY_RUN early-return before every mutation (apply to: `setup.sh` all write paths)
**Source:** `setup.zsh` lines 149-152, 204-213, 335-342, 357-367; `setup.nu` lines 15, 115-121, 155-157, 183-192; `teardown.zsh` lines 95-100, 126-134, 146-151.
```zsh
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"
        return
    fi
```
Banner `=== DRY RUN MODE: No changes will be applied ===` (`setup.zsh` lines 383-385; `setup.nu` line 15) prints once at startup; every mutating function re-guards. Preview commands: installs echo the exact argv; stow uses `stow --no --verbose`.

### Step logging (apply to: `setup.sh`)
**Source:** `setup.zsh` lines 379-381 (`Starting Zsh Bootstrapper…` / `Detected distribution:` / `Selected mode:`); `setup.nu` lines 17, 20, 39, 42 (`Starting Unified Bootstrapper…`, `$"Detected distribution: ($distro)"`); `teardown.zsh` line 161 / `teardown.nu` line 27 (`⚠️  WARNING: Starting Teardown Process ⚠️`).
Plain `echo`/`print` per step, `  -`/`  +` per-dep lines, `✓`/`!` per-module lines (`teardown.zsh` lines 129-133). No log framework. Never log secret values.

### Typed-`yes` confirmation (apply to: Phase 2 `--uninstall` only — reference, NOT Phase 1 behavior)
**Source:** `teardown.zsh` lines 161-169; `teardown.nu` lines 27-41.
```zsh
    read "REPLY?Are you sure you want to continue? Type 'yes' to confirm: "
    if [[ "$REPLY" != "yes" ]]; then
        echo "Teardown cancelled."
        exit 0
    fi
```
```nu
    let confirm = if $dry_run {
        "n"
    } else {
        input "Are you sure you want to continue? Type 'yes' to confirm: "
    }

    if ($confirm != "yes") {
        print "Teardown cancelled."
        exit 0
    }
```
Exact-`yes` match, `dry_run` bypasses to cancel-path, anything else aborts with `Teardown cancelled.` + exit 0. Phase 1 only needs staged-delete awareness; copy this verbatim for Phase 2 `--uninstall` (+ `--yes` CI bypass).

### Stow deploy/undeploy verbs (apply to: `setup.sh` deploy; teardowns stay canonical for remove until Phase 2)
**Source:** `setup.zsh` line 368 (`stow --restow "$module"`); `setup.nu` line 191-192 (`stow --no -v --restow` preview); `teardown.zsh` lines 122-135 (`stow -D "$module"` with `2>/dev/null` + non-zero warning); `teardown.nu` lines 120-139 (`complete` + `exit_code` check).
```zsh
    if stow -D "$module" 2>/dev/null; then
        echo "   ✓ $module unstowed successfully"
    else
        echo "   ! Warning: stow returned non-zero exit code for $module"
    fi
```
Phase 1 deploy upgrades to `stow --dir="$SCRIPT_DIR" --target="$HOME" --restow <selected…>`; `keyd` privileged `sudo stow --adopt -t / keyd` (`setup.zsh` lines 339-341; `setup.nu` lines 159-161) is BANNED in Phase 1.

### Error handling: guard + early exit (apply to: `setup.sh`)
**Source:** `setup.zsh` lines 390-394; `setup.nu` lines 22-26; `teardown.zsh` lines 48-52.
```zsh
    if [[ "$distro" != "arch" && "$distro" != "cachyos" && "$distro" != "ubuntu" ]]; then
        echo "Error: This script only supports Arch Linux (CachyOS) and Ubuntu."
        echo "Please refer to README.md for manual installation instructions."
        exit 1
    fi
```
`Error: …` to stdout (existing style) + manual-install pointer + `exit 1`. Keep the shape; replace the hard-coded predicate with `detect_family` failure (derivatives + Termux resolve instead of erroring).

## No Analog Found

| File / Capability | Role | Data Flow | Reason |
|-------------------|------|-----------|--------|
| `setup.sh` checklist ladder `gum → whiptail → dialog → fzf → read` (D-09…D-12) | utility | request-response (TTY) | No ladder code exists in repo (grep: zero hits for `gum`/`whiptail`/`dialog`/`SCRIPT_DIR`/`BASH_SOURCE` outside `.planning/`; only `fzf` hits are nvim telescope + zsh wiring). Planner must use RESEARCH.md Patterns 5-6 (`whiptail --checklist` fd-swap `3>&1 1>&2 2>&3`; `gum choose --no-limit`; `fzf -m`; `read` numbered fallback) + disabled-row emulation (OFF + reason tag + post-strip/validate, Termux `keyd`/`hyprland`/`wofi` never selectable). |
| `setup.sh` Termux-aware `detect_family` | utility | batch | Donors only do `source /etc/os-release; echo $ID`. Tier-1 Termux probes (`TERMUX_VERSION`/`PREFIX`/`command -v pkg`/`uname -o = Android`) + `ID_LIKE` token split + manager fallback exist only in RESEARCH.md Pattern 4. |
| `setup.sh` quarantine `.stow-conflicts/<ts>/` + `MANIFEST` + restore hint (D-13/D-14) | utility | file-I/O | Inverts the only existing conflict pattern (`rm -rf "$target"`, `setup.zsh` line 360 / `setup.nu` line 186 — explicitly banned). `mv` + `MANIFEST` shape comes from RESEARCH.md Code Examples only. |
| `setup.sh` strict post-verify `test -e` + `readlink -f` prefix-match incl. folding (D-16) | utility | file-I/O | No `readlink`/`test -L` verification exists in repo. Use RESEARCH.md `assert_linked()` (folded dir-link vs unfolded file-link agnostic; abort with link → expected-target report). |
| `setup.sh` repo-root guard + `SCRIPT_DIR` resolve | utility | file-I/O | Donors are CWD-relative (`stow --restow`, `$PWD/$module` in `teardown.zsh` line 139). `BASH_SOURCE` resolve + `[[ -f "$SCRIPT_DIR/setup.sh" ]]` abort is RESEARCH Pattern 1 only. |
| `setup.sh` stow self-upgrade `< 2.4.1` via `sort -V` (D-15) | utility | batch | No version-compare code in repo. Use RESEARCH.md `sort -V` idiom (never lexicographic `>`). |
| `setup.sh` no-TTY + partial-flag gating (D-06/D-07) | utility | request-response | `[[ ! -t 0 ]]` appears only in `setup.zsh` lines 215-224 (auto-install-core variant). Abort-with-usage + zero-writes on no-TTY/incomplete, keep-given-flags semantics are new. |
| `setup.sh` `--shell` preselection → checklist defaults (D-11) | utility | request-response | No shell-choice prompt exists in donors (each script IS its shell path). New logic: pre-check chosen shell, uncheck other, user-overridable. |

## Metadata

**Analog search scope:** repo root (`*.zsh`/`*.nu`), `.gitignore`, `README.md`, `nvim/.config/nvim/README.md`; grep over full repo for `setup.*|teardown.*`, `gum|whiptail|dialog|fzf|stow-conflicts|quarantine|MANIFEST|readlink|inherit_errexit|BASH_SOURCE|SCRIPT_DIR`.
**Files scanned:** 4 donor scripts read fully (`setup.zsh` 408 lines, `setup.nu` 193 lines, `teardown.zsh` 185 lines, `teardown.nu` 155 lines) + 3 edited-file targets read fully + 1 phase directory listing; grep returned 100+ hits (all `setup.*` references are docs/planning, no hidden installer analogs).
**Pattern extraction date:** 2026-09-10
**Conventions observed:** 4-space indent, `snake_case` funcs / UPPER_SNAKE globals in Zsh donors, `local var="$1"` quoting, `local -a` arrays, heredoc `usage()`, `set -euo pipefail`, `[DRY RUN] Would run:` prefix, `✓`/`!` per-module status, `# Section` gitignore headers, pipe-table + `stow --restow` one-liners in README. Bash port must swap zsh-only syntax (`${0:t}`, `read -q`, `read "REPLY?…"`) for Bash equivalents (`basename`, `read -r -p … -n 1`).
