/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * RepExec - Loading and executing of reports, built with RepBuild
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "guilib.ch"
#include "repmain.h"
#include "fileio.ch"
#include "common.ch"

// #define __DEBUG__

STATIC aPaintRep := Nil

REQUEST DBUseArea
REQUEST RecNo
REQUEST DBSkip
REQUEST DBGoTop
REQUEST DBCloseArea

FUNCTION hwg_ClonePaintRep( ar )

   aPaintRep := AClone( ar )
   RETURN Nil

FUNCTION hwg_SetPaintRep( ar )

   aPaintRep := ar
   RETURN Nil

FUNCTION hwg_OpenReport( fname, repName )

   LOCAL strbuf := Space( 512 ), poz := 513, stroka, nMode := 0
   LOCAL han
   LOCAL itemName, aItem, res := .T.
   LOCAL nFormWidth

   IF aPaintRep != Nil .AND. fname == aPaintRep[ FORM_FILENAME ] .AND. repName == aPaintRep[ FORM_REPNAME ]
      RETURN res
   ENDIF
   han := FOpen( fname, FO_READ + FO_SHARED )
   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han, @strbuf, @poz, 512 )
         IF Len( stroka ) = 0
            EXIT
         ENDIF
         IF Left( stroka, 1 ) == ";"
            LOOP
         ENDIF
         IF nMode == 0
            IF Left( stroka, 1 ) == "#"
               IF Upper( SubStr( stroka, 2, 6 ) ) == "REPORT"
                  stroka := LTrim( SubStr( stroka, 9 ) )
                  IF Upper( stroka ) == Upper( repName )
                     nMode := 1
                     aPaintRep := { 0, 0, 0, 0, 0, { }, fname, repName, .F., 0, Nil }
                  ENDIF
               ENDIF
            ENDIF
         ELSEIF nMode == 1
            IF Left( stroka, 1 ) == "#"
               IF Upper( SubStr( stroka, 2, 6 ) ) == "ENDREP"
                  EXIT
               ELSEIF Upper( SubStr( stroka, 2, 6 ) ) == "SCRIPT"
                  nMode := 2
                  IF aItem != Nil
                     aItem[ ITEM_SCRIPT ] := ""
                  ELSE
                     aPaintRep[ FORM_VARS ] := ""
                  ENDIF
               ENDIF
            ELSE
               IF ( itemName := NextItem( stroka, .T. ) ) == "FORM"
                  aPaintRep[ FORM_WIDTH ] := Val( NextItem( stroka ) )
                  aPaintRep[ FORM_HEIGHT ] := Val( NextItem( stroka ) )
                  nFormWidth := Val( NextItem( stroka ) )
                  aPaintRep[ FORM_XKOEF ] := nFormWidth / aPaintRep[ FORM_WIDTH ]
               ELSEIF itemName == "TEXT"
                  AAdd( aPaintRep[ FORM_ITEMS ], { 1, NextItem( stroka ), Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), 0, NextItem( stroka ), ;
                                                   Val( NextItem( stroka ) ), 0, Nil, 0 } )
                  aItem := ATail( aPaintRep[ FORM_ITEMS ] )
                  aItem[ ITEM_FONT ] := HFont():Add( NextItem( aItem[ ITEM_FONT ], .T., "," ), ;
                                                     Val( NextItem( aItem[ ITEM_FONT ],, "," ) ), Val( NextItem( aItem[ ITEM_FONT ],, "," ) ), ;
                                                     Val( NextItem( aItem[ ITEM_FONT ],, "," ) ), Val( NextItem( aItem[ ITEM_FONT ],, "," ) ), ;
                                                     Val( NextItem( aItem[ ITEM_FONT ],, "," ) ), Val( NextItem( aItem[ ITEM_FONT ],, "," ) ), ;
                                                     Val( NextItem( aItem[ ITEM_FONT ],, "," ) ) )
                  IF aItem[ ITEM_X1 ] == Nil .OR. aItem[ ITEM_X1 ] == 0 .OR. ;
                          aItem[ ITEM_Y1 ] == Nil .OR. aItem[ ITEM_Y1 ] == 0 .OR. ;
                          aItem[ ITEM_WIDTH ] == Nil .OR. aItem[ ITEM_WIDTH ] == 0 .OR. ;
                          aItem[ ITEM_HEIGHT ] == Nil .OR. aItem[ ITEM_HEIGHT ] == 0
                          hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "HLINE" .OR. itemName == "VLINE" .OR. itemName == "BOX"
                  AAdd( aPaintRep[ FORM_ITEMS ], { IIf( itemName == "HLINE", 2, IIf( itemName == "VLINE", 3, 4 ) ), ;
                                                   "", Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), 0, NextItem( stroka ), 0, 0, 0, Nil, 0 } )
                  aItem := ATail( aPaintRep[ FORM_ITEMS ] )
                  aItem[ ITEM_PEN ] := HPen():Add( Val( NextItem( aItem[ ITEM_PEN ], .T., "," ) ), ;
                                                   Val( NextItem( aItem[ ITEM_PEN ],, "," ) ), Val( NextItem( aItem[ ITEM_PEN ],, "," ) ) )
                  IF aItem[ ITEM_X1 ] == Nil .OR. aItem[ ITEM_X1 ] == 0 .OR. ;
                              aItem[ ITEM_Y1 ] == Nil .OR. aItem[ ITEM_Y1 ] == 0 .OR. ;
                              aItem[ ITEM_WIDTH ] == Nil .OR. aItem[ ITEM_WIDTH ] == 0 .OR. ;
                              aItem[ ITEM_HEIGHT ] == Nil .OR. aItem[ ITEM_HEIGHT ] == 0
                              hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "BITMAP"
                  AAdd( aPaintRep[ FORM_ITEMS ], { 5, NextItem( stroka ), ;
                                                   Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), 0, 0, 0, 0, 0, Nil, 0 } )
                  aItem := ATail( aPaintRep[ FORM_ITEMS ] )
                  IF aItem[ ITEM_X1 ] == Nil .OR. aItem[ ITEM_X1 ] == 0 .OR. ;
                     aItem[ ITEM_Y1 ] == Nil .OR. aItem[ ITEM_Y1 ] == 0 .OR. ;
                     aItem[ ITEM_WIDTH ] == Nil .OR. aItem[ ITEM_WIDTH ] == 0 .OR. ;
                     aItem[ ITEM_HEIGHT ] == Nil .OR. aItem[ ITEM_HEIGHT ] == 0
                     hwg_Msgstop( "Error: " + stroka )
                     res := .F.
                     EXIT
                  ENDIF
               ELSEIF itemName == "MARKER"
                  AAdd( aPaintRep[ FORM_ITEMS ], { 6, NextItem( stroka ), Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                                                   Val( NextItem( stroka ) ), Val( NextItem( stroka ) ), ;
                                                   0, 0, 0, 0, Nil, 0 } )
                  aItem := ATail( aPaintRep[ FORM_ITEMS ] )
               ENDIF
            ENDIF
         ELSEIF nMode == 2
            IF Left( stroka, 1 ) == "#" .AND. Upper( SubStr( stroka, 2, 6 ) ) == "ENDSCR"
               nMode := 1
            ELSE
               IF aItem != Nil
                  aItem[ ITEM_SCRIPT ] += stroka + Chr( 13 ) + Chr( 10 )
               ELSE
                  aPaintRep[ FORM_VARS ] += stroka + Chr( 13 ) + Chr( 10 )
               ENDIF
            ENDIF
         ENDIF
      ENDDO
      FClose( han )
   ELSE
      hwg_Msgstop( "Can't open " + fname )
      RETURN .F.
   ENDIF
   IF Empty( aPaintRep[ FORM_ITEMS ] )
      hwg_Msgstop( repName + " not found or empty!" )
      res := .F.
   ELSE
      aPaintRep[ FORM_ITEMS ] := ASort( aPaintRep[ FORM_ITEMS ],,, { | z, y | z[ ITEM_Y1 ] < y[ ITEM_Y1 ] .OR.( z[ ITEM_Y1 ] == y[ ITEM_Y1 ] .AND.z[ ITEM_X1 ] < y[ ITEM_X1 ] ) .OR.( z[ ITEM_Y1 ] == y[ ITEM_Y1 ] .AND.z[ ITEM_X1 ] == y[ ITEM_X1 ] .AND.( z[ ITEM_WIDTH ] < y[ ITEM_WIDTH ] .OR.z[ ITEM_HEIGHT ] < y[ ITEM_HEIGHT ] ) ) } )
   ENDIF
RETURN res

FUNCTION hwg_RecalcForm( aPaintRep, nFormWidth )

   LOCAL hDC, aMetr, aItem, i
   hDC := hwg_Getdc( hwg_Getactivewindow() )
   aMetr := hwg_Getdevicearea( hDC )
   aPaintRep[ FORM_XKOEF ] := ( aMetr[ 1 ] - XINDENT ) / aPaintRep[ FORM_WIDTH ]
   hwg_Releasedc( hwg_Getactivewindow(), hDC )

   IF nFormWidth != aMetr[ 1 ] - XINDENT
      FOR i := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
         aItem := aPaintRep[ FORM_ITEMS, i ]
         aItem[ ITEM_X1 ] := Round( aItem[ ITEM_X1 ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
         aItem[ ITEM_Y1 ] := Round( aItem[ ITEM_Y1 ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
         aItem[ ITEM_WIDTH ] := Round( aItem[ ITEM_WIDTH ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
         aItem[ ITEM_HEIGHT ] := Round( aItem[ ITEM_HEIGHT ] * ( aMetr[ 1 ] - XINDENT ) / nFormWidth, 0 )
      NEXT
   ENDIF
   RETURN Nil

FUNCTION hwg_PrintReport( printerName, oPrn, lPreview )

   LOCAL oPrinter := IIf( oPrn != Nil, oPrn, HPrinter():New( printerName ) )
   LOCAL aPrnCoors, prnXCoef, prnYCoef
   LOCAL iItem, aItem, nLineStartY := 0, nLineHeight := 0, nPHStart := 0
   LOCAL iPH := 0, iSL := 0, iEL := 0, iPF := 0, iEPF := 0, iDF := 0
   LOCAL poz := 0, stroka, varName, varValue, i
   LOCAL oFont
   LOCAL lAddMode := .F., nYadd := 0, nEndList := 0

   MEMVAR lFirst, lFinish, lLastCycle, oFontStandard
   PRIVATE lFirst := .T., lFinish := .T., lLastCycle := .F.

   IF oPrinter:hDCPrn == Nil .OR. oPrinter:hDCPrn == 0
      RETURN .F.
   ENDIF

   aPrnCoors := hwg_Getdevicearea( oPrinter:hDCPrn )
   prnXCoef := ( aPrnCoors[ 1 ] / aPaintRep[ FORM_WIDTH ] ) / aPaintRep[ FORM_XKOEF ]
   prnYCoef := ( aPrnCoors[ 2 ] / aPaintRep[ FORM_HEIGHT ] ) / aPaintRep[ FORM_XKOEF ]
   // writelog( oPrinter:cPrinterName + str(aPrnCoors[1])+str(aPrnCoors[2])+" / "+str(aPaintRep[FORM_WIDTH])+" "+str(aPaintRep[FORM_HEIGHT])+str(aPaintRep[FORM_XKOEF])+" / "+str(prnXCoef)+str(prnYCoef) )

   IF Type( "oFontStandard" ) = "U"
      PRIVATE oFontStandard := HFont():Add( "Arial", 0, - 13, 400, 204 )
   ENDIF

   FOR i := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
      IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_TEXT
         oFont := aPaintRep[ FORM_ITEMS, i, ITEM_FONT ]
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ] := HFont():Add( oFont:name, ;
                                                                oFont:width, Round( oFont:height * prnYCoef, 0 ), oFont:weight, ;
                                                                oFont:charset, oFont:italic )
      ENDIF
   NEXT

   IF ValType( aPaintRep[ FORM_VARS ] ) == "C"
      DO WHILE .T.
         stroka := RDSTR( , aPaintRep[ FORM_VARS ], @poz )
         IF Len( stroka ) = 0
            EXIT
         ENDIF
         DO WHILE ! Empty( varName := getNextVar( @stroka, @varValue ) )
            PRIVATE &varName
            IF varValue != Nil
               &varName := &varValue
            ENDIF
         ENDDO
      ENDDO
   ENDIF

   FOR iItem := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
      aItem := aPaintRep[ FORM_ITEMS, iItem ]
      IF aItem[ ITEM_TYPE ] == TYPE_MARKER
         aItem[ ITEM_STATE ] := 0
         IF aItem[ ITEM_CAPTION ] == "SL"
            nLineStartY := aItem[ ITEM_Y1 ]
            aItem[ ITEM_STATE ] := 0
            iSL := iItem
         ELSEIF aItem[ ITEM_CAPTION ] == "EL"
            nLineHeight := aItem[ ITEM_Y1 ] - nLineStartY
            iEL := iItem
         ELSEIF aItem[ ITEM_CAPTION ] == "PF"
            nEndList := aItem[ ITEM_Y1 ]
            iPF := iItem
         ELSEIF aItem[ ITEM_CAPTION ] == "EPF"
            iEPF := iItem
         ELSEIF  aItem[ ITEM_CAPTION ] == "DF"
            iDF := iItem
            IF iPF == 0
               nEndList := aItem[ ITEM_Y1 ]
            ENDIF
         ELSEIF aItem[ ITEM_CAPTION ] == "PH"
            iPH := iItem
            nPHStart := aItem[ ITEM_Y1 ]
         ENDIF
      ENDIF
   NEXT
   IF iPH > 0 .AND. iSL == 0
      hwg_Msgstop( "'Start Line' marker is absent" )
      oPrinter:END()
      RETURN .F.
   ELSEIF iSL > 0 .AND. iEL == 0
      hwg_Msgstop( "'End Line' marker is absent" )
      oPrinter:END()
      RETURN .F.
   ELSEIF iPF > 0 .AND. iEPF == 0
      hwg_Msgstop( "'End of Page Footer' marker is absent" )
      oPrinter:END()
      RETURN .F.
   ELSEIF iSL > 0 .AND. iPF == 0 .AND. iDF == 0
      hwg_Msgstop( "'Page Footer' and 'Document Footer' markers are absent" )
      oPrinter:END()
      RETURN .F.
   ENDIF

   #ifdef __DEBUG__
      oPrinter:END()
      // Writelog( "Startdoc" )
      // Writelog( "Startpage" )
   #else
      oPrinter:StartDoc( lPreview )
      oPrinter:StartPage()
   #endif

   DO WHILE .T.
      iItem := 1
      DO WHILE iItem <= Len( aPaintRep[ FORM_ITEMS ] )
         aItem := aPaintRep[ FORM_ITEMS, iItem ]
         // WriteLog( Str(iItem,3)+": "+Str(aItem[ITEM_TYPE]) )
         IF aItem[ ITEM_TYPE ] == TYPE_MARKER
            IF aItem[ ITEM_CAPTION ] == "PH"
               IF aItem[ ITEM_STATE ] == 0
                  aItem[ ITEM_STATE ] := 1
                  FOR i := 1 TO iPH - 1
                     IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                        hwg_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                     ENDIF
                  NEXT
               ENDIF
            ELSEIF aItem[ ITEM_CAPTION ] == "SL"
               IF aItem[ ITEM_STATE ] == 0
                  // IF iPH == 0
                  FOR i := 1 TO iSL - 1
                     IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                        hwg_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                     ENDIF
                  NEXT
                  // ENDIF
                  aItem[ ITEM_STATE ] := 1
                  IF ! ScriptExecute( aItem )
                     #ifdef __DEBUG__
                        // Writelog( "Endpage" )
                        // Writelog( "Enddoc" )
                     #else
                        oPrinter:EndPage()
                        oPrinter:EndDoc()
                        oPrinter:END()
                     #endif
                     RETURN .F.
                  ENDIF
                  IF lLastCycle
                     iItem := iEL + 1
                     LOOP
                  ENDIF
               ENDIF
               lAddMode := .T.
            ELSEIF aItem[ ITEM_CAPTION ] == "EL"
               FOR i := iSL + 1 TO iEL - 1
                  IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                     hwg_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                  ENDIF
               NEXT
               IF ! ScriptExecute( aItem )
                  #ifdef __DEBUG__
                     // Writelog( "Endpage" )
                     // Writelog( "Enddoc" )
                  #else
                     oPrinter:EndPage()
                     oPrinter:EndDoc()
                     oPrinter:END()
                  #endif
                  RETURN .F.
               ENDIF
               IF ! lLastCycle
                  nYadd += nLineHeight
                  // Writelog( Str(nLineStartY)+" "+Str(nYadd)+" "+Str(nEndList) )
                  IF nLineStartY + nYadd + nLineHeight >= nEndList
                     // Writelog("New Page")
                     IF iPF == 0
                        #ifdef __DEBUG__
                           // Writelog( "Endpage" )
                           // Writelog( "Startpage" )
                        #else
                           oPrinter:EndPage()
                           oPrinter:StartPage()
                        #endif
                        nYadd := 10 - IIf( nPHStart > 0, nPHStart, nLineStartY )
                        lAddMode := .T.
                        IF iPH == 0
                           iItem := iSL
                        ELSE
                           iItem := iPH
                        ENDIF
                     ELSE
                        lAddMode := .F.
                     ENDIF
                  ELSE
                     iItem := iSL
                  ENDIF
               ELSE
                  lAddMode := .F.
               ENDIF
            ELSEIF aItem[ ITEM_CAPTION ] == "EPF"
               FOR i := iPF + 1 TO iEPF - 1
                  IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
                     hwg_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
                  ENDIF
               NEXT
               IF ! lLastCycle
                  #ifdef __DEBUG__
                     // Writelog( "Endpage" )
                     // Writelog( "Startpage" )
                  #else
                     oPrinter:EndPage()
                     oPrinter:StartPage()
                  #endif
                  nYadd := 10 - IIf( nPHStart > 0, nPHStart, nLineStartY )
                  lAddMode := .T.
                  IF iPH == 0
                     iItem := iSL
                  ELSE
                     iItem := iPH
                  ENDIF
               ENDIF
            ELSEIF aItem[ ITEM_CAPTION ] == "DF"
               lAddMode := .F.
               IF aItem[ ITEM_ALIGN ] == 1
               ENDIF
            ENDIF
         ELSE
            IF aItem[ ITEM_TYPE ] == TYPE_TEXT
               IF ! ScriptExecute( aItem )
                  #ifdef __DEBUG__
                     // Writelog( "Endpage" )
                     // Writelog( "Enddoc" )
                  #else
                     oPrinter:EndPage()
                     oPrinter:EndDoc()
                  #endif
                  oPrinter:END()
                  RETURN .F.
               ENDIF
            ENDIF
            IF aItem[ ITEM_TYPE ] != TYPE_BITMAP
               hwg_PrintItem( oPrinter, aPaintRep, aItem, prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
            ENDIF
         ENDIF
         iItem ++
      ENDDO
      FOR i := IIf( iSL == 0, 1, IIf( iDF > 0, iDF + 1, IIf( iPF > 0, iEPF + 1, iEL + 1 ) ) ) TO Len( aPaintRep[ FORM_ITEMS ] )
         IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_BITMAP
            hwg_PrintItem( oPrinter, aPaintRep, aPaintRep[ FORM_ITEMS, i ], prnXCoef, prnYCoef, IIf( lAddMode, nYadd, 0 ), .T. )
         ENDIF
      NEXT
      IF lFinish
         EXIT
      ENDIF
   ENDDO

   #ifdef __DEBUG__
      // Writelog( "Endpage" )
      // Writelog( "Enddoc" )
   #else
      oPrinter:EndPage()
      oPrinter:EndDoc()
      IF lPreview != Nil .AND. lPreview
         oPrinter:Preview()
      ENDIF
   #endif
   oPrinter:END()

   FOR i := 1 TO Len( aPaintRep[ FORM_ITEMS ] )
      IF aPaintRep[ FORM_ITEMS, i, ITEM_TYPE ] == TYPE_TEXT
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ]:Release()
         aPaintRep[ FORM_ITEMS, i, ITEM_STATE ] := Nil
      ENDIF
   NEXT

   RETURN .T.

FUNCTION hwg_PrintItem( oPrinter, aPaintRep, aItem, prnXCoef, prnYCoef, nYadd, lCalc )

   LOCAL x1 := aItem[ ITEM_X1 ], y1 := aItem[ ITEM_Y1 ] + nYadd, x2, y2
   LOCAL hBitmap, stroka

   HB_SYMBOL_UNUSED( aPaintRep )

   x2 := x1 + aItem[ ITEM_WIDTH ] - 1
   y2 := y1 + aItem[ ITEM_HEIGHT ] - 1
   // writelog( Str(aItem[ITEM_TYPE])+": "+Iif(aItem[ITEM_TYPE]==TYPE_TEXT,aItem[ITEM_CAPTION],"")+str(x1)+str(y1)+str(x2)+str(y2) )
   x1 := Round( x1 * prnXCoef, 0 )
   y1 := Round( y1 * prnYCoef, 0 )
   x2 := Round( x2 * prnXCoef, 0 )
   y2 := Round( y2 * prnYCoef, 0 )
   // writelog( "PrintItem-2: "+str(x1)+str(y1)+str(x2)+str(y2))

   #ifdef __DEBUG__
      // Writelog( Str(aItem[ITEM_TYPE])+": "+Str(x1)+" "+Str(y1)+" "+Str(x2)+" "+Str(y2)+" "+Iif(aItem[ITEM_TYPE] == TYPE_TEXT,aItem[ITEM_CAPTION]+Iif(aItem[ITEM_VAR]>0,"("+&( aItem[ITEM_CAPTION] )+")",""),"") )
   #else
      // Writelog( Str(aItem[ITEM_TYPE])+": "+Str(x1)+" "+Str(y1)+" "+Str(x2)+" "+Str(y2)+" "+Iif(aItem[ITEM_TYPE] == TYPE_TEXT,aItem[ITEM_CAPTION]+Iif(aItem[ITEM_VAR]>0,"("+&( aItem[ITEM_CAPTION] )+")",""),"") )
      IF aItem[ ITEM_TYPE ] == TYPE_TEXT
         IF aItem[ ITEM_VAR ] > 0
            stroka := IIf( lCalc, &( aItem[ ITEM_CAPTION ] ), "" )
         ELSE
            stroka := aItem[ ITEM_CAPTION ]
         ENDIF
         IF ! Empty( aItem[ ITEM_CAPTION ] )
            oPrinter:Say( stroka, x1, y1, x2, y2, ;
                          IIf( aItem[ ITEM_ALIGN ] == 0, DT_LEFT, IIf( aItem[ ITEM_ALIGN ] == 1, DT_RIGHT, DT_CENTER ) ), ;
                          aItem[ ITEM_STATE ] )
         ENDIF
      ELSEIF aItem[ ITEM_TYPE ] == TYPE_HLINE
         oPrinter:Line( x1, Round( ( y1 + y2 ) / 2, 0 ), x2, Round( ( y1 + y2 ) / 2, 0 ), aItem[ ITEM_PEN ] )
      ELSEIF aItem[ ITEM_TYPE ] == TYPE_VLINE
         oPrinter:Line( Round( ( x1 + x2 ) / 2, 0 ), y1, Round( ( x1 + x2 ) / 2, 0 ), y2, aItem[ ITEM_PEN ] )
      ELSEIF aItem[ ITEM_TYPE ] == TYPE_BOX
         oPrinter:Box( x1, y1, x2, y2, aItem[ ITEM_PEN ] )
      ELSEIF aItem[ ITEM_TYPE ] == TYPE_BITMAP
         hBitmap := hwg_Openbitmap( aItem[ ITEM_CAPTION ], oPrinter:hDC )
         // writelog( "hBitmap: "+str(hBitmap) )
         oPrinter:Bitmap( x1, y1, x2, y2,, hBitmap )
         hwg_Deleteobject( hBitmap )
         // hwg_Drawbitmap( hDC, aItem[ITEM_BITMAP],SRCAND, x1, y1, x2-x1+1, y2-y1+1 )
      ENDIF
   #endif
   RETURN Nil

STATIC FUNCTION ScriptExecute( aItem )
   LOCAL nError, nLineEr
   IF aItem[ ITEM_SCRIPT ] != Nil .AND. ! Empty( aItem[ ITEM_SCRIPT ] )
      IF ValType( aItem[ ITEM_SCRIPT ] ) == "C"
         IF ( aItem[ ITEM_SCRIPT ] := RdScript( , aItem[ ITEM_SCRIPT ] ) ) == Nil
            nError := CompileErr( @nLineEr )
            hwg_Msgstop( "Script error (" + LTrim( Str( nError ) ) + "), line " + LTrim( Str( nLineEr ) ) )
            RETURN .F.
         ENDIF
      ENDIF
      DoScript( aItem[ ITEM_SCRIPT ] )
      RETURN .T.
   ENDIF
   RETURN .T.



