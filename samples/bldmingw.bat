@echo off 
REM
REM hwmk.bat
REM
REM $Id$
REM
REM Batch file compiling single sample prg with HWGUI
REM by DF7BE
REM
REM Modify path to your own needs
REM
SET HWGUI_INSTALL=..
SET MINGW=C:\hmg.3.3.1\MINGW
SET HRB_DIR=C:\harbour\core-master
SET HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw
REM Optional
REM SET GTK_DIR=C:\gtk 
REM
REM SET HWGUI_INSTALL=C:\hwgui\hwgui
REM SET MINGW=C:\hmg.3.3.1\MINGW
REM SET HRB_DIR=C:\hmg.3.3.1\HARBOUR
REM SET HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw
REM SET GTK_DIR=C:\gtk


hbmk2 %1 hwgui_xp.rc -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui
REM ---- EOF of hwmk.bat ----