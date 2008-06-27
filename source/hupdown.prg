/*
 * $Id: hupdown.prg,v 1.10 2008-06-27 10:38:59 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HUpDown class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
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
   DATA hUpDown, idUpDown, styleUpDown
   DATA nLower INIT 0
   DATA nUpper INIT 999
   DATA nUpDownWidth INIT 12
   DATA lChanged    INIT .F.

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip,tcolor,bcolor,nUpDWidth,nLower,nUpper )
   METHOD Activate()
   METHOD Init()
   METHOD Refresh()

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
         oFont,bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip,tcolor,bcolor,   ;
         nUpDWidth,nLower,nUpper ) CLASS HUpDown

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::idUpDown := ::NewId()
   IF Valtype(vari) != "N"
      vari := 0
      Eval( bSetGet,vari )
   ENDIF
   ::title := Str(vari)
   ::bSetGet := bSetGet

   ::styleUpDown := UDS_SETBUDDYINT+UDS_ALIGNRIGHT

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
   IF !empty( ::oParent:handle ) 
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD Init()  CLASS HUpDown
   IF !::lInit
      Super:Init()
      ::hUpDown := CreateUpDownControl( ::oParent:handle, ::idUpDown, ;
          ::styleUpDown,0,0,::nUpDownWidth,0,::handle,::nUpper,::nLower,Val(::title) )
   ENDIF
Return Nil

METHOD Refresh()  CLASS HUpDown

   IF ::bSetGet != Nil
      ::value := Eval( ::bSetGet )
      IF Str(::value) != ::title
         ::title := Str( ::value )
         SetUpDown( ::hUpDown, ::value )
      ENDIF
   ELSE
      SetUpDown( ::hUpDown, Val(::title) )
   ENDIF

Return Nil

Static Function __When( oCtrl )
Local res, oParent

   oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
		IF ! res
         oParent := ParentGetDialog(oCtrl)
         IF oParent:nSkip > 0
            IF oCtrl == ATail(oParent:GetList)
               oParent:nSkip := -1
            ENDIF
         ELSE
            IF oCtrl == oParent:getList[1]
               oParent:nSkip := 1
            ENDIF
         ENDIF
         GetSkip( oCtrl:oParent, oCtrl:handle )
      ENDIF
      RETURN res
   ENDIF

Return .T.

Static Function __Valid( oCtrl )

   oCtrl:title := GetEditText( oCtrl:oParent:handle, oCtrl:id )
   oCtrl:value := Val( Ltrim( oCtrl:title ) )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl ) .OR. ;
         oCtrl:value > oCtrl:nUpper .OR. oCtrl:value < oCtrl:nLower
      SetFocus( oCtrl:handle )
   ENDIF

Return .T.
