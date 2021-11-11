#!/bin/bash

# get input variables
export PROXY_PORT=$1
export R_VERSION=$2
export SHINY_PORT=$3
export MDI_DIR=$4 # must be valid, as it was used to call this script
export DATA_DIR=$5
export HOST_DIR=$6
export ACCOUNT=$7
export JOB_TIME_MINUTES=$8
export CPUS_PER_TASK=$9
export MEM_PER_CPU=$10

# set a function to discover any currently running MDI web server job
function set_server_node {
     NODE=`squeue --user=$USER | grep mdi_web | awk '{print $9}'`
    JOBID=`squeue --user=$USER | grep mdi_web | awk '{print $1}'`    
}
set_server_node

# launch a new MDI web server job if one isn't already running
SEPARATOR="---------------------------------------------------------------------"
if [[ "$NODE" = "" || "$NODE" = "(None)" ]]; then
    echo $SEPARATOR
    echo "please wait for the web server job to start"
    echo $SEPARATOR 
    module load R/$R_VERSION
    sbatch \
        --account $ACCOUNT \
        --time $JOB_TIME_MINUTES \
        --cpus-per-task $CPUS_PER_TASK \
        --mem-per-cpu $MEM_PER_CPU \
        $MDI_DIR/remote/mdi-remote-node-job.sh
    set_server_node
    while [[ "$NODE" = "" || "$NODE" = "(None)" ]]; do
        sleep 10
        set_server_node
    done
fi

# report the NODE and JOBID to the user
echo $SEPARATOR 
echo "Web server process running on remote node $NODE, port $SHINY_PORT, as job $JOBID"

# report on usage within the command shell on user's local computer
echo $SEPARATOR 
echo "To use the MDI, point any web browser to:"
echo "    http://$NODE:$SHINY_PORT"
echo "and use SwitchyOmega to set the proxy server to:"
echo "    socks5://127.0.0.1:$PROXY_PORT"

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

# kill the web server job if requested
if [ "$USER_ACTION" = "1" ]; then
    echo
    echo "Killing MDI server running on remote node $NODE, port $SHINY_PORT, as job $JOBID"
    scancel $JOBID
    echo "Done"
fi

# send a final helpful message
# note: the ssh process on client will NOT exit when this script exits since it is port forwarding still
echo
echo "Thank you for using the Michigan Data Interface."
echo "You may now safely close this command window."
