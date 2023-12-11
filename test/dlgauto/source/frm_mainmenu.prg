/*
frm_mainmenu - menu of DBF files
*/

#include "hbgtinfo.ch"
#include "directry.ch"
#include "frm_class.ch"
#include "inkey.ch"

FUNCTION frm_MainMenu( aAllSetup )

   LOCAL aItem, cName := "", nQtd := 0, aMenuList := {}, oDlg := "Main", cDBF

   FOR EACH aItem IN aAllSetup
      IF ! cName == aItem[1]
         IF Mod( nQtd, 15 ) == 0
            AAdd( aMenuList, {} )
         ENDIF
         cDBF := aItem[1]
         AAdd( Atail( aMenuList ), cDBF )
         nQtd += 1
      ENDIF
   NEXT

   gui_MainMenu( oDlg, aMenuList, aAllSetup, gui_LibName() + " - MENU" )

   RETURN Nil
