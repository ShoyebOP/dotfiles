# Specification: CSS Completion Fix and Color Picker Integration

## Overview
This track aims to refine the Neovim editing experience by resolving a specific annoyance in CSS completion and adding a powerful color management tool. Specifically, it will prevent the `nvim-cmp` completion popup from triggering immediately after an opening brace `{` in CSS-like files and integrate `ccc.nvim` for color picking and global color highlighting.

## Functional Requirements

### 1. CSS Completion Behavior
- **Trigger Suppression:** In CSS, SCSS, Less, and PostCSS files, the `nvim-cmp` completion menu must NOT trigger automatically when the character immediately preceding the cursor is `{`.
- **Preservation:** Normal auto-trigger behavior must be maintained for all other characters and contexts.
- **Scope:** This behavior must apply to the following filetypes: `css`, `scss`, `less`, `postcss`.

### 2. Color Management (`ccc.nvim`)
- **Plugin Integration:** Install and configure `uga-rosa/ccc.nvim`.
- **Automatic Highlighting:** Enable the highlighter globally so that hex codes and color strings are automatically highlighted with their respective colors in all buffers.
- **Color Picker:**
  - Provide a command or keybinding to open the color picker.
  - **Proposed Keybinding:** `<leader>cp` (Color Picker), provided it does not conflict with existing maps. (Will verify and adjust if needed during implementation).
- **Lazy Loading:** The plugin should be lazy-loaded on relevant commands (`CccPick`, `CccConvert`) or keybindings.

### 3. Color Grid (Palette)
- **Visual Grid:** Provide a dedicated keyboard-navigable grid of common colors.
- **Navigation:** Support `h/j/k/l` movement within the grid.
- **Selection:** Pressing `Enter` should insert the selected color.
- **Accessibility:** Triggered via a separate keybinding (`<leader>cP`).

## Non-Functional Requirements
- **Performance:** The completion suppression logic must be efficient and not introduce perceptible latency during typing.
- **Maintainability:** Changes must be modular, using the `lua/plugins/` directory to avoid modifying core LazyVim files.
- **Consistency:** Follow the project's established Neovim configuration style.

## Acceptance Criteria
1. Opening a `.css` file and typing `{` does not trigger the completion menu.
2. Typing property names (e.g., `color:`) in a `.css` file still triggers the completion menu.
3. Hex colors (e.g., `#ff0000`) are visually highlighted in any open buffer.
4. The color picker can be opened via a keybinding or command, allowing for color selection and insertion.
5. All new plugin configurations are contained within `~/.config/nvim/lua/plugins/`.

## Out of Scope
- Modifications to completion behavior for non-CSS-like languages.
- Integration with other color-related plugins (e.g., `nvim-colorizer.lua`).
