@echo off

set HRB_DIR=%HB_Path%
set HWGUI_INSTALL=..\..

%HRB_DIR%\bin\harbour designer.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour hctrl.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour hformgen.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour inspect.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour editor.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include

   bcc32 -c -O2 -tW -M -I%HRB_DIR%\include designer.c hctrl.c hformgen.c inspect.c editor.c
   brc32 -r designer.rc

echo c0w32.obj + > b32.bc
echo designer.obj + >> b32.bc
echo hctrl.obj + >> b32.bc
echo hformgen.obj + >> b32.bc
echo inspect.obj + >> b32.bc
echo editor.obj, + >> b32.bc
echo designer.exe, + >> b32.bc
echo designer.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
echo %HRB_DIR%\lib\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
if not exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
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
rem echo %HRB_DIR%\lib\libct.lib + >> b32.bc

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
echo designer.res >> b32.bc
ilink32 -Gn -aa -Tpe @b32.bc

del *.tds
del designer.c
del hctrl.c
del hformgen.c
del inspect.c
del editor.c
del *.map
del *.obj
del designer.res
del b32.bc
