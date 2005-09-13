@echo off
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist lib md lib
if not exist obj md obj


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
   del obj\*.obj
   del obj\*.c
   del make_b32.log

   goto EXIT

:EXIT

