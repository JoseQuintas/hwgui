@echo off
REM 
REM make_b32.bat
REM
REM $Id$
REM
REM Batch file for building under Borland C (32 bit)
REM
REM Please modify environment accordingly
REM

SET BCC_INSTALL=C:\bcc
SET MAKE=%BCC_INSTALL%\Bin\make.exe
SET HRB_DIR=C:\harbour-bcc\core-master

if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist lib md lib
if not exist obj md obj
if not exist obj\b32 md obj\b32
if not exist obj\b32\mt md obj\b32\mt
:BUILD

rem set HARBOURFLAGS=-dUNICODE
rem set CFLAGS=-DHWG_USE_POINTER_ITEM -DUNICODE
set CFLAGS=-DHWG_USE_POINTER_ITEM

%MAKE% -l EXE_OBJ_DIR=obj\b32\bin OBJ_DIR=obj\b32 -fmakefile.bc %1 %2 %3 > make_b32.log
if errorlevel 1 goto BUILD_ERR
%MAKE% -l OBJ_DIR=obj\b32\mt -DHB_THREAD_SUPPORT -DHB_MT=mt -fmakefile.bc %2 %3 >> make_b32.log

:BUILD_OK

   goto EXIT

:BUILD_ERR

REM   notepad make_b32.log
   echo Build Error HWGUI
   goto EXIT

:CLEAN
   del lib\*.lib
   del lib\*.bak
   del obj\b32\*.obj
   del obj\b32\*.c
   del obj\b32\mt\*.obj
   del obj\b32\mt\*.c

   del make_b32.log

   goto EXIT

:EXIT

REM ====================== EOF of make_b32.bat =======================