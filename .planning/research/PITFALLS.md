# Pitfalls Research — Dotfiles Bootstrapper & Unified Bash Installer

**Domain:** Stow-based dotfiles bootstrappers, unified Bash installer, Neovim/Zsh reliability hardening  
**Researched:** 2026-09-10  
**Confidence:** HIGH (GNU Stow, Bash strict-mode, Mason headless, distro ID_LIKE — validated against live repo + manuals + host probes), MEDIUM (TUI ladder nuances, fzf version drift policy, theme centralization)  
**Context:** Replaces mirrored `setup.nu`/`setup.zsh`+`teardown.*` with canonical `bash setup.sh` (`--install`/`--uninstall`/`--dry-run`/`--self-test`), handles `local` vs `server`, `zsh` default/`nushell` backup, TUI package override before any write, privileged `keyd -t /`, Neovim `lazy.nvim+Mason` auto-install, Zsh `Ctrl+R` fzf history, machine-local gitignored overlays, reversal parity.

---

## Critical Pitfalls

### Pitfall 1: Bash Strict-Mode Crash — `set -euo pipefail` + `inherit_errexit` Silent Aborts

**What goes wrong:**
Unified installer crashes before `--help` renders, or dies mid-`install_deps` on an innocuous `grep … | head -1` SIGPIPE 141, or aborts on `${1}` with `unbound variable` when a flag has no value. Fresh user runs `bash setup.sh --dry-run` on CachyOS and gets `setup.sh: line 44: $1: unbound variable` instead of a preview. Because `set -e` is ignored inside `if`/`while`/`&&`/`||` and inside `$( )`, partial failures are masked until `pipefail` flips them, then `yes | head -1` return code 141 trips `errexit` even though the pipeline succeeded semantically.

**Why it happens:**
`set -euo pipefail` is copy-pasted from blogs without `inherit_errexit`/`failglob`/`extglob` companions and without `${var-}` / `${1-}` guards. Arch BBS (`set -euo pipefail is not recommended in any way`) and BashFAQ 105 explicitly warn `errexit` does not propagate into subshells without `shopt -s inherit_errexit`, and `pipefail` turns harmless SIGPIPE into a fatal error. Installer authors also write `while [[ $# -gt 0 ]]; do case $1 in …` which violates `nounset`, and use `source /etc/os-release` without `[[ -f … ]]` guard (containers have no file).

**How to avoid:**
Use the **Bash Coding Standard full preamble** and lint every change:
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit failglob extglob nullglob shift_verbose
IFS=$'\n\t'
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
```
Arg parsing must use `${1-}` / `${2-}`:
```bash
while [[ $# -gt 0 ]]; do case "${1-}" in
  --mode) MODE="${2-}"; shift 2 ;;
  --dry-run) DRY_RUN=true; shift ;;
  *) die "Unknown: ${1-}" ;;
esac; done
```
Guard intentional SIGPIPE: `yes | head -n1 || true`, or `trap '' PIPE` for pager flows. Check `PIPESTATUS` where the first stage matters. Run `shellcheck -S warning setup.sh` and `shfmt -i 4 -ci -w setup.sh` in pre-commit and `--self-test`.

**Warning signs:**
- `shellcheck` SC2086/SC2154/SC2181 fires on any `$var` or `$1` without `${var:-}`/`${1-}`.
- Manual test `bash -x setup.sh --help 2>&1 | head` shows `+ set -e` then immediate exit with `unbound variable` before usage prints.
- `bash setup.sh --mode server 2>&1; echo $?` returns 141 instead of 0/1.
- CI flake: passes on Ubuntu (bash 5.2.21) but fails on Arch live ISO if `inherit_errexit` missing.

**Phase to address:** Phase 1 — Installer Foundation & Safe Flags. This is the first gate; every later phase depends on a non-crashing entry-point. Add `test: strict-mode` Bats case that runs every flag permutation under `set -u`.

---

### Pitfall 2: Distro Allowlist Rejects Derivatives — `["arch","cachyos","ubuntu"]` Hard-Code

**What goes wrong:**
User on Manjaro (`ID=manjaro ID_LIKE=arch`), EndeavourOS (`ID=endeavouros ID_LIKE=arch`), Mint (`ID=linuxmint ID_LIKE=ubuntu`), Pop!_OS (`ID=pop ID_LIKE=ubuntu debian`) or Garuda/Arco hits `Error: This script only supports Arch/CachyOS/Ubuntu` and falls back to manual `stow` per README, bypassing all validation, `verify-deps`, `make`→`telescope-fzf-native`, and `keyd` confirmation. Auto-install never begins — the exact crash reported in `CONCERNS.md`.

**Why it happens:**
`get-distro` / `get_distro` branches on literal `ID` equality against a three-element allowlist (`setup.nu: get-distro`, `setup.zsh: get_distro`) and maps `get-deps` per ID. It never reads `ID_LIKE` (systemd `os-release(5)` space-separated) and never probes `command -v pacman`/`apt-get` capability. Arch-family all share `pacman`; Debian-family all share `apt`. The mapping treats `arch` vs `cachyos` as distinct despite identical `pacman -S`.

**How to avoid:**
Canonical probe — **package-manager capability first, `ID_LIKE` second, `ID` third** (per `man os-release(5)` example `if [ "${ID_LIKE#*debian*}" != "${ID_LIKE}" ]`):
```bash
get_distro() {
  local id="" id_like=""
  [[ -f /etc/os-release ]] && source /etc/os-release
  id="${ID:-}"; id_like="${ID_LIKE:-}"; id="${id,,}"; id_like="${id_like,,}"
  if command -v pacman &>/dev/null; then echo "arch"; return; fi
  if command -v apt-get &>/dev/null || command -v apt &>/dev/null; then echo "debian"; return; fi
  if [[ " $id_like " == *" arch "* ]] || [[ "$id" == "manjaro" || "$id" == "endeavouros" || "$id" == "garuda" ]]; then echo "arch"; return; fi
  if [[ " $id_like " == *" debian "* || " $id_like " == *" ubuntu "* ]] || [[ "$id" == "linuxmint" || "$id" == "pop" ]]; then echo "debian"; return; fi
  echo "unknown"
}
```
Map `get_deps` to families (`arch` vs `debian`), not IDs. Treat `unknown` only after both probes fail; then print manual `stow` hint. Normalize to lowercase. Add explicit test matrix: `ID=manjaro ID_LIKE=arch command -v pacman` → arch, `ID=linuxmint ID_LIKE=ubuntu` → debian.

**Warning signs:**
- Bug report: "derivative rejected" before any package list prints.
- `grep -R 'arch.*cachyos.*ubuntu' setup.*` still exists.
- `get_distro` test with `ID=manjaro` returns `unknown` in `--dry-run` log.
- Stale README table listing only three distros while `get-deps` branches on `cachyos` vs `arch` identically.

**Phase to address:** Phase 1 — Installer Foundation (same as strict-mode; both are entry-point crashes). Must ship before any TUI or stow work. Verify via Bats mock: `env ID=manjaro ID_LIKE=arch bash -c 'source setup.sh; get_distro'` → `arch`.

---

### Pitfall 3: Manual Package Override Stage Missing — `Mode → Shell` Jumps Straight to Writes

**What goes wrong:**
Installer prompts `mode` (`local` full GUI vs `server` headless) then `shell` (`zsh` default / `nushell` backup) and immediately runs `pacman -S` + `stow --restow`. User has no chance to deselect `keyd` (privileged `/etc`), `hyprland` on a server, or `nvim` when they only wanted `zsh`+`starship`. Server users accidentally pull `hyprland`+`waybar`+`grim`/`slurp`/`wl-copy`; headless CI pulls GUI deps and fails on missing `wl-clipboard`. No preview of the final module list until `stow` conflicts appear. This violates PROJECT.md flow `mode → shell → build package list → show select/deselect package override checklist (manual override before any writes) → execute`.

**Why it happens:**
Original `setup.nu`/`setup.zsh` hard-code `core=[nvim,nushell,starship]` vs `[nvim,zsh]` and `gui_modules` arrays and go straight to `run-stow`. Cost of adding a TUI checklist (gum/whiptail/fzf branching, ON/OFF pre-check, parsing quoted tags, handling non-TTY `! -t 0`) feels optional, so the checklist is deferred and never lands. Even when implemented, developers place it *after* `install_deps`, so package installs already wrote to disk before the user could veto.

**How to avoid:**
Enforce **TUI runs before any write** as a safety invariant (PROJECT.md `Safety: No destructive writes without preview/confirmation`). Flow per `ARCHITECTURE.md`:
```
get_distro → get_deps (candidate lists)
→ prompt_mode (if not --mode)
→ prompt_shell (if not --shell)
→ build_package_list(mode,shell) → "pkg ON/OFF" lines
→ tui_checklist(candidate) → selected set   # <-- before install/stow
→ install_deps(selected)
→ setup_shell(selected)
→ run_stow(selected)
```
Implement ladder: `gum choose --no-limit --header --selected` (primary) → `whiptail --checklist … 3>&1 1>&2 2>&3` → `dialog` → `fzf --multi` → plain `read -p "numbers or 'all'"`. Skip gracefully when `--yes` or `[[ ! -t 0 ]]` (use ON defaults). Persist `echo "$MODE" > ~/.config/dotfiles/mode` so `zsh/.zprofile` Hyprland guard can read it. Always show `[DRY RUN] Would stow: nvim zsh …` before mutate.

**Warning signs:**
- Dry-run log shows `pacman -S` before any checklist output.
- User bug: "I ran `--mode server` and it tried to install hyprland."
- Code review: `install_deps` called before `tui_checklist` in call graph.
- No `--separate-output` or `tr -d '"'` parsing anywhere (means checklist output not handled).

**Phase to address:** Phase 2 — Dependency Resolution & TUI Checklist Ladder. Must complete before Stow Orchestration. Verification: `bash setup.sh --dry-run` shows checklist first, and non-TTY `echo | bash setup.sh --mode server --shell zsh` uses ON defaults without hanging.

---

### Pitfall 4: Whiptail/Dialog Checklist fd Swap & Exit-Code Mis-handling

**What goes wrong:**
Checklist appears, user presses SPACE to toggle and ENTER to confirm, but `selected=$(whiptail --checklist …)` captures empty string; installer either proceeds with zero packages (no-op) or crashes under `set -u` on empty array `selected=()`. Pressing ESC or Cancel (exit code 255/1) is treated as "no selection" rather than abort, so the script continues to install deps for an empty set. With `set -euo pipefail`, the failing `whiptail` line triggers `errexit` and kills the installer with no error message, or the `3>&1 1>&2 2>&3` swap is omitted and the checklist renders but output goes to terminal, not the variable.

**Why it happens:**
Whiptail writes the chosen tags to **stderr**, not stdout (Ubuntu man `whiptail(8)`, cdocsa cheat-sheet). Capturing requires the non-obvious fd swap `3>&1 1>&2 2>&3` (save stdout→fd3, redirect stdout→stderr, then stderr→stdout for `$()` capture). Dialog uses the same convention; gum does not. The swap must be on the same command that produces output, not a wrapper. Exit codes are `0=OK`, `1=Cancel/No`, `255=ESC/error` (Debian trixie `-1`, Ubuntu `255` — distro varies), and checklist output is quoted `"nvim" "zsh"` by default unless `--separate-output` is passed (one tag per line, no quotes). Newcomers forget `|| true` after `whiptail … 3>&1 1>&2 2>&3` so `set -e` kills on Cancel.

**How to avoid:**
Canonical checklist wrapper (from STACK.md, whiptail man, Shell TUI cheat-sheet):
```bash
tui_checklist() {
  local -a names=() defaults=() # built from "pkg ON/OFF" stdin
  # … populate names/defaults …
  if command -v gum &>/dev/null && [[ -t 0 ]]; then
    printf '%s\n' "${names[@]}" | gum choose --no-limit --header "Select (Space toggle)" --height 14
    return
  fi
  if command -v whiptail &>/dev/null && [[ -t 0 ]]; then
    local -a args=(); for i in "${!names[@]}"; do args+=("${names[$i]}" "${names[$i]}" "${defaults[$i]}"); done
    local out; out="$(whiptail --title Packages --checklist "Space to toggle, Enter to confirm:" 20 78 10 "${args[@]}" 3>&1 1>&2 2>&3)" || true
    local rc=$?
    if (( rc == 255 || rc == 1 )); then echo "CANCELLED:$rc" >&2; return 1; fi
    echo "$out" | tr -d '"' | tr ' ' '\n' | grep -v '^$' || true
    return
  fi
  # Or with --separate-output: whiptail --separate-output --checklist … 3>&1 1>&2 2>&3 → one per line, no tr -d needed
}
```
Rules: always `|| true` after whiptail under `set -e`; always handle `1` and `255` as abort (ask confirm); prefer `--separate-output` to avoid quote stripping; when using `3>&1 1>&2 2>&3` keep it inside `$()` capture, not a temp var split. Alternative `exec 3>&1; result=$(whiptail … 2>&1 1>&3); rc=$?; exec 3>&-` pattern also works but swaps differently.

**Warning signs:**
- `grep -n whiptail setup.sh` shows no `3>&1` — output is not captured.
- `whiptail --checklist …; echo "selected=$selected"` prints empty after user pressed OK.
- Cancel/ESC proceeds to `stow` instead of aborting; `--dry-run` does a real install after ESC.
- `shellcheck` SC2091/SC2086 on quoted checklist parsing; `selected` contains `"` characters.
- Host `fzf 0.44.1` but whiptail branch never tested (whiptail path only exercised on fresh Ubuntu).

**Phase to address:** Phase 2 — TUI Ladder (same as override stage; both are the checklist implementation). Gate: Bats mock of `whiptail` that writes to stderr and exits 0/1/255; assert array parsing and `set -e` survival.

---

### Pitfall 5: Stow `--adopt` Repo Pollution & Privileged `/etc/keyd` Overwrite — Silent Data Loss

**What goes wrong:**
`sudo stow --adopt -t / keyd` silently moves the live host file `/etc/keyd/default.conf` into the repo (`keyd/etc/keyd/default.conf`), overwriting the committed `default.conf` with whatever was on the machine (often an old or locally-edited version). `git status` now shows a dirty diff that looks intentional; the next `git commit` permanently replaces the repo's keyd config with the host's file, and every other clone pulls the polluted version. If the host file was malicious or had a syntax error, `sudo keyd reload` applies it system-wide and breaks input (keyd handles all keystrokes). Unstow is ambiguous: `--adopt` moves are not reversible by `stow -D`; rollback requires knowing what was moved.

**Why it happens:**
GNU Stow manual (HIGH) explicitly warns: "`--adopt` Warning! This behaviour is specifically intended to alter the contents of your stow directory. If you do not want that, this option is not for you." It exists to import existing dotfiles into a new stow package, not to deploy an existing package onto a host with conflicts. Original `setup.nu:run-stow` / `setup.zsh:run_stow` call `--adopt` unconditionally for `keyd` with only a dry-run preview, no conflict gate, no `diff`, no `gum confirm`. Sudoers suggestion `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd` widens privilege incorrectly.

**How to avoid:**
**Preview-first + conflict-gate + confirm + plain stow, adopt only on explicit overwrite:**
```bash
if [[ " ${SELECTED[*]} " == *" keyd "* ]]; then
  if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] sudo stow -t / keyd && sudo keyd reload"; return; fi
  if [[ -f /etc/keyd/default.conf && ! -L /etc/keyd/default.conf ]]; then
    warn "/etc/keyd/default.conf exists and is not a symlink"
    command -v diff &>/dev/null && diff -u /etc/keyd/default.conf "$SCRIPT_DIR/keyd/etc/keyd/default.conf" || true
    confirm "Adopt and overwrite /etc/keyd/default.conf? (moves host file into repo)" || { info "Skipping keyd."; return; }
    sudo stow --adopt -t / keyd  # only after explicit yes
  else
    sudo stow -t / keyd
  fi
  sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true
fi
```
Also: `stow --no --verbose --adopt -t / keyd` preview before ask; document least-privilege sudoers `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd, /usr/bin/systemctl reload keyd, /usr/bin/keyd reload` only. Never `NOPASSWD: /usr/bin/systemctl *`. Version `default.conf` with `# hash:` comment. Keep `keyd` OFF by default in checklist (privileged opt-in). On `--uninstall`, `sudo stow -D -t / keyd` then `sudo systemctl stop keyd` if deselected.

**Warning signs:**
- `git diff keyd/etc/keyd/default.conf` after stow shows host contents, not repo contents.
- `grep -R -- --adopt setup.sh` without preceding `diff` + `confirm`.
- `sudo cat /etc/keyd/default.conf` is a real file (not symlink) after install but repo file changed `mtime`.
- `stow --no --verbose -t / keyd` warns `existing target is not owned by stow` but script proceeds without prompt.
- `teardown` after `--adopt` leaves stale host file in repo; second install diff is empty (already pollluted).

**Phase to address:** Phase 3 — Stow Orchestration & Safety. Must precede shell init. Verification: `stow --no --verbose -t / keyd` preview asserted; host-conflict Bats fixture `/tmp/fake-etc/keyd/default.conf` exercises gate.

---

### Pitfall 6: Stow Folding & Conflict Half-Stow — Tree Folding, Wrong stow Directory, and Two-Phase Failures

**What goes wrong:**
`stow --restow nvim` reports success but `~/.config/nvim/init.lua` is not a symlink to the repo (or `~/.config/starship.toml` points nowhere). Prompt is not themed, `nvim` opens vanilla, `z`/`zi` broken. Or stow aborts mid-way: `target is not owned by stow` leaves half the package linked, half not; re-running `stow --restow` no longer cleans because folding collapsed `~/.config` into a single symlink. Moving the repo or invoking `setup.sh` from a subdirectory (`cd nvim && bash ../setup.sh`) silently breaks folding so `starship/.config/starship.toml → ~/.config/starship.toml` folding rule fails and creates `~/.config/starship/starship.toml` instead.

**Why it happens:**
GNU Stow tree folding creates a single symlink for an entire subtree (`/usr/local/bin → stow/perl/bin`) and only descends when necessary; refolding/unfolding during unstow is subtle (manual `Installing Packages` §5.1). Two key errors: (1) Not using `stow --dir="$SCRIPT_DIR"` / repo-root guarantee, so folding is evaluated relative to CWD; (2) Relying on Stow 2.3.1 (host `2.3.1`) which has spurious `BUG in find_stowed_path? Absolute/relative mismatch` on unstow and broken `--dotfiles` for `dot-foo` packages. Stow's two-phase (since 2.0) scans for conflicts before any write, but if conflict is found it terminates with no changes — new users retry with `--adopt` to "force" it, causing pitfall 5. Packages overlapping paths (`nvim` + `starship` both touching `~/.config`) without isolation create fold collisions.

**How to avoid:**
- **Lock Stow ≥2.4.1** per STACK.md (2.4.0 fixes `--dotfiles`, 2.4.1 fixes `find_stowed_path` warning + `.stowrc` spaces + Perl 5.40 warning).
- **Always invoke from repo root with explicit dir:** `stow --dir="$SCRIPT_DIR" --restow "$pkg"` and `assert [[ -f ./setup.sh ]] || die "Run from repo root"`.
- **Preview before mutate:** `stow --no --verbose --restow nvim zsh starship` on `--dry-run` and in `--self-test`; assert `test -L ~/.config/nvim && [[ "$(readlink -f ~/.config/nvim/init.lua)" == *"/nvim/.config/nvim/init.lua" ]]`.
- **Conflict pre-check:** `stow --no --verbose --restow <pkg> 2>&1 | grep -q "existing target"` → surface and abort with `mv`/`backup` hint, do not auto `--adopt` except keyd gate.
- **Keep packages non-overlapping:** each stow package mirrors a distinct XDG/system target (`nvim/.config/nvim/`, `starship/.config/starship.toml` folding to `~/.config/starship.toml`), document invocation directory in README.
- Consider `--no-folding` for debugging but keep default folding for fewer symlinks (tradeoff: fewer symlinks vs predictable `ls -la`).

**Warning signs:**
- `ls -la ~/.config/starship.toml` is a file, not a symlink, or `readlink -f ~/.config/nvim` points outside repo.
- `stow --no --verbose` on re-run shows `BUG in find_stowed_path` (Stow 2.3.1 signal).
- `echo $SCRIPT_DIR` in stow wrapper prints `nvim/` instead of repo root.
- Fresh clone `setup.sh --dry-run` shows `stow: ERROR: existing target is not owned by stow` but script continues.
- After `mv ~/dotfiles ~/dotfiles.bak`, symlinks are dangling but `stow --restow` claims success.

**Phase to address:** Phase 3 — Stow Orchestration (same phase as --adopt safety; both are the stow correctness slice). Gate: `test -L` + `readlink -f` assertions in `--self-test`; `stow --no --verbose` TAP output.

---

### Pitfall 7: No Post-Install Lock — `pacman -S` / `apt install` Partial Success, No Re-verify

**What goes wrong:**
Installer runs `pacman -S --needed` or `apt install -y` for `core`+`gui` deps, one package fails (network, 404, held package), but script continues to `run_stow` as if deps satisfied. Later `nvim` opens with `telescope-fzf-native` silent fallback (no `make`), `zoxide init` missing → `z: command not found`, `starship --version` absent → prompt falls back to P10k with missing glyphs. Rerun is supposed to be idempotent but `verify-deps` never re-checks after install, so second run also believes deps are present. `verify-deps` only checked `command -v` once at start.

**Why it happens:**
Original `setup.nu:install-deps` / `setup.zsh:install_deps` dispatch to `pacman -S` / `apt install` without version pinning and without `set -e` coverage (arch BBS notes `makepkg` disabled `errexit` for its own error handling). The install loop does not capture `DPKG_LOCKED` or `pacman` database lock, and does not partition `core_missing` vs `gui_missing` for headless decides. No `verify_deps_strict` re-run after install; no log of installed versions for drift audit.

**How to avoid:**
**Post-install re-verify (the lock) + partitioning + idempotence:**
```bash
verify_deps() { local -a deps=("$@"); local missing=(); for d in "${deps[@]}"; do command -v "$d" &>/dev/null || missing+=("$d"); done; printf '%s\n' "${missing[@]}"; }
verify_deps_strict() {
  local -a need=("$@"); local remaining; remaining="$(verify_deps "${need[@]}")"
  if [[ -n "$remaining" ]]; then warn "Still missing after install: $remaining"; return 1; fi
  info "All dependencies satisfied."
}
install_deps() {
  local pm_family="$1"; shift; local -a pkgs=("$@"); (( ${#pkgs[@]}==0 )) && return 0
  local -a cmd=(); case "$pm_family" in arch) cmd=(sudo pacman -S --needed);; debian) cmd=(sudo apt-get install -y);; *) die "Unsupported $pm_family";; esac
  [[ "$DRY_RUN" == true ]] && { echo "[DRY RUN] ${cmd[*]} ${pkgs[*]}"; return 0; }
  confirm "Install ${pkgs[*]} via ${cmd[*]}?" || { info "Skipping install."; return 0; }
  "${cmd[@]}" "${pkgs[@]}"
}
# after install_deps:
verify_deps_strict "${selected_deps[@]}" || die "Install incomplete — see above. Re-run: verify-deps"
```
Add `make`+`gcc` to `common` (fixes `telescope-fzf-native` `cond = executable("make")==1` silent fallback). Detect `[[ ! -t 0 ]]` non-interactive → auto-install `core`, skip `gui`. Log installed versions (`pacman -Q` / `dpkg -l`) for audit.

**Warning signs:**
- Log shows `pacman -S` returned non-zero but script printed `All dependencies satisfied.`
- Second run still shows `Missing: make gcc` even after "install".
- Headless `--mode server` tried to install `hyprland` (GUI partition missing).
- `nvim --headless -c "checkhealth"` warns `make: not found` after install claimed success.
- `apt` lock `Could not get lock /var/lib/dpkg/lock` not surfaced as retryable error.

**Phase to address:** Phase 2 — Dependency Resolution & Install Lock (pair with distro probe + checklist). Gate: `verify_deps_strict` TAP line; Bats fixture where fake `pacman` fails on one package and assert re-verify aborts.

---

### Pitfall 8: fzf Version Drift — Host `0.44.1` vs Installer `≥0.48` `fzf --zsh` Embedded Scripts

**What goes wrong:**
Zsh `Ctrl-R` history search works on dev laptop (Arch `fzf 0.51+` with `source <(fzf --zsh)`) but breaks on fresh Ubuntu 24.04 VM (ships `fzf 0.44.1`) where `fzf --zsh` flag does not exist, or works on VM but breaks on laptop after `zinit` updated `junegunn/fzf` from `master` (`shell/key-bindings.zsh` mismatched binary → `$FZF_DEFAULT_OPTS: height required: HEIGHT`). `Ctrl-R` binds to `history-incremental-search-backward` instead of `fzf-history-widget`; no error beyond missing widget. `zoxide 0.9.8+` `zi` interactive requires `fzf ≥0.51.0` but host is `0.44.1`; `zi` silently falls back to non-interactive.

**Why it happens:**
fzf CHANGELOG 0.48.0 moved shell integration into the binary (`eval "$(fzf --bash)"` / `source <(fzf --zsh)"`, `fzf --fish`) and embedded scripts are version-coupled. Legacy manual `source /usr/share/fzf/key-bindings.zsh && source /usr/share/fzf/completion.zsh` only works when script version matches binary; pulling `https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh` via Zinit (`wait"0d"`) against `fzf 0.44.1` binary triggers the HEIGHT error (issue #4211). Host probes confirm `fzf 0.44.1` (Ubuntu Noble) vs `0.51+` needed for `zoxide 0.9.8 doctor` and `fzf --zsh` native. Installer documents nothing about the branch point, so rollback is guessed.

**How to avoid:**
- **Detect version at install:** `fzf --version` → parse `0.44.1`; if `<0.48` use legacy fallback, if `≥0.48` use embedded.
```bash
fzf_version_ge() { # $1 = min like 0.48.0
  local have; have="$(fzf --version 2>/dev/null | awk '{print $1}')"
  [[ -z "$have" ]] && return 1
  printf '%s\n%s\n' "$1" "$have" | sort -V -C --check=reverse 2>/dev/null || \
    [[ "$(printf '%s\n%s\n' "$1" "$have" | sort -V | head -n1)" == "$1" ]]
}
if fzf_version_ge 0.48.0; then
  source <(fzf --zsh)  # or eval "$(fzf --bash)" on bash host
else
  [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
  [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
fi
```
- **Pin Zinit fzf to tag, not master:** never `https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh` → use `https://github.com/junegunn/fzf/blob/v0.58.0/shell/key-bindings.zsh` or `fzf --zsh` inside binary.
- **Add to `common` deps:** `fzf` must be in `common` so VM gets `≥0.48`; on Ubuntu check Charm/Barn apt lag and warn; offer `go install github.com/junegunn/fzf@latest` fallback.
- **Self-test gate:** `bindkey '^R'` must show `fzf-history-widget`, `zle -l | grep -q fzf`; `fzf --version` printed in `--self-test` TAP.
- **Per docs:** Do not set `FZF_CTRL_T_COMMAND` after sourcing; set before: `FZF_CTRL_T_COMMAND= FZF_ALT_C_COMMAND= source <(fzf --zsh)`.

**Warning signs:**
- `bindkey | grep -E '\^R|\^I'` shows `history-incremental-search-backward` after stow.
- `fzf --zsh` on Ubuntu prints `fzf: unknown option --zsh` but installer did not fall back.
- `zinit update` broke `Ctrl-R` overnight (`HEIGHT required` in `zsh -i -c` output).
- `zoxide --version` shows `0.9.3` but `zi` has no interactive preview (needs fzf 0.51+).
- `fzf --version` not printed in `--self-test` log.

**Phase to address:** Phase 5 — Zsh QoL & fzf History Fix. Must follow Phase 4 (init ordering) and precede final docs. Verify with VM matrix: Ubuntu 24.04 `0.44.1` → legacy, Arch `0.51+` → embedded.

---

### Pitfall 9: Zsh `Ctrl+R` / `Ctrl+I` War — `marlonrichert/zsh-autocomplete` vs `joshskidmore/zsh-fzf-history-search` Double-Bind

**What goes wrong:**
After stow, `Ctrl-R` does nothing or opens the wrong widget; `Tab` (`Ctrl-I`) inserts literal tab instead of expanding completions, or vice versa. Both plugins bind `^I` (`menu-select` vs autocomplete) and history `^R`; whichever loads last wins, but load order is implicit in `zsh/.zshrc` `zi light` lines. `fzf` widget is clobbered by `bindkey -v` + `zle-keymap-select` later in file, or by `edit-command-line` (`Ctrl+X Ctrl+E`) rebinding. User edits `zsh/.zshrc` to "clean up" and breaks navigation/completion with only manual shell restart to discover. README lists `zsh-autocomplete` and `zsh-fzf-history-search` as co-installed but they aggressively own `Tab`.

**Why it happens:**
`zsh-autocomplete` (`marlonrichert/zsh-autocomplete`) owns `Tab` for real-time autocomplete + `menu-select`; `joshskidmore/zsh-fzf-history-search` is a one-liner that binds `^R` to `fzf-history-widget` but is redundant once `fzf --zsh` is present. `zsh/.zshrc:50` `eval "$(zoxide init zsh)"`, `zsh/.zshrc:70` `bindkey -v` + `zle-keymap-select`, and `zinit` annexes all run side-effects that overwrite earlier bindings if reordered. `fzf` wiki (#1304, #1639, #4211) notes `zsh completion plugin overwrite the binding` as the root cause.

**How to avoid:**
**Pick one history widget, document, and lock order** (per STACK.md):
- **Option A (recommended, least maintenance):** keep native `source <(fzf --zsh)` `Ctrl-R` and **remove** `zi light joshskidmore/zsh-fzf-history-search` entirely. Configure `marlonrichert/zsh-autocomplete` with `zstyle ':autocomplete:tab:*' fzf yes` if keeping it.
```zsh
# fzf integration — AFTER Zinit but BEFORE bindkey overrides
if fzf_version_ge 0.48; then source <(fzf --zsh); else ...; fi
bindkey '^R' fzf-history-widget
FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
# DO NOT rebind ^R/^I after this
```
- **Option B:** keep `zsh-fzf-history-search` and drop `zsh-autocomplete` history binding. Less recommended.
Never load both history plugins. Post-stow verification must assert:
```bash
zsh -ic 'bindkey "^R" | grep -q fzf-history-widget || die "^R not fzf"'
zsh -ic 'bindkey "^I" | grep -q fzf-completion || warn "^I not fzf"'
zsh -ic 'zle -l | grep -qi fzf | grep .'
```
Keep explicit comments `# NOTE: zoxide.nu is sourced at the END` + `# p10k instant prompt should stay close to top` intact.

**Warning signs:**
- `bindkey '^R'` prints `history-incremental-search-backward` after `source ~/.zshrc`.
- Tab produces `^I` or `expand-or-complete-with-dots` instead of fzf completion.
- Adding/removing a `zi light` line changes `Ctrl-R` behaviour (load-order symptom).
- `zsh -i -c 'echo $PROMPT; bindkey "^R"'` in `--self-test` fails.
- Issue template: "fzf Ctrl-R nor working in ZSH" (fzf #1304) exactly matches setup.

**Phase to address:** Phase 5 — Zsh QoL (same as fzf version drift; both are the history search contract). Covered by the same post-stow `bindkey` TAP gates.

---

### Pitfall 10: Hyprland `exec` Kills Server Login — `zsh/.zprofile` Unconditional `exec start-hyprland` on tty1

**What goes wrong:**
User runs `bash setup.sh --mode server --shell zsh` on a headless VM or server workstation (intending no GUI), logs out and back in on `tty1`, and the session immediately `exec`s `start-hyprland`. If Hyprland is not installed (server mode should not have it), `exec` fails and the login shell dies — user is loop-kicked or left with no shell. Even when Hyprland is present, `server` users never intended to autostart a compositor and lose their headless workflow. Nushell `env.nu:18-20` commented guard and Zsh `zsh/.zprofile:2-4` unconditional `if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi` diverge.

**Why it happens:**
`zsh/.zprofile` is stowed unconditionally when `zsh` is selected; it has no awareness of `MODE` (`local` vs `server`). The `exec` replaces the login shell without checking `command -v Hyprland`, without reading the mode persisted by the installer, and without an `autostart_hyprland=false` escape hatch. Original `setup.zsh core=[nvim,zsh]` vs `setup.nu core=[nvim,nushell,starship]` divergence means mode mapping is already fragile; adding mode-aware guard was deferred.

**How to avoid:**
**Installer writes mode marker; `.zprofile` guards on marker + executable:**
```zsh
# zsh/.zprofile — guarded autostart (prescribed in ARCHITECTURE.md)
DOTFILES_MODE="${DOTFILES_MODE:-$(cat ~/.config/dotfiles/mode 2>/dev/null || echo local)}"
if [[ "$DOTFILES_MODE" != "server" ]] \
   && [[ -z "${DISPLAY-}" ]] \
   && [[ "$(tty 2>/dev/null)" == "/dev/tty1" ]] \
   && { command -v Hyprland &>/dev/null || command -v start-hyprland &>/dev/null; }; then
  exec start-hyprland 2>/dev/null || exec Hyprland 2>/dev/null || true  # never kill login
fi
```
Installer does:
```bash
mkdir -p ~/.config/dotfiles && echo "$MODE" > ~/.config/dotfiles/mode
# support env override: DOTFILES_MODE=server bash setup.sh …
# alternative: touch ~/.config/dotfiles/no-hyprland && check [[ ! -f ~/.config/dotfiles/no-hyprland ]]
```
Never `exec` without `|| true` fallback. Mirror fix for Nushell placeholder (`env.nu` guard) if ever re-enabled; for this milestone scope filter keeps Nushell docs-only but the marker helps.

**Warning signs:**
- `cat ~/.config/dotfiles/mode` missing after `server` install.
- `grep -n exec zsh/.zprofile` without `DOTFILES_MODE` or `command -v` vicinity.
- VM test: login on `tty1` after `server` mode drops to Hyprland or fails with `exec: start-hyprland: not found` then logout loop.
- `zsh/.zprofile` stowed on server but `hyprland` not in `verify_deps` `common` (should be `gui` only).

**Phase to address:** Phase 4 — Shell Runtime Hardening (Zsh init ordering & `.zprofile` guard). Must land right after Stow Orchestration and before Zsh QoL; verification is a simulated `tty1` login test that asserts no `exec` when `mode == server`.

---

### Pitfall 11: Mason Headless Not Auto-Installing — `python` LSP (`pyright`/`ruff`) Dead After Setup

**What goes wrong:**
Setup finishes with `stow --restow nvim` success, user opens `nvim` on a Python file, expects `pyright`/`ruff` (declared in `lang/python/python.lua` `mason_packages`) to work, but `:LspInfo` shows `0 clients`, `:Mason` shows not installed, `:checkhealth` warns `mason: package … not installed`. User must manually run `:MasonInstallAll` — documented but forgotten, and depends on which of the four mirrored bootstrappers was used (drift). Headless VM self-test `nvim --headless -c "MasonInstallAll" -c "qa"` hangs or exits before installs finish because `MasonInstallAll` is a custom `utils/mason-install-all.lua` loop using `mr.refresh(function() … p:install() … end)` async without blocking; `MasonInstall` is documented to be blocking only when **no UIs attached** (`mason.nvim` doc `mason.txt` + issue #467), but the wrapper's `mr.refresh` callback is async.

**Why it happens:**
`lang/init.lua` aggregates `mason_packages` declaratively but installation is side-effect — previously manual `MasonInstallAll` not automatic on startup. `mason.nvim` 2.x (`mason-org/mason.nvim`, min `nvim ≥0.10`) has `install_root_dir = stdpath("data").."/mason"`; `mason-tool-installer.nvim` (`WhoIsSethDaniel/mason-tool-installer.nvim`) is the intended `ensure_installed` bridge, but repo keeps hand-rolled `mr.get_package(pkg):is_installed()` loop. `setup.sh --dry-run` path skips headless install for speed and never fails the gate. `telescope-fzf-native` `cond = vim.fn.executable("make")==1` already silently disables if `make` missing — the same silent-fallback pattern hides Mason absence.

**How to avoid:**
**Keep hand-rolled `MasonInstallAll` for parity but add `mason-tool-installer` as canonical, and make headless sync blocking:**
```lua
-- lua/plugins/mason.lua (recommended addition)
return {
  "mason-org/mason.nvim",
  build = ":MasonInstallAll", -- ensures :MasonInstallAll exists post-Lazy
  opts = { ui = { border = "rounded" } }
}
-- lua/plugins/mason-tool-installer.lua (new)
return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  opts = {
    ensure_installed = require("lang").mason_packages,
    run_on_start = true,
    start_delay = 3000,
    debounce_hours = 24,
  }
}
```
Installer post-stow headless sync (blocking — no UI → Mason runs synchronously per `mason.txt`):
```bash
# after run_stow when nvim selected and not --dry-run:
nvim --headless -c "MasonInstallAll" -c "sleep 12" -c "qa"  # hand-rolled: sleep covers mr.refresh async
# OR preferred sync (mason-tool-installer):
nvim --headless -c "lua require('mason-tool-installer').check_install(false,true)" -c "qa"
# verify:
nvim --headless -c "checkhealth mason" -c "qa" 2>&1 | grep -q "ERROR" && die "Mason health failed"
nvim --headless -c "lua print(vim.inspect(require('lang').mason_packages))" -c "qa"
```
Add `make`+`gcc` to `common` so `telescope-fzf-native` `cond` no longer trips (turn the `cond` else into `vim.notify WARN` so editor surfaces it). On `--uninstall` when `nvim` deselected: `rm -rf ~/.local/share/nvim/mason ~/.local/state/nvim ~/.cache/nvim` if confirm.

**Warning signs:**
- `:Mason` shows `Not installed` for `pyright` but `settings.lua` has `"python"` enabled.
- `nvim --headless -c "MasonInstallAll" -c "qa" && nvim --headless -c "checkhealth mason" -c "qa"` still warns missing package (async race; needs `sleep` or sync `check_install(false,true)`).
- `lazy-lock.json` contains `mason.nvim` but `mason-registry` is `williamboman` (stale namespace) → `has_package` miss.
- `telescope` falls back to slower generic sorter without user warning beyond status (make missing symptom).
- No `build = ":MasonInstallAll"` or `mason-tool-installer` spec in `lua/plugins/`.

**Phase to address:** Phase 6 — Neovim Hardening (`which-key` + Mason headless). This is the editor runtime slice; verification is headless `checkhealth` zero warnings + `mason_packages` installed list in TAP.

---

### Pitfall 12: Neovim Bootstrap Drift & Colorscheme Schedule Fragility — `lazy.nvim stable` vs `lazy-lock.json` 85c7ff3

**What goes wrong:**
Fresh clone on a cold network clones `https://github.com/folke/lazy.nvim.git --branch stable --filter=blob:none` on every `nvim` launch; a new `stable` tip introduces a breaking change to `performance.rtp.disabled_plugins` (23 entries hard-coded in `init.lua:44`), keymap plugins, or `vim.loop`→`vim.uv` API. `lazy-lock.json` pins downstream 44 plugins but **not** `lazy.nvim` itself (`lazy.nvim` is excluded from its own lock until after bootstrap). Post-setup `vim.schedule(function() vim.cmd.colorscheme(settings.colorscheme) end)` deferred colorscheme relies on `require("settings")` succeeding after `lazy` setup; if settings load fails, colorscheme is blank. `init.lua` `vim.loop.fs_stat(lazypath)` uses `vim.loop` which is deprecated since `nvim 0.10` (`vim.uv` is canonical).

**Why it happens:**
Bootstrap snippet in `nvim/.config/nvim/init.lua:1-11` is the pre-0.10 sample (`vim.loop.fs_stat` + no `vim.v.shell_error` check, no `vim.fn.getchar()`+`os.exit(1)` on clone failure, no commit pin). Lazy community keeps `lazy.nvim` on `stable` for convenience but `stable` moves weekly; install-to-install drift is unpinned. `disabled_plugins` list (23 entries `netrwPlugin`, `spellfile_plugin` etc.) is Neovim-version-sensitive and will break on upgrade if names change. `performance.rtp.disabled_plugins` failing silently only surfaces via `checkhealth` provider errors much later.

**How to avoid:**
Replace with **official snippet** (context7 `/folke/lazy.nvim` HIGH, also lazy.folke.io installation):
```lua
vim.g.mapleader = " "
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({ "git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git","--branch=stable", lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({{"Failed to clone lazy.nvim:\n"..out,"ErrorMsg"}}, true, {})
    vim.fn.getchar(); os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
```
Add drift verification (warn, not fatal):
```bash
git -C "$lazypath" rev-parse HEAD  # compare to lazy-lock.json lazy.nvim commit 85c7ff3
```
Refresh `disabled_plugins` after `nvim --headless -c "Lazy check" -c "qa"`; run host probe `nvim v0.12.2` to ensure list still valid. Keep `vim.schedule(colorscheme)` but guard: `pcall(require,"settings")` → on fail notify ERROR and keep fallback `habamax`. Use `vim.uv or vim.loop` for compat.

**Warning signs:**
- `git -C ~/.local/share/nvim/lazy/lazy.nvim rev-parse HEAD` vs `jq .["lazy.nvim"].commit lazy-lock.json` diverges by months.
- `nvim --startuptime /tmp/start.log` shows `lazy.nvim` clone `git` blocking >3s on cold launch.
- `nvim --headless -c "Lazy check" -c "qa" 2>&1` warns about `disabled_plugins` unknown plugin.
- `colorscheme tokyodark` not applied on first launch (keeps `habamax` fallback).
- `rg -n "vim.loop.fs_stat" nvim/.config/nvim/init.lua` without `vim.uv` guard.

**Phase to address:** Phase 6 — Neovim Hardening (same as Mason; both are editor runtime reliability). Gate: `nvim --headless -c "checkhealth" -c "qa"` zero errors + `Lazy check` TAP; `init.lua` bootstrap pattern review.

---

### Pitfall 13: Secrets Committed — `MISTRAL_API_KEY` in `env.nu` + Missing Gitignored Local Pattern

**What goes wrong:**
Live `MISTRAL_API_KEY = "sk-..."` (and any future `*_API_KEY`) is committed to `nushell/.config/nushell/env.nu:48` and indefinitely in `git log --all -S MISTRAL_API_KEY`. Every clone receives a billable credential; `git filter-repo` history purge is never done, scanners (GitHub secret scanning, TruffleHog, `gitleaks`) flag the repo, and rotation invalidates any downstream `curl -H "Authorization: Bearer $MISTRAL_API_KEY"` that assumed the committed value. Machine-specific `PATH`/alias/theme tweaks also land in tracked `zsh/.zshrc` or `nvim/lua/settings.lua` because no `*.local` pattern exists, dirtying `git status` per machine.

**Why it happens:**
No `.gitignore` entry for `env.nu` assignments, no `.secrets.example`/`env.example`, no `sops`/`age`/`pass` indirection, and `CONCERNS.md` grep for `sk-`, `akIA`, `-----BEGIN` misses generic `*_API_KEY=` in `*.nu`/`*.zsh`. Workflow forbids reading `.env` but Nushell `env.nu` is not scanned as a secret holder. Docs favor Nushell (`setup.nu`) even though Zsh is canonical. Per-machine overrides were addressed by `.gitignore` path edits (`616b669`, `17530e5`, `116674b` manual fixes) rather than a systemic `*.local` convention.

**How to avoid:**
- **Rotate and purge:** `Mistral dashboard → rotate MISTRAL_API_KEY`, then `git filter-repo --invert-paths` or `BFG --replace-text` + force-push; notify clones.
- **Move to ignored local file:** 
```nu
# nushell/.config/nushell/env.nu placeholder (committed)
$env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""  # sourced from secrets.nu
# nushell/.config/nushell/secrets.nu (gitignored, never commit)
# $env.MISTRAL_API_KEY = "sk-..."
# zsh/.zshrc tail:
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
# nvim init.lua tail:
pcall(require, "local") -- loads nvim/.config/nvim/lua/local.lua if present
```
- **Add to `.gitignore` (committed):**
```
zsh/.zshrc.local
zsh/.zprofile.local
nvim/.config/nvim/lua/local.lua
nushell/.config/nushell/secrets.nu
.env.local
.migration_backups/
```
Ship `*.example` templates (`zsh/.zshrc.local.example`, `nvim/lua/local.lua.example`, `nushell/secrets.nu.example`, `.env.example`) with docs in `README.md` + `nvim/README.md`. Add pre-commit `gitleaks`/`git-secrets` hook scanning `API_KEY|SECRET|TOKEN|PRIVATE_KEY` in `*.nu`/`*.zsh`/`*.lua` and extend `codebase/CONCERNS.md` grep to `*_API_KEY`.

**Warning signs:**
- `git log --all -p -S MISTRAL_API_KEY` still shows `sk-` value.
- `grep -R "API_KEY.*=" nushell/ zsh/` outside `*.example`/`*.local` or `MISTRAL_API_KEY? | default`.
- `.gitignore` lacks `zsh/.zshrc.local` or `nvim/.config/nvim/lua/local.lua` entry.
- `git status` after per-machine `PATH` edit on second laptop shows `zsh/.zshrc` modified.
- No `secrets.nu.example` committed; onboarding instructions say "edit env.nu directly".

**Phase to address:** Phase 7 — Polish, Secrets & Machine-Local (penultimate polish phase after stow/shell/editor are solid). Verification: `gitleaks detect --source . --no-git` zero hits; clone + `ls ~/.zshrc.local` absent but sourced without error; `git status` clean after per-machine edit.

---

### Pitfall 14: Silent Language Loss — `settings.lua` `languages = { "pythoon", … }` Typo + Stale Mason Binary on Disable

**What goes wrong:**
User edits `nvim/.config/nvim/lua/settings.lua:24` `languages = { "bash","git","python","javascript",… }`, typos `"python"` as `"pythoon"` or forgets a trailing comma after commenting. `nvim` starts normally with only `vim.notify WARN "Failed to load: lang.pythoon.pythoon"` which is suppressed by `noice.nvim` routing; Python LSP/formatter/treesitter silently missing with no hard error. Commenting a language (e.g., `"c"`) to save disk does not uninstall its Mason package (`pyright` 200MB) or Treesitter parser — stale binary remains, disk grows linearly with 14→30 languages. Re-enabling requires remembering `:MasonInstallAll`; there is no `MasonUninstall` hook.

**Why it happens:**
`nvim/.config/nvim/lua/lang/init.lua:23` uses `pcall(require, "lang."..lang.."."..lang)` with WARN-only recovery and returns empty `M` on failure; downstream `plugins/conform.lua` and `mason.lua` just `require("lang")` with no hard gate. `lang/init.lua` silent `pcall(require, "lang."..lang..".plugins")` ignores missing companion `plugins.lua` intentionally (only python/css/django/html/json/markdown need it) — but the same silence masks real typos. Aggregator O(n) deduplication cost is negligible, but `mr.refresh` iterates all `mason_packages` each startup context.

**How to avoid:**
- **Make WARN visible:** verify `noice.nvim` routing not suppressed (`:Noice telescope` must show WARN); test `nvim --headless -c "checkhealth" -c "qa"` surfaces missing lang.
- **Post-edit checklist in README:** `Edit settings.lua → restart nvim → run :MasonInstallAll, :TSInstallInfo, :checkhealth — verify no WARN toasts → keep disabled languages commented with --"c" + reason, not deleted`. Add `settings.lua` header comment.
- **Make disable clean:** on `--uninstall` or when language deselected, installer offers `rm -rf ~/.local/share/nvim/mason/packages/<name>` and `stdpath("data").."/mason"` cleanup; otherwise document `MasonUninstall <pkg>` + `TSUninstall <parser>`.
- **Deduplication is already correct** (`deduplicate()` 12 lines); do not regress by appending duplicates per lang module.
- **Future tiering:** split `languages` into `core` always-installed vs `opt-in` lazy-install on first `FileType` (defer Mason ensure); not required this milestone but note.

**Warning signs:**
- `nvim --headless +"lua print(vim.inspect(require('lang').mason_packages))" +"qa"` missing expected server after adding language.
- `:Mason` shows `Not installed` for a lang just added to `settings.lua`.
- `du -sh ~/.local/share/nvim/mason` keeps growing after disabling language.
- `:Noice history` has no WARN even after deliberately typoing `"pythoon"` (routing suppressed).
- `settings.lua` diff shows `-"c"` without `MasonInstallAll` run.

**Phase to address:** Phase 6 — Neovim Hardening (language aggregator hardening). Gate: deliberately broken `settings.lua` typo → `nvim --headless -c "checkhealth" -c "qa"` must surface WARN; `mason_packages` length in self-test TAP.

---

## Technical Debt Patterns

Shortcuts that look cheap now but become rewrites later. All from `codebase/CONCERNS.md` scaling/tech-debt.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-----------------|----------------|-----------------|
| **Keep mirrored `setup.nu`/`setup.zsh` + `teardown.*` instead of canonical `setup.sh`** | No file rename, no doc updates | Drift already visible `core=[nvim,nushell,starship]` vs `[nvim,zsh]` and GUI lists diverge; bug fix in one never propagates; mode×distro×keyd matrix 2× tested; future dep change → missing configs on one shell path | **Never** — this is `CONCERNS.md` #1 tech debt. Migrate to `bash setup.sh` with `setup.{nu,zsh}` shims `exec bash setup.sh "$@"` for one release, then delete. Thin wrappers only. |
| **Hard-coded `["arch","cachyos","ubuntu"]` in `get_distro`** | 3-line if, no `ID_LIKE` parsing | Rejects Manjaro/EndeavourOS/Arco/Garuda/Mint/Pop!_OS; support tickets + manual `stow` bypasses health gate; auto-install never fixes itself | **Never** — fix in Phase 1 before any feature phases. Use `ID_LIKE` + `command -v` probe (see Pitfall 2). |
| **Hard-coded theme/palette duplication (`catppuccin-mocha.toml` import + `starship.toml palette='catppuccin_latte'` + `nvim catppuccin.lua` + `nushell catppuccin.nu`)** | Copy-paste fast | 4 edits to change one flavor; currently `alacritty mocha` vs `starship latte` mismatch; inconsistency risk on every theme PR | **OK only this milestone as validation, not generation.** Phase 7 ships `THEME=mocha` env + `apply_theme()` consistency check and warns. Full templating (`chezmoi`/`envsubst` sed) deferred until 5th manual edit — avoid re-layout of 7 packages. |
| **Skipping `pacman -Q`/`dpkg -l` re-verify lock after `install_deps`** | One less loop, feels idempotent via `stow --restow` | Partial install not caught → `fzf-native` silent fallback, `zoxide: not found`, prompt glyphs missing; drift invisible until user opens file; second run also passes | **Never** for package installs. Stow idempotence ≠ package idempotence. Always `verify_deps_strict` re-run (Pitfall 7). |
| **Skipping `shellcheck`/`shfmt` + no `set -Eeuo pipefail` preamble** | Fewer CI steps, looser Bash style | `errexit`/`pipefail`/`nounset` bugs ship (Pitfall 1), `whiptail` fd swap errors hidden, `${1}` aborts; later phases inherit crashing installer | **Never** — add `shellcheck -S warning setup.sh && shfmt -i 4 -ci -d setup.sh` to Phase 1 `--self-test` and pre-commit. Cost is seconds; failure mode is a bricked fresh install. |
| **Stow 2.3.1 "good enough" (`Brew` Stow 2.3.x, ignore 2.4.1 upgrade)** | No GNU FTP fetch, host default is 2.3.1 | Spurious `BUG in find_stowed_path` on unstow, `--dotfiles` broken for `dot-` directories, Perl 5.40 warning; confuses stash/unstow, wastes debug hours | **Never** — lock `stow >=2.4.1` in docs and `--self-test` gate (`stow --version`). Host already `2.3.1` → document `sudo pacman -S stow` (MSYS2 2.4.1-1, Gentoo EAPI 8, GNU FTP `stow-2.4.1.tar.gz`). |
| **No `manifest.toml`/`packages.json` declarative deps; keep inline `get_deps` arrays per distro×mode×shell** | Arrays visible in one file, no parser dependency | Hard-coded `core=[stow,nvim,…]` + `gui=[hyprland,…]` drift again after unification if future deps added; mode matrix combinational testing grows | **Acceptable this milestone if commented.** Prefer `manifest.toml` `[[package]] name= tag=core|gui arch-only` consumed by Bash (or keep inline with `# MANIFEST — edit here` banner + self-test assert). Revisit when GUI set grows beyond 7 packages. |
| **Skipping snapshot/backup before `teardown`/`stow -D` + privileged `keyd`** | One fewer `mkdir -p ~/.local/state/dotfiles/backups/$ts` and `cp` | Accidental `teardown` on working machine loses edits adopted via `--adopt`; `keyd --adopt` moved host file into repo with no restore; no rollback from `--mode local` mistaken on server | **Never for destructive paths.** Phase 3 must add snapshot `backup_adopted_files()` before `--adopt`/`-D`. Stow `--no --verbose` preview is not a backup. Keep 5 most recent `~/.local/state/dotfiles/backups/` (Aman1337g pattern). |
| **`init.lua` bootstrap `vim.loop.fs_stat` without `vim.v.shell_error` + no `lazy-lock.json` pin** | 5-line bootstrap fast | Network MITM or flaky GitHub hangs `nvim` for seconds on cold machines; `stable` tip drift breaks `disabled_plugins`; reproducibility depends on manual `:Lazy update` | **Acceptable only with official guard.** Keep `stable` but add `vim.uv or vim.loop` + `shell_error` + `getchar()+os.exit(1)` (Pitfall 12). Pin `lazy.nvim` commit 85c7ff3 verification. |
| **Committing secrets placeholder as `MISTRAL_API_KEY=""` without `.local` + `gitleaks`** | One-line edit | Next contributor invents ad-hoc `env.nu` placement and re-commits key; history leak forecloses rotation | **Never** — fix in Phase 7 with `secrets.nu` ignored + pre-commit (Pitfall 13). |

---

## Integration Gotchas

Stow, fzf, Mason, zoxide, P10k, Starship, Keyd interop mistakes that pass local tests but fail on target distro/derivative/VM.

| Integration | Common Mistake | Correct Approach |
|-------------|---------------|------------------|
| **GNU Stow** | Run `stow` from subdir (`cd nvim && stow --restow nvim`), omit `--dir`, rely on `stow 2.3.1` folding; call `--adopt` to "force" a conflict; treat `--no --verbose` output as JSON | Run `stow --dir="$SCRIPT_DIR" --restow <pkg>` from repo root only; `[[ -f ./setup.sh ]] || die` guard; require `stow >=2.4.1`; preview `--no --verbose` and parse human-readable two-phase conflict message; use `--adopt` only via keyd conflict gate + `confirm` (Pitfall 5/6). |
| **fzf** | `source /usr/share/fzf/key-bindings.zsh` on `0.48+` or `source <(fzf --zsh)` on `0.44.1`; Zinit `from"gh-r" @junegunn/fzf + https://…/master/shell/key-bindings.zsh` mixing binary+script versions | Branch by version: `fzf_version_ge 0.48.0 && source <(fzf --zsh) \|\| source /usr/share/fzf/key-bindings.zsh`; pin Zinit fzf scripts to `v0.58.0` tag, not `master` (issue #4211). `which zoxide` + `fzf --version` in self-test (Pitfall 8). |
| **Mason (`mason-org/mason.nvim` + `mason-tool-installer`)** | Use old `williamboman/mason.nvim` spec, call `MasonInstallAll` in interactive-only mode, expect async `mr.refresh → p:install()` to be blocking headless, set `version=false` globally | Use `mason-org/mason.nvim` + `mason-org/mason-lspconfig` + `WhoIsSethDaniel/mason-tool-installer.nvim`; `require("mason-tool-installer").setup{ ensure_installed=require("lang").mason_packages, run_on_start=true, start_delay=3000 }`; headless `nvim --headless -c "lua require('mason-tool-installer').check_install(false,true)" -c "qa"` (sync) or `MasonInstallAll + sleep 12` (Pitfall 11). |
| **zoxide** | `eval "$(zoxide init zsh)"` at random position (before `fpath`, after `bindkey -v` clobber), missing `fzf ≥0.51.0` for `zi` interactive, hook double-reg on `source config.nu` | Keep `zoxide init` after `fpath` + before `bindkey -v` but after `Zinit`+`fzf`; Nushell `zoxide.nu` sourced **last** (`config.nu` tail comment is load-bearing); `typeset -U path PATH` dedup; `test-zoxide.nu` hook count assertion; `zoxide doctor` (0.9.8+) diagnoses `PROMPT_COMMAND`/`ble.sh` (Pitfall 10 ordering). |
| **Powerlevel10k + Zinit** | Instant prompt not at top; console I/O before it (reads/writes TTY); `ZINIT[HOME_DIR]` wrong; vendor Zinit latest without commit pin | Keep `# NOTE: p10k instant prompt should stay close to top` block verbatim at top; move `keychain`/`confirm` I/O above it; `[[ -f ~/.local/share/zinit/zinit.git ]] \|\| git clone --depth 1 $ZINIT_URL ~/.local/share/zinit/zinit.git` pin to commit SHA; verify `zsh -i -c 'echo $POWERLEVEL9K_INSTANT_PROMPT; echo loaded'`. Treat P10k as frozen (life-support 2024-05-23) → document Starship successor, don't rip out. |
| **Starship + Alacritty** | Import `catppuccin-mocha.toml` via hardcoded path that breaks after repo move; `scan_timeout=1000` on `server` mode scanning 12 language modules | Keep `import = ["~/.config/alacritty/catppuccin-mocha.toml"]` via XDG (stowed), not repo-relative; per-mode toml: `local` rich powerline, `server` minimal `scan_timeout=200` + `disabled=true` for `php/kotlin/haskell`; `starship timings` audit. |
| **keyd + systemd** | `sudo stow --adopt -t / keyd && sudo keyd reload && sudo systemctl start keyd` with `NOPASSWD: /usr/bin/systemctl *` and no conflict diff | `sudo stow -t / keyd` unless `[[ -f /etc/keyd/default.conf && ! -L ... ]]` → `diff -u` + `gum confirm`; least-privilege `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd, /usr/bin/systemctl reload keyd, /usr/bin/keyd reload` only (Pitfall 5). |
| **Gum / whiptail / dialog ladder** | Assume `gum` present on fresh Ubuntu server or Arch live ISO; use only `gum choose` (no fallback) or only `whiptail` without fd swap | Ladder `gum → whiptail --checklist … 3>&1 1>&2 2>&3 → dialog → fzf --multi → read` with `command -v` probe + `[[ -t 0 ]]` TTY guard; handle `whiptail` `1`/`255` as abort; `--separate-output` to simplify parsing (Pitfall 4). |
| **Pacman / Apt family** | `pacman -S` without `--needed` on rerun re-downloads; `apt` without `-y` hangs on interactive prompt; `pacman`/`apt` mixed up via `ID` (CachyOS `pacman`, Mint `apt`) | Branch on `pm_family` (`arch`→`pacman -S --needed`, `debian`→`apt-get install -y`) not `ID`; probe `command -v pacman`/`apt-get` first; handle `dpkg` lock `/var/lib/dpkg/lock` retry hint. |
| **Tree-sitter CLI + `telescope-fzf-native`** | `setup.zsh --mode server` minimal image without `make`/`gcc`; `cond = executable("make")==1` silently disables fzf-native with slower generic sorter | Add `make`+`gcc` to `common` deps; change `cond` else to `vim.notify("fzf-native: make missing — using fallback", WARN)` so editor surfaces it; `nvim --headless -c "checkhealth"` gates. |

---

## Performance Traps

Patterns that feel fine on a warm dev laptop but kill first-launch, prompt latency, or scaling to 30 languages.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| **Starship `scan_timeout = 1000` on `server`** | Every `ENTER` waits up to 1s; prompt shows `$cmd_duration` jitter; `starship timings` shows `git_status`/`nodejs`/`python` spawning per prompt | Ship `starship-minimal.toml` variant for `server` with `scan_timeout = 200` and `disabled = true` for unused `php`/`kotlin`/`haskell`/`conda`; `local` keeps rich powerline. Keep `palette = 'catppuccin_latte'` centralized via `THEME` check (ARCHITECTURE.md Theme Centralizer). | `server` fresh VM, large git repo, prompt lag felt at >5 prompts/min; DEV: 100ms per prompt × 60/min = 6s wasted. |
| **Nushell `uv.nu` (400-line completions) + zoxide hook sourced eagerly at every interactive launch** | Nushell startup >800ms, `Ctrl+R` smart `history | where` scans full `history.txt` synchronously | Gate `uv.nu` externs behind `completer:` demand-load or `completions/` extern directory; cap `history | where` to last 1000 entries and index; keep Nushell as backup only (PROJECT.md scope filter) so deoptimizations are docs-only | Not in scope this milestone; document as out-of-scope tech debt (CONCERNS.md Nushell sourcing overhead). |
| **Neovim startup `vim.fn.system({ "git","clone", … })` blocking per `nvim` launch** | Cold machine or flaky GitHub → `nvim` hangs seconds on every open; user thinks editor broken | Gate clone behind explicit install (`NvimInstall` not `init`), keep `fs_stat` fast path + `vim.v.shell_error` + spinner/timeout; `nvim --startuptime /tmp/start.log` and move heavy `lang` aggregation to deferred `vim.schedule` (CONCERNS.md). Official bootstrap only clones when `lazypath` missing, not every startup. | First launch on fresh VM without network; every launch if `lazypath` permission denied. |
| **Ripgrep `grepprg=rg --vimgrep` + Telescope `live_grep` with no ignore custom (`nvim/state/`, `cache/`, `shada/`, `undo/`)** | `live_grep` in `$HOME` scans `~/.config/nvim/state/` + `lazy-lock.json` + history files; noisy + slow (`rg` still traverses ignored dirs if `.ignore` missing) | Add `.ignore` at `nvim/.config/nvim/.ignore` excluding `state/|cache/|shada/|undo/|.git/|lazy-lock.json` and `telescope file_ignore_patterns`; set `grepprg=rg --vimgrep --no-heading` with `--glob '!.git/*'` | `live_grep` from `$HOME` or large repo; scales with `undo/` files (>10K). |
| **Nvim language count linear cost (14 → 30 languages)** | `settings.languages` 30 entries → `MasonInstallAll` 500MB parsers + network burst + `mr.refresh` loop O(n) on every sync; `:MasonInstallAll` wall time 3→12min; startup `require` loop 14→30 | Split `languages` into `core` always-installed vs `opt-in` lazy-install via `:MasonInstall <lang>` on first open; group `treesitter.ensure_installed` behind deferred `require("lang")`; document `MasonUninstall` cleanup; add installer `THEME` of language tiers | 30+ languages or disk-constrained VM (500MB Mason + parsers). |
| **Stow package fan-out (7 → per-app configs, mode matrix)** | `setup.sh` `gui_modules` arrays unwieldy; mode×distro combinational testing grows; `stow` conflicts from overlapping `~/.config` paths | Replace hard-coded arrays with `packages.json`/`manifest.toml` manifest tagging `tag: core|gui|arch-only` and generate stow commands dynamically (CONCERNS.md Scaling path) | Adding 10+ packages or per-app stow (e.g., per-language `waybar`); defer until needed. |
| **Host PATH length (10+ segments `~/.local/bin:~/.local/sbin:~/.cargo/bin:~/.bun/bin:~/.npm-global/bin:~/.local/share/zinit`)** | `getconf PATH_MAX` hit, shell completion slowness (`uv.nu` 400-line exports per prompt), `ARG_MAX` expansion loops | Deduplicate: Zsh `typeset -U path PATH` (`ARCHITECTURE.md` Prescribed order), Bash `printf "%s" "$PATH" | `awk -v RS=: '!seen[$0]++' | paste -sd:`; move rarely-used bins to lazy `prepend` on demand | Reaching `PATH_MAX` or login slow >2s; measurable via `zsh -i -c 'echo $PATH | tr : "\n" | wc -l'` (>15 segments). |

---

## Security Mistakes

Domain-specific beyond OWASP basics — dotfiles are code that runs as user on login and as root for `keyd`.

| Mistake | Risk | Prevention |
|---------|------|------------|
| **Committing `MISTRAL_API_KEY` / `sk-*` / `*_API_KEY` in `nushell/env.nu` or `zsh/.zshrc` tracked files** | Live credential in `git log --all`; every clone gets billing-capable secret; GitHub scanning/TruffleHog flags repo; history purge required via `filter-repo`/`BFG` + force-push | Rotate via Mistral dashboard; purge history; move to `$env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""` placeholder + `~/.config/nushell/secrets.nu` ignored + `.gitignore` (`secrets.nu`, `*.local`, `.env.local`); add `gitleaks`/`git-secrets` pre-commit scanning `API_KEY|SECRET|TOKEN` in `*.nu`/`*.zsh` (see Pitfall 13). |
| **`sudo stow --adopt -t / keyd` without conflict preview, `diff`, user confirmation, or hash pin** | Host `/etc/keyd/default.conf` overwritten with repo (or repo polluted with host) silently; malicious `keyd/etc/keyd/default.conf` remaps all keys as root; no signature/ checksum | `stow --no --verbose --adopt -t / keyd` preview + `diff -u /etc/keyd/default.conf $SCRIPT_DIR/keyd/etc/keyd/default.conf` + `gum confirm` before `sudo stow --adopt`; version `default.conf` with `# hash:` comment; least-privilege sudoers (only `systemctl start|stop|reload keyd`, `keyd reload`) (Pitfall 5). |
| **`nvim init.lua` `git clone --branch stable` without hash/commit pin or `vim.v.shell_error` verification** | MITM or compromised `folke/lazy.nvim` injects code executed as user on every `nvim` launch (bootstrap runs as user) | Official bootstrap (`vim.uv or vim.loop` + `filter=blob:none` + `shell_error` guard + `getchar()+os.exit(1)`) per context7; pin `lazy.nvim` commit `85c7ff3` in `lazy-lock.json` verification `git -C "$lazypath" rev-parse HEAD`; document in `init.lua` comment (Pitfall 12). |
| **Sudoers `NOPASSWD: /usr/bin/systemctl *` or `ALL` in README visudo snippet** | Overbroad root without password for any `systemctl` action (not just `keyd`); expands laterally | Document `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, /usr/bin/systemctl stop keyd, /usr/bin/systemctl reload keyd, /usr/bin/keyd reload` only; never wildcard `*`. |
| **`.env` / `*.local` / machine-local patterns not in `.gitignore` allowlist model** | New tool writes credentials to `~/.config/<tool>/config` (e.g., `gh`, `1Password`, `Muse`) and repo tracks it because `.gitignore` is deny-list, not allowlist | Use allowlist model: `.gitignore` `.config/*` then `!.config/nvim/` etc. per `superhighfives/dotfiles` pattern; audit via `scripts/config-drift.sh`; opt-in `!` lines (`!.config/<name>/`) — failure mode "forgot to back up" never "leaked secret" (see `superhighfives` and `FluxxField` adopt-dry merge). |
| **Scanner misses `env.nu` `MISTRAL_API_KEY` because workflow only greps `sk-` / `ghp_` / `-----BEGIN`** | `*_API_KEY=` assignments in `*.nu` slip through code scanning; credential leak flagged only after public push | Extend pre-commit to `API_KEY|SECRET|TOKEN|PRIVATE_KEY` assignments in `*.nu`/`*.zsh`/`*.lua`; extend `codebase/CONCERNS.md` grep to `*_API_KEY=` (Pitfall 13). |

---

## UX Pitfalls

How users suffer when an install "succeeds" but leaves broken affordances.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| **No package checklist even with `--mode local` — GUI set forced** | Server user on VM gets `hyprland`+`waybar`+`grim`/`slurp` deps pulled, `wl-clipboard` missing → installer half-fails; no way to say "I only want `nvim`+`zsh`" | Provide **select/deselect override checklist before any write** (Pitfall 3); gum primary, whiptail fallback; `keyd` OFF by default; persist mode marker for `.zprofile` Hyprland guard. Show preview list in `--dry-run`. |
| **Zsh `Ctrl+R` does nothing after setup** | No working history fuzzy search; user thinks fzf not installed and manually `brew install fzf` but still broken due to bindkey clash (core pain in PROJECT.md `Current Zsh pain`) | Decide fzf history binding (Pitfall 8/9), assert `bindkey '^R'` is `fzf-history-widget` and `bindkey '^I'` not clobbered; ship `FZF_CTRL_R_OPTS` with preview; document conflict resolution and test `bindkey \| grep -E '\^R\|\^I'` after stow. |
| **Neovim `python` LSP dead without manual `:MasonInstallAll`** | `python` enabled in `settings.lua` but `pyright`/`ruff`/`black` never auto-install; user must discover `MasonInstallAll`; `python` "doesn't work out-of-box" violates `Core Value: bash setup.sh → working Zsh + Neovim` | Headless `MasonInstallAll` sync post-stow (`nvim --headless -c "MasonInstallAll" -c "qa"` or `mason-tool-installer check_install(false,true)`) + `build = ":MasonInstallAll"` in lazy spec; removal cleans `~/.local/share/nvim/mason` when uninstalling `nvim` (Pitfall 11). |
| **No which-key leader popup on `<Space>`** | Nested combos invisible (LazyVim had this); user forgets `<Space>f`/`s`/`g`/`e`/`t`/`q` groups, discovery lost | Add `folke/which-key.nvim` v3 `preset=modern`, `delay=200`, `event="VeryLazy"`, `spec` for `f/s/g/e/t/q` groups; auto-discovers `desc` already in `base/keymaps.lua` (ARCHITECTURE.md hardening). |
| **Machine-local overrides not documented / not gitignored** | Per-machine `PATH`/`alias`/`theme` edits dirty `git status`; user hesitates to commit or leaks hostname-specific paths into shared repo | Ship `.gitignore` `*.local` + `secrets.nu` + `.example` templates + docs; source guards `[[ -f ~/.zshrc.local ]] && source` tail and `pcall(require,"local")` in `init.lua`; `README.md` + `nvim/README.md` document copying `*.example` → `*.local` (Pitfall 13). |
| **No `--dry-run` preview / no self-check usable in VM** | User must risk real writes or own VM to validate; agent cannot validate locally without VM; changes ship untested | Every mutating path guarded by `DRY_RUN` printing `[DRY RUN] Would run: …` + `stow --no --verbose`; add `--self-test` gate (TAP: `stow --no --verbose`, `test -L`, `z`/`zi`, `checkhealth zero warnings`, Mason packages, starship/zoxide hooks) — PROJECT.md validation plan. |
| **`telescope-fzf-native` silently disables if `make` missing** | Fuzzy finder falls back to slower generic sorter with no toast; user expects fzf performance on minimal server image | Add `make`+`gcc` to core deps; make `cond = vim.fn.executable("make")==1` else `vim.notify("fzf-native: make missing — fallback", WARN)`; surface in self-test. |
| **Hyprland auto-launches on `server` or kills login** | See Pitfall 10 — headless login replaced by compositor | Guarded `.zprofile` reading `~/.config/dotfiles/mode` + executable check + `|| true`. |
| **Privileged keyd write without preview/confirmation** | See Pitfall 5 — `/etc` write surprises | Require `diff` + `gum confirm` and checklist `keyd` OFF default. |

---

## "Looks Done But Isn't" Checklist

Features that demo as green but hide missing gates. Run through *after* `bash setup.sh --dry-run` and *after* real stow on a VM.

- [ ] **Unified Bash installer `--dry-run`:** Often missing fd-swap `3>&1 1>&2 2>&3` handling for whiptail — verify `bash setup.sh --dry-run --mode server 2>&1 | grep "^\[DRY RUN\] Would stow"` prints, and Cancel/ESC aborts instead of continuing.
- [ ] **Distro handling on derivatives:** Often missing `ID_LIKE` + `command -v pacman/apt` probe — verify `ID=manjaro ID_LIKE=arch bash -c 'source ./setup.sh; get_distro'` prints `arch`, `ID=linuxmint ID_LIKE=ubuntu` prints `debian`; hard-coded `["arch","cachyos","ubuntu"]` gone.
- [ ] **TUI checklist override before writes:** Often missing — verify checklist appears *before* any `[DRY RUN] Would run: pacman` line; non-TTY `echo | bash setup.sh --yes` uses ON defaults without hang.
- [ ] **Stow symlinks correct (folding):** Often missing `stow --dir` + trailing `test -L` — verify `ls -l ~/.config/nvim` → `…/dotfiles/nvim/.config/nvim` via `readlink -f`; `ls -l ~/.config/starship.toml` is symlink (folding), not file; `stow --version` is `2.4.1+`.
- [ ] **Privileged `keyd -t /`:** Often missing conflict gate + `diff` + `confirm` — verify `sudo stow --no --verbose -t / keyd 2>&1` preview shown and `keyd` is OFF in checklist by default; after adopt, `git diff keyd/etc/keyd/default.conf` empty.
- [ ] **Post-install lock:** Often missing `verify_deps_strict` re-run — verify after `--dry-run` with fake missing dep (`make gcc` not installed) the script reports `Still missing after install:` and exits non-zero; check `pacman -Q` / `dpkg -l` log.
- [ ] **fzf integration `Ctrl+R`:** Often missing version branch — verify `fzf --version` ≥0.48 → `source <(fzf --zsh)`, else legacy `/usr/share/fzf/key-bindings.zsh`; `bindkey '^R'` is `fzf-history-widget`, `bindkey '^I'` not clobbered, `zle -l | grep fzf` has entries.
- [ ] **Zsh init ordering:** Often missing P10k top + zoxide last — verify `head -n 20 zsh/.zshrc` is instant-prompt block; `tail -n 20 zsh/.zshrc` has `eval "$(zoxide init zsh)"` then `[[ -f ~/.zshrc.local ]]` tail and no `bindkey '^R'` after; `zsh -i -c 'echo $POWERLEVEL9K_INSTANT_PROMPT'` no warning.
- [ ] **Mason auto-install after setup without manual `:MasonInstallAll`:** Often missing headless sync — verify `nvim --headless -c "MasonInstallAll" -c "sleep 12" -c "qa"` completes, then `nvim --headless -c "checkhealth mason" -c "qa" 2>&1 | grep -i "ERROR"` empty, `pyright`/`ruff` works out-of-box.
- [ ] **`telescope-fzf-native` `make` guard:** Often missing `make`/`gcc` in core deps — verify `command -v make && command -v gcc` after install; `:checkhealth` no `WARN` for fzf-native; editor toast on `executable("make")==0`.
- [ ] **which-key popup on `<Space>`:** Often missing — verify `nvim --headless -c "lua print(require('which-key'))" -c "qa"` no error; open `nvim` and press `<Space>` → which-key popup with `find`/`search`/`git` nested hints (`preset=modern`, `delay=200`).
- [ ] **Hyprland `exec` guard for `server`:** Often missing mode marker read — verify `cat ~/.config/dotfiles/mode` equals `--mode`; `grep -n DOTFILES_MODE zsh/.zprofile` present with `command -v Hyprland` + `|| true`; simulated `tty1` login as `server` does not `exec`.
- [ ] **Secrets hygiene & machine-local:** Often missing `.gitignore` entries + `secrets.nu` ignored — verify `grep -q "zsh/.zshrc.local" .gitignore && grep -q "secrets.nu" .gitignore`; `grep -R MISTRAL_API_KEY nushell/ --include="*.nu" | grep -v example | grep -v "default \"\""` empty; `git log --all -p -S MISTRAL_API_KEY` empty after rotation.
- [ ] **PATH dedup + `stow` stow-dir invarian:** Often missing — verify `echo $PATH | tr : "\n" | sort | uniq -d` empty; invoking `bash ./setup.sh` vs `bash /abs/path/setup.sh` both resolve `SCRIPT_DIR` to repo root and `stow --dir`.
- [ ] **Health gate / self-test:** Often missing `test -L`, `zoxide --version`, `checkhealth` zero warnings — verify `bash setup.sh --self-test` TAP `ok 1 stow nvim`, `ok 2 stow starship folding`, `ok 3 fzf >=0.48 branch`, `ok 4 bindkey ^R`, `ok 5 Mason packages`, `ok 6 checkhealth zero ERRORs` and exits non-zero on any failure.

---

## Recovery Strategies

When pitfalls occur despite prevention, cheapest fix first.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| **Bash strict-mode crash (`unbound variable`, `PIPESTATUS 141`)** | LOW | `shellcheck -S warning setup.sh` → add `${1-}` / `${var:-}` / `|| true` on SIGPIPE line; add `shopt -s inherit_errexit`; re-run `bash -x setup.sh --help` until usage prints; `shfmt -w` then commit. |
| **Derivative rejected (Manjaro/EndeavourOS/Mint/Pop!_OS)** | LOW | Hot-fix `get_distro`: add `ID_LIKE` check + `command -v pacman/apt` probe at top; test `env ID=manjaro ID_LIKE=arch bash -c 'source setup.sh; get_distro'` → `arch`; docs: manual `stow --restow nvim zsh starship` as interim. |
| **Checklist bypass / fd swap empty capture** | LOW | Fix wrapper: add `3>&1 1>&2 2>&3 || true`, handle `1`/`255` abort, prefer `--separate-output`; fallback to `read "numbers or all"` for CI; test `whiptail --checklist … 3>&1 1>&2 2>&3` in Bats with stubbed whiptail. |
| **Stow `--adopt` repo pollution** | MEDIUM | If already polluted: `git diff keyd/etc/keyd/default.conf` → `git checkout HEAD -- keyd/etc/keyd/default.conf` (restore committed), `sudo cat /etc/keyd/default.conf > /tmp/host.keyd.conf` to recover host file, `git log -p keyd/etc/keyd/default.conf` to find last good; `stow --no --verbose -t / keyd` preview, then plain `sudo stow -t / keyd`. Prevent next: add conflict gate + `gum confirm`. |
| **Stow folding / half-stow** | MEDIUM | `ls -la ~/.config/nvim ~/.config/starship.toml` → `readlink -f` check; `stow -D -t ~ nvim zsh starship && rm -rf ~/.config/nvim/.git` if dangling; `stow --dir="$(pwd)" --restow nvim zsh starship` from repo root; upgrade `stow 2.3.1 → 2.4.1` (`pacman -S stow` / GNU FTP); verify `stow --no --verbose`. |
| **Partial `pacman`/`apt` install, no re-verify** | LOW | `verify_deps_strict $(get_deps arch local zsh)` after install; on `Remaining:` re-run `sudo pacman -S --needed missing` or `apt update && apt install -y`; log `pacman -Q` / `dpkg -l` for audit; `stow` only after strict passes. |
| **fzf version mismatch `HEIGHT required` / `^R` broken** | LOW | Pin rescue: `fzf_version_ge 0.48.0 && source <(fzf --zsh) \|\| source /usr/share/fzf/key-bindings.zsh`; Zinit: change `https://…/master/shell/key-bindings.zsh → https://…/v0.58.0/shell/key-bindings.zsh`; rebuild `fzf --version` gate in installer; `bindkey '^R' fzf-history-widget` after zinit. |
| **Zsh `Ctrl+R`/`Ctrl+I` double-bind** | LOW | Decide: remove `zi light joshskidmore/zsh-fzf-history-search` (use native fzf `Ctrl-R`), keep `marlonrichert/zsh-autocomplete` with `zstyle ':autocomplete:*' fzf-completion yes`; assert `bindkey '^R' \| grep fzf-history-widget`; restart shell and re-check `zle -l \| grep fzf`. |
| **Hyprland exec kills server login** | LOW | Emergency: `ssh` in on `tty2` (`Ctrl+Alt+F2`) or `DOTFILES_MODE=server bash setup.sh --mode server` writes `~/.config/dotfiles/mode=server`; edit `zsh/.zprofile` guard `[[ "$DOTFILES_MODE" != "server" && -z "$DISPLAY" && $(tty)=="/dev/tty1" && command -v Hyprland ]]`; `exec` → `exec … || true`. |
| **Mason headless not auto-installing** | LOW | `nvim --headless -c "MasonInstallAll" -c "sleep 12" -c "qa"` then `nvim --headless -c "checkhealth mason" -c "qa"`; migrate to `mason-tool-installer check_install(false,true)` (blocking); add `make`+`gcc` to core; on disable `rm -rf ~/.local/share/nvim/mason/packages/<name>`. |
| **lazy.nvim `stable` drift / colorscheme blank** | LOW | Replace `vim.loop` with `vim.uv or vim.loop`; add `shell_error` guard; `git -C ~/.local/share/nvim/lazy/lazy.nvim rev-parse HEAD` vs `jq .["lazy.nvim"] lazy-lock.json`; `nvim --headless -c "Lazy check" -c "qa"`; keep `vim.schedule` colorscheme fallback `habamax`. |
| **Committed `MISTRAL_API_KEY`** | HIGH | Rotate key now (Mistral dashboard); `git filter-repo --invert-paths` or `BFG --replace-text` + force-push; notify clones to `git fetch --all && git reset --hard origin/main`; move to `secrets.nu` ignored + `API_KEY? | default ""` placeholder; enable `gitleaks` pre-commit. Cost HIGH due to history rewrite + collaborator rebase. |
| **Silent language loss (`lang.pythoon` typo)** | LOW | `nvim --headless +"lua print(vim.inspect(require('lang').mason_packages))" +"qa"` → missing server; fix `settings.lua` spelling, restart, `:MasonInstallAll`; ensure `:Noice` shows WARN; keep disabled comments as `--"c"` with reason. |
| **No rollback/snapshot before destructive teardown** | MEDIUM | If just ran `teardown`: restore from `~/.local/state/dotfiles/backups/<ts>/` (manual `make adopt-dry` snapshot) or `git checkout HEAD -- $(stow --no --verbose 2>&1 | awk '{print $NF}')`; next: add `backup_adopted_files()` before `-D`/`--adopt` and keep 5 recent `~/.local/state/dotfiles/backups/`. |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls. Ordering rationale: crash gates first (Phase 1 → every other phase depends on a runnable entry-point), then interactive safety before any write (Phase 2 before Phase 3), then privileged/filesystem correctness (Phase 3 before shell/editor), shell ordering before QoL, editor hardening after shell, polish/secrets/health last.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| **Bash strict-mode crash (`set -euo pipefail`)** | **Phase 1 — Installer Foundation & Safe Flags** | `shellcheck -S warning setup.sh` clean; `bash -x setup.sh --help` prints usage with `set -u`; Bats: every flag permutation under `set -euo pipefail` + `PIPESTATUS 141` guard; `exec` with SIGPIPE (`yes | head -1`) returns 0 not 141. |
| **Distro allowlist rejects derivatives** | **Phase 1 — Installer Foundation** | Bats mock `ID=manjaro ID_LIKE=arch → arch`, `ID=endeavouros ID_LIKE=arch → arch`, `ID=linuxmint ID_LIKE=ubuntu → debian`; live probe `command -v pacman` / `apt-get` on Arch/CachyOS/Ubuntu + live derivatives; `grep -R 'cachyos.*arch.*ubuntu' setup.sh` absent. |
| **Manual package override checklist missing** | **Phase 2 — Dependency Resolution & TUI Ladder** | `bash setup.sh --dry-run` log shows `checklist:` before first `[DRY RUN] Would run: pacman/apt` line; non-TTY `echo | bash setup.sh --yes` uses ON defaults; TAP `ok tui checklist before writes`. |
| **Whiptail fd swap & exit-code mis-handling** | **Phase 2 — TUI Ladder** | Bats stub `whiptail` writing to stderr + exits 0/1/255; assert array parsing `tr -d '"'` / `--separate-output` one per line; Cancel/ESC aborts (return 1) and does not reach `install_deps`; `set -e` survives `whiptail … 3>&1 1>&2 2>&3 \|\| true`. |
| **Stow `--adopt` repo pollution / privileged overwrite** | **Phase 3 — Stow Orchestration & Safety** | `stow --no --verbose -t / keyd` preview in `--dry-run`; `grep -n -- --adopt setup.sh` only under `diff -u` + `confirm` block; `keyd` OFF by default in checklist; privileged sudoers least-privilege; `git diff keyd/` clean after stow. |
| **Stow folding / half-stow / wrong dir** | **Phase 3 — Stow Orchestration** | `stow --version` ≥2.4.1 gate; `[[ -f ./setup.sh ]]` repo-root assert; `test -L ~/.config/nvim && readlink -f ~/.config/nvim/init.lua` + `test -L ~/.config/starship.toml` in `--self-test`; `stow --no --verbose --restow nvim zsh starship` TAP passes. |
| **No post-install lock / re-verify** | **Phase 2 — Dependency Resolution & Lock** | `verify_deps_strict` re-run after `install_deps`; fake `pacman` failure → strict aborts; `make`+`gcc` in `common` and `command -v make/gcc` passes; `core_missing` vs `gui_missing` partitioned; non-interactive `! -t 0` installs core only. |
| **fzf version drift `0.44.1` vs `0.48+`** | **Phase 5 — Zsh QoL & fzf History Fix** | `fzf --version` branch: `≥0.48 → source <(fzf --zsh)`, else legacy; `bindkey '^R' \| grep fzf-history-widget` in self-test; VM matrix: Ubuntu 24.04 `0.44.1` legacy, Arch `0.51+` embedded; Zinit fzf scripts pin to `v0.58.0` not `master`. |
| **Zsh `Ctrl+R`/`Ctrl+I` autocomplete war** | **Phase 5 — Zsh QoL** | One history plugin policy (remove `joshskidmore/zsh-fzf-history-search` when native fzf present); `zstyle ':autocomplete:*' fzf-completion yes`; `zle -l \| grep fzf` and `bindkey "^I"` TAP gates; docs comment `# DO NOT rebind ^R/^I after this`. |
| **Hyprland exec kills server login** | **Phase 4 — Shell Runtime Hardening** | `cat ~/.config/dotfiles/mode` persisted; `grep -q DOTFILES_MODE zsh/.zprofile` + `command -v Hyprland` + `\|\| true`; simulated `tty1` login test: `server` mode no `exec`, `local` with Hyprland present would `exec`; `autostart_hyprland=false` override honored. |
| **Mason headless not auto-installing** | **Phase 6 — Neovim Hardening** | `nvim --headless -c "MasonInstallAll" -c "sleep 12" -c "qa"` or `mason-tool-installer check_install(false,true)` headless sync; `checkhealth mason` zero ERRORs; `require("lang").mason_packages` installed list printed; removal cleans `~/.local/share/nvim/mason` when `nvim` deselected. |
| **Bootstrap drift & colorscheme scheduling** | **Phase 6 — Neovim Hardening** | `rg "vim\.uv or vim\.loop" nvim/.config/nvim/init.lua` + `shell_error` guard present; `git -C "$lazypath" rev-parse HEAD` vs `lazy-lock.json` not diverged months; `nvim --headless -c "Lazy check" -c "qa"` and `checkhealth` zero errors; `vim.schedule(colorscheme)` fallback `habamax`. |
| **Secrets committed (`MISTRAL_API_KEY`)** | **Phase 7 — Polish, Secrets & Machine-Local** | `gitleaks detect --source . --no-git` zero; `grep -R MISTRAL_API_KEY --include="*.nu" --include="*.zsh"` only `example`/`default ""`; `.gitignore` has `zsh/.zshrc.local`, `nvim/lua/local.lua`, `secrets.nu`; `git log --all -p -S MISTRAL_API_KEY` empty post-purge. |
| **Silent language loss (`settings.lua` typo)** | **Phase 6 — Neovim Hardening** | Deliberate `pythoon` typo → `vim.notify WARN` visible via `:Noice` and `checkhealth` WARN; `mason_packages` length in TAP reflects enabled set; README `Edit settings.lua → :MasonInstallAll → :checkhealth` checklist linked. |
| **Theme duplication (4-file `mocha`/`latte`)** | **Phase 7 — Polish & Theme Centralization** | `apply_theme()` validates `alacritty import` vs `starship palette` vs `nvim catppuccin` vs `nushell catppuccin.nu` mismatch WARN; `THEME=mocha` env + `theme.toml` single token doc; currently allowed to warn, not template (deferred). |
| **Ripgrep ignore / PATH length / language scaling** | **Phase 7 — Polish** | `.ignore` at `nvim/.config/nvim/.ignore` excluding `state/|cache/|shada/` + `rg --no-heading` in `grepprg`; `typeset -U path PATH` dedup and `echo $PATH \| tr : "\n" \| sort \| uniq -d` empty TAP line; language tiers doc. |
| **No rollback/snapshot / missing health gate** | **Phase 3 (snapshot) + Phase 7 (health gate)** | Snapshot `~/.local/state/dotfiles/backups/<ts>/` before `-D`/`--adopt` (5 kept) + `stow --no --verbose` preview; `bash setup.sh --self-test` TAP covers all above and fails on any `ERROR`; `stow --no --verbose --restow nvim zsh starship` + `checkhealth` zero warnings documented as VM-less validation. |
| **which-key hints missing** | **Phase 6 — Neovim Hardening** | `folke/which-key.nvim` v3 `preset=modern` + `event="VeryLazy"` spec present; `<Space>` shows `find`/`search`/`git`/`run`/`toggle`/`session` groups; `delay=200` TAP via `nvim --headless -c "lua require('which-key')"` no error. |

**Phase ordering rationale (dependency-driven):**
1. **Foundation first** — `set -euo` crash and derivative-reject both brick every later phase; fix entry-point before any TUI/stow/editor work.
2. **TUI before writes** — checklist must precede `pacman -S`/`stow` (safety invariant; no destructive write without preview/confirmation). Hence Phase 2 (checklist + re-verify lock) precedes Phase 3 (stow).
3. **Filesystem correctness before shell/editor** — symlink folding and privileged `/etc/keyd` correctness determine where `~/.config/nvim`/`~/.zshrc` actually resolve; shell `zsh/.zprofile` guard writes `~/.config/dotfiles/mode` that editor later reads. Hence Phase 3 → Phase 4.
4. **Shell init ordering before QoL** — P10k instant prompt top + zoxide last is the contract; `Ctrl+R` fzf version branch and bindkey conflict both depend on that base ordering, so Phase 4 precedes Phase 5.
5. **Editor hardening mid-pipeline** — Mason headless + lazy pin + which-key share the `lang` aggregator and `lazy-lock.json`; they are a natural bundle after shell is stable (Phase 6).
6. **Polish last** — secrets hygiene, theme centralization, PATH dedup, `.local` gitignore, and the final `--self-test` health gate aggregate all previous phases and become the release gate (Phase 7). Any later drift is caught by the gate.

**Research flags for phases:**
- **Phase 6 (Neovim Mason headless + Treesitter `main`):** Likely needs deeper research — Mason registry `mason-org` vs legacy `williamboman`, `nvim-treesitter main` (4916d65) vs `master`, headless blocking semantics, and `:MasonInstallAll` vs `mason-tool-installer` debounce. Starship `scan_timeout` per-mode tuning also deferred.
- **Phase 5 (fzf history):** Medium — fzf `0.48+` embedded vs legacy script distribution is version-coupled and host-dependent (Ubuntu `0.44.1` baseline). Ladder `fzf --multi` fallback needs per-distro testing.
- **Phase 3 (Stow folding):** Standard but high-stakes — Stow 2.4.1 upgrade and `--dir`/`-t` target nuance only surface on moved-repro or overlapping `~/.config` packages.
- **Phase 7 (Secrets):** Low-code but HIGH-severity — history purge `filter-repo` vs `BFG` and gitleaks pre-commit vary per team; plan before milestone.

---

## Sources

- **GNU Stow 2.4.1 manual** — https://www.gnu.org/software/stow/manual/stow.html — `--adopt` warning, tree folding (§5.1), two-phase conflict check (since 2.0), `find_stowed_path` fix — HIGH (official). Cross-checked with 2.4.1 NEWS (2024-09).
- **GNU Stow release notes** — 2.4.0 (2024-04) / 2.4.1 (2024-09) — `--dotfiles` + `find_stowed_path` + Perl 5.40 warning fixes — HIGH (official).
- **`man os-release(5)` + systemd os-release example** — `ID_LIKE` space-separated, `[ "${ID_LIKE#*debian*}" != "$ID_LIKE" ]` probe — HIGH (official).
- **BashFAQ 105 / `The Set Builtin` (Bash Reference Manual)** — `errexit` ignored in `if`/`while`/`&&`/`||`/pipeline-but-last, `pipefail` rightmost non-zero — HIGH (official) — used to justify SIGPIPE guard.
- **Arch BBS `set -uo pipefail` thread (Alad, Ataraxy, 2018-10-05)** — `set -euo pipefail is not recommended in any way. Don't trust blogs … Instead of set -u, use shellcheck … Instead of pipefail, consider PIPESTATUS` + `makepkg disables errexit` — MEDIUM (verified primary-community wisdom, cross-checks BashFAQ dissent).
- **imrekoszo / mohanpedala gists + `linuxize.com` 2026-04-20 Bash Strict Mode** — `set -euo pipefail`, `IFS=$'\n\t'`, `pipefail` `grep … | sort` example, SIGPIPE 141 — LOW→MEDIUM (web, cross-checked with Arch BBS + Bash manual).
- **Shell TUI cheat-sheet (cdocsa)** + **`man whiptail(8)` / `man dialog(1)`** — `3>&1 1>&2 2>&3` fd swap, `--separate-output`, `--output-fd`, exit codes `0/1/255` — MEDIUM (web, cross-checked with Debian/Ubuntu man pages).
- **fzf CHANGELOG 0.48.0–0.52.0 + `pkg.go.dev/github.com/junegunn/fzf` + `junegunn/fzf` issues #1304/#1639/#4211/#4294** — `source <(fzf --zsh)` / `eval "$(fzf --bash)"` embedded, `HEIGHT required` mismatch when binary vs master `key-bindings.zsh` — MEDIUM (verified via primary CHANGELOG + issue #4211).
- **Context7 `/folke/lazy.nvim`** — `vim.uv or vim.loop` + `git clone --filter=blob:none --branch=stable` + `vim.v.shell_error` + `pin/tag/commit/version` + `lazy-lock.json` — MEDIUM (verified).
- **Context7 `/mason-org/mason.nvim` + `/mason-org/mason-lspconfig` + `/WhoIsSethDaniel/mason-tool-installer`** — `mason.txt` `nvim --headless` blocking when no UIs, `Registry.refresh`/`is_installed`/`ensure_installed`/`run_on_start`/`check_install(false,true)` sync — MEDIUM (verified) + Issues #103/#467/#1618 cross-checked async.
- **Context7 `/folke/which-key.nvim` v3** — `preset="modern"`, `spec`/`triggers={"<auto>"}`, `delay=200`, `event="VeryLazy"` — MEDIUM (verified). v2 `register()` removal breaking change noted.
- **Powerlevel10k `zsh-bench#instant-prompt` / issues #2502/77 + `zinox9/zsh-windows` instant-prompt docs** — instant prompt must stay `close to the top`, console I/O above preamble, `POWERLEVEL9K_INSTANT_PROMPT=off` fallback — MEDIUM (verified via primary issue + docs).
- **zoxide CHANGELOG 0.9.8/0.10.0 + `docs.rs`** — `--score`, `doctor` (diagnoses `PROMPT_COMMAND`/`ble.sh`), `import` (atuin), fzf `0.51+` minimum — LOW→MEDIUM (web, cross-check).
- **Host probes (ground truth)** — `bash 5.2.21`, `stow 2.3.1`, `zsh 5.9`, `nvim v0.12.2`, `fzf 0.44.1`, `whiptail 0.52.24`, `starship 1.24.2`, `zoxide 0.9.3` on `/etc/os-release ID=ubuntu ID_LIKE=debian` — HIGH (local execution, STACK.md).
- **Dotfiles community patterns (web cross-check, MEDIUM):** Aman1337g (`--adopt` handling + `~/.local/state/dotfiles/backups/` 5 recent), FluxxField (`make adopt-dry` + `--adopt` merge), Robert Lanier (timestamped backup + `uninstall.sh --auto`), `superhighfives/dotfiles` (allowlist `.gitignore` `.config/*` + `!` opt-in prevent leak, `*.local` additive overlays), `mshuffett/dotfiles` (gum bootstrap), `iatosh/dotfiles` (`~/dotfiles/.secrets` gitignored sourced by `env.zsh`). Used to validate backup/adopt merge, secrets hygiene, and TUI ladder patterns — not as primary spec.
- **Pure MPC `Connecting the : Checked-In Secret Exposure` (2024) — 73.6% .dotfiles leak API keys, 9.5% repositories, `MISTRAL_API_KEY` / `GITHUB_TOKEN` most common** — MEDIUM (academic scan, cross-checks CONCERNS.md `MISTRAL_API_KEY` committed history and gitleaks pattern).

---

*Pitfalls research for: Dotfiles — Unified Installer & Reliability Hardening*  
*Researched: 2026-09-10*  
*Confidence notes: HIGH items are manuals + codebase + host probes. MEDIUM items are cross-checked with 2+ web sources + live repo anchors. No LOW presented as authoritative (per source hierarchy — `websearch` LOW→MEDIUM after cross-check). Gaps flagged in Pitfall-to-Phase Mapping Research flags.*
