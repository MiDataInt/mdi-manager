#---------------------------------------------------------------------------
# copy a file for the user to manually configure their MDI instance
# don't overwrite an existing config.yml file
#---------------------------------------------------------------------------
copyConfigFile <- function(dirs){
    message('checking for a config.yml file')
    fileName <- 'config.yml'
    filePath <- file.path(dirs$root, fileName)
    fileTemplate <- system.file(fileName, package = 'mdi')
    file.copy(fileTemplate, filePath, overwrite = FALSE, recursive = FALSE)
    filePath
}
