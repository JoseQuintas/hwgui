@echo off
set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=%HB_PATH%\CONTRIB\HWGUI

%HRB_DIR%\bin\harbour xmlrun.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
   bcc32 -c -O2 -tW -M -I%HRB_DIR%\include xmlrun.c

if exist xmlrun.rc brc32 -r xmlrun.rc

echo c0w32.obj + > b32.bc
echo xmlrun.obj, + >> b32.bc
echo xmlrun.exe, + >> b32.bc
echo xmlrun.map, + >> b32.bc
echo %HWGUI_INSTALL%\lib\hwgui.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\procmisc.lib + >> b32.bc
echo %HWGUI_INSTALL%\lib\hbxml.lib + >> b32.bc
echo %HRB_DIR%\lib\rtl%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\vm%HB_MT%.lib + >> b32.bc
if exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtgui.lib + >> b32.bc
if not exist %HRB_DIR%\lib\gtgui.lib echo %HRB_DIR%\lib\gtwin.lib + >> b32.bc
echo %HRB_DIR%\lib\lang.lib + >> b32.bc
echo %HRB_DIR%\lib\codepage.lib + >> b32.bc
echo %HRB_DIR%\lib\macro%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\rdd%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfntx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbfcdx%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\dbffpt%HB_MT%.lib + >> b32.bc
echo %HRB_DIR%\lib\common.lib + >> b32.bc
echo %HRB_DIR%\lib\debug.lib + >> b32.bc
echo %HRB_DIR%\lib\pp.lib + >> b32.bc
echo %HRB_DIR%\lib\hsx.lib + >> b32.bc
echo %HRB_DIR%\lib\hbsix.lib + >> b32.bc
echo %HRB_DIR%\lib\sixCDX.lib + >> b32.bc

if exist %HRB_DIR%\lib\pcrepos.lib echo %HRB_DIR%\lib\pcrepos.lib + >> b32.bc
rem echo %HRB_DIR%\lib\libct.lib + >> b32.bc
rem echo rddads.lib + >> b32.bc
rem echo ace32.lib + >> b32.bc
echo cw32.lib + >> b32.bc
echo import32.lib, >> b32.bc

if exist xmlrun.res echo xmlrun.res >> b32.bc

ilink32 -Gn -aa -Tpe @b32.bc


if exist xmlrun.res del xmlrun.res



del *.tds
del xmlrun.c
del *.map
del *.obj
del b32.bc
