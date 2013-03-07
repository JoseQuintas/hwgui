#include "windows.ch"
#include "guilib.ch"

Function Main
Local oMainWindow
Local oSplash


   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 0,0 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION oMainWindow:Close()
   ENDMENU

   //oSplash := HSplash():Create( "Hwgui.bmp",2000)
   SPLASH oSplash TO "hwgui.bmp" TIME 2000

   ACTIVATE WINDOW oMainWindow

Return Nil

 
