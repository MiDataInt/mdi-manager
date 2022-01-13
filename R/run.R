#---------------------------------------------------------------------------
#' Run the Michigan Data Interface (MDI) in a web server
#'
#' \code{run()} launches the suites of data analysis applications that comprise
#' the Michigan Data Interface (MDI) in a web server, either on a web host 
#' that is publicly addressable, on your local computer, or on on a cluster 
#' compute node or other ssh accessible server. \code{develop()} is a shortcut 
#' to \code{run()} with settings appropriate for developers (mode='local', 
#' browser=FALSE, debug=TRUE, developer=TRUE).
#'
#' All default settings are consistent with an end user running the MDI in 
#' local mode on their desktop or laptop computer.
#'
#' \code{mdiDir} must be the same directory as used in a prior call to 
#' \code{mdi::install()}.
#' 
#' When \code{developer} is FALSE, \code{run()} will use the definitive
#' version of all repositories checked out to the latest version tag on 
#' the 'main' branch (or the tip of main if no version tags are set).
#' 
#' When \code{developer} is TRUE, \code{run()} will use a developer-forks
#' repository for each framework or suite when it exists, otherwise, it
#' will fall back to the definitive repository. Forked repos will be left
#' on whatever branch they were already on, whereas definitive repos
#' will be checked out to the tip of the 'main' branch.
#' 
#' When \code{developer} is TRUE, you must have git properly installed on
#' your computer. To pull or push code via the GUI, you must also have 
#' enabled non-prompted authorized access to the remote repositories 
#' (e.g., via the command line).
#' 
#' #' If access to private repositories or developer forks is needed, you must
#' create script 'gitCredentials.R' in \code{mdiDir} or your home directory, 
#' to be sourced by \code{mdi::run()}, with the following contents:
#' gitCredentials <- list(
#'     USER_NAME  = "First Last",
#'     USER_EMAIL = "lastf@example.com",
#'     GIT_USER   = "xxx",
#'     GITHUB_PAT = "xxx"
#' )
#' where GIT_USER and GITHUB_PAT are the username and Personal Access 
#' Token of a GitHub account that holds any developer forks and/or grants
#' permissions for accessing any tool suites that have restricted access.
#' You should protect gitCredentials.R by removing read permissions for 
#' anyone except yourself. If you are uncomfortable storing sensitive
#' information on disk, you may alternatively set gitCredentials values  
#' in the environment using Sys.setenv(GITHUB_PAT = "xxx"), etc., prior to
#' calling \code{mdi::run()}.
#' 
#' @param mdiDir character. Path to the directory where the MDI has 
#' previously been installed. Defaults to your home directory, such that 
#' the MDI will run from '~/mdi' by default.
#' 
#' @param dataDir character. Path to the directory where your MDI data
#' can be found. Defaults to '\code{mdiDir}/data'. You might wish to change
#' this to a directory that holds shared data, e.g., for your laboratory.
#' 
#' @param hostDir character. Path to the directory where a hosted, i.e., a 
#' shared public, installation of the MDI can be found. The following folders 
#' from that installation will be used instead of from the user installation 
#' executing the \code{mdi::run()} command:
#' \itemize{
#'   \item config
#'   \item containers
#'   \item environments
#'   \item library
#'   \item resources
#' }
#' Option \code{hostDir} must be set if you ran \code{mdi::install()}
#' with option \code{installPackages} set to FALSE.
#' 
#' @param mode character. Controls aspects of server behavior. The following
#' valid values will help you properly run the MDI web server on/in:
#' \itemize{
#'   \item local = your desktop or laptop
#'   \item remote = a server you have direct access to via SSH
#'   \item node = a worker node in a Slurm cluster, accessed via SSH to a login node
#'   \item ondemand = a worker node in a Slurm cluster, accessed via Open OnDemand
#'   \item server = a mdi-cloud-server container on a publicly addressable cloud instance
#' }
#' Most users manually calling \code{mdi::run()} want 'local' (the default). 
#' 
#' @param install logical. When TRUE (the default), \code{mdi::run()} will
#' clone or pull all repositories and install any missing R packages. Setting 
#' \code{install} to FALSE will allow the server to start a bit more quickly.
#' Ignored when \code{mode} is 'node', since cluster nodes are not expected 
#' to have internet access to download software.
#'
#' @param url character. The complete browser URL to load the web page. 
#' Examples: 'http://localhost' (the default) or 'https://mymdi.org'.
#'
#' @param port integer. The port to use on the host specified in \code{url}.
#' Defaults to the canonical Shiny port, 3838. Example: setting \code{url} 
#' to 'https://mymdi.org' and \code{port} to 5000 will yield a final access 
#' url of 'https://mymdi.org:5000/'.
#' 
#' @param browser logical. Whether or not to attempt to launch a web browser 
#' after starting the MDI server. Defaults to FALSE unless \code{mode} is 'local'
#' or 'ondemand'.
#'
#' @param debug logical. When \code{debug} is TRUE, verbose activity logs 
#' will be printed to the R console where \code{mdi::run()} was called. 
#' Defaults to FALSE. 
#' 
#' @param developer logical. When \code{developer} is TRUE, additional
#' development utilities are added to the web page and forked repositories
#' will be used if they exist. Ignored if \code{mode} is set to 'server'.
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
run <- function(
    mdiDir = '~',
    dataDir = NULL,
    hostDir = NULL,  
    mode = 'local',   
    install = TRUE, 
    url = 'http://localhost',
    port = 3838,
    browser = mode %in% c('local', 'ondemand'),
    debug = FALSE,
    developer = FALSE,
    frameworkVersion = "latest"        
){
    # NB: the rough order of operations for run() is deliberately parallel to install()
    # generally, run() works to help ensure a proper installation prior to launching the server

    # enforce option overrides
    if(mode == 'server') developer <- FALSE # never show developer tools on public servers
    if(mode == 'node') install <- FALSE

    # establish whether the MDI has been previously installed into mdiDir
    # combined with call to run(), take as permission to continue modifying user files
    confirmPriorInstallation(mdiDir)

    # collect directories for the user (i.e, calling) installation, and, if applicable, the host installation
    isHosted <- !is.null(hostDir)
    versions <- getRBioconductorVersions(mode == 'node')
    dirs <-       list(user = parseDirectories(mdiDir,  versions, create = FALSE))
    dirs$host <- if(isHosted) parseDirectories(hostDir, versions, create = FALSE) else dirs$user
    setGitCredentials(dirs$user)

    # collect the list of all framework and suite repositories declared by the host installation
    # and parse the paths where they will be cloned or pulled into the user's installation
    suitesFilePath <- file.path(dirs$host$config, 'suites.yml')
    repos <- parseGitRepos(dirs$user, suitesFilePath)

    # for most users, download (clone or pull) the most current version of the git repositories
    if(install) do.call(downloadGitRepo, repos)  
    if(!install) for(dir in filterRepoDirs(repos, fork = Forks$definitive)){
        if(!dir.exists(dir)) stop(paste('missing repository:', dir))
        isGitRepo(dir, require = TRUE)
    }

    # get the latest tagged versions of all existing repos
    repos$exists <- repoExists(repos$dir)
    repos <- repos[repos$exists, ]
    repos$version <- do.call(getLatestVersions, repos)

    # establish the list of repos to use by the rules identified in comments above
    # NB: code repos are _not_ public/shared assets to allow version selection by each user
    if(developer){
        getRepoI <- function(name, fork) which(repos$name == name & repos$fork == fork)
        is <- sapply(unique(repos$name), function(name){
            devI <- getRepoI(name, Forks$developer) # use developer fork if found, otherwise fall back to definitive
            if(length(devI)) devI else getRepoI(name, Forks$definitive)
        })
        repos <- repos[is, ]
    } else {
        repos <- repos[repos$fork == Forks$definitive, ]
    }
    appsFrameworkDir <- repos[repos$name == "mdi-apps-framework", 'dir']

    # revalidate the existence and integrity of all repos that are in use
    for(dir in repos$dir){
        gitConfig <- file.path(dir, '.git', 'config')
        if(!file.exists(gitConfig)) stop(paste(dir, 'is not a valid git repository'))
    }

    # checkout the appropriate repository versions
    #   definitive repositories use the most recent tagged version, 
    #       or the tip of main if no versions are declared or we are in developer mode
    #   developer-forks stay where the developer had them

    # TODO: definitive apps-framework should be set to frameworkVersion if not 'latest'
    # in contrast, tools suite versions probably don't need to be set here at all - set and working-copy them as apps load
    # thus, framework versons are set at server launch, suite versions are set within the running server, per session
    # actually, even the working copy is probably superfluous - remember that apps code is SOURCED all at once!
    # so, in fact, as app loads, determine the version, lock the repo, checkout as needed, source code, release the lock
    # all this is likely coordinated by observeLoadRequest and the file loading functions that call it
    # a careful look at observeLoadRequest might also reveal that the _session_ code in framework could also be versioned? 
    # but that is potentially dangerous, since the framework could be mixing code from different versions...
    # last thought for now: one a single-user server (e.g. local), could also restart the server with a new framework version
    # everything but run_server.R could probably be reset

    mapply(function(dir, fork, version){
        if(fork == Forks$definitive){
            branch <- if(developer || is.null(version) || is.na(version)) 'main' else paste0('v', version)
            checkoutGitBranch(dir, branch) # git checkout <tag> is fine but results in a detached head
        }     
    }, repos$dir, repos$fork, repos$version)

    # install any missing R packages if not hosted (hosts are expected to keep their installations up to date)
    if(install && !isHosted){
        collectAndInstallPackages(
            cranRepo = 'https://repo.miserver.it.umich.edu/cran/', 
            force = FALSE, 
            versions = versions, 
            dirs = dirs$user, 
            repos = repos
        )
    }

    # set environment variables with two values, one for user, one for host installation
    Sys.setenv(IS_HOSTED = isHosted)
    Sys.setenv(HOST_DIR = if(isHosted) hostDir else "")
    Sys.setenv(USER_CONFIG_DIR = dirs$user$config) # downstream might need portions of each config
    Sys.setenv(HOST_CONFIG_DIR = dirs$host$config)
    Sys.setenv(USER_RESOURCES_DIR = dirs$user$resources) # similarly, may use shared or personal resources
    Sys.setenv(HOST_RESOURCES_DIR = dirs$host$resources)    

    # update the primary directories to use, with overrides for data and hosted directories
    dirs <- parseDirectories(mdiDir, versions, create = FALSE, 
                             dataDir = dataDir, hostDir = hostDir)

    # set environment variables required by run_server.R
    dirsOut <- list()
    for(dirLabel in names(dirs)){    
        dirLabelOut <- paste(toupper(gsub('-', '_', dirLabel)), 'DIR', sep = '_') # e.g., yields DATA_DIR
        dirsOut[[dirLabelOut]] <- dirs[[dirLabel]]
    }
    do.call(Sys.setenv, dirsOut)
    Sys.setenv(SERVER_MODE = mode)
    Sys.setenv(SERVER_URL = url)
    Sys.setenv(SERVER_PORT = port)
    Sys.setenv(LAUNCH_BROWSER = browser)
    Sys.setenv(DEBUG = debug)
    Sys.setenv(IS_DEVELOPER = developer)
    Sys.setenv(APPS_FRAMEWORK_DIR = appsFrameworkDir)
    Sys.setenv(LIBRARY_DIR = dirs$versionLibrary)

    # source the script that runs the server in the global environment
    # the web server never returns as it handles client requests via https
    source(file.path(appsFrameworkDir, 'shiny', 'run_server.R'), local = .GlobalEnv)
}

#---------------------------------------------------------------------------
# shortcut to run with developer tools exposed, local mode only
#' @rdname run
#' @export
#---------------------------------------------------------------------------
develop <- function(
    mdiDir = '~', 
    dataDir = NULL,            
    url = 'http://localhost', 
    port = 3838
){
    run(
        mdiDir,
        dataDir = dataDir,
        hostDir = NULL,  
        mode = 'local',   
        install = TRUE, 
        url = url,
        port = port,
        browser = FALSE,
        debug = TRUE,
        developer = TRUE
    )
}

#---------------------------------------------------------------------------
# shortcut to run within a batch process in a production Open OnDemand HPC environment
#' @rdname run
#' @export
#---------------------------------------------------------------------------
ondemand <- function(
    hostDir, 
    mdiDir = '~', 
    dataDir = NULL, 
    port = 3838,
    debug = FALSE
){
    run(
        mdiDir,
        dataDir = dataDir,
        hostDir = hostDir, # the path where the public installation lives 
        mode = 'ondemand',  
        install = TRUE,               
        url = 'http://localhost:',
        port = port,
        browser = TRUE,
        debug = debug,
        developer = FALSE
    )
}
