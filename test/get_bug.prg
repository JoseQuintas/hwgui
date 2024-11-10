/*
 * HWGUI test program to demonstrate the GET bug
 * not appeared in r3484
 *
 * Copyright 2024 Wilfried Brunken, DF7BE
 *
 * $Id$
 *  
 * 
 * Status:
 *  WinAPI   :  Yes
 *  GTK/Linux:  Yes
 *  GTK/Win  :  Yes 
 */
 
/*
 The symptom:
  This bug appeared in of the newest revision of HWGUI.
  Starting the dialog for entering values,
  and fill the string field up to the end with characters,
  for example "12345678901234567890" (with len=20).
  Move the cursor with the TAB key to any field and move the
  cursor to the end with the cursor right key, the cursor is at the
  character before the end position.
  It is not possible to reach the end position.
  Using the mouse, it is no problem, to positionize the cursor
  at the last position.
  See get_bug.png
  The motivation for this is, that on MacOS there is not a DELETE key,
  you must always use the BACKSPACE key.
  
  Analysis:
  The HEdit class is used for GET.
  Find it in hedit.prg
  
  wParam == 39     // KeyRight 
  ...
  IF !Empty( ::oPicture )
                     IF ( nPos := ::oPicture:KeyRight( hwg_edit_Getpos( ::handle ) ) ) > 0
                        && nPos is get with 20, but 21 set cursor to the end of field
                        hwg_edit_Setpos( ::handle, nPos )
                     ENDIF
                     RETURN 0
                  ENDIF

  The "End" key works OK:
            ELSEIF wParam == 35     // End
               IF !hwg_IsCtrlShift()
                  ::lFirst := .F.
                  IF ::cType == "C"
                     nPos := hwg_Len( Trim( ::title ) ) + 1
                     hwg_edit_SetPos( ::handle, nPos )
                     RETURN 0
                  ENDIF
               ENDIF

  Simular to GTK:

        ELSEIF wParam == GDK_Right
            IF lParam == 0
               ::lFirst := .F.
               IF !Empty( ::oPicture )
                  IF ( nPos := ::oPicture:KeyRight( hwg_edit_Getpos( ::handle ) ) ) > 0
                     hwg_edit_Setpos( ::handle, nPos )
                  ENDIF
                  RETURN 1
               ENDIF
            ENDIF
         ELSEIF wParam == GDK_Left


  - During the continued development the class HPicture was moved
    from hedit.prg into the cross area
      source\cross\common.prg  
    also METHOD KeyRight , IsEditable
    (they are former static functions, now added to class HPicture)
    The METHOD KeyRight returns the new position the
    cursor should be set.
    The HWG_EDIT_SETPOS() of control.c sends the message to move the cursor,
    the parameter nPos is internally decreased by 1, because
    the first position starts with 0. 
    
    But the return value must be increased by 1,
    if end of input line is reached.

    For example:
    Enter in string field of this programm a string with 20 charaters,
    the cursor is placed to the position after by:
     nPos := 21     hwg_edit_Setpos( ::handle, nPos )

    On GTK, the function hwg_Sendmessage() of misc.c is empty,
    so functions gtk_editable_set_position() and gtk_editable_get_position()
     of source\gtk\control.c are used for get and set cursor positions.
  
  
 Solution:
 
   In METHOD KeyRight of CLASS HPicture
   an ELSE path is added, because the isEditable() method
   returns .F., if the end of edit field is reached:    
 
         IF ::IsEditable( nPos )
            RETURN nPos
         ELSE
          * Set Cursor to position after last character or figure
            RETURN nPos + 1
         ENDIF

    Pressing the right key several times, the cursor "toggles"
    before and after the last position.
    The hwg_edit_Getpos() function does not return 
    the recent last position (which must be 21 instead of 20).
 
    But this behavior is acceptable.

    On GTK the above modification has same effect.

*/ 

/* === includes === */
#include "hwgui.ch"


/* Main Program */
FUNCTION MAIN

    LOCAL o_main, oButton1, oButton2, oButton3, oButton4 

SET CENTURY ON
SET DATE GERMAN   
 
 INIT WINDOW o_main MAIN TITLE "Demonstrate new GET bug"  ;
     AT 200,100 SIZE 500,500 ;
     ON EXIT {||hwg_MsgYesNo("OK to quit ?")}
 
   

   @ 150,150 BUTTON oButton1 CAPTION "Test with decimal point is point" SIZE 280,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK {|| teste("9999.999") } 
 
   @ 150,200 BUTTON oButton2 CAPTION "Test with decimal point is comma" SIZE 280,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK {|| teste("@E 9999.999") }

   @ 150,250 BUTTON oButton3 CAPTION "Test without picture" SIZE 280,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK {|| teste("") }

   @ 250,400 BUTTON oButton4 CAPTION "Quit" SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ON CLICK {|| o_main:Close() }

     ACTIVATE WINDOW o_main


RETURN NIL
/* End of Main */

FUNCTION teste(cPictFrequency)

 LOCAL odlg , o_get1 , o_get2, o_get3, l_string, oSay1, oSay2, oSay3, nzahl
 LOCAL lpict

 lpict := .T.
 
 IF EMPTY(cPictFrequency)
   lpict := .F.
 ENDIF  
 
l_string := SPACE(20)
l_string := hwg_GET_Helper(l_string,20)

nzahl := 145.550 

d_date := DATE()

  INIT DIALOG oDlg TITLE "Demonstrate new GET bug" ;
    AT 475,157 SIZE 462,288 NOEXIT;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE 
 
* Date
   @ 10, 10 SAY oSay1 CAPTION "Enter a date (DD.MM.YYYY):" SIZE 284,22  
   @ 10, 40 GET  o_get1 VAR d_date ;
        SIZE 80, 30 ;
        STYLE WS_BORDER ;
        TOOLTIP "Enter a date"

* String
   @ 10, 90  SAY oSay2 CAPTION "Enter a string:" SIZE 284,22
 IF lpict  
   @ 10, 120 GET o_get2 VAR l_string  SIZE 373,24 ;
        STYLE WS_BORDER PICTURE REPLICATE("X",20) ;
        TOOLTIP "Enter a string (len=20)"
 ELSE
   @ 10, 120 GET o_get2 VAR l_string  SIZE 373,24 ;
        STYLE WS_BORDER ;
        TOOLTIP "Enter a string (len=20)"
 ENDIF 

* Numeric


   @ 10, 150 SAY oSay3 CAPTION "Enter a number:" SIZE 284,22
 IF lpict    
   @ 10, 190 GET o_get3 VAR nzahl  SIZE 80,24 ;
        STYLE WS_BORDER PICTURE cPictFrequency ;
        TOOLTIP "Enter a number (" + cPictFrequency + ")"
 ELSE
  * Without PICTURE, the field is too short 
  @ 10, 190 GET o_get3 VAR nzahl  SIZE 100,24 ;
        STYLE WS_BORDER  ;
        TOOLTIP "Enter a number (9999.999, no PICTURE statement)"
 ENDIF
 
   @ 310,190 BUTTON oButton2 CAPTION "Quit"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| oDlg:Close() }

ACTIVATE DIALOG oDlg

hwg_MsgInfo("Result:" + CHR(10) + ;
  "String=>" + l_string + "<" + " (len=" + ALLTRIM(STR(LEN(l_string))) + ")" + CHR(10) + ; 
  "Date=" + DTOC(d_date)+ CHR(10) + ;
  "Number=" + ALLTRIM(STR(nzahl)) )  

RETURN NIL

* ====== EOF of get_bug.prg ======
 

