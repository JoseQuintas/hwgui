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
   DATA  lText        INIT .F.
   DATA  oText, oBtn, oList
   DATA  arrowColor   INIT 0
   DATA  arrowPen
   DATA  nRowCount    INIT 3
   DATA  bChange

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, aItems, xValue, lText, bPaint, bChange, bChgState, nRowCount )

   METHOD Paint( hDC )
   METHOD Value( xValue ) SETGET

   METHOD ListShow()
   METHOD ListHide()

   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, aItems, xValue, lText, bPaint, bChange, bChgState, nRowCount ) CLASS HDrawnCombo

   LOCAL bKey := {|o,m,w|
      HB_SYMBOL_UNUSED(o)
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
      HB_SYMBOL_UNUSED(x)
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
   ::xValue := 0
   IF Valtype( lText ) == "L"; ::lText := lText; ENDIF
   IF nRowCount != Nil; ::nRowCount := nRowCount; ENDIF
   ::bChange := bChange

   ::oText := HDrawn():New( Self, ::nLeft, ::nTop, ::nWidth-::nHeight+1, ::nHeight, ::tcolor, ::bColor, ::aStyles, ;
      "", ::oFont )
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

   HB_SYMBOL_UNUSED(xPos)
   HB_SYMBOL_UNUSED(yPos)

   IF ::oBtn:nState == STATE_PRESSED
      ::oBtn:nState := STATE_NORMAL
      ::Refresh()
   ENDIF
   RETURN Nil

CLASS HDrawnUpDown INHERIT HDrawn

   DATA  nLower       INIT 0
   DATA  nUpper       INIT 999

   DATA  oEdit, oBtnUp, oBtnDown
   DATA  oTimer
   DATA  nPeriod      INIT 100
   DATA  arrowColor   INIT 0
   DATA  arrowPen

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, nLower, nUpper, bPaint, bChgState )

   METHOD Paint( hDC )
   METHOD Value( xValue ) SETGET

   METHOD onKey( msg, wParam, lParam )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, nLower, nUpper, bPaint, bChgState ) CLASS HDrawnUpDown

   LOCAL n := 1, nw := Int( nHeight*2/3 )

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, ;
      Iif(tcolor==Nil,CLR_BLACK,tcolor), Iif(bcolor==Nil,CLR_WHITE,bColor), aStyles,, oFont, bPaint,, bChgState )

   IF nLower != Nil
      ::nLower := nLower
   ENDIF
   IF nUpper != Nil
      ::nUpper := nUpper
   ENDIF

   ::xValue := ::nLower
   nUpper := ::nUpper
   DO WHILE ( nUpper := (nUpper / 10) ) >= 1
      n ++
   ENDDO

   ::oEdit := HDrawnEdit():New( Self, ::nLeft, ::nTop, ::nWidth-nw+1, ::nHeight, ::tcolor, ::bColor, ;
      oFont, ::xValue, Replicate( '9', n ) )
   ::oEdit:nTextStyle := DT_RIGHT
   nHeight := Int( nHeight / 2 )
   ::oBtnUp := HDrawn():New( Self, ::nLeft+::nWidth-::nHeight, ::nTop, nw, nHeight, ;
      ::tcolor, ::bColor, aStyles, "", ::oFont )
   ::oBtnDown := HDrawn():New( Self, ::nLeft+::nWidth-::nHeight, ::nTop+nHeight-1, nw, nHeight, ;
      ::tcolor, ::bColor, aStyles, "", ::oFont )

   ::aDrawn := {}

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnUpDown

   LOCAL n := Int( ::oBtnUp:nHeight/3 ) + 1

   IF Empty( ::aStyles )
      ::aStyles := ::oBtnUp:aStyles := ::oBtnDown:aStyles := ;
         { HStyle():New( {CLR_GRAY3,CLR_WHITE}, 1 ), HStyle():New( {CLR_GRAY3,CLR_WHITE}, 2 ) }
   ENDIF
   ::oEdit:Paint( hDC )
   ::oBtnUp:Paint( hDC )
   ::oBtnDown:Paint( hDC )
   IF Empty( ::arrowPen )
      ::arrowPen := HPen():Add( PS_SOLID, 1, ::arrowColor )
   ENDIF
   hwg_SelectObject( hDC, ::arrowPen:handle )

   hwg_MoveTo( hDC, ::oBtnUp:nLeft+n, ::oBtnUp:nTop+::oBtnUp:nHeight-n-1 )
   hwg_LineTo( hDC, ::oBtnUp:nLeft+Int(::oBtnUp:nWidth/2), ::oBtnUp:nTop+n )
   hwg_LineTo( hDC, ::oBtnUp:nLeft+::oBtnUp:nWidth-n, ::oBtnUp:nTop+::oBtnUp:nHeight-n, .T. )

   hwg_MoveTo( hDC, ::oBtnDown:nLeft+n, ::oBtnDown:nTop+n+1 )
   hwg_LineTo( hDC, ::oBtnDown:nLeft+Int(::oBtnDown:nWidth/2), ::oBtnDown:nTop+::oBtnDown:nHeight-n )
   hwg_LineTo( hDC, ::oBtnDown:nLeft+::oBtnDown:nWidth-n, ::oBtnDown:nTop+n, .T. )

   RETURN Nil

METHOD Value( xValue ) CLASS HDrawnUpDown

   IF xValue != Nil
      IF xValue >= ::nLower .AND. xValue <= ::nUpper
         ::xValue := xValue
         ::oEdit:Value := xValue
      ENDIF
   ENDIF

   RETURN ::oEdit:Value

METHOD onKey( msg, wParam, lParam ) CLASS HDrawnUpDown
   RETURN ::oEdit:onKey( msg, wParam, lParam )

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnUpDown

   LOCAL l := .F.
   IF ::oBtnUp:nState == STATE_PRESSED
      IF !( xPos > ::oBtnUp:nLeft .AND. xPos < ::oBtnUp:nLeft+::oBtnUp:nWidth .AND. ;
         yPos > ::oBtnUp:nTop .AND. yPos < ::oBtnUp:nTop+::oBtnUp:nHeight )
         ::oBtnUp:nState := STATE_NORMAL
         l := .T.
         ::oBtnUp:Refresh()
      ENDIF
   ELSEIF ::oBtnDown:nState == STATE_PRESSED
      IF !( xPos > ::oBtnDown:nLeft .AND. xPos < ::oBtnDown:nLeft+::oBtnDown:nWidth .AND. ;
         yPos > ::oBtnDown:nTop .AND. yPos < ::oBtnDown:nTop+::oBtnDown:nHeight )
         ::oBtnDown:nState := STATE_NORMAL
         l := .T.
         ::oBtnDown:Refresh()
      ENDIF
   ENDIF
   IF l
      IF !Empty( ::oTimer )
         ::oTimer:End()
         ::oTimer := Nil
      ENDIF
   ENDIF

   RETURN Nil

METHOD onMouseLeave() CLASS HDrawnUpDown

   ::onButtonUp()
   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnUpDown

   LOCAL nVal := ::Value
   IF msg == WM_LBUTTONDOWN
      IF xPos > ::oBtnUp:nLeft .AND. xPos < ::oBtnUp:nLeft+::oBtnUp:nWidth .AND. yPos > ::oBtnUp:nTop .AND. yPos < ::oBtnUp:nTop+::oBtnUp:nHeight
         ::oBtnUp:nState := STATE_PRESSED
         IF ++nVal > ::nUpper
            nVal := ::nUpper
         ENDIF
         ::Value := nVal
         ::oTimer := HTimer():New( ::GetParentBoard(),, ::nPeriod, {|o|UpDownTimerProc(o,::oBtnUp)} )
         ::oTimer:cargo := 8
      ELSEIF xPos > ::oBtnDown:nLeft .AND. xPos < ::oBtnDown:nLeft+::oBtnDown:nWidth .AND. yPos > ::oBtnDown:nTop .AND. yPos < ::oBtnDown:nTop+::oBtnDown:nHeight
         ::oBtnDown:nState := STATE_PRESSED
         IF --nVal < ::nLower
            nVal := ::nLower
         ENDIF
         ::Value := nVal
         ::oTimer := HTimer():New( ::GetParentBoard(),, ::nPeriod, {|o|UpDownTimerProc(o,::oBtnDown)} )
         ::oTimer:cargo := 8
      ELSE
         ::oEdit:SetFocus()
      ENDIF
   ENDIF
   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnUpDown

   HB_SYMBOL_UNUSED(xPos)
   HB_SYMBOL_UNUSED(yPos)

   IF ::oBtnUp:nState == STATE_PRESSED
      ::oBtnUp:nState := STATE_NORMAL
      ::Refresh()
   ELSEIF ::oBtnDown:nState == STATE_PRESSED
      ::oBtnDown:nState := STATE_NORMAL
      ::Refresh()
   ENDIF
   IF !Empty( ::oTimer )
      ::oTimer:End()
      ::oTimer := Nil
   ENDIF

   RETURN Nil

STATIC FUNCTION UpDownTimerProc( op, oBtn )

   LOCAL o := oBtn:oParent, nVal := o:Value

   HB_SYMBOL_UNUSED(op)
   IF o:oTimer:cargo > 0
      o:oTimer:cargo --
      RETURN Nil
   ENDIF
   IF oBtn == o:oBtnUp
      IF ++nVal > o:nUpper
         nVal := o:nUpper
      ENDIF
      o:Value := nVal

   ELSEIF oBtn == o:oBtnDown
      IF --nVal < o:nLower
         nVal := o:nLower
      ENDIF
      o:Value := nVal
   ENDIF

   RETURN Nil
