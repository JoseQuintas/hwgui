/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTrack, HDrawnTrack classes
 *
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
 *
 * Copyright 2021 DF7BE
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0x000000

CLASS HTrack INHERIT HBoard

   DATA oDrawn

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
               bSize, bPaint, color, bcolor, nSize, oStyleBar, oStyleSlider, lAxis )
   METHOD Set( nSize, oStyleBar, oStyleSlider, lAxis, bPaint )
   METHOD Move( x1, y1, width, height )
   METHOD bChange ( b ) SETGET
   METHOD Value ( xValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
            bSize, bPaint, color, bcolor, nSize, oStyleBar, oStyleSlider, lAxis ) CLASS HTrack

   color := Iif( color == Nil, CLR_BLACK, color )
   bColor := Iif( bColor == Nil, CLR_WHITE, bColor )
   ::Super:New( oWndParent, nId, nLeft, nTop, nWidth, nHeight,,, ;
              bSize, bPaint,, color, bcolor )

   ::oDrawn := HDrawnTrack():New( Self, 0, 0, nWidth, nHeight, ;
            bPaint, color, bcolor, nSize, oStyleBar, oStyleSlider, lAxis )
   RETURN Self

METHOD Set( nSize, oStyleBar, oStyleSlider, lAxis, bPaint ) CLASS HTrack

   RETURN ::oDrawn:Set( nSize, oStyleBar, oStyleSlider, lAxis, bPaint )

METHOD Move( x1, y1, width, height ) CLASS HTrack

   ::oDrawn:Move( 0, 0, width, height )
   ::Super:Move( x1, y1, width, height )

   RETURN Nil

METHOD bChange ( b ) CLASS HTrack

   IF !Empty( b )
      ::oDrawn:bChange := b
   ENDIF

   RETURN ::oDrawn:bChange

METHOD Value( xValue ) CLASS HTrack

   RETURN ::oDrawn:Value( xValue )

CLASS HDrawnTrack INHERIT HDrawn

   DATA lVertical
   DATA oStyleBar, oStyleSlider
   DATA lAxis    INIT .T.
   DATA nFrom, nTo, nCurr, nSize
   DATA oPen1, oPen2, tColor2
   DATA lCaptured   INIT .F.
   DATA bEndDrag
   DATA bChange

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, ;
               bPaint, tcolor, bcolor, nSize, oStyleBar, oStyleSlider, lAxis )
   METHOD Set( nSize, oStyleBar, oStyleSlider, lAxis, bPaint )
   METHOD Paint( hDC )
   METHOD Drag( xPos, yPos )
   METHOD Move( x1, y1, width, height )
   METHOD Value ( xValue ) SETGET
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, ;
            bPaint, tcolor, bcolor, nSize, oStyleBar, oStyleSlider, lAxis ) CLASS HDrawnTrack

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bColor,, ' ',, bPaint )

   ::title  := ""
   ::lVertical := ( ::nHeight > ::nWidth )
   ::nSize := Iif( nSize == Nil, 12, nSize )
   ::nFrom  := Int( ::nSize/2 )
   ::nTo    := Iif( ::lVertical, ::nHeight-1-Int(::nSize/2), ::nWidth-1-Int(::nSize/2) )
   ::nCurr  := ::nFrom
   ::oStyleBar := oStyleBar
   ::oStyleSlider := oStyleSlider
   ::lAxis := ( lAxis == Nil .OR. lAxis )
   ::oPen1 := HPen():Add( PS_SOLID, 1, tcolor )

   RETURN Self

METHOD Set( nSize, oStyleBar, oStyleSlider, lAxis, bPaint ) CLASS HDrawnTrack
   LOCAL xValue := (::nCurr - ::nFrom) / (::nTo - ::nFrom)

   IF nSize != Nil
      ::nSize := nSize
      ::nFrom  := Int( ::nSize/2 )
      ::nTo    := Iif( ::lVertical, ::nHeight, ::nWidth ) -1-Int(::nSize/2)
      ::nCurr  := xValue * (::nTo - ::nFrom) + ::nFrom
   ENDIF
   IF oStyleBar != Nil
      ::oStyleBar := oStyleBar
   ENDIF
   IF oStyleSlider != Nil
      ::oStyleSlider := oStyleSlider
   ENDIF
   IF lAxis != Nil
      ::lAxis := lAxis
   ENDIF
   IF bPaint != Nil
      ::bPaint := bPaint
   ENDIF
   ::Refresh()

   RETURN Nil

METHOD Paint( hDC ) CLASS HDrawnTrack

   LOCAL nHalf, nw, x1, y1

   IF ::lHide .OR. ::lDisable
      RETURN Nil
   ENDIF

   IF ::tColor2 != Nil .AND. ::oPen2 == Nil
      ::oPen2 := HPen():Add( PS_SOLID, 1, ::tColor2 )
   ENDIF

   IF ::bPaint != Nil
      Eval( ::bPaint, Self, hDC )
   ELSE

      IF ::oStyleBar == Nil
         hwg_Fillrect( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth, ::nTop+::nHeight, ::oBrush:handle )
      ELSE
         ::oStyleBar:Draw( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth, ::nTop+::nHeight )
      ENDIF

      nHalf := Int( ::nSize/2 )
      hwg_Selectobject( hDC, ::oPen1:handle )
      IF ::lVertical
         x1 := Int( ::nWidth/2 )
         nw := Min( nHalf, x1 - 2 )
         IF ::lAxis .AND. ::nCurr - nHalf > ::nFrom
            hwg_Drawline( hDC, ::nLeft+x1, ::nTop+::nFrom, ::nLeft+x1, ::nTop+::nCurr-nHalf )
         ENDIF
         IF ::oStyleSlider == Nil
            hwg_Rectangle( hDC, ::nLeft+x1-nw, ::nTop+::nCurr+nHalf, ::nLeft+x1+nw, ::nTop+::nCurr-nHalf )
         ELSE
            ::oStyleSlider:Draw( hDC, ::nLeft+x1-nw, ::nTop+::nCurr-nHalf, ::nLeft+x1+nw, ::nTop+::nCurr+nHalf )
         ENDIF
         IF ::lAxis .AND. ::nCurr + nHalf < ::nTo
            IF ::oPen2 != Nil
               hwg_Selectobject( hDC, ::oPen2:handle )
            ENDIF
            hwg_Drawline( hDC, ::nLeft+x1, ::nTop+::nCurr+nHalf+1, ::nLeft+x1, ::nTop+::nTo )
         ENDIF
      ELSE
         y1 := Int( ::nHeight/2 )
         nw := Min( nHalf, y1 - 2 )
         IF ::lAxis .AND. ::nCurr - nHalf > ::nFrom
            hwg_Drawline( hDC, ::nLeft+::nFrom, ::nTop+y1, ::nLeft+::nCurr-nHalf, ::nTop+y1 )
         ENDIF
         IF ::oStyleSlider == Nil
            hwg_Rectangle( hDC, ::nLeft+::nCurr-nHalf, ::nTop+y1-nw, ::nLeft+::nCurr+nHalf, ::nTop+y1+nw )
         ELSE
            ::oStyleSlider:Draw( hDC, ::nLeft+::nCurr-nHalf, ::nTop+y1-nw, ::nLeft+::nCurr+nHalf, ::nTop+y1+nw )
         ENDIF
         IF ::lAxis .AND. ::nCurr + nHalf < ::nTo
            IF ::oPen2 != Nil
               hwg_Selectobject( hDC, ::oPen2:handle )
            ENDIF
            hwg_Drawline( hDC, ::nLeft+::nCurr+nHalf+1, ::nTop+y1, ::nLeft+::nTo, ::nTop+y1 )
         ENDIF
      ENDIF

   ENDIF

   RETURN Nil

METHOD Drag( xPos, yPos ) CLASS HDrawnTrack

   LOCAL nCurr := ::nCurr

   IF ::lVertical
      IF yPos > 32000
         yPos -= 65535
      ENDIF
      yPos -= ::nTop
      ::nCurr := Min( Max( ::nFrom, yPos ), ::nTo )
   ELSE
      IF xPos > 32000
         xPos -= 65535
      ENDIF
      xPos -= ::nLeft
      ::nCurr := Min( Max( ::nFrom, xPos ), ::nTo )
   ENDIF

   ::Refresh()
   IF nCurr != ::nCurr .AND. ::bChange != Nil
      Eval( ::bChange, Self, ::Value )
   ENDIF

   RETURN Nil

METHOD Move( x1, y1, width, height ) CLASS HDrawnTrack
   LOCAL xValue := (::nCurr - ::nFrom) / (::nTo - ::nFrom)

   HB_SYMBOL_UNUSED(x1)
   HB_SYMBOL_UNUSED(y1)

   IF ::lVertical .AND. !Empty( height ) .AND. height != ::nHeight
      ::nFrom  := Int( ::nSize/2 )
      ::nTo    := height - 1 - Int(::nSize/2)
      ::nCurr  := xValue * (::nTo - ::nFrom) + ::nFrom
   ELSEIF !::lVertical .AND. !Empty( width ) .AND. width != ::nWidth
      ::nFrom  := Int( ::nSize/2 )
      ::nTo    := width - 1 - Int( ::nSize/2 )
      ::nCurr  := xValue * (::nTo - ::nFrom) + ::nFrom
   ENDIF

   ::Super:Move( x1, y1, width, height )

   RETURN Nil

METHOD Value ( xValue ) CLASS HDrawnTrack

   LOCAL oldValue := (::nCurr - ::nFrom) / (::nTo - ::nFrom)

   IF xValue != Nil
      xValue := Iif( xValue < 0, 0, Iif( xValue > 1, 1, xValue ) )
      IF Abs( xValue - oldValue ) > 0.005
         ::nCurr := xValue * (::nTo - ::nFrom) + ::nFrom
         ::Refresh()
      ENDIF
   ELSE
      RETURN oldValue
   ENDIF

   RETURN xValue

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnTrack

   IF ::lCaptured
      ::Drag( xPos, yPos )
   ENDIF

   RETURN Nil

METHOD onMouseLeave() CLASS HDrawnTrack

   ::lCaptured := .F.

   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnTrack

   IF msg == WM_LBUTTONDOWN
      ::lCaptured := .T.
      ::Drag( xPos, yPos )
   ENDIF

   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnTrack

   HB_SYMBOL_UNUSED( xPos )
   HB_SYMBOL_UNUSED( yPos )

   ::lCaptured := .F.
   IF ::bEndDrag != Nil
      Eval( ::bEndDrag, Self )
   ENDIF
   ::Refresh()

   RETURN Nil

