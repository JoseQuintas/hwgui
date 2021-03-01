@echo off
REM build designer for MINGW (gcc) on Windows
REM $Id$
REM by DF7BE
REM 2019-09-08

rem configure installation path of Harbour and gcc to your own needs
rem set HB_PATH=c:\harbour_v3
REM set HRB_DIR=%HB_Path%
SET HRB_DIR=C:\harbour\core-master
REM
set HRB_LIBS=%HRB_DIR%\lib\win\mingw
set HRB_EXE=%HRB_DIR%\bin\win\mingw\harbour.exe
REM configure HWGUI install (current dir is utils\designer )
set HWGUI_INSTALL=..\..


REM %HRB_EXE% designer.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
REM %HRB_EXE% hctrl.prg -w  -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
REM %HRB_EXE% hformgen.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
REM %HRB_EXE% inspect.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
REM %HRB_EXE% editor.prg -w -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include
REM compiling .c to .o with gcc


REM   gcc -I. -I%HRB_DIR%\include -Wall -c  hctrl.c -o  hctrl.o
   
REM compling resource file
REM   windres designer.rc designer_res.o

REM and link
hbmk2 designer designer.rc  -I%HWGUI_INSTALL%\include -L%HWGUI_INSTALL%\lib -lhwgui -lprocmisc -lhbxml -lhwgdebug -gui




REM ======= EOF of blddesgw.bat =========
