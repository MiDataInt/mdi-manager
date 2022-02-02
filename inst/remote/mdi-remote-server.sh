#!/bin/bash
#----------------------------------------------------------------
# run the MDI R server in 'remote' mode
# this script executes on the remote login server (not the user's local computer)
#----------------------------------------------------------------

# get input variables
export SHINY_PORT=$1
export MDI_DIRECTORY=$2 # must be valid, as it was used to call this script
export DATA_DIRECTORY=$3
export HOST_DIRECTORY=$4
export DEVELOPER=$5
export R_LOAD_COMMAND=`echo $6 | sed 's/~~/ /g'`
export MDI_REMOTE_MODE=remote

# check for server currently running on SHINY_PORT
PID_FILE=mdi-remote-pid-$SHINY_PORT.txt
MDI_PID=""
if [ -e $PID_FILE ]; then MDI_PID=`cat $PID_FILE`; fi
EXISTS=""
if [ "$MDI_PID" != "" ]; then EXISTS=`ps -p $MDI_PID | grep -v PID`; fi 

# launch Shiny if not already running
SEPARATOR="---------------------------------------------------------------------"
WAIT_SECONDS=15
if [ "$EXISTS" = "" ]; then
    echo $SEPARATOR 
    echo "Please wait $WAIT_SECONDS seconds for the web server to start"
    echo $SEPARATOR
    $R_LOAD_COMMAND
    bash $MDI_DIRECTORY/remote/mdi-remote.sh &
    MDI_PID=$!
    echo "$MDI_PID" > $PID_FILE
    sleep $WAIT_SECONDS # give Shiny time to start up before showing further prompts   
fi

# report the PID to the user
echo $SEPARATOR
echo "Web server process running on remote port $SHINY_PORT as PID $MDI_PID"

# report on browser usage within the command shell on user's local computer
echo $SEPARATOR
echo "To use the MDI, point any web browser to:"
echo
echo "http://127.0.0.1:$SHINY_PORT"
echo

# prompt for exit action, with or without killing of the R web server process
USER_ACTION=""
while [[ "$USER_ACTION" != "1" && "$USER_ACTION" != "2" ]]; do
    echo $SEPARATOR
    echo "To close the remote server connection:"
    echo
    echo "  1 - close the connection AND stop the web server"
    echo "  2 - close the connection, but leave the web server running"
    echo
    echo "Select an action (type '1' or '2' and hit Enter):"
    read USER_ACTION
done

# kill the web server process if requested
if [ "$USER_ACTION" = "1" ]; then
    source $MDI_DIRECTORY/remote/mdi-kill-remote.sh
fi 

# send a final helpful message
# note: the ssh process on client will NOT exit when this script exits since it is port forwarding still
echo
echo "Thank you for using the Michigan Data Interface."
echo "You may now safely close this command window."
