@echo off

set HRB_DIR=\harbour
set HWGUI_INSTALL=..

%HRB_DIR%\bin\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

cl /c /TP /W3 /nologo /Fo -I%HRB_DIR%\include -I%HWGUI_INSTALL%\include %1.c


echo %HWGUI_INSTALL%\lib\hwgui.lib  > b32.vc
echo %HWGUI_INSTALL%\lib\procmisc.lib  >> b32.vc
echo %HWGUI_INSTALL%\lib\hbxml.lib  >> b32.vc
echo %HRB_DIR%\lib\rtl.lib  >> b32.vc
echo %HRB_DIR%\lib\vm.lib  >> b32.vc
echo %HRB_DIR%\lib\gtwin.lib >> b32.vc
echo %HRB_DIR%\lib\lang.lib  >> b32.vc
echo %HRB_DIR%\lib\macro.lib >> b32.vc
echo %HRB_DIR%\lib\rdd.lib  >> b32.vc
echo %HRB_DIR%\lib\dbfntx.lib >> b32.vc
echo %HRB_DIR%\lib\common.lib >> b32.vc
echo %HRB_DIR%\lib\debug.lib >> b32.vc
echo %HRB_DIR%\lib\pp.lib >> b32.vc
echo user32.lib >> b32.vc
echo gdi32.lib >> b32.vc
echo comdlg32.lib >> b32.vc
echo shell32.lib  >> b32.vc
echo comctl32.lib >> b32.vc
echo winspool.lib >> b32.vc

rem IF EXIST %1.rc brc32 -r %1
link -SUBSYSTEM:WINDOWS -LIBPATH:d:\progra~1\micros~1\vc98\lib %1.obj @b32.vc
del %1.c
rem del %1.map
del %1.obj
del b32.vc