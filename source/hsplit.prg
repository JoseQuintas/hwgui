/*
 * $Id$
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
#include "common.ch"

#define TRANSPARENT 1

CLASS HSplitter INHERIT HControl

CLASS VAR winclass INIT "STATIC"

   DATA aLeft
   DATA aRight
   DATA lVertical
   DATA hCursor
   DATA lCaptured INIT .F.
   DATA lMoved INIT .F.
   DATA bEndDrag
   DATA lScrolling

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
               bSize, bDraw, color, bcolor, aLeft, aRight, lTransp, lScrolling )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint()
   METHOD Drag( lParam )
   METHOD DragAll( lScroll )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
            bSize, bDraw, color, bcolor, aLeft, aRight, lTransp, lScrolling ) CLASS HSplitter
                                                         //+  WS_CLIPCHILDREN
   Super:New( oWndParent, nId, WS_VISIBLE + SS_OWNERDRAW , nLeft, nTop, nWidth, nHeight,,, ;
              bSize, bDraw,, color, bcolor )

   ::title   := ""
   
   ::aLeft   := IIf( aLeft == Nil, { }, aLeft )
   ::aRight  := IIf( aRight == Nil, { }, aRight )
   ::lVertical := ( ::nHeight > ::nWidth )
   ::lScrolling := Iif( lScrolling == Nil, .F., lScrolling )
   IF ( lTransp != NIL .AND. lTransp )
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HSplitter
   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HSplitter

   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Hwg_InitWinCtrl( ::handle )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HSplitter

   HB_SYMBOL_UNUSED( wParam )

   IF msg == WM_MOUSEMOVE
      IF ::hCursor == Nil
         ::hCursor := LoadCursor( IIf( ::lVertical, IDC_SIZEWE, IDC_SIZENS ) )
      ENDIF
      Hwg_SetCursor( ::hCursor )
      IF ::lCaptured
         ::Drag( lParam )
         IF ::lScrolling
            ::DragAll( .T. )
         ENDIF
      ENDIF
   ELSEIF msg == WM_PAINT
      ::Paint()
   ELSEIF msg == WM_ERASEBKGND

   ELSEIF msg == WM_LBUTTONDOWN
      Hwg_SetCursor( ::hCursor )
      SetCapture( ::handle )
      ::lCaptured := .T.
      InvalidateRect( ::handle, 1 )
   ELSEIF msg == WM_LBUTTONUP
      ReleaseCapture()
      ::lCaptured := .F.
      ::lMoved := .F.
      ::DragAll( .F. )
      IF ::bEndDrag != Nil
       //  Eval( ::bEndDrag, Self )
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1


METHOD Paint() CLASS HSplitter
   LOCAL pps, hDC, aCoors, x1, y1, x2, y2, oBrushFill


   pps := DefinePaintStru()
   hDC := BeginPaint( ::handle, pps )
   aCoors := GetClientRect( ::handle )
   
   x1 := aCoors[ 1 ] //+ IIf( ::lVertical, 1, 2 )
   y1 := aCoors[ 2 ] //+ IIf( ::lVertical, 2, 1 )
   x2 := aCoors[ 3 ] //- IIf( ::lVertical, 0, 3 )
   y2 := aCoors[ 4 ] //- IIf( ::lVertical, 3, 0 )

   SetBkMode( hDC, ::backStyle )
   IF ::bPaint != Nil
      Eval( ::bPaint, Self )
   ELSEIF ! ::lScrolling
      IF ::lCaptured
         oBrushFill := HBrush():Add( RGB( 156, 156, 156 ) )
         SelectObject( hDC, oBrushFill:handle )
         DrawEdge( hDC, x1, y1, x2, y2, EDGE_ETCHED, Iif( ::lVertical,BF_RECT,BF_TOP ) + BF_MIDDLE )
         FillRect( hDC, x1, y1, x2, y2, oBrushFill:handle )
      ELSEIF ::BackStyle = OPAQUE
         DrawEdge( hDC, x1, y1, x2, y2, EDGE_ETCHED, IIf( ::lVertical, BF_LEFT, BF_TOP ) )
      ENDIF
   ELSEIF !::lMoved .AND. ::BackStyle = OPAQUE
      DrawEdge( hDC, x1, y1, x2, y2, EDGE_ETCHED, Iif( ::lVertical,BF_RECT,BF_TOP ) ) //+ BF_MIDDLE )
   ENDIF
   EndPaint( ::handle, pps )

   RETURN Nil

METHOD Drag( lParam ) CLASS HSplitter
   LOCAL xPos := LOWORD( lParam ), yPos := HIWORD( lParam )

   IF ::lVertical
      IF xPos > 32000
         xPos -= 65535
      ENDIF
      ::nLeft += xPos
      yPos := 0
   ELSE
      IF yPos > 32000
         yPos -= 65535
      ENDIF
      ::nTop += yPos
      xPos := 0
   ENDIF
   ::Move( ::nLeft + xPos, ::nTop + yPos, ::nWidth, ::nHeight ) //,  ! ::lScrolling  )
   InvalidateRect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nleft + ::nWidth , ::nTop + ::nHeight )
   ::lMoved := .T.

   RETURN Nil

METHOD DragAll( lScroll ) CLASS HSplitter
   LOCAL i, oCtrl, xDiff := 0, yDiff := 0

   lScroll := IIF(  Len( ::aLeft ) = 0 .OR. Len( ::aRight ) = 0, .F., lScroll )

   FOR i := 1 TO Len( ::aRight )
      oCtrl := ::aRight[ i ]
      IF ::lVertical
         xDiff := ::nLeft + ::nWidth - oCtrl:nLeft
         //oCtrl:nLeft += nDiff
         //oCtrl:nWidth -= nDiff
      ELSE
         yDiff := ::nTop + ::nHeight - oCtrl:nTop
         //oCtrl:nTop += nDiff
         //oCtrl:nHeight -= nDiff
      ENDIF
      oCtrl:Move( oCtrl:nLeft + xDiff, oCtrl:nTop + yDiff, oCtrl:nWidth - xDiff ,oCtrl:nHeight - yDiff, ! lScroll )
      //InvalidateRect( oCtrl:oParent:Handle, 1, oCtrl:nLeft, oCtrl:nTop, oCtrl:nleft + oCtrl:nWidth, oCtrl:nTop + oCtrl:nHeight )
      IF oCtrl:winclass == "STATIC"
          InvalidateRect( oCtrl:Handle, 1 )
      ENDIF

   NEXT
   FOR i := 1 TO Len( ::aLeft )
      oCtrl := ::aLeft[ i ]
      IF ::lVertical
         xDiff := ::nLeft - ( oCtrl:nLeft + oCtrl:nWidth )
         //oCtrl:nWidth += nDiff
      ELSE

         yDiff := ::nTop - ( oCtrl:nTop + oCtrl:nHeight )
        // oCtrl:nHeight += nDiff
      ENDIF
      oCtrl:Move( oCtrl:nLeft, oCtrl:nTop, oCtrl:nWidth + xDiff, oCtrl:nHeight + yDiff , ! lScroll )
      IF oCtrl:winclass == "STATIC"
         InvalidateRect( oCtrl:Handle, 1 )
      ENDIF

      //InvalidateRect( oCtrl:oParent:Handle, 1, oCtrl:nLeft, oCtrl:nTop, oCtrl:nleft + oCtrl:nWidth, oCtrl:nTop+oCtrl:nHeight )
   NEXT
   //::lMoved := .F.
   IF ! lScroll
      InvalidateRect( ::oParent:handle, 1, ::nleft, ::ntop, ::nleft + ::nwidth, ::nTop + ::nHeight )
   ENDIF
   IF ::bEndDrag != Nil
      Eval( ::bEndDrag,Self )
   ENDIF

   RETURN Nil

