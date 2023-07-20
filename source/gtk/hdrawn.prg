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

   DATA bPaint

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, title, oFont, bPaint  )
   METHOD GetParentBoard()
   METHOD Paint( hDC )
   METHOD Move( x1, y1, width, height )
   METHOD Refresh()

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor, title, oFont, bPaint  ) CLASS HDrawn

   ::oParent := oWndParent
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::title   := title
   ::oFont   := oFont
   ::bPaint  := bPaint
   ::tcolor  := tcolor
   ::bColor  := bColor

   AAdd( ::oParent:aDrawn, Self )

   RETURN Self

METHOD GetParentBoard() CLASS HDrawn

   LOCAL oParent := ::oParent

   DO WHILE __ObjHasMsg( oParent, "GETPARENTBOARD" ); oParent := oParent:oParent; ENDDO

   RETURN oParent

METHOD Paint( hDC ) CLASS HDrawn

   LOCAL i

   IF ::lHide
      RETURN Nil
   ENDIF
   IF !Empty( ::bPaint )
      IF Eval( ::bPaint, Self, hDC ) == 0
         RETURN Nil
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

METHOD Refresh() CLASS HDrawn

   hwg_Invalidaterect( GetParentBoard():handle, 0, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1 )
   RETURN Nil
