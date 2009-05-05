/*
 * $Id: hsplit.prg,v 1.1 2009-05-05 09:31:48 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HSplitter class
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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
   DATA hCursor
   DATA lCaptured INIT .F.
   DATA lMoved INIT .F.
   DATA bEndDrag

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight, ;
                  bSize,bPaint,color,bcolor,aLeft,aRight )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint( lpdis )
   METHOD Move( x1,y1,width,height )
   METHOD Drag( lParam )
   METHOD DragAll()

ENDCLASS

METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight, ;
                  bSize,bDraw,color,bcolor,aLeft,aRight ) CLASS HSplitter

   Super:New( oWndParent,nId,WS_CHILD+WS_VISIBLE+SS_OWNERDRAW,nLeft,nTop,nWidth,nHeight,,, ;
                  bSize,bDraw,,color,bcolor )

   ::title   := ""
   ::aLeft   := Iif( aLeft==Nil, {}, aLeft )
   ::aRight  := Iif( aRight==Nil, {}, aRight )
   ::lVertical := ( ::nHeight > ::nWidth )

   ::Activate()

Return Self

METHOD Activate() CLASS HSplitter
   IF !Empty( ::oParent:handle )
      ::handle := CreateSplitter( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSplitter

   IF msg == WM_MOUSEMOVE
      IF ::hCursor == Nil
         ::hCursor := LoadCursor( GDK_HAND1 )
      ENDIF
      Hwg_SetCursor( ::hCursor,::handle )
      IF ::lCaptured
         ::Drag( lParam )
      ENDIF
   ELSEIF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_LBUTTONDOWN
      Hwg_SetCursor( ::hCursor,::handle )
      ::lCaptured := .T.
   ELSEIF msg == WM_LBUTTONUP
      ::DragAll()
      ::lCaptured := .F.
      IF ::bEndDrag != Nil
         Eval( ::bEndDrag,Self )
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::End()
   ENDIF

Return -1

METHOD Init CLASS HSplitter

   IF !::lInit
      Super:Init()
      SetWindowObject( ::handle,Self )
   ENDIF

Return Nil

METHOD Paint( lpdis ) CLASS HSplitter
Local hDC

   IF ::bPaint != Nil
      Eval( ::bPaint,Self )
   ELSE
      hDC := GetDC( ::handle )
      DrawButton( hDC, 0,0,::nWidth-1,::nHeight-1,6 )
      releaseDC( ::handle, hDC )
   ENDIF

Return Nil

METHOD Move( x1,y1,width,height )  CLASS HSplitter

   Super:Move( x1,y1,width,height,.T. )
Return Nil

METHOD Drag( lParam ) CLASS HSplitter
Local xPos := Loword( lParam ), yPos := Hiword( lParam )

   IF ::lVertical
      IF xPos > 32000
         xPos -= 65535
      ENDIF
      ::Move( ::nLeft + xPos )
   ELSE
      IF yPos > 32000
         yPos -= 65535
      ENDIF
      ::Move( ,::nTop + yPos )
   ENDIF
   ::lMoved := .T.

Return Nil

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

Return Nil
