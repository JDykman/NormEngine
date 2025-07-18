@echo off

set NORM_ENGINE_RUNNING=false

:: OUT_DIR is for everything except the exe. The exe needs to stay in root
:: folder so it sees the assets folder, without having to copy it.
set OUT_DIR=build\hot_reload
set PDBS_DIR=%OUT_DIR%\NormEngine_pdbs

set EXE=NormEngine_hot_reload.exe

:: Check if NormEngine is running
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% set NORM_ENGINE_RUNNING=true

if not exist %OUT_DIR% mkdir %OUT_DIR%

:: If NormEngine isn't running then:
:: - delete all NormEngine_XXX.dll files
:: - delete all PDBs in pdbs subdir
:: - optionally create the pdbs subdir
:: - write 0 into pdbs\pdb_number so NormEngine.dll PDBs start counting from zero
::
:: This makes sure we start over "fresh" at PDB number 0 when starting up the
:: NormEngine and it also makes sure we don't have so many PDBs laying around.
if %NORM_ENGINE_RUNNING% == false (
	del /q /s %OUT_DIR% >nul 2>nul
	if not exist "%PDBS_DIR%" mkdir %PDBS_DIR%
	echo 0 > %PDBS_DIR%\pdb_number
)

:: Load PDB number from file, increment and store back. For as long as the NormEngine
:: is running the pdb_number file won't be reset to 0, so we'll get a PDB of a
:: unique name on each hot reload.
set /p PDB_NUMBER=<%PDBS_DIR%\pdb_number
set /a PDB_NUMBER=%PDB_NUMBER%+1
echo %PDB_NUMBER% > %PDBS_DIR%\pdb_number

:: Build NormEngine dll, use pdbs\NormEngine_%PDB_NUMBER%.pdb as PDB name so each dll gets
:: its own PDB. This PDB stuff is done in order to make debugging work.
:: Debuggers tend to lock PDBs or just misbehave if you reuse the same PDB while
:: the debugger is attached. So each time we compile `NormEngine.dll` we give the
:: PDB a unique PDB.
:: 
:: Note that we could not just rename the PDB after creation; the DLL contains a
:: reference to where the PDB is.
::
:: Also note that we always write NormEngine.dll to the same file. NormEngine_hot_reload.exe
:: monitors this file and does the hot reload when it changes.
echo Building NormEngine.dll
odin build . -strict-style -vet -debug -build-mode:dll -out:%OUT_DIR%/NormEngine.dll -pdb-name:%PDBS_DIR%\NormEngine_%PDB_NUMBER%.pdb > nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

:: If NormEngine.exe already running: Then only compile NormEngine.dll and exit cleanly
if %NORM_ENGINE_RUNNING% == true (
	echo Hot reloading... && exit /b 0
)

:: Build NormEngine.exe, which starts the program and loads NormEngine.dll och does the logic for hot reloading.
echo Building %EXE%
odin build main_NormEngine_hot -strict-style -vet -debug -out:%EXE% -pdb-name:%OUT_DIR%\main_hot_reload.pdb
IF %ERRORLEVEL% NEQ 0 exit /b 1

set ODIN_PATH=
for /f "delims=" %%i in ('odin root') do set "ODIN_PATH=%%i"

@REM if not exist "raylib.dll" (
@REM 	if exist "%ODIN_PATH%\vendor\raylib\windows\raylib.dll" (
@REM 		echo raylib.dll not found in current directory. Copying from %ODIN_PATH%\vendor\raylib\windows\raylib.dll
@REM 		copy "%ODIN_PATH%\vendor\raylib\windows\raylib.dll" .
@REM 		IF %ERRORLEVEL% NEQ 0 exit /b 1
@REM 	) else (
@REM 		echo "Please copy raylib.dll from <your_odin_compiler>/vendor/raylib/windows/raylib.dll to the same directory as NormEngine.exe"
@REM 		exit /b 1
@REM 	)
@REM )

if "%~1"=="run" (
	echo Running %EXE%...
	start %EXE%
)
