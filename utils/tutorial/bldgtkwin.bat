@echo off
REM
REM bldgtkwin.bat
REM
REM  $Id$
REM
REM Created by DF7BE 2020-08-23
REM Script building tutorial
REM for HWGUI on Windows with GTK+
REM (not the native Windows calls)
REM For test purposes.
REM Created by DF7BE
REM
REM Warning:
REM For normal use on Windows it is strictly recommended to build only the WinAPI
REM edition of HWGUI and your application. The WinAPI functions are quite stable and
REM effective.
REM Take the GTK build only for test- and development purposes ! 
REM Also it is strictly recommended to check the modified GTK sources
REM on Linux or another *NIX operating system before checking in into
REM a source repository.
REM For details read instructions in file
REM samples\dev\MingW-GTK\Readme.txt
REM #######################################


REM =====================================
REM configure all installation path's
REM Modify to your own needs:
REM Example 1
REM base path auf Mingw and Harbour Compiler
REM set GTK_INSTALL=C:/GTK
REM set MINGW=c:\mingw
REM set HRB_DIR=c:\dvl\hrb
REM set HWGUI_INSTALL=..\..

REM Example 2
REM this example for using Harbour and MingW of installed MiniGUI
REM set GTK_INSTALL=C:/GTK
REM set MINGW=C:\hmg.3.3.1\MINGW
REM set HRB_DIR=C:\hmg.3.3.1\HARBOUR

REM --- active settings ---
REM using own build Harbour
set GTK_INSTALL=C:/GTK
REM set MINGW=C:\hmg.3.3.1\MINGW
SET MINGW=C:\MinGW32
REM set HRB_DIR=C:\hmg.3.3.1\HARBOUR
set HRB_DIR=C:\harbour\core-master
SET HRB_EXE=%HRB_DIR%\bin\win\mingw\harbour
set HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw

REM Installation path of HWGUI
set HWGUI_INSTALL=C:\hwgui\hwgui-gtk
REM =====================================


REM GTK libs and includes
REM set GTK_INCLUDE=-I"%GTK_INSTALL%/include/glib-2.0" -I"%GTK_INSTALL%/lib/glib-2.0/include" -I"%GTK_INSTALL%/include/gtk-2.0" -I"%GTK_INSTALL%/lib/gtk-2.0/include" -I"%GTK_INSTALL%/include/atk-1.0" -I"%GTK_INSTALL%/include/pango-1.0" -I"%GTK_INSTALL%/include/libglade-2.0" -I"%GTK_INSTALL%/include/libxml2" -I"%GTK_INSTALL%/include/cairo" -I"%GTK_INSTALL%/include"

SET GTK_LIB=-L"%GTK_INSTALL%/lib"
REM SET /p GTK_INC= | pkg-config --cflags gtk+-2.0
REM SET /p GTK_LIBS= | pkg-config gtk+-2.0 --libs
REM 
REM Libraries
set HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw
if exist %HRB_LIB_DIR%\libhbvm.a goto hrb
goto common
set HRB_LIBS=-lvm -lrdd -lmacro -lpp -lrtl -lcodepage -llang -lcommon -ldbfntx  -ldbfcdx -ldbffpt -lhsx -lhbsix -lgtgui -lgtwin -lgtcgi
:hrb
set HRB_LIBS=-lhbvm -lhbrdd -lhbmacro -lhbpp -lhbrtl -lhbcpage -lhblang -lhbcommon -lrddntx  -lrddcdx -lrddfpt -lhbsix -lgtgui -lgtwin -lhbcplr -lgtcgi
:common
REM set HRB_LIBS=-lhbdebug -lhbvm -lhbrtl -lgtcgi -lhbdebug -lhblang -lhbrdd -lhbmacro -lhbpp -lrddntx -lrddcdx -lrddfpt -lhbsix -lhbcommon -lhbcpage -lgtwin -lgtgui
REM set HWGUI_LIBS=-lhbxml -lhwgdebug -lhwgui -lprocmisc -lpcre
set HWGUI_LIBS=-lhwgui -lprocmisc -lhbxml -lpcre
REM Windows-DLLs
set WIN_DLLS=-lcomctl32 -lole32 -lwinspool -loleaut32 -lshell32 -luuid -lwinmm

REM ==== Tutor ====
%HRB_EXE% tutor.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -d__GTK__ %2
gcc -I. -I%HRB_DIR%\include -Wall -c tutor.c -o tutor.o

REM --- Link with GTK+ V2 =====
gcc -Wall -mwindows -otutor.exe tutor.o -L%MINGW%\lib -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib %GTK_LIB%  -Wl,--allow-multiple-definition -Wl,--start-group  %HWGUI_LIBS% %HRB_LIBS% -lgtk-win32-2.0 -lgdk-win32-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangowin32-1.0 -lgdi32 -lpango-1.0 -lcairo -lgobject-2.0 -lgmodule-2.0 -lglib-2.0 -lintl -liconv -lgio-2.0  -lgdi32 -lpangocairo-1.0  -lgthread-2.0   %WIN_DLLS% -Wl,--end-group

REM ==== hwgrun ====
%HRB_EXE% hwgrun.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include -d__GTK__ %2
gcc -I. -I%HRB_DIR%\include -Wall -c hwgrun.c -o hwgrun.o

REM --- Link with GTK+ V2 =====
gcc -Wall -mwindows -ohwgrun.exe hwgrun.o -L%MINGW%\lib -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib %GTK_LIB%  -Wl,--allow-multiple-definition -Wl,--start-group  %HWGUI_LIBS% %HRB_LIBS% -lgtk-win32-2.0 -lgdk-win32-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangowin32-1.0 -lgdi32 -lpango-1.0 -lcairo -lgobject-2.0 -lgmodule-2.0 -lglib-2.0 -lintl -liconv -lgio-2.0  -lgdi32 -lpangocairo-1.0  -lgthread-2.0   %WIN_DLLS% -Wl,--end-group


del tutor.c
del tutor.o


REM ------------ EOF of bldgtkwin.bat --------------------
