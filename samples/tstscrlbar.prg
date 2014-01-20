#include "windows.ch"
#include "guilib.ch"

FUNCTION main

   LOCAL oMain, i

   INIT WINDOW oMain main TITLE "Scrollbar example"  ;
        At 200, 100 SIZE 400, 250 ;
        STYLE WS_VSCROLL + WS_HSCROLL

   FOR i := 0 TO 200 STEP 20
      @ 0, i  say StrZero(i, 3) + "  -  " + "01234567890123456789012345678901234567890" + "  -  " + StrZero(i, 3) size 420, 20
   next

   ACTIVATE window oMain

   RETURN nil

