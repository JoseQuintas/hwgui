/*
 * hello.prg
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * Sample program to demonstrate
 *   HGraph class to draw graphs and
 *   HBoard, HDrawn classes to draw control items on a drawing area
 *
 * Copyright 2005-2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgui.ch"

#define CLR_BLACK           0
#define CLR_DGRAY1   0x222222
#define CLR_DGRAY2   0x555555
#define CLR_DGRAY3   0x888888
#define CLR_WHITE    0xFFFFFF

FUNCTION Main()

   LOCAL oMain, oPaneHea, oPaneTop, oGraph, oPaneDrawn, oFont
   LOCAL oStyleNormal, oStylePressed, oStyleOver
   LOCAL aCorners := { 4,4,4,4 }
   LOCAL aStyles := { HStyle():New( { CLR_DGRAY2 }, 1, aCorners ), ;
      HStyle():New( { CLR_WHITE }, 2, aCorners ), ;
      HStyle():New( { CLR_DGRAY3 }, 1, aCorners ) }

   PREPARE FONT oFont NAME "Georgia" WIDTH 0 HEIGHT -17 ITALIC

   oStyleNormal := HStyle():New( {0x7b7680,0x5b5760}, 1 )
   oStylePressed := HStyle():New( {0x7b7680}, 1,, 2, CLR_WHITE )
   oStyleOver := HStyle():New( {0x7b7680}, 1 )

   INIT WINDOW oMain MAIN TITLE "Example" AT 200, 0 SIZE 400, 320 ;
      BACKCOLOR 0x3C3940 FONT oFont STYLE WND_NOTITLE + WND_NOSIZEBOX

   ADD HEADER PANEL oPaneHea HEIGHT 32 TEXTCOLOR 0xFFFFFF BACKCOLOR 0x2F343F ;
      FONT oFont TEXT "Graphs" COORS 20 BTN_CLOSE BTN_MINIMIZE

   oPaneHea:SetSysbtnColor( 0xffffff, 0x7b7680 )

   @ 30, 50 GRAPH oGraph DATA Nil SIZE 340, 250 COLOR 65280

   oPaneDrawn := HDrawn():New( oGraph, 4, 4, 96, 180, CLR_WHITE, CLR_BLACK,,,,,, ;
      {|o,n|o:lHide:=(n==0),o:Refresh(),-1} )
   HDrawn():New( oPaneDrawn, 12, 12, 40, 30, CLR_WHITE, CLR_BLACK, aStyles, '1', oFont,, {|| Graph1() } )
   HDrawn():New( oPaneDrawn, 12, 56, 40, 30, CLR_WHITE, CLR_BLACK, aStyles, '2', oFont,, {|| Graph2() } )
   HDrawn():New( oPaneDrawn, 12, 96, 40, 30, CLR_WHITE, CLR_BLACK, aStyles, '3', oFont,, {|| Graph3() } )
   HDrawn():New( oPaneDrawn, 12, 136, 80, 30, CLR_WHITE, CLR_BLACK, aStyles, 'Exit', oFont,, {|| hwg_EndWindow() } )

   ACTIVATE WINDOW oMain

RETURN Nil

STATIC FUNCTION Graph1()

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

STATIC FUNCTION Graph2()

   LOCAL oGraph, i, aGraph := { {} }

   FOR i := 1 TO 8
      AAdd( aGraph[1], i * i )
   NEXT

   oGraph := HWindow():GetMain():oGraph
   oGraph:nGraphs := 1

   oGraph:Rebuild( aGraph, 2 )

RETURN Nil

STATIC FUNCTION Graph3()

   LOCAL oGraph, i, aGraph := { {} }

   FOR i := 1 TO 6
      AAdd( aGraph[1], { "", i * i } )
   NEXT

   oGraph := HWindow():GetMain():oGraph
   oGraph:nGraphs := 1

   oGraph:Rebuild( aGraph, 3 )

RETURN Nil
