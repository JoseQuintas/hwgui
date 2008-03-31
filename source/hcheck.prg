/*
 * $Id: hcheck.prg,v 1.16 2008-03-31 15:34:52 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckButton class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define BST_INDETERMINATE    2

CLASS HCheckButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA bSetGet
   DATA value

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,oFont,bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus )
   METHOD Init()
   METHOD Refresh()
   METHOD Disable()
   METHOD Enable()
   METHOD SetValue( lValue )  INLINE SendMessage(::handle,BM_SETCHECK,Iif(lValue,1,0),0)
   METHOD GetValue()          INLINE ( SendMessage(::handle,BM_GETCHECK,0,0)==1 )

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), BS_NOTIFY+BS_PUSHBUTTON+BS_AUTOCHECKBOX+WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::title   := cCaption
   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="L",.F.,vari )
   ::bSetGet := bSetGet

   ::Activate()

   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_CLICKED,::id,{|o,id|__Valid(o:FindControl(id))} )
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ENDIF

Return Self

METHOD Activate CLASS HCheckButton
   IF ::oParent:handle != 0
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,oFont,bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus ) CLASS HCheckButton


   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="L",.F.,vari )
   ::bSetGet := bSetGet

   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_CLICKED,::id,{|o,id|__Valid(o:FindControl(id))} )
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ENDIF

Return Self

METHOD Init() CLASS HCheckButton
   IF !::lInit
      Super:Init()
      IF ::value
         SendMessage(::handle,BM_SETCHECK,1,0)
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HCheckButton
Local var

   IF ::bSetGet != Nil
       var := Eval( ::bSetGet,,nil )
       ::value := Iif( var==Nil,.F.,var )
   ENDIF

   SendMessage(::handle,BM_SETCHECK,Iif(::value,1,0),0)

Return Nil

METHOD Disable() CLASS HCheckButton

   Super:Disable()
   SendMessage( ::handle,BM_SETCHECK,BST_INDETERMINATE,0 )

Return Nil

METHOD Enable() CLASS HCheckButton

   Super:Enable()
   SendMessage(::handle,BM_SETCHECK,Iif(::value,1,0),0)

Return Nil

Static Function __Valid( oCtrl )
Local l := SendMessage( oCtrl:handle,BM_GETCHECK,0,0 )

   IF l == BST_INDETERMINATE
      CheckDlgButton( oCtrl:oParent:handle, oCtrl:id, .F. )
      SendMessage( oCtrl:handle,BM_SETCHECK,0,0 )
      oCtrl:value := .F.
   ELSE
      oCtrl:value := ( l == 1 )
   ENDIF

   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. !Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl )
      SetFocus( oCtrl:handle )
   ENDIF

Return .T.

Static Function __When( oCtrl )
Local res

   oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         GetSkip( oCtrl:oParent,oCtrl:handle )
      ENDIF
      Return res
   ENDIF

Return .T.

