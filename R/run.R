#---------------------------------------------------------------------------
#' Run the Michigan Data Interface (MDI) in a web server
#'
#' \code{run} launches the suites of data analysis applications that comprise
#' the Michigan Data Interface (MDI) in a web server, either on a web host 
#' that is publicly addressable, on your local computer, or on on a cluster 
#' compute node within an OnDemand batch job. \code{develop} is a shortcut 
#' to \code{run}  with settings appropriate for developers (mode='local', 
#' browser=FALSE, debug=TRUE, developer=TRUE).
#'
#' All default settings are consistent with an end user running the 
#' MDI in local mode on their desktop or laptop computer.
#'
#' \code{rootDir} must be the same directory as used in a prior
#' call to \code{mdi::install}.
#'
#' When \code{developer} is TRUE, you must have git properly installed on
#' your computer. If needed, you will be prompted to provide your email
#' address and user name on first use, which will be stored in your local
#' repositories and used to tag your code commits. To pull or push code
#' via the GUI, you must also have enabled non-prompted authorized
#' access to the remote repositories (e.g. via the command line).
#'
#' When \code{developer} is TRUE, \code{run()} always ensures that the current
#' git branch is somewhere other than 'main' (either 'develop' or your
#' current development branch). Otherwise, it resets the git branch to 'main'
#' at the appropriate version tag based on your system and usage.
#'
#' @param rootDir character. Path to the directory where the MDI
#' has previously been installed. Defaults to your home directory.
#'
#' @param dataDir character. Path to the directory where your MDI
#' data can be found. Defaults to code{rootDir}/data. You might wish to change
#' this to a directory that holds shared data, e.g., for your laboratory.
#'
#' @param ondemandDir character. Path to the directory where a public
#' installation of the MDI can be found. Some paths from this
#' installation will be used instead of the user's installation when code{mode}
#' is 'ondemand'.
#'
#' @param url character. The complete browser URL to load the web page. Must
#' include port 3838 and a trailing slash. Examples: 'http://localhost:3838/' 
#' or 'https://mymdi.org:3838/'.
#'
#' @param mode character. Either 'server', 'local' or 'ondemand'. Most users
#' want 'local' (the default) to run the MDI on your desktop or laptop. 
#' Mode 'server' is for a public web server, 'ondemand' is for managed execution
#' on an HPC cluster via Open OnDemand Interactive Apps.
#'
#' @param browser logical. Whether or not to attempt to launch a web browser 
#' after starting the MDI server. Defaults to TRUE unless \code{mode} is 'server'.
#'
#' @param debug logical. When \code{debug} is TRUE, verbose activity logs
#' will be printed to the R console where \code{mdi::run} was called.
#' Defaults to TRUE unless \code{mode} is 'server'.
#'
#' @param developer logical. When \code{developer} is TRUE, additional
#' development utilities are added to the web page. Only honored if
#' \code{mode} is 'local'.
#'
#' @param checkout character. If NULL (the default), \code{run} will auto-set
#' repositories to the appropriate branch based on R and MDI versions.
#' Developers might want to specify a code branch.
#'
#' @return These functions never return. They launch a blocking web server 
#' that runs perpeptually in the parent R process in the global environment.
#'
#' @name run
#---------------------------------------------------------------------------
NULL

#---------------------------------------------------------------------------
# run the MDI
#' @rdname run
#' @export
#---------------------------------------------------------------------------
run <- function(rootDir = '~',
                dataDir = NULL,
                ondemandDir = NULL,                
                url = 'http://localhost:3838/',
                mode = 'local',
                browser = mode != 'server',
                debug = mode != 'server',
                developer = FALSE,
                checkout = NULL){
    
    # never show developer tools on public servers
    if(mode == 'server') developer <- FALSE
    
    # parse needed versions and paths
    version <- version(quiet=TRUE)    
    dirs <- parseDirectories(rootDir, version, create=FALSE,
                             dataDir=dataDir, ondemandDir=ondemandDir)
    if(is.null(version)){ # in case remote recovery of versions failed
        version <- version(quiet=TRUE, dirs=dirs)
        if(is.null(version)) stop('unable to obtain resolve MDI version')
        dirs <- parseDirectories(rootDir, version, create=FALSE,
                                 dataDir=dataDir, ondemandDir=ondemandDir)
    }     
    
    # read the config file
    configFilePath <- copyConfigFile(dirs)    
    
    # collect the git repositories
    repos <- parseGitRepos(dirs, configFilePath, gitUser)


    # check for valid repos (NB: these are _not_ public assets in ondemand mode)
    # if missing, get user data on first developer call

    checkUpstreamRepos(repos)    
    
    user <- NULL
    for(repoKey in repoKeys){
        dir <- dirs[[repoKey]]
        gitConfig <- file.path(dir, '.git', 'config')
        if(!file.exists(gitConfig)) stop(
            paste(dir, 'is not a valid clone of the', repoKey, 'repository')
        )
        if(developer) user <- checkGitConfiguration(dir, gitConfig, user)
    }    

    # check for and automatically install missing package installations
    # minor version increments whenever code requires a new R package
    if(mode != 'ondemand'){ # public assets update is handled by administrators
        installedVersion <- version3ToIntegers( getInstalledVersion(dirs) )
        latestVersion    <- version3ToIntegers( version$MDIVersion )
        if(installedVersion$minor < latestVersion$minor ) install(rootDir) # major version already checked above        
    }

    # execute hard set of git branch consistent with usage mode and current repo status
    for(repoKey in repoKeys){
        initializeGitBranch(repoKey, dirs, repos, version, developer, checkout) 
    }    

    # set environment variables required by run_framework.R
    dirsOut <- list()
    for(dirLabel in names(dirs)){    
        dirLabelOut <- paste(toupper(gsub('-','_',dirLabel)), 'DIR', sep='_') # e.g., yields DATA_DIR
        dirsOut[[dirLabelOut]] <- dirs[[dirLabel]]
    }
    do.call(Sys.setenv, dirsOut)
    Sys.setenv(SERVER_URL = url)
    Sys.setenv(SERVER_MODE = mode)
    Sys.setenv(MDI_VERSION = version$MDIVersion)
    Sys.setenv(BIOCONDUCTOR_RELEASE = version$BioconductorRelease)
    Sys.setenv(LAUNCH_BROWSER = browser)
    Sys.setenv(DEBUG = debug)
    Sys.setenv(IS_DEVELOPER = developer)    

    # source the script that runs the server in the global environment
    # the web server never returns as it handles client requests via http
    source(file.path(dirs$magc_portal_apps,'shiny','run_framework.R'), local=.GlobalEnv)
}

#---------------------------------------------------------------------------
# run with developer tools exposed, local mode only
#' @rdname run
#' @export
#---------------------------------------------------------------------------
develop <- function(rootDir = '~', dataDir = NULL, url = 'http://localhost:3838/'){
    run(
        rootDir,
        dataDir = dataDir,
        ondemandDir = NULL,
        url = url,
        mode = 'local',
        browser = FALSE,
        debug = TRUE,
        developer = TRUE,
        checkout = NULL # initializeGitBranch handles branch selection for developer mode
    )
}

#---------------------------------------------------------------------------
# run within a batch process in an Open OnDemand HPC environment
#' @rdname run
#' @export
#---------------------------------------------------------------------------
ondemand <- function(ondemandDir, rootDir = '~', dataDir = NULL, port = 3838){
    url <- paste0('http://localhost:', port)
    run(
        rootDir,
        dataDir = dataDir,
        ondemandDir = ondemandDir, # the path where the public installation lives        
        url = url,
        mode = 'ondemand',
        browser = TRUE,
        debug = FALSE,
        developer = FALSE,
        checkout = NULL # initializeGitBranch handles branch selection for developer mode
    )
}

