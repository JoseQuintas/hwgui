

#include "hwgui.ch"

FUNCTION MAIN()

LOCAL oDlg
LOCAL oLabel1, oLabel2, oLabel3, oEditbox1, l_string, l_sout, oButton1, oButton2

l_string := SPACE(40)
l_string := hwg_GET_Helper(l_string,40)
l_sout   := SPACE(40)

 INIT WINDOW oDlg TITLE "GET bug in main window" ;
    AT 475,157 SIZE 462,288 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE
 
   @ 40,25 SAY oLabel1 CAPTION "Enter a string and fill to end of field :"  SIZE 350,22  
 
   @ 40,60 GET oEditbox1 VAR l_string  SIZE 373,24 ;
        STYLE WS_BORDER 

   @ 40,97 SAY oLabel2 CAPTION "Result :"  SIZE 80,22   
   @ 40,128 SAY oLabel3 CAPTION l_sout  SIZE 373,22

      @ 43,170 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
       ON CLICK {|| l_sout := l_string , oLabel3:SetText(l_sout) }
   @ 310,170 BUTTON oButton2 CAPTION "Quit"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| oDlg:Close() }


   ACTIVATE WINDOW oDlg

RETURN NIL

/*

The Symtom:
 Fill the GET field complete with characters, if end of field is reached,
 the program crashes with the appended listed error stack.
 Using the same procedure in a DIALOG, the crash does not appear.
 
 The bugfix:
 In hwindow.prg add following lines in the class definition of CLASS HMainWindow:
 
   // DF7BE: Fix crash, if GET used in main window (for details see test/demosaycrash.prg)
   DATA lExitOnEnter INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key
   DATA _lResult  INIT .T.   // For __errInHandler()
   
 (about line 302)  

Error HCUSTOMWINDOW/0  Invalid class member
Called from (b)HWG_ERRSYS(20)
Called from HMAINWINDOW:LEXITONENTER(263)
Called from HWG_DLGCOMMAND(383)
Called from HEDIT:ONEVENT(177)
Called from HWG_ACTIVATEMAINWINDOW(0)
Called from HMAINWINDOW:ACTIVATE(395)
Called from MAIN(34)

Error HCUSTOMWINDOW/0  Invalid class member
Called from (b)HWG_ERRSYS(20)
Called from HMAINWINDOW:_LRESULT(263)
Called from HWG_DLGCOMMAND(385)
Called from HEDIT:ONEVENT(177)
Called from HWG_ACTIVATEMAINWINDOW(0)
Called from HMAINWINDOW:ACTIVATE(397)
Called from MAIN(34)

*/   

* ================ EOF of demosaycrash.prg ================