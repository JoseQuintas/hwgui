/*
in mixed mode use DIALOG and not WINDOW
or you will have hidden windows
*/

#include "hbgtinfo.ch"
#include "hwgui.ch"

FUNCTION Menuhwgui()

   LOCAL oDlg

   INIT DIALOG oDlg TITLE "Example" ;
     AT 200,0 SIZE 400,150

   MENU OF oDlg
      MENU TITLE "Exit"
         MENUITEM "&Exit" ACTION oDlg:Close()
      ENDMENU
      MENU TITLE "&Tests"
         MENUITEM "&Show gt name"        ACTION hwg_MsgInfo( hb_gtinfo( HB_GTI_VERSION ) )
         //MENUITEM "Menu gtwvg"           ACTION hb_ThreadStart( { || hb_gtReload( "WVG" ), menu() } )
         MENUITEM "Dialog get colorized" ACTION DlgGet(.T.)
         MENUITEM "Dialog Textview"      ACTION DlgTextView()
         MENUITEM "Dialog Auto"          ACTION DlgAuto()
      ENDMENU
   ENDMENU

   ACTIVATE DIALOG oDlg

RETURN Nil

