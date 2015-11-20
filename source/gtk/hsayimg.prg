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

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctoolt )
   METHOD Activate()
   METHOD End()  INLINE ( ::Super:End(), iif( ::oImage <> Nil,::oImage:Release(),::oImage := Nil ), ::oImage := Nil )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, ;
      bSize, ctoolt ) CLASS HSayImage

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop,               ;
      iif( nWidth != Nil, nWidth, 0 ), iif( nHeight != Nil, nHeight, 0 ), , ;
      bInit, bSize, , ctoolt )

   ::title   := ""

   RETURN Self

METHOD Activate CLASS HSayImage

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

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt, bClick, bDblClick, lTransp, nStretch, trcolor )
   METHOD INIT
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint()
   METHOD ReplaceBitmap( Image, lRes )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, Image, lRes, bInit, ;
      bSize, ctoolt, bClick, bDblClick, lTransp, nStretch, trcolor ) CLASS HSayBmp

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, bInit, bSize, ctoolt )

   ::lTransp := Iif( lTransp = Nil, .F. , lTransp )
   ::trcolor := Iif( trcolor = Nil, 16777215, trcolor )

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
         IF ::lTransp
            ::oImage:Transparent( ::trcolor )
         ENDIF
      ELSE
         RETURN Nil
      ENDIF
   ENDIF
   ::Activate()

   RETURN Self

METHOD INIT CLASS HSayBmp

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSayBmp

   IF msg == WM_PAINT
      ::Paint()
   ENDIF

   RETURN 0

METHOD Paint() CLASS HSayBmp
   LOCAL hDC := hwg_Getdc( ::handle )

   IF ::oImage != Nil
      IF ::nZoom == Nil
         hwg_Drawbitmap( hDC, ::oImage:handle, , ::nOffsetH, ;
            ::nOffsetV, ::nWidth, ::nHeight )
      ELSE
         hwg_Drawbitmap( hDC, ::oImage:handle, , ::nOffsetH, ;
            ::nOffsetV, ::oImage:nWidth * ::nZoom, ::oImage:nHeight * ::nZoom )
      ENDIF
   ENDIF
   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD ReplaceBitmap( Image, lRes ) CLASS HSayBmp

   IF ::oImage != Nil
      ::oImage:Release()
   ENDIF
   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := iif( lRes .OR. ValType( Image ) == "N",  ;
      HBitmap():AddResource( Image ), ;
      Iif( ValType( Image ) == "C",   ;
      HBitmap():AddFile( Image ), Image ) )

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
      HIcon():AddResource( Image ),  ;
      Iif( ValType( Image ) == "C",  ;
      HIcon():AddFile( Image ), Image ) )
   ::Activate()

   RETURN Self
