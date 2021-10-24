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
parseDirectories <- function(rootDir, versions,
                             create = TRUE, message = FALSE,
                             dataDir = NULL, ondemandDir = NULL){
    if(message) message('parsing target directories')
    isOnDemand <- !is.null(ondemandDir)
    
    # parse the required rootDir
    rootDir <- path.expand(rootDir)
    if(!dir.exists(rootDir)) stop(paste("error:", rootDir, "does not exist"))
    rootFolder <- 'mdi'    
    if(!endsWith(rootDir, paste0('/', rootFolder))){
        rootDir <- file.path(rootDir, rootFolder)
        if(!dir.exists(rootDir)){
            if(create) createRootDir(rootDir)   
                  else throwRootDirError(rootDir)
        }
    }

    # parse top-level directory names
    bareDirNames <- c('data', 'environments', 'frameworks', 'library', 'resources', 'sessions', 'suites') 
    dirs <- as.list( file.path(rootDir, bareDirNames) )
    names(dirs) <- bareDirNames
    dirs$root <- rootDir
    
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
createRootDir <- function(rootDir){
    message()
    message('------------------------------------------------------------------')
    message('CONFIRM DIRECTORY CREATION')
    message('------------------------------------------------------------------')
    message('The following directory will be created and populated on your file system:')
    message()
    message(rootDir)
    message()
    confirmed <- readline(prompt = "Do you wish to continue? (type 'y' for 'yes'): ")
    confirmed <- strsplit(tolower(trimws(confirmed)), '')[[1]][1] == 'y'
    if(!is.na(confirmed) && confirmed){
        dir.create(rootDir, showWarnings = FALSE)
    } else {
        stop('installation permission denied')
    }    
}
throwRootDirError <- function(rootDir){
    message()
    message('Could not find the following directory on your file system:')
    message()
    message(rootDir)
    message()
    message('You must call mdi::run() using a value of rootDir')
    message('that you previously used for mdi::install().')
    message()
    stop('unknown rootDir')
}
