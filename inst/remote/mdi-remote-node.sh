#!/bin/bash
#----------------------------------------------------------------
# run the MDI R server in 'node' mode
# this script executes on the remote login server (not the user's 
#    local computer, and not on the node)
#----------------------------------------------------------------
# at present, only supports the Slurm job scheduler
#----------------------------------------------------------------

# get input variables
export PROXY_PORT=$1 # NO LONGER USED (was for reporting only)
export R_LOAD_COMMAND=`echo $2 | sed 's/~~/ /g'`
export SHINY_PORT=$3 # must be a port number, otherwise can be anything
export MDI_DIRECTORY=$4 # must be valid, as it was used to call this script
export DATA_DIRECTORY=$5
export HOST_DIRECTORY=$6
export DEVELOPER=$7
export CLUSTER_ACCOUNT=$8
export JOB_TIME_MINUTES=$9
export CPUS_PER_TASK=${10}
export MEM_PER_CPU=${11}
export MDI_REMOTE_DOMAIN=${12}
export MDI_REMOTE_MODE=node

# launch MDI Shiny server as background process on a worker node
export SEPARATOR="---------------------------------------------------------------------"
$R_LOAD_COMMAND
export BIOCONDUCTOR_RELEASE=` Rscript -e "options(BiocManager.check_repositories = FALSE); cat( paste(BiocManager::version(), collapse='.') )"`
srun \
    --account $CLUSTER_ACCOUNT \
    --time $JOB_TIME_MINUTES \
    --cpus-per-task $CPUS_PER_TASK \
    --mem-per-cpu $MEM_PER_CPU \
    --job-name=mdi_web_server \
    --nodes=1 \
    --ntasks-per-node=1 \
    --partition=standard \
    bash $MDI_DIRECTORY/remote/mdi-remote.sh & # server runs in background
MDI_PID=$! # the pid of the srun process
trap "kill -9 $MDI_PID; exit" SIGINT SIGQUIT SIGHUP # make sure we always kill the server on exit

# source the remote server monitor in the main process on the login node
source $MDI_DIRECTORY/remote/mdi-remote-monitor.sh
