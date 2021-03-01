@echo off
REM
REM Build script HWGUI hwreport for Borland C Compiler
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
set HWGUI_INSTALL=..\..

%HRB_EXE% hwreport.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_EXE% opensave.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_EXE% propert.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_EXE% printrpt.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
%HRB_EXE% repexec.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include

   bcc32 -c -O2 -tW -M -I%BCC_INCLUDE% -I%HRB_DIR%\include hwreport.c opensave.c propert.c printrpt.c repexec.c

   brc32 -r repbuild.rc

echo %BCC_LIB_DIR%\c0w32.obj + > b32.bc
echo hwreport.obj + >> b32.bc
echo opensave.obj + >> b32.bc
echo propert.obj + >> b32.bc
echo printrpt.obj + >> b32.bc
echo repexec.obj, + >> b32.bc
echo hwreport.exe, + >> b32.bc
echo hwreport.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc

if exist %HRB_LIB_DIR%\hbvm.lib goto hrb

echo %HRB_LIB_DIR%\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_LIB_DIR%\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_LIB_DIR%\gtgui.lib echo %HRB_LIB_DIR%\gtgui.lib + >> b32.bc
echo %HRB_LIB_DIR%\gtgui.lib + >> b32.bc
echo %HRB_LIB_DIR%\lang.lib + >> b32.bc
echo %HRB_LIB_DIR%\hbcpage.lib + >> b32.bc
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
if not exist %HRB_LIB_DIR%\gtgui.lib echo %HRB_LIB_DIR%\lib\gtwin.lib + >> b32.bc
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
echo %HRB_LIB_DIR%\hbpcre.lib + >> b32.bc

:common

echo %BCC_LIB_DIR%\cw32.lib + >> b32.bc
echo %BCC_LIB_DIR%\import32.lib, >> b32.bc
echo repbuild.res >> b32.bc
ilink32 -Gn -aa -Tpe -L%BCC_LIB_DIR% @b32.bc

del *.tds
del *.c
del *.map
del *.obj
del b32.bc
del repbuild.res

REM ====================== EOF of bldhwrep.bat =========================
