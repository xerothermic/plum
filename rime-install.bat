@echo off

setlocal

title Plum Windows bootstrap script

set config_file=%~dp0\rime-install-config.bat
if exist "%config_file%" call "%config_file%"

if defined ProgramFiles(x86) (set arch=64) else (set arch=32)

set search_path==%~dp0;^
%ProgramFiles%\Git\cmd;^
%ProgramFiles%\Git\mingw%arch%\bin;^
%ProgramFiles%\Git\usr\bin;

rem find 64-bit Git in 32-bit cmd.exe
if defined ProgramW6432 set search_path=%search_path%^
%ProgramW6432%\Git\cmd;^
%ProgramW6432%\Git\mingw%arch%\bin;^
%ProgramW6432%\Git\usr\bin;

rem find user installed 32-bit Git on 64-bit OS
if defined ProgramFiles(x86) set search_path=%search_path%^
%ProgramFiles(x86)%\Git\cmd;^
%ProgramFiles(x86)%\Git\mingw32\bin;^
%ProgramFiles(x86)%\Git\usr\bin;

set PATH=%search_path%;%PATH%
rem path

rem check for updates at https://github.com/git-for-windows/git/releases/latest
if not defined git_version set git_version=2.17.0
if not defined git_release set git_release=.1

set git_installer=Git-%git_version%%git_release:.1=%-%arch%-bit.exe

if "%git_mirror%" == "taobao" (
  set git_download_url_prefix=https://npm.taobao.org/mirrors/git-for-windows/
) else (
  set git_download_url_prefix=https://github.com/git-for-windows/git/releases/download/
)

set git_download_url=%git_download_url_prefix%v%git_version%.windows%git_release%/%git_installer%

where /q bash
if %errorlevel% equ 0 goto :bash_found

where /q %git_installer%
if %errorlevel% equ 0 (
   set git_installer_path=
   echo Found installer: %git_installer%
   goto :install_git
)

where /q curl
if %errorlevel% equ 0 (
   set downloader=curl -fsSL
   set save_to=-o
   goto :download_git
)

where /q powershell
if %errorlevel% equ 0 (
   set downloader=powershell Invoke-WebRequest
   set save_to=-OutFile
   goto :download_git
)

echo Error: neither curl nor powershell is found.
echo Please manually download and install git, then re-run %~n0:
echo %git_download_url%
exit /b 1

:download_git
set git_installer_path=%TEMP%\
echo Downloading installer: %git_installer%
%downloader% %git_download_url% %save_to% %git_installer_path%%git_installer%
if %errorlevel% neq 0 (
   echo Error downloading %git_installer%
   exit /b 1
)
rem TODO: verify installer
echo Download complete: %git_installer%

:install_git
echo Installing git ...
%git_installer_path%%git_installer% /SILENT /GitAndUnixToolsOnPath

:bash_found

if exist "%plum_dir%"/rime-install (
   bash "%plum_dir%"/rime-install %*
) else if exist plum/rime-install (
  bash plum/rime-install %*
) else if exist rime-install (
  bash rime-install %*
) else (
  echo Downloading rime-install ...
  curl -fsSL https://git.io/rime-install -o "%TEMP%"/rime-install
  if errorlevel 1 (
    echo Error downloading rime-install
    exit /b 1
  )
  bash "%TEMP%"/rime-install %*
)

exit /b
