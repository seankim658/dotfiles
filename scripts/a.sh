#!/bin/bash

SESSION_NAME="win_def"
MAIN_WINDOW_NAME="main_win"
SECOND_WINDOW_NAME="sec_win"
CWD=$(pwd)

# check if the session already exists, supressing output
tmux has-session -t $SESSION_NAME &> /dev/null 

# check if the exit status of the previous command (whether the session exits)
if [ $? != 0 ]; then
  # the session does not already exist, create a new session in detached mode
  tmux new-session -s $SESSION_NAME -n $MAIN_WINDOW_NAME -d 
  # change main pane cwd 
  tmux send-keys -t $SESSION_NAME:$MAIN_WINDOW_NAME "cd $CWD" C-m 
  # create second window
  tmux new-window -t $SESSION_NAME -n $SECOND_WINDOW_NAME
  # change cwd of the secondary window
  tmux send-keys -t $SESSION_NAME:$SECOND_WINDOW_NAME "cd $CWD" C-m 
  # change focus back to main window 
  tmux select-window -t $SESSION_NAME:$MAIN_WINDOW_NAME

fi 

# attach to the session 
tmux attach -t $SESSION_NAME 

