#include "windows.ch"
#include "guilib.ch"

FUNCTION main

   LOCAL oMain, i

   INIT WINDOW oMain main TITLE "Scrollbar example"  ;
        COLOR COLOR_3DLIGHT + 1                       ;
        At 200, 100 SIZE 400, 250 ;
        STYLE WS_VSCROLL + WS_HSCROLL

   FOR i := 0 TO 200 STEP 20
      @ 0, i  say StrZero(i, 3) + "  -  " + "01234567890123456789012345678901234567890" + "  -  " + StrZero(i, 3) size 420, 20
   next


   oMain:bScroll := { | o, msg, wParam, lParam | stdScroll( o, msg, wParam, lParam ) }

   ACTIVATE window oMain

   RETURN nil


STATIC FUNCTION stdScroll( oDlg, msg, wParam, lParam, nIncr )
   LOCAL nScrollCode := hwg_Loword( wParam )
   LOCAL nNewPos := hwg_Hiword( wParam )
   LOCAL x, y, xx, yy, pg

   IF ! HB_IsNumeric( nIncr )
      nIncr := 10
   ENDIF
   pg := Max(Round(nIncr / 5, 0), 2)
   x := hwg_Getscrollpos( oDlg:handle, SB_HORZ )
   y := hwg_Getscrollpos( oDlg:handle, SB_VERT )
   IF msg == WM_VSCROLL
      yy := y
      hwg_Setscrollrange( oDlg:handle, SB_VERT, 0, nIncr )
      IF nScrollCode == SB_LINEDOWN
         IF ++y > nIncr
            y := nIncr
         ENDIF
      ELSEIF nScrollCode == SB_LINEUP
         IF --y < 0
            y := 0
         ENDIF
      ELSEIF nScrollCode == SB_PAGEDOWN
         y += pg
         IF y > nIncr
            y := nIncr
         ENDIF
      ELSEIF nScrollCode == SB_PAGEUP
         y -= pg
         IF y < 0
               y := 0
         ENDIF
      ELSEIF nScrollCode == SB_THUMBTRACK .or. nScrollCode == SB_THUMBPOSITION
         y := nNewPos
      ENDIF
      IF y != yy
         hwg_Setscrollpos( oDlg:handle, SB_VERT, y )
         hwg_Scrollwindow( oDlg:handle, 0, ( yy - y ) * nIncr )
      ENDIF
   ELSEIF msg == WM_HSCROLL
      hwg_Setscrollrange( oDlg:handle, SB_HORZ, 0, nIncr )
      xx := x
      IF nScrollCode == SB_LINERIGHT
         IF ++x > nIncr
            x := nIncr
         ENDIF
      ELSEIF nScrollCode == SB_LINELEFT
         IF --x < 0
            x := 0
         ENDIF
      ELSEIF nScrollCode == SB_PAGERIGHT
         x += pg
         IF x > nIncr
            x := nIncr
         ENDIF
      ELSEIF nScrollCode == SB_PAGELEFT
         x -= pg
         IF x < 0
            x := 0
         ENDIF
      ELSEIF nScrollCode == SB_THUMBTRACK .or. nScrollCode == SB_THUMBPOSITION
         x := nNewPos
      ENDIF
      IF x != xx
         hwg_Setscrollpos( oDlg:handle, SB_HORZ, x )
         hwg_Scrollwindow( oDlg:handle, ( xx - x ) * nIncr, 0 )
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      yy := y
      hwg_Setscrollrange( oDlg:handle, SB_VERT, 0, nIncr )
      IF hwg_Hiword(wParam) > 32678
         IF ++y > nIncr
            y := nIncr
         ENDIF
      ELSE
         IF --y < 0
            y := 0
         ENDIF
      ENDIF
      IF y != yy
         hwg_Setscrollpos( oDlg:handle, SB_VERT, y )
         hwg_Scrollwindow( oDlg:handle, 0, ( yy - y ) * nIncr )
      ENDIF
   ENDIF

   RETURN - 1