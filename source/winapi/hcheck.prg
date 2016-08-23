/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckButton class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HCheckButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA bSetGet
   DATA lValue
   DATA bClick

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp, bLFocus )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus )
   METHOD Init()
   METHOD Refresh()
   METHOD Disable()
   METHOD Enable()
   METHOD Value( lValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp, bLFocus ) CLASS HCheckButton

   IF !Empty( lTransp )
      ::extStyle := WS_EX_TRANSPARENT
   ENDIF
   nStyle   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), BS_AUTO3STATE + WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )

   ::title   := cCaption
   ::lValue   := iif( vari == Nil .OR. ValType( vari ) != "L", .F. , vari )
   ::bSetGet := bSetGet

   ::Activate()

   ::bClick := bClick
   ::bLostFocus := bLFocus
   ::bGetFocus  := bGFocus
                                                                      
   ::oParent:AddEvent( BN_CLICKED, ::id, { |o, id|__Valid( o:FindControl(id ) ) } )
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, ::id, { |o, id|__When( o:FindControl(id ) ) } )
   ENDIF
   IF bLFocus != Nil
      ::oParent:AddEvent( BN_KILLFOCUS, ::id, ::bLostFocus )
   ENDIF

   RETURN Self

METHOD Activate CLASS HCheckButton

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Redefine( oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus ) CLASS HCheckButton

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )

   ::lValue  := iif( vari == Nil .OR. ValType( vari ) != "L", .F. , vari )
   ::bSetGet := bSetGet

   ::bClick := bClick
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_CLICKED, ::id, { |o, id|__Valid( o:FindControl(id ) ) } )
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, ::id, { |o, id|__When( o:FindControl(id ) ) } )
   ENDIF

   RETURN Self

METHOD Init() CLASS HCheckButton

   IF !::lInit
      ::Super:Init()
      IF ::lValue
         hwg_Sendmessage( ::handle, BM_SETCHECK, 1, 0 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS HCheckButton
   LOCAL var

   IF ::bSetGet != Nil
      var := Eval( ::bSetGet, , nil )
      ::lValue := iif( var == Nil, .F. , var )
   ENDIF

   hwg_Sendmessage( ::handle, BM_SETCHECK, iif( ::lValue,1,0 ), 0 )

   RETURN Nil

METHOD Disable() CLASS HCheckButton

   ::Super:Disable()
   hwg_Sendmessage( ::handle, BM_SETCHECK, BST_INDETERMINATE, 0 )

   RETURN Nil

METHOD Enable() CLASS HCheckButton

   ::Super:Enable()
   hwg_Sendmessage( ::handle, BM_SETCHECK, iif( ::lValue,1,0 ), 0 )

   RETURN Nil

METHOD Value( lValue ) CLASS HCheckButton

   IF lValue != Nil
      IF ValType( lValue ) != "L"
         lValue := .F.
      ENDIF
      hwg_Sendmessage( ::handle, BM_SETCHECK, iif( lValue,1,0 ), 0 )
      IF ::bSetGet != NIL
         Eval( ::bSetGet, lValue, Self )
      ENDIF
      RETURN ( ::lValue := lValue )
   ENDIF

   RETURN ( ::lValue := ( hwg_Sendmessage( ::handle, BM_GETCHECK, 0, 0 ) == 1 ) )

STATIC FUNCTION __Valid( oCtrl )
   LOCAL l := hwg_Sendmessage( oCtrl:handle, BM_GETCHECK, 0, 0 )

   IF l == BST_INDETERMINATE
      hwg_Checkdlgbutton( oCtrl:oParent:handle, oCtrl:id, .F. )
      hwg_Sendmessage( oCtrl:handle, BM_SETCHECK, 0, 0 )
      oCtrl:lValue := .F.
   ELSE
      oCtrl:lValue := ( l == 1 )
   ENDIF

   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:lValue, oCtrl )
   ENDIF
   IF oCtrl:bClick != Nil .AND. !Eval( oCtrl:bClick, oCtrl, oCtrl:lValue )
      hwg_Setfocus( oCtrl:handle )
   ENDIF

   RETURN .T.

STATIC FUNCTION __When( oCtrl )
   LOCAL res

   oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
      RETURN res
   ENDIF

   RETURN .T.
