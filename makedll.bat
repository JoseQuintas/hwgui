rem @echo off
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
   del lib\*.dll
   del lib\*.lib
   del lib\*.tds
   del obj\dll\*.obj
   del obj\dll\*.c
   del obj\dll\*.res
   del obj\lib\*.obj
   del obj\lib\*.c
   del obj\lib\*.res
   del makedll.log

   goto EXIT

:EXIT

