@echo off

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..\..

%HRB_DIR%\bin\harbour dbchw.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -dRDD_LETO
%HRB_DIR%\bin\harbour commands.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -dRDD_LETO
%HRB_DIR%\bin\harbour modistru.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -dRDD_LETO
%HRB_DIR%\bin\harbour move.prg -n -b -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -dRDD_LETO
%HRB_DIR%\bin\harbour view.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -dRDD_LETO

   bcc32 -c -O2 -tW -M -I%HRB_DIR%\include dbchw.c commands.c modistru.c move.c view.c procs_c.c

   brc32 -r dbchw.rc
   echo 1 24 "..\..\image\WindowsXP.Manifest" > hwgui_xp.rc
   brc32 -r hwgui_xp -fohwgui_xp

echo c0w32.obj + > b32.bc
echo dbchw.obj + >> b32.bc
echo commands.obj + >> b32.bc
echo modistru.obj + >> b32.bc
echo move.obj + >> b32.bc
echo view.obj + >> b32.bc
echo procs_c.obj, + >> b32.bc
echo dbchwl.exe, + >> b32.bc
echo dbchwl.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgdebug.lib + >> b32.bc

if exist %HRB_DIR%\lib\hbvm.lib goto hrb

echo %HRB_DIR%\lib\rtl.lib + >> b32.bc
echo %HRB_DIR%\lib\vm.lib + >> b32.bc
echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
echo %HRB_DIR%\lib\lang.lib + >> b32.bc
echo %HRB_DIR%\lib\codepage.lib + >> b32.bc
echo %HRB_DIR%\lib\macro.lib + >> b32.bc
echo %HRB_DIR%\lib\rdd.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfntx.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfcdx.lib + >> b32.bc
echo %HRB_DIR%\lib\dbffpt.lib + >> b32.bc
echo %HRB_DIR%\lib\common.lib + >> b32.bc
echo %HRB_DIR%\lib\debug.lib + >> b32.bc
echo %HRB_DIR%\lib\pp.lib + >> b32.bc
echo %HRB_DIR%\lib\hsx.lib + >> b32.bc
echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc
if exist %HRB_DIR%\lib\pcrepos.lib echo %HRB_DIR%\lib\pcrepos.lib + >> b32.bc
goto common

:hrb
echo %HRB_DIR%\lib\hbrtl.lib + >> b32.bc
echo %HRB_DIR%\lib\hbvm.lib + >> b32.bc
echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
echo %HRB_DIR%\lib\hblang.lib + >> b32.bc
echo %HRB_DIR%\lib\hbcpage.lib + >> b32.bc
echo %HRB_DIR%\lib\hbmacro.lib + >> b32.bc
echo %HRB_DIR%\lib\hbrdd.lib + >> b32.bc
echo %HRB_DIR%\lib\rddntx.lib + >> b32.bc
echo %HRB_DIR%\lib\rddcdx.lib + >> b32.bc
echo %HRB_DIR%\lib\rddfpt.lib + >> b32.bc
echo %HRB_DIR%\lib\rddleto.lib + >> b32.bc
echo %HRB_DIR%\lib\hbcommon.lib + >> b32.bc
echo %HRB_DIR%\lib\hbdebug.lib + >> b32.bc
echo %HRB_DIR%\lib\hbpp.lib + >> b32.bc
echo %HRB_DIR%\lib\hbhsx.lib + >> b32.bc
echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbpcre.lib echo %HRB_DIR%\lib\hbpcre.lib + >> b32.bc

:common

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
echo dbchw.res + >> b32.bc
echo hwgui_xp.res >> b32.bc
ilink32 -Gn -aa -Tpe @b32.bc

del *.tds
del dbchw.c
del commands.c
del modistru.c
del move.c
del view.c
del *.map
del *.obj
del *.res
del b32.bc
