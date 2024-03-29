#---------------------------------------------------------------------------
# create and return the ordered folder structure of a MDI installation
#   mdi
#       config
#       containers
#           library
#       data
#       environments
#       frameworks
#           definitive
#           developer-forks
#       library
#           <R-0.0_BC-0.0>
#       remote
#       resources
#       sessions
#           <sessionId>
#       suites
#           definitive
#           developer-forks
#---------------------------------------------------------------------------
parseDirectories <- function(mdiDir, versions,
                             create = TRUE, message = FALSE,
                             dataDir = NULL, hostDir = NULL){
    if(message) message('parsing target directories')
    isHosted <- !is.null(hostDir)
    
    # parse the required mdiDir
    mdiDir <- parseMdiDir(mdiDir, check = TRUE, create = create)

    # parse top-level directory names
    bareDirNames <- c('config', 'containers', 'data', 'environments', 'frameworks', 'library', 
                      'remote', 'resources', 'sessions', 'suites') 
    dirs <- as.list( file.path(mdiDir, bareDirNames) )
    names(dirs) <- bareDirNames
    dirs$mdi <- mdiDir
    
    # override the data directory in run mode, if override is requested
    if(!is.null(dataDir)) dirs$data <- dataDir

    # override public directories when an installation uses shared code and resources
    if(isHosted){
        publicDirNames <- c('config', 'containers', 'environments', 'library', 'resources')
        for(dirName in publicDirNames) dirs[[dirName]] <- file.path(hostDir, dirName)
    }

    # initialize the file structure
    suiteName <- Sys.getenv('SUITE_NAME')
    noSuite <- "__no_suite__"
    if(suiteName == "") suiteName <- noSuite
    dirs$containersLibrary <- file.path(dirs$containers, suiteName, 'library') # used by 'extend'
    dirs$versionLibraryShort      <- file.path(dirs$library, versions$RVersionLong) # just library/R-4.2
    dirs$versionLibrary           <- file.path(dirs$library, versions$complete) # library/R-4.2_BC-3.15
    dirs$containersVersionLibraryShort <- file.path(dirs$containersLibrary, versions$RVersionLong) 
    dirs$containersVersionLibrary      <- file.path(dirs$containersLibrary, versions$complete) 
    if(create && !isHosted){
        for(dir in bareDirNames) dir.create(dirs[[dir]], showWarnings = FALSE)
        dir.create(dirs$containersLibrary, showWarnings = FALSE) 
        dir.create(dirs$versionLibraryShort, showWarnings = FALSE) 
        dir.create(dirs$versionLibrary, showWarnings = FALSE)
        dir.create(dirs$containersVersionLibraryShort, showWarnings = FALSE)   
        dir.create(dirs$containersVersionLibrary, showWarnings = FALSE)   
    }

    # on run, make sure everything exists as expected
    if(!create) for(dir in dirs){
        if(!dir.exists(dir) && !grepl(noSuite, dir)) stop(paste('missing directory:', dir))
    }
    
    dirs  
}
parseMdiDir <- function(mdiDir, check = TRUE, create = FALSE){
    mdiDir <- path.expand(mdiDir)
    rootFolder <- 'mdi'  
    endsWithRoot <- endsWith(mdiDir, paste0('\\', rootFolder)) || # windows
                    endsWith(mdiDir, paste0('/', rootFolder))     # not windows  
    mustExistDir <- if(endsWithRoot) dirname(mdiDir) else mdiDir
    if(!dir.exists(mustExistDir)) stop(paste("error:", mustExistDir, "does not exist"))
    if(!endsWithRoot) mdiDir <- file.path(mdiDir, rootFolder)
    if(check && !dir.exists(mdiDir)){
        if(create) dir.create(mdiDir, showWarnings = FALSE) # already confirmed by confirmInstallation()
              else throwMdiDirError(mdiDir)
    }
    mdiDir
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
