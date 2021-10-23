#---------------------------------------------------------------------------
# initialize root files for an MDI installation
# the source for these files is mdi-manager/inst
#---------------------------------------------------------------------------
rPackageName <- 'mdi'

#---------------------------------------------------------------------------
# copy a file for the user to manually configure their MDI instance
# never overwrite an existing config file
#---------------------------------------------------------------------------
copyRootFile <- function(dirs, fileName){
    message('checking for file:', fileName)
    filePath <- file.path(dirs$root, fileName)
    fileTemplate <- system.file(fileName, package = rPackageName)
    file.copy(fileTemplate, filePath, overwrite = FALSE, recursive = FALSE)
    filePath
}

#---------------------------------------------------------------------------
# copy and modify mdi launcher utilities for command line and Windows
#---------------------------------------------------------------------------
updateRootFile <- function(dirs, fileName, replace = list()){
    message('updating file:', fileName)
    filePath <- file.path(dirs$root, fileName)
    fileTemplate <- system.file(fileName, package = rPackageName)
    contents <- readChar(fileTemplate, file.info(fileTemplate)$size)
    for(name in names(replace)){
        target <- paste0('_', name, '_')
        value <- replace[[name]]
        contents <- gsub(target, value, contents)
    }
    cat(contents, file = filePath, append = FALSE)
    filePath
}
