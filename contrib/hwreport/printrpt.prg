/*
 * Repbuild - Visual Report Builder
 * Printing functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "windows.ch"
#include "guilib.ch"
#include "repbuild.h"
#include "repmain.h"
memvar aPaintRep, lAddMode, oFontStandard
Function PrintRpt
Local hDCwindow
Local oPrinter := HPrinter():New()
Local aPrnCoors, prnXCoef, prnYCoef
Local i, aItem, aMetr, aTmetr, aPmetr, dKoef, pKoef
Local fontKoef, oFont
Private lAddMode := .F.

   IF oPrinter:hDCPrn == Nil .OR. oPrinter:hDCPrn == 0
      Return .F.
   ENDIF

   aPrnCoors := hwg_GetDeviceArea( oPrinter:hDCPrn )
   prnXCoef := aPrnCoors[1]/aPaintRep[FORM_WIDTH]
   prnYCoef := aPrnCoors[2]/aPaintRep[FORM_HEIGHT]
   // writelog( str(aPrnCoors[1])+str(aPrnCoors[2])+" / "+str(prnXCoef)+str(prnYCoef)+" / "+str(aPaintRep[FORM_XKOEF]) )

   hDCwindow := hwg_Getdc( Hwindow():GetMain():handle )
   aMetr := hwg_GetDeviceArea( hDCwindow )
   hwg_Selectobject( hDCwindow, oFontStandard:handle )
   aTmetr := hwg_Gettextmetric( hDCwindow )
   dKoef := ( aMetr[1]-XINDENT ) / aTmetr[2]
   hwg_Releasedc( Hwindow():GetMain():handle,hDCwindow )

   hwg_Selectobject( oPrinter:hDCPrn, oFontStandard:handle )
   aPmetr := hwg_Gettextmetric( oPrinter:hDCPrn )
   pKoef := aPrnCoors[1] / aPmetr[2]
   fontKoef := pKoef / dKoef
   FOR i := 1 TO Len( aPaintRep[FORM_ITEMS] )
      IF aPaintRep[FORM_ITEMS,i,ITEM_TYPE] == TYPE_TEXT
         oFont := aPaintRep[FORM_ITEMS,i,ITEM_FONT]
         aPaintRep[FORM_ITEMS,i,ITEM_STATE] := HFont():Add( oFont:name,;
              oFont:width,Round(oFont:height*fontKoef,0),oFont:weight, ;
              oFont:charset,oFont:italic )
      ENDIF
   NEXT

   oPrinter:StartDoc(.T.)
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

Return Nil
