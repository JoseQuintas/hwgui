/*
 *$Id: hprinter.prg,v 1.2 2005-09-16 11:13:29 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HPrinter class
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HPrinter INHERIT HObject

   DATA hDC  INIT 0
   DATA cPrinterName   INIT "DEFAULT"
   DATA lPreview
   DATA nWidth, nHeight, nPWidth, nPHeight
   DATA nHRes, nVRes                     // Resolution ( pixels/mm )
   DATA nPage
   DATA oFont

   DATA lmm  INIT .F.
   DATA nCurrPage, oTrackV, oTrackH
   DATA nZoom, xOffset, yOffset, x1, y1, x2, y2

   METHOD New( cPrinter,lmm )
   METHOD SetMode( nOrientation )
   METHOD AddFont( fontName, nHeight ,lBold, lItalic, lUnderline )
   METHOD SetFont( oFont )
   METHOD StartDoc( lPreview, cFileName )
   METHOD EndDoc()
   METHOD StartPage()
   METHOD EndPage()
   METHOD End()
   METHOD Box( x1,y1,x2,y2,oPen )
   METHOD Line( x1,y1,x2,y2,oPen )
   METHOD Say( cString,x1,y1,x2,y2,nOpt,oFont )
   METHOD Bitmap( x1,y1,x2,y2,nOpt,hBitmap )
   METHOD Preview()  INLINE Nil
   METHOD GetTextWidth( cString, oFont )  INLINE hwg_gp_GetTextSize( ::hDC,cString,Iif(oFont==Nil,Nil,oFont:handle) )

ENDCLASS

METHOD New( cPrinter,lmm ) CLASS HPrinter
Local aPrnCoors

   IF lmm != Nil
      ::lmm := lmm
   ENDIF
   IF cPrinter == Nil
      /* Temporary instead of printer select dialog */
      ::hDC := Hwg_OpenDefaultPrinter()
   ELSEIF Empty( cPrinter )
      ::hDC := Hwg_OpenDefaultPrinter()
   ELSE
      ::hDC := Hwg_OpenPrinter( cPrinter )
      ::cPrinterName := cPrinter
   ENDIF
   IF ::hDC == 0
      Return Nil
   ELSE
      aPrnCoors := hwg_gp_GetDeviceArea( ::hDC )
      ::nWidth  := Iif( ::lmm, aPrnCoors[3], aPrnCoors[1] )
      ::nHeight := Iif( ::lmm, aPrnCoors[4], aPrnCoors[2] )
      ::nPWidth  := Iif( ::lmm, aPrnCoors[8], aPrnCoors[1] )
      ::nPHeight := Iif( ::lmm, aPrnCoors[9], aPrnCoors[2] )
      ::nHRes   := aPrnCoors[1] / aPrnCoors[3]
      ::nVRes   := aPrnCoors[2] / aPrnCoors[4]
      // writelog( ::cPrinterName + str(aPrnCoors[1])+str(aPrnCoors[2])+str(aPrnCoors[3])+str(aPrnCoors[4])+str(aPrnCoors[5])+str(aPrnCoors[6])+str(aPrnCoors[8])+str(aPrnCoors[9]) )
   ENDIF

Return Self

METHOD SetMode( nOrientation ) CLASS HPrinter
Local aPrnCoors

   SetPrinterMode( ::hDC, nOrientation )
   aPrnCoors := hwg_gp_GetDeviceArea( ::hDC )
   ::nWidth  := Iif( ::lmm, aPrnCoors[3], aPrnCoors[1] )
   ::nHeight := Iif( ::lmm, aPrnCoors[4], aPrnCoors[2] )
   ::nPWidth  := Iif( ::lmm, aPrnCoors[8], aPrnCoors[1] )
   ::nPHeight := Iif( ::lmm, aPrnCoors[9], aPrnCoors[2] )
   ::nHRes   := aPrnCoors[1] / aPrnCoors[3]
   ::nVRes   := aPrnCoors[2] / aPrnCoors[4]
   // writelog( ":"+str(aPrnCoors[1])+str(aPrnCoors[2])+str(aPrnCoors[3])+str(aPrnCoors[4])+str(aPrnCoors[5])+str(aPrnCoors[6])+str(aPrnCoors[8])+str(aPrnCoors[9]) )

Return .T.

METHOD AddFont( fontName, nHeight ,lBold, lItalic, lUnderline, nCharset ) CLASS HPrinter
Local oFont

   IF ::lmm .AND. nHeight != Nil
      nHeight *= ::nVRes
   ENDIF
   oFont := HGP_Font():Add( fontName, nHeight, ;
       Iif( lBold!=Nil.AND.lBold,700,400 ),    ;
       Iif( lItalic!=Nil.AND.lItalic,255,0 ), Iif( lUnderline!=Nil.AND.lUnderline,1,0 ) )

Return oFont

METHOD SetFont( oFont )  CLASS HPrinter
Local oFontOld := ::oFont

   hwg_gp_SetFont( ::hDC,oFont:handle )
   ::oFont := oFont
Return oFontOld

METHOD End() CLASS HPrinter

   IF ::hDC != 0
     hwg_UnrefPrinter( ::hDC )
     ::hDC := 0
   ENDIF
Return Nil

METHOD Box( x1,y1,x2,y2,oPen ) CLASS HPrinter

/*
   IF oPen != Nil
      SelectObject( ::hDC,oPen:handle )
   ENDIF
*/
   IF y2 > ::nHeight
      Return Nil
   ENDIF
   y1 := ::nHeight - y1
   y2 := ::nHeight - y2
   IF ::lmm
      x1 *= ::nHRes
      x2 *= ::nHRes
      y1 *= ::nVRes
      y2 *= ::nVRes
   ENDIF
   hwg_gp_Rectangle( ::hDC,x1,y2,x2,y1 )   

Return Nil

METHOD Line( x1,y1,x2,y2,oPen ) CLASS HPrinter

/*
   IF oPen != Nil
      SelectObject( ::hDC,oPen:handle )
   ENDIF
*/
   IF y2 > ::nHeight
      Return Nil
   ENDIF
   y1 := ::nHeight - y1
   y2 := ::nHeight - y2
   IF ::lmm
      x1 *= ::nHRes
      x2 *= ::nHRes
      y1 *= ::nVRes
      y2 *= ::nVRes
   ENDIF

   hwg_gp_DrawLine( ::hDC,x1,y2,x2,y1 )

Return Nil

METHOD Say( cString,x1,y1,x2,y2,nOpt,oFont ) CLASS HPrinter
Local oFontOld

   IF y2 > ::nHeight
      Return Nil
   ENDIF
   y1 := ::nHeight - y1
   y2 := ::nHeight - y2
   IF ::lmm
      x1 *= ::nHRes
      x2 *= ::nHRes
      y1 *= ::nVRes
      y2 *= ::nVRes
   ENDIF
   
   IF oFont != Nil
      oFontOld := ::SetFont( oFont )
   ENDIF
   
   hwg_gp_DrawText( ::hDC,cString,x1,y2,x2,y1,Iif(nOpt==Nil,DT_LEFT,nOpt) )
   IF oFont != Nil
      ::SetFont( oFontOld )
   ENDIF

Return Nil

METHOD Bitmap( x1,y1,x2,y2,nOpt,hBitmap ) CLASS HPrinter

   IF y2 > ::nHeight
      Return Nil
   ENDIF
   y1 := ::nHeight - y1
   y2 := ::nHeight - y2
   IF ::lmm
      x1 *= ::nHRes
      x2 *= ::nHRes
      y1 *= ::nVRes
      y2 *= ::nVRes
   ENDIF 

   DrawBitmap( ::hDC,hBitmap,Iif(nOpt==Nil,SRCAND,nOpt),x1,y1,x2-x1+1,y2-y1+1 )

Return Nil

METHOD StartDoc( lPreview, cFileName ) CLASS HPrinter

   Hwg_StartDoc( ::hDC )
   IF cFileName != Nil
      hwg_gp_ToFile( ::hDC,cFileName )
   ENDIF
   ::nPage := 0
Return Nil

METHOD EndDoc() CLASS HPrinter

   Hwg_EndDoc( ::hDC )
Return Nil

METHOD StartPage() CLASS HPrinter

   Hwg_StartPage( ::hDC )
   ::nPage ++
Return Nil

METHOD EndPage() CLASS HPrinter

   Hwg_EndPage( ::hDC )
Return Nil


/*
 *  CLASS HGP_Font
 */

CLASS HGP_Font INHERIT HObject

   CLASS VAR aFonts   INIT {}
   DATA handle
   DATA name, height ,weight
   DATA italic, Underline
   DATA nCounter   INIT 1

   METHOD Add( fontName, nWidth, nHeight ,fnWeight, fdwItalic, fdwUnderline )
   METHOD Release()

ENDCLASS

METHOD Add( fontName, nHeight ,fnWeight, fdwItalic, fdwUnderline ) CLASS HGP_Font
Local i, nlen := Len( ::aFonts )

   nHeight  := Iif( nHeight==Nil,-13,nHeight )
   fnWeight := Iif( fnWeight==Nil,0,fnWeight )
   fdwItalic := Iif( fdwItalic==Nil,0,fdwItalic )
   fdwUnderline := Iif( fdwUnderline==Nil,0,fdwUnderline )

   For i := 1 TO nlen
      IF ::aFonts[i]:name == fontName .AND.          ;
         ::aFonts[i]:height == nHeight .AND.         ;
         ::aFonts[i]:weight == fnWeight .AND.        ;
         ::aFonts[i]:Italic == fdwItalic .AND.       ;
         ::aFonts[i]:Underline == fdwUnderline

         ::aFonts[i]:nCounter ++
         Return ::aFonts[i]
      ENDIF
   NEXT

   ::handle := hwg_gp_AddFont( fontName, nHeight )

   ::name      := fontName
   ::height    := nHeight
   ::weight    := fnWeight
   ::Italic    := fdwItalic
   ::Underline := fdwUnderline

   Aadd( ::aFonts,Self )

Return Self

METHOD Release() CLASS HGP_Font
Local i, nlen := Len( ::aFonts )

   ::nCounter --
   IF ::nCounter == 0
      For i := 1 TO nlen
         IF ::aFonts[i]:handle == ::handle
            Adel( ::aFonts,i )
            Asize( ::aFonts,nlen-1 )
            Exit
         ENDIF
      NEXT
   ENDIF
Return Nil
