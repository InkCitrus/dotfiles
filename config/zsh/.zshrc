[[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/env.zsh ]] &&
  source "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/env.zsh"

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=20000
SAVEHIST=20000
setopt APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
bindkey -e

autoload -Uz compinit
# Skip completion paths with unsafe permissions without prompting for input.
compinit -i

_dotfiles_source_first() {
  local candidate
  for candidate in "$@"; do
    if [[ -n $candidate && -r $candidate ]]; then
      source "$candidate"
      return 0
    fi
  done
  return 1
}

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
_dotfiles_source_first "${ZSH_AUTOSUGGESTIONS_FILE:-}" \
  "${HOMEBREW_PREFIX:-/nonexistent}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Probe Atuin initialization first; older versions may lack --disable-ai.
_dotfiles_atuin_init=''
if [[ -o zle && $TERM != dumb ]] && (( $+commands[atuin] )); then
  _dotfiles_atuin_init=$(atuin init zsh --disable-up-arrow --disable-ai 2>/dev/null) ||
    _dotfiles_atuin_init=$(atuin init zsh --disable-up-arrow 2>/dev/null) ||
    _dotfiles_atuin_init=''
fi

# fzf >= 0.48 embeds its integration; distro packages may ship separate files.
if [[ -o zle && $TERM != dumb ]] && (( $+commands[fzf] )); then
  _dotfiles_fzf_init=$(fzf --zsh 2>/dev/null) || _dotfiles_fzf_init=''
  if [[ -n $_dotfiles_fzf_init ]]; then
    if [[ -n $_dotfiles_atuin_init ]]; then
      FZF_CTRL_R_COMMAND= eval "$_dotfiles_fzf_init"
    else
      eval "$_dotfiles_fzf_init"
    fi
  else
    _dotfiles_source_first \
      "${HOMEBREW_PREFIX:-/nonexistent}/opt/fzf/shell/key-bindings.zsh" \
      /usr/share/fzf/key-bindings.zsh /usr/share/doc/fzf/examples/key-bindings.zsh
    _dotfiles_source_first \
      "${HOMEBREW_PREFIX:-/nonexistent}/opt/fzf/shell/completion.zsh" \
      /usr/share/fzf/completion.zsh /usr/share/doc/fzf/examples/completion.zsh
  fi
  unset _dotfiles_fzf_init
fi

# Atuin owns Ctrl-R when available; otherwise fzf or zsh keeps it.
[[ -n $_dotfiles_atuin_init ]] && eval "$_dotfiles_atuin_init"
unset _dotfiles_atuin_init

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

if [[ $TERM != dumb ]] && (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Host-only aliases, paths, and overrides stay outside Git.
[[ -r ${ZDOTDIR:-$HOME}/.zshrc.local ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"

# Syntax highlighting must follow widget definitions and local customizations.
_dotfiles_source_first "${ZSH_SYNTAX_HIGHLIGHTING_FILE:-}" \
  "${HOMEBREW_PREFIX:-/nonexistent}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unfunction _dotfiles_source_first
true
