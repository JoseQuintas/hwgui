/*
 *$Id: hupdown.prg,v 1.5 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HUpDown class 
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define UDS_SETBUDDYINT     2
#define UDS_ALIGNRIGHT      4

CLASS HUpDown INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"
   DATA bSetGet
   DATA value
   DATA nLower INIT 0
   DATA nUpper INIT 999
   DATA nUpDownWidth INIT 12
   DATA lChanged    INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctoolt,tcolor,bcolor,nUpDWidth,nLower,nUpper )
   METHOD Activate()
   METHOD Refresh()

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctoolt,tcolor,bcolor,   ;
         nUpDWidth,nLower,nUpper ) CLASS HUpDown

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctoolt,tcolor,bcolor )

   IF vari != Nil
      IF Valtype(vari) != "N"
         vari := 0
         Eval( bSetGet,vari )
      ENDIF
      ::title := Str(vari)
   ENDIF
   ::bSetGet := bSetGet

   IF nLower != Nil ; ::nLower := nLower ; ENDIF
   IF nUpper != Nil ; ::nUpper := nUpper ; ENDIF
   IF nUpDWidth != Nil ; ::nUpDownWidth := nUpDWidth ; ENDIF

   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGFocus
      ::bLostFocus := bLFocus
      ::oParent:AddEvent( EN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
      ::oParent:AddEvent( EN_KILLFOCUS,::id,{|o,id|__Valid(o:FindControl(id))} )
   ELSE
      IF bGfocus != Nil
         ::oParent:AddEvent( EN_SETFOCUS,::id,bGfocus )
      ENDIF
      IF bLfocus != Nil
         ::oParent:AddEvent( EN_KILLFOCUS,::id,bLfocus )
      ENDIF
   ENDIF

Return Self

METHOD Activate CLASS HUpDown
   IF !Empty(::oParent:handle )
      ::handle := CreateUpDownControl( ::oParent:handle, ;
          ::nLeft,::nTop,::nWidth,::nHeight,Val(::title),::nLower,::nUpper )
      ::Init()
   ENDIF
Return Nil

METHOD Refresh()  CLASS HUpDown
Local vari

   IF ::bSetGet != Nil
      ::value := Eval( ::bSetGet )
      IF Str(::value) != ::title
         ::title := Str( ::value )
         hwg_SetUpDown( ::handle, ::value )
      ENDIF
   ELSE
      hwg_SetUpDown( ::handle, Val(::title) )
   ENDIF

Return Nil

Static Function __When( oCtrl )

   oCtrl:Refresh()
   IF oCtrl:bGetFocus != Nil 
      Return Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet ), oCtrl )
   ENDIF

Return .T.

Static Function __Valid( oCtrl )

   oCtrl:value := hwg_SetUpDown( oCtrl:handle )
   oCtrl:title := Str( oCtrl:value )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl ) .OR. ;
         oCtrl:value > oCtrl:nUpper .OR. oCtrl:value < oCtrl:nLower
      SetFocus( oCtrl:handle )
   ENDIF

Return .T.
