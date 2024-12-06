#!/bin/bash

SESSION_NAME="obsidian"
if [[ "$OSTYPE" == "darwin"* ]]; then
  VAULT_PATH="$HOME/Documents/macos_vault/"
else
  VAULT_PATH="$HOME/Documents/legion_vault/"
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux attach-session -t "$SESSION_NAME"
else
  tmux new-session -s "$SESSION_NAME" -c "$VAULT_PATH"
fi
