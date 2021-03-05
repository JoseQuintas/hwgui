@echo off
REM
REM Build script HWGUI sample for Borland C Compiler
REM
REM $Id$
REM
REM
REM Before usage, start environment script:
REM ..\..\samples\dev\env\pfad_bc.bat
REM Modify this to your own needs
REM (location of BCC and Harbour installation)
REM
REM usage:
REM bld.bat <program name without extension .prg>
REM

SET BCC_LIB_DIR=%CCOMP%\lib

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..

SET HB_MT=

SET INCLUDE=%CCOMP%\include

rem SET C_DEFINES= -DHB_THREAD_SUPPORT
rem SET H_DEFINES= -DHB_THREAD_SUPPORT

SET C_DEFINES= 
SET H_DEFINES= 

if not exist obj md obj

%HRB_DIR%\bin\win\bcc\harbour %1.prg %H_DEFINES% -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2 %3

bcc32 -v -y -c %C_DEFINES% -O2 -tW -M -I%INCLUDE%;%HRB_DIR%\include;%HWGUI_INSTALL%\include %1.c

if exist %1.rc brc32 -r %1 -foobj\%1

echo 1 24 "..\image\WindowsXP.Manifest" > obj\hwgui_xp.rc
brc32 -r obj\hwgui_xp -foobj\hwgui_xp

echo %CCOMP%\lib\c0w32.obj + > b32.bc
echo %1.obj, + >> b32.bc
echo %1.exe, + >> b32.bc
echo %1.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
REM echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
REM echo %HWGUI_INSTALL%\lib\hwgdebug.lib + >> b32.bc
if exist %HWGUI_INSTALL%\lib\hwg_qhtm.lib echo %HWGUI_INSTALL%\lib\hwg_qhtm.lib + >> b32.bc
if exist %HWGUI_INSTALL%\lib\hbactivex.lib echo %HWGUI_INSTALL%\lib\hbactivex.lib + >> b32.bc

if exist %HRB_DIR%\lib\win\bcc\hbvm.lib goto hrb

echo %HRB_DIR%\lib\win\bcc\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_DIR%\lib\win\bcc\gtgui.lib echo %HRB_DIR%\lib\win\bcc\gtgui.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\gtgui.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\lang.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\codepage.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\macro%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\rdd%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\dbfntx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\dbfcdx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\dbffpt%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\common.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\pp.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hsx.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbsix.lib + >> b32.bc
if exist %HRB_DIR%\lib\win\bcc\pcrepos.lib echo %HRB_DIR%\lib\win\bcc\pcrepos.lib + >> b32.bc
if exist %HRB_DIR%\lib\win\bcc\hbole.lib echo %HRB_DIR%\lib\win\bcc\hbole.lib + >> b32.bc
rem echo %HRB_DIR%\lib\win\bcc\libct.lib + >> b32.bc
goto common

:hrb
echo %HRB_DIR%\lib\win\bcc\hbrtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbvm%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\gtwin.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\gtgui.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hblang.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbcpage.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbmacro%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbrdd%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\rddntx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\rddcdx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\rddfpt%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbcommon.lib + >> b32.bc
REM added
echo %HRB_DIR%\lib\win\bcc\hbdebug.lib + >> b32.bc
REM ------
echo %HRB_DIR%\lib\win\bcc\hbpp.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbhsx.lib + >> b32.bc
echo %HRB_DIR%\lib\win\bcc\hbsix.lib + >> b32.bc

if exist %HRB_DIR%\lib\win\bcc\hbpcre.lib echo %HRB_DIR%\lib\win\bcc\hbpcre.lib + >> b32.bc
REM removed
REM if exist %HRB_DIR%\lib\win\bcc\hbwin.lib echo %HRB_DIR%\lib\win\bcc\hbwin.lib + >> b32.bc
rem echo %HRB_DIR%\lib\win\bcc\hbct.lib + >> b32.bc

:common
echo %CCOMP%\lib\cw32.lib + >> b32.bc
echo %CCOMP%\lib\import32.lib, >> b32.bc
if exist obj\%1.res echo obj\%1.res + >> b32.bc
REM Removed
REM echo obj\hwgui_xp.res >> b32.bc
ilink32 -v -Gn -aa -Tpe -L%BCC_LIB_DIR% @b32.bc

del *.tds
del %1.c
del %1.map
del %1.obj
del b32.bc

REM =============================== EOF of bld.bat ====================================
