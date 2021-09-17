#---------------------------------------------------------------------------
# collect the R version in use
# RVersion is "major.minor", whereas RRelease is "major.minor.patch"
#---------------------------------------------------------------------------
getRBioconductorVersions <- function(){
    list(
        RVersion = getRVersion(),
        RRelease = getRRelease(),
        BioconductorRelease = BiocManager::version()
    )
}
getRVersion <- function(){
    Rmajor <- R.version$major
    Rminor <- strsplit(R.version$minor, "\\.")[[1]][1]
    paste(Rmajor, Rminor, sep = ".")    
}
getRRelease <- function(){
    paste(R.version$major, R.version$minor, sep = ".")
}

#---------------------------------------------------------------------------
# get the latest semantic version tags, i.e., release, of main branch of upstream, definitive repos
#---------------------------------------------------------------------------
semVerToIntegers <- function(semVer){ # major.minor.patch
    x <- as.integer(strsplit(semVer, "\\.")[[1]])
    names(x) <- c('major', 'minor', 'patch')
    as.list(x) # i.e. integer(major, minor, patch)
}
semVerToSortableInteger <- Vectorize(function(semVer){ # major.minor.patch
    x <- as.list(as.integer(strsplit(semVer, "\\.")[[1]]))
    names(x) <- c('major', 'minor', 'patch')    
    x$major * 1e8 + x$minor * 1e4 + x$patch # thus, most recent versions have the highest number
})
filterSemVerTags <- function(tags){ # discard all tags except [v]major.minor.patch
    isSemVer <- grepl('^v{0,1}\\d+\\.\\d+\\.\\d+$', tags, perl = TRUE)
    tags <- tags[isSemVer]
    gsub('v', '', tags) # return major.minor.patch (no 'v')
}
getLatestVersion <- function(tags){ # return most recent version tag as major.minor.patch
    if(length(tags) == 0) return(NA)
    semVer <- filterSemVerTags(tags)
    if(length(semVer) == 0) return(NA)
    semVer[ which.max( semVerToSortableInteger(semVer) ) ]
}
getLatestVersions <- Vectorize(function(dir, fork, ...) {
    if(fork == forks$definitive){
        tags <- git2r::tags(dir) # tag (name) = commit data list (value)
        getLatestVersion( names(tags) )
    } else {
        NA # we will never check out tags in forked repos
    }
})




# ---------------------------------------------------------------------------
# ' Michigan Data Interface (MDI) version information
# '
# ' Report the versions of R, Bioconductor and the Michigan Data Interface (MDI)
# '
# ' @param quiet logical. If FALSE (the default) the function will
# ' print a report on the current version statuses.
# '
# ' @return A list with named values, always including at least
# ' MDIVersion and BioconductorRelease.
# '
# ' @export
#---------------------------------------------------------------------------
# version <- function(quiet = FALSE, message=FALSE, dirs=NULL){
#     if(message) message('getting version information')
    
#     # get the version
#     versions <- loadMDIVersions(dirs)
    
    
    
#     if(is.null(versions)) return(NULL)
#     RVersion <- getRVersion()
#     version <- getLatestCompatibleVersion(RVersion, versions)
    
#     # warn for rare users with old R (or new R we haven't released for yet)
#     if(is.null(version)){
#         warning(paste(
#             "No compatible MDI versions found.",
#             "Your R version is most likely too old.",
#             "Please update your R installation to at least version:",
#             versions$RRelease[nrow(versions)],
#             ". Alternatively, we might not have released the MDI for the newest R version yet."
#         ))
#         return(NULL)
#     }    

#     # report interactively
#     if(!quiet) {
#         RRelease <- getRRelease()    
#         message()
#         message(paste(RRelease, "R version in use", sep="\t"))
#         message(paste(version$MDIVersion, "Latest compatible MDI version", sep="\t"))
#         message(paste(version$BioconductorRelease, "Corresponding Bioconductor version", sep="\t"))
#         if(!is.null(version$MDIVersion)){
#             latest <- versions$MDIVersion[1]
#             if(version$MDIVersion == latest){
#                 message("You are using/will install the most recent MDI version.")
#             } else {
#                 message("A newer version of the MDI is available, as follows.")
#                 message("Update your R version to make use of the more recent version.")
#                 print(versions[1,])
#             }
#         }
#         message()
#     }
    
#     # return our result
#     as.list(version)
# }

# #---------------------------------------------------------------------------
# # collect the R version in use (it dictates everything else)
# # RVersion is "major.minor", whereas RRelease is "major.minor.patch"
# #---------------------------------------------------------------------------
# getRVersion <- function(){
#     Rmajor <- R.version$major
#     Rminor <- strsplit(R.version$minor, "\\.")[[1]][1]
#     paste(Rmajor, Rminor, sep=".")    
# }
# getRRelease <- function(){
#     paste(R.version$major, R.version$minor, sep=".")
# }

#---------------------------------------------------------------------------
# load available versions information
#---------------------------------------------------------------------------
localVersionsFile <- function(dirs) file.path(dirs$library, 'versions.yml')
backupCodeVersions <- function(dirs){
    if(is.null(tmpVersionsFile) || !file.exists(tmpVersionsFile)) return()
    file.copy(tmpVersionsFile, localVersionsFile(dirs), overwrite = TRUE)
    unlink(tmpVersionsFile)
}
readVersionsFile <- function(versionsFile){
    if(!file.exists(versionsFile)) return(NULL)
    versionsYml <- yaml::read_yaml(versionsFile)
    cols <- c('MDIVersion', 'RRelease', 'RVersion', 'BioconductorRelease', 'ReleaseDate', 'Type')
    df <- lapply(cols, function(col){
        sapply(versionsYml, function(version) {
            if(is.null(version[[col]])) NA else version[[col]]
        })
    })
    names(df) <- cols
    data.frame(df)
}
loadMDIVersions <- function(dirs){
    if(!is.null(dirs)) return( readVersionsFile(localVersionsFile(dirs)) )
    tryCatch(
        {
            url <- 'https://raw.githubusercontent.com/MiDataInt/mdi-versions/main/versions.yml'
            assign("tmpVersionsFile", tempfile(), envir = .GlobalEnv)
            download.file(url, tmpVersionsFile)
            readVersionsFile(tmpVersionsFile)   
        },
        warning = function(w) {
            print(w)
            NULL
        }, 
        error = function(e) {
            print(e)
            NULL
        }
    )
}

#---------------------------------------------------------------------------
# apply comparison operators to string versions to match R versions to MDI versions
#---------------------------------------------------------------------------
getLatestCompatibleVersion <- function(RVersion, versions){
    versionReleases <- versions[versions$RVersion == RVersion, ]
    # all information on the latest compatible MDI version for the user's R version
    if(nrow(versionReleases) == 0) NULL else versionReleases[1, ] 
}
