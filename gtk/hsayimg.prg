/*
 * $Id: hsayimg.prg,v 1.1 2005-10-27 12:10:33 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HSayImage class
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "hbclass.ch"
#include "hwgui.ch"

//- HSayImage

CLASS HSayImage INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA  oImage

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,bInit, ;
                  bSize,ctoolt )
   METHOD Activate()
   METHOD End()  INLINE ( Super:End(),iif(::oImage<>Nil,::oImage:Release(),::oImage:=Nil),::oImage := Nil )

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,bInit, ;
                  bSize,ctoolt ) CLASS HSayImage

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,               ;
               Iif( nWidth!=Nil,nWidth,0 ),Iif( nHeight!=Nil,nHeight,0 ),, ;
               bInit,bSize,,ctoolt )

   ::title   := ""

Return Self

METHOD Activate CLASS HSayImage

   IF !Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil




//- HSayBmp

CLASS HSayBmp INHERIT HSayImage 

   DATA nOffsetV  INIT 0
   DATA nOffsetH  INIT 0
   DATA nZoom

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt )
   METHOD INIT
   METHOD onEvent( msg, wParam, lParam )
   METHOD Paint()
   METHOD ReplaceBitmap( Image, lRes )

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt ) CLASS HSayBmp

   Super:New( oWndParent,nId,SS_OWNERDRAW,nLeft,nTop,nWidth,nHeight,bInit,bSize,ctoolt )

   IF Image != Nil
      IF lRes == Nil ; lRes := .F. ; ENDIF
      ::oImage := Iif( lRes .OR. Valtype(Image)=="N",     ;
                          HBitmap():AddResource( Image ), ;
                          Iif( Valtype(Image) == "C",     ;
                          HBitmap():AddFile( Image ), Image ) )
      IF !Empty( ::oImage )
         IF nWidth == Nil .OR. nHeight == Nil
            ::nWidth  := ::oImage:nWidth
            ::nHeight := ::oImage:nHeight
         ENDIF
      ELSE
         Return Nil
      ENDIF
   ENDIF
   ::Activate()

Return Self

METHOD INIT CLASS HSayBmp
   IF !::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle,Self )
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSayBmp
   IF msg == WM_PAINT
      ::Paint()
   ENDIF
Return 0

METHOD Paint() CLASS HSayBmp
Local hDC := GetDC( ::handle )

   IF ::oImage != Nil
      IF ::nZoom == Nil
         DrawBitmap( hDC, ::oImage:handle,, ::nOffsetH, ;
               ::nOffsetV, ::nWidth, ::nHeight )
      ELSE
         DrawBitmap( hDC, ::oImage:handle,, ::nOffsetH, ;
               ::nOffsetV, ::oImage:nWidth*::nZoom, ::oImage:nHeight*::nZoom )
      ENDIF
   ENDIF
   releaseDC( ::handle, hDC )

Return Nil

METHOD ReplaceBitmap( Image, lRes ) CLASS HSayBmp

   IF ::oImage != Nil
      ::oImage:Release()
   ENDIF
   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(Image)=="N",     ;
                       HBitmap():AddResource( Image ), ;
                       Iif( Valtype(Image) == "C",     ;
                       HBitmap():AddFile( Image ), Image ) )

Return Nil


//- HSayIcon

CLASS HSayIcon INHERIT HSayImage

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt )

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt ) CLASS HSayIcon

   Super:New( oWndParent,nId,SS_ICON,nLeft,nTop,nWidth,nHeight,bInit,bSize,ctoolt )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(Image)=="N",    ;
                       HIcon():AddResource( Image ),  ;
                       Iif( Valtype(Image) == "C",    ;
                       HIcon():AddFile( Image ), Image ) )
   ::Activate()

Return Self
