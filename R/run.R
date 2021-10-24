#---------------------------------------------------------------------------
#' Run the Michigan Data Interface (MDI) in a web server
#'
#' \code{run()} launches the suites of data analysis applications that comprise
#' the Michigan Data Interface (MDI) in a web server, either on a web host 
#' that is publicly addressable, on your local computer, or on on a cluster 
#' compute node within an OnDemand batch job. \code{develop()} is a shortcut 
#' to \code{run()}  with settings appropriate for developers (mode='local', 
#' browser=FALSE, debug=TRUE, developer=TRUE).
#'
#' All default settings are consistent with an end user running the 
#' MDI in local mode on their desktop or laptop computer.
#'
#' \code{mdiDir} must be the same directory as used in a prior
#' call to \code{mdi::install()}.
#' 
#' When \code{developer} is FALSE, \code{run()} will use the definitive
#' version of all repositories checked out to the latest version tag on 
#' the 'main' branch.
#' 
#' When \code{developer} is TRUE, \code{run()} will use a developer-forks
#' repository for each framework or suite when it exists, otherwise, it
#' will fall back to the definitive repository. Forked repos will be left
#' on whatever branch they were already on, whereas definitive repos
#' will be checked out to the tip of the 'main' branch.
#' 
#' When \code{developer} is TRUE, you must have git properly installed on
#' your computer. If needed, you will be prompted to provide your email
#' address and user name on first use, which will be stored in your local
#' repositories and used to tag your code commits. To pull or push code
#' via the GUI, you must also have enabled non-prompted authorized
#' access to the remote repositories (e.g., via the command line).
#' 
#' @param mdiDir character. Path to the directory where the MDI
#' has previously been installed. Defaults to your home directory.
#'
#' @param dataDir character. Path to the directory where your MDI
#' data can be found. Defaults to code{mdiDir}/data. You might wish to change
#' this to a directory that holds shared data, e.g., for your laboratory.
#'
#' @param ondemandDir character. Path to the directory where a public
#' installation of the MDI can be found. Some paths from this
#' installation will be used instead of the user's installation when 
#' code{mode} is 'ondemand'.
#'
#' @param mode character. Either 'server', 'local' or 'ondemand'. Most users
#' want 'local' (the default) to run the MDI on your desktop or laptop. 
#' Mode 'server' is for a public web server, 'ondemand' is for managed execution
#' on an HPC cluster via Open OnDemand Interactive Apps.
#'
#' @param url character. The complete browser URL to load the web page. Must
#' include port 3838 and a trailing slash. Examples: 'http://localhost:3838/' 
#' or 'https://mymdi.org:3838/'.
#'
#' @param browser logical. Whether or not to attempt to launch a web browser 
#' after starting the MDI server. Defaults to TRUE unless \code{mode} is 'server'.
#'
#' @param debug logical. When \code{debug} is TRUE, verbose activity logs
#' will be printed to the R console where \code{mdi::run()} was called.
#' Defaults to TRUE unless \code{mode} is 'server'.
#'
#' @param developer logical. When \code{developer} is TRUE, additional
#' development utilities are added to the web page and forked repositories
#' will be used if they exist. Only honored if ' \code{mode} is 'local'.
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
run <- function(mdiDir = '~',
                dataDir = NULL,
                ondemandDir = NULL,  
                mode = 'local',                              
                url = 'http://localhost:3838/',
                browser = mode != 'server',
                debug = mode != 'server',
                developer = FALSE
){


# consider adding option install, if TRUE will ensure everything is up to date
install(
    mdiDir = mdiDir,
    stages = 1:2,
    gitUser = gitUser,
    token = token,                    
    clone = TRUE,                
    ondemand = mode == 'ondemand'
)



    # never show developer tools on public servers
    if(mode == 'server') developer <- FALSE

    # parse needed versions and file paths
    versions <- getRBioconductorVersions()
    dirs <- parseDirectories(mdiDir, versions, create = FALSE, dataDir = dataDir, ondemandDir = ondemandDir)

    # initialize config file 
    configFilePath <- file.path(dirs$mdi, 'config.yml')

    # collect the list of all framework and suite repositories for this installation
    repos <- parseGitRepos(dirs, configFilePath, gitUser)
    


    # # parse needed versions and paths
    # version <- version(quiet = TRUE)    
    # dirs <- parseDirectories(mdiDir, version, create = FALSE,
    #                          dataDir = dataDir, ondemandDir = ondemandDir)
    # if(is.null(version)){ # in case remote recovery of versions failed
    #     version <- version(quiet = TRUE, dirs = dirs)
    #     if(is.null(version)) stop('unable to obtain resolve MDI version')
    #     dirs <- parseDirectories(mdiDir, version, create = FALSE,
    #                              dataDir = dataDir, ondemandDir = ondemandDir)
    # }     
    
    # # read the config file
    # configFilePath <- copyConfigFile(dirs)    
    
    # collect the git repositories
    # repos <- parseGitRepos(dirs, configFilePath, gitUser)


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
        if(installedVersion$minor < latestVersion$minor ) install(mdiDir) # major version already checked above        
    }

    # execute hard set of git branch consistent with usage mode and current repo status
    for(repoKey in repoKeys){
        initializeGitBranch(repoKey, dirs, repos, version, developer, checkout) 
    }    





    # set environment variables required by run_server.R
    dirsOut <- list()
    for(dirLabel in names(dirs)){    
        dirLabelOut <- paste(toupper(gsub('-', '_', dirLabel)), 'DIR', sep = '_') # e.g., yields DATA_DIR
        dirsOut[[dirLabelOut]] <- dirs[[dirLabel]]
    }
    do.call(Sys.setenv, dirsOut)
    Sys.setenv(SERVER_URL = url)
    Sys.setenv(SERVER_MODE = mode)
    # Sys.setenv(MDI_VERSION = version$MDIVersion)
    Sys.setenv(BIOCONDUCTOR_RELEASE = versions$BioconductorRelease)
    Sys.setenv(LAUNCH_BROWSER = browser)
    Sys.setenv(DEBUG = debug)
    Sys.setenv(IS_DEVELOPER = developer)    

    # source the script that runs the server in the global environment
    # the web server never returns as it handles client requests via https

    # TODO: need a function to set the target repo for each definitive repo
    # (either definitive or forked depending on developer)

    source(file.path(dirs$magc_portal_apps, 'shiny', 'run_server.R'), local = .GlobalEnv)
}

#---------------------------------------------------------------------------
# run with developer tools exposed, local mode only
#' @rdname run
#' @export
#---------------------------------------------------------------------------
develop <- function(mdiDir = '~', dataDir = NULL, url = 'http://localhost:3838/'){
    run(
        mdiDir,
        dataDir = dataDir,
        ondemandDir = NULL,
        mode = 'local',        
        url = url,
        browser = FALSE,
        debug = TRUE,
        developer = TRUE
    )
}

#---------------------------------------------------------------------------
# run within a batch process in an Open OnDemand HPC environment
#' @rdname run
#' @export
#---------------------------------------------------------------------------
ondemand <- function(ondemandDir, mdiDir = '~', dataDir = NULL, port = 3838){
    url <- paste0('http://localhost:', port)
    run(
        mdiDir,
        dataDir = dataDir,
        ondemandDir = ondemandDir, # the path where the public installation lives 
        mode = 'ondemand',               
        url = url,
        browser = TRUE,
        debug = FALSE,
        developer = FALSE
    )
}
