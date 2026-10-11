#!/bin/bash

set -euo pipefail

## Run Claude Code in a container that only reaches a clone of the current repo
##
## Usage: claude-sandbox.sh [--rebuild] [claude args...]
##   --rebuild    Rebuild the image and recreate this repo's container
##   claude args  Passed to claude, such as --dangerously-skip-permissions
##
## Claude works in its own clone at ~/projects/claude/<repo> and reads the real
## repo at /upstream, which is mounted read-only. Patches and handoffs land in
## the clone's outbox/ folder. The repo's project-knowledge/ folder is mounted
## read-only at /knowledge and added to the session, so its CLAUDE.md loads as
## project instructions. The repo's other/ folder is hidden from Claude. Each
## repo keeps its own container between runs, so installed dependencies
## persist. All containers share one Claude login. See llm/README.md.

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
CLONES_DIR="$HOME/projects/claude"
KNOWLEDGE_FOLDER=project-knowledge
PRIVATE_FOLDER=other
IMAGE=claude-sandbox
CONFIG_VOLUME=claude-sandbox-config

fail() {
  echo "$1" >&2
  exit 1
}

# Docker names allow letters, digits, and _.- only
container_name() {
  local repo_name
  repo_name="$(printf '%s' "$(basename "$1")" | tr -c 'a-zA-Z0-9_.-' '-')"
  echo "claude-sandbox-$repo_name"
}

ensure_clone() {
  local repo_root=$1
  local clone_dir=$2

  if [ ! -e "$clone_dir" ]; then
    mkdir -p "$(dirname "$clone_dir")"
    git clone --quiet "$repo_root" "$clone_dir"
    echo "Created Claude's clone: $clone_dir"
  elif [ ! -d "$clone_dir/.git" ]; then
    fail "Claude's clone must be a git repo, but $clone_dir is not"
  elif [ "$(git -C "$clone_dir" remote get-url origin)" != "$repo_root" ]; then
    fail "Claude's clone at $clone_dir must come from $repo_root, but it comes from $(git -C "$clone_dir" remote get-url origin)"
  fi
}

build_image() {
  docker build --tag "$IMAGE" \
    --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" \
    "$DOTFILES_DIR/llm/sandbox"
}

# Print running, stopped, or missing
container_state() {
  local running
  if ! running="$(docker container inspect --format '{{.State.Running}}' "$1" 2>/dev/null)"; then
    echo missing
  elif [ "$running" = true ]; then
    echo running
  else
    echo stopped
  fi
}

# Print the repo-specific mounts as destination=source lines, sorted. The other/
# mask is an empty tmpfs, so it has no source.
expected_mounts() {
  local repo_root=$1
  local clone_dir=$2

  {
    echo "/workspace=$clone_dir"
    echo "/upstream=$repo_root"
    if [ -d "$repo_root/$KNOWLEDGE_FOLDER" ]; then
      echo "/knowledge=$repo_root/$KNOWLEDGE_FOLDER"
    fi
    if [ -d "$repo_root/$PRIVATE_FOLDER" ]; then
      echo "/upstream/$PRIVATE_FOLDER="
    fi
  } | sort
}

actual_mounts() {
  docker container inspect \
    --format '{{range .Mounts}}{{.Destination}}={{.Source}}{{println}}{{end}}' "$1" \
    | grep -E "^/(workspace|upstream|knowledge|upstream/$PRIVATE_FOLDER)=" | sort
}

# Mounts are fixed when a container is made. This catches two repos with the
# same folder name, a moved clone, and knowledge or private folders added or
# removed since.
require_matching_container() {
  local name=$1
  local repo_root=$2
  local clone_dir=$3

  if [ "$(container_state "$name")" = missing ]; then
    return
  fi
  if [ "$(actual_mounts "$name")" != "$(expected_mounts "$repo_root" "$clone_dir")" ]; then
    fail "Container $name was made for different folders than this repo has now. Remove it with 'docker rm -f $name', then run this again."
  fi
}

prepare_image() {
  local rebuild=$1
  local name=$2

  if [ "$rebuild" = true ]; then
    if [ "$(container_state "$name")" != missing ]; then
      docker rm --force "$name" >/dev/null
    fi
    build_image
  elif ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    build_image
  fi
}

create_container() {
  local name=$1
  local repo_root=$2
  local clone_dir=$3
  local mounts=(
    --volume "$clone_dir:/workspace"
    --volume "$repo_root:/upstream:ro"
    --volume "$DOTFILES_DIR/llm:/opt/llm:ro"
    --volume "$CONFIG_VOLUME:/home/node/.claude"
  )

  if [ -d "$repo_root/$KNOWLEDGE_FOLDER" ]; then
    mounts+=(--volume "$repo_root/$KNOWLEDGE_FOLDER:/knowledge:ro")
  fi
  if [ -d "$repo_root/$PRIVATE_FOLDER" ]; then
    mounts+=(--mount "type=tmpfs,destination=/upstream/$PRIVATE_FOLDER,readonly")
  fi
  docker run --detach --name "$name" "${mounts[@]}" "$IMAGE" sleep infinity >/dev/null
}

start_container() {
  local name=$1
  local repo_root=$2
  local clone_dir=$3

  case "$(container_state "$name")" in
    missing) create_container "$name" "$repo_root" "$clone_dir" ;;
    stopped) docker start "$name" >/dev/null ;;
    running) ;;
  esac
}

# --add-dir gives Claude the knowledge folder, and the variable makes Claude
# Code load the CLAUDE.md and rules inside it
run_claude() {
  local name=$1
  local repo_root=$2
  shift 2

  if [ -d "$repo_root/$KNOWLEDGE_FOLDER" ]; then
    exec docker exec --interactive --tty \
      --env CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 \
      "$name" claude --add-dir /knowledge "$@"
  fi
  exec docker exec --interactive --tty "$name" claude "$@"
}

main() {
  local rebuild=false
  if [ "${1:-}" = "--rebuild" ]; then
    rebuild=true
    shift
  fi

  command -v docker >/dev/null 2>&1 || fail "docker is not installed"
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "Not inside a git repo: $(pwd)"
  local clone_dir
  clone_dir="$CLONES_DIR/$(basename "$repo_root")"
  local name
  name="$(container_name "$repo_root")"

  require_matching_container "$name" "$repo_root" "$clone_dir"
  ensure_clone "$repo_root" "$clone_dir"
  prepare_image "$rebuild" "$name"
  start_container "$name" "$repo_root" "$clone_dir"
  docker exec "$name" /opt/llm/sandbox/link-config.sh

  echo "Patches and handoffs: $clone_dir/outbox"
  run_claude "$name" "$repo_root" "$@"
}

main "$@"
