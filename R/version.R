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
# get the latest semantic version tags, i.e., release, of the main branch of upstream, definitive repos
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
    if(fork == Forks$definitive){
        tags <- git2r::tags(dir) # tag (name) = commit data list (value)
        getLatestVersion( names(tags) )
    } else {
        NA # we will never check out tags in forked repos
    }
})
