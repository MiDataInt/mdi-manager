#---------------------------------------------------------------------------
# initialize the Stage 1 job manager and put mdiDir into the user's PATH
#---------------------------------------------------------------------------
initializeJobManager <- function(mdiPath, developer = FALSE) {
    message('initializing the Stage 1 pipelines job manager')
    args <- if(developer) c(mdiPath, 'develop', 'initialize')
                     else c(mdiPath,            'initialize')
    tryCatch(
        {
            system2(
                'bash', 
                args = args,
                stdout = FALSE, 
                stderr = FALSE
            )
        }, 
        warning = function(w) NULL,
        error = function(e) NULL
    )
}
