#include "hbgtinfo.ch"
#include "hwgui.ch"
#include "directry.ch"

FUNCTION DlgAutoMenu( aAllSetup )

   LOCAL oDlg, aItem, cName := "", nQtd := 0, aMenuList := {}, aGrupoList, cOpcao

   //hb_gtReload( "WVG" )

   FOR EACH aItem IN aAllSetup
      IF ! cName == aItem[1]
         IF Mod( nQtd, 15 ) == 0
            AAdd( aMenuList, {} )
         ENDIF
         cName := aItem[1]
         AAdd( Atail( aMenuList ), cName )
         nQtd += 1
      ENDIF
   NEXT

   INIT WINDOW oDlg TITLE "Example" ;
     AT 0, 0 SIZE 512, 384

   MENU OF oDlg
      FOR EACH aGrupoList IN aMenuList
         MENU TITLE "Data" + Ltrim( Str( aGrupoList:__EnumIndex ) )
            FOR EACH cOpcao IN aGrupoList
               MENUITEM cOpcao ACTION DlgAutoMain( cOpcao, @aAllSetup )
            NEXT
         ENDMENU
      NEXT
      MENU TITLE "Exit"
         MENUITEM "&Exit" ACTION oDlg:Close()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oDlg CENTER

   RETURN Nil
