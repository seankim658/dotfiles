#!/bin/bash

set -euo pipefail

## Link the dotfiles skills, rules, and coding guidelines into Claude Code's config
##
## Runs inside the sandbox on every launch, so skills and rules added to
## dotfiles show up without a rebuild. A claude-code skill replaces a shared
## skill of the same name. Links to skills or rules that no longer exist are
## removed.

LLM_DIR=/opt/llm
CONFIG_DIR="${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR must be set}"
SKILLS_DIR="$CONFIG_DIR/skills"
RULES_DIR="$CONFIG_DIR/rules"

remove_stale_links() {
  find "$1" -mindepth 1 -maxdepth 1 -type l -lname "$LLM_DIR/*" \
    ! -exec test -e {} \; -delete
}

# Leave alone anything made inside the sandbox that shares a dotfiles name
link_into() {
  local source=$1
  local target_dir=$2
  local link_name
  link_name="$target_dir/$(basename "$source")"

  if [ -e "$link_name" ] && [ ! -L "$link_name" ]; then
    echo "Skipping $(basename "$source"), a file made inside the sandbox has that name" >&2
    return
  fi
  ln -sfn "$source" "$link_name"
}

mkdir -p "$SKILLS_DIR" "$RULES_DIR"
remove_stale_links "$SKILLS_DIR"
remove_stale_links "$RULES_DIR"

for skill_dir in "$LLM_DIR"/skills/shared/*/ "$LLM_DIR"/skills/claude-code/*/; do
  [ -d "$skill_dir" ] || continue
  link_into "${skill_dir%/}" "$SKILLS_DIR"
done

for rule in "$LLM_DIR"/rules/*.md; do
  [ -f "$rule" ] || continue
  link_into "$rule" "$RULES_DIR"
done

ln -sfn "$LLM_DIR/llm-instructions.md" "$CONFIG_DIR/CLAUDE.md"
