# Debug Session: shell doesn't change (G-01-16)

**Phase:** 01-universal-installer-platform-foundations
**Gap:** G-01-16
**Symptom:** `also shell doesnt change after all the changes`
**Severity:** major
**Test:** 16

## Symptoms
- User selects `zsh` (default) at `Select Shell: 1. Zsh` prompt
- Installer completes: `Setup complete. Deployed: ...` and `Post-verify passed`
- `echo $SHELL` still shows `/bin/bash` or previous shell, not `/usr/bin/zsh`
- `chsh -l` or `/etc/passwd` unchanged
- Expected: login shell changes to zsh (or at least offer with confirmation)

## Investigation
- Read `setup.sh:663-850` main() full flow
  - No invocation of `chsh`, `usermod`, or `lchsh` anywhere
  - `grep -n "chsh\|usermod" setup.sh` → 0 hits
  - SHELL_CHOICE only drives: (a) preset_state for checklist (zsh ON / nushell OFF) and (b) echo `Selected shell: $SHELL_CHOICE` — never acts on system
  - `get_deps` includes `zsh` in common deps, so zsh binary is installed, but default shell not switched
  - `run_stow` stows `zsh/.zshrc` to `$HOME/.zshrc`, so config is linked, but not active until shell is zsh

- Checked REQUIREMENTS and ROADMAP
  - SHEL-01 (Phase 2): `User gets Zsh provisioned before stow — installer ensures zsh binary present, clones Zinit if missing, and offers chsh -s $(which zsh) only after explicit user confirmation (never auto)`
  - Phase 1 requirements: INST-01, DEPS etc. do NOT include SHEL-01 — shell change is explicitly Phase 2 per ROADMAP
  - 01-01 and 01-02 PLANs also defer Zinit/chsh to Phase 2; Zinit bootstrap currently lives only in `zsh/.zshrc` (runtime clone on first zsh start), not in installer
  - So technically Phase 1 intentionally did not change shell — but user expectation is that selecting a shell should change it, and docs said `Zsh default` suggesting it would.

- Checked `zsh/.zshrc` Zinit bootstrap
  - `zsh/.zshrc:1-30` clones `zdharma-continuum/zinit` to `~/.local/share/zinit` on first zsh run if missing — requires zsh to be running
  - Without chsh, user must manually run `zsh` or `chsh -s $(which zsh)` to activate; installer never prompts

- Checked previous dots: `setup.zsh` donor did have Zinit clone? It did `if [[ ! -d ... ]]; then git clone ...` inside installer? Need to check git history: `setup.zsh` had `zsh` install plus maybe chsh? Let's see `git show` for old setup.zsh
  - `git log --oneline -- setup.zsh` shows donor had `zsh` handling but still Phase 2 scope

- Checked host behavior
  - `which zsh` → `/usr/bin/zsh` exists after deps install
  - `echo $SHELL` → `/bin/bash` (unchanged) — reproduces user report
  - `grep -q chsh zsh/.zshrc` → 0 (no chsh logic in shell config)

- Checked safety constraints
  - `chsh` requires password or sudo depending on distro; must be explicit confirmation (ROADMAP Phase 2 criterion 4: `offers chsh -s $(which zsh) only after explicit confirmation (never auto)`)
  - Must not auto-change without user consent; should use `gum confirm` or `read -p` with `yes` gate, and should be bypassable with `--yes` / non-TTY skip

## Root Cause
**Phase 1 deliberately deferred shell provisioning (SHEL-01) to Phase 2, so SHELL_CHOICE selection only affects stow presets, not the login shell. Installer never invokes `chsh` nor clones Zinit, leaving `$SHELL` unchanged despite user selecting zsh.**

- File: `setup.sh:663-850` — main() lacks chsh offer after `run_stow`/`post_verify`
- File: `zsh/.zshrc` — runtime Zinit clone, not installer-provided
- Missing:
  - Post-stow Zinit ensure step (clone commit-pinned if missing)
  - `chsh -s $(which zsh)` offer with explicit confirmation (`gum confirm` → `read yes` fallback), never auto, with warning that change requires re-login

## Evidence Summary
- `grep -c chsh setup.sh` → 0
- `get_deps` includes zsh, `run_stow` stows zsh config, but `echo $SHELL` remains bash after run
- SHEL-01 is Phase 2 per ROADMAP, so gap is expected per plan but violates user expectation from Phase 1 `Zsh default` messaging
- User report matches: shell doesn't change after all changes

## Files Involved
- `setup.sh:663-850` — needs post-verify shell change offer
- `zsh/.zshrc` — Zinit clone could be moved to installer for eager provisioning (Phase 2 scope)

## Suggested Fix Direction
- Add post-verify step `maybe_change_shell()` after `post_verify` success:
  - If `SHELL_CHOICE == zsh` and `command -v zsh` and `[[ "$SHELL" != *zsh ]]`
  - Print `Your shell is $SHELL; selected shell is zsh. Change login shell to $(which zsh)?`
  - If `gum` available: `gum confirm "Change login shell to zsh?"` else `read -p "Type 'yes' to change shell: "`
  - On yes: `chsh -s $(which zsh)` (no sudo, user-owned), warn `Log out and back in for change to take effect`
  - Else: print `Skipping shell change. Run chsh -s $(which zsh) manually if desired.`
  - Respect `--yes` / non-TTY: skip prompt or auto-confirm if `--yes`, otherwise skip with notice
  - Similarly handle `nushell` if chosen
  - Keep PHASE 1 message: "Shell provisioned, needs re-login" — full Zinit pinning can remain Phase 2 but chsh offer fixes immediate gap
