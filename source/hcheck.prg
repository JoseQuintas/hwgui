/*
 * $Id: hcheck.prg,v 1.33 2009-05-02 22:15:39 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckButton class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HCheckButton INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"
   DATA bSetGet
   DATA value
   DATA lEnter

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
               bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter )
   METHOD Init()
   METHOD onevent( msg, wParam, lParam )
   METHOD Refresh()
 //  METHOD Disable()
 //  METHOD Enable()
   METHOD SetValue( lValue )  INLINE SendMessage( ::handle, BM_SETCHECK, Iif( lValue, 1, 0 ), 0 ), ::value := lValue, ::Refresh()
   METHOD GetValue()          INLINE ( SendMessage( ::handle, BM_GETCHECK, 0, 0 ) == 1 )
   METHOD onGotFocus()
   METHOD onClick()
   METHOD KillFocus()
   
ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
            bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp ) CLASS HCheckButton

	 LOCAL hTheme
   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), BS_NOTIFY + BS_PUSHBUTTON + BS_AUTOCHECKBOX + WS_TABSTOP )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )

   ::title   := cCaption
   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "L", .F., vari )
   ::bSetGet := bSetGet
   
   IF (lTransp != NIL .AND. lTransp) 
      bcolor := ::oParent:bcolor             
      IF bcolor = Nil .AND. ::oParent:oParent != Nil .AND. ISTHEMEACTIVE()
         hTheme := hb_OpenThemeData( ::oParent:handle, "TAB" )
         IF !EMPTY( hTheme )
            bColor := HWG_GETTHEMESYSCOLOR( hTheme, COLOR_WINDOW  )
            HB_CLOSETHEMEDATA( hTheme ) 
         ENDIF 
      ENDIF
   ENDIF

   ::bcolor  := bcolor
   ::tcolor  := tcolor
   IF bcolor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF
   ::Activate()
   IF tcolor != Nil
      ::SetColor( tcolor )
   ENDIF

   ::lEnter     := IIf( lEnter == Nil .OR. ValType( lEnter ) != "L", .F., lEnter )
   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus

   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::lnoValid := .T.
   ENDIF

   ::oParent:AddEvent( BN_CLICKED, Self, { | o, id | __Valid( o:FindControl( id ), ) },, "onClick" )
   ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::KILLFOCUS() } )

   RETURN Self

METHOD Activate CLASS HCheckButton
   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter ) CLASS HCheckButton


   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )

   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "L", .F., vari )
   ::bSetGet := bSetGet
   ::lEnter     := IIf( lEnter == Nil .OR. ValType( vari ) != "L", .F., lEnter )
   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_CLICKED, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onClick" )
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
   ENDIF
   ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::KILLFOCUS() } )

   RETURN Self

METHOD Init() CLASS HCheckButton
   IF ! ::lInit
      SetWindowObject( ::handle, Self )
      HWG_INITBUTTONPROC( ::handle )
      Super:Init()
      IF ::value
         SendMessage( ::handle, BM_SETCHECK, 1, 0 )
      ENDIF
   ENDIF
   RETURN Nil 

METHOD onevent( msg, wParam, lParam ) CLASS HCheckButton
	 LOCAL oParent := ::oParent
	 LOCAL itemRect, dc
	 
   IF ::bOther != Nil                                         
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF (msg = WM_SETFOCUS .OR. msg = WM_ACTIVATE)  
      IF  ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
         dc := getDC( ::Handle )
         itemRect  := GetClientRect( ::handle ) 
         InflateRect( @itemRect, + 1, + 1 )
         DrawFocusRect( dc, itemRect )
      ENDIF
   ELSEIF msg = WM_KILLFOCUS //.AND. ::oParent:oParent != Nil
       IF  ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
          dc := getDC( ::Handle )
          itemRect  := GetClientRect( ::handle ) //GetWindowRect( ::HANDLE )
          InflateRect( @itemRect, + 1, + 1 )
          DrawFocusRect( dc, itemRect )
       ENDIF
   ELSEIF msg = WM_KEYDOWN
      IF ProcKeyList( Self, wParam )
      ELSEIF  wParam = VK_TAB 
         GetSkip( ::oparent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1)  )
         RETURN 0
      ELSEIF wParam = VK_LEFT .OR. wParam = VK_UP 
         GetSkip( ::oparent, ::handle, , -1 )
         RETURN 0
      ELSEIF wParam = VK_RIGHT .OR. wParam = VK_DOWN 
         GetSkip( ::oparent, ::handle, , 1 )
         RETURN 0
      ELSEIF  ( wParam == VK_RETURN ) //  .OR. wParam == VK_SPACE ) 
         IF  ::lEnter
            ::SetValue( !::GetValue() )
           __VALID(self)
            RETURN 0 //-1
         ELSE
				    GetSkip( ::oparent, ::handle, , 1 )   
				    RETURN 0
         ENDIF
      ENDIF  
   ELSEIF msg == WM_KEYUP
	 ELSEIF  msg = WM_GETDLGCODE .AND. lParam != 0
      IF wParam = VK_RETURN .OR. wParam = VK_TAB
      ELSEIF GETDLGMESSAGE( lParam ) = WM_KEYDOWN .AND.wParam != VK_ESCAPE    
      ELSEIF GETDLGMESSAGE( lParam ) = WM_CHAR .OR.wParam = VK_ESCAPE 
         RETURN -1
      ENDIF   
      RETURN DLGC_WANTMESSAGE //+ DLGC_WANTCHARS
   ENDIF
   
   RETURN -1


METHOD Refresh() CLASS HCheckButton
   LOCAL var

   IF ::bSetGet != Nil
       var := SendMessage(::handle,BM_GETCHECK,0,0) == 1 
       Eval( ::bSetGet, var, Self ) 
       ::value := Iif( var == Nil .OR. Valtype( var ) != "L", .F., var )        
   ENDIF
   SendMessage( ::handle, BM_SETCHECK, IIf( ::value, 1, 0 ), 0 )

   RETURN Nil

/*
METHOD Disable() CLASS HCheckButton

   Super:Disable()
   SendMessage( ::handle, BM_SETCHECK, BST_INDETERMINATE, 0 )

   RETURN Nil

METHOD Enable() CLASS HCheckButton

   Super:Enable()
   SendMessage( ::handle, BM_SETCHECK, IIf( ::value, 1, 0 ), 0 )

   RETURN Nil
*/

METHOD onGotFocus CLASS HCheckButton
   RETURN __When( Self )

METHOD onClick CLASS HCheckButton
   RETURN __Valid( Self )

METHOD killFocus() CLASS HCheckButton
   LOCAL ndown := getkeystate( VK_RIGHT ) + getkeystate( VK_DOWN ) + GetKeyState( VK_TAB )
   LOCAL nSkip := 0

   IF ::oParent:classname = "HTAB" 
      IF getkeystate( VK_LEFT ) + getkeystate( VK_UP ) < 0 .OR. ;
         ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 )
         nSkip := - 1
      ELSEIF ndown < 0
         nSkip := 1
      ENDIF
      IF nSkip != 0
         GetSkip( ::oparent, ::handle, , nSkip )
      ENDIF
   ENDIF
   IF getkeystate( VK_RETURN ) < 0 .AND. ::lEnter
      ::SetValue( ! ::GetValue() )
      __VALID( Self )
   ENDIF
   RETURN Nil


STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., oParent, nSkip := 1

   IF ! CheckFocus( oCtrl, .f. )
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   IF oCtrl:bGetFocus != Nil
      oCtrl:lnoValid := .T.
      oCtrl:oParent:lSuspendMsgsHandling := .t.
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet, , oCtrl ), oCtrl )
      oCtrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog( oCtrl )
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
   oCtrl:oParent:lSuspendMsgsHandling := .f.
   RETURN res


STATIC FUNCTION __Valid( oCtrl )
   LOCAL l := SendMessage( oCtrl:handle, BM_GETCHECK, 0, 0 )

   IF ! CheckFocus( oCtrl, .t. )  .OR. oCtrl:lnoValid
      RETURN .T.
   ENDIF
   IF l == BST_INDETERMINATE
      CheckDlgButton( oCtrl:oParent:handle, oCtrl:id, .F. )
      SendMessage( oCtrl:handle, BM_SETCHECK, 0, 0 )
      oCtrl:value := .F.
   ELSE
      oCtrl:value := ( l == 1 )
   ENDIF
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bLostFocus != Nil
      oCtrl:oparent:lSuspendMsgsHandling := .t.
      Eval( oCtrl:bLostFocus, oCtrl:value,  oCtrl )
      oCtrl:oparent:lSuspendMsgsHandling := .f.
   ENDIF
   IF GETFOCUS() = 0
      GetSkip( oCtrl:oParent, oCtrl:handle,, oCtrl:nGetSkip )
   ENDIF

   RETURN .T.

