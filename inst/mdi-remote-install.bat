ECHO OFF
REM ----------------------------------------------------------------
REM install the MDI on a remote server path via SSH
REM such installations support subsequent remote run calls
REM ----------------------------------------------------------------

REM set ssh server (i.e., login node) variables
SET USER=johndoe
SET SERVER=johndoe.example.org

REM set installation variables
REM   R_LOAD should be:
REM     "echo" if R is already available on the server system
REM     a command to load the target R version (e.g., module load R/0.0.0)
REM   MDI_DIR must exist, it won't be created
REM   INSTALL_PACKAGES and ADD_TO_PATH must be TRUE or FALSE
SET R_LOAD=echo
SET MDI_DIR=~
SET INSTALL_PACKAGES=FALSE
SET ADD_TO_PATH=TRUE


REM do not edit anything below this line


REM prompt for permission
SET IP_MESSAGE=-(action suppressed)
IF %INSTALL_PACKAGES%==TRUE (
    SET IP_MESSAGE=- install or update R packages
)
SET ATP_MESSAGE=-(action suppressed)
IF %ADD_TO_PATH%==TRUE (
    SET ATP_MESSAGE=- modify '~/.bashrc' to add the mdi executable to PATH
)
ECHO.
ECHO ------------------------------------------------------------------
ECHO CONFIRM MDI INSTALLATION ACTIONS
ECHO ------------------------------------------------------------------
ECHO.
ECHO   - populate %SERVER% directory %MDI_DIR% or %MDI_DIR%/mdi (as appropriate)
ECHO   - clone or update MDI repositories from GitHub
ECHO   - check out the most recent version of all definitive MDI repositories
ECHO   %IP_MESSAGE%
ECHO   %ATP_MESSAGE%
ECHO.
SET /p CONFIRMATION=Do you wish to continue? (type 'y' for 'yes'):

IF "%CONFIRMATION%"=="y" (

REM ssh into server and execute the install command sequence
ssh %USER%@%SERVER% ^
%R_LOAD%; ^
Rscript -e """install.packages('remotes', repos = 'https://cloud.r-project.org')"""; ^
Rscript -e """gC <- '~/gitCredentials.R'; if(file.exists(gC)) {source(gC); do.call(Sys.setenv, gitCredentials)}; remotes::install_github('MiDataInt/mdi-manager')"""; ^
Rscript -e """mdi::install('%MDI_DIR%', installPackages = %INSTALL_PACKAGES%, addToPATH = %ADD_TO_PATH%)"""; ^
echo; ^
echo "Done"

REM 

PAUSE

)
