/*
 * $Id: hcheck.prg,v 1.6 2004-05-16 16:47:15 lculik Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCheckButton class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "HBClass.ch"
#include "guilib.ch"

CLASS HCheckButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA bSetGet
   DATA bWhen
   DATA value

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor,bwhen )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,vari,bSetGet,oFont,bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor,bwhen )
   METHOD Init()
   METHOD Refresh()     

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor,bwhen ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), BS_AUTOCHECKBOX+WS_TABSTOP )
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctoolt,tcolor,bcolor )

   ::title   := cCaption
   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="L",.F.,vari )
   ::bSetGet := bSetGet

   ::Activate()

   IF bSetGet != Nil
      ::bLostFocus := bClick
      ::bWhen := bWhen

      ::oParent:AddEvent( BN_CLICKED,::id,{|o,id|__Valid(o:FindControl(id))} )
      ::oParent:AddEvent( BN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ELSE
      IF bClick != Nil
         ::oParent:AddEvent( BN_CLICKED,::id,bClick )
      ENDIF
   ENDIF
   if bWhen != Nil
      ::oParent:AddEvent( BN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   endif
Return Self

METHOD Activate CLASS HCheckButton
   IF ::oParent:handle != 0
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,vari,bSetGet,oFont,bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor,bwhen ) CLASS HCheckButton


   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctoolt,tcolor,bcolor )

   ::value   := Iif( vari==Nil .OR. Valtype(vari)!="L",.F.,vari )
   ::bSetGet := bSetGet

   IF bSetGet != Nil
      ::bLostFocus := bClick
      ::bWhen := bWhen
      ::oParent:AddEvent( BN_CLICKED,::id,{|o,id|__Valid(o:FindControl(id))} )
      ::oParent:AddEvent( BN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   ELSE
      IF bClick != Nil
         ::oParent:AddEvent( BN_CLICKED,::id,bClick )
      ENDIF
   ENDIF
   if bWhen != Nil
      ::oParent:AddEvent( BN_SETFOCUS,::id,{|o,id|__When(o:FindControl(id))} )
   endif


Return Self

METHOD Init() CLASS HCheckButton
   IF !::lInit
      Super:Init()
      IF ::value
         CheckDlgButton( ::oParent:handle,::id,.T. )
      ENDIF
   ENDIF
Return Nil

METHOD Refresh() CLASS HCheckButton
   Local var
   IF ::bSetGet != Nil
       var := Eval( ::bSetGet,,nil )
       ::value := Iif( var==Nil,.F.,var ) 
   ENDIF

   CheckDlgButton( ::oParent:handle,::id,Iif( ::value==Nil,.F.,::value) )
Return Nil

Static Function __Valid( oCtrl )

   oCtrl:value := IsDlgButtonChecked( oCtrl:oParent:handle, oCtrl:id )

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

   IF oCtrl:bWhen != Nil 
      res := Eval( oCtrl:bWhen, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )

      IF !res
         GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.


