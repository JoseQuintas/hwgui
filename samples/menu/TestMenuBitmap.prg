/*
 * $Id: TestMenuBitmap.prg,v 1.2 2009-03-26 01:02:54 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level menu functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
 * Copyright 2004 Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
 * Demo for use Bitmap in menu
*/

#include "windows.ch"
#include "guilib.ch"

 
Function Main()
Local oMain
Private oMenu

        INIT WINDOW oMain MAIN TITLE "Teste" ;
             AT 0,0 ;//BACKGROUND BITMAP OBMP;
             SIZE GetDesktopWidth(), GetDesktopHeight() - 28

               MENU OF oMain
                  MENU TITLE "Samples"
                     MENUITEM "&Exit"    ID 1001 ACTION oMain:Close()   BITMAP "\hwgui\samples\image\exit_m.bmp" 
                     SEPARATOR                      
                     MENUITEM "&New "    ID 1002 ACTION msginfo("New")  BITMAP "\hwgui\samples\image\new_m.bmp"  
                     MENUITEM "&Open"    ID 1003 ACTION msginfo("Open") BITMAP "\hwgui\samples\image\open_m.bmp" 
                     MENUITEM "&Demo"    ID 1004 ACTION Test()
                     separator
                     MENUITEM "&Bitmap and a Text"  ID 1005 ACTION Test()
                  ENDMENU   
                ENDMENU                
                //The number ID is very important to use bitmap in menu
                MENUITEMBITMAP oMain ID 1005 BITMAP "\hwgui\samples\image\logo.bmp"                 
                //Hwg_InsertBitmapMenu(oMain:Menu, 1005, "\hwgui\sourceoBmp:handle)   //do not use bitmap empty
        ACTIVATE WINDOW oMain
Return Nil

Function Test()
MsgInfo("Test")
Return Nil

 
