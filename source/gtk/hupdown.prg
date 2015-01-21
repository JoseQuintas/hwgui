/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HUpDown class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#ifndef UDS_SETBUDDYINT
#define UDS_SETBUDDYINT     2
#define UDS_ALIGNRIGHT      4
#endif

CLASS HUpDown INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"
   DATA bSetGet
   DATA nValue
   DATA nLower INIT 0
   DATA nUpper INIT 999
   DATA nUpDownWidth INIT 12
   DATA lChanged    INIT .F.

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctoolt, tcolor, bcolor, nUpDWidth, nLower, nUpper )
   METHOD Activate()
   METHOD Refresh()
   METHOD Value( nValue ) SETGET
   METHOD SetRange( n1, n2 )  INLINE hwg_SetRangeUpdown( ::handle, n1, n2 )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctoolt, tcolor, bcolor,   ;
      nUpDWidth, nLower, nUpper ) CLASS HUpDown

   nStyle   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, ctoolt, tcolor, bcolor )

   IF vari != Nil
      IF ValType( vari ) != "N"
         vari := 0
         Eval( bSetGet, vari )
      ENDIF
      ::title := Str( vari )
   ENDIF
   ::bSetGet := bSetGet

   IF nLower != Nil ; ::nLower := nLower ; ENDIF
   IF nUpper != Nil ; ::nUpper := nUpper ; ENDIF
   IF nUpDWidth != Nil ; ::nUpDownWidth := nUpDWidth ; ENDIF

   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGFocus
      ::bLostFocus := bLFocus
      ::oParent:AddEvent( EN_SETFOCUS, ::id, { |o, id|__When( o:FindControl(id ) ) } )
      ::oParent:AddEvent( EN_KILLFOCUS, ::id, { |o, id|__Valid( o:FindControl(id ) ) } )
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS, ::id, bGfocus )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS, ::id, bLfocus )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate CLASS HUpDown

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createupdowncontrol( ::oParent:handle, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, Val( ::title ), ::nLower, ::nUpper )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Refresh()  CLASS HUpDown
   LOCAL vari

   IF ::bSetGet != Nil
      ::nValue := Eval( ::bSetGet )
      IF Str( ::nValue ) != ::title
         ::title := Str( ::nValue )
         hwg_SetUpDown( ::handle, ::nValue )
      ENDIF
   ELSE
      hwg_SetUpDown( ::handle, Val( ::title ) )
   ENDIF

   RETURN Nil

METHOD Value( nValue ) CLASS HUpDown

   IF nValue != Nil
      IF ValType( nValue ) == "N"
         hwg_SetUpdown( ::handle, nValue )
         ::nValue := nValue
         IF ::bSetGet != NIL
            Eval( ::bSetGet, nValue, Self )
         ENDIF
      ENDIF
   ELSE
      ::nValue := hwg_GetUpDown( ::handle )
   ENDIF

   RETURN ::nValue

STATIC FUNCTION __When( oCtrl )

   oCtrl:Refresh()
   IF oCtrl:bGetFocus != Nil
      RETURN Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet ), oCtrl )
   ENDIF

   RETURN .T.

STATIC FUNCTION __Valid( oCtrl )

   oCtrl:nValue := hwg_GetUpDown( oCtrl:handle )
   oCtrl:title := Str( oCtrl:nValue )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:nValue )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, oCtrl:nValue, oCtrl ) .OR. ;
         oCtrl:nValue > oCtrl:nUpper .OR. oCtrl:nValue < oCtrl:nLower
      hwg_Setfocus( oCtrl:handle )
   ENDIF

   RETURN .T.
