#!/bin/bash

set -euo pipefail

## Link the dotfiles skills and coding guidelines into Claude Code's config
##
## Runs inside the sandbox on every launch, so skills added to dotfiles show up
## without a rebuild. A claude-code skill replaces a shared skill of the same
## name. Links to skills that no longer exist are removed.

LLM_DIR=/opt/llm
CONFIG_DIR="${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR must be set}"
SKILLS_DIR="$CONFIG_DIR/skills"

remove_stale_links() {
  find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type l -lname "$LLM_DIR/*" \
    ! -exec test -e {} \; -delete
}

link_skill() {
  local skill_dir=$1
  local link_name
  link_name="$SKILLS_DIR/$(basename "$skill_dir")"

  if [ -e "$link_name" ] && [ ! -L "$link_name" ]; then
    echo "Skipping $(basename "$skill_dir"), a skill made inside the sandbox has that name" >&2
    return
  fi
  ln -sfn "$skill_dir" "$link_name"
}

mkdir -p "$SKILLS_DIR"
remove_stale_links

for skill_dir in "$LLM_DIR"/skills/shared/*/ "$LLM_DIR"/skills/claude-code/*/; do
  [ -d "$skill_dir" ] || continue
  link_skill "${skill_dir%/}"
done

ln -sfn "$LLM_DIR/llm-instructions.md" "$CONFIG_DIR/CLAUDE.md"
