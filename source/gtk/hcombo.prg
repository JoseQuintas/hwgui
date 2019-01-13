/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HComboBox class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#ifndef CBN_SELCHANGE
#define CBN_SELCHANGE       1
#endif

CLASS HComboBox INHERIT HControl

   CLASS VAR winclass   INIT "COMBOBOX"
   DATA  aItems
   DATA  bSetGet
   DATA  bValid
   DATA  xValue    INIT 1
   DATA  bChangeSel
   DATA  lText    INIT .F.
   DATA  lEdit    INIT .F.
   DATA  hEdit

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      aItems, oFont, bInit, bSize, bPaint, bChange, cToolt, lEdit, lText, bGFocus, tcolor, bcolor, bValid )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init( aCombo, nCurrent )
   METHOD Refresh( xVal )
   METHOD Setitem( nPos )
   METHOD GetValue( nItem )
   METHOD Value ( xValue ) SETGET
   METHOD End()

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, ;
      bInit, bSize, bPaint, bChange, cToolt, lEdit, lText, bGFocus, tcolor, bcolor, bValid ) CLASS HComboBox

   IF lEdit == Nil; lEdit := .F. ; ENDIF
   IF lText == Nil; lText := .F. ; ENDIF

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), iif( lEdit,CBS_DROPDOWN,CBS_DROPDOWNLIST ) + WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctoolt, tcolor, bcolor )

   ::lEdit := lEdit
   ::lText := lText

   IF lEdit
      ::lText := .T.
   ENDIF

   IF ::lText
      ::xValue := iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
   ELSE
      ::xValue := iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
   ENDIF

   IF bSetGet != Nil
      ::bSetGet := bSetGet
      Eval( ::bSetGet, ::xValue, self )
   ENDIF

   ::aItems  := aItems

   ::Activate()
   ::bValid := bValid
   ::bGetFocus := bGFocus
   ::bChangeSel := bChange

   hwg_SetEvent( ::handle, "focus_in_event", EN_SETFOCUS, 0, 0 )
   hwg_SetEvent( ::handle, "focus_out_event", EN_KILLFOCUS, 0, 0 )
   hwg_SetSignal( ::handle, "changed", CBN_SELCHANGE, 0, 0 )

   IF Left( ::oParent:ClassName(), 6 ) == "HPANEL" .AND. hwg_BitAnd( ::oParent:style, SS_OWNERDRAW ) != 0
      ::oParent:SetPaintCB( PAINT_ITEM, { |o, h|iif( !::lHide,hwg__DrawCombo(h,::nLeft + ::nWidth - 22,::nTop,::nLeft + ::nWidth - 1,::nTop + ::nHeight - 1 ), .T. ) }, "hc" + LTrim( Str(::id ) ) )
   ENDIF

   RETURN Self

METHOD Activate CLASS HComboBox

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createcombo( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
      hwg_Setwindowobject( ::handle, Self )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HComboBox

   LOCAL i

   IF msg == EN_SETFOCUS
      IF ::bSetGet == Nil
         IF ::bGetFocus != Nil
            i := hwg_ComboGet( ::handle )
            Eval( ::bGetFocus, iif( ValType(::aItems[1] ) == "A", ::aItems[i,1], ::aItems[i] ), Self )
         ENDIF
      ELSE
         __When( Self )
      ENDIF
   ELSEIF msg == EN_KILLFOCUS
      IF ::bSetGet == Nil
         IF ::bLostFocus != Nil
            i := hwg_ComboGet( ::handle )
            Eval( ::bLostFocus, iif( ValType(::aItems[1] ) == "A", ::aItems[i,1], ::aItems[i] ), Self )
         ENDIF
      ELSE
         __Valid( Self )
      ENDIF

   ELSEIF msg == CBN_SELCHANGE
      ::GetValue()
      IF ::bChangeSel != Nil
         Eval( ::bChangeSel, ::xValue, Self )
      ENDIF

   ENDIF

   RETURN 0

METHOD Init() CLASS HComboBox
   LOCAL i

   IF !::lInit
      ::Super:Init()
      IF !Empty( ::aItems )
         hwg_ComboSetArray( ::handle, ::aItems )
         IF Empty( ::xValue )
            IF ::lText
               ::xValue := iif( ValType( ::aItems[1] ) == "A", ::aItems[1,1], ::aItems[1] )
            ELSE
               ::xValue := 1
            ENDIF
         ENDIF
         ::Value := ::xValue
         IF ::bSetGet != Nil
            Eval( ::bSetGet, ::xValue, Self )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

METHOD Refresh( xVal ) CLASS HComboBox
   LOCAL vari, i

   IF xVal != Nil
      ::xValue := xVal
   ELSEIF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , Self )
      IF ::lText
         ::xValue := iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
      ELSE
         ::xValue := iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
      ENDIF
   ENDIF

   IF !Empty( ::aItems )
      hwg_ComboSetArray( ::handle, ::aItems )

      IF ::lText
         hwg_ComboSet( ::handle, 1 )
      ELSE
         hwg_ComboSet( ::handle, ::xValue )
      ENDIF

   ENDIF

   RETURN Nil

METHOD SetItem( nPos ) CLASS HComboBox

   IF ::lText
      ::xValue := iif( ValType( ::aItems[nPos] ) == "A", ::aItems[nPos,1], ::aItems[nPos] )
   ELSE
      ::xValue := nPos
   ENDIF

   hwg_ComboSet( ::handle, nPos )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::xValue, self )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, ::xValue, Self )
   ENDIF

   RETURN Nil

METHOD GetValue( nItem ) CLASS HComboBox
   LOCAL nPos := hwg_ComboGet( ::handle )
   LOCAL vari := iif( !Empty( ::aItems ) .AND. nPos > 0, ;
      iif( ValType( ::aItems[1] ) == "A", ::aItems[nPos,1], ::aItems[nPos] ), "" )
   LOCAL l := nPos > 0 .AND. ValType( ::aItems[nPos] ) == "A"

   ::xValue := iif( ::lText, vari, nPos )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::xValue, Self )
   ENDIF

   RETURN iif( l .AND. nItem != Nil, iif( nItem > 0 .AND. nItem <= Len(::aItems[nPos] ), ::aItems[nPos,nItem], Nil ), ::xValue )

METHOD Value ( xValue ) CLASS HComboBox

   IF xValue != Nil
      IF ValType( xValue ) == "C"
#ifdef __XHARBOUR__
         xValue := iif( ValType( ::aItems[1] ) == "A", AScan( ::aItems, { |a|a[1] == xValue } ), AScan( ::aItems, { |s|s == xValue } ) )
#else
         xValue := iif( ValType( ::aItems[1] ) == "A", AScan( ::aItems, { |a|a[1] == xValue } ), hb_AScan( ::aItems, xValue,,, .T. ) )
#endif
      ENDIF
      ::SetItem( xValue )

      RETURN ::xValue
   ENDIF

   RETURN ::GetValue()

METHOD End() CLASS HComboBox

   hwg_ReleaseObject( ::handle )
   ::Super:End()

   RETURN Nil

STATIC FUNCTION __Valid( oCtrl )

   oCtrl:GetValue()
   IF oCtrl:bValid != NIL
      IF !Eval( oCtrl:bValid, oCtrl )
         hwg_Setfocus( oCtrl:handle )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION __When( oCtrl )
   LOCAL res

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         hwg_GetSkip( oCtrl:oParent, oCtrl:handle, 1 )
      ENDIF
      RETURN res
   ENDIF

   RETURN .T.
