/*
 * HWGUI - Harbour Win32 GUI library source code:
 * HTrackBar class
 *
 * Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
 * www - http://geocities.yahoo.com.br/marcosgambeta/
*/

#include "windows.ch"
#include "HBClass.ch"
#include "guilib.ch"

#define TBS_AUTOTICKS                1
#define TBS_VERT                     2
#define TBS_TOP                      4
#define TBS_LEFT                     4
#define TBS_BOTH                     8
#define TBS_NOTICKS                 16

#define TBM_GETPOS              (WM_USER)
#define TBM_SETPOS              (WM_USER+5)

CLASS HTrackBar INHERIT HControl

   CLASS VAR winclass   INIT "msctls_trackbar32"

   DATA value
   DATA bChange
   DATA nLow
   DATA nHigh

   METHOD New( oWndParent,nId,vari,nStyle,nLeft,nTop,nWidth,nHeight,;
               bInit,cTooltip,bChange,nLow,nHigh,lVertical,lAutoTicks,;
               lNoTicks,lBoth,lTop,lLeft)
   METHOD Activate()
   METHOD Init()
   METHOD SetValue( nValue )
   METHOD GetValue()

ENDCLASS

METHOD New( oWndParent,nId,vari,nStyle,nLeft,nTop,nWidth,nHeight,;
            bInit,cTooltip,bChange,nLow,nHigh,lVertical,lAutoTicks,;
            lNoTicks,lBoth,lTop,lLeft ) CLASS HTrackBar

   nstyle   := Hwg_BitOr( Iif( nStyle==Nil, 0, nStyle ), WS_CHILD+WS_VISIBLE+WS_TABSTOP )
   nstyle   += Iif( lVertical , TBS_VERT     , 0 )
   nstyle   += Iif( lAutoTicks, TBS_AUTOTICKS, 0 )
   nstyle   += Iif( lNoTicks  , TBS_NOTICKS  , 0 )
   nstyle   += Iif( lBoth     , TBS_BOTH     , 0 )
   nstyle   += Iif( lTop      , TBS_TOP      , 0 )
   nstyle   += Iif( lLeft     , TBS_LEFT     , 0 )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,,bInit,,,ctooltip )
   ::value   := Iif( Valtype(vari)=="N", vari, 0 )
   ::bChange := bChange
   ::nLow    := Iif( nLow==Nil, 0, nLow )
   ::nHigh   := Iif( nHigh==Nil, 100, nHigh )

   HWG_InitCommonControlsEx()
   ::Activate()

Return Self

METHOD Activate CLASS HTrackBar
   IF ::oParent:handle != 0
      ::handle := InitTrackBar ( ::oParent:handle, ::id, ::style, ;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight, ::nLow, ::nHigh )
      ::Init()
   ENDIF
Return Nil

METHOD Init() CLASS HTrackBar
   IF !::lInit
      Super:Init()
      TrackBarSetRange( ::handle, ::nLow, ::nHigh )
      SendMessage( ::handle, TBM_SETPOS, 1, ::value )
   ENDIF
Return Nil

METHOD SetValue( nValue ) CLASS HTrackBar
   IF Valtype(nValue)=="N"
      SendMessage( ::handle, TBM_SETPOS, 1, nValue )
      ::value := nValue
   ENDIF
Return Nil

METHOD GetValue() CLASS HTrackBar
   ::value := SendMessage( ::handle, TBM_GETPOS, 0, 0 )
Return (::value)

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


#include <hbapi.h>

HB_FUNC ( INITTRACKBAR )
{
	HWND hTrackBar;

	hTrackBar = CreateWindow( TRACKBAR_CLASS,
                             0,
                             (LONG) hb_parnl(3),
                             hb_parni(4),
                             hb_parni(5),
                             hb_parni(6),
                             hb_parni(7),
                             (HWND) hb_parnl(1),
                             (HMENU) hb_parni(2),
                             GetModuleHandle(NULL),
                             NULL ) ;

	hb_retnl ( (LONG) hTrackBar );
}

HB_FUNC ( TRACKBARSETRANGE )
{
	SendMessage( (HWND) hb_parnl(1), TBM_SETRANGE, TRUE, MAKELONG(hb_parni(2),hb_parni(3)) );
}

#pragma ENDDUMP

