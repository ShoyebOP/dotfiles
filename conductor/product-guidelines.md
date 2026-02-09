# Product Guidelines

## Development Philosophy
- **Modular Minimalism:** Use a functional approach with small, reusable custom Nushell commands and pipelines. Avoid unnecessary abstractions—keep code strictly minimal and focused on the immediate task.
- **On-Demand Expansion:** Only add new tools or plugins when a recurring pain point is identified. Every addition must be benchmarked for its impact on startup time and system resources.
- **Manual Verification:** All configuration changes must be manually tested on a local machine to ensure stability before being pushed to the remote repository.

## Workflow & Interaction
- **Consistent Keybindings:** Maintain a unified keybinding language across all tools (Neovim, Hyprland, etc.) to ensure a seamless and predictable user experience.
- **Keyboard-Centric:** Design every interaction to be accessible via keyboard, prioritizing speed and functional utility over visual aesthetics.

## Documentation Standards
- **Usage-Centric README:** The `README.md` is the primary source of truth for deployment. It must contain clear, actionable commands for bootstrapping and troubleshooting (replacing the temporary `usage.md`).
- **Self-Documenting Code:** Where possible, leverage Nushell's help system and keep configuration files clean and intuitive.
