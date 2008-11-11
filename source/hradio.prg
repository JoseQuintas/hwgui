/*
 * $Id: hradio.prg,v 1.16 2008-11-11 04:49:14 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HRadioButton class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HRadioGroup INHERIT HObject
   CLASS VAR oGroupCurrent
   DATA aButtons
   DATA value  INIT 1
   DATA bSetGet

   METHOD New( vari,bSetGet )
   METHOD EndGroup( nSelected )
   METHOD SetValue( nValue )
   METHOD GetValue()  INLINE ::value
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
         IF ::oGroupCurrent:aButtons[nlen]:handle > 0
            CheckRadioButton( ::oGroupCurrent:aButtons[nlen]:oParent:handle, ;
                  ::oGroupCurrent:aButtons[1]:id,    ;
                  ::oGroupCurrent:aButtons[nLen]:id, ;
                  ::oGroupCurrent:aButtons[nSelected]:id )
         ELSE
            ::oGroupCurrent:aButtons[nLen]:bInit :=                     ;
                &( "{|o|CheckRadioButton(o:oParent:handle," +           ;
                  Ltrim(Str(::oGroupCurrent:aButtons[1]:id)) + "," +    ;
                  Ltrim(Str(::oGroupCurrent:aButtons[nLen]:id)) + "," + ;
                  Ltrim(Str(::oGroupCurrent:aButtons[nSelected]:id)) + ")}" )
         ENDIF
      ENDIF
   ENDIF
   ::oGroupCurrent := Nil
Return Nil

METHOD SetValue( nValue )  CLASS HRadioGroup
Local nLen

   IF ( nLen:=Len(::aButtons) ) > 0 .AND. nValue > 0 .AND. nValue <= nLen
      CheckRadioButton( ::aButtons[nlen]:oParent:handle, ;
            ::aButtons[1]:id,    ;
            ::aButtons[nLen]:id, ;
            ::aButtons[nValue]:id )
      ::value := nValue
      IF ::bSetGet != Nil
         Eval( ::bSetGet,::value )
      ENDIF   
   ENDIF
   
Return Nil


CLASS HRadioButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA  oGroup
   DATA lWhen  INIT .F.
   
   METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus, lTransp )
   METHOD Activate()
   METHOD Redefine( oWnd,nId,oFont,bInit,bSize,bPaint,bClick,lInit,ctooltip,tcolor,bcolor )
   METHOD GetValue()          INLINE ( SendMessage( ::handle,BM_GETCHECK,0,0)==1 )
   METHOD Notify(lParam )
ENDCLASS

METHOD New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,cCaption,oFont, ;
                  bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus, lTransp ) CLASS HRadioButton

   ::oParent := Iif( oWndParent==Nil, ::oDefaultParent, oWndParent )
   ::id      := Iif( nId==Nil,::NewId(), nId )
   ::title   := cCaption
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::style   := Hwg_BitOr( Iif( nStyle==Nil,0,nStyle ),BS_RADIOBUTTON+; // BS_AUTORADIOBUTTON+;
                     WS_CHILD+WS_VISIBLE + BS_NOTIFY +;
                     Iif( ::oGroup != Nil .AND. Empty( ::oGroup:aButtons ),WS_GROUP ,0))
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := ctooltip
   /*
   ::tcolor  := tcolor
   IF tColor != Nil .AND. bColor == Nil
      bColor := GetSysColor( COLOR_3DFACE )
   ENDIF
   */
   IF (lTransp != NIL .AND. lTransp) 
      bcolor := ::oParent:bcolor
   ENDIF
   ::bcolor  := bcolor
	 ::tColor  := tcolor
   IF bColor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF
   ::Activate()
   IF tColor != Nil
     ::setcolor(tColor)
   ENDIF  

   ::oParent:AddControl( Self )
   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      ::bLostFocus := bClick
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS,self,{|o,id|__When(o:FindControl(id))},,"onGotFocus" )
      ::lnoValid := .T.      
   ENDIF

   ::oParent:AddEvent( BN_KILLFOCUS, self, {|| ::Notify(WM_KEYDOWN)})

   IF ::oGroup != Nil
      Aadd( ::oGroup:aButtons,Self )
      // IF ::oGroup:bSetGet != Nil
         ::bLostFocus := bClick
         ::oParent:AddEvent( BN_CLICKED,self,{|o,id|__Valid(o:FindControl(id))},,"onClick" )
      // ENDIF
   ENDIF

Return Self

METHOD Activate CLASS HRadioButton
   IF !empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                  ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent,nId,oFont,bInit,bSize,bPaint,bClick,ctooltip,tcolor,bcolor,bGFocus, lTransp ) CLASS HRadioButton
   ::oParent := Iif( oWndParent==Nil, ::oDefaultParent, oWndParent )
   ::id      := nId
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::oFont   := oFont
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := ctooltip
   /*
   ::tcolor  := tcolor
   IF tColor != Nil .AND. bColor == Nil
      bColor := GetSysColor( COLOR_3DFACE )
   ENDIF
   */
   IF (lTransp != NIL .AND. lTransp) 
      bcolor := ::oParent:bcolor
   ENDIF
   ::bcolor  := bcolor
	 ::tColor  := tcolor
   IF bColor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF
   ::oParent:AddControl( Self )
   IF tColor != Nil
     ::setcolor(tColor)
   ENDIF  

   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      *::oParent:AddEvent( 0,self,bClick,,"onClick" )
      ::bLostFocus := bClick
      //::oParent:AddEvent( 0,self,{|o,id|__Valid(o:FindControl(id))},,"onClick" )
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS,self,{|o,id|__When(o:FindControl(id))},,"onGotFocus" )
      ::lnoValid := .T.      
   ENDIF
   ::oParent:AddEvent( BN_KILLFOCUS, self, {|| ::Notify(WM_KEYDOWN)})
   IF ::oGroup != Nil
      Aadd( ::oGroup:aButtons,Self )
      // IF ::oGroup:bSetGet != Nil
         ::bLostFocus := bClick
         ::oParent:AddEvent( BN_CLICKED,self,{|o,id|__Valid(o:FindControl(id))},,"onClick" )
      // ENDIF
   ENDIF
Return Self

METHOD Notify(lParam ) CLASS HRadioButton
 Local ndown := getkeystate(VK_RIGHT)+getkeystate(VK_DOWN)+GetKeyState( VK_TAB )
 Local nSkip := 0

   IF !CheckFocus(self, .t.)
      RETURN 0
   ENDIF

   IF PTRTOULONG( lParam )  = WM_KEYDOWN
      IF  GetKeyState( VK_RETURN ) < 0 //.AND. ::oGroup:value < Len(::oGroup:aButtons)
           ::oParent:lSuspendMsgsHandling := .T.
         __VALID(self)
           ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
      IF ::oParent:classname = "HTAB"
        IF getkeystate(VK_LEFT) + getkeystate(VK_UP) < 0 .OR. ;
          (GetKeyState( VK_TAB ) < 0 .and. GetKeyState(VK_SHIFT) < 0 )
           nSkip := -1
        ELSEIF nDown < 0
            nSkip := 1
         ENDIF
         IF nSkip != 0
            //SETFOCUS(::oParent:handle)
            ::oParent:SETFOCUS()
            GetSkip(::oparent, ::handle, ,nSkip)
          ENDIF
       ENDIF
   ENDIF

RETURN Nil

STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., oParent, nSkip := 1
   
	IF !CheckFocus(oCtrl, .f.)
	   RETURN .t.
	ENDIF
   nSkip := iif( GetKeyState( VK_UP ) < 0 .or. (GetKeyState( VK_TAB ) < 0 .and. GetKeyState(VK_SHIFT) < 0 ), -1, 1 )
   oCtrl:lwhen := GetKeyState( VK_UP )  + GetKeyState( VK_DOWN ) + GetKeyState( VK_RETURN ) + GetKeyState( VK_TAB ) < 0
   IF oCtrl:bGetFocus != Nil
      octrl:lnoValid := .T.
 		  octrl:oparent:lSuspendMsgsHandling := .t.    
      res := Eval( oCtrl:bGetFocus, oCtrl:oGroup:value, oCtrl )
      octrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog(oCtrl)
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
   octrl:oparent:lSuspendMsgsHandling := .f.
RETURN res

Static Function __Valid( oCtrl )
lOCAL nEnter := GetKeyState( VK_RETURN ), hctrl

 	 IF octrl:lnoValid .OR. getkeystate(VK_LEFT)+getkeystate(VK_RIGHT)+GetKeyState( VK_UP ) + GetKeyState( VK_DOWN ) +GetKeyState( VK_TAB ) < 0 ;
 	    .OR. oCtrl:oGroup = Nil .OR. oCtrl:lwhen 
 	    oCtrl:lwhen := .F.
      RETURN .T.
	 ELSE
  	 IF nEnter < 0
       oCtrl:oGroup:value := Ascan( oCtrl:oGroup:aButtons,{|o|o:id==oCtrl:id} )
	     oCtrl:oGroup:setvalue(oCtrl:oGroup:value)	   
	   ELSE
	     oCtrl:oParent:lSuspendMsgsHandling := .T.
  	   oCtrl:oGroup:value := Ascan( oCtrl:oGroup:aButtons,{|o|o:id==oCtrl:id} )
	     oCtrl:oGroup:setvalue(oCtrl:oGroup:value)	      
     ENDIF
   ENDIF
   IF oCtrl:oGroup:bSetGet != Nil
      Eval( oCtrl:oGroup:bSetGet,oCtrl:oGroup:value )
  ENDIF
   IF nEnter < 0
     oCtrl:setfocus() //octrl:handle)
	 ENDIF
   hctrl :=getfocus()
   IF oCtrl:bLostFocus != Nil //.and. nEnter >= 0
      Eval( oCtrl:bLostFocus, oCtrl:oGroup:value, oCtrl )
   ENDIF
   IF nEnter < 0 .and. getfocus() = hctrl
      KEYB_EVENT(VK_DOWN)
   ENDIF
   oCtrl:oParent:lSuspendMsgsHandling := .F.  
Return .T.

