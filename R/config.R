#---------------------------------------------------------------------------
# initialize root files for an MDI installation
# the source for these files is mdi-manager/inst
#---------------------------------------------------------------------------
rPackageName <- 'mdi'

#---------------------------------------------------------------------------
# copy a file for the user to manually configure their MDI instance
# never overwrite an existing config file
#---------------------------------------------------------------------------
copyConfigFile <- function(dirs, fileName){
    message(paste('checking for file:', fileName))
    filePath <- file.path(dirs$config, fileName)
    fileTemplate <- system.file('config', fileName, package = rPackageName)
    file.copy(fileTemplate, filePath, overwrite = FALSE, recursive = FALSE)
    filePath
}
copyRemoteFiles <- function(dirs){
    source <- system.file('remote', package = rPackageName)
    file.copy(source, dirs$mdi, recursive = TRUE)
}

#---------------------------------------------------------------------------
# copy and modify mdi launcher utilities for command line and Windows
#---------------------------------------------------------------------------
updateRootFile <- function(dirs, fileName, replace = list(), executable = FALSE){
    message(paste('updating file:', fileName))
    filePath <- file.path(dirs$mdi, fileName)
    fileTemplate <- system.file(fileName, package = rPackageName)
    contents <- readChar(fileTemplate, file.info(fileTemplate)$size)
    contents <- gsub("\\r", "", contents)
    for(name in names(replace)){
        target <- paste0('_', name, '_')
        value <- replace[[name]]
        contents <- gsub(target, value, contents)
    }
    cat(contents, file = filePath, append = FALSE)
    Sys.chmod(filePath, mode = if(executable) "0770" else "0660")
    filePath
}
