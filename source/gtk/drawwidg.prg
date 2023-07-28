/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Pens, brushes, fonts, bitmaps, icons handling
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* List of classes in this file:
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* HFont
* HPen
* HBrush
* HBitmap
* HBitmap
* HStyle

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* List of functions:
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* hwg_BmpFromRes()
* hwg_SetResContainer()
* hwg_GetResContainer()
* hwg_ExtractResContItem2file()
* hwg_ExtractResContItemType()
* hwg_ResContItemPosition()
* hwg_Bitmap2tmpfile()
* EXIT PROCEDURE CleanDrawWidg()
* hwg_FontSetCharset()
* hwg_LoadCursorFromString()
* hwg_BPMinches_per_meter()
* hwg_BPMconv_inch(mtr)
* hwg_BMPWriteFile()



#include "hbclass.ch"
#include "hwgui.ch"

Static oResCnt

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
   METHOD Select( oFont , cTitle )
   METHOD Props2Arr()
   METHOD PrintFont()
   METHOD Release()
   METHOD SetFontStyle( lBold, nCharSet, lItalic, lUnder, lStrike, nHeight )
   // METHOD AddC( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle )

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
      IF ::aFonts[i]:name == fontName .AND.          ;
            ( ( Empty(::aFonts[i]:width) .AND. Empty(nWidth) ) ;
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

/* Added: cTitle */
METHOD Select( oFont, cTitle ) CLASS HFont
   LOCAL af := hwg_Selectfont( oFont, cTitle )

   IF Valtype( af ) != "A"
      RETURN Nil
   ENDIF

   Return ::Add( af[2], af[3], af[4], af[5], af[6], af[7], af[8], af[9], af[1], .T. )

METHOD Release() CLASS HFont

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


/* DF7BE: For debugging purposes */
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




RETURN "Font Name=" + fontName + " Width=" + ALLTRIM(STR(nWidth)) + " Height=" + ALLTRIM(STR(nHeight)) + ;
       " Weight=" + ALLTRIM(STR(fnWeight)) + " CharSet=" + ALLTRIM(STR(fdwCharSet)) + ;
       " Italic=" + ALLTRIM(STR(fdwItalic)) + " Underline=" + ALLTRIM(STR(fdwUnderline)) + ;
       " StrikeOut=" + ALLTRIM(STR(fdwStrikeOut))


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

   AADD (aFontprops, fontName)  && C
   AADD (aFontprops, nWidth)    && all other of type N
   AADD (aFontprops, nHeight)
   AADD (aFontprops, fnWeight)
   AADD (aFontprops, fdwCharSet)
   AADD (aFontprops, fdwItalic)
   AADD (aFontprops, fdwUnderline)
   AADD (aFontprops, fdwStrikeOut)

 RETURN aFontprops


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
      nCharSet, Italic, Underline, StrikeOut,,(nHeight==::height) )

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
   IF nStyle != PS_SOLID
      nWidth := 1
   ENDIF
   nColor := iif( nColor == Nil, 0, nColor )

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
   DATA nTransparent    INIT -1
   DATA nCounter        INIT 1

   METHOD AddResource( name )
   METHOD AddFile( name, HDC , lTransparent, nWidth, nHeight)
   METHOD AddString( name, cVal )
   METHOD AddStandard( cId, nSize )
   METHOD AddWindow( oWnd, x1, y1, width, height )
   METHOD Draw( hDC, x1, y1, width, height )
   METHOD Release()
   METHOD OBMP2FILE( cfilename , name )

ENDCLASS

/*
 Stores a bitmap in a file from object
*/
METHOD OBMP2FILE( cfilename , name ) CLASS HBitmap

   LOCAL i , hbmp

   hbmp := NIL
   * Search for bitmap in object
   FOR EACH i IN ::aBitmaps
      IF i:name == name
         hbmp := i:handle
      ELSE
        * not found
        RETURN NIL
      ENDIF
   NEXT

   hwg_SaveBitMap(cfilename, hbmp )

   RETURN NIL

METHOD AddResource( name ) CLASS HBitmap
/*
 *  name : resource name in container, not file name.
 *  returns an object to bitmap, if resource successfully added
 */
   LOCAL oBmp   && cVal
   LOCAL i , cTmp

   For EACH oBmp IN ::aBitmaps
      IF oBmp:name == name
         oBmp:nCounter ++
         RETURN oBmp  && go back, if already exists
      ENDIF
   NEXT

   /*
    * DF7BE: AddString method loads image from file or
    * binary container and added it to resource container.
   */

   * oResCnt (Static Memvar) is object of HBinC class
   IF !Empty( oResCnt )
      IF !Empty( i := oResCnt:Get( name ) )
       * DF7BE:
       * Store bmp in a temporary file
       * (otherwise the bmp is not loadable)
       * Load from temporary file
       *  ::handle := hwg_OpenImage( i, .T. )
       * Ready for multi platform use
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
      hwg_MsgStop("Can not add bitmap to resource container: >" + name + "<" )
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

    * Parameters not used
    HB_SYMBOL_UNUSED(HDC)
    HB_SYMBOL_UNUSED(lTransparent)
    HB_SYMBOL_UNUSED(nWidth)
    HB_SYMBOL_UNUSED(nHeight)

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

METHOD AddString( name, cVal ) CLASS HBitmap

/*
  Add name to resource container (array ::aBitmaps)
  and add image to resource container.
  name : Name of resource in container
  cVal : Contents of image
*/

   LOCAL oBmp, aBmpSize, cTmp

   For EACH oBmp IN ::aBitmaps
      IF oBmp:name == name
         oBmp:nCounter ++
         * already existing, nothing to add
         RETURN oBmp
      ENDIF
   NEXT

   /* Try to load image from file */
   ::handle := hwg_Openimage( cVal  )  && 2nd parameter not .T. !
   IF Empty( ::handle )
      * Otherwise:
      * Write image from binary container into temporary file
      * (as a bitmap file)

*      hb_memowrit( cTmp := "/tmp/e" + Ltrim(Str(Int(Seconds()*100))), cVal )
*      DF7BE: Ready for multi platform use
       hb_memowrit( cTmp := hwg_CreateTempfileName() , cVal )
      ::handle := hwg_Openimage( cTmp )
      FErase( cTmp )
   ENDIF
   IF !Empty( ::handle )
      * hwg_Msginfo("Bitmap successfully loaded: >" + name + "<")
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aBitmaps, Self )
   ELSE
      hwg_MsgStop("Bitmap not loaded >" + name + "<" )
      RETURN Nil
   ENDIF

   RETURN Self

METHOD AddStandard( cId, nSize ) CLASS HBitmap
   LOCAL i, aBmpSize, cName

   cName := cId + Iif( nSize==Nil, "", Str(nSize,1) )
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
   * Variables not used
   * i

   IF x1 == Nil .OR. y1 == Nil
      x1 := 0; y1 := 0; width := oWnd:nWidth - 1; height := oWnd:nHeight - 1
   ENDIF
   ::handle := hwg_Window2Bitmap( Iif( Empty(handle),oWnd:handle,handle ),x1,y1,width,height )
   ::name := LTrim( hb_valToStr( oWnd:handle ) )
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[1]
   ::nHeight := aBmpSize[2]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD Draw( hDC, x1, y1, width, height ) CLASS HBitmap

   IF ::nTransparent < 0
      hwg_Drawbitmap( hDC, ::handle,, x1, y1, width, height )
   ELSE
      hwg_Drawtransparentbitmap( hDC, ::handle, x1, y1, ::nTransparent )
   ENDIF

   RETURN Nil

METHOD Release() CLASS HBitmap

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

   METHOD AddResource( name , nWidth, nHeight , nFlags, lOEM )
   METHOD AddFile( name, nWidth, nHeight )
   METHOD AddString( name, cVal , nWidth, nHeight )
   METHOD RELEASE()

ENDCLASS

METHOD AddResource( name , nWidth, nHeight , nFlags, lOEM ) CLASS HIcon
* For compatibility to WinAPI the parameters nFlags and lOEM are dummys
   LOCAL i , cTmp

   * Variables not used
   * lPreDefined := .F.

     * Parameters not used
    HB_SYMBOL_UNUSED(nWidth)
    HB_SYMBOL_UNUSED(nHeight)
    HB_SYMBOL_UNUSED(nFlags)
    HB_SYMBOL_UNUSED(lOEM)

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
      * lPreDefined := .T.
   ENDIF

   For EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         * resource always existing, nothing to do
         RETURN i
      ENDIF
   NEXT
   * oResCnt (Static Memvar) is object of HBinC class
   IF !Empty( oResCnt )
      IF !Empty( i := oResCnt:Get( name ) )
       * DF7BE:
       * Store icon in a temporary file
       * (otherwise the icon is not loadable)
       * Load from temporary file
       *  ::handle := hwg_OpenImage( i, .T. )
       * Ready for multi platform use
       hb_memowrit( cTmp := hwg_CreateTempfileName() , i )
         ::handle := hwg_OpenImage( cTmp )
      ENDIF
   ENDIF
   IF Empty( ::handle )
      hwg_MsgStop("Can not add icon to resource container: >" + name + "<" )
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

   For EACH i IN  ::aIcons
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
      hwg_MsgStop("Can not load icon: >" + name + "<")
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

   For EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         * resource always existing, nothing to do
         RETURN i
      ENDIF
   NEXT
   * DF7BE:
   * Write contents into temporary file
       hb_memowrit( cTmp := hwg_CreateTempfileName() , cVal )
       ::handle := hwg_OpenImage( cTmp )
       FERASE(cTmp)
   IF !Empty( ::handle )
      ::name := name
      aBmpSize  := hwg_Getbitmapsize( ::handle )
      ::nWidth  := aBmpSize[1]
      ::nHeight := aBmpSize[2]
      AAdd( ::aIcons, Self )
   ELSE
      hwg_MsgStop("Can not load icon: >" + name + "<")
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

CLASS HStyle INHERIT HObject

   CLASS VAR aStyles   INIT { }

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

   nBorder := Iif( nBorder == Nil, 0, nBorder )
   tColor := Iif( tColor == Nil, -1, tColor )
   nOrient := Iif( nOrient == Nil .OR. nOrient > 9, 1, nOrient )

   FOR i := 1 TO nlen
      IF hwg_aCompare( ::aStyles[i]:aColors, aColors ) .AND. ;
         hwg_aCompare( ::aStyles[i]:aCorners, aCorners ) .AND. ;
         Valtype(::aStyles[i]:tColor) == Valtype(tColor) .AND. ;
         ::aStyles[i]:nBorder == nBorder .AND. ;
         ::aStyles[i]:tColor == tColor .AND. ;
         ::aStyles[i]:nOrient == nOrient .AND. ;
         ( ( ::aStyles[i]:oBitmap == Nil .AND. oBitmap == Nil ) .OR. ;
         ( ::aStyles[i]:oBitmap != Nil .AND. oBitmap != Nil .AND. ::aStyles[i]:oBitmap:name == oBitmap:name ) )

         RETURN ::aStyles[ i ]
      ENDIF
   NEXT

   ::aColors  := aColors
   ::nOrient  := nOrient
   ::nBorder  := nBorder
   ::tColor   := tColor
   ::aCorners := aCorners
   ::oBitmap := oBitmap
   ::nBmpStyle := Iif( nBmpStyle==Nil, BMP_DRAW_SPREAD, nBmpStyle )
   IF nBorder > 0
      ::oPen := HPen():Add( BS_SOLID, nBorder, tColor )
   ENDIF

   AAdd( ::aStyles, Self )
   ::id := Len( ::aStyles )

   RETURN Self

METHOD Draw( hDC, nLeft, nTop, nRight, nBottom ) CLASS HStyle

   IF ::oBitmap == Nil
      hwg_drawGradient( hDC, nLeft, nTop, nRight, nBottom, ::nOrient, ::aColors,, ::aCorners )
   ELSEIF ::nBmpStyle == BMP_DRAW_CENTER
      n1 := Round( ( nRight-nLeft - ::oBitmap:nWidth ) / 2, 0 )
      n2 := Round( ( nBottom-nTop - ::oBitmap:nHeight ) / 2, 0 )
      hwg_Drawbitmap( hDC, ::oBitmap:handle,, n1, n2, ::oBitmap:nWidth, ::oBitmap:nHeight )
   ELSEIF ::nBmpStyle == BMP_DRAW_FULL
      hwg_Drawbitmap( hDC, ::oBitmap:handle,, nLeft, nTop, nRight-nLeft+1, nBottom-nTop+1 )
   ELSE
      hwg_SpreadBitmap( hDC, ::oBitmap:handle, nLeft, nTop, nRight, nBottom )
   ENDIF

   IF !Empty( ::oPen )
      hwg_Selectobject( hDC, ::oPen:handle )
      hwg_Rectangle( hDC, nLeft, nTop, nRight-1, nBottom-1 )
   ENDIF

   RETURN Nil


FUNCTION hwg_aCompare( arr1, arr2 )

   LOCAL i, nLen

   IF arr1 == Nil .AND. arr2 == Nil
      RETURN .T.
   ELSEIF Valtype( arr1 ) == Valtype( arr2 ) .AND. Valtype( arr1 ) == "A" ;
         .AND. ( nLen := Len( arr1 ) ) == Len( arr2 )
      FOR i := 1 TO nLen
         IF !( Valtype(arr1[i]) == Valtype(arr2[i]) ) .OR. !( arr1[i] == arr2[i] )
            RETURN .F.
         ENDIF
      NEXT
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_BmpFromRes( cBmp )

   LOCAL handle, cBuff, cTmp

   IF !Empty( oResCnt )
      IF !Empty( cBuff := oResCnt:Get( cBmp ) )
         handle := hwg_OpenImage( cBuff, .T. )
         IF Empty( handle )
            * hb_memowrit( cTmp := "/tmp/e"+Ltrim(Str(Int(Seconds()*100))), cBuff )
            * DF7BE: Ready for multi platform use (also Windows cross development environment)
            hb_memowrit( cTmp := hwg_CreateTempfileName() , cBuff )
            * Load from temporary image file
            handle := hwg_Openimage( cTmp )
            FErase( cTmp )
         ENDIF
     ENDIF
   ENDIF

   RETURN handle

/*

 Functions for Binary Container handling
 List of array elements:
 OBJ_NAME      1
 OBJ_TYPE      2
 OBJ_VAL       3
 OBJ_SIZE      4
 OBJ_ADDR      5
*/

FUNCTION hwg_SetResContainer( cName )
* Returns .T., if container is opened successfully

   IF Empty( cName )
      IF !Empty( oResCnt )
         oResCnt:Close()
         oResCnt := Nil
      ENDIF
   ELSE
      IF Empty( oResCnt := HBinC():Open( cName ) )
         RETURN .F.
      ENDIF
   ENDIF
   RETURN .T.

FUNCTION hwg_GetResContainerOpen()

   * Returns .T., if a container is open
   IF !Empty( oResCnt )
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_GetResContainer()

   * Returns the object of opened container,
   * otherwise NIL
   * (because the object variable is static)

   IF !Empty( oResCnt )
      RETURN oResCnt
   ENDIF

   RETURN NIL

FUNCTION hwg_ExtractResContItem2file(cfilename,cname)

   * Extracts an item with name cname of an opened
   * container to file cfilename
   * (get file extension with function
   * hwg_ExtractResContItemType() before)
   * Returns .T., if success, otherwise .F.
   * for example if no match.

   LOCAL n

   n := hwg_ResContItemPosition(cname)
   IF n > 0
      hb_MemoWrit( cfilename, oResCnt:Get( oResCnt:aObjects[n,1] ) )
      RETURN .T.
   ENDIF

   RETURN .F.

FUNCTION hwg_ExtractResContItemType(cname)

   * Extracts the type of item with name cname of an opened
   * container
   * Returns the type (bmp,png,ico,jpg)
   * as a string.
   * Empty string "", of container not open or no match

   LOCAL  cItemType := ""

   IF hwg_GetResContainerOpen()
      cItemType := oResCnt:GetType(cname)
   ENDIF

   RETURN cItemType

FUNCTION hwg_ResContItemPosition(cname)

* Extracts the position number of item with name cname of an opened
* container
* Returns the position name of item in the container,
* 0 , if no match or container not open.

   LOCAL i := 0

   IF hwg_GetResContainerOpen()
      i := oResCnt:GetPos( cname )
   ENDIF

   RETURN i

FUNCTION hwg_Bitmap2tmpfile(objBitmap , cname , cfextn)

* Creates a temporary file from a bitmap object
* Avoids trouble with imcompatibility of image displays.
* Almost needed for binary container.
* objBitmap : object from resource container (from HBitmap class)
* cname     : resource name of object
* cfextn    : file extension, for example "bmp" (Default)
* Returns:
* The temporary file name,
* empty string, if error occured.
* Don't forget to delete the temporary file after usage.
* LOCAL ctmpbmpf
* ctmpbmpf := hwg_Bitmap2tmpfile(obitmap , "sample" , "bmp")
* hwg_MsgInfo(ctmpbmpf,"Temporary image file")
* IF .NOT. EMPTY(ctmpbmpf)
*  ...
* ENDIF
* ERASE &ctmpbmpf
*
* Read more about the usage of this function in the documentation
* of the Binary Container Manager in the utils/bincnt directory.

   LOCAL ctmpfilename

   IF cfextn == NIL
      cfextn := "bmp"
   ENDIF

   ctmpfilename := hwg_CreateTempfileName("img","." + cfextn )
   objBitmap:OBMP2FILE( ctmpfilename , cname )

   IF .NOT. FILE(ctmpfilename)
      RETURN ""
   ENDIF

   RETURN ctmpfilename

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* End of Binary Container functions
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

EXIT PROCEDURE CleanDrawWidg

   LOCAL i

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
   IF !Empty( oResCnt )
      oResCnt:Close()
   ENDIF

   RETURN

/*
   DF7BE: only needed for WinAPI, on GTK/LINUX charset is UTF-8 forever.
   All other attributes are not modified.
 */

FUNCTION hwg_FontSetCharset ( oFont, nCharSet  )

   LOCAL i, nlen := Len( oFont:aFonts )

   IF nCharSet == NIL .OR. nCharSet == -1
      RETURN oFont
   ENDIF

   oFont:charset := nCharSet

   FOR i := 1 TO nlen
      oFont:aFonts[ i ]:CharSet := nCharSet
   NEXT

   RETURN oFont

FUNCTION hwg_LoadCursorFromString(cVal, nx , ny)

   LOCAL cTmp , hCursor

   * Parameter x and y not used on WinApi

   * Write contents into temporary file
   hb_memowrit( cTmp := hwg_CreateTempfileName( , ".cur") , cVal )
   * Load cursor from temporary file
   hCursor := hwg_LoadCursorFromFile( cTmp , nx, ny )
   FERASE(cTmp)

   RETURN hCursor

*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   Functions for raw bitmap support
*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FUNCTION hwg_BPMinches_per_meter()

   RETURN 100.0 / 2.54

FUNCTION hwg_BPMconv_inch(mtr)

   RETURN mtr / (100.0 / 2.54)

FUNCTION hwg_ShowBitmap(cbmp,cbmpname,ncolbg,ncolfg)
* Shows a bitmap
* cbmp      : The bitmap file image string
* cbmpname  : A unique name of the bitmap
* ncolbg    : Background color (system, if NIL)
* ncolfg    : foreground colors (ignored, if no background color is set)
* You can use
* hwg_ColorC2N( cColor ):
*  Converts color representation from string to numeric format.
*  cColor - a string in #RRGGBB

   LOCAL frm_bitmap , oButton1 , nx , ny , oBitmap
   LOCAL oLabel1, oLabel2, oLabel3, oLabel4
   LOCAL obmp, ldefc

* Display the bitmap in an extra window
* Max size : 1277,640

   ldefc := .F.
   IF ncolbg != NIL
      ldefc := .T.
   ENDIF

   IF ncolfg != NIL
      ldefc := .T.
   ENDIF

   obmp := HBitmap():AddString( cbmpname , cbmp )


   * Get current size
   nx := hwg_GetBitmapWidth ( obmp:handle )
   ny := hwg_GetBitmapHeight( obmp:handle )

   IF nx > 1277
      nx := 1277
   ENDIF

   IF ny > 640
      ny := 640
   ENDIF

   IF ldefc

      INIT DIALOG frm_bitmap TITLE "Bitmap Image" ;
         AT 20,20 SIZE 1324,772 ;
         BACKCOLOR ncolbg;
         STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

      @ 747,667 SAY oLabel1 CAPTION "Size:  x:"  SIZE 87,22 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;
         STYLE SS_RIGHT

      @ 866,667 SAY oLabel2 CAPTION ALLTRIM(STR(nx))  SIZE 80,22  ;
         COLOR ncolfg  BACKCOLOR ncolbg
      @ 988,667 SAY oLabel3 CAPTION "y:"  SIZE 80,22 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;
         STYLE SS_RIGHT
      @ 1130,667 SAY oLabel4 CAPTION ALLTRIM(STR(ny))  SIZE 80,22 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;

#ifdef __GTK__
      @ 17,12 BITMAP oBitmap  ;
         SHOW obmp OF frm_bitmap  ;
         SIZE nx, ny
#else
      @ 17,12 BITMAP oBitmap  ;
         SHOW obmp OF frm_bitmap
#endif

      @ 590,663 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
         COLOR ncolfg  BACKCOLOR ncolbg ;
         STYLE WS_TABSTOP+BS_FLAT ;
         ON CLICK { || frm_bitmap:Close() }
   ELSE
      * System colors

  INIT DIALOG frm_bitmap TITLE "Bitmap Image" ;
    AT 20,20 SIZE 1324,772 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

   @ 747,667 SAY oLabel1 CAPTION "Size:  x:"  SIZE 87,22 ;
        STYLE SS_RIGHT
   @ 866,667 SAY oLabel2 CAPTION ALLTRIM(STR(nx))  SIZE 80,22
   @ 988,667 SAY oLabel3 CAPTION "y:"  SIZE 80,22 ;
        STYLE SS_RIGHT
   @ 1130,667 SAY oLabel4 CAPTION ALLTRIM(STR(ny))  SIZE 80,22

#ifdef __GTK__
   @ 17,12 BITMAP oBitmap  ;
        SHOW obmp OF frm_bitmap  ;
        SIZE nx, ny
#else
   @ 17,12 BITMAP oBitmap  ;
        SHOW obmp OF frm_bitmap
#endif

   @ 590,663 BUTTON oButton1 CAPTION "OK"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK { || frm_bitmap:Close() }

ENDIF

   ACTIVATE DIALOG frm_bitmap

   RETURN NIL

FUNCTION hwg_BMPDrawCircle(nradius,ndeg)

   LOCAL aret , nx, ny ,nrad

   aret := {}
   * Convert degrees to radiant
   nrad := ndeg/180.0 * hwg_PI()

   nx := ROUND( hwg_Cos(nrad) * nradius  , 0) + nradius + 1
   ny := ROUND( hwg_Sin(nrad) * nradius  , 0) + nradius + 1

   AADD(aret,nx)
   AADD(aret,ny)

   RETURN aret


FUNCTION hwg_BMPSetMonochromePalette(pcBMP)

* Set monochrome palette for QR encoding,
* The background is white.
* (2 colors, black and white)
* Set 55, 56, 57 to 0xFF
* This setting define color 0 as white (the color 1 now is black by default)
* Sample:
* CBMP := HWG_BMPNEWIMAGE(nx, ny, 1, 2, 2835, 2835 )
* HWG_BMPDESTROY()
* CBMP := hwg_BMPSetMonochromePalette(CBMP)

   LOCAL npoffset, CBMP
   CBMP := pcBMP

   * Get Offset to palette data, expected value by default is 54
   npoffset := HWG_BMPCALCOFFSPAL()
   CBMP := hwg_ChangeCharInString(CBMP,npoffset     , CHR(255) )
   CBMP := hwg_ChangeCharInString(CBMP,npoffset + 1 , CHR(255) )
   CBMP := hwg_ChangeCharInString(CBMP,npoffset + 2 , CHR(255) )
   CBMP := hwg_ChangeCharInString(CBMP,npoffset + 3 , CHR(255) )

   RETURN CBMP

* Converts the bitmap string after (opional)
* modifications into a bitmap object.
* cbmpname : String with an unique bitmap name

FUNCTION hwg_BMPStr2Obj(pcBMP,cbmpname)

   LOCAL oBmp

   oBmp := HBitmap():AddString( cbmpname , pcBMP )

   RETURN oBmp

*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   End of Functions for raw bitmap support
*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*   ~~~~~~~~~~~~~~~~~~~~~~~~~
*   Functions for QR encoding
*   ~~~~~~~~~~~~~~~~~~~~~~~~~

/* Convert QR code to bitmap */
FUNCTION hwg_QRCodetxt2BPM(cqrcode)

   LOCAL cBMP , nlines, ncol , x , i , n
   LOCAL leofq

   IF cqrcode == NIL
      RETURN ""
   ENDIF

   * Count the columns in QR code text string
   * ( Appearance of line end in first line )
   ncol   := AT(CHR(10),cqrcode ) - 1

   * Count the lines in QR code text string
   * Suppress empty lines

   leofq := .F.
   nlines := 0
   FOR i := 1 TO LEN(cqrcode)
      IF .NOT. leofq
         IF SUBSTR(cqrcode,i,1) == CHR(10)
            IF .NOT. ( SUBSTR(cqrcode, i + 1 , 1) == " ")
               * Empty line following, stop here
               leofq := .T.
            ELSE
               * Count line ending
               nlines := nlines + 1
            ENDIF
         ENDIF
      ENDIF

   NEXT

   * Based on this, calculate the bitmap size
   nlines := nlines + 1

   * Create the bitmap template and set monochrome palette
   cBMP := HWG_BMPNEWIMAGE(ncol, nlines, 1, 2, 2835, 2835 )
   HWG_BMPDESTROY()
   cBMP := hwg_BMPSetMonochromePalette(cBMP)

   * Convert to bitmap

   leofq := .F.
   * i:        Position in cqrcode
   n := 1   && Line
   x := 0   && Column
   FOR i := 1 TO LEN(cqrcode)
      x := x + 1
      IF .NOT. leofq
         IF SUBSTR(cqrcode,i,1) == CHR(10)
            IF .NOT. ( SUBSTR(cqrcode, i + 1 , 1) == " ")
               * Empty line following, stop here
               leofq := .T.
            ENDIF
            * Count line ending and start with new line
            n := n + 1
            x := 0
         ELSE  && SUBSTR " "
            IF SUBSTR(cqrcode,i,1) == "#"
               cBMP := hwg_QR_SetPixel(cBMP,x,n,ncol,nlines)
            ENDIF  && #
         ENDIF && is CHR(10)
      ENDIF && .NOT. leofq

   NEXT

   RETURN cBMP

* Set a single pixel into QR code bitmap string
* Background color is white, pixel color is black

FUNCTION hwg_QR_SetPixel(cmbp,x,y,xw,yh)

   LOCAL cbmret, noffset, nbit , y1
   LOCAL nolbyte
   LOCAL nbline, nbyt , nline , nbint

   cbmret := cmbp

* Range check
   IF ( x > xw ) .OR. ( y > yh ) .OR. ( x < 1 ) .OR. ( y < 1 )
      RETURN cbmret
   ENDIF

* Add 1 to pixel data offset, this is done with call of HWG_SETBITBYTE()
   noffset := hwg_BMPCalcOffsPixArr(2);  && For 2 colors

* y Position conversion
* (reversed position 1 = 48, 48 = 1)
   y1 := yh - y + 1
* Bytes per line
   nline := hwg_BMPLineSize(xw,1)
// hwg_MsgInfo("nline="+ STR(nline) )

* Calculate the recent y position
* (Start postion of a line)

   nbyt := ( y1 - 1 ) *  nline

* Split line into number of bytes and bit position
   nbline := INT( x / 8 )
   nbyt := nbyt + nbline + 1   && Added 1 padding byte at begin of a line

   nbint :=  INT( x % 8 ) // + 1

* Reverse x value in a byte
   nbint := 8 - nbint + 1 && 1 ... 8

   IF nbint == 9
      nbint := 1
      nbyt := nbyt - 1
   ENDIF

* Extract old byte value
   nolbyte := ASC(SUBSTR(cbmret,noffset + nbyt,1))

   nbit := CHR(HWG_SETBITBYTE(0,nbint,1))
   nbit := CHR(HWG_BITOR_INT(ASC(nbit), nolbyte) )

   cbmret := hwg_ChangeCharInString(cbmret,noffset + nbyt , nbit)

   RETURN cbmret

* Increases the size of a QR code image
* cqrcode : The QR code in text format
* nzoom   : The zoom factor 1 ... n
* Return the new QR code text string

FUNCTION hwg_QRCodeZoom(cqrcode,nzoom)

   LOCAL cBMP, cLine, i , j
   LOCAL leofq

   IF nzoom == NIL
      nzoom := 1
   ENDIF

   IF nzoom < 1
      RETURN cqrcode
   ENDIF

   cBMP  := ""
   cLine := ""

   leofq := .F.
   * i:        Position in cqrcode

   FOR i := 1 TO LEN(cqrcode)
      IF .NOT. leofq
         IF SUBSTR(cqrcode,i,1) == CHR(10)
            IF .NOT. ( SUBSTR(cqrcode, i + 1 , 1) == " ")
               * Empty line following, stop here
               leofq := .T.
            ENDIF
            * Count line ending and start with new line

            * Replicate line with zoom factor
            FOR j := 1 TO nzoom
               cBMP  := cBMP + cLine + CHR(10)
            NEXT
            *
            cLine := ""
         ELSE  && SUBSTR " "
            cLine := cLine + REPLICATE(SUBSTR(cqrcode,i,1),nzoom)
         ENDIF && is CHR(10)
      ENDIF && .NOT. leofq

   NEXT

   IF .NOT. EMPTY(cLine)
      cBMP  := cBMP + cLine + CHR(10)
   ENDIF

* Empty line as mark for EOF
   cBMP  := cBMP + CHR(10)

   RETURN cBMP

* ====
* Add border to QR code image
* cqrcode : The QR code in text format
* nborder : The number of border pixels to add 1 ... n
* Return the new QR code text string

FUNCTION hwg_QRCodeAddBorder(cqrcode,nborder)

   LOCAL cBMP,  i , nx , cLine , cLineOut
   LOCAL leofq

   IF nborder == NIL
      RETURN cqrcode
   ENDIF

   IF nborder < 1
      RETURN cqrcode
   ENDIF

   cBMP  := ""
   cLineOut := ""

   leofq := .F.
   * i:        Position in cqrcode

   * Add nborder lines to begin
   * Preread first line getting the x size of the QR code
   nx := AT(CHR(10),cqrcode)
   cLine := SPACE( nx + nborder + nborder - 1 ) + CHR(10) && Empty line new
   FOR i := 1 TO nborder
      cBMP  := cBMP + cLine
   NEXT

   FOR i := 1 TO LEN(cqrcode)
      IF .NOT. leofq
         IF SUBSTR(cqrcode,i,1) == CHR(10)
            IF .NOT. ( SUBSTR(cqrcode, i + 1 , 1) == " ")
               * Empty line following, stop here
               leofq := .T.
            ENDIF
            * Count line ending and start with new line
            cBMP := cBMP + SPACE(nborder) + cLineOut + SPACE(nborder) + CHR(10)
            cLineOut := ""
         ELSE  && SUBSTR " "
            cLineOut := cLineOut + SUBSTR(cqrcode,i,1)
         ENDIF && is CHR(10)
      ENDIF && .NOT. leofq

    NEXT

  FOR i := 1 TO nborder
     cBMP  := cBMP + cLine
  NEXT

   RETURN cBMP

* Get the size of a QR code
* Returns an array with 2 elements: xSize,ySize

FUNCTION hwg_QRCodeGetSize(cqrcode)

   LOCAL aret, xSize, ySize, i, leofq

   aret := {}
   ySize := 0
   leofq := .F.

   xSize := AT(CHR(10),cqrcode)

   FOR i := 1 TO LEN(cqrcode)
      IF .NOT. leofq
         IF SUBSTR(cqrcode,i,1) == CHR(10)
            IF .NOT. ( SUBSTR(cqrcode, i + 1 , 1) == " ")
               * Empty line following, stop here
               leofq := .T.
            ENDIF
            * Count lines
            ySize := ySize + 1
         ENDIF && is CHR(10)
      ENDIF && .NOT. leofq
   NEXT

  AADD(aret,xSize)
  AADD(aret,ySize)

   RETURN aret

*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   End of Functions for QR encoding
*   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
