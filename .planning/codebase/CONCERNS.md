# Codebase Concerns

**Analysis Date:** 2026-09-10

## Tech Debt

**Mirrored bootstrapper implementations without shared source:**
- Issue: `setup.nu` (Nushell) and `setup.zsh` (Zsh) independently implement `get-distro`, `get-deps`, `verify-deps`, `install-deps`, `run-stow` with different syntax; `teardown.nu` vs `teardown.zsh` mirror `run-unstow` similarly; bug fix in one does not propagate
- Files: `setup.nu:1-200`, `setup.zsh:1-200`, `teardown.nu:1-150`, `teardown.zsh:1-150`
- Impact: Drift already observable — `setup.nu` core=`["nvim","nushell","starship"]` vs `setup.zsh` core=`["nvim","zsh"]` divergence, and GUI lists differ; future dependency changes risk inconsistent `--mode local` payloads leading to missing configs on one shell path
- Fix approach: Extract declarative manifest (`deps.toml` or `manifest.json`) listing per-distro core/gui arrays consumed by thin wrappers; or canonicalize on one bootstrapper and shim the other (e.g., `setup.zsh` calls `nu setup.nu` under the hood)

**Stow package coupling to host distro names:**
- Issue: `get-distro` hard-codes `["arch","cachyos","ubuntu"]` allowlist and `get-deps` branches on distro ID; Arch-family names like `manjaro`, `endeavouros` not accepted despite pacman compatibility; `arch` vs `cachyos` treated as distinct despite same package manager
- Files: `setup.nu:get-distro`/`get-deps`, `setup.zsh:get_distro`/`get_deps`, `README.md` table
- Impact: Users on derivatives hit `Error: This script only supports Arch/CachyOS/Ubuntu` and must fall back to manual `stow` per README, bypassing validation
- Fix approach: Normalize `ID_LIKE` from `/etc/os-release` (`ID_LIKE=arch` covers derivatives) and map package manager capability (`pacman` existance) rather than distro string

**Hard-coded theme/palette duplication:**
- Issue: Catppuccin `mocha`/`latte` themes repeated across `alacritty/.config/alacritty/alacritty.toml:1` (`import = ["...catppuccin-mocha.toml"]`), `alacritty/.config/alacritty/catppuccin-mocha.toml:1-200`, `starship/.config/starship.toml:palette='catppuccin_latte'`, `nushell/.config/nushell/scripts/catppuccin.nu`, `nvim/.config/nvim/lua/colorschemes/catppuccin.lua` — no single token
- Files: `alacritty/.config/alacritty/alacritty.toml`, `starship/.config/starship.toml`, `nushell/.config/nushell/scripts/catppuccin.nu`, `nvim/.config/nvim/lua/colorschemes/catppuccin.lua`
- Impact: Changing flavor requires 4+ file edits; inconsistency risk (e.g., alacritty mocha vs starship latte as currently)
- Fix approach: Central `theme.toml` or XDG `THEME` env read by all packages via templating (`chezmoi`/ `yadm` style or shell sed)

**No lock for system package installs:**
- Issue: `setup.*` `install-deps` calls `pacman -S`/`apt install` without pinning versions and without `set -e` coverage for partial installs; rerun is idempotent only for stow, not for package installs
- Files: `setup.nu:install-deps`, `setup.zsh:install_deps`
- Impact: Repeated runs may partial-install; no `pacman -Q`/`dpkg -l` verification post-install
- Fix approach: After install, re-run `verify-deps` and abort with report; log installed versions for drift audit

## Known Bugs

**`zsh/.zprofile` unconditionally execs Hyprland on tty1 under Zsh path only:**
- Symptoms: Nushell users on tty1 never auto-launch Hyprland despite `nushell/.config/nushell/env.nu` containing commented launch guard; Zsh users get Hyprland even when intending `server` headless mode if they ever log in on tty1
- Files: `zsh/.zprofile:2-4` (`if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec start-hyprland; fi`), `nushell/.config/nushell/env.nu:18-20` (commented `if ($env.LAST_EXIT_CODE? == 0) and ((tty)=="/dev/tty1") { exec start-hyprland }`)
- Trigger: Log in via tty1 with Zsh as login shell while `setup.zsh --mode server` previously stowed only `nvim`+`zsh`; Hyprland may not be installed yet `exec` fails and login session dies
- Workaround: `server` users should remove or guard `zsh/.zprofile` Hyprland block, or set `autostart_hyprland=false` flag (not currently supported)

**Zoxide hook double-registration on repeated Nushell config reloads:**
- Symptoms: Re-sourcing `nushell/.config/nushell/config.nu` appends duplicate `__zoxide_hook` entries to `$env.config.hooks.env_change.PWD`; benchmark or history handling slows subtly
- Files: `nushell/.config/nushell/scripts/zoxide.nu:8-22` (guard `if not $__zoxide_hooked { append }`)
- Trigger: Manual `source ~/.config/nushell/config.nu` multiple times without restart — guard checks current table snapshot, but some Nushell versions clone config and miss hook identity
- Workaround: Restart Nushell instead of re-sourcing; see `test-zoxide.nu` hook count assertion

**Telescope fzf-native silently disables if `make` missing:**
- Symptoms: Fuzzy finder falls back to slower generic sorter without user warning beyond status; users expect fzf performance
- Files: `nvim/.config/nvim/lua/plugins/telescope.lua:12-16` (`cond = function() return vim.fn.executable("make")==1 end`)
- Trigger: `setup.zsh --mode server` on minimal image without `make` (README lists `make` under nvim subtree README but not core `setup.*` core deps on non-Arch)
- Workaround: Install `make`/`gcc` manually; no bootstrapper error is surfaced at editor launch

## Security Considerations

**Hard-coded `MISTRAL_API_KEY` committed to git:**
- Risk: Live API credential exposed to every clone and indefinitely in git history (`git log --all -S MISTRAL_API_KEY`); automated scanners (GitHub secret scanning, TruffleHog) will flag; key can be abused for billing and data exfiltration via Mistral API
- Files: `nushell/.config/nushell/env.nu:48` (`$env.MISTRAL_API_KEY = "<redacted>"` — value not reproduced); also `zsh/.zshrc` does not set it but host `opencode` outside repo has `sk-...` — broader secret hygiene concern
- Current mitigation: None — value is tracked, `.gitignore` does not exclude `env.nu`, no `sops`/`git-crypt`/`pass` indirection, no rotation notes
- Recommendations: Rotate key immediately via Mistral dashboard, purge from history (`git filter-repo` or `BFG`) and force-push, move to external secret (`~/.config/nushell/secrets.nu` gitignored, `sops` age key, or `pass`); replace committed line with `$env.MISTRAL_API_KEY = $env.MISTRAL_API_KEY? | default ""` placeholder and document in `README.md`; enable pre-commit `gitleaks`/`git-secrets` hook

**`keyd` privileged `stow --adopt` into `/`:**
- Risk: `sudo stow --adopt -t / keyd` overlays `/etc/keyd/default.conf` but `--adopt` moves conflicting host files into repo, then `sudo keyd reload` and `systemctl` actions run as root; if `keyd/etc/keyd/default.conf` were malicious, it directly impacts input handling. Sudoers NOPASSWD suggestion `shoyeb ALL=(ALL) NOPASSWD: /usr/bin/systemctl start keyd, ...` widens privilege
- Files: `setup.nu:run-stow` (`sudo stow --adopt -t / keyd`), `setup.zsh:run_stow`, `README.md` visudo snippet, `keyd/etc/keyd/default.conf`
- Current mitigation: Interactive confirmation via `get-mode-interactive` + dry-run preview, but no checksum/signature of `default.conf`
- Recommendations: Replace `--adopt` with plain `stow` and explicit conflict check (`stow --no --verbose`), require user confirmation for any `/etc` write, document least-privilege sudoers (only `systemctl start|stop|reload keyd` not all `systemctl`), version `default.conf` with comment hash

**`init.lua` git clone without integrity verification:**
- Risk: `nvim/.config/nvim/init.lua:4-8` clones `https://github.com/folke/lazy.nvim.git --branch stable --filter=blob:none` without tag/commit pin or hash verification; MITM or compromised repo could inject code executed as user
- Files: `nvim/.config/nvim/init.lua:1-11`
- Current mitigation: HTTPS + GitHub implicit trust, `lazy-lock.json` pins downstream plugin commits but not lazy.nvim itself (`lazy.nvim` pinned in lock but bootstrap clone precedes lock check)
- Recommendations: Pin `lazy.nvim` to commit hash in bootstrap or verify post-clone `git rev-parse HEAD` against expected sha listed in `lazy-lock.json`; document in `init.lua` comment

**No `.env` scanning but secrets still slip via `*.nu`:**
- Risk: Workflow forbids reading `.env` contents but Nushell `env.nu` pattern can hold any `*_API_KEY` without detection; current scanner for `CONCERNS.md` focused on `sk-`/`ghp_` patterns but missed `MISTRAL_API_KEY` style
- Files: `nushell/.config/nushell/env.nu`, `zsh/.zshrc`
- Current mitigation: Grep in map workflow checks `sk-`, `akIA`, `-----BEGIN` etc. but not generic `*_API_KEY=` assignments
- Recommendations: Add pre-commit hook scanning for `API_KEY|SECRET|TOKEN` assignments in `*.nu`/`*.zsh`, and extend bootstrap secret grep to `*_API_KEY`

## Performance Bottlenecks

**Neovim startup gated on lazy.nvim git existence check:**
- Problem: Every startup runs `vim.loop.fs_stat(lazypath)` and potentially `vim.fn.system({ "git","clone",... })` (blocking `system` call); on cold machines or flaky GitHub network, launch hangs for seconds
- Files: `nvim/.config/nvim/init.lua:2-9`
- Cause: Synchronous clone during `init.lua` (no async); also 44 plugins with `event` lazy triggers still require spec aggregation and `require("lang")` pcall loop over 14 languages each startup
- Improvement path: Gate clinic clone behind explicit install command (`NvimInstall` not init), keep `fs_stat` fast path but add spinner/timeout; profile via `nvim --startuptime /tmp/start.log` and move heavy `lang` aggregation to deferred `vim.schedule`

**Starship `scan_timeout = 1000` ms:**
- Problem: Starship prompt waits up to 1s per prompt (`starship/.config/starship.toml:1` `scan_timeout=1000` vs default 30ms commented in file) to scan modules (git, language versions)
- Files: `starship/.config/starship.toml:1`
- Cause: Intentional for catppuccin powerline with many segments (`c/rust/golang/nodejs/php/java/kotlin/haskell/python/conda`) — each `cmd` segment spawns subprocess
- Improvement path: Reduce segments in `starship-minimal.toml` variant for server mode, set `scan_timeout=200` and disable unused languages (php/kotlin/haskell commented in practice), enable `starship timings` diagnose

**Nushell config sourcing 400-line `uv.nu` + zoxide hooks at every interactive launch:**
- Problem: `nushell/.config/nushell/config.nu:5-9` sources `uv.nu` (~400-line completions) plus `zoxide.nu` and `venv.nu` on every shell start; history smart filter (`nushell/.config/nushell/config.nu:90-150` history menu source closures filtering `history | where`) scans full history synchronously on `Ctrl+R`
- Files: `nushell/.config/nushell/config.nu:1-180`, `nushell/.config/nushell/scripts/uv.nu:1-500`
- Cause: No lazy-loading for completions; all scripts sourced eagerly
- Improvement path: Gate `uv.nu` externs behind `completer:` demand-load, or move to Nushell `completions/` extern directory; cap `history | where` to last 1000 entries and add index

**Ripgrep-driven grep (`grepprg=rg --vimgrep`) with no ignore custom:**
- Problem: `nvim/.config/nvim/lua/base/options.lua:grepprg` + `telescope live_grep` scans entire `~/dotfiles` plus `~/.config/nvim` state/cache if cwd is `$HOME`; combined with `lazy-lock.json` and history files, `live_grep` can be noisy/slow
- Files: `nvim/.config/nvim/lua/base/options.lua:grepprg`, `nvim/.config/nvim/lua/plugins/telescope.lua:defaults`
- Cause: Missing `.ignore`/`rg` exclusions for `cache/`, `state/`, `shada/`, `.git/`, `undo/`
- Improvement path: Add `.ignore` at `nvim/.config/nvim/.ignore` excluding `state/|cache/|shada/|undo/|.git/|lazy-lock.json` and telescope `file_ignore_patterns`

## Fragile Areas

**`nvim/.config/nvim/lua/settings.lua` single-toggle surface:**
- Files: `nvim/.config/nvim/lua/settings.lua:24` (`languages = { "bash","git","python","javascript",... }`), also `colorscheme = "tokyodark"` line
- Why fragile: Single array controls LSP + formatter + parser + plugin inclusion via `lang/init.lua`; typo (e.g., `"pythoon"`) fails with only `vim.notify WARN "Failed to load: lang.pythoon.pythoon"` and silent feature loss; commenting `languages` entry does not auto-uninstall Mason package leaving stale binary; re-enabling requires remembering `MasonInstallAll`
- Safe modification: Edit `settings.lua`, restart nvim, run `:MasonInstallAll`, `:TSInstallInfo`, `:checkhealth` — verify no WARN toasts; keep desired languages commented with reason rather than deleted
- Test coverage: No automated coverage; manual Lua `pcall` branch untested

**Neovim `init.lua` bootstrap + colorscheme scheduling:**
- Files: `nvim/.config/nvim/init.lua:1-85` (lazy path, `performance.rtp.disabled_plugins` list of 23, `defaults.lazy`, `vim.schedule(colorscheme)`)
- Why fragile: Order-sensitive — `vim.schedule` deferred colorscheme relies on `require("settings")` succeeding after lazy setup; `disabled_plugins` list will break on Neovim upgrade if names change (e.g., `spellfile_plugin` removal); `lazypath` hard-codes `stdpath("data") .. "/lazy/lazy.nvim"` not parameterized
- Safe modification: Change `settings.colorscheme` rather than `init.lua` directly; run `nvim --headless -c "Lazy check" -c "qa"` after any `disabled_plugins` edit; pin Neovim version in README
- Test coverage: None; startup crash requires `nvim --startuptime` bisect

**Stow symlink targets (especially `keyd` / `starship`):**
- Files: `starship/.config/starship.toml` deployed to `~/.config/starship.toml` (note repo stores as `starship/.config/starship.toml` → symlink target must be `~/.config/starship.toml` via stow's directory folding), `keyd/etc/keyd/default.conf` → `/etc/keyd/default.conf`
- Why fragile: Starship `env.nu` sets `$env.STARSHIP_CONFIG = $env.HOME | path join ".config" "starship.toml"` but stow path is `starship/.config/...` — subtle: `stow starship` from repo root creates `~/.config/starship.toml` correctly only if stow's `folding` resolves; if user moves repo or uses `stow` from subdir, links break; keyd's `-t /` requires root and `adopt` can swallow edits
- Safe modification: Always run `setup.* --dry-run` before stow; use `stow --no --verbose` to preview; after move verify `ls -la ~/.config/starship.toml` and `cat /etc/keyd/default.conf` symlink target; document stow invocation directory (repo root) in README
- Test coverage: No symlink integration test; `teardown.*` must be tested after move

**Shell init ordering (`nushell config.nu` zoxide last, Zsh instant prompt first):**
- Files: `nushell/.config/nushell/config.nu:90` comment `zoxide.nu is sourced at the END`, `zsh/.zshrc:8-12` Powerlevel10k instant prompt at top, `zsh/.zshrc:50` `eval "$(zoxide init zsh)"`, `zsh/.zshrc:70` `bindkey -v`+ `zle-keymap-select`
- Why fragile: Swapping order breaks zoxide hooks (Nushell) or instant prompt (Zsh shows warning `P10k instant prompt should stay close to top`); `zsh/.zshrc` also conditionally sources `~/.shell_aliases` before `zoxide init` — alias order matters for `z`/`zi`
- Safe modification: Keep explicit `# NOTE: ... must be sourced last` comments intact; after any reordering, launch fresh shell and verify `z`/`zi` and prompt rendering, `echo $POWERLEVEL9K_INSTANT_PROMPT`
- Test coverage: Only manual; `test-zoxide.nu` catches hook loss but not prompt timing

## Scaling Limits

**Nvim language count linear cost:**
- Current capacity: 14 languages enabled in `nvim/.config/nvim/lua/settings.lua` aggregating ~10 LSP servers (`pyright`, `ruff`, `ts_ls`, etc.), ~12 formatters, ~8 treesitter parsers, 4 extra plugin specs
- Limit: Each added language appends to `mason_packages` and `treesitter_parsers` arrays in `nvim/.config/nvim/lua/lang/init.lua`; `mr.refresh` callback iterates all; with 30+ languages, `:MasonInstallAll` network burst and disk (~500MB parsers) grows linearly, startup `require` loop grows O(n)
- Scaling path: Split `languages` into tiers (`core` always-installed vs `opt-in`), lazy-install via `:MasonInstall <lang>` on first open, or group `treesitter.ensure_installed` behind `require("lang")` defer

**Stow package fan-out:**
- Current capacity: 7 stow packages (`nvim`, `nushell`, `zsh`, `alacritty`, `starship`, `wofi`, `keyd`) plus 2 bootstrap modes; `setup.*` hard-codes lists
- Limit: Adding many packages (e.g., per-app configs) makes `setup.*` `gui_modules` arrays unwieldy; mode matrix (`local` vs `server` × `arch`/`ubuntu`) combinational testing grows
- Scaling path: Replace hard-coded arrays with `packages.json` manifest plus tagging (`tag: core|gui|arch-only`) and generate stow commands dynamically

**Host PATH length:**
- Current capacity: `nushell/.config/nushell/env.nu` and `zsh/.zshrc` each prepend 5+ bins (`~/.local/bin`, `~/.local/sbin`, `~/.cargo/bin`, `~/.bun/bin`, `~/.npm-global/bin`, `~/.local/share/zinit`) — PATH has 10+ segments after starship/zoxide hooks
- Limit: Reaching ARG_MAX / shell `getconf PATH_MAX` or triggering shell completion slowness (especially `uv.nu` 400-line exports per prompt)
- Scaling path: Deduplicate PATH via `str uniq` filter in `env.nu`, move rarely-used bins to lazy `prepend` on demand

## Dependencies at Risk

**`lazy.nvim` on `stable` branch without pin:**
- Risk: Bootstrap clones `branch stable` tip which can introduce breaking changes or revoke APIs used by `nvim/.config/nvim/init.lua:44` `opts.performance.rtp.disabled_plugins` or keymap plugins; reproducibility depends on user manually updating `lazy-lock.json`
- Impact: Fresh clone could get newer `lazy.nvim` incompatible with pinned `lazy.nvim:85c7ff3` in `lazy-lock.json` — bootstrap and lock drift
- Migration plan: Pin bootstrap clone to commit (`git clone --branch v11.x` tag or `--depth 1 --shasum`), add `lazy-lock.json` verify step comparing `lazypath` HEAD to lock entry on startup and warn on mismatch

**Powerlevel10k + Zinit maintenance:**
- Risk: Both `romkatv/powerlevel10k` and `zdharma-continuum/zinit` are community-maintained with bus-factor concerns; `romkatv` archived personal fork discussions; Zinit activation via `git clone` with no hash pin
- Impact: Deprecation would break `zsh/.zshrc` instant prompt and plugin loading for Zsh path users
- Migration plan: Keep Nushell as primary (already favored in `setup.nu` and README `Local` table), vendor Zinit via commit pin in `zsh/.zshrc` clone URL (`--branch v3.14`), evaluate `starship`+`sheldon` alternative if Zinit unmaintained

**`MISTRAL_API_KEY` provider tie-in:**
- Risk: Mistral API itself is external vendor lock; committed key suggests tooling depends on Mistral (perhaps agent or Nushell script not visible) — pricing/auth changes would break that flow silently
- Impact: Credential invalid after rotation breaks any downstream `curl -H "Authorization: Bearer $MISTRAL_API_KEY"` not present in repo but implied
- Migration plan: Abstract via `$env.LLM_API_KEY` generic plus provider switch (OpenAI/Anthropic/Mistral) and keep provider config in ignored `secrets.nu`

**Node/bun duplication for JS LSP:**
- Risk: Repo depends on both `node`+`npm` (setup core) and `bun` (`zsh/.zshrc` BUN_INSTALL, recent commits) for overlapping TS tooling (`typescript-language-server`, `prettier`); Bun not listed in `setup.nu:get-deps` core yet Zsh path assumes it
- Impact: Nushell `server` deploys may miss Bun but have JS language enabled, leading to `mason` package install differing between shells
- Migration plan: Canonicalize runtime (`node` vs `bun`) or list both in core deps for both bootstrappers; decide via `settings.lua` comment and document in README setup table

## Missing Critical Features

**No automated health gate:**
- Problem: No `make test` / `just check` / `git hook` validating stow symlinks, `checkhealth` zero warnings, or `MasonInstallAll` success; `.gitignore` changes like `Fix .gitignore paths for nvim files, untrack machine-specific files` (commits `616b669`, `17530e5`, `116674b`) were fixed manually after leak
- Blocks: Safe PRs and onboarding — new contributor can't `verify` deployment without opening nvim manually

**No rollback/snapshot before destructive teardown:**
- Problem: `teardown.nu`/`teardown.zsh` `unstow` immediately removes symlinks but do not save pre-state (`stow --no` only previews, no backup of replaced files via `--adopt`); `keyd` `--adopt` already moves host file into repo making rollback ambiguous
- Blocks: Recovering from accidental `teardown` or mistaken `--mode local` on server without snapshot

**No secrets management documented:**
- Problem: No `sops`/`age`/`pass`/`git-crypt` setup, no `.secrets.example`, no `env.example` — contributors invent ad-hoc `MISTRAL_API_KEY` placement (as seen) leading to credential leak
- Blocks: Consistent onboarding and secure key rotation

## Test Coverage Gaps

**Bootstrapper integration:**
- What's not tested: `setup.nu` vs `setup.zsh` parity (mode×distro×keyd matrix), `teardown.nu` vs `teardown.zsh` `yes` confirmation, dry-run idempotence, sudo keyd path, failure on Fedora/manifold IDs, missing dep install error path
- Files: `setup.nu:main`+`get-distro`+`get-deps`+`verify-deps`+`run-stow`, `setup.zsh` equivalents, `teardown.nu:main`+`run-unstow`, `teardown.zsh:run_unstow`
- Risk: Regression in one shell path ships undetected (already drift between `core_modules`/`gui_modules`); Privileged `/etc` write could be tested only by accident on user machine
- Priority: High

**Neovim language aggregation:**
- What's not tested: `nvim/.config/nvim/lua/lang/init.lua:deduplicate`, merging of `formatters` maps, `plugin_specs` collection, WARN on missing `lang/<name>/<name>.lua`, `mason_packages` dedup, `nvim/.config/nvim/lua/utils/mason-install-all.lua:get_packages` and `install_all` filtering `is_installed`
- Files: `nvim/.config/nvim/lua/lang/init.lua`, `nvim/.config/nvim/lua/utils/mason-install-all.lua`, each `nvim/.config/nvim/lua/lang/<lang>/*.lua`
- Risk: Typo in `settings.lua:languages` silently loses language support; duplicate Mason package wastes network/disk; `pcall` WARN may be suppressed by `noice.nvim` routing
- Priority: High

**Symlink deployment correctness:**
- What's not tested: Whether `stow --restow nvim` actually creates `~/.config/nvim/init.lua` → repo path, whether confilcts (`existing target is not owned by stow`) are surfaced, whether `keyd` privileged stow correctly targets `/etc/keyd/default.conf` on both stow and unstow
- Files: All `*/.config/**` stow sources plus bootstrappers
- Risk: Fresh clone reports success but links target wrong XDG location (especially `starship.toml` vs `starship/.config/starship.toml` folding), leading to silent wrong config (prompt not themed, keyd not applied, shell still default)
- Priority: High

**Shell init ordering:**
- What's not tested: Nushell `config.nu` sourcing order (zoxide last), Zsh instant prompt still at top after edits, `z`/`zi` aliases functional, Powerlevel10k prompt renders without error on second init, `uv` completions available after `uv generate-shell-completion`
- Files: `nushell/.config/nushell/config.nu:1-180`, `nushell/.config/nushell/scripts/zoxide.nu`, `zsh/.zshrc:1-200`, `zsh/.p10k.zsh`
- Risk: User edits init order to "clean up" and breaks navigation/completion with only manual shell restart to discover
- Priority: Medium

**Starship/Alacritty/Wofi rendering:**
- What's not tested: Starship powerline format `starship/.config/starship.toml:5-15` renders without glyph missing (JetBrainsMono Nerd Font present), Alacritty `catppuccin-mocha.toml` import resolves, wofi `style.css` valid
- Files: `starship/.config/starship.toml`, `starship/.config/starship-minimal.toml`, `alacritty/.config/alacritty/alacritty.toml`, `wofi/.config/wofi/style.css`
- Risk: Theme typo or missing font leads to garbled prompt/terminal with no automated screenshot diff gate
- Priority: Low

---

*Concerns audit: 2026-09-10*
