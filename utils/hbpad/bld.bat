@echo off

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..\..\
set SRC_DIR=.\
set C_PARAMS=-c -O2 -tW -M -D__WIN32__ -DHWG_USE_POINTER_ITEM

%HRB_DIR%\bin\harbour %SRC_DIR%\hbpad.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %1

bcc32 %C_PARAMS% -I%HRB_DIR%\include -I%HWGUI_INSTALL%\include hbpad.c

echo 1 24 "..\..\image\WindowsXP.Manifest" > hwgui_xp.rc
brc32 -r hwgui_xp -fohwgui_xp

echo c0w32.obj + > b32.bc
echo hbpad.obj, + >> b32.bc
echo hbpad.exe, + >> b32.bc
echo hbpad.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgdebug.lib + >> b32.bc

echo %HRB_DIR%\lib\win\bcc\hbrtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbvm%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\gtwin.lib + >> b32.bc
if exist %HRB_DIR%\lib\win\bcc\gtgui.lib echo %HRB_DIR%\lib\win\bcc\gtgui.lib + >> b32.bc
if not exist %HRB_DIR%\lib\win\bcc\gtgui.lib echo %HRB_DIR%\lib\win\bcc\gtwin.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hblang.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbcpage.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbmacro%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbrdd%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\rddntx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\rddcdx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\rddfpt%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbcommon.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbpp.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbhsx.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbsix.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbpcre.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbdebug.lib + >> b32.bc

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
echo hwgui_xp.res >> b32.bc
ilink32 -v -Gn -aa -Tpe @b32.bc

del *.tds
del hbpad.c
del *.map
del *.obj
del b32.bc
del hwgui_xp.rc
del hwgui_xp.res
