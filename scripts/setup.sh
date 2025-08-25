#!/bin/bash

## Sets up the symlinks and re-sources source files
##
## Symlinks (in home directory)
## 1) .bashrc -> ~/projects/personal/dotfiles/bash/bashrc
## 2) .bash_profile -> ~/projects/personal/dotfiles/bash/bash_profile
## 3) .bash_aliases -> ~/projects/personal/dotfiles/bash/bash_aliases
## 4) .tmux_conf -> ~/projects/personal/dotfiles/tmux.conf
## 5) scripts -> ~/projects/personal/dotfiles/scripts/
## 6) .gitconfig -> ~/projects/personal/dotfiles/gitconfig
## 7) .config/nvim -> ~/projects/personal/dotfiles/nvim/
## 8) cptemps -> ~/projects/personal/codeprompts/src/templates/
## 9) .codeprompts.toml -> ~/projects/personal/dotfiles/codeprompts.toml
## 
## MacOS Specific Symlinks
## 1) .aerospace.toml -> ~/projects/personal/dotfiles/mac/aerospace.toml
## 2) .config/ghostty/config -> ~/projects/personal/dotfiles/mac/ghostty

PROJ_DIR=~/projects/
PERSONAL_DIR="${PROJ_DIR}/personal/"
MISC_DIR="${PROJ_DIR}/misc/"

mkdir -p "$PERSONAL_DIR"
mkdir -p "$MISC_DIR"

DOTFILES_DIR=~/projects/personal/dotfiles/
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
    echo "File exists and is not a symlink, moving to backup directory: $link_name"
    mv "$link_name" "${BACKUP_DIR}/$(basename "$link_name").bck"
    echo "Moved to $link_name to $BACKUP_DIR"
  fi

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
    create_symlink "$HOME_DIR/projects/personal/codeprompts/cli/src/templates" "$HOME_DIR/cptemps"
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

# Re-source files
if [ -f "$HOME_DIR/.bashrc" ]; then
    echo "Re-sourcing .bashrc"
    source "$HOME_DIR/.bashrc"
fi

if [ -f "$HOME_DIR/.tmux.conf" ]; then
    echo "Re-sourcing .tmux.conf"
    tmux source-file "$HOME_DIR/.tmux.conf"
fi

echo "All symlinks created successfully."
