/*
 * $Id: hbrowse.prg,v 1.66 2006-08-31 12:49:22 alkresin Exp $
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
#include "inkey.ch"
#include "dbstruct.ch"
#include "hbclass.ch"
#include "guilib.ch"

REQUEST DBGOTOP
REQUEST DBGOTO
REQUEST DBGOBOTTOM
REQUEST DBSKIP
REQUEST RECCOUNT
REQUEST RECNO
REQUEST EOF
REQUEST BOF

/*
 * Scroll Bar Constants
 */
#define SB_HORZ             0
#define SB_VERT             1
#define SB_CTL              2
#define SB_BOTH             3

#define HDM_GETITEMCOUNT    4608

static ColSizeCursor := 0
static arrowCursor := 0
static oCursor     := 0
static xDrag

//----------------------------------------------------//
CLASS HColumn INHERIT HObject

   DATA block,heading,footing,width,type
   DATA length INIT 0
   DATA dec,cargo
   DATA nJusHead, nJusLin        // Para poder Justificar los Encabezados
                                 // de las columnas y lineas.
                                 // WHT. 27.07.2002
   DATA tcolor,bcolor,brush
   DATA oFont
   DATA lEditable INIT .F.       // Is the column editable
   DATA aList                    // Array of possible values for a column -
                                 // combobox will be used while editing the cell
   DATA aBitmaps
   DATA bValid,bWhen             // When and Valid codeblocks for cell editing
   DATA bEdit                    // Codeblock, which performs cell editing, if defined
   DATA cGrid
   DATA lSpandHead INIT .F.
   DATA lSpandFoot INIT .F.
   DATA Picture
   DATA bHeadClick
   DATA bColorBlock              //   bColorBlock must return an array containing four colors values
                                 //   oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
                                 //      {textColor, backColor, textColorSel, backColorSel} , ;
                                 //      {textColor, backColor, textColorSel, backColorSel} ) }
   METHOD New( cHeading,block,type,length,dec,lEditable,nJusHead,nJusLin,cPict,bValid,bWhen,aItem,bColorBlock )

ENDCLASS

//----------------------------------------------------//
METHOD New( cHeading,block,type,length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock ) CLASS HColumn

   ::heading   := iif( cHeading == nil,"",cHeading )
   ::block     := block
   ::type      := type
   ::length    := length
   ::dec       := dec
   ::lEditable := Iif( lEditable != Nil,lEditable,.F. )
   ::nJusHead  := iif( nJusHead == nil,  DT_LEFT , nJusHead )  // Por default
   ::nJusLin   := iif( nJusLin  == nil,  DT_LEFT , nJusLin  )  // Justif.Izquierda
   ::picture   := cPict
   ::bValid    := bValid
   ::bWhen     := bWhen
   ::aList     := aItem
   ::bColorBlock := bColorBlock

RETURN Self

//----------------------------------------------------//
CLASS HBrowse INHERIT HControl

   DATA winclass   INIT "BROWSE"
   DATA active     INIT .T.
   DATA lChanged   INIT .F.
   DATA lDispHead  INIT .T.                    // Should I display headers ?
   DATA lDispSep   INIT .T.                    // Should I display separators ?
   DATA aColumns                               // HColumn's array
   DATA aColAlias  INIT {}
   DATA aRelation  INIT .F.
   DATA rowCount                               // Number of visible data rows
   DATA rowPos     INIT 1                      // Current row position
   DATA rowCurrCount INIT 0                    // Current number of rows
   DATA colPos     INIT 1                      // Current column position
   DATA nColumns                               // Number of visible data columns
   DATA nLeftCol                               // Leftmost column
   DATA xpos
   DATA freeze                                 // Number of columns to freeze
   DATA kolz                                   // Number of records in browse
   DATA tekzp      INIT 1
   DATA msrec
   DATA recCurr INIT 0
   DATA headColor                              // Header text color
   DATA sepColor INIT 12632256                 // Separators color
   DATA lSep3d  INIT .F.
   DATA varbuf                                 // Used on Edit()
   DATA tcolorSel,bcolorSel,brushSel
   DATA bSkip,bGoTo,bGoTop,bGoBot,bEof,bBof
   DATA bRcou,bRecno,bRecnoLog
   DATA bPosChanged, bLineOut
   DATA bScrollPos                             // Called when user move browse through vertical scroll bar
   DATA bHScrollPos                            // Called when user move browse through horizontal scroll bar
   DATA bEnter, bKeyDown, bUpdate
   DATA internal
   DATA alias                                  // Alias name of browsed database
   DATA x1,y1,x2,y2,width,height
   DATA minHeight INIT 0
   DATA lEditable INIT .F.
   DATA lAppable  INIT .F.
   DATA lAppMode  INIT .F.
   DATA lAutoEdit INIT .F.
   DATA lUpdated  INIT .F.
   DATA lAppended INIT .F.
   DATA lAdjRight INIT .T.                     // Adjust last column to right
   DATA nHeadRows INIT 1                       // Rows in header
   DATA nFootRows INIT 0                       // Rows in footer
   DATA lResizing INIT .F.                     // .T. while a column resizing is undergoing
   // inicio bloco sauli - para controlar multiselecao
   DATA lCtrlPress INIT .F.
   DATA aSelected
   // fim bloco sauli

   METHOD New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
                  bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,lNoBorder,;
                  lAppend,lAutoedit,bUpdate,bKeyDown,bPosChg,lMultiSelect )
   METHOD InitBrw( nType )
   METHOD Rebuild()
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Redefine( lType,oWnd,nId,oFont,bInit,bSize,bPaint,bEnter,bGfocus,bLfocus )
   METHOD FindBrowse( nId )
   METHOD AddColumn( oColumn )
   METHOD InsColumn( oColumn,nPos )
   METHOD DelColumn( nPos )
   METHOD Paint()
   METHOD LineOut()
   METHOD HeaderOut( hDC )
   METHOD FooterOut( hDC )
   METHOD SetColumn( nCol )
   METHOD DoHScroll( wParam )
   METHOD DoVScroll( wParam )
   METHOD LineDown(lMouse)
   METHOD LineUp()
   METHOD PageUp()
   METHOD PageDown()
   METHOD Bottom(lPaint)
   METHOD Top()
   METHOD ButtonDown( lParam )
   METHOD ButtonUp( lParam )
   METHOD ButtonDbl( lParam )
   METHOD MouseMove( wParam, lParam )
   METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos )
   METHOD Edit( wParam,lParam )
   METHOD Append() INLINE (::Bottom(.F.),::LineDown())
   METHOD RefreshLine()
   METHOD Refresh( lFull )
   METHOD ShowSizes()
   METHOD End()

ENDCLASS

//----------------------------------------------------//
METHOD New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
                  bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,;
                  lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown,bPosChg,lMultiSelect ) CLASS HBrowse

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_CHILD+WS_VISIBLE+  ;
                    Iif(lNoBorder=Nil.OR.!lNoBorder,WS_BORDER,0)+            ;
                    Iif(lNoVScroll=Nil.OR.!lNoVScroll,WS_VSCROLL,0) )

   Super:New( oWndParent,nId,nStyle,nLeft,nTop,Iif( nWidth==Nil,0,nWidth ), ;
             Iif( nHeight==Nil,0,nHeight ),oFont,bInit,bSize,bPaint )

   ::type    := lType
   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bGetFocus   := bGFocus
   ::bLostFocus  := bLFocus

   ::lAppable    := Iif( lAppend==Nil,.F.,lAppend )
   ::lAutoEdit   := Iif( lAutoedit==Nil,.F.,lAutoedit )
   ::bUpdate     := bUpdate
   ::bKeyDown    := bKeyDown
   ::bPosChanged := bPosChg
   IF lMultiSelect != Nil .AND. lMultiSelect
      ::aSelected := {}
   ENDIF

   hwg_RegBrowse()
   ::InitBrw()
   ::Activate()

RETURN Self

//----------------------------------------------------//
METHOD Activate CLASS HBrowse
   IF ::oParent:handle != 0
      ::handle := CreateBrowse( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD onEvent( msg, wParam, lParam )  CLASS HBrowse
Local aCoors, oParent, cKeyb, nCtrl, nPos
Static keyCode := 0

   // WriteLog( "Brw: "+Str(::handle,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF ::active .AND. !Empty( ::aColumns )

      IF ::bOther != Nil
         Eval( ::bOther,Self,msg,wParam,lParam )
      ENDIF

      IF msg == WM_PAINT
         ::Paint()
         RETURN 1

      ELSEIF msg == WM_ERASEBKGND
         IF ::brush != Nil
            aCoors := GetClientRect( ::handle )
            FillRect( wParam, aCoors[1], aCoors[2], aCoors[3]+1, aCoors[4]+1, ::brush:handle )
            RETURN 1
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
         ::DoHScroll( wParam )

      ELSEIF msg == WM_VSCROLL
         ::DoVScroll( wParam )

      ELSEIF msg == WM_GETDLGCODE
         IF wParam != 0
            keyCode := wParam
         ENDIF
         RETURN 1

      ELSEIF msg == WM_COMMAND
         // Super:onEvent( WM_COMMAND )
         DlgCommand( Self, wParam, lParam )

      ELSEIF msg == WM_KEYUP
         // inicio bloco sauli
         IF wParam == 17
            ::lCtrlPress := .F.
         ENDIF
         // fim bloco sauli
         IF wParam == 13 .AND. keyCode == 13
            keyCode := 0
            ::Edit()
         ENDIF
         IF wParam != 16 .AND. wParam != 17 .AND. wParam != 18
            oParent := ::oParent
            DO WHILE oParent != Nil .AND. !__ObjHasMsg( oParent,"GETLIST" )
               oParent := oParent:oParent
            ENDDO
            IF oParent != Nil .AND. !Empty( oParent:KeyList )
               cKeyb := GetKeyboardState()
               nCtrl := Iif( Asc(Substr(cKeyb,VK_CONTROL+1,1))>=128,FCONTROL,Iif( Asc(Substr(cKeyb,VK_SHIFT+1,1))>=128,FSHIFT,0 ) )
               IF ( nPos := Ascan( oParent:KeyList,{|a|a[1]==nCtrl.AND.a[2]==wParam} ) ) > 0
                  Eval( oParent:KeyList[ nPos,3 ], Self )
               ENDIF
            ENDIF
         ENDIF

         RETURN 1

      ELSEIF msg == WM_KEYDOWN
         IF ::bKeyDown != Nil
            IF !Eval( ::bKeyDown,Self,wParam )
               RETURN 1
            ENDIF
         ENDIF
         IF wParam == 40        // Down
            ::LINEDOWN()
         ELSEIF wParam == 38    // Up
            ::LINEUP()
         ELSEIF wParam == 39    // Right
            ::DoHScroll( SB_LINERIGHT )
         ELSEIF wParam == 37    // Left
            ::DoHScroll( SB_LINELEFT )
         ELSEIF wParam == 36    // Home
            ::TOP()
         ELSEIF wParam == 35    // End
            ::BOTTOM()
         ELSEIF wParam == 34    // PageDown
            ::PageDown()
         ELSEIF wParam == 33    // PageUp
            ::PageUp()
         ELSEIF wParam == 13    // Enter
            ::Edit()
         // inicio bloco sauli
         ELSEIF wParam == 17
            ::lCtrlPress := .T.
         // fim bloco sauli
         ELSEIF ::lAutoEdit .AND. (wParam >= 48 .and. wParam <= 90 .or. wParam >= 96 .and. wParam <= 111 )
            ::Edit( wParam,lParam )
         ENDIF
         RETURN 1

      ELSEIF msg == WM_LBUTTONDBLCLK
         ::ButtonDbl( lParam )

      ELSEIF msg == WM_LBUTTONDOWN
         ::ButtonDown( lParam )

      ELSEIF msg == WM_LBUTTONUP
         ::ButtonUp( lParam )

      ELSEIF msg == WM_MOUSEMOVE
         ::MouseMove( wParam, lParam )

      ELSEIF msg == WM_MOUSEWHEEL
         ::MouseWheel( LoWord( wParam ),;
                          If( HiWord( wParam ) > 32768,;
                          HiWord( wParam ) - 65535, HiWord( wParam ) ),;
                          LoWord( lParam ), HiWord( lParam ) )
      ELSEIF msg == WM_DESTROY
         ::End()
      ENDIF

   ENDIF

RETURN -1

//----------------------------------------------------//
METHOD Init CLASS HBrowse

   IF !::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle,Self )
   ENDIF

RETURN Nil


//----------------------------------------------------//
METHOD Redefine( lType,oWndParent,nId,oFont,bInit,bSize,bPaint,bEnter,bGfocus,bLfocus ) CLASS HBrowse

   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit,bSize,bPaint )

   ::type    := lType
   IF oFont == Nil
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter  := bEnter
   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus

   hwg_RegBrowse()
   ::InitBrw()

RETURN Self

//----------------------------------------------------//
METHOD FindBrowse( nId ) CLASS HBrowse
Local i := Ascan( ::aItemsList,{|o|o:id==nId},1,::iItems )

RETURN Iif( i>0,::aItemsList[i],Nil )

//----------------------------------------------------//
METHOD AddColumn( oColumn ) CLASS HBrowse
Local n

   aadd( ::aColumns, oColumn )
   ::lChanged := .T.
   InitColumn( Self, oColumn, Len( ::aColumns ) )

RETURN oColumn

//----------------------------------------------------//
METHOD InsColumn( oColumn,nPos ) CLASS HBrowse

   aadd( ::aColumns,Nil )
   ains( ::aColumns,nPos )
   ::aColumns[ nPos ] := oColumn
   ::lChanged := .T.
   InitColumn( Self, oColumn,nPos )

RETURN oColumn

Static Function InitColumn( oBrw, oColumn, n )

   IF oColumn:type == Nil
      oColumn:type := Valtype( Eval( oColumn:block,,oBrw,n ) )
   ENDIF
   IF oColumn:dec == Nil
      IF oColumn:type == "N" .and. At( '.', Str( Eval( oColumn:block,,oBrw,n ) ) ) != 0
         oColumn:dec := Len( Substr( Str( Eval( oColumn:block,,oBrw,n ) ), ;
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

//----------------------------------------------------//
METHOD DelColumn( nPos ) CLASS HBrowse

   Adel( ::aColumns,nPos )
   Asize( ::aColumns,Len( ::aColumns ) - 1 )
   ::lChanged := .T.
RETURN Nil

//----------------------------------------------------//
METHOD End() CLASS HBrowse

   Super:End()
   IF ::brush != Nil
      ::brush:Release()
      ::brush := Nil
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
      ::brushSel := Nil
   ENDIF

RETURN Nil

//----------------------------------------------------//
METHOD InitBrw( nType )  CLASS HBrowse

   IF nType != Nil
      ::type := nType
   ELSE
      ::aColumns := {}
      ::rowPos    := ::tekzp  := ::colpos := ::nLeftCol := 1
      ::freeze  := ::height := 0
      ::internal  := { 15,1 }
      ::msrec     := Nil

      IF ColSizeCursor == 0
         ColSizeCursor := LoadCursor( IDC_SIZEWE )
         arrowCursor := LoadCursor( IDC_ARROW )
      ENDIF
   ENDIF

   IF ::type == BRW_DATABASE
      ::alias   := Alias()
      ::bSKip   :=  {|o, x| (::alias)->(DBSKIP(x)) }
      ::bGoTop  :=  {|| (::alias)->(DBGOTOP())}
      ::bGoBot  :=  {|| (::alias)->(DBGOBOTTOM())}
      ::bEof    :=  {|| (::alias)->(EOF())}
      ::bBof    :=  {|| (::alias)->(BOF())}
      ::bRcou   :=  {|| (::alias)->(RECCOUNT())}
      ::bRecnoLog := ::bRecno  := {||(::alias)->(RECNO())}
      ::bGoTo   := {|a,n|(::alias)->(DBGOTO(n))}
   ELSEIF ::type == BRW_ARRAY
      ::bSKip   := { | o, x | ARSKIP( o, x ) }
      ::bGoTop  := { | o | o:tekzp := 1 }
      ::bGoBot  := { | o | o:tekzp := o:kolz }
      ::bEof    := { | o | o:tekzp > o:kolz }
      ::bBof    := { | o | o:tekzp == 0 }
      ::bRcou   := { | o | len( o:msrec ) }
      ::bRecnoLog := ::bRecno  := { | o | o:tekzp }
      ::bGoTo   := { | o, n | o:tekzp := n }
      ::bScrollPos := {|o,n,lEof,nPos|VScrollPos(o,n,lEof,nPos)}
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD Rebuild( hDC ) CLASS HBrowse
Local i, j, oColumn, xSize, nColLen, nHdrLen, nCount

   IF ::brush != Nil
      ::brush:Release()
   ENDIF
   IF ::brushSel != Nil
      ::brushSel:Release()
   ENDIF
   IF ::bcolor != Nil
      ::brush     := HBrush():Add( ::bcolor )
      IF hDC != Nil
         SendMessage( ::handle, WM_ERASEBKGND, hDC, 0 )
      ENDIF
   ENDIF
   IF ::bcolorSel != Nil
      ::brushSel  := HBrush():Add( ::bcolorSel )
   ENDIF
   ::nLeftCol  := ::freeze + 1
   // ::tekzp     := ::rowPos := ::colPos := 1
   ::lEditable := .F.

   ::minHeight := 0
   FOR i := 1 TO len( ::aColumns )

      oColumn := ::aColumns[i]

      IF oColumn:lEditable
         ::lEditable := .T.
      ENDIF

      IF oColumn:aBitmaps != Nil
         xSize := 0
         FOR j := 1 TO len( oColumn:aBitmaps )
            xSize := max( xSize, oColumn:aBitmaps[j,2]:nWidth+2 )
            ::minHeight := max( ::minHeight,oColumn:aBitmaps[j,2]:nHeight )
         NEXT
      ELSE
         // xSize := round( (max( len( FldStr( Self,i ) ), len( oColumn:heading ) ) + 2 ) * 8, 0 )
         nColLen := oColumn:length
         IF oColumn:heading != nil
            HdrToken( oColumn:heading, @nHdrLen, @nCount )
            IF ! oColumn:lSpandHead
               nColLen := max( nColLen, nHdrLen )
            ENDIF
            ::nHeadRows := Max(::nHeadRows, nCount)
         ENDIF
         IF oColumn:footing != nil
            HdrToken( oColumn:footing, @nHdrLen, @nCount )
            IF ! oColumn:lSpandFoot
               nColLen := max( nColLen, nHdrLen )
            ENDIF
            ::nFootRows := Max(::nFootRows, nCount)
         ENDIF
         IF ::oFont != Nil
            xSize := round( ( nColLen + 2 ) * ((-::oFont:height)*0.6), 0 )  // Added by Fernando Athayde
         ELSE
            xSize := round( ( nColLen + 2 ) * 6, 0 )
         ENDIF
      ENDIF

      oColumn:width := xSize

   NEXT

   ::lChanged := .F.

RETURN Nil

//----------------------------------------------------//
METHOD Paint()  CLASS HBrowse
Local aCoors, aMetr, i, oldAlias, tmp, nRows
Local pps, hDC
Local oldBkColor, oldTColor

   IF !::active .OR. Empty( ::aColumns )
      RETURN Nil
   ENDIF

   IF ::tcolor == Nil ; ::tcolor := 0 ; ENDIF
   IF ::bcolor == Nil ; ::bcolor := VColor( "FFFFFF" ) ; ENDIF
   IF ::tcolorSel == Nil ; ::tcolorSel := VColor( "FFFFFF" ) ; ENDIF
   IF ::bcolorSel == Nil ; ::bcolorSel := VColor( "808080" ) ; ENDIF

   pps := DefinePaintStru()
   hDC := BeginPaint( ::handle, pps )

   IF ::ofont != Nil
      SelectObject( hDC, ::ofont:handle )
   ENDIF
   IF ::brush == Nil .OR. ::lChanged
      ::Rebuild(hDC)
   ENDIF
   aCoors := GetClientRect( ::handle )
   aMetr := GetTextMetric( hDC )
   ::width := Round( ( aMetr[ 3 ] + aMetr[ 2 ] ) / 2 - 1,0 )
   ::height := Max( aMetr[ 1 ], ::minHeight ) + 1
   ::x1 := aCoors[ 1 ]
   ::y1 := aCoors[ 2 ] + Iif( ::lDispHead, ::height*::nHeadRows, 0 )
   ::x2 := aCoors[ 3 ]
   ::y2 := aCoors[ 4 ]

   ::kolz := eval( ::bRcou,Self )
   IF ::tekzp > ::kolz .AND. ::kolz > 0
      ::tekzp := ::kolz
   ENDIF

   ::nColumns := FLDCOUNT( Self, ::x1 + 2, ::x2 - 2, ::nLeftCol )
   ::rowCount := Int( (::y2-::y1) / (::height+1) ) - ::nFootRows
   nRows := Min( ::kolz,::rowCount )

   IF ::internal[1] == 0
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval( ::bSkip, Self, ::internal[2]-::rowPos )
      ENDIF
      // bloco sauli - multiselect
      if ascan(::aSelected, {|x| x=Eval( ::bRecno,Self )}) > 0
         ::LineOut( ::internal[2], 0, hDC, .T. )
      else
         ::LineOut( ::internal[2], 0, hDC, .F. )
      end
      // fim bloco sauli
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval( ::bSkip, Self, ::rowPos-::internal[2] )
      ENDIF
   ELSE
      IF Eval( ::bEof,Self )
         Eval( ::bGoTop, Self )
         ::rowPos := 1
      ENDIF
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF
      tmp := Eval( ::bRecno,Self )
      IF ::rowPos > 1
         Eval( ::bSkip, Self,-(::rowPos-1) )
      ENDIF
      i := 1
      DO WHILE .T.
         IF Eval( ::bRecno,Self ) == tmp
            ::rowPos := i
         ENDIF
         IF i > nRows .OR. Eval( ::bEof,Self )
            EXIT
         ENDIF
         // bloco sauli - multiselect
         if ascan(::aSelected, {|x| x=Eval( ::bRecno,Self )}) > 0
            ::LineOut( i, 0, hDC, .T. )
         else
            ::LineOut( i, 0, hDC, .F. )
         end
         // fim bloco sauli
         i ++
         Eval( ::bSkip, Self,1 )
      ENDDO
      ::rowCurrCount := i - 1

      IF ::rowPos >= i
         ::rowPos := Iif( i > 1,i - 1,1 )
      ENDIF
      DO WHILE i <= nRows
         // bloco sauli - multiselect
         if ascan(::aSelected, {|x| x=Eval( ::bRecno,Self )}) > 0
            ::LineOut( i, 0, hDC, .t.,.T. )
         else
            ::LineOut( i, 0, hDC, .F.,.T. )
         end
         // fim bloco sauli
         i ++
      ENDDO

      Eval( ::bGoTo, Self,tmp )
   ENDIF
   IF ::lAppMode
      ::LineOut( nRows+1, 0, hDC, .F.,.T. )
   ENDIF

   ::LineOut( ::rowPos, Iif( ::lEditable, ::colpos, 0 ), hDC, .T. )

   IF Checkbit( ::internal[1],1 ) .OR. ::lAppMode
      ::HeaderOut( hDC )
      IF ::nFootRows > 0
         ::FooterOut( hDC )
      ENDIF
   ENDIF

   EndPaint( ::handle, pps )
   ::internal[1] := 15
   ::internal[2] := ::rowPos
   tmp := eval( ::bRecno,Self )
   IF ::recCurr != tmp
      ::recCurr := tmp
      IF ::bPosChanged != Nil
         Eval( ::bPosChanged,Self )
      ENDIF
   ENDIF

   IF ::lAppMode
      ::Edit()
   ENDIF

   IF ( tmp := GetFocus() ) == ::oParent:handle .OR. ;
         ::oParent:FindControl(,tmp) != Nil
      SetFocus( ::handle )
   ENDIF
   ::lAppMode := .F.

RETURN Nil

//----------------------------------------------------//
METHOD HeaderOut( hDC ) CLASS HBrowse
Local i, x, oldc, fif, xSize
Local nRows := Min( ::kolz+Iif(::lAppMode,1,0),::rowCount )
Local oPen, oldBkColor := SetBkColor( hDC,GetSysColor(COLOR_3DFACE) )
Local oColumn, nLine, cStr, cNWSE, oPenHdr, oPenLight

   IF ::lDispSep
      oPen := HPen():Add( PS_SOLID,1,::sepColor )
      SelectObject( hDC, oPen:handle )
   ENDIF
   IF ::lSep3d
      oPenLight := HPen():Add( PS_SOLID,1,GetSysColor(COLOR_3DHILIGHT) )
   ENDIF

   x := ::x1
   IF ::headColor <> Nil
      oldc := SetTextColor( hDC,::headColor )
   ENDIF
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      IF ::lAdjRight .and. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      IF ::lDispHead .AND. !::lAppMode
         IF oColumn:cGrid == nil
            DrawButton( hDC, x-1,::y1-::height*::nHeadRows,x+xSize-1,::y1+1,1 )
         ELSE
            DrawButton( hDC, x-1,::y1-::height*::nHeadRows,x+xSize-1,::y1+1,0 )
            IF oPenHdr == nil
               oPenHdr := HPen():Add( BS_SOLID,1,0 )
            ENDIF
            SelectObject( hDC, oPenHdr:handle )
            cStr := oColumn:cGrid + ';'
            FOR nLine := 1 TO ::nHeadRows
               cNWSE := __StrToken(@cStr, nLine, ';')
               IF At('S', cNWSE) != 0
                  DrawLine(hDC, x-1, ::y1-(::height)*(::nHeadRows-nLine), x+xSize-1, ::y1-(::height)*(::nHeadRows-nLine))
               ENDIF
               IF At('N', cNWSE) != 0
                  DrawLine(hDC, x-1, ::y1-(::height)*(::nHeadRows-nLine+1), x+xSize-1, ::y1-(::height)*(::nHeadRows-nLine+1))
               ENDIF
               IF At('E', cNWSE) != 0
                  DrawLine(hDC, x+xSize-2, ::y1-(::height)*(::nHeadRows-nLine+1)+1, x+xSize-2, ::y1-(::height)*(::nHeadRows-nLine))
               ENDIF
               IF At('W', cNWSE) != 0
                  DrawLine(hDC, x-1, ::y1-(::height)*(::nHeadRows-nLine+1)+1, x-1, ::y1-(::height)*(::nHeadRows-nLine))
               ENDIF
            NEXT
            SelectObject( hDC, oPen:handle )
         ENDIF
         // Ahora Titulos Justificados !!!
         cStr := oColumn:heading + ';'
         FOR nLine := 1 TO ::nHeadRows
            DrawText( hDC, __StrToken(@cStr, nLine, ';'), x, ::y1-(::height)*(::nHeadRows-nLine+1)+1, x+xSize-1,::y1-(::height)*(::nHeadRows-nLine),;
               oColumn:nJusHead  + if(oColumn:lSpandHead, DT_NOCLIP, 0) )
         NEXT
      ENDIF
      IF ::lDispSep .AND. x > ::x1
         IF ::lSep3d
            SelectObject( hDC, oPenLight:handle )
            DrawLine( hDC, x-1, ::y1+1, x-1, ::y1+(::height+1)*nRows )
            SelectObject( hDC, oPen:handle )
            DrawLine( hDC, x-2, ::y1+1, x-2, ::y1+(::height+1)*nRows )
         ELSE
            DrawLine( hDC, x-1, ::y1+1, x-1, ::y1+(::height+1)*nRows )
         ENDIF
      ENDIF
      x += xSize
      IF ! ::lAdjRight .and. fif == Len( ::aColumns )
         DrawLine( hDC, x-1, ::y1-(::height*::nHeadRows), x-1, ::y1+(::height+1)*nRows )
      ENDIF
      fif := Iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         exit
      ENDIF
   ENDDO

   IF ::lDispSep
      FOR i := 1 TO nRows
         DrawLine( hDC, ::x1, ::y1+(::height+1)*i, iif(::lAdjRight, ::x2, x), ::y1+(::height+1)*i )
      NEXT
   ENDIF

   SetBkColor( hDC,oldBkColor )
   IF ::headColor <> Nil
      SetTextColor( hDC,oldc )
   ENDIF
   IF ::lDispSep
      oPen:Release()
      IF oPenHdr != nil
         oPenHdr:Release()
      ENDIF
      IF oPenLight != nil
         oPenLight:Release()
      ENDIF
   ENDIF

RETURN Nil

//----------------------------------------------------//
METHOD FooterOut( hDC ) CLASS HBrowse
Local i, x, fif, xSize, oPen, nLine, cStr
Local oColumn

   IF ::lDispSep
      oPen := HPen():Add( BS_SOLID,1,::sepColor )
      SelectObject( hDC, oPen:handle )
   ENDIF

   x := ::x1
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      IF ::lAdjRight .and. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      ENDIF
      IF oColumn:footing <> nil
         cStr := oColumn:footing + ';'
         FOR nLine := 1 TO ::nFootRows
            DrawText( hDC, __StrToken(@cStr, nLine, ';'),;
               x, ::y1+(::rowCount+nLine-1)*(::height+1)+1, x+xSize-1, ::y1+(::rowCount+nLine)*(::height+1),;
               oColumn:nJusLin + if(oColumn:lSpandFoot, DT_NOCLIP, 0) )
         NEXT
      ENDIF
      x += xSize
      fif := Iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         exit
      ENDIF
   ENDDO

   IF ::lDispSep
      DrawLine( hDC, ::x1, ::y1+(::rowCount)*(::height+1)+1, iif(::lAdjRight, ::x2, x), ::y1+(::rowCount)*(::height+1)+1 )
      oPen:Release()
   ENDIF

RETURN Nil

//----------------------------------------------------//
METHOD LineOut( nstroka, vybfld, hDC, lSelected, lClear ) CLASS HBrowse
Local x, dx, i := 1, shablon, sviv, fldname, slen, xSize
Local j, ob, bw, bh, y1, hBReal
Local oldBkColor, oldTColor, oldBk1Color, oldT1Color
Local oLineBrush := Iif( lSelected, ::brushSel,::brush )
Local lColumnFont := .F.
Local nPaintCol, nPaintRow
Local aCores

   ::xpos := x := ::x1
   IF lClear == Nil ; lClear := .F. ; ENDIF

   IF ::bLineOut != Nil
      Eval( ::bLineOut,Self,lSelected )
   ENDIF
   IF ::kolz > 0
      oldBkColor := SetBkColor( hDC, Iif( lSelected,::bcolorSel,::bcolor ) )
      oldTColor  := SetTextColor( hDC, Iif( lSelected,::tcolorSel,::tcolor ) )
      fldname := SPACE( 8 )
      nPaintCol  := Iif( ::freeze > 0, 1, ::nLeftCol )
      nPaintRow  := nstroka

      WHILE x < ::x2 - 2
         IF ::aColumns[nPaintCol]:bColorBlock != Nil
            aCores := eval(::aColumns[nPaintCol]:bColorBlock)
            IF lSelected
              ::aColumns[nPaintCol]:tColor := aCores[3]
              ::aColumns[nPaintCol]:bColor := aCores[4]
            ELSE
              ::aColumns[nPaintCol]:tColor := aCores[1]
              ::aColumns[nPaintCol]:bColor := aCores[2]
            ENDIF
            ::aColumns[nPaintCol]:brush := HBrush():Add(::aColumns[nPaintCol]:bColor   )
         ENDIF
         xSize := ::aColumns[nPaintCol]:width
         IF ::lAdjRight .and. nPaintCol == LEN( ::aColumns )
            xSize := Max( ::x2 - x, xSize )
         ENDIF
         IF i == ::colpos
            ::xpos := x
         ENDIF

         IF vybfld == 0 .OR. vybfld == i
            IF ::aColumns[nPaintCol]:bColor != Nil .AND. ::aColumns[nPaintCol]:brush == Nil
               ::aColumns[nPaintCol]:brush := HBrush():Add( ::aColumns[nPaintCol]:bColor )
            ENDIF
            hBReal := Iif( ::aColumns[nPaintCol]:brush != Nil, ;
                         ::aColumns[nPaintCol]:brush:handle,   ;
                         oLineBrush:handle )
            FillRect( hDC, x, ::y1+(::height+1)*(nPaintRow-1)+1, x+xSize-Iif(::lSep3d,2,1),::y1+(::height+1)*nPaintRow, hBReal )
            IF !lClear
               IF ::aColumns[nPaintCol]:aBitmaps != Nil .AND. !Empty( ::aColumns[nPaintCol]:aBitmaps )
                  FOR j := 1 TO Len( ::aColumns[nPaintCol]:aBitmaps )
                     IF Eval( ::aColumns[nPaintCol]:aBitmaps[j,1],Eval( ::aColumns[nPaintCol]:block,,Self,nPaintCol ),lSelected )
                        ob := ::aColumns[nPaintCol]:aBitmaps[j,2]
                        IF ob:nHeight > ::height
                           y1 := 0
                           bh := ::height
                           bw := Int( ob:nWidth * ( ob:nHeight / ::height ) )
                           DrawBitmap( hDC, ob:handle,, x, y1+::y1+(::height+1)*(nPaintRow-1)+1, bw, bh )
                        ELSE
                           y1 := Int( (::height-ob:nHeight)/2 )
                           bh := ob:nHeight
                           bw := ob:nWidth
                           DrawTransparentBitmap( hDC, ob:handle, x, y1+::y1+(::height+1)*(nPaintRow-1)+1 )
                        ENDIF
                        // DrawBitmap( hDC, ob:handle,, x, y1+::y1+(::height+1)*(nPaintRow-1)+1, bw, bh )
                        EXIT
                     ENDIF
                  NEXT
               ELSE
                  sviv := FLDSTR( Self,nPaintCol )
                  // Ahora lineas Justificadas !!
                  IF ::aColumns[nPaintCol]:tColor != Nil
                     oldT1Color := SetTextColor( hDC, ::aColumns[nPaintCol]:tColor )
                  ENDIF
                  IF ::aColumns[nPaintCol]:bColor != Nil
                     oldBk1Color := SetBkColor( hDC, ::aColumns[nPaintCol]:bColor )
                  ENDIF
                  IF ::aColumns[nPaintCol]:oFont != Nil
                     SelectObject( hDC, ::aColumns[nPaintCol]:oFont:handle )
                     lColumnFont := .T.
                  ELSEIF lColumnFont
                     SelectObject( hDC, ::ofont:handle )
                     lColumnFont := .F.
                  ENDIF
                  DrawText( hDC, sviv, x, ::y1+(::height+1)*(nPaintRow-1)+1, x+xSize-2,::y1+(::height+1)*nPaintRow-1, ::aColumns[nPaintCol]:nJusLin )
                  IF ::aColumns[nPaintCol]:tColor != Nil
                     SetTextColor( hDC, oldT1Color )
                  ENDIF
                  IF ::aColumns[nPaintCol]:bColor != Nil
                     SetBkColor( hDC, oldBk1Color )
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         x += xSize
         nPaintCol := Iif( nPaintCol = ::freeze, ::nLeftCol, nPaintCol + 1 )
         i ++
         IF ! ::lAdjRight .and. nPaintCol > LEN( ::aColumns )
            EXIT
         ENDIF
      ENDDO
      SetTextColor( hDC,oldTColor )
      SetBkColor( hDC,oldBkColor )
      IF lColumnFont
         SelectObject( hDC, ::ofont:handle )
      ENDIF
   ENDIF
RETURN Nil


//----------------------------------------------------//
METHOD SetColumn( nCol ) CLASS HBrowse
Local nColPos, lPaint := .f.

   IF ::lEditable
      IF nCol != nil .AND. nCol >= 1 .AND. nCol <= Len(::aColumns)
         IF nCol <= ::freeze
            ::colpos := nCol
         ELSEIF nCol >= ::nLeftCol .AND. nCol <= ::nLeftCol + ::nColumns - ::freeze - 1
            ::colpos := nCol - ::nLeftCol + ::freeze + 1
         ELSE
            ::nLeftCol := nCol
            ::colpos := ::freeze + 1
            lPaint := .T.
         ENDIF
         IF !lPaint
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
Local i

   IF oBrw:lEditable
      IF oBrw:colpos < oBrw:nColumns
         oBrw:colpos ++
         RETURN Nil
      ENDIF
   ENDIF
   IF oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len(oBrw:aColumns) ;
        .AND. oBrw:nLeftCol < Len(oBrw:aColumns)
      i := oBrw:nLeftCol + oBrw:nColumns
      DO WHILE oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len(oBrw:aColumns) .AND. oBrw:nLeftCol + oBrw:nColumns = i
         oBrw:nLeftCol ++
      ENDDO
      oBrw:colpos := i - oBrw:nLeftCol + 1
   ENDIF
RETURN Nil

//----------------------------------------------------//
STATIC FUNCTION LINELEFT( oBrw )

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
RETURN Nil

//----------------------------------------------------//
METHOD DoVScroll( wParam ) CLASS HBrowse
Local nScrollCode := LoWord( wParam )

   IF nScrollCode == SB_LINEDOWN
      ::LINEDOWN(.T.)
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

   ELSEIF nScrollCode == SB_THUMBPOSITION
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, SB_THUMBPOSITION, .F., Hiword( wParam ) )
      ENDIF
   ELSEIF nScrollCode == SB_THUMBTRACK
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, SB_THUMBTRACK, .F., Hiword( wParam ) )
      ENDIF
   ENDIF
RETURN 0


//----------------------------------------------------//
METHOD DoHScroll( wParam ) CLASS HBrowse
Local nScrollCode := LoWord( wParam )
Local minPos, maxPos, nPos
Local oldLeft := ::nLeftCol, oldPos := ::colpos, fif
Local lMoveThumb := .T.

   GetScrollRange( ::handle, SB_HORZ, @minPos, @maxPos )
   //nPos := GetScrollPos( ::handle, SB_HORZ )

   IF nScrollCode == SB_LINELEFT .OR. nScrollCode == SB_PAGELEFT
      LineLeft( Self )

   ELSEIF nScrollCode == SB_LINERIGHT .OR. nScrollCode == SB_PAGERIGHT
      LineRight( Self )

   ELSEIF nScrollCode == SB_THUMBPOSITION
      IF ::bHScrollPos != Nil
         Eval( ::bHScrollPos, Self, SB_THUMBPOSITION, .F., Hiword( wParam ) )
         lMoveThumb := .F.
      ENDIF


   ELSEIF nScrollCode == SB_THUMBTRACK
      IF ::bHScrollPos != Nil
         Eval( ::bHScrollPos, Self, SB_THUMBTRACK, .F., Hiword( wParam ) )
         lMoveThumb := .F.
      ENDIF
   ENDIF

   IF ::nLeftCol != oldLeft .OR. ::colpos != oldpos

      /* Move scrollbar thumb if ::bHScrollPos has not been called, since, in this case,
         movement of scrollbar thumb is done by that codeblock
      */
      IF lMoveThumb

         fif := Iif( ::lEditable, ::colpos + ::nLeftCol - 1, ::nLeftCol )
         nPos := Iif( fif == 1, minPos,                        ;
                    Iif( fif = Len( ::aColumns ), maxpos,      ;
                    Int( ( maxPos - minPos + 1 ) * fif / Len( ::aColumns ) ) ) )
         SetScrollPos( ::handle, SB_HORZ, nPos )

      ENDIF

      IF ::nLeftCol == oldLeft
         ::RefreshLine()
      ELSE
         RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
      ENDIF
   ENDIF
   SetFocus( ::handle )

RETURN Nil

//----------------------------------------------------//
METHOD LINEDOWN( lMouse ) CLASS HBrowse
Local minPos, maxPos, nPos

   Eval( ::bSkip, Self,1 )
   IF Eval( ::bEof,Self )
      Eval( ::bSkip, Self,- 1 )
      IF ::lAppable .AND. ( lMouse==Nil.OR.!lMouse )
         ::lAppMode := .T.
      ELSE
         SetFocus( ::handle )
         RETURN Nil
      ENDIF
   ENDIF
   ::rowPos ++
   IF ::rowPos > ::rowCount
      ::rowPos := ::rowCount
      InvalidateRect( ::handle, 0 )
   ELSE
      ::internal[1] := 0
      InvalidateRect( ::handle, 0, ::x1, ::y1+(::height+1)*::internal[2]-::height, ::x2, ::y1+(::height+1)*(::rowPos+1) )
   ENDIF
   IF ::lAppMode
      IF ::rowPos > 1
         ::rowPos --
      ENDIF
      ::colPos := ::nLeftCol := 1
   ENDIF
   IF !::lAppMode  .OR. ::nLeftCol == 1
      ::internal[1] := SetBit( ::internal[1], 1, 0 )
   ENDIF

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, 1, .F. )
   ELSEIF ::kolz > 1
      GetScrollRange( ::handle, SB_VERT, @minPos, @maxPos )
      nPos := GetScrollPos( ::handle, SB_VERT )
      nPos += Int( (maxPos-minPos)/(::kolz-1) )
      SetScrollPos( ::handle, SB_VERT, nPos )
   ENDIF

   PostMessage( ::handle, WM_PAINT, 0, 0 )
   SetFocus( ::handle )

RETURN Nil

//----------------------------------------------------//
METHOD LINEUP() CLASS HBrowse
Local minPos, maxPos, nPos

   Eval( ::bSkip, Self,- 1 )
   IF Eval( ::bBof,Self )
      Eval( ::bGoTop,Self )
   ELSE
      ::rowPos --
      IF ::rowPos = 0
         ::rowPos := 1
         InvalidateRect( ::handle, 0 )
      ELSE
         ::internal[1] := 0
         InvalidateRect( ::handle, 0, ::x1, ::y1+(::height+1)*::internal[2]-::height, ::x2, ::y1+(::height+1)*::internal[2] )
         InvalidateRect( ::handle, 0, ::x1, ::y1+(::height+1)*::rowPos-::height, ::x2, ::y1+(::height+1)*::rowPos )
      ENDIF

      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, -1, .F. )
      ELSEIF ::kolz > 1
         GetScrollRange( ::handle, SB_VERT, @minPos, @maxPos )
         nPos := GetScrollPos( ::handle, SB_VERT )
         nPos -= Int( (maxPos-minPos)/(::kolz-1) )
         SetScrollPos( ::handle, SB_VERT, nPos )
      ENDIF
      ::internal[1] := SetBit( ::internal[1], 1, 0 )
      PostMessage( ::handle, WM_PAINT, 0, 0 )
   ENDIF
   SetFocus( ::handle )
RETURN Nil

//----------------------------------------------------//
METHOD PAGEUP() CLASS HBrowse
Local minPos, maxPos, nPos, step, lBof := .F.

   IF ::rowPos > 1
      step := ( ::rowPos - 1 )
      Eval( ::bSKip, Self,- step )
      ::rowPos := 1
   ELSE
      step := ::rowCurrCount    // Min( ::kolz,::rowCount )
      Eval( ::bSkip, Self,- step )
      IF Eval( ::bBof,Self )
         Eval( ::bGoTop,Self )
         lBof := .T.
      ENDIF
   ENDIF

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, - step, lBof )
   ELSEIF ::kolz > 1
      GetScrollRange( ::handle, SB_VERT, @minPos, @maxPos )
      nPos := GetScrollPos( ::handle, SB_VERT )
      nPos := Max( nPos - Int( (maxPos-minPos)*step/(::kolz-1) ), minPos )
      SetScrollPos( ::handle, SB_VERT, nPos )
   ENDIF

   ::Refresh(.F.)
   SetFocus( ::handle )
RETURN Nil

//----------------------------------------------------//
METHOD PAGEDOWN() CLASS HBrowse
Local minPos, maxPos, nPos, nRows := ::rowCurrCount
Local step := Iif( nRows>::rowPos,nRows-::rowPos+1,nRows )

   Eval( ::bSkip, Self, step )
   ::rowPos := Min( ::kolz, nRows )

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, step, Eval( ::bEof,Self ) )
   ELSE
      GetScrollRange( ::handle, SB_VERT, @minPos, @maxPos )
      nPos := GetScrollPos( ::handle, SB_VERT )
      IF Eval( ::bEof,Self )
         Eval( ::bSkip, Self,- 1 )
         nPos := maxPos
         SetScrollPos( ::handle, SB_VERT, nPos )
      ELSEIF ::kolz > 1
         nPos := Min( nPos + Int( (maxPos-minPos)*step/(::kolz-1) ), maxPos )
         SetScrollPos( ::handle, SB_VERT, nPos )
      ENDIF

   ENDIF

   ::Refresh(.F.)
   SetFocus( ::handle )
RETURN Nil

//----------------------------------------------------//
METHOD BOTTOM(lPaint) CLASS HBrowse
Local minPos, maxPos, nPos

   GetScrollRange( ::handle, SB_VERT, @minPos, @maxPos )

   nPos := GetScrollPos( ::handle, SB_VERT )
   ::rowPos := Lastrec()
   Eval( ::bGoBot, Self )
   ::rowPos := Min( ::kolz, ::rowCount )
   nPos := maxPos
   SetScrollPos( ::handle, SB_VERT, nPos )
   InvalidateRect( ::handle, 0 )

   ::internal[1] := SetBit( ::internal[1], 1, 0 )
   IF lPaint == Nil .OR. lPaint
      PostMessage( ::handle, WM_PAINT, 0, 0 )
      SetFocus( ::handle )
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD TOP() CLASS HBrowse
Local minPos, maxPos, nPos

   GetScrollRange( ::handle, SB_VERT, @minPos, @maxPos )
   nPos := GetScrollPos( ::handle, SB_VERT )
   ::rowPos := 1
   Eval( ::bGoTop,Self )
   nPos := minPos
   SetScrollPos( ::handle, SB_VERT, nPos )
   InvalidateRect( ::handle, 0 )
   ::internal[1] := SetBit( ::internal[1], 1, 0 )
   PostMessage( ::handle, WM_PAINT, 0, 0 )
   SetFocus( ::handle )

RETURN Nil

//----------------------------------------------------//
METHOD ButtonDown( lParam ) CLASS HBrowse
Local hBrw := ::handle
Local nLine := Int( HIWORD(lParam)/(::height+1) + Iif(::lDispHead,1-::nHeadRows,1) )
Local step := nLine - ::rowPos, res := .F., nrec
Local minPos, maxPos, nPos
Local xm := LOWORD(lParam), x1, fif

   x1  := ::x1
   fif := Iif( ::freeze > 0, 1, ::nLeftCol )
   
   DO WHILE fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + ::aColumns[ fif ]:width < xm
      x1 += ::aColumns[ fif ]:width
      fif := Iif( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      IF step != 0
         nrec := Recno()
         Eval( ::bSkip, Self, step )
         IF !Eval( ::bEof,Self )
            ::rowPos := nLine
            IF ::bScrollPos != Nil
               Eval( ::bScrollPos, Self, step, .F. )
            ELSEIF ::kolz > 1
               GetScrollRange( hBrw, SB_VERT, @minPos, @maxPos )
               nPos := GetScrollPos( hBrw, SB_VERT )
               nPos := Min( nPos + Int( (maxPos-minPos)*step/(::kolz-1) ), maxPos )
               SetScrollPos( hBrw, SB_VERT, nPos )
            ENDIF
            res := .T.
         ELSE
            Go nrec
         ENDIF
      ENDIF
      IF ::lEditable

         IF ::colpos != fif - ::nLeftCol + 1 + ::freeze

            // Colpos should not go beyond last column or I get bound errors on ::Edit()
            ::colpos := Min( ::nColumns+1, fif - ::nLeftCol + 1 + ::freeze )
            GetScrollRange( hBrw, SB_HORZ, @minPos, @maxPos )

            nPos := Iif( fif == 1,;
                         minPos,;
                         Iif( fif == Len( ::aColumns ),;
                              maxpos,;
                              Int( ( maxPos - minPos + 1 ) * fif / Len( ::aColumns ) ) ) )

            SetScrollPos( hBrw, SB_HORZ, nPos )
            res := .T.

         ENDIF

      ENDIF

      IF res
         InvalidateRect( hBrw, 0, ::x1, ::y1+(::height+1)*::internal[2]-::height, ::x2, ::y1+(::height+1)*::internal[2] )
         InvalidateRect( hBrw, 0, ::x1, ::y1+(::height+1)*::rowPos-::height, ::x2, ::y1+(::height+1)*::rowPos )
         ::internal[1] := SetBit( ::internal[1], 1, 0 )
         PostMessage( hBrw, WM_PAINT, 0, 0 )
      ENDIF

   ELSEIF ::lDispHead .and.;
          nLine >= -::nHeadRows .and.;
          fif <= Len( ::aColumns ) .AND.;
          ::aColumns[fif]:bHeadClick != nil

      Eval(::aColumns[fif]:bHeadClick, Self, fif)

   ELSEIF nLine == 0
      IF oCursor == ColSizeCursor
         ::lResizing := .T.
         Hwg_SetCursor( oCursor )
         xDrag := LoWord( lParam )
      ENDIF
   ENDIF

RETURN Nil

//----------------------------------------------------//
METHOD ButtonUp( lParam ) CLASS HBrowse
Local hBrw := ::handle
Local xPos := LOWORD(lParam), x, x1, i

   IF ::lResizing
      x := ::x1
      i := ::nLeftCol
      DO WHILE x < xDrag
         x += ::aColumns[i]:width
         IF Abs( x-xDrag ) < 10
            x1 := x - ::aColumns[i]:width
            EXIT
         ENDIF
         i++
      ENDDO
      IF xPos > x1
         ::aColumns[i]:width := xPos - x1
         Hwg_SetCursor( arrowCursor )
         oCursor := 0
         ::lResizing := .F.
         InvalidateRect( hBrw, 0 )
         PostMessage( hBrw, WM_PAINT, 0, 0 )
      ENDIF
   ELSEIF ::aSelected != Nil
      // inicio bloco sauli - multiselect
      IF ::lCtrlPress
         IF ( i := Ascan( ::aSelected, Eval( ::bRecno,Self ) ) ) > 0
            Adel( ::aSelected, i )
            Asize( ::aSelected, Len(::aSelected)-1 )
         ELSE
            Aadd(::aSelected, Eval( ::bRecno,Self ) )
         ENDIF
      ELSE
         IF Len( ::aSelected ) > 0
            ::aSelected := {}
            ::Refresh()
         ENDIF
      ENDIF
      // fim bloco sauli
   ENDIF
   SetFocus( ::handle )
RETURN Nil

//----------------------------------------------------//
METHOD ButtonDbl( lParam ) CLASS HBrowse
Local hBrw := ::handle
Local nLine := Int( HIWORD(lParam)/(::height+1) + Iif(::lDispHead,1-::nHeadRows,1) )

   // writelog( "ButtonDbl"+str(nLine)+ str(::rowCurrCount) )
   IF nLine > 0 .and. nLine <= ::rowCurrCount
      ::ButtonDown( lParam )
      ::Edit()
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD MouseMove( wParam, lParam ) CLASS HBrowse
   Local xPos := LoWord( lParam ), yPos := HiWord( lParam )
   Local x := ::x1, i := ::nLeftCol, res := .F.

   DlgMouseMove()
   IF !::active .OR. Empty( ::aColumns ) .OR. ::x1 == Nil
      RETURN Nil
   ENDIF
   IF ::lDispSep .AND. yPos <= ::height*::nHeadRows+1
      IF wParam == 1 .AND. ::lResizing
         Hwg_SetCursor( oCursor )
         res := .T.
      ELSE
         DO WHILE x < ::x2 - 2 .AND. i <= Len( ::aColumns )
            x += ::aColumns[i++]:width
            IF Abs( x - xPos ) < 8
               IF oCursor != ColSizeCursor
                  oCursor := ColSizeCursor
               ENDIF
               Hwg_SetCursor( oCursor )
               res := .T.
               EXIT
            ENDIF
         ENDDO
      ENDIF
      IF !res .AND. oCursor != 0
         Hwg_SetCursor( arrowCursor )
         oCursor := 0
         ::lResizing := .F.
      ENDIF
   ENDIF
RETURN Nil

//----------------------------------------------------------------------------//
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

//----------------------------------------------------//
METHOD Edit( wParam,lParam ) CLASS HBrowse
Local fipos, lRes, x1, y1, fif, nWidth, lReadExit, rowPos
Local oModDlg, oColumn, aCoors, nChoic, bInit, oGet, type
Local oComboFont, oCombo

   fipos := ::colpos + ::nLeftCol - 1 - ::freeze

   IF ::bEnter == Nil .OR. ;
         ( Valtype( lRes := Eval( ::bEnter, Self, fipos ) ) == 'L' .AND. !lRes )
      oColumn := ::aColumns[fipos]
      IF ::type == BRW_DATABASE
         ::varbuf := (::alias)->(Eval( oColumn:block,,Self,fipos ))
      ELSE
         ::varbuf := Eval( oColumn:block,,Self,fipos )
      ENDIF
      type := Iif( oColumn:type=="U".AND.::varbuf!=Nil, Valtype( ::varbuf ), oColumn:type )
      IF ::lEditable .AND. type != "O"
         IF oColumn:lEditable .AND. ( oColumn:bWhen = Nil .OR. Eval( oColumn:bWhen ) )
            IF ::lAppMode
               IF type == "D"
                  ::varbuf := CtoD("")
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
         fif := Iif( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE fif < fipos
            x1 += ::aColumns[fif]:width
            fif := Iif( fif = ::freeze, ::nLeftCol, fif + 1 )
         ENDDO
         nWidth := Min( ::aColumns[fif]:width, ::x2 - x1 - 1 )
         rowPos := ::rowPos - 1
         IF ::lAppMode .AND. ::kolz != 0
            rowPos ++
         ENDIF
         y1 := ::y1+(::height+1)*rowPos

         // aCoors := GetWindowRect( ::handle )
         // x1 += aCoors[1]
         // y1 += aCoors[2]

         aCoors := ClientToScreen( ::handle,x1,y1 )
         x1 := aCoors[1]
         y1 := aCoors[2]

         lReadExit := Set( _SET_EXIT, .t. )
         bInit := Iif( wParam==Nil, {|o|MoveWindow(o:handle,x1,y1,nWidth,o:nHeight+1)}, ;
            {|o|MoveWindow(o:handle,x1,y1,nWidth,o:nHeight+1),PostMessage(o:aControls[1]:handle,WM_KEYDOWN,wParam,lParam)} )

         INIT DIALOG oModDlg;
            STYLE WS_POPUP + 1 + iif( oColumn:aList == Nil, WS_BORDER, 0 ) ;
            AT x1, y1 - Iif( oColumn:aList == Nil, 1, 0 ) ;
            SIZE nWidth, ::height + Iif( oColumn:aList == Nil, 1, 0 ) ;
            ON INIT bInit

         IF oColumn:aList != Nil
            oModDlg:brush := -1
            oModDlg:nHeight := ::height * 5

            IF valtype(::varbuf) == 'N'
                nChoic := ::varbuf
            ELSE
                ::varbuf := AllTrim(::varbuf)
                nChoic := Ascan( oColumn:aList,::varbuf )
            ENDIF

            /* 21/09/2005 - <maurilio.longo@libero.it>
                            The combobox needs to use a font smaller than the one used
                            by the browser or it will be taller than the browse row that
                            has to contain it.
            */
            oComboFont := iif( Valtype( ::oFont ) == "U",;
                               HFont():Add("MS Sans Serif", 0, -8 ),;
                               HFont():Add( ::oFont:name, ::oFont:width, ::oFont:height + 2 ) )

            @ 0,0 GET COMBOBOX oCombo VAR nChoic ;
               ITEMS oColumn:aList            ;
               SIZE nWidth, ::height * 5      ;
               FONT oComboFont

               IF oColumn:bValid != NIL
                  oCombo:bValid := oColumn:bValid
               ENDIF

         ELSE
            @ 0,0 GET oGet VAR ::varbuf       ;
               SIZE nWidth, ::height+1        ;
               NOBORDER                       ;
               STYLE ES_AUTOHSCROLL           ;
               FONT ::oFont                   ;
               PICTURE oColumn:picture        ;
               VALID oColumn:bValid
         ENDIF

         ACTIVATE DIALOG oModDlg

         IF oColumn:aList != Nil
            oComboFont:Release()
         ENDIF

         IF oModDlg:lResult
            IF oColumn:aList != Nil
               IF valtype(::varbuf) == 'N'
                  ::varbuf := nChoic
               ELSE
                  ::varbuf := oColumn:aList[nChoic]
               ENDIF
            ENDIF
            IF ::lAppMode
               ::lAppMode := .F.
               IF ::type == BRW_DATABASE
                  (::alias)->( dbAppend() )
                  (::alias)->( Eval( oColumn:block,::varbuf,Self,fipos ) )
                  UNLOCK
               ELSE
                  IF Valtype(::msrec[1]) == "A"
                     Aadd( ::msrec,Array(Len(::msrec[1])) )
                     FOR fif := 2 TO Len((::msrec[1]))
                        ::msrec[Len(::msrec),fif] := ;
                              Iif( ::aColumns[fif]:type=="D",Ctod(Space(8)), ;
                                 Iif( ::aColumns[fif]:type=="N",0,"" ) )
                     NEXT
                  ELSE
                     Aadd( ::msrec,Nil )
                  ENDIF
                  ::tekzp := Len( ::msrec )
                  Eval( oColumn:block,::varbuf,Self,fipos )
               ENDIF
               IF ::kolz > 0
                  ::rowPos ++
               ENDIF
               ::lAppended := .T.
               ::Refresh()
            ELSE
               IF ::type == BRW_DATABASE
                  IF (::alias)->( Rlock() )
                     (::alias)->( Eval( oColumn:block,::varbuf,Self,fipos ) )
                  ELSE
                     MsgStop("Can't lock the record!")
                  ENDIF
               ELSE
                  Eval( oColumn:block,::varbuf,Self,fipos )
               ENDIF

               ::lUpdated := .T.
               InvalidateRect( ::handle, 0, ::x1, ::y1+(::height+1)*(::rowPos-2), ::x2, ::y1+(::height+1)*::rowPos )
               ::RefreshLine()
            ENDIF

            /* Execute block after changes are made */
            IF ::bUpdate != nil
                Eval( ::bUpdate,  Self, fipos )
            END

         ELSEIF ::lAppMode
            ::lAppMode := .F.
            InvalidateRect( ::handle, 0, ::x1, ::y1+(::height+1)*::rowPos, ::x2, ::y1+(::height+1)*(::rowPos+2) )
            ::RefreshLine()
         ENDIF
         SetFocus( ::handle )
         Set(_SET_EXIT, lReadExit )

      ENDIF
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD RefreshLine() CLASS HBrowse

   ::internal[1] := 0
   InvalidateRect( ::handle, 0, ::x1, ::y1+(::height+1)*::rowPos-::height, ::x2, ::y1+(::height+1)*::rowPos )
   SendMessage( ::handle, WM_PAINT, 0, 0 )
RETURN Nil

//----------------------------------------------------//
METHOD Refresh( lFull ) CLASS HBrowse

   IF lFull == Nil .OR. lFull
      ::internal[1] := 15
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ELSE
      InvalidateRect( ::handle, 0 )
      ::internal[1] := SetBit( ::internal[1], 1, 0 )
      PostMessage( ::handle, WM_PAINT, 0, 0 )
   ENDIF
RETURN Nil

//----------------------------------------------------//
STATIC FUNCTION FldStr( oBrw,numf )
Local cRes, vartmp, type, pict

   IF numf <= Len( oBrw:aColumns )

      pict := oBrw:aColumns[numf]:picture

      IF pict != nil
         IF oBrw:type == BRW_DATABASE
             IF oBrw:aRelation
                cRes := (oBrw:aColAlias[numf])->(Transform(Eval( oBrw:aColumns[numf]:block,,oBrw,numf ), pict))
             ELSE
                cRes := (oBrw:alias)->(Transform(Eval( oBrw:aColumns[numf]:block,,oBrw,numf ), pict))
             ENDIF
         ELSE
             cRes := Transform(Eval( oBrw:aColumns[numf]:block,,oBrw,numf ), pict)
         ENDIF
      ELSE
         IF oBrw:type == BRW_DATABASE
             IF oBrw:aRelation
                 vartmp := (oBrw:aColAlias[numf])->(Eval( oBrw:aColumns[numf]:block,,oBrw,numf ))
             ELSE
                 vartmp := (oBrw:alias)->(Eval( oBrw:aColumns[numf]:block,,oBrw,numf ))
             ENDIF
         ELSE
             vartmp := Eval( oBrw:aColumns[numf]:block,,oBrw,numf )
         ENDIF

         type := (oBrw:aColumns[numf]):type
         IF type == "U" .AND. vartmp != Nil
            type := Valtype( vartmp )
         ENDIF
         IF type == "C"
            cRes := Padr( vartmp, oBrw:aColumns[numf]:length )

         ELSEIF type == "N"
            cRes := Padl( STR( vartmp, oBrw:aColumns[numf]:length, ;
                   oBrw:aColumns[numf]:dec ),oBrw:aColumns[numf]:length )
         ELSEIF type == "D"
            cRes := Padr( DTOC( vartmp ),oBrw:aColumns[numf]:length )

         ELSEIF type == "L"
            cRes := Padr( Iif( vartmp, "T", "F" ),oBrw:aColumns[numf]:length )

         ELSEIF type == "M"
            cRes := "<Memo>"

         ELSEIF type == "O"
            cRes := "<" + vartmp:Classname() + ">"

         ELSEIF type == "A"
            cRes := "<Array>"

         ELSE
            cRes := Space( oBrw:aColumns[numf]:length )
         ENDIF
      ENDIF
   ENDIF

RETURN cRes

//----------------------------------------------------//
STATIC FUNCTION FLDCOUNT( oBrw, xstrt, xend, fld1 )
Local klf := 0, i := Iif( oBrw:freeze > 0, 1, fld1 )

   DO WHILE .T.
      // xstrt += ( MAX( oBrw:aColumns[i]:length, LEN( oBrw:aColumns[i]:heading ) ) - 1 ) * oBrw:width
      xstrt += oBrw:aColumns[i]:width
      IF xstrt > xend
         EXIT
      ENDIF
      klf ++
      i   := Iif( i = oBrw:freeze, fld1, i + 1 )
      // xstrt += 2 * oBrw:width
      IF i > Len(oBrw:aColumns)
         EXIT
      ENDIF
   ENDDO
RETURN Iif( klf = 0, 1, klf )


//----------------------------------------------------//
FUNCTION CREATEARLIST( oBrw, arr )
   Local i
   oBrw:type  := BRW_ARRAY
   oBrw:msrec := arr
   IF Len( oBrw:aColumns ) == 0
      // oBrw:aColumns := {}
      IF Valtype( arr[1] ) == "A"
         FOR i := 1 TO Len( arr[1] )
            oBrw:AddColumn( HColumn():New( ,ColumnArBlock() ) )
         NEXT
      ELSE
         oBrw:AddColumn( HColumn():New( ,{|value,o| o:msrec[ o:tekzp ] } ) )
      ENDIF
   ENDIF
   Eval( oBrw:bGoTop,oBrw )
   oBrw:Refresh()
RETURN Nil

//----------------------------------------------------//
PROCEDURE ARSKIP( oBrw, kolskip )
Local tekzp1

   IF oBrw:kolz != 0
      tekzp1   := oBrw:tekzp
      oBrw:tekzp += kolskip + Iif( tekzp1 = 0, 1, 0 )
      IF oBrw:tekzp < 1
         oBrw:tekzp := 0
      ELSEIF oBrw:tekzp > oBrw:kolz
         oBrw:tekzp := oBrw:kolz + 1
      ENDIF
   ENDIF
RETURN

//----------------------------------------------------//
FUNCTION CreateList( oBrw,lEditable )
Local i
Local nArea := Select()
Local kolf := Fcount()

   oBrw:alias   := Alias()

   oBrw:aColumns := {}
   FOR i := 1 TO kolf
      oBrw:AddColumn( HColumn():New( Fieldname(i),                      ;
                                     FieldWBlock( Fieldname(i),nArea ), ;
                                     dbFieldInfo( DBS_TYPE,i ),         ;
                                     iif(dbFieldInfo( DBS_TYPE,i )=="D".AND.__SetCentury(),10,dbFieldInfo( DBS_LEN,i )), ;
                                     dbFieldInfo( DBS_DEC,i ),          ;
                                     lEditable ) )
   NEXT

   oBrw:Refresh()

RETURN Nil

Function VScrollPos( oBrw, nType, lEof, nPos )
Local minPos, maxPos, oldRecno, newRecno

   GetScrollRange( oBrw:handle, SB_VERT, @minPos, @maxPos )
   IF nPos == Nil
      IF nType > 0 .AND. lEof
         Eval( oBrw:bSkip, oBrw,- 1 )
      ENDIF
      nPos := Iif( oBrw:kolz>1, Round( ( (maxPos-minPos)/(oBrw:kolz-1) ) * ;
                                 ( Eval( oBrw:bRecnoLog,oBrw )-1 ),0 ), minPos )
      SetScrollPos( oBrw:handle, SB_VERT, nPos )
   ELSE
      oldRecno := Eval( oBrw:bRecnoLog,oBrw )
      newRecno := Round( (oBrw:kolz-1)*nPos/(maxPos-minPos)+1,0 )
      IF newRecno <= 0
         newRecno := 1
      ELSEIF newRecno > oBrw:kolz
         newRecno := oBrw:kolz
      ENDIF
      IF nType == SB_THUMBPOSITION
         SetScrollPos( oBrw:handle, SB_VERT, nPos )
      ENDIF
      IF newRecno != oldRecno
         Eval( oBrw:bSkip, oBrw, newRecno - oldRecno )
         IF oBrw:rowCount - oBrw:rowPos > oBrw:kolz - newRecno
            oBrw:rowPos := oBrw:rowCount - ( oBrw:kolz - newRecno )
         ENDIF
         IF oBrw:rowPos > newRecno
            oBrw:rowPos := newRecno
         ENDIF
         oBrw:Refresh(.F.)
      ENDIF
   ENDIF

RETURN Nil



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


//----------------------------------------------------//
// Agregado x WHT. 27.07.02
// Locus metodus.
METHOD ShowSizes() CLASS HBrowse
Local cText := ""

   Aeval( ::aColumns,;
          { | v,e | cText += ::aColumns[e]:heading + ": " + str( round(::aColumns[e]:width/8,0)-2  ) + chr(10)+chr(13) } )
   MsgInfo( cText )
RETURN nil

Function ColumnArBlock()
RETURN {|value,o,n| Iif( value==Nil,o:msrec[o:tekzp,n],o:msrec[o:tekzp,n]:=value ) }

Static function HdrToken(cStr, nMaxLen, nCount)
Local nL, nPos := 0

   nMaxLen := nCount := 0
   cStr += ';'
   DO WHILE (nL := Len(__StrTkPtr(@cStr, @nPos, ";"))) != 0
      nMaxLen := Max( nMaxLen, nL )
      nCount ++
   ENDDO
RETURN nil

