#!/usr/bin/env bash
if [ -z "${BASH_VERSION-}" ]; then echo "Error: This installer must be run with Bash." >&2; echo "Use: bash setup.sh [OPTIONS]  (not sh setup.sh)" >&2; echo "See: bash setup.sh --help" >&2; exit 1; fi
set -Eeuo pipefail
shopt -s inherit_errexit

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
UNINSTALL=false
MODE=""
SHELL_CHOICE=""
YES=false
FAMILY=""
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"

# Global to capture missing deps from verify_deps
declare -a VERIFY_MISSING=()

# 01-02: stow orchestration constants
ALL_PACKAGES=(nvim zsh nushell alacritty starship wofi keyd)
GUI_STOW_PACKAGES=(alacritty wofi keyd)
TERMUX_DISABLED_PACKAGES=(alacritty wofi keyd)
declare -a SELECTED_PACKAGES=()
ALL_TOOLCHAIN=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
declare -a SELECTED_DEPS=()

usage() {
    local prog
    prog="$(basename -- "${BASH_SOURCE[0]}")"
    cat << EOF
Usage: $prog [OPTIONS]

Unified Dotfiles Installer (Bash) — Zsh default, Nushell backup

OPTIONS:
    --mode MODE         Deployment mode: 'local' (full GUI) or 'server' (headless)
    --shell SHELL       Shell choice: 'zsh' (default) or 'nushell' (backup)
    --dry-run           Show what would be done without making changes
    --yes               Assume yes for prompts (CI bypass for uninstall and privileged flows)
    --help, -h          Show this help and exit
    --uninstall, --remove  Cleanly unstows selected packages via stow -D plus privileged keyd cleanup and Mason when nvim deselected, typed yes required with --yes bypass for CI, --dry-run previews before every mutation

EXAMPLES:
    $prog --mode local
    $prog --mode server --shell zsh --dry-run
    $prog --help

EOF
}

parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                usage
                exit 0
                ;;
        esac
    done
    while [[ $# -gt 0 ]]; do
        case "${1-}" in
            --mode)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --mode requires an argument (local|server)" >&2
                    usage >&2
                    exit 1
                fi
                case "${2-}" in
                    local|server)
                        MODE="${2-}"
                        ;;
                    *)
                        echo "Error: --mode must be 'local' or 'server' (got '${2-}')" >&2
                        usage >&2
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --shell)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --shell requires an argument (zsh|nushell)" >&2
                    usage >&2
                    exit 1
                fi
                case "${2-}" in
                    zsh|nushell)
                        SHELL_CHOICE="${2-}"
                        ;;
                    *)
                        echo "Error: --shell must be 'zsh' or 'nushell' (got '${2-}')" >&2
                        usage >&2
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes)
                YES=true
                shift
                ;;
            --uninstall|--remove)
                UNINSTALL=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
            --*)
                echo "Unknown option: ${1-}" >&2
                usage >&2
                exit 1
                ;;
            -*)
                echo "Unknown option: ${1-}" >&2
                usage >&2
                exit 1
                ;;
            *)
                echo "Unknown option: ${1-}" >&2
                usage >&2
                exit 1
                ;;
        esac
    done
}

detect_family() {
    if [[ -n "${TERMUX_VERSION-}" ]] || [[ "${PREFIX-}" == *"com.termux"* ]]; then
        echo "termux"
        return 0
    fi
    local have_pacman=false
    local have_apt=false
    if command -v pacman >/dev/null 2>&1; then have_pacman=true; fi
    if command -v apt >/dev/null 2>&1; then have_apt=true; fi
    local id=""
    local id_like=""
    local os_file="${OS_RELEASE_FILE:-/etc/os-release}"
    if [[ -f "$os_file" ]]; then
        # Safe parse without sourcing: extract ID/ID_LIKE without executing file content (mitigates CR-02)
        id="$(grep -E '^ID=' "$os_file" 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null || echo "")"
        id_like="$(grep -E '^ID_LIKE=' "$os_file" 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null || echo "")"
    fi
    local cand
    for cand in $id_like; do
        case "$cand" in
            arch|cachyos|manjaro|endeavouros|garuda) echo "arch"; return 0 ;;
            debian|ubuntu|linuxmint|mint|pop|elementary) echo "debian"; return 0 ;;
            termux) echo "termux"; return 0 ;;
        esac
    done
    case "$id" in
        arch|cachyos|manjaro|endeavouros|garuda) echo "arch"; return 0 ;;
        debian|ubuntu|linuxmint|mint|pop|elementary) echo "debian"; return 0 ;;
        termux) echo "termux"; return 0 ;;
    esac
    if [[ "$have_pacman" == true ]] && [[ "$have_apt" == false ]]; then echo "arch"; return 0; fi
    if [[ "$have_apt" == true ]] && [[ "$have_pacman" == false ]]; then echo "debian"; return 0; fi
    echo "Error: Unable to detect supported distribution." >&2
    echo "This installer supports Arch, Debian-family, and Termux." >&2
    echo "Please refer to README.md for manual installation instructions." >&2
    return 1
}

get_deps() {
    local family="${1-}"
    local mode="${2-}"
    local -a common=()
    local -a gui=()
    # zsh in common ensures Zsh provision before stow per D-12 (Phase 1 make+gcc+fzf+zsh decision)
    # Zinit self-clones on first zsh launch via zsh/.zshrc — no installer clone, no commit pin per D-12
    case "$family" in
        arch)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=(hyprland alacritty wofi keyd waybar grim slurp wl-copy)
            ;;
        debian)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=(alacritty wofi waybar grim slurp wl-copy)
            ;;
        termux)
            common=(stow neovim starship git zoxide uv ripgrep nodejs npm make gcc fzf zsh)
            gui=()
            ;;
        *)
            echo "Error: unknown family '$family'" >&2
            return 1
            ;;
    esac
    local -a _all=()
    if [[ "$mode" == "local" ]]; then _all=("${common[@]}" "${gui[@]}"); else _all=("${common[@]}"); fi
    if [[ ${#SELECTED_DEPS[@]} -gt 0 ]]; then
        local -a _f=()
        local _d
        for _d in "${_all[@]}"; do
            local _is_tc=false
            local _tt
            for _tt in "${ALL_TOOLCHAIN[@]}"; do if [[ "$_d" == "$_tt" ]]; then _is_tc=true; break; fi; done
            if [[ "$_is_tc" == true ]]; then
                local _sel=false
                for _tt in "${SELECTED_DEPS[@]}"; do if [[ "$_tt" == "$_d" ]]; then _sel=true; break; fi; done
                if [[ "$_sel" == true ]]; then _f+=("$_d"); fi
            else
                _f+=("$_d")
            fi
        done
        printf '%s\n' "${_f[@]}"
    else
        printf '%s\n' "${_all[@]}"
    fi
}

# 01-05: filter deps by toolchain selection — only toolchain names are toggleable;
# gui extras (hyprland/waybar/etc.) bypass the filter and are governed by mode alone
filter_deps_by_selection() {
    local -a input=("$@")
    local -a out=()
    local dep
    for dep in "${input[@]}"; do
        local is_toolchain=false
        local t
        for t in "${ALL_TOOLCHAIN[@]}"; do if [[ "$dep" == "$t" ]]; then is_toolchain=true; break; fi; done
        if [[ "$is_toolchain" == true ]]; then
            local sel=false
            for t in "${SELECTED_DEPS[@]}"; do if [[ "$t" == "$dep" ]]; then sel=true; break; fi; done
            if [[ "$sel" == true ]]; then out+=("$dep"); fi
        else
            out+=("$dep")
        fi
    done
    printf '%s\n' "${out[@]}"
}

verify_command() { command -v "${1-}" >/dev/null 2>&1; }

verify_deps() {
    local deps=("$@")
    local -a missing=()
    echo ""
    echo "Verifying dependencies..."
    local dep; local cmd
    for dep in "${deps[@]}"; do
        case "$dep" in neovim) cmd="nvim" ;; ripgrep) cmd="rg" ;; nodejs) cmd="node" ;; *) cmd="$dep" ;; esac
        if ! verify_command "$cmd"; then missing+=("$dep"); echo "  - $dep (missing, need '$cmd')"; else echo "  + $dep (installed)"; fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then echo ""; echo "Missing dependencies: ${missing[*]}"; else echo ""; echo "All dependencies are satisfied."; fi
    VERIFY_MISSING=("${missing[@]}")
}

install_deps() {
    local family="${1-}"
    shift || true
    local -a missing=("$@")
    if [[ ${#missing[@]} -eq 0 ]]; then echo "All dependencies are satisfied."; return 0; fi
    local -a install_cmd=()
    case "$family" in
        arch) install_cmd=(sudo pacman -S --needed --noconfirm) ;;
        debian) install_cmd=(sudo apt install -y) ;;
        termux) install_cmd=(pkg install -y) ;;
        *) echo "Unsupported family for auto-install: $family" >&2; return 1 ;;
    esac
    case "$family" in
        arch)
            echo "Refreshing pacman DB..."
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would run: sudo pacman -Sy"
            else
                if ! sudo pacman -Sy; then echo "Warning: pacman -Sy failed, continuing" >&2; fi
            fi
            ;;
        debian)
            echo "Refreshing apt lists..."
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would run: sudo apt update"
            else
                if ! sudo apt update; then echo "Warning: apt update failed, continuing" >&2; fi
            fi
            ;;
        termux)
            echo "Refreshing pkg lists..."
            if [[ "$DRY_RUN" == true ]]; then
                echo "[DRY RUN] Would run: pkg update -y"
            else
                if ! pkg update -y; then echo "Warning: pkg update failed, continuing" >&2; fi
            fi
            ;;
    esac
    echo ""
    echo "Ready to install: ${missing[*]}"
    if [[ "$DRY_RUN" == true ]]; then echo "[DRY RUN] Would run: ${install_cmd[*]} ${missing[*]}"; return 0; fi
    echo "Installing via: ${install_cmd[*]} ${missing[*]}"
    if [[ "$family" == "termux" ]]; then
        local pkg
        for pkg in "${missing[@]}"; do
            if ! "${install_cmd[@]}" "$pkg"; then
                echo "Warning: failed to install '$pkg' via '${install_cmd[*]} $pkg'." >&2
                echo "  Try manually: ${install_cmd[*]} $pkg" >&2
                echo "  (Package name may differ in Termux repos — check 'pkg search $pkg')" >&2
            fi
        done
    else
        if ! "${install_cmd[@]}" "${missing[@]}"; then echo "Error: package install failed." >&2; return 1; fi
    fi
}

reverify_deps() {
    local family="${1-}"
    local mode="${2-}"
    local -a deps=()
    if ! mapfile -t deps < <(get_deps "$family" "$mode"); then echo "Error: failed to get deps for re-verify" >&2; return 1; fi
    local -a filtered=()
    if [[ ${#SELECTED_DEPS[@]} -eq 0 ]]; then
        filtered=("${deps[@]}")
    else
        if ! mapfile -t filtered < <(filter_deps_by_selection "${deps[@]}"); then echo "Error: failed to filter deps for re-verify" >&2; return 1; fi
    fi
    verify_deps "${filtered[@]}"
    local -a still_missing=("${VERIFY_MISSING[@]}")
    if [[ ${#still_missing[@]} -gt 0 ]]; then
        echo ""; echo "Error: Still missing dependencies after install: ${still_missing[*]}" >&2
        echo "Please install manually:" >&2
        case "$family" in arch) echo "  sudo pacman -S --needed --noconfirm ${still_missing[*]}" >&2 ;; debian) echo "  sudo apt install -y ${still_missing[*]}" >&2 ;; termux) echo "  pkg install -y ${still_missing[*]}" >&2 ;; esac
        return 1
    fi
    echo "Re-verify passed: all dependencies present."
    return 0
}

prompt_mode() {
    echo "" >&2; echo "Select Deployment Mode:" >&2
    echo "1. Local Mode (Full GUI: Hyprland, Alacritty, keyd, etc.)" >&2
    echo "2. Server Mode (Headless: Nvim, Zsh, Starship only)" >&2
    local reply
    while true; do
        if ! read -r -p "Enter choice (1 or 2): " reply; then echo "Error: failed to read input" >&2; exit 1; fi
        case "$reply" in 1) echo "local"; return 0 ;; 2) echo "server"; return 0 ;; *) echo "Invalid choice. Please enter 1 or 2." >&2 ;; esac
    done
}

prompt_shell() {
    echo "" >&2; echo "Select Shell:" >&2
    echo "1. Zsh (default)" >&2; echo "2. Nushell (backup)" >&2
    local reply
    while true; do
        if ! read -r -p "Enter choice (1 or 2) [1]: " reply; then echo "Error: failed to read input" >&2; exit 1; fi
        if [[ -z "$reply" ]]; then reply="1"; fi
        case "$reply" in 1) echo "zsh"; return 0 ;; 2) echo "nushell"; return 0 ;; *) echo "Invalid choice. Please enter 1 or 2." >&2 ;; esac
    done
}

# ──────────────────────────────────────────────
# 01-02: checklist ladder + stow orchestration
# ──────────────────────────────────────────────

strip_termux_disabled() {
    if [[ "${FAMILY:-}" != "termux" ]]; then return 0; fi
    local -a filtered=()
    local pkg; local is_disabled; local d
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        is_disabled=false
        for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            if [[ "$pkg" == "$d" ]]; then is_disabled=true; break; fi
        done
        if [[ "$is_disabled" == true ]]; then echo "Warning: '$pkg' is not available on Termux — skipping." >&2
        else filtered+=("$pkg"); fi
    done
    SELECTED_PACKAGES=("${filtered[@]}")
}

preview_selection() {
    echo ""
    echo "=== DRY RUN: Preview of selected packages ==="
    echo "Selection: ${SELECTED_PACKAGES[*]:-<none>}"
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            if [[ "${FAMILY:-}" == "termux" ]]; then
                echo "[DRY RUN] Would skip keyd — not available on Termux"
                continue
            fi
            echo ""
            echo "=== Privileged keyd preview (no writes) ==="
            echo "[PREVIEW] stow --dir=\"$SCRIPT_DIR\" --target=/ --no --verbose keyd"
            if command -v stow >/dev/null 2>&1; then
                stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd 2>&1 | sed 's/^/  /' || true
            else
                echo "  (stow not found — would install via package manager first)"
            fi
            local host_conf="/etc/keyd/default.conf"
            local repo_conf="$SCRIPT_DIR/keyd/etc/keyd/default.conf"
            if [[ -f "$host_conf" ]] && [[ ! -L "$host_conf" ]]; then
                echo ""
                echo "Conflict: $host_conf exists as a regular file (not a symlink) — showing diff:"
                diff -u "$host_conf" "$repo_conf" 2>&1 | sed 's/^/  /' || true
            fi
            echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ keyd"
            echo "[DRY RUN] Would run: sudo keyd reload || sudo systemctl reload keyd || true"
            continue
        fi
        echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if command -v stow >/dev/null 2>&1; then echo "[DRY RUN] stow --no --verbose preview for $pkg:"; stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose "$pkg" 2>&1 | sed 's/^/  /' || true
        else echo "  (stow not found — would install via package manager first)"; fi
    done
    echo "[DRY RUN] No changes made. Re-run without --dry-run to apply."
}

quarantine_scan() {
    local ts
    if ! ts=$(date +%Y%m%d-%H%M%S-%N 2>/dev/null | cut -c1-19 2>/dev/null); then
        if ! ts=$(date +%Y%m%d-%H%M%S 2>/dev/null); then ts="$(date +%s)"; fi
        ts="${ts}-$$"
    fi
    local qdir="$SCRIPT_DIR/.stow-conflicts/$ts"
    local manifest="$qdir/MANIFEST"
    local quarantined_count=0
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then continue; fi
        local pkg_dir="$SCRIPT_DIR/$pkg"
        if [[ ! -d "$pkg_dir" ]]; then continue; fi
        while IFS= read -r -d '' src; do
            local rel="${src#$pkg_dir/}"
            local home_target="$HOME/$rel"
            if [[ ! -e "$home_target" && ! -L "$home_target" ]]; then continue; fi
            local canon=""
            if canon=$(readlink -f "$home_target" 2>/dev/null); then
                if [[ "$canon" == "$pkg_dir/"* ]] || [[ "$canon" == "$pkg_dir" ]]; then continue; fi
            fi
            local q_target="$qdir/$rel"
            if [[ -e "$q_target" ]]; then echo "Warning: quarantine target already exists: $q_target — skipping duplicate" >&2; continue; fi
            if [[ "$quarantined_count" -eq 0 ]]; then
                mkdir -p "$qdir"
                {
                    echo "# Stow quarantine manifest"
                    echo "# Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "$ts")"
                    echo "# Restore: mv <quarantined-path> <original-path>"
                    echo "# Or: cat $manifest | while IFS= read -r line; do src=\$(echo \"\$line\" | awk -F' -> ' '{print \$1}'); dst=\$(echo \"\$line\" | awk -F' -> ' '{print \$2}'); mv \"\$dst\" \"\$src\"; done"
                    echo ""
                } > "$manifest"
            fi
            mkdir -p "$(dirname "$q_target")"
            if mv "$home_target" "$q_target"; then echo "$home_target -> $q_target" >> "$manifest"; echo "Quarantined: $home_target -> $q_target"; quarantined_count=$((quarantined_count + 1))
            else echo "Warning: failed to quarantine $home_target" >&2; fi
        done < <(find "$pkg_dir" -type f -print0 2>/dev/null || true)
    done
    if [[ "$quarantined_count" -gt 0 ]]; then
        echo ""
        echo "Quarantine complete: $quarantined_count item(s) moved to $qdir"
        echo "Restore with: mv <quarantined-path> <original-path>"
        echo "See manifest: $manifest"
        echo "Manifest contents:"
        cat "$manifest" 2>/dev/null | sed 's/^/  /' || true
    fi
}

assert_linked() {
    local rel="$1"
    local pkg="$2"
    local abs="$HOME/$rel"
    local got=""
    if [[ ! -e "$abs" ]]; then echo "MISSING: $rel (expected from package $pkg) -> $abs does not exist" >&2; echo "  Expected target: $SCRIPT_DIR/$pkg/$rel" >&2; return 1; fi
    if ! got=$(readlink -f "$abs" 2>/dev/null); then echo "UNRESOLVABLE: $rel -> $abs (readlink -f failed)" >&2; return 1; fi
    case "$got" in
        "$SCRIPT_DIR/$pkg/"*|"$SCRIPT_DIR/$pkg") echo "ok: $rel -> $got"; return 0 ;;
        *) echo "MISMATCH: $rel -> $got (expected under $SCRIPT_DIR/$pkg/)" >&2; echo "  Link: $abs -> $got" >&2; echo "  Expected target prefix: $SCRIPT_DIR/$pkg/" >&2; return 1 ;;
    esac
}

post_verify() {
    echo ""
    echo "Post-verify: checking deployed symlinks..."
    local failed=0; local total=0; local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then continue; fi
        local pkg_dir="$SCRIPT_DIR/$pkg"
        if [[ ! -d "$pkg_dir" ]]; then echo "Warning: package dir not found: $pkg_dir — skipping verify" >&2; continue; fi
        while IFS= read -r -d '' src; do
            local rel="${src#$pkg_dir/}"
            total=$((total + 1))
            if ! assert_linked "$rel" "$pkg"; then failed=$((failed + 1)); fi
        done < <(find "$pkg_dir" -type f -print0 2>/dev/null || true)
    done
    if [[ "$total" -eq 0 ]]; then echo "Post-verify: no files to verify (empty selection or keyd-only)."; echo "Post-verify passed."; return 0; fi
    if [[ "$failed" -gt 0 ]]; then echo "Post-verify FAILED: $failed/$total links bad" >&2; return 1; fi
    echo "Post-verify passed: all $total links verified"
    return 0
}

install_keyd_privileged() {
    if [[ "${FAMILY:-}" == "termux" ]]; then
        echo "Warning: 'keyd' is not available on Termux — skipping privileged install." >&2
        return 0
    fi
    echo ""
    echo "=== Privileged keyd preview (no writes) ==="
    echo "[PREVIEW] stow --dir=\"$SCRIPT_DIR\" --target=/ --no --verbose keyd"
    if command -v stow >/dev/null 2>&1; then
        stow --dir="$SCRIPT_DIR" --target=/ --no --verbose keyd 2>&1 | sed 's/^/  /' || true
    else
        echo "  (stow not found — would install via package manager first)"
    fi
    local host_conf="/etc/keyd/default.conf"
    local repo_conf="$SCRIPT_DIR/keyd/etc/keyd/default.conf"
    local has_regular_conflict=false
    if [[ -f "$host_conf" ]] && [[ ! -L "$host_conf" ]]; then
        has_regular_conflict=true
        echo ""
        echo "Conflict: $host_conf exists as a regular file (not a symlink) — showing diff:"
        diff -u "$host_conf" "$repo_conf" 2>&1 | sed 's/^/  /' || true
    fi
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ keyd"
        if [[ "$has_regular_conflict" == true ]]; then
            echo "[DRY RUN] (conflict detected — would prompt for adopt vs plain stow)"
        fi
        echo "[DRY RUN] Would run: sudo keyd reload || sudo systemctl reload keyd || true"
        return 0
    fi
    local confirmed=false
    if [[ "$YES" == true ]]; then
        confirmed=true
    elif command -v gum >/dev/null 2>&1; then
        if gum confirm "Write privileged keyd config to /etc/keyd/default.conf ?"; then
            confirmed=true
        else
            echo "Privileged keyd install cancelled (gum)." >&2
            return 1
        fi
    else
        local reply=""
        printf "Type 'yes' to confirm privileged keyd install: " >&2
        if ! read -r reply; then
            echo "Error: failed to read input" >&2
            return 1
        fi
        if [[ "$reply" == "yes" ]]; then
            confirmed=true
        else
            echo "Cancelled (expected 'yes')." >&2
            return 1
        fi
    fi
    if [[ "$confirmed" != true ]]; then
        return 1
    fi
    local use_adopt=false
    if [[ "$has_regular_conflict" == true ]]; then
        local adopt_reply=""
        if [[ "$YES" == true ]]; then
            use_adopt=false
        elif command -v gum >/dev/null 2>&1; then
            if gum confirm "Conflict file exists. Adopt host file into repo (moves $host_conf into repo)?"; then
                use_adopt=true
            fi
        else
            printf "Conflict file exists at %s.\n" "$host_conf" >&2
            printf "Type 'adopt' to move host file into repo (stow --adopt), or Enter for plain stow: " >&2
            if ! read -r adopt_reply; then
                adopt_reply=""
            fi
            if [[ "$adopt_reply" == "adopt" ]]; then
                use_adopt=true
            fi
        fi
    fi
    if [[ "$use_adopt" == true ]]; then
        sudo stow --dir="$SCRIPT_DIR" --target=/ --adopt keyd
    else
        sudo stow --dir="$SCRIPT_DIR" --target=/ keyd
    fi
    sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true
}

# D-05 verbatim: offer to remove all installed deps via manager, not only stow config related ones — reuse per-family install names to removal commands, dry-run preview, same yes gate
offer_system_package_removal() {
    if [[ -z "${FAMILY:-}" ]]; then
        # No family detected — cannot determine manager
        return 0
    fi
    local -a candidates=()
    if [[ ${#SELECTED_DEPS[@]} -gt 0 ]]; then
        candidates=("${SELECTED_DEPS[@]}")
    else
        candidates=("${ALL_TOOLCHAIN[@]}")
    fi
    # Filter candidates through filter_deps_by_selection when SELECTED_DEPS is active
    # This preserves ALL_TOOLCHAIN order and respects user's toolchain checklist
    if [[ ${#SELECTED_DEPS[@]} -gt 0 ]]; then
        local -a filtered=()
        if ! mapfile -t filtered < <(filter_deps_by_selection "${candidates[@]}"); then
            filtered=("${candidates[@]}")
        fi
        candidates=("${filtered[@]}")
    fi
    if [[ ${#candidates[@]} -eq 0 ]]; then
        return 0
    fi
    if [[ "$DRY_RUN" == true ]]; then
        local pkg
        for pkg in "${candidates[@]}"; do
            case "$FAMILY" in
                arch) echo "[DRY RUN] Would run: sudo pacman -Rns $pkg" ;;
                debian) echo "[DRY RUN] Would run: sudo apt remove -y $pkg" ;;
                termux) echo "[DRY RUN] Would run: pkg uninstall $pkg" ;;
                *) echo "[DRY RUN] Would run: remove $pkg (unknown family $FAMILY)" ;;
            esac
        done
        return 0
    fi
    echo ""
    echo "=== System packages installed via setup.sh ==="
    printf "  %s\n" "${candidates[@]}"
    echo ""
    local confirmed=false
    if [[ "$YES" == true ]]; then
        confirmed=true
    elif command -v gum >/dev/null 2>&1; then
        local manager="apt"
        case "$FAMILY" in
            arch) manager="pacman" ;;
            debian) manager="apt" ;;
            termux) manager="pkg" ;;
        esac
        if gum confirm "Remove system packages listed above via $manager?"; then
            confirmed=true
        else
            echo "Skipping system package removal." >&2
            return 0
        fi
    else
        local manager="apt"
        case "$FAMILY" in
            arch) manager="pacman" ;;
            debian) manager="apt" ;;
            termux) manager="pkg" ;;
        esac
        local reply=""
        printf "Offer to remove system packages via %s for: %s. Type 'yes' to confirm: " "$manager" "${candidates[*]}" >&2
        if ! read -r reply; then
            echo "Error: failed to read input" >&2
            return 1
        fi
        if [[ "$reply" == "yes" ]]; then
            confirmed=true
        else
            echo "Skipping system package removal." >&2
            return 0
        fi
    fi
    if [[ "$confirmed" != true ]]; then
        echo "Skipping system package removal." >&2
        return 0
    fi
    local pkg
    for pkg in "${candidates[@]}"; do
        local cmd_status=0
        case "$FAMILY" in
            arch)
                if ! sudo pacman -Rns --noconfirm "$pkg" 2>&1; then
                    echo "Warning: failed to remove '$pkg' via 'sudo pacman -Rns --noconfirm $pkg'. Try manually: sudo pacman -Rns $pkg" >&2
                fi
                ;;
            debian)
                if ! sudo apt remove -y "$pkg" 2>&1; then
                    echo "Warning: failed to remove '$pkg' via 'sudo apt remove -y $pkg'. Try manually: sudo apt remove -y $pkg" >&2
                fi
                ;;
            termux)
                if ! pkg uninstall -y "$pkg" 2>&1; then
                    echo "Warning: failed to remove '$pkg' via 'pkg uninstall -y $pkg'. Try manually: pkg uninstall $pkg" >&2
                fi
                ;;
            *)
                echo "Warning: unknown family '$FAMILY' — cannot remove '$pkg'" >&2
                ;;
        esac
    done
    return 0
}

offer_chsh() {
    local zsh_path
    if ! zsh_path="$(command -v zsh 2>/dev/null)"; then
        echo "Warning: zsh not found — cannot offer chsh." >&2
        return 0
    fi
    if [[ -n "${SHELL-}" ]] && [[ "$zsh_path" == "$SHELL" ]]; then
        echo "Default shell already zsh ($SHELL) — skipping chsh offer." >&2
        return 0
    fi
    if [[ "${FAMILY:-}" == "termux" ]]; then
        echo "Termux detected — chsh not applicable; skipping default shell change." >&2
        return 0
    fi
    if ! command -v chsh >/dev/null 2>&1; then
        echo "chsh not found — skipping. Run manually: chsh -s $zsh_path" >&2
        return 0
    fi
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would run: chsh -s $zsh_path" >&2
        return 0
    fi
    local reply
    printf "Change default shell to zsh? Type 'yes' to run chsh -s %s: " "$zsh_path" >&2
    if ! read -r reply; then
        echo "Error: failed to read input" >&2
        return 1
    fi
    if [[ "$reply" != "yes" ]]; then
        echo "Skipping chsh (expected 'yes'). Manually run: chsh -s $zsh_path" >&2
        return 0
    fi
    if ! chsh -s "$zsh_path"; then
        echo "Warning: chsh failed (check /etc/shells contains $zsh_path, or use sudo chsh)." >&2
        return 1
    fi
    echo "Default shell changed to $zsh_path — relogin to take effect." >&2
}

# .stow-conflicts/<timestamp>/ is never auto-deleted on uninstall — remains as safety backup per D-04
run_uninstall() {
    # DRY_RUN preview for HOME stow -D and privileged keyd -D
    if [[ "$DRY_RUN" == true ]]; then
        for pkg in "${SELECTED_PACKAGES[@]}"; do
            if [[ "$pkg" == "keyd" ]]; then
                continue
            fi
            echo "[DRY RUN] Would run: stow --dir=\"$SCRIPT_DIR\" --target=\"$HOME\" --delete $pkg"
            if command -v stow >/dev/null 2>&1; then
                stow --dir="$SCRIPT_DIR" --target="$HOME" --no --verbose --delete "$pkg" 2>&1 | sed 's/^/  /' || true
            else
                echo "  (stow not found — would install via package manager first)"
            fi
        done
        if printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx keyd; then
            echo "[DRY RUN] Would run: sudo stow --dir=\"$SCRIPT_DIR\" --target=/ --no --verbose --delete keyd"
            if command -v stow >/dev/null 2>&1; then
                sudo stow --dir="$SCRIPT_DIR" --target=/ --no --verbose --delete keyd 2>&1 | sed 's/^/  /' || true
            else
                echo "  (stow not found — would install via package manager first)"
            fi
        fi
        # Mason preview when nvim deselected (D-02)
        if ! printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim; then
            if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
                echo "Removing Mason artefacts: ~/.local/share/nvim/mason (nvim deselected)" >&2
                echo "[DRY RUN] Would run: rm -rf ~/.local/share/nvim/mason"
            else
                # Even if dir missing, preview the would-run for verification visibility
                echo "[DRY RUN] Would run: rm -rf ~/.local/share/nvim/mason (nvim deselected, dir not present)"
            fi
        fi
        # Legacy mode file preview (no filesystem touch)
        echo "[DRY RUN] Would run: rm -f ~/.config/dotfiles/mode and $SCRIPT_DIR/.dotfiles-mode (legacy cleanup)"
        # System package preview is handled by offer_system_package_removal when present; for now show hint
        if declare -f offer_system_package_removal >/dev/null 2>&1; then
            offer_system_package_removal
        fi
        return 0
    fi
    if [[ "$YES" != true ]]; then
        if command -v gum >/dev/null 2>&1; then
            if ! gum confirm "Run uninstall (stow -D) for: ${SELECTED_PACKAGES[*]} ?"; then
                echo "Uninstall cancelled." >&2
                return 1
            fi
        else
            local reply=""
            printf "Type 'yes' to confirm: " >&2
            if ! read -r reply; then
                echo "Error: failed to read input" >&2
                return 1
            fi
            if [[ "$reply" != "yes" ]]; then
                echo "Uninstall cancelled (expected 'yes')." >&2
                return 1
            fi
        fi
    fi
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            continue
        fi
        if [[ ! -d "$SCRIPT_DIR/$pkg" ]]; then
            echo "Warning: package dir not found: $SCRIPT_DIR/$pkg — skipping unstow for $pkg" >&2
            continue
        fi
        if ! stow --dir="$SCRIPT_DIR" --target="$HOME" -D "$pkg" 2>&1; then
            echo "Warning: stow -D $pkg returned non-zero (already unstowed or not owned — continuing)" >&2
        else
            echo "Unstowed: $pkg"
        fi
    done
    if printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx keyd; then
        if ! sudo stow --dir="$SCRIPT_DIR" --target=/ -D keyd 2>&1; then
            echo "Warning: sudo stow -D -t / keyd failed (not stowed or not owned — continuing)" >&2
        else
            echo "Unstowed privileged: keyd"
        fi
        sudo keyd reload 2>/dev/null || sudo systemctl reload keyd 2>/dev/null || true
    fi
    # Mason artefact cleanup only when nvim not selected (D-02)
    if ! printf '%s\n' "${SELECTED_PACKAGES[@]}" | grep -qx nvim; then
        if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
            echo "Removing Mason artefacts: ~/.local/share/nvim/mason (nvim deselected)" >&2
            # DRY_RUN already returned above, so this is live path — remove directly
            rm -rf "$HOME/.local/share/nvim/mason"
            rmdir "$HOME/.local/share/nvim" 2>/dev/null || true
        fi
    fi
    # Legacy mode-file cleanup with no error if absent per D-04 and D-11
    rm -f "$HOME/.config/dotfiles/mode" 2>/dev/null || true
    rm -f "$SCRIPT_DIR/.dotfiles-mode" 2>/dev/null || true
    # System package removal offer (D-05) — handled by offer_system_package_removal if defined
    if declare -f offer_system_package_removal >/dev/null 2>&1; then
        offer_system_package_removal || true
    fi
    echo ""
    echo "Uninstall complete. Deployed removal for: ${SELECTED_PACKAGES[*]}"
    return 0
}

run_stow() {
    local pkg
    for pkg in "${SELECTED_PACKAGES[@]}"; do
        if [[ "$pkg" == "keyd" ]]; then
            if ! install_keyd_privileged; then
                echo "Error: privileged keyd install failed." >&2
                return 1
            fi
            continue
        fi
        echo "Stowing $pkg -> \$HOME via stow --dir=\"$SCRIPT_DIR\" --target=\"\$HOME\" --restow $pkg"
        if ! stow --dir="$SCRIPT_DIR" --target="$HOME" --restow "$pkg"; then echo "Error: stow failed for package '$pkg'" >&2; return 1; fi
    done
}

# ── Ladder rung helpers ──

checklist_gum() {
    if ! command -v gum >/dev/null 2>&1; then return 1; fi
    # Compute presets for Termux suffix handling (gum has no ON/OFF, but we still render disabled suffix)
    local -a items=()
    local pkg
    for pkg in "${ALL_PACKAGES[@]}"; do
        local display="$pkg"
        local is_disabled=false
        for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            if [[ "$pkg" == "$d" ]] && [[ "${FAMILY:-}" == "termux" ]]; then is_disabled=true; break; fi
        done
        if [[ "$is_disabled" == true ]]; then display="$pkg (not available on Termux)"; fi
        items+=("$display")
    done
    local out
    local gum_status=0
    # gum choose --no-limit expects items on stdin
    out=$(printf '%s\n' "${items[@]}" | gum choose --no-limit --header "Toggle packages (Space to select, Enter to confirm):" 2>&1) || gum_status=$?
    if [[ $gum_status -ne 0 ]]; then
        echo "Checklist cancelled (gum)." >&2
        return 2
    fi
    if [[ -z "$out" ]]; then
        echo "Checklist cancelled (gum empty selection)." >&2
        return 2
    fi
    SELECTED_PACKAGES=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        line="${line% \(not available on Termux\)}"
        for pkg in "${ALL_PACKAGES[@]}"; do
            if [[ "$line" == "$pkg" ]]; then SELECTED_PACKAGES+=("$pkg"); break; fi
        done
    done <<< "$out"
    if [[ ${#SELECTED_PACKAGES[@]} -eq 0 ]]; then
        echo "Checklist cancelled (no packages selected via gum)." >&2
        return 2
    fi
    strip_termux_disabled
    # After strip, if user selected only disabled, filtered may be empty — still need to handle
    # If filtered empty but original had disabled, we already warned; treat as valid empty? But empty should abort.
    # However preset contract says stripping drops them with warning, not abort, if they slipped through.
    # So if after strip we have at least nvim etc, success.
    echo "Selected via gum: ${SELECTED_PACKAGES[*]:-<none>}" >&2
    echo "7 packages offered" >&2
    echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
    return 0
}

checklist_whiptail() {
    if ! command -v whiptail >/dev/null 2>&1; then return 1; fi
    declare -A preset_state
    local pkg
    for pkg in "${ALL_PACKAGES[@]}"; do preset_state["$pkg"]="ON"; done
    if [[ "$MODE" == "server" ]]; then for pkg in "${GUI_STOW_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    if [[ "$SHELL_CHOICE" == "zsh" ]]; then preset_state["zsh"]="ON"; preset_state["nushell"]="OFF"
    elif [[ "$SHELL_CHOICE" == "nushell" ]]; then preset_state["zsh"]="OFF"; preset_state["nushell"]="ON"; fi
    if [[ "${FAMILY:-}" == "termux" ]]; then for pkg in "${TERMUX_DISABLED_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    local -a args=()
    for pkg in "${ALL_PACKAGES[@]}"; do
        local desc=""
        local state="${preset_state[$pkg]}"
        local is_disabled=false
        for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            if [[ "$pkg" == "$d" ]] && [[ "${FAMILY:-}" == "termux" ]]; then is_disabled=true; break; fi
        done
        if [[ "$is_disabled" == true ]]; then desc="(not available on Termux)"; state="OFF"; fi
        args+=("$pkg" "$desc" "$state")
    done
    local rows
    rows=$(stty size 2>/dev/null | cut -d' ' -f1 2>/dev/null || echo "")
    if [[ -z "$rows" ]] || ! [[ "$rows" =~ ^[0-9]+$ ]]; then rows=24; fi
    if [[ "$rows" -lt 20 ]]; then
        if checklist_read; then return 0; fi
        local rc=$?
        return $rc
    fi
    local list_height=$(( rows - 8 ))
    if [[ "$list_height" -gt 7 ]]; then list_height=7; fi
    if [[ "$list_height" -lt 7 ]]; then list_height=7; fi
    local sel
    local status=0
    sel=$(whiptail --title "Packages" --checklist "Space to toggle (before any write):" 20 78 "$list_height" "${args[@]}" 3>&1 1>&2 2>&3) || status=$?
    if [[ $status -ne 0 ]]; then echo "Checklist cancelled (whiptail)." >&2; return 2; fi
    sel="$(echo "$sel" | xargs 2>/dev/null || echo "$sel")"
    if [[ -z "$sel" ]]; then echo "Checklist cancelled (empty selection via whiptail)." >&2; return 2; fi
    # Safe parse without eval: split quoted output via xargs without code execution (mitigates CR-01)
    local -a parsed=()
    if ! mapfile -t parsed < <(printf '%s' "$sel" | xargs -n1 2>/dev/null); then parsed=(); fi
    local -a filtered=()
    local tok
    local clean
    for tok in "${parsed[@]}"; do
        clean="${tok#\"}"; clean="${clean%\"}"
        clean="${clean#\'}"; clean="${clean%\'}"
        clean="$(echo "$clean" | xargs 2>/dev/null || echo "$clean")"
        [[ -z "$clean" ]] && continue
        for pkg in "${ALL_PACKAGES[@]}"; do if [[ "$clean" == "$pkg" ]]; then filtered+=("$clean"); break; fi; done
    done
    SELECTED_PACKAGES=("${filtered[@]}")
    strip_termux_disabled
    echo "Selected via whiptail: ${SELECTED_PACKAGES[*]:-<none>}" >&2
    echo "7 packages offered" >&2
    echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
    return 0
}

checklist_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then return 1; fi
    declare -A preset_state
    local pkg
    for pkg in "${ALL_PACKAGES[@]}"; do preset_state["$pkg"]="ON"; done
    if [[ "$MODE" == "server" ]]; then for pkg in "${GUI_STOW_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    if [[ "$SHELL_CHOICE" == "zsh" ]]; then preset_state["zsh"]="ON"; preset_state["nushell"]="OFF"
    elif [[ "$SHELL_CHOICE" == "nushell" ]]; then preset_state["zsh"]="OFF"; preset_state["nushell"]="ON"; fi
    if [[ "${FAMILY:-}" == "termux" ]]; then for pkg in "${TERMUX_DISABLED_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    local -a args=()
    for pkg in "${ALL_PACKAGES[@]}"; do
        local desc=""
        local state="${preset_state[$pkg]}"
        local is_disabled=false
        for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            if [[ "$pkg" == "$d" ]] && [[ "${FAMILY:-}" == "termux" ]]; then is_disabled=true; break; fi
        done
        if [[ "$is_disabled" == true ]]; then desc="(not available on Termux)"; state="OFF"; fi
        args+=("$pkg" "$desc" "$state")
    done
    local rows
    rows=$(stty size 2>/dev/null | cut -d' ' -f1 2>/dev/null || echo "")
    if [[ -z "$rows" ]] || ! [[ "$rows" =~ ^[0-9]+$ ]]; then rows=24; fi
    if [[ "$rows" -lt 20 ]]; then
        if checklist_read; then return 0; fi
        local rc=$?
        return $rc
    fi
    local list_height=$(( rows - 8 ))
    if [[ "$list_height" -gt 7 ]]; then list_height=7; fi
    if [[ "$list_height" -lt 7 ]]; then list_height=7; fi
    local sel
    local status=0
    sel=$(dialog --title "Packages" --checklist "Space to toggle (before any write):" 20 78 "$list_height" "${args[@]}" 3>&1 1>&2 2>&3) || status=$?
    if [[ $status -ne 0 ]]; then echo "Checklist cancelled (dialog)." >&2; return 2; fi
    sel="$(echo "$sel" | xargs 2>/dev/null || echo "$sel")"
    if [[ -z "$sel" ]]; then echo "Checklist cancelled (empty selection via dialog)." >&2; return 2; fi
    # Safe parse without eval: split quoted output via xargs without code execution (mitigates CR-01)
    local -a parsed=()
    if ! mapfile -t parsed < <(printf '%s' "$sel" | xargs -n1 2>/dev/null); then parsed=(); fi
    local -a filtered=()
    local tok
    local clean
    for tok in "${parsed[@]}"; do
        clean="${tok#\"}"; clean="${clean%\"}"
        clean="${clean#\'}"; clean="${clean%\'}"
        clean="$(echo "$clean" | xargs 2>/dev/null || echo "$clean")"
        [[ -z "$clean" ]] && continue
        for pkg in "${ALL_PACKAGES[@]}"; do if [[ "$clean" == "$pkg" ]]; then filtered+=("$clean"); break; fi; done
    done
    SELECTED_PACKAGES=("${filtered[@]}")
    strip_termux_disabled
    echo "Selected via dialog: ${SELECTED_PACKAGES[*]:-<none>}" >&2
    echo "7 packages offered" >&2
    echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
    return 0
}

checklist_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then return 1; fi
    local -a items=()
    local pkg
    for pkg in "${ALL_PACKAGES[@]}"; do
        local display="$pkg"
        local is_disabled=false
        for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do
            if [[ "$pkg" == "$d" ]] && [[ "${FAMILY:-}" == "termux" ]]; then is_disabled=true; break; fi
        done
        if [[ "$is_disabled" == true ]]; then display="$pkg (not available on Termux)"; fi
        items+=("$display")
    done
    local out
    local fzf_status=0
    out=$(printf '%s\n' "${items[@]}" | fzf -m --header "Toggle packages (Tab to select, Enter to confirm)" --height=15 --reverse --border 2>&1) || fzf_status=$?
    if [[ $fzf_status -ne 0 ]]; then echo "Checklist cancelled (fzf)." >&2; return 2; fi
    if [[ -z "$out" ]]; then echo "Checklist cancelled (fzf empty)." >&2; return 2; fi
    SELECTED_PACKAGES=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        line="${line% \(not available on Termux\)}"
        for pkg in "${ALL_PACKAGES[@]}"; do if [[ "$line" == "$pkg" ]]; then SELECTED_PACKAGES+=("$pkg"); break; fi; done
    done <<< "$out"
    if [[ ${#SELECTED_PACKAGES[@]} -eq 0 ]]; then echo "Checklist cancelled (fzf no valid selection)." >&2; return 2; fi
    strip_termux_disabled
    echo "Selected via fzf: ${SELECTED_PACKAGES[*]:-<none>}" >&2
    echo "7 packages offered" >&2
    echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
    return 0
}

checklist_read() {
    declare -A preset_state
    local pkg
    for pkg in "${ALL_PACKAGES[@]}"; do preset_state["$pkg"]="ON"; done
    if [[ "$MODE" == "server" ]]; then for pkg in "${GUI_STOW_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    if [[ "$SHELL_CHOICE" == "zsh" ]]; then preset_state["zsh"]="ON"; preset_state["nushell"]="OFF"
    elif [[ "$SHELL_CHOICE" == "nushell" ]]; then preset_state["zsh"]="OFF"; preset_state["nushell"]="ON"; fi
    if [[ "${FAMILY:-}" == "termux" ]]; then for pkg in "${TERMUX_DISABLED_PACKAGES[@]}"; do preset_state["$pkg"]="OFF"; done; fi
    if [[ ! -t 0 ]]; then
        SELECTED_PACKAGES=()
        for pkg in "${ALL_PACKAGES[@]}"; do if [[ "${preset_state[$pkg]}" == "ON" ]]; then SELECTED_PACKAGES+=("$pkg"); fi; done
        strip_termux_disabled
        echo "Selected packages (non-interactive presets): ${SELECTED_PACKAGES[*]:-<none>}" >&2
        echo "7 packages offered" >&2
        echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
        return 0
    fi
    echo "" >&2
    echo "Package checklist — toggle packages before any write (Zsh default, Nushell backup):" >&2
    echo "All 7 packages are individually toggleable. Server mode pre-unchecks GUI; shell choice pre-checks only chosen shell." >&2
    echo "" >&2
    local i=1
    for pkg in "${ALL_PACKAGES[@]}"; do
        local state="${preset_state[$pkg]}"
        local marker="[x]"
        if [[ "$state" != "ON" ]]; then marker="[ ]"; fi
        local note=""
        local is_disabled=false
        if [[ "${FAMILY:-}" == "termux" ]]; then for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do if [[ "$pkg" == "$d" ]]; then is_disabled=true; break; fi; done; fi
        if [[ "$is_disabled" == true ]]; then marker="[ ]"; note=" (not available on Termux — never selectable)"; fi
        printf " %2d %s %s%s\n" "$i" "$marker" "$pkg" "$note" >&2
        i=$((i + 1))
    done
    echo "" >&2
    echo "Enter numbers to toggle (e.g., '1 3' or '1,3'), press Enter to keep presets, or 'c' to cancel:" >&2
    local reply
    if ! read -r -p "> " reply; then echo "Error: failed to read checklist input" >&2; return 1; fi
    reply="$(echo "$reply" | xargs 2>/dev/null || echo "$reply")"
    if [[ "$reply" == "c" ]] || [[ "$reply" == "C" ]] || [[ "$reply" == "cancel" ]]; then echo "Checklist cancelled by user." >&2; return 1; fi
    if [[ -z "$reply" ]]; then
        SELECTED_PACKAGES=()
        for pkg in "${ALL_PACKAGES[@]}"; do if [[ "${preset_state[$pkg]}" == "ON" ]]; then SELECTED_PACKAGES+=("$pkg"); fi; done
        strip_termux_disabled
        echo "Keeping presets: ${SELECTED_PACKAGES[*]:-<none>}" >&2
        echo "7 packages offered" >&2
        echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
        return 0
    fi
    declare -A toggled
    for pkg in "${ALL_PACKAGES[@]}"; do toggled["$pkg"]="${preset_state[$pkg]}"; done
    local normalized="${reply//,/ }"
    local tok
    for tok in $normalized; do
        if ! [[ "$tok" =~ ^[0-9]+$ ]]; then echo "Warning: ignoring invalid token '$tok'" >&2; continue; fi
        if [[ "$tok" -lt 1 ]] || [[ "$tok" -gt ${#ALL_PACKAGES[@]} ]]; then echo "Warning: ignoring out-of-range selection '$tok'" >&2; continue; fi
        local idx=$((tok - 1))
        local target_pkg="${ALL_PACKAGES[$idx]}"
        local is_disabled=false
        if [[ "${FAMILY:-}" == "termux" ]]; then for d in "${TERMUX_DISABLED_PACKAGES[@]}"; do if [[ "$target_pkg" == "$d" ]]; then is_disabled=true; break; fi; done; fi
        if [[ "$is_disabled" == true ]]; then echo "Warning: '$target_pkg' is not available on Termux — cannot be selected." >&2; continue; fi
        if [[ "${toggled[$target_pkg]}" == "ON" ]]; then toggled["$target_pkg"]="OFF"; else toggled["$target_pkg"]="ON"; fi
    done
    SELECTED_PACKAGES=()
    for pkg in "${ALL_PACKAGES[@]}"; do if [[ "${toggled[$pkg]}" == "ON" ]]; then SELECTED_PACKAGES+=("$pkg"); fi; done
    strip_termux_disabled
    echo "Final selection: ${SELECTED_PACKAGES[*]:-<none>}" >&2
    echo "7 packages offered" >&2
    echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
    return 0
}

prompt_checklist() {
    # No-TTY fast path: presets directly, zero prompts
    if [[ ! -t 0 ]]; then
        if ! checklist_read; then return 1; fi
        return 0
    fi
    # TTY: five-backend ladder in locked order, cancel never cascades
    local rc
    if checklist_gum; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if checklist_whiptail; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if checklist_dialog; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if checklist_fzf; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if checklist_read; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]] || [[ $rc -eq 1 ]]; then return 1; fi
    return 1
}

# ──────────────────────────────────────────────
# 01-05: toolchain selection (13 deps) — second checklist
# ──────────────────────────────────────────────

_toolchain_ensure_stow() {
    local found=false
    local s
    for s in "${SELECTED_DEPS[@]}"; do if [[ "$s" == "stow" ]]; then found=true; break; fi; done
    if [[ "$found" == false ]]; then
        if ! command -v stow >/dev/null 2>&1; then
            echo "Warning: 'stow' is required for deployment — re-enabling." >&2
            local -a old=("${SELECTED_DEPS[@]}")
            SELECTED_DEPS=()
            local pkg
            local was_selected
            for pkg in "${ALL_TOOLCHAIN[@]}"; do
                if [[ "$pkg" == "stow" ]]; then
                    SELECTED_DEPS+=("stow")
                else
                    was_selected=false
                    for s in "${old[@]}"; do if [[ "$s" == "$pkg" ]]; then was_selected=true; break; fi; done
                    if [[ "$was_selected" == true ]]; then SELECTED_DEPS+=("$pkg"); fi
                fi
            done
        fi
    fi
}

toolchain_gum() {
    if ! command -v gum >/dev/null 2>&1; then return 1; fi
    local -a items=()
    local pkg
    for pkg in "${ALL_TOOLCHAIN[@]}"; do
        local display="$pkg"
        if [[ "$pkg" == "stow" ]]; then display="$pkg (required for deployment)"; fi
        items+=("$display")
    done
    local out
    local gum_status=0
    out=$(printf '%s\n' "${items[@]}" | gum choose --no-limit --header "Toggle toolchain (Space to select, Enter to confirm):" 2>&1) || gum_status=$?
    if [[ $gum_status -ne 0 ]]; then echo "Checklist cancelled (gum)." >&2; return 2; fi
    if [[ -z "$out" ]]; then echo "Checklist cancelled (gum empty selection)." >&2; return 2; fi
    SELECTED_DEPS=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        line="${line% \(required for deployment\)}"
        for pkg in "${ALL_TOOLCHAIN[@]}"; do if [[ "$line" == "$pkg" ]]; then SELECTED_DEPS+=("$pkg"); break; fi; done
    done <<< "$out"
    if [[ ${#SELECTED_DEPS[@]} -eq 0 ]]; then echo "Checklist cancelled (no toolchain selected via gum)." >&2; return 2; fi
    _toolchain_ensure_stow
    echo "Selected via gum: ${SELECTED_DEPS[*]:-<none>}" >&2
    echo "13 toolchain offered" >&2
    return 0
}

toolchain_whiptail() {
    if ! command -v whiptail >/dev/null 2>&1; then return 1; fi
    declare -A preset_state
    local pkg
    for pkg in "${ALL_TOOLCHAIN[@]}"; do preset_state["$pkg"]="ON"; done
    local -a args=()
    for pkg in "${ALL_TOOLCHAIN[@]}"; do
        local desc=""
        local state="${preset_state[$pkg]}"
        if [[ "$pkg" == "stow" ]]; then desc="(required for deployment)"; fi
        args+=("$pkg" "$desc" "$state")
    done
    local rows
    rows=$(stty size 2>/dev/null | cut -d' ' -f1 2>/dev/null || echo "")
    if [[ -z "$rows" ]] || ! [[ "$rows" =~ ^[0-9]+$ ]]; then rows=24; fi
    if [[ "$rows" -lt 20 ]]; then
        if toolchain_read; then return 0; fi
        local rc=$?
        return $rc
    fi
    local list_height=$(( rows - 8 ))
    if [[ "$list_height" -gt 13 ]]; then list_height=13; fi
    if [[ "$list_height" -lt 7 ]]; then list_height=7; fi
    local sel
    local status=0
    sel=$(whiptail --title "Toolchain" --checklist "Space to toggle (before any write):" 20 78 "$list_height" "${args[@]}" 3>&1 1>&2 2>&3) || status=$?
    if [[ $status -ne 0 ]]; then echo "Checklist cancelled (whiptail)." >&2; return 2; fi
    sel="$(echo "$sel" | xargs 2>/dev/null || echo "$sel")"
    if [[ -z "$sel" ]]; then echo "Checklist cancelled (empty selection via whiptail)." >&2; return 2; fi
    local -a parsed=()
    if ! mapfile -t parsed < <(printf '%s' "$sel" | xargs -n1 2>/dev/null); then parsed=(); fi
    local -a filtered=()
    local tok
    local clean
    for tok in "${parsed[@]}"; do
        clean="${tok#\"}"; clean="${clean%\"}"
        clean="${clean#\'}"; clean="${clean%\'}"
        clean="$(echo "$clean" | xargs 2>/dev/null || echo "$clean")"
        [[ -z "$clean" ]] && continue
        for pkg in "${ALL_TOOLCHAIN[@]}"; do if [[ "$clean" == "$pkg" ]]; then filtered+=("$clean"); break; fi; done
    done
    SELECTED_DEPS=("${filtered[@]}")
    _toolchain_ensure_stow
    echo "Selected via whiptail: ${SELECTED_DEPS[*]:-<none>}" >&2
    echo "13 toolchain offered" >&2
    return 0
}

toolchain_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then return 1; fi
    declare -A preset_state
    local pkg
    for pkg in "${ALL_TOOLCHAIN[@]}"; do preset_state["$pkg"]="ON"; done
    local -a args=()
    for pkg in "${ALL_TOOLCHAIN[@]}"; do
        local desc=""
        local state="${preset_state[$pkg]}"
        if [[ "$pkg" == "stow" ]]; then desc="(required for deployment)"; fi
        args+=("$pkg" "$desc" "$state")
    done
    local rows
    rows=$(stty size 2>/dev/null | cut -d' ' -f1 2>/dev/null || echo "")
    if [[ -z "$rows" ]] || ! [[ "$rows" =~ ^[0-9]+$ ]]; then rows=24; fi
    if [[ "$rows" -lt 20 ]]; then
        if toolchain_read; then return 0; fi
        local rc=$?
        return $rc
    fi
    local list_height=$(( rows - 8 ))
    if [[ "$list_height" -gt 13 ]]; then list_height=13; fi
    if [[ "$list_height" -lt 7 ]]; then list_height=7; fi
    local sel
    local status=0
    sel=$(dialog --title "Toolchain" --checklist "Space to toggle (before any write):" 20 78 "$list_height" "${args[@]}" 3>&1 1>&2 2>&3) || status=$?
    if [[ $status -ne 0 ]]; then echo "Checklist cancelled (dialog)." >&2; return 2; fi
    sel="$(echo "$sel" | xargs 2>/dev/null || echo "$sel")"
    if [[ -z "$sel" ]]; then echo "Checklist cancelled (empty selection via dialog)." >&2; return 2; fi
    local -a parsed=()
    if ! mapfile -t parsed < <(printf '%s' "$sel" | xargs -n1 2>/dev/null); then parsed=(); fi
    local -a filtered=()
    local tok
    local clean
    for tok in "${parsed[@]}"; do
        clean="${tok#\"}"; clean="${clean%\"}"
        clean="${clean#\'}"; clean="${clean%\'}"
        clean="$(echo "$clean" | xargs 2>/dev/null || echo "$clean")"
        [[ -z "$clean" ]] && continue
        for pkg in "${ALL_TOOLCHAIN[@]}"; do if [[ "$clean" == "$pkg" ]]; then filtered+=("$clean"); break; fi; done
    done
    SELECTED_DEPS=("${filtered[@]}")
    _toolchain_ensure_stow
    echo "Selected via dialog: ${SELECTED_DEPS[*]:-<none>}" >&2
    echo "13 toolchain offered" >&2
    return 0
}

toolchain_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then return 1; fi
    local -a items=()
    local pkg
    for pkg in "${ALL_TOOLCHAIN[@]}"; do
        local display="$pkg"
        if [[ "$pkg" == "stow" ]]; then display="$pkg (required for deployment)"; fi
        items+=("$display")
    done
    local out
    local fzf_status=0
    out=$(printf '%s\n' "${items[@]}" | fzf -m --header "Toggle toolchain (Tab to select, Enter to confirm)" --height=15 --reverse --border 2>&1) || fzf_status=$?
    if [[ $fzf_status -ne 0 ]]; then echo "Checklist cancelled (fzf)." >&2; return 2; fi
    if [[ -z "$out" ]]; then echo "Checklist cancelled (fzf empty)." >&2; return 2; fi
    SELECTED_DEPS=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        line="${line% \(required for deployment\)}"
        for pkg in "${ALL_TOOLCHAIN[@]}"; do if [[ "$line" == "$pkg" ]]; then SELECTED_DEPS+=("$pkg"); break; fi; done
    done <<< "$out"
    if [[ ${#SELECTED_DEPS[@]} -eq 0 ]]; then echo "Checklist cancelled (fzf no valid selection)." >&2; return 2; fi
    _toolchain_ensure_stow
    echo "Selected via fzf: ${SELECTED_DEPS[*]:-<none>}" >&2
    echo "13 toolchain offered" >&2
    return 0
}

toolchain_read() {
    declare -A preset_state
    local pkg
    for pkg in "${ALL_TOOLCHAIN[@]}"; do preset_state["$pkg"]="ON"; done
    if [[ ! -t 0 ]]; then
        SELECTED_DEPS=()
        for pkg in "${ALL_TOOLCHAIN[@]}"; do if [[ "${preset_state[$pkg]}" == "ON" ]]; then SELECTED_DEPS+=("$pkg"); fi; done
        _toolchain_ensure_stow
        echo "Selected toolchain (non-interactive presets): ${SELECTED_DEPS[*]:-<none>}" >&2
        echo "13 toolchain offered" >&2
        return 0
    fi
    echo "" >&2
    echo "Toolchain — toggle dependencies before any write (13 individually toggleable):" >&2
    echo "" >&2
    local i=1
    for pkg in "${ALL_TOOLCHAIN[@]}"; do
        local state="${preset_state[$pkg]}"
        local marker="[x]"
        if [[ "$state" != "ON" ]]; then marker="[ ]"; fi
        local note=""
        if [[ "$pkg" == "stow" ]]; then note=" (required for deployment)"; fi
        printf " %2d %s %s%s\n" "$i" "$marker" "$pkg" "$note" >&2
        i=$((i + 1))
    done
    echo "" >&2
    echo "Enter numbers to toggle (e.g., '1 3' or '1,3'), press Enter to keep presets, or 'c' to cancel:" >&2
    local reply
    if ! read -r -p "> " reply; then echo "Error: failed to read toolchain checklist input" >&2; return 1; fi
    reply="$(echo "$reply" | xargs 2>/dev/null || echo "$reply")"
    if [[ "$reply" == "c" ]] || [[ "$reply" == "C" ]] || [[ "$reply" == "cancel" ]]; then echo "Checklist cancelled by user." >&2; return 1; fi
    if [[ -z "$reply" ]]; then
        SELECTED_DEPS=()
        for pkg in "${ALL_TOOLCHAIN[@]}"; do if [[ "${preset_state[$pkg]}" == "ON" ]]; then SELECTED_DEPS+=("$pkg"); fi; done
        _toolchain_ensure_stow
        echo "Keeping presets: ${SELECTED_DEPS[*]:-<none>}" >&2
        echo "13 toolchain offered" >&2
        return 0
    fi
    declare -A toggled
    for pkg in "${ALL_TOOLCHAIN[@]}"; do toggled["$pkg"]="${preset_state[$pkg]}"; done
    local normalized="${reply//,/ }"
    local tok
    for tok in $normalized; do
        if ! [[ "$tok" =~ ^[0-9]+$ ]]; then echo "Warning: ignoring invalid token '$tok'" >&2; continue; fi
        if [[ "$tok" -lt 1 ]] || [[ "$tok" -gt ${#ALL_TOOLCHAIN[@]} ]]; then echo "Warning: ignoring out-of-range selection '$tok'" >&2; continue; fi
        local idx=$((tok - 1))
        local target_pkg="${ALL_TOOLCHAIN[$idx]}"
        if [[ "${toggled[$target_pkg]}" == "ON" ]]; then toggled["$target_pkg"]="OFF"; else toggled["$target_pkg"]="ON"; fi
    done
    SELECTED_DEPS=()
    for pkg in "${ALL_TOOLCHAIN[@]}"; do if [[ "${toggled[$pkg]}" == "ON" ]]; then SELECTED_DEPS+=("$pkg"); fi; done
    _toolchain_ensure_stow
    echo "13 toolchain offered" >&2
    return 0
}

prompt_toolchain_checklist() {
    if [[ "$YES" == true ]]; then
        SELECTED_DEPS=("${ALL_TOOLCHAIN[@]}")
        _toolchain_ensure_stow
        echo "Selected toolchain (--yes presets): ${SELECTED_DEPS[*]:-<none>}" >&2
        echo "13 toolchain offered" >&2
        return 0
    fi
    if [[ ! -t 0 ]]; then
        if ! toolchain_read; then return 1; fi
        return 0
    fi
    local rc
    if toolchain_gum; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if toolchain_whiptail; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if toolchain_dialog; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if toolchain_fzf; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]]; then return 1; fi
    if toolchain_read; then return 0; fi; rc=$?
    if [[ $rc -eq 2 ]] || [[ $rc -eq 1 ]]; then return 1; fi
    return 1
}

main() {
    parse_args "$@"
    if [[ ! -f "$SCRIPT_DIR/setup.sh" ]]; then echo "Error: run from the dotfiles repo root (setup.sh not found in $SCRIPT_DIR)." >&2; exit 1; fi
    if [[ ! -f ./setup.sh ]]; then
        echo "Error: setup.sh must be run from the dotfiles repo root." >&2
        echo "This installer uses stow --dir=\"\$SCRIPT_DIR\" and expects to be run from the clone root." >&2
        echo "Please cd to the dotfiles clone and run: bash setup.sh [OPTIONS]" >&2
        echo "Current directory: $PWD (./setup.sh not found) — run-from-clone required." >&2
        exit 1
    fi
    local is_tty=false
    if [[ -t 0 ]]; then is_tty=true; fi
    if [[ -z "$MODE" ]] || [[ -z "$SHELL_CHOICE" ]]; then
        if [[ "$is_tty" == false ]]; then echo "Error: --mode and --shell are required in non-interactive mode." >&2; echo "Provide: --mode local|server --shell zsh|nushell" >&2; usage >&2; exit 1
        else
            if [[ -z "$MODE" ]]; then local prompted_mode; if ! prompted_mode=$(prompt_mode); then echo "Error: failed to prompt for mode" >&2; exit 1; fi; MODE="$prompted_mode"; fi
            if [[ -z "$SHELL_CHOICE" ]]; then local prompted_shell; if ! prompted_shell=$(prompt_shell); then echo "Error: failed to prompt for shell" >&2; exit 1; fi; SHELL_CHOICE="$prompted_shell"; fi
        fi
    fi
    if ! FAMILY=$(detect_family); then exit 1; fi
    echo "Detected family: $FAMILY"
    echo "Selected mode: $MODE"
    echo "Selected shell: $SHELL_CHOICE"
    if [[ "$DRY_RUN" == true ]]; then echo "=== DRY RUN MODE: No changes will be applied ==="; fi
    if [[ "$UNINSTALL" == true ]]; then
        echo ""
        echo "=== Package Selection (uninstall) ==="
        if ! prompt_checklist; then echo "Uninstall cancelled at package checklist." >&2; exit 1; fi
        if [[ ${#SELECTED_PACKAGES[@]} -eq 0 ]]; then echo "No packages selected — nothing to unstow. Exiting." >&2; echo "No packages to unstow."; exit 0; fi
        echo ""
        echo "Final package selection (uninstall): ${SELECTED_PACKAGES[*]}"
        echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
        echo "7 packages offered" >&2
        if ! run_uninstall; then exit 1; fi
        exit 0
    fi
    echo ""
    echo "=== Package Selection ==="
    if ! prompt_checklist; then echo "Installation cancelled at package checklist." >&2; exit 1; fi
    if [[ ${#SELECTED_PACKAGES[@]} -eq 0 ]]; then echo "No packages selected — nothing to stow. Exiting." >&2; echo "No packages to deploy."; exit 0; fi
    echo ""
    echo "Final package selection: ${SELECTED_PACKAGES[*]}"
    echo "Final selection: ${SELECTED_PACKAGES[*]} (offered 7, selected ${#SELECTED_PACKAGES[@]})" >&2
    echo "7 packages offered" >&2
    echo ""
    echo "=== Toolchain Selection ==="
    if ! prompt_toolchain_checklist; then echo "Installation cancelled at toolchain checklist." >&2; exit 1; fi
    echo ""
    echo "Final toolchain selection: ${SELECTED_DEPS[*]} (offered 13, selected ${#SELECTED_DEPS[@]})" >&2
    echo "13 toolchain offered" >&2
    local -a deps=()
    if ! mapfile -t deps < <(get_deps "$FAMILY" "$MODE"); then echo "Error: failed to get dependencies for $FAMILY/$MODE" >&2; exit 1; fi
    local -a filtered_deps=()
    if ! mapfile -t filtered_deps < <(filter_deps_by_selection "${deps[@]}"); then echo "Error: failed to filter deps" >&2; exit 1; fi
    verify_deps "${filtered_deps[@]}"
    local -a missing=("${VERIFY_MISSING[@]}")
    local -a gui_list=()
    case "$FAMILY" in arch) gui_list=(hyprland alacritty wofi keyd waybar grim slurp wl-copy) ;; debian) gui_list=(alacritty wofi waybar grim slurp wl-copy) ;; termux) gui_list=() ;; esac
    local -a core_missing=()
    local -a gui_missing=()
    local m; local g; local is_gui
    for m in "${missing[@]}"; do
        is_gui=false; for g in "${gui_list[@]}"; do if [[ "$m" == "$g" ]]; then is_gui=true; break; fi; done
        if [[ "$is_gui" == true ]]; then gui_missing+=("$m"); else core_missing+=("$m"); fi
    done
    if command -v stow >/dev/null 2>&1; then
        local stow_ver_str=""; local stow_ver=""; local outdated=false
        if stow_ver_str=$(stow --version 2>/dev/null); then
            if stow_ver=$(printf '%s' "$stow_ver_str" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1); then
                if [[ -n "$stow_ver" ]]; then
                    local smallest=""
                    if smallest=$(printf '%s\n' "$stow_ver" "2.4.1" | sort -V | head -n 1); then
                        if [[ "$smallest" == "$stow_ver" ]] && [[ "$stow_ver" != "2.4.1" ]]; then outdated=true; fi
                    fi
                fi
            fi
        fi
        if [[ "$outdated" == true ]]; then
            local stow_selected=false
            local _sd
            for _sd in "${SELECTED_DEPS[@]}"; do if [[ "$_sd" == "stow" ]]; then stow_selected=true; break; fi; done
            if [[ "$stow_selected" == true ]]; then
                echo "Stow $stow_ver < 2.4.1 — will upgrade via $FAMILY manager."
                local found=false; local p
                for p in "${missing[@]}"; do if [[ "$p" == "stow" ]]; then found=true; break; fi; done
                if [[ "$found" == false ]]; then missing+=("stow"); core_missing+=("stow"); fi
            fi
        fi
    fi
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "=== Preview ==="
        if [[ ${#core_missing[@]} -gt 0 ]] || [[ ${#gui_missing[@]} -gt 0 ]]; then
            echo "Dependency Status"
            echo "----------------------------------------"
            if [[ ${#core_missing[@]} -gt 0 ]]; then echo "Missing CORE deps: ${core_missing[*]}"; else echo "Core deps: OK"; fi
            if [[ ${#gui_missing[@]} -gt 0 ]]; then echo "Missing GUI deps: ${gui_missing[*]}"; else echo "GUI deps: OK"; fi
            echo ""
        else
            echo "All dependencies are satisfied."
            echo ""
        fi
        if [[ ${#missing[@]} -gt 0 ]]; then
            install_deps "$FAMILY" "${missing[@]}"
            echo ""
            echo "DRY RUN: Skipped re-verify (no changes made)."
        else
            echo "No install needed — second run is a safe no-op for deps."
            echo ""
            echo "DRY RUN: deps already satisfied."
        fi
        echo "Toolchain preview: ${#missing[@]} to install among ${#SELECTED_DEPS[@]} selected"
        preview_selection
        # DRY_RUN chsh preview — mirrors live offer_chsh when zsh binary exists and SHELL differs
        {
            local _chsh_zsh_path=""
            if _chsh_zsh_path="$(command -v zsh 2>/dev/null)"; then
                if [[ -z "${SHELL-}" ]] || [[ "$_chsh_zsh_path" != "$SHELL" ]]; then
                    if [[ "${FAMILY:-}" != "termux" ]]; then
                        if command -v chsh >/dev/null 2>&1; then
                            echo "[DRY RUN] Would run: chsh -s $_chsh_zsh_path"
                        fi
                    fi
                else
                    echo "Default shell already zsh ($SHELL) — skipping chsh offer."
                fi
            fi
        } || true
        echo ""
        echo "DRY RUN complete — no writes performed."
        return 0
    fi
    if [[ ${#core_missing[@]} -gt 0 ]] || [[ ${#gui_missing[@]} -gt 0 ]]; then
        echo ""; echo "Dependency Status"; echo "----------------------------------------"
        if [[ ${#core_missing[@]} -gt 0 ]]; then echo "Missing CORE deps: ${core_missing[*]}"; else echo "Core deps: OK"; fi
        if [[ ${#gui_missing[@]} -gt 0 ]]; then echo "Missing GUI deps: ${gui_missing[*]}"; else echo "GUI deps: OK"; fi
    fi
    if [[ ${#missing[@]} -gt 0 ]]; then
        install_deps "$FAMILY" "${missing[@]}"
        if ! reverify_deps "$FAMILY" "$MODE"; then exit 1; fi
        echo ""; echo "Dependencies verified and installed successfully."
    else
        echo ""; echo "All dependencies are satisfied."
        echo "No install needed — second run is a safe no-op for deps."
        echo ""
    fi
    quarantine_scan
    if ! run_stow; then echo "Error: stow deployment failed." >&2; exit 1; fi
    if ! post_verify; then echo "Error: post-verify failed — deployment incomplete." >&2; exit 1; fi
    offer_chsh || true
    echo ""
    echo "Setup complete. Deployed: ${SELECTED_PACKAGES[*]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi
