#---------------------------------------------------------------------------
# collect the complete list of packages used by the framework and all apps
#---------------------------------------------------------------------------
getAppsPackages <- function(repos, rRepos) {
    message('collecting R package dependencies of available MDI apps')
    pattern <- "(packages\\.yml|config\\.yml|module\\.yml)"
    unique(unname(unlist(lapply(repos, function(repo){
        if(repo$stage != Stages$apps) return(NULL)
        files <- list.files(path = repo$dir, pattern = pattern, full.names = TRUE, recursive = TRUE)
        lapply(files, function(file){
            app <- yaml::read_yaml(file) 
            if(is.null(app$packages)) return(NULL) 
            if(!is.null(app$packages)){
                for(x in names(pkgLists)) if(!is.null(app$packages[[x]])){
                    pkgLists[[x]] <- c(pkgLists[[x]], app$packages[[x]])
                }
            }               
        })
        for(file in files){
            app <- yaml::read_yaml(file)        

        }

    # get the R packages required by the framework
    frameworkPackages <- yaml::read_yaml( file.path(sharedDir, 'global', 'packages', 'packages.yml') )
    pkgLists <- list(
        R = unname(unlist(frameworkPackages$R)),
        Bioconductor = unname(unlist(frameworkPackages$Bioconductor))
    )

    }))))
    




    

    
    # get the R packages required by all specific apps, modules and analysis types
    appDependsFiles <- c(
        list.files(path = sharedDir, pattern = 'config.yml', full.names = TRUE, recursive = TRUE),
        list.files(path = sharedDir, pattern = 'module.yml', full.names = TRUE, recursive = TRUE),
        list.files(path = appsDir,   pattern = 'config.yml', full.names = TRUE, recursive = TRUE),
        list.files(path = appsDir,   pattern = 'module.yml', full.names = TRUE, recursive = TRUE)
    )
    for(appDependsFile in appDependsFiles){
        app <- yaml::read_yaml(appDependsFile)        
        if(!is.null(app$packages)){
            for(x in names(pkgLists)) if(!is.null(app$packages[[x]])){
                pkgLists[[x]] <- c(pkgLists[[x]], app$packages[[x]])
            }
        }
    }

    # expand the package list to required dependencies
    message('recursively expanding package dependencies')
    suppressWarnings( for(x in names(pkgLists)) {
        pkgLists[[x]] <- miniCRAN::pkgDep(
            unique(pkgLists[[x]]), # the packages called by magc-portal framework and apps (not nested yet)
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
