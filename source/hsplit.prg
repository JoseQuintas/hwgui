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
   ::Super:New( oWndParent, nId, WS_VISIBLE + SS_OWNERDRAW , nLeft, nTop, nWidth, nHeight,,, ;
         bSize, bDraw,, color, bcolor )

   ::title := ""

   ::aLeft := IIf( aLeft == NIL, { }, aLeft )
   ::aRight := IIf( aRight == NIL, { }, aRight )
   ::lVertical := ( ::nHeight > ::nWidth )
   ::lScrolling := Iif( lScrolling == NIL, .F., lScrolling )
   IF ( lTransp != NIL .AND. lTransp )
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HSplitter
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
            ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HSplitter

   IF ! ::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      Hwg_InitWinCtrl( ::handle )
   ENDIF

   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HSplitter

   HB_SYMBOL_UNUSED( wParam )

   IF msg == WM_MOUSEMOVE
      IF ::hCursor == NIL
         ::hCursor := hwg_Loadcursor( IIf( ::lVertical, IDC_SIZEWE, IDC_SIZENS ) )
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
      hwg_Setcapture( ::handle )
      ::lCaptured := .T.
      hwg_Invalidaterect( ::handle, 1 )
   ELSEIF msg == WM_LBUTTONUP
      hwg_Releasecapture()
      ::lCaptured := .F.
      ::lMoved := .F.
      ::DragAll( .F. )
      IF ::bEndDrag != NIL
         // Eval( ::bEndDrag, Self )
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1

METHOD Paint() CLASS HSplitter
   LOCAL pps, hDC, aCoors, x1, y1, x2, y2, oBrushFill

   pps := hwg_Definepaintstru()
   hDC := hwg_Beginpaint( ::handle, pps )
   IF hwg_Getppserase( pps ) > 0
      //aCoors := hwg_Getclientrect( ::handle )
      aCoors := hwg_Getppsrect( pps )

      x1 := aCoors[ 1 ] //+ IIf( ::lVertical, 1, 2 )
      y1 := aCoors[ 2 ] //+ IIf( ::lVertical, 2, 1 )
      x2 := aCoors[ 3 ] //- IIf( ::lVertical, 0, 3 )
      y2 := aCoors[ 4 ] //- IIf( ::lVertical, 3, 0 )

      hwg_Setbkmode( hDC, ::backStyle )
      IF ::bPaint != NIL
         Eval( ::bPaint, Self )
      ELSEIF ! ::lScrolling
        IF ::lCaptured
           oBrushFill := HBrush():Add( hwg_Rgb( 156, 156, 156 ) )
           hwg_Selectobject( hDC, oBrushFill:handle )
           hwg_Drawedge( hDC, x1, y1, x2, y2, EDGE_ETCHED, Iif( ::lVertical,BF_RECT,BF_TOP ) + BF_MIDDLE )
           hwg_Fillrect( hDC, x1, y1, x2, y2, oBrushFill:handle )
        ELSEIF ::BackStyle = OPAQUE
            hwg_Drawedge( hDC, x1, y1, x2, y2, EDGE_ETCHED, IIf( ::lVertical, BF_LEFT, BF_TOP ) )
         ENDIF
      ELSEIF !::lMoved .AND. ::BackStyle = OPAQUE
         hwg_Drawedge( hDC, x1, y1, x2, y2, EDGE_ETCHED, Iif( ::lVertical,BF_RECT,BF_TOP ) ) //+ BF_MIDDLE )
      ENDIF
   ENDIF
   hwg_Endpaint( ::handle, pps )

   RETURN NIL

METHOD Drag( lParam ) CLASS HSplitter
   LOCAL xPos := hwg_Loword( lParam ), yPos := hwg_Hiword( lParam )

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
   ::Move( ::nLeft + xPos, ::nTop + yPos, ::nWidth, ::nHeight )
   IF ! ::lScrolling
      hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nleft + ::nWidth , ::nTop + ::nHeight )
   ENDIF
   ::lMoved := .T.

   RETURN NIL

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
      IF ( yDiff < 0.OR. xDiff > 0 ) .OR. ! lScroll
         hwg_Invalidaterect( oCtrl:Handle, 0 )
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
      IF ( yDiff > 0.OR. xDiff > 0 ) .OR. ! lScroll
         hwg_Invalidaterect( oCtrl:Handle, 0 )
      ENDIF
   NEXT
   //::lMoved := .F.
   IF ! lScroll
      hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft ,::nTop  , ::nLeft + ::nWidth , ::nTop + ::nHeight  )
   ELSEIF ::lVertical
      hwg_Invalidaterect( ::oParent:Handle, 1, ::nLeft - ::nWidth - xDiff - 1 , ::nTop , ::nLeft + ::nWidth + xDiff + 1, ::nTop + ::nHeight )
   ELSE
      hwg_Invalidaterect( ::oParent:Handle, 1, ::nLeft , ::nTop - ::nHeight - yDiff - 1 , ::nLeft + ::nWidth, ::nTop + ::nHeight + yDiff + 1 )
   ENDIF
   IF ::bEndDrag != NIL
      Eval( ::bEndDrag,Self )
   ENDIF

   RETURN NIL
