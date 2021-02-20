/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HSayImage class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hbclass.ch"
#include "hwgui.ch"

   //- HSayImage

CLASS HSayImage INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA  oImage
   DATA bClick, bDblClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctoolt, bClick, bDblClick, bColor )
   METHOD Activate()
   METHOD End()  INLINE ( ::Super:End(), Iif( ::oImage <> Nil,::oImage:Release(),::oImage := Nil ), ::oImage := Nil )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctoolt, bClick, bDblClick, bColor ) CLASS HSayImage

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
      iif( nWidth != Nil, nWidth, 0 ), iif( nHeight != Nil, nHeight, 0 ),, ;
      bInit, bSize,, ctoolt,, bColor )

   ::title := ""

   ::bClick := bClick
   ::bDblClick := bDblClick

   RETURN Self

METHOD Activate() CLASS HSayImage

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

   //- HSayBmp

CLASS HSayBmp INHERIT HSayImage

   DATA nOffsetV  INIT 0
   DATA nOffsetH  INIT 0
   DATA nZoom
   DATA lTransp, trcolor
   DATA nBorder, oPen

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt, bClick, bDblClick, lTransp, nStretch, trcolor, bColor )
   METHOD INIT
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint()
   METHOD ReplaceBitmap( Image, lRes )
   METHOD Refresh() INLINE hwg_Redrawwindow( ::handle )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt, bClick, bDblClick, lTransp, nStretch, trcolor, bColor ) CLASS HSayBmp

   * Parameters not used
   HB_SYMBOL_UNUSED(nStretch)

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, ;
         bInit, bSize, ctoolt, bClick, bDblClick, bColor )

   ::lTransp := Iif( lTransp = Nil, .F. , lTransp )
   ::trcolor := Iif( trcolor = Nil, 16777215, trcolor )
   ::nBorder := 0
   ::tColor := 0

   IF Image != Nil
      IF lRes == Nil ; lRes := .F. ; ENDIF
      ::oImage := iif( lRes .OR. ValType( Image ) == "N",     ;
         HBitmap():AddResource( Image ), ;
         iif( ValType( Image ) == "C",     ;
         HBitmap():AddFile( Image ), Image ) )
      IF !Empty( ::oImage )
         IF nWidth == Nil .OR. nHeight == Nil
            ::nWidth  := ::oImage:nWidth
            ::nHeight := ::oImage:nHeight
         ENDIF
      ELSE
         RETURN Nil
      ENDIF
   ENDIF
   ::Activate()

   RETURN Self

METHOD INIT() CLASS HSayBmp

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSayBmp

   * Parameters not used
   HB_SYMBOL_UNUSED(wParam)
   HB_SYMBOL_UNUSED(lParam)

   IF msg == WM_PAINT
      ::Paint()
   ENDIF

   RETURN 0

METHOD Paint() CLASS HSayBmp
   LOCAL hDC := hwg_Getdc( ::handle )

   IF ::brush != Nil
      hwg_Fillrect( hDC, ::nOffsetH, ::nOffsetV, ::nWidth, ::nHeight, ::brush:handle )
   ENDIF
   IF ::oImage != Nil
      IF ::nZoom == Nil
         IF ::lTransp
            hwg_Drawtransparentbitmap( hDC, ::oImage:handle, ::nOffsetH, ;
               ::nOffsetV, ::trColor, ::nWidth, ::nHeight )
         ELSE
            hwg_Drawbitmap( hDC, ::oImage:handle, , ::nOffsetH, ;
               ::nOffsetV, ::nWidth, ::nHeight )
         ENDIF
      ELSE
         hwg_Drawbitmap( hDC, ::oImage:handle, , ::nOffsetH, ;
            ::nOffsetV, ::oImage:nWidth * ::nZoom, ::oImage:nHeight * ::nZoom )
      ENDIF
   ENDIF
   IF ::nBorder > 0
      IF ::oPen == Nil
         ::oPen := HPen():Add( BS_SOLID, ::nBorder, ::tColor )
      ENDIF
      hwg_Selectobject( hDC, ::oPen:handle )
      hwg_Rectangle( hDC, ::nOffsetH, ::nOffsetV, ::nOffsetH+::nWidth-1-::nBorder, ::nOffsetV+::nHeight-1-::nBorder )
   ENDIF
   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD ReplaceBitmap( Image, lRes ) CLASS HSayBmp

   IF ::oImage != Nil
      ::oImage:Release()
      ::oImage := Nil
   ENDIF
   IF !Empty( Image )
      IF lRes == Nil ; lRes := .F. ; ENDIF
      ::oImage := iif( lRes .OR. ValType( Image ) == "N",  ;
         HBitmap():AddResource( Image ), ;
         Iif( ValType( Image ) == "C",   ;
         HBitmap():AddFile( Image ), Image ) )
   ENDIF

   RETURN Nil

   //- HSayIcon

CLASS HSayIcon INHERIT HSayImage

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt ) CLASS HSayIcon

   ::Super:New( oWndParent, nId, SS_ICON, nLeft, nTop, nWidth, nHeight, bInit, bSize, ctoolt )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := iif( lRes .OR. ValType( Image ) == "N", ;
      HIcon():AddResource( Image , nWidth, nHeight ),  ;
      Iif( ValType( Image ) == "C",  ;
      HIcon():AddFile( Image , nWidth, nHeight ), Image ) )
   ::Activate()

   RETURN Self
   
* ====================== EOF of hsayimg.prg ========================
   
