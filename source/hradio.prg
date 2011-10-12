/*
 * $Id$
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
#DEFINE TRANSPARENT 1

CLASS HRadioGroup INHERIT HControl //HObject

   CLASS VAR winclass   INIT "STATIC"
   CLASS VAR oGroupCurrent
   DATA aButtons
   DATA nValue  INIT 1
   DATA bSetGet
   DATA oHGroup
   DATA lEnabled  INIT .T.
   DATA bClick


   METHOD New( vari, bSetGet, bInit, bClick, bGFocus, nStyle )
   METHOD Newrg( oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
              cCaption, oFont, bInit, bSize,tcolor, bColor,bClick,;
              bGFocus,lTransp )
   METHOD EndGroup( nSelected )
   METHOD SetValue( nValue )
   METHOD GetValue()  INLINE ::nValue
   METHOD Value ( nValue ) SETGET
   METHOD Refresh()
   //METHOD IsEnabled() INLINE ::lEnabled
   METHOD Enable()
   METHOD Disable()
   //METHOD Enabled( lEnabled ) SETGET
   METHOD Init()
   METHOD Activate() VIRTUAL

ENDCLASS

METHOD New( vari, bSetGet, bInit, bClick, bGFocus, nStyle ) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := { }
   ::oParent := IIF( HWindow():GetMain() != Nil, HWindow():GetMain():oDefaultParent, Nil )
   ::lEnabled :=  ! Hwg_BitAnd( nStyle, WS_DISABLED ) > 0

   Super:New( ::oParent, ,, ,,,,, bInit)

   ::bInit := bInit
   ::bClick := bClick
   ::bGetFocus := bGfocus


   IF vari != Nil
      IF ValType( vari ) == "N"
         ::nValue := vari
      ENDIF
      //::bSetGet := bSetGet
   ENDIF
   ::bSetGet := bSetGet

   RETURN Self

METHOD NewRg( oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
              cCaption, oFont, bInit, bSize,tcolor, bColor,bClick,;
              bGFocus,lTransp ) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := {}
   ::lEnabled :=  ! Hwg_BitAnd( nStyle, WS_DISABLED ) > 0

   Super:New( ::oParent,,,nLeft, nTop, nWidth, nHeight, oFont, bInit )
   ::oHGroup := HGroup():New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
                              oFont, bInit, bSize, , tcolor, bColor, lTransp, Self )
                              
   ::lInit := .T.
   ::bInit := bInit
   ::bClick := bClick
   ::bGetFocus := bGfocus

   IF vari != Nil
      IF Valtype( vari ) == "N"
         ::nValue := vari
      ENDIF
   ENDIF
   ::bSetGet := bSetGet

   RETURN Self


METHOD EndGroup( nSelected )  CLASS HRadioGroup
   LOCAL nLen

   IF ::oGroupCurrent != Nil .AND. ( nLen := Len( ::oGroupCurrent:aButtons ) ) > 0

      nSelected := IIf( nSelected != Nil.AND.nSelected <= nLen.AND.nSelected > 0, ;
                        nSelected, ::oGroupCurrent:nValue )
      IF nSelected != 0 .AND. nSelected <= nLen
         IF ::oGroupCurrent:aButtons[ nLen ]:handle > 0
            CheckRadioButton( ::oGroupCurrent:aButtons[ nLen ]:oParent:handle, ;
                              ::oGroupCurrent:aButtons[ 1 ]:id,    ;
                              ::oGroupCurrent:aButtons[ nLen ]:id, ;
                              ::oGroupCurrent:aButtons[ nSelected ]:id )
         ELSE
            ::oGroupCurrent:aButtons[ nLen ]:bInit :=                     ;
                                                      &( "{|o|CheckRadioButton(o:oParent:handle," +           ;
                                                                                LTrim( Str( ::oGroupCurrent:aButtons[ 1 ]:id ) ) + "," +    ;
                                                                                LTrim( Str( ::oGroupCurrent:aButtons[ nLen ]:id ) ) + "," + ;
                                                                                LTrim( Str( ::oGroupCurrent:aButtons[ nSelected ]:id ) ) + ")}" )
         ENDIF
      ENDIF
      IF EMPTY( ::oParent )
         ::oParent := ::oGroupCurrent:aButtons[ nLen ]:oParent //GetParentForm()
      ENDIF
      //::Init()
   ENDIF
   ::oGroupCurrent := Nil
   RETURN Nil

METHOD Init() CLASS HRadioGroup

   IF ! ::lInit
      /*
      IF ::oHGroup != Nil
        ::id := ::oHGroup:id
        ::handle := ::oHGroup:handle
      ENDIF
      */
      super:init()
   ENDIF
   RETURN  NIL

METHOD SetValue( nValue )  CLASS HRadioGroup
   LOCAL nLen

   IF ( nLen := Len( ::aButtons ) ) > 0 .AND. nValue > 0 .AND. nValue <= nLen
      CheckRadioButton( ::aButtons[ nLen ]:oParent:handle, ;
                        ::aButtons[ 1 ]:id,    ;
                        ::aButtons[ nLen ]:id, ;
                        ::aButtons[ nValue ]:id )
      ::nValue := nValue
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::nValue )
      ENDIF
   ELSEIF nLen > 0
      CheckRadioButton( ::aButtons[ nlen ]:oParent:handle, ;
            ::aButtons[ 1 ]:id,    ;
            ::aButtons[ nLen ]:id, ;
            0 )
   ENDIF
   RETURN Nil
   
METHOD Value( nValue ) CLASS HRadioGroup

   IF nValue != Nil
       ::SetValue( nValue )
   ENDIF
	 RETURN ::nValue
   

METHOD Refresh()  CLASS HRadioGroup
   LOCAL vari

   IF ::bSetGet != Nil
     vari := Eval( ::bSetGet,, Self )
     IF vari = Nil .OR. Valtype( vari ) != "N"
         vari := ::nValue
      ENDIF
      ::SetValue( vari )
   ENDIF
   RETURN Nil

METHOD Enable() CLASS HRadioGroup
   LOCAL i, nLen := Len( ::aButtons )

   FOR i = 1 TO nLen
       ::aButtons[ i ]:Enable()
	 NEXT
   RETURN Nil

METHOD Disable() CLASS HRadioGroup
   LOCAL i, nLen := Len( ::aButtons )

   FOR i = 1 TO nLen
       ::aButtons[ i ]:Disable()
	 NEXT
   RETURN Nil

 *--------------------------------------------------------------

CLASS HRadioButton INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"
   DATA  oGroup
   DATA lWhen  INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
               bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp )
   METHOD Activate()
   METHOD Init()
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp )
   METHOD GetValue() INLINE ( SendMessage( ::handle, BM_GETCHECK, 0, 0 ) == 1 )
  // METHOD Notify( lParam )
   METHOD onevent( msg, wParam, lParam )
   METHOD onGotFocus()
   METHOD onClick()
   METHOD Valid( nKey )
   METHOD When()


ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
            bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp ) CLASS HRadioButton

   ::oParent := IIf( oWndParent == Nil, ::oDefaultParent, oWndParent )

   ::id      := IIf( nId == Nil, ::NewId(), nId )
   ::title   := cCaption
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::Enabled := ! Hwg_BitAnd( nStyle, WS_DISABLED ) > 0
   ::style   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), BS_RADIOBUTTON + ; // BS_AUTORADIOBUTTON+;
                        BS_NOTIFY + ;  // WS_CHILD + WS_VISIBLE
                       IIf( ::oGroup != Nil .AND. Empty( ::oGroup:aButtons ), WS_GROUP , 0 ) )

   Super:New( oWndParent, nId, ::Style, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint,ctooltip, tcolor, bColor )

   ::backStyle :=  IIF( lTransp != NIL .AND. lTransp, TRANSPARENT, OPAQUE )

   ::Activate()
   //::SetColor( tcolor, bColor, .t. )

   //::oParent:AddControl( Self )

   IF ::oGroup != Nil
      bClick := IIF( bClick != Nil, bClick, ::oGroup:bClick )
      bGFocus := IIF( bGFocus != Nil, bGFocus, ::oGroup:bGetFocus )
   ENDIF
   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      ::bLostFocus := bClick
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, self, { | o, id | ::When( o:FindControl( id ) ) },, "onGotFocus" )
      //::oParent:AddEvent( BN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::lnoValid := .T.
   ENDIF

   //::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )

   IF ::oGroup != Nil
      AAdd( ::oGroup:aButtons, Self )
      // IF ::oGroup:bSetGet != Nil
      ::bLostFocus := bClick
      *- ::oParent:AddEvent( BN_CLICKED, self, { | o, id | ::Valid( o:FindControl( id ) ) },, "onClick" )
      ::oParent:AddEvent( BN_CLICKED, self, { |  | ::onClick( ) },,"onClick" )
      // ENDIF
   ENDIF

   RETURN Self

METHOD Activate() CLASS HRadioButton
   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HRadioButton
   IF !::lInit
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITBUTTONPROC( ::handle )
      ::Enabled :=  ::oGroup:lEnabled .AND. ::Enabled 
      Super:Init()
   ENDIF
Return Nil

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp ) CLASS HRadioButton
   ::oParent := IIf( oWndParent == Nil, ::oDefaultParent, oWndParent )
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
   ::backStyle :=  IIF( lTransp != NIL .AND. lTransp, TRANSPARENT, OPAQUE )
   ::setcolor( tColor, bColor ,.t.)
   ::oParent:AddControl( Self )

   ::oParent:AddControl( Self )

   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      *::oParent:AddEvent( 0,self,bClick,,"onClick" )
      ::bLostFocus := bClick
      //::oParent:AddEvent( 0,self,{|o,id|__Valid(o:FindControl(id))},,"onClick" )
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, self, { | o, id | ::When( o:FindControl( id ) ) },, "onGotFocus" )
      ::lnoValid := .T.
   ENDIF
   //::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )
   IF ::oGroup != Nil
      AAdd( ::oGroup:aButtons, Self )
      // IF ::oGroup:bSetGet != Nil
      ::bLostFocus := bClick
      //::oParent:AddEvent( BN_CLICKED, self, { | o, id | ::Valid( o:FindControl( id ) ) },, "onClick" )
      ::oParent:AddEvent( BN_CLICKED, self, { |  | ::onClick( ) },,"onClick" )
      // ENDIF
   ENDIF
   RETURN Self

METHOD onEvent( msg, wParam, lParam ) CLASS HRadioButton
	 LOCAL oCtrl
	  
   IF ::bOther != Nil
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF  msg = WM_GETDLGCODE //.AND.  ! EMPTY( wParam )
	    IF  wParam = VK_RETURN .AND. ProcOkCancel( Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE )
         RETURN 0
      ELSEIF wParam = VK_ESCAPE  .AND. ;
                  ( oCtrl := ::GetParentForm:FindControl( IDCANCEL ) ) != Nil .AND. ! oCtrl:IsEnabled() 
         RETURN DLGC_WANTMESSAGE  
	    ELSEIF ( wParam != VK_TAB .AND. GETDLGMESSAGE( lParam ) = WM_CHAR ) .OR. GETDLGMESSAGE( lParam ) = WM_SYSCHAR .OR. ;
               wParam = VK_ESCAPE 
         RETURN -1         
      ELSEIF GETDLGMESSAGE( lParam ) = WM_KEYDOWN .AND. wParam = VK_RETURN  // DIALOG 
         ::VALID( VK_RETURN )   // dialog funciona
         RETURN DLGC_WANTARROWS
      ENDIF 
      RETURN DLGC_WANTMESSAGE
   ELSEIF msg = WM_KEYDOWN
      //IF  ProcKeyList( Self, wParam )
      IF wParam = VK_LEFT .OR. wParam = VK_UP
         GetSkip( ::oparent, ::handle, , -1 )
         RETURN 0
      ELSEIF wParam = VK_RIGHT .OR. wParam = VK_DOWN
         GetSkip( ::oparent, ::handle, , 1 )
         RETURN 0
      ELSEIF wParam = VK_TAB //.AND. nType < WND_DLG_RESOURCE
         GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
         RETURN 0
      ENDIF
      IF  ( wParam == VK_RETURN )
         ::VALID( VK_RETURN )
         RETURN 0
      ENDIF
   ELSEIF msg == WM_KEYUP
      ProcKeyList( Self, wParam )   // working in MDICHILD AND DIALOG
      IF  ( wParam == VK_RETURN ) 
         RETURN 0
      ENDIF  
   ELSEIF msg == WM_NOTIFY
   ENDIF

   RETURN -1
/*
METHOD Notify( lParam ) CLASS HRadioButton
   LOCAL ndown := getkeystate( VK_RIGHT ) + getkeystate( VK_DOWN ) + GetKeyState( VK_TAB )
   LOCAL nSkip := 0

   IF ! CheckFocus( Self, .t. )
      RETURN 0
   ENDIF

   IF PTRTOULONG( lParam )  = WM_KEYDOWN
      IF  GetKeyState( VK_RETURN ) < 0 //.AND. ::oGroup:value < Len(::oGroup:aButtons)
         ::oParent:lSuspendMsgsHandling := .T.
         __VALID( Self )
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
      IF ::oParent:classname = "HTAB"
         IF getkeystate( VK_LEFT ) + getkeystate( VK_UP ) < 0 .OR. ;
            ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 )
            nSkip := - 1
         ELSEIF ndown < 0
            nSkip := 1
         ENDIF
         IF nSkip != 0
            //SETFOCUS(::oParent:handle)
            ::oParent:SETFOCUS()
            GetSkip( ::oparent, ::handle, , nSkip )
         ENDIF
      ENDIF
   ENDIF

   RETURN Nil
*/

METHOD onGotFocus() CLASS HRadioButton
   RETURN ::When( )

METHOD onClick() CLASS HRadioButton
   ::lWhen := .F.
   ::lnoValid := .f.
   RETURN ::Valid( 0 )

METHOD When( ) CLASS HRadioButton
   LOCAL res := .t., nSkip

   IF ! CheckFocus( Self, .f. )
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   ::lwhen := GetKeyState( VK_UP )  + GetKeyState( VK_DOWN ) + GetKeyState( VK_RETURN ) + GetKeyState( VK_TAB ) < 0
   IF ::bGetFocus != Nil
      ::lnoValid := .T.
      ::oParent:lSuspendMsgsHandling := .t.
      res := Eval( ::bGetFocus, ::oGroup:nValue, Self )
      ::lnoValid := ! res
      ::oparent:lSuspendMsgsHandling := .f.
      IF ! res
         GetSkip( ::oParent, ::handle, , nSkip )
      ELSE
         ::SETfOCUS()   
      ENDIF
   ENDIF
   RETURN res


METHOD Valid( nKey ) CLASS HRadioButton
   LOCAL nEnter := IIF( nKey = nil, 1, nkey)
   LOCAL hctrl, iValue

   IF ::lnoValid .OR. getkeystate( VK_LEFT ) + getkeystate( VK_RIGHT ) + GetKeyState( VK_UP ) + ;
       GetKeyState( VK_DOWN ) + GetKeyState( VK_TAB ) < 0 .OR. ::oGroup = Nil .OR. ::lwhen
      ::lwhen := .F.
      RETURN .T.
   ELSE
      ::oParent:lSuspendMsgsHandling := .T.
	    iValue := Ascan( ::oGroup:aButtons, {| o | o:id == ::id } )
      IF nEnter = VK_RETURN //< 0
         *-iValue := Ascan( ::oGroup:aButtons,{ | o | o:id == ::id } )
         IF  ! ::GetValue() 
            ::oGroup:nValue  := iValue
	          ::oGroup:SetValue( ::oGroup:nValue )	   
            ::SetFocus() 
         ENDIF
      ELSEIF nEnter = 0 .AND. ! GetKeyState( VK_RETURN ) < 0
         IF ! ::GetValue()
  	        ::oGroup:nValue := Ascan( ::oGroup:aButtons, {| o | o:id == ::id } )
	          ::oGroup:SetValue( ::oGroup:nValue )
         ENDIF 
      ENDIF
   ENDIF
   IF ::oGroup:bSetGet != Nil
      Eval( ::oGroup:bSetGet, ::oGroup:nValue )
   ENDIF
   hCtrl := GetFocus()
   IF ::bLostFocus != Nil .AND. ( nEnter = 0 .OR. iValue = Len( ::oGroup:aButtons ) )
      Eval( ::bLostFocus, Self, ::oGroup:nValue )
   ENDIF
   IF nEnter = VK_RETURN .AND. GetFocus() = hctrl
       GetSkip( ::oParent, hCtrl, , 1 )
   ENDIF
   ::oParent:lSuspendMsgsHandling := .F.  
   
   RETURN .T.
