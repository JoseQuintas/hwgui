/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDatePicker class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define DTN_DATETIMECHANGE    -759
#define DTN_CLOSEUP           -753
#define DTM_GETMONTHCAL       4104   // 0x1008

#ifndef HBMK_HAS_GTWVG
#define NM_KILLFOCUS          -8
#define NM_SETFOCUS           -7
#endif

CLASS HDatePicker INHERIT HControl

   CLASS VAR winclass   INIT "SYSDATETIMEPICK32"
   DATA bSetGet
   DATA dValue
   DATA bChange

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor )
   METHOD Activate()
   METHOD Init()
   METHOD Refresh()
   METHOD Value ( dValue ) SETGET

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, bcolor ) CLASS HDatePicker

   nStyle := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      , , ctooltip, tcolor, bcolor )

   ::dValue  := iif( vari == Nil .OR. ValType( vari ) != "D", CToD( Space(8 ) ), vari )
   ::bSetGet := bSetGet
   ::bChange := bChange

   HWG_InitCommonControlsEx()
   ::Activate()

   IF bGfocus != Nil
      ::oParent:AddEvent( NM_SETFOCUS, ::id, bGfocus, .T. )
   ENDIF
   ::oParent:AddEvent( DTN_DATETIMECHANGE, ::id, { |o, id|__Change( o:FindControl(id ),DTN_DATETIMECHANGE ) }, .T. )
   ::oParent:AddEvent( DTN_CLOSEUP, ::id, { |o, id|__Change( o:FindControl(id ),DTN_CLOSEUP ) }, .T. )
   IF bSetGet != Nil
      ::bLostFocus := bLFocus
      ::oParent:AddEvent( NM_KILLFOCUS, ::id, { |o, id|__Valid( o:FindControl(id ) ) }, .T. )
   ELSE
      IF bLfocus != Nil
         ::oParent:AddEvent( NM_KILLFOCUS, ::id, bLfocus, .T. )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate() CLASS HDatePicker

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createdatepicker( ::oParent:handle, ::id, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init() CLASS HDatePicker

   IF !::lInit
      ::Super:Init()
      IF Empty( ::dValue )
         hwg_Setdatepickernull( ::handle )
      ELSE
         hwg_Setdatepicker( ::handle, ::dValue )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Refresh() CLASS HDatePicker

   IF ::bSetGet != Nil
      ::dValue := Eval( ::bSetGet,, Self )
   ENDIF

   IF Empty( ::dValue )
      hwg_Setdatepickernull( ::handle )
   ELSE
      hwg_Setdatepicker( ::handle, ::dValue )
   ENDIF

   RETURN Nil

METHOD Value( dValue ) CLASS HDatePicker

   IF dValue != Nil
      IF ValType( dValue ) == "D"
         hwg_Setdatepicker( ::handle, dValue )
         ::dValue := dValue
         IF ::bSetGet != Nil
            Eval( ::bSetGet, dValue, Self )
         ENDIF
      ENDIF
   ELSE
      ::dValue := hwg_Getdatepicker( ::handle )
   ENDIF

   RETURN ::dValue

STATIC FUNCTION __Change( oCtrl, nMess )

   IF ( nMess == DTN_DATETIMECHANGE .AND. ;
         hwg_Sendmessage( oCtrl:handle, DTM_GETMONTHCAL, 0, 0 ) == 0 ) .OR. ;
         nMess == DTN_CLOSEUP
      oCtrl:dValue := hwg_Getdatepicker( oCtrl:handle )
      IF oCtrl:bSetGet != Nil
         Eval( oCtrl:bSetGet, oCtrl:dValue, oCtrl )
      ENDIF
      IF oCtrl:bChange != Nil
         Eval( oCtrl:bChange, oCtrl:dValue, oCtrl )
      ENDIF
   ENDIF

   RETURN .T.

STATIC FUNCTION __Valid( oCtrl )

   oCtrl:dValue := hwg_Getdatepicker( oCtrl:handle )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:dValue, oCtrl )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, oCtrl:dValue, oCtrl )
      RETURN .F.
   ENDIF

   RETURN .T.
