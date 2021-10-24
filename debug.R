#---------------------------------------------------------------------------
# function to debug mdi-manager code changes
#---------------------------------------------------------------------------
debugManager <- function(
    mdiDir = 'C:/mdi',
    debugDir = 'test-installation', # path relative to mdiDir where mdi will be installed
    force = FALSE, # if TRUE, completely remove prior installation before installing
    gitUser = NULL, # same as mdi::install()
    token = NULL,
    clone = FALSE
){
    # set working directory
    setwd(mdiDir)
    message(paste("working directory:", mdiDir))
    message(paste("test installation directory:", file.path(mdiDir, debugDir)))

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
        mdiDir = debugDir, 
        gitUser = if(is.null(gitUser)) Sys.getenv('GIT_USER')   else gitUser,
        token   = if(is.null(token))   Sys.getenv('GITHUB_PAT') else token,
        clone = clone
    )
}
