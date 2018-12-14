#include "windows.ch"
#include "guilib.ch"

FUNCTION Main

   LOCAL oMain, oPaneHea, oPaneTop, oGraph, oFont
   LOCAL oStyleNormal, oStylePressed, oStyleOver

   PREPARE FONT oFont NAME "Georgia" WIDTH 0 HEIGHT -17 ITALIC

   oStyleNormal := HStyle():New( {0x7b7680,0x5b5760}, 1 )
   oStylePressed := HStyle():New( {0x7b7680}, 1,, 2, 0xffffff )
   oStyleOver := HStyle():New( {0x7b7680}, 1 )

   INIT WINDOW oMain MAIN TITLE "Example" AT 200, 0 SIZE 400, 320 ;
      BACKCOLOR 0x3C3940 FONT oFont STYLE WND_NOTITLE + WND_NOSIZEBOX

   ADD HEADER PANEL oPaneHea HEIGHT 32 TEXTCOLOR 0xFFFFFF BACKCOLOR 0x2F343F ;
      FONT oFont TEXT "Graphs" COORS 20 BTN_CLOSE BTN_MINIMIZE

   oPaneHea:SetSysbtnColor( 0xffffff, 0x7b7680 )

   @ 0, 32 PANEL oPaneTop SIZE 400, 48 HSTYLE oStyleNormal ;
      ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS

   @ 0,0 OWNERBUTTON OF oPaneTop SIZE 64,48 ;
         HSTYLES oStyleNormal, oStylePressed, oStyleOver TEXT "1" ;
         ON CLICK {||Graph1()}
   @ 64,0 OWNERBUTTON OF oPaneTop SIZE 64,48 ;
         HSTYLES oStyleNormal, oStylePressed, oStyleOver TEXT "2" ;
         ON CLICK {||Graph2()}
   //@ 128,0 OWNERBUTTON OF oPaneTop SIZE 64,48 ;
   //      HSTYLES oStyleNormal, oStylePressed, oStyleOver TEXT "3" ;
   //      ON CLICK {||Graph3()}

   @ 332,0 OWNERBUTTON OF oPaneTop SIZE 64,48 ;
         HSTYLES oStyleNormal, oStylePressed, oStyleOver TEXT "Exit" ;
         ON CLICK {||hwg_EndWindow()}

   @ 50, 100 GRAPH oGraph DATA Nil SIZE 300, 200 COLOR 65280

   ACTIVATE WINDOW oMain

   RETURN nil

STATIC FUNCTION Graph1
   LOCAL oGraph, i, aGraph := { {}, {} }

   FOR i := - 40 TO 40
      AAdd( aGraph[1], hwg_cos( i/10 ) )
      AAdd( aGraph[2], hwg_sin( i/10 ) )
   NEXT

   oGraph := HWindow():GetMain():oGraph
   oGraph:nGraphs := 2
   oGraph:aColors := { 255 }

   oGraph:Rebuild( aGraph, 1 )

   RETURN Nil

STATIC FUNCTION Graph2
   LOCAL oGraph, i, aGraph := { {} }

   FOR i := 1 TO 8
      AAdd( aGraph[1], i * i )
   NEXT

   oGraph := HWindow():GetMain():oGraph
   oGraph:nGraphs := 1

   oGraph:Rebuild( aGraph, 2 )

   RETURN Nil

STATIC FUNCTION Graph3
   LOCAL oGraph, i, aGraph := { {} }

   FOR i := 1 TO 6
      AAdd( aGraph[1], { "", i * i } )
   NEXT

   oGraph := HWindow():GetMain():oGraph
   oGraph:nGraphs := 1

   oGraph:Rebuild( aGraph, 3 )

   RETURN Nil
