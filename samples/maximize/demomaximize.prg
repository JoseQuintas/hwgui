/*
 * $Id:
 *
 * HWGUI demo for screen Maximized
 * 
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
 *
 * Copyright 2004 Sandro <sandrorrfreire@yahoo.com.br>
 * 
*/

#include "windows.ch"
#include "guilib.ch"
 
* --------------------------------------------
function Main
* --------------------------------------------
Private oMain, temp1
Private oDlg
Private oFont := Nil
 
   INIT WINDOW oMain MAIN TITLE "Demo Maximize"

    MENU OF oMain
      MENU TITLE "&Arquivo"

         MENUITEM "&Maximize   " ACTION oMain:Maximize()
         MENUITEM "&Minimize   " ACTION oMain:Minimize()
         MENUITEM "&Restore    " ACTION oMain:Restore()
         MENUITEM "&Center     " ACTION oMain:Center()
         MENUITEM "&Sair" ACTION EndWindow()

      ENDMENU
    ENDMENU

    ACTIVATE WINDOW oMain MAXIMIZED
 
return nil
 
