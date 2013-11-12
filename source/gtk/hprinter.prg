/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HPrinter class
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

STATIC crlf := e"\r\n"

CLASS HPrinter

#if defined( __GTK__ ) .AND. defined( __RUSSIAN__ )
   CLASS VAR cdp       SHARED  INIT "RUKOI8"
#else
   CLASS VAR cdp       SHARED
#endif
   DATA hDC  INIT 0
   DATA cPrinterName   INIT "DEFAULT"
   DATA cdpIn
   DATA lPreview       INIT .F.
   DATA nWidth, nHeight
   DATA nOrient        INIT 1
   DATA nFormType      INIT 0
   DATA nHRes, nVRes                     // Resolution ( pixels/mm )
   DATA nPage
   DATA oPen, oFont
   DATA lastPen, lastFont
   DATA aPages

   DATA lmm  INIT .F.
   DATA cMetafile

   METHOD New( cPrinter, lmm, nFormType )
   METHOD SetMode( nOrientation )
   METHOD Recalc( x1, y1, x2, y2 )
   METHOD AddFont( fontName, nHeight , lBold, lItalic, lUnderline )
   METHOD SetFont( oFont )
   METHOD AddPen( nWidth, style, color )
   METHOD SetPen( nWidth, style, color )
   METHOD StartDoc()
   METHOD EndDoc()
   METHOD StartPage()
   METHOD EndPage()
   METHOD End()
   METHOD Box( x1, y1, x2, y2, oPen )
   METHOD Line( x1, y1, x2, y2, oPen )
   METHOD Say( cString, x1, y1, x2, y2, nOpt, oFont )
   METHOD Bitmap( x1, y1, x2, y2, nOpt, cImageName )
   METHOD Preview()  INLINE Nil
   METHOD GetTextWidth( cString, oFont )  INLINE hwg_gp_GetTextSize( ::hDC, cString, oFont:name, oFont:height )

ENDCLASS

METHOD New( cPrinter, lmm, nFormType ) CLASS HPrinter
   LOCAL aPrnCoors

   IF lmm != Nil
      ::lmm := lmm
   ENDIF
   IF nFormType != Nil
      ::nFormType := nFormType
   ENDIF

   ::cdpIn := iif( Empty( ::cdp ), hb_cdpSelect(), ::cdp )

   ::hDC := Hwg_OpenPrinter( cPrinter, nFormType )
   ::cPrinterName := cPrinter

   IF ::hDC == 0
      RETURN Nil
   ELSE
      aPrnCoors := hwg_gp_GetDeviceArea( ::hDC )
      ::nWidth  := iif( ::lmm, aPrnCoors[3], aPrnCoors[1] )
      ::nHeight := iif( ::lmm, aPrnCoors[4], aPrnCoors[2] )
      ::nHRes   := aPrnCoors[1] / aPrnCoors[3]
      ::nVRes   := aPrnCoors[2] / aPrnCoors[4]
      // hwg_WriteLog( "Printer:" + str(aPrnCoors[1])+str(aPrnCoors[2])+str(aPrnCoors[3])+str(aPrnCoors[4])+str(aPrnCoors[5])+str(aPrnCoors[6]) )
   ENDIF

   RETURN Self

METHOD SetMode( nOrientation ) CLASS HPrinter
   LOCAL x

   IF ( nOrientation == 1 .OR. nOrientation == 2 ) .AND. nOrientation != ::nOrient
      hwg_Setprintermode( ::hDC, nOrientation )
      ::nOrient := nOrientation
      x := ::nHRes
      ::nHRes := ::nVRes
      ::nVRes := x
      x := ::nWidth
      ::nWidth := ::nHeight
      ::nHeight := x
   ENDIF

   RETURN .T.

METHOD Recalc( x1, y1, x2, y2 ) CLASS HPrinter

   IF ::lmm
      x1 *= ::nHRes
      x2 *= ::nHRes
      y1 *= ::nVRes
      y2 *= ::nVRes
   ENDIF

   RETURN Nil

METHOD AddFont( fontName, nHeight , lBold, lItalic, lUnderline, nCharset ) CLASS HPrinter
   LOCAL oFont

   IF ::lmm .AND. nHeight != Nil
      nHeight *= ::nVRes
   ENDIF
   oFont := HGP_Font():Add( fontName, nHeight, ;
      iif( lBold != Nil .AND. lBold, 700, 400 ),    ;
      iif( lItalic != Nil .AND. lItalic, 255, 0 ), iif( lUnderline != Nil .AND. lUnderline, 1, 0 ) )

   RETURN oFont

METHOD SetFont( oFont )  CLASS HPrinter
   LOCAL oFontOld := ::oFont

   ::oFont := oFont

   RETURN oFontOld

METHOD AddPen( nWidth, style, color ) CLASS HPrinter
   LOCAL oPen

   IF ::lmm .AND. nWidth != Nil
      nWidth *= ::nVRes
   ENDIF
   oPen := HGP_Pen():Add( nWidth, style, color )

   RETURN oPen

METHOD SetPen( nWidth, style, color )  CLASS HPrinter
   LOCAL oPenOld := ::oPen

   ::oPen := HGP_Pen():Add( nWidth, style, color )

   RETURN oPenOld

METHOD End() CLASS HPrinter

   IF ::hDC != 0
      hwg_ClosePrinter( ::hDC )
      ::hDC := 0
   ENDIF

   RETURN Nil

METHOD Box( x1, y1, x2, y2, oPen ) CLASS HPrinter

   IF oPen == Nil
      oPen := ::oPen
   ENDIF
   IF oPen != Nil
      IF Empty( ::lastPen ) .OR. oPen:width != ::lastPen:width .OR. ;
            oPen:style != ::lastPen:style .OR. oPen:color != ::lastPen:color
         ::lastPen := oPen
         ::aPages[::nPage] += "pen," + LTrim( Str( oPen:width ) ) + "," + ;
            LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:color ) ) + "," + crlf
      ENDIF
   ENDIF

   IF y2 > ::nHeight
      RETURN Nil
   ENDIF

   ::Recalc( @x1, @y1, @x2, @y2 )

   ::aPages[::nPage] += "box," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
      LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + crlf

   RETURN Nil

METHOD Line( x1, y1, x2, y2, oPen ) CLASS HPrinter

   IF oPen == Nil
      oPen := ::oPen
   ENDIF
   IF oPen != Nil
      IF Empty( ::lastPen ) .OR. oPen:width != ::lastPen:width .OR. ;
            oPen:style != ::lastPen:style .OR. oPen:color != ::lastPen:color
         ::lastPen := oPen
         ::aPages[::nPage] += "pen," + LTrim( Str( oPen:width ) ) + "," + ;
            LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:color ) ) + "," + crlf
      ENDIF
   ENDIF

   IF y2 > ::nHeight
      RETURN Nil
   ENDIF

   ::Recalc( @x1, @y1, @x2, @y2 )

   ::aPages[::nPage] += "lin," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
      LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + crlf

   RETURN Nil

METHOD Say( cString, x1, y1, x2, y2, nOpt, oFont ) CLASS HPrinter

   IF y2 > ::nHeight
      RETURN Nil
   ENDIF

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF oFont == Nil
      oFont := ::oFont
   ENDIF

   IF oFont != Nil  .AND. ( ::lastFont == Nil .OR. !::lastFont:Equal( oFont:name, oFont:height, oFont:weight, oFont:Italic, oFont:Underline ) )
      ::lastFont := oFont
      ::aPages[::nPage] += "fnt," + oFont:name + "," + LTrim( Str( oFont:height ) ) + "," + ;
         LTrim( Str( oFont:weight ) ) + "," + LTrim( Str( oFont:Italic ) ) + "," + LTrim( Str( oFont:Underline ) ) + crlf
   ENDIF

   IF !Empty( nOpt ) .AND. ( Hb_BitAnd( nOpt, DT_RIGHT ) != 0 .OR. Hb_BitAnd( nOpt, DT_CENTER ) != 0 ) .AND. Left( cString, 1 ) == " "
      cString := LTrim( cString )
   ENDIF
   ::aPages[::nPage] += "txt," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
      LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + ;
      iif( nOpt == Nil, ",", LTrim( Str(nOpt ) ) + "," ) + hb_StrToUtf8( cString, ::cdpIn ) + crlf

   RETURN Nil

METHOD Bitmap( x1, y1, x2, y2, nOpt, cImageName ) CLASS HPrinter

   IF y2 > ::nHeight
      RETURN Nil
   ENDIF

   ::Recalc( @x1, @y1, @x2, @y2 )

   ::aPages[::nPage] += "img," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
      LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + ;
      iif( nOpt == Nil, ",", LTrim( Str(nOpt ) ) + "," ) + cImageName + crlf

   RETURN Nil

METHOD StartDoc() CLASS HPrinter

   ::nPage := 0
   ::aPages := {}

   RETURN Nil

METHOD EndDoc() CLASS HPrinter
   LOCAL cExt, nOper := 0, han, i

   IF !Empty( ::cMetaFile )
      han := FCreate( ::cMetaFile )
      FOR i := 1 TO Len( ::aPages )
         FWrite( han, ::aPages[i] + crlf )
      NEXT
      FClose( han )
   ENDIF

   IF !Empty( ::cPrinterName ) .AND. ( cExt := Lower( FilExten( ::cPrinterName ) ) ) $ "pdf;ps;png;svg;"
      nOper := iif( cExt == "pdf", 1, iif( cExt == "ps",2,iif( cExt == "png",3,4 ) ) )
   ENDIF
   hwg_gp_Print( ::hDC, ::aPages, Len( ::aPages ), nOper, ::cPrinterName )

   RETURN Nil

METHOD StartPage() CLASS HPrinter

   ::nPage ++
   AAdd( ::aPages, "page," + LTrim( Str( ::nPage ) ) + "," + ;
      iif( ::lmm, "mm,", "px," ) + iif( ::nOrient == 1, "p", "l" ) + crlf )

   RETURN Nil

METHOD EndPage() CLASS HPrinter

   ::lastFont := ::lastPen := Nil
   hb_gcStep()

   RETURN Nil

/*
 *  CLASS HGP_Font
 */

CLASS HGP_Font

   CLASS VAR aFonts   INIT {}
   DATA name, height , weight
   DATA italic, Underline
   DATA nCounter   INIT 1

   METHOD Add( fontName, nHeight , fnWeight, fdwItalic, fdwUnderline )
   METHOD Equal( fontName, nHeight , fnWeight, fdwItalic, fdwUnderline )
   METHOD RELEASE( lAll )

ENDCLASS

METHOD Add( fontName, nHeight , fnWeight, fdwItalic, fdwUnderline ) CLASS HGP_Font
   LOCAL i, nlen := Len( ::aFonts )

   nHeight  := iif( nHeight == Nil, 13, Abs( nHeight ) )
   nHeight -= 1
   fnWeight := iif( fnWeight == Nil, 0, fnWeight )
   fdwItalic := iif( fdwItalic == Nil, 0, fdwItalic )
   fdwUnderline := iif( fdwUnderline == Nil, 0, fdwUnderline )

   For i := 1 TO nlen
      IF ::aFonts[i]:Equal( fontName, nHeight, fnWeight, fdwItalic, fdwUnderline )
         ::aFonts[i]:nCounter ++
         Return ::aFonts[i]
      ENDIF
   NEXT

   ::name      := fontName
   ::height    := nHeight
   ::weight    := fnWeight
   ::Italic    := fdwItalic
   ::Underline := fdwUnderline

   AAdd( ::aFonts, Self )

   RETURN Self

METHOD Equal( fontName, nHeight , fnWeight, fdwItalic, fdwUnderline )

   IF ::name == fontName .AND.          ;
         ::height == nHeight .AND.         ;
         ::weight == fnWeight .AND.        ;
         ::Italic == fdwItalic .AND.       ;
         ::Underline == fdwUnderline

      RETURN .T.
   ENDIF

   RETURN .F.

METHOD RELEASE( lAll ) CLASS HGP_Font
   LOCAL i, nlen := Len( ::aFonts )

   IF lAll != Nil .AND. lAll
      ::aFonts := {}
      RETURN Nil
   ENDIF
   ::nCounter --
   IF ::nCounter == 0
      For i := 1 TO nlen
         IF ::aFonts[i]:Equal( ::name, ::height, ::weight, ::Italic, ::Underline )
            ADel( ::aFonts, i )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

CLASS HGP_Pen

   CLASS VAR aPens   INIT {}
   DATA style, width, color
   DATA nCounter   INIT 1

   METHOD Add( nWidth, style, color )
   METHOD Release()

ENDCLASS

METHOD Add( nWidth, style, color ) CLASS HGP_Pen
   LOCAL i

   nWidth := iif( nWidth == Nil, 1, nWidth )
   style := iif( style == Nil, 0, style )
   color := iif( color == Nil, 0, color )

   FOR i := 1 TO Len( ::aPens )
      IF ::aPens[i]:width == nWidth .AND. ::aPens[i]:style == style .AND. ::aPens[i]:color == color
         ::aPens[i]:nCounter ++
         Return ::aPens[i]
      ENDIF
   NEXT

   ::width  := nWidth
   ::style  := style
   ::color  := color
   AAdd( ::aPens, Self )

   RETURN Self

METHOD Release() CLASS HGP_Pen
   LOCAL i, nlen := Len( ::aPens )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aPens[i]:width == ::width .AND. ::aPens[i]:style == ::style .AND. ::aPens[i]:color == ::color
            ADel( ::aPens, i )
            ASize( ::aPens, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil
