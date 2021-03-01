@echo off
REM build HWGUI dbc for MINGW (gcc) on Windows
REM $Id$
REM by DF7BE
REM 2019-09-09

rem configure installation path of Harbour and gcc to your own needs
rem set HB_PATH=c:\harbour_v3
REM set HRB_DIR=%HB_Path%
SET HRB_DIR=C:\harbour\core-master
REM
set HRB_LIBS=%HRB_DIR%\lib\win\mingw
set HRB_EXE=%HRB_DIR%\bin\win\mingw\harbour.exe
REM configure HWGUI install (current dir is utils\designer )
set HWGUI_INSTALL=..\..



REM   gcc -I. -I%HRB_DIR%\include -Wall -c  hctrl.c -o  hctrl.o
   
REM compling resource file
REM echo 1 24 "..\..\image\WindowsXP.Manifest" > hwgui_xp.rc
REM no effect visible

REM and link
hbmk2 dbchw dbchw.rc -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui


REM ======= EOF of blddbcgw.bat =========
