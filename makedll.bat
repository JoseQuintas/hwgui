@echo off
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

:BUILD

   del *.log
   del *.@@@
   make -f makedll.bc %1 %2 %3 %4 %5 %6 > makedll.log

   if errorlevel 1 goto BUILD_ERR

:BUILD_OK

   goto EXIT

:BUILD_ERR

   notepad makedll.log
   goto EXIT

:CLEAN
   del lib\hwguidll.dll
   del lib\hwguidll.lib
   del lib\hwguidll.map
   del lib\hwguidll.tds
   del obj\dll\*.obj
   del obj\dll\*.c
   del obj\dll\*.res
   del makedll.log

:EXIT

