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
   DATA lPreview
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

   DATA nZoom, nCurrPage, hMeta
   DATA oBrush1, oBrush2

   METHOD New( cPrinter, lmm, nFormType )
   METHOD SetMode( nOrientation )
   METHOD Recalc( x1, y1, x2, y2 )
   METHOD AddFont( fontName, nHeight , lBold, lItalic, lUnderline )
   METHOD SetFont( oFont )
   METHOD AddPen( nWidth, style, color )
   METHOD SetPen( nWidth, style, color )
   METHOD StartDoc( lPreview, cMetaFile )
   METHOD EndDoc()
   METHOD StartPage()
   METHOD EndPage()
   METHOD End()
   METHOD Box( x1, y1, x2, y2, oPen )
   METHOD Line( x1, y1, x2, y2, oPen )
   METHOD Say( cString, x1, y1, x2, y2, nOpt, oFont )
   METHOD Bitmap( x1, y1, x2, y2, nOpt, cImageName )
   METHOD LoadMeta( cMetaFile )
   METHOD Preview()
   METHOD PlayMeta( oCanvas )
   METHOD PrintMeta()
   METHOD ChangePage( oCanvas, oSayPage, n, nPage )
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

METHOD StartDoc( lPreview, cMetaFile ) CLASS HPrinter

   ::nPage := 0
   ::aPages := {}
   ::lPreview := lPreview
   IF !Empty( cMetaFile )
      ::cMetaFile := cMetaFile
   ENDIF

   RETURN Nil

METHOD EndDoc() CLASS HPrinter
   LOCAL han, i

   IF !Empty( ::cMetaFile )
      han := FCreate( ::cMetaFile )
      FOR i := 1 TO Len( ::aPages )
         FWrite( han, ::aPages[i] + crlf )
      NEXT
      FClose( han )
   ENDIF

   IF Empty( ::lPreview )
      ::PrintMeta()
   ELSE
      ::Preview()
   ENDIF
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

METHOD LoadMeta( cMetaFile ) CLASS HPrinter
   LOCAL arr, i, s

   IF Empty( cMetaFile ) .OR. Empty( arr := hb_aTokens( Memoread( cMetaFile ), crlf ) )
      RETURN .F.
   ENDIF
   ::cMetaFile := cMetaFile
   ::aPages := {}

   FOR i := 1 TO Len( arr )
      IF Left( arr[i], 4 ) == "page"
         IF !Empty( s )
            Aadd( ::aPages, s )
         ENDIF
         s := arr[i] + crlf
      ELSEIF !Empty( arr[i] ) .AND. !Empty( s )
         s += arr[i]
      ENDIF
   NEXT
   IF !Empty( s )
      Aadd( ::aPages, s )
   ENDIF

   RETURN !Empty( ::aPages )

#define TOOL_SIDE_WIDTH  88
METHOD Preview( cTitle, aBitmaps, aTooltips, aBootUser ) CLASS HPrinter
   LOCAL oDlg, oSayPage, oBtn, oCanvas, oTimer, i, nLastPage := Len( ::aPages ), aPage := { }
   LOCAL oFont := HFont():Add( "Times New Roman", 0, - 13, 700 )
   LOCAL lTransp := ( aBitmaps != Nil .AND. Len( aBitmaps ) > 9 .AND. aBitmaps[ 10 ] != Nil .AND. aBitmaps[ 10 ] )

   FOR i := 1 TO nLastPage
      AAdd( aPage, Str( i, 4 ) + ":" + Str( nLastPage, 4 ) )
   NEXT

   IF cTitle == Nil ; cTitle := "Print preview" ; ENDIF
   ::nZoom := 0
   ::ChangePage( ,,,1 )

   ::oBrush1 := HBrush():Add( 8421504 )
   ::oBrush2 := HBrush():Add( 16777215 )

   INIT DIALOG oDlg TITLE cTitle AT 0, 0 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight()

   @ TOOL_SIDE_WIDTH, 0 PANEL oCanvas ;
      SIZE oDlg:nWidth - TOOL_SIDE_WIDTH, oDlg:nHeight ;
      ON SIZE { | o, x, y | o:Move(,, x - TOOL_SIDE_WIDTH, y ) } ;
      ON PAINT { || ::PlayMeta( oCanvas ) } STYLE WS_VSCROLL + WS_HSCROLL

   //oCanvas:bScroll := { | oWnd, msg, wParam, lParam | HB_SYMBOL_UNUSED( oWnd ), ::ResizePreviewDlg( oCanvas,, msg, wParam, lParam ) }

   @ 3, 2 OWNERBUTTON oBtn ON CLICK { || hwg_EndDialog() } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT "Exit" FONT oFont        ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 1 ], "Exit Preview" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 1 .AND. aBitmaps[ 2 ] != Nil
      oBtn:oBitmap  := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 2 ] ), HBitmap():AddFile( aBitmaps[ 2 ] ) )
      oBtn:title    := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 31 LINE LENGTH TOOL_SIDE_WIDTH - 1

   @ 3, 36 OWNERBUTTON oBtn  ON CLICK { || ::PrintMeta() } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT "Print" FONT oFont         ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 2 ], "Print file" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 2 .AND. aBitmaps[ 3 ] != Nil
      oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 3 ] ), HBitmap():AddFile( aBitmaps[ 3 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 62 COMBOBOX oSayPage ITEMS aPage ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 color "fff000" backcolor 12507070 ;
      ON CHANGE { || ::ChangePage( oCanvas, oSayPage,, oSayPage:GetValue() ) } STYLE WS_VSCROLL

   @ 3, 86 OWNERBUTTON oBtn ON CLICK { || ::ChangePage( oCanvas, oSayPage, 0 ) } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT "|<<" FONT oFont                 ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 3 ], "First page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 3 .AND. aBitmaps[ 4 ] != Nil
      oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 4 ] ), HBitmap():AddFile( aBitmaps[ 4 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 110 OWNERBUTTON oBtn ON CLICK { || ::ChangePage( oCanvas, oSayPage, 1 ) } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT ">>" FONT oFont                  ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 4 ], "Next page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 4 .AND. aBitmaps[ 5 ] != Nil
      oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 5 ] ), HBitmap():AddFile( aBitmaps[ 5 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 134 OWNERBUTTON oBtn ON CLICK { || ::ChangePage( oCanvas, oSayPage, - 1 ) } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT "<<" FONT oFont    ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 5 ], "Previous page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 5 .AND. aBitmaps[ 6 ] != Nil
      oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 6 ] ), HBitmap():AddFile( aBitmaps[ 6 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 158 OWNERBUTTON oBtn ON CLICK { || ::ChangePage( oCanvas, oSayPage, 2 ) } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT ">>|" FONT oFont   ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 6 ], "Last page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 6 .AND. aBitmaps[ 7 ] != Nil
      oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 7 ] ), HBitmap():AddFile( aBitmaps[ 7 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 189 LINE LENGTH TOOL_SIDE_WIDTH - 1

   @ 3, 192 OWNERBUTTON oBtn ON CLICK { || .t. } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT "(-)" FONT oFont   ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 7 ], "Zoom out" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 7 .AND. aBitmaps[ 8 ] != Nil
      oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 8 ] ), HBitmap():AddFile( aBitmaps[ 8 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 216 OWNERBUTTON oBtn ON CLICK { || .t. } ;
      SIZE TOOL_SIDE_WIDTH - 6, 24 TEXT "(+)" FONT oFont   ;
      TOOLTIP IIf( aTooltips != Nil, aTooltips[ 8 ], "Zoom in" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 8 .AND. aBitmaps[ 9 ] != Nil
      oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 9 ] ), HBitmap():AddFile( aBitmaps[ 9 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 243 LINE LENGTH TOOL_SIDE_WIDTH - 1

   IF aBootUser != Nil

      @ 1, 313 LINE LENGTH TOOL_SIDE_WIDTH - 1

      @ 3, 316 OWNERBUTTON oBtn ;
         SIZE TOOL_SIDE_WIDTH - 6, 24        ;
         TEXT IIf( Len( aBootUser ) == 4, aBootUser[ 4 ], "User Button" ) ;
         FONT oFont                   ;
         TOOLTIP IIf( aBootUser[ 3 ] != Nil, aBootUser[ 3 ], "User Button" )

      oBtn:bClick := aBootUser[ 1 ]

      IF aBootUser[ 2 ] != Nil
         oBtn:oBitmap := IIf( aBitmaps[ 1 ], HBitmap():AddResource( aBootUser[ 2 ] ), HBitmap():AddFile( aBootUser[ 2 ] ) )
         oBtn:title   := Nil
         oBtn:lTransp := lTransp
      ENDIF

   ENDIF

   oDlg:Activate()

   oFont:Release()
   IF !Empty( ::hMeta )
      hwg_Deleteobject( ::hMeta )
   ENDIF

   RETURN Nil

METHOD PlayMeta( oCanvas ) CLASS HPrinter
   LOCAL pps, hDC, x1, y1, nWidth, nHeight

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( oCanvas:handle, pps )

   hwg_Fillrect( hDC, 0, 0, oCanvas:nWidth, oCanvas:nHeight, ::oBrush1:handle )
   IF !Empty( ::hMeta )
      nWidth := oCanvas:nWidth-20
      IF ( nHeight := Int( nWidth * ( ::nHeight / ::nWidth ) ) ) > oCanvas:nHeight-20
         nHeight := oCanvas:nHeight-20
         nWidth := Int( nHeight * ( ::nWidth / ::nHeight ) )
      ENDIF
      x1 := Int( ( oCanvas:nWidth - nWidth ) / 2 )
      y1 := Int( ( oCanvas:nHeight - nHeight ) / 2 )
      hwg_Fillrect( hDC, x1, y1, x1+nWidth, y1+nHeight, ::oBrush2:handle )
      hwg_Drawbitmap( hDC, ::hMeta, , x1, y1, nWidth, nHeight )
   ENDIF

   hwg_Endpaint( oCanvas:handle, pps )

   RETURN Nil

METHOD PrintMeta()
   LOCAL nOper := 0, cExt

   IF !Empty( ::cPrinterName ) .AND. ( cExt := Lower( FilExten( ::cPrinterName ) ) ) $ "pdf;ps;png;svg;"
      nOper := iif( cExt == "pdf", 1, iif( cExt == "ps",2,iif( cExt == "png",3,4 ) ) )
   ENDIF
   hwg_gp_Print( ::hDC, ::aPages, Len( ::aPages ), nOper, ::cPrinterName )

   RETURN Nil

METHOD ChangePage( oCanvas, oSayPage, n, nPage ) CLASS HPrinter
   LOCAL nCurrPage := ::nCurrPage, cMetaName

   IF nPage == Nil
      IF n == 0
         ::nCurrPage := 1
      ELSEIF n == 2
         ::nCurrPage := Len( ::aPages )
      ELSEIF n == 1 .AND. ::nCurrPage < Len( ::aPages )
         ::nCurrPage ++
      ELSEIF n == - 1 .AND. ::nCurrPage > 1
         ::nCurrPage --
      ENDIF
      oSayPage:SetItem( ::nCurrPage )
   ELSE
      ::nCurrPage := nPage
   ENDIF
   IF !( nCurrPage == ::nCurrPage )
      IF !Empty( ::hMeta )
         hwg_Deleteobject( ::hMeta )
      ENDIF
      cMetaName := "/tmp/i"+Ltrim(Str(Int(Seconds())))+".png"
      hwg_gp_Print( ::hDC, ::aPages, Len( ::aPages ), 3, cMetaName, ::nCurrPage )
      ::hMeta := hwg_Openimage( cMetaName )
      FErase( cMetaName )
      IF !Empty( oCanvas )
         hwg_Redrawwindow( oCanvas:handle )
      ENDIF
   ENDIF

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
