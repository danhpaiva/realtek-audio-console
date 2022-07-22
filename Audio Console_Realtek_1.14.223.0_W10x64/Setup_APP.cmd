
@echo off
if not exist C:\OEM\AcerLogs md C:\OEM\AcerLogs
SET LogPath=C:\OEM\AcerLogs\Useralaunch.Log

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
IF '%errorlevel%' NEQ '0' (
    ECHO Requesting administrative privileges...
    GOTO UACPrompt
) ELSE GOTO gotAdmin

:UACPrompt
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
ECHO UAC.ShellExecute "%~s0", "%~s1", "", "runas", 1 >> "%temp%\getadmin.vbs"

"%temp%\getadmin.vbs"
del /q "%temp%\getadmin.vbs"
EXIT /B 1

:gotAdmin
ECHO.>>%LogPath%
ECHO %DATE% %TIME%[Log START]  ============ %~dpnx0 ============ >> %LogPath%
SETLOCAL ENABLEDELAYEDEXPANSION
pushd "%~dp0"

ECHO %DATE% %TIME%[Log TRACE]  Installing, please wait... >> %LogPath% 2>&1
ECHO Installing, please wait...

ECHO %DATE% %TIME%[Log TRACE]  reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber>>%LogPath% 2>&1
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber>>%LogPath% 2>&1
for /f "skip=2 tokens=3 delims= " %%V in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber') do SET OSCurrentVerison=%%V
if %OSCurrentVerison% LEQ 16299 (
	ECHO %DATE% %TIME%[Log TRACE]  OSCurrentVerison=[%OSCurrentVerison%], No support Driver UWP. Goto :end>>%LogPath%
	goto :END
) else (
	ECHO %DATE% %TIME%[Log TRACE]  OSCurrentVerison=[%OSCurrentVerison%], It's okay to support Driver UWP. Continue>>%LogPath%
)

REM for /f "skip=2 tokens=3" %%A in ('reg query HKLM\Software\OEM\Metadata /v Brand') do set Brand=%%A
REM ECHO %DATE% %TIME%[Log TRACE]  SET Custom DATA File NAME by Brand >> %LogPath%
REM SET CustomDATA=.\CDF\custom.data.acerlt.xml
REM if /I "%Brand%" == "Gateway" set CustomDATA=gateway-abb.json
REM if /I "%Brand%" == "Packard" set CustomDATA=packardbell-abb.json

if exist C:\OEM\FilterVCLibsList.txt del /f /q C:\OEM\FilterVCLibsList.txt >NUL 2>&1
SET TargetVCLib=Microsoft.VCLibs.140.00_

ECHO !DATE! !TIME![Log TRACE]  dir /s /b "%TargetVCLib%*_x64*.appx" >>%LogPath% 2>&1
dir /s /b "%TargetVCLib%*_x64*.appx" >>%LogPath% 2>&1
(for /f "delims=" %%I in ('dir /s /b "%TargetVCLib%*_x64*.appx"') do (
	pushd "%%~dpI"
	ECHO !DATE! !TIME![Log TRACE]  call :CheckingVCLib x64
	call :CheckingVCLib x64
	popd
)) >>%LogPath% 2>&1

ECHO !DATE! !TIME![Log TRACE]  dir /s /b "%TargetVCLib%*_x86*.appx" >>%LogPath% 2>&1
dir /s /b "%TargetVCLib%*_x86*.appx" >>%LogPath% 2>&1
(for /f "delims=" %%I in ('dir /s /b "%TargetVCLib%*_x86*.appx"') do (
	pushd "%%~dpI"
	ECHO !DATE! !TIME![Log TRACE]  call :CheckingVCLib x86
	call :CheckingVCLib x86
	popd
)) >>%LogPath% 2>&1

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::	
::::   DO Not Trim Trailing space............
::::
::::   Each Set Value in the end exist the Space for dism split paramter
::::   set APPXPackagePath_X86=!APPXPackagePath_X86!/dependencypackagepath:"%%d" 
::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:InstallUWP
IF /i "%PROCESSOR_ARCHITECTURE%" equ "AMD64" (
	call :GetParameter
	REM ECHO %DATE% %TIME%[Log TRACE]  dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X64!/CustomDataPath:"%CustomDATA%" /region="all">>%LogPath% 2>&1
	REM dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X64!/CustomDataPath:"%CustomDATA%" /region="all">>%LogPath% 2>&1
	ECHO %DATE% %TIME%[Log TRACE]  dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X64!/region="all">>%LogPath% 2>&1
	dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X64!/region="all">>%LogPath% 2>&1
) else (	
	call :GetParameter
	REM ECHO %DATE% %TIME%[Log TRACE]  dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X86!/CustomDataPath:"%CustomDATA%" /region="all">>%LogPath% 2>&1
	REM dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X86!/CustomDataPath:"%CustomDATA%" /region="all">>%LogPath% 2>&1
	ECHO %DATE% %TIME%[Log TRACE]  dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X86!/region="all">>%LogPath% 2>&1
	dism /online /english /add-provisionedappxpackage /packagepath:"!packagepath!" /licensepath:"!licensepath!" !DependencyPackage_X86!/region="all">>%LogPath% 2>&1
)
SET DISMErrCode=%errorlevel%
ECHO %DATE% %TIME%[Log TRACE]  got return code [%DISMErrCode%] >>%LogPath%
if %DISMErrCode% neq 0 (
	ECHO %DATE% %TIME%[Log TRACE]  Return code is [%DISMErrCode%], pop up error message to remind user. >>%LogPath%
	REM call :Reboot
) else (
	ECHO %DATE% %TIME%[Log TRACE]  Return code is [%DISMErrCode%], leave. >>%LogPath%
)

timeout /t 5 >NUL 2>&1
ECHO Installaton process completed.
ECHO Press any key to exit
PAUSE >NUL

:END
popd
SETLOCAL DISABLEDELAYEDEXPANSION
ECHO %DATE% %TIME%[Log LEAVE]  ============ %~dpnx0 ============ >> %LogPath%
ECHO.>>%LogPath%
exit /b 0



:GetParameter
:GetPackagePath_Start
REM Prepare PackagePath
:Method1
ECHO %DATE% %TIME%[Log TRACE]  dir /s /b *.appxbundle >> %LogPath%
dir /s /b *.appxbundle >> %LogPath% 2>&1
(for /f "delims=" %%d in ('dir /s /b *.appxbundle') do (
	set packagepath=%%d
))>NUL 2>&1

ECHO %DATE% %TIME%[Log TRACE]  dir /s /b *.msixbundle >> %LogPath%
dir /s /b *.msixbundle >> %LogPath% 2>&1
(for /f "delims=" %%d in ('dir /s /b *.msixbundle') do (
	set packagepath=%%d
))>NUL 2>&1

:Method2
ECHO %DATE% %TIME%[Log TRACE]  dir /s /b *.appx>> %LogPath% 2>&1
dir /s /b *.appx>C:\OEM\Appx_list.txt 2>&1
if %errorlevel% neq 0 (
	ECHO !DATE! !TIME![Log TRACE]  *.appx not found, goto :GetPackagePath_END >>%LogPath%
	goto :GetPackagePath_END
)
type C:\OEM\Appx_list.txt >> %LogPath%
ECHO %DATE% %TIME%[Log TRACE]  Getting Dependency Appx list>>%LogPath%
dir /s /b Microsoft*.appx>C:\OEM\DependencyAppx_list.txt 2>&1
type C:\OEM\DependencyAppx_list.txt >>%LogPath%
for /f "delims=" %%f in (C:\OEM\Appx_list.txt) do (
	ECHO ------------------------------------------------------------------------------ >>%LogPath%
	ECHO !DATE! !TIME![Log TRACE]  Checking [%%~nf] if main Package... >>%LogPath%
	ECHO !DATE! !TIME![Log TRACE]  find /i "%%~nf" C:\OEM\DependencyAppx_list.txt>>%LogPath% 2>&1
	find /i "%%~nf" C:\OEM\DependencyAppx_list.txt>>%LogPath% 2>&1
	if !errorlevel! neq 0 (
		ECHO !DATE! !TIME![Log TRACE]  [%%~nxf] did not exist in the C:\OEM\DependencyAppx_list.txt, set as PackagePath>>%LogPath%
		set PackagePath=%%f
	) else (
		ECHO !DATE! !TIME![Log TRACE]  [%%~nxf] exist in the C:\OEM\DependencyAppx_list.txt, not the main package. >>%LogPath%
	)
)

:GetPackagePath_END
ECHO %DATE% %TIME%[Log TRACE]  PackagePath is [%packagepath%]  >> %LogPath%
ECHO.>>%LogPath%

REM Prepare LicensePath
ECHO %DATE% %TIME%[Log TRACE]  dir /s /b *License*.xml >> %LogPath%
dir /s /b *License*.xml >> %LogPath% 2>&1
(for /f "delims=" %%d in ('dir /s /b *License*.xml') do (
	set licensepath=%%d
))>NUL 2>&1
ECHO %DATE% %TIME%[Log TRACE]  LicensePath is [%licensepath%]  >> %LogPath%
ECHO.>>%LogPath%

REM Prepare DependencyPackagePath
ECHO %DATE% %TIME%[Log TRACE]  dir /s /b Microsoft*_x86*.appx >> %LogPath%
dir /s /b Microsoft*_x86*.appx >> %LogPath% 2>&1
(for /f "delims=" %%d in ('dir /s /b Microsoft*_x86*.appx') do (
	ECHO !DATE! !TIME![Log TRACE]  find /i "%%~nxd" C:\OEM\FilterVCLibsList.txt >>%LogPath% 2>&1
	find /i "%%~nxd" C:\OEM\FilterVCLibsList.txt >>%LogPath% 2>&1
	if !errorlevel! neq 0 (
		ECHO !DATE! !TIME![Log TRACE]  [%%~nxd] can be added to dependencypackagepath >>%LogPath%
		set DependencyPackage_X86=!DependencyPackage_X86!/dependencypackagepath:"%%d" 
	) else ( ECHO !DATE! !TIME![Log TRACE]  [%%~nxd] should be filtered from dependencypackagepath >>%LogPath% )
	ECHO !DATE! !TIME![Log TRACE]  Now DependencyPackage_X86 is [!DependencyPackage_X86!] >>%LogPath%
))>NUL 2>&1
ECHO %DATE% %TIME%[Log TRACE]  dir /s /b Microsoft*_x64*.appx >> %LogPath%
dir /s /b Microsoft*_x64*.appx >> %LogPath% 2>&1
(for /f "delims=" %%d in ('dir /s /b Microsoft*_x64*.appx') do (
	ECHO !DATE! !TIME![Log TRACE]  find /i "%%~nxd" C:\OEM\FilterVCLibsList.txt >>%LogPath% 2>&1
	find /i "%%~nxd" C:\OEM\FilterVCLibsList.txt >>%LogPath% 2>&1
	if !errorlevel! neq 0 (
		ECHO !DATE! !TIME![Log TRACE]  [%%~nxd] can be added to dependencypackagepath >>%LogPath%
		set DependencyPackage_X64=!DependencyPackage_X64!/dependencypackagepath:"%%d" 
	) else ( ECHO !DATE! !TIME![Log TRACE]  [%%~nxd] should be filtered from dependencypackagepath >>%LogPath% )
	ECHO !DATE! !TIME![Log TRACE]  Now DependencyPackage_X64 is [!DependencyPackage_X64!] >>%LogPath%
))>NUL 2>&1
ECHO %DATE% %TIME%[Log TRACE]  Merge _x86.appx and _x64.appx For X64 >> %LogPath%
set DependencyPackage_X64=%DependencyPackage_X86%%DependencyPackage_X64%
ECHO %DATE% %TIME%[Log TRACE]  After merge DependencyPackage_X64 is [%DependencyPackage_X64%] >>%LogPath%
ECHO.>>%LogPath%
exit /b 0



:Reboot
if exist UWPFAIL_rebooted.tag (
	if exist c:\OEM\NAPP\D2D.tag (
		ECHO %DATE% %TIME%[Log TRACE]  c:\OEM\NAPP\D2D.tag found, exit /b 0 >>%LogPath%
		exit /b 0
	)
)
ECHO %DATE% %TIME%[Log TRACE]  acerReboot.exe with timeout 10 and Pause >>%LogPath%
ECHO %DATE% %TIME%[Log TRACE]  acerReboot.exe with timeout 10 and Pause >UWPFAIL_rebooted.tag
if exist C:\Windows\System32\acerReboot.exe (
	acerReboot.exe >>%LogPath% 2>&1
) else (
	ECHO MsgBox "ERROR! Driver UWP Install process failed with ERROR code %DISMErrCode%",16,"Driver UWP Installation Detection" >ErrorMsg.vbs
	CScript /nologo ErrorMsg.vbs
	CScript /nologo ErrorMsg.vbs
	CScript /nologo ErrorMsg.vbs
)
timeout /t 10
pause
exit /b 0




:CheckingVCLib
:GetVCLibs_Start
SET CheckingVCLib_Now=%TargetVCLib%*_%1*.appx
ECHO.
ECHO -----------------------------------------------------------------
ECHO %DATE% %TIME%[Log TRACE]  Current working directory is [!CD!]
ECHO %DATE% %TIME%[Log TRACE]  dir /b %CheckingVCLib_Now%
dir /b %CheckingVCLib_Now%
if %errorlevel% neq 0 ECHO %DATE% %TIME%[Log TRACE]  dir /b %CheckingVCLib_Now% not exist, exit /b 0 && exit /b 0

for /f "tokens=1,2 delims=_" %%I in ('dir /b %CheckingVCLib_Now%') do (
	ECHO !DATE! !TIME![Log TRACE]  set VCLibsName=[%%I], VCLibsVer=[%%J]
	set VCLibsName=%%I
	set VCLibsVer=%%J
	goto :GetVCLibs_End
)
:GetVCLibs_End
pushd "%~dp0"
ECHO %DATE% %TIME%[Log TRACE]  powershell.exe -noprofile -executionpolicy unrestricted -command ".\CheckingVCLib.ps1 %VCLibsName% %VCLibsVer% %1; exit $LASTEXITCODE"
powershell.exe -noprofile -executionpolicy unrestricted -command ".\CheckingVCLib.ps1 %VCLibsName% %VCLibsVer% %1; exit $LASTEXITCODE"
SET ExitCode=%errorlevel%
ECHO %DATE% %TIME%[Log TRACE]  Getting return code is %ExitCode%
popd
if %ExitCode% equ 5 (
	ECHO !DATE! !TIME![Log TRACE]  Skip below dependency package list from UWP source
	dir /b %CheckingVCLib_Now% >>C:\OEM\FilterVCLibsList.txt
	type C:\OEM\FilterVCLibsList.txt
) else (
	ECHO !DATE! !TIME![Log TRACE]  OS with older version, no need to filter.
)
ECHO -----------------------------------------------------------------
ECHO.
exit /b 0

