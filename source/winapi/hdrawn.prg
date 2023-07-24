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

CLASS HDrawn INHERIT HObject

   CLASS VAR oOver, oOver0 SHARED
   CLASS VAR oPressed SHARED

   DATA oParent
   DATA title
   DATA nTop, nLeft, nWidth, nHeight
   DATA tcolor, bcolor, brush
   DATA lHide         INIT .F.
   DATA lStatePaint   INIT .F.
   DATA nState        INIT 0
   DATA oFont
   DATA aStyles
   DATA aDrawn        INIT {}
   DATA xValue        INIT Nil

   DATA bPaint, bClick, bChgState

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
      title, oFont, bPaint, bClick, bChgState )
   METHOD GetParentBoard()
   METHOD GetByPos( xPos, yPos, oBoard )
   METHOD Paint( hDC )
   METHOD Move( x1, y1, width, height )
   METHOD SetState( nState, nPosX, nPosY )
   METHOD SetText( cText )
   METHOD Value( xValue ) SETGET
   METHOD Refresh()

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, aStyles, ;
   title, oFont, bPaint, bClick, bChgState ) CLASS HDrawn

   ::oParent := oWndParent
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::tcolor  := Iif( tcolor == Nil, 0, tcolor )
   ::bColor  := bColor
   ::aStyles := aStyles
   ::title   := title
   ::oFont   := Iif( oFont == Nil, oWndParent:oFont, oFont )
   ::bPaint  := bPaint
   ::bClick  := bClick
   ::bChgState := bChgState

   IF bColor != NIL
      ::brush := HBrush():Add( bColor )
   ENDIF

   AAdd( ::oParent:aDrawn, Self )

   RETURN Self

METHOD GetParentBoard() CLASS HDrawn

   LOCAL oParent := ::oParent

   DO WHILE __ObjHasMsg( oParent, "GETPARENTBOARD" ); oParent := oParent:oParent; ENDDO

   RETURN oParent

METHOD GetByPos( xPos, yPos, oBoard ) CLASS HDrawn

   LOCAL aDrawn := Iif( !Empty( oBoard ), oBoard:aDrawn, ::aDrawn ), i, o

   FOR i := 1 TO Len( aDrawn )
      o := aDrawn[i]
      IF xPos >= o:nLeft .AND. xPos < o:nLeft + o:nWidth .AND. ;
         yPos >= o:nTop .AND. yPos < o:nTop + o:nHeight
         RETURN o
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
      ELSEIF !Empty( ::brush )
         hwg_RoundRect_Filled( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, 4,, ::brush:handle )
      ENDIF
      IF !Empty( ::title )
         hwg_Settransparentmode( hDC, .T. )
         hwg_Settextcolor( hDC, ::tColor )
         IF !Empty( ::oFont )
            hwg_SelectObject( hDC, ::oFont:handle )
         ENDIF
         hwg_Drawtext( hDC, ::title, ::nLeft+4, ::nTop+6, ::nLeft+::nWidth-4, ::nTop+::nHeight-6, DT_CENTER )
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

   LOCAL o, nOldstate := ::nState

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
      ELSEIF !Empty( ::oOver ) .AND. !( ::oOver == Self )
         ::oOver:SetState( 0, nPosX, nPosY )
         ::oOver := Nil
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
         ::nState := STATE_MOVER
         IF !Empty( ::oOver ) .AND. !( ::oOver == Self )
            ::oOver:SetState( 0, nPosX, nPosY )
         ENDIF
         IF Empty( ::aDrawn )
            ::oOver := Self
         ELSE
            ::oOver0 := Self
         ENDIF
      ELSEIF nState == STATE_NORMAL
         ::nState := STATE_NORMAL
      ELSEIF nState == STATE_PRESSED
         ::nState := STATE_PRESSED
         IF Empty( ::aDrawn )
            ::oPressed := Self
         ENDIF
      ELSEIF nState == STATE_UNPRESS
         ::nState := Iif( nPosX >= ::nLeft .AND. nPosX < ::nLeft + ::nWidth .AND. ;
            nPosY >= ::nTop .AND. nPosY < ::nTop + ::nHeight, STATE_MOVER, STATE_NORMAL )
         IF Self == ::oPressed
            IF !Empty( ::bClick )
               Eval( ::bClick, Self )
            ENDIF
         ELSEIF !Empty( ::oPressed )
            ::oPressed:nState := Iif( nPosX >= ::oPressed:nLeft .AND. nPosX < ::oPressed:nLeft + ::oPressed:nWidth .AND. ;
               nPosY >= ::oPressed:nTop .AND. nPosY < ::oPressed:nTop + ::oPressed:nHeight, STATE_MOVER, STATE_NORMAL )
         ENDIF
         ::oPressed := Nil
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

METHOD Refresh() CLASS HDrawn

   hwg_Invalidaterect( ::GetParentBoard():handle, 0, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1 )
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
