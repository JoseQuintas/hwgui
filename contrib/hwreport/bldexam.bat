@echo off
REM
REM Build script HWGUI hwreport sample program for Borland C Compiler
REM
REM $Id$
REM
REM Before usage, start environment script:
REM ..\..\samples\dev\env\pfad_bc.bat
REM
REM Modify path to BCC, Harbour and HWGUI your own needs
SET BCC_INCLUDE=%CCOMP%\include
SET BCC_LIB_DIR=%CCOMP%\Lib
set HB_PATH=C:\harbour-bcc\core-master
set HRB_DIR=%HB_PATH%
set HRB_EXE=%HB_PATH%\bin\win\bcc\harbour.exe
set HRB_LIB_DIR=%HB_PATH%\lib\win\bcc
REM

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..\..

%HRB_EXE% example.prg repexec.prg -n -I%HRB_DIR%\include;%HWGUI_INSTALL%\include

   bcc32 -c -O2 -tW -M -I%BCC_INCLUDE% -I%HRB_DIR%\include example.c repexec.c

echo c0w32.obj + > b32.bc
echo example.obj + >> b32.bc
echo repexec.obj, + >> b32.bc
echo example.exe, + >> b32.bc
echo example.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
if exist %HRB_LIB_DIR%\hbvm.lib goto hrb

echo %HRB_LIB_DIR%\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_LIB_DIR%\gtgui.lib echo %HRB_LIB_DIR%\gtgui.lib + >> b32.bc
echo %HRB_LIB_DIR%\gtgui.lib + >> b32.bc
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

:common
echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc
ilink32 -Gn -aa -Tpe -L%BCC_LIB_DIR% @b32.bc

del *.tds
del *.c
del *.map
del *.obj
del b32.bc

REM ====================== EOF of bldexam.bat ===========================
