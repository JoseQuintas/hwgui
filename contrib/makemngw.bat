@echo off
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist ..\lib md ..\lib
if not exist obj md obj

:BUILD

   set CFLAGS=-DHWG_USE_POINTER_ITEM

   rem set path=d:\softools\mingw\bin
   mingw32-make.exe -f makefile.gcc
   if errorlevel 1 goto BUILD_ERR

:BUILD_OK

   goto EXIT

:BUILD_ERR

   goto EXIT

:CLEAN
   del ..\lib\libhwg_misc.a 2> NUL
   del ..\lib\libhwg_qhtm.a 2> NUL
   del ..\lib\libhbactivex.a 2> NUL
   del ..\lib\libhwg_extctrl.a 2> NUL
   del ..\lib\*.bak 2> NUL
   del obj\*.o 2> NUL
   del obj\*.c 2> NUL

   goto EXIT

:EXIT
