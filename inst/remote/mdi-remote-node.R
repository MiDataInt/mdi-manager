# get shiny port
port <- Sys.getenv("SHINY_PORT")
if (is.null(port)) port <- 3838
port <- as.integer(port)

# TEMP
.libPaths("/nfs/turbo/path-wilsonte-turbo/mdi/library/3.14")

# attempt to launch the server (may fail, if already running)
tryCatch({
    shiny::runExample(
        example = "01_hello",
        port = port,
        launch.browser = FALSE,
        host = "0.0.0.0"
    )
}, error = function(e) message("web server already running"))
