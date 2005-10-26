/*
 * $Id: hsayimg.prg,v 1.11 2005-10-26 07:43:26 omm Exp $
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

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,bInit, ;
                  bSize,ctooltip )
   METHOD Redefine( oWndParent,nId,bInit,bSize,ctooltip )
   METHOD Activate()
   METHOD End()  INLINE ( Super:End(),iif(::oImage<>Nil,::oImage:Release(),::oImage:=Nil),::oImage := Nil )

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,bInit, ;
                  bSize,ctooltip ) CLASS HSayImage

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,               ;
               Iif( nWidth!=Nil,nWidth,0 ),Iif( nHeight!=Nil,nHeight,0 ),, ;
               bInit,bSize,,ctooltip )

   ::title   := ""

Return Self

METHOD Redefine( oWndParent,nId,bInit,bSize,ctooltip ) CLASS HSayImage

   Super:New( oWndParent,nId,0,0,0,0,0,,bInit,bSize,,ctooltip )

Return Self

METHOD Activate CLASS HSayImage

   IF ::oParent:handle != 0
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
                  bSize,ctooltip )
   METHOD Redefine( oWndParent,nId,Image,lRes,bInit,bSize,ctooltip )
   METHOD Paint( lpdis )
   METHOD ReplaceBitmap( Image, lRes )

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctooltip ) CLASS HSayBmp

   Super:New( oWndParent,nId,SS_OWNERDRAW,nLeft,nTop,nWidth,nHeight,bInit,bSize,ctooltip )

   ::bPaint := {|o,lpdis|o:Paint(lpdis)}

   IF Image != Nil
      IF lRes == Nil ; lRes := .F. ; ENDIF
      ::oImage := Iif( lRes .OR. Valtype(Image)=="N",     ;
                          HBitmap():AddResource( Image ), ;
                          Iif( Valtype(Image) == "C",     ;
                          HBitmap():AddFile( Image ), Image ) )
      IF nWidth == Nil .OR. nHeight == Nil
         ::nWidth  := ::oImage:nWidth
         ::nHeight := ::oImage:nHeight
      ENDIF
   ENDIF
   ::Activate()

Return Self

METHOD Redefine( oWndParent,nId,xImage,lRes,bInit,bSize,ctooltip ) CLASS HSayBmp

   Super:Redefine( oWndParent,nId,bInit,bSize,ctooltip )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(xImage)=="N",     ;
                       HBitmap():AddResource( xImage ), ;
                       Iif( Valtype(xImage) == "C",     ;
                       HBitmap():AddFile( xImage ), xImage ) )
Return Self

METHOD Paint( lpdis ) CLASS HSayBmp
Local drawInfo := GetDrawItemInfo( lpdis )

   IF ::oImage != Nil
      IF ::nZoom == Nil
         DrawBitmap( drawInfo[3], ::oImage:handle,, drawInfo[4]+::nOffsetH, ;
               drawInfo[5]+::nOffsetV, drawInfo[6]-drawInfo[4]+1, drawInfo[7]-drawInfo[5]+1 )
      ELSE
         DrawBitmap( drawInfo[3], ::oImage:handle,, drawInfo[4]+::nOffsetH, ;
               drawInfo[5]+::nOffsetV, ::oImage:nWidth*::nZoom, ::oImage:nHeight*::nZoom )
      ENDIF
   ENDIF

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
                  bSize,ctooltip )
   METHOD Redefine( oWndParent,nId,Image,lRes,bInit,bSize,ctooltip )
   METHOD Init()

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctooltip ) CLASS HSayIcon

   Super:New( oWndParent,nId,SS_ICON,nLeft,nTop,nWidth,nHeight,bInit,bSize,ctooltip )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(Image)=="N",    ;
                       HIcon():AddResource( Image ),  ;
                       Iif( Valtype(Image) == "C",    ;
                       HIcon():AddFile( Image ), Image ) )
   ::Activate()

Return Self

METHOD Redefine( oWndParent,nId,xImage,lRes,bInit,bSize,ctooltip ) CLASS HSayIcon

   Super:Redefine( oWndParent,nId,bInit,bSize,ctooltip )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(xImage)=="N",   ;
                       HIcon():AddResource( xImage ), ;
                       Iif( Valtype(xImage) == "C",   ;
                       HIcon():AddFile( xImage ), xImage ) )
Return Self

METHOD Init() CLASS HSayIcon

   IF !::lInit
      Super:Init()
      SendMessage( ::handle,STM_SETIMAGE,IMAGE_ICON,::oImage:handle )
   ENDIF
Return Nil
