#include "hwgui.ch"

FUNCTION _saymoney
PRIVATE oEditbox1, oLabel2, oOwnerbutton1, oLSay, oOwnerbutton2, oOwnerbutton3
 PRIVATE nValue


nValue:=0

  INIT DIALOG oDlg TITLE "Say Money Sample" ;
    AT 309,214 SIZE 552,239 ;
     STYLE DS_CENTER +WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 136,10 GET oEditbox1 VAR nValue  SIZE 158,24 ;
        STYLE WS_BORDER     
   @ 25,11 SAY oLabel2 CAPTION "Value"  SIZE 80,22   
   @ 20,54 OWNERBUTTON oOwnerbutton1   SIZE 92,28 ;
        STYLE WS_TABSTOP  ;
        TEXT 'SayDollar()'  ;
        COORDINATES 0, 0, 0, 0  ;
        ON CLICK {|| Olsay:SETTEXT(SAYDOLLAR(nValue)) }
   @ 137,57 SAY oLSay CAPTION "Label"  SIZE 281,82  ;
         BACKCOLOR 8421504  ;
        FONT HFont():Add( 'Arial',0,-13,400,,255,)
   @ 21,85 OWNERBUTTON oOwnerbutton2   SIZE 92,28 ;
        STYLE WS_TABSTOP  ;
        TEXT 'SayRupiah()'  ;
        COORDINATES 0, 0, 0, 0  ;
        ON CLICK {|| Olsay:SETTEXT(SAYRUPIAH(nValue)) }
   @ 434,161 OWNERBUTTON oOwnerbutton3   SIZE 28,28 ;
        STYLE WS_TABSTOP  ;
        TEXT 'OButton'  ;
        COORDINATES 0, 0, 0, 0  ;
        BITMAP HBitmap():AddFile('smExit')  FROM RESOURCE  TRANSPARENT  ;
        COORDINATES 0, 0, 0, 0  ;
        ON CLICK {|| enddialog() }

   ACTIVATE DIALOG oDlg
RETURN oDlg:lresult

