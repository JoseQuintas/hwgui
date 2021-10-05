/*
 * Example of printing reports, using HWReport
 *
 * $Id$
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "fileio.ch"
#include "hwgui.ch"
#include "repmain.h"

FUNCTION Main()
   LOCAL oMainWindow, oPanel, oFont

   SET EPOCH TO 1960
   SET DATE FORMAT "dd/mm/yyyy"

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT - 12

   INIT WINDOW oMainWindow MAIN TITLE "HWReport example" SIZE 240, 100

   @ 0, 0 PANEL oPanel OF oMainWindow ;
      ON SIZE { |o, x|hwg_Movewindow( o:handle, 0, 0, x, 50 ) }

   @ 2, 3  OWNERBUTTON OF oPanel ON CLICK { ||hwg_EndWindow() } ;
      SIZE 80, 44 FLAT ;
      TEXT "Exit" COLOR hwg_ColorC2N( "0000FF" ) FONT oFont

   @ 82, 3 OWNERBUTTON OF oPanel ON CLICK { ||Print1() } ;
      SIZE 120, 22 FLAT ;
      TEXT "Print Example.rpt" COLOR hwg_ColorC2N( "FF0000" ) FONT oFont
   @ 82, 25 OWNERBUTTON OF oPanel ON CLICK { ||Print2() } ;
      SIZE 120, 22 FLAT ;
      TEXT "Print MyReport()" COLOR hwg_ColorC2N( "E60099" ) FONT oFont

   oMainWindow:Activate()

   RETURN Nil

STATIC FUNCTION Print1

   IF hwg_OpenReport( "example.rpt", "MyReport" )
      hwg_PrintReport( ,, .T. )
   ENDIF

   RETURN Nil

STATIC FUNCTION Print2

   MyReport()
   hwg_PrintReport( ,, .T. )

   RETURN Nil

FUNCTION MyReport
   LOCAL aPaintRep , crlf := Chr( 13 ) + Chr( 10 )

   aPaintRep := { 210, 297, 0, 0, 0, {}, , "MyReport", .F. , 0, Nil }
   aPaintRep[11] := "nStroka := 1" + crlf

   AAdd( aPaintRep[6], { 1, "Sample report - first 100 records of test.dbf", 132, 41, 513, 27, 2, 0, HFont():Add( "Arial",0, - 18,700,204,0,0,0 ), 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 5, "..\..\samples\Image\logo.bmp", 94, 44, 68, 61, 0, 0, 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "2001", 320, 81, 89, 20, 2, 0, HFont():Add( "Arial",0, - 18,700,204,0,0,0 ), 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 2, , 182, 106, 408, 6, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 6, "PH", - 16, 172, 16, 10, 0, 0, 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 4, , 110, 174, 60, 40, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 4, , 168, 174, 200, 40, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 4, , 366, 174, 200, 40, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 4, , 564, 174, 60, 40, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "Last name", 424, 183, 103, 20, 2, 0, HFont():Add( "MS Sans Serif",0, - 13,0,0,0,0,0 ), 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "Nn", 123, 184, 33, 20, 2, 0, HFont():Add( "Arial",0, - 13,0,0,0,0,0 ), 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "First name", 229, 184, 93, 20, 2, 0, HFont():Add( "MS Sans Serif",0, - 13,0,0,0,0,0 ), 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "Age", 578, 184, 37, 20, 2, 0, HFont():Add( "MS Sans Serif",0, - 13,0,0,0,0,0 ), 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 6, "SL", - 16, 218, 16, 10, 0, 0, 0, 0, 0, Nil, 0 } )
   aPaintRep[6,Len(aPaintRep[6] ), 12] := ;
      "use test" + crlf;
      + "go top" + crlf
   AAdd( aPaintRep[6], { 4, , 110, 218, 60, 26, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 4, , 168, 218, 200, 26, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 4, , 366, 218, 201, 26, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 4, , 565, 218, 59, 26, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "Str(nStroka,2)", 119, 220, 40, 17, 0, 0, HFont():Add( "Arial",0, - 13,0,0,0,0,0 ), 1, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "First", 179, 220, 182, 17, 0, 0, HFont():Add( "MS Sans Serif",0, - 13,0,0,0,0,0 ), 1, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "Last", 381, 220, 176, 17, 0, 0, HFont():Add( "MS Sans Serif",0, - 13,0,0,0,0,0 ), 1, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "Str(Age,2)", 578, 220, 36, 16, 0, 0, HFont():Add( "MS Sans Serif",0, - 13,0,0,0,0,0 ), 1, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 6, "EL", - 16, 243, 16, 10, 0, 0, 0, 0, 0, Nil, 0 } )
   aPaintRep[6,Len(aPaintRep[6] ), 12] := ;
      "skip" + crlf;
      + "nStroka++" + crlf;
      + "lLastCycle := (Recno()>=20)" + crlf
   AAdd( aPaintRep[6], { 6, "PF", - 16, 861, 16, 10, 0, 0, 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 2, , 46, 867, 661, 6, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 6, "EPF", - 16, 875, 16, 10, 0, 0, 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 6, "DF", - 16, 899, 16, 10, 0, 0, 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 2, , 459, 924, 238, 6, 0, HPen():Add( 0,1,0 ), 0, 0, 0, Nil, 0 } )
   AAdd( aPaintRep[6], { 1, "End of report", 522, 932, 160, 20, 0, 0, HFont():Add( "MS Sans Serif",0, - 13,0,0,0,0,0 ), 0, 0, Nil, 0 } )
   hwg_RecalcForm( aPaintRep, 735 )

   RETURN hwg_SetPaintRep( aPaintRep )

   // ============================= EOF of example.prg ================================
