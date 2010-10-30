/*
 * $Id: hanimat.prg,v 1.12 2010-10-30 16:43:31 mlacecilia Exp $
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
   METHOD End() INLINE ::Destroy()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cFilename, lAutoPlay, lCenter, lTransparent, xResID ) CLASS HAnimation

   nStyle     := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE )
   nStyle     := nStyle + IIf( lAutoPlay == Nil.OR.lAutoPlay, ACS_AUTOPLAY, 0 )
   nStyle     := nStyle + IIf( lCenter == Nil.OR. ! lCenter, 0, ACS_CENTER )
   nStyle     := nStyle + IIf( lTransparent == Nil.OR. ! lTransparent, 0, ACS_TRANSPARENT )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight )
   ::xResID    := xResID
   ::cFilename := cFilename
   ::brush     := ::oParent:brush
   ::bColor    := ::oParent:bColor
   HWG_InitCommonControlsEx()
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HAnimation
   IF ! Empty( ::oParent:handle )
      ::handle := Animate_Create( ::oParent:handle, ::id, ::style, ;
                                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HAnimation
   IF ! ::lInit
      Super:Init()
      IF ::xResID != Nil
         Animate_OpenEx( ::handle, GetResources(), ::xResID )
      ELSEIF ::cFileName <> Nil
         Animate_Open( ::handle, ::cFileName )
      ENDIF
   ENDIF
   RETURN Nil

METHOD Open( cFileName ) CLASS HAnimation
   IF cFileName <> Nil
      ::cFileName := cFileName
      Animate_Open( ::handle, ::cFileName )
   ENDIF
   RETURN Nil

METHOD Play( nFrom, nTo, nRep ) CLASS HAnimation
   nFrom := IIf( nFrom == Nil,  0, nFrom )
   nTo   := IIf( nTo   == Nil, - 1, nTo   )
   nRep  := IIf( nRep  == Nil, - 1, nRep  )
   Animate_Play( ::handle, nFrom, nTo, nRep )
   RETURN Self

METHOD Seek( nFrame ) CLASS HAnimation
   nFrame := IIf( nFrame == Nil, 0, nFrame )
   Animate_Seek( ::handle, nFrame )
   RETURN Self

METHOD Stop() CLASS HAnimation
   Animate_Stop( ::handle )
   RETURN Self

METHOD Close() CLASS HAnimation
   Animate_Close( ::handle )
   RETURN Nil

METHOD Destroy() CLASS HAnimation
   Animate_Destroy( ::handle )
   RETURN Nil