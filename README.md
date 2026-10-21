# Claude Launcher

Omarchy shell plugin that launches Claude Code with a chosen model and thinking effort.

- **Chooser overlay**: `omarchy-shell shell toggle flintspark.claude-launcher`. `←/→` rotates model (fable, opus, sonnet, haiku on 5.5), `↑/↓` rotates thinking (`--effort`), `Enter` launches, `1-9` launches a saved profile.
- **Named profiles with shortcuts**: edit `~/.config/omarchy/claude-launcher.json` (see `examples/`), then run `bin/claude-launcher-sync` to generate the Hyprland bindings.
- **Theming**: uses the shell's `menu` color/style tokens, so any Omarchy theme styles it.
- Launches in the active terminal's cwd: `bin/claude-launch <model> <effort>` or `--profile <name>`.
- **Folder picker**: the overlay lists the active terminal's folder plus your last 5 launcher folders. `[`/`]` rotate, `Alt+0` picks the terminal's folder, `Alt+1`–`5` pick a recent one, `b` opens an fzf browser over `$HOME` (or type any path and press Enter).
- **CLI presets**: `bin/claude-launcher-sync` installs `claude-fable`, `claude-opus`, `claude-sonnet` and `claude-haiku` into `~/.local/bin`. Each runs claude in the current folder with that model and the effort from its first profile, and passes extra args through (`claude-opus -p "hi"`).
