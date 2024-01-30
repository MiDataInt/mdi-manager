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
        shinyDir <- file.path(dir, 'shiny')
        if(dir.exists(shinyDir)){ # could be false for a pipelines-only suite
            files <- list.files(path = shinyDir, pattern = pattern, full.names = TRUE, recursive = TRUE)
            for(file in files){
                yml <- yaml::read_yaml(file)
                addYmlPackages(yml$packages)              
            }
        }
    }

    # expand the package list to required dependencies
    message('recursively expanding package dependencies ...')
    installed <- installed.packages()
    base <- installed[which(installed[, "Priority"] == "base"), "Package"]
    # suppressWarnings( for(x in names(pkgLists)) {
    suppressWarnings( for(x in 'R') {
        pkgLists[[x]] <- if(length(pkgLists[[x]]) > 0) {
            getPackageDependencies(unique(pkgLists[[x]]), rRepos[[x]], skip = base)
        } else NULL
    } )
    
    # having problems expanding Bioconductor packages above, BiocManager::install should do this downstream
    pkgLists$Bioconductor <- if(length(pkgLists$Bioconductor) > 0) unique(pkgLists$Bioconductor) else NULL
    
    # return our results
    pkgLists
}
getPackageDependencies <- function(packages, repo, skip = character()){
    dependencies <- tools::package_dependencies(
        packages = packages, 
        db = available.packages(type = "source", filters = list(), repos = repo), 
        which = c("Depends", "Imports", "LinkingTo"), # not Suggests or Enhances
        recursive = TRUE,
        verbose = FALSE
    )
    packages <- sort(unique(c(packages, unlist(dependencies))))
    packages[!(packages %in% skip)]
}
