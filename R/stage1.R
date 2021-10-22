#---------------------------------------------------------------------------
# initialize the Stage 1 job manager and put the mdi rootDir into the user's PATH
#---------------------------------------------------------------------------
initializeJobManager <- function(mdiPath) {
    message('initializing the Stage 1 pipelines job manager and mdi command line function')
    tryCatch(
        {
            system2(
                'bash', 
                args = c(mdiPath, 'initialize'),
                stdout = FALSE, 
                stderr = FALSE
            )
        }, 
        warning = function(w) NULL,
        error = function(e) NULL
    )
}
