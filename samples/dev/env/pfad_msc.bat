@echo off
REM
REM $Id$
REM
REM HWGUI source code
REM Set path for MSC + Harbour
REM Pfad fuer MSC + Harbour setzen
REM Created by DF7BE
REM
REM Usable for WinAPI edition of HWGUI 
REM
REM Call sample:
REM C:\hwgui\hwgui-msc\samples\dev\env\pfad_msc.bat
REM
REM Set path to MS Visual Visual Studio to your own needs.
REM The path depends on used version of Microsoft Visual C
REM Now set by MSVC script:
REM
CALL "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x86
REM Expected output:
REM [vcvarsall.bat] Environment initialized for: 'x86' 
REM SET MSVCPATH=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.34.31933\bin\Hostx64\x64
REM SET HB_INC1="C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VC\Linux\include\usr\include"
REM SET HB_INC2="C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VC\Linux\include\usr\include\x86_64-linux-gnu"
REM SET HB_INC3="C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\VC\Linux\include\usr\lib\gcc\x86_64-linux-gnu\5\include"
REM SET HB_INC4="C:\Program Files (x86)\Windows Kits\10\Include\10.0.22000.0\um"
REM SET HB_INC5="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.34.31933\include"
REM SET HB_INC6="C:\Program Files (x86)\Windows Kits\10\Include\10.0.22000.0\shared"
REM SET HB_HOST_INC=%HB_INC1% -I%HB_INC2% -I%HB_INC3% -I%HB_INC4% -I%HB_INC5% -I%HB_INC6%
REM Harbour
SET HB_COMPILER=msvc
SET HB_PLATFORM=win
SET HB_PATH=C:\harbour-msc\core-master
SET HRB_EXE=%HB_PATH%\bin\%HB_PLATFORM%\%HB_COMPILER%\harbour.exe
REM SET PATH=%PATH%;C:\hwgui-msc\hwgui\bin;C:\make\bin;%MSVCPATH%
SET PATH=%PATH%;C:\hwgui-msc\hwgui\bin;C:\make\bin;C:\harbour-msc\core-master\bin\win\msvc
REM

REM
REM ========================= EOF of pfad.bat ==================================
REM 
