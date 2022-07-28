#!/bin/bash
#----------------------------------------------------------------
# run the MDI R server in 'remote' mode
# this script executes on the remote login server (not the user's local computer)
#----------------------------------------------------------------

# get input variables
export SHINY_PORT=$1 # must be a port number that matches the forwarded port
export MDI_DIRECTORY=$2 # must be valid, as it was used to call this script
export DATA_DIRECTORY=$3
export HOST_DIRECTORY=$4
export DEVELOPER=$5
export R_LOAD_COMMAND=`echo $6 | sed 's/~~/ /g'`
export MDI_REMOTE_DOMAIN=$7
export MDI_REMOTE_MODE=remote

# launch MDI Shiny server as background process on the login node
export SEPARATOR="---------------------------------------------------------------------"
$R_LOAD_COMMAND
bash $MDI_DIRECTORY/remote/mdi-remote.sh & # server runs in background
MDI_PID=$! # the pid of the server process (after a series of execs)
trap "kill -9 $MDI_PID; exit" SIGINT SIGQUIT SIGHUP # make sure we always kill the server on exit

# source the remote server monitor in the main process
source $MDI_DIRECTORY/remote/mdi-remote-monitor.sh
