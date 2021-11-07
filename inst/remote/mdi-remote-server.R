# get shiny port
port <- Sys.getenv("SHINY_PORT")
if (is.null(port)) port <- 3838
port <- as.integer(port)

# attempt to launch the server (may fail, if already running)
tryCatch({
    shiny::runExample(
        example = "01_hello",
        port = port,
        launch.browser = FALSE,
        host = "127.0.0.1"
    )
}, error = function(e) message("web server already running"))
