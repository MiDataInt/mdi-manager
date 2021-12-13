#----------------------------------------------------------------
# launch the Stage 2 apps server when running in 'remote' or 'node' mode
# soured by 'mdi-remote-server.sh' and 'mdi-remote-node-job.sh' as needed
#----------------------------------------------------------------

# get shiny port
port <- Sys.getenv("SHINY_PORT")
if (is.null(port)) port <- 3838
port <- as.integer(port)

# get directories
dirs <- list()
for(name in c('DATA_DIRECTORY', 'HOST_DIRECTORY')){
    x <- Sys.getenv(name)
    if(x != "NULL" && x != "") dirs[[name]] <- x
}

# launch the server
mdi::run(
    mdiDir = Sys.getenv('MDI_DIRECTORY'),
    dataDir = dirs$DATA_DIRECTORY,
    hostDir = dirs$HOST_DIRECTORY,
    mode = Sys.getenv('MDI_REMOTE_MODE'),
    install = TRUE,
    url = 'http://127.0.0.1',
    port = port,
    browser = FALSE,
    debug = FALSE,
    developer = as.logical(Sys.getenv('DEVELOPER'))
)
