@echo off
REM
REM bld.bat
REM
REM $Id$
REM
REM Build script for HWGUI utility hwmake for Borland C compiler
REM
REM Some images lost (not checked in)
REM See resource file:
REM PIM.ICO ==> use ok.ico instead
REM BUILD.BMP ==> use next.bmp
REM
REM Before use start environment script:
REM ..\..\samples\dev\env\pfad_bc.bat

REM Set path to BCC lib and include dir to your own needs
set BCC_LIB_DIR=C:\bcc\Lib
set BCC_INC_DIR=C:\bcc\include

REM Set path to Harbour installation to your own needs
REM
set HB_PATH=C:\harbour-bcc\core-master

set HRB_DIR=%HB_PATH%
set HRB_EXE=%HB_PATH%\bin\win\bcc\harbour.exe
set HRB_LIB_DIR=%HB_PATH%\lib\win\bcc
set HWGUI_INSTALL=..\..

SET HB_MT=

rem SET C_DEFINES= -DHB_THREAD_SUPPORT
rem SET H_DEFINES= -DHB_THREAD_SUPPORT

SET C_DEFINES= 
SET H_DEFINES= 

if not exist obj md obj

%HRB_EXE% %1.prg %H_DEFINES% -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

bcc32 -v -y -c %C_DEFINES% -O2 -tW -M -I%BCC_INC_DIR%;%HRB_DIR%\include;%HWGUI_INSTALL%\include %1.c

if exist %1.rc brc32 -r %1 -foobj\%1

echo 1 24 "..\..\image\WindowsXP.Manifest" > obj\hwgui_xp.rc
brc32 -r obj\hwgui_xp -foobj\hwgui_xp

echo c0w32.obj + > b32.bc
echo %1.obj, + >> b32.bc
echo %1.exe, + >> b32.bc
echo %1.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
REM echo %HWGUI_INSTALL%\lib\hwg_qhtm.lib + >> b32.bc
if exist %HWGUI_INSTALL%\lib\hbactivex.lib echo %HWGUI_INSTALL%\lib\hbactivex.lib + >> b32.bc
if exist %HRB_LIB_DIR%\hbvm.lib goto hrb

echo %HRB_LIB_DIR%\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\vm%HB_MT%.lib + >> b32.bc
rem if exist %HRB_LIB_DIR%\gtgui.lib echo %HRB_LIB_DIR%\gtgui.lib + >> b32.bc
rem if not exist %HRB_LIB_DIR%\gtgui.lib echo %HRB_LIB_DIR%\gtwin.lib + >> b32.bc
echo %HRB_LIB_DIR%\gtwin.lib + >> b32.bc
echo %HRB_LIB_DIR%\lang.lib + >> b32.bc
echo %HRB_LIB_DIR%\codepage.lib + >> b32.bc
echo %HRB_LIB_DIR%\macro%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\rdd%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\dbfntx%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\dbfcdx%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\dbffpt%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\common.lib + >> b32.bc
echo %HRB_LIB_DIR%\debug.lib + >> b32.bc
echo %HRB_LIB_DIR%\pp.lib + >> b32.bc
echo %HRB_LIB_DIR%\hsx.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbsix.lib + >> b32.bc
if exist %HRB_LIB_DIR%\pcrepos.lib echo %HRB_LIB_DIR%\pcrepos.lib + >> b32.bc
if exist %HRB_LIB_DIR%\hbole.lib echo %HRB_LIB_DIR%\hbole.lib + >> b32.bc
rem echo %HRB_LIB_DIR%\libct.lib + >> b32.bc
goto common

:hrb
echo %HRB_LIB_DIR%\hbrtl%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbvm%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\gtwin.lib + >> b32.bc
if exist %HRB_LIB_DIR%\gtgui.lib echo %HRB_LIB_DIR%\gtgui.lib + >> b32.bc
if not exist %HRB_LIB_DIR%\gtgui.lib echo %HRB_LIB_DIR%\gtwin.lib + >> b32.bc
echo %HRB_LIB_DIR%\hblang.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbcpage.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbmacro%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbrdd%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\rddntx%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\rddcdx%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\rddfpt%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbcommon.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbdebug.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbpp.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbhsx.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbsix.lib + >> b32.bc
if exist %HRB_LIB_DIR%\hbpcre.lib echo %HRB_LIB_DIR%\hbpcre.lib + >> b32.bc
if exist %HRB_LIB_DIR%\hbole.lib echo %HRB_LIB_DIR%\hbole.lib + >> b32.bc
if exist %HRB_LIB_DIR%\hbwin.lib echo %HRB_LIB_DIR%\hbwin.lib + >> b32.bc
if exist %HRB_LIB_DIR%\xhb.lib echo %HRB_LIB_DIR%\xhb.lib + >> b32.bc
rem echo %HRB_LIB_DIR%\hbct.lib + >> b32.bc

:common
echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
if exist obj\%1.res echo obj\%1.res + >> b32.bc
echo obj\hwgui_xp.res >> b32.bc
ilink32 -v -Gn -Tpe -aa -L%BCC_LIB_DIR% @b32.bc

rem del *.tds
del %1.c
del %1.map
del %1.obj
del b32.bc

REM ========================== EOF of bld.bat ======================

