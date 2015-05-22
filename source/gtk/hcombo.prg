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
   METHOD Refresh()
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
      ::xValue := Iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
   ELSE
      ::xValue := Iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
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

   hwg_SetEvent( ::hEdit, "focus_in_event", EN_SETFOCUS, 0, 0 )
   hwg_SetEvent( ::hEdit, "focus_out_event", EN_KILLFOCUS, 0, 0 )
   hwg_SetSignal( ::hEdit, "changed", CBN_SELCHANGE, 0, 0 )

   RETURN Self

METHOD Activate CLASS HComboBox

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createcombo( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::hEdit := hwg_ComboGetEdit( ::handle )
      ::Init()
      hwg_Setwindowobject( ::hEdit, Self )
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HComboBox

   IF msg == EN_SETFOCUS
      IF ::bSetGet == Nil
         IF ::bGetFocus != Nil
            Eval( ::bGetFocus, hwg_Edit_GetText( ::hEdit ), Self )
         ENDIF
      ELSE
         __When( Self )
      ENDIF
   ELSEIF msg == EN_KILLFOCUS
      IF ::bSetGet == Nil
         IF ::bLostFocus != Nil
            Eval( ::bLostFocus, hwg_Edit_GetText( ::hEdit ), Self )
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
      IF !Empty(::aItems)
         hwg_ComboSetArray( ::handle, ::aItems )
         IF Empty( ::xValue )
            IF ::lText
               ::xValue := Iif( Valtype(::aItems[1]) == "A", ::aItems[1,1], ::aItems[1] )
            ELSE
               ::xValue := 1
            ENDIF
         ENDIF
         IF ::lText
            hwg_edit_Settext( ::hEdit, ::xValue )
         ELSE
            hwg_edit_Settext( ::hEdit, Iif( Valtype(::aItems[1]) == "A", ::aItems[::xValue,1], ::aItems[::xValue] ) )
         ENDIF
         IF ::bSetGet != Nil
            Eval( ::bSetGet, ::xValue, Self )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS HComboBox
   LOCAL vari, i

   IF ::bSetGet != Nil
      vari := Eval( ::bSetGet, , Self )
      IF ::lText
         ::xValue := Iif( vari == Nil .OR. ValType( vari ) != "C", "", vari )
      ELSE
         ::xValue := Iif( vari == Nil .OR. ValType( vari ) != "N", 1, vari )
      ENDIF
   ENDIF

   IF !Empty( ::aItems )
      hwg_ComboSetArray( ::handle, ::aItems )

      IF ::lText
         hwg_edit_Settext( ::hEdit, ::xValue )
      ELSE
         hwg_edit_Settext( ::hEdit, Iif( Valtype(::aItems[1]) == "A", ::aItems[::xValue,1], ::aItems[::xValue] ) )
      ENDIF

   ENDIF
   RETURN Nil

METHOD SetItem( nPos ) CLASS HComboBox

   IF ::lText
      ::xValue := Iif( Valtype(::aItems[nPos]) == "A", ::aItems[nPos,1], ::aItems[nPos] )
   ELSE
      ::xValue := nPos
   ENDIF

   hwg_edit_Settext( ::hEdit, Iif( Valtype(::aItems[nPos]) == "A", ::aItems[nPos,1], ::aItems[nPos] ) )

   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::xValue, self )
   ENDIF

   IF ::bChangeSel != Nil
      Eval( ::bChangeSel, ::xValue, Self )
   ENDIF

   RETURN Nil

METHOD GetValue( nItem ) CLASS HComboBox
   LOCAL vari := hwg_edit_Gettext( ::hEdit )
   LOCAL nPos := Iif( !Empty(::aItems) .AND. Valtype(::aItems[1]) == "A", Ascan(::aItems,{|a|a[1]==vari}), Ascan(::aItems,vari) )
   LOCAL l := nPos > 0 .AND. Valtype(::aItems[nPos]) == "A"

   ::xValue := Iif( ::lText, vari, nPos )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::xValue, Self )
   ENDIF
   Return Iif( l .AND. nItem!=Nil, Iif( nItem>0 .AND. nItem<=Len(::aItems[nPos]), ::aItems[nPos,nItem], Nil ), ::xValue )

METHOD Value ( xValue ) CLASS HComboBox
 
   IF xValue != Nil
      IF Valtype( xValue ) == "C"
         xValue := Iif( Valtype(::aItems[1]) == "A", AScan( ::aItems, {|a|a[1]==xValue} ), AScan( ::aItems, xValue ) )
      ENDIF
      ::SetItem( xValue )

      RETURN ::xValue
   ENDIF

   RETURN ::GetValue()


METHOD End() CLASS HComboBox

   hwg_ReleaseObject( ::hEdit )
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
