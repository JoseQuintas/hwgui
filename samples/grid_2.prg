/*
 * $Id: grid_2.prg,v 1.1 2004/04/05 14:16:35 rodrigo_moreno Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
 * This Sample use Postgres Library, you need to link libpq.lib and libhbpg.lib
 *
*/

#include "windows.ch"
#include "guilib.ch"
#include "common.ch"

#translate hwg_ColorRgb2N( <nRed>, <nGreen>, <nBlue> ) => ( <nRed> + ( <nGreen> * 256 ) + ( <nBlue> * 65536 ) )

Static oMain, oForm, oFont, oGrid, oServer, oQuery

Function Main()

        ConnectGrid()
        
        INIT WINDOW oMain MAIN TITLE "Grid Postgres Sample Using TPostgres" ;
             AT 0,0 ;
             SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

                MENU OF oMain
                        MENUITEM "&Exit"   ACTION oMain:Close()
                        MENUITEM "&Demo" ACTION Test()
                ENDMENU

        ACTIVATE WINDOW oMain
        
        oServer:Close()
        
Return Nil

Function Test()
        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11
        
        INIT DIALOG oForm CLIPPER NOEXIT TITLE "Postgres Sample";
             FONT oFont ;
             AT 0, 0 SIZE 700, 425 ;
             STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU
                
             @ 10,10 GRID oGrid OF oForm SIZE 680,375;
                     ITEMCOUNT oQuery:Lastrec() ;
                     COLOR hwg_ColorC2N('D3D3D3');
                     BACKCOLOR hwg_ColorRgb2N(220,220,220) ;
                     ON DISPINFO {|oCtrl, nRow, nCol| valtoprg(oQuery:FieldGet( nRow, nCol )) } 

             ADD COLUMN TO GRID oGrid HEADER "Column 1" WIDTH  50
             ADD COLUMN TO GRID oGrid HEADER "Column 2" WIDTH 200
             ADD COLUMN TO GRID oGrid HEADER "Column 3" WIDTH 100
                                                              
             @ 620, 395 BUTTON 'Close' SIZE 75,25 ON CLICK {|| oForm:Close() }                            
             
        ACTIVATE DIALOG oForm
Return Nil

Function ConnectGrid()
    Local cHost := 'Localhost'
    Local cDatabase := 'test'
    Local cUser := 'Rodrigo'
    Local cPass := 'moreno'
    Local oRow, i
    
    oServer := TPQServer():New(cHost, cDatabase, cUser, cPass)

    if oServer:NetErr()
        ? oServer:Error()
        quit
    end
    
    if oServer:TableExists('test')
        oServer:DeleteTable('Test')
    endif        
    
    oServer:CreateTable('Test', {{'col1', 'N', 6, 0},;
                                 {'col2', 'C', 40,0},;
                                 {'col3', 'D', 8, 0}})
        
    oQuery := oServer:Query('SELECT * FROM test')
                                     
    For i := 1 to 100
        oRow := oQuery:blank()
        
        oRow:Fieldput(1, i)
        oRow:Fieldput(2, 'teste line ' + str(i))
        oRow:Fieldput(3, date() + i)
        
        oQuery:Append(oRow)
    Next  
    
    oQuery:refresh()                                              
    
return nil        

