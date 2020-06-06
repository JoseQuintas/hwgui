@ECHO OFF
REM
REM pfad_pc.bat
REM
REM $Id$
REM
REM Set environment for Pelles C (32 bit) Compiler
REM
REM Modify values to your own needs
REM GNU make
SET GNU_MAKE=c:\make\bin
REM Harbour
REM Because Pelles C crashes at harbour build,
REM try to build HWGUI application with Borland C build
rem SET HB_PATH=C:\harbour-pc\core-master
SET HB_PATH=C:\harbour-bcc\core-master
SET HRB_EXE=%HB_PATH%\bin\win\bcc\harbour.exe
REM
rem SET HB_COMPILER=pocc
SET HB_PLATFORM=win
rem see above
rem SET HRB_EXE=%HB_PATH%\bin\%HB_PLATFORM%\%HB_COMPILER%\harbour.exe
REM
REM C compiler
REM Attention ! Blanks in path name not allowed.
REM Modify installation path accordingly when runnung setup.exe
SET CCOMP=C:\PellesC
SET HB_HOST_INC=%CCOMP%\Include\Win
REM Needed by makefile.pc
SET POCC=%CCOMP%
REM 32 bit
SET PATH=%GNU_MAKE%;%CCOMP%\Bin;%HB_PATH%\bin\%HB_PLATFORM%\%HB_COMPILER%;%PATH%
rem see above
SET PATH=%HB_PATH%\win\bcc;%PATH%
REM
SET INCLUDE=%CCOMP%\include
REM SET LIB=
REM
REM
REM ========================= EOF of pfad_pc.bat ==============================

