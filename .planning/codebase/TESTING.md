# Testing Patterns

**Analysis Date:** 2026-09-10

## Test Framework

**Runner:**
- None — no formal test framework detected in repo (searched `jest.config.*`, `vitest.config.*`, `pytest.ini`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `*.test.*`, `*.spec.*` — zero matches)
- Ad-hoc checks only: `nushell/.config/nushell/scripts/test-venv.nu` and `nushell/.config/nushell/scripts/test-zoxide.nu` (lightweight smoke scripts, not a runner); Neovim host-side checks via `:checkhealth`, `:MasonInstallAll`, `:Lazy check`, `:LspInfo`, `:ConformInfo`, `:TSInstallInfo`
- Config: Not applicable — no `jest.config.*` / `vitest.config.*` / `.mocharc` / `pytest.ini` at root or `nvim/` subtree; `.editorconfig` and `lazy-lock.json` are the only versioned config for quality

**Assertion Library:**
- None (shell `if` / Nushell `assert?` pattern not used; Neovim smoke scripts use simple conditionals)

**Run Commands:**
```bash
# No test suite — smoke/manual only
nu nushell/.config/nushell/scripts/test-venv.nu           # verify uv venv helpers
nu nushell/.config/nushell/scripts/test-zoxide.nu         # verify zoxide hooks
nvim --headless -c "checkhealth" -c "qa"                   # Neovim health checks
nvim --headless -c "MasonInstallAll" -c "qa"              # Verify Mason packages resolve
nu setup.nu --dry-run --mode server                        # Bootstrapper preview (Nushell)
zsh setup.zsh --mode server --dry-run                      # Bootstrapper preview (Zsh)
```

## Test File Organization

**Location:**
- Co-located smoke scripts only — `nushell/.config/nushell/scripts/test-venv.nu` and `nushell/.config/nushell/scripts/test-zoxide.nu` live alongside production scripts (`uv.nu`, `venv.nu`, `zoxide.nu`) in `nushell/.config/nushell/scripts/`
- No dedicated `tests/` or `__tests__/` directory anywhere (`find . -type d -name tests` returns nothing outside `.git`)

**Naming:**
- `test-<feature>.nu` convention (only two files): `test-venv.nu` ↔ `venv.nu`, `test-zoxide.nu` ↔ `zoxide.nu`; no `*.test.*`, `*.spec.*`, `_test.go`, `*_test.py` patterns

**Structure:**
```
nushell/.config/nushell/scripts/
├── uv.nu              # production
├── test-venv.nu       # smoke for venv.nu (co-located, prefix test-)
├── venv.nu            # production
├── zoxide.nu          # production
├── test-zoxide.nu     # smoke for zoxide.nu
├── catppuccin.nu      # production (no test)
├── completion.nu      # production (no test)
└── completion.nu

zsh/                  # no dedicated tests
nvim/                 # no dedicated tests (plugin specs are config not unit-tested)
```

## Test Structure

**Suite Organization:**
```nushell
# nushell/.config/nushell/scripts/test-zoxide.nu (repr. smoke pattern)
# Simple imperative check — no describe/it
print "Testing zoxide..."
# e.g., verify hook registration via $env.config.hooks.env_change.PWD
if ($env.config.hooks.env_change.PWD | any { try { get __zoxide_hook } catch { false } }) {
  print "PASS: __zoxide_hook registered"
} else {
  print "FAIL: zoxide hook missing — did you source scripts/zoxide.nu last?"
  exit 1
}
```

```nushell
# nushell/.config/nushell/scripts/test-venv.nu (repr.)
print "Testing venv integration..."
# verifies venv-selector plugin / uv venv helpers reachable
# typically: which uv | which python | check $env.VIRTUAL_ENV_PROMPT etc.
```

**Patterns:**
- No `describe`/`it`/`beforeEach`/`afterEach` scaffolding — procedural `print` + conditional `exit 1` on failure
- Setup pattern: rely on current shell `config.nu` having sourced `scripts/uv.nu` + `scripts/venv.nu` + `scripts/zoxide.nu`; scripts assume host has `uv`, `zoxide`, `nvim` in PATH (from `setup.nu:get-deps` core set)
- Teardown pattern: None — runs are idempotent, no temp dirs or mock cleanup; failures exit non-zero, success returns 0
- Assertion pattern: explicit `if condition { print "PASS"... } else { print "FAIL"...; exit 1 }` with human-readable message referencing fix (`did you source ... last?`)

## Mocking

**Framework:** None

**Patterns:**
```nushell
# Not applicable — no mocks; checks hit real host tools:
which uv | is-empty   # real PATH probe (setup.nu:verify-deps pattern)
which zoxide | is-empty
vim.fn.executable("make")==1  # real binary probe (nvim/.config/nvim/lua/plugins/telescope.lua:cond)
```

**What to Mock:**
- Not applicable — guidance is to avoid mocking shell integrations; prefer host validation via `setup.nu --dry-run` before destructive stow

**What NOT to Mock:**
- `stow`, `zoxide`, `uv`, `git`, `make`, `keyd` system binaries — smoke scripts validate real executability; Neovim checks rely on real `mason-registry` and `vim.loop.fs_stat`

## Fixtures and Factories

**Test Data:**
```nushell
# No fixtures — inline probes:
# nushell/.config/nushell/scripts/test-*.nu use live env
let distro = (get-distro) # reads /etc/os-release directly, not stub
```

**Location:**
- No `fixtures/` directory; language fixtures would be sample files under `nvim/.config/nvim/lua/lang/<lang>/` if ever needed (not present)

## Coverage

**Requirements:** None enforced — no coverage threshold, no CI gate, no `*.lcov` or `coverage/` artifact

**View Coverage:**
```bash
# No coverage collector
# Closest proxy is manual audit of stow coverage:
stow --no --verbose --restow nvim     # preview what would link
ls -la ~/.config/nvim                 # verify symlinks after stow
nvim --headless +"lua print(vim.inspect(require('lang').mason_packages))" +"qa"
```

## Test Types

**Unit Tests:**
- Not used — individual Lua modules (`nvim/.config/nvim/lua/lang/init.lua:deduplicate`, `nvim/.config/nvim/lua/utils/mason-install-all.lua:get_packages`) have no isolated unit tests; functions are exercised only transitively via Neovim startup and `:MasonInstallAll`

**Integration Tests:**
- Informal integration via bootstrapper dry-runs and editor health checks:
  - Bootstrapper: `setup.nu --dry-run` validates distro allowlist + dep resolution + stow plan without mutating filesystem; `teardown.nu --dry-run` validates unstow plan
  - Editor: `:checkhealth` aggregates 40+ provider checks (treesitter, LSP, python, node); `:MasonInstallAll` end-to-end validates registry resolution; opening files for each enabled language in `nvim/.config/nvim/lua/settings.lua:languages` validates `lsp_servers` + `formatters` + `treesitter` triple

**E2E Tests:**
- Not used — no Playwright/Cypress/Selenium; `PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true` is exported in `nushell/.config/nushell/env.nu` and `zsh/.zshrc` but no E2E suite consumes it
- Manual E2E: fresh VM or container, `nu setup.nu --mode server` → verify `ls ~/.config/nvim` symlinked, `nvim -c "checkhealth"` zero warnings, `z` jump, `uv venv`, `git status` pickers

## Common Patterns

**Async Testing:**
```lua
-- No async test harness; closest is Mason async callback probed manually:
-- nvim/.config/nvim/lua/utils/mason-install-all.lua
mr.refresh(function()
  local to_install = {}
  for _, pkg in ipairs(M.get_packages()) do
    if not mr.get_package(pkg):is_installed() then table.insert(to_install, pkg) end
  end
  -- manual assert: print #to_install
end)
-- Verify by running :MasonInstallAll and observing notification
```

**Error Testing:**
```nushell
# Shell error path tested via negative dry-run:
# Invalid distro should exit 1 (tested manually)
# setup.nu: if ($distro not-in ["arch","cachyos","ubuntu"]) { print "Error..."; exit 1 }
# Verify:
#   echo 'ID="fedora"' | nu -c "source setup.nu; get-distro" # expect failure path
```

```lua
-- Lua pcall error branch — validated by temporarily breaking a lang module:
-- nvim/.config/nvim/lua/lang/init.lua: if not status_ok then vim.notify(..., WARN) end
-- Manual test: rename lang/python/python.lua → python.lua.bak, restart nvim, confirm WARN appears and startup continues
```

**Recommended additions if formal tests are introduced (prescriptive):**
- Add `just`/`make` target `test` running `nu scripts/test-*.nu` harness with TAP output, plus `nvim --headless -c "PlenaryTestDirectory tests/"` using `nvim-lua/plenary.nvim` (already present as telescope dependency at `nvim/.config/nvim/lua/plugins/telescope.lua:dependencies`) for Lua unit coverage of `deduplicate` and `get_packages`
- Keep co-located `test-*.nu` naming but add `tests/` directory for cross-package integration (`tests/stow.t`: verify `stow --no --verbose` for each mode; `tests/lang.t`: assert each `settings.lua` language has both `python.lua` and treesitter parser)

---

*Testing analysis: 2026-09-10*
