@echo off

set HRB_DIR=%HB_Path%
set HWGUI_INSTALL=..\..

%HRB_DIR%\bin\harbour designer.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -DINTEGRATED -DMODAL
%HRB_DIR%\bin\harbour hctrl.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour hformgen.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour inspect.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_DIR%\bin\harbour editor.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include

   bcc32 -c -O2 -tW -M -I%HRB_DIR%\include designer.c hctrl.c hformgen.c inspect.c editor.c
   del %HWGUI_INSTALL%\lib\designer.lib
   tlib %HWGUI_INSTALL%\lib\designer +designer +hctrl +hformgen +inspect +editor

del designer.c
del hctrl.c
del hformgen.c
del inspect.c
del editor.c
del *.obj
