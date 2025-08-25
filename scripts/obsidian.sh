#!/bin/bash

SESSION_NAME="obsidian"
if [[ "$OSTYPE" == "darwin"* ]]; then
  VAULT_PATH="$HOME/Documents/obsidian_vault/"
else
  VAULT_PATH="$HOME/Documents/legion_vault/"
fi

# If not in tmux, create or attach to session
if [[ -z $TMUX ]]; then
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux attach-session -t "$SESSION_NAME"
  else
    tmux new-session -s "$SESSION_NAME" -c "$VAULT_PATH"
  fi
  exit 0
fi

# If in tmux and session doesn't exist, create it in detached mode
if ! tmux has-session -t="$SESSION_NAME" 2>/dev/null; then
  tmux new-session -ds "$SESSION_NAME" -c "$VAULT_PATH"
fi

# Switch to the obsidian session
tmux switch-client -t "$SESSION_NAME"
