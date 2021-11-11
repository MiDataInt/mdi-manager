ECHO OFF
REM ----------------------------------------------------------------
REM launch the MDI web server and browser client in 'remote' mode
REM     web server runs on a remote server on the login node
REM     web browser runs on a user's local desktop/laptop computer
REM     communication from browser to server is via SSH local port forwarding
REM     thus, address entered into web browser is "http://127.0.0.1:SHINY_PORT"
REM ----------------------------------------------------------------

REM set ssh server (i.e., login node) variables
SET USER=johndoe
SET SERVER=johndoe.example.org

REM set node/job variables
REM     set SHINY_PORT to not conflict on the server
REM     MDI_DIR must end with /mdi, e.g., ~/mdi
REM     set DATA_DIR and HOST_DIR to NULL if not needed
REM     DEVELOPER must be TRUE or FALSE
SET SHINY_PORT=3838
SET MDI_DIR=/treehouse/wilsonte_lab/ssd/mdi
SET DATA_DIR=NULL
SET HOST_DIR=NULL
SET DEVELOPER=TRUE


REM do not edit anything below this line


REM open a Chrome browser window at the appropriate url and port for the ssh tunnel to server
START "Chrome" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" http://127.0.0.1:%SHINY_PORT%

REM ssh into server, with local port forwarding
REM launch MDI web server if not already running and report it's access URL
REM await user input for how to close, including whether or not to leave the web server running after exit
ssh -L %SHINY_PORT%:127.0.0.1:%SHINY_PORT% %USER%@%SERVER% ^
bash %MDI_DIR%/remote/mdi-remote-server.sh ^
%SHINY_PORT% %MDI_DIR% %DATA_DIR% %HOST_DIR% %DEVELOPER%
