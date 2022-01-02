*
* $Id$
*
* HWGUI test tray sample especially for GTK/LINUX
*
* Copyright 2022 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details.
*
* Special information:
* The behavior on LINUX differs:
* - The main window is visible at start time
*   but the tray menu works as usual under LINUX
*   

#include "windows.ch"
#include "guilib.ch"

FUNCTION Main
   LOCAL oMainWindow, oTrayMenu
   // LOCAL oIcon1 := HIcon():AddResource( "ICON_1" )
   // LOCAL oIcon2 := HIcon():AddResource( "ICON_2" )
   
   LOCAL oIcon1 := HIcon():AddFile("../../image/ok.ico")
   LOCAL oIcon2 := HIcon():AddFile("../../image/cancel.ico") 

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
   ICON oIcon1

   // CONTEXT MENU oTrayMenu
   MENU OF oMainWindow 
    MENU TITLE "&Tray menu"
     MENUITEM "Message"  ACTION hwg_Msginfo( "Tray Message !" )
     // MENUITEM "Change icon"  ACTION hwg_ShellModifyicon( oMainWindow:handle, oIcon2:handle )
     SEPARATOR
     MENUITEM "Exit"  ACTION hwg_EndWindow()
    ENDMENU 
   ENDMENU

   // oMainWindow:InitTray( oIcon1, oTrayMenu:aMenu[1,1,1], oTrayMenu, "TestTray" )
   oMainWindow:DEICONIFY()

   ACTIVATE WINDOW oMainWindow && NOSHOW
   // oTrayMenu:End()

   RETURN Nil
   
* ============================= EOF of testtray.prg =========================================   
