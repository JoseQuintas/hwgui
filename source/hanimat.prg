/*
 * $Id: hanimat.prg,v 1.4 2004-09-29 05:24:52 alkresin Exp $
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

#define ACS_CENTER              1
#define ACS_TRANSPARENT         2
#define ACS_AUTOPLAY            4

CLASS HAnimation INHERIT HControl

   CLASS VAR winclass   INIT "SysAnimate32"

   DATA cFileName

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cFilename, lAutoPlay, lCenter, lTransparent )
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
            cFilename, lAutoPlay, lCenter, lTransparent ) CLASS HAnimation

   nStyle     := Hwg_BitOr( Iif( nStyle==Nil, 0, nStyle ), WS_CHILD+WS_VISIBLE )
   nStyle     := nStyle + Iif( lAutoplay==Nil.OR.lAutoPlay, ACS_AUTOPLAY, 0 )
   nStyle     := nStyle + Iif( lCenter==Nil.OR.!lCenter, 0, ACS_CENTER )
   nStyle     := nStyle + Iif( lTransparent==Nil.OR.!lTransparent, 0, ACS_TRANSPARENT )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight )
   ::cFileName := cFilename

   HWG_InitCommonControlsEx()
   ::Activate()

Return Self

METHOD Activate CLASS HAnimation
   If ::oParent:handle != 0
      ::handle := Animate_Create ( ::oParent:handle, ::id, ::style, ;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   EndIf
Return Nil

METHOD Init() CLASS HAnimation
   If !::lInit
      Super:Init()
      If ::cFileName <> Nil
         Animate_Open ( ::handle, ::cFileName )
      EndIf
   EndIf
Return Nil

METHOD Open( cFileName ) CLASS HAnimation
   If cFileName <> Nil
      ::cFileName := cFileName
      Animate_Open ( ::handle, ::cFileName )
   EndIf
Return Nil

METHOD Play( nFrom, nTo, nRep ) CLASS HAnimation
   nFrom := Iif( nFrom == Nil,  0, nFrom )
   nTo   := Iif( nTo   == Nil, -1, nTo   )
   nRep  := Iif( nRep  == Nil, -1, nRep  )
   Animate_Play ( ::handle, nFrom, nTo, nRep )
Return Nil

METHOD Seek( nFrame ) CLASS HAnimation
   nFrame := Iif( nFrame == Nil, 0, nFrame )
   Animate_Seek ( ::handle, nFrame )
Return Nil

METHOD Stop() CLASS HAnimation
   Animate_Stop ( ::handle )
Return Nil

METHOD Close() CLASS HAnimation
   Animate_Close ( ::handle )
Return Nil

METHOD Destroy() CLASS HAnimation
   Animate_Destroy ( ::handle )
Return Nil

#pragma BEGINDUMP

#define _WIN32_IE      0x0500
#define HB_OS_WIN_32_USED
#define _WIN32_WINNT   0x0400

#include <windows.h>
#include <commctrl.h>
#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"

HB_FUNC ( ANIMATE_CREATE )
{
	HWND hwnd;

	hwnd = Animate_Create( (HWND) hb_parnl(1), (LONG) hb_parnl(2), (LONG) hb_parnl(3), GetModuleHandle(NULL) );
   MoveWindow( hwnd, hb_parnl(4), hb_parnl(5), hb_parnl(6), hb_parnl(7), TRUE );
	hb_retnl ( (LONG) hwnd );
}

HB_FUNC ( ANIMATE_OPEN )
{
  Animate_Open( (HWND) hb_parnl(1), hb_parc(2) );
}

HB_FUNC ( ANIMATE_PLAY )
{
  Animate_Play( (HWND) hb_parnl(1), hb_parni(2), hb_parni(3), hb_parni(4) );
}

HB_FUNC ( ANIMATE_SEEK )
{
  Animate_Seek( (HWND) hb_parnl(1), hb_parni(2) );
}

HB_FUNC ( ANIMATE_STOP )
{
  Animate_Stop( (HWND) hb_parnl(1) );
}

HB_FUNC ( ANIMATE_CLOSE )
{
  Animate_Close( (HWND) hb_parnl(1) );
}

HB_FUNC ( ANIMATE_DESTROY )
{
  DestroyWindow( (HWND) hb_parnl(1) );
}

#pragma ENDDUMP

