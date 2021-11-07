ECHO OFF
REM ----------------------------------------------------------------
REM launch the MDI web server and browser client in 'remote:node' mode
REM     web server runs on a worker node on a Slurm cluster via an sbatch job on a time limit
REM     web browser runs on a user's local desktop/laptop computer
REM     communication from browser to server is via SSH dynamic port forwarding (i.e., SOCKS5)
REM     thus, address entered into web browser is "http://NODE:SHINY_PORT"
REM ----------------------------------------------------------------
REM this script launches two processes and immediately exits
REM ssh process continues interactively in separate command shell
REM ----------------------------------------------------------------

REM set local (i.e., client) variables
SET PROXY_PORT=1080

REM set ssh server (i.e., cluster login node) variables
SET USER=wilsonte
SET SERVER=greatlakes.arc-ts.umich.edu

REM set MDI server variables
SET R_VERSION=4.1.0
SET SHINY_PORT=3838

REM set node/job variables
SET ACCOUNT=wilsonte1
SET JOB_TIME_MINUTES=30
SET CPUS_PER_TASK=1
SET MEM_PER_CPU=1000m

REM ssh into server, with dynamic port forwarding (SOCKS5)
REM launch MDI web server job if one is not already running and report URL
START "%SERVER%" ssh -D %PROXY_PORT% %USER%@%SERVER% ^
bash mdi-remote-node.sh ^
%R_VERSION% %SHINY_PORT% %ACCOUNT% %JOB_TIME_MINUTES% %CPUS_PER_TASK% %MEM_PER_CPU%

REM open a Chrome browser window that uses the SOCKS5 proxy port (without changing system settings)
CD "C:\Program Files (x86)\Google\Chrome\Application"
START chrome.exe --proxy-server="socks5://127.0.0.1:%PROXY_PORT%"
