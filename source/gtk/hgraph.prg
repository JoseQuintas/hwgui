/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HGraph class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HGraph INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA aValues
   DATA nGraphs INIT 1
   DATA nType
   DATA lGrid   INIT .F.
   DATA scaleX, scaleY
   DATA ymaxSet
   DATA tbrush
   DATA colorCoor INIT 16777215
   DATA oPen, oPenCoor
   DATA xmax, ymax, xmin, ymin PROTECTED

   METHOD New( oWndParent, nId, aValues, nLeft, nTop, nWidth, nHeight, oFont, ;
      bSize, ctoolt, tcolor, bcolor )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD CalcMinMax()
   METHOD Paint()
   METHOD Rebuild( aValues )

ENDCLASS

METHOD New( oWndParent, nId, aValues, nLeft, nTop, nWidth, nHeight, oFont, ;
      bSize, ctoolt, tcolor, bcolor ) CLASS HGraph

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, oFont, , ;
      bSize, { |o, lpdis|o:Paint( lpdis ) }, ctoolt, ;
      iif( tcolor == Nil, hwg_ColorC2N( "FFFFFF" ), tcolor ), iif( bcolor == Nil, 0, bcolor ) )

   ::aValues := aValues
   ::nType   := 1
   ::nGraphs := 1

   ::Activate()

   RETURN Self

METHOD Activate CLASS HGraph

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      hwg_Setwindowobject( ::handle, Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HGraph

   IF msg == WM_PAINT
      ::Paint()
   ENDIF

   RETURN 0

METHOD CalcMinMax() CLASS HGraph
   LOCAL i, j, nLen

   ::xmax := ::xmin := ::ymax := ::ymin := 0
   IF ::ymaxSet != Nil .AND. ::ymaxSet != 0
      ::ymax := ::ymaxSet
   ENDIF
   FOR i := 1 TO ::nGraphs
      nLen := Len( ::aValues[i] )
      IF ::nType == 1
         FOR j := 1 TO nLen
            ::xmax := Max( ::xmax, ::aValues[i,j,1] )
            ::xmin := Min( ::xmin, ::aValues[i,j,1] )
            ::ymax := Max( ::ymax, ::aValues[i,j,2] )
            ::ymin := Min( ::ymin, ::aValues[i,j,2] )
         NEXT
      ELSEIF ::nType == 2
         FOR j := 1 TO nLen
            ::ymax := Max( ::ymax, ::aValues[i,j,2]   )
            ::ymin := Min( ::ymin, ::aValues[i,j,2]   )
         NEXT
         ::xmax := nLen
      ELSEIF ::nType == 3
         FOR j := 1 TO nLen
            ::ymax += ::aValues[i,j,2]
         NEXT
      ENDIF
   NEXT

   RETURN Nil

METHOD Paint( lpdis ) CLASS HGraph
   LOCAL hDC := hwg_Getdc( ::handle )
   LOCAL x1 := 0, y1 := 0, x2 := ::nWidth, y2 := ::nHeight
   LOCAL i, j, nLen
   LOCAL px1, px2, py1, py2, nWidth

   IF ::xmax == Nil
      ::CalcMinMax()
   ENDIF
   i := Round( ( x2 - x1 )/10, 0 )
   x1 += i
   x2 -= i
   i := Round( ( y2 - y1 )/10, 0 )
   y1 += i
   y2 -= i

   IF ::nType < 3
      ::scaleX := ( ::xmax - ::xmin ) / ( x2 - x1 )
      ::scaleY := ( ::ymax - ::ymin ) / ( y2 - y1 )
   ENDIF

   IF ::oPenCoor == Nil
      ::oPenCoor := HPen():Add( PS_SOLID, 1, ::colorCoor )
   ENDIF
   IF ::oPen == Nil
      ::oPen := HPen():Add( PS_SOLID, 2, ::tcolor )
   ENDIF

   hwg_Fillrect( hDC, 0, 0, ::nWidth, ::nHeight, ::brush:handle )
   IF ::nType != 3
      hwg_Selectobject( hDC, ::oPenCoor:handle )
      hwg_Drawline( hDC, x1 + ( 0 - ::xmin )/::scaleX, 3, x1 + ( 0 - ::xmin )/::scaleX, ::nHeight - 3 )
      hwg_Drawline( hDC, 3, y2 - ( 0 - ::ymin )/::scaleY, ::nWidth - 3, y2 - ( 0 - ::ymin )/::scaleY )
   ENDIF
   IF ::ymax == ::ymin .AND. ::ymax == 0
      RETURN Nil
   ENDIF

   hwg_Selectobject( hDC, ::oPen:handle )
   FOR i := 1 TO ::nGraphs
      nLen := Len( ::aValues[i] )
      IF ::nType == 1
         FOR j := 2 TO nLen
            px1 := Round( x1 + ( ::aValues[i,j-1,1] - ::xmin )/::scaleX, 0 )
            py1 := Round( y2 - ( ::aValues[i,j-1,2] - ::ymin )/::scaleY, 0 )
            px2 := Round( x1 + ( ::aValues[i,j,1] - ::xmin )/::scaleX, 0 )
            py2 := Round( y2 - ( ::aValues[i,j,2] - ::ymin )/::scaleY, 0 )
            IF px2 != px1 .OR. py2 != py1
               hwg_Drawline( hDC, px1, py1, px2, py2 )
            ENDIF
         NEXT
      ELSEIF ::nType == 2
         IF ::tbrush == Nil
            ::tbrush := HBrush():Add( ::tcolor )
         ENDIF
         nWidth := Round( ( x2 - x1 ) / ( nLen * 2 + 1 ), 0 )
         FOR j := 1 TO nLen
            px1 := Round( x1 + nWidth * ( j * 2 - 1 ), 0 )
            py1 := Round( y2 - ( ::aValues[i,j,2] - ::ymin )/::scaleY, 0 )
            hwg_Fillrect( hDC, px1, py1, px1 + nWidth, y2 - 2, ::tbrush:handle )
         NEXT
      ELSEIF ::nType == 3
         hwg_Drawbutton( hDC, 5, 5, 80, 30, 5 )
         hwg_Drawbutton( hDC, 5, 35, 80, 55, 6 ) 
      ENDIF
   NEXT
   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD Rebuild( aValues, nType ) CLASS HGraph

   ::aValues := aValues
   IF nType != Nil
      ::nType := nType
   ENDIF
   ::CalcMinMax()
   hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )

   RETURN Nil
