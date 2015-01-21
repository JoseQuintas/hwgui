/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTab class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define  IPN_FIELDCHANGED   4294966436

//- HIPedit

CLASS HIPedit INHERIT HControl

   CLASS VAR winclass   INIT "SysIPAddress32"
   DATA bSetGet
   DATA bChange
   DATA bKillFocus
   DATA bGetFocus

   METHOD New( oWndParent, nId, aValue, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bGetFocus, bKillFocus )
   METHOD Activate()
   METHOD Init()
   METHOD Value( aValue ) SETGET
   METHOD Clear()
   METHOD END()

   HIDDEN:
   DATA  aValue           // Valor atual

ENDCLASS

METHOD New( oWndParent, nId, aValue, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bGetFocus, bKillFocus ) CLASS HIPedit

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont )

   ::title   := ""

   ::bSetGet := bSetGet
   DEFAULT aValue := { 0, 0, 0, 0 }
   ::aValue  := aValue
   ::bGetFocus  := bGetFocus
   ::bKillFocus := bKillFocus

   HWG_InitCommonControlsEx()
   ::Activate()


   IF bKillFocus != Nil
      ::oParent:AddEvent( IPN_FIELDCHANGED, ::id, ::bKillFocus, .t., "onChange" )
   ENDIF
  * ENDIF

   // Notificacoes de Ganho e perda de foco
   ::oParent:AddEvent( EN_SETFOCUS , ::id, { | o, id | __GetFocus( o:FindControl( id ) ) },, "onGotFocus" )
   ::oParent:AddEvent( EN_KILLFOCUS, ::id, { | o, id | __KillFocus( o:FindControl( id ) ) },, "onLostFocus" )


   RETURN Self

METHOD Activate() CLASS HIPedit
   IF ! Empty( ::oParent:handle )
      ::handle := hwg_Initipaddress ( ::oParent:handle, ::id, ::style , ;
                                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HIPedit

   IF ! ::lInit
      ::Super:Init()
      hwg_Setipaddress( ::handle , ::aValue[ 1 ], ::aValue[ 2 ], ::aValue[ 3 ], ::aValue[ 4 ] )
      ::lInit := .t.
   ENDIF

   RETURN Nil

METHOD Value( aValue ) CLASS HIPedit

   IF aValue != Nil
      hwg_Setipaddress( ::handle , aValue[ 1 ], aValue[ 2 ], aValue[ 3 ], aValue[ 4 ] )
      ::aValue := aValue
   ELSE
      ::aValue := hwg_Getipaddress( ::handle )
   ENDIF

   RETURN ::aValue


METHOD Clear( ) CLASS HIPedit
   hwg_Clearipaddress( ::handle )
   ::aValue := { 0, 0, 0, 0 }
   RETURN ( ::aValue )


METHOD END() CLASS HIPedit

   // Nothing to do here, yet!
   ::Super:END()

   RETURN Nil


STATIC FUNCTION __GetFocus( oCtrl )
   LOCAL xRet

   IF ValType( oCtrl:bGetFocus ) == "B"
      xRet := Eval( oCtrl:bGetFocus, oCtrl )
   ENDIF

   RETURN xRet


STATIC FUNCTION __KillFocus( oCtrl )
   LOCAL xRet

   IF ValType( oCtrl:bKillFocus ) == "B"
      xRet := Eval( oCtrl:bKillFocus, oCtrl )
   ENDIF

   RETURN xRet
