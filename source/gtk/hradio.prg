/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HRadioButton class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HRadioGroup INHERIT HObject
   CLASS VAR oGroupCurrent
   DATA handle INIT 0
   DATA aButtons
   DATA value  INIT 1
   DATA bSetGet
   DATA oHGroup

   METHOD New( vari,bSetGet )
   METHOD NewRg( oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, tcolor, bColor )
   METHOD EndGroup( nSelected )
   METHOD SetValue( nValue )
   METHOD Refresh()   INLINE Iif( ::bSetGet!=Nil,::SetValue(Eval(::bSetGet)),.T. )
ENDCLASS

METHOD New( vari,bSetGet ) CLASS HRadioGroup
   ::oGroupCurrent := Self
   ::aButtons := {}

   IF vari != Nil
      IF Valtype( vari ) == "N"
         ::value := vari
      ENDIF
      ::bSetGet := bSetGet
   ENDIF

Return Self

METHOD NewRg( oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, tcolor, bColor ) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := {}

   ::oHGroup := HGroup():New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
         oFont, bInit, bSize, , tcolor, bColor )

   IF vari != NIL
      IF Valtype( vari ) == "N"
         ::value := vari
      ENDIF
      ::bSetGet := bSetGet
   ENDIF

   RETURN Self

METHOD EndGroup( nSelected )  CLASS HRadioGroup
Local nLen

   IF ::oGroupCurrent != Nil .AND. ( nLen:=Len(::oGroupCurrent:aButtons) ) > 0

      nSelected := Iif( nSelected!=Nil.AND.nSelected<=nLen.AND.nSelected > 0, ;
                        nSelected, ::oGroupCurrent:value )
      IF nSelected != 0 .AND. nSelected <= nlen
         hwg_CheckButton( ::oGroupCurrent:aButtons[nSelected]:handle,.T. )
      ENDIF
   ENDIF
   ::oGroupCurrent := Nil
Return Nil

METHOD SetValue( nValue )  CLASS HRadioGroup
Local nLen

   IF ( nLen:=Len(::aButtons) ) > 0 .AND. nValue > 0 .AND. nValue <= nLen
      hwg_CheckButton( ::aButtons[nValue]:handle,.T. )
   ENDIF
Return Nil


CLASS HRadioButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA  oGroup

   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor )
   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctoolt,tcolor,bcolor ) CLASS HRadioButton

   ::oParent := Iif( oWndParent==Nil, ::oDefaultParent, oWndParent )
   ::id      := Iif( nId==Nil,::NewId(), nId )
   ::title   := cCaption
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::style   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ), BS_AUTORADIOBUTTON+;
                     WS_CHILD+WS_VISIBLE+ ;
                     Iif( ::oGroup != Nil .AND. Empty( ::oGroup:aButtons ),WS_GROUP,0 ) )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   IF Valtype( bSize ) == "N"
      ::Anchor := bSize
   ELSE
      ::bSize   := bSize
   ENDIF
   ::bPaint  := bPaint
   ::tooltip := ctoolt
   ::tcolor  := tcolor

   ::Activate()
   ::oParent:AddControl( Self )
   ::bLostFocus := bClick
   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      hwg_SetSignal( ::handle,"released",WM_LBUTTONUP,0,0 )
   ENDIF
   IF ::oGroup != Nil
      Aadd( ::oGroup:aButtons,Self )
      IF ::oGroup:bSetGet != Nil
         hwg_SetSignal( ::handle,"released",WM_LBUTTONUP,0,0 )	 
      ENDIF
   ENDIF

Return Self

METHOD Activate CLASS HRadioButton
Local groupHandle := ::oGroup:handle

   IF !Empty(::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, @groupHandle, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::oGroup:handle := groupHandle
      hwg_Setwindowobject( ::handle,Self )
      ::Init()
   ENDIF
Return Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HRadioButton

   IF msg == WM_LBUTTONUP
      IF ::oGroup:bSetGet == Nil
         Eval( ::bLostFocus, ::oGroup:value, Self )
      ELSE
         __Valid( Self )
      ENDIF
   ENDIF
Return Nil


Static Function __Valid( oCtrl )

   oCtrl:oGroup:value := Ascan( oCtrl:oGroup:aButtons,{|o|o:id==oCtrl:id} )
   IF oCtrl:oGroup:bSetGet != Nil
      Eval( oCtrl:oGroup:bSetGet,oCtrl:oGroup:value )
   ENDIF
   IF oCtrl:bLostFocus != Nil
      Eval( oCtrl:bLostFocus, oCtrl:oGroup:value, oCtrl )
   ENDIF

Return .T.
