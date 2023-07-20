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

CLASS HDrawn INHERIT HObject

   DATA oParent
   DATA title
   DATA nTop, nLeft, nWidth, nHeight
   DATA tcolor, bcolor, brush
   DATA lHide         INIT .F.
   DATA nState        INIT 0
   DATA oFont
   DATA aStyles
   DATA aDrawn        INIT {}

   DATA bPaint, bClick

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, title, oFont, bPaint, bClick )
   METHOD GetParentBoard()
   METHOD GetByPos( xPos, yPos, oBoard )
   METHOD Paint( hDC )
   METHOD Move( x1, y1, width, height )
   METHOD SetState( nState, nPosX, nPosY )
   METHOD Refresh()

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, title, oFont, bPaint, bClick ) CLASS HDrawn

   ::oParent := oWndParent
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::tcolor  := tcolor
   ::bColor  := bColor
   ::title   := title
   ::oFont   := oFont
   ::bPaint  := bPaint
   ::bClick  := bClick

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

   LOCAL i

   IF ::lHide
      RETURN Nil
   ENDIF
   IF !Empty( ::bPaint )
      IF Eval( ::bPaint, Self, hDC ) == 0
         RETURN Nil
      ENDIF
   ELSE
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

   IF nState != ::nState
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS HDrawn

   hwg_Invalidaterect( ::GetParentBoard():handle, 0, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1 )
   RETURN Nil
