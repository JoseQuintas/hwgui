/*
 * Repbuild - Visual Report Builder
 * Printing functions
 *
 * Copyright 2001-2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "repbuild.h"
#include "repmain.h"

MEMVAR aPaintRep, lAddMode, oFontStandard, aBitmaps

FUNCTION PrintRpt

   LOCAL hDCwindow
   LOCAL oPrinter := HPrinter():New()
   LOCAL aPrnCoors, prnXCoef, prnYCoef
   LOCAL i, aItem, aMetr, aTmetr, aPmetr, dKoef, pKoef
   LOCAL fontKoef, oFont
#ifdef __GTK__
   LOCAL hDC := oPrinter:hDC
#else
   LOCAL hDC := oPrinter:hDCPrn
#endif
   PRIVATE lAddMode := .F.
   PRIVATE aBitmaps := {}

   IF Empty( hDC )
      RETURN .F.
   ENDIF

   aPrnCoors := hwg_GetDeviceArea( hDC )
   prnXCoef := ( aPrnCoors[ 1 ] / aPaintRep[ FORM_WIDTH ] ) / aPaintRep[ FORM_XKOEF ]
   prnYCoef := ( aPrnCoors[ 2 ] / aPaintRep[ FORM_HEIGHT ] ) / aPaintRep[ FORM_XKOEF ]
   // writelog( str(aPrnCoors[1])+str(aPrnCoors[2])+" / "+str(prnXCoef)+str(prnYCoef)+" / "+str(aPaintRep[FORM_XKOEF]) )

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Selectobject( hDCwindow, oFontStandard:handle )
   aTmetr := hwg_Gettextmetric( hDCwindow )
   dKoef := ( aMetr[1] - XINDENT ) / aTmetr[2]
   hwg_Releasedc( Hwindow():GetMain():handle, hDCwindow )

   hwg_Selectobject( hDC, oFontStandard:handle )
   aPmetr := hwg_Gettextmetric( hDC )
   pKoef := aPrnCoors[1] / aPmetr[2]
   fontKoef := pKoef / dKoef
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_TEXT
         oFont := aPaintRep[FORM_ITEMS,i,ITEM_FONT]
         aPaintRep[FORM_ITEMS,i,ITEM_STATE] := HFont():Add( oFont:name, ;
            oFont:width, Round( oFont:height * fontKoef, 0 ), oFont:weight, ;
            oFont:charset, oFont:italic )
      ENDIF
   NEXT

   oPrinter:StartDoc( .T. )
   oPrinter:StartPage()

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] != TYPE_BITMAP
         hwg_PrintItem( oPrinter, aPaintRep, aPaintRep[FORM_ITEMS,i], prnXCoef, prnYCoef, 0, .F. )
      ENDIF
   NEXT
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_BITMAP
         hwg_PrintItem( oPrinter, aPaintRep, aPaintRep[FORM_ITEMS,i], prnXCoef, prnYCoef, 0, .F. )
      ENDIF
   NEXT

   oPrinter:EndPage()
   oPrinter:EndDoc()

   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_TEXT
         aPaintRep[FORM_ITEMS,i,ITEM_STATE]:Release()
         aPaintRep[FORM_ITEMS,i,ITEM_STATE] := Nil
      ENDIF
   NEXT

   oPrinter:Preview()
   oPrinter:End()

   FOR i := 1 TO Len( aBitmaps )
      hwg_Deleteobject( aBitmaps[i] )
      aBitmaps[i] := Nil
   NEXT

   RETURN Nil
