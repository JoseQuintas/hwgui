/*
 * $Id: hanimat.prg,v 1.8 2008-06-20 23:43:00 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HAnimation class
 *
 * Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
 * www - http://geocities.yahoo.com.br/marcosgambeta/
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HAnimation INHERIT HControl

   CLASS VAR winclass   INIT "SysAnimate32"

   DATA cFileName
   DATA xResID

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cFilename, lAutoPlay, lCenter, lTransparent, xResID )
   METHOD Activate()
   METHOD Init()
   METHOD Open( cFileName )
   METHOD Play( nFrom, nTo, nRep )
   METHOD Seek( nFrame )
   METHOD Stop()
   METHOD Close()
   METHOD Destroy()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cFilename, lAutoPlay, lCenter, lTransparent, xResID ) CLASS HAnimation

   nStyle     := Hwg_BitOr( Iif( nStyle==Nil, 0, nStyle ), WS_CHILD+WS_VISIBLE )
   nStyle     := nStyle + Iif( lAutoplay==Nil.OR.lAutoPlay, ACS_AUTOPLAY, 0 )
   nStyle     := nStyle + Iif( lCenter==Nil.OR.!lCenter, 0, ACS_CENTER )
   nStyle     := nStyle + Iif( lTransparent==Nil.OR.!lTransparent, 0, ACS_TRANSPARENT )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight )
   ::xResID    := xResID
   ::cFileName := cFilename

   HWG_InitCommonControlsEx()
   ::Activate()

Return Self

METHOD Activate CLASS HAnimation
   IF !empty( ::oParent:handle ) 
      ::handle := Animate_Create( ::oParent:handle, ::id, ::style, ;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   EndIf
Return Nil

METHOD Init() CLASS HAnimation
   If !::lInit
      Super:Init()
      IF ::xResID != Nil
         Animate_OpenEx( ::handle, GetResources(), ::xResID)
      ELSEIF ::cFileName <> Nil
         Animate_Open( ::handle, ::cFileName )
      EndIf
   EndIf
Return Nil

METHOD Open( cFileName ) CLASS HAnimation
   If cFileName <> Nil
      ::cFileName := cFileName
      Animate_Open( ::handle, ::cFileName )
   EndIf
Return Nil

METHOD Play( nFrom, nTo, nRep ) CLASS HAnimation
   nFrom := Iif( nFrom == Nil,  0, nFrom )
   nTo   := Iif( nTo   == Nil, -1, nTo   )
   nRep  := Iif( nRep  == Nil, -1, nRep  )
   Animate_Play( ::handle, nFrom, nTo, nRep )
Return self

METHOD Seek( nFrame ) CLASS HAnimation
   nFrame := Iif( nFrame == Nil, 0, nFrame )
   Animate_Seek( ::handle, nFrame )
Return self

METHOD Stop() CLASS HAnimation
   Animate_Stop( ::handle )
Return self

METHOD Close() CLASS HAnimation
   Animate_Close( ::handle )
Return Nil

METHOD Destroy() CLASS HAnimation
   Animate_Destroy( ::handle )
Return Nil