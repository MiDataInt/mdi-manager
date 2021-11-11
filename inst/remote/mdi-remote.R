# get shiny port
port <- Sys.getenv("SHINY_PORT")
if (is.null(port)) port <- 3838
port <- as.integer(port)

# get directories
dirs <- list()
for(name in c('DATA_DIR', 'HOST_DIR')){
    x <- Sys.getenv(name)
    if(x != "NULL" && x != "") dirs[[name]] <- x
}

# attempt to launch the server (may fail, if already running)
tryCatch({
    mdi::run(
        mdiDir = Sys.getenv('MDI_DIR'),
        dataDir = dirs$DATA_DIR,
        hostDir = dirs$HOST_DIR,
        mode = Sys.getenv('MDI_REMOTE_MODE'),
        install = TRUE,
        url = 'http://127.0.0.1',
        port = port,
        browser = FALSE,
        debug = FALSE,
        developer = FALSE
    )
}, error = function(e) message("Web server already running"))
