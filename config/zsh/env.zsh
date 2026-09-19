# Shared by login and interactive shells. No machine-specific paths.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Homebrew on Apple Silicon, Intel macOS, or Linux. Never require Homebrew.
if [[ -z ${HOMEBREW_PREFIX:-} ]]; then
  for _dotfiles_brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x $_dotfiles_brew ]]; then
      eval "$("$_dotfiles_brew" shellenv)"
      break
    fi
  done
  unset _dotfiles_brew
fi

typeset -U path PATH
path=("$HOME/.local/bin" $path)
export PATH
