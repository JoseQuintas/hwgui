/*
 * $Id: hsayimg.prg,v 1.32 2010-10-30 16:43:31 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HSayImage class
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define STM_SETIMAGE        370    // 0x0172

//- HSayImage

CLASS HSayImage INHERIT HControl

CLASS VAR winclass   INIT "STATIC"
   DATA  oImage
   DATA bClick, bDblClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
               bSize, ctooltip, bClick, bDblClick )
   METHOD Redefine( oWndParent, nId, bInit, bSize, ctooltip )
   METHOD Activate()
   METHOD END()  INLINE ( Super:END(), IIf( ::oImage <> Nil, ::oImage:Release(), ::oImage := Nil ), ::oImage := Nil )
   METHOD onClick()
   METHOD onDblClick()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
            bSize, ctooltip, bClick, bDblClick ) CLASS HSayImage

   nStyle := Hwg_BitOr( nStyle, IIF( ISBLOCK( bClick ) .OR. ISBLOCK( bDblClick ), SS_NOTIFY , 0 ) )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop,               ;
              IIf( nWidth != Nil, nWidth, 0 ), IIf( nHeight != Nil, nHeight, 0 ),, ;
              bInit, bSize,, ctooltip )

   ::title   := ""

   ::bClick := bClick
   ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )

   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Redefine( oWndParent, nId, bInit, bSize, ctooltip ) CLASS HSayImage

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0,, bInit, bSize,, ctooltip )

   RETURN Self

METHOD Activate() CLASS HSayImage

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD onClick()  CLASS HSayImage
   IF ::bClick != NIL
      ::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil

METHOD onDblClick()  CLASS HSayImage
   IF ::bDblClick != NIL
      ::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bDblClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil



//- HSayBmp

CLASS HSayBmp INHERIT HSayImage

   DATA nOffsetV  INIT 0
   DATA nOffsetH  INIT 0
   DATA nZoom
   DATA lTransp
   DATA nStretch

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
               bSize, ctooltip, bClick, bDblClick, lTransp, nStretch, nStyle )
   METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip, lTransp )
   METHOD Init()
   METHOD Paint( lpdis )
   METHOD ReplaceBitmap( Image, lRes )
   //METHOD REFRESH() INLINE ::HIDE(), SENDMESSAGE( ::handle, WM_PAINT, 0, 0 ), ::SHOW()
   METHOD Refresh() INLINE RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_UPDATENOW )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
            bSize, ctooltip, bClick, bDblClick, lTransp, nStretch, nStyle ) CLASS HSayBmp

   nStyle := IIF( nStyle = Nil, 0, nStyle )
   Super:New( oWndParent, nId, SS_OWNERDRAW + nStyle, nLeft, nTop, nWidth, nHeight, bInit, bSize, ctooltip, bClick, bDblClick )

   ::bPaint := { | o, lpdis | o:Paint( lpdis ) }
   ::lTransp := IIf( lTransp = Nil, .F., lTransp )
   ::nStretch := IIf( nStretch = Nil, 0, nStretch )

   IF Image != Nil .AND. ! Empty( Image )
      IF lRes == Nil ; lRes := .F. ; ENDIF
      ::oImage := IIf( lRes .OR. ValType( Image ) == "N",     ;
                       HBitmap():AddResource( Image ), ;
                       IIf( ValType( Image ) == "C",     ;
                            HBitmap():AddFile( Image ), Image ) )
      IF nWidth == Nil .OR. nHeight == Nil
         ::nWidth  := ::oImage:nWidth
         ::nHeight := ::oImage:nHeight
         ::nStretch = 2
      ENDIF
   ENDIF
   ::Activate()

   RETURN Self

METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip, lTransp ) CLASS HSayBmp


   Super:Redefine( oWndParent, nId, bInit, bSize, ctooltip )
   ::bPaint := { | o, lpdis | o:Paint( lpdis ) }
   ::lTransp := IIf( lTransp = Nil, .F., lTransp )
   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := IIf( lRes .OR. ValType( xImage ) == "N",     ;
                    HBitmap():AddResource( xImage ), ;
                    IIf( ValType( xImage ) == "C",     ;
                         HBitmap():AddFile( xImage ), xImage ) )
   RETURN Self

METHOD Init() CLASS HSayBmp

   IF !::lInit
      Super:Init()
      IF ::oImage != Nil .AND. !empty( ::oImage:Handle )
         SendMessage( ::handle,STM_SETIMAGE, IMAGE_BITMAP, ::oImage:handle )
      ENDIF
   ENDIF
Return Nil

METHOD Paint( lpdis ) CLASS HSayBmp
   LOCAL drawInfo := GetDrawItemInfo( lpdis )

   IF ::oImage != Nil .AND. !empty( ::oImage:Handle )
      IF ::nZoom == Nil
         IF ::lTransp
            IF ::nStretch = 1  // isometric
               DrawTransparentBitmap( drawInfo[ 3 ], ::oImage:handle, drawInfo[ 4 ] + ::nOffsetH, ;
                                      drawInfo[ 5 ] + ::nOffsetV,, ) // ::nWidth+1, ::nHeight+1 )
ELSEIF ::nStretch = 2  // CLIP
   DrawTransparentBitmap( drawInfo[ 3 ], ::oImage:handle, drawInfo[ 4 ] + ::nOffsetH, ;
                          drawInfo[ 5 ] + ::nOffsetV,, ::nWidth + 1, ::nHeight + 1 )
ELSE // stretch (DEFAULT)
   DrawTransparentBitmap( drawInfo[ 3 ], ::oImage:handle, drawInfo[ 4 ] + ::nOffsetH, ;
                          drawInfo[ 5 ] + ::nOffsetV,, drawInfo[ 6 ] - drawInfo[ 4 ] + 1, drawInfo[ 7 ] - drawInfo[ 5 ] + 1  )
ENDIF
ELSE
   IF ::nStretch = 1  // isometric
      DrawBitmap( drawInfo[ 3 ], ::oImage:handle,, drawInfo[ 4 ] + ::nOffsetH, ;
                  drawInfo[ 5 ] + ::nOffsetV ) //, ::nWidth+1, ::nHeight+1 )
ELSEIF ::nStretch = 2  // CLIP
   DrawBitmap( drawInfo[ 3 ], ::oImage:handle,, drawInfo[ 4 ] + ::nOffsetH, ;
               drawInfo[ 5 ] + ::nOffsetV, ::nWidth + 1, ::nHeight + 1 )
ELSE // stretch (DEFAULT)
   DrawBitmap( drawInfo[ 3 ], ::oImage:handle,, drawInfo[ 4 ] + ::nOffsetH, ;
               drawInfo[ 5 ] + ::nOffsetV, drawInfo[ 6 ] - drawInfo[ 4 ] + 1, drawInfo[ 7 ] - drawInfo[ 5 ] + 1 )
ENDIF
ENDIF
ELSE
   DrawBitmap( drawInfo[ 3 ], ::oImage:handle,, drawInfo[ 4 ] + ::nOffsetH, ;
               drawInfo[ 5 ] + ::nOffsetV, ::oImage:nWidth * ::nZoom, ::oImage:nHeight * ::nZoom )
ENDIF
ENDIF

RETURN Nil

METHOD ReplaceBitmap( Image, lRes ) CLASS HSayBmp

   IF ::oImage != Nil
      ::oImage:Release()
   ENDIF
   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := IIf( lRes .OR. ValType( Image ) == "N",     ;
                    HBitmap():AddResource( Image ), ;
                    IIf( ValType( Image ) == "C",     ;
                         HBitmap():AddFile( Image ), Image ) )

   RETURN Nil


//- HSayIcon

CLASS HSayIcon INHERIT HSayImage

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
               bSize, ctooltip, lOEM, bClick, bDblClick )
   METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip )
   METHOD Init()
   METHOD REFRESH() INLINE SendMessage( ::handle, STM_SETIMAGE, IMAGE_ICON, ::oImage:handle )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
            bSize, ctooltip, lOEM, bClick, bDblClick ) CLASS HSayIcon

   Super:New( oWndParent, nId, SS_ICON, nLeft, nTop, nWidth, nHeight, bInit, bSize, ctooltip, bClick, bDblClick )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   IF lOEM == Nil ; lOEM := .F. ; ENDIF
   IF ::oImage == nil
      ::oImage := IIf( lRes .OR. ValType( Image ) == "N",  ;
                       HIcon():AddResource( Image,,,, lOEM ),  ;
                       IIf( ValType( Image ) == "C",    ;
                            HIcon():AddFile( Image ), Image ) )
   ENDIF
   ::Activate()

   RETURN Self

METHOD Redefine( oWndParent, nId, xImage, lRes, bInit, bSize, ctooltip ) CLASS HSayIcon

   Super:Redefine( oWndParent, nId, bInit, bSize, ctooltip )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   IF ::oImage == nil
      ::oImage := IIf( lRes .OR. ValType( xImage ) == "N",   ;
                       HIcon():AddResource( xImage ), ;
                       IIf( ValType( xImage ) == "C",   ;
                            HIcon():AddFile( xImage ), xImage ) )
   ENDIF
   RETURN Self

METHOD Init() CLASS HSayIcon

   IF ! ::lInit
      Super:Init()
      SendMessage( ::handle, STM_SETIMAGE, IMAGE_ICON, ::oImage:handle )
   ENDIF
   RETURN Nil

