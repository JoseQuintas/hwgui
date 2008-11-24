/*
 * $Id: hcheck.prg,v 1.26 2008-11-24 10:02:12 mlacecilia Exp $
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
   METHOD Refresh()
   METHOD Disable()
   METHOD Enable()
   METHOD SetValue( lValue )  INLINE SendMessage( ::handle, BM_SETCHECK, IIf( lValue, 1, 0 ), 0 ), ::value := lValue
   METHOD GetValue()          INLINE ( SendMessage( ::handle, BM_GETCHECK, 0, 0 ) == 1 )
   METHOD KillFocus()
ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
            bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), BS_NOTIFY + BS_PUSHBUTTON + BS_AUTOCHECKBOX + WS_TABSTOP )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )

   ::title   := cCaption
   ::value   := IIf( vari == Nil .OR. ValType( vari ) != "L", .F., vari )
   ::bSetGet := bSetGet

   IF ( lTransp != NIL .AND. lTransp )
      bcolor := ::oParent:bcolor
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
      Super:Init()
      IF ::value
         SendMessage( ::handle, BM_SETCHECK, 1, 0 )
      ENDIF
   ENDIF
   RETURN Nil

METHOD Refresh() CLASS HCheckButton
   LOCAL VAR

   IF ::bSetGet != Nil
      VAR := Eval( ::bSetGet,, nil )
      ::value := IIf( VAR == Nil, .F., VAR )
   ENDIF

   SendMessage( ::handle, BM_SETCHECK, IIf( ::value, 1, 0 ), 0 )

   RETURN Nil

METHOD Disable() CLASS HCheckButton

   Super:Disable()
   SendMessage( ::handle, BM_SETCHECK, BST_INDETERMINATE, 0 )

   RETURN Nil

METHOD Enable() CLASS HCheckButton

   Super:Enable()
   SendMessage( ::handle, BM_SETCHECK, IIf( ::value, 1, 0 ), 0 )

   RETURN Nil

METHOD killFocus() CLASS HCheckButton
   LOCAL ndown := getkeystate( VK_RIGHT ) + getkeystate( VK_DOWN ) + GetKeyState( VK_TAB )
   LOCAL nSkip := 0

   IF ::oParent:classname = "HTAB" //.AND. !getkeystate(VK_RETURN) < 0
      ///oCtrl:oparent:HANDLE)
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

