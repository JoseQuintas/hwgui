/*
 * $Id: htrackbr.prg,v 1.9 2005-10-26 07:43:26 omm Exp $
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

   DATA value
   DATA bChange
   DATA bThumbDrag
   DATA nLow
   DATA nHigh
   DATA hCursor

   METHOD New( oWndParent,nId,vari,nStyle,nLeft,nTop,nWidth,nHeight,;
               bInit,bSize,bPaint,cTooltip,bChange,bDrag,nLow,nHigh,lVertical,TickStyle,TickMarks )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD SetValue( nValue )
   METHOD GetValue()

ENDCLASS

METHOD New( oWndParent,nId,vari,nStyle,nLeft,nTop,nWidth,nHeight,;
            bInit,bSize,bPaint,cTooltip,bChange,bDrag,nLow,nHigh,lVertical,TickStyle,TickMarks ) CLASS HTrackBar

   IF TickStyle == Nil ; TickStyle := TBS_AUTOTICKS ; ENDIF
   IF TickMarks == Nil ; TickMarks := 0 ; ENDIF
   IF bPaint != Nil
      TickStyle := Hwg_BitOr( TickStyle,TBS_AUTOTICKS )
   ENDIF
   nstyle   := Hwg_BitOr( Iif( nStyle==Nil, 0, nStyle ), WS_CHILD+WS_VISIBLE+WS_TABSTOP )
   nstyle   += Iif( lVertical != Nil .AND. lVertical, TBS_VERT, 0 )
   nstyle   += TickStyle + TickMarks
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,,bInit,bSize,bPaint,ctooltip )
   ::value   := Iif( Valtype(vari)=="N", vari, 0 )
   ::bChange := bChange
   ::bThumbDrag := bDrag
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

METHOD onEvent( msg, wParam, lParam ) CLASS HTrackBar
Local aCoors

   IF msg == WM_PAINT
      IF ::bPaint != Nil
         Eval( ::bPaint, Self )
         Return 0
      ENDIF
   ELSEIF msg == WM_MOUSEMOVE
      IF ::hCursor != Nil
         Hwg_SetCursor( ::hCursor )
      ENDIF
   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != Nil
         aCoors := GetClientRect( ::handle )
         FillRect( wParam, aCoors[1], aCoors[2], aCoors[3]+1, aCoors[4]+1, ::brush:handle )
         Return 1
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ELSEIF ::bOther != Nil
      Return Eval( ::bOther, Self, msg, wParam, lParam )
   ENDIF

Return -1

METHOD Init() CLASS HTrackBar
   IF !::lInit
      Super:Init()
      TrackBarSetRange( ::handle, ::nLow, ::nHigh )
      SendMessage( ::handle, TBM_SETPOS, 1, ::value )
      IF ::bPaint != Nil
         SetWindowObject( ::handle,Self )
         Hwg_InitTrackProc( ::handle )
      ENDIF
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


#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"


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

