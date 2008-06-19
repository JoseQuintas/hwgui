/*
 * $Id: hbrowse.prg,v 1.126 2008-06-19 04:38:48 giuseppem Exp $
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
#include "common.ch"

REQUEST DBGOTOP
REQUEST DBGOTO
REQUEST DBGOBOTTOM
REQUEST DBSKIP
REQUEST RECCOUNT
REQUEST RECNO
REQUEST EOF
REQUEST BOF

#define HDM_GETITEMCOUNT    4608

//#define DLGC_WANTALLKEYS    0x0004      /* Control wants all keys */

static ColSizeCursor := 0
static arrowCursor := 0
static oCursor     := 0
static xDrag

//----------------------------------------------------//
CLASS HColumn INHERIT HObject

   DATA block,heading,footing,width,type
   DATA length INIT 0
   DATA dec,cargo
   DATA nJusHead, nJusLin, nJusFoot        // Para poder Justificar los Encabezados
                                           // de las columnas y lineas.
   DATA tcolor,bcolor,brush
   DATA oFont
   DATA lEditable INIT .F.       // Is the column editable
   DATA aList                    // Array of possible values for a column -
                                 // combobox will be used while editing the cell
   DATA aBitmaps
   DATA bValid,bWhen             // When and Valid codeblocks for cell editing
   DATA bEdit                    // Codeblock, which performs cell editing, if defined
   DATA cGrid                    // Specify border for Header (SNWE), can be
                                 // multiline if separated by ;
   DATA lSpandHead INIT .F.
   DATA lSpandFoot INIT .F.
   DATA Picture
   DATA bHeadClick
   DATA bColorFoot               //   bColorFoot must return an array containing two colors values
                                 //   oBrowse:aColumns[1]:bColorFoot := {|| IF (nNumber < 0, ;
                                 //      {textColor, backColor} , ;
                                 //      {textColor, backColor} ) }

   DATA bColorBlock              //   bColorBlock must return an array containing four colors values
                                 //   oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
                                 //      {textColor, backColor, textColorSel, backColorSel} , ;
                                 //      {textColor, backColor, textColorSel, backColorSel} ) }
   METHOD New( cHeading,block,type,length,dec,lEditable,nJusHead,nJusLin,cPict,bValid,bWhen,aItem,bColorBlock, bHeadClick )

ENDCLASS

//----------------------------------------------------//
METHOD New( cHeading,block,type,length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick ) CLASS HColumn

   ::heading   := iif( cHeading == nil,"",cHeading )
   ::block     := block
   ::type      := type
   ::length    := length
   ::dec       := dec
   ::lEditable := Iif( lEditable != Nil,lEditable,.F. )
   ::nJusHead  := iif( nJusHead == nil,  DT_LEFT , nJusHead )  // Por default
   ::nJusLin   := iif( nJusLin  == nil,  DT_LEFT , nJusLin  )  // Justif.Izquierda
   ::nJusFoot  := ::nJusLin
   ::picture   := cPict
   ::bValid    := bValid
   ::bWhen     := bWhen
   ::aList     := aItem
   ::bColorBlock := bColorBlock
   ::bHeadClick  := bHeadClick
   ::footing := ""
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
   DATA freeze                                 // Number of columns to freeze
   DATA nRecords     INIT 0                    // Number of records in browse
   DATA nCurrent     INIT 1                    // Current record
   DATA aArray                                 // An array browsed if this is BROWSE ARRAY
   DATA recCurr 		INIT 0
   DATA headColor                      // Header text color
   DATA sepColor 		INIT 12632256             // Separators color
   DATA lSep3d  		INIT .F.
   DATA varbuf                                 // Used on Edit()
   DATA tcolorSel,bcolorSel,brushSel, htbColor, httColor // Hilite Text Back Color
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
   DATA lEditable INIT .T.
   DATA lAppable  INIT .F.
   DATA lAppMode  INIT .F.
   DATA lAutoEdit INIT .F.
   DATA lUpdated  INIT .F.
   DATA lAppended INIT .F.
   DATA lESC      INIT .F.
   DATA lAdjRight INIT .T.                     // Adjust last column to right
   DATA nHeadRows INIT 1                       // Rows in header
   DATA nFootRows INIT 0                       // Rows in footer
   DATA lResizing INIT .F.                     // .T. while a column resizing is undergoing
   DATA lCtrlPress INIT .F.                    // .T. while Ctrl key is pressed
   DATA lShiftPress INIT .F.                    // .T. while Shift key is pressed
   DATA aSelected                              // An array of selected records numbers
   DATA nWheelPress INIT 0							   // wheel or central button mouse pressed flag
	
   DATA lDescend INIT .F.              // Descend Order?
   DATA lFilter INIT .F.               // Filtered? (atribuition is automatic in method "New()").
   DATA bFirst INIT {|| DBGOTOP()}     // Block to place pointer in first record of condition filter. (Ex.: DbGoTop(), DbSeek(), etc.).
   DATA bLast  INIT {|| DBGOBOTTOM()}  // Block to place pointer in last record of condition filter. (Ex.: DbGoBottom(), DbSeek(), etc.).
   DATA bWhile INIT {|| .T.}           // Clausule "while". Return logical.
   DATA bFor INIT {|| .T.}             // Clausule "for". Return logical.
   DATA nLastRecordFilter INIT 0       // Save the last record of filter.
   DATA nFirstRecordFilter INIT 0      // Save the first record of filter.
   DATA nPaintRow, nPaintCol                   // Row/Col being painted

   METHOD New( lType,oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont, ;
                  bInit,bSize,bPaint,bEnter,bGfocus,bLfocus,lNoVScroll,lNoBorder,;
                  lAppend,lAutoedit,bUpdate,bKeyDown,bPosChg,lMultiSelect, bFirst, bWhile, bFor  )
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
   METHOD Paint(lLostFocus)
   METHOD LineOut()
   METHOD Select()
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
   METHOD Home()  INLINE ::DoHScroll( SB_LEFT )
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
                  lNoBorder,lAppend,lAutoedit,bUpdate,bKeyDown,bPosChg,lMultiSelect,;
                  lDescend, bWhile, bFirst, bLast, bFor  ) CLASS HBrowse

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
   ::lDescend    := Iif( lDescend==Nil,.F.,lDescend )

   IF ISBLOCK(bFirst) .OR. ISBLOCK(bFor) .OR. ISBLOCK(bWhile)
     ::lFilter := .T.
     IF ISBLOCK(bFirst)
       ::bFirst  := bFirst
     ENDIF
     IF ISBLOCK(bLast)
       ::bLast   := bLast
     ENDIF
     IF ISBLOCK(bWhile)
       ::bWhile  := bWhile
     ENDIF
     IF ISBLOCK(bFor)
       ::bFor    := bFor
     ENDIF
   ELSE
     ::lFilter := .F.
   ENDIF

   hwg_RegBrowse()
   ::InitBrw()
   ::Activate()

RETURN Self

//----------------------------------------------------//
METHOD Activate CLASS HBrowse
   IF !empty( ::oParent:handle ) 
      ::handle := CreateBrowse( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD onEvent( msg, wParam, lParam )  CLASS HBrowse
Local oParent, cKeyb, nCtrl, nPos, lBEof
Local nRecStart, nRecStop

   IF ::active .AND. !Empty( ::aColumns )

      IF ::bOther != Nil
         Eval( ::bOther,Self,msg,wParam,lParam )
      ENDIF

      IF msg == WM_PAINT
         ::Paint()
         RETURN 1

      ELSEIF msg == WM_ERASEBKGND
         RETURN 0

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
         RETURN DLGC_WANTALLKEYS

      ELSEIF msg == WM_COMMAND
         // Super:onEvent( WM_COMMAND )
         DlgCommand( Self, wParam, lParam )

      ELSEIF msg == WM_KEYUP
         IF wParam == 17
            ::lCtrlPress := .F.
         ENDIF
         IF wParam == 16
            ::lShiftPress := .F.
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
         IF wParam == VK_TAB
          IF ::lCtrlPress                                                              
             nPos := AScan( ::oParent:acontrols, { | o | o:handle == ::HANDLE } )      
             IF GetKeyState(VK_SHIFT) < 0                                              
                nPos := IIF(nPos <= 1 ,len(::oParent:acontrols),nPos-1)                
             ELSE                                                                      
                nPos := IIF(nPos = 0 .OR. nPos=len(::oParent:acontrols),1,nPos+1)      
             ENDIF                                                                     
             ::oParent:acontrols[nPos]:setFocus()                                      
          ELSE                                                                         
             IF GetKeyState(VK_SHIFT) < 0                                              
                ::DoHScroll( SB_LINELEFT )                                             
             ELSE                                                                      
                ::DoHScroll( SB_LINERIGHT )                                            
             ENDIF                                                                     
          endif                                                                        
         elseIF wParam == 40        // Down
            IF ::lShiftPress .AND. ::aSelected != Nil
                 Eval(::bskip, Self, 1)
                 lBEof:=Eval(::beof, Self)
                 Eval(::bskip, Self, -1)
                 IF !(lBEof .and. Ascan( ::aSelected, Eval( ::bRecno,Self ) )>0)
                    ::select()
                    if lBeof
                       ::refreshline()
                    endif
                 ENDIF
            ENDIF
            ::LINEDOWN()

         ELSEIF wParam == 38    // Up

            IF ::lShiftPress .AND. ::aSelected != Nil
                 Eval(::bskip, Self, 1)
                 lBEof:=Eval(::beof, Self)
                 Eval(::bskip, Self, -1)
                 IF !(lBEof .and. Ascan( ::aSelected, Eval( ::bRecno,Self ) )>0)
                    ::LINEUP()
                 ENDIF
            ELSE
                 ::LINEUP()
            ENDIF

            IF ::lShiftPress .AND. ::aSelected != Nil
                 Eval(::bskip, Self, -1)
                 IF !lBEof:=Eval(::bBof, Self)
                    Eval(::bskip, Self, 1)
                 ENDIF
                 IF !(lBEof .and. Ascan( ::aSelected, Eval( ::bRecno,Self ) )>0)
                     ::select()
                     ::refresh(.f.)
                 ENDIF
            ENDIF

         ELSEIF wParam == 39    // Right
            ::DoHScroll( SB_LINERIGHT )
         ELSEIF wParam == 37    // Left
            ::DoHScroll( SB_LINELEFT )
         ELSEIF wParam == 36    // Home
            ::DoHScroll( SB_LEFT )
         ELSEIF wParam == 35    // End
            ::DoHScroll( SB_RIGHT )
         ELSEIF wParam == 34    // PageDown
            nRecStart:=Eval(::brecno, Self)
            IF ::lCtrlPress
                if( ::nRecords > ::rowCount )
               ::BOTTOM()
                else
                   ::PageDown()
                endif
            ELSE
               ::PageDown()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != Nil
                nRecStop:=Eval(::brecno, Self)
                Eval(::bskip, Self, 1)
                lBEof:=Eval(::beof, Self)
                Eval(::bskip, Self, -1)
                IF !(lBEof .and. Ascan( ::aSelected, Eval( ::bRecno,Self ) )>0)
                    ::select()
                ENDIF
                DO WHILE Eval( ::bRecno,Self ) != nRecStart
                     ::Select()
                     Eval(::bskip, Self, -1)
                ENDDO
                ::Select()
                Eval(::bgoto, Self, nRecStop)
                Eval(::bskip, Self, 1)
                IF Eval(::beof, self)
                   Eval(::bskip, Self, -1)
                   ::Select()
                ELSE
                   Eval(::bskip, Self, -1)
                ENDIF
                ::Refresh()
            ENDIF
         ELSEIF wParam == 33    // PageUp
            nRecStop:=Eval(::brecno, Self)
            IF ::lCtrlPress
               ::TOP()
            ELSE
               ::PageUp()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != Nil
                nRecStart:=Eval( ::bRecno,Self )
                DO WHILE Eval( ::bRecno,Self ) != nRecstop
                     ::Select()
                     Eval(::bskip, Self, 1)
                ENDDO

                Eval(::bgoto, Self, nRecStart)
                ::Refresh()
            ENDIF

         ELSEIF wParam == 13    // Enter
            ::Edit()

         ELSEIF wParam == 27 .AND. ::lESC
            SendMessage( GetParent(::handle),WM_CLOSE,0,0 )
         ELSEIF wParam == 17
            ::lCtrlPress := .T.
         ELSEIF wParam == 16
            ::lShiftPress := .T.
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
         IF ::nWheelPress > 0
            ::MouseWheel( LoWord( wParam ),::nWheelPress - lParam)
         ELSE   
            ::MouseMove( wParam, lParam )
			ENDIF
			
      ELSEIF msg == WM_MBUTTONUP                   
         ::nWheelPress := IIF(::nWheelPress>0,0,lParam)
         IF ::nWheelPress > 0
           Hwg_SetCursor( LOADCURSOR(32652))
         ELSE
           Hwg_SetCursor( LOADCURSOR(IDC_ARROW))
			ENDIF
			  
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
Local xres,ctype

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
         xRes     := Eval( oColumn:block,,oBrw,n )
         cType    := Valtype( xRes )
      ENDIF
//      oColumn:length := Max( oColumn:length, Len( oColumn:heading ) )
      oColumn:length := LenVal(xres,ctype,oColumn:picture)
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
      ::rowPos    := ::nCurrent  := ::colpos := ::nLeftCol := 1
      ::freeze  := ::height := 0
      ::internal  := { 15,1 }
      ::aArray     := Nil

      IF ColSizeCursor == 0
         ColSizeCursor := LoadCursor( IDC_SIZEWE )
         arrowCursor := LoadCursor( IDC_ARROW )
      ENDIF
   ENDIF

   IF ::type == BRW_DATABASE
      ::alias   := Alias()
      IF ::lFilter
        ::nLastRecordFilter  := ::nFirstRecordFilter := 0
        IF ::lDescend
           ::bSkip     := { |o, n| (::alias)->(FltSkip(o, n, .T.)) }
           ::bGoTop    := { |o| (::alias)->(FltGoBottom(o)) }
           ::bGoBot    := { |o| (::alias)->(FltGoTop(o)) }
           ::bEof      := { |o| (::alias)->(FltBOF(o)) }
           ::bBof      := { |o| (::alias)->(FltEOF(o)) }
        ELSE
           ::bSkip     := { |o, n| (::alias)->(FltSkip(o, n, .F.)) }
        ::bGoTop    := { |o| (::alias)->(FltGoTop(o)) }
        ::bGoBot    := { |o| (::alias)->(FltGoBottom(o)) }
        ::bEof      := { |o| (::alias)->(FltEOF(o)) }
        ::bBof      := { |o| (::alias)->(FltBOF(o)) }
        ENDIF
        ::bRcou     := { |o| (::alias)->(FltRecCount(o)) }
        ::bRecnoLog := ::bRecno := { |o| (::alias)->(FltRecNo(o)) }
        ::bGoTo     := { |o, n|(::alias)->(FltGoTo(o, n)) }
      ELSE
        ::bSkip     :=  {|o, n| (::alias)->(DBSKIP(n)) }
        ::bGoTop    :=  {|| (::alias)->(DBGOTOP())}
        ::bGoBot    :=  {|| (::alias)->(DBGOBOTTOM())}
        ::bEof      :=  {|| (::alias)->(EOF())}
        ::bBof      :=  {|| (::alias)->(BOF())}
        ::bRcou     :=  {|| (::alias)->(RECCOUNT())}
        ::bRecnoLog := ::bRecno  := {||(::alias)->(RECNO())}
        ::bGoTo     := {|a,n|(::alias)->(DBGOTO(n))}
      ENDIF
   ELSEIF ::type == BRW_ARRAY
      ::bSkip      := { | o, n | ARSKIP( o, n ) }
      ::bGoTop  := { | o | o:nCurrent := 1 }
      ::bGoBot  := { | o | o:nCurrent := o:nRecords }
      ::bEof    := { | o | o:nCurrent > o:nRecords }
      ::bBof    := { | o | o:nCurrent == 0 }
      ::bRcou   := { | o | len( o:aArray ) }
      ::bRecnoLog := ::bRecno  := { | o | o:nCurrent }
      ::bGoTo   := { | o, n | o:nCurrent := n }
      ::bScrollPos := {|o,n,lEof,nPos|VScrollPos(o,n,lEof,nPos)}
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD Rebuild() CLASS HBrowse
Local i, j, oColumn, xSize, nColLen, nHdrLen, nCount

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
   FOR i := 1 TO len( ::aColumns )

      oColumn := ::aColumns[i]

      IF oColumn:lEditable
         ::lEditable := .T.
      ENDIF

      IF oColumn:aBitmaps != Nil
         IF oColumn:heading != nil
             IF ::oFont != Nil
                xSize := round( ( len(oColumn:heading) + 2 ) * ((-::oFont:height)*0.6), 0 )
             ELSE
                xSize := round( ( len(oColumn:heading) + 2 ) * 6, 0 )
             ENDIF
         ELSE
            xSize := 0
         ENDIF
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
      IF Empty( oColumn:width )
         oColumn:width := xSize
      ENDIF
   NEXT

   ::lChanged := .F.

RETURN Nil

//----------------------------------------------------//
METHOD Paint(lLostFocus)  CLASS HBrowse
Local aCoors, aMetr, cursor_row, tmp, nRows
Local pps, hDC

   IF !::active .OR. Empty( ::aColumns )
      RETURN Nil
   ENDIF

// Validate some variables

   IF ::tcolor    == Nil ; ::tcolor    := 0 ; ENDIF
   IF ::bcolor    == Nil ; ::bcolor    := VColor( "FFFFFF" ) ; ENDIF

   IF ::httcolor  == Nil ; ::httcolor  := VColor( "FFFFFF" ) ; ENDIF
   IF ::htbcolor  == Nil ; ::htbcolor  := 2896388  ; ENDIF

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
   ::width := Round( ( aMetr[ 3 ] + aMetr[ 2 ] ) / 2 - 1,0 )
   ::height := Max( aMetr[ 1 ], ::minHeight ) + 1
   ::x1 := aCoors[ 1 ]
   ::y1 := aCoors[ 2 ] + Iif( ::lDispHead, ::height*::nHeadRows, 0 )
   ::x2 := aCoors[ 3 ]
   ::y2 := aCoors[ 4 ]

   ::nRecords := eval( ::bRcou,Self )
   IF ::nCurrent > ::nRecords .AND. ::nRecords > 0
      ::nCurrent := ::nRecords
   ENDIF

// Calculate number of columns visible

   ::nColumns := FLDCOUNT( Self, ::x1 + 2, ::x2 - 2, ::nLeftCol )

// Calculate number of rows the canvas can host
   ::rowCount := Int( (::y2-::y1) / (::height+1) ) - ::nFootRows

// nRows: if number of data rows are less than video rows available....
   nRows := Min( ::nRecords,::rowCount )

   IF ::internal[1] == 0
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval( ::bSkip, Self, ::internal[2]-::rowPos )
      ENDIF
      IF ::aSelected != Nil .AND. Ascan(::aSelected, {|x| x=Eval( ::bRecno,Self )}) > 0
         ::LineOut( ::internal[2], 0, hDC, .T. )
      ELSE
         ::LineOut( ::internal[2], 0, hDC, .F. )
      ENDIF
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval( ::bSkip, Self, ::rowPos-::internal[2] )
      ENDIF
   ELSE
      IF Eval( ::bEof,Self ) .OR. Eval( ::bBof,Self )
         Eval( ::bGoTop, Self )
         ::rowPos := 1
      ENDIF

// Se riga_cursore_video > numero_record
//    metto il cursore sull'ultima riga
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF

// Take record number
      tmp := Eval( ::bRecno,Self )

// if riga_cursore_video > 1
//   we skip ::rowPos-1 number of records back, 
//   actually positioning video cursor on first line
      IF ::rowPos > 1
         Eval( ::bSkip, Self,-(::rowPos-1) )
      ENDIF

// Browse printing is split in two parts
// first part starts from video row 1 and goes to end of data (EOF)
//   or end of video lines

// second part starts from where part 1 stopped - 

      cursor_row := 1
      DO WHILE .T.
         // if we are on the current record, set current video line
         IF Eval( ::bRecno,Self ) == tmp
            ::rowPos := cursor_row
         ENDIF

         // exit loop when at last row or eof()
         IF cursor_row > nRows .OR. Eval( ::bEof,Self )
            EXIT
         ENDIF

         // decide how to print the video row
         IF ::aSelected != Nil .AND. Ascan(::aSelected, {|x| x=Eval( ::bRecno,Self )}) > 0
            ::LineOut( cursor_row, 0, hDC, .T. )
         ELSE
            ::LineOut( cursor_row, 0, hDC, .F. )
         ENDIF
         cursor_row ++
         Eval( ::bSkip, Self,1 )
      ENDDO
      ::rowCurrCount := cursor_row - 1

      // set current_video_line depending on the situation
      IF ::rowPos >= cursor_row
         ::rowPos := Iif( cursor_row > 1,cursor_row - 1,1 )
      ENDIF

      // print the rest of the browse
      DO WHILE cursor_row <= nRows
         IF ::aSelected != Nil .AND. Ascan(::aSelected, {|x| x=Eval( ::bRecno,Self )}) > 0
            ::LineOut( cursor_row, 0, hDC, .t.,.T. )
         ELSE
            ::LineOut( cursor_row, 0, hDC, .F.,.T. )
         ENDIF
         cursor_row ++
      ENDDO
      
      if nRows < ::rowCount
           FillRect( hDC, ::x1, ::y1 + (::height + 1) * nRows + 1, ::x2, ::y2, ::brush:handle )
      endif
      Eval( ::bGoTo, Self,tmp )
   ENDIF
   IF ::lAppMode
      ::LineOut( nRows+1, 0, hDC, .F.,.T. )
   ENDIF

   //::LineOut( ::rowPos, Iif( ::lEditable, ::colpos, 0 ), hDC, .T. )

   // Highlights the selected ROW
   // we can have a modality with CELL selection only or ROW selection
   ::LineOut( ::rowPos, 0, hDC, .T. )

   // Highligths the selected cell
   // FP: Reenabled the lEditable check as it's not possible
   //     to move the "cursor cell" if lEditable is FALSE
   //     Actually: if lEditable is FALSE we can only have LINE selection
//   if ::lEditable
      if lLostFocus==NIL
        ::LineOut( ::rowPos,::colpos, hDC, .T. )
      endif
//   endif

   // if bit-1 refresh header and footer
   IF Checkbit( ::internal[1],1 ) .OR. ::lAppMode
      if ::nHeadRows > 0
          ::HeaderOut( hDC )
      ENDIF    
      IF ::nFootRows > 0
         ::FooterOut( hDC )
      ENDIF
   ENDIF

   // End paint block
   EndPaint( ::handle, pps )

   ::internal[1] := 15
   ::internal[2] := ::rowPos

   // calculate current bRecno()
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


   ::lAppMode := .F.

RETURN Nil

//----------------------------------------------------//
// TODO: __StrToken can create problems.... can't have separator as first char
METHOD HeaderOut( hDC ) CLASS HBrowse
Local i, x, oldc, fif, xSize
Local nRows := Min( ::nRecords+Iif(::lAppMode,1,0),::rowCount )
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
            // Draws a grid to the NWSE coordinate...
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
         // Prints the column heading - justified
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
Local x, fif, xSize, oPen, nLine, cStr
Local oColumn, aColorFoot, oldBkColor, oldTColor, oBrush

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
      cStr := oColumn:footing + ';'
      aColorFoot:=Nil
      IF oColumn:bColorFoot != Nil
         aColorFoot := eval(oColumn:bColorFoot,Self)
         oldBkColor := SetBkColor(   hDC, aColorFoot[2])
         oldTColor  := SetTextColor( hDC, aColorFoot[1])
         oBrush := HBrush():Add( aColorFoot[2] )
      ELSE
         oBrush := ::brush
      ENDIF

      FillRect( hDC,x, ::y1+::rowCount*(::height+1)+1, ;
                  x+xSize, ::y1+(::rowCount+::nFootRows)*(::height+1), oBrush:handle )

      FOR nLine := 1 TO ::nFootRows

         DrawText( hDC, __StrToken(@cStr, nLine, ';'),;
                   x, ::y1+(::rowCount+nLine-1)*(::height+1)+1, x+xSize-1, ::y1+(::rowCount+nLine)*(::height+1),;
                   oColumn:nJusFoot + if(oColumn:lSpandFoot, DT_NOCLIP, 0) )
      NEXT

      IF aColorFoot != Nil
         SetBkColor(   hDC, oldBkColor)
         SetTextColor( hDC, oldTColor)
         oBrush:release()
      ENDIF

      IF ::lDispSep .AND. x >= ::x1
         DrawLine(hDC,x+xSize-1,::y1+::rowCount*(::height+1)+1 , x+xSize-1, ::y1+(::rowCount+::nFootRows)*(::height+1))
      ENDIF

      x += xSize
      fif := Iif( fif = ::freeze, ::nLeftCol, fif + 1 )
      IF fif > Len( ::aColumns )
         exit
      ENDIF
   ENDDO

   IF ::lDispSep
      DrawLine( hDC, ::x1, ::y1+(::rowCount)*(::height+1)+1, iif(::lAdjRight, ::x2, x), ::y1+(::rowCount)*(::height+1)+1 )
      DrawLine( hDC, ::x1, ::y1+(::rowCount+::nFootRows)*(::height+1), iif(::lAdjRight, ::x2, x), ::y1+(::rowCount+::nFootRows)*(::height+1) )
      oPen:Release()
   ENDIF

RETURN Nil

//-------------- -Row--  --Col-- ------------------------------//
METHOD LineOut( nstroka, vybfld, hDC, lSelected, lClear ) CLASS HBrowse
Local x, nColumn, sviv, fldname, xSize
Local j, ob, bw, bh, y1, hBReal
Local oldBkColor, oldTColor, oldBk1Color, oldT1Color
Local oLineBrush :=  iif(vybfld>=1, HBrush():Add(::htbColor), Iif( lSelected, ::brushSel,::brush ))
Local lColumnFont := .F.
//Local nPaintCol, nPaintRow
Local aCores

   nColumn := 1
   x := ::x1
   IF lClear == Nil ; lClear := .F. ; ENDIF

   IF ::bLineOut != Nil
      Eval( ::bLineOut,Self,lSelected )
   ENDIF
   IF ::nRecords > 0
      oldBkColor := SetBkColor(   hDC, iif(vybfld>=1,::htbcolor, Iif( lSelected,::bcolorSel,::bcolor )))
      oldTColor  := SetTextColor( hDC, iif(vybfld>=1,::httcolor, Iif( lSelected,::tcolorSel,::tcolor )))
      fldname := SPACE( 8 )
      ::nPaintCol  := Iif( ::freeze>0, 1, ::nLeftCol )
      ::nPaintRow  := nstroka

      WHILE x < ::x2 - 2

         // if bColorBlock defined get the colors
         IF ::aColumns[::nPaintCol]:bColorBlock != Nil
            aCores := eval(::aColumns[::nPaintCol]:bColorBlock)
            IF lSelected
              ::aColumns[::nPaintCol]:tColor := aCores[3]
              ::aColumns[::nPaintCol]:bColor := aCores[4]
            ELSE
              ::aColumns[::nPaintCol]:tColor := aCores[1]
              ::aColumns[::nPaintCol]:bColor := aCores[2]
            ENDIF
            ::aColumns[::nPaintCol]:brush := HBrush():Add(::aColumns[::nPaintCol]:bColor   )
         ENDIF
         xSize := ::aColumns[::nPaintCol]:width
         IF ::lAdjRight .and. ::nPaintCol == LEN( ::aColumns )
            xSize := Max( ::x2 - x, xSize )
         ENDIF
         IF vybfld == 0 .OR. vybfld == nColumn
            IF ::aColumns[::nPaintCol]:bColor != Nil .AND. ::aColumns[::nPaintCol]:brush == Nil
               ::aColumns[::nPaintCol]:brush := HBrush():Add( ::aColumns[::nPaintCol]:bColor )
            ENDIF
            hBReal := Iif( ::aColumns[::nPaintCol]:brush != Nil .AND. (::nPaintCol != ::colPos .OR. !lSelected), ;
                           ::aColumns[::nPaintCol]:brush:handle,   ;
                           oLineBrush:handle )

            // Fill background color of a cell
            FillRect( hDC, x, ::y1+(::height+1)*(::nPaintRow-1)+1, ;
                           x+xSize-Iif(::lSep3d,2,1),::y1+(::height+1)*::nPaintRow, hBReal )

            IF !lClear
               IF ::aColumns[::nPaintCol]:aBitmaps != Nil .AND. !Empty( ::aColumns[::nPaintCol]:aBitmaps )
                  FOR j := 1 TO Len( ::aColumns[::nPaintCol]:aBitmaps )
                     IF Eval( ::aColumns[::nPaintCol]:aBitmaps[j,1],Eval( ::aColumns[::nPaintCol]:block,,Self,::nPaintCol ),lSelected )
                        ob := ::aColumns[::nPaintCol]:aBitmaps[j,2]
                        IF ob:nHeight > ::height
                           y1 := 0
                           bh := ::height
                           bw := Int( ob:nWidth * ( ob:nHeight / ::height ) )
                           DrawBitmap( hDC, ob:handle,, x+(int(::aColumns[::nPaintCol]:width-ob:nWidth)/2), y1+::y1+(::height+1)*(::nPaintRow-1)+1, bw, bh )
                        ELSE
                           y1 := Int( (::height-ob:nHeight)/2 )
                           bh := ob:nHeight
                           bw := ob:nWidth
                           DrawTransparentBitmap( hDC, ob:handle, x+(int(::aColumns[::nPaintCol]:width-ob:nWidth)/2), y1+::y1+(::height+1)*(::nPaintRow-1)+1 )
                        ENDIF
                        // DrawBitmap( hDC, ob:handle,, x, y1+::y1+(::height+1)*(::nPaintRow-1)+1, bw, bh )
                        EXIT
                     ENDIF
                  NEXT
               ELSE
                  sviv := FLDSTR( Self, ::nPaintCol)
                  // Ahora lineas Justificadas !!
                  IF ::aColumns[::nPaintCol]:tColor != Nil .AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     oldT1Color := SetTextColor( hDC, ::aColumns[::nPaintCol]:tColor )
                  ENDIF

                  IF ::aColumns[::nPaintCol]:bColor != Nil .AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     oldBk1Color := SetBkColor( hDC, ::aColumns[::nPaintCol]:bColor )
                  ENDIF
                  IF ::aColumns[::nPaintCol]:oFont != Nil
                     SelectObject( hDC, ::aColumns[::nPaintCol]:oFont:handle )
                     lColumnFont := .T.
                  ELSEIF lColumnFont
                     SelectObject( hDC, ::ofont:handle )
                     lColumnFont := .F.
                  ENDIF

                  DrawText( hDC, sviv, x, ::y1+(::height+1)*(::nPaintRow-1)+1, x+xSize-2,::y1+(::height+1)*::nPaintRow-1, ::aColumns[::nPaintCol]:nJusLin )

                  IF ::aColumns[::nPaintCol]:tColor != Nil .AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     SetTextColor( hDC, oldT1Color )
                  ENDIF

                  IF ::aColumns[::nPaintCol]:bColor != Nil .AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     SetBkColor( hDC, oldBk1Color )
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         x += xSize
         ::nPaintCol := Iif( ::nPaintCol == ::freeze, ::nLeftCol, ::nPaintCol + 1 )
         nColumn ++
         IF ! ::lAdjRight .and. ::nPaintCol > LEN( ::aColumns )
            EXIT
         ENDIF
      ENDDO

// Fill the browse canvas from x+::width to ::x2-2
// when all columns width less than canvas width (lAdjRight == .F.)

      IF ! ::lAdjRight .and. ::nPaintCol == LEN( ::aColumns ) + 1
         xSize := Max( ::x2 - x, xSize )
         FillRect( hDC, x, 0, ;
            x+xSize-Iif(::lSep3d,2,1), ::y2, oLineBrush )
      ENDIF

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
// Move the visible browse one step to the left
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

   ELSEIF nScrollCode == SB_THUMBPOSITION .OR. nScrollCode == SB_THUMBTRACK
      SetFocus( ::handle )
      IF ::bScrollPos != Nil
         Eval( ::bScrollPos, Self, nScrollCode, .F., Hiword( wParam ) )
      ELSE
         IF ( ::Alias ) -> ( IndexOrd() ) == 0              // sk
            ( ::Alias ) -> ( DbGoto( HiWord( wParam ) ) )   // sk
         ELSE
            ( ::alias )->( OrdKeyGoTo( Hiword( wParam ) ) ) // sk
         ENDIF
         Eval( ::bSkip, Self, 1 )
         Eval( ::bSkip, Self, -1 )
         VScrollPos( Self, 0, .f.)
         ::refresh(.F.)
      ENDIF
   ENDIF
RETURN 0


//----------------------------------------------------//
METHOD DoHScroll( wParam ) CLASS HBrowse
Local nScrollCode := LoWord( wParam )
Local nPos
Local oldLeft := ::nLeftCol, nLeftCol, colpos, oldPos := ::colpos

   IF nScrollCode == SB_LINELEFT .OR. nScrollCode == SB_PAGELEFT
      LineLeft( Self )

   ELSEIF nScrollCode == SB_LINERIGHT .OR. nScrollCode == SB_PAGERIGHT
      LineRight( Self )

   ELSEIF nScrollCode == SB_LEFT
      nLeftCol := colPos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colPos != ::colPos
         nLeftCol := ::nLeftCol
         colPos := ::colPos
         LineLeft( Self )
      ENDDO
   ELSEIF nScrollCode == SB_RIGHT
      nLeftCol := colPos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colPos != ::colPos
         nLeftCol := ::nLeftCol
         colPos := ::colPos
         LineRight( Self )
      ENDDO
   ELSEIF nScrollCode == SB_THUMBTRACK .OR. nScrollCode == SB_THUMBPOSITION
         SetFocus( ::handle )
         IF ::lEditable
             SetScrollRange( ::handle, SB_HORZ, 1, Len( ::aColumns ))
             SetScrollPos( ::handle, SB_HORZ, Hiword( wParam ) )
             ::SetColumn(Hiword( wParam ))
         ELSE
             IF Hiword( wParam ) > (::colpos + ::nLeftCol - 1)
                LineRight( Self )
             ENDIF
             IF Hiword( wParam ) < (::colpos + ::nLeftCol - 1)
                LineLeft( Self )
             ENDIF
         ENDIF
   ENDIF

   IF ::nLeftCol != oldLeft .OR. ::colpos != oldpos

      SetScrollRange( ::handle, SB_HORZ, 1, Len( ::aColumns ) )
      nPos :=  ::colpos + ::nLeftCol - 1
      SetScrollPos( ::handle, SB_HORZ, nPos )

      // TODO: here I force a full repaint and HSCROLL appears...
      //       but we should do more checks....
      // IF ::nLeftCol == oldLeft
      //   ::RefreshLine()
      //ELSE
         RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW )  // Force a complete redraw
      //ENDIF
   ENDIF
   SetFocus( ::handle )

RETURN Nil

//----------------------------------------------------//
METHOD LINEDOWN( lMouse ) CLASS HBrowse

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
   ELSEIF ::nRecords > 1
      VScrollPos( Self, 0, .f.)
   ENDIF

   SetFocus( ::handle )

RETURN Nil

//----------------------------------------------------//
METHOD LINEUP() CLASS HBrowse

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
      ELSEIF ::nRecords > 1
         VScrollPos( Self, 0, .f.)
      ENDIF
      ::internal[1] := SetBit( ::internal[1], 1, 0 )
   ENDIF
   SetFocus( ::handle )
RETURN Nil

//----------------------------------------------------//
METHOD PAGEUP() CLASS HBrowse
Local step, lBof := .F.

   IF ::rowPos > 1
      step := ( ::rowPos - 1 )
      Eval( ::bSKip, Self,- step )
      ::rowPos := 1
   ELSE
      step := ::rowCurrCount    // Min( ::nRecords,::rowCount )
      Eval( ::bSkip, Self,- step )
      IF Eval( ::bBof,Self )
         Eval( ::bGoTop,Self )
         lBof := .T.
      ENDIF
   ENDIF

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, - step, lBof )
   ELSEIF ::nRecords > 1
       VScrollPos( Self, 0, .f.)
   ENDIF

   ::Refresh(.F.)
   SetFocus( ::handle )
RETURN Nil

//----------------------------------------------------//
/**
 * 
 * If cursor is in the last visible line, skip one page
 * If cursor in not in the last line, go to the last
 * 
*/
METHOD PAGEDOWN() CLASS HBrowse
Local nRows := ::rowCurrCount
Local step := Iif( nRows>::rowPos,nRows-::rowPos+1,nRows )

   Eval( ::bSkip, Self, step )

   IF Eval(::bEof, Self)
      Eval(::bSkip, Self, -1)
   ENDIF
   ::rowPos := Min( ::nRecords, nRows )

   IF ::bScrollPos != Nil
      Eval( ::bScrollPos, Self, step, .f. )
   ELSE
      VScrollPos( Self, 0, .f.)
   ENDIF

   ::Refresh(.F.)
   SetFocus( ::handle )

RETURN Nil

//----------------------------------------------------//
METHOD BOTTOM(lPaint) CLASS HBrowse

   if ::type == BRW_ARRAY
       ::nCurrent := ::nRecords
       ::rowPos := ::rowCount + 1
   else
       ::rowPos := Lastrec()
       Eval( ::bGoBot, Self )
   endif

   VScrollPos( Self, 0, .f.)

   InvalidateRect( ::handle, 0 )

   ::internal[1] := SetBit( ::internal[1], 1, 0 )
   IF lPaint == Nil .OR. lPaint
      SetFocus( ::handle )
   ENDIF
RETURN Nil

//----------------------------------------------------//
METHOD TOP() CLASS HBrowse

   ::rowPos := 1
   Eval( ::bGoTop,Self )
   VScrollPos( Self, 0, .f.)

   InvalidateRect( ::handle, 0 )
   ::internal[1] := SetBit( ::internal[1], 1, 0 )
   SetFocus( ::handle )

RETURN Nil

//----------------------------------------------------//
METHOD ButtonDown( lParam ) CLASS HBrowse
Local hBrw := ::handle
Local nLine := Int( HIWORD(lParam)/(::height+1) + Iif(::lDispHead,1-::nHeadRows,1) )
Local step := nLine - ::rowPos, res := .F., nrec
Local xm := LOWORD(lParam), x1, fif

   x1  := ::x1
   fif := Iif( ::freeze > 0, 1, ::nLeftCol )
   DO WHILE fif <= ::nColumns
        if( ! (fif < ( ::nLeftCol + ::nColumns ) .AND. x1 + ::aColumns[ fif ]:width < xm ))
            exit
        endif
      x1 += ::aColumns[ fif ]:width
      fif := Iif( fif == ::freeze, ::nLeftCol, fif + 1 )
   ENDDO

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      IF step != 0
         nrec := Eval(::brecno, Self)
         Eval( ::bSkip, Self, step )
         IF !Eval( ::bEof,Self )
            ::rowPos := nLine
            IF ::bScrollPos != Nil
               Eval( ::bScrollPos, Self, step, .F. )
            ELSEIF ::nRecords > 1
               VScrollPos( Self, 0, .f.)
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
            VScrollPos( Self, 0, .f.)
            res := .T.

         ENDIF

      ENDIF

      IF res
         RedrawWindow( ::handle, RDW_INVALIDATE )

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
      i := Iif( ::freeze > 0, 1, ::nLeftCol )    // ::nLeftCol
      DO WHILE x < xDrag
         x += ::aColumns[i]:width
         IF Abs( x-xDrag ) < 10
            x1 := x - ::aColumns[i]:width
            EXIT
         ENDIF
         i := Iif( i == ::freeze, ::nLeftCol, i + 1 )
      ENDDO
      IF xPos > x1
         ::aColumns[i]:width := xPos - x1
         Hwg_SetCursor( arrowCursor )
         oCursor := 0
         ::lResizing := .F.
         InvalidateRect( hBrw, 0 )
      ENDIF

   ELSEIF ::aSelected != Nil
      IF ::lCtrlPress
         ::select()
         ::refreshline()
      ELSE
         IF Len( ::aSelected ) > 0
            ::aSelected := {}
            ::Refresh()
         ENDIF
      ENDIF
   ENDIF
   SetFocus( ::handle )
RETURN Nil

METHOD Select() CLASS HBrowse
Local i

   IF ( i := Ascan( ::aSelected, Eval( ::bRecno,Self ) ) ) > 0
      Adel( ::aSelected, i )
      Asize( ::aSelected, Len(::aSelected)-1 )
   ELSE
      Aadd(::aSelected, Eval( ::bRecno,Self ) )
   ENDIF

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
   Local x := ::x1, i, res := .F.
   Local nLastColumn   

   nLastColumn := iif( ::lAdjRight, len( ::aColumns )-1, len( ::aColumns ) )

   DlgMouseMove()
   IF !::active .OR. Empty( ::aColumns ) .OR. ::x1 == Nil
      RETURN Nil
   ENDIF
   IF ::lDispSep .AND. yPos <= ::height*::nHeadRows+1
      IF wParam == MK_LBUTTON .AND. ::lResizing
         Hwg_SetCursor( oCursor )
         res := .T.
      ELSE
         i := Iif( ::freeze > 0, 1, ::nLeftCol )
         DO WHILE x < ::x2 - 2 .AND. i <= nLastColumn     // Len( ::aColumns )
            // TraceLog( "Colonna "+str(i)+"    x="+str(x))
            x += ::aColumns[i]:width
            IF Abs( x - xPos ) < 8
               IF oCursor != ColSizeCursor
                  oCursor := ColSizeCursor
               ENDIF
               Hwg_SetCursor( oCursor )
               res := .T.
               EXIT
            ENDIF
            i := Iif( i == ::freeze, ::nLeftCol, i + 1 )
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
Local oGet1, owb1, owb2

   fipos := MIN( ::colpos + ::nLeftCol - 1 - ::freeze, LEN(::aColumns))

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
         IF oColumn:lEditable
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
         IF ::lAppMode .AND. ::nRecords != 0
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

      if type <> "M"
			INIT DIALOG oModDlg;
            STYLE WS_POPUP + 1 + iif( oColumn:aList == Nil, WS_BORDER, 0 ) ;
            AT x1, y1 - Iif( oColumn:aList == Nil, 1, 0 ) ;
            SIZE nWidth, ::height + Iif( oColumn:aList == Nil, 1, 0 ) ;
            ON INIT bInit
      else
         INIT DIALOG oModDlg title "memo edit" AT 0, 0 SIZE 400, 300 ON INIT {|o|o:center()}
      endif

         IF oColumn:aList != Nil .AND. ( oColumn:bWhen = Nil .OR. Eval( oColumn:bWhen ) )
            oModDlg:brush := -1
            oModDlg:nHeight := ::height * 5

            IF valtype(::varbuf) == 'N'
                nChoic := ::varbuf
            ELSE
                ::varbuf := AllTrim(::varbuf)
                nChoic := Ascan( oColumn:aList,::varbuf )
            ENDIF

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
         if type <> "M"
            @ 0,0 GET oGet VAR ::varbuf       ;
               SIZE nWidth, ::height+1        ;
               NOBORDER                       ;
               STYLE ES_AUTOHSCROLL           ;
               FONT ::oFont                   ;
               PICTURE oColumn:picture        ;
               VALID oColumn:bValid           ;
               WHEN oColumn:bWhen
         else
            oGet1 := ::varbuf
            @ 10,10 Get oGet1 SIZE oModDlg:nWidth-20,240 FONT ::oFont Style WS_VSCROLL + WS_HSCROLL + ES_MULTILINE VALID oColumn:bValid
            @ 010,252 ownerbutton owb2 text "Save" size 80,24 ON Click {||::varbuf:=oGet1,omoddlg:close(),oModDlg:lResult:=.t.}
            @ 100,252 ownerbutton owb1 text "Close" size 80,24 ON CLICK {||oModDlg:close()}
         endif
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
                  IF Valtype(::aArray[1]) == "A"
                     Aadd( ::aArray,Array(Len(::aArray[1])) )
                     FOR fif := 2 TO Len((::aArray[1]))
                        ::aArray[Len(::aArray),fif] := ;
                              Iif( ::aColumns[fif]:type=="D",Ctod(Space(8)), ;
                                 Iif( ::aColumns[fif]:type=="N",0,"" ) )
                     NEXT
                  ELSE
                     Aadd( ::aArray,Nil )
                  ENDIF
                  ::nCurrent := Len( ::aArray )
                  Eval( oColumn:block,::varbuf,Self,fipos )
               ENDIF
               IF ::nRecords > 0
                  ::rowPos ++
               ENDIF
               ::lAppended := .T.
               ::Refresh()
            ELSE
               IF ::type == BRW_DATABASE
                  IF (::alias)->( Rlock() )
                     (::alias)->( Eval( oColumn:block,::varbuf,Self,fipos ) )
                     (::alias)->( Dbunlock() )
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
RETURN Nil

//----------------------------------------------------//
METHOD Refresh( lFull ) CLASS HBrowse

   IF lFull == Nil .OR. lFull
      IF ::lFilter
        ::nLastRecordFilter := 0
        ::nFirstRecordFilter := 0
        ( ::alias )->( FltGoTop( Self ) ) // sk
      ENDIF
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
            //cRes := Padr( vartmp, oBrw:aColumns[numf]:length )
       cRes := vartmp
         ELSEIF type == "N"
            cRes := Padl( STR( vartmp, oBrw:aColumns[numf]:length, ;
                   oBrw:aColumns[numf]:dec ),oBrw:aColumns[numf]:length )
         ELSEIF type == "D"
            cRes := Padr( DTOC( vartmp ),oBrw:aColumns[numf]:length )

         ELSEIF type == "L"
            cRes := Padr( Iif( vartmp, "T", "F" ),oBrw:aColumns[numf]:length )

         ELSEIF type == "M"
            cRes := iif(Empty(vartmp),"<memo>","<MEMO>")

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
   oBrw:aArray := arr
   IF Len( oBrw:aColumns ) == 0
      // oBrw:aColumns := {}
      IF Valtype( arr[1] ) == "A"
         FOR i := 1 TO Len( arr[1] )
            oBrw:AddColumn( HColumn():New( ,ColumnArBlock() ) )
         NEXT
      ELSE
         oBrw:AddColumn( HColumn():New( ,{|value,o| o:aArray[ o:nCurrent ] } ) )
      ENDIF
   ENDIF
   Eval( oBrw:bGoTop,oBrw )
   oBrw:Refresh()
RETURN Nil

//----------------------------------------------------//
PROCEDURE ARSKIP( oBrw, nSkip )
Local nCurrent1

   IF oBrw:nRecords != 0
      nCurrent1   := oBrw:nCurrent
      oBrw:nCurrent += nSkip + Iif( nCurrent1 = 0, 1, 0 )
      IF oBrw:nCurrent < 1
         oBrw:nCurrent := 0
      ELSEIF oBrw:nCurrent > oBrw:nRecords
         oBrw:nCurrent := oBrw:nRecords + 1
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
Local minPos, maxPos, oldRecno, newRecno, nrecno

   GetScrollRange( oBrw:handle, SB_VERT, @minPos, @maxPos )
   IF nPos == Nil
     IF oBrw:type <> BRW_DATABASE
         IF nType > 0 .AND. lEof
            Eval( oBrw:bSkip, oBrw,- 1 )
         ENDIF
         nPos := Iif( oBrw:nRecords>1, Round( ( (maxPos-minPos)/(oBrw:nRecords-1) ) * ;
                    ( Eval( oBrw:bRecnoLog,oBrw )-1 ),0 ), minPos )
         SetScrollPos( oBrw:handle, SB_VERT, npos )
     ELSE
         nrecno:=( oBrw:alias )->(recno())
         eval(oBrw:bGotop, oBrw)
         minpos:=if(( oBrw:alias )->(indexord())=0,( oBrw:alias )->(recno()),( oBrw:alias )->(ordkeyno()))
         eval(oBrw:bGobot, oBrw)
         maxpos:=if(( oBrw:alias )->(indexord())=0,( oBrw:alias )->(recno()),( oBrw:alias )->(ordkeyno()))
         IF minPos != maxPos
            SetScrollRange( oBrw:handle, SB_VERT, minPos, maxPos )
         ENDIF
         ( oBrw:alias )->(dbgoto(nrecno))
         SetScrollPos( oBrw:handle, SB_VERT, if(( oBrw:alias )->(indexord())=0,( oBrw:alias )->(recno()),( oBrw:alias )->(ordkeyno())))
     ENDIF
   ELSE
      oldRecno := Eval( oBrw:bRecnoLog,oBrw )
      newRecno := Round( (oBrw:nRecords-1)*nPos/(maxPos-minPos)+1,0 )
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
         oBrw:Refresh(.F.)
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
Local cText := ""

   Aeval( ::aColumns,;
          { | v,e | cText += ::aColumns[e]:heading + ": " + str( round(::aColumns[e]:width/8,0)-2  ) + chr(10)+chr(13) } )
   MsgInfo( cText )
RETURN nil

Function ColumnArBlock()
   RETURN { | value, o, n | IIf( value == Nil, o:aArray[ IIf( o:nCurrent < 1, 1, o:nCurrent ), n ], ;
                                               o:aArray[ IIf( o:nCurrent < 1, 1, o:nCurrent ), n ] := value ) }


Static function HdrToken(cStr, nMaxLen, nCount)
Local nL, nPos := 0

   nMaxLen := nCount := 0
   cStr += ';'
   DO WHILE (nL := Len(__StrTkPtr(@cStr, @nPos, ";"))) != 0
      nMaxLen := Max( nMaxLen, nL )
      nCount ++
   ENDDO
RETURN nil

STATIC FUNCTION FltSkip(oBrw, nLines, lDesc)
LOCAL n
  IF nLines == NIL
    nLines := 1
  ENDIF
  IF lDesc == NIL
     lDesc := .F.
  ENDIF
  IF nLines > 0
    FOR n := 1 TO nLines
      SKIP IF(lDesc, -1, +1)
      WHILE ! EOF() .AND. EVAL(oBrw:bWhile) .AND. ! EVAL(oBrw:bFor)
        SKIP IF(lDesc, -1, +1)
      ENDDO
    NEXT
  ELSEIF nLines < 0

    FOR n := 1 TO (nLines*(-1))
      IF EOF()
         IF lDesc
            FltGoTop(oBrw)
         ELSE
            FltGoBottom(oBrw)
         ENDIF
      ELSE
         SKIP IF(lDesc, +1, -1)
      ENDIF
      WHILE ! BOF() .AND. EVAL(oBrw:bWhile) .AND. ! EVAL(oBrw:bFor)
        SKIP IF(lDesc, +1, -1)
      ENDDO
     NEXT

  ENDIF

RETURN NIL


STATIC FUNCTION FltGoTop(oBrw)
  IF oBrw:nFirstRecordFilter == 0
    EVAL(oBrw:bFirst)
    IF ! EOF()
      WHILE ! EOF() .AND. ! (EVAL(oBrw:bWhile) .AND. EVAL(oBrw:bFor))
        DBSKIP()
      ENDDO
      oBrw:nFirstRecordFilter := FltRecNo(oBrw)
    ELSE
      oBrw:nFirstRecordFilter := 0
    ENDIF
  ELSE
    FltGoTo(oBrw, oBrw:nFirstRecordFilter)
  ENDIF
RETURN NIL

STATIC FUNCTION FltGoBottom(oBrw)
  IF oBrw:nLastRecordFilter == 0
    EVAL(oBrw:bLast)
    IF ! EVAL(oBrw:bWhile) .OR. ! EVAL(oBrw:bFor)
      WHILE ! BOF() .AND. ! EVAL(oBrw:bWhile)
        DBSKIP(-1)
      ENDDO
      WHILE ! BOF() .AND. EVAL(oBrw:bWhile) .AND. ! EVAL(oBrw:bFor)
        DBSKIP(-1)
      ENDDO
    ENDIF
    oBrw:nLastRecordFilter := FltRecNo(oBrw)
  ELSE
    FltGoTo(oBrw, oBrw:nLastRecordFilter)
  ENDIF
RETURN NIL

STATIC FUNCTION FltBOF(oBrw)
  LOCAL lRet := .F., cKey := "", nRecord := 0
  LOCAL xValue, xFirstValue
  IF BOF()
    lRet := .T.
  ELSE
    cKey  := INDEXKEY()
    nRecord := FltRecNo(oBrw)

    xValue := OrdKeyNo() //&(cKey)

    FltGoTop(oBrw)
    xFirstValue := OrdKeyNo()//&(cKey)

    IF xValue < xFirstValue
      lRet := .T.
      FltGoTop(oBrw)
    ELSE
      FltGoTo(oBrw, nRecord)
    ENDIF
  ENDIF
RETURN lRet

STATIC FUNCTION FltEOF(oBrw)
  LOCAL lRet := .F., cKey := "", nRecord := 0
  LOCAL xValue, xLastValue
  IF EOF()
    lRet := .T.
  ELSE
    cKey := INDEXKEY()
    nRecord := FltRecNo(oBrw)

    xValue := OrdKeyNo()

    FltGoBottom(oBrw)
    xLastValue := OrdKeyNo()

    IF xValue > xLastValue
      lRet := .T.
      FltGoBottom(oBrw)
      DBSKIP()
    ELSE
      FltGoTo(oBrw, nRecord)
    ENDIF
  ENDIF
RETURN lRet

STATIC FUNCTION FltRecCount(oBrw)
  LOCAL nRecord := 0, nCount := 0
  nRecord := FltRecNo(oBrw)
  FltGoTop(oBrw)
  WHILE ! EOF() .AND. EVAL(oBrw:bWhile)
    IF EVAL(oBrw:bFor)
      nCount++
    ENDIF
    DBSKIP()
  ENDDO
  FltGoTo(oBrw, nRecord)
RETURN nCount

STATIC FUNCTION FltGoTo(oBrw, nRecord)
RETURN DBGOTO(nRecord)

STATIC FUNCTION FltRecNo(oBrw)
RETURN RECNO()
//End Implementation by Luiz

static function LenVal( xVal, cType, cPict )
   LOCAL nLen

   if !ISCHARACTER( cType )
      cType := Valtype( xVal )
   endif

   Switch cType
      case "L"
         nLen := 1
         exit

      case "N"
      case "C"
      case "D"
         If !Empty( cPict )
            nLen := Len( Transform( xVal, cPict ) )
            exit
         Endif

         Switch cType
            case "N"
               nLen := Len( Str( xVal ) )
               exit

            case "C"
               nLen := Len( xVal )
               exit

            case "D"
               nLen := Len( DToC( xVal ) )
               exit
         end
         exit

#ifdef __XHARBOUR__
      default
#else
      otherwise
#endif
         nLen := 0

   end

Return nLen



