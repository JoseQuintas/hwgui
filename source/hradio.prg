/*
 * $Id: hradio.prg,v 1.25 2009-03-25 13:15:49 lfbasso Exp $
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
   
   DATA xEnabled     INIT .T. HIDDEN
   ACCESS Enabled    INLINE ::xEnabled
   ASSIGN Enabled(xL)  INLINE ::xEnabled := xL, IIF(::xEnabled,::enable(),::disable())
   ASSIGN Name( cName )   INLINE IIF( !EMPTY( cName ) .AND. VALTYPE( cName) == "C" .AND. cName != ":" .AND. ! "[" $ cName,;
			(__objAddData( ::oParent, cName ), ::oParent: & ( cName ) := Self),.T.)
   DATA oParent
   DATA lInit   INIT .F.
   DATA bInit
   DATA bClick
   DATA bGfocus

   METHOD New( vari, bSetGet, bInit, bClick, bGFocus )
   METHOD EndGroup( nSelected )
   METHOD SetValue( nValue )
   METHOD GetValue()  INLINE ::value
   METHOD Refresh()   INLINE IIf( ::bSetGet != Nil, ::SetValue( Eval( ::bSetGet ) ), .T. )
   METHOD IsEnabled() INLINE ::xEnabled  
   METHOD Enable()
   METHOD Disable()
   METHOD Init()
   
ENDCLASS

METHOD New( vari, bSetGet, bInit, bClick, bGFocus ) CLASS HRadioGroup
   ::oGroupCurrent := Self
   ::aButtons := { }

   ::oParent := IIF( HWindow():GetMain() != Nil, HWindow():GetMain():oDefaultParent, Nil )
   ::bInit := bInit
   ::bClick := bClick
   ::bGfocus := bGfocus 
   
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

      nSelected := IIf( nSelected != Nil.AND.nSelected <= nLen.AND.nSelected > 0, ;
                        nSelected, ::oGroupCurrent:value )
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
      ::Init()
   ENDIF
   ::oGroupCurrent := Nil
   RETURN Nil

METHOD Init CLASS HRadioGroup

   IF ! ::lInit
     IF ::bInit != Nil
        ::oparent:lSuspendMsgsHandling := .t.
        Eval( ::bInit, Self )
        ::oparent:lSuspendMsgsHandling := .f.
     ENDIF
   ENDIF
   RETURN  NIL

METHOD SetValue( nValue )  CLASS HRadioGroup
   LOCAL nLen

   IF ( nLen := Len( ::aButtons ) ) > 0 .AND. nValue > 0 .AND. nValue <= nLen
      CheckRadioButton( ::aButtons[ nLen ]:oParent:handle, ;
                        ::aButtons[ 1 ]:id,    ;
                        ::aButtons[ nLen ]:id, ;
                        ::aButtons[ nValue ]:id )
      ::value := nValue
      IF ::bSetGet != Nil
         Eval( ::bSetGet, ::value )
      ENDIF
   ENDIF

   RETURN Nil

METHOD Enable() CLASS HRadioGroup
   LOCAL i, nLen := Len( ::aButtons )
   
   FOR i = 1 TO nLen
       ::aButtons[ i ]:Enable()
	 NEXT
	 ::xEnabled := .T.
	 
   RETURN Nil
 
METHOD Disable() CLASS HRadioGroup
   LOCAL i, nLen := Len( ::aButtons )
   
   FOR i = 1 TO nLen
       ::aButtons[ i ]:Disable()
	 NEXT
   ::xEnabled := .F.
   
   RETURN Nil

CLASS HRadioButton INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"
   DATA  oGroup
   DATA lWhen  INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
               bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp )
   METHOD Activate()
   METHOD Init()
   METHOD Redefine( oWnd, nId, oFont, bInit, bSize, bPaint, bClick, lInit, ctooltip, tcolor, bcolor )
   METHOD GetValue() INLINE ( SendMessage( ::handle, BM_GETCHECK, 0, 0 ) == 1 )
  // METHOD Notify( lParam )
   METHOD onevent( msg, wParam, lParam )
   METHOD onGotFocus()
   METHOD onClick()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
            bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp ) CLASS HRadioButton

   ::oParent := IIf( oWndParent == Nil, ::oDefaultParent, oWndParent )
   
   ::id      := IIf( nId == Nil, ::NewId(), nId )
   ::title   := cCaption
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::style   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), BS_RADIOBUTTON + ; // BS_AUTORADIOBUTTON+;
                       WS_CHILD + WS_VISIBLE + BS_NOTIFY + ;
                       IIf( ::oGroup != Nil .AND. Empty( ::oGroup:aButtons ), WS_GROUP , 0 ) )
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
   IF ( lTransp != NIL .AND. lTransp )
      bcolor := ::oParent:bcolor
   ENDIF
   ::bcolor  := bcolor
   ::tcolor  := tcolor
   IF bcolor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF
   ::Activate()
   IF tcolor != Nil
      ::SetColor( tcolor )
   ENDIF

   ::oParent:AddControl( Self )
   
   IF ::oGroup != Nil
      bClick := IIF( bClick != Nil, bClick, ::oGroup:bClick )
      bGFocus := IIF( bGFocus != Nil, bGFocus, ::oGroup:bGFocus )
   ENDIF
   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      ::bLostFocus := bClick
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::lnoValid := .T.
   ENDIF

   //::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )

   IF ::oGroup != Nil
      AAdd( ::oGroup:aButtons, Self )
      // IF ::oGroup:bSetGet != Nil
      ::bLostFocus := bClick
      ::oParent:AddEvent( BN_CLICKED, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onClick" )
      // ENDIF
   ENDIF

   RETURN Self

METHOD Activate CLASS HRadioButton
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
   IF ( lTransp != NIL .AND. lTransp )
      bcolor := ::oParent:bcolor
   ENDIF
   ::bcolor  := bcolor
   ::tcolor  := tcolor
   IF bcolor != Nil
      ::brush := HBrush():Add( bcolor )
   ENDIF
   ::oParent:AddControl( Self )
   IF tcolor != Nil
      ::SetColor( tcolor )
   ENDIF

   IF bClick != Nil .AND. ( ::oGroup == Nil .OR. ::oGroup:bSetGet == Nil )
      *::oParent:AddEvent( 0,self,bClick,,"onClick" )
      ::bLostFocus := bClick
      //::oParent:AddEvent( 0,self,{|o,id|__Valid(o:FindControl(id))},,"onClick" )
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != Nil
      ::oParent:AddEvent( BN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::lnoValid := .T.
   ENDIF
   //::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )
   IF ::oGroup != Nil
      AAdd( ::oGroup:aButtons, Self )
      // IF ::oGroup:bSetGet != Nil
      ::bLostFocus := bClick
      ::oParent:AddEvent( BN_CLICKED, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onClick" )
      // ENDIF
   ENDIF
   RETURN Self

METHOD onevent( msg, wParam, lParam ) CLASS HRadioButton
	 LOCAL oParent := ::oParent
	 
   IF ::bOther != Nil                                         
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg = WM_KEYDOWN
      IF  ProcKeyList( Self, wParam )
      ELSEIF wParam = VK_LEFT .OR. wParam = VK_UP 
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
         __VALID(self)
      ENDIF  
   ELSEIF msg == WM_NOTIFY 
         
	 ELSEIF  msg = WM_GETDLGCODE .AND.  wParam != 0 
	    RETURN DLGC_WANTMESSAGE 
	    /*
      IF wParam = VK_TAB //.AND.  ::GetParentForm( Self ):Type < WND_DLG_RESOURCE
         GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
      ELSEIF wParam != 0 
         RETURN ButtonGetDlgCode( lParam )
      ENDIF   
      */
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

METHOD onGotFocus CLASS HRadioButton
   RETURN __When( Self )

METHOD onClick CLASS HRadioButton
   RETURN __Valid( Self )


STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., oParent, nSkip := 1

   IF ! CheckFocus( oCtrl, .f. )
      RETURN .t.
   ENDIF
   nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
   oCtrl:lwhen := GetKeyState( VK_UP )  + GetKeyState( VK_DOWN ) + GetKeyState( VK_RETURN ) + GetKeyState( VK_TAB ) < 0
   IF oCtrl:bGetFocus != Nil
      oCtrl:lnoValid := .T.
      oCtrl:oParent:lSuspendMsgsHandling := .t.
      res := Eval( oCtrl:bGetFocus, oCtrl:oGroup:value, oCtrl )
      oCtrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog( oCtrl )
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
   oCtrl:oParent:lSuspendMsgsHandling := .f.
   RETURN res

STATIC FUNCTION __Valid( oCtrl )
   LOCAL nEnter := GetKeyState( VK_RETURN ), hctrl

   IF oCtrl:lnoValid .OR. getkeystate( VK_LEFT ) + getkeystate( VK_RIGHT ) + GetKeyState( VK_UP ) + GetKeyState( VK_DOWN ) + GetKeyState( VK_TAB ) < 0 ;
      .OR. oCtrl:oGroup = Nil .OR. oCtrl:lwhen
      oCtrl:lwhen := .F.
      RETURN .T.
   ELSE
      IF nEnter < 0
         oCtrl:oGroup:value := AScan( oCtrl:oGroup:aButtons, { | o | o:id == oCtrl:id } )
         oCtrl:oGroup:setvalue( oCtrl:oGroup:value )
         oCtrl:setfocus()
      ELSE
         oCtrl:oParent:lSuspendMsgsHandling := .T.
         oCtrl:oGroup:value := AScan( oCtrl:oGroup:aButtons, { | o | o:id == oCtrl:id } )
         oCtrl:oGroup:setvalue( oCtrl:oGroup:value )
      ENDIF
   ENDIF
   IF oCtrl:oGroup:bSetGet != Nil
      Eval( oCtrl:oGroup:bSetGet, oCtrl:oGroup:value )
   ENDIF
   //IF nEnter < 0
   //   oCtrl:setfocus() //octrl:handle)
   //ENDIF
   hctrl := getfocus()
   IF oCtrl:bLostFocus != Nil //.and. nEnter >= 0
      Eval( oCtrl:bLostFocus, oCtrl, oCtrl:oGroup:value  )
   ENDIF
   IF nEnter < 0 .and. getfocus() = hctrl
      KEYB_EVENT( VK_DOWN )
   ENDIF
   oCtrl:oParent:lSuspendMsgsHandling := .F.
   RETURN .T.

