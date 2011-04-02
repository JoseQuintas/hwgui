Rem
Rem File to compiler using Pelles C
Rem

echo off
@echo.Building file %1.prg for Pelles C Compiler  
ECHO %1.obj > make.tmp 
echo %HRB_DIR%\lib\rtl%HB_MT%.lib  >> make.tmp
echo %HRB_DIR%\lib\vm%HB_MT%.lib  >> make.tmp
echo %HRB_DIR%\lib\gtwin.lib  >> make.tmp
echo %HRB_DIR%\lib\lang.lib  >> make.tmp
echo %HRB_DIR%\lib\codepage.lib  >> make.tmp
echo %HRB_DIR%\lib\macro%HB_MT%.lib  >> make.tmp
echo %HRB_DIR%\lib\rdd%HB_MT%.lib  >> make.tmp
echo %HRB_DIR%\lib\dbfntx%HB_MT%.lib  >> make.tmp
echo %HRB_DIR%\lib\dbfcdx%HB_MT%.lib  >> make.tmp
echo %HRB_DIR%\lib\dbfdbt%HB_MT%.lib  >> make.tmp
echo %HRB_DIR%\lib\common.lib  >> make.tmp
echo %HRB_DIR%\lib\debug.lib  >> make.tmp
echo %HRB_DIR%\lib\pp.lib  >> make.tmp
ECHO %HRB_DIR%\LIB\optcon.lib>> make.tmp
ECHO %HRB_DIR%\LIB\optgui.lib >> make.tmp
ECHO %HRB_DIR%\LIB\nulsys.lib  >> make.tmp
ECHO %HRB_DIR%\LIB\hbodbc.lib   >> make.tmp
ECHO %HRB_DIR%\LIB\samples.lib   >> make.tmp

ECHO %HWGUI_INSTALL%\LIB\hwgui.lib >> make.tmp
ECHO %HWGUI_INSTALL%\LIB\procmisc.lib >> make.tmp
ECHO %HWGUI_INSTALL%\LIB\hbxml.lib >> make.tmp
ECHO %HWGUI_INSTALL%\LIB\hwg_qhtm.lib >> make.tmp

ECHO %POCC%\LIB\kernel32.lib >> make.tmp
ECHO %POCC%\LIB\comctl32.lib >> make.tmp
ECHO %POCC%\LIB\comdlg32.lib >> make.tmp
ECHO %POCC%\LIB\delayimp.lib >> make.tmp
ECHO %POCC%\LIB\ole32.lib >> make.tmp
ECHO %POCC%\LIB\shell32.lib >> make.tmp
ECHO %POCC%\LIB\oleaut32.lib >> make.tmp
ECHO %POCC%\LIB\user32.lib >> make.tmp
ECHO %POCC%\LIB\gdi32.lib >> make.tmp
ECHO %POCC%\LIB\winspool.lib >> make.tmp
ECHO %POCC%\LIB\uuid.lib >> make.tmp
ECHO %POCC%\LIB\portio.lib >> make.tmp
IF EXIST obj\%1.res echo obj\%1.res  >> make.tmp
echo obj\hwgui_xp.res >> make.tmp


rem %HRB_DIR%\BIN\HARBOUR %1.prg -i%POCC%\INCLUDE;%HRB_DIR%\INCLUDE;%HWGUI_INSTALL%\INCLUDE -n -q0 -w -es2 -gc0
%HRB_DIR%\BIN\HARBOUR %1.prg -i%POCC%\INCLUDE;%HRB_DIR%\INCLUDE;%HWGUI_INSTALL%\INCLUDE  -n -q0 -es2 -gc0

IF EXIST %1.rc %POCC%\BIN\porc -r %1 -foobj\%1
echo 1 24 "..\image\WindowsXP.Manifest" > obj\hwgui_xp.rc
%POCC%\BIN\porc -r obj\hwgui_xp -foobj\hwgui_xp

%POCC%\bin\pocc %1.c /Ze /D"NEED_DUMMY_RETURN" /D"__XCC__" /I"INCLUDE" /I"%HRB_DIR%\INCLUDE" /I"%POCC%\INCLUDE" /I"%POCC%\INCLUDE\WIN" /I"%POCC%\INCLUDE\MSVC" /D"HB_STATIC_STARTUP" /c

%POCC%\bin\POLINK /LIBPATH:%POCC%\lib /OUT:%1.EXE /MACHINE:IX86 /OPT:WIN98 /SUBSYSTEM:WINDOWS /FORCE:MULTIPLE @make.tmp >error.log
Echo.Building Complete
DEL make.tmp
del %1.c
rem del %1.map
del %1.obj

