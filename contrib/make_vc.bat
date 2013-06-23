@echo off
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

:BUILD

if not exist obj\vc md obj\vc
if not exist lib\vc md lib\vc

@SET VSINSTALLDIR=C:\Softools\MSVS8
@SET VCINSTALLDIR=C:\Softools\MSVS8\VC
@set PATH=C:\Softools\MSVS8\VC\BIN;C:\Softools\MSVS8\VC\PlatformSDK\bin;C:\Softools\MSVS8\Common7\IDE;C:\Softools\MSVS8\Common7\Tools;C:\Softools\MSVS8\Common7\Tools\bin;C:\Softools\MSVS8\SDK\v2.0\bin;C:\Softools\MSVS8\VC\VCPackages;%PATH%
@set INCLUDE=C:\Softools\MSVS8\VC\include;C:\Softools\MSVS8\VC\PlatformSDK\include
@set LIB=C:\Softools\MSVS8\VC\lib;C:\Softools\MSVS8\VC\PlatformSDK\lib
@set LIBPATH=C:\Softools\MSVS8\VC\lib;C:\Softools\MSVS8\VC\PlatformSDK\lib

   nmake /I /Fmakefile.vc %1 %2 %3 > make_vc.log
   if errorlevel 1 goto BUILD_ERR

:BUILD_OK

   goto EXIT

:BUILD_ERR

   notepad make_vc.log
   goto EXIT

:CLEAN
   del lib\vc\*.lib
   del lib\vc\*.bak
   del obj\vc\*.obj
   del obj\vc\*.c
   del make_vc.log

   goto EXIT

:EXIT

