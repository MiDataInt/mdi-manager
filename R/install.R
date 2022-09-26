#---------------------------------------------------------------------------
#' Install the Michigan Data Interface (MDI) code repositories and dependencies
#'
#' Install all dependencies of the Michigan Data Interface (MDI). This will 
#' include Bioconductor's BiocManager and its child packages, as well as a 
#' series of Git repositories cloned from GitHub. 
#' 
#' No action will be taken unless approved by the user when prompted.
#' 
#' All default settings are consistent with an end user running the MDI in 
#' local mode on their desktop or laptop computer.
#' 
#' All components will be install into directory \code{mdiDir}. 
#' \code{mdiDir} must already exist, it will not be created. 
#' If \code{mdiDir} ends with '/mdi' it will be used as is. Otherwise, 
#' a subdirectory of that name will be created in \code{mdiDir}.
#'
#' If they do not already exist, \code{mdi::install()} will create a series 
#' of subdirectories in \code{mdiDir}, as follows:
#' \itemize{
#'   \item config = configuration data for the MDI installation
#'   \item containers = Singularity container images for suites that use them
#'   \item data = project-specific input and output files
#'   \item environments = conda environments used by data analysis pipelines
#'   \item frameworks = git repositories with common code for all pipelines and apps
#'   \item library = version-controlled library of R packages private to the MDI
#'   \item remote = scripts to help run the MDI in remote modes
#'   \item resources = version-controlled ~static files such as reference data sets
#'   \item sessions = temporary files associated with user web sessions
#'   \item suites = git repositories with code that defines specific pipelines and apps
#' }
#' 
#' If access to private repositories or developer forks is needed, you must
#' create script 'gitCredentials.R' in \code{mdiDir} or your home directory, 
#' to be sourced by \code{mdi::install()}, with the following contents:
#' 
#' gitCredentials <- list(  
#'     USER_NAME  = "First Last",  
#'     USER_EMAIL = "lastf@example.com",  
#'     GIT_USER   = "xxx",  
#'     GITHUB_PAT = "xxx"  
#' )
#' 
#' where GIT_USER and GITHUB_PAT are the username and Personal Access 
#' Token of a GitHub account that holds any developer forks and/or grants
#' permissions for accessing any tool suites that have restricted access.
#' You should protect gitCredentials.R by removing read permissions for 
#' anyone except yourself. If you are uncomfortable storing sensitive
#' information on disk, you may alternatively set gitCredentials values  
#' in the environment using Sys.setenv(GITHUB_PAT = "xxx"), etc., prior to
#' calling \code{mdi::install()}.
#'
#' @param mdiDir character. Path to the directory where the MDI will be/has 
#' been installed. Defaults to your home directory, such that the MDI will 
#' be installed into '~/mdi' by default.
#'
#' @param hostDir character. Path to the directory where a hosted, i.e., a 
#' shared public, installation of the MDI can be found. If not NULL (the default),
#' the only action taken will be to clone or update copies of the pipelines and  
#' apps suites specified in \code{hostDir}/config/suites.yml, which also forces 
#' \code{installPackages} to FALSE. The purpose of setting hostDir for 
#' \code{mdi::install()} is mainly to prepare to execute hosted Stage 1 pipelines.
#' 
#' @param installPackages logical. If TRUE (the default), \code{mdi::install()} 
#' will fully install both Stage 1 Pipelines and Stage 2 Apps. If you know you  
#' will only want to use Stage 1 Pipelines from your installation, or if you 
#' will always use \code{mdi::run()} option \code{hostDir} to run the Stage 2  
#' Apps server with code sourced from a shared MDI installation, then setting 
#' \code{installPackages} to FALSE will skip the much slower installation of  
#' the Stage 2 R packages library.
#' 
#' @param confirm logical. If TRUE (the default) and in interactive mode,
#' \code{mdi::install()} will list all actions to be taken and prompt for 
#' permission before creating or modifying any system files.
#'
#' @param clone logical. If TRUE (the default), the apps and pipelines code 
#' repositories will be cloned anew from GitHub if they do not already exist, 
#' or they will be pulled from the server to update a repository if they have been 
#' cloned previously. Developers might want to set this option to FALSE.
#' 
#' @param cranRepo character. The base URL of the R repository to use, e.g., the
#' URL of a CRAN mirror. Defaults to the University of Michigan CRAN mirror.
#'
#' @param packages character vector. If not NULL (the default), only install
#' these specific R packages (for developers to quickly update selected
#' packages). No other actions will be taken and the library's installation.rds
#' file will not be updated.
#' 
#' @param force logical.  When FALSE (the default), \code{mdi::install()}
#' does not attempt to update R packages that have previously been installed,
#' regardless of version. When TRUE, all packages are installed without further
#' prompting.
#' 
#' @param checkout list.  When not NULL (the default), a list of version tags, 
#' branch names, or git commit identifiers to check out prior to installing 
#' Stage 2 R packages, of form 
#' \code{list(framework = "v0.0.0", suites = list(<suiteName> = "v0.0.0", ...))}
#' where framework refers to the mdi-apps-framework. If \code{checkout} or the 
#' list entry for a git repository is NULL or NA, the latest release tag will 
#' be checked out prior to installation (ignored for developer-forks of git repos). 
#' Finally, if \code{checkout} is FALSE, no git checkout actions will be taken.
#'  
#' @return A list of installation data with names components 'versions', dirs', 
#' 'repos', 'rRepos', 'packages'. This information will be incomplete if 
#' \code{packages} was not NULL (repos and rRepos will be NULL, packages will  
#' only contain\code{packages}) or if installPackages was FALSE (repos, rRepos  
#' and packages will all be NULL).
#'
#' @export
#---------------------------------------------------------------------------
install <- function(
    mdiDir = '~',
    hostDir = NULL, 
    installPackages = TRUE,
    confirm = TRUE,                
    clone = TRUE,
    cranRepo = 'https://repo.miserver.it.umich.edu/cran/',                    
    packages = NULL,
    force = FALSE,
    checkout = NULL
){
    # enforce option overrides
    if(!is.null(hostDir) && hostDir == "NULL") hostDir <- NULL # deal with vagary of remote scripts
    isHosted <- !is.null(hostDir)
    if(isHosted) installPackages <- FALSE

    # collate actions to be take and prompt for confirmation
    if(confirm && interactive()) 
        getInstallationPermission(mdiDir, installPackages, clone)

    # parse needed versions and file paths
    versions <- getRBioconductorVersions()
    dirs <- parseDirectories(mdiDir, versions, message = TRUE)
    setGitCredentials(dirs)

    # if developer requests an override, just install those specific R packages and stop
    if(!is.null(packages)){
        packages <- unique(unname(unlist(packages)))
        installPackages(versions, dirs, packages, force)
        return( getInstallationData(versions, dirs, packages = packages) )
    }

    # initialize config files
    suitesFilePath <- copyConfigFile(dirs, 'suites.yml') 
    copyConfigFile(dirs, 'stage1-pipelines.yml') 
    copyConfigFile(dirs, 'stage2-apps.yml')
    copyRemoteFiles(dirs) 

    # collect the list of all framework and suite repositories requested for this installation
    if(isHosted) suitesFilePath <- file.path(hostDir, 'config', 'suites.yml')
    repos <- parseGitRepos(dirs, suitesFilePath)

    # process the requested repos, plus any chained suite dependencies
    while(TRUE){
        priorRepos <- repos[!is.na(repos$exists), ]
        newRepos   <- repos[ is.na(repos$exists), ]

        # for most users, download (clone or pull) the most current version of the git repositories
        if(clone) do.call(downloadGitRepo, newRepos)  
        if(!clone) for(dir in filterRepoDirs(newRepos, fork = Forks$definitive)){
            if(!dir.exists(dir)) stop(paste('missing repository:', dir))
            isGitRepo(dir, require = TRUE)
        }

        # get the latest tagged versions of all repos
        newRepos$exists <- repoExists(newRepos$dir)
        newRepos$latest <- do.call(getLatestVersions, newRepos)

        # checkout the appropriate repository versions to continue with the installation
        # for install, both definitive and developer forks are scanned for suite dependencies and R packages
        message('locking repositories')
        setMdiGitLock(newRepos$dir[newRepos$exists & newRepos$fork == Forks$definitive])
        checkoutRepoTargets(newRepos, checkout)
        repos <- mergeGitRepoLists(priorRepos, newRepos)    

        # find external suite dependencies not already in repos
        message("check for additional dependencies")
        newDirs <- newRepos[newRepos$exists, 'dir']
        urls <- unique(unlist(sapply(newDirs, function(dir){
            configFile <- file.path(dir, "_config.yml")
            if(!file.exists(configFile)) return(character())
            suiteConfig <- yaml::read_yaml(configFile)
            if(is.null(suiteConfig$suite_dependencies)) return(character())
            expandGitUrls(suiteConfig$suite_dependencies)         
        })))
        urls <- urls[!(urls %in% repos[, 'url'])] # NOT just newRepos
        if(length(urls) == 0) break

        # append new dependencies to the repos list and iterate
        message("installing additional dependencies")
        dependencies <- assembleReposList(dirs, Types$suite, Stages$tools, urls)
        repos <- mergeGitRepoLists(repos, dependencies)
    }

    # write repos.rds for use by mdi::run(), with information on all officially installed repos
    reposRdsFile <- file.path(dirs$library, "repos.rds")
    saveRDS(repos, reposRdsFile)

    # initialize MDI root batch execution files
    mdiPath <- updateRootFile(
        dirs, 
        'mdi',
        executable = TRUE
    ) 

    # initialize the mdi command line utility
    if(.Platform$OS.type == "unix") {
        initializeJobManager(mdiPath)
        dir <- file.path(mdiDir, "frameworks/developer-forks/mdi-pipelines-framework")
        if(dir.exists(dir)) initializeJobManager(mdiPath, developer = TRUE)
    }

    # install Stage 2 apps packages
    # all paths must release repo locks
    if(!installPackages){
        message('releasing repository locks')
        releaseMdiGitLock(repos$dir[repos$exists])
        return( getInstallationData(versions, dirs) ) 
    }
    collectAndInstallPackages(cranRepo, force, versions, dirs, repos)
}
getInstallationData <- function(versions, dirs, repos = NULL, rRepos = NULL, packages = NULL){
    list(
        versions = versions, 
        dirs = dirs,
        repos = repos, 
        rRepos = rRepos,
        packages = sort(packages)
    )
}

#---------------------------------------------------------------------------
# use BiocManager to install all apps R packages (whether CRAN or Bioconductor)
#---------------------------------------------------------------------------
collectAndInstallPackages <- function(cranRepo, force, 
                                      versions, dirs, repos, releaseLocks = TRUE,
                                      staticLib = NULL){

    # set the public R package repositories
    message('collecting R repository information')
    options(BiocManager.check_repositories = FALSE)
    rRepos <- list(R = cranRepo)
    rRepos$Bioconductor <- unname(BiocManager::repositories()['BioCsoft']) 

    # collect the complete list of packages used by the framework and all Stage 2 apps
    # (pipelines repos don't depend on R packages installed here, they use conda)
    pkgLists <- getAppsPackages(repos, rRepos)   
    packages <- unique(unname(unlist(pkgLists)))

    # record the app versions that led to the current set of installed R library packages
    # used by run() to determine if latest app versions have missing package installations
    installationFile <- file.path(dirs$versionLibrary, 'installation.rds')
    installationData <- getInstallationData(versions, dirs, 
                                            repos = repos, rRepos = rRepos, packages = packages)
    saveRDS(installationData, installationFile)

    # install or update all required apps R packages
    if(releaseLocks) {
        message('releasing repository locks')
        releaseMdiGitLock(repos$dir[repos$exists])
    }
    installPackages(versions, dirs, packages, force, staticLib)

    # return installation data
    installationData
}
installPackages <- function(versions, dirs, packages, force, staticLib = NULL){
    activeLibShort <- dirs$versionLibraryShort # honor packages in the R-version-only library
    activeLib <- dirs$versionLibrary
    systemLib <- Sys.getenv("MDI_SYSTEM_R_LIBRARY")
    if(systemLib == "" || !dir.exists(systemLib)) systemLib <- NULL
    getRPackages <- function(lib) {
        if(is.null(lib)) character() 
        else list.dirs(lib, full.names = FALSE, recursive = FALSE)
    }
    newPackages <- if(force) packages else {
        activePackagesShort <- getRPackages(activeLibShort)
        activePackages <- getRPackages(activeLib)
        staticPackages <- getRPackages(staticLib)
        systemPackages <- getRPackages(systemLib)
        existingPackages <- unique(c(activePackagesShort, activePackages, staticPackages, systemPackages))
        packages[!(packages %in% existingPackages)]
    } 
    if(length(newPackages) > 0 || # missing packages
       length(packages) == 0) {   # user just requested an update of current packages
        Ncpus <- Sys.getenv("N_CPU")
        if(Ncpus == "") Ncpus <- 1       
        message('installing/updating R packages in private library')
        message(paste("installing", length(newPackages), "of a total of", 
                                    length(packages),    "required packages"))
        message(paste('installing into:', activeLib))
        if(!is.null(staticLib)) message(paste('honoring:', staticLib))
        if(!is.null(systemLib)) message(paste('honoring:', systemLib))
        message(paste("Ncpus =", Ncpus))
        BiocManager::install(
            newPackages,
            lib.loc = c(activeLibShort, activeLib, staticLib, systemLib),
            lib     = activeLib,
            #update = TRUE,
            update = FALSE,
            ask = FALSE,
            checkBuilt = FALSE,
            force = TRUE,
            version = versions$BioconductorRelease,
            Ncpus = Ncpus,
            type = .Platform$pkgType # force binary on Windows
        )         
    } else {
        message(paste('available library(s) already have all', length(packages), "required packages"))
        message(activeLib)   
    }
}
