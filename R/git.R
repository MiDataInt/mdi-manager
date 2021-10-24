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
Branches <- list(main = "main", develop = "develop")
Types    <- list(framework = 'frameworks', suite = 'suites')
Stages   <- list(pipelines = 'pipelines', apps = 'apps')
#---------------------------------------------------------------------------
# there are two different framework repositories, corresponding to the two main stages of execution
#   mdi-pipelines-framework = code that runs mostly non-interactively, stage 1, resource-intensive processing
#   mdi-apps-framework = code that runs the web server and thus interactively, stage 2, data exploration
pipelinesFrameworkRepo <- 'mdi-pipelines-framework'
appsFrameworkRepo      <- 'mdi-apps-framework'
#repoKeys <- c('mdi_pipelines_framework', 'mdi_apps_framework')
#appsRepoKey <- 'mdi_apps_framework'
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# collect information on all relevant git repos
#---------------------------------------------------------------------------
parseGitRepos <- function(dirs, configFilePath, gitUser){
    message('collecting git repos from config.yml')
    config <- yaml::read_yaml(configFilePath)
    
    # prepend the frameworks repos to the suites repos
    upstreamUrls <- sapply(c(pipelinesFrameworkRepo, appsFrameworkRepo), assembleGitUrl, mdiGitUser)
    upstreamUrls <- c(upstreamUrls, config$pipelines, config$apps) 
    types <- c(
        rep(Types$framework, 2), 
        rep(Types$suite, length(upstreamUrls) - 2)
    )
    stages <- c(
        Stages$pipelines, 
        Stages$apps, 
        rep(Stages$pipelines, length(config$pipelines)), 
        rep(Stages$apps, length(config$apps))
    )

    # assemble and return an ordered table of all repos known to this MDI instance
    x <- rbind(   
        data.frame( # repos with remote==upstream are the definitive public source code
            type    = types,
            stage   = stages,
            remote  = Remotes$upstream,
            fork    = Forks$definitive,
            url     = upstreamUrls,
            stringsAsFactors = FALSE
        ),
        data.frame( # repos with remote==origin are a developer's forks, if any
            type    = types,
            stage   = stages,
            remote  = Remotes$origin,
            fork    = Forks$developer,
            url     = switchGitUser(upstreamUrls, gitUser) # NB: some forked repos might not exist
        )
    )
    x$dir <- getRepoDir(dirs$root, x$type, x$fork, x$url)
    x
}
assembleGitUrl <- function(repoName, gitUser) {
    repo <- paste(repoName, 'git', sep = ".")
    paste(gitHubUrl, gitUser, repo, sep = "/")
}
switchGitUser <- Vectorize(function(url, gitUser){
    if(is.null(gitUser)) return(NULL)
    parts <- strsplit(url, '/')[[1]]
    parts[length(parts) - 1] <- gitUser
    paste(parts, collapse = '/')
})
getRepoDir <- Vectorize(function(mdiDir, type, fork, url){
    if(is.null(url)) return(NULL)
    repo <- rev(strsplit(url, '/')[[1]])[1]
    repo <- strsplit(repo, '\\.')[[1]][1]
    file.path(mdiDir, type, fork, repo)
})
filterRepoDirs <- function(repos, type = NULL, stage = NULL, fork = NULL, paste = FALSE){
    x <- !is.null(repos$dir) &
         !is.na(repos$dir) & 
         if(is.null(type))  TRUE else repos$type  == type & 
         if(is.null(stage)) TRUE else repos$stage == stage & 
         if(is.null(fork))  TRUE else repos$fork  == fork
    repos <- repos[x, ]
    if(!paste) return(repos$dir)
    paste(repos$dir, collapse = " ")
}

#---------------------------------------------------------------------------
# set a user's GitHub PAT into the proper environment variable
#---------------------------------------------------------------------------
setPersonalAccessToken <- function(token){ 
    if(!is.null(token)) Sys.setenv(GITHUB_PAT = token)
}

#---------------------------------------------------------------------------
# clone or pull a code repository
# always maintain each of the two core branches (main and develop)
#---------------------------------------------------------------------------
downloadGitRepo <- Vectorize(function(dir, url, fork, ...) { 
    if(is.null(url)) return()

    # get up-to-date repo from the server
    #   definitive repos set to tip of 'main' prior to pulling
    #   don't change branches on developer-forks, attempt to pull on the current branch
    if(isGitRepo(dir)){
        if(!gitRepoMatches(dir, url)) stop(paste(dir, 'is not a clone of', url))
        message(paste('pulling', url))
        if(fork == Forks$definitive) checkoutGitBranch(dir, silent = TRUE)
        tryCatch( 
            { git2r::pull(                                  
                repo = dir,
                credentials = git2r::cred_token()
            ) },
            error = function(e) NULL # checkoutGitBranch(dir, silent = TRUE)
        )

    # or clone it on first encounter
    #   all repos set to tip of 'main' on first installation
    } else {
        message(paste('cloning', url))
        git2r::clone(
            url = url,
            local_path = dir,
            credentials = git2r::cred_token(),
            progress = TRUE
        )
        checkoutGitBranch(dir, silent = TRUE)
        
        # initialize the tracked develop branch on developer forks
        if(fork == Forks$developer){
            # checkoutGitBranch(dir, Branches$develop, create = TRUE, silent = TRUE)
            # git2r::branch_set_upstream(
            #     git2r::repository_head(dir),
            #     paste(Remotes$origin, Branches$develop, sep = '/')
            # )            
            # checkoutGitBranch(dir, Branches$main, silent = TRUE)

            # set the "upstream" remote to the definitive repository
            git2r::remote_add(dir, Remotes$upstream, switchGitUser(url, mdiGitUser)) 
        }
        
        # ensure that at least a null user is present in config
        setGitConfigUser(dir)
    }
})
pullGitMain <- function(dir){
    checkoutGitBranch(dir, silent = TRUE) 
    git2r::pull(                                  
        repo = dir,
        credentials = git2r::cred_token()
    )  
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
#---------------------------------------------------------------------------
checkoutGitBranch <- function(dir, branch = 'main', create = FALSE, silent = FALSE) {
    if(!silent) message(paste('setting', dir, 'head to', branch))
    git2r::checkout(
        object = dir,
        branch = branch,
        force = FALSE,
        create = create
    )
}

#---------------------------------------------------------------------------
# check for all required git configuration elements when running in developer mode
# prompt user as needed for missing information
#---------------------------------------------------------------------------
# NB: information about the repository is implicity present in a cloned repo
#---------------------------------------------------------------------------
checkGitConfigUser <- function(dir){ 
    user.email <- git2r::config(git2r::repository(dir))$local$user.email
    !is.null(user.email) && user.email != 'NA'
}
setGitConfigUser <- function(dir, user.name='NA', user.email='NA'){ 
    git2r::config(
        git2r::repository(dir),
        user.name  = user.name,
        user.email = user.email
    )
}
checkGitConfiguration <- function(dir, gitConfig, user=NULL){

    # check for system git
    if(Sys.which('git') == ""){ # check for development mode must be made by caller
        stop('git must be installed on your system when working in developer mode')
        
    # check for user data in .git/config
    } else {
        
        # whether repo itself (not global) has user metadata 
        if(checkGitConfigUser(dir)) return(NULL)
        
        # prompt for required values if not already present
        if(is.null(user)){
            user <- list()
            message('------------------------------------------------------------------')
            message('Please enter the information used to identify your git commits.')
            message('------------------------------------------------------------------')
            abortMessage <- 'User attributes are required to run in developer mode.'
            user$name  <- trimws(readline(prompt = "Your name (e.g. Jane Doe): "))
            if(user$name == '')  stop(abortMessage)
            user$email <- trimws(readline(prompt = "Email address (e.g. janedoe@umich.edu): "))
            if(user$email == '') stop(abortMessage)        
        }

        # add info to git config
        setGitConfigUser(dir, user$name, user$email)
        if(!checkGitConfigUser(dir)) {
            stop(paste('could not write user information to', gitConfig))
        }
        
        # return user if needed for the next repo
        user
    }
}

#---------------------------------------------------------------------------
# get information on known git branches
#---------------------------------------------------------------------------
getCurrentBranch <- function(dir){
    branches <- git2r::branches(dir)
    names(branches[sapply(branches, git2r::is_head)]) 
}
getAllBranches <- function(dir){
    branches <- names(git2r::branches(dir, flags = "local"))
    list(
        upstream = upstreamBranches, # only main and develop
        origin = branches[!(branches %in% upstreamBranches)] # anything EXCEPT main and develop
    )
}
branchExists <- function(dir, branch){
    branches <- names(git2r::branches(dir, flags = "local"))
    branch %in% branches
}

#---------------------------------------------------------------------------
# checkout the most appropriate branch at web server run time
#---------------------------------------------------------------------------
initializeGitBranch <- function(repoKey, dirs, repos, version, developer, checkout) {
    dir      <- dirs[[repoKey]]
    upstream <- repos[[repoKey]]$upstream
    ref <- if(developer){ # a branch or a tag
        if(git2r::is_detached(dir) || # TRUE when HEAD is on a tagged version on main
           git2r::is_head(git2r::branches(dir)$main)){ # TRUE when head is attached at main
            # either way, force developers off of main branch
            if(repoKey == appsRepoKey) defaultEditBranch # to 'framework' branch of apps repo (to start with)
            else developerBranch # or 'develop' branch of pipelines repo
        } else { # HEAD was not on main, leave it wherever the developer already had it
            branch <- getCurrentBranch(dir)
            if(repoKey == appsRepoKey && 
               branch == developerBranch) { # unless it was the apps develop branch
                branch <- defaultEditBranch
               }
            branch
        }
    } else if(!is.null(checkout)) { # allow server mode (i.e. run) to force a version or branch
        checkout 
    } else { # default to appropriate tagged version based on R version when in production mode
        # TODO: implement version tags on pipelines
        if(repoKey == appsRepoKey) paste0('v', version$MDIVersion) else mainBranch
    }
    syncLocalBranches(dir, ref, upstream)  
    if(!is.null(ref)){
        if(git2r::is_detached(dir)) checkoutGitBranch(dir, mainBranch, silent = TRUE) 
        checkoutGitBranch(dir, ref, create = developer)
    }
}

#---------------------------------------------------------------------------
# sync the local copy of a branch with the upstream repository (if forked)
# NB: this only updates the local copy; developers would later push to GitHub
#---------------------------------------------------------------------------
syncLocalBranches <- function(dir, ref, upstream){
    
    # for end users of the definitive repository, only pull branch if update is needed
    # disallow developer mode on definitive, upstream repo
    if(git2r::remote_url(dir, originRemote) == upstream){
        if(is.null(ref)) return()
        
        ################################
        # TODO: comment this back in !!
        #if(ref %in% c(defaultEditBranch, developerBranch)) {
        #     stop('developer mode not allowed on the MDI repository; please fork it first')
        # }
        
        # TODO: implement this when public
        #if(local does not have requested version){ 
        #    message(paste("syncing clone of", upstream))
        #    branches <- getAllBranches(dir)
        #    fetchAndMergeRemote(originRemote, branches, dir)
        #}
        
    # for developers with a forked repo, always sync branches on server start
    #   main and develop synced from upstream to capture project changes from all users
    #   other local branches are synced from origin to capture changes made by user from another computer
    #   branches on remote but not present locally are fetched and will be tracked on first checkout
    } else {
        message(paste("syncing forked clone of", upstream))
        branches <- getAllBranches(dir)
        for (remote in remotes) fetchAndMergeRemote(remote, branches, dir)
    }
}
fetchAndMergeRemote <- function(remote, branches, dir){
    message(paste('  remote:', remote))
    fetched <- git2r::fetch(
        repo = dir,
        name = remote,
        credentials = git2r::cred_token(),
        verbose = FALSE
    )
    if(fetched$total_objects > 0){
        for(branch in branches[[remote]]){
            message(paste('    branch:', branch))
            checkoutGitBranch(dir, branch, silent = TRUE)        
            merge <- git2r::merge(
                x = dir,
                y = paste(remote, branch, sep = "/"),
                commit_on_success = TRUE,
                fail = FALSE
            )
            if(merge$conflicts) throwMergeError(remote, branch)  
        }
    }    
}
throwMergeError <- function(remote, branch){
    isUpstream <- remote == Remotes$upstream
    message()
    message(paste('You have code conflicts with the remote repository:', remote))
    message(paste0(
        '(i.e. ',
        if(isUpstream) 'the definitive MDI repository'
                  else 'your fork of the MDI repositiory on GitHub',
        ')'
    ))
    message()
    if(isUpstream){
        message('This conflict should not have happened!!')
        message(paste('Never commit code changes on the', branch, 'branch'))
        if(branch == mainBranch){
            message('Changes to main are made by project leads during a production release.')
        } else { # develop
            message('Changes to develop are made by project leads when ')
            message('handling pull requests from user app/feature branches.')
        }
        message()
        message('Your best action now is to re-install the MDI and start over.')
    } else {
        message('Presumably, you failed to keep code changes in sync')
        message('when editing from multiple computers. Hint: remember')
        message('to push your changes before leaving a computer!')
        message()
        message('This conflict is unfortunate but can be resolved.')
        message('Manually find and edit all code conflicts and try again.')
    }
    message()
    stop('FATAL ERROR: merge conflicts with remote repo')
}

