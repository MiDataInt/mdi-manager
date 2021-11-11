#---------------------------------------------------------------------------
# establish a list of installation actions to be taken and get permission to proceed
#---------------------------------------------------------------------------
getInstallationPermission <- function(mdiDir, installPackages, addToPATH, clone){

    # initialize the actions list
    actions <- character()
    confirmEnv <- environment()
    addAction <- function(action){
        assign('actions', c(actions, action), envir = confirmEnv)
    }

    # does the installation directory already exist?
    mdiDir <- parseMdiDir(mdiDir, check = FALSE, create = FALSE)
    create <- if(dir.exists(mdiDir)) "" else "create and "
    addAction(paste0(create, "populate directory '", mdiDir, "'"))

    # will we interact with GitHub to clone or update repositories?
    if(clone) 
        addAction(paste("clone or update MDI repositories from GitHub"))
    addAction("check out the most recent version of all definitive MDI repositories")

    # will we install apps R package dependencies?
    if(installPackages)
        addAction(paste0("install or update R packages into '", file.path(mdiDir, "library"), "'"))

    # will we attempt to update .bashrc on a Linux server?
    if(addToPATH && .Platform$OS.type == "unix") 
        addAction("modify '~/.bashrc' to add the mdi executable to PATH")

    # display the composite user prompt
    message('------------------------------------------------------------------')
    message('CONFIRM MDI INSTALLATION ACTIONS')
    message('------------------------------------------------------------------')
    message()
    message('The following actions will be taken to install the MDI on your system:')
    message()
    for(i in seq_along(actions)){
        message(paste0("  ", i, ") ", actions[i]))
    }
    message()

    # get and process user confirmation; stop unless permission is granted
    confirmed <- readline(prompt = "Do you wish to continue? (type 'y' for 'yes'): ")
    confirmed <- strsplit(tolower(trimws(confirmed)), '')[[1]][1] == 'y'
    if(is.na(confirmed) || !confirmed){
        message()
        message("please use '?mdi::install' for help on controlling the installation process")
        message()
        stop('installation permission denied')
    }    
}

#---------------------------------------------------------------------------
# validate that the mdi has previously been installed into mdiDir
#---------------------------------------------------------------------------
confirmPriorInstallation <- function(mdiDir){
    mdiDir <- parseMdiDir(mdiDir, check = FALSE, create = FALSE)
    isConfig <- file.exists(file.path(mdiDir, 'config', 'suites.yml'))
    if(isConfig) return()
    stop(paste(
        paste0("Not a valid MDI installation: '", mdiDir, "'."),
        "Please use 'mdi::install()' prior to calling 'mdi::run()'.",
        "Aborting run attempt.",
        sep = "\n"
    ))
}
