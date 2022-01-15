#---------------------------------------------------------------------------
# collect the R version in use
# RVersion is "major.minor", whereas RRelease is "major.minor.patch"
#---------------------------------------------------------------------------
getRBioconductorVersions <- function(isNode = FALSE){
    list(
        RVersion = getRVersion(),
        RRelease = getRRelease(),
        BioconductorRelease = if(isNode) Sys.getenv('BIOCONDUCTOR_RELEASE') else BiocManager::version()
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
# get the latest/all semantic version tags, i.e., release, of upstream, definitive repos
#---------------------------------------------------------------------------
semVerToSortableInteger <- Vectorize(function(semVer){ # expects vMajor.Minor.Patch
    x <- gsub('v', '', semVer) # Major.Minor.Patch (no 'v')
    x <- as.integer(strsplit(x, "\\.")[[1]])
    x[1] * 1e10 + x[2] * 1e5 + x[3] # thus, most recent versions have the highest integer value
})
getLatestVersion <- function(tags){ # return most recent version tag as vMajor.Minor.Patch
    if(length(tags) == 0) return(NA)
    isSemVer <- grepl('^v{0,1}\\d+\\.\\d+\\.\\d+$', tags, perl = TRUE)
    semVer <- tags[isSemVer]
    if(length(semVer) == 0) return(NA)
    semVerI <- semVerToSortableInteger(semVer)
    semVer[ which.max(semVerI) ]
}
getLatestVersions <- Vectorize(function(dir, fork, exists, ...) {
    if(fork == Forks$definitive && exists){
        tags <- git2r::tags(dir) # tag (name) = commit data list (value)
        getLatestVersion( names(tags) )
    } else {
        NA # we will never check out tags in forked repos
    }
})
getAllVersions <- function(dir, ...) {
    tags <- git2r::tags(dir) # tag (name) = commit data list (value)
    if(length(tags) == 0) return(character())
    tags <- names(tags)
    isSemVer <- grepl('^v{0,1}\\d+\\.\\d+\\.\\d+$', tags, perl = TRUE)
    semVer <- tags[isSemVer]
    if(length(semVer) == 0) return(character())
    semVerI <- semVerToSortableInteger(semVer)
    rev( semVer[ rank(semVerI) ] ) # thus, latest release tag is always first in list
}
