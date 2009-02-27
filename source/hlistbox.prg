/*
 * $Id: hlistbox.prg,v 1.21 2009-02-27 12:25:17 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HListBox class
 *
 * Copyright 2004 Vic McClung
 *
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

CLASS HListBox INHERIT HControl

CLASS VAR winclass   INIT "LISTBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  value         INIT 1
   DATA  bChangeSel
   DATA  bkeydown, bDblclick
   DATA  bValid
   
   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
              aItems,oFont,bInit,bSize,bPaint,bChange,cTooltip,tColor,bcolor,bGFocus,bLFocus, bKeydown, bDblclick,bOther )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bDraw, bChange, cTooltip, bKeydown, bOther )
   METHOD Init( aListbox, nCurrent )
   METHOD Refresh()
   METHOD Requery() 
   METHOD Setitem( nPos )
   METHOD AddItems( p )
   METHOD DeleteItem( nPos )
   METHOD onDblClick() 
   METHOD Clear()
   METHOD onEvent( msg, wParam, lParam ) 
   
ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
            bInit, bSize, bPaint, bChange, cTooltip, tColor, bcolor, bGFocus, bLFocus,bKeydown, bDblclick,bOther )  CLASS HListBox

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + WS_VSCROLL + LBS_DISABLENOSCROLL + LBS_NOTIFY + LBS_NOINTEGRALHEIGHT + WS_BORDER )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, cTooltip, tColor, bcolor )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ::bSetGet := bSetGet

   IF aItems == Nil
      ::aItems := { }
   ELSE
      ::aItems  := aItems
   ENDIF

   ::Activate()

   ::bChangeSel := bChange
   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus
    ::bKeydown := bKeydown
    ::bDblclick := bDblclick 
		::bOther := bOther 

   IF bSetGet != Nil
      IF bGFocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( LBN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ENDIF
      ::oParent:AddEvent( LBN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) }, .F., "onLostFocus" )
      ::bValid := { | o | __Valid( o ) }
   ELSE
      IF bGFocus != Nil
         ::oParent:AddEvent( LBN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ENDIF
      ::oParent:AddEvent( LBN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) }, .F., "onLostFocus" )
   ENDIF
   IF bChange != Nil .OR. bSetGet != Nil
      ::oParent:AddEvent( LBN_SELCHANGE, Self, { | o, id | __onChange( o:FindControl( id ) ) },, "onChange" )
   ENDIF
   IF bDblclick != Nil 
      ::oParent:AddEvent( LBN_DBLCLK, self,{|| ::onDblClick()})
   ENDIF

   RETURN Self

METHOD Activate CLASS HListBox
   IF ! Empty( ::oParent:handle )
      ::handle := CreateListbox( ::oParent:handle, ::id, ;
                                 ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Redefine( oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, ;
                 bChange, cTooltip, bKeydown, bOther )  CLASS HListBox

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ::bSetGet := bSetGet
   ::bKeydown := bKeydown
	 ::bOther := bOther 

   IF aItems == Nil
      ::aItems := { }
   ELSE
      ::aItems  := aItems
   ENDIF

   IF bSetGet != Nil
      ::bChangeSel := bChange
      ::oParent:AddEvent( LBN_SELCHANGE, Self, { | o, id | __Valid( o:FindControl( id ) ) }, "onChange" )
   ENDIF
   RETURN Self

METHOD Init() CLASS HListBox
   LOCAL i

   IF ! ::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITLISTPROC( ::handle )
      Super:Init()
      IF ::aItems != Nil
         IF ::value == Nil
            ::value := 1
         ENDIF
         SendMessage( ::handle, LB_RESETCONTENT, 0, 0 )
         FOR i := 1 TO Len( ::aItems )
            ListboxAddString( ::handle, ::aItems[ i ] )
         NEXT
         ListboxSetString( ::handle, ::value )
      ENDIF
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HListBox
 Local nEval, pos

   IF ::bOther != Nil
      IF (nEval := Eval( ::bOther,Self,msg,wParam,lParam )) != -1 .AND. nEval != Nil
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_KEYDOWN 
      IF ProcKeyList( Self, wParam )  
         RETURN - 1
      ENDIF   
      IF wParam = VK_TAB //.AND. nType < WND_DLG_RESOURCE   
         GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
        //RETURN 0
      ENDIF
			IF ::bKeyDown != Nil .and. ValType( ::bKeyDown ) == 'B'
         ::oparent:lSuspendMsgsHandling := .T.              
         nEval := Eval( ::bKeyDown, Self, wParam )
         IF (VALTYPE( nEval ) == "L" .AND. ! nEval ) .OR. ( nEval != -1 .AND. nEval != Nil )
            ::oparent:lSuspendMsgsHandling := .F.
            RETURN 0
         ENDIF
         ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF  msg = WM_GETDLGCODE .AND. ( wParam = VK_RETURN .OR.wParam = VK_ESCAPE ) .AND. ::bKeyDown != Nil
      RETURN DLGC_WANTALLKEYS  //DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS           
   ENDIF
   RETURN -1

METHOD Requery() CLASS HListBox
   Local i
   
   SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
   FOR i := 1 TO Len( ::aItems )
      ListboxAddString( ::handle, ::aItems[i] )
   NEXT
   ListboxSetString( ::handle, ::value )
   ::refresh()
   Return Nil


METHOD Refresh() CLASS HListBox
   LOCAL vari
   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet )
   ENDIF

   ::value := IIf( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ::SetItem( ::value )
   RETURN Nil

METHOD SetItem( nPos ) CLASS HListBox
   ::value := nPos
   SendMessage( ::handle, LB_SETCURSEL, nPos - 1, 0 )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, ::value, Self )
   ENDIF
   RETURN Nil

METHOD onDblClick()  CLASS HListBox
  IF ::bDblClick != Nil
	    ::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bDblClick, self, ::value )
  	  ::oParent:lSuspendMsgsHandling := .F.
   ENDIF   
   RETURN Nil

METHOD AddItems( p )
// Local i
   AAdd( ::aItems, p )
   ListboxAddString( ::handle, p )
//   SendMessage( ::handle, LB_RESETCONTENT, 0, 0)
//   FOR i := 1 TO Len( ::aItems )
//      ListboxAddString( ::handle, ::aItems[i] )
//   NEXT
   ListboxSetString( ::handle, ::value )
   RETURN Self

METHOD DeleteItem( nPos )

   IF SendMessage( ::handle, LB_DELETESTRING , nPos - 1, 0 ) > 0 //<= LEN(ocombo:aitems)
      ADel( ::Aitems, nPos )
      ASize( ::Aitems, Len( ::aitems ) - 1 )
      RETURN .T.
   ENDIF
   RETURN .F.

METHOD Clear()
   ::aItems := { }
   ::value := 1
   SendMessage( ::handle, LB_RESETCONTENT, 0, 0 )
   ListboxSetString( ::handle, ::value )
   RETURN .T.


STATIC FUNCTION __onChange( oCtrl )
   LOCAL nPos

   nPos := SendMessage( oCtrl:handle, LB_GETCURSEL, 0, 0 ) + 1
   oCtrl:SetItem( nPos )

   RETURN Nil


STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., nSkip

   IF ! CheckFocus( oCtrl, .f. )
      RETURN .t.
   ENDIF
   oCtrl:SetFocus()
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bGetFocus != Nil
      oCtrl:lnoValid := .T.
      oCtrl:oparent:lSuspendMsgsHandling := .t.
      res := Eval( oCtrl:bGetFocus, oCtrl:Value, oCtrl )
      oCtrl:oparent:lSuspendMsgsHandling := .f.
      oCtrl:lnoValid := ! res
      IF ! res
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
   RETURN res


STATIC FUNCTION __Valid( oCtrl )
   LOCAL res := .t., oDlg, nSkip
   LOCAL ltab :=  GETKEYSTATE( VK_TAB ) < 0

   IF ! CheckFocus( oCtrl, .t. ) .or. oCtrl:lNoValid
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_SHIFT ) < 0 , - 1, 1 )
   IF ( oDlg := ParentGetDialog( oCtrl ) ) == Nil .OR. oDlg:nLastKey != 27
      oCtrl:value := SendMessage( oCtrl:handle, LB_GETCURSEL, 0, 0 ) + 1
      IF oCtrl:bSetGet != Nil
         Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 27
      ENDIF
      IF oCtrl:bLostFocus != Nil
         oCtrl:oparent:lSuspendMsgsHandling := .t.
         res := Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl )
         oCtrl:oparent:lSuspendMsgsHandling := .f.
         IF ! res
            oCtrl:SetFocus() //( oCtrl:handle )
            IF oDlg != Nil
               oDlg:nLastKey := 0
            ENDIF
            RETURN .F.
         ENDIF
      ENDIF
      IF oDlg != Nil
         oDlg:nLastKey := 0
      ENDIF
   ENDIF
   IF lTab .AND. GETFOCUS() = oCtrl:handle
      IF oCtrl:oParent:CLASSNAME = "HTAB"
         oCtrl:oParent:SETFOCUS()
      ENDIF
      GetSkip( oCtrl:oparent, oCtrl:handle,, nSkip )
   ENDIF
   RETURN .T.
