/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Pens, brushes, fonts, bitmaps, icons handling
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

#ifndef HS_HORIZONTAL
#define HS_HORIZONTAL       0       /* ----- */
#define HS_VERTICAL         1       /* ||||| */
#define HS_FDIAGONAL        2       /* \\\\\ */
#define HS_BDIAGONAL        3       /* ///// */
#define HS_CROSS            4       /* +++++ */
#define HS_DIAGCROSS        5       /* xxxxx */
#endif

   //- HFont

CLASS HFont INHERIT HObject

   CLASS VAR aFonts   INIT {}
   DATA handle
   DATA name, width, height , weight
   DATA charset, italic, Underline, StrikeOut
   DATA nCounter   INIT 1

   METHOD Add( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle, lLinux )
   METHOD SELECT( oFont )
   METHOD RELEASE()
   METHOD SetFontStyle( lBold, nCharSet, lItalic, lUnder, lStrike, nHeight )

ENDCLASS

METHOD Add( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, ;
      fdwUnderline, fdwStrikeOut, nHandle, lLinux ) CLASS HFont

   LOCAL i, nlen := Len( ::aFonts )

   nHeight  := iif( nHeight == Nil, 13, Abs( nHeight ) )
   //IF lLinux == Nil .OR. !lLinux
   //   nHeight -= 3
   //ENDIF
   fnWeight := iif( fnWeight == Nil, 0, fnWeight )
   fdwCharSet := iif( fdwCharSet == Nil, 0, fdwCharSet )
   fdwItalic := iif( fdwItalic == Nil, 0, fdwItalic )
   fdwUnderline := iif( fdwUnderline == Nil, 0, fdwUnderline )
   fdwStrikeOut := iif( fdwStrikeOut == Nil, 0, fdwStrikeOut )

   FOR i := 1 TO nlen
      IF ::aFonts[i]:name == fontName .AND.          ;
            ::aFonts[i]:width == nWidth .AND.           ;
            ::aFonts[i]:height == nHeight .AND.         ;
            ::aFonts[i]:weight == fnWeight .AND.        ;
            ::aFonts[i]:CharSet == fdwCharSet .AND.     ;
            ::aFonts[i]:Italic == fdwItalic .AND.       ;
            ::aFonts[i]:Underline == fdwUnderline .AND. ;
            ::aFonts[i]:StrikeOut == fdwStrikeOut

         ::aFonts[i]:nCounter ++
         IF nHandle != Nil
            hwg_Deleteobject( nHandle )
         ENDIF
         Return ::aFonts[i]
      ENDIF
   NEXT

   IF nHandle == Nil
      ::handle := hwg_Createfont( fontName, nWidth, nHeight * 1024 , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut )
   ELSE
      ::handle := nHandle
      nHeight := nHeight / 1024
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

METHOD SELECT( oFont ) CLASS HFont
   LOCAL af := hwg_Selectfont( oFont )

   IF af == Nil
      RETURN Nil
   ENDIF

   Return ::Add( af[2], af[3], af[4], af[5], af[6], af[7], af[8], af[9], af[1], .T. )

METHOD RELEASE() CLASS HFont
   LOCAL i, nlen := Len( ::aFonts )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      For EACH i in ::aFonts
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aFonts, hb_enumindex() )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      For i := 1 TO nlen
         IF ::aFonts[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aFonts, i )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#endif
   ENDIF

   RETURN Nil

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

   RETURN HFont():Add( ::name, ::width, nheight, weight, ;
      nCharSet, Italic, Underline, StrikeOut )

   //- HPen

CLASS HPen INHERIT HObject

   CLASS VAR aPens   INIT {}
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
   nColor := iif( nColor == Nil, hwg_VColor( "000000" ), nColor )

   For EACH i in ::aPens
      IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   ::handle := hwg_Createpen( nStyle, nWidth, nColor )
   ::style  := nStyle
   ::width  := nWidth
   ::color  := nColor
   AAdd( ::aPens, Self )

   RETURN Self

METHOD Get( nStyle, nWidth, nColor ) CLASS HPen
   LOCAL i

   nStyle := iif( nStyle == Nil, PS_SOLID, nStyle )
   nWidth := iif( nWidth == Nil, 1, nWidth )
   nColor := iif( nColor == Nil, hwg_VColor( "000000" ), nColor )

   For EACH i in ::aPens
      IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

         RETURN i
      ENDIF
   NEXT

   RETURN Nil

METHOD RELEASE() CLASS HPen
   LOCAL i, nlen := Len( ::aPens )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      For EACH i  in ::aPens
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aPens, hb_EnumIndex() )
            ASize( ::aPens, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      For i := 1 TO nlen
         IF ::aPens[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
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

   CLASS VAR aBrushes   INIT {}
   DATA handle
   DATA COLOR
   DATA nHatch   INIT 99
   DATA nCounter INIT 1

   METHOD Add( nColor )
   METHOD RELEASE()

ENDCLASS

METHOD Add( nColor ) CLASS HBrush
   LOCAL i

   For EACH i IN ::aBrushes
      IF i:color == nColor
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   ::handle := hwg_Createsolidbrush( nColor )
   ::color  := nColor
   AAdd( ::aBrushes, Self )

   RETURN Self

METHOD RELEASE() CLASS HBrush
   LOCAL i, nlen := Len( ::aBrushes )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      For EACH i IN ::aBrushes
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aBrushes, hb_EnumIndex() )
            ASize( ::aBrushes, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      For i := 1 TO nlen
         IF ::aBrushes[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
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

   CLASS VAR cPath SHARED
   CLASS VAR aBitmaps   INIT {}
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name )
   METHOD AddFile( name, HDC )
   METHOD Transparent( trColor )
   METHOD AddWindow( oWnd, lFull )
   METHOD RELEASE()

ENDCLASS

METHOD AddResource( name ) CLASS HBitmap
   LOCAL lPreDefined := .F. , i, aBmpSize

   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF

   For EACH i  IN  ::aBitmaps
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   ::handle :=  hwg_Loadbitmap( iif( lPreDefined, Val(name ),name ) )
   IF !Empty( ::handle )
      ::name    := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aBitmaps, Self )
   ELSE
      RETURN Nil
   ENDIF

   RETURN Self

METHOD AddFile( name, HDC ) CLASS HBitmap
   LOCAL i, aBmpSize

   For EACH i IN ::aBitmaps
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   ::handle := hwg_Openimage( name )
   IF !Empty( ::handle )
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aBitmaps, Self )
   ELSE
      RETURN Nil
   ENDIF

   RETURN Self

METHOD Transparent( trColor )

   hwg_alpha2pixbuf( ::handle, trColor )

   RETURN Nil

METHOD AddWindow( oWnd, lFull ) CLASS HBitmap
   LOCAL i, aBmpSize

   // ::handle := hwg_Window2bitmap( oWnd:handle,lFull )
   ::name := LTrim( Str( oWnd:handle ) )
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[1]
   ::nHeight := aBmpSize[2]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD RELEASE() CLASS HBitmap
   LOCAL i, nlen := Len( ::aBitmaps )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      For EACH i IN ::aBitmaps
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aBitmaps, hb_EnumIndex() )
            ASize( ::aBitmaps, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      For i := 1 TO nlen
         IF ::aBitmaps[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
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

   CLASS VAR cPath SHARED
   CLASS VAR aIcons   INIT {}
   DATA handle
   DATA name
   DATA nCounter   INIT 1
   DATA nWidth, nHeight

   METHOD AddResource( name )
   METHOD AddFile( name, HDC )
   METHOD RELEASE()

ENDCLASS

METHOD AddResource( name ) CLASS HIcon
   LOCAL lPreDefined := .F. , i

   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF

   For EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
   // ::handle :=   hwg_Loadicon( Iif( lPreDefined, Val(name),name ) )
   ::name   := name
   AAdd( ::aIcons, Self )

   RETURN Self

METHOD AddFile( name ) CLASS HIcon
   LOCAL i, aBmpSize

   For EACH i IN  ::aIcons
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   ::handle := hwg_Openimage( name )
   IF !Empty( ::handle )
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aIcons, Self )
   ELSE
      RETURN Nil
   ENDIF

   RETURN Self

METHOD RELEASE() CLASS HIcon
   LOCAL i, nlen := Len( ::aIcons )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      For EACH i IN ::aIcons
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aIcons, hb_EnumIndex() )
            ASize( ::aIcons, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      For i := 1 TO nlen
         IF ::aIcons[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
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

   For i := 1 TO Len( HPen():aPens )
      hwg_Deleteobject( HPen():aPens[i]:handle )
   NEXT
   For i := 1 TO Len( HBrush():aBrushes )
      hwg_Deleteobject( HBrush():aBrushes[i]:handle )
   NEXT
   For i := 1 TO Len( HFont():aFonts )
      hwg_Deleteobject( HFont():aFonts[i]:handle )
   NEXT
   For i := 1 TO Len( HBitmap():aBitmaps )
      hwg_Deleteobject( HBitmap():aBitmaps[i]:handle )
   NEXT
   For i := 1 TO Len( HIcon():aIcons )
      // hwg_Deleteobject( HIcon():aIcons[i]:handle )
   NEXT

   RETURN

