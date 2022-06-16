@echo off
REM
REM hwmk.bat
REM $Id$
REM Batch file compiling single prg with HWGUI
REM
REM
REM remove file extension
SET PRGNAME=%~n1
REM === Modify to your own needs ===
SET HWGUI_INSTALL=C:\hwgui\hwgui
REM SET MINGW=C:\hmg.3.3.1\MINGW
SET MINGW=C:\MINGW32
SET HRB_DIR=C:\harbour\core-master
REM SET HRB_DIR=C:\hmg.3.3.1\HARBOUR
SET HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw
SET GTK_DIR=C:\gtk
REM ================================



REM compile with Harbour and HWGUI 

REM Added: -n -w
REM -w3 : Lots of warnings

hbmk2 %PRGNAME%.prg -n -w -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui -dENGLISH

REM ---- EOF of hwmk.bat ----
