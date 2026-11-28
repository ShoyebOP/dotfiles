---
phase: "06"
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - nvim/.config/nvim/lua/base/options.lua
autonomous: true
requirements:
  - QOL-03
user_setup: []
estimate:
  tokens: 12000
  raw_tokens: 8000
  tasks: 2
  confidence: low
must_haves:
  truths:
    - "On a signed line the gitsigns sign is followed by at most one blank cell before the first line-number digit (HEAD measured three)."
    - "Left-gutter source is confirmed textually identical to the pre-Phase-7 state for signcolumn and numberwidth; the only new left-gutter setting is an explicit native status column."
    - "Native per-line gitsigns signs still render; no gutter plugin, widened sign column, divider glyph, or right-side setting was introduced."
  artifacts:
    - "nvim/.config/nvim/lua/base/options.lua"
  key_links:
    - from: "nvim/.config/nvim/lua/base/options.lua"
      to: "nvim/.config/nvim/lua/plugins/gitsigns.lua"
      via: "signcolumn stays \"yes\" so native gitsigns signs render; the new status column packs the sign slot (%s) directly against a raw line number"
---

<objective>
Close the residual blank gutter between the native gitsigns sign and the line number, changing only the left side of the Neovim window.

Purpose: git history proves there is no textual left-gutter delta to revert — the parent of 5e4f704 (887b97c) and HEAD both carry `opt.signcolumn = "yes"` and `opt.numberwidth = 2`, and `gitsigns.lua` is unchanged. The reported gap is the default Neovim status column layout (sign slot + separator cell + right-aligned number field), which a headless `screenstring` probe measures as three blank cells on a 100-line buffer. Because a no-op is not acceptable, the fix is one explicit left-gutter option that packs sign and number tightly.
Output: one added line in `nvim/.config/nvim/lua/base/options.lua` plus a reproducible headless before/after measurement.
</objective>

<execution_context>
@/home/shoyeb/.config/opencode/gsd-core/workflows/execute-plan.md
@/home/shoyeb/.config/opencode/gsd-core/templates/summary.md
</execution_context>

<context>
@AGENTS.md
@.planning/STATE.md
@.planning/debug/gutter-git-marker-separator-layout.md
@.planning/ROADMAP.md
nvim/.config/nvim/lua/base/options.lua
nvim/.config/nvim/lua/plugins/gitsigns.lua
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add an explicit tight left-gutter status column</name>
  <files>nvim/.config/nvim/lua/base/options.lua</files>
  <action>
First establish the baseline from the checkout root: run `git show 887b97c:nvim/.config/nvim/lua/base/options.lua` and compare its `signcolumn` and `numberwidth` lines with the working copy. They are already identical (`opt.signcolumn = "yes"`, `opt.numberwidth = 2`) and `nvim/.config/nvim/lua/plugins/gitsigns.lua` is unchanged since 887b97c, so no textual revert exists. The residual gap comes from Neovim's default status column, not from any surviving Phase-7 source edit.

Then edit only `nvim/.config/nvim/lua/base/options.lua`: insert ONE line directly after the existing `opt.signcolumn = "yes"` line that sets `opt.statuscolumn` to the exact Lua string `%s%{v:virtnum>0 ? '' : v:lnum}`. Place a one-line comment above it stating that the sign slot is kept native and the raw number expression removes the reserved right-aligned padding, and that the virtual-line guard avoids repeating the number on wrapped rows. Do not change the values of `signcolumn` or `numberwidth`. Do not add any gutter plugin, widened sign-column value, divider glyph, or right-side bar setting. Do not commit a probe script into the repository.

Create the temporary probe `/tmp/opencode/gutter_gap_probe.lua` with the Write tool (no heredoc). It must: create a 100-line buffer; set window-local `number=true`, `relativenumber=false`, `numberwidth=2`, `signcolumn='yes'`, `foldcolumn='0'`; define and place a one-cell sign on line 2; run two passes — DEFAULT with `statuscolumn=''` and SHIPPED with the exact string from options.lua; after each pass call `redraw!`, read columns 1-10 of row 2 with `vim.fn.screenstring`, count the contiguous blank cells between the sign glyph and the first line-number digit, and print `DEFAULT_GAP=<n>` then `SHIPPED_GAP=<n>`; finally quit. Use `timeout 30` when invoking Neovim so the probe cannot hang.
  </action>
  <verify>
    <automated>
cd "$(git rev-parse --show-toplevel)"
nvim --headless --clean -u NONE -S /tmp/opencode/gutter_gap_probe.lua 2>&1 | tee /tmp/opencode/gutter_gap.out
grep -E 'DEFAULT_GAP=[2-9]' /tmp/opencode/gutter_gap.out
grep -E 'SHIPPED_GAP=1' /tmp/opencode/gutter_gap.out
grep -F 'opt.statuscolumn = ' nvim/.config/nvim/lua/base/options.lua
grep -F "%s%{v:virtnum>0 ? '' : v:lnum}" nvim/.config/nvim/lua/base/options.lua
    </automated>
  </verify>
  <done>Headless probe reports DEFAULT_GAP>=2 and SHIPPED_GAP=1; options.lua contains the exact statuscolumn assignment; signcolumn and numberwidth values are untouched.</done>
</task>

<task type="auto">
  <name>Task 2: Confirm left-only scope and native-sign regression safety</name>
  <files>nvim/.config/nvim/lua/base/options.lua</files>
  <action>
Make no further edits. Confirm the working-tree diff is limited to the single added status column line in the base options file, that native signs are still enabled with the unchanged signcolumn value, that the gitsigns plugin spec is untouched, and that no dependency manifest or right-side setting changed. Accept that an explicit status column drops default sign-column click callbacks as out of scope for this left-gutter-only fix.
  </action>
  <verify>
    <automated>
cd "$(git rev-parse --show-toplevel)"
CHANGED=$(git diff --name-only)
[ "$CHANGED" = "nvim/.config/nvim/lua/base/options.lua" ] || { echo "scope drift: $CHANGED"; exit 1; }
git diff -- nvim/.config/nvim/lua/base/options.lua | grep '^+' | grep -v '^+++' | grep -c 'statuscolumn'   # [HEAD=0 EXPECT=1]
grep -v '^#' nvim/.config/nvim/lua/base/options.lua | grep -cE 'yes:[0-9]'   # [HEAD=0 EXPECT=0]
git diff --name-only | grep -c -E '(lazy-lock|bar|side)' || true   # [HEAD=0 EXPECT=0]
git diff --quiet -- nvim/.config/nvim/lua/plugins/gitsigns.lua
grep -F 'opt.signcolumn = "yes"' nvim/.config/nvim/lua/base/options.lua
timeout 30 nvim --headless --clean -u NONE -c 'echo "config-ok"' -c 'qa!' 2>&1 | grep -q 'config-ok'
    </automated>
  </verify>
  <done>Diff touches only base/options.lua with one added status column line; no widened sign column, no plugin or manifest change, no right-side setting; gitsigns.lua untouched; headless Neovim starts cleanly.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| repo → deployed nvim config | Stow symlink makes this options file live configuration |

## STRIDE Threat Register

No new trust boundary, input path, or privileged operation is introduced; the change is a display option in a local config file. No STRIDE threats apply.

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-06-SC | Tampering | package installs | high | mitigate | No package manager install occurs in this plan; scope gate rejects any manifest change |
</threat_model>

<verification>
Run both task `<automated>` blocks from the checkout root. The headless probe is the authoritative visual gate: it must show a blank-cell count of at least 2 before and exactly 1 after. The scope gate must show a single changed file with one added status column line.
</verification>

<success_criteria>
- Signed lines show the gitsigns sign immediately followed by the line number with at most one blank cell between them.
- Native per-line gitsigns remain the only git indicator; signcolumn and numberwidth values are unchanged.
- No gutter plugin was restored, no dependency manifest changed, and no right-side window setting was touched.
</success_criteria>

<output>
Create `.planning/quick/261128-khe-there-is-a-gap-between-the-gitsigns-colu/261128-khe-SUMMARY.md` when done.
</output>
