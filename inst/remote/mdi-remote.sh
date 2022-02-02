#----------------------------------------------------------------
# launch the Stage 2 apps server when running in 'remote' or 'node' mode
# sourced by 'mdi-remote-server.sh' or 'mdi-remote-node-job.sh'
#----------------------------------------------------------------

# set shiny port
if [ "$SHINY_PORT" = "" ]; then export SHINY_PORT=3838; fi

# set directories
if [ "$DATA_DIRECTORY" = "" ]; then export DATA_DIRECTORY=NULL; fi
if [ "$HOST_DIRECTORY" = "" ]; then export HOST_DIRECTORY=NULL; fi

# launch the server
exec $MDI_DIRECTORY/mdi server \
    --server-command $MDI_REMOTE_MODE \
    --data-dir $DATA_DIRECTORY \
    --host-dir $HOST_DIRECTORY \
    --port $SHINY_PORT
