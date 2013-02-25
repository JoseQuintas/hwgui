
@echo off

set HRB_DIR=%HB_PATH%
set HRB_LIBS=%HRB_DIR%\lib
rem set HWGUI_INSTALL=..

SET HB_MT=

rem SET C_DEFINES= -DHB_THREAD_SUPPORT
rem SET H_DEFINES= -DHB_THREAD_SUPPORT

SET C_DEFINES= 
SET H_DEFINES= 

if not exist obj md obj

%HRB_DIR%\bin\harbour %1.prg %H_DEFINES% -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

bcc32 -v -y -c %C_DEFINES% -O2 -tW -M -I%HRB_DIR%\include;%HWGUI_INSTALL%\include %1.c

if exist %1.rc brc32 -r %1 -foobj\%1

echo 1 24 "..\image\WindowsXP.Manifest" > obj\hwgui_xp.rc
brc32 -r obj\hwgui_xp -foobj\hwgui_xp

echo c0w32.obj + > b32.bc
echo %1.obj, + >> b32.bc
echo %1.exe, + >> b32.bc
echo %1.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwg_contrib.lib + >> b32.bc
if exist %HWGUI_INSTALL%\lib\hbactivex.lib echo %HWGUI_INSTALL%\lib\hbactivex.lib + >> b32.bc
if exist %HRB_LIBS%\hbvm.lib goto hrb

echo %HRB_LIBS%\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_LIBS%\gtgui.lib echo %HRB_LIBS%\gtgui.lib + >> b32.bc
rem if not exist %HRB_LIBS%\gtgui.lib echo %HRB_LIBS%\gtwin.lib + >> b32.bc
echo %HRB_LIBS%\gtgui.lib + >> b32.bc
echo %HRB_LIBS%\lang.lib + >> b32.bc
echo %HRB_LIBS%\codepage.lib + >> b32.bc
echo %HRB_LIBS%\macro%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\rdd%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\dbfntx%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\dbfcdx%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\dbffpt%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\common.lib + >> b32.bc
echo %HRB_LIBS%\debug.lib + >> b32.bc
echo %HRB_LIBS%\pp.lib + >> b32.bc
echo %HRB_LIBS%\hsx.lib + >> b32.bc
echo %HRB_LIBS%\hbsix.lib + >> b32.bc
if exist %HRB_LIBS%\pcrepos.lib echo %HRB_LIBS%\pcrepos.lib + >> b32.bc
if exist %HRB_LIBS%\hbole.lib echo %HRB_LIBS%\hbole.lib + >> b32.bc
rem echo %HRB_LIBS%\libct.lib + >> b32.bc
goto common

:hrb
echo %HRB_LIBS%\hbrtl%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\hbvm%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\gtwin.lib + >> b32.bc
if exist %HRB_LIBS%\gtgui.lib echo %HRB_LIBS%\gtgui.lib + >> b32.bc
if not exist %HRB_LIBS%\gtgui.lib echo %HRB_LIBS%\gtwin.lib + >> b32.bc
echo %HRB_LIBS%\hblang.lib + >> b32.bc
echo %HRB_LIBS%\hbcpage.lib + >> b32.bc
echo %HRB_LIBS%\hbmacro%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\hbrdd%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\rddntx%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\rddcdx%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\rddfpt%HB_MT%.lib + >> b32.bc
echo %HRB_LIBS%\hbcommon.lib + >> b32.bc
echo %HRB_LIBS%\hbdebug.lib + >> b32.bc
echo %HRB_LIBS%\hbpp.lib + >> b32.bc
echo %HRB_LIBS%\hbhsx.lib + >> b32.bc
echo %HRB_LIBS%\hbsix.lib + >> b32.bc
if exist %HRB_LIBS%\hbpcre.lib echo %HRB_LIBS%\hbpcre.lib + >> b32.bc
if exist %HRB_LIBS%\hbole.lib echo %HRB_LIBS%\hbole.lib + >> b32.bc
if exist %HRB_LIBS%\hbw32.lib echo %HRB_LIBS%\hbw32.lib + >> b32.bc
rem echo %HRB_LIBS%\hbct.lib + >> b32.bc

:common
echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
if exist obj\%1.res echo obj\%1.res + >> b32.bc
echo obj\hwgui_xp.res >> b32.bc
ilink32 -v -Gn -Tpe -aa @b32.bc

rem del *.tds
del %1.c
del %1.map
del %1.obj
del b32.bc
