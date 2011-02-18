@echo off

set HRB_DIR=%HB_Path%
set HWGUI_INSTALL=..\..

%HRB_DIR%\bin\harbour designer.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour hctrl.prg -w  -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour hformgen.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour inspect.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour editor.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include

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


rem echo %HRB_DIR%\lib\richgui.lib + >> b32.bc

echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
if exist %HRB_DIR%\lib\rtl%HB_MT%.lib echo %HRB_DIR%\lib\rtl%HB_MT%.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbrtl%HB_MT%.lib echo %HRB_DIR%\lib\hbrtl%HB_MT%.lib + >> b32.bc
if exist %HRB_DIR%\lib\vm%HB_MT%.lib echo %HRB_DIR%\lib\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbvm.lib echo %HRB_DIR%\lib\hbvm.lib + >> b32.bc
if exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
if exist %HRB_DIR%\lib\gtwin.lib echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
if exist %HRB_DIR%\lib\lang.lib echo %HRB_DIR%\lib\lang.lib + >> b32.bc
if exist %HRB_DIR%\lib\hblang.lib echo %HRB_DIR%\lib\hblang.lib + >> b32.bc
if exist %HRB_DIR%\lib\codepage.lib echo %HRB_DIR%\lib\codepage.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbcpage.lib echo %HRB_DIR%\lib\hbcpage.lib + >> b32.bc
if exist %HRB_DIR%\lib\macro%HB_MT%.lib echo %HRB_DIR%\lib\macro%HB_MT% + >> b32.bc
if exist %HRB_DIR%\lib\hbmacro.lib echo %HRB_DIR%\lib\hbmacro.lib + >> b32.bc

rem echo %HRB_DIR%\lib\rddleto.lib + >> b32.bc

if exist %HRB_DIR%\lib\rdd%HB_MT%.lib echo %HRB_DIR%\lib\rdd%HB_MT% + >> b32.bc
if exist %HRB_DIR%\lib\hbrdd.lib echo %HRB_DIR%\lib\hbrdd.lib + >> b32.bc
if exist %HRB_DIR%\lib\dbfntx%HB_MT%.lib echo %HRB_DIR%\lib\dbfntx%HB_MT% + >> b32.bc
if exist %HRB_DIR%\lib\rddntx.lib echo %HRB_DIR%\lib\rddntx.lib + >> b32.bc
if exist %HRB_DIR%\lib\dbfcdx%HB_MT%.lib echo %HRB_DIR%\lib\dbfcdx%HB_MT% + >> b32.bc
if exist %HRB_DIR%\lib\rddcdx.lib echo %HRB_DIR%\lib\rddcdx.lib + >> b32.bc
if exist %HRB_DIR%\lib\dbffpt%HB_MT%.lib echo %HRB_DIR%\lib\dbffpt%HB_MT% + >> b32.bc
if exist %HRB_DIR%\lib\rddfpt.lib echo %HRB_DIR%\lib\rddfpt.lib + >> b32.bc
if exist %HRB_DIR%\lib\sixcdx%HB_MT%.lib echo %HRB_DIR%\lib\sixcdx%HB_MT% + >> b32.bc
if exist %HRB_DIR%\lib\hbsix.lib echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc
if exist %HRB_DIR%\lib\common.lib echo %HRB_DIR%\lib\common + >> b32.bc
if exist %HRB_DIR%\lib\hbcommon.lib echo %HRB_DIR%\lib\hbcommon.lib + >> b32.bc
if exist %HRB_DIR%\lib\debug.lib echo %HRB_DIR%\lib\debug.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbdebug.lib echo %HRB_DIR%\lib\hbdebug.lib + >> b32.bc
if exist %HRB_DIR%\lib\pp.lib echo %HRB_DIR%\lib\pp.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbpp.lib echo %HRB_DIR%\lib\hbpp.lib + >> b32.bc
if exist %HRB_DIR%\lib\hsx.lib echo %HRB_DIR%\lib\hsx.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbhsx.lib echo %HRB_DIR%\lib\hbhsx.lib + >> b32.bc
echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc

rem echo %HRB_DIR%\lib\rddads.lib + >> b32.bc
rem echo ace32.lib + >> b32.bc

if exist %HRB_DIR%\lib\pcrepos.lib echo %HRB_DIR%\lib\pcrepos.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbpcre.lib echo %HRB_DIR%\lib\hbpcre.lib + >> b32.bc
if exist %HRB_DIR%\lib\zlib.lib echo %HRB_DIR%\lib\zlib.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbzlib.lib echo %HRB_DIR%\lib\hbzlib.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbw32.lib echo %HRB_DIR%\lib\hbw32.lib + >> b32.bc
if exist %HRB_DIR%\lib\hbwin.lib echo %HRB_DIR%\lib\hbwin.lib + >> b32.bc
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
