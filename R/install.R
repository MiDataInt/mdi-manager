#---------------------------------------------------------------------------
#' Install Michigan Data Interface (MDI) dependencies
#'
#' Install all dependencies of the Michigan Data Interface (MDI). 
#' This will include Bioconductor's BiocManager and its child packages.
#'
#' All default settings are consistent with an end user running the 
#' MDI in local mode on their desktop or laptop computer.
#'
#' \code{rootDir} must already exist, it will not be created. 
#' 
#' If \code{rootDir} ends with '/mdi' it will be used as is
#' without prompting. Otherwise, a subdirectory of that name will be 
#' created in \code{rootDir} after prompting for confirmation.
#'
#' If they do not already exist, \code{mdi::install()} will create a series of
#' subdirectories in \code{rootDir} without prompting, as follows:
#' \itemize{
#'   \item data = project-specific input and output files
#'   \item environments = conda environments used by data analysis pipelines
#'   \item frameworks = git repositories with common code for all pipelines and apps
#'   \item library = version-controlled library of R packages private to the MDI
#'   \item resources = version-controlled ~static files such as reference data sets
#'   \item sessions = temporary files associated with user web sessions
#'   \item suites = git repositories with code that defines specific pipelines and apps
#' }
#'
#' @param rootDir character. Path to the directory where the MDI
#' will be/has been installed. Defaults to your home directory.
#'
#' @param cranRepo character. The base URL of the R repository to use, e.g., the
#' URL of a CRAN mirror. Defaults to the University of Michigan CRAN mirror.
#'
#' @param packages character vector. If not NULL (the default), only install
#' these specific R packages (useful for developers to quickly update selected
#' packages). The apps and pipelines repositories will not be cloned or pulled.
#'
#' @param force logical.  When FALSE (the default), \code{mdi::install()}
#' does not attempt to update R packages that have previously been installed,
#' regardless of version. When TRUE, all packages are installed without further
#' prompting.
#'
#' @param gitUser character. Developers should use \code{gitUser} to provide 
#' the username of the GitHub account that holds their forks of any
#' frameworks or suites repositories. Code editing is done in these forks,
#' which will be cloned locally into frameworks/developer-forks and/or 
#' suites/developer-forks and used by \code{mdi::develop()} instead of the 
#' upstream repos, when available.
#'
#' @param token character. The GitHub Personal Access Token (PAT) that grants
#' permissions for accessing forked repositories in the \code{gitUser} account,
#' and/or any tool suites that have restricted access. You can also preset the 
#' token into environment variable \code{GITHUB_PAT} using
#' \code{Sys.setenv(GITHUB_PAT = "your_token")}.
#'
#' @param clone logical. If TRUE (the default), the apps and pipelines code 
#' repositories will be cloned anew from GitHub if they do not already exist, 
#' or they will be pulled from the server to update a repository if they have been 
#' cloned previously. Developers might want to set this option to FALSE.
#'
#' @param ondemand logical. If TRUE, the installer will not install _any_ R
#' packages, as they will be used from the managed host installation. Default
#' is FALSE.
#'
#' @return same as BiocManager::install
#'
#' @export
#---------------------------------------------------------------------------
install <- function(rootDir = '~',
                    cranRepo = 'https://repo.miserver.it.umich.edu/cran/',                    
                    packages = NULL,
                    force = FALSE,
                    gitUser = NULL,
                    token = NULL,                    
                    clone = TRUE,


                    checkout = NULL,


                    ondemand = FALSE){
    
    # parse needed versions and file paths
    versions <- getRBioconductorVersions()
    dirs <- parseDirectories(rootDir, versions, message = TRUE)

    # if caller requests an override, just install those specific packages and stop
    if(!is.null(packages)){
        return( installPackages(versions, dirs, unique(unname(unlist(packages))), force, ondemand) )
    }

    # initialize MDI root files
    copyRootFile(dirs, 'mdi') 
    if(.Platform$OS.type != "unix") copyRootFile(dirs, 'mdi.bat')     
    configFilePath <- copyRootFile(dirs, 'config.yml') 

    # establish a list of all framework and suite repositories for this installation
    repos <- parseGitRepos(dirs, configFilePath, gitUser)

    # for most users, download (clone or pull) the most current version of the git repositories
    setPersonalAccessToken(token)
    if(clone) do.call(downloadGitRepo, repos)  
    if(!clone) for(dir in repos[repos$fork == Forks$definitive, 'dir']){
        if(!dir.exists(dir)) stop(paste('missing repository:', dir))
        isGitRepo(dir, require = TRUE)
    }

    # get the latest tagged versions of all repos
    repos$exists <- repoExists(repos$dir)
    repos$version <- do.call(getLatestVersions, repos)

    # checkout the appropriate repository versions to continue with the installation
    #   definitive repositories use the most recent tagged version
    #   developer-forks stay where the developer had them (tip of 'main' if a new installation)
    mapply(function(dir, fork, version){
        if(!is.null(dir) && !is.na(dir) && fork == Forks$definitive){
            branch <- paste0('v', version)
            checkoutGitBranch(dir, branch) # git checkout <tag> is fine but results in a detached head
        }        
    }, repos$dir, repos$fork, repos$version)

    # initialize the Stage 1 pipelines management utility


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
    versionsFile <- file.path(dirs$versionLibrary, 'versions.rds')
    saveRDS(list(versions = versions, repos = repos, packages = packages), versionsFile)

    # install or update all required apps R packages
    installPackages(versions, dirs, packages, force, ondemand)
}

#---------------------------------------------------------------------------
# use BiocManager to install all apps R packages (whether CRAN or Bioconductor)
#---------------------------------------------------------------------------
installPackages <- function(versions, dirs, packages, force, ondemand){
    if(ondemand) return(NULL)
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
