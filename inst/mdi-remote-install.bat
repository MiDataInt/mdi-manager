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


REM ssh into server and execute the install command sequence
ssh %USER%@%SERVER% ^
%R_LOAD%; ^
Rscript -e """install.packages('remotes', repos = 'https://cloud.r-project.org')"""; ^
Rscript -e """gC <- '~/gitCredentials.R'; if(file.exists(gC)) source(gC); remotes::install_github('MiDataInt/mdi-manager')"""; ^
Rscript -e """mdi::install('%MDI_DIR%', installPackages = %INSTALL_PACKAGES%, addToPATH = %ADD_TO_PATH%)"""; ^
echo; ^
echo "Done"

REM 

PAUSE
