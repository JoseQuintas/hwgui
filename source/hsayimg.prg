/*
 * $Id: hsayimg.prg,v 1.7 2004-11-16 18:22:08 alkresin Exp $
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

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,bInit, ;
                  bSize,ctoolt )
   METHOD Redefine( oWndParent,nId,bInit,bSize,ctoolt )
   METHOD Activate()
   METHOD End()  INLINE ( Super:End(),iif(::oImage<>Nil,::oImage:Release(),::oImage:=Nil),::oImage := Nil )

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,bInit, ;
                  bSize,ctoolt ) CLASS HSayImage

   Super:New( oWndParent,nId,WS_VISIBLE+WS_CHILD,nLeft,nTop,               ;
               Iif( nWidth!=Nil,nWidth,0 ),Iif( nHeight!=Nil,nHeight,0 ),, ;
               bInit,bSize,,ctoolt )

   ::title   := ""

Return Self

METHOD Redefine( oWndParent,nId,bInit,bSize,ctoolt ) CLASS HSayImage

   Super:New( oWndParent,nId,0,0,0,0,0,,bInit,bSize,,ctoolt )

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

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt )
   METHOD Redefine( oWndParent,nId,Image,lRes,bInit,bSize,ctoolt )
   METHOD Init()
   METHOD ReplaceBitmap( Image, lRes )

ENDCLASS

METHOD ReplaceBitmap( Image, lRes ) CLASS HSayBmp

   ::oImage := Iif( lRes .OR. Valtype(Image)=="N",     ;
                       HBitmap():AddResource( Image ), ;
                       Iif( Valtype(Image) == "C",     ;
                       HBitmap():AddFile( Image ), Image ) )

    SendMessage( ::handle,STM_SETIMAGE,IMAGE_BITMAP,::oImage:handle )

Return Nil

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt ) CLASS HSayBmp

   Super:New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,bInit,bSize,ctoolt )

   ::style   += SS_BITMAP

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(Image)=="N",     ;
                       HBitmap():AddResource( Image ), ;
                       Iif( Valtype(Image) == "C",     ;
                       HBitmap():AddFile( Image ), Image ) )
   ::Activate()

Return Self

METHOD Redefine( oWndParent,nId,xImage,lRes,bInit,bSize,ctoolt ) CLASS HSayBmp

   Super:Redefine( oWndParent,nId,bInit,bSize,ctoolt )

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(xImage)=="N",     ;
                       HBitmap():AddResource( xImage ), ;
                       Iif( Valtype(xImage) == "C",     ;
                       HBitmap():AddFile( xImage ), xImage ) )
Return Self

METHOD Init() CLASS HSayBmp

   IF !::lInit
      Super:Init()
      SendMessage( ::handle,STM_SETIMAGE,IMAGE_BITMAP,::oImage:handle )
   ENDIF
Return Nil

//- HSayIcon

CLASS HSayIcon INHERIT HSayImage

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt )
   METHOD Redefine( oWndParent,nId,Image,lRes,bInit,bSize,ctoolt )
   METHOD Init()

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,Image,lRes,bInit, ;
                  bSize,ctoolt ) CLASS HSayIcon

   Super:New( oWndParent,nId,nLeft,nTop,nWidth,nHeight,bInit,bSize,ctoolt )

   ::style   += SS_ICON

   IF lRes == Nil ; lRes := .F. ; ENDIF
   ::oImage := Iif( lRes .OR. Valtype(Image)=="N",    ;
                       HIcon():AddResource( Image ),  ;
                       Iif( Valtype(Image) == "C",    ;
                       HIcon():AddFile( Image ), Image ) )
   ::Activate()

Return Self

METHOD Redefine( oWndParent,nId,xImage,lRes,bInit,bSize,ctoolt ) CLASS HSayIcon

   Super:Redefine( oWndParent,nId,bInit,bSize,ctoolt )

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
