REM 
REM hwmk.bat
REM 
REM $Id$
REM 
REM hwmk.bat
REM
REM An alternative bat to compile HWGUI programs
REM with MinGW
REM
REM remove file extension
SET PRGNAME=%~n1
REM ++++++++++++++++++++ Settings +++++++++++++++++++++
REM === Modify to your own needs ===
SET HWGUI_INSTALL=C:\hwgui\hwgui
SET MINGW=C:\MINGW32
SET HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw
REM SET GTK_DIR=C:\gtk
REM ================================

SET CCOMPILER=MinGW

hbmk2 %PRGNAME%.prg -d__MingW__  -I%HWGUI_INSTALL%\include -I..\include -L%HWGUI_INSTALL%\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui -lgdiplus
REM To add a resource file:
REM hbmk2 %PRGNAME%.prg %PRGNAME%.rc -d__MingW__  ...
REM
REM ================== EOF of hwmk.bat ===========================