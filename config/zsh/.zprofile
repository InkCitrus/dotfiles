[[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/env.zsh ]] &&
  source "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/env.zsh"
[[ -r ${ZDOTDIR:-$HOME}/.zprofile.local ]] && source "${ZDOTDIR:-$HOME}/.zprofile.local"
true
