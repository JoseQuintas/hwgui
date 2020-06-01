@echo off
rem
rem $Id$
rem
rem Batch file for building under Open-Watcom (OW)
rem
rem Please modify environment accordingly
rem

SET _PATH=%PATH%
SET _INCLUDE=%INCLUDE%
SET _LIB=%LIB%

SET HB_PATH=C:\Harbour_wc\core-master
SET HRB_EXE=%HB_PATH%\bin\win\watcom\harbour.exe

SET WATCOM=C:\WATCOM
SET PATH=%WATCOM%\BINNT64;%WATCOM%\BINNT;%PATH%
SET EDPATH=%WATCOM%\EDDAT
SET INCLUDE=%WATCOM%\H;%WATCOM%\H\NT;%HB_PATH%\include
SET LIB=%WATCOM%\lib386;c:\watcom\lib386\nt;%_LIB%
REM SET WHTMLHELP=D:\BINNT\HELP

REM SET PATH=C:\watcom\BINNT;C:\watcom\BINW;;D:\xhrb\bin\watcom;%_PATH%


if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist lib md lib
if not exist obj md obj

:BUILD

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

REM Restore old environment values
SET PATH=%_PATH%
SET _PATH=
SET INCLUDE=%_INCLUDE%
SET _INCLUDE=
SET LIB=%_LIB%
SET _LIB=

REM =============================  EOF of make_w32.bat =========================