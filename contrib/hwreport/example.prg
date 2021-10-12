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

   LOCAL aRep

   IF !Empty( aRep := hwg_hwr_Open( "example.rpt", "MyReport" ) )
      hwg_hwr_Print( aRep,, .T. )
      hwg_hwr_Close( aRep )
   ENDIF

   RETURN Nil

STATIC FUNCTION Print2

   LOCAL aRep

   aRep := MyReport()
   hwg_hwr_Print( aRep,, .T. )
   hwg_hwr_Close( aRep )

   RETURN Nil

FUNCTION MyReport

   LOCAL aPaintRep , crlf := Chr( 13 ) + Chr( 10 ), cScr

   aPaintRep := hwg_hwr_Init( "MyReport", 210, 297, 735, "nStroka := 1" + crlf )

   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "Sample report - first 100 records of test.dbf", 132, 41, 513, 27, 2,, HFont():Add( "Arial",0, - 18,700,204 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BITMAP, "..\..\samples\Image\logo.bmp", 94, 44, 68, 61 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "2001", 320, 81, 89, 20, 2,, HFont():Add( "Arial",0, - 18,700,204 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_HLINE, , 182, 106, 408, 6, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_MARKER, "PH", - 16, 172, 16, 10 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 110, 174, 60, 40, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 168, 174, 200, 40, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 366, 174, 200, 40, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 564, 174, 60, 40, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "Last name", 424, 183, 103, 20, 2,, HFont():Add( "MS Sans Serif",0, -13 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "Nn", 123, 184, 33, 20, 2,, HFont():Add( "Arial",0, - 13 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "First name", 229, 184, 93, 20, 2,, HFont():Add( "MS Sans Serif",0, - 13 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "Age", 578, 184, 37, 20, 2,, HFont():Add( "MS Sans Serif",0, - 13 ) )
   cScr :=  "use test" + crlf ;
     + "go top" + crlf
   hwg_Hwr_AddItem( aPaintRep, TYPE_MARKER, "SL", -16, 218, 16, 10,,,,, cScr ) 
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 110, 218, 60, 26, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 168, 218, 200, 26, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 366, 218, 201, 26, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_BOX, , 565, 218, 59, 26, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "Str(nStroka,2)", 119, 220, 40, 17, 0,, HFont():Add( "Arial",0, - 13 ), 1 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "First", 179, 220, 182, 17, 0,, HFont():Add( "MS Sans Serif",0, - 13 ), 1 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "Last", 381, 220, 176, 17, 0,, HFont():Add( "MS Sans Serif",0, - 13 ), 1 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "Str(Age,2)", 578, 220, 36, 16, 0,, HFont():Add( "MS Sans Serif",0, - 13 ), 1 )
   cScr :=  "skip" + crlf;
      + "nStroka++" + crlf;
      + "lLastCycle := (Recno()>=20)" + crlf
   hwg_Hwr_AddItem( aPaintRep, TYPE_MARKER, "EL", - 16, 243, 16, 10,,,,, cScr )
   hwg_Hwr_AddItem( aPaintRep, TYPE_MARKER, "PF", - 16, 861, 16, 10 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_HLINE, , 46, 867, 661, 6, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_MARKER, "EPF", - 16, 875, 16, 10 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_MARKER, "DF", - 16, 899, 16, 10 )
   hwg_Hwr_AddItem( aPaintRep, TYPE_HLINE, , 459, 924, 238, 6, 0, HPen():Add( 0,1,0 ) )
   hwg_Hwr_AddItem( aPaintRep, TYPE_TEXT, "End of report", 522, 932, 160, 20, 0,, HFont():Add( "MS Sans Serif",0, - 13 ) )

   RETURN aPaintRep

   // ============================= EOF of example.prg ================================
