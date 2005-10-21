/*
 *$Id: hcheck.prg,v 1.8 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HCheckButton class 
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HCheckButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA bSetGet
   DATA value

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor,bGFocus )
   METHOD Activate()
   METHOD Init()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Refresh()
   METHOD SetValue( lValue )  INLINE hwg_CheckButton( ::handle,lValue )
   METHOD GetValue()  INLINE ::value := hwg_IsButtonChecked( ::handle )

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor,bGFocus ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), BS_AUTO3STATE+WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctoolt,tcolor,bcolor )

   ::title   := cCaption
   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="L",.F.,vari )
   ::bSetGet := bSetGet

   ::Activate()

   ::bLostFocus := bClick
   ::bGetFocus  := bGFocus

   hwg_SetSignal( ::handle,"clicked",WM_LBUTTONUP,0,0 )
   // ::oParent:AddEvent( BN_CLICKED,::id,{|o,id|__Valid(o:FindControl(id))} )
   IF bGFocus != Nil
      hwg_SetSignal( ::handle,"enter",BN_SETFOCUS,0,0 )
      // ::oParent:AddEvent( BN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ENDIF

Return Self

METHOD Activate CLASS HCheckButton

   IF !Empty(::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      SetWindowObject( ::handle,Self )
      ::Init()
   ENDIF
Return Nil

METHOD Init() CLASS HCheckButton
   IF !::lInit
      Super:Init()
      IF ::value
         hwg_CheckButton( ::handle,.T. )
      ENDIF
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HCheckButton

   IF msg == WM_LBUTTONUP
      __Valid( Self )
   ELSEIF msg == BN_SETFOCUS
      __When( Self )
   ENDIF
Return Nil

METHOD Refresh() CLASS HCheckButton
Local var

   IF ::bSetGet != Nil
       var := Eval( ::bSetGet,,nil )
       ::value := Iif( var==Nil,.F.,var ) 
   ENDIF

   hwg_CheckButton( ::handle,::value )
Return Nil

Static Function __Valid( oCtrl )
Local res

   oCtrl:value := hwg_IsButtonChecked( oCtrl:handle )

   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet,oCtrl:value, oCtrl )
   ENDIF
   IF oCtrl:bLostFocus != Nil .AND. ;
         Valtype( res := Eval( oCtrl:bLostFocus, oCtrl:value, oCtrl ) ) == "L" ;
	 .AND. !res
      SetFocus( oCtrl:handle )
   ENDIF

Return .T.

Static Function __When( oCtrl )
Local res

   oCtrl:Refresh()

   IF oCtrl:bGetFocus != Nil 
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF Valtype(res) == "L" .AND. !res
         GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.
