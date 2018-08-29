/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HCheckButton class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HCheckButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA bSetGet
   DATA lValue

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctoolt, tcolor, bcolor, bGFocus )
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Refresh()
   METHOD SetText( value ) INLINE hwg_button_SetText( ::handle, value )
   METHOD GetText() INLINE hwg_button_GetText( ::handle )
   METHOD Value( lValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctoolt, tcolor, bcolor, bGFocus ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), BS_AUTO3STATE + WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor )

   ::title   := cCaption
   ::lValue   := iif( vari == Nil .OR. ValType( vari ) != "L", .F. , vari )
   ::bSetGet := bSetGet

   ::Activate()

   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus

   hwg_SetSignal( ::handle, "clicked", WM_LBUTTONUP, 0, 0 )
   IF bGFocus != Nil
      hwg_SetSignal( ::handle, "enter", BN_SETFOCUS, 0, 0 )
   ENDIF

   IF Left( ::oParent:ClassName(),6 ) == "HPANEL" .AND. hwg_BitAnd( ::oParent:style,SS_OWNERDRAW ) != 0
      ::oParent:SetPaintCB( PAINT_ITEM, {|o,h|Iif(!::lHide,hwg__DrawCheckBtn(h,::nLeft,::nTop,::nLeft+::nWidth-1,::nTop+::nHeight-1,::lValue,::title),.T.)}, "ch"+Ltrim(Str(::id)) )
   ENDIF

   RETURN Self

METHOD Activate CLASS HCheckButton

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      hwg_Setwindowobject( ::handle, Self )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HCheckButton

   IF !::lInit
      ::Super:Init()
      IF ::lValue
         hwg_CheckButton( ::handle, .T. )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HCheckButton

   IF msg == WM_LBUTTONUP
      __Valid( Self )
   ELSEIF msg == BN_SETFOCUS
      __When( Self )
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS HCheckButton
   LOCAL var

   IF ::bSetGet != Nil
      var := Eval( ::bSetGet, , nil )
      ::lValue := iif( var == Nil, .F. , var )
   ENDIF

   hwg_CheckButton( ::handle, ::lValue )

   RETURN Nil

METHOD Value( lValue ) CLASS HCheckButton

   IF lValue != Nil
      IF ValType( lValue ) != "L"
         lValue := .F.
      ENDIF
      hwg_CheckButton( ::handle, lValue )
      IF ::bSetGet != NIL
         Eval( ::bSetGet, lValue, Self )
      ENDIF
      RETURN ( ::lValue := lValue )
   ENDIF

   RETURN ( ::lValue := hwg_IsButtonChecked( ::handle ) )


STATIC FUNCTION __Valid( oCtrl )
   LOCAL res

   oCtrl:lValue := hwg_IsButtonChecked( oCtrl:handle )

   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:lValue, oCtrl )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. ;
         ValType( res := Eval( oCtrl:bLostFocus, oCtrl, oCtrl:lValue ) ) == "L" ;
         .AND. !res
      hwg_Setfocus( oCtrl:handle )
   ENDIF

   RETURN .T.

STATIC FUNCTION __When( oCtrl )
   LOCAL res

   oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF ValType( res ) == "L" .AND. !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
      RETURN res
   ENDIF

   RETURN .T.
