#---------------------------------------------------------------------------
# standardized names for git repos, users, remotes and branches
#---------------------------------------------------------------------------
gitHubUrl <- 'https://github.com'
#---------------------------------------------------------------------------
# there are three levels of repo forks and clones
#   remotes/upstream = the definitive, managed repo, on GitHub
#   remotes/origin = a user's fork of the definitive repo, on GitHub
#   local = a clone of the user's fork of remotes/origin, on their computer
#---------------------------------------------------------------------------
mdiGitUser <- 'MiDataInt' # the name of the MDI GitHub Organization
Remotes  <- list(upstream = "upstream", origin = "origin")
Forks    <- list(definitive = "definitive", developer = "developer-forks")
Branches <- list(main = "main")
Types    <- list(framework = 'frameworks', suite = 'suites')
Stages   <- list(pipelines = 'pipelines', apps = 'apps', tools = 'tools') # tool suites may contain pipelines and/or apps # nolint
#---------------------------------------------------------------------------
# there are two different framework repositories, corresponding to the two main stages of execution
#   mdi-pipelines-framework = code that runs mostly non-interactively, stage 1, resource-intensive processing
#   mdi-apps-framework = code that runs the web server and thus interactively, stage 2, data exploration
pipelinesFrameworkRepo <- 'mdi-pipelines-framework'
appsFrameworkRepo      <- 'mdi-apps-framework'
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# set a user's GitHub PAT into the proper environment variable
#---------------------------------------------------------------------------
setGitCredentials <- function(dirs){ 
    gitCredentialsFile1 <- file.path(dirs$mdi, "gitCredentials.R")
    gitCredentialsFile2 <- file.path("~", "gitCredentials.R")
         if(file.exists(gitCredentialsFile1)) source(gitCredentialsFile1)
    else if(file.exists(gitCredentialsFile2)) source(gitCredentialsFile2)
    else return()
    for(name in names(gitCredentials)){ # remove unspecified items to not overwrite current environment
        x <- gitCredentials[[name]]
        if(is.na(x) || x == "") gitCredentials[[name]] <- NULL
    }
        
        print(gitCredentials)
    
    do.call(Sys.setenv, gitCredentials) # set specific values into environment
}

#---------------------------------------------------------------------------
# collect information on all git repos relevant to an MDI installation
#---------------------------------------------------------------------------
parseGitRepos <- function(dirs, suitesFilePath){
    message('collecting git repos from suites.yml')
    config <- yaml::read_yaml(suitesFilePath)

    # prepend the frameworks repos to the suites repos
    upstreamUrls <- c(
        sapply(c(pipelinesFrameworkRepo, appsFrameworkRepo), assembleGitUrl, mdiGitUser), 
        expandGitUrls(config$suites)
    )
    types <- c(
        rep(Types$framework, 2), 
        rep(Types$suite, length(upstreamUrls) - 2)
    )
    stages <- c(
        Stages$pipelines, 
        Stages$apps, 
        rep(Stages$tools, length(config$suites))
    )

    # assemble and return an ordered table of all repos known to this MDI instance
    assembleReposList(dirs, types, stages, upstreamUrls)
}
assembleGitUrl <- function(repoName, gitUser) {
    repo <- paste(repoName, 'git', sep = ".")
    paste(gitHubUrl, gitUser, repo, sep = "/")
}
expandGitUrls <- function(urls){ # turn GIT_USER/SUITE_NAME into https://github.com/GIT_USER/SUITE_NAME-mdi-pipelines.git # nolint
    if(is.null(urls) || length(urls) == 0) return(character())
    urls <- ifelse(startsWith(urls, gitHubUrl), urls, paste(gitHubUrl, urls, sep = "/"))
    urls <- ifelse(endsWith(urls, ".git"), urls, paste(urls, "git", sep = "."))
    urls
}
switchGitUser <- Vectorize(function(url, gitUser){
    if(is.null(gitUser) || gitUser == "") return(NA)
    parts <- strsplit(url, '/')[[1]]
    parts[length(parts) - 1] <- gitUser
    paste(parts, collapse = '/')
})
getRepoDir <- Vectorize(function(mdiDir, type, fork, url){
    if(is.null(url) || is.na(url)) return(NA)
    repo <- rev(strsplit(url, '/')[[1]])[1]
    repo <- strsplit(repo, '\\.')[[1]][1]
    file.path(mdiDir, type, fork, repo)
})
repoFilter <- function(repos, type, stage, fork){
    isType  <- if(is.null(type))  TRUE else repos$type  == type
    isStage <- if(is.null(stage)) TRUE else repos$stage == stage | repos$stage == Stages$tools
    isFork  <- if(is.null(fork))  TRUE else repos$fork  == fork
    !is.null(repos$dir) &
    !is.na(repos$dir) & 
    isType & 
    isStage & 
    isFork
}
filterRepoDirs <- function(repos, type = NULL, stage = NULL, fork = NULL, paste = FALSE){
    repoFilter <- repoFilter(repos, type, stage, fork)
    repos <- repos[repoFilter, ]
    if(!paste) return(repos$dir)
    paste(repos$dir, collapse = " ")
}
filterRepos <- function(repos, type = NULL, stage = NULL, fork = NULL){
    repoFilter <- repoFilter(repos, type, stage, fork)
    repos[repoFilter, ]
}
assembleReposList <- function(dirs, types, stages, upstreamUrls){
    x <- rbind(   
        data.frame( # repos with remote==upstream are the definitive public source code
            type    = types,
            stage   = stages,
            remote  = Remotes$upstream,
            fork    = Forks$definitive,
            url     = upstreamUrls,
            exists  = NA,
            latest  = NA,
            stringsAsFactors = FALSE
        ),
        data.frame( # repos with remote==origin are a developer's forks, if any
            type    = types,
            stage   = stages,
            remote  = Remotes$origin,
            fork    = Forks$developer,
            url     = switchGitUser(upstreamUrls, Sys.getenv('GIT_USER')), # NB: some forked repos might not exist
            exists  = NA,
            latest  = NA,
            stringsAsFactors = FALSE 
        )
    )
    x$dir <- getRepoDir(dirs$mdi, x$type, x$fork, x$url) # this is the user's target directory, not a host's
    x$name <- sapply(strsplit(x$dir, '/'), function(y) rev(y)[1])
    x
}
mergeGitRepoLists <- function(repos1, repos2){ # rbind repo lists, preserving the proper search order
    rbind(
        repos1[repos1$remote == Remotes$upstream, ],
        repos2[repos2$remote == Remotes$upstream, ],        
        repos1[repos1$remote == Remotes$origin, ],
        repos2[repos2$remote == Remotes$origin, ]
    )
}

#---------------------------------------------------------------------------
# clone or pull a code repository
#---------------------------------------------------------------------------
downloadGitRepo <- Vectorize(function(dir, url, fork, ...) { 
    if(is.null(url) || is.na(url)) return()

    # get up-to-date repo from the server
    #   definitive repos set to tip of 'main' prior to pulling
    #   don't change branches on developer-forks, attempt to pull on the current branch
    if(isGitRepo(dir)){
        if(!gitRepoMatches(dir, url)) stop(paste(dir, 'is not a clone of', url))
        message(paste('pulling', url))
        if(fork == Forks$definitive) checkoutGitBranch(dir, silent = TRUE)
        pullGit(dir)

    # or clone it on first encounter
    #   all repos set to tip of 'main' on first installation
    } else {
        message(paste('attempting to clone', url))
        if(cloneGit(dir, url)) { # will fails if developer has not forked a specific repo
            checkoutGitBranch(dir, silent = TRUE)
            initializeRepo(dir, url, fork)
        }
    }
})
pullGit <- function(dir){
    checkGitConfigUser(dir)
    tryCatch( { 
        git2r::pull(                                  
            repo = dir,
            credentials = git2r::cred_token()
        ) 
    }, error = function(e) {
        message(e$message)
        NULL
    }) 
}
cloneGit  <- function(dir, url){
    tryCatch( { 
        git2r::clone(
            url = url,
            local_path = dir,
            credentials = git2r::cred_token(),
            progress = TRUE
        )
        TRUE
    }, error = function(e) {
        if(grepl("404", e$message)) message("  repository does not exist")
        else message(e$message)
        FALSE
    })
}
initializeRepo <- function(dir, url, fork){
    # set the "upstream" remote to the definitive repository
    if(fork == Forks$developer){
        git2r::remote_add(dir, Remotes$upstream, switchGitUser(url, mdiGitUser)) 
        setGitConfigUser(dir)
    } else {
        # ensure that at least a null user is present in all git configs
        setGitConfigUser(dir, nullUser = TRUE)
    }
}

#---------------------------------------------------------------------------
# check for a valid repository
#---------------------------------------------------------------------------
isGitRepo <- function(dir, require = FALSE) {
    isGitRepo <- dir.exists(dir) && dir.exists(file.path(dir, '.git'))
    if(require && !isGitRepo) stop(paste(dir, 'is not a git repository'))
    isGitRepo
}    
gitRepoMatches <- function(dir, url){
    git2r::remote_url(dir, Remotes$origin) == url
}
repoExists <- Vectorize(function(dir){
    !is.na(dir) &&
    !is.null(dir) &&
    isGitRepo(dir)
})

#---------------------------------------------------------------------------
# checkout (i.e. change to) a specific branch
# do not check or set repo locks here, caller must manage locks as needed
#---------------------------------------------------------------------------
checkoutGitBranch <- function(dir, branch = 'main', create = FALSE, silent = FALSE) {
    if(!silent) message(paste('setting', dir, 'head to', branch))
    git2r::checkout(
        object = dir,
        branch = branch, # git2r calls it 'branch', but can be anything that can be checked out
        force = FALSE,
        create = create
    )
    x <- list() # record the current branch of all repos in environment for rapid checking later
    x[[dir]] <- branch       
    do.call(Sys.setenv, x)
}

#---------------------------------------------------------------------------
# check for all required git configuration elements in developer forks
#---------------------------------------------------------------------------
nullGitUserId <- list(
    user.name  = "NA",
    user.email = "NA"
)
gitEnv <- new.env()
gitUserId <- "gitUserId"
assign(gitUserId, nullGitUserId, envir = gitEnv)
getRepoUserId <- function(dir){
    git2r::config(git2r::repository(dir))$local
}
getGlobalUserId <- function(dir){
    git2r::config(git2r::repository(dir))$global
}
setGitConfigUser <- function(dir, nullUser = FALSE){ 
    userId <- nullGitUserId # don't need user info for definitive repo clones
    if(!nullUser){
        userId <- getRepoUserId(dir) # use the existing user info if already present; nothing to do
        if(!is.null(userId$user.email) && userId$user.email != 'NA'){
            assign(gitUserId, userId, envir = gitEnv)
            return()
        }
        userId <- get(gitUserId, envir = gitEnv)
        if(is.null(userId$user.email) || userId$user.email == 'NA'){
            userId <- list(
                name  = Sys.getenv('USER_NAME'), 
                email = Sys.getenv('USER_EMAIL')
            )
            
            print(userId)
            
            if(userId$user.name == "" || userId$user.email == "") return(NULL)
            assign(gitUserId, userId, envir = gitEnv)
        } 
    } 
    git2r::config(
        git2r::repository(dir),
        user.name  = userId$user.name,
        user.email = userId$user.email
    )
}
checkGitConfigUser <- function(dir){ # ensure presence of user.name/email prior to pull
    userId <- getRepoUserId(dir)
    if(!is.null(userId$user.name) && !is.null(userId$user.email)) return()
    global <- getGlobalUserId(dir)
    toEnv <- list(
        "user.name"  = "USER_NAME",
        "user.email" = "USER_EMAIL"
    )
    for(key in names(toEnv)){
        if(!is.null(userId[[key]])) next # use repo value first
        userId[[key]] <- Sys.getenv(toEnv[[key]]) # then gitCredentials.R
        if(userId[[key]] == "") userId[[key]] <- global[[key]] # then git config global
        if(is.null(userId[[key]])) userId[[key]] <- nullGitUserId[[key]] # then NA as last resort
    }
    git2r::config(
        git2r::repository(dir),
        user.name  = userId$user.name,
        user.email = userId$user.email
    )
}

#---------------------------------------------------------------------------
# set and clear MDI locks on git repositories
# use same format as mdi-pipelines-framework so locks are shared between Stages 1 and 2
# locks are _not_ fork-specific, i.e., a lock applies equally to definitive and developer-forks
#---------------------------------------------------------------------------
getMdiLockFile <- function(repoDir){
    parts <- rev(strsplit(repoDir, '/')[[1]])
    repo <- parts[1]
    fork <- parts[2] # definitive or developer-forks
    type <- parts[3] # suites or frameworks
    lockFile <- paste(repo, 'lock', sep = ".")
    mdiDir <- paste(rev(parts[4:length(parts)]), collapse = "/")
    file.path(mdiDir, type, lockFile)
}
waitForRepoLock <- function(lockFile = NULL, repoDir = NULL){
    if(is.null(lockFile)) lockFile <- getMdiLockFile(repoDir)
    if(!file.exists(lockFile)) return()  
    message(paste("waiting for lock to clear:", lockFile))  
    maxLockWaitSec <- 30
    cumLockWaitSec <- 0
    while(file.exists(lockFile) && cumLockWaitSec <= maxLockWaitSec){ # wait for others to release their lock
        cumLockWaitSec <- cumLockWaitSec + 1
        Sys.sleep(1);
    }
    if(file.exists(lockFile)){
        message(paste0(
            "\nrepository is locked:\n    ", 
                repoDir,
            "\nif you know the repository is not in use, try deleting its lock file:\n    ", 
                lockFile, "\n"
        ))
        stop('no')
    }
}
setMdiGitLock <- Vectorize(function(repoDir){ # expect that caller has used waitForRepoLock as needed
    lockFile <- getMdiLockFile(repoDir)
    waitForRepoLock(lockFile)
    file.create(lockFile)
})
releaseMdiGitLock <- Vectorize(function(repoDir){
    lockFile <- getMdiLockFile(repoDir)
    if(file.exists(lockFile)) unlink(lockFile)
})

#---------------------------------------------------------------------------
# checkout the appropriate repository versions
#---------------------------------------------------------------------------
# the definitive mdi-pipelines-framework uses the most recent tagged version (which always exists)
# definitive mdi-apps-framework and tool suite repositories use, in order of highest precedence:
#   the override value found in 'checkout' list
#   the tip of main if launching server in developer mode
#   the most recent tagged version
#   the tip of main if no release tags
# all developer-forks stay where the developer had them (tip of 'main' if a new installation)
#---------------------------------------------------------------------------
checkoutRepoTargets <- function(repos, checkout, developer = FALSE){
    if(is.logical(checkout) && checkout == FALSE) return()
    message('checking out most recent or requested repository versions')
    areOverrides <- is.list(checkout)
    if(areOverrides && is.null(checkout$suites)) checkout$suites <- list()     
    mapply(function(name, dir, exists, fork, stage, type, latest){
        if(exists && fork == Forks$definitive){
            default <- if(developer || is.na(latest)) 'main' else latest # a branch or version tag
            isPipelinesFramework <- stage == Stages$pipelines && type == Types$framework
            target <- if(isPipelinesFramework || !areOverrides){
                default            
            } else { # look for version overrides on apps framework and tool suites
                isAppsFramework <- stage == Stages$apps && type == Types$framework 
                override <- if(isAppsFramework) checkout$framework else checkout$suites[[name]]
                if(is.null(override) || override == "latest") default # honor MDI version directives
                    else if(override == "pre-release") 'main'
                    else override
            }
            checkoutGitBranch(dir, target) # git checkout <tag> is fine but results in a detached head
        }        
    }, repos$name, repos$dir, repos$exists, repos$fork, repos$stage, repos$type, repos$latest)    
}
