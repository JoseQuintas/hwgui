/*
 * $Id$
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

   CLASS VAR winclass INIT "BUTTON"
   DATA bSetGet
   DATA lValue
   DATA lEnter
   DATA lFocu INIT .f.
   DATA bClick

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
               bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp, bLFocus )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter )
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Refresh()
   // METHOD Disable()
   // METHOD Enable()
   METHOD SetValue( lValue )
   METHOD GetValue() INLINE ( hwg_Sendmessage( ::handle, BM_GETCHECK, 0, 0 ) == 1 )
   METHOD onGotFocus()
   METHOD onClick()
   METHOD KillFocus()
   METHOD Valid()
   METHOD When()
   METHOD Value ( lValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp, bLFocus ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_NOTIFY + BS_PUSHBUTTON + BS_AUTOCHECKBOX + WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
         bSize, bPaint, ctooltip, tcolor, bcolor )

   ::title   := cCaption
   ::lValue   := IIf( vari == NIL .OR. ValType( vari ) != "L", .F., vari )
   ::bSetGet := bSetGet
   ::backStyle :=  IIF( lTransp != NIL .AND. lTransp, TRANSPARENT, OPAQUE )

   ::Activate()

   ::lEnter     := IIf( lEnter == NIL .OR. ValType( lEnter ) != "L", .F., lEnter )
   ::bClick     := bClick
   ::bLostFocus := bLFocus
   ::bGetFocus  := bGFocus

   IF bGFocus != NIL
      //::oParent:AddEvent( BN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::oParent:AddEvent( BN_SETFOCUS, self, { | o, id | ::When( o:FindControl( id ) ) },, "onGotFocus" )
      ::lnoValid := .T.
   ENDIF
   //::oParent:AddEvent( BN_CLICKED, Self, { | o, id | __Valid( o:FindControl( id ), ) },, "onClick" )
   ::oParent:AddEvent( BN_CLICKED, Self, { | o, id | ::Valid( o:FindControl( id ) ) },, "onClick" )
   ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::KILLFOCUS() } )

   RETURN Self

METHOD Activate() CLASS HCheckButton
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ;
            ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter ) CLASS HCheckButton

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint, ctooltip, tcolor, bcolor )

   ::lValue   := IIf( vari == NIL .OR. ValType( vari ) != "L", .F., vari )
   ::bSetGet := bSetGet
   ::lEnter     := IIf( lEnter == NIL .OR. ValType( vari ) != "L", .F., lEnter )
   ::bClick     := bClick
   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus
   IF bGFocus != NIL
      ::oParent:AddEvent( BN_SETFOCUS, self, { | o, id | ::When( o:FindControl( id ) ) },, "onGotFocus" )
   ENDIF
   ::oParent:AddEvent( BN_CLICKED, self, { | o, id | ::Valid( o:FindControl( id ) ) },, "onClick" )
   ::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::KILLFOCUS() } )

   RETURN Self

METHOD Init() CLASS HCheckButton
   IF ! ::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      HWG_INITBUTTONPROC( ::handle )
      ::Super:Init()
      IF ::lValue
         hwg_Sendmessage( ::handle, BM_SETCHECK, 1, 0 )
      ENDIF
   ENDIF

   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HCheckButton
   LOCAL oCtrl

   IF ::bOther != NIL
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg = WM_KEYDOWN
      //IF hwg_ProcKeyList( Self, wParam )
      IF wParam = VK_TAB
         hwg_GetSkip( ::oparent, ::handle, , iif( hwg_IsCtrlShift(.f., .t.), -1, 1 )  )
         RETURN 0
      ELSEIF wParam = VK_LEFT .OR. wParam = VK_UP
         hwg_GetSkip( ::oparent, ::handle, , -1 )
         RETURN 0
      ELSEIF wParam = VK_RIGHT .OR. wParam = VK_DOWN
         hwg_GetSkip( ::oparent, ::handle, , 1 )
         RETURN 0
      ELSEIF  ( wParam == VK_RETURN ) //  .OR. wParam == VK_SPACE )
         IF ::lEnter
            ::SetValue( ! ::GetValue() )
            ::VALID()
            RETURN 0 //-1
         ELSE
            hwg_GetSkip( ::oparent, ::handle, , 1 )
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYUP
      hwg_ProcKeyList( Self, wParam ) // working in MDICHILD AND DIALOG
   ELSEIF msg = WM_GETDLGCODE .AND. !EMPTY( lParam )
      IF wParam = VK_RETURN .OR. wParam = VK_TAB
         RETURN -1
      ELSEIF wParam = VK_ESCAPE  .AND. ;
            ( oCtrl := hwg_GetParentForm(Self):FindControl( IDCANCEL ) ) != NIL .AND. ! oCtrl:IsEnabled()
         RETURN DLGC_WANTMESSAGE
      ELSEIF hwg_Getdlgmessage( lParam ) = WM_KEYDOWN .AND. wParam != VK_ESCAPE
      ELSEIF hwg_Getdlgmessage( lParam ) = WM_CHAR .OR.wParam = VK_ESCAPE .OR.;
         hwg_Getdlgmessage( lParam ) = WM_SYSCHAR
         RETURN -1
      ENDIF
      RETURN DLGC_WANTMESSAGE //+ DLGC_WANTCHARS
   ENDIF

   RETURN -1

METHOD SetValue( lValue ) CLASS HCheckButton

   hwg_Sendmessage( ::handle, BM_SETCHECK, IIF( EMPTY( lValue) , 0, 1 ), 0 )
   ::lValue := IIF( lValue = NIL .OR. Valtype( lValue ) != "L", .F., lValue )
   IF ::bSetGet != NIL
       Eval( ::bSetGet, lValue, Self )
   ENDIF
   ::Refresh()

   RETURN NIL

METHOD Value( lValue ) CLASS HCheckButton

   IF lValue != NIL
      ::SetValue( lValue )
   ENDIF

   RETURN hwg_Sendmessage( ::handle,BM_GETCHECK, 0, 0 ) == 1

METHOD Refresh() CLASS HCheckButton
   LOCAL var

   IF ::bSetGet != NIL
      var :=  Eval( ::bSetGet,, Self )
      IF var = NIL .OR. Valtype( var ) != "L"
         var := hwg_Sendmessage( ::handle, BM_GETCHECK, 0, 0 ) == 1
      ENDIF
      ::lValue := Iif( var==NIL .OR. Valtype(var) != "L", .F., var )
   ENDIF
   hwg_Sendmessage( ::handle, BM_SETCHECK, IIf( ::lValue, 1, 0 ), 0 )

   RETURN NIL

/*
METHOD Disable() CLASS HCheckButton

   ::Super:Disable()
   hwg_Sendmessage( ::handle, BM_SETCHECK, BST_INDETERMINATE, 0 )

   RETURN NIL

METHOD Enable() CLASS HCheckButton

   ::Super:Enable()
   hwg_Sendmessage( ::handle, BM_SETCHECK, IIf( ::lValue, 1, 0 ), 0 )

   RETURN NIL
*/

METHOD onGotFocus() CLASS HCheckButton

   RETURN ::When( )

METHOD onClick() CLASS HCheckButton

   RETURN ::Valid( )

METHOD killFocus() CLASS HCheckButton
   LOCAL ndown := hwg_Getkeystate( VK_RIGHT ) + hwg_Getkeystate( VK_DOWN ) + hwg_Getkeystate( VK_TAB )
   LOCAL nSkip := 0

   IF ! hwg_CheckFocus( Self, .T. )
      RETURN .t.
   ENDIF

   IF ::oParent:classname = "HTAB"
      IF hwg_Getkeystate( VK_LEFT ) + hwg_Getkeystate( VK_UP ) < 0 .OR. ;
            ( hwg_Getkeystate( VK_TAB ) < 0 .and. hwg_Getkeystate( VK_SHIFT ) < 0 )
         nSkip := - 1
      ELSEIF ndown < 0
         nSkip := 1
      ENDIF
      IF nSkip != 0
         hwg_GetSkip( ::oparent, ::handle, , nSkip )
      ENDIF
   ENDIF
   IF hwg_Getkeystate( VK_RETURN ) < 0 .AND. ::lEnter
      ::SetValue( ! ::GetValue() )
      ::VALID( )
   ENDIF
   IF ::bLostFocus != NIL
      ::oparent:lSuspendMsgsHandling := .t.
      Eval( ::bLostFocus, Self, ::lValue )
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF

   RETURN NIL

METHOD When( ) CLASS HCheckButton
   LOCAL res := .t., nSkip

   IF ! hwg_CheckFocus( Self, .f. )
      RETURN .t.
   ENDIF
   nSkip := IIf( hwg_Getkeystate( VK_UP ) < 0 .or. ( hwg_Getkeystate( VK_TAB ) < 0 .and. hwg_Getkeystate( VK_SHIFT ) < 0 ), - 1, 1 )
   IF ::bGetFocus != NIL
      ::lnoValid := .T.
      ::oParent:lSuspendMsgsHandling := .t.
      IF ::bSetGet != NIL
         res := Eval( ::bGetFocus, Eval( ::bSetGet, , Self ), Self )
      ELSE
         res := Eval( ::bGetFocus,::lValue, Self )
      ENDIF
      ::lnoValid := ! res
      IF ! res
         hwg_WhenSetFocus( Self, nSkip )
      ENDIF
   ENDIF
   ::oParent:lSuspendMsgsHandling := .f.

   RETURN res

METHOD Valid() CLASS HCheckButton
   LOCAL l := hwg_Sendmessage( ::handle, BM_GETCHECK, 0, 0 )

   IF ! hwg_CheckFocus( Self, .t. )  .OR. ::lnoValid
      RETURN .T.
   ENDIF
   IF l == BST_INDETERMINATE
      hwg_Checkdlgbutton( ::oParent:handle, ::id, .F. )
      hwg_Sendmessage( ::handle, BM_SETCHECK, 0, 0 )
      ::lValue := .F.
   ELSE
      ::lValue := ( l == 1 )
   ENDIF
   IF ::bSetGet != NIL
      Eval( ::bSetGet, ::lValue, Self )
   ENDIF
   IF ::bClick != NIL
      ::oparent:lSuspendMsgsHandling := .t.
       Eval( ::bClick, Self, ::lValue )
       ::oparent:lSuspendMsgsHandling := .f.
   ENDIF
   IF EMPTY( hwg_Getfocus() )
      hwg_GetSkip( ::oParent, ::handle,, ::nGetSkip )
   ENDIF

   RETURN .T.
