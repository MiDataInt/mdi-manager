ECHO OFF
REM -----------------------------------------------------------------------
REM this batch file will help you easily launch MDI target programs on Windows
REM -----------------------------------------------------------------------
REM edit the following line to match the system path to your R installation
SET RSCRIPT="_PATH_TO_R_/bin/Rscript.exe"
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
    SET OPTIONS=
    SET MESSAGE=MDI shutdown complete
) ELSE IF "%OPTION_NUMBER%"=="2" (
    SET COMMAND=develop
    SET OPTIONS=
    SET MESSAGE=MDI shutdown complete
) ELSE IF "%OPTION_NUMBER%"=="3" (
    SET COMMAND=install
    SET OPTIONS=
    SET MESSAGE=MDI installation complete
) ELSE (
    EXIT
)

%RSCRIPT% -e "mdi::%COMMAND%(getwd() %OPTIONS%)"

ECHO.
ECHO %MESSAGE%
ECHO.

PAUSE
