set MINGW=c:\mingw
set HRB_DIR=c:\dvl\hrb
set HWGUI_INSTALL=..

   %HRB_DIR%\bin\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
   gcc -I. -I%HRB_DIR%\include -mno-cygwin -Wall -c %1.c -o%1.o
   gcc -Wall -o%1.exe %1.o  -L%MINGW%\lib -L%HRB_DIR%\lib -L%HWGUI_INSTALL%\lib -mno-cygwin -Wl,--start-group -lhwgui -lprocmisc -lhbxml -lvm -lrdd -lmacro -lpp -lrtl -lpp -llang -lcommon -lnulsys  -ldbfntx  -ldbfcdx -ldbfdbt -lgtnul -lgtwin -lgtwvt -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -Wl,--end-group
   del %1.c
   del %1.o
