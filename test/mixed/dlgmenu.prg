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
         MENUITEM "&Exit" ACTION hwg_EndDialog()
      ENDMENU
      MENU TITLE "&Tests"
         MENUITEM "&Show gt name" ACTION hwg_MsgInfo( hb_gtinfo( HB_GTI_VERSION ) )
         MENUITEM "Empty dialog" ACTION DlgEmpty(.T.)
         MENUITEM "Dialog with get colorized" ACTION DlgGet(.T.)
      ENDMENU
   ENDMENU

   ACTIVATE DIALOG oDlg

RETURN Nil

