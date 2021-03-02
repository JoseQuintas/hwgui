/*
 *
 * testspli.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Sample for split windows
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2021 Wilfried Brunken, DF7BE
*/

   * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes

/*
 Modifications by DF7BE:
 - Removed Borland resource file,
   substituded by HWGUI commands,
   now ready for multi platform
 - Cursor files by hex value
   (prepared for GTK)
   but needed to implement as next
 - Custom cursor from file 
 
 Contents of deleted rc file "testspli.rc":
 VSPLIT CURSOR "SPLITV.cur"
 HSPLIT CURSOR "SPLITH.cur"
 ==> substitute by equal cursor's from stock.
*/


#include "windows.ch"
#include "guilib.ch"
#ifdef __GTK__
#include "gtk.ch"
#endif


Function Main
Local oMainWindow, oFont, oSplitV, oSplitH, oEdit1, oEdit2

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13

   INIT WINDOW oMainWindow MAIN TITLE "Split windows example"  ;
     SYSCOLOR COLOR_3DLIGHT+1                    ;
     AT 200,0 SIZE 420,300                       ;
     FONT oFont

   @ 20,10 TREE oTree SIZE 140,100

   oTree:AddNode( "First" )
   oTree:AddNode( "Second" )
   oItem := oTree:AddNode( "Third" )
   oItem:AddNode( "Third-1" )
   oTree:AddNode( "Forth" )

   @ 163,10 EDITBOX oEdit1 CAPTION "Hello, World!"  SIZE 200,100

   @ 160,10 SPLITTER oSplitV SIZE 3,100 DIVIDE {oTree} FROM {oEdit1} LIMITS 100,300
#ifdef __GTK__   
*   oSplitV:hCursor := hwg_Loadcursor( GDK_SB_H_DOUBLE_ARROW  )  && "VSPLIT"
*   oSplitV:hCursor := hwg_LoadCursorFromFile("transistor.cur",7,7)   && Test
   oSplitV:hCursor := hwg_LoadCursorFromFile("splitv.cur",16,16)   
#else
*   oSplitV:hCursor := hwg_Loadcursor( 32644 )  && IDC_SIZEWE from stock optional
   oSplitV:hCursor := hwg_LoadCursorFromFile("splitv.cur")
#endif   

   @ 20,113 EDITBOX oEdit2 CAPTION "Example"  SIZE 344,130

   @ 20,110 SPLITTER oSplitH SIZE 344,3 DIVIDE {oTree,oEdit1,oSplitV} FROM {oEdit2} LIMITS ,220
#ifdef __GTK__   
*   oSplitH:hCursor := hwg_Loadcursor( GDK_SB_V_DOUBLE_ARROW  )  && "HSPLIT"
   oSplitH:hCursor := hwg_LoadCursorFromFile("splith.cur",16,16)
#else
*   oSplitH:hCursor := hwg_Loadcursor( 32645 ) && IDC_SIZENS from stock optional
   oSplitH:hCursor := hwg_LoadCursorFromFile("splith.cur") 
#endif

   ACTIVATE WINDOW oMainWindow

Return nil

FUNCTION hex_splith()
* Hex value of splith.cur
RETURN ;
"00 00 02 00 01 00 20 20 00 00 0E 00 0C 00 30 01 " + ;
"00 00 16 00 00 00 28 00 00 00 20 00 00 00 40 00 " + ;
"00 00 01 00 01 00 00 00 00 00 80 00 00 00 00 00 " + ;
"00 00 00 00 00 00 02 00 00 00 00 00 00 00 00 00 " + ;
"00 00 FF FF FF 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 " + ;
"00 00 00 05 00 00 00 08 80 00 00 10 40 00 00 20 " + ;
"20 00 00 3D E0 00 00 05 00 00 03 FF FE 00 02 00 " + ;
"02 00 03 FF FE 00 02 00 02 00 03 FF FE 00 00 05 " + ;
"00 00 00 3D E0 00 00 20 20 00 00 10 40 00 00 08 " + ;
"80 00 00 05 00 00 00 02 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FD " + ;
"FF FF FF F8 FF FF FF F0 7F FF FF E0 3F FF FF C0 " + ;
"1F FF FF C0 1F FF FF F8 FF FF FC 00 01 FF FC 00 " + ;
"01 FF FC 00 01 FF FC 00 01 FF FC 00 01 FF FF F8 " + ;
"FF FF FF C0 1F FF FF C0 1F FF FF E0 3F FF FF F0 " + ;
"7F FF FF F8 FF FF FF FD FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF "


FUNCTION hex_splitv
* Hex value of splitv.cur
RETURN ;
"00 00 02 00 01 00 20 20 00 00 10 00 0E 00 30 01 " + ;
"00 00 16 00 00 00 28 00 00 00 20 00 00 00 40 00 " + ;
"00 00 01 00 01 00 00 00 00 00 80 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 FF FF FF 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 03 E0 00 00 02 " + ;
"A0 00 00 02 A0 00 00 02 A0 00 00 1A AC 00 00 2A " + ;
"AA 00 00 4A A9 00 00 8E B8 80 01 02 A0 40 00 8E " + ;
"B8 80 00 4A A9 00 00 2A AA 00 00 1A AC 00 00 02 " + ;
"A0 00 00 02 A0 00 00 02 A0 00 00 03 E0 00 00 00 " + ;
"00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 " + ;
"00 00 00 00 00 00 FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FC 1F FF FF FC " + ;
"1F FF FF FC 1F FF FF FC 1F FF FF E4 13 FF FF C4 " + ;
"11 FF FF 84 10 FF FF 00 00 7F FE 00 00 3F FF 00 " + ;
"00 7F FF 84 10 FF FF C4 11 FF FF E4 13 FF FF FC " + ;
"1F FF FF FC 1F FF FF FC 1F FF FF FC 1F FF FF FF " + ;
"FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF " + ;
"FF FF FF FF FF FF "

* ================================ EOF of testspli.prg ===============================

