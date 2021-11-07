#!/bin/bash

# get input variables
R_VERSION=$1
SHINY_PORT=$2
ACCOUNT=$3
JOB_TIME_MINUTES=$4
CPUS_PER_TASK=$5
MEM_PER_CPU=$6

# set a function to discover any currently running MDI web server job
function set_server_node {
    NODE=`squeue --user=$USER | grep mdi_web | awk '{print $9}'`
    JOBID=`squeue --user=$USER | grep mdi_web | awk '{print $1}'`    
}
set_server_node

# launch a new MDI web server job if one isn't already running
if [[ "$NODE" = "" || "$NODE" = "(None)" ]]; then
    module load R/$R_VERSION
    sbatch \
        --account $ACCOUNT \
        --time $JOB_TIME_MINUTES \
        --cpus-per-task $CPUS_PER_TASK \
        --mem-per-cpu $MEM_PER_CPU \
        mdi-remote-node-job.sh $SHINY_PORT
    set_server_node
    while [[ "$NODE" = "" || "$NODE" = "(None)" ]]; do
        sleep 10
        set_server_node
    done
fi

# report the NODE and JOBID to the user
echo
echo "web server process running on remote node $NODE, port $SHINY_PORT, as job $JOBID"

# report on usage within the command shell on user's local computer
echo
echo "type 'scancel $JOBID' to kill the remote web server"
echo
echo "type 'exit' followed by 'Ctrl-C' to close this port tunnel"
echo
echo "to use the MDI, point the opened Chrome web browser at:"
echo "http://$NODE:$SHINY_PORT"
echo

# keep job blocked for ssh port forwarding by forking to a new, interactive bash shell
exec bash
