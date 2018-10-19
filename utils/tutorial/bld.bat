@echo off
rem set HRB_DIR=c:\harbour_v3
set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..\..
set HWGUI_LIBS=hwgui.lib hbxml.lib procmisc.lib

if exist %HRB_DIR%\lib\win\bcc\hbvm.lib goto hrb
set HRB_LIBS=vm.lib rtl.lib gtgui.lib gtwin.lib codepage.lib lang.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib hsx.lib hbsix.lib common.lib ct.lib
goto common
:hrb
set HRB_LIBS=hbvm.lib hbrtl.lib gtgui.lib gtwin.lib hbcpage.lib hblang.lib hbrdd.lib hbmacro.lib hbpp.lib rddntx.lib rddcdx.lib rddfpt.lib hbsix.lib hbcommon.lib hbct.lib hbcplr.lib
:common

%HRB_DIR%\bin\harbour tutor.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

echo 1 24 "..\..\image\WindowsXP.Manifest" > hwgui_xp.rc
brc32 -r hwgui_xp -fohwgui_xp

bcc32 -c -O2 -tW -M -I%HRB_DIR%\include tutor.c  
ilink32 -Gn -aa -Tpe -L%HRB_DIR%\lib\win\bcc;%HWGUI_INSTALL%\lib c0w32.obj tutor.obj, tutor.exe, tutor.map, %HWGUI_LIBS% %HRB_LIBS% ws2_32.lib cw32.lib import32.lib,, hwgui_xp.res

%HRB_DIR%\bin\harbour hwgrun.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

bcc32 -c -O2 -tW -M -I%HRB_DIR%\include hwgrun.c
ilink32 -Gn -aa -Tpe -L%HRB_DIR%\lib\win\bcc;%HWGUI_INSTALL%\lib c0w32.obj hwgrun.obj, hwgrun.exe, hwgrun.map, %HWGUI_LIBS% %HRB_LIBS% ws2_32.lib cw32.lib import32.lib,, hwgui_xp.res

del *.obj
del *.c
del *.map
del hwgui_xp.rc
del *.res
del *.tds