#---------------------------------------------------------------------------
# functions to debug mdi-manager code changes
#---------------------------------------------------------------------------
# set environment variables as needed before running debugInstall() or debugRun():
#   Sys.setenv(GIT_USER = 'xxx')
#   Sys.setenv(GITHUB_PAT = 'xxx')
#---------------------------------------------------------------------------
debugInstall <- function(
    mdiDir = 'C:/mdi',
    debugDir = NA, # 'test-installation', # path relative to mdiDir where mdi will be installed
    force = FALSE, # if TRUE, completely remove prior installation before installing
    clone = FALSE
){
    # initialize
    initializeDebug(mdiDir, debugDir)

    # remove the last installation (but only if a specific installation subdirectory was defined)
    if(!is.na(debugDir)){
        if(force){
            message()
            message('REMOVING MDI INSTALLATION')
            unlink(debugDir, recursive = TRUE, force = TRUE)
        }
        if(!dir.exists(debugDir)) dir.create(debugDir)
    }

    # run the installation
    message()
    message('INSTALLING THE MDI')
    message()
    mdi::install(
        mdiDir = if(is.na(debugDir)) mdiDir else debugDir, 
        gitUser = Sys.getenv('GIT_USER'),
        token   = Sys.getenv('GITHUB_PAT'),
        clone = clone
    )
}
debugRun <- function(
    mdiDir = 'C:/mdi',
    debugDir = NA, # 'test-installation', # path relative to mdiDir
    install = TRUE,
    developer = TRUE
){
    # initialize
    initializeDebug(mdiDir, debugDir)

    # run the MDI
    message()
    message('RUNNING THE MDI')
    message()
    mdi::run(
        mdiDir = if(is.na(debugDir)) mdiDir else debugDir, 
        install = install,
        developer = developer,
        gitUser = Sys.getenv('GIT_USER'),
        token   = Sys.getenv('GITHUB_PAT')
    )
}
initializeDebug <- function(mdiDir, debugDir){

    # set working directory
    setwd(mdiDir)
    message(paste("working directory:", mdiDir))
    message(paste("installation subdirectory:", debugDir))

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
}
