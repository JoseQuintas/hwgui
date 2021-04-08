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
   DATA oStyle
   DATA nFrom, nTo, nCurr, nSize
   DATA oPen1, oPen2, tColor2
   DATA lCaptured   INIT .F.
   DATA bEndDrag
   DATA bChange


   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
               bSize, bDraw, color, bcolor, nSize, oStyle )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Drag( xPos, yPos )
   METHOD Value ( xValue ) SETGET

ENDCLASS

  METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
               bSize, bDraw, color, bcolor, nSize, oStyle ) CLASS HTrack

   color := Iif( color == Nil, CLR_BLACK, color )
   bColor := Iif( bColor == Nil, CLR_WHITE, bColor )
   ::Super:New( oWndParent, nId, WS_CHILD + WS_VISIBLE + SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight,,, ;
              bSize, bDraw,, color, bcolor )

   ::title  := ""
   ::lVertical := ( ::nHeight > ::nWidth )
   ::nSize := Iif( nSize == Nil, 12, nSize )
   ::nFrom  := Iif( ::lVertical, ::nHeight-1-Int(::nSize/2), Int(::nSize/2) )
   ::nTo    := Iif( ::lVertical, Int(::nSize/2), ::nWidth-1-Int(::nSize/2) )
   ::nCurr  := ::nFrom
   ::oStyle := oStyle
   ::oPen1 := HPen():Add( PS_SOLID, 1, color )

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HTrack
   IF ! Empty( ::oParent:handle )
#ifdef __GTK__
      ::handle := hwg_Createsplitter( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
#else
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
#endif
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
      ::Drag( hwg_Loword( lParam ), hwg_Hiword( lParam ) )

   ELSEIF msg == WM_LBUTTONUP
      ::lCaptured := .F.
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
   LOCAL hDC, nHalf, x1, y1
#ifndef __GTK__
   LOCAL pps
#endif
   IF ::bPaint != Nil
      Eval( ::bPaint, Self )
   ELSE
#ifdef __GTK__
      hDC := hwg_Getdc( ::handle )
#else
      pps := hwg_Definepaintstru()
      hDC := hwg_Beginpaint( ::handle, pps )
#endif

      IF ::tColor2 != Nil .AND. ::oPen2 == Nil
         ::oPen2 := HPen():Add( PS_SOLID, 1, ::tColor2 )
      ENDIF
      IF ::oStyle == Nil
         hwg_Fillrect( hDC, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
      ELSE
         ::oStyle:Draw( hDC, 0, 0, ::nWidth, ::nHeight )
      ENDIF

      nHalf := Int(::nSize/2)
      hwg_Selectobject( hDC, ::oPen1:handle )
      IF ::lVertical
         x1 := Int(::nWidth/2)
         IF ::nCurr + nHalf < ::nFrom
            hwg_Drawline( hDC, x1, ::nTo, x1, ::nCurr+nHalf )
         ENDIF
         hwg_Rectangle( hDC, x1-nHalf, ::nCurr+nHalf, x1+nHalf, ::nCurr-nHalf )
         IF ::nCurr - nHalf > ::nTo
            IF ::oPen2 != Nil
               hwg_Selectobject( hDC, ::oPen2:handle )
            ENDIF
            hwg_Drawline( hDC, x1, ::nCurr-nHalf, x1, ::nTo )
         ENDIF
      ELSE
         y1 :=Int(::nHeight/2)
         IF ::nCurr - nHalf > ::nFrom
            hwg_Drawline( hDC, ::nFrom, y1, ::nCurr-nHalf, y1 )
         ENDIF
         hwg_Rectangle( hDC, ::nCurr-nHalf, y1-nHalf, ::nCurr+nHalf, y1+nHalf )
         //hwg_Ellipse( hDC, ::nCurr-nHalf, y1-nHalf, ::nCurr+nHalf, y1+nHalf )
         IF ::nCurr + nHalf < ::nTo
            IF ::oPen2 != Nil
               hwg_Selectobject( hDC, ::oPen2:handle )
            ENDIF
            hwg_Drawline( hDC, ::nCurr+nHalf+1, y1, ::nTo, y1 )
         ENDIF
      ENDIF

#ifdef __GTK__
      hwg_Releasedc( ::handle, hDC )
#else
      hwg_Endpaint( ::handle, pps )
#endif
   ENDIF

   RETURN Nil

   
METHOD Drag( xPos, yPos ) CLASS HTrack
   LOCAL nCurr := ::nCurr
   
    // UNUSED: LOCAL nFrom, nTo


   // Fires warning
   // nFrom := Iif( ::nFrom == Nil, 1, ::nFrom )
 
/* 
     IF  ::nFrom == Nil
      nFrom := 1
     ELSE
      nFrom := ::nFrom
     ENDIF
*/ 
    // Fires warning 
    // nTo := Iif( ::nTo == Nil, Iif(::lVertical,::oParent:nWidth-1,::oParent:nHeight-1), ::nTo )

/*
    IF ::nTo == Nil
 
      IF ::lVertical
        nTo := ::oParent:nWidth-1  
      ELSE
        nTo := ::oParent:nHeight-1
      ENDIF

    ELSE
     nTo := ::nTo
    ENDIF
  
*/
  
   IF ::lVertical
      ::nCurr := Min( Max( ::nTo, yPos ), ::nFrom )
   ELSE
      ::nCurr := Min( Max( ::nFrom, xPos ), ::nTo )
   ENDIF
   hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   IF nCurr != ::nCurr .AND. ::bChange != Nil
      Eval( ::bChange, Self, ::Value )
   ENDIF

   RETURN Nil

METHOD Value( xValue ) CLASS HTrack

   IF xValue != Nil .AND. xValue >= 0 .AND. xValue <= 1
      ::nCurr := xValue * Abs(::nTo - ::nFrom) + Iif( ::lVertical, -::nFrom, ::nFrom )
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
