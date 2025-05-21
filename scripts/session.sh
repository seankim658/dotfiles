#!/bin/bash

SEARCH_PATHS=(~/projects/hive ~/projects/personal ~/projects/misc ~/projects ~/scripts)

# Determines whether to open separate `frontend/` and `backend/` windows
is_split_project=false

# Parse command line args
while getopts "s" opt; do
  case $opt in
    s)
      is_split_project=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    esac
done

# Shift the options so $1 becomes the first non-option argument
shift $((OPTIND-1))

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

# Function to create session with frontend/backend directories
create_split_session() {
  local session_name=$1
  local project_dir=$2

  # Create new session with frontend window
  tmux new-session -ds $session_name -c "$project_dir" -n frontend
  tmux send-keys -t $session_name:0 "cd frontend" C-m

  # Create backend window
  tmux new-window -t $session_name:1 -n backend -c "$project_dir/backend"

  # Create shell window at project root
  tmux new-window -t $session_name:2 -n shell -c "$project_dir"

  # Select frontend window
  tmux select-window -t $session_name:0
}

# Function to create regular session
create_regular_session() {
  local session_name=$1
  local project_dir=$2

  # Create new session with code window
  tmux new-session -ds $session_name -c "$project_dir" -n code

  # Create shell window
  tmux new-window -t $session_name:1 -n shell -c "$project_dir"

  # Select code window
  tmux select-window -t $session_name:0
}

# If the script is not running inside an exisitng tmux session ($TMUX is unset)
if [[ -z $TMUX ]]; then
  # Check if session with the name already exists
  if tmux has-session -t=$selected_name 2> /dev/null; then
      # If the session already exists, attach to it
      tmux attach-session -t $selected_name
  else
    # If the session doesn't exist, create a new tmux session
    if [[ $is_split_project == true ]]; then
      create_split_session $selected_name "$selected"
      tmux attach-session -t $selected_name
    else
      tmux new-session -s $selected_name -c "$selected" -n code \; \
        new-window -n shell -c "$selected" \; \
        select-window -t code
    fi
  fi
    exit 0
fi

# If tmux is already running and the session does not exist, create in detached mode
if ! tmux has-session -t=$selected_name 2> /dev/null; then
  if [[ $is_split_project == true ]]; then
    create_split_session $selected_name "$selected"
  else
    create_regular_session $selected_name "$selected"
  fi
fi

tmux switch-client -t $selected_name
tmux select-window -t $selected_name:0
