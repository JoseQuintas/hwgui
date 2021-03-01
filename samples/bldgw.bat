@echo off
rem set hb_path=c:\harbour_v3
rem set path=c:\softools\mingw\bin
set MINGW=c:\softools\mingw
set HRB_DIR=%HB_PATH%
set HRB_LIB_DIR=%HB_PATH%\lib\win\mingw
set HWGUI_INSTALL=..
set OBJ_LIST=%1.o

%HRB_DIR%\bin\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
gcc -I. -I%HRB_DIR%\include -Wall -c %1.c -o%1.o
if not exist %1.rc goto link
windres %1.rc %1_res.o
set OBJ_LIST=%OBJ_LIST% %1_res.o
:link
if exist %HRB_LIB_DIR%\libhbvm.a goto hrb
gcc -Wall -mwindows -o%1.exe %OBJ_LIST% -L%MINGW%\lib -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib -mno-cygwin -Wl,--allow-multiple-definition -Wl,--start-group -lhwgui -lprocmisc -lhbxml -lvm -lrdd -lmacro -lpp -lrtl -lpp -lcodepage -llang -lcommon -lnulsys  -ldbfntx  -ldbfcdx -ldbffpt -lhbsix -lgtgui -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -Wl,--end-group
goto common

:hrb
gcc -Wall -mwindows -o%1.exe %OBJ_LIST% -L%MINGW%\lib -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib -mno-cygwin -Wl,--allow-multiple-definition -Wl,--start-group -lhwgui -lprocmisc -lhbxml -lhbvm -lhbrdd -lhbmacro -lhbpp -lhbrtl -lhbcpage -lhblang -lhbcommon -lrddntx  -lrddcdx -lrddfpt -lhbsix -lgtgui -lgtwin -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -Wl,--end-group

:common
del %1.c
del %1.o
if exist %1_res.o del %1_res.o 
