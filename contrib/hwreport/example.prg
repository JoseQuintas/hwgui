/*
 * Example of printing reports, using HWReport
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "fileio.ch"
#include "windows.ch"
#include "guilib.ch"
#include "repmain.h"

#define IDCW_PANEL   2001

Function Main()
Local oMainWindow, oPanel, oFont
Local hDCwindow
PRIVATE aTermMetr := { 800 }

   SET EPOCH TO 1960
   SET DATE FORMAT "dd/mm/yyyy"

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

   INIT WINDOW oMainWindow MAIN TITLE "HWReport example" ;
         ON SIZE {|o|hwg_Movewindow(o:handle,0,0,aTermMetr[1],80)}

   @ 0,0 PANEL oPanel OF oMainWindow ID IDCW_PANEL ;
        ON SIZE {|o,x|hwg_Movewindow(o:handle,0,0,x,48)}

    @ 2,3  OWNERBUTTON OF oPanel ID 113 ON CLICK {||hwg_EndWindow()} ;
        SIZE 80,44 FLAT ;
        TEXT "Exit" COLOR hwg_ColorC2N("0000FF") FONT oFont
    @ 82,3 OWNERBUTTON OF oPanel ID 108 ON CLICK {||Print1()} ;
        SIZE 120,22 FLAT ;
        TEXT "Print Example.rpt" COLOR hwg_ColorC2N("FF0000") FONT oFont
    @ 82,25 OWNERBUTTON OF oPanel ID 109 ON CLICK {||Print2()} ;
        SIZE 120,22 FLAT ;
        TEXT "Print MyReport()" COLOR hwg_ColorC2N("E60099") FONT oFont

   hDCwindow := hwg_Getdc( oMainWindow:handle )
   aTermMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Deletedc( hDCwindow )

   oMainWindow:Activate()

Return Nil

Static Function Print1
   IF OpenReport( "example.rpt", "MyReport" ) 
      hwg_PrintReport()
   ENDIF
Return Nil

Static Function Print2
   MyReport()
   hwg_PrintReport()
Return Nil

FUNCTION MyReport
LOCAL aPaintRep
   cEnd:=Chr(13)+Chr(10)
   aPaintRep := { 210,297,0,0,0,{},,"MyReport",.F.,0,Nil }
   aPaintRep[11] := ;
     "nStroka := 1"+cEnd
   Aadd( aPaintRep[6], { 1,"Sample report - first 100 records of test.dbf",132,41,513,27,2,0,HFont():Add( "Arial",0,-18,700,204,0,0,0 ),0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 5,"..\..\samples\Image\logo.bmp",94,44,68,61,0,0,0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"2001",320,81,89,20,2,0,HFont():Add( "Arial",0,-18,700,204,0,0,0 ),0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 2,,182,106,408,6,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 6,"PH",-16,172,16,10,0,0,0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 4,,110,174,60,40,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 4,,168,174,200,40,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 4,,366,174,200,40,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 4,,564,174,60,40,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"Last name",424,183,103,20,2,0,HFont():Add( "MS Sans Serif",0,-13,0,0,0,0,0 ),0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"Nn",123,184,33,20,2,0,HFont():Add( "Arial",0,-13,0,0,0,0,0 ),0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"First name",229,184,93,20,2,0,HFont():Add( "MS Sans Serif",0,-13,0,0,0,0,0 ),0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"Age",578,184,37,20,2,0,HFont():Add( "MS Sans Serif",0,-13,0,0,0,0,0 ),0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 6,"SL",-16,218,16,10,0,0,0,0,0,Nil,0 } )
   aPaintRep[6,Len(aPaintRep[6]),12] := ;
     "use test"+cEnd;
     + "go top"+cEnd
   Aadd( aPaintRep[6], { 4,,110,218,60,26,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 4,,168,218,200,26,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 4,,366,218,201,26,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 4,,565,218,59,26,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"Str(nStroka,2)",119,220,40,17,0,0,HFont():Add( "Arial",0,-13,0,0,0,0,0 ),1,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"First",179,220,182,17,0,0,HFont():Add( "MS Sans Serif",0,-13,0,0,0,0,0 ),1,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"Last",381,220,176,17,0,0,HFont():Add( "MS Sans Serif",0,-13,0,0,0,0,0 ),1,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"Str(Age,2)",578,220,36,16,0,0,HFont():Add( "MS Sans Serif",0,-13,0,0,0,0,0 ),1,0,Nil,0 } )
   Aadd( aPaintRep[6], { 6,"EL",-16,243,16,10,0,0,0,0,0,Nil,0 } )
   aPaintRep[6,Len(aPaintRep[6]),12] := ;
     "skip"+cEnd;
     + "nStroka++"+cEnd;
     + "lLastCycle := (Recno()>=20)"+cEnd
   Aadd( aPaintRep[6], { 6,"PF",-16,861,16,10,0,0,0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 2,,46,867,661,6,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 6,"EPF",-16,875,16,10,0,0,0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 6,"DF",-16,899,16,10,0,0,0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 2,,459,924,238,6,0,HPen():Add(0,1,0),0,0,0,Nil,0 } )
   Aadd( aPaintRep[6], { 1,"End of report",522,932,160,20,0,0,HFont():Add( "MS Sans Serif",0,-13,0,0,0,0,0 ),0,0,Nil,0 } )
   hwg_RecalcForm( aPaintRep,735 )
RETURN hwg_SetPaintRep( aPaintRep )

