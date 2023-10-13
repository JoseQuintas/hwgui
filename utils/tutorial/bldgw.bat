@echo off
rem set path=c:\softools\mingw\bin;%HB_PATH%\bin
set HRB_DIR=%HB_PATH%
set HRB_LIB_DIR=%HB_PATH%\lib\win\mingw
REM configure Path of Harbour exe to your own needs
set HRB_EXE=%HB_PATH%\bin\win\mingw\harbour.exe
set HWGUI_INSTALL=..\..
set HWGUI_LIBS=-lhwgui -lprocmisc -lhbxml
if exist %HRB_LIB_DIR%\libhbvm.a goto hrb
goto common
set HRB_LIBS=-lvm -lrdd -lmacro -lpp -lrtl -lcodepage -llang -lcommon -ldbfntx  -ldbfcdx -ldbffpt -lhsx -lhbsix -lgtgui -lgtwin
:hrb
set HRB_LIBS=-lhbvm -lhbrdd -lhbmacro -lhbpp -lhbrtl -lhbcpage -lhblang -lhbcommon -lrddntx  -lrddcdx -lrddfpt -lhbsix -lgtgui -lgtwin -lhbcplr -lhbmemio -lhbpcre -lhbzlib
:common

%HRB_EXE% tutor.prg -n -w -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
echo 1 24 "../../image/WindowsXP.Manifest" > hwgui_xp.rc

gcc -I. -I%HRB_DIR%\include -Wall -c tutor.c -otutor.o
windres hwgui_xp.rc hwgui_xp.o
gcc -Wall -mwindows -otutor.exe tutor.o hwgui_xp.o -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib -Wl,--allow-multiple-definition -Wl,--start-group %HWGUI_LIBS% %HRB_LIBS% -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdiplus -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lws2_32 -lwsock32 -liphlpapi -Wl,--end-group

%HRB_EXE% hwgrun.prg -n -w -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
gcc -I. -I%HRB_DIR%\include -Wall -c hwgrun.c -ohwgrun.o
gcc -Wall -mwindows -ohwgrun.exe hwgrun.o hwgui_xp.o -L%HRB_LIB_DIR% -L%HWGUI_INSTALL%\lib -Wl,--allow-multiple-definition -Wl,--start-group %HWGUI_LIBS% %HRB_LIBS% -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdiplus -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lws2_32 -lwsock32 -liphlpapi -Wl,--end-group

del *.c
del *.o
del *.rc
