@echo off
REM CMake wrapper to force Visual Studio 17 2022 generator
REM This script is placed alongside cmake-real.exe

REM Get the directory of this script
set SCRIPT_DIR=%~dp0

REM Build new arguments - replace -G "Visual Studio 16 2019" with VS 17 2022
set NEW_ARGS=

:parse_args
if "%~1"=="" goto run_cmake
if "%~1"=="-G" goto skip_generator
if "%~2"=="Visual Studio 16 2019" goto skip_value
set NEW_ARGS=!NEW_ARGS! %1
shift
goto parse_args

:skip_generator
REM Skip -G and its value
shift
shift
goto parse_args

:skip_value
REM Skip the value only
shift
goto parse_args

:run_cmake
REM Add our generator
set NEW_ARGS=-G "Visual Studio 17 2022" -A x64 !NEW_ARGS!
echo Running: "%SCRIPT_DIR%cmake-real.exe" !NEW_ARGS!
"%SCRIPT_DIR%cmake-real.exe" !NEW_ARGS!

exit /b %ERRORLEVEL%
