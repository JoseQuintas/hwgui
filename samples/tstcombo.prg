/*
 * $Id: tstcombo.prg,v 1.2 2004/05/13 12:46:20 rodrigo_moreno Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGrid class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 * Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
 *
*/

#include "windows.ch"
#include "guilib.ch"

Static oMain, oForm, oFont, oBar

Function Main()

        INIT WINDOW oMain MAIN TITLE "ComboBox Sample" ;
             AT 0,0 ;
             SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

                MENU OF oMain
                        MENUITEM "&Exit" ACTION oMain:Close()
                        MENUITEM "&Demo" ACTION Test()
                ENDMENU

        ACTIVATE WINDOW oMain
Return Nil

Function Test()
        Local nCombo := 1
        Local cCombo := 'Four'
        Local xCombo := 'Test'
        Local aItems := {'First', 'Second', 'Third', 'Four'}
        Local cEdit  := Space(50)
        Local oCombo1, oCombo2, oCombo3, oCombo4, oCombo5, oCombo6
        
        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

        INIT DIALOG oForm CLIPPER NOEXIT TITLE "ComboBox Demo";
             FONT oFont ;
             AT 0, 0 SIZE 700, 425 ;
             STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

            @ 20, 20 GET COMBOBOX oCombo1 VAR nCombo ITEMS aItems SIZE 100, 150 
            @ 20, 50 GET COMBOBOX oCombo2 VAR cCombo ITEMS aItems SIZE 100, 150 TEXT 
            @ 20, 80 GET COMBOBOX oCombo3 VAR xCombo ITEMS aItems SIZE 100, 150 EDIT TOOLTIP 'Type any thing here'
            
            @ 20,110 COMBOBOX oCombo4 ITEMS aItems SIZE 100, 150
            @ 20,140 COMBOBOX oCombo5 ITEMS aItems SIZE 100, 150 TEXT
            @ 20,170 COMBOBOX oCombo6 ITEMS aItems SIZE 100, 150 EDIT

            @ 20,200 GET cEdit SIZE 150,23
                         
            @ 380, 395 BUTTON 'Test'    SIZE 75,25 ON CLICK {|| xCombo := 'Temp', oCombo3:refresh(), nCombo := 2, oCombo1:refresh(), oCombo2:SetItem(3), oCombo4:SetItem(3), oCombo5:value := 'Third', oCombo5:refresh(), oCombo6:SetItem(2) }
            @ 460, 395 BUTTON 'Combo 1' SIZE 75,25 ON CLICK {|| hwg_Msginfo(str(nCombo)) }
            @ 540, 395 BUTTON 'Combo 2' SIZE 75,25 ON CLICK {|| hwg_Msginfo(cCombo, xCombo) }
            @ 620, 395 BUTTON 'Close'   SIZE 75,25 ON CLICK {|| oForm:Close() }

        ACTIVATE DIALOG oForm
Return Nil

