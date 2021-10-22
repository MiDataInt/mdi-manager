#---------------------------------------------------------------------------
# collect the complete list of packages used by the framework and all apps
#---------------------------------------------------------------------------
getAppsPackages <- function(repos, rRepos) {

    # initialize
    pkgLists <- list(
        R = character(),
        Bioconductor = character()
    )
    addYmlPackages <- function(yml){
        if(is.null(yml)) return()
        for(x in names(pkgLists)) if(!is.null(yml[[x]])){
            pkgLists[[x]] <<- c(pkgLists[[x]], unname(unlist(yml[[x]])))
        }     
    }

    # get the R packages required by the apps framework   
    message('collecting R package dependencies of MDI framework')
    targetRepos <- repos[repos$type  == Types$framework & 
                         repos$stage == Stages$apps & 
                         repos$exists, ] # one definitive and maybe a forked repo
    for(repo in targetRepos){
        file <- file.path(repo$dir, 'shiny', 'shared', 'global', 'packages', 'packages.yml')
        yml <- yaml::read_yaml(file)
        addYmlPackages(yml)    
    }

    # add R packages requested by individual apps
    message('collecting R package dependencies of MDI apps')
    targetRepos <- repos[repos$stage == Stages$apps & 
                         repos$exists, ] # will query all apps defined in framework and suites 
    pattern <- "(config\\.yml|module\\.yml)"
    for(repo in targetRepos){
        files <- list.files(path = repo$dir, pattern = pattern, full.names = TRUE, recursive = TRUE)
        for(file in files){
            yml <- yaml::read_yaml(file)
            addYmlPackages(yml$packages)              
        }
    }

    # expand the package list to required dependencies
    message('recursively expanding package dependencies')
    suppressWarnings( for(x in names(pkgLists)) {
        pkgLists[[x]] <- miniCRAN::pkgDep(
            unique(pkgLists[[x]]), # the packages named by the MDI framework and apps
            repos = rRepos[[x]],
            type = "source",
            depends = TRUE,
            suggests = FALSE,
            enhances = FALSE,
            includeBasePkgs = FALSE, # these always come from a server's R installation
            quiet = TRUE
        )
    } )
    
    # return our results
    pkgLists
}
