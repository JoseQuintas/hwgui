
@echo off

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..

SET HB_MT=

rem SET C_DEFINES= -DHB_THREAD_SUPPORT
rem SET H_DEFINES= -DHB_THREAD_SUPPORT

SET C_DEFINES= 
SET H_DEFINES= 

if not exist obj md obj

%HRB_DIR%\bin\harbour %1.prg %H_DEFINES% -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

bcc32  -c %C_DEFINES% -O2 -tW -M -I%HRB_DIR%\include;%HWGUI_INSTALL%\include %1.c

IF EXIST %1.rc brc32 -r %1 -foobj\%1

echo 1 24 "..\image\WindowsXP.Manifest" > obj\hwgui_xp.rc
brc32 -r obj\hwgui_xp -foobj\hwgui_xp

echo c0w32.obj + > b32.bc
echo %1.obj, + >> b32.bc
echo %1.exe, + >> b32.bc
echo %1.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwg_qhtm.lib + >> b32.bc
echo %HRB_DIR%\lib\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\vm%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
echo %HRB_DIR%\lib\lang.lib + >> b32.bc
echo %HRB_DIR%\lib\codepage.lib + >> b32.bc
echo %HRB_DIR%\lib\macro%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\rdd%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfntx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfcdx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfdbt%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\common.lib + >> b32.bc
echo %HRB_DIR%\lib\debug.lib + >> b32.bc
echo %HRB_DIR%\lib\pp.lib + >> b32.bc
rem echo %HRB_DIR%\lib\libct.lib + >> b32.bc

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
IF EXIST obj\%1.res echo obj\%1.res + >> b32.bc
echo obj\hwgui_xp.res >> b32.bc
ilink32 -Gn -Tpe -aa @b32.bc

del *.tds
del %1.c
del %1.map
del %1.obj
rem del b32.bc
