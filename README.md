# macOS ricing
macOS rice: tiling WM, the active workspace in the menu bar, Ghostty, herdr and the shell from [dotfiles](https://github.com/kremeshnoi/dotfiles).

This repo is the `mac` submodule of dotfiles and belongs to the work Mac, where Nix is not allowed. `install.sh` sets it up with Homebrew for the packages and copies of the configs; run it again after a repo edit. The Mac at home is built by nix-darwin from dotfiles and reads nothing from here.

## Stack
| Component | Role |
|---|---|
| [GlazeWM](https://github.com/glzr-io/glazewm) | tiling window manager, one workspace per app |
| [SwiftBar](https://github.com/swiftbar/SwiftBar) | the active GlazeWM workspace in the menu bar |
| [Ghostty](https://ghostty.org) | terminal, Option passed through as Alt |
| [herdr](https://herdr.dev) | terminal workspace manager for AI agents |
| [sqlit](https://github.com/Maxteabag/sqlit) | TUI for SQL databases, installed with `uv tool install` |

## Layout
```
Brewfile                       packages and casks for the Mac without Nix
install.sh                     brew bundle, copies of the configs, herdr plugins, bat cache
zsh/.zshrc                     zsh without home-manager: Homebrew, PATH and plugins around shared/zsh
helix/hx                       hx wrapper that puts the managed language servers first in PATH
glazewm/config.yaml            GlazeWM — tiling WM, same setup as on Windows
glazewm/kill-workspace.sh      quits every app on the focused workspace
swiftbar/glazewm.sh            SwiftBar plugin showing the active GlazeWM workspace
ghostty/config                 Ghostty — terminal
herdr/space-colors/            work Mac only: plugin that tags each workspace with its team under ~/dev/teams/, and sidebar.toml that colours the sidebar by it
```

## Install without Nix
```bash
git clone --recurse-submodules git@github.com:kremeshnoi/dotfiles.git ~/dev/dotfiles
~/dev/dotfiles/mac/install.sh
exec zsh
```

`install.sh` needs the parent dotfiles checkout: everything that is not macOS-specific comes from `shared/` — `.zshrc` sources `shared/zsh/startup.zsh` and `shared/zsh/rc.zsh`, and git, helix, the herdr config and the Claude skills are copied from there. Every path it places is listed in `~/.local/state/dotfiles/copied` and overwritten on the next run; any other file in the way is moved to `<name>.backup-<timestamp>`. `~/.zshrc` is generated: a first line with the path to `shared/`, then `zsh/.zshrc`. Machine-specific settings go into `~/.zshrc.local`, which is sourced early and never committed. git keeps the user name and email in `~/.gitconfig`, which overrides `~/.config/git/config`.

herdr comes from Homebrew and is pinned there; `install.sh` warns when its version differs from `shared/herdr/versions.toml`, which nix-darwin and NixOS build from. herdr reads a single file, so `~/.config/herdr/config.toml` is generated from `shared/herdr/base.toml`, `shared/herdr/keys-macos.toml` and `herdr/space-colors/sidebar.toml`.

Brewfile and the Nix package lists in dotfiles must match; `.github/scripts/packages.py` in dotfiles checks it in CI.

GlazeWM needs Accessibility access (System Settings → Privacy & Security → Accessibility).
