/*
 * Demo by HwGUI Alexander Kresin
 *  http://kresin.belgorod.su/
 *
 *
 */

#include "windows.ch"
#include "guilib.ch"

***********************
FUNCTION Main()
***********************
LOCAL oWinMain

    SET(_SET_DATEFORMAT, "dd/mm/yyyy")
    SET(_SET_EPOCH, 1950)

    INIT WINDOW oWinMain MAIN  ;
       TITLE "Teste" AT 0, 0 SIZE 600,400;
       FONT HFont():Add( 'Arial',0,-13,400,,,) ;
       STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER 

    @ 10 ,10 BROWSE oBrw ARRAY SIZE 180, 325 ;
	   AUTOEDIT  NO VSCROLL

    CreateArList( oBrw, { { "1","a" }, { "2","b" }, { "3","c" }, { "4","d" } } )

    oBrw:aColumns[1]:length := 5
    oBrw:aColumns[2]:length := 5

    oBrw:aColumns[1]:width := 50
    oBrw:aColumns[2]:width := 50

    oBrw:aColumns[1]:heading := "Campo"
    oBrw:aColumns[2]:heading := "Filtro"

    oBrw:aColumns[2]:lEditable = .T.

    oBrw:tColor := GetSysColor( COLOR_BTNTEXT )
    oBrw:tColorSel := 8404992
    oBrw:bColor := oBrw:bColorSel := GetSysColor( COLOR_BTNFACE )
    oBrw:freeze := 1
    oBrw:lDispHead := .T.
    oBrw:lSep3d := .T.
    oBrw:lAdjRight := .F.
    oBrw:sepColor  := GetSysColor( COLOR_BTNSHADOW )
    oBrw:colpos  := 2

    readexit(.T.) 
    oWinMain:Activate()

RETURN(NIL)

