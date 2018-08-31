/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HPanel class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HPanel INHERIT HControl

   DATA winclass   INIT "PANEL"

   DATA hBox
   DATA oStyle
   DATA aPaintCB  INIT {}       // Array of items to draw: { cIt, bDraw(hDC,aCoors) }

   DATA hScrollV  INIT Nil
   DATA hScrollH  INIT Nil
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
   DATA bVScroll, bHScroll

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bColor, oStyle )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD DrawItems( hDC, aCoors )
   METHOD Paint()
   METHOD Move( x1, y1, width, height )
   METHOD SetPaintCB( nId, block, cId )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      bInit, bSize, bPaint, bColor, oStyle ) CLASS HPanel

   LOCAL oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )

   IF !Empty( bPaint ) .OR. bColor != Nil
      nStyle := Hwg_BitOr( nStyle, SS_OWNERDRAW )
   ENDIF
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == Nil,0,nWidth ), ;
      nHeight, oParent:oFont, bInit, ;
      bSize, bPaint, , , bColor )

   ::oStyle := oStyle
   ::bPaint  := bPaint

   ::Activate()

   RETURN Self

METHOD Activate CLASS HPanel

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createpanel( Self, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HPanel

   IF msg == WM_PAINT
      ::Paint()

   ELSEIF msg == WM_HSCROLL
      IF ::bHScroll != Nil
         Eval( ::bHScroll, Self )
      ENDIF

   ELSEIF msg == WM_VSCROLL
      IF ::bVScroll != Nil
         Eval( ::bVScroll, Self )
      ENDIF

   ELSE
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN 0

METHOD Init CLASS HPanel

   IF !::lInit
      IF ::bSize == Nil .AND. Empty( ::Anchor )
         IF ::nHeight != 0 .AND. ( ::nWidth > ::nHeight .OR. ::nWidth == 0 )
            ::bSize := { |o, x, y|o:Move( , iif( ::nTop > 0,y - ::nHeight,0 ), x, ::nHeight ) }
         ELSEIF ::nWidth != 0 .AND. ( ::nHeight > ::nWidth .OR. ::nHeight == 0 )
            ::bSize := { |o, x, y|o:Move( iif( ::nLeft > 0,x - ::nLeft,0 ), , ::nWidth, y ) }
         ENDIF
      ENDIF

      ::Super:Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD DrawItems( hDC, aCoors ) CLASS HPanel

   LOCAL i, aCB

   IF Empty( aCoors )
      aCoors := hwg_Getclientrect( ::handle )
   ENDIF
   IF !Empty( aCB := hwg_getPaintCB( ::aPaintCB, PAINT_ITEM ) )
      FOR i := 1 TO Len( aCB )
         Eval( aCB[i], Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
      NEXT
   ENDIF

   RETURN Nil

METHOD Paint() CLASS HPanel
   LOCAL hDC, aCoors, block

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   hDC := hwg_Getdc( ::handle )
   aCoors := hwg_Getclientrect( ::handle )

   IF !Empty( block := hwg_getPaintCB( ::aPaintCB, PAINT_BACK ) )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF ::oStyle == Nil
      hwg_Drawbutton( hDC, 0, 0, ::nWidth - 1, ::nHeight - 1, 5 )
   ELSE
      ::oStyle:Draw( hDC, 0, 0, aCoors[3], aCoors[4] )
   ENDIF
   ::DrawItems( hDC, aCoors )

   hwg_Releasedc( ::handle, hDC )

   RETURN Nil

METHOD Move( x1, y1, width, height )  CLASS HPanel

   LOCAL lMove := .F. , lSize := .F.

   IF x1 != Nil .AND. x1 != ::nLeft
      ::nLeft := x1
      lMove := .T.
   ENDIF
   IF y1 != Nil .AND. y1 != ::nTop
      ::nTop := y1
      lMove := .T.
   ENDIF
   IF width != Nil .AND. width != ::nWidth
      ::nWidth := width
      lSize := .T.
   ENDIF
   IF height != Nil .AND. height != ::nHeight
      ::nHeight := height
      lSize := .T.
   ENDIF
   IF lMove .OR. lSize
      hwg_MoveWidget( ::hbox, iif( lMove,::nLeft,Nil ), iif( lMove,::nTop,Nil ), ;
         iif( lSize, ::nWidth, Nil ), iif( lSize, ::nHeight, Nil ), .F. )
      IF lSize
         hwg_MoveWidget( ::handle, Nil, Nil, ::nWidth, ::nHeight, .F. )
         hwg_Redrawwindow( ::handle )
         /*
         IF !Empty( ::hScrollV )
            hwg_Redrawwindow( ::hScrollV )
         ENDIF
         IF !Empty( ::hScrollH )
            hwg_Redrawwindow( ::hScrollH )
         ENDIF
         */
      ENDIF
   ENDIF

   //::Super:Move( x1,y1,width,height,.T. )

   RETURN Nil

METHOD SetPaintCB( nId, block, cId ) CLASS HPanel

   LOCAL i, nLen

   IF Empty( cId ); cId := "_"; ENDIF
   IF Empty( ::aPaintCB ); ::aPaintCB := {}; ENDIF

   nLen := Len( ::aPaintCB )
   FOR i := 1 TO nLen
      IF ::aPaintCB[i,1] == nId .AND. ::aPaintCB[i,2] == cId
         EXIT
      ENDIF
   NEXT
   IF Empty( block )
      IF i <= nLen
         ADel( ::aPaintCB, i )
         ::aPaintCB := ASize( ::aPaintCB, nLen-1 )
      ENDIF
   ELSE
      IF i > nLen
         Aadd( ::aPaintCB, { nId, cId, block } )
      ELSE
         ::aPaintCB[i,3] := block
      ENDIF
   ENDIF

   RETURN Nil


CLASS HPanelStS INHERIT HPANEL

   DATA aParts
   DATA aText

   METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts )
   METHOD Write( cText, nPart, lRedraw )
   METHOD PaintText( hDC )
   METHOD Paint()

ENDCLASS

METHOD New( oWndParent, nId, nHeight, oFont, bInit, bPaint, bcolor, oStyle, aParts ) CLASS HPanelStS

   oWndParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   IF bColor == Nil
      bColor := hwg_GetSysColor( COLOR_3DFACE )
   ENDIF

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, oWndParent:nHeight - nHeight, ;
      oWndParent:nWidth, nHeight, bInit, { |o, w, h|o:Move( 0, h - o:nHeight, w ) }, bPaint, bcolor )

   ::oFont := Iif( oFont == Nil, ::oParent:oFont, oFont )
   ::oStyle := oStyle
   ::aParts := aParts
   ::aText := Array( Len(aParts) )
   AFill( ::aText, "" )

   RETURN Self

METHOD Write( cText, nPart, lRedraw ) CLASS HPanelStS

   ::aText[nPart] := cText
   IF Valtype( lRedraw ) != "L" .OR. lRedraw
      hwg_Invalidaterect( ::handle, 0 )
   ENDIF

   RETURN Nil

METHOD PaintText( hDC ) CLASS HPanelStS

   LOCAL i, x1, x2, nWidth := ::nWidth

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   hwg_Settransparentmode( hDC, .T. )
   FOR i := 1 TO Len( ::aParts )
      x1 := Iif( i == 1, 4, x2 + 4 )
      IF ::aParts[i] == 0
         x2 := x1 + Int( nWidth/(Len(::aParts)-i+1) )
      ELSE
         x2 := x1 + ::aParts[i]
      ENDIF
      nWidth -= ( x2-x1+1 )
      IF !Empty( ::aText[i] )
         hwg_Drawtext( hDC, ::aText[i], x1, 6, x2, ::nHeight-2, DT_LEFT + DT_VCENTER )
      ENDIF
   NEXT
   hwg_Settransparentmode( hDC, .F. )

   RETURN Nil

METHOD Paint() CLASS HPanelStS
   LOCAL pps, hDC, block, aCoors

   IF ::bPaint != Nil
      RETURN Eval( ::bPaint, Self )
   ENDIF

   pps    := hwg_Definepaintstru()
   hDC    := hwg_Beginpaint( ::handle, pps )

   IF !Empty( block := hwg_getPaintCB( ::aPaintCB, PAINT_BACK ) )
      aCoors := hwg_Getclientrect( ::handle )
      Eval( block, Self, hDC, aCoors[1], aCoors[2], aCoors[3], aCoors[4] )
   ELSEIF Empty( ::oStyle )
      ::oStyle := HStyle():New( {::bColor}, 1,, 0.4, 0 )
   ENDIF
   ::oStyle:Draw( hDC, 0, 0, ::nWidth, ::nHeight )

   ::PaintText( hDC )
   ::DrawItems( hDC )

   hwg_Endpaint( ::handle, pps )

   RETURN Nil
