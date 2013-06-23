/*
 * $Id: TestMenuBitmap.prg,v 1.6 2004/05/05 18:27:14 sandrorrfreire Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level menu functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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
             SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

               MENU OF oMain
                  MENU TITLE "Samples"
                     MENUITEM "&Exit"    ID 1001 ACTION oMain:Close()   BITMAP "\hwgui\image\exit_m.bmp" 
                     SEPARATOR                      
                     MENUITEM "&New "    ID 1002 ACTION hwg_Msginfo("New")  BITMAP "\hwgui\image\new_m.bmp"  
                     MENUITEM "&Open"    ID 1003 ACTION hwg_Msginfo("Open") BITMAP "\hwgui\image\open_m.bmp" 
                     MENUITEM "&Demo"    ID 1004 ACTION Test()
                     separator
                     MENUITEM "&Bitmap and a Text"  ID 1005 ACTION Test()
                  ENDMENU   
                ENDMENU                
                //The number ID is very important to use bitmap in menu
                MENUITEMBITMAP oMain ID 1005 BITMAP "\hwgui\image\logo.bmp"                 
                //Hwg_InsertBitmapMenu(oMain:Menu, 1005, "\hwgui\sourceoBmp:handle)   //do not use bitmap empty
        ACTIVATE WINDOW oMain
Return Nil

Function Test()
hwg_Msginfo("Test")
Return Nil

 
