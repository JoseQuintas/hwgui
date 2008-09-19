/*
 * Demo hbrowse
 */

#include "windows.ch"
#include "guilib.ch"

***********************
STATIC FUNCTION Main()
***********************
LOCAL oWinMain
local i, a, b

    INIT WINDOW oWinMain MAIN  ;
        TITLE "Test scroll in HBrowse" AT 0, 0 SIZE 600,400;
        FONT HFont():Add( 'Arial',0,-13,400,,,) ;
        STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER 

    @  10, 20 BROWSE oBrw1 ARRAY SIZE 180, 325 
    @ 200, 20 BROWSE oBrw2 ARRAY SIZE 180, 325 

    a := { } 
    for i := 1 to 16
        aAdd( a, { i, chr( asc("a")-1+i) } )
    next
    for i := 1 to 16
        aAdd( a, { i, chr( asc("A")-1+i) } )
    next
    for i := 1 to 16
        aAdd( a, { i, chr( asc("a")-1+i) } )
    next

    oBrw1:aArray := a
    CreateArList( oBrw1, a )
    oBrw1:aColumns[1]:length := 5
    oBrw1:aColumns[2]:length := 5
    oBrw1:aColumns[1]:width := 50
    oBrw1:aColumns[2]:width := 50

    b := { } 
    for i := 1 to 5
        aAdd( b, { i, chr( asc("a")-1+i) } )
    next

    oBrw2:aArray := b
    CreateArList( oBrw2, b )
    oBrw2:lAdjRight := .F.
    oBrw2:aColumns[1]:length := 5
    oBrw2:aColumns[2]:length := 5
    oBrw2:aColumns[1]:width := 50
    oBrw2:aColumns[2]:width := 50

    oWinMain:Activate()

RETURN(NIL)

