/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Pens, brushes, fonts, bitmaps, icons handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

   //- HFont

CLASS HFont INHERIT HObject

   CLASS VAR aFonts   INIT { }
   DATA handle
   DATA name, width, height , weight
   DATA charset, italic, Underline, StrikeOut
   DATA nCounter   INIT 1

   METHOD Add( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle )
   METHOD SELECT( oFont, nCharSet )
   METHOD RELEASE()
   METHOD SetFontStyle( lBold, nCharSet, lItalic, lUnder, lStrike, nHeight )

ENDCLASS

METHOD Add( fontName, nWidth, nHeight , fnWeight, ;
      fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle ) CLASS HFont

   LOCAL i, nlen := Len( ::aFonts )

   nHeight  := iif( nHeight == Nil, - 13, nHeight )
   fnWeight := iif( fnWeight == Nil, 0, fnWeight )
   fdwCharSet := iif( fdwCharSet == Nil, 0, fdwCharSet )
   fdwItalic := iif( fdwItalic == Nil, 0, fdwItalic )
   fdwUnderline := iif( fdwUnderline == Nil, 0, fdwUnderline )
   fdwStrikeOut := iif( fdwStrikeOut == Nil, 0, fdwStrikeOut )

   FOR i := 1 TO nlen
      IF ::aFonts[ i ]:name == fontName .AND.          ;
            ::aFonts[ i ]:width == nWidth .AND.           ;
            ::aFonts[ i ]:height == nHeight .AND.         ;
            ::aFonts[ i ]:weight == fnWeight .AND.        ;
            ::aFonts[ i ]:CharSet == fdwCharSet .AND.     ;
            ::aFonts[ i ]:Italic == fdwItalic .AND.       ;
            ::aFonts[ i ]:Underline == fdwUnderline .AND. ;
            ::aFonts[ i ]:StrikeOut == fdwStrikeOut

         ::aFonts[ i ]:nCounter ++
         IF nHandle != Nil
            DeleteObject( nHandle )
         ENDIF
         RETURN ::aFonts[ i ]
      ENDIF
   NEXT

   IF nHandle == Nil
      ::handle := CreateFont( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut )
   ELSE
      ::handle := nHandle
   ENDIF

   ::name      := fontName
   ::width     := nWidth
   ::height    := nHeight
   ::weight    := fnWeight
   ::CharSet   := fdwCharSet
   ::Italic    := fdwItalic
   ::Underline := fdwUnderline
   ::StrikeOut := fdwStrikeOut

   AAdd( ::aFonts, Self )

   RETURN Self

METHOD SELECT( oFont, nCharSet  ) CLASS HFont
   LOCAL af := hwg_SelectFont( oFont )

   IF af == Nil
      RETURN Nil
   ENDIF

   RETURN ::Add( af[ 2 ], af[ 3 ], af[ 4 ], af[ 5 ], iif( Empty( nCharSet ), af[ 6 ], nCharSet ), af[ 7 ], af[ 8 ], af[ 9 ], af[ 1 ] )

METHOD SetFontStyle( lBold, nCharSet, lItalic, lUnder, lStrike, nHeight ) CLASS HFont
   LOCAL  weight, Italic, Underline, StrikeOut

   IF lBold != Nil
      weight = iif( lBold, FW_BOLD, FW_REGULAR )
   ELSE
      weight := ::weight
   ENDIF
   Italic    := iif( lItalic = Nil, ::Italic, iif( lItalic, 1, 0 ) )
   Underline := iif( lUnder  = Nil, ::Underline, iif( lUnder , 1, 0 ) )
   StrikeOut := iif( lStrike = Nil, ::StrikeOut, iif( lStrike , 1, 0 ) )
   nheight   := iif( nheight = Nil, ::height, nheight )
   nCharSet  := iif( nCharSet = Nil, ::CharSet, nCharSet )

   RETURN ::Add( ::name, ::width, nheight, weight, ;
      nCharSet, Italic, Underline, StrikeOut ) // ::handle )

METHOD RELEASE() CLASS HFont
   LOCAL i, nlen := Len( ::aFonts )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      FOR EACH i IN ::aFonts
         IF i:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aFonts, hb_enumindex() )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aFonts[ i ]:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aFonts, i )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#endif
   ENDIF

   RETURN Nil

   //- HPen

CLASS HPen INHERIT HObject

   CLASS VAR aPens   INIT { }
   DATA handle
   DATA style, width, color
   DATA nCounter   INIT 1

   METHOD Add( nStyle, nWidth, nColor )
   METHOD Get( nStyle, nWidth, nColor )
   METHOD RELEASE()

ENDCLASS

METHOD Add( nStyle, nWidth, nColor ) CLASS HPen
   LOCAL i

   nStyle := iif( nStyle == Nil, BS_SOLID, nStyle )
   nWidth := iif( nWidth == Nil, 1, nWidth )
   nColor := iif( nColor == Nil, 0, nColor )

#ifdef __XHARBOUR__
   FOR EACH i IN ::aPens
      IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aPens )
      IF ::aPens[ i ]:style == nStyle .AND. ;
            ::aPens[ i ]:width == nWidth .AND. ;
            ::aPens[ i ]:color == nColor

         ::aPens[ i ]:nCounter ++
         RETURN ::aPens[ i ]
      ENDIF
   NEXT
#endif

   ::handle := CreatePen( nStyle, nWidth, nColor )
   ::style  := nStyle
   ::width  := nWidth
   ::color  := nColor
   AAdd( ::aPens, Self )

   RETURN Self

METHOD Get( nStyle, nWidth, nColor ) CLASS HPen
   LOCAL i

   nStyle := iif( nStyle == Nil, PS_SOLID, nStyle )
   nWidth := iif( nWidth == Nil, 1, nWidth )
   nColor := iif( nColor == Nil, 0, nColor )

#ifdef __XHARBOUR__
   FOR EACH i IN ::aPens
      IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aPens )
      IF ::aPens[ i ]:style == nStyle .AND. ;
            ::aPens[ i ]:width == nWidth .AND. ;
            ::aPens[ i ]:color == nColor

         RETURN ::aPens[ i ]
      ENDIF
   NEXT
#endif

   RETURN Nil

METHOD RELEASE() CLASS HPen
   LOCAL i, nlen := Len( ::aPens )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      FOR EACH i  IN ::aPens
         IF i:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aPens, hb_EnumIndex() )
            ASize( ::aPens, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aPens[ i ]:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aPens, i )
            ASize( ::aPens, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#endif
   ENDIF

   RETURN Nil

   //- HBrush

CLASS HBrush INHERIT HObject

   CLASS VAR aBrushes   INIT { }
   DATA handle
   DATA COLOR
   DATA nHatch   INIT 99
   DATA nCounter INIT 1

   METHOD Add( nColor, nHatch )
   METHOD RELEASE()

ENDCLASS

METHOD Add( nColor, nHatch ) CLASS HBrush
   LOCAL i

   IF nHatch == Nil
      nHatch := 99
   ENDIF
   IF ValType( nColor ) == "P"
      nColor := PTRTOULONG( nColor )
   ENDIF
#ifdef __XHARBOUR__
   FOR EACH i IN ::aBrushes

      IF i:color == nColor .AND. i:nHatch == nHatch
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aBrushes )
      IF ::aBrushes[ i ]:color == nColor .AND. ::aBrushes[ i ]:nHatch == nHatch
         ::aBrushes[ i ]:nCounter ++
         RETURN ::aBrushes[ i ]
      ENDIF
   NEXT
#endif
   IF nHatch != 99
      ::handle := CreateHatchBrush( nHatch, nColor )
   ELSE
      ::handle := CreateSolidBrush( nColor )
   ENDIF
   ::color  := nColor
   AAdd( ::aBrushes, Self )

   RETURN Self

METHOD RELEASE() CLASS HBrush
   LOCAL i, nlen := Len( ::aBrushes )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      FOR EACH i IN ::aBrushes
         IF i:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aBrushes, hb_enumindex() )
            ASize( ::aBrushes, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aBrushes[ i ]:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aBrushes, i )
            ASize( ::aBrushes, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#endif
   ENDIF

   RETURN Nil

   //- HBitmap

CLASS HBitmap INHERIT HObject

   CLASS VAR aBitmaps   INIT { }
   CLASS VAR lSelFile   INIT .T.
   DATA handle
   DATA name
   DATA nFlags
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nFlags, lOEM, nWidth, nHeight )
   METHOD AddStandard( nId )
   METHOD AddFile( name, hDC, lTranparent, nWidth, nHeight )
   METHOD AddWindow( oWnd, lFull )
   METHOD Draw( hDC, x1, y1, width, height )  INLINE DrawBitmap( hDC, ::handle, SRCCOPY, x1, y1, width, height )
   METHOD RELEASE()

ENDCLASS

METHOD AddResource( name, nFlags, lOEM, nWidth, nHeight ) CLASS HBitmap
   LOCAL lPreDefined := .F. , i, aBmpSize

   IF nFlags == nil
      nFlags := LR_DEFAULTCOLOR
   ENDIF
   IF lOEM == nil
      lOEM := .F.
   ENDIF
   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF
#ifdef __XHARBOUR__
   FOR EACH i  IN  ::aBitmaps
      IF i:name == name .AND. i:nFlags == nFlags .AND. ;
            ( ( nWidth == nil .OR. nHeight == nil ) .OR. ;
            ( i:nWidth == nWidth .AND. i:nHeight == nHeight ) )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aBitmaps )
      IF ::aBitmaps[ i ]:name == name .AND. ::aBitmaps[ i ]:nFlags == nFlags .AND. ;
            ( ( nWidth == nil .OR. nHeight == nil ) .OR. ;
            ( ::aBitmaps[ i ]:nWidth == nWidth .AND. ::aBitmaps[ i ]:nHeight == nHeight ) )
         ::aBitmaps[ i ]:nCounter ++
         RETURN ::aBitmaps[ i ]
      ENDIF
   NEXT
#endif
   IF lOEM
      ::handle := LoadImage( 0, Val( name ), IMAGE_BITMAP, nil, nil, Hwg_bitor( nFlags, LR_SHARED ) )
   ELSE
      //::handle := LoadImage( nil, IIf( lPreDefined, Val( name ), name ), IMAGE_BITMAP, nil, nil, nFlags )
      ::handle := LoadImage( nil, iif( lPreDefined, Val( name ), name ), IMAGE_BITMAP, nWidth, nHeight, nFlags )
   ENDIF
   ::name    := name
   aBmpSize  := GetBitmapSize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   ::nFlags  :=  nFlags
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddStandard( nId ) CLASS HBitmap
   LOCAL i, aBmpSize, name := "s" + LTrim( Str( nId ) )

#ifdef __XHARBOUR__

   FOR EACH i  IN  ::aBitmaps
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aBitmaps )
      IF ::aBitmaps[ i ]:name == name
         ::aBitmaps[ i ]:nCounter ++
         RETURN ::aBitmaps[ i ]
      ENDIF
   NEXT
#endif
   ::handle :=   LoadBitmap( nId, .T. )
   ::name   := name
   aBmpSize  := GetBitmapSize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddFile( name, hDC, lTranparent, nWidth, nHeight ) CLASS HBitmap
   LOCAL i, aBmpSize, cname := CutPath( name ), cCurDir

#ifdef __XHARBOUR__
   FOR EACH i IN ::aBitmaps
      IF i:name == cname .AND. ( nWidth == nil .OR. nHeight == nil )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aBitmaps )
      IF ::aBitmaps[ i ]:name == cname .AND. ( nWidth == nil .OR. nHeight == nil )
         ::aBitmaps[ i ]:nCounter ++
         RETURN ::aBitmaps[ i ]
      ENDIF
   NEXT
#endif
   name := iif( ! File( name ) .AND. File( cname ), cname, name )
   IF ::lSelFile .AND. !File( name )
      cCurDir  := DiskName() + ':\' + CurDir()
      name := hwg_SelectFile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath( name ), FilePath( name ), "Locate " + name ) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange( cCurDir )
   ENDIF

   IF Lower( Right( name, 4 ) ) != ".bmp" .OR. ( nWidth == nil .AND. nHeight == nil .AND. lTranparent == Nil )
      IF Lower( Right( name, 4 ) ) == ".bmp"
         ::handle := OpenBitmap( name, hDC )
      ELSE
         ::handle := OpenImage( name )
      ENDIF
   ELSE
      IF lTranparent != Nil .AND. lTranparent
         ::handle := LoadImage( nil, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE + LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS )
      ELSE
         ::handle := LoadImage( nil, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE )
      ENDIF
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name := cname
   aBmpSize  := GetBitmapSize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddWindow( oWnd, lFull ) CLASS HBitmap
   LOCAL aBmpSize

   ::handle := Window2Bitmap( oWnd:handle, lFull )
   ::name := LTrim( hb_valToStr( oWnd:handle ) )
   aBmpSize  := GetBitmapSize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD RELEASE() CLASS HBitmap
   LOCAL i, nlen := Len( ::aBitmaps )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      FOR EACH i IN ::aBitmaps
         IF i:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aBitmaps, hB_enumIndex() )
            ASize( ::aBitmaps, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aBitmaps[ i ]:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aBitmaps, i )
            ASize( ::aBitmaps, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#endif
   ENDIF

   RETURN Nil

   //- HIcon

CLASS HIcon INHERIT HObject

   CLASS VAR aIcons   INIT { }
   CLASS VAR lSelFile   INIT .T.
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nWidth, nHeight, nFlags, lOEM )
   METHOD AddFile( name, nWidth, nHeight )
   METHOD Draw( hDC, x, y )   INLINE DrawIcon( hDC, ::handle, x, y )
   METHOD RELEASE()

ENDCLASS

METHOD AddResource( name, nWidth, nHeight, nFlags, lOEM ) CLASS HIcon
   LOCAL lPreDefined := .F. , i, aIconSize

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF
   IF nFlags == nil
      nFlags := 0
   ENDIF
   IF lOEM == nil
      lOEM := .F.
   ENDIF
   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF
#ifdef __XHARBOUR__
   FOR EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aIcons )
      IF ::aIcons[ i ]:name == name
         ::aIcons[ i ]:nCounter ++
         RETURN ::aIcons[ i ]
      ENDIF
   NEXT
#endif
   // ::classname:= "HICON"
   IF lOEM // LR_SHARED is required for OEM images
      ::handle := LoadImage( 0, Val( name ), IMAGE_ICON, nWidth, nHeight, Hwg_bitor( nFlags, LR_SHARED ) )
   ELSE
      ::handle := LoadImage( nil, iif( lPreDefined, Val( name ), name ), IMAGE_ICON, nWidth, nHeight, nFlags )
   ENDIF
   ::name   := name
   aIconSize := GetIconSize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   RETURN Self

METHOD AddFile( name, nWidth, nHeight ) CLASS HIcon
   LOCAL i, aIconSize, cname := CutPath( name ), cCurDir

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF
#ifdef __XHARBOUR__
   FOR EACH i IN  ::aIcons
      IF i:name == cname
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
#else
   FOR i := 1 TO Len( ::aIcons )
      IF ::aIcons[ i ]:name == cname
         ::aIcons[ i ]:nCounter ++
         RETURN ::aIcons[ i ]
      ENDIF
   NEXT
#endif
   // ::classname:= "HICON"
   name := iif( ! File( name ) .AND. File( cname ), cname, name )
   IF ::lSelFile .AND. !File( name )
      cCurDir  := DiskName() + ':\' + CurDir()
      name := hwg_SelectFile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath( name ), FilePath( name ), "Locate " + name ) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange( cCurDir )
   ENDIF

   //::handle := LoadImage( 0, name, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE + LR_LOADFROMFILE )
   ::handle := LoadImage( 0, name, IMAGE_ICON, nWidth, nHeight, LR_DEFAULTSIZE + LR_LOADFROMFILE + LR_SHARED )
   ::name := cname
   aIconSize := GetIconSize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   RETURN Self

METHOD RELEASE() CLASS HIcon
   LOCAL i, nlen := Len( ::aIcons )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      FOR EACH i IN ::aIcons
         IF i:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aIcons, hb_enumindex() )
            ASize( ::aIcons, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aIcons[ i ]:handle == ::handle
            DeleteObject( ::handle )
            ADel( ::aIcons, i )
            ASize( ::aIcons, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#endif
   ENDIF

   RETURN Nil

EXIT PROCEDURE CleanDrawWidg
   LOCAL i

   FOR i := 1 TO Len( HPen():aPens )
      DeleteObject( HPen():aPens[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HBrush():aBrushes )
      DeleteObject( HBrush():aBrushes[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HFont():aFonts )
      DeleteObject( HFont():aFonts[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HBitmap():aBitmaps )
      DeleteObject( HBitmap():aBitmaps[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HIcon():aIcons )
      DeleteObject( HIcon():aIcons[ i ]:handle )
   NEXT

   RETURN

