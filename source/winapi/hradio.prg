/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HRadioButton class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

   // #define BM_GETCHECK        0x00F0

CLASS HRadioGroup INHERIT HObject

   CLASS VAR oGroupCurrent
   DATA aButtons
   DATA value  INIT 1
   DATA bSetGet

   METHOD New( vari, bSetGet )
   METHOD EndGroup( nSelected )
   METHOD SetValue( nValue )
   METHOD GetValue()  INLINE ::value
   METHOD Refresh()   INLINE iif( ::bSetGet != Nil, ::SetValue( Eval(::bSetGet ) ), .T. )

ENDCLASS

METHOD New( vari, bSetGet ) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := {}

   IF vari != Nil
      IF ValType( vari ) == "N"
         ::value := vari
      ENDIF
      ::bSetGet := bSetGet
   ENDIF

   RETURN Self

METHOD EndGroup( nSelected )  CLASS HRadioGroup
   LOCAL nLen

   IF ::oGroupCurrent != Nil .AND. ( nLen := Len( ::oGroupCurrent:aButtons ) ) > 0

      nSelected := iif( nSelected != Nil .AND. nSelected <= nLen .AND. nSelected > 0, ;
         nSelected, ::oGroupCurrent:value )
      IF nSelected != 0 .AND. nSelected <= nlen
         IF !Empty( ::oGroupCurrent:aButtons[nlen]:handle )
            hwg_Checkradiobutton( ::oGroupCurrent:aButtons[nlen]:oParent:handle, ;
               ::oGroupCurrent:aButtons[1]:id,    ;
               ::oGroupCurrent:aButtons[nLen]:id, ;
               ::oGroupCurrent:aButtons[nSelected]:id )
         ELSE
            ::oGroupCurrent:aButtons[nLen]:bInit :=                      ;
               &( "{|o|hwg_Checkradiobutton(o:oParent:handle," +         ;
               LTrim( Str( ::oGroupCurrent:aButtons[1]:id ) ) + "," +    ;
               LTrim( Str( ::oGroupCurrent:aButtons[nLen]:id ) ) + "," + ;
               LTrim( Str( ::oGroupCurrent:aButtons[nSelected]:id ) ) + ")}" )
         ENDIF
      ENDIF
   ENDIF
   ::oGroupCurrent := Nil

   RETURN Nil

METHOD SetValue( nValue )  CLASS HRadioGroup
   LOCAL nLen

   IF ( nLen := Len( ::aButtons ) ) > 0 .AND. nValue > 0 .AND. nValue <= nLen
      hwg_Checkradiobutton( ::aButtons[nlen]:oParent:handle, ;
         ::aButtons[1]:id,    ;
         ::aButtons[nLen]:id, ;
         ::aButtons[nValue]:id )
      ::value := nValue
   ENDIF

   RETURN Nil

CLASS HRadioButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA  oGroup

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, lTransp )
   METHOD Activate()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, lInit, ctooltip, tcolor, bcolor )
   METHOD GetValue()          INLINE ( hwg_Sendmessage( ::handle,BM_GETCHECK,0,0 ) == 1 )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
      bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, lTransp ) CLASS HRadioButton

   ::oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   ::id      := iif( nId == Nil, ::NewId(), nId )
   ::title   := cCaption
   ::oGroup  := HRadioGroup():oGroupCurrent
   IF !Empty( lTransp )
      ::extStyle := WS_EX_TRANSPARENT
   ENDIF
   ::style   := Hwg_BitOr( iif( nStyle == Nil,0,nStyle ), BS_AUTORADIOBUTTON + ;
      WS_CHILD + WS_VISIBLE + WS_TABSTOP + ;
      iif( ::oGroup != Nil .AND. Empty( ::oGroup:aButtons ), WS_GROUP, 0 ) )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   IF ValType( bSize ) == "N"
      ::Anchor := bSize
   ELSE
      ::bSize  := bSize
   ENDIF
   ::bPaint  := bPaint
   ::tooltip := ctooltip
   ::tcolor  := tcolor
   IF tColor != Nil .AND. bColor == Nil
      bColor := hwg_Getsyscolor( COLOR_3DFACE )
   ENDIF
   ::bcolor  := bcolor
   IF bColor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF

   ::Activate()
   ::oParent:AddControl( Self )
   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      ::oParent:AddEvent( 0, ::id, bClick )
   ENDIF
   IF ::oGroup != Nil
      AAdd( ::oGroup:aButtons, Self )
      ::bLostFocus := bClick
      ::oParent:AddEvent( BN_CLICKED, ::id, { |o, id|__Valid( o:FindControl(id ) ) } )
   ENDIF

   RETURN Self

METHOD Activate CLASS HRadioButton

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ;
         ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF

   RETURN Nil

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor ) CLASS HRadioButton

   ::oParent := iif( oWndParent == Nil, ::oDefaultParent, oWndParent )
   ::id      := nId
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::oFont   := oFont
   ::bInit   := bInit
   IF ValType( bSize ) == "N"
      ::Anchor := bSize
   ELSE
      ::bSize  := bSize
   ENDIF
   ::bPaint  := bPaint
   ::tooltip := ctooltip
   ::tcolor  := tcolor
   IF tColor != Nil .AND. bColor == Nil
      bColor := hwg_Getsyscolor( COLOR_3DFACE )
   ENDIF
   ::bcolor  := bcolor
   IF bColor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF

   ::oParent:AddControl( Self )
   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      ::oParent:AddEvent( 0, ::id, bClick )
   ENDIF
   IF ::oGroup != Nil
      AAdd( ::oGroup:aButtons, Self )
      ::bLostFocus := bClick
      ::oParent:AddEvent( BN_CLICKED, ::id, { |o, id|__Valid( o:FindControl(id ) ) } )
   ENDIF

   RETURN Self

STATIC FUNCTION __Valid( oCtrl )

   oCtrl:oGroup:value := Ascan( oCtrl:oGroup:aButtons, { |o|o:id == oCtrl:id } )
   IF oCtrl:oGroup:bSetGet != Nil
      Eval( oCtrl:oGroup:bSetGet, oCtrl:oGroup:value )
   ENDIF
   IF oCtrl:bLostFocus != Nil
      Eval( oCtrl:bLostFocus, oCtrl:oGroup:value, oCtrl )
   ENDIF

   RETURN .T.
