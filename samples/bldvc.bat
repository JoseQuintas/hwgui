@echo off

set HRB_DIR=\harbour
set HWGUI_INSTALL=..

@SET VSINSTALLDIR=C:\Softools\MSVS8
@SET VCINSTALLDIR=C:\Softools\MSVS8\VC
@set PATH=C:\Softools\MSVS8\VC\BIN;C:\Softools\MSVS8\VC\PlatformSDK\bin;C:\Softools\MSVS8\Common7\IDE;C:\Softools\MSVS8\Common7\Tools;C:\Softools\MSVS8\Common7\Tools\bin;C:\Softools\MSVS8\SDK\v2.0\bin;C:\Softools\MSVS8\VC\VCPackages;%PATH%
@set INCLUDE=C:\Softools\MSVS8\VC\include;C:\Softools\MSVS8\VC\PlatformSDK\include
@set LIB=C:\Softools\MSVS8\VC\lib;C:\Softools\MSVS8\VC\PlatformSDK\lib
@set LIBPATH=C:\Softools\MSVS8\VC\lib;C:\Softools\MSVS8\VC\PlatformSDK\lib

%HRB_DIR%\bin\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

cl /c /TP /W3 /nologo /Fo -I%HRB_DIR%\include -I%HWGUI_INSTALL%\include %1.c


echo %HWGUI_INSTALL%\lib\vc\hwgui.lib  > b32.vc
echo %HWGUI_INSTALL%\lib\vc\procmisc.lib  >> b32.vc
echo %HWGUI_INSTALL%\lib\vc\hbxml.lib  >> b32.vc
echo %HRB_DIR%\lib\vc\rtl.lib  >> b32.vc
echo %HRB_DIR%\lib\vc\vm.lib  >> b32.vc
echo %HRB_DIR%\lib\vc\gtgui.lib >> b32.vc
echo %HRB_DIR%\lib\vc\lang.lib  >> b32.vc
echo %HRB_DIR%\lib\vc\macro.lib >> b32.vc
echo %HRB_DIR%\lib\vc\rdd.lib  >> b32.vc
echo %HRB_DIR%\lib\vc\dbfntx.lib >> b32.vc
echo %HRB_DIR%\lib\vc\dbffpt.lib >> b32.vc
echo %HRB_DIR%\lib\vc\common.lib >> b32.vc
echo %HRB_DIR%\lib\vc\debug.lib >> b32.vc
echo %HRB_DIR%\lib\vc\pp.lib >> b32.vc
echo %HRB_DIR%\lib\vc\hbsix.lib >> b32.vc
echo user32.lib >> b32.vc
echo gdi32.lib >> b32.vc
echo comdlg32.lib >> b32.vc
echo shell32.lib  >> b32.vc
echo comctl32.lib >> b32.vc
echo winspool.lib >> b32.vc
echo OleAut32.Lib >> b32.vc
echo Ole32.Lib >> b32.vc

rem IF EXIST %1.rc brc32 -r %1
link -SUBSYSTEM:WINDOWS %1.obj @b32.vc
del %1.c
rem del %1.map
del %1.obj
del b32.vc