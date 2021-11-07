ECHO OFF
REM ----------------------------------------------------------------
REM launch the MDI web server and browser client in 'remote:server' mode
REM     web server runs perpetually on a remote server on the login node
REM     web browser runs on a user's local desktop/laptop computer
REM     communication from browser to server is via SSH local port forwarding
REM     thus, address entered into web browser is "http://127.0.0.1:SHINY_PORT"
REM ----------------------------------------------------------------
REM this script launches two processes and immediately exits
REM ssh process continues interactively in separate command shell
REM ----------------------------------------------------------------

REM set ssh server (i.e., login node) variables
SET USER=wilsonte
SET SERVER=wilsonte-lab.mbni.org

REM set node/job variables
SET SHINY_PORT=3838

REM ssh into server, with local port forwarding
REM launch MDI web server if not already running and report URL
START "%SERVER%" ssh -L %SHINY_PORT%:127.0.0.1:%SHINY_PORT% %USER%@%SERVER% bash mdi-remote-server.sh %SHINY_PORT%

REM open a Chrome browser window at the appropriate url and port for the ssh tunnel to server
START "Chrome" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" http://127.0.0.1:%SHINY_PORT%
