/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HTrack class - Substitute for WinAPI HTRACKBAR
 *
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * 
 * Copyright 2021 DF7BE
*/

#include "gtk.ch"
#include "hwgui.ch"
#include "hbclass.ch"

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0x000000

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
               bSize, bPaint, color, bcolor, nSize, oStyle )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Drag( xPos, yPos )
   METHOD Value ( xValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
            bSize, bPaint, color, bcolor, nSize, oStyle ) CLASS HTrack

   color := Iif( color == Nil, CLR_BLACK, color )
   bColor := Iif( bColor == Nil, CLR_WHITE, bColor )
   ::Super:New( oWndParent, nId, WS_CHILD + WS_VISIBLE + SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight,,, ;
              bSize, bPaint,, color, bcolor )

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
      ::handle := hwg_Createsplitter( ::oParent:handle, ::id, ;
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
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HTrack

   LOCAL nHalf, x1, y1
   LOCAL hDC := hwg_Getdc( ::handle )

   IF ::tColor2 != Nil .AND. ::oPen2 == Nil
      ::oPen2 := HPen():Add( PS_SOLID, 1, ::tColor2 )
   ENDIF

   IF ::bPaint != Nil
      Eval( ::bPaint, Self, hDC )
   ELSE

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
         y1 := Int(::nHeight/2)
         IF ::nCurr - nHalf > ::nFrom
            hwg_Drawline( hDC, ::nFrom, y1, ::nCurr-nHalf, y1 )
         ENDIF
         hwg_Rectangle( hDC, ::nCurr-nHalf, y1-nHalf, ::nCurr+nHalf, y1+nHalf )
         IF ::nCurr + nHalf < ::nTo
            IF ::oPen2 != Nil
               hwg_Selectobject( hDC, ::oPen2:handle )
            ENDIF
            hwg_Drawline( hDC, ::nCurr+nHalf+1, y1, ::nTo, y1 )
         ENDIF
      ENDIF
   ENDIF

   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD Drag( xPos, yPos ) CLASS HTrack

   LOCAL nCurr := ::nCurr

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
      hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ELSE
      xValue := (::nCurr - ::nFrom) / (::nTo - ::nFrom)
   ENDIF

   RETURN xValue  

* ================== EOF of htrackbr.prg =======================