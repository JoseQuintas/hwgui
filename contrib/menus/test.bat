set HB_INSTALL=\harbour
set HWGUI_INSTALL=\hwgui

%HB_INSTALL%\bin\harbour test.prg -n -p -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include %2 %3
%HB_INSTALL%\bin\harbour hwindow.prg -n -p -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include %2 %3
%HB_INSTALL%\bin\harbour menu.prg -n -p -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include %2 %3

bcc32 -c -O2 -tW -M -I%HB_INSTALL%\include;%HWGUI_INSTALL%\include test.c
bcc32 -c -O2 -tW -M -I%HB_INSTALL%\include;%HWGUI_INSTALL%\include hwindow.c
bcc32 -c -O2 -tW -M -I%HB_INSTALL%\include;%HWGUI_INSTALL%\include menu.c

IF EXIST test.rc brc32 -r test

echo c0w32.obj + > b32.bc
echo test.obj+hwindow.obj+menu.obj, + >> b32.bc
echo test.exe, + >> b32.bc
echo test.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwg_qhtm.lib + >> b32.bc
echo %HB_INSTALL%\lib\rtl.lib + >> b32.bc
echo %HB_INSTALL%\lib\vm.lib + >> b32.bc
echo %HB_INSTALL%\lib\gtwin.lib + >> b32.bc
echo %HB_INSTALL%\lib\lang.lib + >> b32.bc
echo %HB_INSTALL%\lib\codepage.lib + >> b32.bc
echo %HB_INSTALL%\lib\macro.lib + >> b32.bc
echo %HB_INSTALL%\lib\rdd.lib + >> b32.bc
echo %HB_INSTALL%\lib\dbfntx.lib + >> b32.bc
echo %HB_INSTALL%\lib\dbfdbt.lib + >> b32.bc
echo %HB_INSTALL%\lib\dbfcdx.lib + >> b32.bc
echo %HB_INSTALL%\lib\common.lib + >> b32.bc
echo %HB_INSTALL%\lib\debug.lib + >> b32.bc
echo %HB_INSTALL%\lib\pp.lib + >> b32.bc
echo %HB_INSTALL%\lib\libct.lib + >> b32.bc

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
IF EXIST test.res echo test.res >> b32.bc
ilink32 -Gn -Tpe -aa @b32.bc

del *.tds
del *.c
del *.map
del *.obj
del b32.bc

pause
