/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Pens, brushes, fonts, bitmaps, icons handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

Static oResCnt

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
   METHOD PrintFont()
   METHOD Props2Arr()
   // METHOD AddC( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle )

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
      IF ::aFonts[i]:name == fontName .AND.             ;
            ( ( Empty(::aFonts[i]:width) .AND. Empty(nWidth) ) ;
            .OR. ::aFonts[i]:width == nWidth ) .AND.    ;
            ::aFonts[i]:height == nHeight .AND.         ;
            ::aFonts[i]:weight == fnWeight .AND.        ;
            ::aFonts[i]:CharSet == fdwCharSet .AND.     ;
            ::aFonts[i]:Italic == fdwItalic .AND.       ;
            ::aFonts[i]:Underline == fdwUnderline .AND. ;
            ::aFonts[i]:StrikeOut == fdwStrikeOut

         ::aFonts[ i ]:nCounter ++
         IF nHandle != Nil
            hwg_Deleteobject( nHandle )
         ENDIF
         RETURN ::aFonts[ i ]
      ENDIF
   NEXT

   IF nHandle == Nil
      ::handle := hwg_Createfont( fontName, nWidth, nHeight , fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut )
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
   LOCAL af := hwg_Selectfont( oFont )

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

   RETURN HFont():Add( ::name, ::width, nheight, weight, ;
      nCharSet, Italic, Underline, StrikeOut ) // ::handle )

METHOD RELEASE() CLASS HFont
   LOCAL i, nlen := Len( ::aFonts )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      FOR EACH i IN ::aFonts
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aFonts, hb_enumindex() )
            ASize( ::aFonts, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aFonts[ i ]:handle == ::handle
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
   IF nStyle != BS_SOLID
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
   IF nStyle != BS_SOLID
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
#ifdef __XHARBOUR__
      FOR EACH i  IN ::aPens
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aPens, hb_EnumIndex() )
            ASize( ::aPens, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aPens[ i ]:handle == ::handle
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

   FOR EACH i IN ::aBrushes

      IF i:color == nColor .AND. i:nHatch == nHatch
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   IF nHatch != 99
      ::handle := hwg_Createhatchbrush( nHatch, nColor )
   ELSE
      ::handle := hwg_Createsolidbrush( nColor )
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
            hwg_Deleteobject( ::handle )
            ADel( ::aBrushes, hb_enumindex() )
            ASize( ::aBrushes, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aBrushes[ i ]:handle == ::handle
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
   CLASS VAR aBitmaps   INIT { }
   CLASS VAR lSelFile   INIT .F.
   DATA handle
   DATA name
   DATA nFlags
   DATA nTransparent    INIT -1
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nFlags, lOEM, nWidth, nHeight )
   METHOD AddStandard( nId )
   METHOD AddFile( name, hDC, lTransparent, nWidth, nHeight )
   METHOD AddString( name, cVal , nWidth, nHeight)
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
   FOR EACH i IN ::aBitmaps
      IF i:name == name .AND. i:nFlags == nFlags .AND. ;
            ( ( nWidth == nil .OR. nHeight == nil ) .OR. ;
            ( i:nWidth == nWidth .AND. i:nHeight == nHeight ) )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   IF !Empty( oResCnt )
      IF !Empty( i := oResCnt:Get( name ) )
         ::handle := hwg_OpenImage( i, .T. )
      ENDIF
   ELSEIF lOEM
      ::handle := hwg_Loadimage( 0, Val( name ), IMAGE_BITMAP, nil, nil, Hwg_bitor( nFlags, LR_SHARED ) )
   ELSE
      ::handle := hwg_Loadimage( nil, iif( lPreDefined, Val( name ), name ), IMAGE_BITMAP, nWidth, nHeight, nFlags )
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name    := name
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   ::nFlags  :=  nFlags
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddStandard( nId ) CLASS HBitmap
   LOCAL i, aBmpSize, name := "s" + LTrim( Str( nId ) )

   FOR EACH i  IN  ::aBitmaps
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   ::handle := hwg_Loadbitmap( nId, .T. )
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name   := name
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddFile( name, hDC, lTransparent, nWidth, nHeight ) CLASS HBitmap
   LOCAL i, aBmpSize, cname := CutPath( name ), cCurDir

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   FOR EACH i IN ::aBitmaps
      IF i:name == cname .AND. ( nWidth == Nil .OR. nHeight == Nil )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   name := iif( ! File( name ) .AND. File( cname ), cname, name )
   IF ::lSelFile .AND. !File( name )
      cCurDir  := DiskName() + ':\' + CurDir()
      name := hwg_Selectfile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath( name ), FilePath( name ), "Locate " + name ) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange( cCurDir )
   ENDIF

   IF Lower( Right( name, 4 ) ) != ".bmp" .OR. ( nWidth == nil .AND. nHeight == nil .AND. lTransparent == Nil )
      IF Lower( Right( name, 4 ) ) == ".bmp"
         ::handle := hwg_Openbitmap( name, hDC )
      ELSE
         ::handle := hwg_Openimage( name )
      ENDIF
   ELSE
      IF lTransparent != Nil .AND. lTransparent
         ::handle := hwg_Loadimage( nil, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE + LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS )
      ELSE
         ::handle := hwg_Loadimage( nil, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE )
      ENDIF
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name := cname
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD AddString( name, cVal , nWidth, nHeight ) CLASS HBitmap
   LOCAL oBmp, aBmpSize

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

   For EACH oBmp IN ::aBitmaps
      IF oBmp:name == name
         oBmp:nCounter ++
         RETURN oBmp
      ENDIF
   NEXT

   ::handle := hwg_Openimage( cVal, .T. )
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

METHOD AddWindow( oWnd, x1, y1, width, height ) CLASS HBitmap
   LOCAL aBmpSize

   IF x1 == Nil .OR. y1 == Nil
      x1 := 0; y1 := 0; width := oWnd:nWidth - 1; height := oWnd:nHeight - 1
   ENDIF

   ::handle := hwg_Window2bitmap( oWnd:handle, x1, y1, width, height )
   ::name := LTrim( hb_valToStr( oWnd:handle ) )
   aBmpSize  := hwg_Getbitmapsize( ::handle )
   ::nWidth  := aBmpSize[ 1 ]
   ::nHeight := aBmpSize[ 2 ]
   AAdd( ::aBitmaps, Self )

   RETURN Self

METHOD Draw( hDC, x1, y1, width, height ) CLASS HBitmap

   IF ::nTransparent < 0
      hwg_Drawbitmap( hDC, ::handle,, x1, y1, width, height )
   ELSE
      hwg_Drawtransparentbitmap( hDC, ::handle, x1, y1, ::nTransparent )
   ENDIF

   RETURN Nil

METHOD RELEASE() CLASS HBitmap
   LOCAL i, nlen := Len( ::aBitmaps )

   ::nCounter --
   IF ::nCounter == 0
#ifdef __XHARBOUR__
      FOR EACH i IN ::aBitmaps
         IF i:handle == ::handle
            hwg_Deleteobject( ::handle )
            ADel( ::aBitmaps, hB_enumIndex() )
            ASize( ::aBitmaps, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aBitmaps[ i ]:handle == ::handle
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
   CLASS VAR aIcons     INIT { }
   CLASS VAR lSelFile   INIT .F.
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource( name, nWidth, nHeight, nFlags, lOEM )
   METHOD AddFile( name, nWidth, nHeight )
   METHOD AddString( name, cVal , nWidth, nHeight )
   METHOD Draw( hDC, x, y )   INLINE hwg_Drawicon( hDC, ::handle, x, y )
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
   // hwg_writelog( "HIcon:AddResource " + Str(nWidth)+"/"+str(nHeight) )
   IF ValType( name ) == "N"
      name := LTrim( Str( name ) )
      lPreDefined := .T.
   ENDIF
   FOR EACH i IN ::aIcons
      IF i:name == name
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT
   IF !Empty( oResCnt )
      IF !Empty( i := oResCnt:Get( name ) )
         ::handle := hwg_OpenImage( i, .T., IMAGE_CURSOR )
         //hwg_writelog( Str(Len(i))+"/"+Iif(Empty(::handle),"Err","Ok") )
      ENDIF
   ELSEIF lOEM // LR_SHARED is required for OEM images
      ::handle := hwg_Loadimage( 0, Val( name ), IMAGE_ICON, nWidth, nHeight, Hwg_bitor( nFlags, LR_SHARED ) )
   ELSE
      ::handle := hwg_Loadimage( nil, iif( lPreDefined, Val( name ), name ), IMAGE_ICON, nWidth, nHeight, nFlags )
   ENDIF
   IF Empty( ::handle )
      RETURN Nil
   ENDIF
   ::name   := name
   aIconSize := hwg_Geticonsize( ::handle )
   ::nWidth  := aIconSize[ 1 ]
   ::nHeight := aIconSize[ 2 ]
   //hwg_writelog( Str(::nWidth)+"/"+str(::nHeight) )

   AAdd( ::aIcons, Self )

   RETURN Self



 /* Added by DF7BE
 name : Name of resource
 cVal : Binary contents of *.ico file
 */
METHOD AddString( name, cVal , nWidth, nHeight) CLASS HIcon
 LOCAL cTmp    && , oreturn
 LOCAL aIconSize

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF

 * Write contents into temporary file
 hb_memowrit( cTmp := hwg_CreateTempfileName( , ".ico") , cVal )
 * Load icon from temporary file
 ::handle := hwg_Loadimage( 0, cTmp, IMAGE_ICON, nWidth, nHeight, LR_DEFAULTSIZE + LR_LOADFROMFILE + LR_SHARED )
 ::name := name
  aIconSize := hwg_Geticonsize( ::handle )
 ::nWidth  := aIconSize[ 1 ]
 ::nHeight := aIconSize[ 2 ]

   AAdd( ::aIcons, Self )

  * oreturn := ::AddFile( name )
 FERASE(cTmp)

RETURN  Self   && oreturn


METHOD AddFile( name, nWidth, nHeight ) CLASS HIcon
   LOCAL i, aIconSize, cname := CutPath( name ), cCurDir

   IF nWidth == nil
      nWidth := 0
   ENDIF
   IF nHeight == nil
      nHeight := 0
   ENDIF
   FOR EACH i IN  ::aIcons
      IF i:name == cname .AND. ( nWidth == Nil .OR. i:nWidth == nWidth ) ;
         .AND. ( nHeight == Nil .OR. i:nHeight == nHeight )
         i:nCounter ++
         RETURN i
      ENDIF
   NEXT

   name := AddPath( name, ::cPath )
   name := iif( ! File( name ) .AND. File( cname ), cname, name )
   IF ::lSelFile .AND. !File( name )
      cCurDir  := DiskName() + ':\' + CurDir()
      name := hwg_Selectfile( "Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath( name ), FilePath( name ), "Locate " + name ) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange( cCurDir )
   ENDIF
   #ifdef __XHARBOUR__
   hb_FNameSplit( name,, , @cFext )
   IF Empty( cFext )
   #else
   IF Empty( hb_fNameExt( name ) )
   #endif
      name += ".ico"
   ENDIF
   ::handle := hwg_Loadimage( 0, name, IMAGE_ICON, nWidth, nHeight, LR_DEFAULTSIZE + LR_LOADFROMFILE + LR_SHARED )
   ::name := cname
   aIconSize := hwg_Geticonsize( ::handle )
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
            hwg_Deleteobject( ::handle )
            ADel( ::aIcons, hb_enumindex() )
            ASize( ::aIcons, nlen - 1 )
            EXIT
         ENDIF
      NEXT
#else
      FOR i := 1 TO nlen
         IF ::aIcons[ i ]:handle == ::handle
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
   DATA nBorder
   DATA tColor
   DATA oPen
   DATA aCorners

   METHOD New( aColors, nOrient, aCorners, nBorder, tColor, oBitmap )
   METHOD Draw( hDC, nLeft, nTop, nRight, nBottom )
ENDCLASS

METHOD New( aColors, nOrient, aCorners, nBorder, tColor, oBitmap ) CLASS HStyle

   LOCAL i, nlen := Len( ::aStyles )

   nBorder := Iif( nBorder == Nil, 0, nBorder )
   tColor := Iif( tColor == Nil, 0, tColor )
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
   IF nBorder > 0
      ::oPen := HPen():Add( BS_SOLID, nBorder, tColor )
   ENDIF

   AAdd( ::aStyles, Self )
   ::id := Len( ::aStyles )

   RETURN Self

METHOD Draw( hDC, nLeft, nTop, nRight, nBottom ) CLASS HStyle

   LOCAL n1, n2
   IF ::oBitmap == Nil
      hwg_drawGradient( hDC, nLeft, nTop, nRight, nBottom, ::nOrient, ::aColors,, ::aCorners )
   ELSE
      hwg_SpreadBitmap( hDC, ::oBitmap:handle, nLeft, nTop, nRight, nBottom )
   ENDIF
   IF !Empty( ::oPen )
      n2 := ::nBorder/2
      n1 := Int( n2 )
      IF n2 - n1 > 0.1
         n2 := n1 + 1
      ENDIF
      hwg_Selectobject( hDC, ::oPen:handle )
      hwg_Rectangle( hDC, nLeft+n1, nTop+n1, nRight-n2, nBottom-n2 )
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

   LOCAL handle, cBuff

   IF !Empty( oResCnt )
      IF !Empty( cBuff := oResCnt:Get( cBmp ) )
         handle := hwg_OpenImage( cBuff, .T. )
      ENDIF
   ELSE
      handle := hwg_Loadbitmap( cBmp )
   ENDIF

   RETURN handle

FUNCTION hwg_SetResContainer( cName )

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

EXIT PROCEDURE CleanDrawWidg
   LOCAL i

   FOR i := 1 TO Len( HPen():aPens )
      hwg_Deleteobject( HPen():aPens[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HBrush():aBrushes )
      hwg_Deleteobject( HBrush():aBrushes[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HFont():aFonts )
      hwg_Deleteobject( HFont():aFonts[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HBitmap():aBitmaps )
      hwg_Deleteobject( HBitmap():aBitmaps[ i ]:handle )
   NEXT
   FOR i := 1 TO Len( HIcon():aIcons )
      hwg_Deleteobject( HIcon():aIcons[ i ]:handle )
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
 HB_SYMBOL_UNUSED( nx )
 HB_SYMBOL_UNUSED( ny )

 * Write contents into temporary file
 hb_memowrit( cTmp := hwg_CreateTempfileName( , ".cur") , cVal )
 * Load cursor from temporary file
 hCursor := hwg_LoadCursorFromFile( cTmp ) && for GTK add parameters nx, ny
 FERASE(cTmp)
RETURN hCursor

* ======================== EOF of drawwidg.prg =========================

