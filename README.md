# macOS ricing
macOS rice: tiling WM, the active workspace in the menu bar, Ghostty, herdr and the shell from [dotfiles](https://github.com/kremeshnoi/dotfiles).

This repo is the `mac` submodule of dotfiles. The Mac with Nix gets these files through nix-darwin (`darwinConfigurations.mac`). A Mac where Nix is not allowed gets the same files through `install.sh`, with Homebrew for the packages and symlinks for the configs, so a repo edit applies at once.

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
install.sh                     brew bundle, symlinks, herdr plugins, bat cache
zsh/.zshrc                     zsh without home-manager: Homebrew, PATH and plugins around shared/zsh
helix/hx                       hx wrapper that puts the managed language servers first in PATH
glazewm/config.yaml            GlazeWM — tiling WM, same setup as on Windows
glazewm/kill-workspace.sh      quits every app on the focused workspace
swiftbar/glazewm.sh            SwiftBar plugin showing the active GlazeWM workspace
ghostty/config                 Ghostty — terminal
herdr/config.toml              herdr — alt as the modifier
herdr/space-colors/            work Mac only: plugin that tags each workspace with its team under ~/dev/teams/, and sidebar.toml that colours the sidebar by it
```

## Install without Nix
```bash
git clone --recurse-submodules git@github.com:kremeshnoi/dotfiles.git ~/dev/dotfiles
~/dev/dotfiles/mac/install.sh
exec zsh
```

`install.sh` needs the parent dotfiles checkout: everything that is not macOS-specific comes from `shared/` — `.zshrc` sources `shared/zsh/startup.zsh` and `shared/zsh/rc.zsh`, and git, helix, the herdr scripts and the Claude skills are linked from there. A file in the way is moved to `<name>.backup-<timestamp>`; running it again is safe. Machine-specific settings go into `~/.zshrc.local`, which is sourced early and never committed. git keeps the user name and email in `~/.gitconfig`, which overrides `~/.config/git/config`.

herdr comes from Homebrew and is pinned there; `install.sh` warns when its version differs from `shared/herdr/versions.toml`, which nix-darwin and NixOS build from, and installs reviewr at the tag from the same file. On this Mac `~/.config/herdr/config.toml` is a generated copy of `herdr/config.toml` with `herdr/space-colors/sidebar.toml` appended, since herdr reads a single file; run `install.sh` again after editing either. The Mac with Nix gets `herdr/config.toml` alone, without space-colors.

Brewfile and the Nix package lists in dotfiles must match; `.github/scripts/packages.py` in dotfiles checks it in CI.

GlazeWM needs Accessibility access (System Settings → Privacy & Security → Accessibility).
