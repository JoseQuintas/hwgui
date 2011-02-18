#include "windows.ch"
#include "guilib.ch"

Function Main ()

   Local oWnd

   INIT WINDOW oWnd MAIN TITLE "Menu with messages" ;
      COLOR COLOR_3DLIGHT+1 ;
      AT 100,100 SIZE 640,480

   MENU OF oWnd
      MENU TITLE "Menu 1"
         MENUITEM "Option 1.1" ACTION MsgInfo("Option 1.1") MESSAGE "Message: Option 1.1"
         MENUITEM "Option 1.2" ACTION MsgInfo("Option 1.2") MESSAGE "Message: Option 1.2"
         MENU TITLE "Option 1.3"
            MENUITEM "Option 1.3.1" ACTION MsgInfo("Option 1.3.1") MESSAGE "Message: Option 1.3.1"
            MENUITEM "Option 1.3.2" ACTION MsgInfo("Option 1.3.2") // MESSAGE "Message: Option 1.3.2"
         ENDMENU
         MENU TITLE "Option 1.4"
            MENUITEM "Option 1.4.1" ACTION MsgInfo("Option 1.4.1") MESSAGE "Message: Option 1.4.1"
            MENUITEM "Option 1.4.2" ACTION MsgInfo("Option 1.4.2") // MESSAGE "Message: Option 1.4.2"
         ENDMENU
         MENUITEM "Option 1.5" ACTION MsgInfo("Option 1.5") MESSAGE "Message: Option 1.5"
         MENUITEM "Option 1.6" ACTION MsgInfo("Option 1.6") MESSAGE "Message: Option 1.6"
         MENUITEM "Option 1.7" ACTION MsgInfo("Option 1.7") MESSAGE "Message: Option 1.7"
      ENDMENU
      MENU TITLE "Menu 2"
         MENUITEM "Option 2.1" ACTION MsgInfo("Option 2.1") MESSAGE "Message: Option 2.1"
         MENUITEM "Option 2.2" ACTION MsgInfo("Option 2.2") // MESSAGE "Message: Option 2.2"
         MENUITEM "Option 2.3" ACTION MsgInfo("Option 2.3") MESSAGE "Message: Option 2.3"
         MENUITEM "Option 2.4" ACTION MsgInfo("Option 2.4") // MESSAGE "Message: Option 2.4"
         MENUITEM "Option 2.5" ACTION MsgInfo("Option 2.5") MESSAGE "Message: Option 2.5"
      ENDMENU
      MENU TITLE "Menu 3"
         MENUITEM "Option 3.1" ACTION MsgInfo("Option 3.1") MESSAGE "Message: Option 3.1"
         MENUITEM "Option 3.2" ACTION MsgInfo("Option 3.2") MESSAGE "Message: Option 3.2"
         MENUITEM "Option 3.3" ACTION MsgInfo("Option 3.3") MESSAGE "Message: Option 3.3"
         MENUITEM "Option 3.4" ACTION MsgInfo("Option 3.4") MESSAGE "Message: Option 3.4"
         MENUITEM "Option 3.5" ACTION MsgInfo("Option 3.5") MESSAGE "Message: Option 3.5"
      ENDMENU
   ENDMENU

   // comment the line below to test withou StatusBar
   ADD STATUS TO oWnd PARTS 320,320

   ACTIVATE WINDOW oWnd

   Return Nil

