/*
 * $Id$
 *
 * HWGUI - Harbour GUI library source code:
 * Simple texxt editor demonstrating hwg_Memoedit()
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2021 DF7BE
 *
*/

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

#include "hwgui.ch"

STATIC fname , mmemofield

FUNCTION Main()

LOCAL oMain

   mmemofield := ""

   INIT WINDOW oMain MAIN TITLE "File Viewer" ;
      AT 0,0 ;
      SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMain
      MENU TITLE "&Exit"
         MENUITEM "&Quit" ACTION oMain:Close()
      ENDMENU
      MENU TITLE "&Open"
         MENUITEM "&Open File" ACTION FileOpen()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMain

RETURN Nil

FUNCTION Test()

   LOCAL oFont , mreturn

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11
#else
   PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12
#endif

   * Start editing
   mreturn := hwg_MemoEdit(mmemofield , , , , , ,  oFont )
   * Modified ?
   IF mmemofield == mreturn
       hwg_MsgInfo( "Nothing to save", "Memo Edit" )
   ELSEIF mreturn == Nil
      hwg_MsgInfo( "Anything wrong for Nil result" )
   ELSE
      * Save file
      IF MemoWrit(fname,mreturn)
         hwg_MsgInfo("File written: " + fname,"Editor")
      ELSE
         hwg_MsgStop("Write error file : " + fname,"Editor" )
      ENDIF
   ENDIF

RETURN Nil

Function FileOpen()

   fname := hwg_Selectfile( "Select File", "*.*")

   IF EMPTY( fname )
      RETURN NIL
   ENDIF
   * Read file
   mmemofield := MemoRead( fname )

RETURN Test()

* ======================= EOF of simpleedit.prg ==========================
