set MINGW=c:\mingw
set HRB_DIR=c:\dvl\hrb
set HWGUI_INSTALL=..\..
set GTK_INCLUDE=-I"C:/GTK/include/glib-2.0" -I"C:/GTK/lib/glib-2.0/include" -I"C:/GTK/include/gtk-2.0" -I"C:/GTK/lib/gtk-2.0/include" -I"C:/GTK/include/atk-1.0" -I"C:/GTK/include/pango-1.0" -I"C:/GTK/include/libglade-2.0" -I"C:/GTK/include/libxml2" -I"C:/GTK/include/cairo" -I"C:/GTK/include"
set GTK_LIB=-L"C:/GTK/lib" 

%HRB_DIR%\bin\harbour %1.prg -n -i%HRB_DIR%\include;%HWGUI_INSTALL%\include %2
gcc -I. -I%HRB_DIR%\include -mno-cygwin -Wall -c %1.c -o%1.o
gcc -Wall -mwindows -o%1.exe %1.o -L%MINGW%\lib -L%HRB_DIR%\lib -L%HWGUI_INSTALL%\lib %GTK_LIB% -mno-cygwin -Wl,--allow-multiple-definition -Wl,--start-group -lhwgtk -lhbxml -lprocmisc -lvm -lrdd -lmacro -lpp -lrtl -lpp -llang -lcommon -lcodepage -lnulsys  -ldbfntx  -ldbfcdx -ldbffpt -lhbsix -lgtnul -lgtcgi -lpcrepos -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lgtk-win32-2.0 -lgdk-win32-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangowin32-1.0 -lgdi32 -lpango-1.0 -lgobject-2.0 -lgmodule-2.0 -lglib-2.0 -lintl -liconv -Wl,--end-group
del %1.c
del %1.o
