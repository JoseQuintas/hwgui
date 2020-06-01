@ECHO OFF
REM
REM pfad_wc.bat
REM
REM $Id$
REM
REM Set environment for Open Watcom C (64 bit) Compiler
REM
REM Modify values to your own needs
REM Harbour
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
REM SET WHTMLHELP=D:\BINNT\HELP
REM
REM
REM ========================= EOF of pfad_wc.bat ==============================

