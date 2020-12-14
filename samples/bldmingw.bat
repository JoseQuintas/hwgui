@echo off 
REM
REM bldmingw.bat
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
SET HBWINBC=%HRB_DIR%\contrib\hbwin.hbc
REM Optional
REM SET GTK_DIR=C:\gtk 
REM
REM SET HWGUI_INSTALL=C:\hwgui\hwgui
REM SET MINGW=C:\hmg.3.3.1\MINGW
REM SET HRB_DIR=C:\hmg.3.3.1\HARBOUR
REM SET HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw
REM SET GTK_DIR=C:\gtk

REM Standard HWGUI libs
SET HWGUI_LIBS=-lhwgui -lprocmisc -lhbxml -lhwgdebug -gui

REM Add contrib libs, if available
if exist %HWGUI_INSTALL%\lib\libhwg_extctrl.a (
SET HWGUI_LIBS=%HWGUI_LIBS% -lhwg_extctrl 
)

if exist %HWGUI_INSTALL%\lib\libhwg_misc.a (
SET HWGUI_LIBS=%HWGUI_LIBS% -lhwg_misc
)

if exist %HWGUI_INSTALL%\lib\libhwg_qhtm.a (
SET HWGUI_LIBS=%HWGUI_LIBS% -lhwg_qhtm
)

REM -trace : see commands for debugging
REM hbmk2 %1 hwgui_xp.rc %HBWINBC% -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib %HWGUI_LIBS%

REM If you get this message
REM hbmk2: Hint: Add option 'hbwin.hbc' for missing function(s):
REM       win_oleCreateObject()
REM activate the following command for compile: 
hbmk2 %1 hwgui_xp.rc %HBWINBC% -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib %HWGUI_LIBS%

REM ---- EOF of bldmingw.bat ----
