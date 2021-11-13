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
#' @param addToPATH logical. If TRUE (the default) and installing on a Linux
#' platform computer, \code{mdi::install()} will modify ~/.bashrc to add
#' the 'mdi' executable to your PATH variable at each shell login, so that 
#' you may call MDI pipelines from any directory as 'mdi ...'.
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
    addToPATH = TRUE,                 
    clone = TRUE,
    cranRepo = 'https://repo.miserver.it.umich.edu/cran/',                    
    packages = NULL,
    force = FALSE
){
    # enforce option overrides
    isHosted <- !is.null(hostDir)
    if(isHosted) installPackages <- FALSE

    # collate actions to be take and prompt for confirmation
    if(confirm && interactive()) 
        getInstallationPermission(mdiDir, installPackages, addToPATH, clone)

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

    # collect the list of all framework and suite repositories for this installation
    if(isHosted) suitesFilePath <- file.path(hostDir, 'config', 'suites.yml')
    repos <- parseGitRepos(dirs, suitesFilePath)

    # for most users, download (clone or pull) the most current version of the git repositories
    if(clone) do.call(downloadGitRepo, repos)  
    if(!clone) for(dir in filterRepoDirs(repos, fork = Forks$definitive)){
        if(!dir.exists(dir)) stop(paste('missing repository:', dir))
        isGitRepo(dir, require = TRUE)
    }

    # get the latest tagged versions of all repos
    repos$exists <- repoExists(repos$dir)
    repos$version <- do.call(getLatestVersions, repos)

    # checkout the appropriate repository versions to continue with the installation
    #   definitive repositories use the most recent tagged version
    #   developer-forks stay where the developer had them (tip of 'main' if a new installation)
    message('checking out most recent versions')
    mapply(function(dir, fork, version){
        if(!is.null(dir) && !is.na(dir) && 
           !is.null(version) && !is.na(version) &&
           fork == Forks$definitive){
            branch <- paste0('v', version)
            checkoutGitBranch(dir, branch) # git checkout <tag> is fine but results in a detached head
        }        
    }, repos$dir, repos$fork, repos$version)

    # initialize MDI root batch execution files
    mdiPath <- updateRootFile(
        dirs, 
        'mdi',
        executable = TRUE
    ) 
    if(.Platform$OS.type != "unix") {
        updateRootFile(
            dirs, 
            'mdi-local.bat', 
            replace = list(PATH_TO_R  = R.home())
        )
    }

    # initialize the mdi command line utility
    if(.Platform$OS.type == "unix") {
        initializeJobManager(mdiPath)
        dir <- file.path(mdiDir, "frameworks/developer-forks/mdi-pipelines-framework")
        if(dir.exists(dir)) initializeJobManager(mdiPath, developer = TRUE)
        addMdiDirToPATH(mdiDir = mdiDir, addToPATH = addToPATH)
    }

    # install Stage 2 apps packages
    if(!installPackages) return( getInstallationData(versions, dirs) )
    return( collectAndInstallPackages(cranRepo, force, versions, dirs, repos) )
}
getInstallationData <- function(versions, dirs, repos = NULL, rRepos = NULL, packages = NULL){
    list(
        versions = versions, 
        dirs = dirs,
        repos = repos, 
        rRepos = rRepos,
        packages = packages
    )
}

#---------------------------------------------------------------------------
# use BiocManager to install all apps R packages (whether CRAN or Bioconductor)
#---------------------------------------------------------------------------
collectAndInstallPackages <- function(cranRepo, force, 
                                      versions, dirs, repos){

    # set the public R package repositories
    message('collecting R repository information')
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
    installPackages(versions, dirs, packages, force)

    # return installation data
    installationData
}
installPackages <- function(versions, dirs, packages, force){
    dir <- dirs$versionLibrary
    newPackages <- if(force) packages else {
        existingPackages <- list.dirs(dir, full.names = FALSE, recursive = FALSE)
        packages[!(packages %in% existingPackages)]
    }    
    if(length(newPackages) > 0 || # missing packages
       length(packages) == 0) {   # user just requested an update of current packages
        message('installing/updating R packages in private library')
        message(dir)        
        BiocManager::install(
            newPackages,
            lib.loc = dir,
            lib     = dir,
            #update = TRUE,
            update = FALSE,
            ask = FALSE,
            checkBuilt = FALSE,
            force = TRUE,
            version = versions$BioconductorRelease
            #,
            #type = .Platform$pkgType
        )         
    } else {
        message('private library has all required packages')
        message(dir)   
    }
}
#Old packages: 'htmltools', 'rtracklayer', 'stringi', 'survival', 'tibble'
#Error in update.packages(...) :
#  specifying 'contriburl' or 'available' requires a single type, not type = "both"
#Calls: <Anonymous> ... tryCatchList -> tryCatchOne -> <Anonymous> -> .inet_error
#In addition: Warning message:
#In miniCRAN::pkgDep(unique(pkgLists[[x]]), repos = rRepos[[x]],  :
#  Package not recognized: rtracklayer, Biostrings, SummarizedExperiment, GenomicRanges, GenomicFeatures, GenomeInfoDb
#Execution halted
