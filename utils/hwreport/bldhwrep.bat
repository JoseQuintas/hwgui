@echo off

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..\..

%HRB_DIR%\bin\harbour hwreport.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour opensave.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour propert.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour printrpt.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour repexec.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include

   bcc32 -c -O2 -tW -M -I%HRB_DIR%\include hwreport.c opensave.c propert.c printrpt.c repexec.c

   brc32 -r repbuild.rc

echo c0w32.obj + > b32.bc
echo hwreport.obj + >> b32.bc
echo opensave.obj + >> b32.bc
echo propert.obj + >> b32.bc
echo printrpt.obj + >> b32.bc
echo repexec.obj, + >> b32.bc
echo hwreport.exe, + >> b32.bc
echo hwreport.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc

if exist %HRB_DIR%\lib\hbvm.lib goto hrb

echo %HRB_DIR%\lib\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
echo %HRB_DIR%\lib\lang.lib + >> b32.bc
echo %HRB_DIR%\lib\codepage.lib + >> b32.bc
echo %HRB_DIR%\lib\macro%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\rdd%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfntx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfcdx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbffpt%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\common.lib + >> b32.bc
echo %HRB_DIR%\lib\debug.lib + >> b32.bc
echo %HRB_DIR%\lib\pp.lib + >> b32.bc
echo %HRB_DIR%\lib\hsx.lib + >> b32.bc
echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc
if exist %HRB_DIR%\lib\pcrepos.lib echo %HRB_DIR%\lib\pcrepos.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbole.lib echo %HRB_DIR%\lib\hbole.lib + >> b32.bc
rem echo %HRB_DIR%\lib\libct.lib + >> b32.bc
goto common

:hrb
echo %HRB_DIR%\lib\hbrtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\hbvm%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
if exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
if not exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
echo %HRB_DIR%\lib\hblang.lib + >> b32.bc
echo %HRB_DIR%\lib\hbcpage.lib + >> b32.bc
echo %HRB_DIR%\lib\hbmacro%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\hbrdd%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\rddntx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\rddcdx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\rddfpt%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\hbcommon.lib + >> b32.bc
echo %HRB_DIR%\lib\hbdebug.lib + >> b32.bc
echo %HRB_DIR%\lib\hbpp.lib + >> b32.bc
echo %HRB_DIR%\lib\hbhsx.lib + >> b32.bc
echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc
echo %HRB_DIR%\lib\hbpcre.lib + >> b32.bc

:common

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
echo repbuild.res >> b32.bc
ilink32 -Gn -aa -Tpe @b32.bc

del *.tds
del *.c
del *.map
del *.obj
del b32.bc
del repbuild.res
