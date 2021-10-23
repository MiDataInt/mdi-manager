#---------------------------------------------------------------------------
# function to debug mdi-manager code changes
#---------------------------------------------------------------------------
debugManager <- function(
    rootDir = 'C:/mdi',
    debugDir = 'test-installation', # path relative to rootDir where mdi will be installed
    force = FALSE, # if TRUE, completely remove prior installation before installing
    gitUser = NULL, # same as mdi::install()
    token = NULL
){
    # set working directory
    setwd(rootDir)
    message(paste("working directory:", rootDir))
    message(paste("test installation directory:", file.path(rootDir, debugDir)))

    # detach prior mdi package
    message()
    message('DETACHING MDI')
    unloadNamespace("mdi")

    # rebuild the manager package
    message()
    message('UPDATING MDI MANAGER PACKAGE')
    remotes::install_local(
        path = 'manager/developer-forks/mdi-manager',
        force = TRUE
    )

    # remove the last installation
    if(force){
        message()
        message('REMOVING MDI INSTALLATION')
        unlink(debugDir, recursive = TRUE, force = TRUE)
    }
    if(!dir.exists(debugDir)) dir.create(debugDir)

    # run the installation
    message()
    message('INSTALLING THE MDI')
    message()
    mdi::install(
        rootDir = debugDir, 
        gitUser = if(is.null(gitUser)) Sys.getenv('GIT_USER')   else gitUser,
        token   = if(is.null(token))   Sys.getenv('GITHUB_PAT') else token
    )
}
