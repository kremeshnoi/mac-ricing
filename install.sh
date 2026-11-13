#!/usr/bin/env bash
set -euo pipefail

mac="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shared="$(dirname "$mac")/shared"
stamp="$(date +%Y%m%d-%H%M%S)"

if [ ! -d "$shared" ]; then
  echo "error: $shared not found; clone kremeshnoi/dotfiles with --recurse-submodules and run mac/install.sh from there" >&2
  exit 1
fi

link() {
  local source="$1" target="$2"
  mkdir -p "$(dirname "$target")"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "ok      $target"
    return
  fi
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    mv "$target" "$target.backup-$stamp"
    echo "backup  $target.backup-$stamp"
  fi
  ln -s "$source" "$target"
  echo "link    $target -> $source"
}

generate() {
  local target="$1"
  shift
  mkdir -p "$(dirname "$target")"
  if [ ! -L "$target" ] && [ -f "$target" ] && cat "$@" | cmp -s - "$target"; then
    echo "ok      $target"
    return
  fi
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    mv "$target" "$target.backup-$stamp"
    echo "backup  $target.backup-$stamp"
  fi
  cat "$@" > "$target"
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

link "$mac/zsh/.zshrc" "$HOME/.zshrc"
link "$shared/git/config" "$HOME/.config/git/config"
git lfs install --skip-repo >/dev/null
link "$shared/helix" "$HOME/.config/helix"
link "$mac/helix/hx" "$HOME/.local/bin/hx"
for skill in "$shared"/claude/skills/*/; do
  skill="$(basename "$skill")"
  link "$shared/claude/skills/$skill" "$HOME/.claude/skills/$skill"
done

generate "$HOME/.config/herdr/config.toml" "$mac/herdr/config.toml" "$mac/herdr/space-colors/sidebar.toml"
link "$shared/herdr/reviewr.toml" "$HOME/.config/herdr/plugins/config/persiyanov.reviewr/config.toml"
link "$shared/herdr/git-review.sh" "$HOME/.local/bin/herdr-git-review"

link "$mac/glazewm/config.yaml" "$HOME/.glzr/glazewm/config.yaml"
link "$mac/glazewm/kill-workspace.sh" "$HOME/.glzr/glazewm/kill-workspace.sh"
link "$mac/swiftbar/glazewm.sh" "$HOME/.config/swiftbar/glazewm.sh"
defaults write com.ameba.SwiftBar PluginDirectory "$HOME/.config/swiftbar"

link "$mac/ghostty/config" "$HOME/.config/ghostty/config"
ghostty_app="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
if [ -f "$ghostty_app" ] && [ ! -L "$ghostty_app" ]; then
  mv "$ghostty_app" "$ghostty_app.backup-$stamp"
  echo "backup  $ghostty_app.backup-$stamp"
fi

pgf="$HOME/.local/src/pgf"
if [ -d "$pgf/.git" ]; then
  git -C "$pgf" pull --ff-only --quiet
  echo "ok      $pgf"
else
  git clone --quiet https://github.com/kremeshnoi/pgf "$pgf"
  echo "clone   $pgf"
fi
link "$pgf/bin/pgf" "$HOME/.local/bin/pgf"
if [ -d "$HOME/.local/share/pgf/.git" ]; then
  rm -rf "$HOME/.local/share/pgf"
  echo "remove  $HOME/.local/share/pgf"
fi

intelephense_version=1.18.2
intelephense="$HOME/.local/share/intelephense"
if command -v fnm >/dev/null && eval "$(fnm env --shell bash)" && command -v npm >/dev/null; then
  if [ "$(jq -r .version "$intelephense/node_modules/intelephense/package.json" 2>/dev/null)" = "$intelephense_version" ]; then
    echo "ok      intelephense $intelephense_version"
  else
    npm install --prefix "$intelephense" --no-fund --no-audit --silent "intelephense@$intelephense_version"
    echo "install intelephense $intelephense_version"
  fi
  link "$intelephense/node_modules/.bin/intelephense" "$HOME/.local/bin/intelephense"
else
  echo "skip    intelephense: no node from fnm"
fi

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

reviewr_version="$(version reviewr)"
plugins_json="$HOME/.config/herdr/plugins.json"
reviewr="$(jq -r '.[] | select(.plugin_id == "persiyanov.reviewr") | .source.requested_ref // "none"' "$plugins_json" 2>/dev/null || true)"
if [ "$reviewr" = "v$reviewr_version" ]; then
  echo "ok      herdr plugin persiyanov.reviewr v$reviewr_version"
else
  [ -n "$reviewr" ] && herdr plugin uninstall persiyanov.reviewr
  herdr plugin install persiyanov/herdr-reviewr --ref "v$reviewr_version" -y
fi

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
