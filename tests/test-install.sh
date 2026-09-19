#!/usr/bin/env bash
set -euo pipefail
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf -- "$fixture"' EXIT
test_home="$fixture/home with spaces"
config_root="$test_home/config with spaces"
state_root="$test_home/state with spaces"
zsh_root="$test_home/zsh with spaces"
mkdir -p "$config_root/atuin" "$zsh_root"
run_install() {
  env HOME="$test_home" XDG_CONFIG_HOME="$config_root" XDG_STATE_HOME="$state_root" ZDOTDIR="$zsh_root" \
    bash "$repo/install.sh" "$@"
}
printf 'original zsh config\n' > "$zsh_root/.zshrc"
printf 'original atuin config\n' > "$config_root/atuin/config.toml"
ln -s "$test_home/nonexistent original" "$zsh_root/.zprofile"
cp "$zsh_root/.zshrc" "$fixture/zshrc.original"
cp "$config_root/atuin/config.toml" "$fixture/atuin.original"

run_install --dry-run > "$fixture/preview.txt"
[[ ! -e $state_root ]]
[[ ! -L $zsh_root/.zshrc ]]
cmp "$zsh_root/.zshrc" "$fixture/zshrc.original"

run_install --install > "$fixture/install.txt"
[[ -L $zsh_root/.zshrc ]]
[[ $(readlink "$zsh_root/.zshrc") = "$repo/config/zsh/.zshrc" ]]
backups=("$state_root"/dotfiles/backups/*)
[[ ${#backups[@]} = 1 ]]
backup=${backups[0]}
[[ $(wc -l < "$backup/manifest.tsv" | tr -d ' ') = 5 ]]

run_install --install > "$fixture/repeat.txt"
backups=("$state_root"/dotfiles/backups/*)
[[ ${#backups[@]} = 1 ]]

# Refuse to erase a destination changed since installation, before any restore.
rm "$zsh_root/.zshrc"
printf 'a later local edit\n' > "$zsh_root/.zshrc"
if run_install --restore "$backup" > "$fixture/conflict.txt" 2>&1; then
  printf 'Expected changed-file conflict\n' >&2; exit 1
fi
[[ -L $config_root/dotfiles/env.zsh ]]
rm "$zsh_root/.zshrc"
ln -s "$repo/config/zsh/.zshrc" "$zsh_root/.zshrc"

run_install --restore "$backup" > "$fixture/restore.txt"
cmp "$zsh_root/.zshrc" "$fixture/zshrc.original"
cmp "$config_root/atuin/config.toml" "$fixture/atuin.original"
[[ -L $zsh_root/.zprofile ]]
[[ $(readlink "$zsh_root/.zprofile") = "$test_home/nonexistent original" ]]
[[ ! -e $config_root/dotfiles/env.zsh && ! -L $config_root/dotfiles/env.zsh ]]
[[ ! -e $config_root/git/config && ! -L $config_root/git/config ]]
[[ -f $backup/RESTORED ]]
if run_install --restore "$backup" > /dev/null 2>&1; then
  printf 'Expected repeat-restore refusal\n' >&2; exit 1
fi

# Refuse a directory collision before mutating any other destination.
mkdir -p "$config_root/git/config"
if run_install --install > /dev/null 2>&1; then
  printf 'Expected directory collision refusal\n' >&2; exit 1
fi
cmp "$zsh_root/.zshrc" "$fixture/zshrc.original"
rmdir "$config_root/git/config"

if command -v zsh >/dev/null; then
  run_install --install > /dev/null
  for source in "$repo/config/zsh/"* "$repo/config/zsh/.zprofile" "$repo/config/zsh/.zshrc"; do zsh -n "$source"; done
  # Hosted runners can include writable completion directories in fpath.
  # Startup must skip unsafe completions without asking a nonexistent terminal.
  mkdir "$zsh_root/insecure-completions"
  chmod 777 "$zsh_root/insecure-completions"
  printf '#compdef dotfiles-unsafe\n' > "$zsh_root/insecure-completions/_dotfiles_unsafe"
  printf 'fpath=("$ZDOTDIR/insecure-completions" $fpath)\n' > "$zsh_root/.zshenv"
  # Minimal PATH and a dummy prefix avoid depending on optional Homebrew tools.
  env HOME="$test_home" XDG_CONFIG_HOME="$config_root" XDG_STATE_HOME="$state_root" \
    ZDOTDIR="$zsh_root" HOMEBREW_PREFIX="$fixture/no-brew" PATH=/usr/bin:/bin TERM=dumb \
    zsh -dlic '[[ $path[1] == "$HOME/.local/bin" && ${_comps[dotfiles-unsafe]-} != _dotfiles_unsafe ]] && bindkey "^[[A" && print -r -- SHELL_OK' > "$fixture/shell.txt" 2> "$fixture/shell.err"
  [[ ! -s $fixture/shell.err ]] || { cat "$fixture/shell.err" >&2; exit 1; }
  [[ $(tail -n 1 "$fixture/shell.txt") = SHELL_OK ]]
fi
printf 'PASS: preview, installation, idempotence, conflict protection, restore, custom paths, and zsh startup\n'
