@echo off
REM CMake wrapper to force Visual Studio 17 2022 generator
REM Rename cmake.exe to cmake-real.exe and place this as cmake.exe

REM Get the directory of this script
set SCRIPT_DIR=%~dp0

REM Build new arguments with -G flag at the start
set NEW_ARGS=-G "Visual Studio 17 2022" -A x64

REM Add all original arguments
:parse_args
if "%~1"=="" goto run_cmake
set NEW_ARGS=!NEW_ARGS! %1
shift
goto parse_args

:run_cmake
echo Running: "%SCRIPT_DIR%cmake-real.exe" !NEW_ARGS!
"%SCRIPT_DIR%cmake-real.exe" !NEW_ARGS!

exit /b %ERRORLEVEL%
