/*
 * $Id: grid_1.prg,v 1.1 2008-09-19 19:15:55 sandrorrfreire Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

#include "windows.ch"
#include "guilib.ch"

Static oMain, oForm, oFont, oGrid

Function Main()

        INIT WINDOW oMain MAIN TITLE "Grid Sample" ;
             AT 0,0 ;
             SIZE GetDesktopWidth(), GetDesktopHeight() - 28

                MENU OF oMain
                        MENUITEM "&Exit"      ACTION oMain:Close()
                        MENUITEM "&Grid Demo" ACTION Test()
                ENDMENU

        ACTIVATE WINDOW oMain
Return Nil

Function Test()
        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11
        
        INIT DIALOG oForm CLIPPER NOEXIT TITLE "Grid Demo";
             FONT oFont ;
             AT 0, 0 SIZE 700, 425 ;
             STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU
                
             @ 10,10 GRID oGrid OF oForm SIZE 680,375;
                     ITEMCOUNT 10000 ;
                     ON KEYDOWN {|oCtrl, key| OnKey(oCtrl, key) } ;
                     ON POSCHANGE {|oCtrl, nRow| OnPoschange(oCtrl, nRow) } ;
                     ON CLICK {|oCtrl| OnClick(oCtrl) } ;
                     ON DISPINFO {|oCtrl, nRow, nCol| OnDispInfo( oCtrl, nRow, nCol ) } ;
                     COLOR VColor('D3D3D3');
                     BACKCOLOR VColor('BEBEBE') 

             ADD COLUMN TO GRID oGrid HEADER "Column 1" WIDTH 150
             ADD COLUMN TO GRID oGrid HEADER "Column 2" WIDTH 150
             ADD COLUMN TO GRID oGrid HEADER "Column 3" WIDTH 150
                                                              
             @ 620, 395 BUTTON 'Close' SIZE 75,25 ON CLICK {|| oForm:Close() }                            
             
        ACTIVATE DIALOG oForm
                
Return Nil

Function OnKey( o, k )
//    msginfo(str(k))
return nil    

Function OnPosChange( o, row )
//    msginfo( str(row) )
return nil    

Function OnClick( o )
//    msginfo( 'click' )
return nil    

Function OnDispInfo( o, x, y )
return 'Row: ' + ltrim(str(x)) + ' Col: ' + ltrim(str(y))

