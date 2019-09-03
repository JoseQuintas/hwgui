@echo off
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
   del lib\*.a
   del lib\*.bak
   del obj\*.o
   del obj\*.c

   goto EXIT

:EXIT
