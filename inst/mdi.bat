ECHO OFF

REM -----------------------------------------------------------------------
REM REQUIRED: edit the following line to match the system path to your R installation
REM -----------------------------------------------------------------------
SET RSCRIPT="C:\Program Files\R\R-4.0.3\bin\Rscript.exe"
REM -----------------------------------------------------------------------

REM -----------------------------------------------------------------------
REM OPTIONAL: edit the following line to provide a GitHub Personal Access Token
REM           that has permissions to use any required private suite repositories
REM -----------------------------------------------------------------------
SET GITHUB_PAT=""
REM -----------------------------------------------------------------------

ECHO.
ECHO Options:
ECHO.
ECHO   1 - run the MDI web interface (end user mode)
ECHO   2 - run the MDI web interface (developer mode)
ECHO   3 - reinstall the MDI packages and repositories
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
