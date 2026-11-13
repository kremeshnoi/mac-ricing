shared="${${(%):-%x}:A:h:h:h}/shared"
brew_prefix=/opt/homebrew

[ -x "$brew_prefix/bin/brew" ] && eval "$("$brew_prefix/bin/brew" shellenv)"

source "$shared/zsh/env.zsh"
path=(
  "$brew_prefix/opt/libpq/bin"
  $path
)

source "$shared/zsh/startup.zsh"

autoload -U compinit && compinit

command -v gdircolors >/dev/null && eval "$(gdircolors -b)"

source "$brew_prefix/share/zsh-you-should-use/you-should-use.plugin.zsh"
source "$shared/zsh/zsh-helix-mode/zsh-helix-mode.plugin.zsh"

source "$shared/zsh/rc.zsh"

source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
zhm-add-update-region-highlight-hook

command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

unset shared brew_prefix
