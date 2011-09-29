/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HBrowse class - browse databases and arrays
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

// Modificaciones y Agregados. 27.07.2002, WHT.de la Argentina ///////////////
// 1) En el metodo HColumn se agregaron las DATA: "nJusHead" y "nJustLin",  //
//    para poder justificar los encabezados de columnas y tambien las       //
//    lineas. Por default es DT_LEFT                                        //
//    0-DT_LEFT, 1-DT_RIGHT y 2-DT_CENTER. 27.07.2002. WHT.                 //
// 2) Ahora la variable "cargo" del metodo Hbrowse si es codeblock          //
//    ejectuta el CB. 27.07.2002. WHT                                       //
// 3) Se agreg¢ el Metodo "ShowSizes". Para poder ver la "width" de cada    //
//    columna. 27.07.2002. WHT.                                             //
//////////////////////////////////////////////////////////////////////////////

#include "windows.ch"
#include "guilib.ch"
#include "common.ch"

#include "inkey.ch"
#include "dbstruct.ch"
#include "hbclass.ch"

#ifdef __XHARBOUR__
   #xtranslate hb_RAScan([<x,...>])        => RAScan(<x>)
 *  #xtranslate hb_tokenGet([<x>,<n>,<c>] ) =>  __StrToken(<x>,<n>,<c>)
#endif

REQUEST DBGoTop
REQUEST DBGoTo
REQUEST DBGoBottom    
REQUEST DBSkip
REQUEST RecCount
REQUEST RecNo
REQUEST Eof
REQUEST Bof

#define HDM_GETITEMCOUNT    4608

//#define DLGC_WANTALLKEYS    0x0004      /* Control wants all keys */

STATIC ColSizeCursor := 0
STATIC arrowCursor := 0
STATIC downCursor := 0
STATIC oCursor     := 0
STATIC oPen64
STATIC xDrag
STATIC xDragMove := 0
STATIC xToolTip 

//----------------------------------------------------//
CLASS HColumn INHERIT HObject

   DATA oParent
   DATA block, heading, footing, width, Type
   DATA length INIT 0
   DATA dec, cargo
   DATA nJusHead, nJusLin, nJusFoot        // Para poder Justificar los Encabezados
   // de las columnas y lineas.
   DATA tcolor, bcolor, brush
   DATA oFont
   DATA lEditable INIT .F.       // Is the column editable
   DATA aList                    // Array of possible values for a column -
   // combobox will be used while editing the cell
   DATA aBitmaps
   DATA bValid, bWhen, bclick    // When and Valid codeblocks for cell editing
   DATA bEdit                    // Codeblock, which performs cell editing, if defined
   DATA cGrid                    // Specify border for Header (SNWE), can be
   // multiline if separated by ;
   DATA lSpandHead INIT .F.
   DATA lSpandFoot INIT .F.
   DATA Picture
   DATA bHeadClick
   DATA bHeadRClick
   DATA bColorFoot               //   bColorFoot must return an array containing two colors values
   //   oBrowse:aColumns[1]:bColorFoot := {|| IF (nNumber < 0, ;
   //      {textColor, backColor} , ;
   //      {textColor, backColor} ) }

   DATA bColorBlock              //   bColorBlock must return an array containing four colors values
   //   oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
   //      {textColor, backColor, textColorSel, backColorSel} , ;
   //      {textColor, backColor, textColorSel, backColorSel} ) }
   DATA headColor                // Header text color
   DATA FootFont                // Footing font

   DATA lHeadClick   INIT .F.
   DATA lHide INIT .F. // HIDDEN
   DATA Column
   DATA nSortMark INIT 0
   DATA Resizable INIT .T.
   DATA ToolTip 
   DATA aHints INIT {}
   DATA Hint INIT .F.

   METHOD New( cHeading, block, Type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick, tcolor, bColor, bClick )
   METHOD Visible( lVisible ) SETGET
   METHOD Hide()
   METHOD Show()
   METHOD SortMark( nSortMark ) SETGET

ENDCLASS

//----------------------------------------------------//
METHOD New( cHeading, block, Type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick, tcolor, bcolor, bClick ) CLASS HColumn

   ::heading   := IIf( cHeading == nil, "", cHeading )
   ::block     := block
   ::Type      := Type
   ::length    := length
   ::dec       := dec
   ::lEditable := lEditable  // IIf( lEditable != Nil, lEditable, .F. )
   ::nJusHead  := IIf( nJusHead == nil,  DT_LEFT, nJusHead ) + DT_VCENTER + DT_SINGLELINE // Por default
   ::nJusLin   := nJusLin //IIf( nJusLin  == nil,  DT_LEFT, nJusLin  ) + DT_VCENTER + DT_SINGLELINE // Justif.Izquierda
   ::nJusFoot  := IIf( nJusLin  == nil, DT_LEFT, nJusLin  )
   ::picture   := cPict
   ::bValid    := bValid
   ::bWhen     := bWhen
   ::aList     := aItem
   ::bColorBlock := bColorBlock
   ::bHeadClick  := bHeadClick
   ::footing   := ""
   ::tcolor    := tcolor
   ::bcolor    := bcolor
   ::bClick    := bClick

   RETURN Self

METHOD Visible( lVisible ) CLASS HColumn

   IF lVisible != Nil
     IF  ! lVisible
        ::Hide()
     ELSE
        ::Show()
     ENDIF
     ::lHide := ! lVisible
  ENDIF
  RETURN ! ::lHide

 METHOD Hide( ) CLASS HColumn
    ::lHide := .T.
    ::oParent:Refresh()
    RETURN ::lHide

 METHOD Show( ) CLASS HColumn
    ::lHide := .F.
    ::oParent:Refresh()
    RETURN ::lHide

 METHOD SortMark( nSortMark ) CLASS HColumn

    IF nSortMark != Nil
      AEVAL( ::oParent:aColumns,{ | c | c:nSortMark := 0 } )
      ::oParent:lHeadClick := .T.
      InvalidateRect( ::oParent:handle, 0, ::oParent:x1, ::oParent:y1 - ::oParent:nHeadHeight * ::oParent:nHeadRows, ::oParent:x2, ::oParent:y1 )
      ::oParent:lHeadClick := .F.
      ::nSortMark := nSortMark
    ENDIF
    RETURN ::nSortMark

//----------------------------------------------------//
CLASS HBrowse INHERIT HControl

   DATA winclass   INIT "BROWSE"
   DATA active     INIT .T.
   DATA lChanged   INIT .F.
   DATA lDispHead  INIT .t.                    // Should I display headers ?
   DATA lDispSep   INIT .t.                    // Should I display separators ?
   DATA aColumns                               // HColumn's array
   DATA aColAlias  INIT { }
   DATA aRelation  INIT .F.
   DATA rowCount   INIT 0                      // Number of visible data rows
   DATA rowPos     INIT 1                      // Current row position
   DATA rowCurrCount INIT 0                    // Current number of rows
   DATA colPos     INIT 1                      // Current column position
   DATA nColumns   INIT 0                      // Number of visible data columns
   DATA nLeftCol                               // Leftmost column
   DATA freeze     INIT 0                      // Number of columns to freeze
   DATA nRecords     INIT 0                    // Number of records in browse
   DATA nCurrent     INIT 1                    // Current record
   DATA aArray                                 // An array browsed if this is BROWSE ARRAY
   DATA recCurr       INIT 0
   DATA headColor                      // Header text color
   DATA sepColor       INIT 12632256             // Separators color
   DATA lSep3d        INIT .F.
   DATA varbuf                                 // Used on Edit()
   DATA tcolorSel, bcolorSel, brushSel, htbColor, httColor // Hilite Text Back Color
   DATA bSkip, bGoTo, bGoTop, bGoBot, bEof, bBof
   DATA bRcou, bRecno, bRecnoLog
   DATA bPosChanged, bLineOut
   DATA bScrollPos                             // Called when user move browse through vertical scroll bar
   DATA bHScrollPos                            // Called when user move browse through horizontal scroll bar
   DATA bEnter, bKeyDown, bUpdate, bRclick
   DATA bChangeRowCol
   DATA internal
   DATA Alias                                  // Alias name of browsed database
   DATA x1, y1, x2, y2, width, height, xAdjRight
   DATA minHeight INIT 0
   DATA forceHeight INIT 0                     // force Row height in pixel, set by SetRowHeight
   DATA lEditable INIT .T.
   DATA lAppable  INIT .F.
   DATA lAppMode  INIT .F.
   DATA lAutoEdit INIT .F.
   DATA lUpdated  INIT .F.
   DATA lAppended INIT .F.
   DATA lESC      INIT .F.
   DATA lAdjRight INIT .T.                     // Adjust last column to right
   DATA nHeadRows INIT 1                       // Rows in header
   DATA nHeadHeight INIT 0                     // Pixel height in header for footer (if present) or std font
   DATA nFootHeight INIT 0                     // Pixel height in footer for standard font
   DATA nFootRows INIT 0                       // Rows in footer
   DATA lResizing INIT .F.                     // .T. while a column resizing is undergoing
   DATA lCtrlPress INIT .F.                    // .T. while Ctrl key is pressed
   DATA lShiftPress INIT .F.                    // .T. while Shift key is pressed
   DATA aSelected                              // An array of selected records numbers
   DATA nWheelPress INIT 0                        // wheel or central button mouse pressed flag
   DATA oHeadFont

   DATA lDescend INIT .F.              // Descend Order?
   DATA lFilter INIT .F.               // Filtered? (atribuition is automatic in method "New()").
   DATA bFirst INIT { || DBGoTop() }     // Block to place pointer in first record of condition filter. (Ex.: DbGoTop(), DbSeek(), etc.).
   DATA bLast  INIT { || DBGoBottom() }  // Block to place pointer in last record of condition filter. (Ex.: DbGoBottom(), DbSeek(), etc.).
   DATA bWhile INIT { || .T. }           // Clausule "while". Return logical.
   DATA bFor INIT { || .T. }             // Clausule "for". Return logical.
   DATA nLastRecordFilter INIT 0       // Save the last record of filter.
   DATA nFirstRecordFilter INIT 0      // Save the first record of filter.
   DATA nPaintRow, nPaintCol                   // Row/Col being painted
   DATA aMargin INIT { 0, 0, 0, 0 } PROTECTED  // Margin TOP-RIGHT-BOTTOM-LEFT
   DATA lRepaintBackground INIT .F. HIDDEN    // Set to true performs a canvas fill before painting rows

   DATA lHeadClick  INIT  .F.    // .T. while a HEADER column is CLICKED
   DATA nyHeight    INIT  0
   DATA fipos      HIDDEN
   DATA lDeleteMark INIT .F.   HIDDEN
   DATA lShowMark   INIT .T.   HIDDEN
   DATA nDeleteMark INIT 0     HIDDEN
   DATA nShowMark   INIT 12    HIDDEN
   DATA oBmpMark    INIT  HBitmap():AddStandard( OBM_MNARROW ) HIDDEN
   DATA ShowSortMark  INIT .T.
   DATA nWidthColRight INIT 0  HIDDEN
   DATA nVisibleColLeft INIT 0 HIDDEN
   // one to many relationships
   DATA LinkMaster             // Specifies the parent table linked to the child table displayed in a Grid control.
   DATA ChildOrder             // Specifies the index tag for the record source of the Grid control or Relation object.
   DATA RelationalExpr         // Specifies the expression based on fields in the parent table that relates to an index in the child table joining the two tables
   DATA aRecnoFilter   INIT {}
   DATA nIndexOrd INIT -1 HIDDEN
   DATA nRecCount INIT 0  HIDDEN

   // ADD THEME IN BROWSE
   DATA m_bFirstTime  INIT .T.
   DATA hTheme
   DATA Themed        INIT .T.
   DATA xPosMouseOver INIT  0
   DATA isMouseOver   INIT .F.
   DATA allMouseOver  INIT .F.
   DATA AutoColumnFit INIT  0   // 0-Enable / 2  Disables capability for columns to fit data automatically.
   DATA nAutoFit
   DATA lNoVScroll   INIT .F.
   DATA lDisableVScrollPos INIT .F.
   DATA oTimer  HIDDEN 
   DATA nSetRefresh  INIT 0 HIDDEN 

   METHOD New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
               bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,;
               lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown,bPosChg,lMultiSelect,;
               lDescend, bWhile, bFirst, bLast, bFor, bOther,tcolor, bcolor, brclick, bChgRowCol, ctooltip )
   METHOD InitBrw( nType, lInit )
   METHOD Rebuild()
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( lType, oWndParent, nId, oFont, bInit, bSize, bPaint, bEnter, bGfocus, bLfocus )
   METHOD FindBrowse( nId )
   METHOD AddColumn( oColumn )
   METHOD InsColumn( oColumn, nPos )
   METHOD DelColumn( nPos )
   METHOD Paint( lLostFocus )
   METHOD LineOut( nRow, nCol, hDC, lSelected, lClear )
   METHOD Select()
   METHOD HeaderOut( hDC )
   METHOD SeparatorOut( hDC, nRowsFill )
   METHOD FooterOut( hDC )
   METHOD SetColumn( nCol )
   METHOD DoHScroll( wParam )
   METHOD DoVScroll( wParam )
   METHOD LineDown( lMouse )
   METHOD LineUp()
   METHOD PageUp()
   METHOD PageDown()
   METHOD Bottom( lPaint )
   METHOD Top()
   METHOD Home()  INLINE ::DoHScroll( SB_LEFT )
   METHOD ButtonDown( lParam )
   METHOD ButtonUp( lParam )
   METHOD ButtonDbl( lParam )
   METHOD MouseMove( wParam, lParam )
   METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos )
   METHOD Edit( wParam, lParam )
   METHOD Append() INLINE ( ::Bottom( .F. ), ::LineDown() )
   METHOD RefreshLine()
   METHOD Refresh( lFull, lLineUp )
   METHOD ShowSizes()
   METHOD END()
   METHOD SetMargin( nTop, nRight, nBottom, nLeft )
   METHOD SetRowHeight( nPixels )
   METHOD FldStr( oBrw, numf )
   METHOD Filter( lFilter ) SETGET
   //
   METHOD WhenColumn( value, oGet )
   METHOD ValidColumn( value, oGet, oBtn )
   METHOD onClickColumn( value, oGet, oBtn )
   METHOD EditEvent( oCtrl, msg, wParam, lParam )
   METHOD ButtonRDown( lParam )
   METHOD ShowMark( lShowMark ) SETGET
   METHOD DeleteMark( lDeleteMark ) SETGET
//   METHOD BrwScrollVPos()
   // new
   METHOD ShowColToolTips( lParam )
	 METHOD SetRefresh( nSeconds ) SETGET
   METHOD When()
   METHOD Valid()
   METHOD ChangeRowCol( nRowColChange )
   METHOD EditLogical( wParam, lParam )   HIDDEN
   METHOD AutoFit()

ENDCLASS

//----------------------------------------------------//
METHOD New( lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
            bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
            lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, ;
            lDescend, bWhile, bFirst, bLast, bFor, bOther, tcolor, bcolor, bRclick, bChgRowCol, ctooltip ) CLASS HBrowse

   lNoVScroll := IIf( lNoVScroll = Nil , .F., lNoVScroll )
   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_CHILD + WS_VISIBLE + WS_TABSTOP + ;
                          IIf( lNoBorder = Nil.OR. ! lNoBorder, WS_BORDER, 0 ) +            ;
                          IIf( ! lNoVScroll, WS_VSCROLL, 0 ) )
   nStyle   -= IIF( Hwg_BitAND( nStyle, WS_VSCROLL ) > 0 .AND. lNoVScroll, WS_VSCROLL, 0 )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, IIf( nWidth == Nil, 0, nWidth ), ;
              IIf( nHeight == Nil, 0, nHeight ), oFont, bInit, bSize, bPaint, ctooltip ,tColor, bColor )

   ::lNoVScroll := lNoVScroll
   ::Type    := lType
   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bRclick := bRclick
   ::bGetFocus   := bGfocus
   ::bLostFocus  := bLfocus
   ::bOther :=  bOther

   ::lAppable      := IIf( lAppend == Nil, .F., lAppend )
   ::lAutoedit     := IIf( lAutoedit == Nil, .F., lAutoedit )
   ::bUpdate       := bUpdate
   ::bKeyDown      := bKeyDown
   ::bPosChanged   := bPosChg
   ::bChangeRowCol := bChgRowCol
   IF lMultiSelect != Nil .AND. lMultiSelect
      ::aSelected := { }
   ENDIF
   ::lDescend    := IIf( lDescend == Nil, .F., lDescend )

   IF ISBLOCK( bFirst ) .OR. ISBLOCK( bFor ) .OR. ISBLOCK( bWhile )
      ::lFilter := .T.
      IF ISBLOCK( bFirst )
         ::bFirst  := bFirst
      ENDIF
      IF ISBLOCK( bLast )
         ::bLast   := bLast
      ENDIF
      IF ISBLOCK( bWhile )
         ::bWhile  := bWhile
      ENDIF
      IF ISBLOCK( bFor )
         ::bFor    := bFor
      ENDIF
   ELSE
      ::lFilter := .F.
   ENDIF
   hwg_RegBrowse()
   ::InitBrw( , .F. )
   ::Activate()

   RETURN Self

//----------------------------------------------------//
METHOD Activate() CLASS HBrowse
   IF ! Empty( ::oParent:handle )
      ::handle := CreateBrowse( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

//----------------------------------------------------//
METHOD Init() CLASS HBrowse

   IF ! ::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      Super:Init()
      VScrollPos( Self, 0, .f. )
      ::InitBrw( , .T. )
      IF ::GetParentForm( ):Type < WND_DLG_RESOURCE
         ::GetParentForm():lDisableCtrlTab := .T.
      ENDIF

   ENDIF

   RETURN Nil


//----------------------------------------------------//
METHOD SetMargin( nTop, nRight, nBottom, nLeft )  CLASS HBrowse

   LOCAL aOldMargin := AClone( ::aMargin )

   IF nTop == NIL
      nTop := 0
   ENDIF

   IF nRight == NIL
      nRight := nBottom := nLeft := nTop
   ENDIF

   IF nBottom == NIL
      nBottom := nTop
      nLeft := nRight
   ENDIF

   ::aMargin := { nTop, nRight, nBottom, nLeft }

   RETURN aOldMargin

/***
*
*/
METHOD SetRowHeight( nPixels ) CLASS HBrowse
   LOCAL nOldPixels

   nOldPixels := ::forceHeight

   IF ValType( nPixels ) == "N"
      IF nPixels > 0
         ::forceHeight := nPixels
         IF nPixels != nOldPixels .AND. ::rowCurrCount > 0  //nando
            ::lRepaintBackground := .T.
            ::Rebuild()
            ::Refresh()
         ENDIF
      ELSE
         ::forceHeight := 0
      ENDIF
   ENDIF

   RETURN( nOldPixels )


//----------------------------------------------------//
METHOD onEvent( msg, wParam, lParam )  CLASS HBrowse
   LOCAL oParent, cKeyb, nCtrl, nPos, lBEof
   LOCAL nRecStart, nRecStop, nRet, nShiftAltCtrl

   IF ::active .AND. ! Empty( ::aColumns )
      // moved to first
      IF msg == WM_MOUSEWHEEL .AND. ! ::oParent:lSuspendMsgsHandling
            ::isMouseOver := .F.
            ::MouseWheel( LOWORD( wParam ), ;
                    IIF( HIWORD( wParam ) > 32768, ;
                        HIWORD( wParam ) - 65535, HIWORD( wParam ) ), ;
                    LOWORD( lParam ), HIWORD( lParam ) )
         RETURN 0
      ENDIF
      //
      IF ::bOther != Nil
         IF Valtype( nRet := Eval( ::bOther,Self,msg,wParam,lParam ) ) != "N"
            nRet := IIF( VALTYPE( nRet ) = "L" .AND. ! nRet, 0, -1 )
         ENDIF
         IF nRet >= 0
				    RETURN -1
         ENDIF
      ENDIF
      IF msg == WM_THEMECHANGED
         IF ::Themed
            IF ValType( ::hTheme ) == "P"
               HB_CLOSETHEMEDATA( ::htheme )
               ::hTheme       := nil
            ENDIF
            ::Themed := .F.
         ENDIF
         ::m_bFirstTime := .T.
         RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
         RETURN 0
      ENDIF
      IF msg == WM_PAINT
         ::Paint()
         RETURN 1

      ELSEIF msg == WM_ERASEBKGND
         RETURN 0

      ELSEIF msg = WM_SIZE
         IF ::AutoColumnFit = 1
            ::AutoFit()
         ENDIF
         ::lRepaintBackground := .T.

      ELSEIF msg = WM_SETFONT .AND. ::oHeadFont = Nil .AND. isWindowVisible( ::Handle )
         ::nHeadHeight := 0
         ::nFootHeight := 0

      ELSEIF msg == WM_SETFOCUS .AND. ! ::oParent:lSuspendMsgsHandling
         ::When()
         /*
         IF ::bGetFocus != Nil
            Eval( ::bGetFocus, Self )
         ENDIF
         */
      ELSEIF msg == WM_KILLFOCUS .AND. ! ::oParent:lSuspendMsgsHandling
         ::Valid()
         /*
         IF ::bLostFocus != Nil
            Eval( ::bLostFocus, Self )
         ENDIF
         */
         IF ::GetParentForm( self ):Type < WND_DLG_RESOURCE
             SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, 0 ), ::handle )
         ENDIF
         ::internal[ 1 ] := 15 //force redraw header,footer and separator

      ELSEIF msg == WM_HSCROLL
         ::DoHScroll( wParam )

      ELSEIF msg == WM_VSCROLL
         ::DoVScroll( wParam )

      ELSEIF msg == WM_CHAR
         IF ! CheckBit( lParam, 32 ) //.AND.::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
             nShiftAltCtrl := IIF( IsCtrlShift( .F., .T. ), 1 , 0 )
             nShiftAltCtrl += IIF( IsCtrlShift( .T., .F. ), 2 , nShiftAltCtrl )
             //nShiftAltCtrl += IIF( wParam > 111, 4, nShiftAltCtrl )
             IF ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
                IF EMPTY( Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl, msg ) )
                   RETURN 0
                ENDIF
             ENDIF
             IF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
                RETURN - 1
             ENDIF
             IF ::lAutoEdit .OR. ::aColumns[ ::SetColumn() ]:lEditable
                ::Edit( wParam, lParam )
             ENDIF
         ENDIF

      ELSEIF msg == WM_GETDLGCODE
         ::isMouseOver := .F.
         RETURN DLGC_WANTALLKEYS

      ELSEIF msg == WM_COMMAND
         // Super:onEvent( WM_COMMAND )
         IF ::GetParentForm( self ):Type < WND_DLG_RESOURCE
            ::GetParentForm( self ):onEvent( msg, wparam, lparam )
         ELSE
            DlgCommand( Self, wParam, lParam )
         ENDIF

      ELSEIF msg == WM_KEYUP .AND. ! ::oParent:lSuspendMsgsHandling
         IF wParam == 17
            ::lCtrlPress := .F.
         ENDIF
         IF wParam == 16
            ::lShiftPress := .F.
         ENDIF
         IF wParam == VK_TAB .AND. ::GetParentForm( ):Type < WND_DLG_RESOURCE
            IF IsCtrlShift(.T.,.F.)
               getskip(::oParent,::handle,, ;
               iif( IsCtrlShift(.f., .t.), -1, 1) )
               RETURN 0
            ENDIF
            /*
            ELSE
               ::DoHScroll( iif( IsCtrlShift( .F., .T. ), SB_LINELEFT, SB_LINERIGHT ) )
            ENDIF
            */
	       ENDIF
         IF wParam != VK_SHIFT .AND. wParam != VK_CONTROL .AND. wParam != 18
            oParent := ::oParent
            DO WHILE oParent != Nil .AND. ! __ObjHasMsg( oParent, "GETLIST" )
               oParent := oParent:oParent
            ENDDO
            IF oParent != Nil .AND. ! Empty( oParent:KeyList )
               cKeyb := GetKeyboardState()
               nCtrl := IIf( Asc( SubStr( cKeyb, VK_CONTROL + 1, 1 ) ) >= 128, FCONTROL, IIf( Asc( SubStr( cKeyb, VK_SHIFT + 1, 1 ) ) >= 128, FSHIFT, 0 ) )
               IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nCtrl.AND.a[ 2 ] == wParam } ) ) > 0
                  Eval( oParent:KeyList[ nPos, 3 ], Self )
               ENDIF
            ENDIF
         ENDIF

         RETURN 1

      ELSEIF msg == WM_KEYDOWN .AND. ! ::oParent:lSuspendMsgsHandling
         //::isMouseOver := .F.
         IF ( ( CheckBit( lParam, 25 ) .AND. wParam != 111 ) .OR.  ( wParam > 111 .AND. wParam < 124 ) ) .AND.;
               ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
             nShiftAltCtrl := IIF( IsCtrlShift( .F., .T. ), 1 , 0 )
             nShiftAltCtrl += IIF( IsCtrlShift( .T., .F. ), 2 , 0 )
             nShiftAltCtrl += IIF( wParam > 111, 4, nShiftAltCtrl )
             IF EMPTY( Eval( ::bKeyDown, Self, wParam, nShiftAltCtrl, msg ) )
                RETURN 0
             ENDIF
         ENDIF
         IF wParam == 33 .OR. wParam == 34 .OR. wParam == 38 .OR. wParam == 40
            IF ! ::ChangeRowCol( 1 )
               RETURN -1
            ENDIF
         ENDIF

         IF wParam == VK_TAB
            IF ::lCtrlPress
               getskip(::oParent,::handle,, ;
               iif( IsCtrlShift(.f., .t.), -1, 1) )
               RETURN 0
            ELSE
               ::DoHScroll( iif( IsCtrlShift( .F., .T. ), SB_LINELEFT, SB_LINERIGHT ) )
            ENDIF
         ELSEIF wParam == VK_DOWN //40        // Down
            IF ::lShiftPress .AND. ::aSelected != Nil
               Eval( ::bskip, Self, 1 )
               lBEof := Eval( ::beof, Self )
               Eval( ::bskip, Self, - 1 )
               IF ! ( lBEof .and. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::Select()
                  IF lBEof
                     ::refreshline()
                  ENDIF
               ENDIF
            ENDIF
            ::LINEDOWN()

         ELSEIF wParam == VK_UP //38    // Up

            IF ::lShiftPress .AND. ::aSelected != Nil
               Eval( ::bskip, Self, 1 )
               lBEof := Eval( ::beof, Self )
               Eval( ::bskip, Self, - 1 )
               IF ! ( lBEof .and. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::LINEUP()
               ENDIF
            ELSE
               ::LINEUP()
            ENDIF

            IF ::lShiftPress .AND. ::aSelected != Nil
               Eval( ::bskip, Self, - 1 )
               IF ! lBEof := Eval( ::bBof, Self )
                  Eval( ::bskip, Self, 1 )
               ENDIF
               IF ! ( lBEof .and. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::Select()
                  ::refresh( .f. )
               ENDIF
            ENDIF

         ELSEIF wParam == VK_RIGHT //39    // Right
            ::DoHScroll( SB_LINERIGHT )
         ELSEIF wParam == VK_LEFT //37    // Left
            ::DoHScroll( SB_LINELEFT )
         ELSEIF wParam == VK_HOME //36    // Home
            IF ! ::lCtrlPress .AND. ( ::lAutoEdit .OR. ::aColumns[ ::SetColumn() ]:lEditable )
               ::Edit( wParam )
            ELSE
               ::DoHScroll( SB_LEFT )
            ENDIF
         ELSEIF wParam == VK_END //35    // End
            IF ! ::lCtrlPress .AND. ( ::lAutoEdit .OR. ::aColumns[ ::SetColumn() ]:lEditable )
               ::Edit( wParam )
            ELSE
               ::DoHScroll( SB_RIGHT )
            ENDIF
         ELSEIF wParam == 34    // PageDown
            nRecStart := Eval( ::brecno, Self )
            IF ::lCtrlPress
               IF( ::nRecords > ::rowCount )
                  ::BOTTOM()
               ELSE
                 ::PageDown()
               ENDIF
            ELSE
              ::PageDown()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != Nil
               nRecStop := Eval( ::brecno, Self )
               Eval( ::bskip, Self, 1 )
               lBEof := Eval( ::beof, Self )
               Eval( ::bskip, Self, - 1 )
               IF ! ( lBEof .and. AScan( ::aSelected, Eval( ::bRecno, Self ) ) > 0 )
                  ::Select()
               ENDIF
               DO WHILE Eval( ::bRecno, Self ) != nRecStart
                  ::Select()
                  Eval( ::bskip, Self, - 1 )
               ENDDO
               ::Select()
               Eval( ::bgoto, Self, nRecStop )
               Eval( ::bskip, Self, 1 )
               IF Eval( ::beof, Self )
                  Eval( ::bskip, Self, - 1 )
                  ::Select()
               ELSE
                  Eval( ::bskip, Self, - 1 )
               ENDIF
               ::Refresh()
            ENDIF
         ELSEIF wParam == 33    // PageUp
            nRecStop := Eval( ::brecno, Self )
            IF ::lCtrlPress
               ::TOP()
            ELSE
               ::PageUp()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != Nil
                nRecStart := Eval( ::bRecno, Self )
                DO WHILE Eval( ::bRecno, Self ) != nRecStop
                   ::Select()
                   Eval( ::bskip, Self, 1 )
                ENDDO
                Eval( ::bgoto, Self, nRecStart )
                ::Refresh()
            ENDIF

         ELSEIF wParam == VK_RETURN    // Enter
            ::Edit( VK_RETURN )

         ELSEIF wParam == VK_ESCAPE .AND. ::lESC
            SendMessage( GetParent( ::handle ), WM_CLOSE, 0, 0 )
         ELSEIF wParam == VK_CONTROL  //17
            ::lCtrlPress := .T.
         ELSEIF wParam == VK_SHIFT   //16
            ::lShiftPress := .T.
         //ELSEIF ::lAutoEdit .AND. ( wParam >= 48 .and. wParam <= 90 .or. wParam >= 96 .and. wParam <= 111 )
         //   ::Edit( wParam, lParam )
         ENDIF
         RETURN 1

      ELSEIF msg == WM_LBUTTONDBLCLK
         ::ButtonDbl( lParam )

      ELSEIF msg == WM_LBUTTONDOWN
         ::ButtonDown( lParam )
      ELSEIF msg == WM_LBUTTONUP
         ::ButtonUp( lParam )
      ELSEIF msg == WM_RBUTTONDOWN
         ::ButtonRDown( lParam )
      ELSEIF msg == WM_MOUSEMOVE .AND.! ::oParent:lSuspendMsgsHandling
         IF ::nWheelPress > 0
            ::MouseWheel( LOWORD( wParam ), ::nWheelPress - lParam )
         ELSE
            ::MouseMove( wParam, lParam )
            IF ::lHeadClick
               AEVAL( ::aColumns,{ | c | c:lHeadClick := .F. } )
               InvalidateRect( ::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1 )
               ::lHeadClick := .F.
            ENDIF
            IF ( ! ::allMouseOver ) .AND. ::hTheme != Nil
               ::allMouseOver := .T.
               TRACKMOUSEVENT( ::handle )
            ELSE
               TRACKMOUSEVENT( ::handle, TME_HOVER + TME_LEAVE )      
            ENDIF
         ENDIF
      ELSEIF msg =  WM_MOUSEHOVER 
         ::ShowColToolTips( lParam ) 
         
      ELSEIF ( msg = WM_MOUSELEAVE .OR. msg = WM_NCMOUSELEAVE ) //.AND.! ::oParent:lSuspendMsgsHandling
         IF ::allMouseOver
            ::MouseMove( 0, 0 )
            ::allMouseOver := .F.
            ::isMouseOver := .F.
         ENDIF

      ELSEIF msg == WM_MBUTTONUP
         ::nWheelPress := IIf( ::nWheelPress > 0, 0, lParam )
         IF ::nWheelPress > 0
            Hwg_SetCursor( LOADCURSOR( 32652 ) )
         ELSE
            Hwg_SetCursor( LOADCURSOR( IDC_ARROW ) )
         ENDIF
      /*
      ELSEIF msg == WM_MOUSEWHEEL
         ::MouseWheel( LOWORD( wParam ), ;
                    IF( HIWORD( wParam ) > 32768, ;
                        HIWORD( wParam ) - 65535, HIWORD( wParam ) ), ;
                    LOWORD( lParam ), HIWORD( lParam ) )
      */
      ELSEIF msg == WM_DESTROY
        ::END()
      ENDIF

   ENDIF

RETURN - 1


//----------------------------------------------------//
METHOD Redefine( lType, oWndParent, nId, oFont, bInit, bSize, bPaint, bEnter, bGfocus, bLfocus ) CLASS HBrowse

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint )

   ::Type    := lType
   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bGetFocus  := bGfocus
   ::bLostFocus := bLfocus

   hwg_RegBrowse()
   ::InitBrw()

   RETURN Self

//----------------------------------------------------//
METHOD FindBrowse( nId ) CLASS HBrowse
   LOCAL i := AScan( ::aItemsList, { | o | o:id == nId }, 1, ::iItems )

   RETURN IIf( i > 0, ::aItemsList[ i ], Nil )

//----------------------------------------------------//
METHOD AddColumn( oColumn ) CLASS HBrowse

   AAdd( ::aColumns, oColumn )
   ::lChanged := .T.
   InitColumn( Self, oColumn, Len( ::aColumns ) )

   RETURN oColumn

//----------------------------------------------------//
METHOD InsColumn( oColumn, nPos ) CLASS HBrowse

   AAdd( ::aColumns, Nil )
   AIns( ::aColumns, nPos )
   ::aColumns[ nPos ] := oColumn
   ::lChanged := .T.
   InitColumn( Self, oColumn, nPos )

   RETURN oColumn

STATIC FUNCTION InitColumn( oBrw, oColumn, n )
   LOCAL xres, ctype
   LOCAL cname := "Column" + LTRIM( STR( Len( oBrw:aColumns ) ) )

   IF oColumn:Type == Nil
      oColumn:Type := ValType( Eval( oColumn:block,, oBrw, n ) )
   ENDIF
   oColumn:width := 0
   IF oColumn:dec == Nil
      IF oColumn:Type == "N" .and. At( '.', Str( Eval( oColumn:block,, oBrw, n ) ) ) != 0
         oColumn:dec := Len( SubStr( Str( Eval( oColumn:block,, oBrw, n ) ), ;
                                     At( '.', Str( Eval( oColumn:block,, oBrw, n ) ) ) + 1 ) )
      ELSE
         oColumn:dec := 0
      ENDIF
   ENDIF
   IF oColumn:length == Nil
      IF oColumn:picture != Nil .AND. ! Empty( oBrw:aArray )
         oColumn:length := Len( Transform( Eval( oColumn:block,, oBrw, n ), oColumn:picture ) )
      ELSE
         oColumn:length := 10
         IF !Empty( oBrw:aArray )
            xres     := Eval( oColumn:block,, oBrw, n )
            ctype    := ValType( xres )
         ELSE
            xRes     := SPACE(10)
            ctype    := "C"
         ENDIF
      ENDIF
//      oColumn:length := Max( oColumn:length, Len( oColumn:heading ) )
      oColumn:length := LenVal( xres, ctype, oColumn:picture )
   ENDIF
   oColumn:nJusLin := IIf( oColumn:nJusLin == nil, IIF( oColumn:Type == "N", DT_RIGHT , DT_LEFT ), oColumn:nJusLin ) + DT_VCENTER + DT_SINGLELINE
   oColumn:lEditable := IIf( oColumn:lEditable != Nil, oColumn:lEditable, .F. )
   oColumn:oParent := oBrw
   oColumn:Column := n
   __objAddData( oBrw, cName)
   oBrw:&(cName) := oColumn

   RETURN Nil

//----------------------------------------------------//
METHOD DelColumn( nPos ) CLASS HBrowse

   ADel( ::aColumns, nPos )
   ASize( ::aColumns, Len( ::aColumns ) - 1 )
   ::lChanged := .T.
   RETURN Nil

//----------------------------------------------------//
METHOD END() CLASS HBrowse

   Super:END()
   IF ::brush != Nil
      ::brush:Release()
      ::brush := Nil
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
      ::brushSel := Nil
   ENDIF
   IF oPen64 != Nil
      oPen64:Release()
   ENDIF
   IF ::oTimer != Nil
      ::oTimer:End()
   ENDIF   


   RETURN Nil

METHOD ShowMark( lShowMark ) CLASS HBrowse

   IF lShowMark != Nil
      ::nShowMark := IIF( lShowMark, 12, 0 )
      ::lShowMark := lShowMark
      ::Refresh()
   ENDIF
   RETURN ::lDeleteMark

METHOD DeleteMark( lDeleteMark ) CLASS HBrowse

   IF lDeleteMark != Nil
      IF ::Type == BRW_DATABASE
         ::nDeleteMark := IIF( lDeleteMark, 7, 0 )
         ::lDeleteMark := lDeleteMark
         ::Refresh()
      ENDIF
   ENDIF
   RETURN ::lDeleteMark

METHOD ShowColToolTips( lParam ) CLASS HBrowse
   LOCAL pt := {, }, cTip := ""

   IF Ascan( ::aColumns, {| c | c:Hint != .F. .AND. c:Tooltip != Nil } ) = 0 
       RETURN Nil
   ENDIF
   pt := ::ButtonDown( lParam, .T. )
   IF pt = Nil .OR. pt[ 1 ] = - 1
      RETURN Nil
   ELSEIF pt[ 1 ] != 0 .AND. pt[ 2 ] != 0 .AND. ::aColumns[ pt[ 2 ] ]:Hint 
      cTip := ::aColumns[ pt[ 2 ] ]:aHints[ pt[ 1 ] ]
   ELSEIF pt[ 2 ] != 0 .AND. ::aColumns[ pt[ 2 ] ]:ToolTip != Nil
      cTip := ::aColumns[ pt[ 2 ] ]:ToolTip
   ENDIF   
   IF ! EMPTY( cTip ) .OR. ! EMPTY( xToolTip ) 
      SETTOOLTIPTITLE( ::GetparentForm():handle, ::handle, cTip )
      xToolTip := IIF( ! EMPTY( cTip ), cTip, IIF( ! EMPTY( xToolTip ), Nil, xToolTip ) )
   ENDIF
   RETURN NIL

METHOD SetRefresh( nSeconds ) CLASS HBrowse
   
   IF nSeconds != Nil //.AND. ::Type == BRW_DATABASE
      IF ::oTimer != Nil 
         ::oTimer:Interval := nSeconds * 1000
      ELSEIF nSeconds > 0    
         SET TIMER ::oTimer OF ::GetParentForm() VALUE ( nSeconds * 1000)  ACTION { || IIF( isWindowVisible( ::Handle ),; 
                                     ( ::internal[ 1 ] := 12, INVALIDATERect( ::handle, 0,;
                                                            ::x1 , ;
                                                            ::y1 ,;
                                                            ::x1 + ::xAdjRight,;
                                                            ::y1 + ::rowCount * ( ::height + 1 ) + 1 ) ), Nil ) } 
      ENDIF
      ::nSetRefresh := nSeconds   
   ENDIF
   RETURN ::nSetRefresh

//----------------------------------------------------//
METHOD InitBrw( nType, lInit )  CLASS HBrowse
   Local cAlias := Alias()

   DEFAULT lInit to .F.
   IF EMPTY( lInit )
      ::x1 := ::y1 := ::x2 := ::y2  := ::xAdjRight := 0
      ::height := ::width := 0
      ::nyHeight := IIF( ::GetParentForm( self ):Type < WND_DLG_RESOURCE ,1 ,0 )
      ::lDeleteMark := .F.
      ::lShowMark := .T.
      IF nType != Nil
         ::Type := nType
      ELSE
         ::aColumns := { }
         ::rowPos  := ::nCurrent  := ::colpos := 1
         ::nLeftCol := 1
         ::freeze  := 0
         ::internal  := { 15, 1 , 0, 0 }
         ::aArray     := Nil
         ::aMargin := { 1, 1, 0, 1 }
         IF Empty( ColSizeCursor )
            ColSizeCursor := LoadCursor( IDC_SIZEWE )
            arrowCursor := LoadCursor( IDC_ARROW )
            downCursor := LoadCursor( IDC_HAND )
         ENDIF
         oPen64 :=  HPen():Add( PS_SOLID, 1, IIF( ::Themed, RGB( 128, 128, 128 ) , RGB( 64, 64, 64 ) ) )
      ENDIF
   ENDIF

   IF ! EMPTY( ::RelationalExpr )
      ::lFilter := .T.
   ENDIF

   IF ::Type == BRW_DATABASE
      ::Filter( ::lFilter )
      /*
      IF ! EMPTY( ::Alias ) .AND. SELECT( ::Alias ) > 0
         SELECT ( ::Alias )
      ENDIF
      ::Alias   := Alias()
      IF EMPTY( ::ALias )
         RETURN Nil
      ENDIF
     IF ::lFilter
         ::nLastRecordFilter  := ::nFirstRecordFilter := 0
         IF ::lDescend
            ::bSkip     := { | o, n | ( ::Alias ) ->( FltSkip( o, n, .T. ) ) }
            ::bGoTop    := { | o | ( ::Alias ) ->( FltGoBottom( o ) ) }
            ::bGoBot    := { | o | ( ::Alias ) ->( FltGoTop( o ) ) }
            ::bEof      := { | o | ( ::Alias ) ->( FltBOF( o ) ) }
            ::bBof      := { | o | ( ::Alias ) ->( FltEOF( o ) ) }
         ELSE
            ::bSkip     := { | o, n | ( ::Alias ) ->( FltSkip( o, n, .F. ) ) }
            ::bGoTop    := { | o | ( ::Alias ) ->( FltGoTop( o ) ) }
            ::bGoBot    := { | o | ( ::Alias ) ->( FltGoBottom( o ) ) }
            ::bEof      := { | o | ( ::Alias ) ->( FltEOF( o ) ) }
            ::bBof      := { | o | ( ::Alias ) ->( FltBOF( o ) ) }
         ENDIF
         ::bRcou     := { | o | ( ::Alias ) ->( FltRecCount( o ) ) }
         ::bRecnoLog := ::bRecno := { | o | ( ::Alias ) ->( FltRecNo( o ) ) }
         ::bGoTo     := { | o, n | ( ::Alias ) ->( FltGoTo( o, n ) ) }
      ELSE
         ::bSkip     :=  { | o, n | HB_SYMBOL_UNUSED( o ), ( ::Alias ) ->( DBSkip( n ) ) }
         ::bGoTop    :=  { || ( ::Alias ) ->( DBGoTop() ) }
         ::bGoBot    :=  { || ( ::Alias ) ->( DBGoBottom() ) }
         ::bEof      :=  { || ( ::Alias ) ->( Eof() ) }
         ::bBof      :=  { || ( ::Alias ) ->( Bof() ) }
         ::bRcou     :=  { || ( ::Alias ) ->( RecCount() ) }
         ::bRecnoLog := ::bRecno  := { || ( ::Alias ) ->( RecNo() ) }
         ::bGoTo     := { | a, n | HB_SYMBOL_UNUSED( a ), ( ::Alias ) ->( DBGoTo( n ) ) }
      ENDIF
      */
   ELSEIF ::Type == BRW_ARRAY
      ::bSkip      := { | o, n | ARSKIP( o, n ) }
      ::bGoTop  := { | o | o:nCurrent := 1 }
      ::bGoBot  := { | o | o:nCurrent := o:nRecords }
      ::bEof    := { | o | o:nCurrent > o:nRecords }
      ::bBof    := { | o | o:nCurrent == 0 }
      ::bRcou   := { | o | Len( o:aArray ) }
      ::bRecnoLog := ::bRecno  := { | o | o:nCurrent }
      ::bGoTo   := { | o, n | o:nCurrent := n }
      ::bScrollPos := { | o, n, lEof, nPos | VScrollPos( o, n, lEof, nPos ) }
   ENDIF

   IF lInit
      IF ! EMPTY( ::LinkMaster )
         SELECT ( ::Alias )
         IF ! EMPTY( ::ChildOrder )
            ( ::Alias ) ->( DBSETORDER( ::ChildOrder ) )
         ENDIF
         IF ! EMPTY( ::RelationalExpr )
             ::bFirst := { || ( ::Alias ) ->( DBSEEK( ( ::LinkMaster ) ->( &( ::RelationalExpr ) ), .F. ) ) }
             ::bLast  := { || ( ::Alias ) ->( DBSEEK( ( ::LinkMaster ) ->( &( ::RelationalExpr ) ) , .F., .T. ) ) }
             ::bWhile := {|| ( ::Alias ) -> ( &( ::RelationalExpr ) ) = ( ::LinkMaster ) ->( &( ::RelationalExpr ) ) }
             //::bSkip  := { | o, n | HB_SYMBOL_UNUSED( o ), ( ::Alias ) ->( DBSkip( n ) ) }
          ENDIF
      ENDIF
   ENDIF
   IF !EMPTY( cAlias )
      SELECT ( cAlias )
   ENDIF

   RETURN Nil

METHOD FILTER( lFilter ) CLASS HBrowse

   IF lFilter != Nil .AND. ::Type == BRW_DATABASE
      IF  EMPTY( ::Alias )
        ::Alias   := Alias()
      ENDIF
      IF ! EMPTY( ::Alias ) .AND. SELECT( ::Alias ) > 0
         SELECT ( ::Alias )
      ENDIF
      IF EMPTY( ::ALias )
         RETURN ::lFilter
      ENDIF
      IF lFilter
         ::nLastRecordFilter  := ::nFirstRecordFilter := 0
         ::rowCurrCount := 0
         IF ::lDescend
            ::bSkip     := { | o, n | ( ::Alias ) ->( FltSkip( o, n, .T. ) ) }
            ::bGoTop    := { | o | ( ::Alias ) ->( FltGoBottom( o ) ) }
            ::bGoBot    := { | o | ( ::Alias ) ->( FltGoTop( o ) ) }
            ::bEof      := { | o | ( ::Alias ) ->( FltBOF( o ) ) }
            ::bBof      := { | o | ( ::Alias ) ->( FltEOF( o ) ) }
         ELSE
            ::bSkip     := { | o, n | ( ::Alias ) ->( FltSkip( o, n, .F. ) ) }
            ::bGoTop    := { | o | ( ::Alias ) ->( FltGoTop( o ) ) }
            ::bGoBot    := { | o | ( ::Alias ) ->( FltGoBottom( o ) ) }
            ::bEof      := { | o | ( ::Alias ) ->( FltEOF( o ) ) }
            ::bBof      := { | o | ( ::Alias ) ->( FltBOF( o ) ) }
         ENDIF
         //::bRcou     := { | o | ( ::Alias ) ->( FltRecCount( o ) ) }
         ::bRcou     := { || ( ::Alias ) ->( RecCount() ) }
         ::bRecnoLog := ::bRecno := { | o | ( ::Alias ) ->( FltRecNo( o ) ) }
         ::bGoTo     := { | o, n | ( ::Alias ) ->( FltGoTo( o, n ) ) }
      ELSE
         ::bSkip     :=  { | o, n | HB_SYMBOL_UNUSED( o ), ( ::Alias ) ->( DBSkip( n ) ) }
         ::bGoTop    :=  { || ( ::Alias ) ->( DBGoTop() ) }
         ::bGoBot    :=  { || ( ::Alias ) ->( DBGoBottom() ) }
         ::bEof      :=  { || ( ::Alias ) ->( Eof() ) }
         ::bBof      :=  { || ( ::Alias ) ->( Bof() ) }
         ::bRcou     :=  { || ( ::Alias ) ->( RecCount() ) }
         ::bRecnoLog := ::bRecno  := { || ( ::Alias ) ->( RecNo() ) }
         ::bGoTo     := { | a, n | HB_SYMBOL_UNUSED( a ), ( ::Alias ) ->( DBGoTo( n ) ) }
      ENDIF
      ::lFilter := lFilter
   ENDIF
   RETURN ::lFilter

//----------------------------------------------------//
METHOD Rebuild() CLASS HBrowse
   LOCAL i, j, oColumn, xSize, nColLen, nHdrLen, nCount, fontsize

   IF ::brush != Nil
      ::brush:Release()
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
   ENDIF
   IF ::bcolor != Nil
      ::brush     := HBrush():Add( ::bcolor )
//      IF hDC != Nil
//         SendMessage( ::handle, WM_ERASEBKGND, hDC, 0 )
//      ENDIF
   ENDIF
   IF ::bcolorSel != Nil
      ::brushSel  := HBrush():Add( ::bcolorSel )
   ENDIF
   ::nLeftCol  := ::freeze + 1
   // ::nCurrent     := ::rowPos := ::colPos := 1
   ::lEditable := .F.
   ::minHeight := 0

   FOR i := 1 TO Len( ::aColumns )

      oColumn := ::aColumns[ i ]

      IF oColumn:lEditable
         ::lEditable := .T.
      ENDIF
      FontSize := TxtRect(  "a", Self, oColumn:oFont )[ 1 ]
      IF oColumn:aBitmaps != Nil
         IF oColumn:heading != nil
            /*
            IF ::oFont != Nil
               xSize := Round( ( Len( oColumn:heading ) + 2 ) * ( ( - ::oFont:height ) * 0.6 ), 0 )
            ELSE
               xSize := Round( ( Len( oColumn:heading ) + 2 ) * 6, 0 )
            ENDIF
            */
            xSize := Round( ( Len( oColumn:heading ) + 0.8 ) * FontSize, 0 )
         ELSE
            xSize := 0
         ENDIF
         IF ::forceHeight > 0
            ::minHeight := ::forceHeight
         ELSE
            FOR j := 1 TO Len( oColumn:aBitmaps )
               xSize := Max( xSize, oColumn:aBitmaps[ j, 2 ]:nWidth + 2 )
               ::minHeight := Max( ::minHeight, ::aMargin[ 1 ] + oColumn:aBitmaps[ j, 2 ]:nHeight + ::aMargin[ 3 ] )
            NEXT
         ENDIF
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
         IF oColumn:footing != nil .AND. !oColumn:lHide
            HdrToken( oColumn:footing, @nHdrLen, @nCount )
            IF ! oColumn:lSpandFoot
               nColLen := Max( nColLen, nHdrLen )
            ENDIF
            ::nFootRows := Max( ::nFootRows, nCount )
         ENDIF
         /*
         IF ::oFont != Nil
            //xSize := Round( ( nColLen + 2 ) * ( ( - ::oFont:height ) * 0.6 ), 0 )  // Added by Fernando Athayde
            xSize := Round( ( nColLen  ) * ( ( - ::oFont:height ) * 0.6 ), 0 )  // Added by Fernando Athayde
         ELSE
            //xSize := Round( ( nColLen + 2 ) * 6, 0 )
            xSize := Round( ( nColLen  ) * 6, 0 )
         ENDIF
         */
         xSize := Round( ( nColLen + 0.8 ) * ( (  FontSize ) ), 0 )
      ENDIF
      xSize := ::aMargin[ 4 ] + xSize + ::aMargin[ 2 ]
      IF Empty( oColumn:width )
         oColumn:width := xSize
      ENDIF
   NEXT
   IF HWG_BITAND( ::style, WS_HSCROLL ) != 0
       SetScrollInfo( ::Handle, SB_HORZ, 1, 0,  1 , Len( ::aColumns ) )
   ENDIF

   ::lChanged := .F.

   RETURN Nil

METHOD AutoFit( ) CLASS HBrowse
   Local nlen , i, aCoors, nXincRelative

   IF ::AutoColumnFit = 2
      RETURN .F.
   ENDIF
   ::oParent:lSuspendMsgsHandling := .T.
   RedrawWindow( ::handle, RDW_VALIDATE + RDW_UPDATENOW )
   ::oParent:lSuspendMsgsHandling := .F.
   aCoors := GetWindowRect( ::handle )
   IF ::nAutoFit = Nil
      ::nAutoFit :=  IIF( Max( 0, ::x2 - ::xAdjRight - 2 ) = 0, 0,  ::x2  / ::xAdjRight )
      nXincRelative := IIF( ( aCoors[ 3 ] - aCoors[ 1 ] )  - ( ::nWidth  ) > 0, ::nAutoFit, 1/::nAutoFit )
   ELSE
      nXincRelative :=    (aCoors[ 3 ] - aCoors[ 1 ] )  / ( ::nWidth  ) - 0.01
   ENDIF
   IF ::nAutoFit = 0 .OR. nXincRelative < 1
      IF nXincRelative < 0.1 .OR. ::nAutoFit = 0
         ::nAutoFit := IIF( nXincRelative < 1, Nil, ::nAutoFit )
         RETURN .F.
      ENDIF
      ::nAutoFit := IIF( nXincRelative < 1, Nil, ::nAutoFit )
   ENDIF
	 nlen := LEN( ::aColumns )
   FOR i = 1 to nLen
      IF ::aColumns[ i ]:Resizable
         ::aColumns[ i ]:Width := ::aColumns[ i ]:Width  * nXincRelative
      ENDIF
   NEXT
   RETURN .T.

//----------------------------------------------------//
METHOD Paint( lLostFocus )  CLASS HBrowse
   LOCAL aCoors, aMetr, cursor_row, tmp, nRows, nRowsFill
   LOCAL pps, hDC
   LOCAL oldfont, aMetrHead,  nRecFilter

   IF ! ::active .OR. Empty( ::aColumns ) .OR. ::lHeadClick  .OR. ::isMouseOver //.AND. ::internal[ 1 ] = WM_MOUSEMOVE )
      pps := DefinePaintStru()
      hDC := BeginPaint( ::handle, pps )
      IF ::lHeadClick   .OR. ::isMouseOver
          ::oParent:lSuspendMsgsHandling := .T.
          ::HeaderOut( hDC )
          ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
      EndPaint( ::handle, pps )
      RETURN Nil
   ENDIF
   IF ( ::m_bFirstTime ) .AND. ::Themed
      ::m_bFirstTime := .F.
      IF ( ISTHEMEDLOAD() )
         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
         ENDIF
         IF ::WindowsManifest
            ::hTheme := hb_OpenThemeData( ::handle, "HEADER" )
         ENDIF
         ::hTheme := IIF( EMPTY( ::hTheme  ), Nil, ::hTheme )
      ENDIF
   ENDIF

// Validate some variables

   IF ::tcolor    == Nil ; ::tcolor    := 0 ; ENDIF
   IF ::bcolor    == Nil ; ::bcolor    := VColor( "FFFFFF" ) ; ENDIF

   //IF ::httcolor  == Nil ; ::httcolor  := VColor( "FFFFFF" ) ; ENDIF
   //IF ::htbcolor  == Nil ; ::htbcolor  := 2896388  ; ENDIF
   IF ::httcolor  == Nil ; ::httcolor  := GETSYSCOLOR( COLOR_HIGHLIGHTTEXT ) ; ENDIF
   IF ::htbcolor  == Nil ; ::htbcolor  := GETSYSCOLOR( COLOR_HIGHLIGHT )  ; ENDIF

   IF ::tcolorSel == Nil ; ::tcolorSel := VColor( "FFFFFF" ) ; ENDIF
   IF ::bcolorSel == Nil ; ::bcolorSel := VColor( "808080" ) ; ENDIF

// Open Paint procedure

   pps := DefinePaintStru()
   hDC := BeginPaint( ::handle, pps )

   IF ::ofont != Nil
      SelectObject( hDC, ::ofont:handle )
   ENDIF
   IF ::brush == Nil .OR. ::lChanged
      ::Rebuild()
   ENDIF

// Get client area coordinate

   aCoors := GetClientRect( ::handle )
   aMetr := GetTextMetric( hDC )
   ::width := Round( ( aMetr[ 3 ] + aMetr[ 2 ] ) / 2 - 1, 0 )
// If forceHeight is set, we should use that value
   IF ( ::forceHeight > 0 )
      ::height := ::forceHeight + 1
   ELSE
      ::height := ::aMargin[ 1 ] + Max( aMetr[ 1 ], ::minHeight ) + 1 + ::aMargin[ 3 ]
   ENDIF

   aMetrHead := AClone( aMetr )
   IF ::oHeadFont != Nil
      oldfont := SelectObject( hDC, ::oHeadFont:handle )
      aMetrHead := GetTextMetric( hDC )
      SelectObject( hDC, oldfont )
   ENDIF
   // USER DEFINE Height  IF != 0
   IF EMPTY( ::nHeadHeight )
      ::nHeadHeight := ::aMargin[ 1 ] + aMetrHead[ 1 ] + 1 + ::aMargin[ 3 ] + 3
   ENDIF
   IF EMPTY( ::nFootHeight )
      ::nFootHeight := ::aMargin[ 1 ] + aMetr[ 1 ] + 1 + ::aMargin[ 3 ]
   ENDIF

   ::x1 := aCoors[ 1 ] +  ::nShowMark + ::nDeleteMark
   ::y1 := aCoors[ 2 ] + IIf( ::lDispHead, ::nHeadHeight * ::nHeadRows, 0 )
   ::x2 := aCoors[ 3 ]
   ::y2 := aCoors[ 4 ] // - Iif( ::nFootRows > 0, ::nFootHeight*::nFootRows, 0 )
   ::xAdjRight := ::x2
   IF ::lRepaintBackground
      //FillRect( hDC, ::x1 - ::nDeleteMark, ::y1,  ::x2, ::y2 - ( ::nFootHeight * ::nFootRows ), ::brush:handle )
      FillRect( hDC, ::x1 - ::nDeleteMark, ::y1, ::xAdjRight, ::y2 - ( ::nFootHeight * ::nFootRows ), ::brush:handle )
      ::lRepaintBackground := .F.
   ENDIF

   nRowsFill := ::rowCurrCount

   ::nRecords := Eval( ::bRcou, Self )
   IF ::nCurrent > ::nRecords .AND. ::nRecords > 0
      ::nCurrent := ::nRecords
   ENDIF

// Calculate number of columns visible

   ::nColumns := FLDCOUNT( Self, ::x1 + 2, ::x2 - 2, ::nLeftCol )

// Calculate number of rows the canvas can host
   ::rowCount := Int( ( ::y2 - ::y1 - ( ::nFootRows * ::nFootHeight ) ) / ( ::height + 1 ) )

// nRows: if number of data rows are less than video rows available....
   nRows := Min( ::nRecords, ::rowCount )

   IF ::internal[ 1 ] == 0
      IF ::rowPos != ::internal[ 2 ] .AND. ! ::lAppMode
         Eval( ::bSkip, Self, ::internal[ 2 ] - ::rowPos )
      ENDIF
      ::oParent:lSuspendMsgsHandling := .T.
      IF ::aSelected != Nil .AND. AScan( ::aSelected, { | x | x = Eval( ::bRecno, Self ) } ) > 0
         ::LineOut( ::internal[ 2 ], 0, hDC, ! ::lResizing )
      ELSE
         ::LineOut( ::internal[ 2 ], 0, hDC, .F. )
      ENDIF
      IF ::rowPos != ::internal[ 2 ] .AND. ! ::lAppMode
         Eval( ::bSkip, Self, ::rowPos - ::internal[ 2 ] )
      ENDIF
    ELSEIF ::internal[ 1 ] == 2
    /*
       tmp := Eval( ::bRecno, Self )
       Eval( ::bgoto, Self, ::internal[ 3 ] )
       cursor_row := 1
       DO WHILE .T.
         IF Eval( ::bRecno, Self ) == ::internal[ 4 ]
            EXIT
         ENDIF
         *IF cursor_row > nRows .OR. ( Eval( ::bEof, Self ) .AND. ! ::lAppMode )
         *   EXIT
         *ENDIF
         ::LineOut( cursor_row, 0, hDC, .F. )
         cursor_row ++
         Eval( ::bSkip, Self, 1 )
       ENDDO
       */
       ::HeaderOut( hDC )
       *Eval( ::bGoTo, Self, tmp )

    ELSE
      IF ! ::lAppMode
         //IF Eval( ::bEof, Self ) .OR. Eval( ::bBof, Self )
         IF Eval( ::bEof, Self ) .OR. Eval( ::bBof, Self ) .OR. ::rowPos > ::nRecords
            Eval( ::bGoTop, Self )
            ::rowPos := 1
         ENDIF
      ENDIF
// Se riga_cursore_video > numero_record
//    metto il cursore sull'ultima riga
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF

// Take record number
      tmp := Eval( ::bRecno, Self )

// if riga_cursore_video > 1
//   we skip ::rowPos-1 number of records back,
//   actually positioning video cursor on first line
      IF ::rowPos > 1
        // Eval( ::bSkip, Self, - ( ::rowPos - 1 ) )
      ENDIF
      // new
      IF ::lFilter .AND. ::rowPos > 1 .AND. tmp = ::nFirstRecordFilter
        Eval( ::bSkip, Self,  ( ::rowPos - 1 ) )
        tmp := Eval( ::bRecno, Self )
      ENDIF

// Browse printing is split in two parts
// first part starts from video row 1 and goes to end of data (EOF)
//   or end of video lines

// second part starts from where part 1 stopped -
      // new 01/09/2009 - nando
      //nRecFilter := FltRecNoRelative( Self )
      nRecFilter := 0
      IF ::Type == BRW_DATABASE
         nRecFilter := ( ::Alias )->( RecNo() )
         IF ::lFilter .AND. EMPTY( ::RelationalExpr )
            nRecFilter := ASCAN( ::aRecnoFilter, ( ::Alias )->( RecNo() ) )
         ELSEIF ! Empty( ( ::Alias )->( DBFILTER() ) ) .AND. ( ::Alias )->( RecNo() ) > ::nRecords
            nRecFilter := ::nRecords
         ENDIF
      ENDIF
      IF ::rowCurrCount = 0  .AND. ::nRecords > 0 // INIT
         Eval( ::bSkip, Self, 1 )
         ::rowCurrCount := IIF( Eval( ::bEof, Self ), ::rowCount , IIF( ::nRecords < ::rowCount, ::nRecords,  1 ) )
         nRecFilter := - 1
      ELSEIF ::nRecords < ::rowCount
         ::rowCurrCount := ::nRecords
      ELSEIF ::rowCurrCount >= ::RowPos  .AND. nRecFilter <= ::nRecords
         ::rowCurrCount -= ( ::rowCurrCount - ::RowPos + 1)
      ELSEIF ::rowCurrCount > ::rowCount - 1
         ::rowCurrCount := ::rowCount - 1
      ENDIF
      IF ::rowCurrCount > 0
          Eval( ::bSkip, Self, - ::rowCurrCount )
          IF Eval( ::bBof, Self )
               Eval( ::bGoTop, Self )
          ENDIF
      ENDIF

      cursor_row := 1
      ::oParent:lSuspendMsgsHandling := .T.
      ::internal[ 3 ] := Eval( ::bRecno, Self )
       AEVAL( ::aColumns, {| c | c:aHints := {} } )
      DO WHILE .T.
         // if we are on the current record, set current video line
         IF Eval( ::bRecno, Self ) == tmp
            ::rowPos := cursor_row
         ENDIF

         // exit loop when at last row or eof()
         IF cursor_row > nRows .OR. ( Eval( ::bEof, Self ) .AND. ! ::lAppMode )
            EXIT
         ENDIF

         // decide how to print the video row
         IF ::aSelected != Nil .AND. AScan( ::aSelected, { | x | x = Eval( ::bRecno, Self ) } ) > 0
            ::LineOut( cursor_row, 0, hDC, ! ::lResizing )
         ELSE
            ::LineOut( cursor_row, 0, hDC, .F. )
         ENDIF
         cursor_row ++
         Eval( ::bSkip, Self, 1 )
      ENDDO
      ::internal[ 4 ] := Eval( ::bRecno, Self )
      //::rowCurrCount := cursor_row - 1
      ::rowCurrCount := IIF( cursor_row - 1 < ::rowCurrCount, ::rowCurrCount, cursor_row - 1 )

      // set current_video_line depending on the situation
      IF ::rowPos >= cursor_row
         ::rowPos := IIf( cursor_row > 1, cursor_row - 1, 1 )
      ENDIF

      // print the rest of the browse

      DO WHILE cursor_row <= ::rowCount .AND. ( ::nRecords > nRows .AND. ! Eval( ::bEof, Self ) )
         //IF ::aSelected != Nil .AND. AScan( ::aSelected, { | x | x = Eval( ::bRecno, Self ) } ) > 0
         //   ::LineOut( cursor_row, 0, hDC, .t., .T. )
         //ELSE
            ::LineOut( cursor_row, 0, hDC, .F., .T. )
         //ENDIF
         cursor_row ++
      ENDDO
      IF ::lDispSep .AND. ! Checkbit( ::internal[ 1 ], 1 ) .AND. nRowsFill <= ::rowCurrCount
         ::SeparatorOut( hDC, ::rowCurrCount )
      ENDIF
      nRowsFill := cursor_row - 1
      // fill the remaining canvas area with background color if needed
      nRows := cursor_row - 1
      IF nRows < ::rowCount .or. ( nRows * ( ::height - 1 ) + ::nHeadHeight + ::nFootHeight ) < ::nHeight
       //  FillRect( hDC, ::x1, ::y1 + ( ::height + 1 ) * nRows + 1, ::x2, ::y2, ::brush:handle )
      ENDIF
      Eval( ::bGoTo, Self, tmp )
   ENDIF
   IF ::lAppMode
      ::LineOut( nRows + 1, 0, hDC, .F., .T. )
   ENDIF

   //::LineOut( ::rowPos, Iif( ::lEditable, ::colpos, 0 ), hDC, .T. )

   // Highlights the selected ROW
   // we can have a modality with CELL selection only or ROW selection
   IF ! ::lHeadClick .AND. ! ::lEditable // .AND. ! ::lResizing
      ::LineOut( ::rowPos, 0, hDC, ! ::lResizing )
   ENDIF
   // Highligths the selected cell
   // FP: Reenabled the lEditable check as it's not possible
   //     to move the "cursor cell" if lEditable is FALSE
   //     Actually: if lEditable is FALSE we can only have LINE selection
//   if ::lEditable
   IF lLostFocus == NIL .AND. !::lHeadClick .AND. ::lEditable // .AND. !::lResizing
      ::LineOut( ::rowPos, ::colpos, hDC, ! ::lResizing )
   ENDIF
//   endif

   // if bit-1 refresh header and footer
   ::oParent:lSuspendMsgsHandling := .F.

   IF Checkbit( ::internal[ 1 ], 1 ) .OR. ::lAppMode
      //IF ::lDispSep
         ::SeparatorOut( hDC , nRowsFill  )
      //ENDIF
      IF ::nHeadRows > 0
         ::HeaderOut( hDC )
      ENDIF
      IF ::nFootRows > 0
         ::FooterOut( hDC )
      ENDIF
   ENDIF
   IF ::lAppMode  .AND. ::nRecords != 0 .AND. ::rowPos = ::rowCount
       ::LineOut( ::rowPos, 0 , hDC, .T., .T. )
   ENDIF

   // End paint block
   EndPaint( ::handle, pps )

   ::internal[ 1 ] := 15
   ::internal[ 2 ] := ::rowPos

   // calculate current bRecno()
   tmp := Eval( ::bRecno, Self )
   IF ::recCurr != tmp
      ::recCurr := tmp
      IF ::bPosChanged != Nil
         Eval( ::bPosChanged, Self, ::rowpos )
      ENDIF
   ENDIF

   IF ::lAppMode
      ::Edit()
   ENDIF

   ::lAppMode := .F.

   // fixed postion vertical scroll bar in refresh out browse
   IF GetFocus() != ::handle .OR. nRecFilter = - 1
       Eval( ::bSkip, Self, 1 )
       Eval( ::bSkip, Self, - 1 )
       IF ::bScrollPos != Nil // array
         Eval( ::bScrollPos, Self, 1, .F. )
      ELSE
         VScrollPos( Self, 0, .f. )
      ENDIF
   ENDIF

   RETURN Nil

//----------------------------------------------------//
// TODO: hb_tokenGet() can create problems.... can't have separator as first char
METHOD HeaderOut( hDC ) CLASS HBrowse
   LOCAL x, oldc, fif, xSize, lFixed := .F., xSizeMax
   LOCAL oPen, oldBkColor
   LOCAL oColumn, nLine, cStr, cNWSE, oPenHdr, oPenLight
   LOCAL toldc, oldfont
   LOCAL oBmpSort, nMe, nMd, captionRect := {,,,}, aTxtSize
   LOCAL state, aItemRect

   oldBkColor := SetBkColor( hDC, GetSysColor( COLOR_3DFACE ) )

   IF ::hTheme = Nil
      SelectObject( hDC, oPen64:handle )
      Rectangle( hDC,;
               ::x1 - ::nShowMark - ::nDeleteMark ,;
               ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
               ::x2 , ;
               ::y1   )
   ENDIF
   IF ! ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::bColor )
      SelectObject( hDC, oPen:handle )
   ELSEIF ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::sepColor )
      SelectObject( hDC, oPen:handle )
   ENDIF
   IF ::lSep3d
      oPenLight := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
   ENDIF

   x := ::x1
   IF ::oHeadFont <> Nil
      oldfont := SelectObject( hDC, ::oHeadFont:handle )
   ENDIF
   IF ::headColor <> Nil
      oldc := SetTextColor( hDC, ::headColor )
   ENDIF
   fif := IIf( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[ fif ]
      IF oColumn:headColor <> Nil
         toldc := SetTextColor( hDC, oColumn:headColor )
      ENDIF
      xSize := oColumn:width
      IF ::lAdjRight .and. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      xSizeMax := xSize

      IF ( fif == Len( ::aColumns ) ) .OR. lFixed
         xSizeMax := Max( ::x2 - x, xSize )
         xSize := IiF(::lAdjRight, xSizeMax, xSize)
      ENDIF
      // NANDO
      IF !oColumn:lHide
       IF ::lDispHead .AND. ! ::lAppMode
         IF oColumn:cGrid == nil
          *-  DrawButton( hDC, x - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xSize - 1, ::y1 + 1, 1 )
            IF xsize != xsizeMax
                DrawButton( hDC, x + xsize, ::y1 - ::nHeadHeight * ::nHeadRows, x + xsizeMax , ::y1 + 1, 0 )
            ENDIF
         ELSE
            // Draws a grid to the NWSE coordinate...
          *-  DrawButton( hDC, x - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xSize - 1, ::y1 + 1, 0 )
            IF xSize != xSizeMax
          *-    DrawButton( hDC, x + xsize - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xsizeMax - 1, ::y1 + 1, 0 )
            ENDIF
            IF oPenHdr == nil
               oPenHdr := HPen():Add( BS_SOLID, 1, 0 )
            ENDIF
            SelectObject( hDC, oPenHdr:handle )
            cStr := oColumn:cGrid + ';'
            FOR nLine := 1 TO ::nHeadRows
               #ifdef __XHARBOUR__
               cNWSE := __StrToken( @cStr, nLine, ';' )
               #else
               cNWSE := hb_tokenGet( @cStr, nLine, ';' )
               #endif
               IF At( 'S', cNWSE ) != 0
                  DrawLine( hDC, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ), x + xSize - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) )
               ENDIF
               IF At( 'N', cNWSE ) != 0
                  DrawLine( hDC, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ), x + xSize - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) )
               ENDIF
               IF At( 'E', cNWSE ) != 0
                  DrawLine( hDC, x + xSize - 2, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) + 1, x + xSize - 2, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) )
               ENDIF
               IF At( 'W', cNWSE ) != 0
                  DrawLine( hDC, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) + 1, x - 1, ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) )
               ENDIF
            NEXT
            SelectObject( hDC, oPen:handle )
         ENDIF
         // Prints the column heading - justified
         aItemRect := { x   , ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight - 1, ;
                        x + xSize  , ::y1 + 1  }
         IF ! oColumn:lHeadClick
            state := IIF( ::hTheme != Nil, IIF( ::xPosMouseOver > x .AND. ::xPosMouseOver < x + xsize - 3,;
                                                PBS_HOT, PBS_NORMAL ), PBS_NORMAL )
         ELSE
            state := IIF( ::hTheme != Nil, PBS_PRESSED, 6 )
            InflateRect( @aItemRect, - 1, - 1 )
         ENDIF
         IF ::hTheme != Nil
             hb_DrawThemeBackground( ::hTheme, hDC, BP_PUSHBUTTON, state , aItemRect, Nil )
             SetBkMode( hDC, 1 )
         ELSE
             DrawButton( hDC, x   ,;
                 ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
                 x + xSize   , ;
                 ::y1  , ;
                 state )
         ENDIF
         nMe := IIF( ::ShowSortMark .AND. oColumn:SortMark > 0, IIF( oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_LEFT, 18, 0 ), 0 )
         nMd := IIF( ::ShowSortMark .AND. oColumn:SortMark > 0, IIF( oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  !=  DT_LEFT, 17, 0 ), ;
                                                                IIF( oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE =  DT_RIGHT, 1, 0 ) )
         cStr := oColumn:heading + ';'
         FOR nLine := 1 TO ::nHeadRows
            aTxtSize := IIF( nLine = 1, TxtRect( cStr, Self ), aTxtSize )
            *#ifdef __XHARBOUR__
            * DrawText( hDC, __StrToken( @cStr, nLine, ';' ), ;
            
            DrawText( hDC, hb_tokenGet( @cStr, nLine, ';' ), ;
                      x + ::aMargin[ 4 ] + 1 + nMe, ;
                      ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine + 1 ) +  ::aMargin[ 1 ] + 1, ;
                      x + xSize - ( 2 + ::aMargin[ 2 ] + nMd ) , ;
                      ::y1 - ( ::nHeadHeight ) * ( ::nHeadRows - nLine ) - 1, ;
                      oColumn:nJusHead + IIF( oColumn:lSpandHead, DT_NOCLIP, 0 ) + DT_END_ELLIPSIS, @captionRect )
         NEXT      // Nando DT_VCENTER+DT_SINGLELINE
         IF ::ShowSortMark .AND. oColumn:SortMark > 0
            oBmpSort  :=  IIF( oColumn:SortMark = 1, HBitmap():AddStandard( OBM_UPARROWD ),  HBitmap():AddStandard( OBM_DNARROWD ) )
            captionRect[ 2 ] := ( ::nHeadHeight + 17 ) / 2 - 17
            IF oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_RIGHT .OR. xSize < aTxtSize[ 1 ] + nMd
               DrawTransparentBitmap( hDC, oBmpSort:Handle, captionRect[ 1 ] + ( captionRect[ 3 ] - captionRect[ 1 ]  ) ,captionRect[ 2 ] + 2, , )
            ELSEIF  oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_CENTER
               CaptionRect[ 1 ] := captionRect[ 1 ] + ( captionRect[ 3 ] - captionRect[ 1 ] + aTxtSize[ 1 ] ) / 2  +  ;
                   MIN( ( x + xSize - ( 1 + ::aMargin[ 2 ] ) ) - ( captionRect[ 1 ] + ( captionRect[ 3 ] - captionRect[ 1 ] + aTxtSize[ 1 ] ) / 2   ) - 16, 8 )
               DrawBitmap( hDC, oBmpSort:Handle,, captionRect[ 1 ] - 1 , captionRect[ 2 ]  , , )
            ELSE
               DrawTransparentBitmap( hDC, oBmpSort:Handle, captionRect[ 1 ] - nMe , captionRect[ 2 ] , , )
            ENDIF
         ENDIF
       ENDIF
      ELSE
         xSize := 0
         IF fif = LEN( ::aColumns ) .AND. !lFixed
            fif := hb_RAscan( ::aColumns,{| c | c:lhide = .F. } ) - 1
               //::nPaintCol := nColumn
            x -= ::aColumns[ fif + 1 ]:width
            lFixed := .T.
          ENDIF
      ENDIF
      x += xSize

      IF oColumn:headColor <> Nil
         SetTextColor( hDC, toldc )
      ENDIF
      fif := IIf( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO
   ::xAdjRight := x
   IF ::lShowMark  .OR. ::lDeleteMark
      xSize := ::nShowMark + ::nDeleteMark
      IF ::hTheme != Nil
         hb_DrawThemeBackground( ::hTheme, hDC, BP_PUSHBUTTON, 1, ;
               { ::x1 - xSize - 1 ,::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight - 1, ;
               ::x1 + 1 ,  ::y1 + 1 }, Nil )
      ELSE
         SelectObject( hDC, oPen64:handle )
         Rectangle( hDC, ::x1 - xSize -1, ::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
               ::x1 - 1 , ::y1  )
         DrawButton( hDC, ::x1 - xSize - 0 ,::y1 - ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
               ::x1 - 1,  ::y1, 1 )
      ENDIF
   ENDIF

   IF ::hTheme != Nil
      SelectObject( hDC, oPen64:handle )
      Rectangle( hDC,;
               ::x1 - ::nShowMark - ::nDeleteMark ,;
               ::y1 ,;//- ( ::nHeadHeight * ::nHeadRows ) - ::nyHeight , ;
               ::x2 , ;
               ::y1   )
   ENDIF

   SetBkColor( hDC, oldBkColor )
   IF ::headColor <> Nil
      SetTextColor( hDC, oldc )
   ENDIF
   IF ::oHeadFont <> Nil
      SelectObject( hDC, oldfont )
   ENDIF
   IF ::lResizing .AND. xDragMove > 0
      SelectObject( hDC, oPen64:handle )
      //Rectangle( hDC, xDragMove , 1, xDragMove , 1 + ( ::nheight + 1 )  )
      DrawLine( hDC, xDragMove, 1, xDragMove , ( ::nHeadHeight * ::nHeadRows ) + ::nyHeight + 1 + (::rowCount * ( ::height + 1 + ::aMargin[ 3 ] ) ) )
   ENDIF
   IF ::lDispSep
      DeleteObject( oPen )
      IF oPenHdr != nil
         oPenHdr:Release()
      ENDIF
      IF oPenLight != nil
         oPenLight:Release()
      ENDIF
   ENDIF

   RETURN Nil

//----------------------------------------------------//
METHOD SeparatorOut( hDC, nRowsFill ) CLASS HBrowse
   LOCAL i, x, fif, xSize, lFixed := .F., xSizeMax
   LOCAL bColor
   LOCAL oColumn, oPen, oPenLight, oPenFree

   DEFAULT nRowsFill TO Min( ::nRecords + IIf( ::lAppMode, 1, 0 ), ::rowCount )
   oPen := Nil
   oPenLight := Nil
   oPenFree := Nil

   IF ! ::lDispSep
     // IF oPen == NIL
         oPen := HPen():Add( PS_SOLID, 1, ::bColor )
     // ENDIF
      SelectObject( hDC, oPen:handle )
   ELSEIF ::lDispSep
     // IF oPen == NIL
         oPen := HPen():Add( PS_SOLID, 1, ::sepColor )
     // ENDIF
      SelectObject( hDC, oPen:handle )
   ENDIF
   IF ::lSep3d
      IF oPenLight == NIL
         oPenLight := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      ENDIF
   ENDIF

   x := ::x1 //- IIF( ::lShowMark .AND. ! ::lDeleteMark , 1, 0 )
   fif := IIf( ::freeze > 0, 1, ::nLeftCol )
   FillRect( hDC, ::x1 - ::nShowMark - ::nDeleteMark - 1 , ::y1 + ( ::height + 1 ) * nRowsfill + 1, ::x2 , ::y2 - ( ::nFootHeight * ::nFootRows ) , ::brush:handle )
   // SEPARATOR HORIZONT
   FOR i := 1 TO nRowsFill
      DrawLine( hDC, ::x1 - ::nDeleteMark, ::y1 + ( ::height + 1 ) * i, IIf( ::lAdjRight, ::x2, ::x2 ), ::y1 + ( ::height + 1 ) * i )
   NEXT
   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[ fif ]
      xSize := oColumn:width
      //IF (::lAdjRight .and. fif == Len( ::aColumns ) ).or. lFixed
      IF ( fif == Len( ::aColumns ) ) .OR. lFixed
         xSizeMax := Max( ::x2 - x, xSize ) - 1
         xSize := IIF( ::lAdjRight, xSizeMax, xSize )
      ENDIF
      IF ! oColumn:lHide
        IF ::lDispSep .AND. x > ::x1
           IF ::lSep3d
              SelectObject( hDC, oPenLight:handle )
              //DrawLine( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * nRows )
              DrawLine( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
              SelectObject( hDC, oPen:handle )
              DrawLine( hDC, x - 2, ::y1 + 1, x - 2, ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
              //DrawLine( hDC, x - 2, ::y1 + 1, x - 2, ::y1 + ( ::height + 1 ) * nRows )
           ELSE
               SelectObject( hDC, oPen:handle )
               DrawLine( hDC, x - 1 , ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
               //DrawLine( hDC, x - 0, ::y1 + 1, x - 0, ::y1 + ( ::height + 1 ) * nRows )
           ENDIF
        ELSE
           // SEPARATOR VERTICAL
           IF ! ::lDispSep .AND. ( oColumn:bColorBlock != Nil .OR. oColumn:bColor != Nil )
              bColor := IIF( oColumn:bColorBlock != Nil ,( Eval( oColumn:bColorBlock, ::FLDSTR( Self, fif ), fif, Self ) )[ 2 ], oColumn:bColor )
              IF bColor != Nil
                 // horizontal
                 SelectObject( hDC, HPen():Add( PS_SOLID, 1, bColor ):handle )
                 FOR i := 1 TO nRowsFill
                    DrawLine( hDC, x, ::y1 + ( ::height + 1 ) * i, x + xsize, ::y1 + ( ::height + 1 ) * i )
                 NEXT
              ENDIF
           ENDIF
           IF x > ::x1 - IIF( ::lDeleteMark , 1, 0 )
              SelectObject( hDC, oPen:handle )
              DrawLine( hDC, x - 1, ::y1 + 1, x - 1, ::y1 + ( ::height + 1 ) * nRowsFill )
           ENDIF
        ENDIF
      ELSE
         xSize := 0
         IF fif = LEN( ::aColumns ) .AND. !lFixed
            fif := hb_RAscan( ::aColumns,{|c| c:lhide = .F.}) - 1
            x -= ::aColumns[ fif + 1 ]:width
            lFixed := .T.
         ENDIF
      ENDIF
      x += xSize //+ IIF( ::lShowMark .AND. x < ::x1, 1, 0 )

      fif := IIf( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO
   //  SEPARATOR HORIZONT
    SelectObject( hDC, oPen:handle )
    IF ! ::lAdjRight
       DrawLine( hDC, x - 1, ::y1 - ( ::height * ::nHeadRows ), x - 1, ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
       //DrawLine( hDC, ::x2 - 1, ::y1 - ( ::height * ::nHeadRows ), ::x2 - 1, ::y1 + ( ::height + 1 ) * ( nRows ) )
    ELSE
       DrawLine( hDC, x, ::y1 - ( ::height * ::nHeadRows ), x , ::y1 + ( ::height + 1 ) * ( nRowsFill ) )
    ENDIF
    /*
   //IF ::lDispSep
      FOR i := 1 TO nRows
         DrawLine( hDC, ::x1, ::y1 + ( ::height + 1 ) * i, IIf( ::lAdjRight, ::x2, x ), ::y1 + ( ::height + 1 ) * i )
      NEXT
   //ENDIF
   */
   IF ::lDispSep
      DeleteObject( oPen )
      IF oPenLight != nil
         oPenLight:Release()
      ENDIF
   ENDIF

   RETURN Nil

//----------------------------------------------------//
METHOD FooterOut( hDC ) CLASS HBrowse
   LOCAL x, fif, xSize, oPen, nLine, cStr
   LOCAL oColumn, aColorFoot, oldBkColor, oldTColor, oBrush
   LOCAL nPixelFooterHeight, nY, lFixed := .F.
   LOCAL lColumnFont := .F. , nMl, aItemRect

   nMl := IIF( ::lShowMark, ::nShowMark, 0 )+ IIF( ::lDeleteMark,  ::nDeleteMark, 0 )
   IF ! ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::bColor )
      SelectObject( hDC, oPen:handle )
   ELSEIF ::lDispSep
      oPen := HPen():Add( PS_SOLID, 1, ::sepColor )
      SelectObject( hDC, oPen:handle )
   ENDIF

   x := ::x1
   fif := IIf( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[ fif ]
      xSize := oColumn:width
      IF ::lAdjRight .and. fif == Len( ::aColumns ) .OR. lFixed
         xSize := Max( ::x2 - x, xSize )
      ENDIF
     IF ! oColumn:lHide
        cStr := oColumn:footing + ';'
        aColorFoot := Nil
        IF oColumn:bColorFoot != Nil
           aColorFoot := Eval( oColumn:bColorFoot, Self )
           oldBkColor := SetBkColor(   hDC, aColorFoot[ 2 ] )
           oldTColor  := SetTextColor( hDC, aColorFoot[ 1 ] )
           oBrush := HBrush():Add( aColorFoot[ 2 ] )
        ELSE
           //oBrush := ::brush
           oBrush := nil
        ENDIF

        IF oColumn:FootFont != Nil
           SelectObject( hDC, oColumn:FootFont:Handle )
           lColumnFont := .T.
        ELSEIF lColumnFont
           SelectObject( hDC, ::ofont:handle )
           lColumnFont := .F.
        ENDIF

        nPixelFooterHeight := ( ::nFootRows ) * ( ::nFootHeight + 1 )

        IF ::lDispSep
           IF ::hTheme != Nil
              aItemRect := {  x, ::y2 - nPixelFooterHeight , x + xsize, ::y2 + 1 }
              hb_DrawThemeBackground( ::hTheme, hDC, PBS_NORMAL , 0 , aItemRect, Nil )
              SetBkMode( hDC, 1 )
           ELSE
              DrawButton( hDC, x, ::y2 - nPixelFooterHeight, x + xsize, ::y2 , 0 )
              DrawLine( hDC, x, ::y2, x + xSize, ::y2 )
           ENDIF
        ELSE
           IF ::hTheme != Nil
              aItemRect := {  x, ::y2 - nPixelFooterHeight , x + xsize + 1, ::y2 + 1 }
              hb_DrawThemeBackground( ::hTheme, hDC, PBS_NORMAL , 0 , aItemRect, Nil )
              SetBkMode( hDC, 1 )
           ELSE
              DrawButton( hDC, x, ::y2 - nPixelFooterHeight, x + xsize + 1, ::y2 + 1 , 0 )
           ENDIF
        ENDIF

        IF oBrush != Nil
           FillRect( hDC, x, ::y2 - nPixelFooterHeight + 1,  ;
                x + xSize - 1, ::y2, oBrush:handle )
        ELSE
           oldBkColor := SetBkColor( hDC, GetSysColor( COLOR_3DFACE ) )
        ENDIF

        nY := ::y2 - nPixelFooterHeight

        FOR nLine := 1 TO ::nFootRows
            //#ifdef __XHARBOUR__
            //DrawText( hDC, __StrToken( @cStr, nLine, ';' ), ;

            DrawText( hDC, hb_tokenGet( @cStr, nLine, ';' ), ;
                   x + ::aMargin[ 4 ], ;
                   nY + ( nLine - 1 ) * ( ::nFootHeight + 1 ) + 1 + ::aMargin[ 1 ], ;
                   x + xSize - ( 1 + ::aMargin[ 2 ] ), ;
                   nY + ( nLine ) * ( ::nFootHeight + 1 ), ;
                   oColumn:nJusFoot + IIF( oColumn:lSpandFoot, DT_NOCLIP, 0 ) )
        NEXT   // nando DT_VCENTER + DT_SINGLELINE

        IF aColorFoot != Nil
           SetBkColor(   hDC, oldBkColor )
           SetTextColor( hDC, oldTColor )
           oBrush:release()
        ENDIF
// Draw footer separator
        IF ::lDispSep .AND. x >= ::x1
           DrawLine( hDC, x + xSize - 1, nY + 3, x + xSize - 1, ::y2 - 4 )
        ENDIF
      ELSE
         xSize := 0
         IF fif = LEN( ::aColumns ) .AND. !lFixed
            fif := hb_RASCAN( ::aColumns, { | c | c:lhide = .F. } ) - 1
            x -= ::aColumns[ fif + 1 ]:width
            lFixed := .T.
         ENDIF
      ENDIF
      x += xSize
      fif := IIf( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         EXIT
      ENDIF
   ENDDO

   IF ::lDispSep
      //DrawLine( hDC, ::x1, nY, IIf( ::lAdjRight, ::x2, x ), nY )
      //DrawLine( hDC, ::x1, nY + 1, IIf( ::lAdjRight, ::x2, x ), nY + 1 )
      IF HWG_BITAND( ::style, WS_HSCROLL ) != 0
          DrawLine( hDC, ::x1 , ::y2 - 1, IIF( ::lAdjRight, ::x2, x ), ::y2 - 1 )
      ENDIF
      oPen:Release()
   ENDIF
   IF nMl > 0
      SelectObject( hDC, oPen64:handle )
      xSize := nMl
      IF ::hTheme != Nil
         aItemRect := {  ::x1 - xSize ,nY , ::x1 - 1,  ::y2 + 1 }
         hb_DrawThemeBackground( ::hTheme, hDC, BP_PUSHBUTTON, 0 , aItemRect, Nil )
      ELSE
        DrawButton( hDC, ::x1 - xSize ,nY  , ;
               ::x1 - 1,  ::y2, 1 )
      ENDIF
   ENDIF
   IF lColumnFont
       SelectObject( hDC, ::oFont:Handle )
   ENDIF

   RETURN Nil

//-------------- -Row--  --Col-- ------------------------------//
METHOD LineOut( nRow, nCol, hDC, lSelected, lClear ) CLASS HBrowse
   LOCAL x, nColumn, sviv, xSize, lFixed := .F., xSizeMax
   LOCAL j, ob, bw, bh, y1, hBReal
   LOCAL oldBkColor, oldTColor, oldBk1Color, oldT1Color
   LOCAL oLineBrush :=  IIf( nCol >= 1, HBrush():Add( ::htbColor ), IIf( lSelected, ::brushSel, ::brush ) )
   LOCAL lColumnFont := .F.
   LOCAL rcBitmap, ncheck, nstate, nCheckHeight

//Local nPaintCol, nPaintRow
   LOCAL aCores

   nColumn := 1
   x := ::x1
   IF lClear == Nil ; lClear := .F. ; ENDIF

   IF ::bLineOut != Nil
      Eval( ::bLineOut, Self, lSelected )
   ENDIF
   IF ::nRecords > 0 .OR. lClear
      oldBkColor := SetBkColor(   hDC, IIf( nCol >= 1, ::htbcolor, IIf( lSelected, ::bcolorSel, ::bcolor ) ) )
      oldTColor  := SetTextColor( hDC, IIf( nCol >= 1, ::httcolor, IIf( lSelected, ::tcolorSel, ::tcolor ) ) )
      ::nPaintCol  := IIf( ::freeze > 0, 1, ::nLeftCol )
      ::nPaintRow  := nRow
      IF ::lDeleteMark
         FillRect( hDC, ::x1 - ::nDeleteMark - 0, ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 , ;
                        ::x1 - 1 , ::y1 + ( ::height + 1 ) * ::nPaintRow , IIF( Deleted(), GetStockObject( 7 ), GetStockObject( 0 ))) //::brush:handle ))
      ENDIF
      IF ::lShowMark
         IF ::hTheme != Nil
             hb_DrawThemeBackground( ::hTheme, hDC, BP_PUSHBUTTON, IIF( lSelected, PBS_VERTICAL,  PBS_VERTICAL ), ;
                      { ::x1 - ::nShowMark - ::nDeleteMark - 1,;
                        ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1  , ;
                        ::x1 - ::nDeleteMark   ,;
                        ::y1 + ( ::height + 1 ) * ::nPaintRow + 1 }  , nil )
          ELSE
             DrawButton( hDC, ::x1 - ::nShowMark - ::nDeleteMark - 0,;
                         ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1  , ;
                         ::x1 - ::nDeleteMark - 1  ,; //IIF( ::lDeleteMark, -1, -2 ),  ;
                         ::y1 + ( ::height + 1 ) * ::nPaintRow + 1, 1 )
             SelectObject( hDC, oPen64:handle )
             Rectangle( hDC, ::x1 - ::nShowMark - ::nDeleteMark - 1 , ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 )  , ;
                        ::x1  - ::nDeleteMark - 1 , ::y1 + ( ::height + 1 ) * ::nPaintRow - 0 ) //, IIF( Deleted(), GetStockObject( 7 ), ::brush:handle ))
          ENDIF
          IF lSelected
              DrawTransparentBitmap( hDC, ::oBmpMark:Handle, ::x1 - ::nShowMark - ::nDeleteMark + 1,;
                          ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) ) + ;
                          ( ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow  ) ) - ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) ) ) / 2 - 6 )
          ENDIF
      ENDIF
      ::nVisibleColLeft :=  ::nPaintCol
      WHILE x < ::x2 - 2
         // if bColorBlock defined get the colors
         //IF ::aColumns[ ::nPaintCol ]:bColorBlock != Nil
         aCores := {}
         IF ( nCol == 0 .OR. nCol == nColumn ) .AND. ::aColumns[ ::nPaintCol ]:bColorBlock != Nil .AND. ! lClear
            // nando
            aCores := Eval( ::aColumns[ ::nPaintCol ]:bColorBlock, ::FLDSTR( Self, ::nPaintCol ), ::nPaintCol, Self )
            IF lSelected
               ::aColumns[ ::nPaintCol ]:tColor := IIF( aCores[ 3 ] != Nil, aCores[ 3 ], ::tcolorSel )
               ::aColumns[ ::nPaintCol ]:bColor := IIF( aCores[ 4 ] != Nil, aCores[ 4 ], ::bcolorSel )
            ELSE
               ::aColumns[ ::nPaintCol ]:tColor := IIF( aCores[ 1 ] != Nil, aCores[ 1 ], ::tcolor )
               ::aColumns[ ::nPaintCol ]:bColor := IIF( aCores[ 2 ] != Nil, aCores[ 2 ], ::bcolor )
            ENDIF
            ::aColumns[ ::nPaintCol ]:brush := HBrush():Add( ::aColumns[ ::nPaintCol ]:bColor )
         ELSE
            ::aColumns[ ::nPaintCol ]:brush := Nil
         ENDIF
         xSize := ::aColumns[ ::nPaintCol ]:width
         xSizeMax := xSize
         IF ( ::nPaintCol == Len( ::aColumns ) ) .OR. lFixed
            xSizeMax := Max( ::x2 - x, xSize )
            xSize := IiF(::lAdjRight, xSizeMax, xSize)
            ::nWidthColRight := xSize
         ENDIF
         IF !::aColumns[ ::nPaintCol ]:lHide
           IF nCol == 0 .OR. nCol == nColumn
              hBReal := oLineBrush:handle
              IF ! lClear
                IF ::aColumns[ ::nPaintCol ]:bColor != Nil .AND. ::aColumns[ ::nPaintCol ]:brush == Nil
                   ::aColumns[ ::nPaintCol ]:brush := HBrush():Add( ::aColumns[ ::nPaintCol ]:bColor )
                ENDIF
                //hBReal := IIf( ::aColumns[ ::nPaintCol ]:brush != Nil .AND. ( ::nPaintCol != ::colPos .OR. ! lSelected ), ;
                hBReal := IIf( ::aColumns[ ::nPaintCol ]:brush != Nil .AND. !( lSelected .AND. EMPTY( aCores ) ),;
                           ::aColumns[ ::nPaintCol ]:brush:handle, oLineBrush:handle )
              ENDIF
             // Fill background color of a cell
             FillRect( hDC, x, ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1, ;
                      x + xSize - IIf( ::lSep3d, 2, 1 ), ::y1 + ( ::height + 1 ) * ::nPaintRow, hBReal )
             IF xSize != xSizeMax
                FillRect( hDC, x + xsize, ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 , ;
                       x + xSizeMax - IIF( ::lSep3d, 2, 1 ) , ::y1 + ( ::height + 1 ) * ::nPaintRow, ::brush:handle )
             ENDIF
             IF ! lClear
               IF ::aColumns[ ::nPaintCol ]:aBitmaps != Nil .AND. ! Empty( ::aColumns[ ::nPaintCol ]:aBitmaps )
                  FOR j := 1 TO Len( ::aColumns[ ::nPaintCol ]:aBitmaps )
                     IF Eval( ::aColumns[ ::nPaintCol ]:aBitmaps[ j, 1 ], Eval( ::aColumns[ ::nPaintCol ]:block,, Self, ::nPaintCol ), lSelected )
                        ob := ::aColumns[ ::nPaintCol ]:aBitmaps[ j, 2 ]
                        IF ob:nHeight > ::height
                           y1 := 0
                           bh := ::height
                           bw := Int( ob:nWidth * ( ob:nHeight / ::height ) )
                           DrawBitmap( hDC, ob:handle,, x + ( Int( ::aColumns[ ::nPaintCol ]:width - ob:nWidth ) / 2 ), y1 + ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1, bw, bh )
                        ELSE
                           y1 := Int( ( ::height - ob:nHeight ) / 2 )
                           DrawTransparentBitmap( hDC, ob:handle, x + ( Int( ::aColumns[ ::nPaintCol ]:width - ob:nWidth ) / 2 ), y1 + ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 )
                        ENDIF
                        EXIT
                     ENDIF
                  NEXT
               ELSE
                  sviv := ::FLDSTR( Self, ::nPaintCol )
                  // new nando
                  IF ::aColumns[ ::nPaintCol ]:type = "L"
                     ncheck := IIF( sviv = "T", 1, 0 ) + 1
                     rcBitmap := { x + ::aMargin[ 4 ] + 1, ;
                               ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 + ::aMargin[ 1 ], ;
                               0, 0 }
                     nCheckHeight := ( ::y1 + ( ::height + 1 ) * ::nPaintRow  ) - ( ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) ) - ::aMargin[ 1 ] - ::aMargin[ 3 ] - 1
                     nCheckHeight := IIF( nCheckHeight > 16, 16, nCheckHeight )
                     IF Hwg_BitAND( ::aColumns[ ::nPaintCol ]:nJusLin, DT_CENTER ) != 0
                        rcBitmap[ 1 ] := rcBitmap[ 1 ] + (  xsize - ::aMargin[ 2 ] - ::aMargin[ 4 ] - nCheckHeight + 1 ) / 2
                     ENDIF
                     rcBitmap[ 4 ] := ::y1 + ( ::height + 1 ) * ::nPaintRow - ( 1 + ::aMargin[ 3 ] )
                     rcBitmap[ 2 ] := rcBitmap[ 2 ] + ( ( rcBitmap[ 4 ] -  rcBitmap[ 2 ] )  -  nCheckHeight + 1 ) / 2
                     rcBitmap[ 3 ] := rcBitmap[ 1 ] + nCheckHeight
                     rcBitmap[ 4 ] := rcBitmap[ 2 ] + nCheckHeight
                     IF ( nCheck > 0 )
                        nState := DFCS_BUTTONCHECK
                        IF ( nCheck > 1 )
                           nState := hwg_bitor( nstate, DFCS_CHECKED )
                        ENDIF
                        nState += IIF( ::lEditable .OR. ::aColumns[ ::nPaintCol ]:lEditable, 0, DFCS_INACTIVE )
                        DrawFrameControl( hDC, rcBitmap, DFC_BUTTON , nState + DFCS_FLAT  )
                     ENDIF
                     sviv := ""
                  ENDIF
                  // Ahora lineas Justificadas !!
                  IF ::aColumns[ ::nPaintCol ]:tColor != Nil //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                     oldT1Color := SetTextColor( hDC, ::aColumns[ ::nPaintCol ]:tColor )
                  ENDIF
                  IF ::aColumns[ ::nPaintCol ]:bColor != Nil //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                     oldBk1Color := SetBkColor( hDC, ::aColumns[ ::nPaintCol ]:bColor )
                  ENDIF
                  IF ::aColumns[ ::nPaintCol ]:oFont != Nil
                     SelectObject( hDC, ::aColumns[ ::nPaintCol ]:oFont:handle )
                     lColumnFont := .T.
                  ELSEIF lColumnFont
                     SelectObject( hDC, ::ofont:handle )
                     lColumnFont := .F.
                  ENDIF
                  IF ::aColumns[ ::nPaintCol ]:Hint
                      AADD( ::aColumns[ ::nPaintCol ]:aHints, sViv )
                  ENDIF  
                  DrawText( hDC, sviv,  ;
                            x + ::aMargin[ 4 ] + 1, ;
                            ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 + ::aMargin[ 1 ] , ;
                            x + xSize - ( 2 + ::aMargin[ 2 ] ) , ;
                            ::y1 + ( ::height + 1 ) * ::nPaintRow - ( 1 + ::aMargin[ 3 ] ) , ;
                            ::aColumns[ ::nPaintCol ]:nJusLin + DT_NOPREFIX )

// Clipping rectangle
                  #if 0
                     rectangle( hDC, ;
                                x + ::aMargin[ 4 ], ;
                                ::y1 + ( ::height + 1 ) * ( ::nPaintRow - 1 ) + 1 + ::aMargin[ 1 ] , ;
                                x + xSize - ( 2 + ::aMargin[ 2 ] ) , ;
                                ::y1 + ( ::height + 1 ) * ::nPaintRow - ( 1 + ::aMargin[ 3 ] ) ;
                              )
                  #endif

                  IF ::aColumns[ ::nPaintCol ]:tColor != Nil //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                     SetTextColor( hDC, oldT1Color )
                  ENDIF

                  IF ::aColumns[ ::nPaintCol ]:bColor != Nil //.AND. ( ::nPaintCol != ::colPos .OR. ! lSelected )
                     SetBkColor( hDC, oldBk1Color )
                  ENDIF
                ENDIF
              ENDIF
           ENDIF
         ELSE
            xSize := 0
            IF nCol > 0 .AND. lSelected .AND. nCol = nColumn
               nCol ++
            ENDIF
            IF nColumn = LEN(::aColumns) .AND. !lFixed
               nColumn := hb_RAscan( ::aColumns, {| c | c:lhide = .F. } ) - 1
               ::nPaintCol := nColumn
               x -= ::aColumns[ ::nPaintCol + 1 ]:width
               lFixed := .T.
            ENDIF
         ENDIF
         x += xSize
         ::nPaintCol := IIF( ::nPaintCol == ::freeze, ::nLeftCol, ::nPaintCol + 1 )
         nColumn ++
         IF ! ::lAdjRight .and. ::nPaintCol > Len( ::aColumns )
            EXIT
         ENDIF
      ENDDO

// Fill the browse canvas from x+::width to ::x2-2
// when all columns width less than canvas width (lAdjRight == .F.)
/*
      IF ! ::lAdjRight .and. ::nPaintCol == Len( ::aColumns ) + 1
         xSize := Max( ::x2 - x, xSizeMax )

         xSize := Max( ::x2 - x, xSize )
         FillRect( hDC, x, 0, ;
                   x + xSize - IIf( ::lSep3d, 2, 1 ), ::y2, oLineBrush )

      ENDIF
*/
      SetTextColor( hDC, oldTColor )
      SetBkColor( hDC, oldBkColor )
      IF lColumnFont
         SelectObject( hDC, ::ofont:handle )
      ENDIF
   ENDIF
   RETURN Nil


//----------------------------------------------------//
METHOD SetColumn( nCol ) CLASS HBrowse
   LOCAL nColPos, lPaint := .f.

   IF ::lEditable .OR. ::lAutoEdit
      IF nCol != nil .AND. nCol >= 1 .AND. nCol <= Len( ::aColumns )
         IF nCol <= ::freeze
            ::colpos := nCol
         ELSEIF nCol >= ::nLeftCol .AND. nCol <= ::nLeftCol + ::nColumns - ::freeze - 1
            ::colpos := nCol - ::nLeftCol + ::freeze + 1
         ELSE
            ::nLeftCol := nCol
            ::colpos := ::freeze + 1
            lPaint := .T.
         ENDIF
         IF ! lPaint
            ::RefreshLine()
         ELSE
            RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
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


//----------------------------------------------------//
STATIC FUNCTION LINERIGHT( oBrw )
   LOCAL i

   IF oBrw:lEditable .OR. oBrw:lAutoEdit
      IF oBrw:colpos < oBrw:nColumns
         oBrw:colpos ++
         RETURN Nil
      ENDIF
   ENDIF
   IF oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len( oBrw:aColumns ) .AND. ;
       oBrw:nLeftCol < Len( oBrw:aColumns )
      i := oBrw:nLeftCol + oBrw:nColumns
      DO WHILE oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len( oBrw:aColumns ) .AND. oBrw:nLeftCol + oBrw:nColumns = i
         oBrw:nLeftCol ++
      ENDDO
      oBrw:colpos := i - oBrw:nLeftCol + 1
   ENDIF
   RETURN Nil

//----------------------------------------------------//
// Move the visible browse one step to the left
STATIC FUNCTION LINELEFT( oBrw )

   IF oBrw:lEditable .OR. oBrw:lAutoEdit
      oBrw:colpos --
   ENDIF
   IF oBrw:nLeftCol > oBrw:freeze + 1 .AND. ( ! oBrw:lEditable .OR. oBrw:colpos < oBrw:freeze + 1 )
      oBrw:nLeftCol --
      IF ! oBrw:lEditable .OR. oBrw:colpos < oBrw:freeze + 1
         oBrw:colpos := oBrw:freeze + 1
      ENDIF
   ENDIF
   IF oBrw:colpos < 1
      oBrw:colpos := 1
   ENDIF
   RETURN Nil

//----------------------------------------------------//
METHOD DoVScroll( wParam ) CLASS HBrowse
   LOCAL nScrollCode := LOWORD( wParam )

   IF nScrollCode == SB_LINEDOWN
      ::LINEDOWN( .T. )
   ELSEIF nScrollCode == SB_LINEUP
      ::LINEUP()
   ELSEIF nScrollCode == SB_BOTTOM
      ::BOTTOM()
   ELSEIF nScrollCode == SB_TOP
      ::TOP()
   ELSEIF nScrollCode == SB_PAGEDOWN
      ::PAGEDOWN()
   ELSEIF nScrollCode == SB_PAGEUP
      ::PAGEUP()

   ELSEIF nScrollCode == SB_THUMBPOSITION .OR. nScrollCode == SB_THUMBTRACK
      ::SetFocus()
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, nScrollCode, .F., HIWORD( wParam ) )
      ELSE
         IF ( ::Alias ) -> ( IndexOrd() ) == 0              // sk
            ( ::Alias ) -> ( DBGoTo( HIWORD( wParam ) ) )   // sk
         ELSE
            ( ::Alias ) ->( OrdKeyGoTo( HIWORD( wParam ) ) ) // sk
         ENDIF
         Eval( ::bSkip, Self, 1 )
         Eval( ::bSkip, Self, - 1 )
         VScrollPos( Self, 0, .f. )
         ::refresh()
      ENDIF
   ENDIF
   RETURN 0


//----------------------------------------------------//
METHOD DoHScroll( wParam ) CLASS HBrowse
   LOCAL nScrollCode := LOWORD( wParam )
   LOCAL nPos
   LOCAL oldLeft := ::nLeftCol, nLeftCol, colpos, oldPos := ::colpos

   IF ! ::ChangeRowCol( 2 )
      RETURN .F.
   ENDIF

   IF nScrollCode == SB_LINELEFT .OR. nScrollCode == SB_PAGELEFT
      LineLeft( Self )

   ELSEIF nScrollCode == SB_LINERIGHT .OR. nScrollCode == SB_PAGERIGHT
      LineRight( Self )

   ELSEIF nScrollCode == SB_LEFT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineLeft( Self )
      ENDDO
   ELSEIF nScrollCode == SB_RIGHT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineRight( Self )
      ENDDO
   ELSEIF nScrollCode == SB_THUMBTRACK .OR. nScrollCode == SB_THUMBPOSITION
      ::SetFocus()
      IF ::lEditable
         SetScrollRange( ::handle, SB_HORZ, 1, Len( ::aColumns ) )
         SetScrollPos( ::handle, SB_HORZ, HIWORD( wParam ) )
         ::SetColumn( HIWORD( wParam ) )
      ELSE
         IF HIWORD( wParam ) > ( ::colpos + ::nLeftCol - 1 )
            LineRight( Self )
         ENDIF
         IF HIWORD( wParam ) < ( ::colpos + ::nLeftCol - 1 )
            LineLeft( Self )
         ENDIF
      ENDIF
   ENDIF

   IF ::nLeftCol != oldLeft .OR. ::colpos != oldPos
      IF HWG_BITAND( ::style, WS_HSCROLL ) != 0
         SetScrollRange( ::handle, SB_HORZ, 1, Len( ::aColumns ) )
         nPos :=  ::colpos + ::nLeftCol - 1
         SetScrollPos( ::handle, SB_HORZ, nPos )
      ENDIF
      // TODO: here I force a full repaint and HSCROLL appears...
      //       but we should do more checks....
      // IF ::nLeftCol == oldLeft
      //   ::RefreshLine()
      //ELSE
      IF ::nLeftCol != ::nVisibleColLeft
         RedrawWindow( ::handle, RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw
      ELSE
         ::RefreshLine()
      ENDIF

   ENDIF
   ::SetFocus()

   RETURN Nil

//----------------------------------------------------//
METHOD LINEDOWN( lMouse ) CLASS HBrowse

   Eval( ::bSkip, Self, 1 )
   IF Eval( ::bEof, Self )
      //Eval( ::bSkip, Self, - 1 )
      IF ::lAppable .AND. ( lMouse == Nil.OR. ! lMouse )
         ::lAppMode := .T.
      ELSE
         Eval( ::bSkip, Self, - 1 )
         ::SetFocus()
         RETURN Nil
      ENDIF
   ENDIF
   ::rowPos ++
   IF ::rowPos > ::rowCount
      ::rowPos := ::rowCount
      //FP InvalidateRect( ::handle, 0 )
      //::Refresh()
      ::Refresh( .F. )  //::nFootRows > 0 )
      ::internal[ 1 ] := 14
   ELSE
      ::internal[ 1 ] := 0
   ENDIF
   //::internal[ 1 ] := 14 //0
   /*
   nUpper := ::y1  +  ( ::height + 1 ) * ( ::rowPos - 2 )
   nLower := ::y1 + ( ::height + 1 ) * ( ::rowPos )
   InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, nUpper, ::x2, nLower )
   */
   InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] - ::height, ::xAdjRight, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] )
   InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::xAdjRight , ::y1 + ( ::height + 1 ) * ::rowPos )

   //ENDIF
   IF ::lAppMode
      IF ::RowCurrCount < ::RowCount
         Eval( ::bSkip, Self, - 1 )
      ENDIF
      IF ::rowPos > 1
         ::rowPos --
      ENDIF
      ::colPos := ::nLeftCol := 1
   ENDIF
   IF ! ::lAppMode  .OR. ::nLeftCol == 1
      ::internal[ 1 ] := SetBit( ::internal[ 1 ], 1, 0 )
   ENDIF

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, 1, .F. )
   ELSEIF ::nRecords > 1
      VScrollPos( Self, 0, .f. )
   ENDIF

  // ::SetFocus()  ??

   RETURN Nil

//----------------------------------------------------//
METHOD LINEUP() CLASS HBrowse

   Eval( ::bSkip, Self, - 1 )
   IF Eval( ::bBof, Self )
      Eval( ::bGoTop, Self )
   ELSE
      ::rowPos --
      IF ::rowPos = 0  // needs scroll
         ::rowPos := 1
         // InvalidateRect( ::handle, 0 )
         ::Refresh( .F., .T. )
         ::internal[ 1 ] := 14
      ELSE
         ::internal[ 1 ] := 0
      ENDIF
      //::internal[ 1 ] := 14 //0
      InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] - ::height, ::xAdjRight, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] )
      InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::xAdjRight , ::y1 + ( ::height + 1 ) * ::rowPos )
      //ENDIF
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, - 1, .F. )
      ELSEIF ::nRecords > 1
         VScrollPos( Self, 0, .f. )
      ENDIF
      ::internal[ 1 ] := SetBit( ::internal[ 1 ], 1, 0 )
   ENDIF
  // ::SetFocus() ??
   RETURN Nil

//----------------------------------------------------//
METHOD PAGEUP() CLASS HBrowse
   LOCAL STEP, lBof := .F.

   IF ::rowPos > 1
      STEP := ( ::rowPos - 1 )
      Eval( ::bSKip, Self, - STEP )
      ::rowPos := 1
   ELSE
      STEP := ::rowCurrCount    // Min( ::nRecords,::rowCount )
      Eval( ::bSkip, Self, - STEP )
      IF Eval( ::bBof, Self )
         Eval( ::bGoTop, Self )
         lBof := .T.
      ENDIF
   ENDIF

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, - STEP, lBof )
   ELSEIF ::nRecords > 1
      VScrollPos( Self, 0, .f. )
   ENDIF

   ::Refresh( ::nFootRows > 0 )
  //  ::SetFocus() ??
   RETURN Nil

//----------------------------------------------------//
/**
 *
 * If cursor is in the last visible line, skip one page
 * If cursor in not in the last line, go to the last
 *
*/
METHOD PAGEDOWN() CLASS HBrowse
   LOCAL nRows := ::rowCurrCount
   LOCAL STEP := IIf( nRows > ::rowPos, nRows - ::rowPos + 1, nRows )

   Eval( ::bSkip, Self, STEP )

   IF Eval( ::bEof, Self )
      Eval( ::bSkip, Self, - 1 )
   ENDIF
   ::rowPos := Min( ::nRecords, nRows )

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, STEP, .f. )
   ELSE
      VScrollPos( Self, 0, .f. )
   ENDIF

   ::Refresh( ::nFootRows > 0 )
   // ::SetFocus() ???

   RETURN Nil

//----------------------------------------------------//
METHOD BOTTOM( lPaint ) CLASS HBrowse

   IF ::Type == BRW_ARRAY
      ::nCurrent := ::nRecords
      ::rowPos := IIF( ::rowCurrCount <= ::rowCount, ::rowCurrCount , ::rowCount + 1 )
   ELSE
      //::rowPos := LastRec()
      ::rowPos := IIF( ::rowCurrCount <= ::rowCount, ::rowCurrCount , ::rowCount + 1 )
      Eval( ::bGoBot, Self )
   ENDIF

   VScrollPos( Self, 0, IIF( ::Type == BRW_ARRAY, .f., .T. ) )

   IF lPaint == Nil .OR. lPaint
      ::Refresh( ::nFootRows > 0 )
      ::SetFocus( )
   ELSE
      InvalidateRect( ::handle, 0 )
      ::internal[ 1 ] := SetBit( ::internal[ 1 ], 1, 0 )
   ENDIF
   RETURN Nil

//----------------------------------------------------//
METHOD TOP() CLASS HBrowse

   ::rowPos := 1
   Eval( ::bGoTop, Self )
   VScrollPos( Self, 0, .f. )

   //InvalidateRect( ::handle, 0 )
   ::Refresh( ::nFootRows > 0 )
   ::internal[ 1 ] := SetBit( ::internal[ 1 ], 1, 0 )
   ::SetFocus()

   RETURN Nil

//----------------------------------------------------//
METHOD ButtonDown( lParam ) CLASS HBrowse

   LOCAL nLine
   LOCAL STEP, res
   LOCAL xm, x1, fif
   LOCAL aColumns := {}, nCols := 1, xSize := 0

   // Calculate the line you clicked on, keeping track of header
   IF( ::lDispHead )
      nLine := Int( ( HIWORD( lParam ) - ( ::nHeadHeight * ::nHeadRows ) ) / ( ::height + 1 ) + 1 )
   ELSE
      nLine := Int( HIWORD( lParam ) / ( ::height + 1 ) + 1 )
   ENDIF

   STEP := nLine - ::rowPos
   res := .F.
   xm := LOWORD( lParam )

   x1  := ::x1
   fif := IIf( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE nCols <= Len( ::aColumns )
      xSize := ::aColumns[ nCols ]:width
      IF ( ::lAdjRight .AND. nCols == Len( ::aColumns ) )
         xSize := Max( ::x2 - x1, xSize )
      ENDIF
      IF !::aColumns[ nCols ]:lHide
         Aadd( aColumns, { xSize, ncols } )
         x1 += xSize
         xSize := 0
      ENDIF
      nCols ++
   ENDDO
   x1  := ::x1
   aColumns[ Len( aColumns ) , 1 ] += xSize

   DO WHILE fif <= Len( ::aColumns )
      IF( ! ( fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + aColumns[ fif,1 ] < xm ) )
         EXIT
      ENDIF
      x1 += aColumns[ fif,1 ]
      fif := IIf( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO
   IF fif > Len( aColumns )
      IF ! ::lAdjRight     // no column select
         RETURN Nil
      ENDIF
      fif --
   ENDIF
   //nando
   fif := aColumns[ fif, 2 ]

IF nLine > 0 .AND. nLine <= ::rowCurrCount
   // NEW
   IF ! ::ChangeRowCol( IIF( nLine = ::rowPos .AND. ::colpos == fif, 0, IIF( ;
         nLine != ::rowPos .AND. ::colpos != fif , 3, IIF( nLine != ::rowPos, 1, 2 ) ) ) )
      RETURN .F.
   ENDIF

   IF STEP != 0
      Eval( ::bSkip, Self, STEP )
      ::rowPos := nLine
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, STEP, .F. )
      ELSEIF ::nRecords > 1
         VScrollPos( Self, 0, .f. )
      ENDIF
      res := .T.

      /*
      IF ! Eval( ::bEof, Self )
         ::rowPos := nLine
         IF ::bScrollPos != Nil
            Eval( ::bScrollPos, Self, STEP, .F. )
         ELSEIF ::nRecords > 1
            VScrollPos( Self, 0, .f. )
         ENDIF
         res := .T.
      ELSEIF nRec > 0
         Eval( ::bGoto, Self, nRec )
      ENDIF
      */
   ENDIF
   IF ::lEditable .OR. ::lAutoEdit

      IF ::colpos != fif - ::nLeftCol + 1 + ::freeze
         // Colpos should not go beyond last column or I get bound errors on ::Edit()
         ::colpos := Min( ::nColumns + 1, fif - ::nLeftCol + 1 + ::freeze )
         VScrollPos( Self, 0, .f. )
         res := .T.
      ENDIF
   ENDIF
   IF res
      ::internal[ 1 ] := 15   // Force FOOTER
      //RedrawWindow( ::handle, RDW_INVALIDATE )
      InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] - ::height, ::xAdjRight, ::y1 + ( ::height + 1 ) * ::internal[ 2 ] )
      InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::xAdjRight , ::y1 + ( ::height + 1 ) * ::rowPos )
   ENDIF
   ::fipos := Min( ::colpos + ::nLeftCol - 1 - ::freeze, Len( ::aColumns ) )
   IF  ::aColumns[ ::fipos ]:Type = "L"
      ::EditLogical( WM_LBUTTONDOWN )
   ENDIF

ELSEIF nLine == 0
   IF PtrtouLong( oCursor ) ==  PtrtouLong( ColSizeCursor )
      ::lResizing := .T.
      ::isMouseOver := .F.
      Hwg_SetCursor( oCursor )
      xDrag := LOWORD( lParam )
      xDragMove := 0
      InvalidateRect( ::handle, 0 )
   ELSEIF ::lDispHead .AND. ;
      nLine >= - ::nHeadRows .AND. ;
      fif <= Len( ::aColumns ) //.AND. ;
      //::aColumns[ fif ]:bHeadClick != nil
      ::aColumns[ fif ]:lHeadClick := .T.
      InvalidateRect( ::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1 )
      IF ::aColumns[ fif ]:bHeadClick != nil
         ::isMouseOver := .F.
         Eval( ::aColumns[ fif ]:bHeadClick, ::aColumns[ fif ], fif, Self )
      ENDIF
      ::lHeadClick := .T.
   ENDIF
ENDIF
   IF  PtrtouLong( GetActiveWindow() ) = PtrtouLong( ::GetParentForm():Handle )  .OR. ;
       ::GetParentForm( ):Type < WND_DLG_RESOURCE
       ::SetFocus()
   ENDIF


RETURN Nil

//----------------------------------------------------//
METHOD ButtonUp( lParam ) CLASS HBrowse

   LOCAL xPos := LOWORD( lParam ), x, x1, i

   IF ::lResizing
      x1 := 0
      x := ::x1
      i := IIf( ::freeze > 0, 1, ::nLeftCol )    // ::nLeftCol
      DO WHILE x < xDrag
         IF !::aColumns[ i ]:lHide
            x += ::aColumns[ i ]:width
            IF Abs( x - xDrag ) < 10 .AND. ::aColumns[ i ]:Resizable
               x1 := x - ::aColumns[ i ]:width
               EXIT
            ENDIF
            i := IIf( i == ::freeze, ::nLeftCol, i + 1 )
         ENDIF
      ENDDO
      IF xPos > x1
         ::aColumns[ i ]:width := xPos - x1
         Hwg_SetCursor( arrowCursor )
         oCursor := 0
         ::isMouseOver := .F.
         xDragMove := 0
         InvalidateRect( ::handle, 0 )
         ::lResizing := .F.
      ENDIF

   ELSEIF ::aSelected != Nil
      IF ::lCtrlPress
         ::Select()
         ::refreshline()
      ELSE
         IF Len( ::aSelected ) > 0
            ::aSelected := { }
            ::Refresh()
         ENDIF
      ENDIF
   ENDIF
   IF  ::lHeadClick
      AEVAL( ::aColumns,{ | c | c:lHeadClick := .F. } )
      InvalidateRect( ::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1 )
      ::lHeadClick := .F.
     Hwg_SetCursor( downCursor )
   ENDIF
   /*
   IF  PtrtouLong( GetActiveWindow() ) = PtrtouLong( ::GetParentForm():Handle )  .OR. ;
       ::GetParentForm( ):Type < WND_DLG_RESOURCE
       ::SetFocus()
   ENDIF
    */
   RETURN Nil

METHOD Select() CLASS HBrowse
   LOCAL i

   IF ( i := AScan( ::aSelected, Eval( ::bRecno, Self ) ) ) > 0
      ADel( ::aSelected, i )
      ASize( ::aSelected, Len( ::aSelected ) - 1 )
   ELSE
      AAdd( ::aSelected, Eval( ::bRecno, Self ) )
   ENDIF

   RETURN Nil

//----------------------------------------------------//
METHOD ButtonRDown( lParam ) CLASS HBrowse
   LOCAL nLine
   LOCAL xm, x1, fif
   Local acolumns:={}, nCols := 1, xSize := 0

   // Calculate the line you clicked on, keeping track of header
   IF( ::lDispHead )
      nLine := Int( ( HIWORD( lParam ) - ( ::nHeadHeight * ::nHeadRows ) ) / ( ::height + 1 ) + 1 )
   ELSE
      nLine := Int( HIWORD( lParam ) / ( ::height + 1 ) + 1 )
   ENDIF
   xm := LOWORD( lParam )

   x1  := ::x1
   fif := IIf( ::freeze > 0, 1, ::nLeftCol )
   DO WHILE nCols <= Len( ::aColumns )
      xSize := ::aColumns[ ncols ]:width
      IF ( ::lAdjRight .and. nCols == Len( ::aColumns ) )
         xSize := Max( ::x2 - x1, xSize )
      ENDIF
      IF !::aColumns[ nCols ]:lhide
         Aadd( aColumns, { xSize, ncols } )
         x1 += xSize
         xSize := 0
      ENDIF
      nCols ++
   ENDDO
   x1  := ::x1
   aColumns[ Len( aColumns ) , 1] += xSize
   DO WHILE fif <= Len( aColumns )
      IF( ! ( fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + aColumns[ fif,1 ] < xm ) )
         EXIT
      ENDIF
      x1 += aColumns[ fif,1 ]
      fif := IIf( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO
   IF fif > Len( aColumns )
      IF ! ::lAdjRight     // no column select
         RETURN Nil
      ENDIF
      fif --
   ENDIF
   fif := aColumns[ fif, 2 ]
   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      //::fipos := Min( ::colpos + ::nLeftCol - 1 - ::freeze, Len( ::aColumns ) )
      IF ::bRClick != nil
         Eval( ::bRClick, Self, nLine, fif )
      ENDIF
   ELSEIF nLine == 0
      IF ::lDispHead .and. ;
         nLine >=  - ::nHeadRows .AND. fif <= Len( ::aColumns )
         IF ::aColumns[ fif ]:bHeadRClick != nil
            Eval( ::aColumns[ fif ]:bHeadRClick, Self, nLine, fif  )
         ENDIF
      ENDIF
   ENDIF
   RETURN Nil

METHOD ButtonDbl( lParam ) CLASS HBrowse
   LOCAL nLine := Int( HIWORD( lParam ) / ( ::height + 1 ) + IIf( ::lDispHead, 1 - ::nHeadRows, 1 ) )

   // writelog( "ButtonDbl"+str(nLine)+ str(::rowCurrCount) )
   IF nLine > 0 .and. nLine <= ::rowCurrCount
      ::ButtonDown( lParam )
      ::Edit()
   ENDIF
   RETURN Nil

//----------------------------------------------------//
METHOD MouseMove( wParam, lParam ) CLASS HBrowse
   LOCAL xPos := LOWORD( lParam ), yPos := HIWORD( lParam )
   LOCAL x := ::x1, i, res := .F.
   LOCAL nLastColumn
   local currxPos := ::xPosMouseOver

   ::xPosMouseOver := 0
   ::isMouseOver := IIF( ::lDispHead .AND. ::hTheme != Nil .AND. currxPos != 0, .T., .F. )
   nLastColumn := IIf( ::lAdjRight, Len( ::aColumns ) - 1, Len( ::aColumns ) )

   // DlgMouseMove()
   IF ! ::active .OR. Empty( ::aColumns ) .OR. ::x1 == Nil
      RETURN Nil
   ENDIF
   IF ::lDispSep .AND.  yPos <= ::nHeadHeight * ::nHeadRows + 1 .AND. ; // ::height*::nHeadRows+1
      ( xPos >= ::x1 .AND. xPos <= Max( xDragMove, ::xAdjRight ) + 4 )
      IF wParam == MK_LBUTTON .AND. ::lResizing
         Hwg_SetCursor( oCursor )
         res := .T.
         InvalidateRect( ::handle, 1, xDragMove - 18 , ::y1 - ( ::nHeadHeight * ::nHeadRows ), xDragMove + 18 , ::y2 - ( ::nFootHeight * ::nFootRows ) - 1 )
         xDragMove := xPos
         ::isMouseOver := .F.
         //::internal[ 1 ] := 2
         InvalidateRect( ::handle, 0, xPos - 18 , ::y1 - ( ::nHeadHeight * ::nHeadRows ), xPos + 18 , ::y2 - ( ::nFootHeight * ::nFootRows ) - 1 )
      ELSE
         i := IIf( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE x < ::x2 - 2 .AND. i <= nLastColumn     // Len( ::aColumns )
            // TraceLog( "Colonna "+str(i)+"    x="+str(x))
            IF !::aColumns[ i ]:lhide
               x += ::aColumns[ i ]:width
               ::xPosMouseOver := xPos
               IF Abs( x - xPos ) < 8
                  IF PtrtouLong( oCursor ) != PtrtouLong( ColSizeCursor )
                     oCursor := ColSizeCursor
                  ENDIF
                  Hwg_SetCursor( oCursor )
                  res := .T.
                  EXIT
               ELSE
                  oCursor := DownCursor
                  Hwg_SetCursor( oCursor )
                  res := .T.
               ENDIF
            ENDIF
            i := IIf( i == ::freeze, ::nLeftCol, i + 1 )
         ENDDO
      ENDIF
      IF ! res .AND. ! EMPTY( oCursor )
         Hwg_SetCursor( arrowCursor )
         oCursor := 0
         ::lResizing := .F.
      ENDIF
      ::isMouseOver := IIF( ::hTheme != Nil .AND. ::xPosMouseOver != 0, .T., .F. )
   ENDIF
   IF ::isMouseOver
      InvalidateRect( ::handle, 1, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::xAdjRight, ::y1 )
   ENDIF

   RETURN Nil

//----------------------------------------------------------------------------//
METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos ) CLASS HBrowse

   HB_SYMBOL_UNUSED( nXPos )
   HB_SYMBOL_UNUSED( nYPos )

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
         ::LineDown( .T. )
      ENDIF
      /*
      IF ( ::rowPos = 1 .OR. ::rowPos = ::rowCount ) .AND. ::rowCurrCount >= ::rowCount
         ::Refresh( .F. , nDelta > 0 )
      ENDIF
      */
   ENDIF
   RETURN nil

//----------------------------------------------------//
METHOD Edit( wParam, lParam ) CLASS HBrowse
   LOCAL fipos, lRes, x1, y1, fif, nWidth, lReadExit, rowPos
   LOCAL oModDlg, oColumn, aCoors, nChoic, bInit, oGet, Type
   LOCAL oComboFont, oCombo, oBtn
   LOCAL oGet1, owb1, owb2 , nHget

   fipos := Min( ::colpos + ::nLeftCol - 1 - ::freeze, Len( ::aColumns ) )
   ::fiPos := fipos

   IF  ( ! Eval( ::bEof, Self ) .OR. ::lAppMode ) .AND. ;
      ( ::bEnter == Nil .OR. ( ValType( lRes := Eval( ::bEnter, Self, fipos ) ) == 'L' .AND. ! lRes ) )
      oColumn := ::aColumns[ fipos ]
      IF ::Type == BRW_DATABASE
         ::varbuf := ( ::Alias ) ->( Eval( oColumn:block,, Self, fipos ) )
      ELSE
         IF ::nRecords  = 0 .AND. ::lAppMode
            AAdd( ::aArray, Array( Len( ::aColumns ) ) )
            FOR fif := 1 TO Len( ::aColumns )
                ::aArray[ 1, fif ] := ;
                   IIF( ::aColumns[ fif ]:Type == "D", CToD( Space( 8 ) ), ;
                   IIF( ::aColumns[ fif ]:Type == "N", 0, IIF( ::aColumns[ fif ]:Type == "L", .F., "" ) ) )
            NEXT
           ::lAppMode := .F.
           ::Refresh( ::nFootRows > 0 )
         ENDIF
         ::varbuf := Eval( oColumn:block,, Self, fipos )
      ENDIF
      Type := IIf( oColumn:Type == "U".AND.::varbuf != Nil, ValType( ::varbuf ), oColumn:Type )
      //IF ::lEditable .AND. Type != "O" .AND. Type != "L" // columns logic is handling in BUTTONDOWN()
      IF ::lEditable .AND. Type != "O" .AND. ( oColumn:aList != Nil .OR.  ( oColumn:aList = Nil .AND. wParam != 13 ) )
         IF oColumn:lEditable
            IF ::lAppMode
               IF Type == "D"
                  ::varbuf := CToD( "" )
               ELSEIF Type == "N"
                  ::varbuf := 0
               ELSEIF Type == "L"
                  ::varbuf := .F.
               ELSE
                  ::varbuf := ""
               ENDIF
            ENDIF
         ELSE
            RETURN Nil
         ENDIF
         x1  := ::x1
         fif := IIf( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE fif < fipos
            x1 += ::aColumns[ fif ]:width
            fif := IIf( fif = ::freeze, ::nLeftCol, fif + 1 )
         ENDDO
         nWidth := Min( ::aColumns[ fif ]:width, ::x2 - x1 - 1 )
         IF  fif =  Len( ::aColumns )
            nWidth := Min( ::nWidthColRight, ::x2 - x1 - 1 )
         ENDIF
         rowPos := ::rowPos - 1
         IF ::lAppMode .AND. ::nRecords != 0 .AND. ::rowPos != ::rowCount
            rowPos ++
         ENDIF
         y1 := ::y1 + ( ::height + 1 ) * rowPos

         // aCoors := GetWindowRect( ::handle )
         // x1 += aCoors[1]
         // y1 += aCoors[2]

         aCoors := ClientToScreen( ::handle, x1, y1 )
         x1 := aCoors[ 1 ]
         y1 := aCoors[ 2 ] + 1

         lReadExit := SET( _SET_EXIT, .t. )

         ::lNoValid := .T.
         IF Type <> "L"
            bInit := IIf( wParam == Nil .OR. wParam = 13 .OR. Empty( lParam ), { | o | MoveWindow( o:handle, x1, y1, nWidth, o:nHeight + 1 ) }, ;
                       { | o | MoveWindow( o:handle, x1, y1, nWidth, o:nHeight + 1 ), PostMessage( o:aControls[ 1 ]:handle, WM_CHAR, wParam, lParam ) } )
         ELSE
            bInit := { || .F. }
         ENDIF

         IF Type <> "M"
            INIT DIALOG oModDlg ;
                 STYLE WS_POPUP + 1 + IIf( oColumn:aList == Nil, WS_BORDER, 0 ) ;
                 At x1, y1 - IIf( oColumn:aList == Nil, 1, 0 ) ;
                 SIZE nWidth - 1, ::height + IIf( oColumn:aList == Nil, 1, 0 ) ;
                 ON INIT bInit ;
                 ON OTHER MESSAGES { | o, m, w, l | ::EditEvent( o, m, w, l ) }
         ELSE
            INIT DIALOG oModDlg title "memo edit" At 0, 0 SIZE 400, 300 ON INIT { | o | o:center() }
         ENDIF

         IF oColumn:aList != Nil .AND. ( oColumn:bWhen = Nil .OR. Eval( oColumn:bWhen ) )
            oModDlg:brush := - 1
            oModDlg:nHeight := ::height + 1 // * 5

            IF ValType( ::varbuf ) == 'N'
               nChoic := ::varbuf
            ELSE
               ::varbuf := AllTrim( ::varbuf )
               nChoic := AScan( oColumn:aList, ::varbuf )
            ENDIF

            oComboFont := IIf( ValType( ::oFont ) == "U", ;
                               HFont():Add( "MS Sans Serif", 0, - 8 ), ;
                               HFont():Add( ::oFont:name, ::oFont:width, ::oFont:height + 2 ) )

            @ 0, 0 GET COMBOBOX oCombo VAR nChoic ;
               ITEMS oColumn:aList            ;
               SIZE nWidth, ::height + 1      ;
               FONT oComboFont  ;
               DISPLAYCOUNT  IIF( LEN( oColumn:aList ) > ::rowCount , ::rowCount - 1, LEN( oColumn:aList ) ) ;
               VALID oColumn:bValid           ;
               WHEN oColumn:bWhen
               oCombo:bSelect := { || KEYB_EVENT( VK_RETURN ) }
               //VALID {| oColumn, oGet | ::ValidColumn( oColumn, oGet )};
               //WHEN {| oColumn, oGet | ::WhenColumn( oColumn, oGet )};

              IF oColumn:bValid != NIL
                 oCombo:bValid := oColumn:bValid
              ENDIF

             oModDlg:AddEvent( 0, IDOK, { || oModDlg:lResult := .T. , oModDlg:close() } )

         ELSE
            IF Type == "L"
               oModDlg:lResult := .T.
            ELSEIF Type <> "M"
               nHGet := Max( ( ::height - ( TxtRect( "A", self ) )[ 2 ] ) / 2 , 0 )
               @ 0, nHGet GET oGet VAR ::varbuf       ;
                  SIZE nWidth - IIF( oColumn:bClick != NIL, 16, 0 ) , ::height         ;
                  NOBORDER                       ;
                  STYLE ES_AUTOHSCROLL           ;
                  FONT ::oFont                   ;
                  PICTURE oColumn:picture        ;
                  VALID { | oColumn, oGet | ::ValidColumn( oColumn, oGet, oBtn ) };
                  WHEN { | oColumn, oGet | ::WhenColumn( oColumn, oGet, oBtn ) }
                  //VALID oColumn:bValid           ;
                  //WHEN oColumn:bWhen
                 //oModDlg:AddEvent( 0, IDOK, { || oModDlg:lResult := .T., oModDlg:close() } )
               IF oColumn:bClick != NIL
                  IF Type != "D"
                     @ nWidth - 15, 0  OWNERBUTTON oBtn  SIZE 16,::height - 0 ;
                        TEXT '...'  FONT HFont():Add( 'MS Sans Serif',0,-10,400,,,) ;
                        COORDINATES 0, 1, 0, 0      ;
                        ON CLICK {| oColumn, oBtn | HB_SYMBOL_UNUSED( oColumn ), ::onClickColumn( .t., oGet, oBtn ) }
                        oBtn:themed :=  ::hTheme != Nil
                  ELSE
                     @ nWidth - 16, 0 DATEPICKER oBtn SIZE 16,::height-1  ;
                        ON CHANGE {| value, oBtn |  ::onClickColumn( value, oGet, oBtn ) }
                  ENDIF
               ENDIF
               oGet:lNoValid := .T.
               IF ! Empty( wParam )  .AND. wParam != 13 .AND. !Empty( lParam )
                  SendMessage( oGet:handle, WM_CHAR,  wParam, lParam  )
               ENDIF
            ELSE
               oGet1 := ::varbuf
               @ 10, 10 Get oGet1 SIZE oModDlg:nWidth - 20, 240 FONT ::oFont Style WS_VSCROLL + WS_HSCROLL + ES_MULTILINE VALID oColumn:bValid
               @ 010, 252 ownerbutton owb2 text "Save" size 80, 24 ON Click { || ::varbuf := oGet1, oModDlg:close(), oModDlg:lResult := .t. }
               @ 100, 252 ownerbutton owb1 text "Close" size 80, 24 ON CLICK { || oModDlg:close() }
            ENDIF
         ENDIF

         IF Type != "L" .AND. ::nSetRefresh > 0
            ::oTimer:Interval := 0
         ENDIF

         ACTIVATE DIALOG oModDlg

         ::lNoValid := .F.
         IF Type = "L" .AND. wParam != VK_RETURN
             Hwg_SetCursor( arrowCursor )
             IF wParam = VK_SPACE
                oModDlg:lResult := ::EditLogical( wParam )
                RETURN NIL
             ENDIF
         ENDIF

         IF oColumn:aList != Nil
            oComboFont:Release()
         ENDIF

         IF oModDlg:lResult
            IF oColumn:aList != Nil
               IF ValType( ::varbuf ) == 'N'
                  ::varbuf := nChoic
               ELSE
                  ::varbuf := oColumn:aList[ nChoic ]
               ENDIF
            ENDIF
            IF ::lAppMode
               ::lAppMode := .F.
               IF ::Type == BRW_DATABASE
                  ( ::Alias ) ->( DBAppend() )
                  ( ::Alias ) ->( Eval( oColumn:block, ::varbuf, Self, fipos ) )
                  ( ::Alias ) ->( DBUnlock() )
               ELSE
                  IF ValType( ::aArray[ 1 ] ) == "A"
                     AAdd( ::aArray, Array( Len( ::aArray[ 1 ] ) ) )
                     FOR fif := 2 TO Len( ( ::aArray[ 1 ] ) )
                        ::aArray[ Len( ::aArray ), fif ] := ;
                                                            IIf( ::aColumns[ fif ]:Type == "D", CToD( Space( 8 ) ), ;
                                                                 IIf( ::aColumns[ fif ]:Type == "N", 0, "" ) )
                     NEXT
                  ELSE
                     AAdd( ::aArray, Nil )
                  ENDIF
                  ::nCurrent := Len( ::aArray )
                  Eval( oColumn:block, ::varbuf, Self, fipos )
               ENDIF
               IF ::nRecords > 0
                  ::rowPos ++
               ENDIF
               ::lAppended := .T.
               IF ! ( Getkeystate( VK_UP ) < 0 .OR. Getkeystate( VK_DOWN ) < 0 )
                  ::DoHScroll( SB_LINERIGHT )
               ENDIF
               ::Refresh( ::nFootRows > 0 )
            ELSE
               IF ::Type == BRW_DATABASE
                  IF ( ::Alias ) ->( RLock() )
                     ( ::Alias ) ->( Eval( oColumn:block, ::varbuf, Self, fipos ) )
                     ( ::Alias ) ->( DBUnlock() )
                  ELSE
                     MsgStop( "Can't lock the record!" )
                  ENDIF
               ELSE
                  Eval( oColumn:block, ::varbuf, Self, fipos )
               ENDIF
               IF ! ( Getkeystate( VK_UP ) < 0 .OR. Getkeystate( VK_DOWN ) < 0 .OR. Getkeystate( VK_SPACE ) < 0) .AND. Type != "L"
                  ::DoHScroll( SB_LINERIGHT )
               ENDIF
               ::lUpdated := .T.
               InvalidateRect( ::handle, 0, ::x1, ::y1 + ( ::height + 1 ) * ( ::rowPos - 2 ), ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
               ::RefreshLine()
            ENDIF

            /* Execute block after changes are made */
            IF ::bUpdate != nil
               Eval( ::bUpdate,  Self, fipos )
            END

         ELSEIF ::lAppMode
            ::lAppMode := .F.
            //InvalidateRect( ::handle, 0, ::x1, ::y1 + ( ::height + 1 ) * ::rowPos, ::x2, ::y1 + ( ::height + 1 ) * ( ::rowPos + 2 ) )
            IF ::Type == BRW_DATABASE .AND. Eval( ::bEof, Self )
               Eval( ::bSkip, Self, - 1 )
            ENDIF
            IF ::rowPos < ::rowCount
               //::RefreshLine()
               InvalidateRect( ::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + ( ::height + 1 ) * ::rowPos, ::x2, ::y1 + ( ::height + 1 ) * ( ::rowPos + 1 ) )
            ELSE
               ::Refresh()
            ENDIF
         ENDIF
         ::SetFocus()
         SET( _SET_EXIT, lReadExit )
         
         IF ::nSetRefresh > 0
            ::oTimer:Interval := ::nSetRefresh
         ENDIF

      ELSEIF ::lEditable
         ::DoHScroll( SB_LINERIGHT )
      ENDIF
   ENDIF
   RETURN Nil

METHOD EditLogical( wParam, lParam ) CLASS HBrowse

   HB_SYMBOL_UNUSED( lParam )

      IF  ! ::aColumns[ ::fipos ]:lEditable
          RETURN .F.
      ENDIF

      IF  ::aColumns[ ::fipos ]:bWhen != Nil
         ::oparent:lSuspendMsgsHandling := .t.
         ::varbuf := Eval( ::aColumns[ ::fipos ]:bWhen, ::aColumns[ ::fipos ], ::varbuf )
         ::oparent:lSuspendMsgsHandling := .f.
         IF ! ( ValType( ::varbuf ) == "L" .AND. ::varbuf )
            RETURN .F.
         ENDIF
      ENDIF

      IF ::Type == BRW_DATABASE
         IF wParam != VK_SPACE
            ::varbuf := ( ::Alias ) ->( Eval( ::aColumns[ ::fipos ]:block,, Self, ::fipos ) )
         ENDIF
         IF ( ::Alias ) ->( RLock() )
            ( ::Alias ) ->( Eval( ::aColumns[ ::fipos ]:block, ! ::varbuf, Self, ::fipos ) )
            ( ::Alias ) ->( DBUnlock() )
         ELSE
             MsgStop( "Can't lock the record!" )
         ENDIF
      ELSEIF ::nRecords  > 0
         IF wParam != VK_SPACE
             ::varbuf :=  Eval( ::aColumns[ ::fipos ]:block,, Self, ::fipos )
         ENDIF
         Eval( ::aColumns[ ::fipos ]:block, ! ::varbuf, Self, ::fipos )
      ENDIF

      ::lUpdated := .T.
      ::RefreshLine()
      IF  ::aColumns[ ::fipos ]:bValid != Nil
         ::oparent:lSuspendMsgsHandling := .t.
         Eval( ::aColumns[ ::fipos ]:bValid, ! ::varbuf, ::aColumns[ ::fipos ] ) //, ::varbuf )
        ::oparent:lSuspendMsgsHandling := .f.
      ENDIF
   RETURN .T.

METHOD EditEvent( oCtrl, msg, wParam, lParam )

   HB_SYMBOL_UNUSED( lParam )

   IF ( msg = WM_KEYDOWN .AND.( wParam = VK_RETURN  .OR. wParam = VK_TAB ) )
      Return -1
   ELSEIF ( msg = WM_KEYDOWN .AND. wParam = VK_ESCAPE )
      oCtrl:oParent:lResult := .F.
      oCtrl:oParent:Close()
      Return 0
   ENDIF
   RETURN -1

METHOD onClickColumn( value, oGet, oBtn ) CLASS HBROWSE
   Local oColumn := ::aColumns[ ::fipos ]

   IF VALTYPE( value ) = "D"
      ::varbuf := value
      oGet:refresh()
      POSTMESSAGE( oBtn:handle, WM_KEYDOWN, VK_TAB, 0 )
   ENDIF
   IF oColumn:bClick != Nil
      ::oparent:lSuspendMsgsHandling := .T.
      EVAL( oColumn:bClick, value, oGet, oColumn, Self )
      ::oparent:lSuspendMsgsHandling := .F.
	 ENDIF
   oGet:SetFocus()
   RETURN Nil


METHOD WhenColumn( value, oGet ) CLASS HBROWSE
   Local res := .t.
   Local oColumn := ::aColumns[ ::fipos ]

   IF oColumn:bWhen != Nil
      ::oparent:lSuspendMsgsHandling := .T.
      res := EVAL( oColumn:bWhen, Value, oGet )
 		  oGet:lnovalid := res
		  IF ValType( res ) = "L" .AND. ! res
		     ::SetFocus()
		     oGet:oParent:close()
		  ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
	 ENDIF
   RETURN res

METHOD ValidColumn( value,oGet, oBtn ) CLASS HBROWSE
   Local res := .t.
   Local oColumn := ::aColumns[ ::fipos ]

   IF ! CheckFocus( oGet, .T. ) //.OR. oGet:lNoValid
      RETURN .t.
   ENDIF
   IF oBtn != Nil .AND. GetFocus() = oBtn:handle
      RETURN .T.
   ENDIF
   IF oColumn:bValid != Nil
       ::oparent:lSuspendMsgsHandling := .T.
       res := EVAL( oColumn:bValid, value, oGet )
 		   oGet:lnovalid := res
		   IF ValType( res ) = "L" .AND. ! res
		      oGet:SetFocus()
		   ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
	 ENDIF
	 IF res
      oGet:oParent:close()
      oGet:oParent:lResult := .T.
	 ENDIF
   RETURN res


METHOD ChangeRowCol( nRowColChange ) CLASS HBrowse
// 0 (default) No change.
// 1 Row change
// 2 Column change
// 3 Row and column change
   LOCAL res := .T.
   LOCAL lSuspendMsgsHandling := ::oParent:lSuspendMsgsHandling
   IF ::bChangeRowCol != Nil .AND.  !::oParent:lSuspendMsgsHandling
      ::oParent:lSuspendMsgsHandling := .T.
      res :=  Eval( ::bChangeRowCol, nRowColChange, Self, ::SetColumn() )
      ::oParent:lSuspendMsgsHandling := lSuspendMsgsHandling
   ENDIF
   IF nRowColChange > 0
      ::lSuspendMsgsHandling := .F.
   ENDIF
   RETURN ! EMPTY( res )

METHOD When() CLASS HBrowse
  LOCAL nSkip, res := .T.

	IF !CheckFocus(self, .f.)
	   RETURN .F.
	ENDIF
  nSkip := iif( GetKeyState( VK_UP ) < 0 .or. (GetKeyState( VK_TAB ) < 0 .and. GetKeyState(VK_SHIFT) < 0 ), -1, 1 )

  IF ::bGetFocus != Nil
		  ::oParent:lSuspendMsgsHandling := .T.
		  ::lnoValid := .T.
		  //::setfocus()
		  res := Eval( ::bGetFocus, ::COLPOS, Self )
		  res := IIF(VALTYPE(res) = "L", res, .T.)
      ::lnoValid := ! res
      IF ! res
         GetSkip( ::oParent, ::handle, , nSkip )
      ENDIF
 		  ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN res

METHOD Valid() CLASS HBrowse
   LOCAL res

	 //IF ::bLostFocus != Nil .AND. ( ! CheckFocus( Self, .t. ) .OR.::lNoValid  )
	 IF !CheckFocus(self, .T.) .OR. ::lNoValid
      RETURN .T.
	 ENDIF
   IF ::bLostFocus != Nil
       ::oParent:lSuspendMsgsHandling := .T.
       res := Eval( ::bLostFocus, ::COLPOS, Self )
       res := IIF( VALTYPE(res) = "L", res, .T. )
       IF VALTYPE(res) = "L" .AND. ! res
          ::setfocus()
          ::oParent:lSuspendMsgsHandling := .F.
          RETURN .F.
       ENDIF
       ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN .T.


//----------------------------------------------------//
METHOD RefreshLine() CLASS HBrowse

   ::internal[ 1 ] := 0
   InvalidateRect( ::handle, 0, ::x1 - ::nDeleteMark , ::y1 + ( ::height + 1 ) * ::rowPos - ::height, ::x2, ::y1 + ( ::height + 1 ) * ::rowPos )
   RETURN Nil

//----------------------------------------------------//
METHOD Refresh( lFull, lLineUp ) CLASS HBrowse

   IF lFull == Nil .OR. lFull
      IF ::lFilter
         ::nLastRecordFilter := 0
         ::nFirstRecordFilter := 0
         //SetScrollPos( ::handle, SB_VERT, 0 )
         //::RowPos := 0
         /*
         ( ::Alias ) ->( FltGoTop( Self ) ) // sk
         */
         	// you need this? becausee it will not let scroll you browse? // lfbasso@
      ENDIF
      ::internal[ 1 ] := 15
      // RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
      IF ::nCurrent < ::rowCount .AND. ::rowPos <= ::nCurrent .AND. EMPTY( lLineUp )
         ::rowPos := ::nCurrent
      ENDIF
      //RedrawWindow( ::handle, RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ELSE
      InvalidateRect( ::handle, 0 )
      ::internal[ 1 ] := SetBit( ::internal[ 1 ], 1, 0 )
      IF ::nCurrent < ::rowCount .AND. ::rowPos <= ::nCurrent .AND. EMPTY( lLineUp )
         ::rowPos := ::nCurrent
      ENDIF
      //RedrawWindow( ::handle, RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ENDIF
 //  RedrawWindow( ::handle, RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw
   RETURN Nil

/*
METHOD BrwScrollVPos( ) CLASS HBrowse
   LOCAL minPos, maxPos
   Local nRecCount, nRecno, nPosRecno
   LOCAL nIndexOrd := ( ::Alias ) ->( IndexOrd() )
   LOCAL lDisableVScrollPos := ::lDisableVScrollPos .AND. IndexOrd() != 0

   nPosRecno := IIF( nIndexOrd = 0 .OR. lDisableVScrollPos, ( ::Alias ) ->( RecNo() ), ( ::Alias ) ->( ordkeyno() ) )

   IF ! lDisableVScrollPos .AND. ( ( ! ::lFilter .AND. Empty( ( ::Alias ) ->( DBFILTER() ) ) ) .OR. ! EMPTY( ::RelationalExpr ) )
      nRecCount := Eval( ::bRcou, Self ) //IIF( ( ::Alias ) ->( IndexOrd() ) = 0, , OrdKeyCount() )
      IF  ::nRecCount != nRecCount .OR. nIndexOrd != ::nIndexOrd  .OR. ::Alias != Alias()
         ::nRecCount := nRecCount
         ::nIndexOrd := nIndexOrd
         nrecno := ( ::Alias ) ->( RecNo() )
         Eval( ::bGobot, Self )
         maxPos := IIF( nIndexOrd = 0, ( ::Alias ) ->( RecNo() ), IIF( EMPTY( ::RelationalExpr ), ::nRecCount, ( ::Alias ) ->( ordkeyno() ) ) )
         Eval( ::bGotop, Self )
         minPos := IIF( nIndexOrd = 0, ( ::Alias ) ->( RecNo() ), ( ::Alias ) ->( ordkeyno() ) )
         ( ::Alias ) ->( DBGoTo( nrecno ) )
         IF minPos != maxPos
            SetScrollRange( ::handle, SB_VERT, minPos, maxPos )
         ENDIF
          // ( ::Alias ) ->( DBGoTo( nrecno ) )
      ENDIF
   ELSE
      ::nRecCount := ( ::Alias ) -> ( Reccount() )
      SetScrollRange( ::handle, SB_VERT, 1, ::nRecCount )
   ENDIF
   RETURN IIF( lDisableVScrollPos, ::nRecCount / 2, nPosRecno )
    //IIF( ( ::Alias ) ->( IndexOrd() ) = 0 .OR. ::lDisableVScrollPos, ( ::Alias ) ->( RecNo() ), ( ::Alias ) ->( ordkeyno() ) )
*/
//----------------------------------------------------//
METHOD FldStr( oBrw, numf ) CLASS HBrowse
   LOCAL cRes, vartmp, Type, pict

   IF numf <= Len( oBrw:aColumns )

      pict := oBrw:aColumns[ numf ]:picture

      IF pict != nil
         IF oBrw:Type == BRW_DATABASE
            IF oBrw:aRelation
               cRes := ( oBrw:aColAlias[ numf ] ) ->( Transform( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ), pict ) )
            ELSE
               cRes := ( oBrw:Alias ) ->( Transform( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ), pict ) )
            ENDIF
         ELSE
            oBrw:nCurrent := IIF( oBrw:nCurrent = 0, 1, oBrw:nCurrent )
            vartmp :=  Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf )
            cRes := IIF( vartmp != Nil, Transform( vartmp, pict ), Space( oBrw:aColumns[ numf ]:length ) )
         ENDIF
      ELSE
         IF oBrw:Type == BRW_DATABASE
            IF oBrw:aRelation
               vartmp := ( oBrw:aColAlias[ numf ] ) ->( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ) )
            ELSE
               vartmp := ( oBrw:Alias ) ->( Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf ) )
            ENDIF
         ELSE
            oBrw:nCurrent := IIF( oBrw:nCurrent = 0, 1, oBrw:nCurrent )
            vartmp := Eval( oBrw:aColumns[ numf ]:block,, oBrw, numf )
         ENDIF

         Type := ( oBrw:aColumns[ numf ] ):Type
         IF Type == "U" .AND. vartmp != Nil
            Type := ValType( vartmp )
         ENDIF
         IF Type == "C"
            //cRes := Padr( vartmp, oBrw:aColumns[numf]:length )
            cRes := vartmp
         ELSEIF Type == "N"
            cRes := PadL( Str( vartmp, oBrw:aColumns[ numf ]:length, ;
                               oBrw:aColumns[ numf ]:dec ), oBrw:aColumns[ numf ]:length )
         ELSEIF Type == "D"
            cRes := PadR( DToC( vartmp ), oBrw:aColumns[ numf ]:length )

         ELSEIF Type == "L"
            cRes := PadR( IIf( vartmp, "T", "F" ), oBrw:aColumns[ numf ]:length )

         ELSEIF Type == "M"
            cRes := IIf( Empty( vartmp ), "<memo>", "<MEMO>" )

         ELSEIF Type == "O"
            cRes := "<" + vartmp:Classname() + ">"

         ELSEIF Type == "A"
            cRes := "<Array>"

         ELSE
            cRes := Space( oBrw:aColumns[ numf ]:length )
         ENDIF
      ENDIF
   ENDIF

   RETURN cRes

//----------------------------------------------------//
STATIC FUNCTION FLDCOUNT( oBrw, xstrt, xend, fld1 )
   LOCAL klf := 0, i := IIf( oBrw:freeze > 0, 1, fld1 )

   DO WHILE .T.
      // xstrt += ( MAX( oBrw:aColumns[i]:length, LEN( oBrw:aColumns[i]:heading ) ) - 1 ) * oBrw:width
      xstrt += oBrw:aColumns[ i ]:width
      IF xstrt > xend
         EXIT
      ENDIF
      klf ++
      i   := IIf( i = oBrw:freeze, fld1, i + 1 )
      // xstrt += 2 * oBrw:width
      IF i > Len( oBrw:aColumns )
         EXIT
      ENDIF
   ENDDO
   RETURN IIf( klf = 0, 1, klf )


//----------------------------------------------------//
FUNCTION CREATEARLIST( oBrw, arr )
   LOCAL i
   oBrw:Type  := BRW_ARRAY
   oBrw:aArray := arr
   IF Len( oBrw:aColumns ) == 0
      // oBrw:aColumns := {}
      IF ValType( arr[ 1 ] ) == "A"
         FOR i := 1 TO Len( arr[ 1 ] )
            oBrw:AddColumn( HColumn():New( , ColumnArBlock() ) )
         NEXT
      ELSE
         oBrw:AddColumn( HColumn():New( , { | value, o | HB_SYMBOL_UNUSED( value ), o:aArray[ o:nCurrent ] } ) )
      ENDIF
   ENDIF
   Eval( oBrw:bGoTop, oBrw )
   oBrw:Refresh()
   RETURN Nil

//----------------------------------------------------//
PROCEDURE ARSKIP( oBrw, nSkip )
   LOCAL nCurrent1

   IF oBrw:nRecords != 0
      nCurrent1   := oBrw:nCurrent
      oBrw:nCurrent += nSkip + IIf( nCurrent1 = 0, 1, 0 )
      IF oBrw:nCurrent < 1
         oBrw:nCurrent := 0
      ELSEIF oBrw:nCurrent > oBrw:nRecords
         oBrw:nCurrent := oBrw:nRecords + 1
      ENDIF
   ENDIF
   RETURN

//----------------------------------------------------//
FUNCTION CreateList( oBrw, lEditable )
   LOCAL i
   LOCAL nArea := Select()
   LOCAL kolf := FCount()

   oBrw:Alias   := Alias()

   oBrw:aColumns := { }
   FOR i := 1 TO kolf
      oBrw:AddColumn( HColumn():New( FieldName( i ),                      ;
                                     FieldWBlock( FieldName( i ), nArea ), ;
                                     dbFieldInfo( DBS_TYPE, i ),         ;
                                     IIf( dbFieldInfo( DBS_TYPE, i ) == "D".AND.__SetCentury(), 10, dbFieldInfo( DBS_LEN, i ) ), ;
                                     dbFieldInfo( DBS_DEC, i ),          ;
                                     lEditable ) )
   NEXT

   oBrw:Refresh()

   RETURN Nil

FUNCTION VScrollPos( oBrw, nType, lEof, nPos )
   LOCAL minPos, maxPos, oldRecno, newRecno, nrecno

   IF oBrw:lNoVScroll
      RETURN Nil
   ENDIF
   GetScrollRange( oBrw:handle, SB_VERT, @minPos, @maxPos )
   IF nPos == Nil
      IF oBrw:Type <> BRW_DATABASE
         IF nType > 0 .AND. lEof
            Eval( oBrw:bSkip, oBrw, - 1 )
         ENDIF
         nPos := IIf( oBrw:nRecords > 1, Round( ( ( maxPos - minPos + 1 ) / ( oBrw:nRecords - 1 ) ) * ;
                                                ( Eval( oBrw:bRecnoLog, oBrw ) - 1 ), 0 ), minPos )
         SetScrollPos( oBrw:handle, SB_VERT, nPos )
      ELSEIF ! Empty( oBrw:Alias )
         nrecno := ( oBrw:Alias ) ->( RecNo() )
         Eval( oBrw:bGotop, oBrw )
         minPos := IF( ( oBrw:Alias ) ->( IndexOrd() ) = 0, ( oBrw:Alias ) ->( RecNo() ), ( oBrw:Alias ) ->( ordkeyno() ) )
         Eval( oBrw:bGobot, oBrw )
         maxPos := IF( ( oBrw:Alias ) ->( IndexOrd() ) = 0, ( oBrw:Alias ) ->( RecNo() ), ( oBrw:Alias ) ->( ordkeyno() ) )
         IF minPos != maxPos
            SetScrollRange( oBrw:handle, SB_VERT, minPos, maxPos )
         ENDIF
         ( oBrw:Alias ) ->( DBGoTo( nrecno ) )
         SetScrollPos( oBrw:handle, SB_VERT, IF( ( oBrw:Alias ) ->( IndexOrd() ) = 0, ( oBrw:Alias ) ->( RecNo() ), ( oBrw:Alias ) ->( ordkeyno() ) ) )

//         SetScrollPos( oBrw:handle, SB_VERT, oBrw:BrwScrollVPos( ) )
      ENDIF
   ELSE
      oldRecno := Eval( oBrw:bRecnoLog, oBrw )
      newRecno := Round( ( oBrw:nRecords - 1 ) * nPos / ( maxPos - minPos ) + 1, 0 )
      IF newRecno <= 0
         newRecno := 1
      ELSEIF newRecno > oBrw:nRecords
         newRecno := oBrw:nRecords
      ENDIF
      IF nType == SB_THUMBPOSITION
         SetScrollPos( oBrw:handle, SB_VERT, nPos )
      ENDIF
      IF newRecno != oldRecno
         Eval( oBrw:bSkip, oBrw, newRecno - oldRecno )
         IF oBrw:rowCount - oBrw:rowPos > oBrw:nRecords - newRecno
            oBrw:rowPos := oBrw:rowCount - ( oBrw:nRecords - newRecno )
         ENDIF
         IF oBrw:rowPos > newRecno
            oBrw:rowPos := newRecno
         ENDIF
         oBrw:Refresh( oBrw:nFootRows > 0 )
      ENDIF
   ENDIF

   RETURN Nil

/*
Function HScrollPos( oBrw, nType, lEof, nPos )
Local minPos, maxPos, i, nSize := 0, nColPixel
Local nBWidth := oBrw:nWidth // :width is _not_ browse width

   GetScrollRange( oBrw:handle, SB_HORZ, @minPos, @maxPos )

   IF nType == SB_THUMBPOSITION

      nColPixel := Int( ( nPos * nBWidth ) / ( ( maxPos - minPos ) + 1 ) )
      i := oBrw:nLeftCol - 1

      while nColPixel > nSize .AND. i < Len( oBrw:aColumns )
         nSize += oBrw:aColumns[ ++i ]:width
      enddo

      // colpos is relative to leftmost column, as it seems, so I subtract leftmost column number
      oBrw:colpos := Max( i, oBrw:nLeftCol ) - oBrw:nLeftCol + 1
   ENDIF

   SetScrollPos( oBrw:handle, SB_HORZ, nPos )

RETURN Nil
*/

//----------------------------------------------------//
// Agregado x WHT. 27.07.02
// Locus metodus.
METHOD ShowSizes() CLASS HBrowse
   LOCAL cText := ""

   AEval( ::aColumns, ;
          { | v, e | HB_SYMBOL_UNUSED( v ), cText += ::aColumns[ e ]:heading + ": " + Str( Round( ::aColumns[ e ]:width / 8, 0 ) - 2  ) + Chr( 10 ) + Chr( 13 ) } )
   MsgInfo( cText )
   RETURN nil

FUNCTION ColumnArBlock()
   RETURN { | value, o, n | IIf( value == Nil, o:aArray[ IIf( o:nCurrent < 1, 1, o:nCurrent ), n ], ;
                                 o:aArray[ IIf( o:nCurrent < 1, 1, o:nCurrent ), n ] := value ) }


STATIC FUNCTION HdrToken( cStr, nMaxLen, nCount )
   LOCAL nL, nPos := 0

   nMaxLen := nCount := 0
   cStr += ';'
   #ifdef __XHARBOUR__
   DO WHILE ( nL := Len( __StrTkPtr( @cStr, @nPos, ";" ) ) ) != 0
   #else
   DO WHILE ( nL := Len( hb_tokenPtr( @cStr, @nPos, ";" ) ) ) != 0
   #endif
      nMaxLen := Max( nMaxLen, nL )
      nCount ++
   ENDDO
   RETURN nil


STATIC FUNCTION FltSkip( oBrw, nLines, lDesc )
   LOCAL n
   IF nLines == NIL
      nLines := 1
   ENDIF
   IF lDesc == NIL
      lDesc := .F.
   ENDIF
   IF nLines > 0
      FOR n := 1 TO nLines
         ( oBrw:Alias )->( DBSKIP( IIF( lDesc, - 1, + 1 ) ) )
         IF  EMPTY( oBrw:RelationalExpr )
            WHILE ( oBrw:Alias )->( ! Eof() ) .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
              //SKIP IF( lDesc, - 1, + 1 )
               ( oBrw:Alias )->( DBSKIP( IIF( lDesc, - 1, + 1 ) ) )
            ENDDO
         ENDIF
      NEXT
   ELSEIF nLines < 0
      FOR n := 1 TO ( nLines * ( - 1 ) )
         IF ( oBrw:Alias )->( Eof() )
            IF lDesc
               FltGoTop( oBrw )
            ELSE
               FltGoBottom( oBrw )
            ENDIF
         ELSE
            //SKIP IF( lDesc, + 1, - 1 )
            ( oBrw:Alias )->( DBSKIP( IIF( lDesc, + 1, - 1 ) ) )
         ENDIF
         IF  EMPTY( oBrw:RelationalExpr )
         WHILE ! ( oBrw:Alias )->( Bof() ) .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
            //SKIP IF( lDesc, + 1, - 1 )
            ( oBrw:Alias )->( DBSKIP( IIF( lDesc, + 1, - 1 ) ) )
         ENDDO
         ENDIF
      NEXT
   ENDIF
   RETURN NIL


STATIC FUNCTION FltGoTop( oBrw )
   IF oBrw:nFirstRecordFilter == 0
      Eval( oBrw:bFirst )
      IF ( oBrw:Alias )-> ( ! Eof() )
         IF  EMPTY( oBrw:RelationalExpr )
            WHILE ( oBrw:Alias )->( ! Eof() ) .AND. ! ( Eval( oBrw:bWhile, oBrw ) .AND. Eval( oBrw:bFor, oBrw ) )
              ( oBrw:Alias )->( DBSkip() )
            ENDDO
         ENDIF
         oBrw:nFirstRecordFilter := FltRecNo( oBrw )
      ELSE
         oBrw:nFirstRecordFilter := 0
      ENDIF
   ELSE
      FltGoTo( oBrw, oBrw:nFirstRecordFilter )
   ENDIF
   RETURN NIL

STATIC FUNCTION FltGoBottom( oBrw )
   IF oBrw:nLastRecordFilter == 0
      Eval( oBrw:bLast )
      IF  EMPTY( oBrw:RelationalExpr )
         IF ! Eval( oBrw:bWhile, oBrw ) .OR. ! Eval( oBrw:bFor, oBrw )
            WHILE ( oBrw:Alias )->( ! Bof() ) .AND. ! Eval( oBrw:bWhile, oBrw )
              ( oBrw:Alias )->( DBSkip( - 1 ) )
            ENDDO
            WHILE ! Bof() .AND. Eval( oBrw:bWhile, oBrw ) .AND. ! Eval( oBrw:bFor, oBrw )
              ( oBrw:Alias )->( DBSkip( - 1 ) )
            ENDDO
         ENDIF
      ENDIF
      oBrw:nLastRecordFilter := FltRecNo( oBrw )
   ELSE
      FltGoTo( oBrw, oBrw:nLastRecordFilter )
   ENDIF
   RETURN NIL

STATIC FUNCTION FltBOF( oBrw )
   LOCAL lRet := .F., nRecord
   LOCAL xValue, xFirstValue
   IF ( oBrw:Alias )->( Bof() )
      lRet := .T.
   ELSE
      nRecord := FltRecNo( oBrw )
      xValue := ( oBrw:Alias )->( OrdKeyNo() ) //&(cKey)
      FltGoTop( oBrw )
      xFirstValue := ( oBrw:Alias )->( OrdKeyNo() ) //&(cKey)

      IF xValue < xFirstValue
         lRet := .T.
         FltGoTop( oBrw )
      ELSE
         FltGoTo( oBrw, nRecord )
      ENDIF
   ENDIF
   RETURN lRet

STATIC FUNCTION FltEOF( oBrw )
   LOCAL lRet := .F., nRecord
   LOCAL xValue, xLastValue
   IF ( oBrw:Alias )->( Eof() )
      lRet := .T.
   ELSE
      nRecord := FltRecNo( oBrw )
      xValue := ( oBrw:Alias )->( OrdKeyNo() )
      FltGoBottom( oBrw )
      xLastValue := ( oBrw:Alias )->( OrdKeyNo() )
      IF xValue > xLastValue
         lRet := .T.
         FltGoBottom( oBrw )
         ( oBrw:Alias )->( DBSkip() )
      ELSE
         FltGoTo( oBrw, nRecord )
      ENDIF
   ENDIF
   RETURN lRet

STATIC FUNCTION FltRecCount( oBrw )
   LOCAL nRecord, nCount := 0
   nRecord := FltRecNo( oBrw )
   FltGoTop( oBrw )
   oBrw:aRecnoFilter := {}
   WHILE !( oBrw:Alias )->( Eof() ) .AND. Eval( oBrw:bWhile, oBrw )
      IF Eval( oBrw:bFor, oBrw )
         nCount ++
         IF oBrw:lFilter
            AADD( oBrw:aRecnoFilter, ( oBrw:Alias )->( recno()) )
         ENDIF
      ENDIF
      ( oBrw:Alias )->( DBSkip() )
   ENDDO
   FltGoTo( oBrw, nRecord )
   RETURN nCount

STATIC FUNCTION FltGoTo( oBrw, nRecord )
   HB_SYMBOL_UNUSED( oBrw )
   RETURN ( oBrw:Alias )->( DBGoTo( nRecord ) )

STATIC FUNCTION FltRecNo( oBrw )
   HB_SYMBOL_UNUSED( oBrw )
   RETURN ( oBrw:Alias )->( RecNo() )

//End Implementation by Luiz

STATIC FUNCTION FltRecNoRelative( oBrw )
   HB_SYMBOL_UNUSED( oBrw )
   IF oBrw:lFilter .AND. EMPTY( oBrw:RelationalExpr )
      RETURN ASCAN( oBrw:aRecnoFilter, ( oBrw:Alias )->( RecNo() ) )
   ENDIF
   IF ! Empty( DBFILTER() ) .AND. ( oBrw:Alias )->( RecNo() ) > oBrw:nRecords
      RETURN oBrw:nRecords
   ENDIF
   RETURN ( oBrw:Alias )->( RecNo() )

STATIC FUNCTION LenVal( xVal, cType, cPict )
   LOCAL nLen

   IF ! ISCHARACTER( cType )
      cType := ValType( xVal )
   ENDIF

   SWITCH cType
   CASE "L"
      nLen := 1
      EXIT

   CASE "N"
   CASE "C"
   CASE "D"
      IF ! Empty( cPict )
         nLen := Len( Transform( xVal, cPict ) )
         EXIT
      ENDIF

      SWITCH cType
      CASE "N"
         nLen := Len( Str( xVal ) )
         EXIT

      CASE "C"
         nLen := Len( xVal )
         EXIT

      CASE "D"
         nLen := Len( DToC( xVal ) )
         EXIT
      END
      EXIT

#ifdef __XHARBOUR__
   DEFAULT
#else
   OTHERWISE
#endif
      nLen := 0

   END

   RETURN nLen
   
