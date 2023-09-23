/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDrawn class
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define  STATE_NORMAL    0
#define  STATE_PRESSED   1
#define  STATE_MOVER     2
#define  STATE_UNPRESS   3

#define CLR_BLACK    0
#define CLR_LYELLOW  0xFFFFD9

CLASS HDrawn INHERIT HObject

   CLASS VAR oDefParent SHARED
   CLASS VAR oFontTool  SHARED
   CLASS VAR tColorTool SHARED  INIT CLR_BLACK
   CLASS VAR bColorTool SHARED  INIT CLR_LYELLOW
   DATA oParent
   DATA title
   DATA nTop, nLeft, nWidth, nHeight
   DATA nTextStyle    INIT DT_CENTER
   DATA tcolor, bcolor, oBrush, oPen
   DATA tBorderColor  INIT Nil
   DATA lHide         INIT .F.
   DATA lStatePaint   INIT .F.
   DATA nState        INIT 0
   DATA oFont
   DATA aStyles
   DATA aDrawn        INIT {}
   DATA xValue        INIT Nil
   DATA nMouseOn      INIT 0
   DATA cTooltip, oTooltip, hBitmapTmp

   DATA bPaint, bClick, bChgState

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState )
   METHOD Delete()
   METHOD GetParentBoard()
   METHOD GetByPos( xPos, yPos, oBoard )
   METHOD GetByState( nState, aDrawn, block, lAll )
   METHOD Paint( hDC )
   METHOD Move( x1, y1, width, height )
   METHOD SetState( nState, nPosX, nPosY )
   METHOD SetText( cText )
   METHOD Value( xValue ) SETGET
   METHOD Refresh( x1, y1, x2, y2 )
   METHOD ShowTooltip( lShow, xPos, yPos )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )     VIRTUAL
   METHOD onButtonDbl( xPos, yPos )  VIRTUAL
   METHOD onKey( msg, wParam, lParam ) VIRTUAL
   METHOD onKillFocus()  VIRTUAL
   METHOD End()          VIRTUAL

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
   title, oFont, bPaint, bClick, bChgState ) CLASS HDrawn

   ::oParent := Iif( oWndParent==Nil, ::oDefParent, oWndParent )
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::tcolor  := Iif( tcolor == Nil, 0, tcolor )
   ::bColor  := bColor
   ::aStyles := aStyles
   ::title   := title
   ::oFont   := Iif( oFont == Nil, ::oParent:oFont, oFont )
   ::bPaint  := bPaint
   ::bClick  := bClick
   ::bChgState := bChgState

   IF bColor != NIL
      ::oBrush := HBrush():Add( bColor )
   ENDIF

   AAdd( ::oParent:aDrawn, Self )

   RETURN Self

METHOD Delete() CLASS HDrawn

   LOCAL i

   FOR i := Len( ::oParent:aDrawn ) TO 1 STEP -1
      IF ::oParent:aDrawn[i] == Self
         ::oParent:aDrawn := hb_ADel( ::oParent:aDrawn, i, .T. )
         EXIT
      ENDIF
   NEXT

   RETURN Nil

METHOD GetParentBoard() CLASS HDrawn

   LOCAL oParent := ::oParent

   DO WHILE __ObjHasMsg( oParent, "GETPARENTBOARD" ); oParent := oParent:oParent; ENDDO

   RETURN oParent

METHOD GetByPos( xPos, yPos, oBoard ) CLASS HDrawn

   LOCAL aDrawn := Iif( !Empty( oBoard ), oBoard:aDrawn, ::aDrawn ), i, o

   FOR i := Len( aDrawn ) TO 1 STEP -1
      o := aDrawn[i]
      IF xPos >= o:nLeft .AND. xPos < o:nLeft + o:nWidth .AND. ;
         yPos >= o:nTop .AND. yPos < o:nTop + o:nHeight
         RETURN o
      ENDIF
   NEXT

   RETURN Nil

METHOD GetByState( nState, aDrawn, block, lAll ) CLASS HDrawn

   LOCAL i, o

   IF Empty( aDrawn )
      aDrawn := ::aDrawn
   ENDIF
   IF lAll == Nil .OR. block == Nil; lAll := .F.; ENDIF

   FOR i := Len( aDrawn ) TO 1 STEP -1
      IF !Empty( aDrawn[i]:aDrawn )
         IF !Empty( o := aDrawn[i]:GetByState( nState,, block, lAll ) ) .AND. !lAll
            RETURN o
         ENDIF
      ENDIF
      IF aDrawn[i]:nState == nState
         IF block != Nil
            Eval( block, aDrawn[i] )
         ENDIF
         IF !lAll
            RETURN aDrawn[i]
         ENDIF
      ENDIF
   NEXT

   RETURN Nil

METHOD Paint( hDC ) CLASS HDrawn

   LOCAL i, oStyle

   IF ::lHide
      RETURN Nil
   ENDIF
   IF !Empty( ::bPaint )
      IF Eval( ::bPaint, Self, hDC ) == 0
         RETURN Nil
      ENDIF
   ELSE
      IF !Empty( ::aStyles )
        oStyle := Iif( Len(::aStyles) > ::nState, ::aStyles[::nState + 1], ATail(::aStyles) )
      ENDIF
      IF !Empty( oStyle )
         oStyle:Draw( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1 )
      ELSEIF !Empty( ::oBrush )
         IF Empty( ::oPen )
            ::oPen := HPen():Add( BS_SOLID, 1, Iif( ::tBorderColor == Nil, ::bcolor, ::tBorderColor ) )
         ENDIF
         hwg_RoundRect_Filled( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, 4, ::oPen:handle, ::oBrush:handle )
      ENDIF
      IF !Empty( ::title )
         hwg_Settransparentmode( hDC, .T. )
         hwg_Settextcolor( hDC, ::tColor )
         IF !Empty( ::oFont )
            hwg_SelectObject( hDC, ::oFont:handle )
         ENDIF
         hwg_Drawtext( hDC, ::title, ::nLeft+4, ::nTop+6, ::nLeft+::nWidth-4, ::nTop+::nHeight-6, ::nTextStyle )
         hwg_Settransparentmode( hDC, .F. )
      ENDIF
   ENDIF

   FOR i := 1 TO Len( ::aDrawn )
      ::aDrawn[i]:Paint( hDC )
   NEXT

   RETURN Nil

METHOD Move( x1, y1, width, height ) CLASS HDrawn

   IF x1 != Nil; ::nLeft := x1; ENDIF
   IF y1 != Nil; ::nTop := y1; ENDIF
   IF width != Nil; ::nWidth := width; ENDIF
   IF height != Nil; ::nHeight := height; ENDIF

   RETURN Nil

METHOD SetState( nState, nPosX, nPosY ) CLASS HDrawn

   LOCAL o, nOldstate := ::nState, op

   IF !Empty( ::aDrawn )
      //IF nOldstate != nState; hwg_writelog( "1> " + Iif(Empty(::title),'!',::title) + " " + str(nOldState) + " " + str( nState ) ); ENDIF
      IF  !Empty( o := ::GetByPos( nPosX, nPosY ) )
         IF nOldstate != nState .AND. !Empty( ::bChgState ) .AND. Eval( ::bChgState, Self, nState ) == 0
            RETURN Nil
         ENDIF
         IF nState != STATE_PRESSED
            ::nState := nState
         ENDIF
         //IF nOldstate != nState; hwg_writelog( "2> " + Iif(Empty(::title),'!',::title) + " " + str(nOldState) + " " + str( nState ) ); ENDIF
         RETURN o:SetState( nState, nPosX, nPosY )
      ELSEIF !Empty( o := ::GetByState( STATE_MOVER ) ) .OR. !Empty( o := ::GetByState( STATE_PRESSED ) )
         o:SetState( STATE_NORMAL, nPosX, nPosY )
      ENDIF
   ENDIF
   IF nState != nOldstate
      //IF nOldstate != nState; hwg_writelog( "3> " + Iif(Empty(::title),'!',::title) + " " + str(nOldState) + " " + str( nState ) ); ENDIF
      IF !Empty( ::bChgState )
         IF Eval( ::bChgState, Self, nState ) == 0
            RETURN Nil
         ENDIF
      ENDIF
      IF nState == STATE_MOVER
         IF ( o := ::GetByState( STATE_MOVER, ::oParent:aDrawn ) ) != Nil
            o:SetState( STATE_NORMAL, nPosX, nPosY )
         ENDIF
         IF ::nState != STATE_PRESSED
            ::nState := STATE_MOVER
         ENDIF
      ELSEIF nState == STATE_NORMAL
         IF ::nState == STATE_MOVER .OR. ::nState == STATE_PRESSED
            ::onMouseLeave()
         ENDIF
         ::nState := STATE_NORMAL
      ELSEIF nState == STATE_PRESSED
         ::nState := STATE_PRESSED
      ELSEIF nState == STATE_UNPRESS
         op := HDrawn():GetByState( STATE_PRESSED, ::oParent:aDrawn )
         ::nState := Iif( nPosX >= ::nLeft .AND. nPosX < ::nLeft + ::nWidth .AND. ;
            nPosY >= ::nTop .AND. nPosY < ::nTop + ::nHeight, STATE_MOVER, STATE_NORMAL )
         IF Self == op
            IF !Empty( ::bClick )
               Eval( ::bClick, Self, nPosX, nPosY )
            ENDIF
         ELSEIF !Empty( op )
            op:nState := Iif( nPosX >= op:nLeft .AND. nPosX < op:nLeft + op:nWidth .AND. ;
               nPosY >= op:nTop .AND. nPosY < op:nTop + op:nHeight, STATE_MOVER, STATE_NORMAL )
         ENDIF
      ENDIF
      IF nOldstate != ::nState .AND. ( ::lStatePaint .OR. ( !Empty(::aStyles) .AND. Len(::aStyles) > 1 ) )
         ::Refresh()
      ENDIF
   ENDIF

   RETURN Nil

METHOD SetText( cText ) CLASS HDrawn

   ::title := cText
   ::Refresh()

   RETURN Nil

METHOD Value( xValue ) CLASS HDrawn

   IF xValue != Nil
      ::xValue := xValue
      ::Refresh()
      RETURN xValue
   ENDIF

   RETURN ::xValue

METHOD Refresh( x1, y1, x2, y2 ) CLASS HDrawn

   hwg_Invalidaterect( ::GetParentBoard():handle, 0, Iif( x1 == Nil, ::nLeft, x1 ), ;
      Iif( y1 == Nil, ::nTop, y1 ), Iif( x2 == Nil, ::nLeft+::nWidth, x2 ), ;
      Iif( y2 == Nil, ::nTop+::nHeight, y2 ) )
   RETURN Nil

METHOD ShowTooltip( lShow, xPos, yPos ) CLASS HDrawn

   LOCAL oBoa, hDC, arr, nw, nh
   LOCAL bPaint := {|o,h|
      IF Empty( o:title )
         hwg_Drawbitmap( h, ::hBitmapTmp,, o:nLeft, o:nTop )
         hwg_Deleteobject( ::hBitmapTmp )
         ::hBitmapTmp := Nil
         o:lHide := .T.
         o:Delete()
      ELSE
         hwg_RoundRect_Filled( h, o:nLeft, o:nTop, o:nLeft+o:nWidth-1, o:nTop+o:nHeight-1, 4, ;
            .F., o:oBrush:handle )
         hwg_Settransparentmode( h, .T. )
         hwg_Settextcolor( h, o:tColor )
         IF !Empty( o:oFont )
            hwg_SelectObject( h, o:oFont:handle )
         ENDIF
         hwg_Drawtext( h, o:title, o:nLeft+4, o:nTop+2, o:nLeft+o:nWidth-4, o:nTop+o:nHeight-4 )
         hwg_Settransparentmode( h, .F. )
      ENDIF
      ::Refresh()
      RETURN 0
   }

   IF lShow
      //hwg_writelog( "show tool" )
      IF ::nMouseOn > 86400
         RETURN Nil
      ELSEIF Empty( ::oTooltip )
         IF Empty( ::oFontTool )
            ::oFontTool := ::oFont
         ENDIF
         ::oTooltip := HDrawn():New( ::oParent, xPos, yPos, 1, 1, ;
            ::tcolorTool, ::bColorTool,, "", ::oFontTool )
      ELSEIF ::oTooltip:lHide
         ::oTooltip:lHide := .F.
      ELSE
         RETURN Nil
      ENDIF

      oBoa := ::GetParentBoard()
      hDC := hwg_Getdc( oBoa:handle )
      arr := hwg_GetTextSize( hDC, ::cTooltip )
      nw := arr[1] + 8
      nh := arr[2] + 4
      IF xPos + 2 + nw <= oBoa:nWidth
         ::oTooltip:nLeft := xPos + 2
      ELSEIF nw < oBoa:nWidth
         ::oTooltip:nLeft := oBoa:nWidth - nw
      ELSE
         ::oTooltip:nLeft := 2
         nw := oBoa:nWidth - 4
      ENDIF
      IF ::nTop + ::nHeight + nh <= oBoa:nHeight
         ::oTooltip:nTop := ::nTop + ::nHeight
      ELSEIF ::nTop - nh > 0
         ::oTooltip:nTop := ::nTop - nh
      ELSEIF yPos + 4 + nh <= oBoa:nHeight
         ::oTooltip:nTop := yPos + 4
      ELSEIF yPos - 4 - nh > 0
         ::oTooltip:nTop := yPos - 4 - nh
      ELSE
         ::oTooltip:nTop := ::nTop + 2
      ENDIF
      hwg_Releasedc( oBoa:handle, hDC )
      ::oTooltip:nWidth  := nw
      ::oTooltip:nHeight := nh
      ::hBitmapTmp := hwg_Window2Bitmap( oBoa:handle, ::oTooltip:nLeft, ::oTooltip:nTop, ;
         ::oTooltip:nWidth, ::oTooltip:nHeight )
      //hwg_SaveBitmap( "h.bmp", ::hBitmapTmp )
      AAdd( oBoa:aDrawn, ::oTooltip )
      ::oTooltip:bPaint := bPaint
      ::oTooltip:SetText( ::cTooltip )
   ELSEIF !Empty( ::oTooltip ) .AND. !::oTooltip:lHide
      ::oTooltip:SetText( "" )
   ENDIF

   RETURN Nil

METHOD onMouseMove( xPos, yPos ) CLASS HDrawn

   IF ::cToolTip != Nil
      IF ::nMouseOn == 0
         ::nMouseOn := Seconds()
         HTimer():New( ::GetParentBoard(),, 500, {||::ShowTooltip( .T., xPos, yPos )}, .T. )
      //ELSEIF Seconds() - ::nMouseOn > 0.3 .AND. ( Empty( ::oTooltip ) .OR. ::oTooltip:lHide )
      //   ::nMouseOn := 90000
      //   ::ShowTooltip( .T., xPos, yPos )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onMouseLeave() CLASS HDrawn

   ::nMouseOn := 0
   IF ::cToolTip != Nil
      ::ShowTooltip( .F. )
   ENDIF
   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawn

   LOCAL o

   IF ( o := ::GetByPos( xPos, yPos ) ) != Nil
      o:onButtonDown( msg, xPos, yPos )
   ENDIF
   IF ::cToolTip != Nil
      ::nMouseOn := 90000
      ::ShowTooltip( .F. )
   ENDIF

   RETURN Nil

CLASS HDrawnCheck INHERIT HDrawn

   DATA cForTitle   INIT 'x'

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState )
   METHOD SetState( nState, nPosX, nPosY )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState ) CLASS HDrawnCheck

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      ' ', oFont, bPaint, bClick, bChgState )

   IF !Empty( title )
      ::cForTitle := title
   ENDIF
   ::xValue := .F.

   RETURN Self

METHOD SetState( nState, nPosX, nPosY ) CLASS HDrawnCheck

   IF nState == STATE_UNPRESS .AND. ::nState == STATE_PRESSED
      ::xValue := !::xValue
      ::title := Iif( ::xValue, ::cForTitle, ' ' )
      ::Refresh()
   ENDIF

   RETURN ::Super:SetState( nState, nPosX, nPosY )

CLASS HDrawnRadio INHERIT HDrawn

   DATA cForTitle   INIT 'o'
   DATA xGroup

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState, xGroup, lInitVal )
   METHOD SetState( nState, nPosX, nPosY )
   METHOD GetGroupValue()
   METHOD SetGroupValue( nVal )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState, xGroup, lInitVal ) CLASS HDrawnRadio

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      ' ', oFont, bPaint, bClick, bChgState )

   IF !Empty( title )
      ::cForTitle := title
   ENDIF
   ::xValue := Iif( lInitVal == Nil, .F., lInitVal )
   IF !Empty( ::xValue )
      ::title := ::cForTitle
   ENDIF
   ::xGroup := xGroup

   RETURN Self

METHOD SetState( nState, nPosX, nPosY ) CLASS HDrawnRadio

   IF nState == STATE_UNPRESS .AND. ::nState == STATE_PRESSED .AND. !::xValue
      ::SetGroupValue()
      ::title := ::cForTitle
      ::Refresh()
   ENDIF

   RETURN ::Super:SetState( nState, nPosX, nPosY )

METHOD GetGroupValue() CLASS HDrawnRadio

   LOCAL i, aDrawn := ::oParent:aDrawn, xGroup := ::xGroup, nVal := 0

   FOR i := 1 TO Len( aDrawn )
      IF __ObjHasMsg( aDrawn[i], "XGROUP" ) .AND. Valtype(aDrawn[i]:xGroup) == Valtype(xGroup) ;
         .AND. aDrawn[i]:xGroup == xGroup
         nVal ++
         IF aDrawn[i]:xValue
            RETURN nVal
         ENDIF
      ENDIF
   NEXT

   RETURN 0

METHOD SetGroupValue( nVal ) CLASS HDrawnRadio

   LOCAL i, aDrawn := ::oParent:aDrawn, xGroup := ::xGroup, n := 0, o

   IF nVal != Nil .AND. ( Valtype( nVal ) != "N" .OR. nVal <= 0 )
      RETURN 0
   ENDIF
   FOR i := 1 TO Len( aDrawn )
      IF __ObjHasMsg( aDrawn[i], "XGROUP" ) .AND. Valtype(aDrawn[i]:xGroup) == Valtype(xGroup) ;
         .AND. aDrawn[i]:xGroup == xGroup
         n ++
         IF aDrawn[i]:xValue
            o := aDrawn[i]:xValue
         ENDIF
         IF nVal == Nil
            IF !(aDrawn[i] == Self) .AND. aDrawn[i]:xValue
               aDrawn[i]:xValue := .F.
               aDrawn[i]:title := ' '
               aDrawn[i]:Refresh()
            ENDIF
         ELSE
            IF aDrawn[i]:xValue != (n == nVal)
               aDrawn[i]:xValue := (n == nVal)
               aDrawn[i]:title := Iif( n == nVal, aDrawn[i]:cForTitle, ' ' )
               aDrawn[i]:Refresh()
            ENDIF
         ENDIF
      ENDIF
   NEXT
   IF nVal == Nil
      ::xValue := .T.
      ::title := ::cForTitle
      ::Refresh()
   ELSEIF n <= nVal .AND. !Empty( o )
      o:xValue := .T.
      o:title := o:cForTitle
      o:Refresh()
   ENDIF

   RETURN 0
