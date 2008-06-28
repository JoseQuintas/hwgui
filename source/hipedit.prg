/*
 * $Id: hipedit.prg,v 1.11 2008-06-28 15:17:53 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HTab class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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

   METHOD New( oWndParent,nId,aValue,bSetGet, nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bGetFocus,bKillFocus )
   METHOD Activate()
   METHOD Init()
   METHOD SetValue( aValue )
   METHOD GetValue(  )
   METHOD Clear(  )
   METHOD End()

   HIDDEN:
     DATA  aValue           // Valor atual

ENDCLASS

METHOD New( oWndParent,nId,aValue,bSetGet, nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bGetFocus,bKillFocus ) CLASS HIPedit

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont )

   ::title   := ""

   ::bSetGet := bSetGet
   DEFAULT aValue := {0,0,0,0}
   ::aValue  := aValue
   ::bGetFocus  := bGetFocus
   ::bKillFocus := bKillFocus

   HWG_InitCommonControlsEx()
   ::Activate()


   IF Valtype(bSetGet) == "B"
      // WriteLog("hIpEdit:New() -> bSetGet == Block")
      ::oParent:AddEvent( IPN_FIELDCHANGED,self,{|o,id|__Valid(o:FindControl(id))} ,.t.,"onChange")
   ELSE
      // WriteLog("hIpEdit:New() -> bSetGet != Block")
      IF Valtype(::bLostFocus) == "B"
         ::oParent:AddEvent( IPN_FIELDCHANGED,self,::bLostFocus, .t.,"onChange" )
      ENDIF
   ENDIF

   // Notificacoes de Ganho e perda de foco
   ::oParent:AddEvent( EN_SETFOCUS , self, {|o,id|__GetFocus(o:FindControl(id))},,"onGotFocus" )
   ::oParent:AddEvent( EN_KILLFOCUS, self, {|o,id|__KillFocus(o:FindControl(id))},,"onLostFocus" )


Return Self

METHOD Activate CLASS HIPedit
   IF !empty( ::oParent:handle ) 
      ::handle := InitIPAddress ( ::oParent:handle, ::id, ::style ,;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF
Return Nil

METHOD Init() CLASS HIPedit

   IF !::lInit
      Super:Init()
      ::SetValue(::aValue)
      ::lInit := .t.
   ENDIF

Return Nil

METHOD SetValue( aValue ) CLASS HIPedit
   SETIPADDRESS(::handle , aValue[1], aValue[2], aValue[3], aValue[4])
   ::aValue := aValue
Return Nil


METHOD GetValue( ) CLASS HIPedit
   ::aValue := GETIPADDRESS(::handle)
Return (::aValue)

METHOD Clear( ) CLASS HIPedit
   CLEARIPADDRESS(::handle)
   ::aValue := { 0,0,0,0 }
Return (::aValue)


METHOD End() CLASS HIPedit

   // Nothing to do here, yet!
   Super:End()

Return Nil


Static Function __Valid( oCtrl )
   // WriteLog("Entrando em valid do IP")

   // oCtrl:aValue := oCtrl:GetValue()

   IF Valtype(oCtrl:bSetGet) == "B"
      // Eval( oCtrl:bSetGet,oCtrl:aValue )
      Eval( oCtrl:bSetGet, oCtrl:GetValue() )
   ENDIF

   IF Valtype(oCtrl:bLostFocus) == "B" .AND. !Eval( oCtrl:bLostFocus, oCtrl:aValue, oCtrl )
      SetFocus( oCtrl:handle )
   ENDIF

Return .T.

Static Function __GetFocus( oCtrl )
   Local xRet

   IF Valtype(oCtrl:bGetFocus) == "B"
      xRet := Eval( oCtrl:bGetFocus,oCtrl )
   ENDIF

Return xRet


Static Function __KillFocus( oCtrl )
   Local xRet

   IF Valtype(oCtrl:bKillFocus) == "B"
      xRet := Eval( oCtrl:bKillFocus,oCtrl )
   ENDIF

Return xRet
