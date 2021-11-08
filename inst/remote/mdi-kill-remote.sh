# get input variables
if [ "$SHINY_PORT" = "" ]; then SHINY_PORT=$1; fi
if [ "$SHINY_PORT" = "" ]; then 
    echo "ERROR: SHINY_PORT must be provided as first argument or environment variable"
    exit 1
fi
PID_FILE=mdi-remote-pid-$SHINY_PORT.txt

# kill the requested PID
MDI_PID=`cat $PID_FILE`
echo
echo "Killing remote MDI server process $MDI_PID running on port $SHINY_PORT"
kill -9 $MDI_PID
echo "Done"
