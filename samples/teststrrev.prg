*
* teststrrev.prg
*
* $Id$
*
* HWGUI - Harbour Win32 GUI and GTK library source code:
*
* Sample program testing function hwg_strrev(cstring)
* Reverse strings with UTF-8
*  
*   Reverses a string. 
*   This is the equivalent strrev() function from the standard C library,
*   but extended to understand UTF-8.
*   cstring may not exceed 511 bytes, inclusive length of all
*   used UTF-8 characters.
*
* Copyright 2024 Wilfried Brunken, DF7BE
*
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes
 
#include "hwgui.ch"



FUNCTION MAIN()

  LOCAL oWinMain


   INIT WINDOW oWinMain MAIN  ;
      TITLE "Sample program for function hwg_Strrev()" AT 100, 100 SIZE 600,400;
      STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Reverse string"     ACTION Teste()
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN Nil  

FUNCTION Teste()
LOCAL Strrev

LOCAL oLabel1, oLabel2, oLabel3, oLabel4, oLabel5, oLabel6
LOCAL oEditbox1, oButton1, oButton2
LOCAL cstring, cneustr

* Init 
   
  cstring := SPACE(511)
  cstring := hwg_GET_Helper(cstring,511)
  cneustr := ""
  
  INIT DIALOG Strrev TITLE "Test of function hwg_Strrev()" ;
    AT 279,216 SIZE 966,475 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE


   @ 40,20 SAY oLabel2 CAPTION "Test of hwg_Strrev()"  SIZE 246,22   
   @ 40,55 SAY oLabel1 CAPTION "Enter a string (max 511 characters) :"  SIZE 386,22   
   @ 40,102 GET oEditbox1 VAR cstring  SIZE 865,24 ;
        STYLE WS_BORDER     
   @ 40,150 SAY oLabel3 CAPTION "UTF-8 support  (hwg__isUnicode()  :  "  SIZE 391,22   
   @ 509,150 SAY oLabel4 CAPTION IIF(hwg__isUnicode(),"Yes","No") ;
        SIZE 249,22   
   @ 40,190 SAY oLabel5 CAPTION "Result :"  SIZE 80,22   
   @ 40,245 SAY oLabel6 CAPTION cneustr  SIZE 865,22   
   @ 53,305 BUTTON oButton1 CAPTION "Reverse string"   SIZE 259,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { | | cneustr := hwg_Strrev(cstring) , oLabel6:SetText(ALLTRIM(cneustr)) } 
        * Attention !
        * On Windows the result string contains blanks
        * from the GET field, so the result must be
        * ALLTRIM'ed for correct display.
   @ 626,305 BUTTON oButton2 CAPTION "Exit"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { | | Strrev:Close() }

   ACTIVATE DIALOG Strrev
// RETURN Strrev:lresult


RETURN NIL


* ==================== EOF of teststrrev.prg ============================   