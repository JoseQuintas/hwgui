/*
 * $Id: drawwidg.prg,v 1.20 2008-11-24 10:02:12 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Pens, brushes, fonts, bitmaps, icons handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
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
   METHOD Select( oFont )
   METHOD Release()

ENDCLASS

METHOD Add( fontName, nWidth, nHeight , fnWeight, ;
            fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle ) CLASS HFont

   LOCAL i, nlen := Len( ::aFonts )

   nHeight  := IIf( nHeight == Nil, - 13, nHeight )
   fnWeight := IIf( fnWeight == Nil, 0, fnWeight )
   fdwCharSet := IIf( fdwCharSet == Nil, 0, fdwCharSet )
   fdwItalic := IIf( fdwItalic == Nil, 0, fdwItalic )
   fdwUnderline := IIf( fdwUnderline == Nil, 0, fdwUnderline )
   fdwStrikeOut := IIf( fdwStrikeOut == Nil, 0, fdwStrikeOut )

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

METHOD Select( oFont ) CLASS HFont
   LOCAL af := SelectFont( oFont )

   IF af == Nil
      RETURN Nil
   ENDIF

   RETURN ::Add( af[ 2 ], af[ 3 ], af[ 4 ], af[ 5 ], af[ 6 ], af[ 7 ], af[ 8 ], af[ 9 ], af[ 1 ] )

METHOD Release() CLASS HFont
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
   METHOD Release()

ENDCLASS

METHOD Add( nStyle, nWidth, nColor ) CLASS HPen
   LOCAL i

   nStyle := IIf( nStyle == Nil, BS_SOLID, nStyle )
   nWidth := IIf( nWidth == Nil, 1, nWidth )
   nColor := IIf( nColor == Nil, 0, nColor )

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

   nStyle := IIf( nStyle == Nil, PS_SOLID, nStyle )
   nWidth := IIf( nWidth == Nil, 1, nWidth )
   nColor := IIf( nColor == Nil, 0, nColor )

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

METHOD Release() CLASS HPen
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
   DATA color
   DATA nHatch   INIT 99
   DATA nCounter INIT 1

   METHOD Add( nColor )
   METHOD Release()

ENDCLASS

METHOD Add( nColor, nHatch ) CLASS HBrush
   LOCAL i

   IF nHatch == Nil
      nHatch := 99
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

METHOD Release() CLASS HBrush
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
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nFlags, lOEM )
   METHOD AddStandard( nId )
   METHOD AddFile( name, hDC )
   METHOD AddWindow( oWnd, lFull )
   METHOD Draw( hDC, x1, y1, width, height )  INLINE DrawBitmap( hDC, ::handle, SRCCOPY, x1, y1, width, height )
   METHOD Release()

ENDCLASS

METHOD AddResource( name, nFlags, lOEM ) CLASS HBitmap
   LOCAL lPreDefined := .F., i, aBmpSize

   IF nFlags == nil
      nFlags := LR_DEFAULTCOLOR
   ENDIF
   IF lOEM == nil
      lOEM := .f.
   ENDIF
   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF
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
   IF lOEM
      ::handle := LoadImage( 0, Val( name ), IMAGE_BITMAP, nil, nil, Hwg_bitor( nFlags, LR_SHARED ) )
   ELSE
      ::handle := LoadImage( nil, IIf( lPreDefined, Val( name ), name ), IMAGE_BITMAP, nil, nil, nFlags )
   ENDIF
   ::name   := name
   aBmpSize  := GetBitmapSize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
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

METHOD AddFile( name, hDC ) CLASS HBitmap
   LOCAL i, aBmpSize

   #ifdef __XHARBOUR__
      FOR EACH i IN ::aBitmaps
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
   name := IIf( ! File( name ) .AND.FILE( CutPath( name ) ), CutPath( name ), name )
   IF ! File( name )
      name := SelectFile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", "*.jpg;*.gif;*.bmp;*.ico",, "Locate " + name )
   ENDIF

   IF Lower( Right( name, 4 ) ) == ".bmp"
      ::handle := OpenBitmap( name, hDC )
   ELSE
      ::handle := OpenImage( name )
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name := name
   aBmpSize  := GetBitmapSize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddWindow( oWnd, lFull ) CLASS HBitmap
   LOCAL aBmpSize

   ::handle := Window2Bitmap( oWnd:handle, lFull )
   ::name := LTrim( Str( oWnd:handle ) )
   aBmpSize  := GetBitmapSize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD Release() CLASS HBitmap
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
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nWidth, nHeight, nFlags, lOEM )
   METHOD AddFile( name, hDC )
   METHOD Draw( hDC, x, y )   INLINE DrawIcon( hDC, ::handle, x, y )
   METHOD Release()

ENDCLASS

METHOD AddResource( name, nWidth, nHeight, nFlags, lOEM ) CLASS HIcon
   LOCAL lPreDefined := .F., i, aIconSize

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
      lOEM := .f.
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
      ::handle := LoadImage( nil, IIf( lPreDefined, Val( name ), name ), IMAGE_ICON, nWidth, nHeight, nFlags )
   ENDIF
   ::name   := name
   aIconSize := GetIconSize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   RETURN Self

METHOD AddFile( name ) CLASS HIcon
   LOCAL i, aIconSize

   #ifdef __XHARBOUR__
      FOR EACH i IN  ::aIcons
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
   name := IIf( ! File( name ) .AND.FILE( CutPath( name ) ), CutPath( name ), name )
   IF ! File( name )
      name := SelectFile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", "*.jpg;*.gif;*.bmp;*.ico",, "Locate " + name )
   ENDIF

   ::handle := LoadImage( 0, name, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE + LR_LOADFROMFILE )
   ::name := name
   aIconSize := GetIconSize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

   RETURN Self

METHOD Release() CLASS HIcon
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

