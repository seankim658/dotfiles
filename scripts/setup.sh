#!/bin/bash

set -euo pipefail

## Sets up the symlinks and re-sources source files
##
## Symlinks (in home directory)
## 1) .bashrc          -> ~/projects/personal/dotfiles/bash/bashrc
## 2) .bash_profile    -> ~/projects/personal/dotfiles/bash/bash_profile
## 3) .bash_aliases    -> ~/projects/personal/dotfiles/bash/bash_aliases
## 4) .tmux.conf       -> ~/projects/personal/dotfiles/tmux.conf
## 5) scripts          -> ~/projects/personal/dotfiles/scripts/
## 6) .gitconfig       -> ~/projects/personal/dotfiles/gitconfig
## 7) .config/nvim     -> ~/projects/personal/dotfiles/nvim/
## 8) codeprompt-temps -> ~/projects/personal/codeprompts/cli/src/templates/
## 9) .codeprompt.toml -> ~/projects/personal/dotfiles/codeprompt.toml
##
## MacOS Specific Symlinks
## 1) .aerospace.toml        -> ~/projects/personal/dotfiles/mac/aerospace.toml
## 2) .config/ghostty/config -> ~/projects/personal/dotfiles/mac/ghostty

DOTFILES_DIR=~/projects/personal/dotfiles
HOME_DIR=~
BACKUP_DIR=~/.backup_dotfiles

mkdir -p "$BACKUP_DIR"

create_symlink() {
  local target=$1
  local link_name=$2

  if [ -L "$link_name" ]; then
    echo "Symlink already exists: $link_name"
    return
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

create_symlink "$DOTFILES_DIR/bash/bashrc" "$HOME_DIR/.bashrc"
delim
create_symlink "$DOTFILES_DIR/bash/bash_profile" "$HOME_DIR/.bash_profile"
delim
create_symlink "$DOTFILES_DIR/bash/bash_aliases" "$HOME_DIR/.bash_aliases"
delim
create_symlink "$DOTFILES_DIR/tmux.conf" "$HOME_DIR/.tmux.conf"
delim
create_symlink "$DOTFILES_DIR/scripts/" "$HOME_DIR/scripts"
delim
create_symlink "$DOTFILES_DIR/gitconfig" "$HOME_DIR/.gitconfig"
delim
create_symlink "$DOTFILES_DIR/nvim" "$HOME_DIR/.config/nvim"
delim
if [ -d ~/projects/personal/codeprompts ]; then
    create_symlink "$HOME_DIR/projects/personal/codeprompts/cli/src/templates" "$HOME_DIR/codeprompt-temps"
    delim
    create_symlink "$DOTFILES_DIR/codeprompt.toml" "$HOME_DIR/.codeprompt.toml"
    delim
fi

# MacOS-specific symlinks
if [[ "$OSTYPE" == "darwin"* ]]; then
    create_symlink "$DOTFILES_DIR/mac/aerospace.toml" "$HOME_DIR/.aerospace.toml"
    delim
    create_symlink "$DOTFILES_DIR/mac/ghostty" "$HOME_DIR/.config/ghostty/config"
    delim
fi

if [ -f "$HOME_DIR/.tmux.conf" ] && command -v tmux >/dev/null 2>&1; then
    echo "Re-sourcing .tmux.conf"
    tmux source-file "$HOME_DIR/.tmux.conf" 2>/dev/null || true
fi

echo "All symlinks created successfully."
