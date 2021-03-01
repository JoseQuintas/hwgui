@echo off

rem $Id: make_w32.bat,v 1.1 2004/04/10 22:25:31 andijahja Exp $
rem
rem Batch file for building under Open-Watcom (OW)
rem
rem Please modify environment accordingly or
rem set environment with script: 
rem ..\samples\dev\env\pfad_wc.bat
rem

SET HB_PATH=C:\Harbour_wc\core-master
SET HRB_EXE=%HB_PATH%\bin\win\watcom\harbour.exe
SET HB_COMPILER=watcom
SET HB_PLATFORM=win
REM C compiler
SET WATCOM=C:\WATCOM
REM 32 bit
SET PATH=%WATCOM%\BINNT;%WATCOM%\BINNT;%HB_PATH%\bin\win\watcom;%PATH%
REM 64 bit
REM SET PATH=%WATCOM%\BINNT64;%WATCOM%\BINNT;%HB_PATH%\bin\win\watcom;%PATH%
SET EDPATH=%WATCOM%\EDDAT
SET INCLUDE=%WATCOM%\H;%WATCOM%\H\NT
REM SET LIB=

rem SET _PATH=%PATH%
rem SET _INCLUDE=%INCLUDE%
rem SET _LIB=%LIB%
rem SET PATH=C:\watcom\BINNT;C:\watcom\BINW;;D:\xhrb\bin\watcom;%_PATH%
rem SET WATCOM=C:\watcom
rem SET EDPATH=C:\watcom\EDDAT
rem SET INCLUDE=C:\watcom\H;C:\watcom\H\NT;d:\xhrb\include
rem SET LIB=C:\watcom\lib386;c:\watcom\lib386\nt;%_LIB%

if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist lib md lib
if not exist obj md obj

:BUILD

REM   wmake -h -ms __XHARBOUR__=1 HB_PATH=d:\xhrb -f makefile.wc
   wmake -h -ms __XHARBOUR__=1 HB_PATH=%HB_PATH% -f makefile.wc
   rem wmake -h -ms -f makefile.wc > make_w32.log
   if errorlevel 1 goto BUILD_ERR

:BUILD_OK

   goto EXIT

:BUILD_ERR

   rem notepad make_b32.log
   goto EXIT

:CLEAN
   del lib\*.lib
   del lib\*.bak
   del obj\*.obj
   del obj\*.c
   del make_b32.log

   goto EXIT

:EXIT

REM SET PATH=%_PATH%
REM SET _PATH=
REM SET INCLUDE=%_INCLUDE%
REM SET _INCLUDE=
REM SET LIB=%_LIB%
REM SET _LIB=

REM ===================== EOF of make_w32.bat ================================