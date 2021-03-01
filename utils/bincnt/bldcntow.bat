@echo off
REM build HWGUI "Binary container manager" for OpenWatCom C  on Windows
REM $Id$
REM by DF7BE
REM 2020-06-23

REM before use, set environment with script:
REM ..\..\samples\dev\env\pfad_wc.bat

REM configure installation path of Harbour to your own needs
SET HRB_DIR=C:\Harbour_wc\core-master
REM
REM HRB_LIBS=%HRB_DIR%\lib\win\watcom
set HRB_EXE=%HRB_DIR%\bin\win\watcom\harbour.exe
REM configure HWGUI install (current dir is utils\designer )
set HWGUI_INSTALL=..\..

hbmk2 bincnt  -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui


REM ======= EOF of bldcntow.bat =========
