# Claude Launcher

Omarchy shell plugin that launches Claude Code with a chosen model and thinking effort.

- **Chooser overlay**: `omarchy-shell shell toggle flintspark.claude-launcher`. `←/→` rotates model (fable, opus, sonnet, haiku on 5.5), `↑/↓` rotates thinking (`--effort`), `Enter` launches, `1-9` launches a saved profile.
- **Named profiles with shortcuts**: edit `~/.config/omarchy/claude-launcher.json` (see `examples/`), then run `bin/claude-launcher-sync` to generate the Hyprland bindings.
- **Theming**: uses the shell's `menu` color/style tokens, so any Omarchy theme styles it.
- Launches in the active terminal's cwd: `bin/claude-launch <model> <effort>` or `--profile <name>`.
