ECHO OFF
REM ----------------------------------------------------------------
REM launch the MDI web server and browser client in 'node' mode
REM     web server runs on a worker node on a Slurm cluster via an sbatch job on a time limit
REM     web browser runs on a user's local desktop/laptop computer
REM     communication from browser to server is via SSH dynamic port forwarding (i.e., SOCKS5)
REM     thus:
REM         address entered into web browser is "http://NODE:SHINY_PORT"
REM         SwitchyOmega browser extension is used to proxy via "socks5://127.0.0.1:PROXY_PORT"
REM ----------------------------------------------------------------

REM set local (i.e., client) variables
SET PROXY_PORT=1080

REM set ssh server (i.e., cluster login node) variables
SET USER=johndoe
SET SERVER=greatlakes.arc-ts.umich.edu

REM set MDI server variables
REM     set SHINY_PORT to not conflict on the server
REM     MDI_DIR must end with /mdi, e.g., ~/mdi
REM     set DATA_DIR and HOST_DIR to NULL if not needed
REM     DEVELOPER must be TRUE or FALSE
SET R_VERSION=4.1.0
SET SHINY_PORT=3838
SET MDI_DIR=/treehouse/wilsonte_lab/ssd/mdi
SET DATA_DIR=NULL
SET HOST_DIR=NULL
SET DEVELOPER=TRUE

REM set node/job variables
SET ACCOUNT=johndoe1
SET JOB_TIME_MINUTES=240
SET CPUS_PER_TASK=1
SET MEM_PER_CPU=4000m


REM do not edit anything below this line


REM ssh into server, with dynamic port forwarding (SOCKS5)
REM launch MDI web server job if one is not already running and report it's access URL
REM await user input for how to close, including whether or not to leave the web server running after exit
START "%SERVER%" ssh -D %PROXY_PORT% %USER%@%SERVER% ^
bash %MDI_DIR%/remote/mdi-remote-node.sh ^
%PROXY_PORT% %R_VERSION% %SHINY_PORT% %MDI_DIR% %DATA_DIR% %HOST_DIR% %DEVELOPER% ^
%ACCOUNT% %JOB_TIME_MINUTES% %CPUS_PER_TASK% %MEM_PER_CPU% 

REM open a Chrome browser window that uses the SOCKS5 proxy port (without changing system settings)
CD "C:\Program Files (x86)\Google\Chrome\Application"
START "Chrome" chrome.exe 
