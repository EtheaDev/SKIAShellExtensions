@echo off
setlocal
REM Paths below are relative to the folder of this script
cd /d "%~dp0"

REM Works out whether this batch was started from Explorer, in which case FROM_EXPLORER is set to 1 instead of 0.
set FROM_EXPLORER=0
echo %cmdcmdline% | find /i "%~nx0" > NUL
if not errorlevel 1 (
  REM This batch was started by a program and not from a command prompt window
  echo %cmdcmdline% | find /i "call " > NUL
  if errorlevel 1 (
    REM This batch was started from Explorer and not from another batch or PowerShell script
    set FROM_EXPLORER=1
  )
)

if "%FROM_EXPLORER%" == "1" (
  echo.
  echo ###############################################################################
  echo Building SKIA Shell Extensions, Lottie Text Editor and Animation Viewer ^(Win32 and Win64^) with Delphi 13 ^(Config=Release^)
  echo ###############################################################################
  echo.
  echo Press ENTER to continue, or close this window to abort...
  pause > NUL
)

set BDS=C:\BDS\Studio\37.0
if exist "c:\program files (x86)\embarcadero\studio\37.0" set BDS=c:\program files (x86)\embarcadero\studio\37.0

if not exist "%BDS%\bin\rsvars.bat" (
  echo.
  echo ERROR: Delphi 13 not found
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

call "%BDS%\bin\rsvars.bat"

echo.
echo **************************************************************************
echo Building SKIAShellExtensions ^(Delphi13/Win64/Release^)
echo **************************************************************************
echo.
msbuild.exe "Source\SKIAShellExtensions.dproj" /target:Clean;Build /p:Platform=Win64 /p:config=Release /v:minimal /p:DCC_Hints=false
if errorlevel 1 (
  echo.
  echo ERROR building SKIAShellExtensions ^(Delphi13/Win64/Release^)
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

echo.
echo **************************************************************************
echo Building SKIAShellExtensions32 ^(Delphi13/Win32/Release^)
echo **************************************************************************
echo.
msbuild.exe "Source\SKIAShellExtensions32.dproj" /target:Clean;Build /p:Platform=Win32 /p:config=Release /v:minimal /p:DCC_Hints=false
if errorlevel 1 (
  echo.
  echo ERROR building SKIAShellExtensions32 ^(Delphi13/Win32/Release^)
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

echo.
echo **************************************************************************
echo Building LottieTextEditor ^(Delphi13/Win64/Release^)
echo **************************************************************************
echo.
msbuild.exe "Source\LottieTextEditor.dproj" /target:Clean;Build /p:Platform=Win64 /p:config=Release /v:minimal /p:DCC_Hints=false
if errorlevel 1 (
  echo.
  echo ERROR building LottieTextEditor ^(Delphi13/Win64/Release^)
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

echo.
echo **************************************************************************
echo Building LottieTextEditor ^(Delphi13/Win32/Release^)
echo **************************************************************************
echo.
msbuild.exe "Source\LottieTextEditor.dproj" /target:Clean;Build /p:Platform=Win32 /p:config=Release /v:minimal /p:DCC_Hints=false
if errorlevel 1 (
  echo.
  echo ERROR building LottieTextEditor ^(Delphi13/Win32/Release^)
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

echo.
echo **************************************************************************
echo Building AnimationViewer ^(Delphi13/Win64/Release^)
echo **************************************************************************
echo.
msbuild.exe "Source\AnimationViewer.dproj" /target:Clean;Build /p:Platform=Win64 /p:config=Release /v:minimal /p:DCC_Hints=false
if errorlevel 1 (
  echo.
  echo ERROR building AnimationViewer ^(Delphi13/Win64/Release^)
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

echo.
echo **************************************************************************
echo Building AnimationViewer ^(Delphi13/Win32/Release^)
echo **************************************************************************
echo.
msbuild.exe "Source\AnimationViewer.dproj" /target:Clean;Build /p:Platform=Win32 /p:config=Release /v:minimal /p:DCC_Hints=false
if errorlevel 1 (
  echo.
  echo ERROR building AnimationViewer ^(Delphi13/Win32/Release^)
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

echo.
echo Adding the digital signature to: D:\ETHEA\SKIAShellExtensions\Bin64\LottieTextEditor.exe
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\SKIAShellExtensions\Bin64\LottieTextEditor.exe
if errorlevel 1 (
  echo.
  echo ERROR signing: D:\ETHEA\SKIAShellExtensions\Bin64\LottieTextEditor.exe
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to continue...
    pause > NUL
  )
)

echo.
echo Adding the digital signature to: D:\ETHEA\SKIAShellExtensions\Bin64\AnimationViewer.exe
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\SKIAShellExtensions\Bin64\AnimationViewer.exe
if errorlevel 1 (
  echo.
  echo ERROR signing: D:\ETHEA\SKIAShellExtensions\Bin64\AnimationViewer.exe
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to continue...
    pause > NUL
  )
)

echo.
echo Adding the digital signature to: D:\ETHEA\SKIAShellExtensions\Bin32\LottieTextEditor.exe
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\SKIAShellExtensions\Bin32\LottieTextEditor.exe
if errorlevel 1 (
  echo.
  echo ERROR signing: D:\ETHEA\SKIAShellExtensions\Bin32\LottieTextEditor.exe
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to continue...
    pause > NUL
  )
)

echo.
echo Adding the digital signature to: D:\ETHEA\SKIAShellExtensions\Bin32\AnimationViewer.exe
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\SKIAShellExtensions\Bin32\AnimationViewer.exe
if errorlevel 1 (
  echo.
  echo ERROR signing: D:\ETHEA\SKIAShellExtensions\Bin32\AnimationViewer.exe
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to continue...
    pause > NUL
  )
)

echo.
echo **********************************************************************************************
echo Building "D:\ETHEA\SKIAShellExtensions\Setup\SKIAShellExtensions.iss" with InnoSetup
echo **********************************************************************************************
echo.
"C:\Program Files (x86)\Inno Setup 6\iscc.exe" "D:\ETHEA\SKIAShellExtensions\Setup\SKIAShellExtensions.iss"
if errorlevel 1 (
  echo.
  echo ERROR building "D:\ETHEA\SKIAShellExtensions\Setup\SKIAShellExtensions.iss" with InnoSetup
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to exit...
    pause > NUL
  )
  exit /b 1
)

echo.
echo Adding the digital signature to: D:\ETHEA\SKIAShellExtensions\Setup\Output\SKIAShellExtensionsSetup.exe
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\SKIAShellExtensions\Setup\Output\SKIAShellExtensionsSetup.exe
if errorlevel 1 (
  echo.
  echo ERROR signing: D:\ETHEA\SKIAShellExtensions\Setup\Output\SKIAShellExtensionsSetup.exe
  if "%FROM_EXPLORER%" == "1" (
    echo.
    echo Press ENTER to continue...
    pause > NUL
  )
)

echo.
echo Done.
if "%FROM_EXPLORER%" == "1" (
  echo.
  echo Press ENTER to exit...
  pause > NUL
)
exit /b 0
