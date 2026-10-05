#!/bin/bash

set -euo pipefail

## Pick a project directory and open (or switch to) a tmux session for it
##
## Usage: session.sh [-s] [directory]
##   -s         Create frontend/backend windows for a split project
##   directory  Use this directory instead of picking one with fzf

# Search paths that don't exist on this machine are skipped
SEARCH_PATHS=(
  "$HOME/projects"
  "$HOME/projects/personal"
  "$HOME/projects/work"
  "$HOME/projects/misc"
)

usage() {
  echo "Usage: $(basename "$0") [-s] [directory]" >&2
  exit 1
}

# Print the directory picked with fzf, or nothing if the picker is cancelled
pick_project_dir() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed" >&2
    exit 1
  fi

  local existing_paths=()
  local search_path
  for search_path in "${SEARCH_PATHS[@]}"; do
    if [[ -d $search_path ]]; then
      existing_paths+=("$search_path")
    fi
  done

  if [[ ${#existing_paths[@]} -eq 0 ]]; then
    echo "None of the search paths exist: ${SEARCH_PATHS[*]}" >&2
    exit 1
  fi

  find "${existing_paths[@]}" -mindepth 1 -maxdepth 1 -type d | fzf || true
}

# Print the absolute path of a directory argument
resolve_project_dir() {
  local dir=$1

  if [[ ! -d $dir ]]; then
    echo "Not a directory: $dir" >&2
    exit 1
  fi

  cd "$dir" && pwd
}

# Replace characters tmux does not allow in session names
session_name_for() {
  basename "$1" | tr '.:' '__'
}

validate_split_project() {
  local project_dir=$1
  local subdir

  for subdir in frontend backend; do
    if [[ ! -d $project_dir/$subdir ]]; then
      echo "Split project is missing $subdir/: $project_dir" >&2
      exit 1
    fi
  done
}

create_regular_session() {
  local session_name=$1
  local project_dir=$2

  tmux new-session -d -s "$session_name" -c "$project_dir" -n code
  tmux new-window -t "$session_name:" -n shell -c "$project_dir"
  tmux select-window -t "$session_name:code"
}

create_split_session() {
  local session_name=$1
  local project_dir=$2

  tmux new-session -d -s "$session_name" -c "$project_dir/frontend" -n frontend
  tmux new-window -t "$session_name:" -n backend -c "$project_dir/backend"
  tmux new-window -t "$session_name:" -n shell -c "$project_dir"
  tmux new-window -t "$session_name:" -n run -c "$project_dir/frontend"
  tmux split-window -t "$session_name:run" -v -c "$project_dir/backend"
  tmux select-window -t "$session_name:frontend"
}

is_split_project=false
while getopts "s" opt; do
  case $opt in
  s) is_split_project=true ;;
  *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -gt 1 ]]; then
  usage
fi

if [[ $# -eq 1 ]]; then
  project_dir=$(resolve_project_dir "$1")
else
  project_dir=$(pick_project_dir)
fi

# Exit quietly when the fzf picker is cancelled
if [[ -z $project_dir ]]; then
  exit 0
fi

session_name=$(session_name_for "$project_dir")

if ! tmux has-session -t "=$session_name" 2>/dev/null; then
  if [[ $is_split_project == true ]]; then
    validate_split_project "$project_dir"
    create_split_session "$session_name" "$project_dir"
  else
    create_regular_session "$session_name" "$project_dir"
  fi
fi

if [[ -z ${TMUX:-} ]]; then
  tmux attach-session -t "=$session_name"
else
  tmux switch-client -t "=$session_name"
fi
