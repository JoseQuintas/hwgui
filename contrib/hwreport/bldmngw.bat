@echo off
REM build HWGUI hwreport for MinGW32 on Windows
REM $Id$
REM by DF7BE
REM 2020-07-01

REM before use, set environment with script:
REM ..\..\samples\dev\env\pfad.bat

REM Ignore warning:
REM Warning! W1008: cannot open hbactivex.lib : No such file or directory

REM Some images lost (not checked in)
REM See resource file:
REM PIM.ICO ==> use ok.ico instead
REM BUILD.BMP ==> use next.bmp

REM configure installation path of Harbour to your own needs
SET HRB_DIR=C:\Harbour\core-master
REM
REM HRB_LIBS=%HRB_DIR%\lib\win\watcom
set HRB_LIB_DIR=%HB_PATH%\lib\win\mingw
set HRB_EXE=%HRB_DIR%\bin\win\mingw\harbour.exe
REM configure HWGUI install
set HWGUI_INSTALL=..\..
SET HWG_LIBS=-lhwgui -lprocmisc -lhbxml -lhwgdebug

REM %XHB%

hbmk2 hwreport2.hbp repbuild2.rc -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib %HWG_LIBS% -gui

REM ======= EOF of bldmngw.bat =========
