#!/usr/bin/env bash
# Bash 3.2+ (stock macOS), Linux, and WSL. Run from any directory.
set -euo pipefail
umask 077

repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
mode=${1:---dry-run}
exists() { [[ -e $1 || -L $1 ]]; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
clean_path() {
  case "$1" in *$'\t'*|*$'\n'*|*$'\r'*) die 'Paths may not contain tabs or newlines.';; esac
  [[ $1 = /* ]] || die "Expected an absolute path: $1"
}

if [[ $mode = --restore ]]; then
  [[ $# = 2 ]] || die 'Usage: bash install.sh --restore /absolute/backup/directory'
  backup=$2
  clean_path "$backup"
  [[ -f $backup/manifest.tsv ]] || die 'Backup manifest not found.'
  [[ ! -e $backup/RESTORED ]] || die 'This backup has already been restored.'
  # Validate every destination before changing anything.
  while IFS=$'\t' read -r id target source original; do
    if [[ -L $target && $(readlink "$target") = "$source" ]]; then
      :
    elif ! exists "$target"; then
      :
    elif [[ $original = yes ]] && ! exists "$backup/files/$id"; then
      continue # An interrupted install did not move this original.
    else
      die "Destination was changed after installation; preserve it manually first: $target"
    fi
    if [[ $original = yes ]] && ! exists "$backup/files/$id"; then
      die "Original backup is missing: $backup/files/$id"
    fi
  done < "$backup/manifest.tsv"
  while IFS=$'\t' read -r id target source original; do
    if [[ $original = yes ]] && ! exists "$backup/files/$id"; then continue; fi
    if [[ -L $target ]]; then rm -- "$target"; fi
    if [[ $original = yes ]]; then
      mkdir -p -- "$(dirname -- "$target")"
      mv -- "$backup/files/$id" "$target"
    fi
    printf 'Restored: %s\n' "$target"
  done < "$backup/manifest.tsv"
  touch "$backup/RESTORED"
  exit 0
fi

[[ $# -le 1 ]] || die 'Pass one of --dry-run, --install, or --restore BACKUP.'
case "$mode" in --dry-run|--install) ;; *) die 'Usage: bash install.sh [--dry-run | --install | --restore BACKUP]';; esac
config_root=${XDG_CONFIG_HOME:-$HOME/.config}
state_root=${XDG_STATE_HOME:-$HOME/.local/state}
zsh_root=${ZDOTDIR:-$HOME}
for location in "$repo" "$HOME" "$config_root" "$state_root" "$zsh_root"; do clean_path "$location"; done

sources=(config/zsh/env.zsh config/zsh/.zprofile config/zsh/.zshrc config/atuin/config.toml config/git/config)
targets=("$config_root/dotfiles/env.zsh" "$zsh_root/.zprofile" "$zsh_root/.zshrc" "$config_root/atuin/config.toml" "$config_root/git/config")

# Check the complete plan before moving any existing files.
for ((i=0; i<${#sources[@]}; i++)); do
  target=${targets[$i]}
  [[ -f $repo/${sources[$i]} ]] || die "Source is missing: ${sources[$i]}"
  [[ ! -d $target || -L $target ]] || die "Refusing to replace a directory: $target"
done

backup=''
for ((i=0; i<${#sources[@]}; i++)); do
  source=$repo/${sources[$i]}
  target=${targets[$i]}
  if [[ -L $target && $(readlink "$target") = "$source" ]]; then
    printf 'Already linked: %s\n' "$target"
    continue
  fi
  if [[ $mode = --dry-run ]]; then
    if exists "$target"; then printf 'Back up: %s\n' "$target"; fi
    printf 'Link: %s -> %s\n' "$target" "$source"
    continue
  fi
  if [[ -z $backup ]]; then
    mkdir -p -- "$state_root/dotfiles/backups"
    backup=$(mktemp -d "$state_root/dotfiles/backups/$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")
    mkdir -- "$backup/files"
    printf 'Backup: %s\n' "$backup"
    trap 'printf "Installation interrupted. Recover with: bash %q --restore %q\n" "$repo/install.sh" "$backup" >&2' ERR
  fi
  original=no
  if exists "$target"; then original=yes; fi
  printf '%s\t%s\t%s\t%s\n' "$i" "$target" "$source" "$original" >> "$backup/manifest.tsv"
  if [[ $original = yes ]]; then mv -- "$target" "$backup/files/$i"; fi
  mkdir -p -- "$(dirname -- "$target")"
  ln -s -- "$source" "$target"
  printf 'Linked: %s\n' "$target"
done

if [[ -n $backup ]]; then
  printf '\nUndo: bash %q --restore %q\n' "$repo/install.sh" "$backup"
elif [[ $mode = --dry-run ]]; then
  printf '\nPreview only. Apply with: bash %q --install\n' "$repo/install.sh"
fi
