@echo off

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..\..

%HRB_DIR%\bin\harbour example.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include

   bcc32 -c -O2 -tW -M -I%HRB_DIR%\include example.c

echo c0w32.obj + > b32.bc
echo example.obj, + >> b32.bc
echo example.exe, + >> b32.bc
echo example.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HRB_DIR%\lib\rtl.lib + >> b32.bc
echo %HRB_DIR%\lib\vm.lib + >> b32.bc
if exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
if not exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
echo %HRB_DIR%\lib\lang.lib + >> b32.bc
echo %HRB_DIR%\lib\macro.lib + >> b32.bc
echo %HRB_DIR%\lib\rdd.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfntx.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfcdx.lib + >> b32.bc
echo %HRB_DIR%\lib\dbffpt.lib + >> b32.bc
if exist %HRB_DIR%\lib\pcrepos.lib echo %HRB_DIR%\lib\pcrepos.lib + >> b32.bc
echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc
echo %HRB_DIR%\lib\hsx.lib + >> b32.bc
echo %HRB_DIR%\lib\common.lib + >> b32.bc
echo %HRB_DIR%\lib\pp.lib + >> b32.bc

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
ilink32 -Gn -aa -Tpe @b32.bc

del *.tds
del *.c
del *.map
del *.obj
del b32.bc
