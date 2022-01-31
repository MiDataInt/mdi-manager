#---------------------------------------------------------------------------
#' Extend a base Singularity container to add suites lacking container support
#'
#' This function is only intended to be called by a Singularity instance.
#' It is not for general use and should be ignored by most people.
#'
#' Packages not present in the container are installed by the container into 
#' an active bind-mounted MDI installation.  
#'
#' @export
#---------------------------------------------------------------------------
extend <- function(staticMdiDir){
    message("extending MDI installation using 'mdi-singularity-base' container")
    activeMdiDir <- '/srv/active/mdi' # this path is fixed by build-suite-common.def
    cranRepo <- 'https://repo.miserver.it.umich.edu/cran/'
    force <- FALSE

    # parse needed versions and file paths
    versions <- getRBioconductorVersions()
    staticDirs <- parseDirectories(staticMdiDir, versions, create = FALSE, message = FALSE)
    activeDirs <- parseDirectories(activeMdiDir, versions, create = TRUE,  message = FALSE)

    # override the container-extension R library to live under the containers folder
    # these files are compiled in the container, not on the host OS
    activeDirs$versionLibrary <- activeDirs$containersVersionLibrary

    # collect the list of all framework and suite repositories for this installation
    # remember, the base container itself has an empty installation
    activeRepos <- parseGitRepos(activeDirs, file.path(activeDirs$config, 'suites.yml'))
    activeRepos$exists <- repoExists(activeRepos$dir)
    activeRepos$latest <- do.call(getLatestVersions, activeRepos)

    # install packages not found in the container's static library
    # i.e., those packages already present to support the empty apps framework
    collectAndInstallPackages(cranRepo, force, versions, activeDirs, activeRepos,
                              releaseLocks = FALSE, staticLib = staticDirs$versionLibrary)
}
