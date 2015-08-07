@ECHO OFF
IF [%1] == [] goto usage
CD %1

SET orig_dir=%CD%
SET WalkshedDirName=Transit_Walksheds_GIS

:: Python Directory
::        Cube 6.1.0 SP1 comes with ArcGIS 10.1       runtime
::        Cube 6.0.2     comes with ArcGIS  9.3.1 SP2 runtime and is not supported here
::        Python 2.6 will support ArcPy upto ArcGIS 10.0. Python 2.7 is needed to support ArcPy with ArcGIS 10.1.

SET python_bindir=0

:: Look in C drive
IF %python_bindir%==0  CALL:CheckPythonPath  C:\Python27\ArcGIS10.2  python_bindir
IF %python_bindir%==0  CALL:CheckPythonPath  C:\Python27\ArcGIS10.1  python_bindir
IF %python_bindir%==0  CALL:CheckPythonPath  C:\Python26\ArcGIS10.0  python_bindir

:: Look in D drive
IF %python_bindir%==0  CALL:CheckPythonPath  D:\Python27\ArcGIS10.2  python_bindir
IF %python_bindir%==0  CALL:CheckPythonPath  D:\Python27\ArcGIS10.1  python_bindir
IF %python_bindir%==0  CALL:CheckPythonPath  D:\Python26\ArcGIS10.0  python_bindir

:: Look in E drive
IF %python_bindir%==0  CALL:CheckPythonPath  E:\Python27\ArcGIS10.2  python_bindir
IF %python_bindir%==0  CALL:CheckPythonPath  E:\Python27\ArcGIS10.1  python_bindir
IF %python_bindir%==0  CALL:CheckPythonPath  E:\Python26\ArcGIS10.0  python_bindir

:: Python should be found by now
IF %python_bindir%==0  GOTO:error-dependency

:DoSteps
ECHO.
ECHO.
ECHO. Using Python from Directory = %python_bindir%
CD /D %orig_dir%
ECHO.
ECHO.

:: Create directories

ECHO.
ECHO.1) Creating Subdirectories ...
ECHO.

IF NOT EXIST  "inputs\%WalkshedDirName%\input"   MKDIR  "inputs\%WalkshedDirName%\input"
IF NOT EXIST  "inputs\%WalkshedDirName%\output"  MKDIR  "inputs\%WalkshedDirName%\output"

:: Change Working Directory

DEL /F /Q /S  inputs\%WalkshedDirName%\*
CD  /D        inputs\%WalkshedDirName%

:: Prepare Inputs (if *.Lin files exist then use PT else use TRNBUILD)

ECHO.
ECHO.2) Preparing Inputs ...
ECHO.

if exist "..\Mode1AM.Lin" (
	ECHO.    using PT line files
	start /w Voyager.exe          ..\..\..\scripts\MWCOG_Prepare_Inputs_to_Walkshed_Process_PT.s        /start -Pvoya -S"%orig_dir%\inputs\%WalkshedDirName%"
	if errorlevel 2 goto error
) else (
	ECHO.    using TRNBUILD line files
	start /w Voyager.exe          ..\..\..\scripts\MWCOG_Prepare_Inputs_to_Walkshed_Process_TRNBUILD.s  /start -Pvoya -S"%orig_dir%\inputs\%WalkshedDirName%"
	if errorlevel 2 goto error
)

:: Create Walksheds

ECHO.
ECHO.3) Launching ArcPy-based Walkshed Process ...
ECHO.

%python_bindir%\python.exe    ..\..\..\scripts\MWCOG_ArcPy_Walkshed_Process.py
if errorlevel 1 goto error

:: Copy AreaWalk.txt file

ECHO.
ECHO.4) Copying AreaWalk.txt / PercentWalk.txt File(s) ...
ECHO.

:: Backup existing copies as "Old"

IF EXIST ..\AreaWalk.txt        COPY /Y  ..\AreaWalk.txt          ..\AreaWalk_Old.txt
IF EXIST ..\PercentWalk.txt	    COPY /Y  ..\PercentWalk.txt       ..\PercentWalk_Old.txt

:: Now install and overwrite existing copies

IF EXIST output\AreaWalk.txt    COPY /Y  output\AreaWalk.txt      ..\.
if errorlevel 1 goto error

IF EXIST output\PercentWalk.txt	COPY /Y  output\PercentWalk.txt   ..\.
if errorlevel 1 goto error

:: Copy Walkshed MXD

ECHO.
ECHO.5) Copying ArcGIS MXD File ...
ECHO.

COPY /Y  ..\..\..\scripts\MWCOG_ArcPy_Walkshed_Process_TEMPLATE.mxd   MWCOG_ArcPy_Walksheds_%1.mxd
if errorlevel 1 goto error

:: Change to Original Directory
CD /D %orig_dir%
ECHO.
ECHO.

:: Done

ECHO. Process Complete!
GOTO end

::------------------------------------------------------------------------------------------------
::------------------------------------------------------------------------------------------------

:error
ECHO.
ECHO.
ECHO. ERROR: Error in Walkshed Process
ECHO.
ECHO.
PAUSE
:end
CD..
GOTO:EOF

:usage
ECHO.
ECHO. Error: No Folder Name Provided
ECHO. This batch file requires a folder name.
ECHO.
PAUSE
GOTO:EOF

:error-dependency
ECHO.
ECHO.
ECHO ERROR: DEPENDENCIES NOT SATISFIED (Do you have Cube 6.1.0 SP1 or above (with ArcGIS runtime)?)
ECHO.
ECHO.
goto error

::--------------------------------------------------------
::-- BEGIN Function CheckPythonPath
::--------------------------------------------------------

:CheckPythonPath          -- This function checks and sets python path
::                        -- %~1: Path containing Python.exe
::                        -- %~2: Variable containing status
SET myPath=0

ECHO     Searching for Python in Path %~1
IF EXIST %~1 (
	CD /D %~1
	IF EXIST python.exe (
		SET myPath=%~1
		ECHO     Found Python in Path %~1
	) ELSE ( SET myPath=0 )
) ELSE ( SET myPath=0 )

SET "%~2=%myPath%"

GOTO:EOF
::--------------------------------------------------------
::-- END Function CheckPythonPath
::--------------------------------------------------------
