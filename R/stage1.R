#---------------------------------------------------------------------------
# initialize the Stage 1 job manager
#---------------------------------------------------------------------------
initializeJobManager <- function(mdiPath, developer = FALSE) {
    if(!developer) message('initializing the Stage 1 pipelines job manager')
    args <- if(developer) c(mdiPath, '--develop', 'initialize')
                     else c(mdiPath,            'initialize')

    # NOTE: this is NOT necessarily sufficient to load all program targets into mdi
    # must run 'mdi initialize' from a shell on some systems
    tryCatch(
        { system2('bash', args = args) }, 
        warning = function(w) print(w),
        error = function(e) print(e)
    )
}
