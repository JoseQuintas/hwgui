/*
 * $Id: hsplit.prg,v 1.4 2004-10-04 12:15:12 alkresin Exp $
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

CLASS HSplitter INHERIT HControl

   CLASS VAR winclass   INIT "PANEL"

   DATA aLeft
   DATA aRight
   DATA lVertical
   DATA hCursor
   DATA lCaptured INIT .F.
   DATA lMoved INIT .F.
   // DATA oPenLight, oPenGray

   METHOD New( oWndParent,nId,nLeft,nTop,nWidth,nHeight, ;
                  bSize,bPaint,color,bcolor,aLeft,aRight )
   METHOD Activate()
   METHOD Init()
   METHOD Paint( lpdis )
   METHOD Drag( lParam )
   METHOD DragAll()
   METHOD End()  INLINE hwg_DecreaseHolders( Self )

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

METHOD Activate()
   IF ::oParent:handle != 0
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Init CLASS HSplitter
   Super:Init()
   SetWindowObject( ::handle,Self )
   Hwg_InitSplitProc( ::handle )
Return Nil

METHOD Paint( lpdis ) CLASS HSplitter
/*
Local drawInfo := GetDrawItemInfo( lpdis )
Local hDC := drawInfo[3], x1 := drawInfo[4], y1 := drawInfo[5], x2 := drawInfo[6], y2 := drawInfo[7]
*/
Local pps, hDC, aCoors, x1, y1, x2, y2

   pps := DefinePaintStru()
   hDC := BeginPaint( ::handle, pps )
   aCoors := GetClientRect( ::handle )
   x1 := aCoors[1] + Iif( ::lVertical,1,5 )
   y1 := aCoors[2] + Iif( ::lVertical,5,1 )
   x2 := aCoors[3] - Iif( ::lVertical,0,5 )
   y2 := aCoors[4] - Iif( ::lVertical,5,0 )

   IF ::bPaint != Nil
      Eval( ::bPaint,Self )
   ELSE
      DrawEdge( hDC,x1,y1,x2,y2,EDGE_ETCHED,Iif( ::lVertical,BF_LEFT,BF_TOP ) )
   ENDIF
   EndPaint( ::handle, pps )

Return Nil

METHOD Drag( lParam ) CLASS HSplitter
Local xPos := Loword( lParam ), yPos := Hiword( lParam )

   IF ::lVertical
      IF xPos > 32000
         xPos -= 65535
      ENDIF
      ::nLeft += xPos
   ELSE
      IF yPos > 32000
         yPos -= 65535
      ENDIF
      ::nTop += yPos
   ENDIF
   MoveWindow( ::handle,::nLeft,::nTop,::nWidth,::nHeight )
   ::lMoved := .T.

Return Nil

METHOD DragAll() CLASS HSplitter
Local i, oCtrl, nDiff

   FOR i := 1 TO Len( ::aRight )
      oCtrl := ::aRight[i]
      IF ::lVertical
         nDiff := ::nLeft+::nWidth - oCtrl:nLeft
         oCtrl:nLeft += nDiff
         oCtrl:nWidth -= nDiff
      ELSE
         nDiff := ::nTop+::nHeight - oCtrl:nTop
         oCtrl:nTop += nDiff
         oCtrl:nHeight -= nDiff
      ENDIF
      MoveWindow( oCtrl:handle,oCtrl:nLeft,oCtrl:nTop,oCtrl:nWidth,oCtrl:nHeight )
   NEXT
   FOR i := 1 TO Len( ::aLeft )
      oCtrl := ::aLeft[i]
      IF ::lVertical
         nDiff := ::nLeft - ( oCtrl:nLeft + oCtrl:nWidth )
         oCtrl:nWidth += nDiff
      ELSE
         nDiff := ::nTop - ( oCtrl:nTop + oCtrl:nHeight )
         oCtrl:nHeight += nDiff
      ENDIF
      MoveWindow( oCtrl:handle,oCtrl:nLeft,oCtrl:nTop,oCtrl:nWidth,oCtrl:nHeight )
   NEXT
   ::lMoved := .F.

Return Nil

Function DefSplitterProc( hCtrl, msg, wParam, lParam )
Local oCtrl
   // writelog( "DefSplitterProc: " + Str(hCtrl,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   oCtrl := GetWindowObject( hCtrl )
   IF msg == WM_MOUSEMOVE
      IF oCtrl:hCursor == Nil
         oCtrl:hCursor := LoadCursor( Iif( oCtrl:lVertical,IDC_SIZEWE,IDC_SIZENS ) )
      ENDIF
      Hwg_SetCursor( oCtrl:hCursor )
      IF oCtrl:lCaptured
         oCtrl:Drag( lParam )
      ENDIF
   ELSEIF msg == WM_PAINT
      oCtrl:Paint()
   ELSEIF msg == WM_LBUTTONDOWN
      Hwg_SetCursor( oCtrl:hCursor )
      SetCapture( hCtrl )
      oCtrl:lCaptured := .T.
   ELSEIF msg == WM_LBUTTONUP
      ReleaseCapture()
      oCtrl:DragAll()
      oCtrl:lCaptured := .F.
   ENDIF
Return -1
