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
    targetRepoDirs <- filterRepoDirs(
        repos[repos$exists, ], # one definitive and maybe a forked apps framework repo
        type = Types$framework, 
        stage = Stages$apps
    )
    for(dir in targetRepoDirs){
        file <- file.path(dir, 'shiny', 'shared', 'global', 'packages', 'packages.yml')
        yml <- yaml::read_yaml(file)
        addYmlPackages(yml)    
    }

    # add R packages requested by individual apps
    message('collecting R package dependencies of MDI apps') 
    targetRepoDirs <- filterRepoDirs(
        repos[repos$exists, ], # will query all apps defined in framework and suites
        stage = Stages$apps
    )   
    pattern <- "(config\\.yml|module\\.yml)"
    for(dir in targetRepoDirs){
        files <- list.files(path = dir, pattern = pattern, full.names = TRUE, recursive = TRUE)
        for(file in files){
            yml <- yaml::read_yaml(file)
            addYmlPackages(yml$packages)              
        }
    }

    # expand the package list to required dependencies
    message('recursively expanding package dependencies ...')
    suppressWarnings( for(x in names(pkgLists)) {
        pkgLists[[x]] <- if(length(pkgLists[[x]]) > 0) miniCRAN::pkgDep(
            unique(pkgLists[[x]]), # the packages named by the MDI framework and apps
            repos = rRepos[[x]],
            type = "source",
            depends = TRUE,
            suggests = FALSE,
            enhances = FALSE,
            includeBasePkgs = FALSE, # these always come from a server's R installation
            quiet = TRUE
        ) else NULL
    } )
    
    # return our results
    pkgLists
}
