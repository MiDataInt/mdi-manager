#---------------------------------------------------------------------------
# initialize the Stage 1 job manager
#---------------------------------------------------------------------------
initializeJobManager <- function(mdiPath, developer = FALSE) {
    if(!developer) message('initializing the Stage 1 pipelines job manager')
    args <- if(developer) c(mdiPath, 'develop', 'initialize')
                     else c(mdiPath,            'initialize')
    tryCatch(
        { system2('bash', args = args) }, 
        warning = function(w) print(w),
        error = function(e) print(e)
    )
}

#---------------------------------------------------------------------------
# put mdiDir into the user's PATH
#---------------------------------------------------------------------------
addMdiDirToPATH <- function(mdiDir, addToPATH = FALSE){
    if(!addToPATH) return()
    message("adding mdi executable to PATH")

    # load current .bashrc
    bashRcFile <- file.path(Sys.getenv('HOME'), ".bashrc")
    bashRcBackup <- paste0(bashRcFile, ".mdi-backup")
    bashRcContents <- if(file.exists(bashRcFile)) {
        if(!file.exists(bashRcBackup)) file.copy(bashRcFile, bashRcBackup) # make a backup
        readChar(bashRcFile, file.info(bashRcFile)$size) 
    } else ""
    bashRcContents <- gsub("\\r", "", bashRcContents)

    # assemble mdi PATH entry
    head <- "# >>> mdi initialize >>>"
    notice <- "# !! Contents within this block are managed by 'mdi initialize' !!"
    PATH <- paste0('export PATH="', mdiDir, ':$PATH"')
    tail <- "# <<< mdi initialize <<<"
    payload <- paste(head, notice, PATH, tail, "\n", sep = "\n")
    filter <- paste0(head, ".+", tail)

    # check if is payload already present, i.e., nothing to do
    if(grepl(payload, bashRcContents)) return()

    # append MDI PATH entry, or replace (i.e., overwrite) prior entry
    if(grepl(filter, bashRcContents)){
        bashRcContents <- gsub(filter, payload, bashRcContents)
    } else {
        bashRcContents <- paste(bashRcContents, payload, sep = "\n\n")
    }

    # write final modified .bashrc file
    bashRcContents <- gsub("\\n{3,}", "\n\n", bashRcContents)
    cat(bashRcContents, file = bashRcFile)
}
