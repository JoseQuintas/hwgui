/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTrackBar class
 *
 * Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
 * www - http://geocities.yahoo.com.br/marcosgambeta/
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define TBS_AUTOTICKS                1
#define TBS_VERT                     2
#define TBS_TOP                      4
#define TBS_LEFT                     4
#define TBS_BOTH                     8
#define TBS_NOTICKS                 16


CLASS HTrackBar INHERIT HControl

   CLASS VAR winclass   INIT "msctls_trackbar32"

   DATA nValue
   DATA bChange
   DATA bThumbDrag
   DATA nLow
   DATA nHigh
   DATA hCursor

   METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight,;
               bInit, bSize, bPaint, cTooltip, bChange, bDrag, nLow, nHigh,;
               lVertical, TickStyle, TickMarks )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Value( nValue ) SETGET
   METHOD GetNumTics()  INLINE hwg_Sendmessage( ::handle, TBM_GETNUMTICS, 0, 0 )

ENDCLASS

METHOD New( oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight,;
            bInit, bSize, bPaint, cTooltip, bChange, bDrag, nLow, nHigh,;
            lVertical, TickStyle, TickMarks ) CLASS HTrackBar

   IF TickStyle == NIL ; TickStyle := TBS_AUTOTICKS ; ENDIF
   IF TickMarks == NIL ; TickMarks := 0 ; ENDIF
   IF bPaint != NIL
      TickStyle := Hwg_BitOr( TickStyle, TBS_AUTOTICKS )
   ENDIF
   nstyle   := Hwg_BitOr( IIF( nStyle==NIL, 0, nStyle ), ;
                          WS_CHILD + WS_VISIBLE + WS_TABSTOP )
   nstyle   += IIF( lVertical != NIL .AND. lVertical, TBS_VERT, 0 )
   nstyle   += TickStyle + TickMarks

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight,,;
              bInit, bSize, bPaint, cTooltip )

   ::nValue     := IIF( Valtype(vari)=="N", vari, 0 )
   ::bChange    := bChange
   ::bThumbDrag := bDrag
   ::nLow       := IIF( nLow==NIL, 0, nLow )
   ::nHigh      := IIF( nHigh==NIL, 100, nHigh )

   HWG_InitCommonControlsEx()
   ::Activate()

RETURN Self

METHOD Activate CLASS HTrackBar
   IF !Empty( ::oParent:handle )
      ::handle := hwg_inittrackbar ( ::oParent:handle, ::id, ::style, ;
                                 ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                 ::nLow, ::nHigh )
      ::Init()
   ENDIF
RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HTrackBar
LOCAL aCoors

   IF msg == WM_PAINT
      IF ::bPaint != NIL
         Eval( ::bPaint, Self )
         RETURN 0
      ENDIF

   ELSEIF msg == WM_MOUSEMOVE
      IF ::hCursor != NIL
         Hwg_SetCursor( ::hCursor )
      ENDIF

   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != NIL
         aCoors := hwg_Getclientrect( ::handle )
         hwg_Fillrect( wParam, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, ;
                   aCoors[ 4 ] + 1, ::brush:handle )
         RETURN 1
      ENDIF

   ELSEIF msg == WM_DESTROY
      ::End()

   ELSEIF ::bOther != NIL
      RETURN Eval( ::bOther, Self, msg, wParam, lParam )

   ENDIF

RETURN -1

METHOD Init() CLASS HTrackBar

   IF !::lInit
      ::Super:Init()
      hwg_trackbarsetrange( ::handle, ::nLow, ::nHigh )
      hwg_Sendmessage( ::handle, TBM_SETPOS, 1, ::nValue )

      IF ::bPaint != NIL
         ::nHolder := 1
         hwg_Setwindowobject( ::handle, Self )
         Hwg_InitTrackProc( ::handle )
      ENDIF
   ENDIF

   RETURN NIL

METHOD Value( nValue ) CLASS HTrackBar

   IF nValue != Nil
      IF Valtype( nValue ) == "N"
         hwg_Sendmessage( ::handle, TBM_SETPOS, 1, nValue )
         ::nValue := nValue
      ENDIF
   ELSE
      ::nValue := hwg_Sendmessage( ::handle, TBM_GETPOS, 0, 0 )
   ENDIF

   RETURN ::nValue


#pragma BEGINDUMP


#define _WIN32_IE      0x0500
#define HB_OS_WIN_32_USED
#ifndef _WIN32_WINNT
   #define _WIN32_WINNT   0x0400
#endif

#include "guilib.h"
#include <windows.h>
#include <commctrl.h>

#include "hbapi.h"

HB_FUNC( HWG_INITTRACKBAR )
{
    HWND hTrackBar;

    hTrackBar = CreateWindow( TRACKBAR_CLASS,
                             0,
                             ( LONG )  hb_parnl( 3 ),
                                       hb_parni( 4 ),
                                       hb_parni( 5 ),
                                       hb_parni( 6 ),
                                       hb_parni( 7 ),
                             ( HWND )  HB_PARHANDLE(1),
                             ( HMENU ) hb_parni( 2 ),
                             GetModuleHandle( NULL ),
                             NULL ) ;

    HB_RETHANDLE( hTrackBar );
}

HB_FUNC( HWG_TRACKBARSETRANGE )
{
    SendMessage( (HWND) HB_PARHANDLE(1), TBM_SETRANGE, TRUE,
                  MAKELONG( hb_parni( 2 ), hb_parni( 3 ) ) );
}

#pragma ENDDUMP

