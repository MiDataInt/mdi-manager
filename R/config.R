#---------------------------------------------------------------------------
# copy a file for the user to manually configure their MDI instance
# don't overwrite an existing config or execution file
# the source for these files is mdi-manager/inst
#---------------------------------------------------------------------------
copyRootFile <- function(dirs, fileName){
    message('checking for file:', fileName)
    filePath <- file.path(dirs$root, fileName)
    fileTemplate <- system.file(fileName, package = 'mdi')
    file.copy(fileTemplate, filePath, overwrite = FALSE, recursive = FALSE)
    filePath
}
