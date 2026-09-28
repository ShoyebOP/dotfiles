# Phase 2: Safe, Reversible & Server-Safe Deployment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-11
**Phase:** 2-Safe, Reversible & Server-Safe Deployment
**Areas discussed:** Uninstall & cleanup scope, Privileged keyd safety gate, Hyprland server guard, Zsh self-provision & docs canon

---

## Uninstall & cleanup scope

| Option | Description | Selected |
|--------|-------------|----------|
| stow -D only | Run `stow -D` for selected pkgs + `sudo stow -D -t / keyd`; never `rm -rf` repo dirs. Safe, reversible | ✓ |
| stow -D + rm -rf repo dirs | Old teardown `rm -rf ./nvim` destructive | |
| stow -D detected only | Only unstow packages currently symlinked (`test -L`) | |

**User's choice:** `stow -D only` (Recommended)
**Notes:** Matches PROJECT Reversibility constraint; repo stays intact.

---

## Uninstall & cleanup scope — Mason

| Option | Description | Selected |
|--------|-------------|----------|
| If nvim not selected now | During --uninstall, if nvim was previously stowed or deselected, remove `~/.local/share/nvim/mason` | ✓ |
| Always on uninstall | Every --uninstall removes Mason artefacts | |
| Never auto, docs only | Never delete Mason automatically; hint `rm -rf` | |

**User's choice:** `If nvim not selected now` (Recommended)

---

## Uninstall — typed yes guard

| Option | Description | Selected |
|--------|-------------|----------|
| Exact 'yes' + --yes bypass, dry-run previews | Interactive `Type 'yes' to confirm:` case-sensitive; `--yes` skips for CI; `--dry-run --uninstall` prints `stow -D --no --verbose` preview | ✓ |
| Simple y/n + --yes | Prompt y/n | |
| No guard when --dry-run | --dry-run never prompts | |

**User's choice:** `Exact 'yes' + --yes bypass, dry-run previews` (Recommended)

---

## Uninstall — idempotence & leftover state

| Option | Description | Selected |
|--------|-------------|----------|
| Clear mode file, keep conflicts | Remove `~/.config/dotfiles/mode` on full uninstall; leave `.stow-conflicts/<ts>/` quarantine untouched | ✓ (later overridden by Hyprland no-mode) |
| Keep mode file | Leave mode file in place | |
| Clear everything | Remove mode + purge `.stow-conflicts/` | |

**User's choice:** `Clear mode file, keep conflicts` then overridden by Hyprland decision `No persisted mode needed` — final: no mode file at all; keep `.stow-conflicts/`
**Notes:** Interim decision before Hyprland exec removal; final D-11 supersedes.

---

## Uninstall — offer to remove all installed system deps

| Option | Description | Selected |
|--------|-------------|----------|
| Offer to remove deps | On --uninstall, list stow-selected toolchain deps that are still installed and offer `pacman -Rns` / `apt remove -y` / `pkg uninstall` only after same `yes` guard, with dry-run preview. Idempotent | ✓ |
| Just hint, don't auto-remove | Print `To remove deps: sudo pacman -Rns ...` but never run | |
| Never touch system pkgs | Uninstall only touches stow symlinks | |

**User's choice:** `Offer to remove deps` (Recommended) — user clarified twice verbatim: "it should also delete the packages it installed" and "it should offer to remove all the packages not only stow config related ones, all the packages that were installed with setup" — captured as offer to remove ALL `pacman`/`apt`/`pkg` deps from the verify→install lock, gated by same `yes` guard + dry-run preview

---

## Privileged keyd safety gate — preview

| Option | Description | Selected |
|--------|-------------|----------|
| Always preview + diff | Before any sudo write, run `stow --no --verbose -t / keyd`; if `/etc/keyd/default.conf` exists and is not a symlink, show `diff -u` | ✓ |
| Dry-run only | Only show preview when --dry-run is passed | |
| Preview without diff | Show stow --no preview but never diff the host file | |

**User's choice:** `Always preview + diff` (Recommended) — shown in normal runs and as `[DRY RUN] Would run: sudo stow ...`

---

## Privileged keyd — adopt vs plain stow

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt only after explicit confirm | Use plain `sudo stow -t / keyd` by default; only use `--adopt` when conflict file exists as regular file AND user confirms | ✓ |
| Always try adopt | Always use `sudo stow --adopt -t / keyd` after confirmation | |
| Never use adopt | Never use --adopt; abort with manual backup instructions | |

**User's choice:** `Adopt only after explicit confirm` (Recommended)

---

## Privileged keyd — confirmation ladder

| Option | Description | Selected |
|--------|-------------|----------|
| gum confirm → Type 'yes' fallback | Try `gum confirm` first; if missing, prompt `Type 'yes' to confirm privileged keyd install:` case-sensitive. --yes bypass for CI | ✓ |
| Always Type 'yes' | Always require typed `yes` even if gum available | |
| Simple y/n | Prompt y/n | |

**User's choice:** `gum confirm → Type 'yes' fallback` (Recommended)

---

## Privileged keyd — reload & sudoers

| Option | Description | Selected |
|--------|-------------|----------|
| keyd reload + docs | Run `sudo keyd reload` (or `systemctl reload keyd` with `|| true`) after successful privileged stow; document least-privilege sudoers (`NOPASSWD: /usr/bin/systemctl reload keyd, /usr/bin/keyd reload`) in README | ✓ |
| Reload only, no docs | Run reload but don't document sudoers | |
| No auto reload | Skip automatic reload; print hint | |

**User's choice:** `keyd reload + docs` (Recommended)

---

## Hyprland server guard — mode file location

| Option | Description | Selected |
|--------|-------------|----------|
| ~/.config/dotfiles/mode literal | Installer writes literal `local`/`server` to `~/.config/dotfiles/mode` | |
| XDG-aware path | Primary `~/.config/dotfiles/mode` but zsh/.zprofile checks XDG override | |
| Env var only | No file; rely on $DOTFILES_MODE env var | |

**User's choice:** Freeform — "it should create in repo root and it should be gitignored" — intermediate, later overridden by Hyprland removal (no file needed)
**Notes:** User initially wanted repo-root gitignored mode file; re-anchored after explaining need for shell to read mode.

---

## Hyprland — mode file read need

| Option | Description | Selected |
|--------|-------------|----------|
| Repo root gitignored + link | Writes repo-root `.dotfiles-mode` gitignored, also ensures `~/.config/dotfiles/mode` symlink | |
| Repo root only | Only repo-root file, patch zsh/.zprofile to read it | |
| Keep SUCCESS path only | Strictly `~/.config/dotfiles/mode` | |

**User's choice:** Freeform — "wait what is yhe need for mode file that it needs zsh/zprofile to read it" — asked for rationale, which unlocked Hyprland removal decision

---

## Hyprland — guard clause

| Option | Description | Selected |
|--------|-------------|----------|
| Mode + Hyprland exists + || true | `if [ "$(cat ~/.config/dotfiles/mode)" != "server" ] && [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && command -v Hyprland ...; then exec start-hyprland \|\| true; fi` | |
| Mode check only | Only check mode != server | |
| Hyprland check only | Only `command -v Hyprland` | |

**User's choice:** Freeform — "no need for that remove that i no longer use tty login so that is redundent" — opted to delete the `exec` block entirely rather than guard it
**Notes:** User no longer uses tty login; session death risk is redundant.

---

## Hyprland — persist mode?

| Option | Description | Selected |
|--------|-------------|----------|
| No persisted mode needed | Remove Hyprland exec entirely; installer does not write any mode file. Next install re-prompts | ✓ |
| Keep mode for recall | Installer still writes mode to repo-root/`~/.config/dotfiles/mode` so re-run recalls previous mode | |
| Repo-root gitignored only | Only repo-root gitignored file | |

**User's choice:** `No persisted mode needed` (Recommended)

---

## Zsh self-provision — Zinit clone

| Option | Description | Selected |
|--------|-------------|----------|
| Before stow, if missing | During deps verify, ensure `zsh` binary; clone `zdharma-continuum/zinit` commit-pinned before `stow --restow zsh` | |
| After stow | Stow zsh first, then clone on first shell start (current inline) | |
| Never clone, docs only | Never clone automatically; hint `git clone ...` | |

**User's choice:** Freeform — "no need to clone anything, zinnit clones itself on first zsh shell launch also no need for pinning. also termux asks an extra login shell prompt which needs to be researched." — No installer clone/pin; Zinit self-clones via zsh/.zshrc inline; Termux login shell prompt flagged as research item

---

## Zsh — chsh offer

| Option | Description | Selected |
|--------|-------------|----------|
| Offer after stow, explicit Type 'yes' only | After successful stow, if `which zsh != $SHELL`, prompt `Change default shell to zsh? Type 'yes' to run chsh -s $(which zsh)` — never auto, --yes does NOT bypass chsh | ✓ |
| Offer only on interactive TTY | Same prompt but skip in non-interactive/CI | |
| Never offer, docs only | Never prompt; print hint `chsh -s $(which zsh)` | |

**User's choice:** Freeform — "offer after stow at the ned when everything is setted up." Mapped to explicit `Type 'yes'` offer at very end after all stow/post-verify
**Notes:** Never auto; --dry-run prints `[DRY RUN] Would run: chsh ...`

---

## Zsh docs — scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full flip, keep backup column | Update README.md table + quick-start + manual stow sections to `Default: Zsh | Backup: Nushell`, primary example `bash setup.sh --mode local` + `--dry-run`, correct `stow --restow nvim zsh starship` vs `nvim nushell starship`; update setup.sh header comments and zsh/.zshrc header; AGENTS.md | ✓ |
| Minimal flip | Only README.md table + setup.sh --help text | |
| Remove Nushell mentions | Full flip and delete Nushell column entirely | |

**User's choice:** `Full flip, keep backup column` (Recommended)

---

## Zsh docs — teardown fallback

| Option | Description | Selected |
|--------|-------------|----------|
| Keep until Phase 2 ships, then delete | Docs note `teardown.*` as fallback until `bash setup.sh --uninstall` lands, then Phase 2 commit deletes teardown scripts and removes mentions atomically (same as Phase 1 staged delete) | ✓ |
| Remove now | Remove all teardown mentions immediately | |
| Never mention teardown | Docs never reference teardown | |

**User's choice:** `Keep until Phase 2 ships, then delete` (Recommended)

---

## The agent's Discretion

None — user decided every question; including two explicit overrides from Recommended (uninstall to remove ALL installed deps, Hyprland exec removal) and two freeform refinements (Zinit no-clone/no-pin + Termux research, chsh at end). No "You decide" selections.

## Deferred Ideas

None — discussion stayed within Phase 2 scope. Termux extra login shell prompt noted as research topic for Phase 2 planning, not deferred to future milestone. Backup/snapshot restore `AUTO-01`/`AUTO-02` remains v2 per REQUIREMENTS.md Out of Scope; not re-raised.

---

## Incremental Checkpoints

- Checkpoint written after Uninstall & cleanup scope: `02-DISCUSS-CHECKPOINT.json` (5 decisions)
- Updated after Privileged keyd safety gate: `02-DISCUSS-CHECKPOINT.json` (9 decisions)
- Updated after Hyprland server guard: `02-DISCUSS-CHECKPOINT.json` (13 decisions)
- Updated after Zsh self-provision & docs: `02-DISCUSS-CHECKPOINT.json` (17 decisions)

User noted auto-advance without explicit `Next area` confirmation and missing checkpoint — corrected in-session: acknowledged, reflected freeform input, rewrote checkpoints after each area, and required explicit `Next area` / `Wrap-up` selection before advancing.
