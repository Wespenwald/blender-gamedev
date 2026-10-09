@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Blender 5.2.2 gamedev builder

REM ------------------------------------------------------------------
REM Builds Blender 5.2.2 from source as a gamedev build
REM (no FFmpeg/Freestyle/fluid/ocean/OpenVDB, non-gamedev editors hidden).
REM Installs Git, CMake and Visual Studio 2022 (C++) via winget if missing.
REM Keep blender-gamedev.patch in the same folder as this script.
REM ------------------------------------------------------------------

set "BLENDER_TAG=v5.2.2"
set "WORK=%SystemDrive%\blender-gamedev"
set "PATCH=%~dp0blender-gamedev.patch"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VSSETUP=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\setup.exe"
set "WINGET_ARGS=-e --source winget --accept-package-agreements --accept-source-agreements"

if not exist "%PATCH%" (
	echo ERROR: blender-gamedev.patch was not found next to this script.
	goto :fail
)

where winget >nul 2>nul
if errorlevel 1 (
	echo ERROR: winget was not found. Install "App Installer" from the Microsoft Store and run this script again.
	goto :fail
)

echo.
echo ==== [1/5] Checking / installing build tools ====
call :refresh_path

where git >nul 2>nul
if errorlevel 1 (
	echo Installing Git for Windows...
	winget install --id Git.Git %WINGET_ARGS%
	call :refresh_path
)
where git >nul 2>nul
if errorlevel 1 (
	echo ERROR: Git is still not available. Close this window and run the script again.
	goto :fail
)
git lfs install --skip-repo >nul

where cmake >nul 2>nul
if errorlevel 1 (
	echo Installing CMake...
	winget install --id Kitware.CMake %WINGET_ARGS%
	call :refresh_path
)
where cmake >nul 2>nul
if errorlevel 1 (
	echo ERROR: CMake is still not available. Close this window and run the script again.
	goto :fail
)

call :find_vs
if defined VS_PATH goto :vs_ok

set "VS_ANY="
if exist "%VSWHERE%" for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -version [17.0^,99.0^) -property installationPath`) do set "VS_ANY=%%i"
if defined VS_ANY (
	echo Adding the C++ workload to the existing Visual Studio at "!VS_ANY!" ^(this can take 15-30 minutes^)...
	"%VSSETUP%" modify --installPath "!VS_ANY!" --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --passive --norestart
) else (
	echo Installing Visual Studio 2022 Community with C++ ^(this can take 15-30 minutes^)...
	winget install --id Microsoft.VisualStudio.2022.Community %WINGET_ARGS% --override "--wait --passive --norestart --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
)
call :find_vs
if not defined VS_PATH (
	echo ERROR: Visual Studio with C++ was not found. Restart Windows and run this script again.
	goto :fail
)
:vs_ok
echo Visual Studio: %VS_PATH%

echo.
echo ==== [2/5] Downloading Blender %BLENDER_TAG% source into %WORK% ====
if not exist "%WORK%" mkdir "%WORK%"
if not exist "%WORK%\blender\.git" (
	git -c core.autocrlf=false clone --depth 1 --branch %BLENDER_TAG% https://projects.blender.org/blender/blender.git "%WORK%\blender"
	if errorlevel 1 goto :fail
)
cd /d "%WORK%\blender"
git config core.autocrlf false

echo.
echo ==== [3/5] Downloading precompiled libraries (several GB, can take a while) ====
if not exist "lib\windows_x64\.git" (
	git config --local submodule.lib/windows_x64.update checkout
	set GIT_LFS_SKIP_SMUDGE=1
	git submodule update --progress --init lib/windows_x64
	if errorlevel 1 goto :fail
	set GIT_LFS_SKIP_SMUDGE=
)
git -C lib/windows_x64 lfs pull
if errorlevel 1 goto :fail

echo.
echo ==== [4/5] Applying gamedev patch ====
if exist "build_files\cmake\config\blender_gamedev.cmake" (
	echo Gamedev patch already applied.
) else (
	git apply --whitespace=nowarn "%PATCH%"
	if errorlevel 1 goto :fail
)

echo.
echo ==== [5/5] Compiling Blender (30-90 minutes depending on your CPU) ====
call make.bat gamedev
if errorlevel 1 goto :fail

set "BLENDER_EXE="
for /d %%d in ("%WORK%\build_windows_*") do if exist "%%d\bin\Release\blender.exe" set "BLENDER_EXE=%%d\bin\Release\blender.exe"
if not defined BLENDER_EXE (
	echo ERROR: Build finished but blender.exe was not found.
	goto :fail
)

echo.
echo ==================================================================
echo  DONE. Your gamedev Blender is here:
echo    %BLENDER_EXE%
echo ==================================================================
set /p RUNNOW=Start Blender now? (y/n) 
if /i "%RUNNOW%"=="y" start "" "%BLENDER_EXE%"
pause
exit /b 0

:find_vs
set "VS_PATH="
if not exist "%VSWHERE%" exit /b 0
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -version [17.0^,99.0^) -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_PATH=%%i"
exit /b 0

:refresh_path
set "PATH=%ProgramFiles%\Git\cmd;%ProgramFiles%\CMake\bin;%PATH%"
exit /b 0

:fail
echo.
echo Build stopped because of the error above. You can run this script again,
echo it continues where it left off.
pause
exit /b 1
