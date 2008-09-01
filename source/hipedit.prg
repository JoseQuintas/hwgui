/*
 * $Id: hipedit.prg,v 1.12 2008-09-01 19:00:19 mlacecilia Exp $
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
   DATA lnoValid   INIT .F.

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


   *IF bSetGet != Nil                                           
      /*
      ::bGetFocus := bGFocus
      ::bLostFocus := bLFocus
      ::oParent:AddEvent( EN_SETFOCUS,self,{|o,id|__When(o:FindControl(id))},.t.,"onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS,self,{|o,id|__Valid(o:FindControl(id))},.t.,"onLostFocus" )
      ::oParent:AddEvent( IPN_FIELDCHANGED,self,{|o,id|__Valid(o:FindControl(id))} ,.t.,"onChange")
      */
	*ELSE
      IF bGetfocus != Nil
         ::lnoValid := .T.
        * ::oParent:AddEvent( EN_SETFOCUS,self,::bGetfocus,.t.,"onGotFocus" )
      ENDIF
      IF bKillfocus != Nil
        * ::oParent:AddEvent( EN_KILLFOCUS,self,::bKillfocus,.t.,"onLostFocus" )
         ::oParent:AddEvent( IPN_FIELDCHANGED,self,::bKillFocus, .t.,"onChange" )
      ENDIF
  * ENDIF

   // Notificacoes de Ganho e perda de foco
   *::oParent:AddEvent( IPN_FIELDCHANGED,self,::bKillFocus, .t.,"onChange" )
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


Static Function __GetFocus( oCtrl )
   Local xRet

  IF !CheckFocus(oCtrl, .f.)
	   RETURN .t.
	ENDIF

   IF Valtype(oCtrl:bGetFocus) == "B"
      octrl:oparent:lSuspendMsgsHandling := .T.
			octrl:lnoValid := .T.
      xRet := Eval( oCtrl:bGetFocus,oCtrl )
      octrl:oparent:lSuspendMsgsHandling := .F.
 			octrl:lnoValid := xRet
   ENDIF

Return xRet


Static Function __KillFocus( oCtrl )
   Local xRet

   IF !CheckFocus(oCtrl, .t.) .or. oCtrl:lNoValid
	   RETURN .t.
	ENDIF

   IF Valtype(oCtrl:bKillFocus) == "B"
      octrl:oparent:lSuspendMsgsHandling := .T.
      xRet := Eval( oCtrl:bKillFocus,oCtrl )
     octrl:oparent:lSuspendMsgsHandling := .F.
   ENDIF

Return xRet
