/*
 * $Id$
 * HWGUI - Harbour Win32 GUI library source code:
 * HLenta class
 *
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define CLR_WHITE    0xffffff
#define CLR_BLACK    0x000000
#define CLR_GRAY_1   0xcccccc
#define CLR_GRAY_2   0x999999

CLASS HLenta INHERIT HBoard

   DATA oDrawn

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont, ;
               bSize, bPaint, bClick, color, bcolor, aItems, nItemSize, aItemStyle )
   METHOD Move( x1, y1, width, height )
   METHOD aItems ( arr ) SETGET
   METHOD bClick ( b ) SETGET
   METHOD Value ( xValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont, ;
               bSize, bPaint, bClick, color, bcolor, aItems, nItemSize, aItemStyle ) CLASS HLenta

   color := Iif( color == Nil, CLR_BLACK, color )
   bColor := Iif( bColor == Nil, CLR_WHITE, bColor )
   ::Super:New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont,, ;
              bSize, bPaint,, color, bcolor )

   ::oDrawn := HDrawnLenta():New( Self, 0, 0, nWidth, nHeight, oFont, ;
               bPaint, bClick, color, bcolor, aItems, nItemSize, aItemStyle )

   RETURN Self

METHOD Move( x1, y1, width, height ) CLASS HLenta

   ::oDrawn:Move( 0, 0, width, height )
   ::Super:Move( x1, y1, width, height )

   RETURN Nil

METHOD aItems ( arr ) CLASS HLenta

   IF !Empty( arr )
      ::oDrawn:aItems := arr
   ENDIF

   RETURN ::oDrawn:aItems

METHOD bClick ( b ) CLASS HLenta

   IF !Empty( b )
      ::oDrawn:bCli := b
   ENDIF

   RETURN ::oDrawn:bCli

METHOD Value( xValue ) CLASS HLenta

   RETURN ::oDrawn:Value( xValue )

CLASS HDrawnLenta INHERIT HDrawn

   DATA lVertical
   DATA aItems
   DATA nItemSize
   DATA aItemStyle
   DATA oFont, oPen
   DATA lDrawNext    INIT .T.
   DATA lPressed     INIT .F.
   DATA lMoved       INIT .F.
   DATA nFirst       INIT 1
   DATA nSelected    INIT 0
   DATA nOver        INIT 0
   DATA nShift       INIT 0
   DATA nDragKoef    INIT 1
   DATA xPos, yPos
   DATA bCli

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, oFont, ;
               bPaint, bClick, color, bcolor, aItems, nItemSize, aItemStyle )
   METHOD Paint( hDC )
   METHOD Drag( xPos, yPos )
   METHOD Value( nValue ) SETGET
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, oFont, ;
            bPaint, bClick, color, bcolor, aItems, nItemSize, aItemStyle ) CLASS HDrawnLenta

   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, color, bColor,, ' ',, bPaint )

   ::title  := ""
   ::oFont := oFont
   ::lVertical := ( ::nHeight > ::nWidth )
   ::bCli := bClick
   ::aItems := aItems
   ::aItemStyle := Iif( Empty(aItemStyle), { HStyle():New( { CLR_WHITE, CLR_GRAY_1 }, 3 ), ;
      HStyle():New( { CLR_GRAY_2 }, 3 ) }, aItemStyle )
   ::nItemSize := nItemSize
   ::oPen := HPen():Add( PS_SOLID, 1, color )

   RETURN Self

METHOD Paint( hDC ) CLASS HDrawnLenta

   LOCAL x := ::nLeft, y := ::nTop
   LOCAL i, y1, ob, nCurr, nItemSize := ::nItemSize, oStyle, cText
   LOCAL lVertical := ::lVertical, l1
   LOCAL nW := Iif( ::lVertical, ::nWidth, ::nHeight ), nLength := Iif( ::lVertical, ::nHeight, ::nWidth )
   LOCAL aItemStyle := ::aItemStyle
   LOCAL lStyleOver := ( Len(aItemStyle)>2.AND.aItemStyle[3]!=Nil ), lStyleSele := ( Len(aItemStyle)>1.AND.aItemStyle[2]!=Nil )

   IF ::lHide .OR. ::lDisable
      RETURN Nil
   ENDIF

   IF ::bPaint != Nil
      Eval( ::bPaint, Self, hDC )
   ELSE

      IF !Empty( ::aItems )
         l1 := ( Valtype( ::aItems[1] ) == "A" )
         IF ::oFont != Nil
            hwg_Selectobject( hDC, ::oFont:handle )
         ENDIF
         y1 := Int( ::nShift % nItemSize )
         IF y1 > 0; y1 := nItemSize - y1; ENDIF
         IF y1 > 0
            IF lVertical
               aItemStyle[1]:Draw( hDC, x, y, x+nW, y+y1 )
            ELSE
               aItemStyle[1]:Draw( hDC, x, y, x+y1, y+nW )
            ENDIF
         ENDIF
         i := 1
         DO WHILE y1 + nItemSize <= nLength .AND. ( nCurr := i + ::nFirst - 1 ) <= Len( ::aItems )
            oStyle := Iif( nCurr == ::nSelected .AND. lStyleSele, aItemStyle[2], ;
               Iif( nCurr == ::nOver .AND. lStyleOver, aItemStyle[3], aItemStyle[1] ) )
            cText := Iif( l1,::aItems[nCurr,1],::aItems[nCurr] )
            IF lVertical
               oStyle:Draw( hDC, x, y+y1, x+nW, y+y1+nItemSize )
               IF !Empty( cText )
                  hwg_SetTextColor( hDC, ::tcolor )
                  hwg_Settransparentmode( hDC, .T. )
                  hwg_Drawtext( hDC, cText, x+4, y+y1+4, x+nW-4, y+y1+nItemSize-4, ;
                     DT_LEFT + DT_VCENTER + DT_SINGLELINE )
               ENDIF
            ELSE
               oStyle:Draw( hDC, x+y1, y, x+y1 + nItemSize, y+nW )
               IF !Empty( cText )
                  hwg_SetTextColor( hDC, ::tcolor )
                  hwg_Settransparentmode( hDC, .T. )
                  hwg_Drawtext( hDC, cText, x+y1+4, y+4, x+y1+nItemSize-4, y+nW-4, ;
                     DT_CENTER + DT_VCENTER + DT_SINGLELINE )
               ENDIF
            ENDIF
            hwg_Settransparentmode( hDC, .F. )
            IF l1 .AND. Len(::aItems[nCurr]) > 1 .AND. !Empty( ob := ::aItems[nCurr,2] )
               ob:Draw( hDC, x+Int( (nW - ob:nWidth)/2 ), y+Int( (nItemSize - ob:nHeight)/2 ), ;
                  ob:nWidth, ob:nHeight )
            ENDIF
            y1 += nItemSize
            i ++
         ENDDO
         IF y1 < nLength
            IF lVertical
               aItemStyle[1]:Draw( hDC, x, y+y1, x+nW, y+nLength )
            ELSE
               aItemStyle[1]:Draw( hDC, x+y1, y, x+nLength, y+nW )
            ENDIF
         ENDIF
         IF ::lDrawNext
            hwg_Selectobject( hDC, ::oPen:handle )
            i := Int( nw/2 )
            IF ::nShift > 0
               IF lVertical
                  hwg_Rectangle( hDC, x+i-1, y+1, x+i, y+2 )
                  hwg_Rectangle( hDC, x+i-7, y+1, x+i-6, y+2 )
                  hwg_Rectangle( hDC, x+i+6, y+1, x+i+7, y+2 )
               ELSE
                  hwg_Rectangle( hDC, x+1, y+i-1, x+2, y+i )
                  hwg_Rectangle( hDC, x+1, y+i-7, x+2, y+i-6 )
                  hwg_Rectangle( hDC, x+1, y+i+6, x+2, y+i+7 )
               ENDIF
            ENDIF
            IF nCurr < Len( ::aItems )
               IF lVertical
                  hwg_Rectangle( hDC, x+i-1, y+nLength-3, x+i, y+nLength-2 )
                  hwg_Rectangle( hDC, x+i-7, y+nLength-3, x+i-6, y+nLength-2 )
                  hwg_Rectangle( hDC, x+i+6, y+nLength-3, x+i+7, y+nLength-2 )
               ELSE
                  hwg_Rectangle( hDC, x+nLength-1, y+i-1, x+nLength-3, y+i )
                  hwg_Rectangle( hDC, x+nLength-1, y+i-7, x+nLength-3, y+i-6 )
                  hwg_Rectangle( hDC, x+nLength-1, y+i+6, x+nLength-3, y+i+7 )
               ENDIF
            ENDIF
         ENDIF
      ENDIF

   ENDIF

   RETURN Nil

METHOD Drag( xPos, yPos ) CLASS HDrawnLenta

   LOCAL nLength := Iif( ::lVertical, ::nHeight, ::nWidth ), nKolItems := Len( ::aItems )

   IF nLength < ::nItemSize * nKolItems - 4 .AND. ;
      ( ( ::lVertical .AND. Abs( yPos-::yPos ) > 2 ) .OR. ( !::lVertical .AND. Abs( xPos-::xPos ) > 2 ) )
      ::lMoved := .T.
      ::nOver := 0
      ::nShift += Int( Iif( ::lVertical, ( ::yPos-yPos ), ( ::xPos-xPos ) ) * ::nDragKoef )
      ::xPos := xPos; ::yPos := yPos
      IF ::nShift < 0
         ::nShift := 0
      ELSEIF ::nShift + nLength > Int( nKolItems * ::nItemSize ) + 2
         ::nShift := Max( 0, Int( nKolItems * ::nItemSize ) - nLength + 2 )
      ENDIF
      ::nFirst := Int( ::nShift/::nItemSize )
      ::nFirst += Iif( ::nShift > ::nFirst * ::nItemSize, 2, 1 )
      //hwg_Writelog( Ltrim(Str(::nShift)) + " " + Ltrim(Str(::nFirst))  )
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD Value( nValue ) CLASS HDrawnLenta

   IF nValue != Nil .AND. nValue >= 0 .AND. !Empty( ::aItems ) .AND. nValue <= Len( ::aItems )
      ::nSelected := nValue
      ::Refresh()
   ELSE
      nValue := ::nSelected
   ENDIF

   RETURN nValue

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnLenta

   LOCAL lRedraw := .F., y1, nPos

   IF xPos < ::nLeft .OR. xPos > ::nLeft+::nWidth .OR. yPos < ::nTop .OR. yPos > ::nTop+::nHeight
   ELSE
      IF ::lPressed
         ::Drag( xPos, yPos )
      ELSE
         y1 := Int( ::nShift % ::nItemSize )
         IF y1 > 0; y1 := ::nItemSize - y1; ENDIF
         nPos := Iif( ::lVertical, yPos - ::nTop - y1, xPos - ::nLeft - y1 )
         IF nPos > 0
            IF ( nPos := Int( nPos / ::nItemSize ) + ::nFirst ) > Len( ::aItems )
               nPos := 0
            ENDIF
            lRedraw := ( ::nOver != nPos )
            ::nOver := nPos
         ENDIF
      ENDIF
   ENDIF
   IF lRedraw
      ::Refresh()
   ENDIF

   RETURN Nil

METHOD onMouseLeave() CLASS HDrawnLenta

   ::lPressed := .F.
   ::nOver := 0

   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnLenta

   IF msg == WM_LBUTTONDOWN
      ::lPressed := .T.
      ::lMoved := .F.
      ::xPos := xPos
      ::yPos := yPos
   ENDIF
   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnLenta

   HB_SYMBOL_UNUSED( xPos )
   HB_SYMBOL_UNUSED( yPos )

   ::lPressed := .F.
   IF !::lMoved
      IF ::nSelected != ::nOver .AND. ::nOver != 0
         ::nSelected := ::nOver
         IF !Empty( ::bCli )
            Eval( ::bCli, Self, ::nSelected )
         ENDIF
         ::Refresh()
      ENDIF
   ENDIF

   RETURN Nil
