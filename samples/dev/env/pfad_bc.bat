@ECHO OFF
REM
REM pfad_bc.bat
REM
REM $Id$
REM
REM Set environment for Borland C (32 bit) Compiler
REM
REM Modify values to your own needs
REM GNU make
SET GNU_MAKE=c:\make\bin
REM Harbour
SET HB_PATH=C:\harbour-bcc\core-master
SET HB_COMPILER=bcc
SET HB_PLATFORM=win
SET HRB_EXE=%HB_PATH%\bin\%HB_PLATFORM%\%HB_COMPILER%\harbour.exe
REM C compiler
SET CCOMP=C:\bcc
REM 32 bit
SET PATH=%GNU_MAKE%;%CCOMP%\Bin;%HB_PATH%\bin\%HB_PLATFORM%\%HB_COMPILER%;%PATH%
SET INCLUDE=%CCOMP%\include
REM SET LIB=
REM
REM
REM ========================= EOF of pfad_bc.bat ==============================

