/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HSplitter class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "gtk.ch"

CLASS HSplitter INHERIT HControl

   CLASS VAR winclass INIT "STATIC"

   DATA aLeft
   DATA aRight
   DATA lVertical
   DATA nFrom, nTo
   DATA hCursor
   DATA lCaptured INIT .F.
   DATA lMoved INIT .F.
   DATA bEndDrag

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      bSize, bPaint, color, bcolor, aLeft, aRight, nFrom, nTo )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Move( x1,y1,width,height )
   METHOD Drag( xPos, yPos )
   METHOD DragAll()

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      bSize, bDraw, color, bcolor, aLeft, aRight, nFrom, nTo ) CLASS HSplitter

   ::Super:New( oWndParent, nId, WS_CHILD + WS_VISIBLE + SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, , , ;
              bSize, bDraw,, Iif(color==Nil,0,color), bcolor )

   ::title  := ""
   ::aLeft  := Iif( aLeft == Nil, {}, aLeft )
   ::aRight := Iif( aRight == Nil, {}, aRight )
   ::lVertical := ( ::nHeight > ::nWidth )
   ::nFrom := nFrom
   ::nTo   := nTo

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HSplitter

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createsplitter( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSplitter

   HB_SYMBOL_UNUSED( wParam )

   IF msg == WM_MOUSEMOVE
      IF ::hCursor == Nil
         ::hCursor := hwg_Loadcursor( GDK_SIZING )
      ENDIF
      Hwg_SetCursor( ::hCursor, ::handle )
      IF ::lCaptured
         ::Drag( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF
   ELSEIF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_LBUTTONDOWN
      Hwg_SetCursor( ::hCursor, ::handle )
      ::lCaptured := .T.
   ELSEIF msg == WM_LBUTTONUP
      ::DragAll()
      ::lCaptured := .F.
      IF ::bEndDrag != Nil
         Eval( ::bEndDrag, Self )
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

   Return - 1

METHOD Init CLASS HSplitter

   IF !::lInit
      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HSplitter
   LOCAL hDC

   IF ::bPaint != Nil
      Eval( ::bPaint, Self )
   ELSE
      hDC := hwg_Getdc( ::handle )
      hwg_Drawbutton( hDC, 0, 0, ::nWidth - 1, ::nHeight - 1, 6 )
      hwg_Releasedc( ::handle, hDC )
   ENDIF

   RETURN Nil

METHOD Move( x1,y1,width,height )  CLASS HSplitter

   ::Super:Move( x1,y1,width,height,.T. )
Return Nil

METHOD Drag( xPos, yPos ) CLASS HSplitter
   LOCAL nFrom, nTo

   nFrom := Iif( ::nFrom == Nil, 1, ::nFrom )
   nTo := Iif( ::nTo == Nil, Iif(::lVertical,::oParent:nWidth-1,::oParent:nHeight-1), ::nTo )
   IF ::lVertical
      IF xPos > 32000
         xPos -= 65535
      ENDIF
      IF ( xPos := ( ::nLeft + xPos ) ) >= nFrom .AND. xPos <= nTo
         ::nLeft := xPos
      ENDIF
   ELSE
      IF yPos > 32000
         yPos -= 65535
      ENDIF
      IF ( yPos := ( ::nTop + yPos ) ) >= nFrom .AND. yPos <= nTo
         ::nTop := yPos
      ENDIF
   ENDIF
   hwg_MoveWidget( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight, .T. )
   ::lMoved := .T.

   RETURN Nil

METHOD DragAll() CLASS HSplitter
Local i, oCtrl, nDiff

   FOR i := 1 TO Len( ::aRight )
      oCtrl := ::aRight[i]
      IF ::lVertical
         nDiff := ::nLeft+::nWidth - oCtrl:nLeft
         oCtrl:Move( oCtrl:nLeft+nDiff,,oCtrl:nWidth-nDiff )
      ELSE
         nDiff := ::nTop+::nHeight - oCtrl:nTop
         oCtrl:Move( ,oCtrl:nTop+nDiff,,oCtrl:nHeight-nDiff )
      ENDIF   
   NEXT
   FOR i := 1 TO Len( ::aLeft )
      oCtrl := ::aLeft[i]
      IF ::lVertical
         nDiff := ::nLeft - ( oCtrl:nLeft + oCtrl:nWidth )
         oCtrl:Move( ,,oCtrl:nWidth+nDiff )
      ELSE
         nDiff := ::nTop - ( oCtrl:nTop + oCtrl:nHeight )
         oCtrl:Move( ,,,oCtrl:nHeight+nDiff )
      ENDIF
   NEXT
   ::lMoved := .F.

   RETURN Nil
