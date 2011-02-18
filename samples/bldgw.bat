@echo off
rem set path=c:\softools\mingw\bin
set MINGW=c:\mingw
set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..
set OBJ_LIST=%1.o

%HRB_DIR%\bin\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
gcc -I. -I%HRB_DIR%\include -mno-cygwin -Wall -c %1.c -o%1.o
if not exist %1.rc goto link
windres %1.rc %1_res.o
set OBJ_LIST=%OBJ_LIST% %1_res.o
:link
gcc -Wall -mwindows -o%1.exe %OBJ_LIST% -L%MINGW%\lib -L%HRB_DIR%\lib\w32 -L%HWGUI_INSTALL%\lib -mno-cygwin -Wl,--allow-multiple-definition -Wl,--start-group -lhwgui -lprocmisc -lhbxml -lvm -lrdd -lmacro -lpp -lrtl -lpp -lcodepage -llang -lcommon -lnulsys  -ldbfntx  -ldbfcdx -ldbffpt -lhbsix -lgtgui -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -Wl,--end-group
del %1.c
del %1.o
if exist %1_res.o del %1_res.o 
