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
#include "hwgui.ch"

   //- HFont

CLASS HFont INHERIT HObject

   CLASS VAR aFonts   INIT {}
   DATA handle
   DATA name, width, height , weight
   DATA charset, italic, Underline, StrikeOut
   DATA nCounter   INIT 1

   METHOD Add( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle, lLinux )
   METHOD SELECT( oFont , cTitle )
   METHOD Props2Arr()
   METHOD PrintFont()
   METHOD SetFontStyle( lBold, nCharSet, lItalic, lUnder, lStrike, nHeight )
   METHOD RELEASE()

ENDCLASS

METHOD Add( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, ;
      fdwUnderline, fdwStrikeOut, nHandle, lLinux ) CLASS HFont

   LOCAL i, nlen := Len( ::aFonts )

   nHeight  := iif( nHeight == Nil, 13, Abs( nHeight ) )
   IF lLinux == Nil .OR. !lLinux
      nHeight -= 3
   ENDIF
   nWidth := iif( nWidth == Nil, 0, nWidth )
   fnWeight := iif( fnWeight == Nil, 0, fnWeight )
   fdwCharSet := iif( fdwCharSet == Nil, 0, fdwCharSet )
   fdwItalic := iif( fdwItalic == Nil, 0, fdwItalic )
   fdwUnderline := iif( fdwUnderline == Nil, 0, fdwUnderline )
   fdwStrikeOut := iif( fdwStrikeOut == Nil, 0, fdwStrikeOut )

   FOR i := 1 TO nlen
      IF ::aFonts[i]:name == fontName .AND.             ;
            ( ( Empty(::aFonts[i]:width ) .AND. Empty(nWidth ) ) ;
            .OR. ::aFonts[i]:width == nWidth ) .AND.    ;
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
         RETURN ::aFonts[i]
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

   /* Added: cTitle */

METHOD SELECT( oFont, cTitle ) CLASS HFont
   LOCAL af := hwg_Selectfont( oFont, cTitle )

   IF ValType( af ) != "A"
      RETURN Nil
   ENDIF

   Return ::Add( af[2], af[3], af[4], af[5], af[6], af[7], af[8], af[9], af[1], .T. )

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
      nCharSet, Italic, Underline, StrikeOut, , ( nHeight == ::height ) )

METHOD RELEASE() CLASS HFont

   LOCAL i, nlen := Len( ::aFonts )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aFonts[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aFonts, i )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

   /* DF7BE: FOR debugging purposes */

METHOD PrintFont()  CLASS HFont

   //        fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut
   // Type:  C         N       N         N         N           N          N             N
   // - 9999 means NIL

   LOCAL fontName , nWidth , nHeight , fnWeight , fdwCharSet , fdwItalic , fdwUnderline , fdwStrikeOut

   fontName     := iif( ::name == NIL , "<Empty>", ::name )
   nWidth       := iif( ::width == Nil, - 9999 , ::width )
   nHeight      := iif( ::height == NIL , - 9999 , ::height )
   fnWeight     := iif( ::weight == Nil, - 9999 , ::weight )
   fdwCharSet   := iif( ::CharSet == Nil, - 9999 , ::CharSet )
   fdwItalic    := iif( ::Italic == Nil, - 9999 , ::Italic )
   fdwUnderline := iif( ::Underline == Nil, - 9999 , ::Underline )
   fdwStrikeOut := iif( ::StrikeOut == Nil, - 9999 , ::StrikeOut )

   RETURN "Font Name=" + fontName + " Width=" + AllTrim( Str( nWidth ) ) + " Height=" + AllTrim( Str( nHeight ) ) + ;
      " Weight=" + AllTrim( Str( fnWeight ) ) + " CharSet=" + AllTrim( Str( fdwCharSet ) ) + ;
      " Italic=" + AllTrim( Str( fdwItalic ) ) + " Underline=" + AllTrim( Str( fdwUnderline ) ) + ;
      " StrikeOut=" + AllTrim( Str( fdwStrikeOut ) )


/*
  Returns an array with font properties (for creating a copy of a font entry)
  Copy sample
   apffrarr := oFont1:Props2Arr()
   oFont2 := HFont():Add( apffrarr[1], apffrarr[2], apffrarr[3], apffrarr[4], apffrarr[5], ;
                apffrarr[6], apffrarr[7], apffrarr[8] )
 */

METHOD Props2Arr() CLASS HFont

   //        fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut
   //        1         2       3         4         5           6          7             8
   LOCAL fontName , nWidth , nHeight , fnWeight , fdwCharSet , fdwItalic , fdwUnderline , fdwStrikeOut
   LOCAL aFontprops := {}

   fontName     := iif( ::name == NIL , "<Empty>", ::name )
   nWidth       := iif( ::width == Nil, - 9999 , ::width )
   nHeight      := iif( ::height == NIL , - 9999 , ::height )
   fnWeight     := iif( ::weight == Nil, - 9999 , ::weight )
   fdwCharSet   := iif( ::CharSet == Nil, - 9999 , ::CharSet )
   fdwItalic    := iif( ::Italic == Nil, - 9999 , ::Italic )
   fdwUnderline := iif( ::Underline == Nil, - 9999 , ::Underline )
   fdwStrikeOut := iif( ::StrikeOut == Nil, - 9999 , ::StrikeOut )

   AAdd ( aFontprops, fontName )  // C
   AAdd ( aFontprops, nWidth )    // all other of type N
   AAdd ( aFontprops, nHeight )
   AAdd ( aFontprops, fnWeight )
   AAdd ( aFontprops, fdwCharSet )
   AAdd ( aFontprops, fdwItalic )
   AAdd ( aFontprops, fdwUnderline )
   AAdd ( aFontprops, fdwStrikeOut )

   RETURN aFontprops

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

   nStyle := iif( nStyle == Nil, PS_SOLID, nStyle )
   nWidth := iif( nWidth == Nil, 1, nWidth )
   IF nStyle != PS_SOLID
      nWidth := 1
   ENDIF
   nColor := iif( nColor == Nil, 0, nColor )

   FOR EACH i IN ::aPens
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
   IF nStyle != PS_SOLID
      nWidth := 1
   ENDIF
   nColor := iif( nColor == Nil, 0, nColor )

   FOR EACH i IN ::aPens
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
      FOR i := 1 TO nlen
         IF ::aPens[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aPens, i )
            ASize( ::aPens, nlen - 1 )
            EXIT
         ENDIF
      NEXT
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

   FOR EACH i IN ::aBrushes
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
      FOR i := 1 TO nlen
         IF ::aBrushes[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aBrushes, i )
            ASize( ::aBrushes, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

   //- HBitmap

CLASS HBitmap INHERIT HObject

   CLASS VAR cPath SHARED
   CLASS VAR aBitmaps   INIT {}
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nTransparent    INIT - 1
   DATA nCounter        INIT 1

   METHOD AddResource( name )
   METHOD AddFile( name, HDC , lTransparent, nWidth, nHeight )
   METHOD AddString( name, cVal )
   METHOD AddStandard( cId, nSize )
   METHOD AddWindow( oWnd, x1, y1, width, height )
   METHOD Draw( hDC, x1, y1, width, height )
   METHOD RELEASE()
   METHOD OBMP2FILE( cfilename , name )

ENDCLASS

/*
 Stores a bitmap in a file from object
*/

METHOD OBMP2FILE( cfilename , name ) CLASS HBitmap

   LOCAL i , hbmp

   hbmp := NIL
   // Search FOR bitmap in object
   FOR EACH i IN ::aBitmaps
      IF i:name == name
         hbmp := i:handle
      ELSE
         // not found
         RETURN NIL
      ENDIF
   NEXT

   hwg_SaveBitMap( cfilename, hbmp )

   RETURN NIL

METHOD AddResource( name ) CLASS HBitmap
/*
 *  name : resource name in container, not file name.
 *  returns an object to bitmap, if resource successfully added
 */
   LOCAL oBmp   // cVal
   LOCAL i , cTmp, oResCnt

   FOR EACH oBmp IN ::aBitmaps
      IF oBmp:name == name
         oBmp:nCounter ++
         RETURN oBmp  // go back, if already exists
      ENDIF
   NEXT

   /*
    * DF7BE: AddString method loads image from file or
    * binary container and added it to resource container.
   */

   // oResCnt (Static Memvar) is object of HBinC class
   IF !Empty( oResCnt := hwg_GetResContainer() )
      IF !Empty( i := oResCnt:Get( name ) )
         // DF7BE:
         // Store bmp in a temporary file
         // (otherwise the bmp is not loadable)
         // Load from temporary file
         //  ::handle := hwg_OpenImage( i, .T. )
         // Ready FOR multi platform use
         hb_memowrit( cTmp := hwg_CreateTempfileName() , i )
         ::handle := hwg_OpenImage( cTmp )
      ENDIF
   ENDIF

   /*
   IF !Empty( oResCnt ) .AND. !Empty( cVal := oResCnt:Get( name ) )
      IF !Empty( oBmp := ::AddString( name, cVal ) )
          RETURN oBmp
      ENDIF
   ENDIF
   */

   IF Empty( ::handle )
      hwg_MsgStop( "Can not add bitmap to resource container: >" + name + "<" )
      RETURN Nil
      // ELSE
      //     hwg_MsgInfo("Bitmap resource successfully loaded >" + name + "<" )
   ENDIF
   ::name   := name
   AAdd( ::aBitmaps, Self )

   RETURN Self

   // RETURN Nil

METHOD AddFile( name, HDC , lTransparent, nWidth, nHeight ) CLASS HBitmap

   LOCAL i, aBmpSize

   // Parameters not used
   HB_SYMBOL_UNUSED( HDC )
   HB_SYMBOL_UNUSED( lTransparent )
   HB_SYMBOL_UNUSED( nWidth )
   HB_SYMBOL_UNUSED( nHeight )

   FOR EACH i IN ::aBitmaps
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

METHOD AddString( name, cVal ) CLASS HBitmap

/*
  Add name to resource container (array ::aBitmaps)
  and add image to resource container.
  name : Name of resource in container
  cVal : Contents of image
*/

   LOCAL oBmp, aBmpSize, cTmp

   FOR EACH oBmp IN ::aBitmaps
      IF oBmp:name == name
         oBmp:nCounter ++
         // already existing, nothing to add
         RETURN oBmp
      ENDIF
   NEXT

   /* Try to load image from file */
   ::handle := hwg_Openimage( cVal  )  // 2nd parameter not .T. !
   IF Empty( ::handle )
      // Otherwise:
      // Write image from binary container into temporary file
      // (as a bitmap file)

      //      hb_memowrit( cTmp := "/tmp/e" + Ltrim(Str(Int(Seconds()*100))), cVal )
      //      DF7BE: Ready FOR multi platform use
      hb_memowrit( cTmp := hwg_CreateTempfileName() , cVal )
      ::handle := hwg_Openimage( cTmp )
      FErase( cTmp )
   ENDIF
   IF !Empty( ::handle )
      // hwg_Msginfo("Bitmap successfully loaded: >" + name + "<")
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aBitmaps, Self )
   ELSE
      hwg_MsgStop( "Bitmap not loaded >" + name + "<" )
      RETURN Nil
   ENDIF

   RETURN Self

METHOD AddStandard( cId, nSize ) CLASS HBitmap
   LOCAL i, aBmpSize, cName

   cName := cId + iif( nSize == Nil, "", Str( nSize,1 ) )
   FOR EACH i IN ::aBitmaps
      IF i:name == cName
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   ::handle := hwg_StockBitmap( cId, nSize )
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name    := cName
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddWindow( oWnd, x1, y1, width, height ) CLASS HBitmap

   LOCAL aBmpSize, handle := hwg_GetDrawing( oWnd:handle )

   // Variables not used
   // i

   IF x1 == Nil .OR. y1 == Nil
      x1 := 0; y1 := 0; width := oWnd:nWidth - 1; height := oWnd:nHeight - 1
   ENDIF
   ::handle := hwg_Window2Bitmap( iif( Empty(handle ),oWnd:handle,handle ), x1, y1, width, height )
   ::name := LTrim( hb_valToStr( oWnd:handle ) )
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[1]
   ::nHeight := aBmpSize[2]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD Draw( hDC, x1, y1, width, height ) CLASS HBitmap

   IF ::nTransparent < 0
      hwg_Drawbitmap( hDC, ::handle, , x1, y1, width, height )
   ELSE
      hwg_Drawtransparentbitmap( hDC, ::handle, x1, y1, ::nTransparent )
   ENDIF

   RETURN Nil

METHOD RELEASE() CLASS HBitmap

   LOCAL i, nlen := Len( ::aBitmaps )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aBitmaps[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aBitmaps, i )
            ASize( ::aBitmaps, nlen - 1 )
            EXIT
         ENDIF
      NEXT
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

   METHOD AddResource( name , nWidth, nHeight , nFlags, lOEM )
   METHOD AddFile( name, nWidth, nHeight )
   METHOD AddString( name, cVal , nWidth, nHeight )
   METHOD RELEASE()

ENDCLASS

METHOD AddResource( name , nWidth, nHeight , nFlags, lOEM ) CLASS HIcon

   // FOR compatibility to WinAPI the parameters nFlags and lOEM are dummys
   LOCAL i , cTmp, oResCnt

   // Variables not used
   // lPreDefined := .F.

   // Parameters not used
   HB_SYMBOL_UNUSED( nWidth )
   HB_SYMBOL_UNUSED( nHeight )
   HB_SYMBOL_UNUSED( nFlags )
   HB_SYMBOL_UNUSED( lOEM )

/*
   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF
*/
   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      // lPreDefined := .T.
   ENDIF

   FOR EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         // resource always existing, nothing to do
         RETURN i
      ENDIF
   NEXT
   // oResCnt (Static Memvar) is object of HBinC class
   IF !Empty( oResCnt := hwg_GetResContainer() )
      IF !Empty( i := oResCnt:Get( name ) )
         // DF7BE:
         // Store icon in a temporary file
         // (otherwise the icon is not loadable)
         // Load from temporary file
         //  ::handle := hwg_OpenImage( i, .T. )
         // Ready FOR multi platform use
         hb_memowrit( cTmp := hwg_CreateTempfileName() , i )
         ::handle := hwg_OpenImage( cTmp )
      ENDIF
   ENDIF
   IF Empty( ::handle )
      hwg_MsgStop( "Can not add icon to resource container: >" + name + "<" )
      RETURN Nil
   ENDIF
   ::name   := name
   AAdd( ::aIcons, Self )

   RETURN Self

METHOD AddFile( name , nWidth, nHeight ) CLASS HIcon

   LOCAL i, aBmpSize

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   FOR EACH i IN  ::aIcons
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   IF Empty( hb_fNameExt( name ) )
      name += ".png"
   ENDIF
   ::handle := hwg_Openimage( name )
   IF !Empty( ::handle )
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )

      //      ::nWidth  := aBmpSize[1]
      //      ::nHeight := aBmpSize[2]
      IF  nWidth > 0
         ::nWidth := nWidth
      ELSE
         ::nWidth  := aBmpSize[ 1 ]
      ENDIF
      IF nHeight > 0
         ::nHeight := nHeight
      ELSE
         ::nHeight := aBmpSize[ 2 ]
      ENDIF

      AAdd( ::aIcons, Self )
   ELSE
      hwg_MsgStop( "Can not load icon: >" + name + "<" )
      RETURN Nil
   ENDIF

   RETURN Self


 /* Added by DF7BE
 name : Name of resource
 cVal : Binary contents of *.ico file
 */

METHOD AddString( name, cVal , nWidth, nHeight ) CLASS HIcon

   LOCAL i , cTmp , aBmpSize

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   FOR EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         // resource always existing, nothing to do
         RETURN i
      ENDIF
   NEXT
   // DF7BE:
   // Write contents into temporary file
   hb_memowrit( cTmp := hwg_CreateTempfileName() , cVal )
   ::handle := hwg_OpenImage( cTmp )
   FErase( cTmp )
   IF !Empty( ::handle )
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aIcons, Self )
   ELSE
      hwg_MsgStop( "Can not load icon: >" + name + "<" )
      RETURN Nil
   ENDIF

   RETURN Self

METHOD RELEASE() CLASS HIcon
   LOCAL i, nlen := Len( ::aIcons )

   ::nCounter --
   IF ::nCounter == 0
      FOR i := 1 TO nlen
         IF ::aIcons[i]:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aIcons, i )
            ASize( ::aIcons, nlen - 1 )
            EXIT
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

CLASS HStyle INHERIT HObject

   CLASS VAR aStyles   INIT {}

   DATA id
   DATA nOrient
   DATA aColors
   DATA oBitmap
   DATA nBmpStyle
   DATA nBorder
   DATA tColor
   DATA oPen
   DATA aCorners

   METHOD New( aColors, nOrient, aCorners, nBorder, tColor, oBitmap, nBmpStyle )
   METHOD Draw( hDC, nLeft, nTop, nRight, nBottom )

ENDCLASS

METHOD New( aColors, nOrient, aCorners, nBorder, tColor, oBitmap, nBmpStyle ) CLASS HStyle

   LOCAL i, nlen := Len( ::aStyles )

   nBorder := iif( nBorder == Nil, 0, nBorder )
   tColor := iif( tColor == Nil, - 1, tColor )
   nOrient := iif( nOrient == Nil .OR. nOrient > 9, 1, nOrient )

   FOR i := 1 TO nlen
      IF hwg_aCompare( ::aStyles[i]:aColors, aColors ) .AND. ;
            hwg_aCompare( ::aStyles[i]:aCorners, aCorners ) .AND. ;
            ValType( ::aStyles[i]:tColor ) == ValType( tColor ) .AND. ;
            ::aStyles[i]:nBorder == nBorder .AND. ;
            ::aStyles[i]:tColor == tColor .AND. ;
            ::aStyles[i]:nOrient == nOrient .AND. ;
            ( ( ::aStyles[i]:oBitmap == Nil .AND. oBitmap == Nil ) .OR. ;
            ( ::aStyles[i]:oBitmap != Nil .AND. oBitmap != Nil .AND. ::aStyles[i]:oBitmap:name == oBitmap:name ) )

         RETURN ::aStyles[i]
      ENDIF
   NEXT

   ::aColors  := aColors
   ::nOrient  := nOrient
   ::nBorder  := nBorder
   ::tColor   := tColor
   ::aCorners := aCorners
   ::oBitmap := oBitmap
   ::nBmpStyle := iif( nBmpStyle == Nil, BMP_DRAW_SPREAD, nBmpStyle )
   IF nBorder > 0
      ::oPen := HPen():Add( BS_SOLID, nBorder, tColor )
   ENDIF

   AAdd( ::aStyles, Self )
   ::id := Len( ::aStyles )

   RETURN Self

METHOD Draw( hDC, nLeft, nTop, nRight, nBottom ) CLASS HStyle

   LOCAL n1, n2

   IF ::oBitmap == Nil
      hwg_drawGradient( hDC, nLeft, nTop, nRight, nBottom, ::nOrient, ::aColors, , ::aCorners )
   ELSEIF ::nBmpStyle == BMP_DRAW_CENTER
      n1 := Round( ( nRight - nLeft - ::oBitmap:nWidth ) / 2, 0 )
      n2 := Round( ( nBottom - nTop - ::oBitmap:nHeight ) / 2, 0 )
      hwg_Drawbitmap( hDC, ::oBitmap:handle, , n1, n2, ::oBitmap:nWidth, ::oBitmap:nHeight )
   ELSEIF ::nBmpStyle == BMP_DRAW_FULL
      hwg_Drawbitmap( hDC, ::oBitmap:handle, , nLeft, nTop, nRight - nLeft + 1, nBottom - nTop + 1 )
   ELSE
      hwg_SpreadBitmap( hDC, ::oBitmap:handle, nLeft, nTop, nRight, nBottom )
   ENDIF

   IF !Empty( ::oPen )
      hwg_Selectobject( hDC, ::oPen:handle )
      hwg_Rectangle( hDC, nLeft, nTop, nRight - 1, nBottom - 1 )
   ENDIF

   RETURN Nil

FUNCTION hwg_aCompare( arr1, arr2 )

   LOCAL i, nLen

   IF arr1 == Nil .AND. arr2 == Nil
      RETURN .T.
   ELSEIF ValType( arr1 ) == ValType( arr2 ) .AND. ValType( arr1 ) == "A" ;
         .AND. ( nLen := Len( arr1 ) ) == Len( arr2 )
      FOR i := 1 TO nLen
         IF !( ValType( arr1[i] ) == ValType( arr2[i] ) ) .OR. !( arr1[i] == arr2[i] )
            RETURN .F.
         ENDIF
      NEXT
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_BmpFromRes( cBmp )

   LOCAL handle, cBuff, cTmp, oResCnt

   IF !Empty( oResCnt := hwg_GetResContainer() )
      IF !Empty( cBuff := oResCnt:Get( cBmp ) )
         handle := hwg_OpenImage( cBuff, .T. )
         IF Empty( handle )
            // hb_memowrit( cTmp := "/tmp/e"+Ltrim(Str(Int(Seconds()*100))), cBuff )
            // DF7BE: Ready FOR multi platform use (also Windows cross development environment)
            hb_memowrit( cTmp := hwg_CreateTempfileName() , cBuff )
            // Load from temporary image file
            handle := hwg_Openimage( cTmp )
            FErase( cTmp )
         ENDIF
      ENDIF
   ENDIF

   RETURN handle

   EXIT PROCEDURE CleanDrawWidg

   LOCAL i, oResCnt

   FOR i := 1 TO Len( HPen():aPens )
      hwg_Deleteobject( HPen():aPens[i]:handle )
   NEXT
   FOR i := 1 TO Len( HBrush():aBrushes )
      hwg_Deleteobject( HBrush():aBrushes[i]:handle )
   NEXT
   FOR i := 1 TO Len( HFont():aFonts )
      hwg_Deleteobject( HFont():aFonts[i]:handle )
   NEXT
   FOR i := 1 TO Len( HBitmap():aBitmaps )
      hwg_Deleteobject( HBitmap():aBitmaps[i]:handle )
   NEXT
   FOR i := 1 TO Len( HIcon():aIcons )
      // hwg_Deleteobject( HIcon():aIcons[i]:handle )
   NEXT
   IF !Empty( oResCnt := hwg_GetResContainer() )
      oResCnt:Close()
   ENDIF

   RETURN

/*
   DF7BE: only needed FOR WinAPI, on GTK/LINUX charset is UTF-8 forever.
   All other attributes are not modified.
 */

FUNCTION hwg_FontSetCharset ( oFont, nCharSet  )

   LOCAL i, nlen := Len( oFont:aFonts )

   IF nCharSet == NIL .OR. nCharSet == - 1
      RETURN oFont
   ENDIF

   oFont:charset := nCharSet

   FOR i := 1 TO nlen
      oFont:aFonts[ i ]:CharSet := nCharSet
   NEXT

   RETURN oFont

FUNCTION hwg_LoadCursorFromString( cVal, nx , ny )

   LOCAL cTmp , hCursor

   // Parameter x and y not used on WinApi

   // Write contents into temporary file
   hb_memowrit( cTmp := hwg_CreateTempfileName( , ".cur" ) , cVal )
   // Load cursor from temporary file
   hCursor := hwg_LoadCursorFromFile( cTmp , nx, ny )
   FErase( cTmp )

   RETURN hCursor

