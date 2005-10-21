/*
 * $Id: hbrowse.prg,v 1.12 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HBrowse class - browse databases and arrays
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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

/*
 * Scroll Bar Constants
 */
#define SB_HORZ             0
#define SB_VERT             1
#define SB_CTL              2
#define SB_BOTH             3

#define HDM_GETITEMCOUNT    4608

#define GDK_BackSpace       0xFF08
#define GDK_Tab             0xFF09
#define GDK_Return          0xFF0D
#define GDK_Escape          0xFF1B
#define GDK_Delete          0xFFFF
#define GDK_Home            0xFF50
#define GDK_Left            0xFF51
#define GDK_Up              0xFF52
#define GDK_Right           0xFF53
#define GDK_Down            0xFF54
#define GDK_Page_Up         0xFF55
#define GDK_Page_Down       0xFF56

#define GDK_End             0xFF57
#define GDK_Insert          0xFF63
static crossCursor := nil
static arrowCursor := nil
static vCursor     := nil
static oCursor     := nil
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

   METHOD New( cHeading,block,type,length,dec,lEditable,nJusHead,nJusLin,cPict,bValid,bWhen,aItem,oBmp )

ENDCLASS

//----------------------------------------------------//
METHOD New( cHeading,block,type,length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, oBmp ) CLASS HColumn

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
   ::aBitmaps  := oBmp

RETURN Self

//----------------------------------------------------//
CLASS HBrowse INHERIT HControl

   DATA winclass   INIT "BROWSE"
   DATA active     INIT .T.
   DATA lChanged   INIT .F.
   DATA lDispHead  INIT .T.                    // Should I display headers ?
   DATA lDispSep   INIT .T.                    // Should I display separators ?
   DATA aColumns                               // HColumn's array
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
   DATA bPosChanged, bLineOut, bScrollPos
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
   
   DATA area, hScrollV, hScrollH
   DATA nScrollV  INIT 0
   DATA nScrollH  INIT 0
   DATA oGet, nGetRec
   DATA lBtnDbl   INIT .F.

   METHOD New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
                  bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,lNoBorder,;
                  lAppend,lAutoedit,bUpdate,bKeyDown,bPosChg)
   METHOD InitBrw( nType )
   METHOD Rebuild()
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
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
                  lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown,bPosChg ) CLASS HBrowse

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_CHILD+WS_VISIBLE+ ;
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

   ::InitBrw()
   ::Activate()
   
RETURN Self

//----------------------------------------------------//
METHOD Activate CLASS HBrowse

   if !Empty( ::oParent:handle )
      ::handle := CreateBrowse( Self )
      ::Init()
   endif
RETURN Self

//----------------------------------------------------//
METHOD onEvent( msg, wParam, lParam )  CLASS HBrowse
Local aCoors, retValue := -1

   // WriteLog( "Brw: "+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF ::active .AND. !Empty( ::aColumns )

      IF ::bOther != Nil
         Eval( ::bOther,Self,msg,wParam,lParam )
      ENDIF

      IF msg == WM_PAINT
         ::Paint()
         retValue := 1

      ELSEIF msg == WM_ERASEBKGND
         IF ::brush != Nil
	    
            aCoors := GetClientRect( ::handle )
            FillRect( wParam, aCoors[1], aCoors[2], aCoors[3]+1, aCoors[4]+1, ::brush:handle )
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
         ::DoHScroll( wParam )

      ELSEIF msg == WM_VSCROLL
         ::DoVScroll( wParam )

      ELSEIF msg == WM_COMMAND
         DlgCommand( Self, wParam, lParam )


      ELSEIF msg == WM_KEYDOWN
         IF ::bKeyDown != Nil
            IF !Eval( ::bKeyDown,Self,wParam )
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
            ::TOP()
         ELSEIF wParam == GDK_End    // End
            ::BOTTOM()
         ELSEIF wParam == GDK_Page_Down    // PageDown
            ::PageDown()
         ELSEIF wParam == GDK_Page_Up    // PageUp
            ::PageUp()
         ELSEIF wParam == GDK_Return  // Enter
            ::Edit()
         ELSEIF (wParam >= 48 .and. wParam <= 90 .or. wParam >= 96 .and. wParam <= 111 ).and. ::lAutoEdit
            ::Edit( wParam,lParam )
         ENDIF
         retValue := 1

      ELSEIF msg == WM_LBUTTONDOWN
         ::ButtonDown( lParam )

      ELSEIF msg == WM_LBUTTONUP
         ::ButtonUp( lParam )

      ELSEIF msg == WM_LBUTTONDBLCLK
         ::ButtonDbl( lParam )

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
      
Return retValue

//----------------------------------------------------//
METHOD Init CLASS HBrowse

   Super:Init()
   ::nHolder := 1
   SetWindowObject( ::handle,Self )
Return Nil

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

   if oColumn:type == Nil
      oColumn:type := Valtype( Eval( oColumn:block,,oBrw,n ) )
   endif 
   if oColumn:dec == Nil 
      if oColumn:type == "N" .and. At( '.', Str( Eval( oColumn:block,,oBrw,n ) ) ) != 0
         oColumn:dec := Len( Substr( Str( Eval( oColumn:block,,oBrw,n ) ), ;
               At( '.', Str( Eval( oColumn:block,,oBrw,n ) ) ) + 1 ) )
      else
         oColumn:dec := 0
      endif
   endif
   if oColumn:length == Nil 
      if oColumn:picture != Nil
         oColumn:length := Len( Transform( Eval( oColumn:block,,oBrw,n ), oColumn:picture ) )
      else
         oColumn:length := 10             
      endif
      oColumn:length := Max( oColumn:length, Len( oColumn:heading ) )
   endif

Return Nil

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
      ::brushSel:Release()
   ENDIF  

RETURN Nil

//----------------------------------------------------//
METHOD InitBrw( nType )  CLASS HBrowse

   if nType != Nil
      ::type := nType
   else
      ::aColumns := {}
      ::rowPos    := ::tekzp  := ::colpos := ::nLeftCol := 1
      ::freeze  := ::height := 0
      ::internal  := { 15,1 }
      ::msrec     := Nil

      if empty(crossCursor) 
         crossCursor := LoadCursor( GDK_CROSS )
         arrowCursor := LoadCursor( GDK_LEFT_PTR )
         vCursor := LoadCursor( GDK_SB_V_DOUBLE_ARROW )
      endif
      
   endif

   if ::type == BRW_DATABASE
      ::alias   := Alias()
      ::bSKip   := &( "{|o, x|" + ::alias + "->(DBSKIP(x)) }" )
      ::bGoTop  := &( "{||" + ::alias + "->(DBGOTOP())}" )
      ::bGoBot  := &( "{||" + ::alias + "->(DBGOBOTTOM())}")
      ::bEof    := &( "{||" + ::alias + "->(EOF())}" )
      ::bBof    := &( "{||" + ::alias + "->(BOF())}" )
      ::bRcou   := &( "{||" + ::alias + "->(RECCOUNT())}" )
      ::bRecnoLog := ::bRecno  := &( "{||" + ::alias + "->(RECNO())}" )
      ::bGoTo   := &( "{|a,n|"  + ::alias + "->(DBGOTO(n))}" )
   elseif ::type == BRW_ARRAY
      ::bSKip   := { | o, x | ARSKIP( o, x ) }
      ::bGoTop  := { | o | o:tekzp := 1 }
      ::bGoBot  := { | o | o:tekzp := o:kolz }
      ::bEof    := { | o | o:tekzp > o:kolz }
      ::bBof    := { | o | o:tekzp == 0 }
      ::bRcou   := { | o | len( o:msrec ) }
      ::bRecnoLog := ::bRecno  := { | o | o:tekzp }
      ::bGoTo   := { | o, n | o:tekzp := n }
      ::bScrollPos := {|o,n,lEof,nPos|VScrollPos(o,n,lEof,nPos)}
   endif
RETURN Nil

//----------------------------------------------------//
METHOD Rebuild( hDC ) CLASS HBrowse

   local i, j, oColumn, xSize, nColLen, nHdrLen, nCount

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
   for i := 1 to len( ::aColumns )

      oColumn := ::aColumns[i]

      if oColumn:lEditable
         ::lEditable := .T.
      endif

      if oColumn:aBitmaps != Nil
         xSize := 0
         for j := 1 to len( oColumn:aBitmaps )
            xSize := max( xSize, oColumn:aBitmaps[j,2]:nWidth+2 )
            ::minHeight := max( ::minHeight,oColumn:aBitmaps[j,2]:nHeight )
         next
      else
         // xSize := round( (max( len( FldStr( Self,i ) ), len( oColumn:heading ) ) + 2 ) * 8, 0 )
         nColLen := oColumn:length
         if oColumn:heading != nil
            HdrToken( oColumn:heading, @nHdrLen, @nCount )
            if ! oColumn:lSpandHead
               nColLen := max( nColLen, nHdrLen )
            endif
            ::nHeadRows := Max(::nHeadRows, nCount)
         endif
         if oColumn:footing != nil
            HdrToken( oColumn:footing, @nHdrLen, @nCount )
            if ! oColumn:lSpandFoot
               nColLen := max( nColLen, nHdrLen )
            endif
            ::nFootRows := Max(::nFootRows, nCount)
         endif
         xSize := round( ( nColLen + 2 ) * 8, 0 )
      endif

      oColumn:width := xSize

   next

   ::lChanged := .F.

RETURN Nil

//----------------------------------------------------//
METHOD Paint()  CLASS HBrowse
Local aCoors, aMetr, i, oldAlias, tmp, nRows
Local pps, hDC
Local oldBkColor, oldTColor

   IF !::active .OR. Empty( ::aColumns )
      Return Nil
   ENDIF

   IF ::tcolor == Nil ; ::tcolor := 0 ; ENDIF
   IF ::bcolor == Nil ; ::bcolor := VColor( "FFFFFF" ) ; ENDIF
   IF ::tcolorSel == Nil ; ::tcolorSel := VColor( "FFFFFF" ) ; ENDIF
   IF ::bcolorSel == Nil ; ::bcolorSel := VColor( "808080" ) ; ENDIF

   hDC := GetDC( ::area )

   if ::ofont != Nil
      SelectObject( hDC, ::ofont:handle )
   endif
   IF ::brush == Nil .OR. ::lChanged
      ::Rebuild(hDC)
   ENDIF
   aCoors := GetClientRect( ::handle )
   Rectangle( hDC, aCoors[1],aCoors[2],aCoors[3]-1,aCoors[4]-1 )
   aMetr := GetTextMetric( hDC )
   
   ::width := aMetr[ 2 ]
   ::height := Max( aMetr[ 1 ], ::minHeight )
   ::x1 := aCoors[ 1 ]
   ::y1 := aCoors[ 2 ] + Iif( ::lDispHead, ::height*::nHeadRows, 0 )
   ::x2 := aCoors[ 3 ]
   ::y2 := aCoors[ 4 ]

   ::kolz := eval( ::bRcou,Self )
   IF ::tekzp > ::kolz
      ::tekzp := ::kolz
   ENDIF

   ::nColumns := FLDCOUNT( Self, ::x1 + 2, ::x2 - 2, ::nLeftCol )
   ::rowCount := Int( (::y2-::y1) / (::height+1) ) - ::nFootRows
   nRows := Min( ::kolz,::rowCount )
   
   IF ::hScrollV != Nil
      tmp := Iif(::kolz<100,::kolz,100)
      i := Iif(::kolz<100,1,::kolz/100)
      hwg_SetAdjOptions( ::hScrollV,,tmp+nRows,i,nRows,nRows )
   ENDIF 
   IF ::hScrollH != Nil
      tmp := Len( ::aColumns )
      hwg_SetAdjOptions( ::hScrollH,,tmp+1,1,1,1 )
   ENDIF 

   IF ::internal[1] == 0
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         EVAL( ::bSkip, Self, ::internal[2]-::rowPos )
      ENDIF
      ::LineOut( ::internal[2], 0, hDC, .F. )
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         EVAL( ::bSkip, Self, ::rowPos-::internal[2] )
      ENDIF
   ELSE
      IF EVAL( ::bEof,Self )
         EVAL( ::bGoTop, Self )
         ::rowPos := 1
      ENDIF
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF
      tmp := EVAL( ::bRecno,Self )
      IF ::rowPos > 1
         EVAL( ::bSkip, Self,-(::rowPos-1) )
      ENDIF
      i := 1
      DO WHILE .T.
         IF EVAL( ::bRecno,Self ) == tmp
            ::rowPos := i
         ENDIF
         IF i > nRows .OR. EVAL( ::bEof,Self )
            EXIT
         ENDIF
         ::LineOut( i, 0, hDC, .F. )
         i ++
         EVAL( ::bSkip, Self,1 )
      ENDDO
      ::rowCurrCount := i - 1

      IF ::rowPos >= i
         ::rowPos := Iif( i > 1,i - 1,1 )
      ENDIF
      DO WHILE i <= nRows
         ::LineOut( i, 0, hDC, .F.,.T. )
         i ++
      ENDDO

      EVAL( ::bGoTo, Self,tmp )
   ENDIF
   IF ::lAppMode
      ::LineOut( nRows+1, 0, hDC, .F.,.T. )
   ENDIF

   ::LineOut( ::rowPos, IIF( ::lEditable, ::colpos, 0 ), hDC, .T. )
   IF Checkbit( ::internal[1],1 ) .OR. ::lAppMode
      ::HeaderOut( hDC )
      if ::nFootRows > 0
         ::FooterOut( hDC )
      endif
   ENDIF

   ReleaseDC( ::area,hDC )
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

   IF ::oGet == Nil .AND. ( ( tmp := GetFocus() ) == ::oParent:handle .OR. ;
         ::oParent:FindControl(,tmp) != Nil )
      SetFocus( ::area )
   ENDIF
   ::lAppMode := .F.

RETURN Nil

//----------------------------------------------------//
METHOD HeaderOut( hDC ) CLASS HBrowse
Local i, x, oldc, fif, xSize
Local nRows := Min( ::kolz+Iif(::lAppMode,1,0),::rowCount )
Local oPen // , oldBkColor := SetBkColor( hDC,GetSysColor(COLOR_3DFACE) )
Local oColumn, nLine, cStr, cNWSE, oPenHdr, oPenLight

   /*
   IF ::lSep3d
      oPenLight := HPen():Add( PS_SOLID,1,GetSysColor(COLOR_3DHILIGHT) )
   ENDIF
   */
   IF ::lDispSep
      oPen := HPen():Add( PS_SOLID,1,::sepColor )
      SelectObject( hDC, oPen:handle ) 
   ENDIF

   x := ::x1
   if ::headColor != Nil
      oldc := SetTextColor( hDC,::headColor )
   endif
   fif := iif( ::freeze > 0, 1, ::nLeftCol )

   while x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      if ::lAdjRight .and. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      endif
      if ::lDispHead .AND. !::lAppMode
         if oColumn:cGrid == nil
            DrawButton( hDC, x-1,::y1-::height*::nHeadRows,x+xSize-1,::y1+1,5 )
         else
            DrawButton( hDC, x-1,::y1-::height*::nHeadRows,x+xSize-1,::y1+1,0 )
            if oPenHdr == nil
               oPenHdr := HPen():Add( BS_SOLID,1,0 )
            endif
            SelectObject( hDC, oPenHdr:handle )
            cStr := oColumn:cGrid + ';'
            for nLine := 1 to ::nHeadRows
               cNWSE := __StrToken(@cStr, nLine, ';')
               if At('S', cNWSE) != 0
                  DrawLine(hDC, x-1, ::y1-(::height)*(::nHeadRows-nLine), x+xSize-1, ::y1-(::height)*(::nHeadRows-nLine))
               endif
               if At('N', cNWSE) != 0
                  DrawLine(hDC, x-1, ::y1-(::height)*(::nHeadRows-nLine+1), x+xSize-1, ::y1-(::height)*(::nHeadRows-nLine+1))
               endif
               if At('E', cNWSE) != 0
                  DrawLine(hDC, x+xSize-2, ::y1-(::height)*(::nHeadRows-nLine+1)+1, x+xSize-2, ::y1-(::height)*(::nHeadRows-nLine))
               endif
               if At('W', cNWSE) != 0
                  DrawLine(hDC, x-1, ::y1-(::height)*(::nHeadRows-nLine+1)+1, x-1, ::y1-(::height)*(::nHeadRows-nLine))
               endif
            next
            SelectObject( hDC, oPen:handle )
         endif
         // Ahora Titulos Justificados !!!
         cStr := oColumn:heading + ';'
         for nLine := 1 to ::nHeadRows
            DrawText( hDC, __StrToken(@cStr, nLine, ';'), x, ::y1-(::height)*(::nHeadRows-nLine+1)+1, x+xSize-1,::y1-(::height)*(::nHeadRows-nLine),;
               oColumn:nJusHead  + if(oColumn:lSpandHead, DT_NOCLIP, 0) )
         next
      endif
      if ::lDispSep .AND. x > ::x1
         IF ::lSep3d
            SelectObject( hDC, oPenLight:handle )
            DrawLine( hDC, x-1, ::y1+1, x-1, ::y1+(::height+1)*nRows )
            SelectObject( hDC, oPen:handle )
            DrawLine( hDC, x-2, ::y1+1, x-2, ::y1+(::height+1)*nRows )
         ELSE
            DrawLine( hDC, x-1, ::y1+1, x-1, ::y1+(::height+1)*nRows )
         ENDIF
      endif
      x += xSize
      if ! ::lAdjRight .and. fif == Len( ::aColumns )
         DrawLine( hDC, x-1, ::y1-(::height*::nHeadRows), x-1, ::y1+(::height+1)*nRows )
      endif
      fif := IIF( fif = ::freeze, ::nLeftCol, fif + 1 )
      if fif > Len( ::aColumns )
         exit
      endif
   enddo

   IF ::lDispSep
      for i := 1 to nRows
         DrawLine( hDC, ::x1, ::y1+(::height+1)*i, iif(::lAdjRight, ::x2, x), ::y1+(::height+1)*i )
      next
      oPen:Release()
      if oPenHdr != nil
         oPenHdr:Release()
      endif
      if oPenLight != nil
         oPenLight:Release()
      endif  
   ENDIF

   /* SetBkColor( hDC,oldBkColor ) */
   if ::headColor <> Nil
      SetTextColor( hDC,oldc )
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

   while x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      if ::lAdjRight .and. fif == Len( ::aColumns )
         xSize := Max( ::x2 - x, xSize )
      endif
      if oColumn:footing <> nil
         cStr := oColumn:footing + ';'
         for nLine := 1 to ::nFootRows
            DrawText( hDC, __StrToken(@cStr, nLine, ';'),;
               x, ::y1+(::rowCount+nLine-1)*(::height+1)+1, x+xSize-1, ::y1+(::rowCount+nLine)*(::height+1),;
               oColumn:nJusLin + if(oColumn:lSpandFoot, DT_NOCLIP, 0) )
         next
      endif
      x += xSize
      fif := IIF( fif = ::freeze, ::nLeftCol, fif + 1 )
      if fif > Len( ::aColumns )
         exit
      endif
   enddo

   IF ::lDispSep
      DrawLine( hDC, ::x1, ::y1+(::rowCount)*(::height+1)+1, iif(::lAdjRight, ::x2, x), ::y1+(::rowCount)*(::height+1)+1 )
      oPen:Release()
   ENDIF

RETURN Nil

//----------------------------------------------------//
METHOD LineOut( nstroka, vybfld, hDC, lSelected, lClear ) CLASS HBrowse
Local x, dx, i := 1, shablon, sviv, fif, fldname, slen, xSize
Local j, ob, bw, bh, y1, hBReal
Local oldBkColor, oldTColor, oldBk1Color, oldT1Color
Local oLineBrush := Iif( lSelected, ::brushSel,::brush )
Local lColumnFont := .F.

   ::xpos := x := ::x1
   IF lClear == Nil ; lClear := .F. ; ENDIF

   IF ::bLineOut != Nil
      Eval( ::bLineOut,Self,lSelected )
   ENDIF
   IF ::kolz > 0
      oldBkColor := SetBkColor( hDC, Iif( lSelected,::bcolorSel,::bcolor ) )
      oldTColor  := SetTextColor( hDC, Iif( lSelected,::tcolorSel,::tcolor ) )
      fldname := SPACE( 8 )
      fif     := IIF( ::freeze > 0, 1, ::nLeftCol )

      WHILE x < ::x2 - 2
         xSize := ::aColumns[fif]:width
         IF ::lAdjRight .and. fif == LEN( ::aColumns )
            xSize := Max( ::x2 - x, xSize )
         ENDIF
         IF i == ::colpos
            ::xpos := x
         ENDIF

         IF vybfld == 0 .OR. vybfld == i
            IF ::aColumns[fif]:bColor != Nil .AND. ::aColumns[fif]:brush == Nil
               ::aColumns[fif]:brush := HBrush():Add( ::aColumns[fif]:bColor )
            ENDIF
            hBReal := Iif( ::aColumns[fif]:brush != Nil, ;
                         ::aColumns[fif]:brush:handle,   ;
                         oLineBrush:handle )
            FillRect( hDC, x, ::y1+(::height+1)*(nstroka-1)+1, x+xSize-Iif(::lSep3d,2,1)-1,::y1+(::height+1)*nstroka, hBReal )
            IF !lClear
               IF ::aColumns[fif]:aBitmaps != Nil .AND. !Empty( ::aColumns[fif]:aBitmaps )
	         /*
                  FOR j := 1 TO Len( ::aColumns[fif]:aBitmaps )
                     IF Eval( ::aColumns[fif]:aBitmaps[j,1],EVAL( ::aColumns[fif]:block,,Self,fif ),lSelected )
                        ob := ::aColumns[fif]:aBitmaps[j,2]
                        IF ob:nHeight > ::height
                           y1 := 0
                           bh := ::height
                           bw := Int( ob:nWidth * ( ob:nHeight / ::height ) )
                           DrawBitmap( hDC, ob:handle,, x, y1+::y1+(::height+1)*(nstroka-1)+1, bw, bh )
                        ELSE
                           y1 := Int( (::height-ob:nHeight)/2 )
                           bh := ob:nHeight
                           bw := ob:nWidth
                           DrawTransparentBitmap( hDC, ob:handle, x, y1+::y1+(::height+1)*(nstroka-1)+1 )
                        ENDIF
                        // DrawBitmap( hDC, ob:handle,, x, y1+::y1+(::height+1)*(nstroka-1)+1, bw, bh )
                        EXIT
                     ENDIF
                  NEXT
		 */
               ELSE
                  sviv := AllTrim( FldStr( Self,fif ) )
                  // Ahora lineas Justificadas !!
                  IF ::aColumns[fif]:tColor != Nil
                     oldT1Color := SetTextColor( hDC, ::aColumns[fif]:tColor )
                  ENDIF
                  IF ::aColumns[fif]:bColor != Nil
                     oldBk1Color := SetBkColor( hDC, ::aColumns[fif]:bColor )
                  ENDIF
                  IF ::aColumns[fif]:oFont != Nil
                     SelectObject( hDC, ::aColumns[fif]:oFont:handle )
                     lColumnFont := .T.
                  ELSEIF lColumnFont
                     SelectObject( hDC, ::ofont:handle )
                     lColumnFont := .F.
                  ENDIF
                  DrawText( hDC, sviv, x, ::y1+(::height+1)*(nstroka-1)+1, x+xSize-2,::y1+(::height+1)*nstroka-1, ::aColumns[fif]:nJusLin )
                  IF ::aColumns[fif]:tColor != Nil
                     SetTextColor( hDC, oldT1Color )
                  ENDIF
                  IF ::aColumns[fif]:bColor != Nil
                     SetBkColor( hDC, oldBk1Color )
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         x += xSize
         fif := IIF( fif = ::freeze, ::nLeftCol, fif + 1 )
         i ++
         IF ! ::lAdjRight .and. fif > LEN( ::aColumns )
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
            /* RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE ) */
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
METHOD DoHScroll( wParam ) CLASS HBrowse
Local nScrollH := hwg_getAdjValue( ::hScrollH )

   IF nScrollH - ::nScrollH < 0
      LineLeft( Self )
   ELSEIF nScrollH - ::nScrollH > 0
      LineRight( Self )
   ENDIF

RETURN Nil

//----------------------------------------------------//
STATIC FUNCTION LINERIGHT( oBrw )
Local maxPos, nPos, oldLeft := oBrw:nLeftCol, oldPos := oBrw:colpos, fif
LocaL i, nColumns := Len(oBrw:aColumns)
   
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
      IF oBrw:hScrollV != Nil
         maxPos := hwg_getAdjValue( oBrw:hScrollH,1 ) - hwg_getAdjValue( oBrw:hScrollH,4 )
         fif := Iif( oBrw:lEditable, oBrw:colpos+oBrw:nLeftCol-1, oBrw:nLeftCol )
         nPos := Iif( fif==1, 0, Iif( fif=nColumns, maxpos, ;
                   Int((maxPos+1)*fif/nColumns) ) )
         hwg_SetAdjOptions( oBrw:hScrollH,nPos )
         oBrw:nScrollH := nPos
      ENDIF
      IF oBrw:nLeftCol == oldLeft
         oBrw:internal[1] := 1
         InvalidateRect( oBrw:area, 0, oBrw:x1, oBrw:y1+(oBrw:height+1)*oBrw:internal[2]-oBrw:height, oBrw:x2, oBrw:y1+(oBrw:height+1)*(oBrw:rowPos+1) )
      ELSE
         InvalidateRect( oBrw:area, 0 )
      ENDIF
   ENDIF
   SetFocus( oBrw:area )
   
RETURN Nil

//----------------------------------------------------//
STATIC FUNCTION LINELEFT( oBrw )
Local maxPos, nPos, oldLeft := oBrw:nLeftCol, oldPos := oBrw:colpos, fif
LocaL nColumns := Len(oBrw:aColumns)

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
      IF oBrw:hScrollV != Nil
         maxPos := hwg_getAdjValue( oBrw:hScrollH,1 ) - hwg_getAdjValue( oBrw:hScrollH,4 )
         fif := Iif( oBrw:lEditable, oBrw:colpos+oBrw:nLeftCol-1, oBrw:nLeftCol )
         nPos := Iif( fif==1, 0, Iif( fif=nColumns, maxpos, ;
                   Int((maxPos+1)*fif/nColumns) ) )
         hwg_SetAdjOptions( oBrw:hScrollH,nPos )
         oBrw:nScrollH := nPos
      ENDIF
      IF oBrw:nLeftCol == oldLeft
         oBrw:internal[1] := 1
         InvalidateRect( oBrw:area, 0, oBrw:x1, oBrw:y1+(oBrw:height+1)*oBrw:internal[2]-oBrw:height, oBrw:x2, oBrw:y1+(oBrw:height+1)*(oBrw:rowPos+1) )
      ELSE
         InvalidateRect( oBrw:area, 0 )
      ENDIF
   ENDIF
   SetFocus( oBrw:area )

RETURN Nil

//----------------------------------------------------//
METHOD DoVScroll( wParam ) CLASS HBrowse
Local nScrollV := hwg_getAdjValue( ::hScrollV )

   if nScrollV - ::nScrollV == 1
      ::LINEDOWN(.T.)
   elseif nScrollV - ::nScrollV == -1
      ::LINEUP(.T.)
   elseif nScrollV - ::nScrollV == 10
      ::PAGEDOWN(.T.)
   elseif nScrollV - ::nScrollV == -10
      ::PAGEUP(.T.)
   else
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, SB_THUMBTRACK, .F., nScrollV )
      ENDIF
   endif
   ::nScrollV := nScrollV
   // writelog( "DoVScroll " + Ltrim(Str(::nScrollV)) + " " + Ltrim(Str(::tekzp)) + "( " + Ltrim(Str(::kolz)) + " )" )
RETURN 0

//----------------------------------------------------//
METHOD LINEDOWN( lMouse ) CLASS HBrowse
Local maxPos := hwg_getAdjValue( ::hScrollV,1 ) - hwg_getAdjValue( ::hScrollV,4 )
Local nPos

   lMouse := Iif( lMouse==Nil,.F.,lMouse )
   Eval( ::bSkip, Self,1 )
   IF Eval( ::bEof,Self )
      Eval( ::bSkip, Self,- 1 )
      IF ::lAppable .AND. !lMouse
         ::lAppMode := .T.
      ELSE
         SetFocus( ::area )
         Return Nil
      ENDIF
   ENDIF
   ::rowPos ++
   IF ::rowPos > ::rowCount
      ::rowPos := ::rowCount
      InvalidateRect( ::area, 0 )
   ELSE
      ::internal[1] := 1
      InvalidateRect( ::area, 0, ::x1, ::y1+(::height+1)*::internal[2]-::height, ::x2, ::y1+(::height+1)*(::rowPos+1) )
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
      ELSE
         nPos := hwg_getAdjValue( ::hScrollV )
         nPos += Int( maxPos/(::kolz-1) )
         hwg_SetAdjOptions( ::hScrollV,nPos )
         ::nScrollV := nPos
      ENDIF
   ENDIF

   SetFocus( ::area )

RETURN Nil

//----------------------------------------------------//
METHOD LINEUP( lMouse ) CLASS HBrowse
Local maxPos := hwg_getAdjValue( ::hScrollV,1 ) - hwg_getAdjValue( ::hScrollV,4 )
Local nPos

   lMouse := Iif( lMouse==Nil,.F.,lMouse )
   EVAL( ::bSkip, Self,- 1 )
   IF EVAL( ::bBof,Self )
      EVAL( ::bGoTop,Self )
   ELSE
      ::rowPos --
      IF ::rowPos = 0
         ::rowPos := 1
         InvalidateRect( ::area, 0 )
      ELSE
         ::internal[1] := 1
         InvalidateRect( ::area, 0, ::x1, ::y1+(::height+1)*::internal[2]-::height, ::x2, ::y1+(::height+1)*::internal[2] )
         InvalidateRect( ::area, 0, ::x1, ::y1+(::height+1)*::rowPos-::height, ::x2, ::y1+(::height+1)*::rowPos )
      ENDIF

      IF !lMouse .AND. ::hScrollV != Nil
         IF ::bScrollPos != Nil
            Eval( ::bScrollPos, Self, -1, .F. )
         ELSE
            nPos := hwg_getAdjValue( ::hScrollV )
            nPos -= Int( maxPos/(::kolz-1) )
            hwg_SetAdjOptions( ::hScrollV,nPos )
            ::nScrollV := nPos
         ENDIF
      ENDIF
      
   ENDIF
   SetFocus( ::area )
   
RETURN Nil

//----------------------------------------------------//
METHOD PAGEUP( lMouse ) CLASS HBrowse
Local maxPos := hwg_getAdjValue( ::hScrollV,1 ) - hwg_getAdjValue( ::hScrollV,4 )
Local nPos, step, lBof := .F.

   lMouse := Iif( lMouse==Nil,.F.,lMouse )
   IF ::rowPos > 1
      step := ( ::rowPos - 1 )
      EVAL( ::bSKip, Self,- step )
      ::rowPos := 1
   ELSE
      step := ::rowCurrCount    // Min( ::kolz,::rowCount )
      EVAL( ::bSkip, Self,- step )
      IF EVAL( ::bBof,Self )
         EVAL( ::bGoTop,Self )
         lBof := .T.
      ENDIF
   ENDIF

   IF !lMouse .AND. ::hScrollV != Nil
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, - step, lBof )
      ELSE
         nPos := hwg_getAdjValue( ::hScrollV )
         nPos -= Int( maxPos/(::kolz-1) )
         nPos := Max( nPos - Int( maxPos*step/(::kolz-1) ), 0 )
         hwg_SetAdjOptions( ::hScrollV,nPos )
         ::nScrollV := nPos
      ENDIF
   ENDIF

   InvalidateRect( ::area, 0 )
   SetFocus( ::area )
RETURN Nil

//----------------------------------------------------//
METHOD PAGEDOWN( lMouse ) CLASS HBrowse
Local maxPos := hwg_getAdjValue( ::hScrollV,1 ) - hwg_getAdjValue( ::hScrollV,4 )
Local nPos, nRows := ::rowCurrCount
Local step := Iif( nRows>::rowPos,nRows-::rowPos+1,nRows ), lEof

   lMouse := Iif( lMouse==Nil,.F.,lMouse )
   EVAL( ::bSkip, Self, step )
   ::rowPos := Min( ::kolz, nRows )
   lEof := EVAL( ::bEof,Self )
   IF lEof .AND. ::bScrollPos == Nil
      EVAL( ::bSkip, Self,- 1 )
   ENDIF

   IF !lMouse .AND. ::hScrollV != Nil
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, step, lEof )
      ELSE
         nPos := hwg_getAdjValue( ::hScrollV )
         IF lEof     
            nPos := maxPos
         ELSE
            nPos := Min( nPos + Int( maxPos*step/(::kolz-1) ), maxPos )
         ENDIF
         hwg_SetAdjOptions( ::hScrollV,nPos )
         ::nScrollV := nPos
      ENDIF
   ENDIF

   InvalidateRect( ::area, 0 )
   SetFocus( ::area )
RETURN Nil

//----------------------------------------------------//
METHOD BOTTOM(lPaint) CLASS HBrowse
Local nPos

   ::rowPos := lastrec()
   eval( ::bGoBot, Self )
   ::rowPos := min( ::kolz, ::rowCount )

   IF ::hScrollV != Nil
      nPos := hwg_getAdjValue( ::hScrollV,1 ) - hwg_getAdjValue( ::hScrollV,4 )
      hwg_SetAdjOptions( ::hScrollV,nPos )
      ::nScrollV := nPos
   ENDIF
   
   InvalidateRect( ::area, 0 )

   IF lPaint == Nil .OR. lPaint
      SetFocus( ::area )
   ENDIF

RETURN Nil

//----------------------------------------------------//
METHOD TOP() CLASS HBrowse
Local nPos

   ::rowPos := 1
   EVAL( ::bGoTop,Self )

   IF ::hScrollV != Nil
      nPos := 0
      hwg_SetAdjOptions( ::hScrollV,nPos )
      ::nScrollV := nPos
   ENDIF
   
   InvalidateRect( ::area, 0 )
   SetFocus( ::area )

RETURN Nil

//----------------------------------------------------//
METHOD ButtonDown( lParam ) CLASS HBrowse
Local hBrw := ::handle
Local nLine := Int( HIWORD(lParam)/(::height+1) + Iif(::lDispHead,1-::nHeadRows,1) )
Local step := nLine - ::rowPos, res := .F., nrec
Local maxPos, nPos
Local xm := LOWORD(lParam), x1, fif

   ::lBtnDbl := .F.
   x1  := ::x1
   fif := IIF( ::freeze > 0, 1, ::nLeftCol )
   DO WHILE fif < (::nLeftCol+::nColumns) .AND. x1 + ::aColumns[fif]:width < xm
      x1 += ::aColumns[fif]:width
      fif := IIF( fif = ::freeze, ::nLeftCol, fif + 1 )
   ENDDO

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      IF step != 0
         nrec := Recno()
         EVAL( ::bSkip, Self, step )
         IF !Eval( ::bEof,Self )
            ::rowPos := nLine
	    IF ::hScrollV != Nil
               IF ::bScrollPos != Nil
                  Eval( ::bScrollPos, Self, step, .F. )
               ELSE	    
                  nPos := hwg_getAdjValue( ::hScrollV )
		  maxPos := hwg_getAdjValue( ::hScrollV,1 ) - hwg_getAdjValue( ::hScrollV,4 )
                  nPos := Min( nPos + Int( maxPos*step/(::kolz-1) ), maxPos )
   	          hwg_SetAdjOptions( ::hScrollV,nPos )
               ENDIF
	    ENDIF
            res := .T.
         ELSE
            Go nrec
         ENDIF
      ENDIF
      IF ::lEditable
         IF ::colpos != fif - ::nLeftCol + 1 + :: freeze
            ::colpos := fif - ::nLeftCol + 1 + :: freeze
	    IF ::hScrollH != Nil
	       maxPos := hwg_getAdjValue( ::hScrollH,1 ) - hwg_getAdjValue( ::hScrollH,4 )
               nPos := Iif( fif==1, 0, Iif( fif=Len(::aColumns), maxpos, ;
                         Int((maxPos+1)*fif/Len(::aColumns)) ) )
	       hwg_SetAdjOptions( ::hScrollH,nPos )
	    ENDIF
            res := .T.
         ENDIF
      ENDIF
      IF res
         ::internal[1] := 1
         InvalidateRect( ::area, 0, ::x1, ::y1+(::height+1)*::internal[2]-::height, ::x2, ::y1+(::height+1)*::internal[2] )
         InvalidateRect( ::area, 0, ::x1, ::y1+(::height+1)*::rowPos-::height, ::x2, ::y1+(::height+1)*::rowPos )
      ENDIF
      
   ELSEIF ::lDispHead .and.;
          nLine >= -::nHeadRows .and.;
          fif <= Len( ::aColumns ) .AND.;
          ::aColumns[fif]:bHeadClick != nil

      Eval(::aColumns[fif]:bHeadClick, Self, fif)

   ELSEIF nLine == 0
      IF oCursor == crossCursor
         oCursor := vCursor
         Hwg_SetCursor( oCursor,::area )
         xDrag := LoWord( lParam )
      ENDIF
   ENDIF

RETURN Nil

//----------------------------------------------------//
METHOD ButtonUp( lParam ) CLASS HBrowse
Local hBrw := ::handle
Local xPos := LOWORD(lParam), x := ::x1, x1, i := ::nLeftCol

   IF ::lBtnDbl
      ::lBtnDbl := .F.
      Return Nil
   ENDIF
   IF oCursor == vCursor
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
         Hwg_SetCursor( arrowCursor,::area )
         oCursor := nil
       
         InvalidateRect( hBrw, 0 )
      ENDIF
   ENDIF

   SetFocus( ::area )
RETURN Nil

//----------------------------------------------------//
METHOD ButtonDbl( lParam ) CLASS HBrowse
Local hBrw := ::handle
Local nLine := Int( HIWORD(lParam)/(::height+1) + Iif(::lDispHead,1-::nHeadRows,1) )

   if nLine <= ::rowCurrCount
      ::ButtonDown( lParam )
      ::Edit()
   endif
   ::lBtnDbl := .T.
RETURN Nil

//----------------------------------------------------//
METHOD MouseMove( wParam, lParam ) CLASS HBrowse
   local xPos := LoWord( lParam ), yPos := HiWord( lParam )
   local x := ::x1, i := ::nLeftCol, res := .F.

   IF !::active .OR. Empty( ::aColumns ) .OR. ::x1 == Nil
      Return Nil
   ENDIF
   IF ::lDispSep .AND. yPos <= ::height+1
      IF wParam == 1 .AND. oCursor == vCursor
         Hwg_SetCursor( oCursor,::area )
         res := .T.
      ELSE
         DO WHILE x < ::x2 - 2 .AND. i <= Len( ::aColumns )
            x += ::aColumns[i++]:width
            IF Abs( x - xPos ) < 8
                  IF oCursor != vCursor
                     oCursor := crossCursor
                  ENDIF
                  Hwg_SetCursor( oCursor,::area )
               res := .T.
               EXIT
            ENDIF
         ENDDO
      ENDIF
      IF !res .AND. !Empty( oCursor )
         Hwg_SetCursor( arrowCursor,::area )
         oCursor := nil
      ENDIF
   ENDIF
RETURN Nil

//----------------------------------------------------------------------------//
METHOD MouseWheel( nKeys, nDelta, nXPos, nYPos ) CLASS HBrowse
   if Hwg_BitAnd( nKeys, MK_MBUTTON ) != 0
      if nDelta > 0
         ::PageUp()
      else
         ::PageDown()
      endif
   else
      if nDelta > 0
         ::LineUp()
      else
         ::LineDown()
      endif
   endif
return nil

//----------------------------------------------------//
METHOD Edit( wParam,lParam ) CLASS HBrowse
Local fipos, lRes, x1, y1, fif, nWidth, lReadExit, rowPos
Local oColumn, type

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
         IF oColumn:lEditable .AND. ( oColumn:bWhen = Nil .OR. EVAL( oColumn:bWhen ) )
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
         fif := IIF( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE fif < fipos
            x1 += ::aColumns[fif]:width
            fif := IIF( fif = ::freeze, ::nLeftCol, fif + 1 )
         ENDDO
         nWidth := Min( ::aColumns[fif]:width, ::x2 - x1 - 1 )
         rowPos := ::rowPos - 1
         IF ::lAppMode .AND. ::kolz != 0
            rowPos ++
         ENDIF
         y1 := ::y1+(::height+1)*rowPos
	 
         ::nGetRec := Eval( ::bRecno,Self )
         @ x1,y1 GET ::oGet VAR ::varbuf      ;
	       OF ::oParent                   ;
               SIZE nWidth, ::height+1        ;
               STYLE ES_AUTOHSCROLL           ;
               FONT ::oFont                   ;
               PICTURE oColumn:picture        ;
               VALID {||VldBrwEdit( Self,fipos )}
	 ::oGet:Show()
	 SetFocus( ::oGet:handle )
	 hwg_edit_SetPos( ::oGet:handle, 0 )
       ::oGet:bAnyEvent := {|o,msg,c|GetEventHandler(Self,msg,c)}

      ENDIF
   ENDIF

RETURN Nil

Static Function GetEventHandler( oBrw, msg, cod )

   IF msg == WM_KEYDOWN .AND. cod == GDK_Escape
      oBrw:oGet:nLastKey := GDK_Escape
      SetFocus( oBrw:area )
      Return 1
   ENDIF
Return 0

Static Function VldBrwEdit( oBrw, fipos )
Local oColumn := oBrw:aColumns[fipos], nRec, fif, nChoic

   IF oBrw:oGet:nLastKey != GDK_Escape
      IF oColumn:aList != Nil
         IF valtype(oBrw:varbuf) == 'N'
            oBrw:varbuf := nChoic
         ELSE
            oBrw:varbuf := oColumn:aList[nChoic]
         ENDIF
      ENDIF
      IF oBrw:lAppMode
         oBrw:lAppMode := .F.
         IF oBrw:type == BRW_DATABASE
            (oBrw:alias)->( dbAppend() )
            (oBrw:alias)->( Eval( oColumn:block,oBrw:varbuf,oBrw,fipos ) )
            UNLOCK
         ELSE
            IF Valtype(oBrw:msrec[1]) == "A"
               Aadd( oBrw:msrec,Array(Len(oBrw:msrec[1])) )
               FOR fif := 2 TO Len( (oBrw:msrec[1]) )
                  oBrw:msrec[Len(oBrw:msrec),fif] := ;
                              Iif( oBrw:aColumns[fif]:type=="D",Ctod(Space(8)), ;
                                 Iif( oBrw:aColumns[fif]:type=="N",0,"" ) )
               NEXT
            ELSE
               Aadd( oBrw:msrec,Nil )
            ENDIF
            oBrw:tekzp := Len( oBrw:msrec )
            Eval( oColumn:block,oBrw:varbuf,oBrw,fipos )
         ENDIF
         IF oBrw:kolz > 0
            oBrw:rowPos ++
         ENDIF
         oBrw:lAppended := .T.
         oBrw:Refresh()
      ELSE
         IF ( nRec := Eval( oBrw:bRecno,oBrw ) ) != oBrw:nGetRec
            Eval( oBrw:bGoTo,oBrw,oBrw:nGetRec )
         ENDIF
         IF oBrw:type == BRW_DATABASE
            IF (oBrw:alias)->( Rlock() )
               (oBrw:alias)->( Eval( oColumn:block,oBrw:varbuf,oBrw,fipos ) )
            ELSE
               MsgStop("Can't lock the record!")
            ENDIF
         ELSE
            Eval( oColumn:block,oBrw:varbuf,oBrw,fipos )
         ENDIF
         IF nRec != oBrw:nGetRec
            Eval( oBrw:bGoTo,oBrw,nRec )
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
   SetFocus( oBrw:area )

Return .T.

//----------------------------------------------------//
METHOD RefreshLine() CLASS HBrowse
   ::internal[1] := 0
   InvalidateRect( ::area, 0, ::x1, ::y1+(::height+1)*::rowPos-::height, ::x2, ::y1+(::height+1)*::rowPos )
RETURN Nil

//----------------------------------------------------//
METHOD Refresh( lFull ) CLASS HBrowse

   IF lFull == Nil .OR. lFull
      ::internal[1] := 15
      RedrawWindow( ::area, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )
   ELSE
      InvalidateRect( ::area, 0 )
      ::internal[1] := SetBit( ::internal[1], 1, 0 )
   ENDIF
   
RETURN Nil

//----------------------------------------------------//
STATIC FUNCTION FldStr( oBrw,numf )

   local fldtype
   local rez
   local vartmp
   local nItem := numf
   local type
   local pict
   
   if numf <= len( oBrw:aColumns )

      pict := oBrw:aColumns[numf]:picture

      if pict != nil
         if oBrw:type == BRW_DATABASE
             rez := (oBrw:alias)->(transform(eval( oBrw:aColumns[numf]:block,,oBrw,numf ), pict)) 
         else
             rez := transform(eval( oBrw:aColumns[numf]:block,,oBrw,numf ), pict) 
         endif
         
      else
         if oBrw:type == BRW_DATABASE
             vartmp := (oBrw:alias)->(eval( oBrw:aColumns[numf]:block,,oBrw,numf ))
         else
             vartmp := eval( oBrw:aColumns[numf]:block,,oBrw,numf )
         endif

         type := (oBrw:aColumns[numf]):type
         if type == "U" .AND. vartmp != Nil
            type := Valtype( vartmp )
         endif
         if type == "C"
            rez := padr( vartmp, oBrw:aColumns[numf]:length )

         elseif type == "N"
            rez := PADL( STR( vartmp, oBrw:aColumns[numf]:length, ;
                   oBrw:aColumns[numf]:dec ),oBrw:aColumns[numf]:length )
         elseif type == "D"
            rez := PADR( DTOC( vartmp ),oBrw:aColumns[numf]:length )

         elseif type == "L"
            rez := PADR( IIF( vartmp, "T", "F" ),oBrw:aColumns[numf]:length )

         elseif type == "M" 
            rez := "<Memo>"

         elseif type == "O" 
            rez := "<" + vartmp:Classname() + ">"

         elseif type == "A" 
            rez := "<Array>"

         else
            rez := Space( oBrw:aColumns[numf]:length )
         endif
      endif
   endif

RETURN rez

//----------------------------------------------------//
STATIC FUNCTION FLDCOUNT( oBrw, xstrt, xend, fld1 )

   local klf := 0, i := IIF( oBrw:freeze > 0, 1, fld1 )

   while .T.
      xstrt += oBrw:aColumns[i]:width
      IF xstrt > xend
         EXIT
      ENDIF
      klf ++
      i   := IIF( i = oBrw:freeze, fld1, i + 1 )
      IF i > Len(oBrw:aColumns)
         EXIT
      ENDIF
   ENDDO
RETURN IIF( klf = 0, 1, klf )

//----------------------------------------------------//
FUNCTION CREATEARLIST( oBrw, arr )
   local i
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
   EVAL( oBrw:bGoTop,oBrw )
   oBrw:Refresh()
RETURN Nil

//----------------------------------------------------//
PROCEDURE ARSKIP( oBrw, kolskip )
Local tekzp1
   if oBrw:kolz != 0
      tekzp1   := oBrw:tekzp
      oBrw:tekzp += kolskip + IIF( tekzp1 = 0, 1, 0 )
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
Local nArea := select()
Local kolf := FCOUNT()

   oBrw:alias := alias()
   oBrw:aColumns := {}
   
   for i := 1 TO kolf
      oBrw:AddColumn( HColumn():New( Fieldname(i),                      ;
                                     FieldWBlock( Fieldname(i),nArea ), ;
                                     dbFieldInfo( DBS_TYPE,i ),         ;
                                     dbFieldInfo( DBS_LEN,i ),          ;
                                     dbFieldInfo( DBS_DEC,i ),          ;
                                     lEditable ) )
   next

   oBrw:Refresh()

RETURN Nil

Function VScrollPos( oBrw, nType, lEof, nPos )
Local maxPos := hwg_getAdjValue( oBrw:hScrollV,1 ) - hwg_getAdjValue( oBrw:hScrollV,4 )
Local oldRecno, newRecno

   IF nPos == Nil
      IF nType > 0 .AND. lEof
         EVAL( oBrw:bSkip, oBrw,- 1 )
      ENDIF
      nPos := Round( ( maxPos/(oBrw:kolz-1) ) * ( EVAL( oBrw:bRecnoLog,oBrw )-1 ),0 )
      hwg_SetAdjOptions( oBrw:hScrollV,nPos )
      oBrw:nScrollV := nPos
   ELSE
      oldRecno := EVAL( oBrw:bRecnoLog,oBrw )
      newRecno := Round( (oBrw:kolz-1)*nPos/maxPos+1,0 )
      IF newRecno <= 0
         newRecno := 1
      ELSEIF newRecno > oBrw:kolz
         newRecno := oBrw:kolz
      ENDIF
      IF newRecno != oldRecno
         EVAL( oBrw:bSkip, oBrw, newRecno - oldRecno )
         IF oBrw:rowCount - oBrw:rowPos > oBrw:kolz - newRecno
            oBrw:rowPos := oBrw:rowCount - ( oBrw:kolz - newRecno )
         ENDIF
         IF oBrw:rowPos > newRecno
            oBrw:rowPos := newRecno
         ENDIF
         oBrw:Refresh()
      ENDIF
   ENDIF

Return Nil

//----------------------------------------------------//
// Agregado x WHT. 27.07.02
// Locus metodus.
METHOD ShowSizes() CLASS HBrowse
   local cText := ""
   aeval( ::aColumns,;
          { | v,e | cText += ::aColumns[e]:heading + ": " + str( round(::aColumns[e]:width/8,0)-2  ) + chr(10)+chr(13) } )
   MsgInfo( cText )
RETURN nil

Function ColumnArBlock()
Return {|value,o,n| Iif( value==Nil,o:msrec[o:tekzp,n],o:msrec[o:tekzp,n]:=value ) }

Static function HdrToken(cStr, nMaxLen, nCount)
Local nL, nPos := 0

   nMaxLen := nCount := 0
   cStr += ';'
   while (nL := Len(__StrTkPtr(@cStr, @nPos, ";"))) != 0
      nMaxLen := Max( nMaxLen, nL )
      nCount ++
   enddo
RETURN nil
