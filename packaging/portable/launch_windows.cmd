@echo off
setlocal
set "BUNDLE_DIR=%~dp0"
set "GAME_EXE=%BUNDLE_DIR%lantern_house_internal.exe"
if not exist "%GAME_EXE%" (
  echo ERROR: Required game executable is missing: lantern_house_internal.exe 1>&2
  echo Re-extract the complete internal playtest bundle and try again. 1>&2
  exit /b 2
)
"%GAME_EXE%" %*
exit /b %ERRORLEVEL%
