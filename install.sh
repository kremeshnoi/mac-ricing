#!/usr/bin/env bash
set -euo pipefail

mac="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shared="$(dirname "$mac")/shared"
stamp="$(date +%Y%m%d-%H%M%S)"

if [ ! -d "$shared" ]; then
  echo "error: $shared not found; clone kremeshnoi/dotfiles with --recurse-submodules and run mac/install.sh from there" >&2
  exit 1
fi

manifest="$HOME/.local/state/dotfiles/copied"
mkdir -p "$(dirname "$manifest")"
touch "$manifest"

managed() {
  grep -qxF "$1" "$manifest" || echo "$1" >> "$manifest"
}

make_room() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ] && ! grep -qxF "$target" "$manifest"; then
    mv "$target" "$target.backup-$stamp"
    echo "backup  $target.backup-$stamp"
  fi
  rm -rf "$target"
}

copy() {
  local source="$1" target="$2"
  if [ ! -L "$target" ] && [ -e "$target" ] && diff -rq "$source" "$target" >/dev/null 2>&1; then
    echo "ok      $target"
    managed "$target"
    return
  fi
  make_room "$target"
  cp -R "$source" "$target"
  managed "$target"
  echo "copy    $target"
}

generate() {
  local target="$1"
  shift
  if [ ! -L "$target" ] && [ -f "$target" ] && cat "$@" | cmp -s - "$target"; then
    echo "ok      $target"
    managed "$target"
    return
  fi
  make_room "$target"
  cat "$@" > "$target"
  managed "$target"
  echo "write   $target"
}

unlink_stale() {
  local target="$1"
  if [ -L "$target" ]; then
    rm "$target"
    echo "remove  $target"
  fi
  [ -d "$target" ] && rmdir "$target" 2>/dev/null || true
}

brew bundle --file="$mac/Brewfile"

zshrc_head="$(mktemp)"
printf 'shared=%q\n' "$shared" > "$zshrc_head"
generate "$HOME/.zshrc" "$zshrc_head" "$mac/zsh/.zshrc"
rm -f "$zshrc_head"
copy "$shared/git/config" "$HOME/.config/git/config"
copy "$shared/helix" "$HOME/.config/helix"
copy "$shared/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
copy "$mac/helix/hx" "$HOME/.local/bin/hx"
for skill in "$shared"/claude/skills/*/; do
  skill="$(basename "$skill")"
  copy "$shared/claude/skills/$skill" "$HOME/.claude/skills/$skill"
done

generate "$HOME/.config/herdr/config.toml" "$shared/herdr/base.toml" "$shared/herdr/keys-macos.toml" "$mac/herdr/space-colors/sidebar.toml"

copy "$mac/glazewm/config.yaml" "$HOME/.glzr/glazewm/config.yaml"
copy "$mac/glazewm/kill-workspace.sh" "$HOME/.glzr/glazewm/kill-workspace.sh"
copy "$mac/swiftbar/glazewm.sh" "$HOME/.config/swiftbar/glazewm.sh"
defaults write com.ameba.SwiftBar PluginDirectory "$HOME/.config/swiftbar"

bat cache --build --source "$shared/bat" >/dev/null
echo "ok      bat cache"

copy "$mac/ghostty/config" "$HOME/.config/ghostty/config"
ghostty_app="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
if [ -f "$ghostty_app" ] && [ ! -L "$ghostty_app" ]; then
  mv "$ghostty_app" "$ghostty_app.backup-$stamp"
  echo "backup  $ghostty_app.backup-$stamp"
fi

uv tool install --quiet sqlit-tui --with psycopg2-binary
echo "ok      sqlit"

unlink_stale "$HOME/.local/bin/intelephense"
rm -rf "$HOME/.local/share/intelephense"

unlink_stale "$HOME/.local/bin/herdr-goto"
unlink_stale "$HOME/.config/shell/env.sh"
unlink_stale "$HOME/.config/shell"
for stale in ohmyzsh zsh-helix-mode fzf-git-branch.zsh; do
  unlink_stale "$HOME/.config/zsh/$stale"
done
unlink_stale "$HOME/.config/zsh"

version() {
  sed -nE "s/^$1 = \"(.*)\"$/\1/p" "$shared/herdr/versions.toml"
}

herdr_version="$(version herdr)"
if [ "$(herdr --version)" = "herdr $herdr_version" ]; then
  echo "ok      herdr $herdr_version"
else
  echo "warning: herdr from Homebrew is $(herdr --version), shared/herdr/versions.toml wants $herdr_version" >&2
fi
brew list --pinned | grep -qx herdr || brew pin herdr

plugins_json="$HOME/.config/herdr/plugins.json"
for root in "$shared/herdr/workspace-tabs" "$mac/herdr/space-colors"; do
  id="$(awk -F'"' '/^id = /{print $2; exit}' "$root/herdr-plugin.toml")"
  current="$(jq -r --arg id "$id" '.[] | select(.plugin_id == $id) | "\(.source.kind) \(.plugin_root)"' "$plugins_json" 2>/dev/null || true)"
  if [ "$current" = "local $root" ]; then
    echo "ok      herdr plugin $id"
  else
    herdr plugin link "$root" >/dev/null
    echo "link    herdr plugin $id -> $root"
  fi
done
