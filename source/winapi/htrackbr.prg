/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTrackBar class
 *
 * Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
 * www - http://geocities.yahoo.com.br/marcosgambeta/
 *
 * HTrack class
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
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

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0x000000


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

METHOD Activate() CLASS HTrackBar
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


CLASS HTrack INHERIT HControl

CLASS VAR winclass INIT "STATIC"

   DATA lVertical
   DATA oStyleBar, oStyleSlider
   DATA lAxis    INIT .T.
   DATA nFrom, nTo, nCurr, nSize
   DATA oPen1, oPen2, tColor2
   DATA lCaptured   INIT .F.
   DATA bEndDrag
   DATA bChange

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
               bSize, bPaint, color, bcolor, nSize, oStyleBar, oStyleSlider, lAxis )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Drag( xPos, yPos )
   METHOD Move( x1, y1, width, height )
   METHOD Value ( xValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
            bSize, bPaint, color, bcolor, nSize, oStyleBar, oStyleSlider, lAxis ) CLASS HTrack

   color := Iif( color == Nil, CLR_BLACK, color )
   bColor := Iif( bColor == Nil, CLR_WHITE, bColor )
   ::Super:New( oWndParent, nId, WS_CHILD + WS_VISIBLE + SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight,,, ;
              bSize, bPaint,, color, bcolor )

   ::title  := ""
   ::lVertical := ( ::nHeight > ::nWidth )
   ::nSize := Iif( nSize == Nil, 12, nSize )
   ::nFrom  := Int(::nSize/2)
   ::nTo    := Iif( ::lVertical, ::nHeight-1-Int(::nSize/2), ::nWidth-1-Int(::nSize/2) )
   ::nCurr  := ::nFrom
   ::oStyleBar := oStyleBar
   ::oStyleSlider := oStyleSlider
   ::lAxis := ( lAxis == Nil .OR. lAxis )
   ::oPen1 := HPen():Add( PS_SOLID, 1, color )

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HTrack
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HTrack

   HB_SYMBOL_UNUSED( wParam )

   IF msg == WM_MOUSEMOVE
      IF ::lCaptured
         ::Drag( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF

   ELSEIF msg == WM_PAINT
      ::Paint()

   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != Nil
         hwg_Fillrect( wParam, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
         RETURN 1
      ENDIF

   ELSEIF msg == WM_LBUTTONDOWN
      ::lCaptured := .T.
      hwg_Setcapture( ::handle )
      ::Drag( hwg_Loword( lParam ), hwg_Hiword( lParam ) )

   ELSEIF msg == WM_LBUTTONUP
      ::lCaptured := .F.
      hwg_Releasecapture()
      IF ::bEndDrag != Nil
         Eval( ::bEndDrag, Self )
      ENDIF
      hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )

   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1

METHOD Init() CLASS HTrack

   IF ! ::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
#ifndef __GTK__
      ::nHolder := 1
      Hwg_InitWinCtrl( ::handle )
#endif
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HTrack

   LOCAL nHalf, nw, x1, y1
   LOCAL pps := hwg_Definepaintstru()
   LOCAL hDC := hwg_Beginpaint( ::handle, pps )

   IF ::tColor2 != Nil .AND. ::oPen2 == Nil
      ::oPen2 := HPen():Add( PS_SOLID, 1, ::tColor2 )
   ENDIF

   IF ::bPaint != Nil
      Eval( ::bPaint, Self, hDC )
   ELSE

      IF ::oStyleBar == Nil
         hwg_Fillrect( hDC, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
      ELSE
         ::oStyleBar:Draw( hDC, 0, 0, ::nWidth, ::nHeight )
      ENDIF

      nHalf := Int(::nSize/2)
      hwg_Selectobject( hDC, ::oPen1:handle )
      IF ::lVertical
         x1 := Int(::nWidth/2)
         nw := Min( nHalf, x1 - 2 )
         IF ::lAxis .AND. ::nCurr - nHalf > ::nFrom
            hwg_Drawline( hDC, x1, ::nFrom, x1, ::nCurr-nHalf )
         ENDIF
         IF ::oStyleSlider == Nil
            hwg_Rectangle( hDC, x1-nw, ::nCurr+nHalf, x1+nw, ::nCurr-nHalf )
         ELSE
            ::oStyleSlider:Draw( hDC, x1-nw, ::nCurr-nHalf, x1+nw, ::nCurr+nHalf )
         ENDIF
         IF ::lAxis .AND. ::nCurr + nHalf < ::nTo
            IF ::oPen2 != Nil
               hwg_Selectobject( hDC, ::oPen2:handle )
            ENDIF
            hwg_Drawline( hDC, x1, ::nCurr+nHalf+1, x1, ::nTo )
         ENDIF
      ELSE
         y1 := Int(::nHeight/2)
         nw := Min( nHalf, x1 - 2 )
         IF ::lAxis .AND. ::nCurr - nHalf > ::nFrom
            hwg_Drawline( hDC, ::nFrom, y1, ::nCurr-nHalf, y1 )
         ENDIF
         IF ::oStyleSlider == Nil
            hwg_Rectangle( hDC, ::nCurr-nHalf, y1-nw, ::nCurr+nHalf, y1+nw )
         ELSE
            ::oStyleSlider:Draw( hDC, ::nCurr-nHalf, y1-nw, ::nCurr+nHalf, y1+nw )
         ENDIF
         IF ::lAxis .AND. ::nCurr + nHalf < ::nTo
            IF ::oPen2 != Nil
               hwg_Selectobject( hDC, ::oPen2:handle )
            ENDIF
            hwg_Drawline( hDC, ::nCurr+nHalf+1, y1, ::nTo, y1 )
         ENDIF
      ENDIF
   ENDIF
   hwg_Endpaint( ::handle, pps )

   RETURN Nil

METHOD Drag( xPos, yPos ) CLASS HTrack

   LOCAL nCurr := ::nCurr
   LOCAL nHalf := Int(::nSize/2), x1, y1

   //hwg_writelog( str(xPos) + str(yPos)  )
   IF ::lVertical
      x1 := Int(::nWidth/2)
      IF yPos > 32000
         yPos -= 65535
      ENDIF
      ::nCurr := Min( Max( ::nFrom, yPos ), ::nTo )
   ELSE
      y1 := Int(::nHeight/2)
      IF xPos > 32000
         xPos -= 65535
      ENDIF
      ::nCurr := Min( Max( ::nFrom, xPos ), ::nTo )
   ENDIF
   hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   IF nCurr != ::nCurr .AND. ::bChange != Nil
      Eval( ::bChange, Self, ::Value )
   ENDIF

   RETURN Nil

METHOD Move( x1, y1, width, height ) CLASS HTrack

   LOCAL xValue := (::nCurr - ::nFrom) / (::nTo - ::nFrom)

   IF ::lVertical .AND. !Empty( height ) .AND. height != ::nHeight
      ::nFrom  := Int(::nSize/2)
      ::nTo    := height-1-Int(::nSize/2)
      ::nCurr  := xValue * (::nTo - ::nFrom) + ::nFrom
   ELSEIF !::lVertical .AND. !Empty( width ) .AND. width != ::nWidth
      ::nFrom  := Int(::nSize/2)
      ::nTo    := width-1-Int(::nSize/2)
      ::nCurr  := xValue * (::nTo - ::nFrom) + ::nFrom
   ENDIF

   ::Super:Move( x1, y1, width, height )

   RETURN Nil

METHOD Value( xValue ) CLASS HTrack

   IF xValue != Nil
      xValue := Iif( xValue < 0, 0, Iif( xValue > 1, 1, xValue ) )
      ::nCurr := xValue * (::nTo - ::nFrom) + ::nFrom
      hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ELSE
      xValue := (::nCurr - ::nFrom) / (::nTo - ::nFrom)
   ENDIF

   RETURN xValue


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
                             ( HMENU )( UINT_PTR ) hb_parni( 2 ),
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

* ========================== EOF of htrackbr.prg =============================
