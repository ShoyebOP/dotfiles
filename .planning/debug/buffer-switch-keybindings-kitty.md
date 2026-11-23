---
status: diagnosed
trigger: "Investigate issue: buffer-switch-keybindings-kitty — <C-,>/<C-.> normal-mode buffer-switch mappings do nothing. User runs kitty, not Alacritty; open to alt+,/alt+. or ctrl+;/ctrl+' or ctrl+[/ctrl+]. Mode: find_root_cause_only (no fix)."
created: 2026-11-23T13:20:00Z
updated: 2026-11-23T13:38:00Z
mode: find_root_cause_only
---

## Current Focus

status: ROOT CAUSE CONFIRMED — diagnosis-only mode, no fix applied
bug_class: Bohrbug / config-as-root-cause (deterministic key-delivery failure in kitty; not timing-dependent)
known_pattern_candidate: none (no `.planning/debug/knowledge-base.md` exists; no prior resolved session matched)
root_cause_summary: >
  Phase-07 QOL-05 rebound buffer cycling to `<C-,>`/`<C-.>`, which are Ctrl+punctuation
  combinations that legacy terminal key encoding cannot express. In kitty's default legacy
  keyboard mode its own `ctrled_key()` has no entry for `,` or `.`, so the `default: return key`
  branch sends a bare `,`/`.` and silently drops the Ctrl modifier. Neovim therefore never
  receives the sequence it binds `<C-,>`/`<C-.>` to and the mappings never fire. The nvim side is
  provably healthy (headless maparg returns the correct buffer-cycle commands). The only shipped
  mitigation was an Alacritty-specific `key_bindings` caveat in the nvim README; the repo ships
  no kitty configuration at all, so the user's actual terminal has no fix.
test: headless keycode/maparg probes + kitty source/docs differential analysis of all 3 suggested combos
expecting: confirmed root cause (achieved)
next_action: return ROOT CAUSE FOUND to orchestrator; do NOT apply fix (find_root_cause_only mode)

## Symptoms

expected: next/previous buffer switches when pressing `<C-,>`/`<C-.>` in normal mode with >=2 buffers open; if the sequence is swallowed, `<C-v><C-,>` in insert mode fails to insert a literal control char, indicating the terminal needs a custom key-binding entry.
actual: "nope this also not works, i am not using alacritty but kitty. even though the problem might be same, i'm open to change the bind with any of the following combinations- \"alt+,/alt+.\", \"ctrl+;/ctrl+'\" or \"ctrl+[/ctrl+]\" and btw i was talking about only the keys not the text itself"
errors: None reported
reproduction: UAT Test 2 — with nvim open on >=2 buffers, press `<C-,>`/`<C-.>` in normal mode (kitty terminal); optionally `<C-v><C-,>` in insert mode to test delivery.
started: Discovered during UAT for Phase 07 (neovim-editor-qol-fixes), 2026-11-23.
scope_note: "i was talking about only the keys not the text itself" concerns ONLY the keybinding keys, not any text/content — the fix scope is the key choices (+ terminal delivery), nothing textual. This quote belongs to UAT Test 2 (this issue), not Test 1 (gutter); the sibling debug session `gutter-git-marker-separator-layout.md` independently reached the same conclusion. "not using alacritty but kitty" corrects the terminal assumption in the plan/README caveat.

## Eliminated

- hypothesis: the nvim-side mappings are missing/mis-wired (bad rhs, shadowed lhs, plugin conflict)
  evidence: Headless probe with the real keymaps.lua loaded reports `maparg('<C-,>','n') = <Cmd>BufferLineCycleNext<CR>` and `maparg('<C-.>','n') = <Cmd>BufferLineCyclePrev<CR>`; `<Tab>`/`<S-Tab>` empty. 07-RESEARCH.md:27 also found `<C-,>`/`<C-.>` unmapped before the change, and 07-VERIFICATION.md gate BUFFER-MAPS-OK passed. The editor side is intact; failure is upstream in terminal->nvim delivery.
  timestamp: 2026-11-23T13:26:00Z
- hypothesis: switching to the user's `ctrl+;/ctrl+'` option avoids the problem
  evidence: Same defect class. kitty's `ctrled_key()` (kitty/key_encoding.c) has no entry for `;` (0x3B) or `'` (0x27); `default: return key` sends the bare character and drops Ctrl. Kitty's own docs table shows `; | ; (59) | : (58) | ESC ; | ; (59) | ...` — plain `;` for Ctrl+;. Harry Min (2025) documents Ctrl+; failing for exactly this reason. Confirmed by kitty source read 2026-11-23.
  timestamp: 2026-11-23T13:34:00Z
- hypothesis: switching to `ctrl+[/ctrl+]` is a safe alternative
  evidence: Headless keycode probe: `nvim_replace_termcodes('<C-[>')` = single byte `1b`, byte-for-byte identical to `<Esc>` (`C-[ == Esc ? true`). In legacy encoding Ctrl+[ IS Escape (kitty ctrl map: `[` -> 27), so a normal-mode `<C-[>` mapping would hijack Esc and break cancel/exit behavior. `<C-]>` = `1d` is a real distinct code but is an existing Vim builtin (tag jump). Half-broken choice, not robust.
  timestamp: 2026-11-23T13:27:00Z
- hypothesis: the Alacritty `key_bindings` caveat already covers this issue
  evidence: `nvim/.config/nvim/README.md:30` and 07-VERIFICATION.md:162-165 scope the caveat exclusively to Alacritty + `TERM=xterm-256color`. The repo has NO kitty package/config tracked (`git ls-files | grep -i kitty` empty; `ALL_PACKAGES` in setup.sh = nvim zsh nushell alacritty starship keyd). The user explicitly uses kitty. The documented fix does not apply to the reporting environment.
  timestamp: 2026-11-23T13:30:00Z

## Evidence

- timestamp: 2026-11-23T13:22:00Z
  checked: nvim/.config/nvim/lua/base/keymaps.lua:93-96, nvim/.config/nvim/README.md:24-30, 07-01-PLAN.md:124-133, 07-VERIFICATION.md:59,162-165, 07-CONTEXT.md:24-25
  found: `<C-,>` -> `BufferLineCycleNext`, `<C-.>` -> `BufferLineCyclePrev` (normal mode only). Plan changed ONLY the lhs from Tab/S-Tab; documented caveat is Alacritty-specific (`key_bindings`, `TERM=xterm-256color`) and insert-mode `<C-v><C-,>` test. RESEARCH explicitly assumed terminal delivery just needs a "caveat" and probed only maparg, never a real terminal.
  implication: Implementation assumed terminals deliver Ctrl-comma/period; no kitty-side mitigation was ever created.
- timestamp: 2026-11-23T13:26:00Z
  checked: headless probe `/tmp/opencode/kitty-maparg-probe.lua` with `vim.opt.rtp:prepend('nvim/.config/nvim'); require('base.keymaps')` on NVIM v0.12.2
  found: `<C-,> n -> <Cmd>BufferLineCycleNext<CR>`, `<C-.> n -> <Cmd>BufferLineCyclePrev<CR>`, `<M-,>`/`<M-.>`/`<Tab>`/`<S-Tab>`/`<C-[>`/`<C-]>` all `<EMPTY>`.
  implication: nvim side fully wired; Alt+comma/period are free and available as a drop-in lhs (matches 07-RESEARCH.md:27).
- timestamp: 2026-11-23T13:27:00Z
  checked: headless probe `/tmp/opencode/kitty-key-probe.lua` (`nvim_replace_termcodes(key, true, false, true)`), NVIM v0.12.2
  found: `<C-,>` -> `80 fc 04 2c`; `<C-.>` -> `80 fc 04 2e`; `<M-,>` -> `80 fc 08 2c`; `<M-.>` -> `80 fc 08 2e`; `<C-;>` -> `80 fc 04 3b`; `<C-'>` -> `80 fc 04 27`; `<C-[>` -> `1b`; `<C-]>` -> `1d`; `<Esc>` -> `1b`; `<C-i>` == `<Tab>` == `09`. `C-[ == Esc ? true`.
  implication: Internal codes confirm `<C-[>` is literally Escape (cannot be bound separately in legacy mode), `<C-;>`/`<C-'>` are the same ctrl+punctuation class as the failing keys, and `<C-,>`/`<C-.>` rely on an extended/modified key encoding the legacy terminal path cannot produce.
- timestamp: 2026-11-23T13:34:00Z
  checked: kitty official keyboard-protocol docs + `kitty/key_encoding.c` `ctrled_key()` / `encode_printable_ascii_key_legacy()` (via web research)
  found: In kitty's default legacy encoding, Ctrl+punctuation is mapped through `ctrled_key()`. Its table covers space, `/`, `0`-`9`, `?`, `@`, `[`, `\`, `]`, `^`, `_`, `a`-`z`, `~` only; `,` (0x2C), `.` (0x2E), `;` (0x3B), `'` (0x27) are absent and hit `default: return key`. Thus Ctrl is dropped and a bare `,`/`.`/`;`/`'` byte reaches nvim. Docs: "Any ASCII keys not in the table must be left untouched by ctrl." Alt is well defined: legacy text keys prepend ESC (0x1b), so alt+, -> `1b 2c`, alt+. -> `1b 2e`, which nvim decodes as `<M-,>`/`<M-.>` regardless of protocol negotiation.
  implication: Direct mechanism for the symptom — nvim receives bare `,`/`.` (normal-mode `,`/`.` are unrelated commands: repeat-last-motion / repeat-last-change), never `<C-,>`/`<C-.>`, so buffer cycling never fires. Explains "does nothing" (or silently does the wrong thing). Also proves which suggested alternatives work and which don't.
- timestamp: 2026-11-23T13:36:00Z
  checked: Neovim `:h tui-input` / `tui-csiu` docs + kitty FAQ + nvim PR #32038
  found: Nvim can enable unambiguous encoding (kitty keyboard protocol / CSI u or modifyOtherKeys) at startup via `CSI ? u` query -> `CSI > 3 u`; kitty supports it. Nvim's support is documented as partial. kitty FAQ: keys not delivered should be diagnosed with `kitten show-key -m kitty` and can be fixed with `map X no_op` or `send_key`/`send_text` in kitty.conf. Research article: inside tmux, CSI-u relay requires `extended-keys on` AND `extended-keys-format csi-u` plus `terminal-features 'xterm-kitty*:extkeys'`.
  implication: A terminal-side fix is possible (protocol negotiation or explicit kitty map), but nothing in this repo configures it. User's `~/.tmux.conf` has only `set -g extended-keys on` (no csi-u format / terminal-features) — a plausible contributing factor IF nvim runs inside tmux, but tmux usage was not confirmed. Logged as blind spot, not asserted as cause.
- timestamp: 2026-11-23T13:37:00Z
  checked: repo-wide tracked-file scan + setup.sh package universe + alacritty config
  found: No kitty files tracked; `ALL_PACKAGES=(nvim zsh nushell alacritty starship keyd)`; `alacritty.toml` has no `key_bindings` and sets `TERM = "xterm-256color"`. Commit a986fca changed only keymaps.lua, README.md, surround.lua, lazy-lock.json — no terminal config.
  implication: Confirms the phase shipped an nvim-only change with an Alacritty-only caveat and no kitty support.

## Resolution

root_cause: >
  CONFIG/ENVIRONMENT ROOT CAUSE (AND-gate = yes): The Phase-07 buffer-cycle lhs was changed to
  `<C-,>`/`<C-.>` (nvim/.config/nvim/lua/base/keymaps.lua:94-95), a Ctrl+punctuation combination
  that legacy terminal key encoding cannot represent. In kitty's default legacy keyboard mode,
  `ctrled_key()` has no mapping for `,` or `.`, so its fallback sends the plain character and drops
  the Ctrl modifier; Neovim receives a bare `,`/`.` instead of the sequence bound to `<C-,>`/`<C-.>`
  and the mappings never fire. The editor-side wiring is intact (headless maparg proves it). The only
  shipped mitigation was an Alacritty-specific `key_bindings` caveat (nvim/.config/nvim/README.md:30);
  the repo contains no kitty configuration, so the user's actual terminal has no fix. Failure requires
  BOTH the fragile key choice (config) AND a terminal that drops Ctrl on punctuation (environment) —
  changing either removes the symptom. Of the user's options, `alt+,`/`alt+.` (`<M-,>`/`<M-.>`) is the
  only robust one: kitty's legacy Alt encoding (ESC + key) is decoded correctly by nvim regardless of
  keyboard-protocol negotiation, and both keys are verified free (07-RESEARCH.md:27, maparg probe).
  `ctrl+;`/`ctrl+'` share the identical broken mechanism; `ctrl+[` is byte-identical to `<Esc>` and
  would hijack Escape (headless probe: `C-[ == Esc ? true`), while `ctrl+]` is an existing builtin.
fix: (none — find_root_cause_only mode; no changes applied)
verification: >
  Headless probes on NVIM v0.12.2: real keymaps.lua loaded -> maparg `<C-,>`/`<C-.>` return the correct
  BufferLine commands (nvim side healthy); keycode probe -> `<C-[>` == `<Esc>` (0x1b), `<C-;>`/`<C-'>`
  are ctrl+punctuation like `<C-,>`. Cross-checked against kitty source `ctrled_key()` (no `,`/`.`/`;`/`'`
  entries -> `default: return key`) and kitty docs (legacy text-key Alt = ESC prefix). No fix applied, no
  live kitty reproduction possible in this headless environment (no kitty binary installed); mechanism
  established from kitty source + user's authoritative live report.
files_changed: []
candidate_causes:
  - "code/config: keymaps.lua:94-95 binds buffer cycling to ctrl+punctuation keys with no legacy terminal encoding"
  - "environment: user runs kitty (not the assumed Alacritty); repo ships no kitty config; optional tmux link lacks extended-keys-format=csi-u"
  - "data: n/a (no data path involved)"
and_gate: "yes — observed failure needs both the fragile key choice and kitty's Ctrl-on-punctuation drop; changing either resolves it"
blind_spots:
  - "No live kitty session available here, so kitty's exact emitted bytes for Ctrl+,/Ctrl+. were derived from source/docs, not observed on the user's machine; user report is authoritative that the mappings do not fire."
  - "Whether nvim's kitty-keyboard-protocol negotiation succeeds in the user's setup is unobserved. If it did, Ctrl+, would arrive as CSI u and might work; the report says it does not. If nvim runs inside tmux, the shipped ~/.tmux.conf lacks extended-keys-format csi-u / terminal-features for xterm-kitty, which would break CSI-u relay — plausible contributor, unconfirmed."
  - "Exact kitty version and kitty.conf of the user are unknown; a user-level kitty map could independently swallow these keys."
