set MINGW=c:\mingw
set HB_INSTALL=%HB_PATH%
set HWGUI_INSTALL=..

   %HB_INSTALL%\bin\harbour %1.prg -n -i%HB_INSTALL%\include;%HWGUI_INSTALL%\include %2
   gcc -I. -I%HB_INSTALL%\include -mno-cygwin -Wall -c %1.c -o%1.o
   gcc -Wall -o%1.exe %1.o  -L%MINGW%\lib -L%HB_INSTALL%\lib -L%HWGUI_INSTALL%\lib -mno-cygwin -lhwgui -lprocmisc -ldebug -lvm -lrdd -lvm -lmacro -lpp -lrtl -lpp -lrtl -llang -lcommon -lnulsys  -ldbfntx  -ldbfcdx -ldbfdbt -lgtwin -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lrtl
   del %1.c
   del %1.o
