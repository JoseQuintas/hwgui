@echo off
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

:BUILD
   IF NOT EXIST OBJ MD OBJ
   IF NOT EXIST OBJ\DLL MD OBJ\DLL
   del makedll.log
   del *.@@@
   make -f makedll.bc %1 %2 %3 %4 %5 %6 > makedll.log

   if errorlevel 1 goto BUILD_ERR

:BUILD_OK

   goto EXIT

:BUILD_ERR

   notepad makedll.log
   goto EXIT

:CLEAN
   del lib\hwgui-b32.dll
   del lib\hwgui-b32.lib
   del lib\hwgui-b32.map
   del lib\hwgui-b32.tds
   del obj\dll\*.obj
   del obj\dll\*.c
   del obj\dll\*.res
   del makedll.log

:EXIT

