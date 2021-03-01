@echo off

rem set HB_PATH=c:\harbour_v3
set HRB_DIR=%HB_Path%
set HRB_LIBS=%HRB_DIR%\lib\win\bcc
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

echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
if exist %HRB_LIBS%\rtl%HB_MT%.lib echo %HRB_LIBS%\rtl%HB_MT%.lib + >> b32.bc
if exist %HRB_LIBS%\hbrtl%HB_MT%.lib echo %HRB_LIBS%\hbrtl%HB_MT%.lib + >> b32.bc
if exist %HRB_LIBS%\vm%HB_MT%.lib echo %HRB_LIBS%\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_LIBS%\hbvm.lib echo %HRB_LIBS%\hbvm.lib + >> b32.bc
if exist %HRB_LIBS%\gtgui.lib echo %HRB_LIBS%\gtgui.lib + >> b32.bc
if exist %HRB_LIBS%\gtwin.lib echo %HRB_LIBS%\gtwin.lib + >> b32.bc
if exist %HRB_LIBS%\lang.lib echo %HRB_LIBS%\lang.lib + >> b32.bc
if exist %HRB_LIBS%\hblang.lib echo %HRB_LIBS%\hblang.lib + >> b32.bc
if exist %HRB_LIBS%\codepage.lib echo %HRB_LIBS%\codepage.lib + >> b32.bc
if exist %HRB_LIBS%\hbcpage.lib echo %HRB_LIBS%\hbcpage.lib + >> b32.bc
if exist %HRB_LIBS%\macro%HB_MT%.lib echo %HRB_LIBS%\macro%HB_MT% + >> b32.bc
if exist %HRB_LIBS%\hbmacro.lib echo %HRB_LIBS%\hbmacro.lib + >> b32.bc

rem echo %HRB_LIBS%\rddleto.lib + >> b32.bc

if exist %HRB_LIBS%\rdd%HB_MT%.lib echo %HRB_LIBS%\rdd%HB_MT% + >> b32.bc
if exist %HRB_LIBS%\hbrdd.lib echo %HRB_LIBS%\hbrdd.lib + >> b32.bc
if exist %HRB_LIBS%\dbfntx%HB_MT%.lib echo %HRB_LIBS%\dbfntx%HB_MT% + >> b32.bc
if exist %HRB_LIBS%\rddntx.lib echo %HRB_LIBS%\rddntx.lib + >> b32.bc
if exist %HRB_LIBS%\dbfcdx%HB_MT%.lib echo %HRB_LIBS%\dbfcdx%HB_MT% + >> b32.bc
if exist %HRB_LIBS%\rddcdx.lib echo %HRB_LIBS%\rddcdx.lib + >> b32.bc
if exist %HRB_LIBS%\dbffpt%HB_MT%.lib echo %HRB_LIBS%\dbffpt%HB_MT% + >> b32.bc
if exist %HRB_LIBS%\rddfpt.lib echo %HRB_LIBS%\rddfpt.lib + >> b32.bc
if exist %HRB_LIBS%\sixcdx%HB_MT%.lib echo %HRB_LIBS%\sixcdx%HB_MT% + >> b32.bc
if exist %HRB_LIBS%\hbsix.lib echo %HRB_LIBS%\hbsix.lib + >> b32.bc
if exist %HRB_LIBS%\rddnsx.lib echo %HRB_LIBS%\rddnsx.lib + >> b32.bc
if exist %HRB_LIBS%\common.lib echo %HRB_LIBS%\common + >> b32.bc
if exist %HRB_LIBS%\hbcommon.lib echo %HRB_LIBS%\hbcommon.lib + >> b32.bc
if exist %HRB_LIBS%\debug.lib echo %HRB_LIBS%\debug.lib + >> b32.bc
if exist %HRB_LIBS%\hbdebug.lib echo %HRB_LIBS%\hbdebug.lib + >> b32.bc
if exist %HRB_LIBS%\pp.lib echo %HRB_LIBS%\pp.lib + >> b32.bc
if exist %HRB_LIBS%\hbpp.lib echo %HRB_LIBS%\hbpp.lib + >> b32.bc
if exist %HRB_LIBS%\hsx.lib echo %HRB_LIBS%\hsx.lib + >> b32.bc
if exist %HRB_LIBS%\hbhsx.lib echo %HRB_LIBS%\hbhsx.lib + >> b32.bc
echo %HRB_LIBS%\hbsix.lib + >> b32.bc

rem echo %HRB_LIBS%\rddads.lib + >> b32.bc
rem echo ace32.lib + >> b32.bc

if exist %HRB_LIBS%\pcrepos.lib echo %HRB_LIBS%\pcrepos.lib + >> b32.bc
if exist %HRB_LIBS%\hbpcre.lib echo %HRB_LIBS%\hbpcre.lib + >> b32.bc
if exist %HRB_LIBS%\zlib.lib echo %HRB_LIBS%\zlib.lib + >> b32.bc
if exist %HRB_LIBS%\hbzlib.lib echo %HRB_LIBS%\hbzlib.lib + >> b32.bc
if exist %HRB_LIBS%\hbw32.lib echo %HRB_LIBS%\hbw32.lib + >> b32.bc
if exist %HRB_LIBS%\hbwin.lib echo %HRB_LIBS%\hbwin.lib + >> b32.bc
rem echo %HRB_LIBS%\libct.lib + >> b32.bc

echo cw32.lib + >> b32.bc
echo ws2_32.lib + >> b32.bc
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
