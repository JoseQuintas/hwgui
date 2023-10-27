/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDrawnBrw class - browse databases and arrays
 *
 * Copyright 2023 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

#define DEF_ROW_HEIGHT  24
#define DEF_COL_WIDTH   80
#define DEF_CLRT_SELE   0xffffff
#define DEF_CLRB_SELE   0x909090
#define DEF_CLR_SELE    0xC0C0C0
#define DEF_HTT_SELE    0xffffff
#define DEF_HTB_SELE    0x505050
#define DEF_HTRACK_WIDTH 18

#define CLR_BLACK    0
#define CLR_WHITE    0xffffff
#define CLR_GRAY3    0xbbbbbb

static hCursorSize, hCursorCommon

CLASS HBrw INHERIT HBoard

   DATA oDrawn

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
               bSize, bPaint, bClick )
   METHOD Move( x1, y1, width, height )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
               bSize, bPaint, bClick ) CLASS HBrw

   ::Super:New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, oFont,, ;
              bSize, bPaint,, tcolor, bcolor )

   ::oDrawn := HDrawnBrw():New( Self, 0, 0, nWidth, nHeight, tcolor, bcolor,,, oFont, ;
               bPaint, bClick )

   RETURN Self

METHOD Move( x1, y1, width, height ) CLASS HBrw

   ::oDrawn:Move( 0, 0, width, height )
   ::Super:Move( x1, y1, width, height )

   RETURN Nil

CLASS HDrawnBrw INHERIT HDrawn

   DATA oData
   DATA aColumns      INIT {}

   DATA nHeightRow    INIT 0
   DATA nHeightHead   INIT 0
   DATA nHeightFoot   INIT 0
   DATA aRowPadding   INIT { 4, 2, 4, 2 }
   DATA aHeadPadding  INIT { 4, 2, 4, 2 }
   DATA aFootPadding  INIT { 4, 2, 4, 2 }

   DATA tColorSel, bColorSel, htbColor, httColor
   DATA bCellBlock                           // {|oBrw,nRow,nCol| Return { tColor, bColor, oFont } }
   DATA sepColor      INIT DEF_CLR_SELE
   DATA oPenSep, oPenBorder
   DATA nBorder       INIT 0
   DATA nBorderColor  INIT 0
   DATA oFontHead, oFontFoot

   DATA oStyleHead                           // An HStyle object to draw the header
   DATA oStyleFoot                           // An HStyle object to draw the footer
   DATA oStyleCell                           // An HStyle object to draw the cell

   DATA aRows         INIT {}                // { { y1,y2 },... }
   DATA nRowCount     INIT 0                 // Number of visible data rows
   DATA nRowCurr      INIT 1                 // Row currently selected

   DATA nColCount     INIT 0                 // Number of visible data columns
   DATA nColCurr      INIT 1                 // Column currently selected
   DATA nColFirst     INIT 1                 // The leftmost column on the screen
   DATA nColResize    INIT 0                 // The column to be resized

   DATA oTrackV, oTrackH
   DATA nTrackWidth, oStyleBar, oStyleSlider

   DATA lCaptured     INIT .F.

   DATA bEnter, bKeyDown, bLostFocus, bRClick
   DATA oEdit
   DATA lSeleCell     INIT .F.
   DATA lRebuild      INIT .T.

   DATA pBrushes      PROTECTED
   DATA nHeightOld    INIT 0

   METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
               bPaint, bChgState, lVScroll, lHScroll )

   METHOD Rebuild( hDC )
   METHOD DoRebuild()  INLINE  (::lRebuild := .T., ::Refresh())
   METHOD Paint( hDC )
   METHOD RowOut( hDC, nRow, x1, y1, x2 )
   METHOD HeaderOut( hDC, y1, y2, oStyle, aPadding, npAll, npBack, npItem )
   METHOD Cell( iCol, nRow )

   METHOD Move( x1, y1, width, height )
   METHOD Refresh( x1, y1, x2, y2, lNeedRefresh )
   METHOD AddColumn( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable )
   METHOD Edit()
   METHOD onKey( msg, wParam, lParam )
   METHOD onMouseMove( xPos, yPos )
   METHOD onMouseLeave()
   METHOD onButtonDown( msg, xPos, yPos )
   METHOD onButtonUp( xPos, yPos )
   METHOD onButtonDbl( xPos, yPos )
   METHOD onKillFocus()
   METHOD SetFocus()

   METHOD Top()
   METHOD Skip( n )
   METHOD Selected( n )
   METHOD ShowTrackV( lShow )
   METHOD ShowTrackH( lShow )

   METHOD End()

ENDCLASS

METHOD New( oWndParent, nLeft, nTop, nWidth, nHeight, tcolor, bcolor, oFont, ;
            bPaint, bChgState, lVScroll, lHScroll ) CLASS HDrawnBrw

   AFill( ::aMargin, 0 )
   ::Super:New( oWndParent, nLeft, nTop, nWidth, nHeight, ;
      Iif( tcolor == Nil, CLR_BLACK, tcolor ), Iif( bColor == Nil, CLR_WHITE, bColor ),, ' ', ;
      oFont, bPaint, bChgState )

   ::tColorSel := DEF_CLRT_SELE
   ::bColorSel := DEF_CLRB_SELE
   ::httColor  := DEF_HTT_SELE
   ::htbColor  := DEF_HTB_SELE
   IF Valtype( lVScroll ) == "L" .AND. lVScroll
      ::oTrackV := 0
   ENDIF
   IF Valtype( lHScroll ) == "L" .AND. lHScroll
      ::oTrackH := 0
   ENDIF
   IF Empty( hCursorSize )
      hCursorSize := hwg_Loadcursor( IDC_SIZEWE )
#ifdef __GTK__
      hCursorCommon := hwg_Loadcursor( IDC_ARROW )
#endif
   ENDIF

   ::pBrushes := hb_hash()

   RETURN Self

METHOD Rebuild( hDC )

   LOCAL i, lh := .F., lf := .F.
   LOCAL nFont := 0, nFontHead := 0, nFontFoot := 0

   IF Empty( ::oPenSep ) .AND. ::sepColor >= 0
      ::oPenSep := HPen():Add( PS_SOLID, 1, ::sepColor )
   ENDIF
   IF Empty( ::oPenBorder) .AND. ::nBorder > 0
      ::oPenBorder := HPen():Add( PS_SOLID, ::nBorder, ::nBorderColor )
      ::aMargin[1] := ::aMargin[2] := ::aMargin[3] := ::aMargin[4] := ::nBorder
   ENDIF

   IF ::oFontHead != Nil
      hwg_Selectobject( hDC, ::oFontHead:handle )
      nFontHead := hwg_GetTextMetric( hDC )[1]
   ENDIF
   IF ::oFontFoot != Nil
      hwg_Selectobject( hDC, ::oFontFoot:handle )
      nFontFoot := hwg_GetTextMetric( hDC )[1]
   ENDIF
   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
      nFont := ::nHeightRow := hwg_GetTextMetric( hDC )[1]
   ELSE
      ::nHeightRow := DEF_ROW_HEIGHT
   ENDIF
   ::nHeightRow += ::aRowPadding[2] + ::aRowPadding[4]

   FOR i := 1 TO Len( ::aColumns )
      IF !Empty( ::aColumns[i]:cHead )
         lh := .T.
      ENDIF
      IF !Empty( ::aColumns[i]:cFoot )
         lf := .T.
      ENDIF
      IF ::aColumns[i]:lEditable
         ::lSeleCell := .T.
      ENDIF
   NEXT
   IF lh
      ::nHeightHead := Iif( nFontHead==0, Iif( nFont==0, DEF_ROW_HEIGHT, nFont ), nFontHead ) + ;
         ::aHeadPadding[2] + ::aHeadPadding[4]
      IF Empty( ::oStyleHead )
         ::oStyleHead := HStyle():New( { CLR_WHITE, CLR_GRAY3 }, 1 )
      ENDIF
   ENDIF
   IF lf
      ::nHeightFoot := Iif( nFontFoot==0, Iif( nFont==0, DEF_ROW_HEIGHT, nFont ), nFontHead ) + ;
         ::aFootPadding[2] + ::aFootPadding[4]
      IF Empty( ::oStyleFoot )
         ::oStyleFoot := HStyle():New( { CLR_WHITE, CLR_GRAY3 }, 1 )
      ENDIF
   ENDIF
   IF Valtype( ::oTrackV ) == "N"
      ::ShowTrackV( .T. )
   ENDIF
   IF Valtype( ::oTrackH ) == "N"
      ::ShowTrackH( .T. )
   ENDIF
   ::lRebuild := .F.

   RETURN Nil

METHOD Paint( hDC ) CLASS HDrawnBrw

   LOCAL x1, y1, x2, y2, x, nRow := 0
   LOCAL nRec, i, lNeedBuf := ::oData:lNeedBuf

   IF ::lHide  .OR. ::lDisable .OR. Empty( ::oData )
      RETURN Nil
   ENDIF

   IF ::lRebuild
      ::Rebuild( hDC )
   ENDIF
   IF ::nHeightOld != ::nHeight
      IF ::nHeightOld < ::nHeight
         //hwg_writelog( "height: "+ str(::nHeightOld) + " " + str(::nHeight) )
         ::oData:lNeedRefresh := .T.
      ENDIF
      ::nHeightOld := ::nHeight
   ENDIF
   IF !Empty( ::bPaint )
      RETURN Eval( ::bPaint, Self, hDC )
   ENDIF
   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF

   x1 := ::nLeft + ::aMargin[1]
   y1 := ::nTop + ::aMargin[2] + ::nHeightHead
   x2 := ::nLeft + ::nWidth - ::aMargin[3]
   y2 := ::nTop + ::nHeight - ::nHeightFoot - ::aMargin[4] - ::nHeightRow + ::aRowPadding[4]

   // Draw header and footer
   IF ::nHeightHead > 0
      ::HeaderOut( hDC, ::nTop + ::aMargin[2], ::nHeightHead, ::oStyleHead, ;
         ::aHeadPadding, PAINT_HEAD_ALL, PAINT_HEAD_BACK, PAINT_HEAD_ITEM )
   ENDIF
   IF ::nHeightFoot > 0
      ::HeaderOut( hDC, y2, ::nHeightFoot, ::oStyleFoot, ;
         ::aFootPadding, PAINT_FOOT_ALL, PAINT_FOOT_BACK, PAINT_FOOT_ITEM )
   ENDIF

   // Draw table content
   nRec := ::oData:Recno()
   IF !lNeedBuf .OR. ::oData:lNeedRefresh .OR. ;
      Len( ::aRows ) < ::nRowCurr .OR. ::aRows[::nRowCurr,3,1] != nRec
      //hwg_Writelog( "p1" )
      ::oData:Skip( -(::nRowCurr - 1) )
      DO WHILE !::oData:Eof()
         nRow ++
         IF lNeedBuf
            ::oData:nCurrent := ::oData():Recno()
            IF Len( ::aRows ) >= nRow
               ::aRows[nRow,3,1] := -1
            ENDIF
         ENDIF
         y1 := ::RowOut( hDC, nRow, x1, y1, x2, y2 )
         IF y1 > y2
            EXIT
         ENDIF
         ::oData:Skip( 1 )
      ENDDO
   ELSE
      //hwg_Writelog( "p2" )
      DO WHILE y1 <= y2 .AND. nRow < Len( ::aRows ) .AND. ::aRows[++nRow,1] != Nil
         ::oData:nCurrent := ::aRows[nRow,3,1]
         y1 := ::RowOut( hDC, nRow, x1, y1, x2, y2 )
      ENDDO
   ENDIF
   IF ::oData:Recno() != nRec
      ::oData:Goto( nRec )
   ENDIF

   IF Len( ::aRows ) == nRow
      AAdd( ::aRows, { Nil, Nil, Nil } )
      IF lNeedBuf
         ::aRows[nRow+1,3] := Array( Len(::aColumns) + 1 )
      ENDIF
   ELSE
      ::aRows[nRow+1,1] := Nil
      IF lNeedBuf
         ::aRows[nRow+1,3,1] := Nil
      ENDIF
   ENDIF
   ::nRowCount := nRow
   y2 += ::nHeightRow - ::aRowPadding[4]
   hwg_FillRect( hDC, x1, y1, x2, y2, ::oBrush:handle )

   // Draw grid and border
   IF !Empty( ::oPenSep )
      hwg_SelectObject( hDC, ::oPenSep:handle )
      i := 0
      DO WHILE ++i <= Len( ::aRows ) .AND. ::aRows[i,1] != Nil
         hwg_DrawLine( hDC, x1, ::aRows[i,2], x2, ::aRows[i,2] )
      ENDDO
      i := ::nColFirst - 1; x := x1
      DO WHILE ++i < Len( ::aColumns ) .AND. x < x2
         x += Min( ::aColumns[i]:nWidth, x2-x )
         hwg_DrawLine( hDC, x, ::nTop + ::aMargin[2] + ::nHeightHead, x, y1 )
      ENDDO
   ENDIF
   IF !Empty( ::oPenBorder )
      hwg_Rectangle( hDC, ::nLeft, ::nTop, ::nLeft+::nWidth-1, ::nTop+::nHeight-1, ::oPenBorder:handle )
   ENDIF

   // Draw scrollbars if active
   IF !Empty( ::oTrackV ) .AND. !::oTrackV:lHide
      nRec := ::oData:RecnoLog()
      ::oTrackV:Value := Iif( nRec == 1, 0, nRec / ::oData:Count() )
      ::oTrackV:Paint( hDC )
   ENDIF
   IF !Empty( ::oTrackH ) .AND. !::oTrackH:lHide
      ::oTrackH:Value := Iif( ::nColCurr == 1, 0, ::nColCurr / Len( ::aColumns ) )
      ::oTrackH:Paint( hDC )
   ENDIF
   // Draw edit control if active
   IF !Empty( ::oEdit )
      ::oEdit:Paint( hDC )
   ENDIF

   IF lNeedBuf
      ::oData:lNeedRefresh := .F.
   ENDIF

   RETURN Nil

METHOD RowOut( hDC, nRow, x1, y1, x2 ) CLASS HDrawnBrw

   LOCAL y2 := y1 + ::nHeightRow, x := x1, iCol := ::nColFirst - 1, i := 0, nw
   LOCAL oCB, oCol, block, aClr, bColor, hBrush

   IF Len( ::aRows ) < nRow
      AAdd( ::aRows, { y1, Nil, Nil } )
      IF ::oData:lNeedBuf
         ::aRows[nRow,3] := Array( Len(::aColumns) + 1 )
         ::aRows[nRow,3,1] := ::oData:nCurrent
      ENDIF
   ELSE
      ::aRows[nRow,1] := y1
      IF ::oData:lNeedBuf
         IF ::oData:nCurrent != ::aRows[nRow,3,1]
            AFill( ::aRows[nRow,3], Nil )
            ::aRows[nRow,3,1] := ::oData:nCurrent
         ENDIF
      ENDIF
   ENDIF

   hwg_Settransparentmode( hDC, .T. )

   DO WHILE ++iCol <= Len( ::aColumns ) .AND. x < x2
      oCol := ::aColumns[iCol]
      nw := Iif( iCol < Len( ::aColumns ), Min( oCol:nWidth,x2-x ), x2 - x )
      IF !Empty( oCB := oCol:oPaintCB ) .AND. !Empty( block := oCB:Get( PAINT_LINE_ALL ) )
         Eval( block, oCol, hDC, x, y1, x + nw, y2, iCol, nRow )
      ELSE
         IF !Empty( ::bCellBlock )
            aClr := Eval( ::bCellBlock, Self, nRow, iCol )
         ENDIF
         IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( PAINT_LINE_BACK ) )
            Eval( block, oCol, hDC, x, y1, x + oCol:nWidth, y2, iCol, nRow )
         ELSE
            bColor := Iif( aClr == Nil .OR. Len(aClr)<2 .OR. aClr[2] == Nil, ;
               IIf( nRow == ::nRowCurr, ;
               Iif( iCol == :: nColCurr .AND. ::lSeleCell, ::htbColor, ::bColorSel ), ;
               Iif( oCol:bColor == Nil, ::bColor, oCol:bColor ) ), aClr[2] )
            IF !hb_hHaskey( ::pBrushes, bColor )
               ::pBrushes[bColor] := HBrush():Add( bColor )
            ENDIF
            hBrush := ::pBrushes[bColor]:handle
            hwg_FillRect( hDC, x, y1, x + nw, y2, hBrush )
         ENDIF
         hwg_Settextcolor( hDC, ;
            Iif( aClr == Nil .OR. aClr[1] == Nil, IIf( nRow == ::nRowCurr, ;
               Iif( iCol == :: nColCurr .AND. ::lSeleCell, ::httColor, ::tColorSel ), ;
               Iif( oCol:tColor == Nil, ::tColor, oCol:tColor ) ), aClr[1] ) )
         hwg_Selectobject( hDC, Iif( !Empty(aClr) .AND. Len(aClr)>2 .AND. !Empty(aClr[3]), ;
            aClr[3]:handle, Iif( !Empty(oCol:oFont), oCol:oFont:handle, ::oFont:handle ) ) )
         hwg_Drawtext( hDC, ::Cell( iCol, nRow ), x+::aRowPadding[1], y1+::aRowPadding[2],  ;
            Min( x2, x+nw-1-::aRowPadding[3] ), y2-::aRowPadding[4], oCol:nAlignRow, .T. )
      ENDIF
      x += oCol:nWidth
      i ++
   ENDDO
   hwg_Settransparentmode( hDC, .F. )

   ::nColCount := Iif( i > 1 .AND. x > x2+2, i - 1, i )
   ::aRows[nRow,2] := y1 + ::nHeightRow
   RETURN ::aRows[nRow,2]

METHOD HeaderOut( hDC, y1, y2, oStyle, aPadding, npAll, npBack, npItem ) CLASS HDrawnBrw

   LOCAL x1 := ::nLeft + ::aMargin[1]
   LOCAL x := x1, iCol := ::nColFirst - 1
   LOCAL x2 := ::nLeft + ::nWidth - ::aMargin[3]
   LOCAL oCB, aCB, oCol, block, i, nw

   y2 := y1 + y2
   hwg_Settransparentmode( hDC, .T. )
   hwg_Settextcolor( hDC, ::tcolor )

   DO WHILE ++iCol <= Len( ::aColumns ) .AND. x < x2
      oCol := ::aColumns[iCol]
      nw := Iif( iCol < Len( ::aColumns ), Min( oCol:nWidth,x2-x ), x2 - x )
      IF !Empty( oCB := oCol:oPaintCB ) .AND. !Empty( block := oCB:Get( npAll ) )
         Eval( block, oCol, hDC, x, y1, x + nw, y2, iCol )
      ELSE
         IF !Empty( oCB ) .AND. !Empty( block := oCB:Get( npBack ) )
            Eval( block, oCol, hDC, x, y1, x + nw, y2, iCol )
         ELSE
            oStyle:Draw( hDC, x, y1, x + nw, y2 )
         ENDIF
         IF !Empty( oCol:cHead )
            hwg_Drawtext( hDC, oCol:cHead, x+aPadding[1], y1+aPadding[2],  ;
               Min( x2, x+nw-1-aPadding[3] ), ;
               y2-aPadding[4], oCol:nAlignHead )
         ENDIF
      ENDIF
      IF !Empty( oCB ) .AND. !Empty( aCB := oCB:Get( npItem ) )
         FOR i := 1 TO Len( aCB )
            Eval( aCB[i], oCol, hDC, x, y1, x + nw, y2, iCol )
         NEXT
      ENDIF
      x += oCol:nWidth
   ENDDO
   hwg_Settransparentmode( hDC, .F. )

   RETURN Nil

METHOD Cell( iCol, nRow ) CLASS HDrawnBrw

   LOCAL xVal, cType

   IF ::oData:lNeedBuf
      IF ::aRows[nRow,3,iCol+1] == Nil
         //hwg_Writelog( "c1 "+ltrim(str(nRow))+" "+ltrim(str(iCol)) )
         IF ::oData:Recno() != ::aRows[nRow,3,1]
            //hwg_Writelog( "c1a "+valtype(::aRows[nRow,3,1]) )
            ::oData:Goto( ::aRows[nRow,3,1] )
         ENDIF
         ::aRows[nRow,3,iCol+1] := Eval( ::aColumns[iCol]:block,, ::oData )
      ELSE
         //hwg_Writelog( "c2 "+ltrim(str(nRow))+" "+ltrim(str(iCol)) )
      ENDIF
      xVal := ::aRows[nRow,3,iCol+1]
   ELSE
      xVal := Eval( ::aColumns[iCol]:block,, ::oData )
   ENDIF
   cType := Valtype( xVal )
   IF cType == "C"
      RETURN xVal
   ELSEIF cType == "N"
      RETURN Ltrim(Str( xVal, 25, ::aColumns[iCol]:dec ))
   ELSEIF cType == "D"
      RETURN Dtoc( xVal )
   ELSEIF cType == "L"
      RETURN Iif( xVal, "T", "F" )
   ENDIF

   RETURN hb_ValToExp( xVal )

METHOD Move( x1, y1, width, height ) CLASS HDrawnBrw

   LOCAL x10 := ::nLeft, y10 := ::nTop, x20 := ::nLeft + ::nWidth, y20 := ::nTop + ::nHeight

   //hwg_writelog( str(::nLeft)+" "+str(::nTop)+" "+str(::nWidth)+" "+str(::nheight)+" "+str(::oTrackV:nLeft)+" "+str(::oTrackH:nTop) )
   ::Super:Move( x1, y1, width, height, .F. )
   IF !Empty( ::oTrackV ) .AND. !::oTrackV:lHide
      ::oTrackV:Move( ::nLeft+::nWidth-::aMargin[3], ::nTop+::aMargin[2]+::nHeightHead,, ;
         ::nHeight-+::nHeightHead-+::nHeightFoot-::aMargin[2]-::aMargin[4] )
   ENDIF
   IF !Empty( ::oTrackH ) .AND. !::oTrackH:lHide
      ::oTrackH:Move( ::nLeft+::aMargin[1], ::nTop+::nHeight-::aMargin[4], ;
         ::nWidth-::aMargin[1]-::aMargin[3] )
   ENDIF
   ::Refresh( Min(x10,::nLeft), Min(y10,::nTop), Max(x20,::nLeft+::nWidth), Max(y20,::nTop+::nHeight) )
   //hwg_writelog( str(::nLeft)+" "+str(::nTop)+" "+str(::nWidth)+" "+str(::nheight)+" "+str(::oTrackV:nLeft)+" "+str(::oTrackH:nTop) )
   //hwg_writelog( "" )
   //hwg_writelog( str(Min(x10,::nLeft))+" "+str(Min(y10,::nTop))+" "+str(Max(x20,::nLeft+::nWidth))+" "+str(Max(y20,::nTop+::nHeight)) )

   RETURN Nil

METHOD Refresh( x1, y1, x2, y2, lNeedRefresh ) CLASS HDrawnBrw

   IF (lNeedRefresh == Nil .OR. lNeedRefresh) .AND. !Empty( ::oData ) .AND. ::oData:lNeedBuf
      ::oData:lNeedRefresh := .T.
   ENDIF

   RETURN ::Super:Refresh( x1, y1, x2, y2 )

METHOD AddColumn( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable ) CLASS HDrawnBrw

   LOCAL oColumn := HBrwCol():New( cHead, Iif( Valtype(block) == "B", block, ::oData:Block(block) ), ;
      nWidth, nAlignRow, nAlignHead, lEditable )

   AAdd( ::aColumns, oColumn )

   RETURN oColumn

METHOD Edit() CLASS HDrawnBrw

   LOCAL lRes, oCol, i
   LOCAL x1, y1, nw, nh, xVal

   oCol := ::aColumns[::nColCurr]
   IF ::bEnter != Nil .AND. ;
         ( ValType( lRes := Eval( ::bEnter, Self, ::nColCurr, ::nRowCurr ) ) != 'L' .OR. lRes )
      RETURN Nil
   ENDIF
   IF !oCol:lEditable
      RETURN Nil
   ENDIF

   xVal := Eval( oCol:block,, ::oData )
   y1 := ::aRows[::nRowCurr,1]
   nh := ::aRows[::nRowCurr,2] - ::aRows[::nRowCurr,1]
   i := ::nColFirst - 1; x1 := ::nLeft + ::aMargin[1]
   DO WHILE ++i < ::nColCurr
      x1 += ::aColumns[i]:nWidth
   ENDDO
   nw := Iif( ::nColCurr == Len( ::aColumns ), ::nLeft + ::nWidth - ::aMargin[3] - x1, oCol:nWidth )
   IF Empty( oCol:aList )
      ::oEdit := HDrawnEdit():New( Self, x1-1, y1-2, nw+2, nh+4, CLR_BLACK, CLR_WHITE, ::oFont, xVal, oCol:cPicture )
      ::oEdit:nBorder := 2
   ELSE
      ::oEdit := HDrawnUpdown():New( Self, x1-1, y1-2, nw+2, nh+4, CLR_BLACK, CLR_WHITE,, ;
               ::oFont, hb_Ascan( oCol:aList,Trim(xVal),,,.T. ),,,,, oCol:aList )
      //::oEdit:oEdit:nBorder := 2
   ENDIF
   ::Refresh( ,,,, .F. )

   RETURN Nil

METHOD onKey( msg, wParam, lParam ) CLASS HDrawnBrw

   LOCAL lRes, o, x

   wParam := hwg_PtrToUlong( wParam )

   IF !Empty( ::oEdit )
      IF msg == WM_KEYDOWN .AND. wParam == VK_ESCAPE
         ::oEdit:onMouseLeave()
         ::oEdit:End()
         ::oEdit := Nil
         ::Refresh( ,,,, .F. )
      ELSEIF msg == WM_KEYDOWN .AND. wParam == VK_RETURN
         o := ::aColumns[::nColCurr]
         x := Iif( !Empty( o:aList ), o:aList[::oEdit:Value], ::oEdit:Value )
         IF Empty( o:bValid ) .OR. Eval( o:bValid, x )
            Eval( o:block, x, ::oData )
            IF ::oData:lNeedBuf
               ::aRows[::nRowCurr,3,::nColCurr+1] := Nil
            ENDIF
            ::oEdit:onMouseLeave()
            ::oEdit:End()
            ::oEdit := Nil
            ::Refresh( ,,,, .F. )
         ENDIF
      ELSEIF wParam != VK_TAB
         ::oEdit:onKey( msg, wParam, lParam )
      ENDIF
      RETURN Nil
   ENDIF

   IF ::bKeyDown != Nil .AND. ;
         ( ValType( lRes := Eval( ::bKeyDown,Self,msg,wParam,lParam ) ) != 'L' .OR. lRes )
      RETURN Nil
   ENDIF
   IF msg == WM_KEYDOWN
      IF wParam == VK_DOWN
         ::Skip( 1 )

      ELSEIF wParam == VK_UP
         ::Skip( -1 )

      ELSEIF wParam == VK_HOME
         ::Top()

      ELSEIF wParam == VK_END
         ::oData:Bottom()
         ::nRowCurr := Min( ::nRowCount, ::oData:Count() )
         ::Refresh( ,,,, .F. )

      ELSEIF wParam == VK_RIGHT
         IF ::lSeleCell
            IF ::nColCurr < Len( ::aColumns )
               IF ++ ::nColCurr >= ::nColFirst + ::nColCount
                  ::nColFirst ++
               ENDIF
               ::Refresh( ,,,, .F. )
            ENDIF
         ELSE
            IF ::nColFirst + ::nColCount < Len( ::aColumns )
               ::nColFirst ++
               ::Refresh( ,,,, .F. )
            ENDIF
         ENDIF

      ELSEIF wParam == VK_LEFT
         IF ::lSeleCell
            IF ::nColCurr > 1
               IF -- ::nColCurr < ::nColFirst
                  ::nColFirst --
               ENDIF
               ::Refresh( ,,,, .F. )
            ENDIF
         ELSE
            IF ::nColFirst > 1
               ::nColFirst --
               ::Refresh( ,,,, .F. )
            ENDIF
         ENDIF

      ELSEIF wParam == VK_PRIOR
         ::Skip( -::nRowCount )

      ELSEIF wParam == VK_NEXT
         ::Skip( ::nRowCount )

      ELSEIF wParam == VK_RETURN
         ::Edit()

      ENDIF
   ENDIF

   RETURN Nil

METHOD onMouseMove( xPos, yPos ) CLASS HDrawnBrw

   LOCAL j, x

   IF !Empty( ::oEdit )
      IF xPos >= ::oEdit:nLeft .AND. xPos < ::oEdit:nLeft+::oEdit:nWidth .AND. ;
         yPos >= ::oEdit:nTop .AND. yPos <= ::oEdit:nTop+::oEdit:nHeight
         RETURN ::oEdit:onMouseMove( xPos, yPos )
      ELSEIF ::oEdit:nMouseOn > 0
         ::oEdit:onMouseLeave()
      ENDIF
      RETURN Nil
   ENDIF

   IF !Empty( ::oTrackV ) .AND. !::oTrackV:lHide .AND. xPos >= ::oTrackV:nLeft
      ::oTrackV:onMouseMove( xPos, yPos )
   ENDIF
   IF !Empty( ::oTrackH ) .AND. !::oTrackH:lHide .AND. yPos >= ::oTrackH:nTop
      ::oTrackH:onMouseMove( xPos, yPos )
   ENDIF

   IF !::lCaptured
      ::nColResize := 0
      IF ::nHeightHead > 0 .AND. ::nRowCount != 0 .AND. yPos < ::aRows[1,1]
         j := ::nColFirst - 1
         x := ::nLeft + ::aMargin[1]
         DO WHILE ++j <= Len( ::aColumns ) .AND. x < xPos+2
            x += ::aColumns[j]:nWidth
            IF xPos >= x-2 .AND. xPos <= x+2
               ::nColResize := j
               EXIT
            ENDIF
         ENDDO
      ENDIF
   ENDIF

   IF ::nColResize > 0 .OR. ::lCaptured
      Hwg_SetCursor( hCursorSize, ::GetParentBoard():handle )
   ENDIF

   RETURN Nil

METHOD onMouseLeave() CLASS HDrawnBrw

   IF !Empty( ::oTrackV ) .AND. !::oTrackV:lHide
      ::oTrackV:onMouseLeave()
   ENDIF
   IF !Empty( ::oTrackH ) .AND. !::oTrackH:lHide
      ::oTrackH:onMouseLeave()
   ENDIF
   IF !Empty( ::oEdit ) .AND. ::oEdit:nMouseOn > 0
      ::oEdit:onMouseLeave()
   ENDIF

   ::lCaptured := .F.
   ::nColResize := 0
#ifdef __GTK__
   Hwg_SetCursor( hCursorCommon, ::GetParentBoard():handle )
#endif
   RETURN Nil

METHOD onButtonDown( msg, xPos, yPos ) CLASS HDrawnBrw

   LOCAL i := 0, j, x, lRefr := .F., nRow := -1, nCol := -1

   ::SetFocus()
   IF !Empty( ::oEdit )
      IF xPos >= ::oEdit:nLeft .AND. xPos < ::oEdit:nLeft+::oEdit:nWidth .AND. ;
         yPos >= ::oEdit:nTop .AND. yPos <= ::oEdit:nTop+::oEdit:nHeight
         ::oEdit:onButtonDown( msg, xPos, yPos )
         ::SetFocus()
      ENDIF
      RETURN Nil
   ELSEIF ::nRowCount == 0
      RETURN Nil
   ENDIF

   IF !Empty( ::oTrackV ) .AND. !::oTrackV:lHide .AND. xPos >= ::oTrackV:nLeft
      RETURN ::oTrackV:onButtonDown( msg, xPos, yPos )
   ENDIF
   IF !Empty( ::oTrackH ) .AND. !::oTrackH:lHide .AND. yPos >= ::oTrackH:nTop
      RETURN ::oTrackH:onButtonDown( msg, xPos, yPos )
   ENDIF

   IF yPos > ::aRows[1,1]
      DO WHILE ++i <= Len( ::aRows ) .AND. ::aRows[i,1] != Nil
         IF yPos > ::aRows[i,1] .AND. yPos < ::aRows[i,2]
            nRow := i
            EXIT
         ENDIF
      ENDDO
   ELSE
      nRow := 0
   ENDIF

   j := ::nColFirst - 1
   x := ::nLeft + ::aMargin[1]
   DO WHILE ++j <= Len( ::aColumns ) .AND. x < xPos
      x += ::aColumns[j]:nWidth
      IF x > xPos
         nCol := j
          EXIT
      ENDIF
   ENDDO

   IF msg == WM_LBUTTONDOWN
      IF nRow > 0
         IF nRow != ::nRowCurr
            ::oData:Skip( nRow - ::nRowCurr )
            ::nRowCurr := nRow
            lRefr := .T.
         ENDIF
         IF nCol > 0 .AND. nCol != ::nColCurr .AND. ::lSeleCell
            ::nColCurr := nCol
            lRefr := .T.
         ENDIF
      ELSEIF nRow == 0
         IF ::nColResize > 0
            ::lCaptured := .T.
            Hwg_SetCursor( hCursorSize, ::GetParentBoard():handle )
         ELSEIF nCol > 0 .AND. !Empty( ::aColumns[nCol]:bHeadClick )
            Eval( ::aColumns[nCol]:bHeadClick, Self, nCol, xPos, yPos )
         ENDIF
      ENDIF
   ELSEIF !Empty( ::bRClick )
      Eval( ::bRClick, Self, nCol, nRow )
   ENDIF

   IF lRefr
      ::Refresh( ,,,, .F. )
   ENDIF

   RETURN Nil

METHOD onButtonUp( xPos, yPos ) CLASS HDrawnBrw

   LOCAL j, x

   IF !Empty( ::oTrackV ) .AND. !::oTrackV:lHide .AND. xPos >= ::oTrackV:nLeft
      RETURN ::oTrackV:onButtonUp( xPos, yPos )
   ENDIF
   IF !Empty( ::oTrackH ) .AND. !::oTrackH:lHide .AND. yPos >= ::oTrackH:nTop
      RETURN ::oTrackH:onButtonUp( xPos, yPos )
   ENDIF

   IF ::lCaptured
      j := ::nColFirst - 1
      x := ::nLeft + ::aMargin[1]
      DO WHILE ++j < ::nColResize; x += ::aColumns[j]:nWidth; ENDDO
      ::lCaptured := .F.
#ifdef __GTK__
      Hwg_SetCursor( hCursorCommon, ::GetParentBoard():handle )
#endif
      ::nColResize := 0
      IF xPos > x
         ::aColumns[j]:nWidth := xPos - x
         ::Refresh( ,,,, .F. )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onButtonDbl( xPos, yPos ) CLASS HDrawnBrw

   IF xPos > ::nLeft + ::aMargin[1] .AND. xPos < ::nLeft + ::nWidth - ::aMargin[3] .AND. ;
      yPos > ::nTop + ::aMargin[2] + ::nHeightHead .AND. yPos < ::nTop + ::nHeight - ::nHeightFoot - ::aMargin[4]
      ::Edit()
   ENDIF

   RETURN Nil

METHOD onKillFocus() CLASS HDrawnBrw

   IF ::bLostFocus != Nil
      Eval( ::bLostFocus, Self )
   ENDIF

   RETURN Nil

METHOD SetFocus() CLASS HDrawnBrw

   LOCAL oBoard := ::GetParentBoard()

   hwg_SetFocus( oBoard:handle )
   oBoard:oInFocus := Self

   RETURN Nil

METHOD Top() CLASS HDrawnBrw

   ::oData:Top()
   ::nRowCurr := 1
   ::Refresh( ,,,, .F. )

   RETURN Nil

METHOD Skip( n ) CLASS HDrawnBrw

   LOCAL nRecOld := ::oData:RecnoLog(), l := .F.

   ::oData:Skip( n )
   IF n < 0 .AND. ::oData:Bof()
      ::oData:Top()
      l := .T.
   ELSEIF n > 0 .AND. ::oData:Eof()
      ::oData:Bottom()
      l := .T.
   ENDIF
   IF l
      n := ::oData:RecnoLog() - nRecOld
   ENDIF
   IF n < 0
      n := Abs( n )
      IF n < ::nRowCurr
         ::nRowCurr -= n
      ELSE
         ::nRowCurr := 1
      ENDIF
   ELSEIF n > 0
      IF n <= ( ::nRowCount - ::nRowCurr )
         ::nRowCurr += n
      ELSE
         ::nRowCurr := ::nRowCount
      ENDIF
   ENDIF
   ::Refresh( ,,,, .F. )

   RETURN Nil

METHOD Selected( n ) CLASS HDrawnBrw

   RETURN Iif( Empty(n), ::oData:Recno(), Eval( ::aColumns[n]:block,, ::oData ) )

METHOD ShowTrackV( lShow ) CLASS HDrawnBrw

   LOCAL nTrackWidth := Iif( Empty(::nTrackWidth), DEF_HTRACK_WIDTH, ::nTrackWidth )
   LOCAL bOnTrack := {|o,n|
      LOCAL nRecOld := o:oParent:oData:RecnoLog()
      LOCAL nRecNew := Round( o:oParent:oData:Count() * n + 1, 0 )
      IF nRecNew != nRecOld
         o:oParent:Skip( nRecNew - nRecOld )
      ENDIF
      RETURN .T.
   }

   IF lShow
      IF Empty( ::oTrackV ) .OR. ::oTrackV:lHide
         IF Empty( ::oTrackV )
            ::oTrackV := HDrawnTrack():New( Self, ::nLeft+::nWidth-nTrackWidth-::aMargin[3], ;
               ::nTop+::aMargin[2]+::nHeightHead, nTrackWidth, ;
               ::nHeight-+::nHeightHead-+::nHeightFoot-::aMargin[2]-::aMargin[4], ;
               , CLR_BLACK, CLR_WHITE, 48, Iif( Empty(::oStyleBar),Nil,::oStyleBar ), ;
               Iif( Empty(::oStyleSlider),HStyle():New( { 0x888888, 0xcccccc }, 3 ),::oStyleSlider), .F. )
            ::oTrackV:bChange := bOnTrack
            ::aDrawn := {}
         ELSE
            ::oTrackV:lHide := .F.
         ENDIF
         ::aMargin[3] += ::oTrackV:nWidth
         ::Refresh( ,,,, .F. )
      ENDIF
   ELSE
      IF !Empty( ::oTrackV ) .AND. !::oTrackV:lHide
         ::oTrackV:lHide := .T.
         ::aMargin[3] -= ::oTrackV:nWidth
         ::Refresh( ,,,, .F. )
      ENDIF
   ENDIF

   RETURN Nil

METHOD ShowTrackH( lShow ) CLASS HDrawnBrw

   LOCAL nTrackWidth := Iif( Empty(::nTrackWidth), DEF_HTRACK_WIDTH, ::nTrackWidth )
   LOCAL bOnTrack := {|o,n|
      LOCAL nColOld := o:oParent:nColCurr
      LOCAL nColNew := Round( Len( o:oParent:aColumns ) * n, 0 )
      LOCAL i
      IF nColNew > nColOld
         FOR i := 1 TO nColNew - nColOld
            o:oParent:onKey( WM_KEYDOWN, VK_RIGHT, 0 )
         NEXT
      ELSEIF nColNew < nColOld
         FOR i := 1 TO nColOld - nColNew
            o:oParent:onKey( WM_KEYDOWN, VK_LEFT, 0 )
         NEXT
      ENDIF
      RETURN .T.
   }

   IF lShow
      IF Empty( ::oTrackH ) .OR. ::oTrackH:lHide
         IF Empty( ::oTrackH )
            ::oTrackH := HDrawnTrack():New( Self, ::nLeft+::aMargin[1], ;
               ::nTop+::nHeight-::aMargin[4]-nTrackWidth, ::nWidth-::aMargin[1]-::aMargin[3], nTrackWidth, ;
               , CLR_BLACK, CLR_WHITE, 48, Iif( Empty(::oStyleBar),Nil,::oStyleBar ), ;
               Iif( Empty(::oStyleSlider),HStyle():New( { 0x888888, 0xcccccc }, 3 ),::oStyleSlider), .F. )
            ::oTrackH:bChange := bOnTrack
            ::aDrawn := {}
         ELSE
            ::oTrackH:lHide := .F.
         ENDIF
         ::aMargin[4] += ::oTrackH:nHeight
         ::Refresh( ,,,, .F. )
      ENDIF
   ELSE
      IF !Empty( ::oTrackH ) .AND. !::oTrackH:lHide
         ::oTrackH:lHide := .T.
         ::aMargin[4] -= ::oTrackH:nHeight
         ::Refresh( ,,,, .F. )
      ENDIF
   ENDIF

   RETURN Nil

METHOD End() CLASS HDrawnBrw

   LOCAL arr := hb_hKeys( ::pBrushes ), i

   FOR i := 1 TO Len( arr )
      ::pBrushes[arr[i]]:Release()
   NEXT
   RETURN Nil

CLASS HBrwCol INHERIT HObject

   DATA block
   DATA cHead, cFoot
   DATA nWidth
   DATA dec        INIT 0
   DATA nAlignHead, nAlignRow
   DATA tcolor, bcolor
   DATA oFont

   DATA lEditable  INIT .F.      // Is the column editable
   DATA cPicture, bValid
   DATA aList                    // Array of possible values for a column
   DATA nEditType                //

   DATA oPaintCB                 // HPaintCB object

   DATA bHeadClick

   METHOD New( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable )

ENDCLASS

METHOD New( cHead, block, nWidth, nAlignRow, nAlignHead, lEditable ) CLASS HBrwCol

   ::cHead      := iif( cHead == Nil, "", cHead )
   ::block      := block
   ::nWidth     := Iif( Empty( nWidth ), DEF_COL_WIDTH, nWidth )
   ::lEditable  := iif( lEditable != Nil, lEditable, .F. )
   ::nAlignHead := iif( nAlignHead == Nil,  DT_LEFT , nAlignHead )
   ::nAlignRow  := iif( nAlignRow  == Nil,  DT_LEFT , nAlignRow  )

   RETURN Self


CLASS HBrwData INHERIT HObject

   DATA nCurrent     INIT 1
   DATA lNeedBuf     INIT .F.
   DATA lNeedRefresh INIT .F.

   METHOD New()  INLINE Self

   METHOD Bof()      VIRTUAL
   METHOD Eof()      VIRTUAL
   METHOD Top()      VIRTUAL
   METHOD Bottom()   VIRTUAL
   METHOD Recno()    VIRTUAL
   METHOD RecnoLog() VIRTUAL
   METHOD GoTo( n )  VIRTUAL
   METHOD Count()    VIRTUAL
   METHOD Skip( nSkip ) VIRTUAL

   METHOD Block( x )    VIRTUAL
ENDCLASS

CLASS HDataArray INHERIT HBrwData

   DATA   aData

   METHOD New( arr )

   METHOD Bof()      INLINE (::nCurrent == 0)
   METHOD Eof()      INLINE (::nCurrent > Len(::aData))
   METHOD Top()      INLINE ::nCurrent := 1
   METHOD Bottom()   INLINE ::nCurrent := Len(::aData)
   METHOD Recno()    INLINE ::nCurrent
   METHOD RecnoLog() INLINE ::nCurrent
   METHOD GoTo( n )
   METHOD Count()    INLINE Len(::aData)
   METHOD Skip( nSkip )
   METHOD Block( x )

ENDCLASS

METHOD New( arr ) CLASS HDataArray

   ::aData := arr

   RETURN ::Super:New()

METHOD GoTo( n ) CLASS HDataArray

   ::nCurrent := n
   IF ::nCurrent < 1
      ::nCurrent := 0
   ELSEIF ::nCurrent > Len( ::aData )
      ::nCurrent := Len( ::aData ) + 1
   ENDIF

   RETURN Nil

METHOD Skip( nSkip ) CLASS HDataArray

   ::nCurrent += nSkip + iif( ::nCurrent == 0, 1, 0 )
   IF ::nCurrent < 1
      ::nCurrent := 0
   ELSEIF ::nCurrent > Len( ::aData )
      ::nCurrent := Len( ::aData ) + 1
   ENDIF

   RETURN Nil

METHOD Block( x ) CLASS HDataArray

   IF ValType( ::aData[1] ) == "A"
      IF Empty( x )
         x := 1
      ENDIF
      RETURN &( "{|v,o| iif( v == Nil, o:aData[o:nCurrent," + Ltrim(Str(x)) + ;
         "], o:aData[o:nCurrent," + Ltrim(Str(x)) + "] := v ) }" )
   ENDIF

   RETURN {|value,o| iif( value == Nil, o:aData[o:nCurrent], o:aData[o:nCurrent] := value ) }

#include "dbinfo.ch"

CLASS HDataDbf INHERIT HBrwData

   DATA cAlias

   METHOD New( cAlias )

   METHOD Bof()     INLINE (::cAlias)->(Bof())
   METHOD Eof()     INLINE (::cAlias)->(Eof())
   METHOD Top()     INLINE (::cAlias)->(dbGoTop())
   METHOD Bottom()  INLINE (::cAlias)->(dbGoBottom())
   METHOD Recno()   INLINE (::cAlias)->(Recno())
   METHOD RecnoLog()
   METHOD GoTo( n ) INLINE (::cAlias)->(dbGoTo(n))
   METHOD Count()
   METHOD Skip( nSkip )  INLINE (::cAlias)->(dbSkip(nSkip))
   METHOD Block( x )

ENDCLASS

METHOD New( cAlias ) CLASS HDataDbf

   ::cAlias := cAlias
   ::lNeedBuf := .T.

   RETURN ::Super:New()

METHOD RecnoLog() CLASS HDataDbf
   RETURN (::cAlias)->( Iif( OrdNumber() == 0, Recno(), OrdKeyNo() ) )

METHOD Count() CLASS HDataDbf
   RETURN (::cAlias)->( Iif( OrdNumber() == 0, RecCount(), OrdKeyCount() ) )

METHOD Block( x ) CLASS HDataDbf

   IF Valtype( x ) == "C" .AND. (::cAlias)->( Fieldpos( x ) ) == 0
      RETURN &( "{||" + x + "}" )
   ENDIF

   x := Iif( Valtype(x) == "N", (::cAlias)->( FieldName( x ) ), x )

   IF (::cAlias)->( Dbinfo(DBI_ISREADONLY) )
      RETURN &( "{||(" + ::cAlias + ")->" + x + "}" )
   ENDIF

   RETURN &( "{|xVal|Iif(xVal==Nil,"+ ::cAlias + "->" + x + ;
      "," + Iif( (::cAlias)->( Dbinfo(DBI_SHARED) ), ;
      ""+::cAlias+"->(Rlock(),field->" + x + ":=xVal,dbUnlock())", ;
      ::cAlias+"->" + x + ":=xVal" ) + ")}" )
