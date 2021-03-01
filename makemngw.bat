@echo off
REM
REM makemngw.bat
REM
REM $Id$
REM
REM Build HWGUI libraries for Windows / MinGW
REM
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist bin md bin
if not exist lib md lib
if not exist obj md obj

:BUILD

   rem set path=d:\softools\mingw\bin
   rem set HARBOURFLAGS=-dUNICODE
   rem set CFLAGS=-DHWG_USE_POINTER_ITEM -DUNICODE
   set CFLAGS=-DHWG_USE_POINTER_ITEM

   mingw32-make.exe -f makefile.gcc
   if errorlevel 1 goto BUILD_ERR

:BUILD_OK

   goto EXIT

:BUILD_ERR

   goto EXIT

:CLEAN
REM === Remove all libraries ===
REM Do not delete libpcre.a (GTK cross development environment) 
del lib\libhbxml.a 2> NUL
del lib\libhwgdebug.a 2> NUL
del lib\libhwgui.a 2> NUL
del lib\libprocmisc.a 2> NUL
REM === Delete the rest ===
   del lib\*.bak 2> NUL
   del obj\*.o 2> NUL
   del obj\*.c 2> NUL

   goto EXIT

:EXIT
