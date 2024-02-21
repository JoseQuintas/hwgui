/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HSayImage class
 *
 * Copyright 2003 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define STM_SETIMAGE        370    // 0x0172

   //- HSayImage

CLASS HSayImage INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA  oImage
   DATA bClick, bDblClick
   DATA lNoRelease      INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctooltip, bClick, bDblClick, bColor )
   METHOD Redefine( oWndParent, nId, bInit, bSize, ctooltip )
   METHOD Activate()
   METHOD onClick()
   METHOD onDblClick()
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctooltip, bClick, bDblClick, bColor ) CLASS HSayImage

   nStyle := Hwg_BitOr( nStyle, SS_NOTIFY )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
      Iif( nWidth != Nil, nWidth, 0 ), iif( nHeight != Nil, nHeight, 0 ),, ;
      bInit, bSize,, ctooltip,, bColor )

   ::title := ""

   ::bClick := bClick
   ::oParent:AddEvent( STN_CLICKED, ::id, { || ::onClick() } )

   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, ::id, { || ::onDblClick() } )

   RETURN Self

/* Parameters bClick, bDblClick were removed a long time ago */
METHOD Redefine( oWndParent, nId, bInit, bSize, ctooltip ) CLASS HSayImage

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0,, bInit, bSize,, ctooltip )

   RETURN Self

METHOD Activate() CLASS HSayImage

   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onClick()  CLASS HSayImage

   IF ::bClick != NIL
      Eval( ::bClick, Self )
   ENDIF

   RETURN Nil

METHOD onDblClick()  CLASS HSayImage

   IF ::bDblClick != NIL
      Eval( ::bDblClick, Self )
   ENDIF

   RETURN Nil

METHOD End() CLASS HSayImage

   IF !::lNoRelease
      IF ::oImage != Nil
         ::oImage:Release()
         ::oImage := Nil
      ENDIF
   ENDIF

   RETURN ::Super:End()

   //- HSayBmp

CLASS HSayBmp INHERIT HSayImage

   DATA nOffsetV  INIT 0
   DATA nOffsetH  INIT 0
   DATA nZoom
   DATA lTransp, trcolor
   DATA nStretch
   DATA nBorder, oPen

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctooltip, bClick, bDblClick, lTransp, nStretch, trcolor, bColor )
   METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip, lTransp )
   METHOD Init()
   METHOD Paint( lpdis )
   METHOD ReplaceBitmap( Image, lRes )
   METHOD Refresh() INLINE hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_UPDATENOW )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctooltip, bClick, bDblClick, lTransp, nStretch, trcolor, bColor ) CLASS HSayBmp

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, bInit, bSize, ctooltip, bClick, bDblClick, bColor )

   ::bPaint := { | o, lpdis | o:Paint( lpdis ) }
   ::lTransp := Iif( lTransp = Nil, .F. , lTransp )
   ::nStretch := Iif( nStretch = Nil, 0, nStretch )
   ::trcolor := Iif( trcolor = Nil, Nil, trcolor )
   ::nBorder := 0
   ::tColor := 0

   IF Image != Nil .AND. ! Empty( Image )
      IF Valtype( Image ) == "O"
         ::oImage := Image
         ::lNoRelease := .T.
      ELSE
         ::oImage := Iif( !Empty( lRes ) .OR. ValType( Image ) == "N",  ;
            HBitmap():AddResource( Image ),   ;
            Iif( ValType( Image ) == "C",     ;
            HBitmap():AddFile( Image ), Nil ) )
      ENDIF
      IF ::oImage != Nil .AND. ( nWidth == Nil .OR. nHeight == Nil )
         ::nWidth  := ::oImage:nWidth
         ::nHeight := ::oImage:nHeight
         ::nStretch = 2
      ENDIF
   ENDIF
   ::Activate()

   RETURN Self

/* Image ==> xImage */
METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip, lTransp ) CLASS HSayBmp

   ::Super:Redefine( oWndParent, nId, bInit, bSize, ctooltip )
   ::bPaint := { | o, lpdis | o:Paint( lpdis ) }
   ::lTransp := iif( lTransp = Nil, .F. , lTransp )
   ::nBorder := 0
   ::tColor := 0

   IF Valtype( xImage ) == "O"
      ::oImage := xImage
      ::lNoRelease := .T.
   ELSE

      ::oImage := Iif( !Empty(lRes) .OR. ValType( xImage ) == "N",     ;
         HBitmap():AddResource( xImage ),   ;
         iif( ValType( xImage ) == "C",     ;
         HBitmap():AddFile( xImage ), Nil ) )
   ENDIF
   RETURN Self

METHOD Init() CLASS HSayBmp

   IF !::lInit
      ::Super:Init()
      IF ::oImage != Nil .AND. !Empty( ::oImage:Handle )
         hwg_Sendmessage( ::handle, STM_SETIMAGE, IMAGE_BITMAP, ::oImage:handle )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Paint( lpdis ) CLASS HSayBmp
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpdis ), n

   IF ::brush != Nil
      hwg_Fillrect( drawInfo[ 3 ], drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ], ::brush:handle )
   ENDIF
   IF ::oImage != Nil .AND. !Empty( ::oImage:Handle )
      IF ::nZoom == Nil
         IF ::lTransp
            IF ::nStretch = 1  // isometric
               hwg_Drawtransparentbitmap( drawInfo[ 3 ], ::oImage:handle, drawInfo[ 4 ] + ::nOffsetH, ;
                  drawInfo[ 5 ] + ::nOffsetV, ::trcolor )
            ELSEIF ::nStretch = 2  // CLIP
               hwg_Drawtransparentbitmap( drawInfo[ 3 ], ::oImage:handle, drawInfo[ 4 ] + ::nOffsetH, ;
                  drawInfo[ 5 ] + ::nOffsetV, ::trcolor, ::nWidth + 1, ::nHeight + 1 )
            ELSE // stretch (DEFAULT)
               hwg_Drawtransparentbitmap( drawInfo[ 3 ], ::oImage:handle, drawInfo[ 4 ] + ::nOffsetH, ;
                  drawInfo[ 5 ] + ::nOffsetV, ::trcolor, drawInfo[ 6 ] - drawInfo[ 4 ] + 1, drawInfo[ 7 ] - drawInfo[ 5 ] + 1  )
            ENDIF
         ELSE
            IF ::nStretch = 1  // isometric
               hwg_Drawbitmap( drawInfo[ 3 ], ::oImage:handle, , drawInfo[ 4 ] + ::nOffsetH, ;
                  drawInfo[ 5 ] + ::nOffsetV ) //, ::nWidth+1, ::nHeight+1 )
            ELSEIF ::nStretch = 2  // CLIP
               hwg_Drawbitmap( drawInfo[ 3 ], ::oImage:handle, , drawInfo[ 4 ] + ::nOffsetH, ;
                  drawInfo[ 5 ] + ::nOffsetV, ::nWidth + 1, ::nHeight + 1 )
            ELSE // stretch (DEFAULT)
               hwg_Drawbitmap( drawInfo[ 3 ], ::oImage:handle, , drawInfo[ 4 ] + ::nOffsetH, ;
                  drawInfo[ 5 ] + ::nOffsetV, drawInfo[ 6 ] - drawInfo[ 4 ] + 1, drawInfo[ 7 ] - drawInfo[ 5 ] + 1 )
            ENDIF
         ENDIF
      ELSE
         hwg_Drawbitmap( drawInfo[ 3 ], ::oImage:handle, , drawInfo[ 4 ] + ::nOffsetH, ;
            drawInfo[ 5 ] + ::nOffsetV, ::oImage:nWidth * ::nZoom, ::oImage:nHeight * ::nZoom )
      ENDIF
   ENDIF
   IF ::nBorder > 0
      IF ::oPen == Nil
         ::oPen := HPen():Add( BS_SOLID, ::nBorder, ::tColor )
      ENDIF
      hwg_Selectobject( drawInfo[ 3 ], ::oPen:handle )
      n := Int( ::nBorder/2 )
      hwg_Rectangle( drawInfo[ 3 ], ::nOffsetH+n, ::nOffsetV+n, ::nOffsetH+::nWidth-n, ::nOffsetV+::nHeight-n )
   ENDIF

   RETURN Nil

METHOD ReplaceBitmap( Image, lRes ) CLASS HSayBmp

   IF ::oImage != Nil .AND. !::lNoRelease
      ::oImage:Release()
      ::oImage := Nil
   ENDIF
   IF !Empty( Image )
      IF Valtype( Image ) == "O"
         ::oImage := Image
         ::lNoRelease := .T.
      ELSE
         ::oImage := Iif( !Empty(lRes) .OR. ValType( Image ) == "N",     ;
            HBitmap():AddResource( Image ), ;
            Iif( ValType( Image ) == "C", HBitmap():AddFile( Image ), Nil ) )
         ::lNoRelease := .F.
      ENDIF
   ENDIF

   RETURN Nil

   //- HSayIcon

CLASS HSayIcon INHERIT HSayImage

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctooltip, lOEM, bClick, bDblClick )
   METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip )
   METHOD Init()
   METHOD REFRESH() INLINE hwg_Sendmessage( ::handle, STM_SETIMAGE, IMAGE_ICON, ::oImage:handle )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctooltip, lOEM, bClick, bDblClick ) CLASS HSayIcon

   ::Super:New( oWndParent, nId, SS_ICON, nLeft, nTop, nWidth, nHeight, bInit, bSize, ctooltip, bClick, bDblClick )

   IF lOEM == Nil ; lOEM := .F. ; ENDIF
   IF ::oImage == Nil
      * Ticket #60
      // hwg_writelog( "::oImage == nil" + Str(nWidth) + "/" + str(nHeight) )
      IF Valtype( Image ) == "O"
         ::oImage := Image
         ::lNoRelease := .T.
      ELSE
         ::oImage := Iif( !Empty(lRes) .OR. ValType( Image ) == "N",  ;
            HIcon():AddResource( Image, nWidth , nHeight , , lOEM ),  ;
            Iif( ValType( Image ) == "C",    ;
            HIcon():AddFile( Image , nWidth , nHeight  ), Nil ) )
      ENDIF
   ENDIF
   ::Activate()

   RETURN Self


/* Image ==> xImage */
METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip ) CLASS HSayIcon

   ::Super:Redefine( oWndParent, nId, bInit, bSize, ctooltip )

   IF ::oImage == Nil
      IF Valtype( xImage ) == "O"
         ::oImage := xImage
         ::lNoRelease := .T.
      ELSE
         ::oImage := iif( !Empty(lRes) .OR. ValType( xImage ) == "N",   ;
            HIcon():AddResource( xImage ), ;
            iif( ValType( xImage ) == "C",   ;
            HIcon():AddFile( xImage ), Nil ) )
      ENDIF
   ENDIF

   RETURN Self

METHOD Init() CLASS HSayIcon

   IF ! ::lInit
      ::Super:Init()
      hwg_Sendmessage( ::handle, STM_SETIMAGE, IMAGE_ICON, ::oImage:handle )
   ENDIF

   RETURN Nil


FUNCTION hwg_GetBitmapHeight( handle )

   LOCAL aBmpSize

   aBmpSize  := hwg_Getbitmapsize( handle )

   RETURN aBmpSize[2]

FUNCTION hwg_GetBitmapWidth( handle )

   LOCAL aBmpSize

   aBmpSize  := hwg_Getbitmapsize( handle )

   RETURN aBmpSize[1]
