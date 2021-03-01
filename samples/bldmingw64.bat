@echo off
REM
REM bldmingw64.bat
REM
REM $Id$
REM
REM Batch file compiling single sample prg with HWGUI, 64bit (x86_64)
REM by DF7BE
REM
REM Call script pfad64.bat for setting environment variables before usage.
REM
REM remove file extension
SET PRGNAME=%~n1
REM === Modify to your own needs ===
SET HWGUI_INSTALL=..
SET MINGW=C:\MinGW64
SET HRB_DIR=C:\harbour64\core-master
SET HRB_LIB_DIR=%HRB_DIR%\lib\win\mingw64
REM
SET HRB_DIR=%HB_PATH%
SET HRB_EXE=%HB_PATH%\bin\win\mingw64\harbour.exe

REM
SET OBJ_LIST=%PRGNAME%.o

SET MINGW_ARCH=-march=x86-64

REM Windows DLLs
SET WIN_DLLS=-luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm

REM Harbour libs
SET HRB_LIBS=

REM Standard HWGUI libs
SET HWGUI_LIBS=-lhwgui -lprocmisc -lhbxml -lhwgdebug

REM Add contrib libs, if available
if exist %HWGUI_INSTALL%\lib\libhwg_extctrl.a (
SET HWGUI_LIBS=%HWGUI_LIBS% -lhwg_extctrl 
)

if exist %HWGUI_INSTALL%\lib\libhwg_misc.a (
SET HWGUI_LIBS=%HWGUI_LIBS% -lhwg_misc
)

if exist %HWGUI_INSTALL%\lib\libhwg_qhtm.a (
SET HWGUI_LIBS=%HWGUI_LIBS% -lhwg_qhtm
)

if exist %HWGUI_INSTALL%\lib\libhbactivex.a (
SET HWGUI_LIBS=%HWGUI_LIBS% -lhbactivex
)

%HRB_EXE% %PRGNAME%.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
gcc %MINGW_ARCH% -I. -I%HRB_DIR%\include -Wall -c %PRGNAME%.c -o%PRGNAME%.o


if not exist %PRGNAME%.rc goto link
echo compile resource file %PRGNAME%.rc
windres -F pe-x86-64 -i %PRGNAME%.rc -o %PRGNAME%_res.o
set OBJ_LIST=%OBJ_LIST% %PRGNAME%_res.o

:link
if exist %HRB_LIB_DIR%\libhbvm.a goto hrb
gcc %MINGW_ARCH% -Wall -mwindows -o%PRGNAME%.exe %OBJ_LIST% -L%MINGW%\lib -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib -Wl,--allow-multiple-definition -Wl,--start-group %HWGUI_LIBS% -lvm -lrdd -lmacro -lpp -lrtl -lpp -lcodepage -llang -lcommon -lnulsys  -ldbfntx  -ldbfcdx -ldbffpt -lhbsix -lgtgui %WIN_DLLS% -Wl,--end-group
goto common

:hrb
gcc %MINGW_ARCH% -Wall -mwindows -o%PRGNAME%.exe %OBJ_LIST% -L%MINGW%\lib -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib -Wl,--allow-multiple-definition -Wl,--start-group %HWGUI_LIBS% -lhbvm -lhbrdd -lhbmacro -lhbpp -lhbrtl -lhbcpage -lhblang -lhbcommon -lrddntx  -lrddcdx -lrddfpt -lhbsix -lgtgui -lgtwin %WIN_DLLS% -Wl,--end-group

:common
del %PRGNAME%.c
del %PRGNAME%.o
if exist %PRGNAME%_res.o del %PRGNAME%_res.o 


REM -mno-cygwin and -gui not supported any more

REM ========================== EOF of bldmingw64.bat ========================= 