@echo off

rem $Id: make_w32.bat,v 1.1 2004/04/10 22:25:31 andijahja Exp $
rem
rem Batch file for building under Open-Watcom (OW)
rem
rem Please modify environment accordingly
rem

SET _PATH=%PATH%
SET _INCLUDE=%INCLUDE%
SET _LIB=%LIB%
SET PATH=C:\watcom\BINNT;C:\watcom\BINW;;D:\xhrb\bin\watcom;%_PATH%
SET WATCOM=C:\watcom
SET EDPATH=C:\watcom\EDDAT
SET INCLUDE=C:\watcom\H;C:\watcom\H\NT;d:\xhrb\include
SET LIB=C:\watcom\lib386;c:\watcom\lib386\nt;%_LIB%

if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist lib md lib
if not exist obj md obj

:BUILD

   wmake -h -ms __XHARBOUR__=1 HB_PATH=d:\xhrb -f makefile.wc
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

SET PATH=%_PATH%
SET _PATH=
SET INCLUDE=%_INCLUDE%
SET _INCLUDE=
SET LIB=%_LIB%
SET _LIB=
