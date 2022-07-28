#----------------------------------------------------------------
# provide a clean process for monitoring and terminating the server
# sourced by 'mdi-remote-server.sh' or 'mdi-remote-node.sh'
#----------------------------------------------------------------

# give Shiny time to start up before showing further prompts   
WAIT_SECONDS=15
sleep $WAIT_SECONDS 

# report the PID to the user
echo $SEPARATOR
echo "MDI web server process running as PID: $MDI_PID"

# prompt for quit request
USER_ACTION=""
while [ "$USER_ACTION" != "quit" ]; do
    echo $SEPARATOR
    echo
    echo "Type 'quit' and hit Enter to stop the server: "
    read USER_ACTION
done

# kill the web server process
kill -9 $MDI_PID

# send a final helpful message
# note: ssh process on client will NOT exit when this script exits since it is port forwarding
echo
echo "Thank you for using the Michigan Data Interface."
echo "You may now safely close this command window."
