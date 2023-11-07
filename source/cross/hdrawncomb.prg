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
   DATA  hBitmapList
   DATA  lDlg         INIT .F.
   DATA  oDlg

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
   ::aDrawn := {}

   ::Value( xValue )

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnCombo

   LOCAL n := Int( ::oBtn:nHeight/3 ) + 1

   IF ::lHide .OR. ::lDisable
      RETURN Nil
   ENDIF

   ::oText:Paint( hDC )
   ::oBtn:Paint( hDC )
   IF Empty( ::arrowPen )
      ::arrowPen := HPen():Add( PS_SOLID, 1, ::arrowColor )
   ENDIF
   hwg_SelectObject( hDC, ::arrowPen:handle )
   hwg_MoveTo( hDC, ::oBtn:nLeft+n, ::oBtn:nTop+n+3 )
   hwg_LineTo( hDC, ::oBtn:nLeft+Int(::oBtn:nWidth/2), ::oBtn:nTop+::oBtn:nHeight-n )
   hwg_LineTo( hDC, ::oBtn:nLeft+::oBtn:nWidth-n, ::oBtn:nTop+n+2, .T. )

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

   LOCAL oBoa := ::GetParentBoard(), nt, oBrw
#ifdef __GTK__
   LOCAL od
#endif
   LOCAL bKey := {|o,m,w|
      IF m == WM_KEYDOWN
         IF w == VK_ESCAPE
            ::ListHide()
            ::GetParentBoard():oInFocus := Nil
            RETURN .T.
         ELSEIF w == VK_RETURN
            ::Value( o:oData:Recno() )
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
            ::Value( o:oData:Recno() )
            ::oText:Refresh()
            ::ListHide()
            ::GetParentBoard():oInFocus := Nil
            EXIT
         ENDIF
      ENDDO
      RETURN .F.
   }

   IF ::nTop+::nHeight+::oList:nHeight > oBoa:nHeight
      ::lDlg := .T.
   ENDIF
   IF ::lDlg
#ifdef __GTK__
      od := hwg_GetParentForm(oBoa)
      nt := oBoa:nTop+::nTop+::nHeight + hwg_widget_get_top(od:handle) - hwg_getwindowPOS(od:handle)[2]
#else
      nt := oBoa:nTop+::nTop+::nHeight
#endif
      INIT DIALOG ::oDlg TITLE "" AT oBoa:nLeft+::oList:nLeft, nt ;
         SIZE ::oList:nWidth, ::oList:nHeight STYLE WND_NOTITLE + WND_NOSIZEBOX

      @ 0, 0 BOARD SIZE ::oDlg:nWidth, ::oDlg:nHeight
      @ 0, 0 DRAWN BROWSE oBrw SIZE ::oDlg:nWidth, ::oDlg:nHeight COLOR ::oList:tColor ;
         BACKCOLOR ::oList:bColor FONT ::oList:oFont
      oBrw:sepColor := ::oList:sepColor
      oBrw:tColorSel := ::oList:tColorSel
      oBrw:bColorSel := ::oList:bColorSel
      oBrw:oStyleCell := ::oList:oStyleCell
      oBrw:nBorder := ::oList:nBorder
      oBrw:aRowPadding[2] := ::oList:aRowPadding[2]
      oBrw:aRowPadding[4] := ::oList:aRowPadding[4]
      oBrw:oData := HDataArray():New( ::aItems )
      oBrw:AddColumn( "", oBrw:oData:Block(),,, DT_CENTER )

      oBrw:bKeyDown := bKey
      oBrw:bClick := bClick
      ::oDlg:bLostFocus := {||::ListHide()}
      oBrw:SetFocus()

#ifdef __GTK__
      ACTIVATE DIALOG ::oDlg
#else
      ACTIVATE DIALOG ::oDlg NOMODAL
#endif
   ELSE
      ::oList:oParent := oBoa
      ::hBitmapList := hwg_Window2Bitmap( ::oList:oParent:handle, ::oList:nLeft, ::oList:nTop, ;
         ::oList:nWidth, ::oList:nHeight )
      AAdd( ::oList:oParent:aDrawn, ::oList )
      ::oList:lHide := .F.
      ::oList:bKeyDown := bKey
      ::oList:bClick := bClick
      ::oList:Refresh()
      ::oList:SetFocus()
   ENDIF

   RETURN Nil

METHOD ListHide() CLASS HDrawnCombo

   LOCAL bPaint := {|o,h|
      hwg_Drawbitmap( h, ::hBitmapList,, o:nLeft, o:nTop )
      hwg_Deleteobject( ::hBitmapList )
      ::hBitmapList := Nil
      o:bPaint := Nil
      o:lHide := .T.
      o:Delete()
      RETURN .T.
   }

   IF ::lDlg
      IF !Empty( ::oDlg )
         ::oDlg:Close()
         ::oDlg := Nil
      ENDIF
   ELSE
      ::oList:bPaint := bPaint
      ::oList:Refresh()
   ENDIF

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

   DATA  nLower       INIT 1
   DATA  nUpper       INIT 999
   DATA  arr

   DATA  oEdit, oBtnUp, oBtnDown
   DATA  oTimer
   DATA  nPeriod      INIT 100
   DATA  arrowColor   INIT 0
   DATA  arrowPen

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, xInit, nLower, nUpper, bPaint, bChgState, arr )

   METHOD Paint( hDC )
   METHOD Value( xValue ) SETGET

   METHOD onKey( msg, wParam, lParam )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, xInit, nLower, nUpper, bPaint, bChgState, arr ) CLASS HDrawnUpDown

   LOCAL n := 1, nw := Int( nHeight*2/3 ), cPict

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, ;
      Iif(tcolor==Nil,CLR_BLACK,tcolor), Iif(bcolor==Nil,CLR_WHITE,bColor), aStyles,, oFont, bPaint,, bChgState )

   IF nLower != Nil
      ::nLower := nLower
   ENDIF
   IF nUpper != Nil
      ::nUpper := nUpper
   ENDIF

   ::xValue := Iif( xInit == Nil, ::nLower, xInit )
   IF ::xValue < ::nLower .OR. ::xValue > ::nUpper
      ::xValue := ::nLower
   ENDIF

   IF Valtype( arr ) == "A"
      ::arr := arr
      IF ::nUpper > Len( ::arr )
         ::nUpper := Len( ::arr )
      ENDIF
      IF ::nLower < 1 .OR. ::nLower > ::nUpper
         ::nLower := 1
      ENDIF
      IF ::xValue < ::nLower .OR. ::xValue > ::nUpper
         ::xValue := ::nLower
      ENDIF
   ELSEIF Valtype( ::xValue ) == "N"
      nUpper := ::nUpper
      DO WHILE ( nUpper := (nUpper / 10) ) >= 1
         n ++
      ENDDO
      cPict := Replicate( '9', n )
   ELSEIF Valtype( ::xValue ) == "D"
      cPict := "@D"
   ENDIF

   ::oEdit := HDrawnEdit():New( Self, ::nLeft, ::nTop, ::nWidth-nw+1, ::nHeight, ::tcolor, ::bColor, ;
      oFont, Iif( !Empty(::arr), ::arr[::xValue], ::xValue ), cPict )
   IF !Empty( ::arr )
      ::oEdit:lReadOnly := .T.
   ENDIF
   ::oEdit:nTextStyle := DT_RIGHT

   nHeight := Int( nHeight / 2 )
   ::oBtnUp := HDrawn():New( Self, ::nLeft+::nWidth-nw, ::nTop, nw, nHeight, ;
      ::tcolor, ::bColor, aStyles, "", ::oFont )
   ::oBtnDown := HDrawn():New( Self, ::nLeft+::nWidth-nw, ::nTop+nHeight-1, nw, nHeight, ;
      ::tcolor, ::bColor, aStyles, "", ::oFont )

   ::aDrawn := {}

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnUpDown

   LOCAL n := Int( ::oBtnUp:nHeight/3 ) + 1

   IF ::lHide .OR. ::lDisable
      RETURN Nil
   ENDIF

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
         ::oEdit:Value := Iif( !Empty(::arr), ::arr[xValue], xValue )
      ENDIF
   ENDIF

   RETURN Iif( !Empty(::arr), ::xValue, ::oEdit:Value )

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

   RETURN ::Super:onMouseMove( xPos, yPos )

METHOD onMouseLeave() CLASS HDrawnUpDown

   ::onButtonUp()
   RETURN ::Super:onMouseLeave()

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
         ::oEdit:onButtonDown( msg, xPos, yPos )
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

CLASS HDateSelect INHERIT HBoard

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, color, bcolor, oFont, ;
               dValue, bSize, bPaint, bChange  )
   METHOD bChange ( b ) SETGET
   METHOD Value ( xValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, color, bcolor, oFont, ;
               dValue, bSize, bPaint, bChange ) CLASS HDateSelect

   color := Iif( color == Nil, CLR_BLACK, color )
   bColor := Iif( bColor == Nil, CLR_WHITE, bColor )
   ::Super:New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont,, ;
              bSize, bPaint,, color, bcolor, .T. )

   HDrawnDate():New( Self, 0, 0, nWidth, nHeight, color, bcolor,, oFont, ;
               dValue, bPaint, bChange )

   RETURN Self

METHOD bChange ( b ) CLASS HDateSelect

   IF !Empty( b )
      ::aDrawn[1]:bChange := b
   ENDIF

   RETURN ::aDrawn[1]:bCli

METHOD Value( xValue ) CLASS HDateSelect

   RETURN ::aDrawn[1]:Value( xValue )

CLASS HDrawnDate INHERIT HDrawn

   DATA  oEdit, oBtn, oList
   DATA  oFontCalen
   DATA  arrowColor   INIT 0
   DATA  arrowPen
   DATA  bChange

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, dValue, bPaint, bChange, bChgState )

   METHOD Paint( hDC )
   METHOD Value( xValue ) SETGET

   METHOD ListShow()
   METHOD ListHide()

   METHOD onKey( msg, wParam, lParam )
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, aStyles, ;
               oFont, dValue, bPaint, bChange, bChgState ) CLASS HDrawnDate

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      , oFont, bPaint,, bChgState )

   ::xValue := Iif( Empty( dValue ), Date(), dValue )
   ::bChange := bChange

   ::oEdit := HDrawnEdit():New( Self, ::nLeft, ::nTop, ::nWidth-::nHeight+1, ::nHeight, ::tcolor, ::bColor, ;
      ::oFont, ::xValue )
   IF !Empty( ::oFont )
      ::oFontCalen := HFont():Add( ::oFont:name,, ::oFont:height-3,, ::oFont:Charset,,,,, .T. )
   ENDIF

   ::oEdit:nTextStyle := DT_LEFT
   ::oBtn := HDrawn():New( Self, ::nLeft+::nWidth-::nHeight, ::nTop, ::nHeight, ::nHeight, ::tcolor, ::bColor,, ;
      "", ::oFont )
   ::aDrawn := {}

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnDate

   LOCAL n := Int( ::oBtn:nHeight/3 ) + 1

   IF ::lHide .OR. ::lDisable
      RETURN Nil
   ENDIF

   ::oEdit:Paint( hDC )
   ::oBtn:Paint( hDC )
   IF Empty( ::arrowPen )
      ::arrowPen := HPen():Add( PS_SOLID, 1, ::arrowColor )
   ENDIF
   hwg_SelectObject( hDC, ::arrowPen:handle )
   hwg_MoveTo( hDC, ::oBtn:nLeft+n, ::oBtn:nTop+n+3 )
   hwg_LineTo( hDC, ::oBtn:nLeft+Int(::oBtn:nWidth/2), ::oBtn:nTop+::oBtn:nHeight-n )
   hwg_LineTo( hDC, ::oBtn:nLeft+::oBtn:nWidth-n, ::oBtn:nTop+n+2, .T. )

   RETURN Nil

METHOD Value( xValue ) CLASS HDrawnDate

   IF xValue != Nil
      ::xValue := xValue
      ::oEdit:Value := xValue
      ::oEdit:Refresh()
   ENDIF

   RETURN ::oEdit:Value

METHOD ListShow() CLASS HDrawnDate

   LOCAL oBoa, oMC, arr, nw, nh, nt, oFont
#ifdef __GTK__
   LOCAL hDC, od
#endif
   LOCAL bChange := {||
      LOCAL dValue
      IF !Empty( oMC ) .AND. !Empty( oMC:handle )
         dValue := hwg_getmonthcalendardate( oMC:handle )
         IF Day( dValue ) != Day( ::xValue )
            ::Value := dValue
            IF !Empty( ::bChange )
               Eval( ::bChange )
            ENDIF
            ::ListHide()
         ENDIF
      ENDIF
      RETURN .T.
   }

   IF !Empty( ::oList )
      RETURN Nil
   ENDIF

   oBoa := ::GetParentBoard()

   oFont := Iif( Empty(::oFontCalen), ::oFont, ::oFontCalen )
#ifdef __GTK__
   od := hwg_GetParentForm(oBoa)
   IF !Empty( oFont )
      hDC := hwg_Getdc( oBoa:handle )
      hwg_Selectobject( hDC,oFont:handle )
      arr := hwg_GetTextSize( hDC, "24x25x26x27x28x29x30" )
      hwg_Releasedc( oBoa:handle, hDC )
      nw := arr[1] + 24
      nh := arr[2] * 18
      //hwg_writelog( "1: "+str(arr[1])+" "+str(arr[2]) )
      //hwg_writelog( "2: "+str(nw)+" "+str(nh) )
   ELSE
      nw := nh := ::nWidth
   ENDIF
   nt := oBoa:nTop+::nTop+::nHeight + hwg_widget_get_top(od:handle) - hwg_getwindowPOS(od:handle)[2]
#else
   nw := nh := ::nWidth
   nt := oBoa:nTop+::nTop+::nHeight
#endif
   INIT DIALOG ::oList TITLE "" AT oBoa:nLeft+::nLeft, nt ;
      SIZE nw, nh STYLE WND_NOTITLE + WND_NOSIZEBOX

   ::oList:bLostFocus := {||::ListHide()}
   @ 0, 0 MONTHCALENDAR oMC SIZE ::oList:nWidth, ::oList:nHeight INIT ::xValue ;
      ON CHANGE bChange FONT oFont

#ifdef __GTK__
   ACTIVATE DIALOG ::oList
#else
   ACTIVATE DIALOG ::oList NOMODAL
   arr := hwg_getMonthCalendarSize( oMC:handle )
   ::oList:nWidth := arr[1]
   ::oList:nHeight := arr[2]
   hwg_MoveWindow( ::oList:handle,,, arr[1], arr[2] )
   oMC:Move( ,, arr[1], arr[2] )
#endif
   RETURN Nil

METHOD ListHide() CLASS HDrawnDate

   IF !Empty( ::oList )
      ::oList:Close()
      ::oList := Nil
      RETURN Nil
   ENDIF

   RETURN Nil

METHOD onKey( msg, wParam, lParam ) CLASS HDrawnDate
   RETURN ::oEdit:onKey( msg, wParam, lParam )

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnDate

   IF msg == WM_LBUTTONDOWN
      IF xPos > ::oBtn:nLeft .AND. xPos < ::oBtn:nLeft+::oBtn:nWidth .AND. yPos > ::oBtn:nTop .AND. yPos < ::oBtn:nTop+::oBtn:nHeight
         ::oBtn:nState := STATE_PRESSED
         IF Empty( ::oList )
            ::ListShow()
         ELSE
            ::ListHide()
         ENDIF
         ::Refresh()
      ELSE
         ::oEdit:onButtonDown( msg, xPos, yPos )
      ENDIF
   ENDIF
   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnDate

   HB_SYMBOL_UNUSED(xPos)
   HB_SYMBOL_UNUSED(yPos)

   IF ::oBtn:nState == STATE_PRESSED
      ::oBtn:nState := STATE_NORMAL
      ::Refresh()
   ENDIF
   RETURN Nil
