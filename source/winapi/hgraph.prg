/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGraph class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HGraph INHERIT HControl

CLASS VAR winclass   INIT "STATIC"
   DATA aValues
   DATA aSignX, aSignY
   DATA nGraphs    INIT 1
   DATA nType
   DATA lGridX     INIT .F.
   DATA lGridY     INIT .F.
   DATA lGridXMid  INIT .T.
   DATA lPositive  INIT .F.
   DATA x1Def      INIT 10
   DATA x2Def      INIT 10
   DATA y1Def      INIT 10
   DATA y2Def      INIT 10
   DATA scaleX, scaleY
   DATA ymaxSet
   DATA tbrush
   DATA colorCoor INIT 16777215
   DATA oPen, oPenCoor
   DATA xmax, ymax, xmin, ymin PROTECTED

   METHOD New( oWndParent, nId, aValues, nLeft, nTop, nWidth, nHeight, oFont, ;
               bSize, ctooltip, tcolor, bcolor )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, aValues, oFont, ;
                    bSize, ctooltip, tcolor, bcolor )
   METHOD Init()
   METHOD CalcMinMax()
   METHOD Paint()
   METHOD Rebuild( aValues )

ENDCLASS

METHOD New( oWndParent, nId, aValues, nLeft, nTop, nWidth, nHeight, oFont, ;
            bSize, ctooltip, tcolor, bcolor ) CLASS HGraph

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, oFont,, ;
              bSize, { | o, lpdis | o:Paint( lpdis ) }, ctooltip, ;
              IIf( tcolor == Nil, hwg_ColorC2N( "FFFFFF" ), tcolor ), IIf( bcolor == Nil, 0, bcolor ) )

   ::aValues := aValues
   ::nType   := 1
   ::nGraphs := 1

   ::Activate()

   RETURN Self

METHOD Redefine( oWndParent, nId, aValues, oFont, ;
                 bSize, ctooltip, tcolor, bcolor )  CLASS HGraph

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, 0, 0, 0, oFont,, ;
              bSize, { | o, lpdis | o:Paint( lpdis ) }, ctooltip, ;
              IIf( tcolor == Nil, hwg_ColorC2N( "FFFFFF" ), tcolor ), IIf( bcolor == Nil, 0, bcolor ) )

   ::aValues := aValues

   RETURN Self

METHOD Activate CLASS HGraph
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init()  CLASS HGraph
   IF ! ::lInit
      ::Super:Init()
      ::CalcMinMax()
   ENDIF
   RETURN Nil

METHOD CalcMinMax() CLASS HGraph
   LOCAL i, j, nLen

   IF ::nType == 0
      RETURN Nil
   ENDIF
   ::xmax := ::xmin := ::ymax := ::ymin := 0
   IF !Empty( ::ymaxSet )
      ::ymax := ::ymaxSet
   ENDIF
   FOR i := 1 TO ::nGraphs
      nLen := Len( ::aValues[ i ] )
      IF ::nType == 1
         FOR j := 1 TO nLen
            ::xmax := Max( ::xmax, ::aValues[ i,j,1 ] )
            ::xmin := Min( ::xmin, ::aValues[ i,j,1 ] )
            ::ymax := Max( ::ymax, ::aValues[ i,j,2 ] )
            ::ymin := Min( ::ymin, ::aValues[ i,j,2 ] )
         NEXT
      ELSEIF ::nType == 2
         FOR j := 1 TO nLen
            IF ::aValues[ i,j,2 ] != Nil
              ::ymax := Max( ::ymax, ::aValues[ i,j,2 ] )
              ::ymin := Min( ::ymin, ::aValues[ i,j,2 ] )
            ENDIF
         NEXT
         ::xmax := nLen
      ELSEIF ::nType == 3
         FOR j := 1 TO nLen
            ::ymax += ::aValues[ i, j, 2 ]
         NEXT
      ENDIF
   NEXT

   RETURN Nil

METHOD Paint( lpdis ) CLASS HGraph
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ], x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ], x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]
   LOCAL i, j, nLen
   LOCAL x0, y0, px1, px2, py1, py2, nWidth

   IF ::nType == 0
      RETURN Nil
   ENDIF

   x1 += ::x1Def
   x2 -= ::x2Def
   y1 += ::y1Def
   y2 -= ::y2Def

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
   x0 := x1 + ( 0 - ::xmin ) / ::scaleX
   y0 := Iif( ::lPositive, y2, y2 - ( 0 - ::ymin ) / ::scaleY )

   hwg_Fillrect( hDC, drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ], ::brush:handle )
   IF ::nType != 3
      hwg_Selectobject( hDC, ::oPenCoor:handle )
      hwg_Drawline( hDC, x0, drawInfo[ 5 ] + 3, x0, drawInfo[ 7 ] - 3 )
      hwg_Drawline( hDC, drawInfo[ 4 ] + 3, y0, drawInfo[ 6 ] - 3, y0 )
   ENDIF

   IF ::ymax != ::ymin .OR. ::ymax != 0
      hwg_Selectobject( hDC, ::oPen:handle )
      FOR i := 1 TO ::nGraphs
         nLen := Len( ::aValues[ i ] )
         IF ::nType == 1
            FOR j := 2 TO nLen
               px1 := Round( x1 + ( ::aValues[ i,j-1,1 ] - ::xmin ) / ::scaleX, 0 )
               py1 := Round( y2 - ( ::aValues[ i,j-1,2 ] - ::ymin ) / ::scaleY, 0 )
               px2 := Round( x1 + ( ::aValues[ i,j,1 ] - ::xmin ) / ::scaleX, 0 )
               py2 := Round( y2 - ( ::aValues[ i,j,2 ] - ::ymin ) / ::scaleY, 0 )
               IF px2 != px1 .OR. py2 != py1
                  hwg_Drawline( hDC, px1, py1, px2, py2 )
               ENDIF
            NEXT
         ELSEIF ::nType == 2
            IF ::tbrush == Nil
               ::tbrush := HBrush():Add( ::tcolor )
            ENDIF
            // nWidth := Round( ( x2 - x1 ) / ( nLen * 2 + 1 ), 0 )
            nWidth := Round( ( x2 - x1 ) / ( nLen ), 0 )
            FOR j := 1 TO nLen
               IF ::aValues[ i,j,2 ] != Nil
                  // px1 := Round( x1 + nWidth * ( j * 2 - 1 ), 0 )
                  px1 := Round( x1 + nWidth * ( j - 1 ) + 1, 0 )
                  py1 := Round( y2 - 2 - ( ::aValues[ i,j,2 ] - ::ymin ) / ::scaleY, 0 )
                  hwg_Fillrect( hDC, px1, y2 - 2, px1 + nWidth - 1, py1, ::tbrush:handle )
               ENDIF
            NEXT
         ELSEIF ::nType == 3
            IF ::tbrush == Nil
               ::tbrush := HBrush():Add( ::tcolor )
            ENDIF
            hwg_Selectobject( hDC, ::oPenCoor:handle )
            hwg_Selectobject( hDC, ::tbrush:handle )
            hwg_Pie( hDC, x1 + 10, y1 + 10, x2 - 10, y2 - 10, x1, Round( y1 + ( y2 - y1 ) / 2, 0 ), Round( x1 + ( x2 - x1 ) / 2, 0 ), y1 )
         ENDIF
      NEXT
   ENDIF

   hwg_Selectobject( hDC, ::oPenCoor:handle )
   IF !Empty( ::aSignY )
      IF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      hwg_Settextcolor( hDC, ::colorCoor )
      FOR i := 1 TO Len( ::aSignY )
         py1 := Round( y2 - 2 - ( ::aSignY[ i,1 ] - ::ymin ) / ::scaleY, 0 )
         IF py1 > y1 .AND. py1 < y2
            hwg_Drawline( hDC, x0-4, py1, x0+1, py1 )
            IF ::aSignY[ i,2 ] != Nil
               hwg_Drawtext( hDC, Iif( Valtype(::aSignY[i,2])=="C",::aSignY[i,2], ;
                     Ltrim(Str(::aSignY[i,2]))), drawInfo[4], py1-8, x0-4, py1+8, DT_RIGHT )
               IF ::lGridY
                  hwg_Drawline( hDC, x0+1, py1, x2, py1 )
               ENDIF
            ENDIF
         ENDIF
      NEXT
   ENDIF
   IF !Empty( ::aSignX )
      nWidth := Round( ( x2 - x1 ) / Len(::aValues[1]), 0 )
      IF ::oFont != Nil
         hwg_Selectobject( hDC, ::oFont:handle )
      ENDIF
      hwg_Settextcolor( hDC, ::colorCoor )
      FOR i := 1 TO Len( ::aSignX )
         px1 := Round( x0 + nWidth * ::aSignX[ i,1 ] + Iif( ::lGridXMid,nWidth/2,0 ), 0 )
         hwg_Drawline( hDC, px1, y0+4, px1, y0-1 )
         IF ::aSignX[ i,2 ] != Nil
            hwg_Drawtext( hDC, Iif( Valtype(::aSignX[i,2])=="C",::aSignX[i,2], ;
                  Ltrim(Str(::aSignX[i,2]))), px1-40, y0+4, px1+40, y0+20, DT_CENTER )
            IF ::lGridX
               hwg_Drawline( hDC, px1, y0-1, px1, y1 )
            ENDIF
         ENDIF
      NEXT
   ENDIF

   RETURN Nil

METHOD Rebuild( aValues, nType ) CLASS HGraph

   ::aValues := aValues
   IF nType != Nil
      ::nType := nType
   ENDIF
   IF ::nType != 0
      ::CalcMinMax()
      hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ENDIF

   RETURN Nil
