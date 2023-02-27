call "D:\BDS\Studio\22.0\bin\rsvars.bat"
msbuild.exe "Source\SKIAShellExtensions.dproj" /target:Clean;Build /p:Platform=Win64 /p:config=release
msbuild.exe "Source\SKIAShellExtensions32.dproj" /target:Clean;Build /p:Platform=Win32 /p:config=release
msbuild.exe "Source\LottieTextEditor.dproj" /target:Clean;Build /p:Platform=Win64 /p:config=release
msbuild.exe "Source\LottieTextEditor.dproj" /target:Clean;Build /p:Platform=Win32 /p:config=release

call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\LottieShellExtensions\Bin32\LottieTextEditor.exe
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\LottieShellExtensions\Bin64\LottieTextEditor.exe

:INNO
"C:\Program Files (x86)\Inno Setup 6\iscc.exe" "D:\ETHEA\SKIAShellExtensions\Setup\SKIAShellExtensions.iss"
set INNO_STATUS=%ERRORLEVEL%
if %INNO_STATUS%==0 GOTO SIGNSETUP
pause
EXIT

:SIGNSETUP
call D:\ETHEA\Certificate\SignFileWithSectico.bat D:\ETHEA\SKIAShellExtensions\Setup\Output\SKIAShellExtensionsSetup.exe

:END
pause
