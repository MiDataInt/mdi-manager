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
#' which will be cloned locally into frameworks/developer and/or suites/developer
#' and used by \code{mdi::develop()} instead of the upstream repos, when available.
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
#' @param checkout character. If NULL (the default), \code{mdi::install()} will 
#' set all repositories to the latest version compatible with your R version.
#' Developers might want to specify a code branch.
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
    
    # parse needed versions, file paths, git repos
    versions <- getRBioconductorVersions()
    dirs <- parseDirectories(rootDir, versions, message = TRUE)
    configFilePath <- copyConfigFile(dirs) 
    repos <- parseGitRepos(dirs, configFilePath, gitUser)

    # if caller requests an override, just install those specific packages and stop
    if(!is.null(packages)){
        return( installPackages(versions, dirs, unique(unname(unlist(packages))), force, ondemand) )
    }

    # for most users, download (clone or pull) the most current version of the git repositories
    setPersonalAccessToken(token)
    if(clone) do.call(downloadGitRepo, repos)
    if(!clone) for(dir in repos[repos$fork == forks$definitive, 'dir']){
        if(!dir.exists(dir)) stop(paste('missing repository:', dir))
    }

    # get latest tagged versions of all repos
    repos$version <- do.call(getLatestVersions, repos)


    # digest of repos$version, or ordered repos, should provide a unique key to the R library
    # but only need to consider apps repos

    # version <- version(quiet = TRUE, message = TRUE)
    

    # # parse needed code versions and file paths
    # version <- version(quiet = TRUE, message = TRUE)
    # dirs <- parseDirectories(rootDir, version, message = TRUE)
    # if(is.null(version)){ # in case remote recovery of versions failed
    #     version <- version(quiet = TRUE, message = TRUE, dirs = dirs)
    #     if(is.null(version)) stop('unable to obtain resolve MDI version')
    #     dirs <- parseDirectories(rootDir, version, message = TRUE)
    # }


    backupCodeVersions(dirs)
    



    
    # check for appropriate git installations (i.e. clone success)
    # set <...>-apps head to the appropriate version
    #   git checkout <tag> is fine but results in a detached head
    for(repoKey in repoKeys){
        dir <- dirs[[repoKey]]
        isGitRepo(dir, require = TRUE)
        # TODO: implement versioning of <...>-pipelines
        if(repoKey == appsRepoKey) {
            if(is.null(checkout)) checkout <- paste0('v', version$MDIVersion) 
            checkoutGitBranch(dir, checkout)
        }
    } 

    # set the public R package repositories
    message('collecting R repository information')
    rRepos <- list(R = cranRepo)
    rRepos$Bioconductor <- unname(BiocManager::repositories()['BioCsoft'])    

   
    # collect the complete list of packages used by the framework and all apps
    pkgLists <- getAppsPackages(dirs, rRepos)   
    

    # record the versions associated with the current set of library packages
    # used by run to determine if latest version has pending package installations
    versionsFile <- file.path(dirs$versionLibrary, 'versions.rds')
    saveRDS(list(versions = versions, repos = repos), versionsFile)

    # install or update all required packages
    installPackages(versions, dirs, unique(unname(unlist(pkgLists))), force, ondemand)
}

#---------------------------------------------------------------------------
# use BiocManager to install all packages (whether CRAN or Bioconductor)
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
        message('installing/updating packages in private library')
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

#---------------------------------------------------------------------------
# get the currently installed version, i.e. set of R packages in the matching library
#---------------------------------------------------------------------------
getInstalledVersion <- function(dirs){
    versionFile <- file.path(dirs$versionLibrary, 'version.yml')
    if(!file.exists(versionFile)) stop(paste('missing version file:', versionFile))
    version <- yaml::read_yaml(versionFile)
    version$MDIVersion
}
