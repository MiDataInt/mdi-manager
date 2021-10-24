ECHO OFF
REM -----------------------------------------------------------------------
REM this batch file will help you easily launch MDI target programs on Windows
REM -----------------------------------------------------------------------
REM REQUIRED: edit the following line to match the system path to your R installation
SET RSCRIPT="_PATH_TO_R_/bin/Rscript.exe"
REM -----------------------------------------------------------------------
REM OPTIONAL: edit the following line to provide a GitHub Personal Access Token
REM           that has permissions to use any required private suite repositories
SET GITHUB_PAT="_GITHUB_PAT_"
REM -----------------------------------------------------------------------

REM do not anything below this line

ECHO.
ECHO Options:
ECHO.
ECHO   1 - run the MDI web interface (end user mode)
ECHO   2 - run the MDI web interface (developer mode)
ECHO   3 - (re)install the MDI packages and repositories
ECHO   4 - exit and do nothing
ECHO.
SET /p OPTION_NUMBER=Select an option number:

IF "%OPTION_NUMBER%"=="1" (
    SET COMMAND=run
    SET OPTIONS=, checkout='main'
    SET MESSAGE=MDI shutdown complete
) ELSE IF "%OPTION_NUMBER%"=="2" (
    SET COMMAND=develop
    SET OPTIONS=
    SET MESSAGE=MDI shutdown complete
) ELSE IF "%OPTION_NUMBER%"=="3" (
    SET COMMAND=install
    SET OPTIONS=
    REM , gitUser='%gitUser%', token='%GITHUB_PAT%', checkout='develop'
    SET MESSAGE=MDI installation complete
) ELSE (
    EXIT
)

ECHO %RSCRIPT% -e "mdi::%COMMAND%(getwd()%OPTIONS%)"

ECHO.
ECHO %MESSAGE%
ECHO.

PAUSE
