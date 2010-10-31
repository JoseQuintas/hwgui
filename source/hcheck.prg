/*
 * $Id: hcheck.prg,v 1.46 2010-10-31 11:59:46 lfbasso Exp $
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
#DEFINE TRANSPARENT 1

CLASS HCheckButton INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"
   DATA bSetGet
   DATA value
   DATA lEnter

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
               bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter )
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Refresh()
 //  METHOD Disable()
 //  METHOD Enable()
   METHOD SetValue( lValue )
   METHOD GetValue()          INLINE ( SendMessage( ::handle, BM_GETCHECK, 0, 0 ) == 1 )
   METHOD onGotFocus()
   METHOD onClick()
   METHOD KillFocus()
   METHOD Valid()
   METHOD When()

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
            bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), BS_NOTIFY + BS_PUSHBUTTON + BS_AUTOCHECKBOX + WS_TABSTOP )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )

   ::title   := cCaption
   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "L", .F., vari )
   ::bSetGet := bSetGet
   ::backStyle :=  IIF( lTransp != NIL .AND. lTransp, TRANSPARENT, OPAQUE )

   ::Activate()

   ::lEnter     := IIf( lEnter == Nil .OR. ValType( lEnter ) != "L", .F., lEnter )
   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus

   IF bGFocus != Nil
      //::oParent:AddEvent( BN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::oParent:AddEvent( BN_SETFOCUS, self, { | o, id | ::When( o:FindControl( id ) ) },, "onGotFocus" )
      ::lnoValid := .T.
   ENDIF
   //::oParent:AddEvent( BN_CLICKED, Self, { | o, id | __Valid( o:FindControl( id ), ) },, "onClick" )
   ::oParent:AddEvent( BN_CLICKED, self, { | o, id | ::Valid( o:FindControl( id ) ) },, "onClick" )
   ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::KILLFOCUS() } )

   RETURN Self

METHOD Activate() CLASS HCheckButton
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
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, self, { | o, id | ::When( o:FindControl( id ) ) },, "onGotFocus" )
   ENDIF
   ::oParent:AddEvent( BN_CLICKED, self, { | o, id | ::Valid( o:FindControl( id ) ) },, "onClick" )
   ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::KILLFOCUS() } )

   RETURN Self

METHOD Init() CLASS HCheckButton
   IF ! ::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITBUTTONPROC( ::handle )
      Super:Init()
      IF ::value
         SendMessage( ::handle, BM_SETCHECK, 1, 0 )
      ENDIF
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HCheckButton

   IF ::bOther != Nil
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg = WM_KEYDOWN
      //IF ProcKeyList( Self, wParam )
      IF  wParam = VK_TAB
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
            ::VALID()
            RETURN 0 //-1
         ELSE
            GetSkip( ::oparent, ::handle, , 1 )
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYUP
      ProcKeyList( Self, wParam ) // working in MDICHILD AND DIALOG
      
    ELSEIF  msg = WM_GETDLGCODE .AND. GETDLGMESSAGE( lParam ) != 0
      IF wParam = VK_RETURN .OR. wParam = VK_TAB
      ELSEIF GETDLGMESSAGE( lParam ) = WM_KEYDOWN .AND.wParam != VK_ESCAPE
      ELSEIF GETDLGMESSAGE( lParam ) = WM_CHAR .OR.wParam = VK_ESCAPE
         RETURN -1
      ENDIF
      RETURN DLGC_WANTMESSAGE //+ DLGC_WANTCHARS
   ENDIF

   RETURN -1

METHOD SetValue( lValue ) CLASS HCheckButton

   SendMessage( ::handle, BM_SETCHECK, IIF( EMPTY( lValue) , 0, 1 ), 0 )
   ::value := IIF( lValue = Nil .OR. Valtype( lValue ) != "L", .F., lValue )
   IF ::bSetGet != Nil
       Eval( ::bSetGet, lValue, Self )
   ENDIF
   ::Refresh()

   RETURN Nil

METHOD Refresh() CLASS HCheckButton
   LOCAL var

   IF ::bSetGet != Nil
      var :=  Eval( ::bSetGet,, Self )
      IF var = Nil .OR. Valtype( var ) != "L"
        var := SendMessage( ::handle, BM_GETCHECK, 0, 0 ) == 1
      ENDIF
      ::value := Iif( var==Nil .OR. Valtype(var) != "L", .F., var )
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

METHOD onGotFocus() CLASS HCheckButton
   RETURN ::When( )

METHOD onClick() CLASS HCheckButton
   RETURN ::Valid( )

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
      ::VALID( )
   ENDIF
   RETURN Nil

METHOD When( ) CLASS HCheckButton
   LOCAL res := .t., nSkip

   IF ! CheckFocus( Self, .f. )
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bGetFocus != Nil
      ::lnoValid := .T.
      ::oParent:lSuspendMsgsHandling := .t.
 		  IF ::bSetGet != Nil
          res := Eval( ::bGetFocus, Eval( ::bSetGet, , Self ), Self )
      ELSE
          res := Eval( ::bGetFocus,::Value, Self )
      ENDIF
      ::lnoValid := ! res
      IF ! res
         GetSkip( ::oParent, ::handle, , nSkip )
      ENDIF
   ENDIF
   ::oParent:lSuspendMsgsHandling := .f.
   RETURN res

METHOD Valid() CLASS HCheckButton
   LOCAL l := SendMessage( ::handle, BM_GETCHECK, 0, 0 )

   IF ! CheckFocus( Self, .t. )  .OR. ::lnoValid
      RETURN .T.
   ENDIF
   IF l == BST_INDETERMINATE
      CheckDlgButton( ::oParent:handle, ::id, .F. )
      SendMessage( ::handle, BM_SETCHECK, 0, 0 )
      ::value := .F.
   ELSE
      ::value := ( l == 1 )
   ENDIF
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::value, Self )
   ENDIF
   IF ::bLostFocus != Nil
      ::oparent:lSuspendMsgsHandling := .t.
      Eval( ::bLostFocus, Self, ::value )
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF
   IF EMPTY( GETFOCUS() )
      GetSkip( ::oParent, ::handle,, ::nGetSkip )
   ENDIF

   RETURN .T.

