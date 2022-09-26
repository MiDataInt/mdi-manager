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
#' the 'main' branch (or the tip of main if no version tags are set),
#' unless version overrides are provided via the \code{checkout} option.
#' 
#' When \code{developer} is TRUE, \code{run()} will use a developer-forks
#' repository for each framework or suite when it exists, otherwise, it
#' will fall back to the definitive repository. Forked repos will be left
#' on whatever branch they were already on, whereas definitive repos
#' will be checked out to the tip of the 'main' branch.
#' 
#' If access to private repositories or developer forks is needed, you must
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
#' @param dataDir character. Path to the directory where your MDI apps data
#' can be found. Defaults to '\code{mdiDir}/data'. You might wish to change
#' this to a directory that holds shared data, e.g., for your laboratory.
#' 
#' @param hostDir character. Path to the directory where a hosted, i.e., a 
#' shared public, installation of the MDI can be found. The following folders 
#' from that installation will be used instead of from the user installation 
#' executing the \code{mdi::run()} command: config, containers, environments, 
#' library, and resources. Option \code{hostDir} must be set if you ran 
#' \code{mdi::install()} with option \code{installPackages} set to FALSE.
#' 
#' @param mode character. Controls aspects of server behavior. The following
#' valid values will help you properly run the MDI web server on/in:
#'      local = your desktop or laptop; 
#'      remote = a server you have direct access to via SSH;
#'      node = a worker node in a Slurm cluster, accessed via SSH to a login node;
#'      server = a server container on a publicly addressable cloud instance.
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
#' Defaults to letting R Shiny select a random port. Example: setting \code{url} 
#' to 'https://mymdi.org' and \code{port} to 5000 will yield a final access 
#' url of 'https://mymdi.org:5000/'.
#' 
#' @param browser logical. Whether or not to attempt to launch a web browser 
#' after starting the MDI server. Defaults to FALSE unless \code{mode} is 
#' 'local'.
#'
#' @param debug logical. When \code{debug} is TRUE, verbose activity logs 
#' will be printed to the R console where \code{mdi::run()} was called. 
#' Defaults to FALSE. 
#' 
#' @param developer logical. When \code{developer} is TRUE, additional
#' development utilities are added to the web page and forked repositories
#' will be used if they exist. Ignored if \code{mode} is set to 'server'.
#' 
#' @param checkout list.  When not NULL (the default), a list of version tags, 
#' branch names, or git commit identifiers to check out prior to installing 
#' Stage 2 R packages and launching the apps server, of form 
#' \code{list(framework = "v0.0.0", suites = list(<suiteName> = "v0.0.0", ...))}
#' where framework refers to the mdi-apps-framework. If \code{checkout} or the 
#' list entry for a git repository is NULL or NA, the latest release tag will 
#' be checked out prior to installation (ignored for developer-forks of git repos). 
#' Finally, if \code{checkout} is FALSE, no git checkout actions will be taken.
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
    port = NULL, # if NULL, Shiny picks the port
    browser = mode %in% c('local'),
    debug = FALSE,
    developer = FALSE,
    checkout = NULL
){
    # NB: the rough order of operations for run() is deliberately parallel to install()
    # generally, run() works to help ensure a proper installation prior to launching the server

    # enforce option overrides
    if(!is.null(dataDir) && dataDir == "NULL") dataDir <- NULL
    if(!is.null(hostDir) && hostDir == "NULL") hostDir <- NULL    
    if(mode == 'server') developer <- FALSE # never show developer tools on public servers
    if(mode == 'node') install <- FALSE

    # determine whether we are running in a container
    staticMdiDir <- Sys.getenv('STATIC_MDI_DIR')
    isContainer  <- Sys.getenv('MDI_IS_CONTAINER') != ""

    # establish whether the MDI has been previously installed into mdiDir
    # combined with call to run(), take as permission to continue modifying user files
    confirmPriorInstallation(mdiDir)

    # collect directories for the user (i.e., calling) and host installations
    isHosted <- !is.null(hostDir)
    versions <- getRBioconductorVersions(mode == 'node')    
    dirs <- list(user = parseDirectories(mdiDir, versions, create = FALSE))
    if(isContainer) {
        dirs$user$versionLibraryShort <- dirs$user$containersVersionLibraryShort
        dirs$user$versionLibrary <- dirs$user$containersVersionLibrary
    }
    dirs$host <- if(isHosted) parseDirectories(hostDir, versions, create = FALSE) else dirs$user
    dirs$static <- if(isContainer) parseDirectories(staticMdiDir, versions, create = FALSE) else NULL
    setGitCredentials(dirs$user)

    # collect the list of all framework and suite repositories declared by the host installation
    # and parse the paths where they will be cloned or pulled into the user's installation
    # suitesFilePath <- file.path(dirs$host$config, 'suites.yml')
    # repos <- parseGitRepos(dirs$user, suitesFilePath)
    reposRdsFile <- file.path(dirs$user$library, "repos.rds")
    repos <- readRDS(reposRdsFile)

    # for most users, download (clone or pull) the most current version of the git repositories
    if(install) do.call(downloadGitRepo, repos)  
    if(!install) for(dir in filterRepoDirs(repos, fork = Forks$definitive)){
        if(!dir.exists(dir)) stop(paste('missing repository:', dir))
        isGitRepo(dir, require = TRUE)
    }

    # get the latest tagged versions of all existing repos
    repos$exists <- repoExists(repos$dir)
    repos <- repos[repos$exists, ]
    repos$latest <- do.call(getLatestVersions, repos)

    # establish the list of repos to use by the rules identified above
    # NB: code repos are _not_ public/shared assets to allow version selection by each user
    if(developer){
        getRepoI <- function(name, fork) which(repos$name == name & repos$fork == fork)
        is <- sapply(unique(repos$name), function(name){
            devI <- getRepoI(name, Forks$developer) # use developer fork if found, otherwise fall back to definitive
            if(length(devI)) devI else getRepoI(name, Forks$definitive)
        })
        repos <- repos[is, ]
    } else {
        repos <- repos[repos$fork == Forks$definitive, ] # thus, all existing definitive repos when not developing
    }
    appsFrameworkDir <- repos[repos$name == "mdi-apps-framework", 'dir']

    # revalidate the existence and integrity of all repos that are in use
    for(dir in repos$dir){
        gitConfig <- file.path(dir, '.git', 'config')
        if(!file.exists(gitConfig)) stop(paste(dir, 'is not a valid git repository'))
    }

    # checkout the appropriate repository versions
    message('locking repositories')
    setMdiGitLock(repos$dir)
    checkoutRepoTargets(repos, checkout, developer)

    # install any missing R packages if not hosted (hosts are expected to keep their installations up to date)
    if(install && !isHosted){
        collectAndInstallPackages( 
            cranRepo = 'https://repo.miserver.it.umich.edu/cran/', 
            force = FALSE, 
            versions = versions, 
            dirs = dirs$user, 
            repos = repos,
            releaseLocks = FALSE,
            staticLib = if(isContainer) dirs$static$versionLibrary else NULL
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
    if(isContainer) {
        dirs$versionLibraryShort <- dirs$containersVersionLibraryShort
        dirs$versionLibrary <- dirs$containersVersionLibrary
    }

    # set environment variables required by run_server.R
    dirsOut <- list()
    for(dirLabel in names(dirs)){    
        dirLabelOut <- paste(toupper(gsub('-', '_', dirLabel)), 'DIR', sep = '_') # e.g., yields DATA_DIR
        dirsOut[[dirLabelOut]] <- dirs[[dirLabel]]
    }
    do.call(Sys.setenv, dirsOut)
    Sys.setenv(SERVER_MODE = mode)
    Sys.setenv(SERVER_URL = url)
    if(!is.null(port)) Sys.setenv(SERVER_PORT = port)
    Sys.setenv(LAUNCH_BROWSER = browser)
    Sys.setenv(DEBUG = debug)
    Sys.setenv(IS_DEVELOPER = developer)
    Sys.setenv(APPS_FRAMEWORK_DIR = appsFrameworkDir)
    Sys.setenv(LIBRARY_DIR_SHORT = dirs$versionLibraryShort)
    Sys.setenv(LIBRARY_DIR = dirs$versionLibrary)

    # release repo locks immediately prior to launching server
    message('releasing repository locks')
    releaseMdiGitLock(repos$dir)

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
    port = NULL,
    ... # all other arguments are ignored
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
# shortcut to run on HPC server in 'remote' mode; used by server.pl 
#' @rdname run
#' @export
#---------------------------------------------------------------------------
remote <- function(
    mdiDir = '~', 
    dataDir = NULL,
    hostDir = NULL,         
    port = NULL,
    ... # all other arguments are ignored
){
    launchRemote('remote', mdiDir, dataDir, hostDir, port)
}

#---------------------------------------------------------------------------
# shortcut to run on HPC server in 'node' mode; used by server.pl 
#' @rdname run
#' @export
#---------------------------------------------------------------------------
node <- function(
    mdiDir = '~', 
    dataDir = NULL,
    hostDir = NULL,         
    port = NULL,
    ... # all other arguments are ignored
){
    launchRemote('node', mdiDir, dataDir, hostDir, port)
}
launchRemote <- function(
    mode,
    mdiDir, 
    dataDir,
    hostDir,         
    port
){
    developer <- Sys.getenv('DEVELOPER')
    run(
        mdiDir,
        dataDir = dataDir,
        hostDir = hostDir,  
        mode = mode,   
        install = TRUE, 
        url = 'http://127.0.0.1',
        port = port,
        browser = FALSE,
        debug = FALSE,
        developer = developer != "" && as.logical(developer)
    )
}
