#!/bin/bash

# get input variables
export SHINY_PORT=$1

# check for server currently running on SHINY_PORT
PID_FILE=mdi-remote-pid-$SHINY_PORT.txt
MDI_PID=""
if [ -e $PID_FILE ]; then MDI_PID=`cat $PID_FILE`; fi
EXISTS=""
if [ "$MDI_PID" != "" ]; then EXISTS=`ps -p $MDI_PID | grep -v PID`; fi

# launch Shiny if not already running
if [ "$EXISTS" = "" ]; then
    Rscript mdi-remote-server.R &
    MDI_PID=$!
    echo "$MDI_PID" > $PID_FILE
fi

# report the PID to the user
echo
echo "web server process running on remote port $SHINY_PORT as PID $MDI_PID"

# report on usage within the command shell on user's local computer
echo
echo "type 'bash mdi-kill-remote.sh' to kill the remote web server"
echo
echo "type 'exit' followed by 'Ctrl-C' to close this port tunnel"
echo
echo "to use the MDI, point any web browser at:"
echo "http://127.0.0.1:$SHINY_PORT"
echo

# keep job blocked for ssh port forwarding by forking to a new, interactive bash shell
exec bash
