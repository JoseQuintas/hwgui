/*
 *$Id: hradio.prg,v 1.4 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HRadioButton class
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
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

   METHOD New( vari,bSetGet )
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
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := ctoolt
   ::tcolor  := tcolor
   /*
   IF tColor != Nil .AND. bColor == Nil
      bColor := GetSysColor( COLOR_3DFACE )
   ENDIF
   ::bcolor  := bcolor
   IF bColor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF
   */

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
      ::handle := CreateButton( ::oParent:handle, @groupHandle, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::oGroup:handle := groupHandle
      SetWindowObject( ::handle,Self )
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
