#!/bin/bash

SEARCH_PATHS=(~/projects/hive ~/projects/personal ~/projects/misc ~/projects ~/scripts)

if [[ "$OSTYPE" == "darwin"* ]]; then
  NOTES_PATH="$HOME/Documents/macos_vault/"
else
  NOTES_PATH="$HOME/Documents/legion_vault/"
fi

# If an argument is provided, use it as the selected directory
if [[ $# -eq 1 ]]; then
  selected=$1
else
  # Otherwise, use fzf to interactively select a directory from the specified paths
  selected=$(find "${SEARCH_PATHS[@]}" -mindepth 1 -maxdepth 1 -type d | fzf)
fi

# If no directory is selected (user pressed Esc or fzf returned nothing), exit
if [[ -z $selected ]]; then
  exit 0
fi 

# Extract the directory base name, replace dots with underscores, and use as session name
selected_name=$(basename $"$selected" | tr . _)

# If the script is not running inside an exisitng tmux session ($TMUX is unset)
if [[ -z $TMUX ]]; then
  # Check if session with the name already exists
  if tmux has-session -t=$selected_name 2> /dev/null; then
      # If the session already exists, attach to it
      tmux attach-session -t $selected_name
  else
    # If the session doesn't exist, create a new tmux session
    tmux new-session -s $selected_name -c $selected -n code \; \
      new-window -n shell -c $selected \; \
      new-window -n notes -c $NOTES_PATH \; \
      select-window -t code
  fi
    exit 0
fi

# If tmux is already running and the session does not exist, create in detached mode
if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected -n code
    tmux new-window -t $selected_name:1 -n shell -c $selected
    tmux new-window -t $selected_name:2 -n notes -c $NOTES_PATH
fi

tmux switch-client -t $selected_name
tmux select-window -t $selected_name:0
