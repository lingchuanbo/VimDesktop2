:: Prune Scene
:: 1.0.1
:: MastaMan 
:: http://3dground.net

chcp 1251 > nul
@echo off 
title PRUNE SCENE PROTECTION
setlocal enabledelayedexpansion
cls

set input=%1
set arg1=
set arg2=
set arg3=
set out=
set pth=
set tmp_scanning=

for /f "tokens=1,2,3 delims=;" %%I in (%input%) do (
	set arg1=%%I
	set arg2=%%J.txt
	set arg3=%%K
	set out=%%J.ini
	set pth=%%~dpJ
	set tmp_scanning=!pth!_tmp_scanning_
) 

del /f "%tmp_scanning%"
del /f "%arg2%"
del /f "%out%"
cls

echo [SCAN] > "%arg2%"
echo [SCAN] > "%tmp_scanning%"

	echo -------------------------------------------------------------
	echo.
	echo                   PRUNE SCENE PROTECTION
	echo.
	echo -------------------------------------------------------------
	echo.
	echo.
	echo.
	
echo Prune Scene preparing files. This may take a while...
echo Please do not close this window!
echo.

set scanned=0

for /f "delims=*" %%G in ('dir /b /s "%arg1%*.max"') do (
	
	set /a scanned+=1
	set str=
	for /f "delims=" %%A in ("%%G") do > nul chcp 1251 & set str=%%A

	findstr /m "%arg3%" "!str!" 
	if not errorlevel 1 (
		@echo !str!= >> "%arg2%"
	) 
	
	findstr /m /r /c:"P.t.P.r.e.A.c" "!str!"
	if not errorlevel 1 (
		@echo !str!= >> "%arg2%"
	)
	
	findstr /m /r /c:"m.s.c.p.r.o.p.\..d.l.l" "!str!"
	if not errorlevel 1 (
		@echo !str!= >> "%arg2%"
	)
 	
	
	cls
	echo -------------------------------------------------------------
	echo.
	echo                   PRUNE SCENE PROTECTION
	echo.
	echo -------------------------------------------------------------
	echo.
	echo.
	echo.
	echo Scan file: !str!
)

set lines=0
for /f "usebackq tokens=*" %%a in ("%arg2%") do set /a lines+=1
set /a lines-=1

echo [DONE] >> "%arg2%"
echo lastscan=%date% %time% >> "%arg2%"
echo scandir=%arg1% >> "%arg2%"
echo scanned=%scanned% >> "%arg2%"

del /f "%tmp_scanning%"

cls
	echo -------------------------------------------------------------
	echo.
	echo                   PRUNE SCENE PROTECTION
	echo.
	echo -------------------------------------------------------------
	echo.
	echo.
	
echo Scanning done. You can close this windon now. Go to Prune Scene script.
echo.
echo Found %lines% infected files! 
echo Total scanned %scanned% 3Ds Max files! 
echo.
color 0a
if %lines% gtr 0 (
	color 0c
)

exit 0


