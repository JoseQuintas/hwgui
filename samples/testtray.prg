#include "windows.ch"
#include "guilib.ch"

FUNCTION Main
   LOCAL oMainWindow, oTrayMenu
   LOCAL oIcon1 := HIcon():AddResource( "ICON_1" )
   LOCAL oIcon2 := HIcon():AddResource( "ICON_2" )

   INIT WINDOW oMainWindow MAIN TITLE "Example"

   CONTEXT MENU oTrayMenu
   MENUITEM "Message"  ACTION hwg_Msginfo( "Tray Message !" )
   MENUITEM "Change icon"  ACTION hwg_ShellModifyicon( oMainWindow:handle, oIcon2:handle )
   SEPARATOR
   MENUITEM "Exit"  ACTION hwg_EndWindow()
   ENDMENU

   oMainWindow:InitTray( oIcon1, oTrayMenu:aMenu[1,1,1], oTrayMenu, "TestTray" )

   ACTIVATE WINDOW oMainWindow NOSHOW
   oTrayMenu:End()

   RETURN Nil
