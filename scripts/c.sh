#!/bin/bash

SESSION_NAME="v_def"
MAIN_WINDOW_NAME="main_win"
CWD=$(pwd)

# check if the session already exists, supressing output
tmux has-session -t $SESSION_NAME &> /dev/null 

# check if the exit status of the previous command (whether the session exits)
if [ $? != 0 ]; then
  # the session does not already exist, create a new session in detached mode
  tmux new-session -s $SESSION_NAME -n $MAIN_WINDOW_NAME -d 
  # change main pane cwd 
  tmux send-keys -t $SESSION_NAME:$MAIN_WINDOW_NAME "cd $CWD" C-m 
  # create vertical split windows
  tmux split-window -v -l 20% -t $SESSION_NAME:$MAIN_WINDOW_NAME
  # change cwd of the secondary pane
  tmux send-keys -t $SESSION_NAME:$MAIN_WINDOW_NAME.1 "cd $CWD" C-m 
  # change focus back to main pane 
  tmux select-pane -t $SESSION_NAME:$MAIN_WINDOW_NAME.0

fi 

# attach to the session 
tmux attach -t $SESSION_NAME 
