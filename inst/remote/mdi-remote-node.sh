#!/bin/bash
#----------------------------------------------------------------
# run the MDI R server in 'node' mode
# this script executes on the remote login server (not the user's 
#    local computer, and not on the node)
#----------------------------------------------------------------
# at present, only supports the Slurm job scheduler
#----------------------------------------------------------------

# get input variables
export PROXY_PORT=$1
export R_LOAD_COMMAND=`echo $2 | sed 's/~~/ /g'`
export SHINY_PORT=$3
export MDI_DIRECTORY=$4 # must be valid, as it was used to call this script
export DATA_DIRECTORY=$5
export HOST_DIRECTORY=$6
export DEVELOPER=$7
export CLUSTER_ACCOUNT=$8
export JOB_TIME_MINUTES=$9
export CPUS_PER_TASK=${10}
export MEM_PER_CPU=${11}

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
    $R_LOAD_COMMAND
    export BIOCONDUCTOR_RELEASE=` Rscript -e "cat( paste(BiocManager::version(), collapse='.') )"`
    sbatch \
        --account $CLUSTER_ACCOUNT \
        --time $JOB_TIME_MINUTES \
        --cpus-per-task $CPUS_PER_TASK \
        --mem-per-cpu $MEM_PER_CPU \
        $MDI_DIRECTORY/remote/mdi-remote-node-job.sh
    set_server_node
    while [[ "$NODE" = "" || "$NODE" = "("* ]]; do
        sleep 5
        set_server_node
    done
fi

# report the NODE and JOBID to the user
echo $SEPARATOR 
echo "Web server process running on remote node $NODE, port $SHINY_PORT, as job $JOBID"

# report on usage within the command shell on user's local computer
echo $SEPARATOR 
echo "To use the MDI, point any web browser to:"
echo
echo "    http://$NODE:$SHINY_PORT"
echo
echo "and use SwitchyOmega to set the proxy server to:"
echo
echo "    socks5://127.0.0.1:$PROXY_PORT"
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
