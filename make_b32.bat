@echo off
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

:BUILD

   make -fmakefile.bc  > make_b32.log
   if errorlevel 1 goto BUILD_ERR

:BUILD_OK

   goto EXIT

:BUILD_ERR

   notepad make_b32.log
   goto EXIT

:CLEAN
   del lib\*.lib
   del lib\*.bak
   del obj\lib\*.obj
   del obj\lib\*.c
   del make_b32.log

   goto EXIT

:EXIT

