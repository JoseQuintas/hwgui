/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HBrowse class - browse databases and arrays
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "inkey.ch"
#include "dbstruct.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "gtk.ch"

REQUEST DBGOTOP
REQUEST DBGOTO
REQUEST DBGOBOTTOM
REQUEST DBSKIP
REQUEST RECCOUNT
REQUEST RECNO
REQUEST EOF
REQUEST BOF

#ifndef SB_HORZ
#define SB_HORZ             0
#define SB_VERT             1
#define SB_CTL              2
#define SB_BOTH             3
#endif
#define HDM_GETITEMCOUNT    4608

STATIC crossCursor := nil
STATIC arrowCursor := nil
STATIC vCursor     := nil
STATIC xDrag

CLASS HColumn INHERIT HObject

   DATA block, heading, footing, width, type
   DATA length INIT 0
   DATA dec, cargo
   DATA nJusHead, nJusLin        // Para poder Justificar los Encabezados
   // de las columnas y lineas.
   // WHT. 27.07.2002
   DATA tcolor, bcolor, brush
   DATA oFont
   DATA lEditable INIT .F.       // Is the column editable
   DATA aList                    // Array of possible values for a column -
                                 // combobox will be used while editing the cell
   DATA oStyleHead               // An HStyle object to draw the header
   DATA aBitmaps
   DATA bValid, bWhen            // When and Valid codeblocks for cell editing
   DATA bEdit                    // Codeblock, which performs cell editing, if defined
   DATA cGrid
   DATA lSpandHead INIT .F.
   DATA lSpandFoot INIT .F.
   DATA PICTURE
   DATA bHeadClick
   DATA bColorBlock              //   bColorBlock must return an array containing four colors values
   //   oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
   //      {textColor, backColor, textColorSel, backColorSel} , ;
   //      {textColor, backColor, textColorSel, backColorSel} ) }

   METHOD New( cHeading, block, type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick )

ENDCLASS

METHOD New( cHeading, block, type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick ) CLASS HColumn

   ::heading   := iif( cHeading == nil, "", cHeading )
   ::block     := block
   ::type      := type
   ::length    := length
   ::dec       := dec
   ::lEditable := iif( lEditable != Nil, lEditable, .F. )
   ::nJusHead  := iif( nJusHead == nil,  DT_LEFT , nJusHead )  // Por default
   ::nJusLin   := iif( nJusLin  == nil,  DT_LEFT , nJusLin  )  // Justif.Izquierda
   ::picture   := cPict
   ::bValid    := bValid
   ::bWhen     := bWhen
   ::aList     := aItem
   ::bColorBlock := bColorBlock
   ::bHeadClick  := bHeadClick

   RETURN Self

CLASS HBrowse INHERIT HControl

   DATA winclass   INIT "BROWSE"
   DATA active     INIT .T.
   DATA lChanged   INIT .F.
   DATA lDispHead  INIT .T.                    // Should I display headers ?
   DATA lDispSep   INIT .T.                    // Should I display separators ?
   DATA aColumns                               // HColumn's array
   DATA rowCount   INIT 2                      // Number of visible data rows
   DATA rowPos     INIT 1                      // Current row position
   DATA rowCurrCount INIT 0                    // Current number of rows
   DATA colPos     INIT 1                      // Current column position
   DATA nColumns                               // Number of visible data columns
   DATA nLeftCol                               // Leftmost column
   DATA xpos
   DATA freeze                                 // Number of columns to freeze
   DATA nRecords                               // Number of records in browse
   DATA nCurrent      INIT 1                   // Current record
   DATA aArray                                 // An array browsed if this is BROWSE ARRAY
   DATA lInFocus   INIT .F.                    // Set focus in :Paint()
   DATA recCurr INIT 0
   DATA oStyleHead                             // An HStyle object to draw the header
   DATA headColor                              // Header text color
   DATA sepColor INIT 12632256                 // Separators color
   DATA lSep3d  INIT .F.
   DATA aPadding   INIT { 4,2,4,2 }
   DATA aHeadPadding   INIT { 4,0,4,0 }
   DATA varbuf                                 // Used on Edit()
   DATA tcolorSel, bcolorSel, brushSel, htbColor, httColor
   DATA bSkip, bGoTo, bGoTop, bGoBot, bEof, bBof
   DATA bRcou, bRecno, bRecnoLog
   DATA bPosChanged, bLineOut, bScrollPos
   DATA bEnter, bKeyDown, bUpdate, bRClick
   DATA internal
   DATA ALIAS                                  // Alias name of browsed database
   DATA x1, y1, x2, y2, width, height
   DATA minHeight INIT 0
   DATA lEditable INIT .F.
   DATA lAppable  INIT .F.
   DATA lAppMode  INIT .F.
   DATA lAutoEdit INIT .F.
   DATA lUpdated  INIT .F.
   DATA lAppended INIT .F.
   DATA lEditing  INIT .F.                     // .T., if a field is edited now
   DATA lAdjRight INIT .T.                     // Adjust last column to right
   DATA nHeadRows INIT 1                       // Rows in header
   DATA nFootRows INIT 0                       // Rows in footer
   DATA nCtrlPress INIT 0                      // Left or Right Ctrl key code while Ctrl key is pressed
   DATA aSelected                              // An array of selected records numbers

   DATA area
   DATA hScrollV  INIT Nil
   DATA hScrollH  INIT Nil
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
   DATA oGet, nGetRec
   DATA lBtnDbl   INIT .F.
   DATA nCursor   INIT 0

   METHOD New( lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, lNoBorder, ;
      lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect )
   METHOD InitBrw( nType )
   METHOD Rebuild()
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddColumn( oColumn )
   METHOD InsColumn( oColumn, nPos )
   METHOD DelColumn( nPos )
   METHOD Paint()
   METHOD LineOut()
   METHOD DrawHeader( hDC, oColumn, x1, y1, x2, y2, oPen )
   METHOD HeaderOut( hDC )
   METHOD FooterOut( hDC )
   METHOD SetColumn( nCol )
   METHOD DoHScroll( wParam )
   METHOD DoVScroll( wParam )
   METHOD LineDown( lMouse )
   METHOD LineUp()
   METHOD PageUp()
   METHOD PageDown()
   METHOD Home()  INLINE ::DoHScroll( SB_LEFT )
   METHOD Bottom( lPaint )
   METHOD Top()
   METHOD ButtonDown( lParam )
   METHOD ButtonUp( lParam )
   METHOD ButtonDbl( lParam )
   METHOD ButtonRDown( lParam )
   METHOD MouseMove( wParam, lParam )
   METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos )
   METHOD Edit( wParam, lParam )
   METHOD APPEND() INLINE ( ::Bottom( .F. ), ::LineDown() )
   METHOD RefreshLine()
   METHOD Refresh( lFull )
   METHOD Setfocus() INLINE hwg_SetFocus( ::area )
   METHOD End()

ENDCLASS

METHOD New( lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
      lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect ) CLASS HBrowse

   nStyle   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_CHILD + WS_VISIBLE + ;
      iif( lNoBorder = Nil .OR. !lNoBorder, WS_BORDER, 0 ) +            ;
      iif( lNoVScroll = Nil .OR. !lNoVScroll, WS_VSCROLL, 0 ) )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, iif( nWidth == Nil,0,nWidth ), ;
      iif( nHeight == Nil, 0, nHeight ), oFont, bInit, bSize, bPaint )

   ::type    := lType
   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bGetFocus   := bGFocus
   ::bLostFocus  := bLFocus

   ::lAppable    := iif( lAppend == Nil, .F. , lAppend )
   ::lAutoEdit   := iif( lAutoedit == Nil, .F. , lAutoedit )
   ::bUpdate     := bUpdate
   ::bKeyDown    := bKeyDown
   ::bPosChanged := bPosChg
   IF lMultiSelect != Nil .AND. lMultiSelect
      ::aSelected := {}
   ENDIF

   ::tcolor := 0
   ::bcolor := hwg_ColorC2N( "FFFFFF" )
   ::tcolorSel := ::httColor := hwg_ColorC2N( "FFFFFF" )
   ::bcolorSel := hwg_ColorC2N( "808080" )
   ::htbColor := 2896388

   ::InitBrw()
   ::Activate()

   RETURN Self

METHOD Activate CLASS HBrowse

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbrowse( Self )
      ::Init()
   ENDIF

   RETURN Self

METHOD onEvent( msg, wParam, lParam )  CLASS HBrowse

   LOCAL aCoors, retValue := - 1

   // hwg_WriteLog( "Brw: "+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF ::active .AND. !Empty( ::aColumns )

      IF ::bOther != Nil
         Eval( ::bOther, Self, msg, wParam, lParam )
      ENDIF

      IF msg == WM_PAINT
         ::Paint()
         retValue := 1

      ELSEIF msg == WM_ERASEBKGND
         IF ::brush != Nil

            aCoors := hwg_Getclientrect( ::handle )
            hwg_Fillrect( wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, ::brush:handle )
            retValue := 1
         ENDIF

      ELSEIF msg == WM_SETFOCUS
         IF ::bGetFocus != Nil
            Eval( ::bGetFocus, Self )
         ENDIF

      ELSEIF msg == WM_KILLFOCUS
         IF ::bLostFocus != Nil
            Eval( ::bLostFocus, Self )
         ENDIF

      ELSEIF msg == WM_HSCROLL
         ::DoHScroll()

      ELSEIF msg == WM_VSCROLL
         ::DoVScroll( wParam )

      ELSEIF msg == WM_COMMAND
         hwg_DlgCommand( Self, wParam, lParam )


      ELSEIF msg == WM_KEYUP
         IF wParam == GDK_Control_L .OR. wParam == GDK_Control_R
            IF wParam == ::nCtrlPress
               ::nCtrlPress := 0
            ENDIF
         ENDIF
         retValue := 1
      ELSEIF msg == WM_KEYDOWN
         IF ::bKeyDown != Nil
            IF !Eval( ::bKeyDown, Self, wParam )
               retValue := 1
            ENDIF
         ENDIF
         IF wParam == GDK_Down        // Down
            ::LINEDOWN()
         ELSEIF wParam == GDK_Up    // Up
            ::LINEUP()
         ELSEIF wParam == GDK_Right    // Right
            LineRight( Self )
         ELSEIF wParam == GDK_Left    // Left
            LineLeft( Self )
         ELSEIF wParam == GDK_Home    // Home
            ::DoHScroll( SB_LEFT )
         ELSEIF wParam == GDK_End    // End
            ::DoHScroll( SB_RIGHT )
         ELSEIF wParam == GDK_Page_Down    // PageDown
            IF ::nCtrlPress != 0
               ::BOTTOM()
            ELSE
               ::PageDown()
            ENDIF
         ELSEIF wParam == GDK_Page_Up    // PageUp
            IF ::nCtrlPress != 0
               ::TOP()
            ELSE
               ::PageUp()
            ENDIF
         ELSEIF wParam == GDK_Return  // Enter
            ::Edit()
         ELSEIF wParam == GDK_Control_L .OR. wParam == GDK_Control_R
            IF ::nCtrlPress == 0
               ::nCtrlPress := wParam
            ENDIF
         ELSEIF ( wParam >= 48 .AND. wParam <= 90 .OR. wParam >= 96 .AND. wParam <= 111 ) .AND. ::lAutoEdit
            ::Edit( wParam, lParam )
         ENDIF
         retValue := 1

      ELSEIF msg == WM_LBUTTONDOWN
         ::ButtonDown( lParam )

      ELSEIF msg == WM_LBUTTONUP
         ::ButtonUp( lParam )

      ELSEIF msg == WM_LBUTTONDBLCLK
         ::ButtonDbl( lParam )

      ELSEIF msg == WM_RBUTTONDOWN
         ::ButtonRDown( lParam )

      ELSEIF msg == WM_MOUSEMOVE
         ::MouseMove( wParam, lParam )

      ELSEIF msg == WM_MOUSEWHEEL
         ::MouseWheel( hwg_Loword( wParam ), ;
            If( hwg_Hiword( wParam ) > 32768, ;
            hwg_Hiword( wParam ) - 65535, hwg_Hiword( wParam ) ), ;
            hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ELSEIF msg == WM_DESTROY
         ::End()
      ENDIF

   ENDIF

   RETURN retValue

METHOD Init CLASS HBrowse

   IF !::lInit
      ::Super:Init()
      // hwg_Setwindowobject( ::handle,Self )
   ENDIF

   RETURN Nil

METHOD AddColumn( oColumn ) CLASS HBrowse

   LOCAL n, arr

   IF Valtype( oColumn ) == "A"
      arr := oColumn
      n := Len(arr)
      oColumn := HColumn():New( Iif(n>0,arr[1],Nil), Iif(n>1,arr[2],Nil), ;
         Iif(n>2,arr[3],Nil), Iif(n>3,arr[4],Nil), Iif(n>4,arr[5],Nil), Iif(n>5,arr[6],Nil) )
   ENDIF

   AAdd( ::aColumns, oColumn )
   ::lChanged := .T.
   InitColumn( Self, oColumn, Len( ::aColumns ) )

   RETURN oColumn

METHOD InsColumn( oColumn, nPos ) CLASS HBrowse

   AAdd( ::aColumns, Nil )
   AIns( ::aColumns, nPos )
   ::aColumns[ nPos ] := oColumn
   ::lChanged := .T.
   InitColumn( Self, oColumn, nPos )

   RETURN oColumn

STATIC FUNCTION InitColumn( oBrw, oColumn, n )

   IF oColumn:type == Nil
      oColumn:type := ValType( Eval( oColumn:block,,oBrw,n ) )
   ENDIF
   IF oColumn:dec == Nil
      IF oColumn:type == "N" .AND. At( '.', Str( Eval( oColumn:block,,oBrw,n ) ) ) != 0
         oColumn:dec := Len( SubStr( Str( Eval( oColumn:block,,oBrw,n ) ), ;
            At( '.', Str( Eval( oColumn:block,,oBrw,n ) ) ) + 1 ) )
      ELSE
         oColumn:dec := 0
      ENDIF
   ENDIF
   IF oColumn:length == Nil
      IF oColumn:picture != Nil
         oColumn:length := Len( Transform( Eval( oColumn:block,,oBrw,n ), oColumn:picture ) )
      ELSE
         oColumn:length := 10
      ENDIF
      oColumn:length := Max( oColumn:length, Len( oColumn:heading ) )
   ENDIF

   RETURN Nil

METHOD DelColumn( nPos ) CLASS HBrowse

   ADel( ::aColumns, nPos )
   ASize( ::aColumns, Len( ::aColumns ) - 1 )
   ::lChanged := .T.

   RETURN Nil

METHOD End() CLASS HBrowse

   hwg_ReleaseObject( ::area )
   IF ::hScrollV != Nil
      hwg_ReleaseObject( ::hScrollV )
   ENDIF
   IF ::hScrollH != Nil
      hwg_ReleaseObject( ::hScrollH )
   ENDIF

   ::Super:End()
   IF ::brush != Nil
      ::brush:Release()
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
   ENDIF

   RETURN Nil

METHOD InitBrw( nType )  CLASS HBrowse

   IF nType != Nil
      ::type := nType
   ELSE
      ::aColumns := {}
      ::nRecords := 0
      ::nLeftCol := 1
      ::internal := { 15, 1 }
      ::aArray   := Nil
      ::freeze := ::height := 0

      IF Empty( crossCursor )
         crossCursor := hwg_Loadcursor( GDK_CROSS )
         arrowCursor := hwg_Loadcursor( GDK_LEFT_PTR )
         vCursor := hwg_Loadcursor( GDK_SB_V_DOUBLE_ARROW )
      ENDIF
   ENDIF
   ::rowPos := ::nCurrent := ::colpos := 1

   if ::type == BRW_DATABASE
      ::alias   := Alias()
      ::bSKip   := &( "{|o, x|" + ::alias + "->(DBSKIP(x)) }" )
      ::bGoTop  := &( "{||" + ::alias + "->(DBGOTOP())}" )
      ::bGoBot  := &( "{||" + ::alias + "->(DBGOBOTTOM())}" )
      ::bEof    := &( "{||" + ::alias + "->(EOF())}" )
      ::bBof    := &( "{||" + ::alias + "->(BOF())}" )
      ::bRcou   := &( "{||" + ::alias + "->(RECCOUNT())}" )
      ::bRecnoLog := ::bRecno  := &( "{||" + ::alias + "->(RECNO())}" )
      ::bGoTo   := &( "{|a,n|"  + ::alias + "->(DBGOTO(n))}" )
   elseif ::type == BRW_ARRAY
      ::bSKip   := { | o, x | ARSKIP( o, x ) }
      ::bGoTop  := { | o | o:nCurrent := 1 }
      ::bGoBot  := { | o | o:nCurrent := o:nRecords }
      ::bEof    := { | o | o:nCurrent > o:nRecords }
      ::bBof    := { | o | o:nCurrent == 0 }
      ::bRcou   := { | o | Len( o:aArray ) }
      ::bRecnoLog := ::bRecno  := { | o | o:nCurrent }
      ::bGoTo   := { | o, n | o:nCurrent := n }
      ::bScrollPos := { |o, n, lEof, nPos|hwg_VScrollPos( o, n, lEof, nPos ) }
   ENDIF

   RETURN Nil

METHOD Rebuild( hDC ) CLASS HBrowse

   LOCAL i, j, oColumn, xSize, nColLen, nHdrLen, nCount

   IF ::brush != Nil
      ::brush:Release()
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
   ENDIF
   IF ::bcolor != Nil
      ::brush     := HBrush():Add( ::bcolor )
   ENDIF
   IF ::bcolorSel != Nil
      ::brushSel  := HBrush():Add( ::bcolorSel )
   ENDIF

   ::nLeftCol  := ::freeze + 1
   ::lEditable := .F.

   ::minHeight := 0
   for i := 1 TO Len( ::aColumns )

      oColumn := ::aColumns[i]

      IF oColumn:lEditable
         ::lEditable := .T.
      ENDIF

      IF oColumn:aBitmaps != Nil
         xSize := 0
         FOR j := 1 TO Len( oColumn:aBitmaps )
            IF Valtype( oColumn:aBitmaps[j,2] ) == "O"
               xSize := Max( xSize, oColumn:aBitmaps[j,2]:nWidth + 2 )
               ::minHeight := Max( ::minHeight, oColumn:aBitmaps[j,2]:nHeight )
            ENDIF
         NEXT
      ELSE
         // xSize := round( (max( len( FldStr( Self,i ) ), len( oColumn:heading ) ) + 2 ) * 8, 0 )
         nColLen := oColumn:length
         IF oColumn:heading != nil
            HdrToken( oColumn:heading, @nHdrLen, @nCount )
            IF ! oColumn:lSpandHead
               nColLen := Max( nColLen, nHdrLen )
            ENDIF
            ::nHeadRows := Max( ::nHeadRows, nCount )
         ENDIF
         IF oColumn:footing != nil
            HdrToken( oColumn:footing, @nHdrLen, @nCount )
            IF ! oColumn:lSpandFoot
               nColLen := Max( nColLen, nHdrLen )
            ENDIF
            ::nFootRows := Max( ::nFootRows, nCount )
         ENDIF
         xSize := Round( ( nColLen + 2 ) * 8, 0 )
      ENDIF

      oColumn:width := xSize + ::aPadding[1] + ::aPadding[3]

   next

   ::lChanged := .F.

   RETURN Nil

METHOD Paint()  CLASS HBrowse

   LOCAL aCoors, aMetr, i, oldAlias, tmp, nRows
   LOCAL pps, hDC
   LOCAL oldBkColor, oldTColor

   IF !::active .OR. Empty( ::aColumns )
      RETURN Nil
   ENDIF

   hDC := hwg_Getdc( ::area )

   if ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   IF ::brush == Nil .OR. ::lChanged
      ::Rebuild( hDC )
   ENDIF
   aCoors := hwg_Getclientrect( ::handle )
   //hwg_Rectangle( hDC, aCoors[1],aCoors[2],aCoors[3]-1,aCoors[4]-1 )
   hwg_gtk_drawedge( hDC, aCoors[1], aCoors[2], aCoors[3] - 1, aCoors[4] - 1, 6 )
   aMetr := hwg_Gettextmetric( hDC )

   ::width := aMetr[ 2 ]
   ::height := Max( aMetr[ 1 ], ::minHeight )

   ::x1 := aCoors[ 1 ] + 2
   ::y1 := aCoors[ 2 ] + 2 + iif( ::lDispHead, ::height * ::nHeadRows, 0 )
   ::y1 := aCoors[ 2 ] + 2 + Iif( ::lDispHead, ::height * ::nHeadRows + ::aHeadPadding[2] + ::aHeadPadding[4], 0 )
   ::x2 := aCoors[ 3 ] - 2
   ::y2 := aCoors[ 4 ] - 2

   ::height += ::aPadding[2] + ::aPadding[4]

   ::nRecords := Eval( ::bRcou, Self )
   IF ::nCurrent > ::nRecords .AND. ::nRecords > 0
      ::nCurrent := ::nRecords
   ENDIF

   ::nColumns := FLDCOUNT( Self, ::x1 + 2, ::x2 - 2, ::nLeftCol )
   ::rowCount := Int( ( ::y2 - ::y1 ) / ( ::height + 1 ) ) - ::nFootRows
   nRows := Min( ::nRecords, ::rowCount )

   IF ::hScrollV != Nil
      tmp := iif( ::nRecords < 100, ::nRecords, 100 )
      i := iif( ::nRecords < 100, 1, ::nRecords/100 )
      hwg_SetAdjOptions( ::hScrollV, , tmp + nRows, i, nRows, nRows )
   ENDIF
   IF ::hScrollH != Nil
      tmp := Len( ::aColumns )
      hwg_SetAdjOptions( ::hScrollH, , tmp + 1, 1, 1, 1 )
   ENDIF

   IF ::internal[1] == 0
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval( ::bSkip, Self, ::internal[2] - ::rowPos )
      ENDIF
      IF ::aSelected != Nil .AND. Ascan( ::aSelected, { |x| x = Eval( ::bRecno,Self ) } ) > 0
         ::LineOut( ::internal[2], 0, hDC, .T. )
      ELSE
         ::LineOut( ::internal[2], 0, hDC, .F. )
      ENDIF
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval( ::bSkip, Self, ::rowPos - ::internal[2] )
      ENDIF
   ELSE
      IF Eval( ::bEof, Self )
         Eval( ::bGoTop, Self )
         ::rowPos := 1
      ENDIF
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF
      tmp := Eval( ::bRecno, Self )
      IF ::rowPos > 1
         Eval( ::bSkip, Self, - ( ::rowPos - 1 ) )
      ENDIF
      i := 1
      DO WHILE .T.
         IF Eval( ::bRecno, Self ) == tmp
            ::rowPos := i
         ENDIF
         IF i > nRows .OR. Eval( ::bEof, Self )
            EXIT
         ENDIF
         IF ::aSelected != Nil .AND. Ascan( ::aSelected, { |x| x = Eval( ::bRecno,Self ) } ) > 0
            ::LineOut( i, 0, hDC, .T. )
         ELSE
            ::LineOut( i, 0, hDC, .F. )
         ENDIF
         i ++
         Eval( ::bSkip, Self, 1 )
      ENDDO
      ::rowCurrCount := i - 1

      IF ::rowPos >= i
         ::rowPos := iif( i > 1, i - 1, 1 )
      ENDIF
      DO WHILE i <= nRows
         IF ::aSelected != Nil .AND. Ascan( ::aSelected, { |x| x = Eval( ::bRecno,Self ) } ) > 0
            ::LineOut( i, 0, hDC, .T. , .T. )
         ELSE
            ::LineOut( i, 0, hDC, .F. , .T. )
         ENDIF
         i ++
      ENDDO

      Eval( ::bGoTo, Self, tmp )
   ENDIF
   IF ::lAppMode
      ::LineOut( nRows + 1, 0, hDC, .F. , .T. )
   ENDIF

   //::LineOut( ::rowPos, iif( ::lEditable, ::colpos, 0 ), hDC, .T. )
   ::LineOut( ::rowPos, 0, hDC, .T. )
   ::LineOut( ::rowPos, ::colpos, hDC, .T. )
   IF hwg_Checkbit( ::internal[1], 1 ) .OR. ::lAppMode
      ::HeaderOut( hDC )
      if ::nFootRows > 0
         ::FooterOut( hDC )
      ENDIF
   ENDIF

   hwg_Releasedc( ::area, hDC )
   ::internal[1] := 15
   ::internal[2] := ::rowPos
   tmp := Eval( ::bRecno, Self )
   IF ::recCurr != tmp
      ::recCurr := tmp
      IF ::bPosChanged != Nil
         Eval( ::bPosChanged, Self )
      ENDIF
   ENDIF

   IF ::lAppMode
      ::Edit()
   ENDIF

   IF ::lInFocus .AND. ::oGet == Nil .AND. ( ( tmp := hwg_Getfocus() ) == ::oParent:handle .OR. ;
         ::oParent:FindControl( , tmp ) != Nil )
      hwg_Setfocus( ::area )
   ENDIF
   ::lAppMode := .F.

   RETURN Nil

METHOD DrawHeader( hDC, oColumn, x1, y1, x2, y2, oPen ) CLASS HBrowse

   LOCAL cStr, cNWSE, nLine, nHeight := ::height - ::aPadding[2] - ::aPadding[4] //, oPenHdr

   IF oColumn:oStyleHead != Nil
      oColumn:oStyleHead:Draw( hDC, x1, y1, x2, y2 )
   ELSEIF ::oStyleHead != Nil
      ::oStyleHead:Draw( hDC, x1, y1, x2, y2 )
      hwg_Selectobject( hDC, oPen:handle )
   ELSE
      hwg_Drawbutton( hDC, x1, y1, x2, y2, Iif(oColumn:cGrid == Nil, 5, 0 ) )
   ENDIF

   IF oColumn:cGrid != Nil
      //IF oPenHdr == Nil
      //   oPenHdr := HPen():Add( BS_SOLID, 1, 0 )
      //ENDIF
      //hwg_Selectobject( hDC, oPenHdr:handle )
      cStr := oColumn:cGrid + ';'
      FOR nLine := 1 TO ::nHeadRows
         cNWSE := hb_tokenGet( @cStr, nLine, ';' )
         IF At( 'S', cNWSE ) != 0
            hwg_Drawline( hDC, x1, y1 + ::height * nLine, x2, y1 + ::height * nLine )
         ENDIF
         IF At( 'N', cNWSE ) != 0
            hwg_Drawline( hDC, x1, y1 + ::height * (nLine-1), x2, y1 + ::height * (nLine-1) )
         ENDIF
         IF At( 'E', cNWSE ) != 0
            hwg_Drawline( hDC, x2-1, y1 + ::height * (nLine-1) + 1, x2-1, y1 + ::height * nLine )
         ENDIF
         IF At( 'W', cNWSE ) != 0
            hwg_Drawline( hDC, x1, y1 + ::height * (nLine-1) + 1, x1, y1 + ::height * nLine )
         ENDIF
      NEXT
      //hwg_Selectobject( hDC, oPen:handle )
      //IF oPenHdr != Nil
      //   oPenHdr:Release()
      //ENDIF
   ENDIF
   cStr := oColumn:heading + ';'
   FOR nLine := 1 TO ::nHeadRows
      hwg_Drawtext( hDC, hb_tokenGet( @cStr, nLine, ';' ), x1+1+::aHeadPadding[1],    ;
            y1 + nHeight * (nLine-1) + 1 + ::aHeadPadding[2], x2 - ::aHeadPadding[3], ;
            y1 + nHeight * nLine + ::aHeadPadding[2] + ::aHeadPadding[4], ;
            oColumn:nJusHead  + Iif( oColumn:lSpandHead, DT_NOCLIP, 0 ) )
   NEXT

   RETURN Nil

METHOD HeaderOut( hDC ) CLASS HBrowse

   LOCAL i, x, y1, oldc, fif, xSize
   LOCAL nRows := Min( ::nRecords + iif( ::lAppMode,1,0 ), ::rowCount )
   LOCAL oPen // , oldBkColor := hwg_Setbkcolor( hDC,hwg_Getsyscolor(COLOR_3DFACE) )
   LOCAL oColumn, nLine, cStr, cNWSE, oPenHdr, oPenLight

   IF ::lDispSep
      oPen := HPen():Add( PS_SOLID, 0.6, ::sepColor )
      hwg_Selectobject( hDC, oPen:handle )
   ENDIF

   x := ::x1
   y1 := ::y1 - ( ::height - ::aPadding[2] - ::aPadding[4] ) * ::nHeadRows - ::aHeadPadding[2] - ::aHeadPadding[4]
   if ::headColor != Nil
      oldc := hwg_Settextcolor( hDC, ::headColor )
   ENDIF
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      if ::lAdjRight .AND. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      if ::lDispHead .AND. !::lAppMode
         ::DrawHeader( hDC, oColumn, x-1, y1, x + xSize - 1, ::y1 + 1, oPen )
      ENDIF
      if ::lDispSep .AND. x > ::x1
         IF ::lSep3d
            hwg_Selectobject( hDC, oPenLight:handle )
            hwg_Drawline( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * nRows )
            hwg_Selectobject( hDC, oPen:handle )
            hwg_Drawline( hDC, x - 2, ::y1 + 1, x - 2, ::y1 + ( ::height + 1 ) * nRows )
         ELSE
            hwg_Drawline( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * nRows )
         ENDIF
      ENDIF
      x += xSize
      IF ! ::lAdjRight .AND. fif == Len( ::aColumns )
         hwg_Drawline( hDC, x - 1, y1, x - 1, ::y1 + ( ::height + 1 ) * nRows )
      ENDIF
      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO

   IF ::lDispSep
      for i := 1 TO nRows
         hwg_Drawline( hDC, ::x1, ::y1 + ( ::height + 1 ) * i, iif( ::lAdjRight, ::x2, x ), ::y1 + ( ::height + 1 ) * i )
      next
      oPen:Release()
      IF oPenHdr != nil
         oPenHdr:Release()
      ENDIF
      IF oPenLight != nil
         oPenLight:Release()
      ENDIF
   ENDIF

   /* hwg_Setbkcolor( hDC,oldBkColor ) */
   if ::headColor <> Nil
      hwg_Settextcolor( hDC, oldc )
   ENDIF

   RETURN Nil

METHOD FooterOut( hDC ) CLASS HBrowse

   LOCAL i, x, fif, xSize, oPen, nLine, cStr
   LOCAL oColumn

   IF ::lDispSep
      oPen := HPen():Add( BS_SOLID, 0.6, ::sepColor )
      hwg_Selectobject( hDC, oPen:handle )
   ENDIF

   x := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      if ::lAdjRight .AND. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      IF oColumn:footing <> nil
         cStr := oColumn:footing + ';'
         for nLine := 1 to ::nFootRows
            hwg_Drawtext( hDC, hb_tokenGet( @cStr, nLine, ';' ), ;
               x, ::y1 + ( ::rowCount + nLine - 1 ) * ( ::height + 1 ) + 1, x + xSize - 1, ::y1 + ( ::rowCount + nLine ) * ( ::height + 1 ), ;
               oColumn:nJusLin + if( oColumn:lSpandFoot, DT_NOCLIP, 0 ) )
         next
      ENDIF
      x += xSize
      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO

   IF ::lDispSep
      hwg_Drawline( hDC, ::x1, ::y1 + ( ::rowCount ) * ( ::height + 1 ) + 1, iif( ::lAdjRight, ::x2, x ), ::y1 + ( ::rowCount ) * ( ::height + 1 ) + 1 )
      oPen:Release()
   ENDIF

   RETURN Nil

METHOD LineOut( nstroka, vybfld, hDC, lSelected, lClear ) CLASS HBrowse

   LOCAL x, dx, i := 1, shablon, sviv, fif, fldname, slen, xSize
   LOCAL j, ob, bw, bh, y1, hBReal
   LOCAL oldBkColor, oldTColor, oldBk1Color, oldT1Color
   LOCAL oLineBrush := iif( vybfld >= 1, HBrush():Add( ::htbColor ), iif( lSelected, ::brushSel,::brush ) )
   LOCAL lColumnFont := .F.
   LOCAL aCores

   ::xpos := x := ::x1
   IF lClear == Nil ; lClear := .F. ; ENDIF

   IF ::bLineOut != Nil
      Eval( ::bLineOut, Self, lSelected )
   ENDIF
   IF ::nRecords > 0
      oldBkColor := hwg_Setbkcolor(   hDC, iif( vybfld >= 1,::htbcolor, iif( lSelected,::bcolorSel,::bcolor ) ) )
      oldTColor  := hwg_Settextcolor( hDC, iif( vybfld >= 1,::httcolor, iif( lSelected,::tcolorSel,::tcolor ) ) )
      fldname := Space( 8 )
      fif     := iif( ::freeze > 0, 1, ::nLeftCol )

      WHILE x < ::x2 - 2
         IF ::aColumns[fif]:bColorBlock != Nil
            aCores := Eval( ::aColumns[fif]:bColorBlock )
            IF lSelected
               ::aColumns[fif]:tColor := aCores[3]
               ::aColumns[fif]:bColor := aCores[4]
            ELSE
               ::aColumns[fif]:tColor := aCores[1]
               ::aColumns[fif]:bColor := aCores[2]
            ENDIF
            ::aColumns[fif]:brush := HBrush():Add( ::aColumns[fif]:bColor   )
         ENDIF
         xSize := ::aColumns[fif]:width
         IF ::lAdjRight .AND. fif == Len( ::aColumns )
            xSize := Max( ::x2 - x, xSize )
         ENDIF
         IF i == ::colpos
            ::xpos := x
         ENDIF

         IF vybfld == 0 .OR. vybfld == i
            IF ::aColumns[fif]:bColor != Nil .AND. ::aColumns[fif]:brush == Nil
               ::aColumns[fif]:brush := HBrush():Add( ::aColumns[fif]:bColor )
            ENDIF
            hBReal := iif( ::aColumns[fif]:brush != Nil, ;
               ::aColumns[fif]:brush:handle,   ;
               oLineBrush:handle )
            hwg_Fillrect( hDC, x, ::y1 + ( ::height + 1 ) * ( nstroka - 1 ) + 1, x + xSize - iif( ::lSep3d,2,1 ) - 1, ::y1 + ( ::height + 1 ) * nstroka, hBReal )
            IF !lClear
               IF ::aColumns[fif]:aBitmaps != Nil .AND. !Empty( ::aColumns[fif]:aBitmaps )
                  FOR j := 1 TO Len( ::aColumns[fif]:aBitmaps )
                     IF Eval( ::aColumns[fif]:aBitmaps[j,1], Eval( ::aColumns[fif]:block,,Self,fif ), lSelected )
                        IF !Empty( ob := ::aColumns[fif]:aBitmaps[j,2] )
                           y1 := 0
                           bh := ::height
                           bw := Int( ob:nWidth * ( ob:nHeight / ::height ) )
                           hwg_Drawbitmap( hDC, ob:handle, , x + ::aPadding[1], y1 + ::y1 + ( ::height + 1 ) * ( nstroka - 1 ) + 1 + ::aPadding[2], bw, bh )
                        ENDIF
                        EXIT
                     ENDIF
                  NEXT
               ELSE
                  sviv := AllTrim( FldStr( Self,fif ) )
                  // Ahora lineas Justificadas !!
                  IF ::aColumns[fif]:tColor != Nil
                     oldT1Color := hwg_Settextcolor( hDC, ::aColumns[fif]:tColor )
                  ENDIF
                  IF ::aColumns[fif]:bColor != Nil
                     oldBk1Color := hwg_Setbkcolor( hDC, ::aColumns[fif]:bColor )
                  ENDIF
                  IF ::aColumns[fif]:oFont != Nil
                     hwg_Selectobject( hDC, ::aColumns[fif]:oFont:handle )
                     lColumnFont := .T.
                  ELSEIF lColumnFont
                     IF ::oFont != Nil
                        hwg_Selectobject( hDC, ::ofont:handle )
                     ENDIF
                     lColumnFont := .F.
                  ENDIF
                  hwg_Drawtext( hDC, sviv, x + ::aPadding[1], ::y1 + ( ::height + 1 ) * ( nstroka - 1 ) + 1 + ::aPadding[2], x + xSize - 2 - ::aPadding[3], ::y1 + ( ::height + 1 ) * nstroka - 1 - ::aPadding[4], ::aColumns[fif]:nJusLin )
                  IF ::aColumns[fif]:tColor != Nil
                     hwg_Settextcolor( hDC, oldT1Color )
                  ENDIF
                  IF ::aColumns[fif]:bColor != Nil
                     hwg_Setbkcolor( hDC, oldBk1Color )
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         x += xSize
         fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
         i ++
         IF ! ::lAdjRight .AND. fif > Len( ::aColumns )
            EXIT
         ENDIF
      ENDDO
      hwg_Settextcolor( hDC, oldTColor )
      hwg_Setbkcolor( hDC, oldBkColor )
      IF lColumnFont
         hwg_Selectobject( hDC, ::ofont:handle )
      ENDIF
   ENDIF

   RETURN Nil

METHOD SetColumn( nCol ) CLASS HBrowse

   LOCAL nColPos, lPaint := .F.

   IF ::lEditable
      IF nCol != nil .AND. nCol >= 1 .AND. nCol <= Len( ::aColumns )
         IF nCol <= ::freeze
            ::colpos := nCol
         ELSEIF nCol >= ::nLeftCol .AND. nCol <= ::nLeftCol + ::Columns - ::freeze - 1
            ::colpos := nCol - ::nLeftCol + ::freeze + 1
         ELSE
            ::nLeftCol := nCol
            ::colpos := ::freeze + 1
            lPaint := .T.
         ENDIF
         IF !lPaint
            ::RefreshLine()
         ELSE
            /* hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE ) */
         ENDIF
      ENDIF

      IF ::colpos <= ::freeze
         nColPos := ::colpos
      ELSE
         nColPos := ::nLeftCol + ::colpos - ::freeze - 1
      ENDIF
      RETURN nColPos

   ENDIF

   RETURN 1

METHOD DoHScroll( wParam ) CLASS HBrowse

   LOCAL nScrollH, nLeftCol, colpos

   IF wParam == Nil
      nScrollH := hwg_getAdjValue( ::hScrollH )
      IF nScrollH - ::nScrollH < 0
         LineLeft( Self )
      ELSEIF nScrollH - ::nScrollH > 0
         LineRight( Self )
      ENDIF
   ELSE
      IF wParam == SB_LEFT
         nLeftCol := colPos := 0
         DO WHILE nLeftCol != ::nLeftCol .OR. colPos != ::colPos
            nLeftCol := ::nLeftCol
            colPos := ::colPos
            LineLeft( Self, .F. )
         ENDDO
      ELSE
         nLeftCol := colPos := 0
         DO WHILE nLeftCol != ::nLeftCol .OR. colPos != ::colPos
            nLeftCol := ::nLeftCol
            colPos := ::colPos
            LineRight( Self, .F. )
         ENDDO
      ENDIF
      hwg_Invalidaterect( ::area, 0 )
   ENDIF

   RETURN Nil

STATIC FUNCTION LINERIGHT( oBrw, lRefresh )

   LOCAL maxPos, nPos, oldLeft := oBrw:nLeftCol, oldPos := oBrw:colpos, fif
   LOCAL i, nColumns := Len( oBrw:aColumns )

   IF oBrw:lEditable .AND. oBrw:colpos < oBrw:nColumns
      oBrw:colpos ++
   ELSEIF oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < nColumns ;
         .AND. oBrw:nLeftCol < nColumns
      i := oBrw:nLeftCol + oBrw:nColumns
      DO WHILE oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < nColumns .AND. oBrw:nLeftCol + oBrw:nColumns = i
         oBrw:nLeftCol ++
      ENDDO
      oBrw:colpos := i - oBrw:nLeftCol + 1
   ENDIF

   IF oBrw:nLeftCol != oldLeft .OR. oBrw:colpos != oldpos
      IF oBrw:hScrollH != Nil
         maxPos := hwg_getAdjValue( oBrw:hScrollH, 1 ) - hwg_getAdjValue( oBrw:hScrollH, 4 )
         fif := iif( oBrw:lEditable, oBrw:colpos + oBrw:nLeftCol - 1, oBrw:nLeftCol )
         nPos := iif( fif == 1, 0, iif( fif = nColumns, maxpos, ;
            Int( ( maxPos + 1 ) * fif/nColumns ) ) )
         hwg_SetAdjOptions( oBrw:hScrollH, nPos )
         oBrw:nScrollH := nPos
      ENDIF
      IF lRefresh == Nil .OR. lRefresh
         IF oBrw:nLeftCol == oldLeft
            oBrw:internal[1] := 1
            hwg_Invalidaterect( oBrw:area, 0, oBrw:x1, oBrw:y1 + ( oBrw:height + 1 ) * oBrw:internal[2] - oBrw:height, oBrw:x2, oBrw:y1 + ( oBrw:height + 1 ) * ( oBrw:rowPos + 1 ) )
         ELSE
            hwg_Invalidaterect( oBrw:area, 0 )
         ENDIF
      ENDIF
   ENDIF
   hwg_Setfocus( oBrw:area )

   RETURN Nil

STATIC FUNCTION LINELEFT( oBrw, lRefresh )

   LOCAL maxPos, nPos, oldLeft := oBrw:nLeftCol, oldPos := oBrw:colpos, fif
   LOCAL nColumns := Len( oBrw:aColumns )

   IF oBrw:lEditable
      oBrw:colpos --
   ENDIF
   IF oBrw:nLeftCol > oBrw:freeze + 1 .AND. ( !oBrw:lEditable .OR. oBrw:colpos < oBrw:freeze + 1 )
      oBrw:nLeftCol --
      IF ! oBrw:lEditable .OR. oBrw:colpos < oBrw:freeze + 1
         oBrw:colpos := oBrw:freeze + 1
      ENDIF
   ENDIF
   IF oBrw:colpos < 1
      oBrw:colpos := 1
   ENDIF
   IF oBrw:nLeftCol != oldLeft .OR. oBrw:colpos != oldpos
      IF oBrw:hScrollH != Nil
         maxPos := hwg_getAdjValue( oBrw:hScrollH, 1 ) - hwg_getAdjValue( oBrw:hScrollH, 4 )
         fif := iif( oBrw:lEditable, oBrw:colpos + oBrw:nLeftCol - 1, oBrw:nLeftCol )
         nPos := iif( fif == 1, 0, iif( fif = nColumns, maxpos, ;
            Int( ( maxPos + 1 ) * fif/nColumns ) ) )
         hwg_SetAdjOptions( oBrw:hScrollH, nPos )
         oBrw:nScrollH := nPos
      ENDIF
      IF lRefresh == Nil .OR. lRefresh
         IF oBrw:nLeftCol == oldLeft
            oBrw:internal[1] := 1
            hwg_Invalidaterect( oBrw:area, 0, oBrw:x1, oBrw:y1 + ( oBrw:height + 1 ) * oBrw:internal[2] - oBrw:height, oBrw:x2, oBrw:y1 + ( oBrw:height + 1 ) * ( oBrw:rowPos + 1 ) )
         ELSE
            hwg_Invalidaterect( oBrw:area, 0 )
         ENDIF
      ENDIF
   ENDIF
   hwg_Setfocus( oBrw:area )

   RETURN Nil

METHOD DoVScroll( wParam ) CLASS HBrowse

   LOCAL nScrollV := hwg_getAdjValue( ::hScrollV )

   IF nScrollV - ::nScrollV == 1
      ::LINEDOWN( .T. )
   ELSEIF nScrollV - ::nScrollV == - 1
      ::LINEUP( .T. )
   ELSEIF nScrollV - ::nScrollV == 10
      ::PAGEDOWN( .T. )
   ELSEIF nScrollV - ::nScrollV == - 10
      ::PAGEUP( .T. )
   ELSE
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, SB_THUMBTRACK, .F. , nScrollV )
      ENDIF
   ENDIF
   ::nScrollV := nScrollV
   // hwg_WriteLog( "DoVScroll " + Ltrim(Str(::nScrollV)) + " " + Ltrim(Str(::nCurrent)) + "( " + Ltrim(Str(::nRecords)) + " )" )

   RETURN 0

METHOD LINEDOWN( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos

   lMouse := iif( lMouse == Nil, .F. , lMouse )
   Eval( ::bSkip, Self, 1 )
   IF Eval( ::bEof, Self )
      Eval( ::bSkip, Self, - 1 )
      IF ::lAppable .AND. !lMouse
         ::lAppMode := .T.
      ELSE
         hwg_Setfocus( ::area )
         RETURN Nil
      ENDIF
   ENDIF
   ::rowPos ++
   IF ::rowPos > ::rowCount
      ::rowPos := ::rowCount
      hwg_Invalidaterect( ::area, 0 )
   ELSE
      ::internal[1] := 1
      hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::internal[2] - ::height, ::x2, ::y1 + ( ::height + 1 ) * ( ::rowPos + 1 ) )
   ENDIF
   IF ::lAppMode
      IF ::rowPos > 1
         ::rowPos --
      ENDIF
      ::colPos := ::nLeftCol := 1
   ENDIF
   IF !lMouse .AND. ::hScrollV != Nil
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, 1, .F. )
      ELSEIF !Empty( ::hScrollV )
         maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
         nPos := hwg_getAdjValue( ::hScrollV )
         nPos += Int( maxPos/ (::nRecords - 1 ) )
         hwg_SetAdjOptions( ::hScrollV, nPos )
         ::nScrollV := nPos
      ENDIF
   ENDIF

   hwg_Setfocus( ::area )

   RETURN Nil

METHOD LINEUP( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos

   lMouse := iif( lMouse == Nil, .F. , lMouse )
   Eval( ::bSkip, Self, - 1 )
   IF Eval( ::bBof, Self )
      Eval( ::bGoTop, Self )
   ELSE
      ::rowPos --
      IF ::rowPos = 0
         ::rowPos := 1
         hwg_Invalidaterect( ::area, 0 )
      ELSE
         ::internal[1] := 1
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::internal[2] - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::internal[2] )
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
      ENDIF

      IF !lMouse .AND. ::hScrollV != Nil
         IF ::bScrollPos != Nil
            Eval( ::bScrollPos, Self, - 1, .F. )
         ELSEIF !Empty( ::hScrollV )
            maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
            nPos := hwg_getAdjValue( ::hScrollV )
            nPos -= Int( maxPos/ (::nRecords - 1 ) )
            hwg_SetAdjOptions( ::hScrollV, nPos )
            ::nScrollV := nPos
         ENDIF
      ENDIF

   ENDIF
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD PAGEUP( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos, step, lBof := .F.

   lMouse := iif( lMouse == Nil, .F. , lMouse )
   IF ::rowPos > 1
      step := ( ::rowPos - 1 )
      Eval( ::bSKip, Self, - step )
      ::rowPos := 1
   ELSE
      step := ::rowCurrCount    // Min( ::nRecords,::rowCount )
      Eval( ::bSkip, Self, - step )
      IF Eval( ::bBof, Self )
         Eval( ::bGoTop, Self )
         lBof := .T.
      ENDIF
   ENDIF

   IF !lMouse .AND. ::hScrollV != Nil
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, - step, lBof )
      ELSEIF !Empty( ::hScrollV )
         maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
         nPos := hwg_getAdjValue( ::hScrollV )
         nPos -= Int( maxPos/ (::nRecords - 1 ) )
         nPos := Max( nPos - Int( maxPos * step/(::nRecords - 1 ) ), 0 )
         hwg_SetAdjOptions( ::hScrollV, nPos )
         ::nScrollV := nPos
      ENDIF
   ENDIF

   hwg_Invalidaterect( ::area, 0 )
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD PAGEDOWN( lMouse ) CLASS HBrowse

   LOCAL maxPos, nPos, nRows := ::rowCurrCount
   LOCAL step := iif( nRows > ::rowPos, nRows - ::rowPos + 1, nRows ), lEof

   lMouse := iif( lMouse == Nil, .F. , lMouse )
   Eval( ::bSkip, Self, step )
   ::rowPos := Min( ::nRecords, nRows )
   lEof := Eval( ::bEof, Self )
   IF lEof .AND. ::bScrollPos == Nil
      Eval( ::bSkip, Self, - 1 )
   ENDIF

   IF !lMouse .AND. ::hScrollV != Nil
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, step, lEof )
      ELSE
         maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
         nPos := hwg_getAdjValue( ::hScrollV )
         IF lEof
            nPos := maxPos
         ELSE
            nPos := Min( nPos + Int( maxPos * step/(::nRecords - 1 ) ), maxPos )
         ENDIF
         hwg_SetAdjOptions( ::hScrollV, nPos )
         ::nScrollV := nPos
      ENDIF
   ENDIF

   hwg_Invalidaterect( ::area, 0 )
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD BOTTOM( lPaint ) CLASS HBrowse

   LOCAL nPos

   ::rowPos := LastRec()
   Eval( ::bGoBot, Self )
   ::rowPos := Min( ::nRecords, ::rowCount )

   IF ::hScrollV != Nil
      nPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
      hwg_SetAdjOptions( ::hScrollV, nPos )
      ::nScrollV := nPos
   ENDIF

   hwg_Invalidaterect( ::area, 0 )

   IF lPaint == Nil .OR. lPaint
      hwg_Setfocus( ::area )
   ENDIF

   RETURN Nil

METHOD TOP() CLASS HBrowse

   LOCAL nPos

   ::rowPos := 1
   Eval( ::bGoTop, Self )

   IF ::hScrollV != Nil
      nPos := 0
      hwg_SetAdjOptions( ::hScrollV, nPos )
      ::nScrollV := nPos
   ENDIF

   hwg_Invalidaterect( ::area, 0 )
   hwg_Setfocus( ::area )

   RETURN Nil

METHOD ButtonDown( lParam ) CLASS HBrowse

   LOCAL hBrw := ::handle
   LOCAL nLine := Int( hwg_Hiword( lParam )/ (::height + 1 ) + iif(::lDispHead,1 - ::nHeadRows,1 ) )
   LOCAL step := nLine - ::rowPos, res := .F. , nrec
   LOCAL maxPos, nPos
   LOCAL xm := hwg_Loword( lParam ), x1, fif

   ::lBtnDbl := .F.
   x1  := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )
   DO WHILE fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + ::aColumns[fif]:width < xm
      x1 += ::aColumns[fif]:width
      fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
   ENDDO

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      IF step != 0
         nrec := Eval( ::bRecno, Self )
         Eval( ::bSkip, Self, step )
         IF !Eval( ::bEof, Self )
            ::rowPos := nLine
            IF ::hScrollV != Nil
               IF ::bScrollPos != Nil
                  Eval( ::bScrollPos, Self, step, .F. )
               ELSE 
                  nPos := hwg_getAdjValue( ::hScrollV )
                  maxPos := hwg_getAdjValue( ::hScrollV, 1 ) - hwg_getAdjValue( ::hScrollV, 4 )
                  nPos := Min( nPos + Int( maxPos * step/(::nRecords - 1 ) ), maxPos )
                  hwg_SetAdjOptions( ::hScrollV, nPos )
               ENDIF
            ENDIF
            res := .T.
         ELSE
            Eval( ::bGoTo, Self, nrec )
         ENDIF
      ENDIF
      IF ::lEditable
         IF ::colpos != fif - ::nLeftCol + 1 + :: freeze
            ::colpos := fif - ::nLeftCol + 1 + :: freeze
            IF ::hScrollH != Nil
               maxPos := hwg_getAdjValue( ::hScrollH, 1 ) - hwg_getAdjValue( ::hScrollH, 4 )
               nPos := iif( fif == 1, 0, iif( fif = Len(::aColumns ), maxpos, ;
                  Int( ( maxPos + 1 ) * fif/Len( ::aColumns ) ) ) )
               hwg_SetAdjOptions( ::hScrollH, nPos )
            ENDIF
            res := .T.
         ENDIF
      ENDIF
      IF res
         ::internal[1] := 1
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::internal[2] - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::internal[2] )
         hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
      ENDIF

   ELSEIF nLine == 0 .AND. ::nCursor == 1
      ::nCursor := 2
      Hwg_SetCursor( vCursor, ::area )
      xDrag := hwg_Loword( lParam )

   ELSEIF ::lDispHead .AND. ;
         nLine >= - ::nHeadRows .AND. ;
         fif <= Len( ::aColumns ) .AND. ;
         ::aColumns[fif]:bHeadClick != nil

      Eval( ::aColumns[fif]:bHeadClick, Self, fif )

   ENDIF

   RETURN Nil

METHOD ButtonRDown( lParam ) CLASS HBrowse

   LOCAL nLine := Int( hwg_Hiword( lParam )/ (::height + 1 ) + iif(::lDispHead,1 - ::nHeadRows,1 ) )
   LOCAL xm := hwg_Loword( lParam ), x1, fif

   IF ::bRClick == NIL
      Return Nil
   ENDIF

   x1  := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + ::aColumns[ fif ]:width < xm
      x1 += ::aColumns[ fif ]:width
      fif := iif( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO

   Eval( ::bRClick, Self, nLine, fif )

   RETURN Nil

METHOD ButtonUp( lParam ) CLASS HBrowse

   LOCAL hBrw := ::handle
   LOCAL xPos := hwg_Loword( lParam ), x := ::x1, x1, i := ::nLeftCol

   IF ::lBtnDbl
      ::lBtnDbl := .F.
      RETURN Nil
   ENDIF
   IF ::nCursor == 2
      DO WHILE x < xDrag
         x += ::aColumns[i]:width
         IF Abs( x - xDrag ) < 10
            x1 := x - ::aColumns[i]:width
            EXIT
         ENDIF
         i ++
      ENDDO
      IF xPos > x1
         ::aColumns[i]:width := xPos - x1
         Hwg_SetCursor( arrowCursor, ::area )
         ::nCursor := 0
         hwg_Invalidaterect( hBrw, 0 )
      ENDIF
   ELSEIF ::aSelected != Nil
      IF ::nCtrlPress == GDK_Control_L
         IF ( i := Ascan( ::aSelected, Eval( ::bRecno,Self ) ) ) > 0
            ADel( ::aSelected, i )
            ASize( ::aSelected, Len( ::aSelected ) - 1 )
         ELSE
            AAdd( ::aSelected, Eval( ::bRecno,Self ) )
         ENDIF
      ELSE
         IF Len( ::aSelected ) > 0
            ::aSelected := {}
            ::Refresh()
         ENDIF
      ENDIF
   ENDIF

   hwg_Setfocus( ::area )

   RETURN Nil

METHOD ButtonDbl( lParam ) CLASS HBrowse

   LOCAL hBrw := ::handle
   LOCAL nLine := Int( hwg_Hiword( lParam )/ (::height + 1 ) + iif(::lDispHead,1 - ::nHeadRows,1 ) )

   IF nLine <= ::rowCurrCount
      ::ButtonDown( lParam )
      ::Edit()
   ENDIF
   ::lBtnDbl := .T.

   RETURN Nil

METHOD MouseMove( wParam, lParam ) CLASS HBrowse

   LOCAL xPos := hwg_Loword( lParam ), yPos := hwg_Hiword( lParam )
   LOCAL x := ::x1, i := ::nLeftCol, res := .F.

   IF !::active .OR. Empty( ::aColumns ) .OR. ::x1 == Nil
      RETURN Nil
   ENDIF
   IF ::lDispSep .AND. yPos <= ::height + 1
      IF wParam == 1 .AND. ::nCursor == 2
         Hwg_SetCursor( vCursor, ::area )
         res := .T.
      ELSE
         DO WHILE x < ::x2 - 2 .AND. i <= Len( ::aColumns )
            x += ::aColumns[i++]:width
            IF Abs( x - xPos ) < 8
               IF ::nCursor != 2
                  ::nCursor := 1
               ENDIF
               Hwg_SetCursor( iif( ::nCursor == 1,crossCursor,vCursor ), ::area )
               res := .T.
               EXIT
            ENDIF
         ENDDO
      ENDIF
      IF !res .AND. ::nCursor != 0
         Hwg_SetCursor( arrowCursor, ::area )
         ::nCursor := 0
      ENDIF
   ENDIF

   RETURN Nil

METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos ) CLASS HBrowse

   IF Hwg_BitAnd( nKeys, MK_MBUTTON ) != 0
      IF nDelta > 0
         ::PageUp()
      ELSE
         ::PageDown()
      ENDIF
   ELSE
      IF nDelta > 0
         ::LineUp()
      ELSE
         ::LineDown()
      ENDIF
   ENDIF

   RETURN nil

METHOD Edit( wParam, lParam ) CLASS HBrowse

   LOCAL fipos, lRes, x1, y1, fif, nWidth, lReadExit, rowPos
   LOCAL oColumn, type

   fipos := ::colpos + ::nLeftCol - 1 - ::freeze
   IF ::bEnter == Nil .OR. ;
         ( ValType( lRes := Eval( ::bEnter, Self, fipos ) ) == 'L' .AND. !lRes )
      oColumn := ::aColumns[fipos]
      IF ::type == BRW_DATABASE
         ::varbuf := ( ::alias ) -> ( Eval( oColumn:block,,Self,fipos ) )
      ELSE
         ::varbuf := Eval( oColumn:block, , Self, fipos )
      ENDIF
      type := iif( oColumn:type == "U" .AND. ::varbuf != Nil, ValType( ::varbuf ), oColumn:type )
      IF ::lEditable .AND. type != "O"
         IF oColumn:lEditable .AND. ( oColumn:bWhen = Nil .OR. Eval( oColumn:bWhen ) )
            IF ::lAppMode
               IF type == "D"
                  ::varbuf := CToD( "" )
               ELSEIF type == "N"
                  ::varbuf := 0
               ELSEIF type == "L"
                  ::varbuf := .F.
               ELSE
                  ::varbuf := ""
               ENDIF
            ENDIF
         ELSE
            RETURN Nil
         ENDIF
         x1  := ::x1
         fif := iif( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE fif < fipos
            x1 += ::aColumns[fif]:width
            fif := iif( fif = ::freeze, ::nLeftCol, fif + 1 )
         ENDDO
         nWidth := Min( ::aColumns[fif]:width, ::x2 - x1 - 1 )
         rowPos := ::rowPos - 1
         IF ::lAppMode .AND. ::nRecords != 0
            rowPos ++
         ENDIF
         y1 := ::y1 + ( ::height + 1 ) * rowPos

         ::nGetRec := Eval( ::bRecno, Self )
         ::lEditing := .T.
         @ x1, y1 GET ::oGet VAR ::varbuf      ;
            OF ::oParent                   ;
            SIZE nWidth, ::height + 1        ;
            STYLE ES_AUTOHSCROLL           ;
            FONT ::oFont                   ;
            PICTURE oColumn:picture        ;
            VALID { ||VldBrwEdit( Self, fipos ) }
         ::oGet:Show()
         hwg_Setfocus( ::oGet:handle )
         hwg_edit_SetPos( ::oGet:handle, 0 )
         ::oGet:bAnyEvent := { |o, msg, c|GetEventHandler( Self, msg, c ) }

      ENDIF
   ENDIF

   RETURN Nil

STATIC FUNCTION GetEventHandler( oBrw, msg, cod )

   IF msg == WM_KEYDOWN .AND. cod == GDK_Escape
      oBrw:oGet:nLastKey := GDK_Escape
      hwg_Setfocus( oBrw:area )
      oBrw:lEditing := .F.
      RETURN 1
   ENDIF

   RETURN 0

STATIC FUNCTION VldBrwEdit( oBrw, fipos )

   LOCAL oColumn := oBrw:aColumns[fipos], nRec, fif, nChoic

   IF oBrw:oGet:nLastKey != GDK_Escape
      IF oColumn:aList != Nil
         IF ValType( oBrw:varbuf ) == 'N'
            oBrw:varbuf := nChoic
         ELSE
            oBrw:varbuf := oColumn:aList[nChoic]
         ENDIF
      ENDIF
      IF oBrw:lAppMode
         oBrw:lAppMode := .F.
         IF oBrw:type == BRW_DATABASE
            ( oBrw:alias ) -> ( dbAppend() )
            ( oBrw:alias ) -> ( Eval( oColumn:block,oBrw:varbuf,oBrw,fipos ) )
            UNLOCK
         ELSE
            IF ValType( oBrw:aArray[1] ) == "A"
               AAdd( oBrw:aArray, Array( Len(oBrw:aArray[1] ) ) )
               FOR fif := 2 TO Len( ( oBrw:aArray[1] ) )
                  oBrw:aArray[Len(oBrw:aArray),fif] := ;
                     iif( oBrw:aColumns[fif]:type == "D", CToD( Space(8 ) ), ;
                     iif( oBrw:aColumns[fif]:type == "N", 0, "" ) )
               NEXT
            ELSE
               AAdd( oBrw:aArray, Nil )
            ENDIF
            oBrw:nCurrent := Len( oBrw:aArray )
            Eval( oColumn:block, oBrw:varbuf, oBrw, fipos )
         ENDIF
         IF oBrw:nRecords > 0
            oBrw:rowPos ++
         ENDIF
         oBrw:lAppended := .T.
         oBrw:Refresh()
      ELSE
         IF ( nRec := Eval( oBrw:bRecno,oBrw ) ) != oBrw:nGetRec
            Eval( oBrw:bGoTo, oBrw, oBrw:nGetRec )
         ENDIF
         IF oBrw:type == BRW_DATABASE
            IF ( oBrw:alias ) -> ( RLock() )
               ( oBrw:alias ) -> ( Eval( oColumn:block,oBrw:varbuf,oBrw,fipos ) )
            ELSE
               hwg_Msgstop( "Can't lock the record!" )
            ENDIF
         ELSE
            Eval( oColumn:block, oBrw:varbuf, oBrw, fipos )
         ENDIF
         IF nRec != oBrw:nGetRec
            Eval( oBrw:bGoTo, oBrw, nRec )
         ENDIF
         oBrw:lUpdated := .T.
      ENDIF
   ENDIF

   oBrw:Refresh()
   // Execute block after changes are made
   IF oBrw:oGet:nLastKey != GDK_Escape .AND. oBrw:bUpdate != nil
      Eval( oBrw:bUpdate, oBrw, fipos )
   ENDIF
   oBrw:oParent:DelControl( oBrw:oGet )
   oBrw:oGet := Nil
   hwg_Setfocus( oBrw:area )

   RETURN .T.

METHOD RefreshLine() CLASS HBrowse

   ::internal[1] := 0
   hwg_Invalidaterect( ::area, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )

   RETURN Nil

METHOD Refresh( lFull ) CLASS HBrowse

   IF lFull == Nil .OR. lFull
      ::internal[1] := 15
      hwg_Redrawwindow( ::area, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ELSE
      hwg_Invalidaterect( ::area, 0 )
      ::internal[1] := hwg_Setbit( ::internal[1], 1, 0 )
   ENDIF

   RETURN Nil

STATIC FUNCTION FldStr( oBrw, numf )

   LOCAL fldtype
   LOCAL rez
   LOCAL vartmp
   LOCAL nItem := numf
   LOCAL TYPE
   LOCAL PICT

   IF numf <= Len( oBrw:aColumns )

      pict := oBrw:aColumns[numf]:picture

      IF pict != nil
         IF oBrw:type == BRW_DATABASE
            rez := ( oBrw:alias ) -> ( Transform( Eval( oBrw:aColumns[numf]:block,,oBrw,numf ), pict ) )
         ELSE
            rez := Transform( Eval( oBrw:aColumns[numf]:block,,oBrw,numf ), pict )
         ENDIF

      ELSE
         IF oBrw:type == BRW_DATABASE
            vartmp := ( oBrw:alias ) -> ( Eval( oBrw:aColumns[numf]:block,,oBrw,numf ) )
         ELSE
            vartmp := Eval( oBrw:aColumns[numf]:block, , oBrw, numf )
         ENDIF

         type := ( oBrw:aColumns[numf] ):type
         IF type == "U" .AND. vartmp != Nil
            type := ValType( vartmp )
         ENDIF
         IF type == "C"
            rez := PadR( vartmp, oBrw:aColumns[numf]:length )

         ELSEIF type == "N"
            rez := PadL( Str( vartmp, oBrw:aColumns[numf]:length, ;
               oBrw:aColumns[numf]:dec ), oBrw:aColumns[numf]:length )
         ELSEIF type == "D"
            rez := PadR( Dtoc( vartmp ), oBrw:aColumns[numf]:length )

         ELSEIF type == "L"
            rez := PadR( iif( vartmp, "T", "F" ), oBrw:aColumns[numf]:length )

         ELSEIF type == "M"
            rez := "<Memo>"

         ELSEIF type == "O"
            rez := "<" + vartmp:Classname() + ">"

         ELSEIF type == "A"
            rez := "<Array>"

         ELSE
            rez := Space( oBrw:aColumns[numf]:length )
         ENDIF
      ENDIF
   ENDIF

   RETURN rez

STATIC FUNCTION FLDCOUNT( oBrw, xstrt, xend, fld1 )

   LOCAL klf := 0, i := iif( oBrw:freeze > 0, 1, fld1 )

   WHILE .T.
      xstrt += oBrw:aColumns[i]:width
      IF xstrt > xend
         EXIT
      ENDIF
      klf ++
      i   := iif( i = oBrw:freeze, fld1, i + 1 )
      IF i > Len( oBrw:aColumns )
         EXIT
      ENDIF
   ENDDO

   RETURN iif( klf = 0, 1, klf )

FUNCTION hwg_CREATEARLIST( oBrw, arr )

   LOCAL i

   oBrw:type  := BRW_ARRAY
   oBrw:aArray := arr
   IF Len( oBrw:aColumns ) == 0
      // oBrw:aColumns := {}
      IF ValType( arr[1] ) == "A"
         FOR i := 1 TO Len( arr[1] )
            oBrw:AddColumn( HColumn():New( ,hwg_ColumnArBlock() ) )
         NEXT
      ELSE
         oBrw:AddColumn( HColumn():New( ,{ |value,o| o:aArray[ o:nCurrent ] } ) )
      ENDIF
   ENDIF
   Eval( oBrw:bGoTop, oBrw )
   oBrw:Refresh()

   RETURN Nil

PROCEDURE ARSKIP( oBrw, kolskip )

   LOCAL tekzp1

   IF oBrw:nRecords != 0
      tekzp1   := oBrw:nCurrent
      oBrw:nCurrent += kolskip + iif( tekzp1 = 0, 1, 0 )
      IF oBrw:nCurrent < 1
         oBrw:nCurrent := 0
      ELSEIF oBrw:nCurrent > oBrw:nRecords
         oBrw:nCurrent := oBrw:nRecords + 1
      ENDIF
   ENDIF

   RETURN

FUNCTION hwg_CreateList( oBrw, lEditable )

   LOCAL i
   LOCAL nArea := Select()
   LOCAL kolf := FCount()

   oBrw:alias := Alias()
   oBrw:aColumns := {}

   FOR i := 1 TO kolf
      oBrw:AddColumn( HColumn():New( FieldName(i ), ;
         FieldWBlock( FieldName( i ), nArea ), ;
         dbFieldInfo( DBS_TYPE, i ),         ;
         dbFieldInfo( DBS_LEN, i ),          ;
         dbFieldInfo( DBS_DEC, i ),          ;
         lEditable ) )
   NEXT

   oBrw:Refresh()

   RETURN Nil

FUNCTION hwg_VScrollPos( oBrw, nType, lEof, nPos )

   LOCAL maxPos := hwg_getAdjValue( oBrw:hScrollV, 1 ) - hwg_getAdjValue( oBrw:hScrollV, 4 )
   LOCAL oldRecno, newRecno

   IF nPos == Nil
      IF nType > 0 .AND. lEof
         Eval( oBrw:bSkip, oBrw, - 1 )
      ENDIF
      nPos := Round( ( maxPos/(oBrw:nRecords - 1 ) ) * ( Eval( oBrw:bRecnoLog,oBrw ) - 1 ),0 )
      hwg_SetAdjOptions( oBrw:hScrollV, nPos )
      oBrw:nScrollV := nPos
   ELSE
      oldRecno := Eval( oBrw:bRecnoLog, oBrw )
      newRecno := Round( ( oBrw:nRecords - 1 ) * nPos/maxPos + 1, 0 )
      IF newRecno <= 0
         newRecno := 1
      ELSEIF newRecno > oBrw:nRecords
         newRecno := oBrw:nRecords
      ENDIF
      IF newRecno != oldRecno
         Eval( oBrw:bSkip, oBrw, newRecno - oldRecno )
         IF oBrw:rowCount - oBrw:rowPos > oBrw:nRecords - newRecno
            oBrw:rowPos := oBrw:rowCount - ( oBrw:nRecords - newRecno )
         ENDIF
         IF oBrw:rowPos > newRecno
            oBrw:rowPos := newRecno
         ENDIF
         oBrw:Refresh()
      ENDIF
   ENDIF

   RETURN Nil

FUNCTION hwg_ColumnArBlock()

   RETURN { |value, o, n| iif( value == Nil, o:aArray[o:nCurrent,n], o:aArray[o:nCurrent,n] := value ) }

STATIC FUNCTION HdrToken( cStr, nMaxLen, nCount )

   LOCAL nL, nPos := 0

   nMaxLen := nCount := 0
   cStr += ';'
   WHILE ( nL := Len( hb_tokenPtr(@cStr, @nPos, ";" ) ) ) != 0
      nMaxLen := Max( nMaxLen, nL )
      nCount ++
   ENDDO

   RETURN nil
