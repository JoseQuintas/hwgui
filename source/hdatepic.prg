/*
 * $Id: hdatepic.prg,v 1.12 2005-10-26 07:43:26 omm Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDatePicker class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define DTN_DATETIMECHANGE    -759
#define DTN_CLOSEUP           -753
#define DTM_GETMONTHCAL       4104   // 0x1008
#define NM_KILLFOCUS          -8
#define NM_SETFOCUS           -7

CLASS HDatePicker INHERIT HControl

   CLASS VAR winclass   INIT "SYSDATETIMEPICK32"
   DATA bSetGet
   DATA value
   DATA bChange

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bGfocus,bLfocus,bChange,ctooltip,tcolor,bcolor )
   METHOD Activate()
   METHOD Init()
   METHOD Refresh()

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
                  oFont,bInit,bGfocus,bLfocus,bChange,ctooltip,tcolor,bcolor ) CLASS HDatePicker

   nStyle := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  ,,ctooltip,tcolor,bcolor )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="D",CTOD(SPACE(8)),vari )
   ::bSetGet := bSetGet
   ::bChange := bChange

   HWG_InitCommonControlsEx()
   ::Activate()

   IF bGfocus != Nil
      ::oParent:AddEvent( NM_SETFOCUS,::id,bGfocus,.T. )
   ENDIF
   ::oParent:AddEvent( DTN_DATETIMECHANGE,::id,{|o,id|__Change(o:FindControl(id),DTN_DATETIMECHANGE)},.T. )
   ::oParent:AddEvent( DTN_CLOSEUP,::id,{|o,id|__Change(o:FindControl(id),DTN_CLOSEUP)},.T. )
   IF bSetGet != Nil
      ::bLostFocus := bLFocus
      ::oParent:AddEvent( NM_KILLFOCUS,::id,{|o,id|__Valid(o:FindControl(id))},.T. )
   ELSE
      IF bLfocus != Nil
         ::oParent:AddEvent( NM_KILLFOCUS,::id,bLfocus,.T. )
      ENDIF
   ENDIF

Return Self

METHOD Activate CLASS HDatePicker
   IF ::oParent:handle != 0
      ::handle := CreateDatePicker( ::oParent:handle, ::id, ;
                  ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ::Init()
   ENDIF
Return Nil

METHOD Init() CLASS HDatePicker
   IF !::lInit
      Super:Init()
      IF !Empty( ::value )
         SetDatePicker( ::handle,::value )
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HDatePicker
   IF ::bSetGet != Nil
      ::value := Eval( ::bSetGet,,nil )
   ENDIF

   IF ! Empty(::value)
      SetDatePicker( ::handle,::value )
   ENDIF
Return Nil

Static Function __Change( oCtrl, nMess )

   IF ( nMess == DTN_DATETIMECHANGE .AND. ;
         SendMessage( oCtrl:handle,DTM_GETMONTHCAL,0,0 ) == 0 ) .OR. ;
         nMess == DTN_CLOSEUP
      oCtrl:value := GetDatePicker( oCtrl:handle )
      IF oCtrl:bSetGet != Nil
         Eval( oCtrl:bSetGet,oCtrl:value, oCtrl )
      ENDIF
      IF oCtrl:bChange != Nil
         Eval( oCtrl:bChange,oCtrl:value,oCtrl )
      ENDIF
   ENDIF
Return .T.

Static Function __Valid( oCtrl )

   oCtrl:value := GetDatePicker( oCtrl:handle )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl )
      // SetFocus( oCtrl:handle )
      Return .F.
   ENDIF

Return .T.
