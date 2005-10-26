/*
 * $Id: hcheck.prg,v 1.11 2005-10-26 07:43:26 omm Exp $
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

#define BM_GETCHECK        240   // 0x00F0
#define BM_SETCHECK        241   // 0x00F1
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
   METHOD SetValue( lValue )  INLINE CheckDlgButton( ::oParent:handle,::id,lValue )
   METHOD GetValue()          INLINE IsDlgButtonChecked( ::oParent:handle, ::id )

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus ) CLASS HCheckButton

   nStyle   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), BS_AUTO3STATE+WS_TABSTOP )
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

   CheckDlgButton( ::oParent:handle,::id,::value )
Return Nil

METHOD Disable() CLASS HCheckButton

   Super:Disable()
   SendMessage( ::handle,BM_SETCHECK,BST_INDETERMINATE,0 )

Return Nil

METHOD Enable() CLASS HCheckButton

   Super:Enable()
   CheckDlgButton( ::oParent:handle,::id,::value )

Return Nil

Static Function __Valid( oCtrl )
Local l := SendMessage( oCtrl:handle,BM_GETCHECK,0,0 )

   IF l == BST_INDETERMINATE
      CheckDlgButton( oCtrl:oParent:handle, oCtrl:id, .F. )
   ENDIF
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

   IF oCtrl:bGetFocus != Nil
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet,, oCtrl ), oCtrl )
      IF !res
         GetSkip( oCtrl:oParent,oCtrl:handle,1 )
      ENDIF
      Return res
   ENDIF

Return .T.

