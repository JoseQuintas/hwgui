set PATH=d:\softools\mingw\bin
set HRB_DIR=%HB_PATH%
set HWGUI_INSTALL=..\..

   %HRB_DIR%\bin\w32\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
   gcc -I. -I%HRB_DIR%\include -mno-cygwin -Wall -c %1.c -o%1.o
   gcc -Wall -o%1.exe %1.o  -Ld:\softools\mingw\lib -L%HRB_DIR%\lib\w32 -L%HWGUI_INSTALL%\lib -mno-cygwin -ldebug -lvm -lrdd -lrtl -lvm -lmacro -lpp -llang -lcommon -lnulsys  -ldbfntx  -ldbfcdx -lgtwin -lhwgui -lprocmisc -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lrtl
   del %1.c
   del %1.o
