/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPrinter class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

STATIC crlf := e"\r\n"

CLASS HPrinter INHERIT HObject

   DATA hDCPrn     INIT 0
   DATA hDC
   DATA cPrinterName
   DATA hPrinter   INIT 0
   DATA lPreview
   DATA nWidth, nHeight, nPWidth, nPHeight
   DATA nHRes, nVRes                     // Resolution ( pixels/mm )
   DATA nOrient        INIT 1
   DATA nPage

   DATA lUseMeta   INIT .F.
   DATA lastPen, lastFont
   DATA aPages, aJob
   DATA aFonts, aPens, aBitmaps
   DATA oFont, oPen
   DATA cScriptFile

   DATA lmm  INIT .F.
   DATA nCurrPage, oTrackV, oTrackH
   DATA nZoom, xOffset, yOffset, x1, y1, x2, y2

   DATA memDC       HIDDEN    // dc offscreen
   DATA memBitmap   HIDDEN    // bitmap offscreen
   DATA NeedsRedraw INIT .T.  // if offscreen needs redrawing...
   DATA FormType       INIT 0
   DATA BinNumber      INIT 0
   DATA Copies         INIT 1
   DATA fDuplexType    INIT 0      HIDDEN
   DATA fPrintQuality  INIT 0      HIDDEN
   DATA PaperLength    INIT 0                        // Value is * 1/10 of mm   1000 = 10cm
   DATA PaperWidth     INIT 0                        //   "    "    "     "       "     "
   DATA TopMargin
   DATA BottomMargin
   DATA LeftMargin
   DATA RightMargin

   METHOD New( cPrinter, lmm, nFormType, nBin, lLandScape, nCopies, lProprierties, hDCPrn )

   METHOD SetMode( nOrientation, nDuplex )
   METHOD AddFont( fontName, nHeight , lBold, lItalic, lUnderline, nCharset )
   METHOD SetFont( oFont )  INLINE (::oFont := oFont, hwg_Selectobject( ::hDC, oFont:handle ) )
   METHOD Settextcolor( nColor )  INLINE hwg_Settextcolor( ::hDC, nColor )
   METHOD SetTBkColor( nColor )   INLINE hwg_Setbkcolor( ::hDC, nColor )
   METHOD Setbkmode( lmode )   INLINE hwg_Setbkmode( ::hDC, IF( lmode, 1, 0 ) )
   METHOD Recalc( x1, y1, x2, y2 )
   METHOD StartDoc( lPreview, cScriptFile )
   METHOD EndDoc()
   METHOD StartPage()
   METHOD EndPage()
   METHOD LoadScript( cScriptFile )
   METHOD SaveScript( cScriptFile )
   METHOD ReleaseMeta()
   METHOD PaintDoc( oWnd )
   METHOD PrintDoc( nPage )
   METHOD PrintScript( hDC, nPage, x1, y1, x2, y2 )
   METHOD Preview( cTitle )
   METHOD END()
   METHOD Box( x1, y1, x2, y2, oPen, oBrush )
   METHOD Line( x1, y1, x2, y2, oPen )
   METHOD Say( cString, x1, y1, x2, y2, nOpt, oFont, nTextColor, nBkColor )
   METHOD Bitmap( x1, y1, x2, y2, nOpt, hBitmap, cImageName )
   METHOD GetTextWidth( cString, oFont )
   METHOD ResizePreviewDlg( oCanvas, nZoom, msg, wParam, lParam ) HIDDEN
   METHOD ChangePage( oCanvas, oSayPage, n, nPage ) HIDDEN

ENDCLASS

METHOD New( cPrinter, lmm, nFormType, nBin, lLandScape, nCopies, lProprierties, hDCPrn ) CLASS HPrinter

   LOCAL aPrnCoors, cPrinterName

   IF ValType( nFormType ) = "N"
      ::FormType := nFormType
   ENDIF
   IF ValType( nBin ) == "N"
      ::BinNumber := nBin
   ENDIF
   IF ValType( lLandScape ) == "L"
      ::nOrient := iif( lLandScape, 2, 1 )
   ENDIF
   IF ValType( nCopies ) == "N"
      IF nCopies > 0
         ::Copies := nCopies
      ENDIF
   ENDIF
   IF ValType( lProprierties ) <> "L"
      lProprierties := .T.
   ENDIF

   IF lmm != Nil
      ::lmm := lmm
   ENDIF
   IF !Empty( hDCPrn )
      ::hDCPrn = hDCPrn
      ::cPrinterName := cPrinter
   ELSE

      IF cPrinter == Nil
         ::hDCPrn := hwg_Printsetup( @cPrinterName )
         ::cPrinterName := cPrinterName
      ELSEIF Empty( cPrinter )
         cPrinterName := HWG_GETDEFAULTPRINTER()
         ::hDCPrn := Hwg_OpenPrinter( cPrinterName )
         ::cPrinterName := cPrinterName
      ELSE
         ::hDCPrn := Hwg_OpenPrinter( cPrinter )
         ::cPrinterName := cPrinter
      ENDIF
   ENDIF

   IF Empty( ::hDCPrn )
      RETURN Nil
   ELSE
      IF lProprierties
         IF !Hwg_SetDocumentProperties( ::hDCPrn, ::cPrinterName, ::FormType, ::nOrient == 2, ::Copies, ::BinNumber, ::fDuplexType, ::fPrintQuality, ::PaperLength, ::PaperWidth )
            RETURN NIL
         ENDIF
      ENDIF

      aPrnCoors := hwg_Getdevicearea( ::hDCPrn )
      ::nWidth  := iif( ::lmm, aPrnCoors[ 3 ], aPrnCoors[ 1 ] )
      ::nHeight := iif( ::lmm, aPrnCoors[ 4 ], aPrnCoors[ 2 ] )
      ::nPWidth  := iif( ::lmm, aPrnCoors[ 8 ], aPrnCoors[ 1 ] )
      ::nPHeight := iif( ::lmm, aPrnCoors[ 9 ], aPrnCoors[ 2 ] )
      ::nHRes   := aPrnCoors[ 1 ] / aPrnCoors[ 3 ]
      ::nVRes   := aPrnCoors[ 2 ] / aPrnCoors[ 4 ]
      //hwg_writelog( str(::nWidth)+"/"+str(::nHeight)+"/"+str(::nPWidth)+"/"+str(::nPHeight)+"/"+str(::nHRes)+"/"+str(::nVRes))
   ENDIF

   RETURN Self

METHOD SetMode( nOrientation, nDuplex ) CLASS HPrinter

   LOCAL hPrinter := ::hPrinter, hDC, aPrnCoors

   hDC := hwg_Setprintermode( ::cPrinterName, @hPrinter, nOrientation, nDuplex )
   IF !Empty( nOrientation )
      ::nOrient := nOrientation
   ENDIF
   IF hDC != Nil
      IF !Empty( ::hDCPrn )
         hwg_Deletedc( ::hDCPrn )
      ENDIF
      ::hDCPrn := hDC
      ::hPrinter := hPrinter
      aPrnCoors := hwg_Getdevicearea( ::hDCPrn )
      ::nWidth  := iif( ::lmm, aPrnCoors[ 3 ], aPrnCoors[ 1 ] )
      ::nHeight := iif( ::lmm, aPrnCoors[ 4 ], aPrnCoors[ 2 ] )
      ::nPWidth  := iif( ::lmm, aPrnCoors[ 8 ], aPrnCoors[ 1 ] )
      ::nPHeight := iif( ::lmm, aPrnCoors[ 9 ], aPrnCoors[ 2 ] )
      ::nHRes   := aPrnCoors[ 1 ] / aPrnCoors[ 3 ]
      ::nVRes   := aPrnCoors[ 2 ] / aPrnCoors[ 4 ]
      // writelog( ":"+str(aPrnCoors[1])+str(aPrnCoors[2])+str(aPrnCoors[3])+str(aPrnCoors[4])+str(aPrnCoors[5])+str(aPrnCoors[6])+str(aPrnCoors[8])+str(aPrnCoors[9]) )
      RETURN .T.
   ENDIF

   RETURN .F.

METHOD AddFont( fontName, nHeight , lBold, lItalic, lUnderline, nCharset ) CLASS HPrinter

   LOCAL oFont

   IF ::lmm .AND. nHeight != Nil
      nHeight := Round( nHeight * ::nVRes, 0 )
   ENDIF
   oFont := HFont():Add( fontName, , nHeight,          ;
      iif( lBold != Nil .AND. lBold, 700, 400 ), nCharset, ;
      iif( lItalic != Nil .AND. lItalic, 255, 0 ), iif( lUnderline != Nil .AND. lUnderline, 1, 0 ) )

   RETURN oFont

METHOD END() CLASS HPrinter

   IF !Empty( ::hDCPrn )
      hwg_Deletedc( ::hDCPrn )
      ::hDCPrn := Nil
   ENDIF
   IF !Empty( ::hPrinter )
      hwg_Closeprinter( ::hPrinter )
   ENDIF
   ::ReleaseMeta()

   RETURN Nil

METHOD Recalc( x1, y1, x2, y2 ) CLASS HPrinter

   IF ::lmm
      x1 := Round( x1 * ::nHRes, 1 )
      x2 := Round( x2 * ::nHRes, 1 )
      y1 := Round( y1 * ::nVRes, 1 )
      y2 := Round( y2 * ::nVRes, 1 )
   ENDIF

   RETURN Nil

METHOD Box( x1, y1, x2, y2, oPen, oBrush ) CLASS HPrinter

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      IF oPen != Nil
         IF ::lUseMeta .AND. ::lPreview
            IF Empty( ::lastPen ) .OR. oPen:width != ::lastPen:width .OR. ;
                  oPen:style != ::lastPen:style .OR. oPen:color != ::lastPen:color
               ::lastPen := oPen
               ::aPages[::nPage] += "pen," + LTrim( Str( oPen:width ) ) + "," + ;
                  LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:color ) ) + "," + crlf
            ENDIF
         ENDIF
      ENDIF

      ::aPages[::nPage] += "box," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + crlf
   ELSE
      IF oPen != Nil
         hwg_Selectobject( ::hDC, oPen:handle )
      ENDIF
      IF oBrush != Nil
         hwg_Selectobject( ::hDC, oBrush:handle )
      ENDIF

      hwg_Rectangle( ::hDC, x1, y1, x2, y2 )
   ENDIF

   RETURN Nil

METHOD Line( x1, y1, x2, y2, oPen ) CLASS HPrinter

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      IF oPen != Nil
         IF Empty( ::lastPen ) .OR. oPen:width != ::lastPen:width .OR. ;
               oPen:style != ::lastPen:style .OR. oPen:color != ::lastPen:color
            ::lastPen := oPen
            ::aPages[::nPage] += "pen," + LTrim( Str( oPen:width ) ) + "," + ;
               LTrim( Str( oPen:style ) ) + "," + LTrim( Str( oPen:color ) ) + "," + crlf
         ENDIF
      ENDIF

      ::aPages[::nPage] += "lin," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + crlf
   ELSE
      IF oPen != Nil
         hwg_Selectobject( ::hDC, oPen:handle )
      ENDIF
      hwg_Drawline( ::hDC, x1, y1, x2, y2 )
   ENDIF

   RETURN Nil

METHOD Say( cString, x1, y1, x2, y2, nOpt, oFont, nTextColor, nBkColor ) CLASS HPrinter

   LOCAL hFont, nOldTC, nOldBC

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      IF oFont == Nil
         oFont := ::oFont
      ENDIF
      IF oFont != Nil
         IF ( ::lastFont == Nil .OR. !( ::lastFont:name == oFont:name .AND. ;
               ::lastFont:height == oFont:height .AND. ;
               ::lastFont:weight == oFont:weight .AND. ;
               ::lastFont:Italic == oFont:Italic .AND. ;
               ::lastFont:Underline == oFont:Underline ) )
            ::lastFont := oFont
            ::aPages[::nPage] += "fnt," + oFont:name + "," + LTrim( Str( oFont:height ) ) + "," + ;
               LTrim( Str( oFont:weight ) ) + "," + LTrim( Str( oFont:Italic ) ) + "," + ;
               LTrim( Str( oFont:Underline ) ) + "," + LTrim( Str( oFont:Charset ) ) + crlf
         ENDIF
      ENDIF

      ::aPages[::nPage] += "txt," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + ;
         iif( nOpt == Nil, ",", LTrim( Str(nOpt ) ) + "," ) + cString + crlf
   ELSE
      IF oFont != Nil
         hFont := hwg_Selectobject( ::hDC, oFont:handle )
      ENDIF
      IF nTextColor != Nil
         nOldTC := hwg_Settextcolor( ::hDC, nTextColor )
      ENDIF
      IF nBkColor != Nil
         nOldBC := hwg_Setbkcolor( ::hDC, nBkColor )
      ENDIF

      hwg_Drawtext( ::hDC, cString, x1, y1, x2, y2, iif( nOpt == Nil, DT_LEFT, nOpt ) )

      IF oFont != Nil
         hwg_Selectobject( ::hDC, hFont )
      ENDIF
      IF nTextColor != Nil
         hwg_Settextcolor( ::hDC, nOldTC )
      ENDIF
      IF nBkColor != Nil
         hwg_Setbkcolor( ::hDC, nOldBC )
      ENDIF

   ENDIF

   RETURN Nil

METHOD Bitmap( x1, y1, x2, y2, nOpt, hBitmap, cImageName ) CLASS HPrinter

   ::Recalc( @x1, @y1, @x2, @y2 )

   IF !::lUseMeta .AND. ::lPreview
      ::aPages[::nPage] += "img," + LTrim( Str( x1 ) ) + "," + LTrim( Str( y1 ) ) + "," + ;
         LTrim( Str( x2 ) ) + "," + LTrim( Str( y2 ) ) + "," + ;
         iif( nOpt == Nil, ",", LTrim( Str(nOpt ) ) + "," ) + cImageName + crlf
   ELSE
      hwg_Drawbitmap( ::hDC, hBitmap, iif( nOpt == Nil, SRCAND, nOpt ), x1, y1, x2 - x1 + 1, y2 - y1 + 1 )
   ENDIF

   RETURN Nil

METHOD GetTextWidth( cString, oFont ) CLASS HPrinter

   LOCAL arr, hFont

   IF oFont != Nil
      hFont := hwg_Selectobject( ::hDC, oFont:handle )
   ENDIF
   arr := hwg_Gettextsize( ::hDC, cString )
   IF oFont != Nil
      hwg_Selectobject( ::hDC, hFont )
   ENDIF

   RETURN iif( ::lmm, Int( arr[ 1 ] / ::nHRes ), arr[ 1 ] )

METHOD StartDoc( lPreview, cScriptFile ) CLASS HPrinter

   IF !Empty( lPreview )
      ::lPreview := .T.
      IF ::lUseMeta
         ::ReleaseMeta()
      ENDIF
      ::aPages := {}
      ::aFonts := {}
      ::aPens := {}
      ::aBitmaps := {}
      ::cScriptFile := cScriptFile
   ELSE
      ::lPreview := .F.
      ::hDC := ::hDCPrn
      Hwg_StartDoc( ::hDC )
   ENDIF
   ::nPage := 0

   RETURN Nil

METHOD EndDoc() CLASS HPrinter

   LOCAL han, i

   IF !::lUseMeta .AND. ::lPreview .AND. !Empty( ::cScriptFile )
      ::SaveScript()
   ENDIF

   IF ! ::lPreview
      Hwg_EndDoc( ::hDC )
   ENDIF

   RETURN Nil

METHOD StartPage() CLASS HPrinter

   LOCAL fname

   ::nPage ++
   IF ::lPreview
      IF ::lUseMeta
         AAdd( ::aPages, hwg_Createmetafile( ::hDCPrn, Nil ) )
         ::hDC := ATail( ::aPages )
      ELSE
         AAdd( ::aPages, "page," + LTrim( Str( ::nPage ) ) + crlf )
      ENDIF
   ELSE
      Hwg_StartPage( ::hDC )
   ENDIF

   RETURN Nil

METHOD EndPage() CLASS HPrinter

   LOCAL nLen

   IF ::lPreview
      IF ::lUseMeta
         nLen := Len( ::aPages )
         ::aPages[ nLen ] := hwg_Closeenhmetafile( ::aPages[ nLen ] )
         ::hDC := 0
      ENDIF
   ELSE
      Hwg_EndPage( ::hDC )
   ENDIF

   RETURN Nil

METHOD LoadScript( cScriptFile ) CLASS HPrinter

   LOCAL arr, i, s

   IF Empty( cScriptFile ) .OR. Empty( arr := hb_aTokens( MemoRead( cScriptFile ), crlf ) )
      RETURN .F.
   ENDIF
   ::cScriptFile := cScriptFile
   ::aPages := {}

   ::aJob := hb_aTokens( arr[1], "," )

   FOR i := 1 TO Len( arr )
      IF Left( arr[i], 4 ) == "page"
         IF !Empty( s )
            AAdd( ::aPages, s )
         ENDIF
         s := arr[i] + crlf
      ELSEIF !Empty( arr[i] ) .AND. !Empty( s )
         s += arr[i]
      ENDIF
   NEXT
   IF !Empty( s )
      AAdd( ::aPages, s )
   ENDIF

   RETURN !Empty( ::aPages )

METHOD SaveScript( cScriptFile ) CLASS HPrinter

   LOCAL han, i

   IF Empty( cScriptFile )
      IF Empty( ::cScriptFile )
         cScriptFile := ::cScriptFile := hwg_Savefile( "*.*","All files( *.* )","*.*",Curdir() )
      ELSE
         cScriptFile := ::cScriptFile
      ENDIF
   ENDIF

   IF !Empty( cScriptFile )
      han := FCreate( cScriptFile )
      FWrite( han, "job," + Iif(::lmm,"mm,","px,") + ;
            LTrim( Str(::nWidth ) ) + "," + LTrim( Str(::nHeight ) ) + "," + ;
            LTrim( Str(::nHRes ) ) + "," + LTrim( Str(::nVRes ) ) + "," + hb_cdpSelect() + crlf )
      FOR i := 1 TO Len( ::aPages )
         FWrite( han, ::aPages[i] + crlf )
      NEXT
      FClose( han )
   ENDIF

   RETURN Nil

METHOD ReleaseMeta() CLASS HPrinter

   LOCAL i, nLen

   IF !::lUseMeta == Nil
      RETURN Nil
   ENDIF

   nLen := Len( ::aPages )
   FOR i := 1 TO nLen
      hwg_Deleteenhmetafile( ::aPages[ i ] )
   NEXT
   ::aPages := Nil

   RETURN Nil

METHOD Preview( cTitle, aBitmaps, aTooltips, aBootUser ) CLASS HPrinter

   LOCAL oDlg, oToolBar, oSayPage, oBtn, oCanvas, i, aPage := { }
   LOCAL oFont := HFont():Add( "Times New Roman", 0, - 13, 700 )
   LOCAL lTransp := ( aBitmaps != Nil .AND. Len( aBitmaps ) > 9 .AND. aBitmaps[ 10 ] != Nil .AND. aBitmaps[ 10 ] )

   aPage := Array( Len( ::aPages ) )
   FOR i := 1 TO Len( aPage )
      aPage[i] := Str( i, 4 ) + ":" + Str( Len( aPage ), 4 )
   NEXT

   IF cTitle == Nil ; cTitle := "Print preview - " + ::cPrinterName ; ENDIF
   ::nZoom := 0
   ::nCurrPage := 1

   ::NeedsRedraw := .T.

   INIT DIALOG oDlg TITLE cTitle                  ;
      At 40, 10 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight()                        ;
      STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + WS_MAXIMIZEBOX + WS_CLIPCHILDREN ;
      ON INIT { | o | o:Maximize(), ::ResizePreviewDlg( oCanvas, 1 ) } ;
      ON EXIT { || oCanvas:brush := NIL, .T. }

   oDlg:bScroll := { | oWnd, msg, wParam, lParam | HB_SYMBOL_UNUSED( oWnd ), ::ResizePreviewDlg( oCanvas, , msg, wParam, lParam ) }
   oDlg:brush := HBrush():Add( 11316396 )

   @ 0, 0 PANEL oToolBar SIZE 88, oDlg:nHeight

   // Canvas should fill ALL the available space
   @ oToolBar:nWidth, 0 PANEL oCanvas ;
      SIZE oDlg:nWidth - oToolBar:nWidth, oDlg:nHeight ;
      ON SIZE { | o, x, y | o:Move( , , x - oToolBar:nWidth, y ), ::ResizePreviewDlg( o ) } ;
      ON PAINT { || ::PaintDoc( oCanvas ) } STYLE WS_VSCROLL + WS_HSCROLL

   oCanvas:bScroll := { | oWnd, msg, wParam, lParam | HB_SYMBOL_UNUSED( oWnd ), ::ResizePreviewDlg( oCanvas, , msg, wParam, lParam ) }
   IF !::lUseMeta
      oCanvas:bOther := { |o,m,wp,lp|HB_SYMBOL_UNUSED(wp),Iif(m==WM_LBUTTONDBLCLK,MessProc(Self,o,lp),-1) }
      SET KEY FCONTROL, ASC("S") TO ::SaveScript()
   ENDIF
   // DON'T CHANGE NOR REMOVE THE FOLLOWING LINE !
   // I need it to have the correct side-effect to avoid flickering !!!
   oCanvas:brush := 0

   @ 3, 2 OWNERBUTTON oBtn OF oToolBar ON CLICK { || hwg_EndDialog() } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "Exit" FONT oFont        ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 1 ], "Exit Preview" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 1 .AND. aBitmaps[ 2 ] != Nil
      oBtn:oBitmap  := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 2 ] ), HBitmap():AddFile( aBitmaps[ 2 ] ) )
      oBtn:title    := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 31 LINE LENGTH oToolBar:nWidth - 1

   @ 3, 36 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::PrintDoc() } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "Print" FONT oFont           ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 2 ], "Print file" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 2 .AND. aBitmaps[ 3 ] != Nil
      oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 3 ] ), HBitmap():AddFile( aBitmaps[ 3 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 62 COMBOBOX oSayPage ITEMS aPage of oToolBar ;
      SIZE oToolBar:nWidth - 6, 24 COLOR "fff000" backcolor 12507070 ;
      ON CHANGE { || ::ChangePage( oCanvas, oSayPage, , oSayPage:GetValue() ) } STYLE WS_VSCROLL


   @ 3, 86 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, 0 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "|<<" FONT oFont                 ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 3 ], "First page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 3 .AND. aBitmaps[ 4 ] != Nil
      oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 4 ] ), HBitmap():AddFile( aBitmaps[ 4 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 110 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT ">>" FONT oFont                  ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 4 ], "Next page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 4 .AND. aBitmaps[ 5 ] != Nil
      oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 5 ] ), HBitmap():AddFile( aBitmaps[ 5 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 134 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, - 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "<<" FONT oFont    ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 5 ], "Previous page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 5 .AND. aBitmaps[ 6 ] != Nil
      oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 6 ] ), HBitmap():AddFile( aBitmaps[ 6 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 158 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ChangePage( oCanvas, oSayPage, 2 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT ">>|" FONT oFont   ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 6 ], "Last page" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 6 .AND. aBitmaps[ 7 ] != Nil
      oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 7 ] ), HBitmap():AddFile( aBitmaps[ 7 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 189 LINE LENGTH oToolBar:nWidth - 1

   @ 3, 192 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ResizePreviewDlg( oCanvas, - 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "(-)" FONT oFont   ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 7 ], "Zoom out" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 7 .AND. aBitmaps[ 8 ] != Nil
      oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 8 ] ), HBitmap():AddFile( aBitmaps[ 8 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 3, 216 OWNERBUTTON oBtn OF oToolBar ON CLICK { || ::ResizePreviewDlg( oCanvas, 1 ) } ;
      SIZE oToolBar:nWidth - 6, 24 TEXT "(+)" FONT oFont   ;
      TOOLTIP iif( aTooltips != Nil, aTooltips[ 8 ], "Zoom in" )
   IF aBitmaps != Nil .AND. Len( aBitmaps ) > 8 .AND. aBitmaps[ 9 ] != Nil
      oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBitmaps[ 9 ] ), HBitmap():AddFile( aBitmaps[ 9 ] ) )
      oBtn:title   := Nil
      oBtn:lTransp := lTransp
   ENDIF

   @ 1, 243 LINE LENGTH oToolBar:nWidth - 1

   IF aBootUser != Nil

      @ 1, 313 LINE LENGTH oToolBar:nWidth - 1

      @ 3, 316 OWNERBUTTON oBtn OF oToolBar  ;
         SIZE oToolBar:nWidth - 6, 24        ;
         TEXT iif( Len( aBootUser ) == 4, aBootUser[ 4 ], "User Button" ) ;
         FONT oFont                   ;
         TOOLTIP iif( aBootUser[ 3 ] != Nil, aBootUser[ 3 ], "User Button" )

      oBtn:bClick := aBootUser[ 1 ]

      IF aBootUser[ 2 ] != Nil
         oBtn:oBitmap := iif( aBitmaps[ 1 ], HBitmap():AddResource( aBootUser[ 2 ] ), HBitmap():AddFile( aBootUser[ 2 ] ) )
         oBtn:title   := Nil
         oBtn:lTransp := lTransp
      ENDIF

   ENDIF

   oDlg:Activate()

   SET KEY FCONTROL, ASC("S") TO
   oDlg:brush:Release()
   oFont:Release()
   IF !::lUseMeta
      FOR i := 1 TO Len( ::aFonts )
         ::aFonts[i]:Release()
      NEXT
      ::aFonts := Nil
      FOR i := 1 TO Len( ::aPens )
         ::aPens[i]:Release()
      NEXT
      ::aPens := Nil
      FOR i := 1 TO Len( ::aBitmaps )
         hwg_Deleteobject( ::aBitmaps[i,2] )
      NEXT
      ::aBitmaps := Nil
   ENDIF

   RETURN Nil

METHOD ChangePage( oCanvas, oSayPage, n, nPage ) CLASS hPrinter

   IF nPage == nil
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
   ::NeedsRedraw := .T.
   hwg_Redrawwindow( oCanvas:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )

   RETURN Nil



/***
 nZoom: zoom factor: -1 or 1, NIL if scroll message
*/

METHOD ResizePreviewDlg( oCanvas, nZoom, msg, wParam, lParam ) CLASS hPrinter

   LOCAL nWidth, nHeight, k1, k2, x, y
   LOCAL i, nPos, wmsg, nPosVert, nPosHorz

   x := oCanvas:nWidth
   y := oCanvas:nHeight

   HB_SYMBOL_UNUSED( lParam )

   nPosVert := hwg_Getscrollpos( oCanvas:handle, SB_VERT )
   nPosHorz := hwg_Getscrollpos( oCanvas:handle, SB_HORZ )

   IF msg = WM_VSCROLL
      hwg_Setscrollrange( oCanvas:handle, SB_VERT, 1, 20 )
      wmsg := hwg_Loword( wParam )
      IF wmsg = SB_THUMBPOSITION .OR. wmsg = SB_THUMBTRACK
         nPosVert := hwg_Hiword( wParam )
      ELSEIF wmsg = SB_LINEUP
         nPosVert := nPosVert - 1
         IF nPosVert < 1
            nPosVert := 1
         ENDIF
      ELSEIF wmsg = SB_LINEDOWN
         nPosVert := nPosVert + 1
         IF nPosVert > 20
            nPosVert = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEDOWN
         nPosVert := nPosVert + 4
         IF nPosVert > 20
            nPosVert = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEUP
         nPosVert := nPosVert - 4
         IF nPosVert < 1
            nPosVert = 1
         ENDIF
      ENDIF
      hwg_Setscrollpos( oCanvas:handle, SB_VERT, nPosVert )
      ::NeedsRedraw := .T.
   ENDIF

   IF msg = WM_HSCROLL
      hwg_Setscrollrange( oCanvas:handle, SB_HORZ, 1, 20 )
      wmsg := hwg_Loword( wParam )
      IF wmsg = SB_THUMBPOSITION .OR. wmsg = SB_THUMBTRACK
         nPosHorz := hwg_Hiword( wParam )
      ELSEIF wmsg = SB_LINEUP
         nPosHorz := nPosHorz - 1
         IF nPosHorz < 1
            nPosHorz = 1
         ENDIF
      ELSEIF wmsg = SB_LINEDOWN
         nPosHorz := nPosHorz + 1
         IF nPosHorz > 20
            nPosHorz = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEDOWN
         nPosHorz := nPosHorz + 4
         IF nPosHorz > 20
            nPosHorz = 20
         ENDIF
      ELSEIF wmsg = SB_PAGEUP
         nPosHorz := nPosHorz - 4
         IF nPosHorz < 1
            nPosHorz = 1
         ENDIF
      ENDIF
      hwg_Setscrollpos( oCanvas:handle, SB_HORZ, nPosHorz )
      ::NeedsRedraw := .T.
   ENDIF

   IF msg == WM_MOUSEWHEEL
      hwg_Setscrollrange( oCanvas:handle, SB_VERT, 1, 20 )
      IF hwg_Hiword( wParam ) > 32678
         IF ++ nPosVert > 20
            nPosVert := 20
         ENDIF
      ELSE
         IF -- nPosVert < 1
            nPosVert := 1
         ENDIF
      ENDIF
      hwg_Setscrollpos( oCanvas:handle, SB_VERT, nPosVert )
      ::NeedsRedraw := .T.
   ENDIF

   IF nZoom != Nil
      // If already at maximum zoom returns
      IF nZoom < 0 .AND. ::nZoom == 0
         RETURN Nil
      ENDIF
      ::nZoom += nZoom
      ::NeedsRedraw := .T.
   ENDIF
   k1 := ::nWidth / ::nHeight
   k2 := ::nHeight / ::nWidth

   IF ::nWidth > ::nHeight
      nWidth := x - 20
      nHeight := Round( nWidth * k2, 0 )
      IF nHeight > y - 20
         nHeight := y - 20
         nWidth := Round( nHeight * k1, 0 )
      ENDIF
      ::NeedsRedraw := .T.
   ELSE
      nHeight := y - 10
      nWidth := Round( nHeight * k1, 0 )
      IF nWidth > x - 20
         nWidth := x - 20
         nHeight := Round( nWidth * k2, 0 )
      ENDIF
      ::NeedsRedraw := .T.
   ENDIF

   IF ::nZoom > 0
      FOR i := 1 TO ::nZoom
         nWidth := Round( nWidth * 1.5, 0 )
         nHeight := Round( nHeight * 1.5, 0 )
      NEXT
      ::NeedsRedraw := .T.
   ELSEIF ::nZoom == 0
      nWidth := Round( nWidth * 0.93, 0 )
      nHeight := Round( nHeight * 0.93, 0 )
   ENDIF

   ::xOffset := ::yOffset := 0
   IF nHeight > y
      nPos := nPosVert
      IF nPos > 0
         ::yOffset := Round( ( ( nPos - 1 ) / 18 ) * ( nHeight - y + 10 ), 0 )
      ENDIF
   ELSE
      hwg_Setscrollpos( oCanvas:handle, SB_VERT, 0 )
   ENDIF

   IF nWidth > x
      nPos := nPosHorz
      IF nPos > 0
         nPos := ( nPos - 1 ) / 18
         ::xOffset := Round( nPos * ( nWidth - x + 10 ), 0 )
      ENDIF
   ELSE
      hwg_Setscrollpos( oCanvas:handle, SB_HORZ, 0 )
   ENDIF

   ::x1 := iif( nWidth < x, Round( ( x - nWidth ) / 2, 0 ), 10 ) - ::xOffset
   ::x2 := ::x1 + nWidth - 1
   ::y1 := iif( nHeight < y, Round( ( y - nHeight ) / 2, 0 ), 10 ) - ::yOffset
   ::y2 := ::y1 + nHeight - 1

   IF nZoom != Nil .OR. msg != Nil
      hwg_Redrawwindow( oCanvas:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )  // Force a complete redraw
   ENDIF
   //hwg_writelog( str(::x1)+" "+str(::y1)+" "+str(::x2)+" "+str(::y2)+" "+str(::xoffset)+" "+str(::yoffset) )

   RETURN Nil

METHOD PaintDoc( oWnd ) CLASS HPrinter

   LOCAL pps, hDC
   LOCAL Rect := hwg_Getclientrect( oWnd:handle )
   STATIC Brush := NIL
   STATIC BrushShadow := NIL
   STATIC BrushBorder := NIL
   STATIC BrushWhite := NIL
   STATIC BrushBlack := NIL
   STATIC BrushLine := NIL
   STATIC BrushBackground := NIL

   IF ::xOffset == Nil
      ::ResizePreviewDlg( oWnd )
   ENDIF

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( oWnd:handle, pps )

   IF ValType( ::memDC ) == "U"
      ::memDC := hDC():New()
      ::memDC:Createcompatibledc( hDC )
      ::memBitmap := hwg_Createcompatiblebitmap( hDC, Rect[ 3 ] - Rect[ 1 ], Rect[ 4 ] - Rect[ 2 ] )
      ::memDC:Selectobject( ::memBitmap )
      Brush           := HBrush():Add( hwg_Getsyscolor( COLOR_3DHILIGHT + 1 ) ):handle
      BrushWhite      := HBrush():Add( hwg_Rgb( 255, 255, 255 ) ):handle
      BrushBlack      := HBrush():Add( hwg_Rgb( 0, 0, 0 ) ):handle
      BrushLine       := HBrush():Add( hwg_Rgb( 102, 100, 92 ) ):handle
      BrushBackground := HBrush():Add( hwg_Rgb( 204, 200, 184 ) ):handle
      BrushShadow     := HBrush():Add( hwg_Rgb( 178, 175, 161 ) ):handle
      BrushBorder     := HBrush():Add( hwg_Rgb( 129, 126, 115 ) ):handle
   ENDIF

   IF ::NeedsRedraw
      // Draw the canvas background (gray)
      hwg_Fillrect( ::memDC:m_hDC, rect[ 1 ], rect[ 2 ], rect[ 3 ], rect[ 4 ], BrushBackground )
      hwg_Fillrect( ::memDC:m_hDC, rect[ 1 ], rect[ 2 ], rect[ 1 ], rect[ 4 ], BrushBorder )
      hwg_Fillrect( ::memDC:m_hDC, rect[ 1 ], rect[ 2 ], rect[ 3 ], rect[ 2 ], BrushBorder )
      // Draw the PAPER background (white)
      hwg_Fillrect( ::memDC:m_hDC, ::x1 - 1, ::y1 - 1, ::x2 + 1, ::y2 + 1, BrushLine )
      hwg_Fillrect( ::memDC:m_hDC, ::x1, ::y1, ::x2, ::y2, BrushWhite )
      // Draw the actual printer data
      IF ::lUseMeta
         hwg_Playenhmetafile( ::memDC:m_hDC, ::aPages[ ::nCurrPage ], ::x1, ::y1, ::x2, ::y2 )
      ELSE
         ::PrintScript( ::memDC:m_hDC, ::nCurrPage, ::x1, ::y1, ::x2, ::y2 )
      ENDIF

      hwg_Fillrect( ::memDC:m_hDC, ::x2, ::y1 + 2, ::x2 + 1, ::y2 + 2, BrushBlack )
      hwg_Fillrect( ::memDC:m_hDC, ::x2 + 1, ::y1 + 1, ::x2 + 2, ::y2 + 2, BrushShadow )
      hwg_Fillrect( ::memDC:m_hDC, ::x2 + 1, ::y1 + 2, ::x2 + 2, ::y2 + 2, BrushLine )
      hwg_Fillrect( ::memDC:m_hDC, ::x2 + 2, ::y1 + 2, ::x2 + 3, ::y2 + 2, BrushShadow )


      hwg_Fillrect( ::memDC:m_hDC, ::x1 + 2, ::y2, ::x2, ::y2 + 2, BrushBlack )
      hwg_Fillrect( ::memDC:m_hDC, ::x1 + 2, ::y2 + 1, ::x2 + 1, ::y2 + 2, BrushLine )
      hwg_Fillrect( ::memDC:m_hDC, ::x1 + 2, ::y2 + 2, ::x2 + 2, ::y2 + 3, BrushShadow )
      ::NeedsRedraw := .F.
   ENDIF
   hwg_Bitblt( hDC, rect[ 1 ], rect[ 2 ], rect[ 3 ], rect[ 4 ], ::memDC:m_hDC, 0, 0, SRCCOPY )

   hwg_Endpaint( oWnd:handle, pps )

   RETURN Nil

METHOD PrintDoc( nPage ) CLASS HPrinter

   IF ::lPreview
      ::StartDoc()
      IF nPage == Nil
         FOR nPage := 1 TO Len( ::aPages )
            IF ::lUseMeta
               hwg_Printenhmetafile( ::hDCPrn, ::aPages[ nPage ] )
            ELSE
               Hwg_StartPage( ::hDCPrn )
               ::PrintScript( ::hDCPrn, nPage )
               Hwg_EndPage( ::hDCPrn )
            ENDIF
         NEXT
      ELSE
         IF ::lUseMeta
            hwg_Printenhmetafile( ::hDCPrn, ::aPages[ nPage ] )
         ELSE
            Hwg_StartPage( ::hDCPrn )
            ::PrintScript( ::hDCPrn, nPage )
            Hwg_EndPage( ::hDCPrn )
         ENDIF
      ENDIF
      ::EndDoc()
      ::lPreview := .T.
   ENDIF

   RETURN Nil

METHOD PrintScript( hDC, nPage, x1, y1, x2, y2 ) CLASS HPrinter

   LOCAL i, j, arr, nPos, sCom
   LOCAL nOpt, cTemp
   LOCAL name, height, weight, italic, underline, charset, oFont
   LOCAL width, style, color, oPen, hBitmap
   LOCAL nHRes, nVRes, xOff, yOff

   IF Empty( ::aPages ) .OR. Empty( nPage ) .OR. Len( ::aPages ) < nPage .OR. ;
         Empty( arr := hb_aTokens( ::aPages[nPage], crlf ) )
      RETURN Nil
   ENDIF

   IF x1 == Nil
      nHRes := ::nHRes
      nVRes := ::nVRes
      xOff := 0
      yOff := 0
   ELSE
      nHRes := (x2-x1)/::nWidth
      nVRes := (y2-y1)/::nHeight
      xOff := x1
      yOff := y1
   ENDIF
   FOR i := 1 TO Len( arr )
      nPos := 0
      sCom := hb_TokenPtr( arr[i], @nPos, "," )
      IF sCom $ "txt;lin;box;img"
         x1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHRes / ::nHres, 0 ) + xOff
         y1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / ::nVres, 0 ) + yOff
         x2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHRes / ::nHres, 0 ) + xOff
         y2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / ::nVres, 0 ) + yOff

         IF sCom == "txt"
            nOpt := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
            cTemp := SubStr( arr[i], nPos+1 )
            hwg_Drawtext( hDC, cTemp, x1, y1, x2, y2, nOpt )

         ELSEIF sCom == "lin"
            hwg_Drawline( hDC, x1, y1, x2, y2 )

         ELSEIF sCom == "box"
            hwg_Rectangle( hDC, x1, y1, x2, y2 )

         ELSEIF sCom == "img"
            nOpt := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
            cTemp := SubStr( arr[i], nPos+1 )

            FOR j := 1 TO Len( ::aBitmaps )
               IF ::aBitmaps[j,1] == cTemp
                  EXIT
               ENDIF
            NEXT
            IF j > Len( ::aBitmaps )
               hBitmap := hwg_Openbitmap( cTemp, hDC )
               Aadd( ::aBitmaps, { cTemp, hBitmap } )
            ELSE
               hBitmap := ::aBitmaps[j,2]
            ENDIF
            hwg_Drawbitmap( hDC, hBitmap, Iif( Empty(nOpt), SRCAND, nOpt ), x1, y1, x2 - x1 + 1, y2 - y1 + 1 )
         ENDIF

      ELSEIF sCom == "fnt"
         name := hb_TokenPtr( arr[i], @nPos, "," )
         height := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / ::nVres, 0 )
         weight := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         italic := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         underline := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         charset := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         FOR j := 1 TO Len( ::aFonts )
            IF ::aFonts[j]:name == name .AND. ::aFonts[j]:height == height .AND. ;
               ::aFonts[j]:weight == weight .AND. ::aFonts[j]:italic == italic .AND. ;
               ::aFonts[j]:underline == underline .AND. ::aFonts[j]:charset == charset
               EXIT
            ENDIF
         NEXT
         IF j > Len( ::aFonts )
            oFont := HFont():Add( name,, height, weight, charset, italic, underline )
            Aadd( ::aFonts, oFont )
         ELSE
            oFont := ::aFonts[j]
         ENDIF
         hwg_Selectobject( hDC, oFont:handle )

      ELSEIF sCom == "pen"
         width := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / ::nVres, 0 )
         style := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         color := Val( hb_TokenPtr( arr[i], @nPos, "," ) )
         FOR j := 1 TO Len( ::aPens )
            IF ::aPens[j]:width == width .AND. ::aPens[j]:style == style .AND. ::aPens[j]:color == color
               EXIT
            ENDIF
         NEXT
         IF j > Len( ::aPens )
            oPen := HPen():Add( style, width, color )
            Aadd( ::aPens, oPen )
         ELSE
            oPen := ::aPens[j]
         ENDIF
         hwg_Selectobject( hDC, oPen:handle )

      ENDIF
   NEXT

   RETURN Nil

Static Function MessProc( oPrinter, oPanel, lParam )
   LOCAL xPos, yPos, nPage := oPrinter:nCurrPage, arr, i, j, nPos, x1, y1, x2, y2, cTemp
   LOCAL nHRes, nVRes

   xPos := hwg_Loword( lParam )
   yPos := hwg_Hiword( lParam )

   nHRes := (oPrinter:x2-oPrinter:x1)/oPrinter:nWidth
   nVRes := (oPrinter:y2-oPrinter:y1)/oPrinter:nHeight
   
   arr := hb_aTokens( oPrinter:aPages[nPage], crlf )
   FOR i := 1 TO Len( arr )
      nPos := 0
      IF hb_TokenPtr( arr[i], @nPos, "," ) == "txt"
         x1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHRes / oPrinter:nHres, 0 ) + oPrinter:x1
         y1 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / oPrinter:nVres, 0 ) + oPrinter:y1
         x2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nHRes / oPrinter:nHres, 0 ) + oPrinter:x1
         y2 := Round( Val( hb_TokenPtr( arr[i], @nPos, "," ) ) * nVRes / oPrinter:nVres, 0 ) + oPrinter:y1
         IF xPos >= x1 .AND. xPos <= x2 .AND. yPos >= y1 .AND. yPos <= y2
            EXIT
         ENDIF
      ENDIF
   NEXT
   IF i <= Len( arr )
      hb_TokenPtr( arr[i], @nPos, "," )
      IF !Empty( cTemp := hwg_MsgGet( "",,ES_AUTOHSCROLL,,,DS_CENTER,SubStr( arr[i], nPos+1 ) ) ) .AND. !( cTemp == SubStr(arr[i],nPos+1) )
         oPrinter:aPages[nPage] := ""
         FOR j := 1 TO Len( arr )
            IF j != i
               oPrinter:aPages[nPage] += arr[j] + crlf
            ELSE
               oPrinter:aPages[nPage] += Left( arr[j], nPos ) + cTemp + crlf
            ENDIF
         NEXT
         oPrinter:NeedsRedraw := .T.
         hwg_Redrawwindow( oPanel:handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE )
      ENDIF
   ENDIF

Return 1
