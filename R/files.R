#---------------------------------------------------------------------------
# create and return the ordered folder structure of a MDI installation
#   mdi
#       data
#       environments
#       frameworks
#           definitive
#           developer-forks
#       library
#           <BioconductorRelease>
#       resources
#       sessions
#           <sessionId>
#       suites
#           definitive
#           developer-forks
#---------------------------------------------------------------------------
parseDirectories <- function(mdiDir, versions,
                             create = TRUE, message = FALSE,
                             dataDir = NULL, ondemandDir = NULL){
    if(message) message('parsing target directories')
    isOnDemand <- !is.null(ondemandDir)
    
    # parse the required mdiDir
    mdiDir <- path.expand(mdiDir)
    if(!dir.exists(mdiDir)) stop(paste("error:", mdiDir, "does not exist"))
    rootFolder <- 'mdi'    
    if(!endsWith(mdiDir, paste0('/', rootFolder))){
        mdiDir <- file.path(mdiDir, rootFolder)
        if(!dir.exists(mdiDir)){
            if(create) createMdiDir(mdiDir)   
                  else throwMdiDirError(mdiDir)
        }
    }

    # parse top-level directory names
    bareDirNames <- c('data', 'environments', 'frameworks', 'library', 'resources', 'sessions', 'suites') 
    dirs <- as.list( file.path(mdiDir, bareDirNames) )
    names(dirs) <- bareDirNames
    dirs$root <- mdiDir
    
    # override the data directory in run mode, if override is requested
    if(!is.null(dataDir)) dirs$data <- dataDir

    # override public directories when runtime mode is ondemand
    if(isOnDemand){
        publicDirNames <- c('environments', 'library', 'resources')
        for(dirName in publicDirNames) dirs[[dirName]] <- file.path(ondemandDir, dirName)
    }

    # initialize the file structure
    if(!isOnDemand) for(dir in bareDirNames) dir.create(dirs[[dir]], showWarnings = FALSE)
    dirs$versionLibrary <- file.path(dirs$library, versions$BioconductorRelease)    
    if(!isOnDemand) dir.create(dirs$versionLibrary, showWarnings = FALSE)    

    # on run, make sure everything exists as expected
    if(!create) for(dir in dirs){
        if(!dir.exists(dir)) stop(paste('missing directory:', dir))
    }
    
    dirs  
}
createMdiDir <- function(mdiDir){
    message()
    message('------------------------------------------------------------------')
    message('CONFIRM DIRECTORY CREATION')
    message('------------------------------------------------------------------')
    message('The following directory will be created and populated on your file system:')
    message()
    message(mdiDir)
    message()
    confirmed <- readline(prompt = "Do you wish to continue? (type 'y' for 'yes'): ")
    confirmed <- strsplit(tolower(trimws(confirmed)), '')[[1]][1] == 'y'
    if(!is.na(confirmed) && confirmed){
        dir.create(mdiDir, showWarnings = FALSE)
    } else {
        stop('installation permission denied')
    }    
}
throwMdiDirError <- function(mdiDir){
    message()
    message('Could not find the following directory on your file system:')
    message()
    message(mdiDir)
    message()
    message('You must call mdi::run() using a value of mdiDir')
    message('that you previously used for mdi::install().')
    message()
    stop('unknown mdiDir')
}
