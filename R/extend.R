#---------------------------------------------------------------------------
#' Extend a base Singularity container to add suites lacking container support
#'
#' This function is only intended to be called by a Singularity instance.
#' It is not for general use and should be ignored by most people.
#'
#' Packages not present in container are installed into an active, bind-mounted
#' MDI installation.  
#'
#' @export
#---------------------------------------------------------------------------
extend <- function(staticMdiDir){
    activeMdiDir <- '/srv/active/mdi' # this path is fixed by build-suite-common.def
    cranRepo <- 'https://repo.miserver.it.umich.edu/cran/'
    force <- FALSE

    # parse needed versions and file paths
    versions <- getRBioconductorVersions()
    staticDirs <- parseDirectories(staticMdiDir, versions, create = FALSE, message = FALSE)
    activeDirs <- parseDirectories(activeMdiDir, versions, create = FALSE, message = FALSE)
    dir.create(activeDirs$containersVersionLibrary, showWarnings = FALSE)
    activeDirs$versionLibrary <- activeDirs$containersVersionLibrary

    # collect the list of all framework and suite repositories for this installation
    activeRepos <- parseGitRepos(activeDirs, file.path(activeDirs$config, 'suites.yml'))

    # install packages not present in container's static library
    collectAndInstallPackages(cranRepo, force, versions, activeDirs, activeRepos,
                              releaseLocks = FALSE, staticLib = staticDirs$versionLibrary)
}
