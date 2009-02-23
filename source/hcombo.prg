/*
 * $Id: hcombo.prg,v 1.59 2009-02-23 12:52:12 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCombo class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckComboEx class
 *
 * Copyright 2007 Luiz Rafale Culik Guimaraes (Luiz at xharbour.com.br)
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#pragma begindump
#include "windows.h"
#include "hbapi.h"
HB_FUNC(COPYDATA)
     {
   LPARAM lParam = ( LPARAM ) hb_parnl( 1 ) ;
                     char * m_strText = hb_parc( 2 ) ;
                     WPARAM wParam = ( WPARAM ) hb_parnl( 3 ) ;

   lstrcpyn( ( LPSTR ) lParam, m_strText, ( INT ) wParam ) ;
}
#pragma enddump

CLASS HComboBox INHERIT HControl

CLASS VAR winclass   INIT "COMBOBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value    INIT 1

   DATA  bChangeSel
   DATA  bChangeInt
   DATA  bValid
																				      
   DATA  lText    INIT .F.
   DATA  lEdit    INIT .F.
   DATA  SelLeght INIT 0
   DATA  SelStart INIT 0
   DATA  SelText  INIT  ""
   DATA  nDisplay
	 DATA  nhItem
	 DATA  ncWidth
	 DATA  nHeightBox
   DATA  lResource INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  aItems,oFont,bInit,bSize,bPaint,bChange,ctooltip,lEdit,lText,bGFocus,tcolor,;
									bcolor,bLFocus, bIChange, nDisplay, nhItem, ncWidth )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bDraw, bChange, ctooltip, bGFocus, bLFocus, bIChange, nDisplay )
   METHOD Init( aCombo, nCurrent )
   METHOD onEvent( msg, wParam, lParam )
   METHOD Requery()
   METHOD Refresh()
   METHOD Setitem( nPos )
   METHOD SetValue( xItem )
   METHOD GetValue()
   METHOD AddItem( cItem )
   METHOD DeleteItem( nPos )
ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,aItems,oFont, ;
        bInit,bSize,bPaint,bChange,ctooltip,lEdit,lText,bGFocus,tcolor,bcolor,bLFocus ,;
				bIChange, nDisplay, nhItem, ncWidth) CLASS HComboBox

   IF lEdit == Nil ; lEdit := .f. ; ENDIF
   IF lText == Nil ; lText := .f. ; ENDIF
   //if bValid != NIL; ::bValid := bValid; endif
   
   ::nHeightBox := INT( nHeight * 0.75 ) //	Meets A 22'S EDITBOX
   IF !EMPTY( nDisplay ) .AND. nDisplay  > 0
      nStyle := Hwg_BitOr( nStyle, CBS_NOINTEGRALHEIGHT ) //+ WS_VSCROLL )
      // CBS_NOINTEGRALHEIGHT. CRIATE VERTICAL SCROOL BAR
   ELSE
	    nDisplay := 6
	 ENDIF   
   nHeight := nHeight + ( IIF( EMPTY( nhItem ), 16.250, ( nhItem += 0.250 ) ) *  nDisplay ) 
   
   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), IIf( lEdit, CBS_DROPDOWN, CBS_DROPDOWNLIST ) + WS_TABSTOP )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor )

   ::nDisplay := nDisplay
	 ::nhItem    := nhItem
	 ::ncWidth   := ncWidth

   ::lEdit := lEdit
   ::lText := lText

   IF lEdit
      ::lText := .t.
   ENDIF

   IF ::lText
      ::value := IIf( vari == Nil .OR. ValType( vari ) != "C", "", vari )
   ELSE
      ::value := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ENDIF

   ::bSetGet := bSetGet
   ::aItems  := aItems
   ::Activate()

   ::bChangeSel := bChange
   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus

   IF bSetGet != Nil
      IF bGFocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( CBN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ENDIF
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 03/06/2006
      ::oParent:AddEvent( CBN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) }, .F., "onLostFocus" )
      //---------------------------------------------------------------------------
   ELSE
      IF bGFocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( CBN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotGocus" )
      ENDIF
      ::oParent:AddEvent( CBN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onLostFocus" )
   ENDIF
   IF bChange != Nil .OR. bSetGet != Nil
      ::oParent:AddEvent( CBN_SELCHANGE, Self, { | o, id | __onChange( o:FindControl( id ) ) },, "onChange" )
   ENDIF

   IF bIChange != Nil .AND. ::lEdit
      ::bchangeInt := bIChange
      ::oParent:AddEvent( CBN_EDITUPDATE , Self, { | o, id | __InteractiveChange( o:FindControl( id ) ) },, "interactiveChange" )
   ENDIF


   RETURN Self

METHOD Activate CLASS HComboBox
   IF ! Empty( ::oParent:handle )
      ::handle := CreateCombo( ::oParent:handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
               bChange, ctooltip, bGFocus, bLFocus, bIChange, nDisplay ) CLASS HComboBox

   //::nHeightBox := INT( 22 * 0.75 ) //	Meets A 22'S EDITBOX
   IF !EMPTY( nDisplay ) .AND. nDisplay  > 0
      ::Style := Hwg_BitOr( ::Style, CBS_NOINTEGRALHEIGHT ) //+ WS_VSCROLL )
      // CBS_NOINTEGRALHEIGHT. CRIATE VERTICAL SCROOL BAR
   ELSE
	    nDisplay := 6
	 ENDIF   
   //::nHeight := ( ::nHeight + 16.250 ) *  nDisplay  
   ::lResource := .T.
   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip )
      
   ::nDisplay := nDisplay

   IF ::lText
      ::value := IIf( vari == Nil .OR. ValType( vari ) != "C", "", vari )
   ELSE
      ::value := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ENDIF
   ::bSetGet := bSetGet
   ::aItems  := aItems

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::bGetFocus := bGFocus
      ::oParent:AddEvent( CBN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      IF ::bSetGet <> nil
         ::oParent:AddEvent( CBN_SELCHANGE, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onChange" )
      ELSEIF ::bChangeSel != NIL
         ::oParent:AddEvent( CBN_SELCHANGE, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onChange" )
      ENDIF
   ELSEIF bChange != Nil
      ::oParent:AddEvent( CBN_SELCHANGE, Self, bChange,, "onChange" )
   ENDIF

   IF bGFocus != Nil .AND. bSetGet == Nil
      ::oParent:AddEvent( CBN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
   ENDIF

   //::Refresh() // By Luiz Henrique dos Santos
   ::Requery() 
   RETURN Self

METHOD Init() CLASS HComboBox
   LOCAL i, numofchars
   LOCAL LongComboWidth := 0
   LOCAL NewLongComboWidth , avgwidth

   IF ! ::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITCOMBOPROC( ::handle )
      Super:Init()
      IF ::aItems != Nil .AND. !EMPTY( ::aItems )
         IF ::value == Nil
            IF ::lText
               ::value := ::aItems[ 1 ]
            ELSE
               ::value := 1
            ENDIF
         ENDIF
         SendMessage( ::handle, CB_RESETCONTENT, 0, 0 )
         FOR i := 1 TO Len( ::aItems )
            ComboAddString( ::handle, ::aItems[ i ] )
            numofchars = SendMessage( ::handle, CB_GETLBTEXTLEN, i - 1, 0 )
            IF  numofchars > LongComboWidth
               LongComboWidth = numofchars
            ENDIF
         NEXT
         IF ::lText
            IF ::lEdit
               SetDlgItemText( getmodalhandle(), ::id, ::value )
            ELSE
               ComboSetString( ::handle, AScan( ::aItems, ::value ) )
            ENDIF
            SendMessage( ::handle, CB_SELECTSTRING, 0, ::value )
            SetWindowText( ::handle, ::value )
         ELSE
            ComboSetString( ::handle, ::value )
         ENDIF
         avgwidth = GetFontDialogUnits( ::oParent:handle ) //,::oParent:oFont:handle)
         NewLongComboWidth = ( LongComboWidth - 2 ) * avgwidth
         SendMessage( ::handle, CB_SETDROPPEDWIDTH, NewLongComboWidth + 50, 0 )
      ENDIF
      IF ! ::lResource
         // HEIGHT Items
         IF !EMPTY( ::nhItem )
            sendmessage( ::handle, CB_SETITEMHEIGHT ,0, ::nhItem ) 
         ELSE
  			    ::nhItem := sendmessage( ::handle, CB_GETITEMHEIGHT , 0, 0 ) + 0.250
         ENDIF
			   //  WIDTH  Items
			   IF !EMPTY( ::ncWidth ) 
			      sendmessage( ::handle, CB_SETDROPPEDWIDTH, ::ncWidth, 0)
			   ENDIF   
		     ::nHeight := INT( ::nHeightBox / 0.75 + ( ::nhItem * ::nDisplay ) ) 
		  ENDIF
   ENDIF
   IF ! ::lResource
      MoveWindow( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )      
      // HEIGHT COMBOBOX
      SendMessage( ::handle, CB_SETITEMHEIGHT , -1, ::nHeightBox )  
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HComboBox

   IF msg == WM_CHAR .AND. ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE .OR. ;
       ! ::GetParentForm( Self ):lModal )
      IF wParam = VK_TAB
        GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
        RETURN 0
      ELSEIF wParam == VK_RETURN 
         GetSkip( ::oParent, ::handle, , 1 )
         RETURN 0
		  ENDIF
	 ELSEIF msg = WM_KEYDOWN
		  ProcKeyList( Self, wParam )  
	 ELSEIF MSG = 343	//.OR.MSG= 359 .or.GETKEYSTATE( VK_TAB ) < 0 //CB_GETDROPPEDSTATE  
	    IF GETKEYSTATE( VK_RETURN ) + GETKEYSTATE( VK_DOWN ) + GETKEYSTATE( VK_TAB ) < 0
	       IF ::oParent:oParent = Nil
	          GetSkip( ::oParent, GetAncestor( ::handle, GA_PARENT), , 1 )
	       ENDIF
	       GetSkip( ::oParent, ::handle, , 1 )
	    ENDIF
	    IF GETKEYSTATE( VK_UP ) < 0
	      IF ::oParent:oParent = Nil
	         GetSkip( ::oParent, GetAncestor( ::handle, GA_PARENT), , 1 )
	      ENDIF
	      GetSkip( ::oParent, ::handle, , -1 )
	    ENDIF
	    RETURN -1 //1
	 ENDIF
	 
   RETURN -1

METHOD Requery() CLASS HComboBox
   Local i

   SendMessage( ::handle, CB_RESETCONTENT, 0, 0)

   FOR i := 1 TO Len( ::aItems )
      ComboAddString( ::handle, ::aItems[i] )
   NEXT
	 ::Refresh()

   Return Nil



METHOD Refresh() CLASS HComboBox
   LOCAL vari, i
   
   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet,, Self )
      IF ::lText
         ::value := IIf( vari == Nil .OR. ValType( vari ) != "C", "", vari )
         SendMessage( ::handle, CB_SETEDITSEL, 0, Len( ::value ) )
      ELSE
         ::value := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
      ENDIF
   ENDIF
	 /*
   SendMessage( ::handle, CB_RESETCONTENT, 0, 0 )

   FOR i := 1 TO Len( ::aItems )
      ComboAddString( ::handle, ::aItems[ i ] )
   NEXT
	 */
   IF ::lText
      IF ::lEdit
         SetDlgItemText( getmodalhandle(), ::id, ::value )
      ELSE
         ComboSetString( ::handle, AScan( ::aItems, ::value ) )
      ENDIF
   ELSE
      ComboSetString( ::handle, ::value )
      ::SetItem( ::value )
   ENDIF

  RETURN Nil

METHOD SetItem( nPos ) CLASS HComboBox
	 /*
	 IF VALTYPE( nPos ) = "C" .AND. ::lText
	    nPos := AScan( ::aItems, nPos )
      ComboSetString( ::handle, nPos  )
   ENDIF
   */
   IF ::lText
      IF nPos > 0
         ::value := ::aItems[ nPos ]
      ELSE
         ::value := ""
      ENDIF
   ELSE
      ::value := nPos
   ENDIF

   SendMessage( ::handle, CB_SETCURSEL, nPos - 1, 0 )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF
	 /*
   IF ::bChangeSel != Nil
      ::oparent:lSuspendMsgsHandling := .t.
      Eval( ::bChangeSel, nPos, Self )
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF
   */
   RETURN Nil
   
METHOD SetValue( xItem ) CLASS HComboBox
   LOCAL nPos

	 IF ::lText .AND. VALTYPE( xItem ) = "C" 
	    nPos := AScan( ::aItems, xItem )
      ComboSetString( ::handle, nPos  )
   ENDIF
   ::setItem( nPos ) 
   RETURN Nil
   
METHOD GetValue() CLASS HComboBox
   LOCAL nPos := SendMessage( ::handle, CB_GETCURSEL, 0, 0 ) + 1

   ::value := IIf( ::lText, ::aItems[ nPos ], nPos )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF

   RETURN ::value

METHOD DeleteItem( nIndex ) CLASS HComboBox

   IF SendMessage( ::handle, CB_DELETESTRING , nIndex - 1, 0 ) > 0 //<= LEN(ocombo:aitems)
      ADel( ::Aitems, nIndex )
      ASize( ::Aitems, Len( ::aitems ) - 1 )
      RETURN .T.
   ENDIF
   RETURN .F.

METHOD AddItem( cItem ) CLASS HComboBox
   LOCAL nCount

   AAdd( ::Aitems, cItem )
   nCount := SendMessage( ::handle, CB_GETCOUNT, 0, 0 ) + 1
   ComboAddString( ::handle, cItem )  //::aItems[i] )
   RETURN nCount


STATIC FUNCTION __InteractiveChange( oCtrl )
   LOCAL npos := SendMessage( oCtrl:handle, CB_GETEDITSEL, 0, 0 )

   octrl:SelStart := nPos
   oCtrl:oparent:lSuspendMsgsHandling := .t.
   Eval( oCtrl:bChangeInt, oCtrl:value, oCtrl )
   oCtrl:oparent:lSuspendMsgsHandling := .f.

   SendMessage( oCtrl:handle, CB_SETEDITSEL, 0, octrl:SelStart )
   RETURN Nil


STATIC FUNCTION __onChange( oCtrl )
   LOCAL nPos := SendMessage( oCtrl:handle, CB_GETCURSEL, 0, 0 ) + 1
   
   oCtrl:SetItem( nPos )
   IF oCtrl:bChangeSel != Nil
      oCtrl:oparent:lSuspendMsgsHandling := .t.
      Eval( oCtrl:bChangeSel, nPos, oCtrl )
      oCtrl:oparent:lSuspendMsgsHandling := .f.
   ENDIF
   RETURN Nil


STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., oParent, nSkip

   IF ! CheckFocus( oCtrl, .f. )
      RETURN .t.
   ENDIF

   IF ! oCtrl:lText
      //oCtrl:Refresh()
   ELSE
     * SetWindowText(oCtrl:handle, oCtrl:value)
     * SendMessage( oCtrl:handle, CB_SELECTSTRING, 0, oCtrl:value)
   ENDIF
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   IF oCtrl:bGetFocus != Nil
      oCtrl:oParent:lSuspendMsgsHandling := .t.
      oCtrl:lnoValid := .T.
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet, , oCtrl ), oCtrl )
      oCtrl:oParent:lSuspendMsgsHandling := .f.
      oCtrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog( oCtrl )
         IF oCtrl == ATail( oParent:GetList )
            nSkip := - 1
         ELSEIF oCtrl == oParent:getList[ 1 ]
            nSkip := 1
         ENDIF
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
   RETURN res

STATIC FUNCTION __Valid( oCtrl )
   LOCAL oDlg, nPos, nSkip, res, hCtrl := getfocus()
   LOCAL ltab :=  GETKEYSTATE( VK_TAB ) < 0

   IF ! CheckFocus( oCtrl, .t. ) .or. oCtrl:lNoValid
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_SHIFT ) < 0 , - 1, 1 )

   IF ( oDlg := ParentGetDialog( oCtrl ) ) == Nil .OR. oDlg:nLastKey != VK_ESCAPE
      // end by sauli
   *IF lESC // "if" by Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      nPos := SendMessage( oCtrl:handle, CB_GETCURSEL, 0, 0 ) + 1
      IF oCtrl:lText
         oCtrl:value := IIf( nPos > 0, oCtrl:aItems[ nPos ], GetWindowText( oCtrl:handle ) )
      ELSE
         oCtrl:value := nPos
      ENDIF
      IF oCtrl:bSetGet != Nil
         Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
      ENDIF
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com.br) 03/06/2006
      IF oCtrl:bLostFocus != Nil
         oCtrl:oparent:lSuspendMsgsHandling := .T.
         res := Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl )
         IF ! res
            SetFocus( oCtrl:handle )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
     		    octrl:oparent:lSuspendMsgsHandling := .F.                             
            RETURN .F.
         ENDIF
         
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 0
      ENDIF
      IF ltab .AND. GETFOCUS() = hCtrl
         IF oCtrl:oParent:CLASSNAME = "HTAB"
            oCtrl:oParent:SETFOCUS()
            getskip( oCtrl:oparent, oCtrl:handle,, nSkip )
         ENDIF
      ENDIF
	    octrl:oparent:lSuspendMsgsHandling := .F.
       IF GETFOCUS() = 0 //::nValidSetfocus = ::handle
          GetSkip( OCTRL:oParent, octrl:handle,,octrl:nGetSkip)
       ENDIF 
   ENDIF
   RETURN .T.


//***************************************************



CLASS HCheckComboBox INHERIT HComboBox

CLASS VAR winclass INIT "COMBOBOX"
   DATA m_bTextUpdated INIT .f.

   DATA m_bItemHeightSet INIT .f.
   DATA m_hListBox INIT 0
   DATA aCheck
   DATA nWidthCheck  INIT 0
   DATA m_strText INIT ""
   METHOD onGetText( w, l )
   METHOD OnGetTextLength( w, l )

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
              aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus,;
							 tcolor, bcolor, bValid, acheck, nDisplay, nhItem, ncWidth ) 
   METHOD Redefine( oWnd, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bDraw, bChange, ctooltip, bGFocus )
   METHOD INIT( aCombo, nCurrent )
   METHOD Requery()
   METHOD Refresh()
   METHOD Paint( lpDis )
   METHOD SetCheck( nIndex, bFlag )
   METHOD RecalcText()

   METHOD GetCheck( nIndex )

   METHOD SelectAll( bCheck )
   METHOD MeasureItem( l )

   METHOD onEvent( msg, wParam, lParam )
   METHOD GetAllCheck()
ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
              bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor,;
						  bValid, acheck, nDisplay, nhItem, ncWidth ) CLASS hCheckComboBox

   ::acheck := IIF( acheck == Nil, {}, acheck )
   IF ValType( nStyle ) == "N"
      nStyle := hwg_multibitor( nStyle, CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS )
   ELSE
      nStyle := hwg_multibitor( CBS_DROPDOWNLIST, CBS_OWNERDRAWVARIABLE, CBS_HASSTRINGS )
   ENDIF

   bPaint := { | o, p | o:paint( p ) }

   ::Super:New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
                bInit, bSize, bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bValid ,, nDisplay, nhItem, ncWidth )

   RETURN Self

METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                 bChange, ctooltip, bGFocus, acheck ) CLASS hCheckComboBox

   ::Super:Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                     bChange, ctooltip, bGFocus )

   ::acheck := acheck

   RETURN Self

METHOD onEvent( msg, wParam, lParam ) CLASS hCheckComboBox

   LOCAL nIndex
   LOCAL rcItem
   LOCAL rcClient
   LOCAL pt
   LOCAL nItemHeight
   LOCAL nTopIndex

   IF msg == WM_RBUTTONDOWN
   ELSEIF msg == LB_GETCURSEL
      RETURN - 1
   ELSEIF msg == LB_GETCURSEL
      RETURN - 1

   ELSEIF msg == WM_MEASUREITEM
      ::MeasureItem( lParam )
      RETURN 0
   ELSEIF msg == WM_GETTEXT
      RETURN ::OnGetText( wParam, lParam )

   ELSEIF msg == WM_GETTEXTLENGTH

      RETURN ::OnGetTextLength( wParam, lParam )

   ELSEIF msg == WM_CHAR
      IF ( wParam == VK_SPACE )

         nIndex := SendMessage( ::handle, CB_GETCURSEL, wParam, lParam ) + 1
         rcItem := COMBOGETITEMRECT( ::handle, nIndex - 1 )
         InvalidateRect( ::handle, .f., rcItem[ 1 ], rcItem[ 2 ], rcItem[ 3 ], rcItem[ 4 ] )
         ::SetCheck( nIndex, ! ::GetCheck( nIndex ) )
         SendMessage( ::oParent:handle, WM_COMMAND, MAKELONG( ::id, CBN_SELCHANGE ), ::handle )
      ENDIF
      IF ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE.OR.! ::GetParentForm( Self ):lModal )
         IF wParam = VK_TAB
            GetSkip( ::oParent, ::handle, , iif( IsCtrlShift( .F., .T. ), -1, 1 ) )
            RETURN 0
         ELSEIF wParam == VK_RETURN 
            GetSkip( ::oParent, ::handle, , 1 )
            RETURN 0
		     ENDIF
      ENDIF
      RETURN 0
	 ELSEIF msg = WM_KEYDOWN
		  ProcKeyList( Self, wParam )  

   ELSEIF msg == WM_LBUTTONDOWN

      rcClient := GetClientRect( ::handle )

      pt := {, }
      pt[ 1 ] = LOWORD( lParam )
      pt[ 2 ] = HIWORD( lParam )

      IF ( PtInRect( rcClient, pt ) )

         nItemHeight := SendMessage( ::handle, LB_GETITEMHEIGHT, 0, 0 )
         nTopIndex   := SendMessage( ::handle, LB_GETTOPINDEX, 0, 0 )

         // Compute which index to check/uncheck
         nIndex := ( nTopIndex + pt[ 2 ] / nItemHeight ) + 1
         rcItem := COMBOGETITEMRECT( ::handle, nIndex - 1 )

         //IF ( PtInRect( rcItem, pt ) )
         IF pt[ 1 ] < ::nWidthCheck
            // Invalidate this window
            InvalidateRect( ::handle, .f., rcItem[ 1 ], rcItem[ 2 ], rcItem[ 3 ], rcItem[ 4 ] )
            nIndex := SendMessage( ::handle, CB_GETCURSEL, wParam, lParam ) + 1
            ::SetCheck( nIndex, !::GetCheck( nIndex ) )

            // Notify that selection has changed

            SendMessage( ::oParent:handle, WM_COMMAND, MAKELONG( ::id, CBN_SELCHANGE ), ::handle )

         ENDIF
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      RETURN -1 //0
   ENDIF
   
   RETURN - 1

METHOD INIT() CLASS hCheckComboBox

   LOCAL i
   //::nHolder := 1
   //SetWindowObject( ::handle, Self )  // because hcombobox is handling
   //HWG_INITCOMBOPROC( ::handle )
   IF ! ::lInit
      Super:Init()
      IF Len( ::acheck ) > 0
         FOR i := 1 TO Len( ::acheck )
            ::Setcheck( ::acheck[ i ], .t. )
         NEXT
      ENDIF
   ENDIF
   RETURN Nil

METHOD Requery() CLASS hCheckComboBox
local i

   ::super:Requery()
   IF LEN( ::acheck ) > 0
      FOR i := 1 TO LEN( ::acheck )
         ::Setcheck( ::acheck[ i ], .t. )
      NEXT
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS hCheckComboBox
   LOCAL i
   ::Super:refresh()
   /*
   IF Len( ::acheck ) > 0
      FOR i := 1 TO Len( ::acheck )
         ::Setcheck( ::acheck[ i ], .t. )
      NEXT
   ENDIF
	 */
   RETURN Nil

METHOD SetCheck( nIndex, bFlag ) CLASS hCheckComboBox

   LOCAL nResult := COMBOBOXSETITEMDATA( ::handle, nIndex - 1, bFlag )

   IF ( nResult < 0 )
      RETURN nResult
   ENDIF

   ::m_bTextUpdated := FALSE

   // Redraw the window
   InvalidateRect( ::handle, 0 )

   RETURN nResult

METHOD GetCheck( nIndex ) CLASS hCheckComboBox

   LOCAL l := COMBOBOXGETITEMDATA( ::handle, nIndex - 1 )

   RETURN IF( l == 1, .t., .f. )

METHOD SelectAll( bCheck ) CLASS hCheckComboBox

   LOCAL nCount
   LOCAL i
   DEFAULT bCheck TO .t.

   nCount := SendMessage( ::handle, CB_GETCOUNT, 0, 0 )

   FOR i := 1 TO nCount
      ::SetCheck( i, bCheck )
   NEXT
   RETURN nil

METHOD RecalcText() CLASS hCheckComboBox

   LOCAL strtext
   LOCAL ncount
   LOCAL strSeparator
   LOCAL i
   LOCAL stritem
   IF ( ! ::m_bTextUpdated )

      // Get the list count
      ncount := SendMessage( ::handle, CB_GETCOUNT, 0, 0 )

      // Get the list separator

      strSeparator := GetLocaleInfo()

      // If none found, the the ''
      IF Len( strSeparator ) == 0
         strSeparator := ''
      ENDIF

      strSeparator := RTrim( strSeparator )

      strSeparator += ' '

      FOR i := 1 TO ncount

         IF ( COMBOBOXGETITEMDATA( ::handle, i ) ) = 1

            COMBOBOXGETLBTEXT( ::handle, i, @stritem )

            IF ! Empty( strtext )
               strtext += strSeparator
            ENDIF

            strtext += stritem
         ENDIF
      NEXT

      // Set the text
      ::m_strText := strtext

      ::m_bTextUpdated := TRUE
   ENDIF
   RETURN Self

METHOD Paint( lpDis ) CLASS hCheckComboBox

   LOCAL drawInfo := GetDrawItemInfo( lpDis )

   LOCAL dc := drawInfo[ 3 ]

   LOCAL rcBitmap := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   LOCAL rcText   := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   LOCAL strtext  := ""
   LOCAL ncheck
   LOCAL metrics
   LOCAL nstate

   IF ( drawInfo[ 1 ] < 0 )

      ::RecalcText()

      strtext := ::m_strText

      ncheck := 0

   ELSE
      COMBOBOXGETLBTEXT( ::handle, drawInfo[ 1 ], @strtext )

      ncheck := 1 + ( COMBOBOXGETITEMDATA( ::handle, drawInfo[ 1 ] ) )

      metrics := GETTEXTMETRIC( dc )

      rcBitmap[ 1 ] := 0
      rcBitmap[ 3 ] := rcBitmap[ 1 ] + metrics[ 1 ] + metrics[ 4 ] + 6
      rcBitmap[ 2 ] += 1
      rcBitmap[ 4 ] -= 1

      rcText[ 1 ] := rcBitmap[ 3 ]
      ::nWidthCheck := rcBitmap[ 3 ]
   ENDIF

   IF ( ncheck > 0 )
      SetBkColor( dc, GetSysColor( COLOR_WINDOW ) )
      SetTextColor( dc, GetSysColor( COLOR_WINDOWTEXT ) )

      nstate := DFCS_BUTTONCHECK

      IF ( ncheck > 1 )
         nstate := hwg_bitor( nstate, DFCS_CHECKED )
      ENDIF

      // Draw the checkmark using DrawFrameControl
      DrawFrameControl( dc, rcBitmap, DFC_BUTTON, nstate )
   ENDIF

   IF ( hwg_Bitand( drawInfo[ 9 ], ODS_SELECTED ) != 0 )
      SetBkColor( dc, GetSysColor( COLOR_HIGHLIGHT ) )
      SetTextColor( dc, GetSysColor( COLOR_HIGHLIGHTTEXT ) )

   ELSE
      SetBkColor( dc, GetSysColor( COLOR_WINDOW ) )
      SetTextColor( dc, GetSysColor( COLOR_WINDOWTEXT ) )
   ENDIF

   // Erase and draw
   IF Empty( strtext )
      strtext := ""
   ENDIF

   ExtTextOut( dc, 0, 0, rcText[ 1 ], rcText[ 2 ], rcText[ 3 ], rcText[ 4 ] )

   DrawText( dc, ' ' + strtext, rcText[ 1 ], rcText[ 2 ], rcText[ 3 ], rcText[ 4 ], DT_SINGLELINE + DT_VCENTER + DT_END_ELLIPSIS )

   IF ( ( hwg_Bitand( drawInfo[ 9 ], ODS_FOCUS + ODS_SELECTED ) ) == ( ODS_FOCUS + ODS_SELECTED ) )
      DrawFocusRect( dc, rcText )
   ENDIF

   RETURN Self

METHOD MeasureItem( l ) CLASS hCheckComboBox

   LOCAL dc                  := HCLIENTDC():new( ::handle )
   LOCAL lpMeasureItemStruct := GETMEASUREITEMINFO( l )
   LOCAL metrics
   LOCAL pFont

   //pFont := dc:SelectObject( IF( ValType( ::oFont ) == "O", ::oFont:handle, ::oParent:oFont:handle ) )
   pFont := dc:SelectObject( IIF( VALTYPE( ::oFont ) == "O", ::oFont:handle,;
	  IIF( VALTYPE( ::oParent:oFont ) == "O", ::oParent:oFont:handle,) ) )

   IF ! Empty( pFont  )

      metrics := dc:GetTextMetric()

      lpMeasureItemStruct[ 5 ] := metrics[ 1 ] + metrics[ 4 ]

      lpMeasureItemStruct[ 5 ] += 2

      IF ( ! ::m_bItemHeightSet )
         ::m_bItemHeightSet := .t.
         SendMessage( ::handle, CB_SETITEMHEIGHT, - 1, MAKELONG( lpMeasureItemStruct[ 5 ], 0 ) )
      ENDIF

      dc:SelectObject( pFont )
      dc:END()
   ENDIF
   RETURN Self

METHOD OnGetText( wParam, lParam ) CLASS hCheckComboBox
   ::RecalcText()

   IF ( lParam == 0 )
      RETURN 0
   ENDIF

   // Copy the 'fake' window text
   copydata( lParam, ::m_strText, wParam )

   RETURN IIF( EMPTY( ::m_strText ), 0, LEN( ::m_strText ) ) 

METHOD OnGetTextLength( WPARAM, LPARAM ) CLASS hCheckComboBox

   HB_SYMBOL_UNUSED( WPARAM )
   HB_SYMBOL_UNUSED( LPARAM )

   ::RecalcText()
   
   RETURN IIF( EMPTY( ::m_strText ), 0, LEN( ::m_strText ) ) 

METHOD GetAllCheck() CLASS hCheckComboBox
   LOCAL aCheck := { }
   LOCAL n
   FOR n := 1  TO Len( ::aItems )
      AAdd( aCheck , ::GetCheck( n ) )
   NEXT
   RETURN aCheck

FUNCTION hwg_multibitor( ... )
   LOCAL aArgumentList := HB_AParams()
   LOCAL nItem
   LOCAL result := 0

   FOR EACH nItem IN aArgumentList
      IF ValType( nItem ) != "N"
         msginfo( "hwg_multibitor parameter not numeric set to zero", "Possible error" )
         nItem := 0
      ENDIF
      result := hwg_bitor( result, nItem )
   NEXT

   RETURN result

