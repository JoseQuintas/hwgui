@echo off
rem ---------------------------------------------------------------
rem This file is intended to build a program, which uses harbour.dll
rem The main function must be called _AppMain.
rem To run the program, you need to have harbour.dll in your path.
rem ---------------------------------------------------------------

set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..

  %HRB_DIR%\BIN\harbour %1.prg -n -i%HRB_DIR%\INCLUDE;%HWGUI_INSTALL%\include %2 %3

  bcc32 -c -O2 -d -I%HRB_DIR%\INCLUDE;%HWGUI_INSTALL%\include %1.c %HRB_DIR%\source\vm\mainwin.c

IF EXIST %1.rc brc32 -r %1 -foobj\%1

  @echo c0w32.obj + > b32.bc
  @echo %1.obj + >> b32.bc
  @echo mainwin.obj,+ >> b32.bc
  @echo %1.exe, + >> b32.bc
  @echo , + >> b32.bc
  @echo %HRB_DIR%\LIB\harbour.lib + >> b32.bc
  @echo %HWGUI_INSTALL%\LIB\hwguidll.lib + >> b32.bc
  @echo cw32.lib + >> b32.bc
  @echo import32.lib, >> b32.bc

IF EXIST obj\%1.res echo obj\%1.res >> b32.bc
  ilink32 -Tpe -Gn -aa @b32.bc

del %1.obj
del mainwin.obj
del %1.c
del *.tds
del b32.bc
