@echo off

set HRB_DIR=%HB_Path%
set HWGUI_INSTALL=..\..


%HRB_DIR%\bin\harbour designer.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour hctrl.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour hformgen.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour inspect.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour editor.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include

  bcc32 -c -O2 -d -I%HRB_DIR%\INCLUDE;%HWGUI_INSTALL%\include designer.c hctrl.c hformgen.c inspect.c  editor.c  %HRB_DIR%\source\vm\mainwin.c

IF EXIST designer.rc brc32 -r designer

  @echo c0w32.obj + > b32.bc
  @echo designer.obj + >> b32.bc
  @echo hctrl.obj + >> b32.bc
  @echo hformgen.obj + >> b32.bc
  @echo inspect.obj + >> b32.bc
  @echo editor.obj + >> b32.bc
  @echo mainwin.obj,+ >> b32.bc
  @echo designer.exe, + >> b32.bc
  @echo , + >> b32.bc
  @echo %HRB_DIR%\LIB\harbour-b32.lib + >> b32.bc
  @echo %HWGUI_INSTALL%\LIB\hwgui-b32.lib + >> b32.bc
  @echo cw32.lib + >> b32.bc
  @echo import32.lib, >> b32.bc

IF EXIST designer.res echo designer.res >> b32.bc
  ilink32 -Tpe -Gn -aa @b32.bc

del *.obj
del *.c
del *.tds
del b32.bc





