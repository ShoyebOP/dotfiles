---
phase: 02-safe-reversible-server-safe-deployment
slug: safe-reversible-server-safe-deployment
status: verified
threats_open: 0
asvs_level: 1
created: 2026-09-12T02:46:00Z
updated: 2026-09-12T02:46:00Z
---

# Phase 02 — Security: Safe, Reversible & Server-Safe Deployment

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CLI args → setup.sh parse_args | Untrusted user input, TTY vs no-TTY, --help must win before any write | CLI flags, env vars; validation before mutation |
| setup.sh → HOME symlinks (stow --dir/--target/--delete) | Deletes only links stow owns; must not follow or delete quarantine | Filesystem symlinks under $HOME/.config |
| setup.sh → /etc/keyd via sudo stow -t / | Privileged filesystem write; requires preview + diff + explicit confirmation before --adopt | /etc/keyd/default.conf (regular file vs symlink) |
| setup.sh → OS package manager (pacman/apt/pkg) | Privileged package removal; must be explicit yes gated and dry-run previewable | Package names via ALL_TOOLCHAIN/SELECTED_DEPS |
| setup.sh → ~/.local/share/nvim/mason | User data deletion gated on nvim deselection only | Mason artefacts directory |
| setup.sh → OS user account via chsh | Changes /etc/passwd login shell; must never auto-run, requires explicit yes | Login shell string vs $SHELL, `which zsh` |
| Docs → user expectations (README.md, AGENTS.md) | Docs must not promise pre-Phase-2 behavior (--adopt without gate, Nushell default) | Markdown documentation |
| teardown deletion → git history | Reversibility via git history, not shims | Git commits |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-02-01 | Spoofing | parse_args --help/unknown handling | medium | mitigate | Pre-scan for --help before while loop, `${1-}` guards under `set -u`, unknown abort with usage nonzero before any prompt or write | closed |
| T-02-02 | Tampering | stow -D deletes wrong target | high | mitigate | `stow --dir="$SCRIPT_DIR" --target="$HOME" -D` only, never rm -rf on repo dirs; check `[[ -d "$SCRIPT_DIR/$pkg" ]]` before -D; warn on non-zero instead of abort; leave .stow-conflicts intact | closed |
| T-02-03 | Tampering | sudo stow --adopt -t / keyd | high | mitigate | Preview `stow --no --verbose -t / keyd` + `diff -u` when host file is regular file, gum confirm → Type yes fallback, adopt only on second explicit adopt confirmation (exact `adopt` string), otherwise plain sudo stow | closed |
| T-02-04 | Elevation of Privilege | sudo keyd reload / systemctl reload | medium | mitigate | Reload with `|| true` so failure never kills session; least-privilege sudoers `reload keyd` / `keyd reload` only (README.md:119), not start/stop | closed |
| T-02-05 | Denial of Service | zsh/.zprofile exec on tty1 | high | mitigate | Delete exec block per D-10, no mode file read/write per D-11, login is no-op; reversible via git history; verified `grep -q exec` 0 hits | closed |
| T-02-06 | Information Disclosure | .stow-conflicts quarantine deletion | medium | mitigate | Never auto-delete .stow-conflicts/<timestamp>/MANIFEST on uninstall; rm -rf only targets mason artefacts when nvim deselected (`grep -q "rm -rf.*\.stow-conflicts" setup.sh` returns 0) | closed |
| T-02-07 | Repudiation | uninstall without typed confirmation | medium | mitigate | Typed `yes` exact case-sensitive, --yes bypass only for CI, --dry-run prints [DRY RUN] Would run: stow ... and sudo stow --no --verbose without filesystem touch; verified `bash setup.sh --dry-run --uninstall --mode server --shell zsh --yes` | closed |
| T-02-SC | Tampering | Host package manager installs/removals | high | mitigate | Reuse per-family install names to binary probe map, dry-run preview `[DRY RUN] Would run: pacman -Rns/apt remove/pkg uninstall` before any mutation, per-package graceful failure with warn-continue | closed |
| T-02-08 | Spoofing | setup.sh usage/docs mismatch | medium | mitigate | Keep README.md quick-start and setup.sh usage() heredoc in sync: both show Default Zsh | Backup Nushell and bash setup.sh --mode local as primary, verified by `grep -q "Default: Zsh"` | closed |
| T-02-09 | Tampering | setup.sh installer cloning Zinit | medium | mitigate | Never run git clone for Zinit in setup.sh per D-12; leave self-clone in zsh/.zshrc only (`! grep -q "git clone.*zinit" setup.sh` passes, `grep -q "git clone.*zinit" zsh/.zshrc` passes) | closed |
| T-02-10 | Elevation of Privilege | chsh -s $(which zsh) | high | mitigate | Offer only after quarantine_scan+run_stow+post_verify succeed, require exact Type 'yes', --yes does NOT bypass, --dry-run prints [DRY RUN] Would run: chsh, Termux skipped, already-zsh skipped, wrapped with || true | closed |
| T-02-11 | Repudiation | teardown staged delete without doc fix | low | mitigate | git rm teardown.zsh teardown.nu atomically in same commit that rewrites README --uninstall bullet and keyd sudoers; no shim, recoverable via git history (`test ! -f teardown.*` passes) | closed |
| T-02-12 | Denial of Service | chsh failure kills installer | medium | mitigate | chsh errors warn but do not abort deployment; offer_chsh called as `offer_chsh || true`, and keyd reload similarly `|| true` | closed |
| T-02-13 | Information Disclosure | docs still advertise blank privileged --adopt or start/stop sudoers | medium | mitigate | Rewrite keyd section to preview+diff+adopt gate and replace sudoers with least-privilege reload keyd / keyd reload only per D-09; verified `! grep -q "start keyd.*stop keyd" README.md` | closed |

*Status: open · closed — threats_open counts only open threats at or above workflow.security_block_on (high)*
*Severity: critical > high > medium > low — only open threats at or above high count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

**Evidence summary (closed):**

- VERIFICATION.md 6/6 must-haves verified 2026-09-12, score 6/6, behavior_unverified 0 — all threats wired and flowing (see Key Links + Behavioral Spot-Checks).
- `bash -n setup.sh` exit 0; `bash setup.sh --help` / `--uninstall --help` exit 0 with Usage (help wins before any write).
- `bash setup.sh --dry-run --mode local --shell zsh --yes` prints `=== Privileged keyd preview (no writes) ===` + `[PREVIEW] stow --dir=... --target=/ --no --verbose keyd` + `[DRY RUN] Would run: sudo stow ...` + `[DRY RUN] Would run: sudo keyd reload` — verified.
- `bash setup.sh --dry-run --uninstall --mode server --shell zsh --yes` prints `[DRY RUN] Would run: stow --dir=... --delete nvim/zsh/starship` + `[DRY RUN] Would run: sudo apt remove -y ...` + `[DRY RUN] Would run: rm -f ...mode` — zero writes, idempotent second run identical.
- `grep -q "diff -u" setup.sh` + `grep -q "gum confirm.*privileged" setup.sh` pass; `grep -q "install_keyd_privileged" setup.sh` pass; `! grep -q "rm -rf.*\.stow-conflicts" setup.sh` pass; `! grep -R "dotfiles/mode" setup.sh | grep -v "rm -f"` pass.
- `cat zsh/.zprofile` is 2 lines comment-only, `! grep -q "exec start-hyprland" zsh/.zprofile` pass.
- `grep -q "Zinit clones itself" zsh/.zshrc` pass, `! grep -q "git clone.*zinit" setup.sh` pass; `grep -q offer_chsh setup.sh` + `grep -q "chsh -s" setup.sh` pass and contains no `YES.*chsh` bypass.
- `grep -q "Default: Zsh" README.md` + `grep -q 'stow --dir=. --target="$HOME" --restow nvim zsh starship' README.md` + `grep -q "systemctl reload keyd" README.md` pass; `! grep -rq teardown README.md AGENTS.md setup.sh` pass.
- `02-UAT.md` 2026-09-12: 9/9 passed (8 automated coverage D1-D4 + 1 human confirmation), 0 issues, source automated + user confirmed.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|

*No accepted risks.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-12 | 14 | 14 | 0 | the agent (gsd-security-auditor) via verify-work |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log (none)
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-12
