@echo off

set HB_INSTALL=%HB_PATH%
set HWGUI_INSTALL=..\..

%HB_INSTALL%\bin\harbour editor.prg    -n -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include
%HB_INSTALL%\bin\harbour fclass1.prg -n -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include
%HB_INSTALL%\bin\harbour ft_funcs.prg -n -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include
%HB_INSTALL%\bin\harbour ffile1.prg     -n -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include
%HB_INSTALL%\bin\harbour pesqtext.prg    -n -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include

   bcc32 -c -O2 -tW -M -I%HB_INSTALL%\include editor.c fclass1.c ft_funcs.c ffile1.c pesqtext.c

   brc32 -r editor.rc

echo c0w32.obj + > b32.bc
echo editor.obj + >> b32.bc
echo fclass1.obj + >> b32.bc
echo ft_funcs.obj + >> b32.bc
echo ffile1.obj + >> b32.bc
echo pesqtext.obj, + >> b32.bc
echo hwedit.exe, + >> b32.bc
echo editor.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HB_INSTALL%\lib\rtl.lib + >> b32.bc
echo %HB_INSTALL%\lib\vm.lib + >> b32.bc
echo %HB_INSTALL%\lib\gtwin.lib + >> b32.bc
echo %HB_INSTALL%\lib\lang.lib + >> b32.bc
echo %HB_INSTALL%\lib\macro.lib + >> b32.bc
echo %HB_INSTALL%\lib\rdd.lib + >> b32.bc
echo %HB_INSTALL%\lib\dbfntx.lib + >> b32.bc
echo %HB_INSTALL%\lib\dbfdbt.lib + >> b32.bc
echo %HB_INSTALL%\lib\common.lib + >> b32.bc
echo %HB_INSTALL%\lib\pp.lib + >> b32.bc

echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
echo editor.res >> b32.bc
ilink32 -Gn -aa -Tpe @b32.bc

del *.tds
del *.c
del *.map
del *.obj
del *.res
del b32.bc
