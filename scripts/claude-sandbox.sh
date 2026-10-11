#!/bin/bash

set -euo pipefail

## Run Claude Code in a container that only reaches a clone of the current repo
##
## Usage: claude-sandbox.sh [--rebuild] [claude args...]
##   --rebuild    Rebuild the image and recreate this repo's container
##   claude args  Passed to claude, such as --dangerously-skip-permissions
##
## Claude works in a sibling clone named <repo>-claude and reads the real repo
## at /upstream, which is mounted read-only. Patches and handoffs land in the
## clone's outbox/ folder. Each repo keeps its own container between runs, so
## installed dependencies persist. All containers share one Claude login.

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
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
    git clone --quiet "$repo_root" "$clone_dir"
    echo "Created Claude's clone: $clone_dir"
  elif [ ! -d "$clone_dir/.git" ]; then
    fail "Claude's clone must be a git repo, but $clone_dir is not"
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

# Two repos with the same folder name would otherwise share a container
require_same_repo() {
  local name=$1
  local repo_root=$2
  local mounted

  if [ "$(container_state "$name")" = missing ]; then
    return
  fi
  mounted="$(docker container inspect \
    --format '{{range .Mounts}}{{if eq .Destination "/upstream"}}{{.Source}}{{end}}{{end}}' "$name")"

  if [ "$mounted" != "$repo_root" ]; then
    fail "Container $name must mount $repo_root, but it mounts $mounted. Remove it with 'docker rm -f $name'."
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

  docker run --detach --name "$name" \
    --volume "$clone_dir:/workspace" \
    --volume "$repo_root:/upstream:ro" \
    --volume "$DOTFILES_DIR/llm:/opt/llm:ro" \
    --volume "$CONFIG_VOLUME:/home/node/.claude" \
    "$IMAGE" sleep infinity >/dev/null
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

main() {
  local rebuild=false
  if [ "${1:-}" = "--rebuild" ]; then
    rebuild=true
    shift
  fi

  command -v docker >/dev/null 2>&1 || fail "docker is not installed"
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "Not inside a git repo: $(pwd)"
  local clone_dir="$repo_root-claude"
  local name
  name="$(container_name "$repo_root")"

  require_same_repo "$name" "$repo_root"
  ensure_clone "$repo_root" "$clone_dir"
  prepare_image "$rebuild" "$name"
  start_container "$name" "$repo_root" "$clone_dir"
  docker exec "$name" /opt/llm/sandbox/link-config.sh

  echo "Patches and handoffs: $clone_dir/outbox"
  exec docker exec --interactive --tty "$name" claude "$@"
}

main "$@"
