#!/bin/bash

set -euo pipefail

## Symlink dotfiles into place and reload the tmux config
##
## Symlinks (in home directory), relative to the repo root
## 1) .bashrc          -> bash/bashrc
## 2) .bash_profile    -> bash/bash_profile
## 3) .bash_aliases    -> bash/bash_aliases
## 4) .tmux.conf       -> tmux.conf
## 5) scripts          -> scripts/
## 6) .gitconfig       -> gitconfig
## 7) .config/nvim     -> nvim/
## 8) codeprompt-temps -> ~/projects/personal/codeprompts/cli/src/templates/
## 9) .codeprompt.toml -> codeprompt.toml
##
## MacOS Specific Symlinks
## 1) .aerospace.toml        -> mac/aerospace.toml
## 2) .config/ghostty/config -> mac/ghostty

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$HOME/.backup_dotfiles"
skipped_count=0

mkdir -p "$BACKUP_DIR"

create_symlink() {
  local target=$1
  local link_name=$2

  if [ ! -e "$target" ]; then
    echo "Target does not exist, skipping: $target" >&2
    skipped_count=$((skipped_count + 1))
    return
  fi

  if [ -L "$link_name" ] && [ "$(readlink "$link_name")" = "$target" ]; then
    echo "Symlink already correct: $link_name"
    return
  fi

  if [ -L "$link_name" ]; then
    echo "Replacing stale symlink: $link_name -> $(readlink "$link_name")"
    rm "$link_name"
  elif [ -e "$link_name" ]; then
    local backup="${BACKUP_DIR}/$(basename "$link_name").$(date +%s).bck"
    echo "File exists and is not a symlink, backing up: $link_name -> $backup"
    mv "$link_name" "$backup"
  fi

  # Ensure the parent directory exists
  mkdir -p "$(dirname "$link_name")"
  ln -s "$target" "$link_name"
  echo "Created symlink: $link_name -> $target"
}

delim() {
  echo "--------------------------------------"
}

create_symlink "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"
delim
create_symlink "$DOTFILES_DIR/bash/bash_profile" "$HOME/.bash_profile"
delim
create_symlink "$DOTFILES_DIR/bash/bash_aliases" "$HOME/.bash_aliases"
delim
create_symlink "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
delim
create_symlink "$DOTFILES_DIR/scripts" "$HOME/scripts"
delim
create_symlink "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
delim
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
delim
if [ -d "$HOME/projects/personal/codeprompts" ]; then
  create_symlink "$HOME/projects/personal/codeprompts/cli/src/templates" "$HOME/codeprompt-temps"
  delim
  create_symlink "$DOTFILES_DIR/codeprompt.toml" "$HOME/.codeprompt.toml"
  delim
fi

# MacOS-specific symlinks
if [[ "$OSTYPE" == "darwin"* ]]; then
  create_symlink "$DOTFILES_DIR/mac/aerospace.toml" "$HOME/.aerospace.toml"
  delim
  create_symlink "$DOTFILES_DIR/mac/ghostty" "$HOME/.config/ghostty/config"
  delim
fi

if [ -f "$HOME/.tmux.conf" ] && command -v tmux >/dev/null 2>&1; then
  echo "Reloading .tmux.conf"
  tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
fi

if [ "$skipped_count" -gt 0 ]; then
  echo "Finished with $skipped_count skipped symlink(s), see warnings above." >&2
  exit 1
fi

echo "All symlinks created successfully."
echo "Run 'exec bash -l' to load the new shell config."
