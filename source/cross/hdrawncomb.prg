/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDrawnCombo class
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define  STATE_NORMAL    0
#define  STATE_PRESSED   1

#define CLR_BLACK    0
#define CLR_WHITE    0xffffff
#define CLR_GRAY1    0x505050
#define CLR_GRAY2    0x909090
#define CLR_GRAY3    0xD0D0D0

CLASS HDrawnCombo INHERIT HDrawn

   DATA  aItems
   DATA  xValue       INIT 0
   DATA  lText        INIT .F.
   DATA  oText, oBtn, oList
   DATA  arrowColor   INIT 0
   DATA  arrowPen
   DATA  nRowCount    INIT 3

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, aItems, xValue, lText, bPaint, bChange, bChgState, nRowCount )

   METHOD Paint( hDC )
   METHOD Value( xValue ) SETGET

   METHOD ListShow()
   METHOD ListHide()

   METHOD onKey( msg, wParam, lParam )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, aItems, xValue, lText, bPaint, bChange, bChgState, nRowCount ) CLASS HDrawnCombo

   LOCAL bKey := {|o,m,w|
      IF m == WM_KEYDOWN
         IF w == VK_ESCAPE
            ::ListHide()
            ::GetParentBoard():oInFocus := Nil
            RETURN .T.
         ELSEIF w == VK_RETURN
            ::Value( ::oList:oData:Recno() )
            ::oText:Refresh()
            ::ListHide()
            ::GetParentBoard():oInFocus := Nil
            RETURN .T.
         ENDIF
      ENDIF
      RETURN .F.
   }
   LOCAL bClick := {|o,x,y|
      LOCAL i := 0
      DO WHILE ++i <= Len( o:aRows ) .AND. o:aRows[i,1] != Nil
         IF y > o:aRows[i,1] .AND. y < o:aRows[i,2]
            ::Value( ::oList:oData:Recno() )
            ::oText:Refresh()
            ::ListHide()
            ::GetParentBoard():oInFocus := Nil
            EXIT
         ENDIF
      ENDDO
      RETURN .F.
   }

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      , oFont, bPaint,, bChgState )

   ::aItems := aItems
   IF Valtype( lText ) == "L"; ::lText := lText; ENDIF
   IF nRowCount != Nil; ::nRowCount := nRowCount; ENDIF

   ::oText := HDrawn():New( Self, ::nLeft, ::nTop, ::nWidth-::nHeight+1, ::nHeight, ::tcolor, ::bColor, ::aStyles, ;
      "", ::oFont )
      //Iif( ::xValue==0, "", Iif(Valtype(::aItems[::xValue])=="A",::aItems[::xValue,1],::aItems[::xValue]) )
   ::oText:nTextStyle := DT_LEFT
   ::oBtn := HDrawn():New( Self, ::nLeft+::nWidth-::nHeight, ::nTop, ::nHeight, ::nHeight, ::tcolor, ::bColor,, ;
      "", ::oFont )
   ::oList := HDrawnBrw():New( Self, ::nLeft, ::nTop+::nHeight, ::nWidth, ;
      (::nHeight-4)*::nRowCount, ::tColor, ::bColor, oFont )
   ::oList:sepColor := -1
   ::oList:aRowPadding[2] := ::oList:aRowPadding[4] := 0
   ::oList:oData := HDataArray():New( aItems )
   ::oList:AddColumn( "", ::oList:oData:Block(),,, DT_CENTER )
   ::oList:lHide := .T.
   ::oList:bLostFocus := {||::ListHide()}
   ::oList:bKeyDown := bKey
   ::oList:bClick := bClick
   ::aDrawn := {}

   ::Value( xValue )

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnCombo

   LOCAL n := Int( ::oBtn:nHeight/3 ) + 1

   ::oText:Paint( hDC )
   ::oBtn:Paint( hDC )
   IF Empty( ::arrowPen )
      ::arrowPen := HPen():Add( PS_SOLID, 1, ::arrowColor )
   ENDIF
   hwg_SelectObject( hDC, ::arrowPen:handle )
   hwg_MoveTo( hDC, ::oBtn:nLeft+n, ::oBtn:nTop+n+3 )
   hwg_LineTo( hDC, ::oBtn:nLeft+Int(::oBtn:nWidth/2), ::oBtn:nTop+::oBtn:nHeight-n )
   hwg_LineTo( hDC, ::oBtn:nLeft+::oBtn:nWidth-n, ::oBtn:nTop+n+2 )

   RETURN Nil

METHOD Value( xValue ) CLASS HDrawnCombo

   LOCAL lMulti := ( ValType( ::aItems[1] ) == "A" )

   IF xValue != Nil
      IF Valtype( xValue ) == "C"
         xValue := Iif( xValue == "", 0, Iif( lMulti, ;
            AScan( ::aItems, {|a|a[1] == xValue } ), AScan( ::aItems, {|s|s == xValue } ) ) )
      ENDIF
      IF xValue >= 0 .AND. xValue <= Len( ::aItems )
         ::xValue := xValue
         ::oText:title := Iif( ::xValue==0, "", Iif( lMulti, ::aItems[::xValue,1], ::aItems[::xValue] ) )
         ::oText:Refresh()
         //hwg_writelog( "val: " + ::oText:title + " " + str(::xValue) )
      ENDIF
   ENDIF

   RETURN Iif( ::lText, Iif(::xValue==0, "", ;
      Iif( lMulti, ::aItems[::xValue,1], ::aItems[::xValue] ) ), ::xValue )

METHOD ListShow() CLASS HDrawnCombo

   ::oList:oParent := ::GetParentBoard()
   ::oList:cargo := hwg_Window2Bitmap( ::oList:oParent:handle, ::oList:nLeft, ::oList:nTop, ;
      ::oList:nLeft+::oList:nWidth, ::oList:nTop+::oList:nHeight )
   AAdd( ::oList:oParent:aDrawn, ::oList )
   ::oList:lHide := .F.
   ::oList:Refresh()
   ::oList:SetFocus()

   RETURN Nil

METHOD ListHide() CLASS HDrawnCombo

   LOCAL bPaint := {|o,h|
      hwg_Drawbitmap( h, o:cargo,, o:nLeft, o:nTop )
      hwg_Deleteobject( o:cargo )
      o:cargo := Nil
      o:bPaint := Nil
      o:lHide := .T.
      o:Delete()
      //hwg_writelog("draw")
      RETURN .T.
   }

   ::oList:bPaint := bPaint
   ::oList:Refresh()
   //hwg_writelog("hidden")

   RETURN Nil

METHOD onKey( msg, wParam, lParam ) CLASS HDrawnCombo
   RETURN Nil

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnCombo
   RETURN Nil

METHOD onMouseLeave() CLASS HDrawnCombo
   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnCombo

   IF msg == WM_LBUTTONDOWN
      IF xPos > ::oBtn:nLeft .AND. xPos < ::oBtn:nLeft+::oBtn:nWidth .AND. yPos > ::oBtn:nTop .AND. yPos < ::oBtn:nTop+::oBtn:nHeight
         ::oBtn:nState := STATE_PRESSED
         IF ::oList:lHide
            ::ListShow()
         ELSE
            ::ListHide()
         ENDIF
         ::Refresh()
      ENDIF
   ENDIF
   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnCombo

   IF ::oBtn:nState == STATE_PRESSED
      ::oBtn:nState := STATE_NORMAL
      ::Refresh()
   ENDIF
   RETURN Nil
