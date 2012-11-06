/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HUpDown class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define UDN_FIRST               ( -721 )        // updown
#define UDN_DELTAPOS            ( UDN_FIRST - 1 )
#define UDM_SETBUDDY            ( WM_USER + 105 )
#define UDM_GETBUDDY            ( WM_USER + 106 )
#define EC_RIGHTMARGIN           2

CLASS HUpDown INHERIT HControl

   CLASS VAR winclass   INIT "EDIT"

   DATA bSetGet
   DATA nValue
   DATA bValid
   DATA hwndUpDown, idUpDown, styleUpDown
   DATA bkeydown, bkeyup, bchange
   DATA bClickDown, bClickUp
   DATA nLower       INIT -9999  //0
   DATA nUpper       INIT 9999  //999
   DATA nUpDownWidth INIT 10
   DATA lChanged     INIT .F.
   DATA Increment    INIT 1
   DATA nMaxLength   INIT Nil
   DATA lNoBorder
   DATA cPicture
   DATA oEditUpDown
   DATA bColorOld   HIDDEN

   DATA lCreate    INIT .F. HIDDEN //

   METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
              oFont, bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip,tcolor,bcolor,;
                     nUpDWidth, nLower,nUpper, nIncr,cPicture,lNoBorder, nMaxLength,;
              bKeyDown, bChange, bOther, bClickUp ,bClickDown )

   METHOD Activate()
   METHOD Init()
   METHOD CreateUpDown()
   METHOD SetValue( nValue )
   METHOD Value( Value ) SETGET
   METHOD Refresh()
   METHOD SetColor( tColor, bColor, lRedraw ) INLINE super:SetColor(tColor, bColor, lRedraw ), IIF( ::oEditUpDown != Nil, ;
                                             ::oEditUpDown:SetColor( tColor, bColor, lRedraw ),)
   METHOD DisableBackColor( DisableBColor ) SETGET
   METHOD Hide() INLINE (::lHide := .T., HideWindow( ::handle ), HideWindow( ::hwndUpDown ) )
   METHOD Show() INLINE (::lHide := .F., ShowWindow( ::handle ), ShowWindow( ::hwndUpDown ) )
   METHOD Enable()  INLINE ( Super:Enable(), EnableWindow( ::hwndUpDown, .T. ), InvalidateRect( ::hwndUpDown, 0 ) )
                          //  InvalidateRect( ::oParent:Handle, 1,  ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight ) )
   METHOD Disable() INLINE ( Super:Disable(), EnableWindow( ::hwndUpDown, .F. ) )
   METHOD Valid()
   METHOD SetRange( nLower, nUpper ) 
   METHOD Move( x1, y1, width, height, nRepaint ) INLINE ;                             // + GetClientRect( ::hwndUpDown )[ 3 ] - 1
                              Super:Move( x1, y1 , IIF( width != Nil, width, ::nWidth ), height, nRepaint  ) ,;
                              SENDMESSAGE( ::hwndUpDown, UDM_SETBUDDY, ::oEditUpDown:handle, 0 ),;
                              IIF( ::lHide, ::Hide(), ::Show() )

ENDCLASS

METHOD New( oWndParent,nId,vari,bSetGet,nStyle,nLeft,nTop,nWidth,nHeight, ;
            oFont, bInit,bSize,bPaint,bGfocus,bLfocus,ctooltip,tcolor,bcolor,;
                 nUpDWidth, nLower,nUpper, nIncr,cPicture,lNoBorder, nMaxLength,;
            bKeyDown, bChange, bOther, bClickUp ,bClickDown ) CLASS HUpDown

   HB_SYMBOL_UNUSED( bOther )

   nStyle := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + IIf( lNoBorder == Nil.OR. ! lNoBorder, WS_BORDER, 0 ) )

   IF Valtype(vari) != "N"
      vari := 0
      Eval( bSetGet,vari )
   ENDIF
   IF bSetGet = Nil
      bSetGet := {| v | IIF( v == Nil, ::nValue, ::nValue := v ) }
   ENDIF

   ::nValue := Vari
   ::title := Str( vari )
   ::bSetGet := bSetGet
   ::bColorOld := bColor
   Super:New( oWndParent,nId,nStyle,nLeft,nTop,nWidth,nHeight,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   ::idUpDown := ::id //::NewId()

   ::Increment := IIF( nIncr = Nil, 1, nIncr )
   ::styleUpDown := UDS_ALIGNRIGHT  + UDS_ARROWKEYS + UDS_NOTHOUSANDS //+ UDS_SETBUDDYINT //+ UDS_HORZ
   IF nLower != Nil ; ::nLower := nLower ; ENDIF
   IF nUpper != Nil ; ::nUpper := nUpper ; ENDIF
   // width of spinner
   IF nUpDWidth != Nil ; ::nUpDownWidth := nUpDWidth ; ENDIF
   ::nMaxLength :=  nMaxLength //= Nil, 4, nMaxLength )
   ::cPicture := IIF( cPicture = Nil, Replicate("9", 4), cPicture )
   ::lNoBorder := lNoBorder
   ::bkeydown := bkeydown
   ::bchange  := bchange
   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus

   ::Activate()

   ::bClickDown := bClickDown
   ::bClickUp := bClickUp

   IF bSetGet != Nil
      ::bValid := bLFocus
   ELSE
      IF bGfocus != Nil
         ::lnoValid := .T.
      ENDIF
   ENDIF

  Return Self

METHOD Activate() CLASS HUpDown

   IF !empty( ::oParent:handle )
      ::lCreate := .T.
      ::oEditUpDown := HEditUpDown():New( ::oParent, ::id , val(::title) , ::bSetGet, ::Style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
           ::oFont, ::bInit, ::bSize, ::bPaint, ::bGetfocus, ::bLostfocus, ::tooltip, ::tcolor, ::bcolor, ::cPicture,;
           ::lNoBorder, ::nMaxLength, , ::bKeyDown, ::bChange, ::bOther , ::controlsource)
      ::oEditUpDown:Name := "oEditUpDown"
      ::SetColor( ::tColor, ::oEditUpDown:bColor ) 
      ::Init()
   ENDIF

   RETURN Nil

METHOD Init()  CLASS HUpDown

   IF !::lInit
      Super:Init()
      ::Createupdown()
      SendMessage( ::oEditUpDown:Handle, EM_SETMARGINS, EC_RIGHTMARGIN,  MAKELPARAM( 0, 1 ) )
      ::DisableBackColor := ::DisablebColor
      ::Refresh()
   ENDIF
   Return Nil


METHOD CREATEUPDOWN() CLASS Hupdown

   ///IF Empty( ::handle )
   //   RETURN Nil
    //ENDIF
   ::nHolder := 0
   IF !::lCreate
      ::Activate()
      AddToolTip( ::GetParentForm():handle, ::oEditUpDown:handle, ::tooltip )
      ::oEditUpDown:SetFont( ::oFont )
      ::oEditUpDown:DisableBrush := ::DisableBrush
      SETWINDOWPOS( ::oEditUpDown:handle, ::Handle, 0, 0, 0, 0, SWP_NOSIZE +  SWP_NOMOVE )
      DESTROYWINDOW( ::Handle )
   ELSEIF ::getParentForm():Type < WND_DLG_RESOURCE .AND. ::oParent:ClassName = "HTAB" //!EMPTY( ::oParent:oParent )
      // MDICHILD WITH TAB
      ::nHolder := 1
      SetWindowObject( ::oEditUpDown:handle, ::oEditUpDown )
      Hwg_InitEditProc( ::oEditUpDown:handle )
   ELSE
      AddToolTip( ::GetParentForm():handle, ::oEditUpDown:handle, ::tooltip )
   ENDIF
   ::handle := ::oEditUpDown:handle
   ::hwndUpDown := CreateUpDownControl( ::oParent:handle, ::idUpDown, ;
                                     ::styleUpDown, 0, 0, ::nUpDownWidth, 0, ::handle, -2147483647, 2147483647, Val(::title) )
                                    // ::styleUpDown, 0, 0, ::nUpDownWidth, 0, ::handle, ::nLower, ::nUpper,Val(::title) )
   ::oEditUpDown:oUpDown := Self
   ::oEditUpDown:lInit := .T.
   IF ::nHolder = 0
      ::nHolder := 1
      SetWindowObject( ::handle, ::oEditUpDown )
      Hwg_InitEditProc( ::handle )
   ENDIF
   RETURN Nil

METHOD DisableBackColor( DisableBColor ) CLASS HUpDown

    IF DisableBColor != NIL
       Super:DisableBackColor( DisableBColor )
       IF ::oEditUpDown != Nil
          ::oEditUpDown:DisableBrush := ::DisableBrush
       ENDIF
    ENDIF
    RETURN ::DisableBColor

METHOD SetRange( nLower, nUpper ) CLASS HUpDown
   
   ::nLower := IIF( nLower != Nil, nLower, ::nLower )
   ::nUpper := IIF( nUpper != Nil, nUpper, ::nUpper )
   SETRANGEUPDOWN( ::nLower, ::nUpper )

   RETURN Nil

METHOD Value( Value )  CLASS HUpDown

   IF Value != Nil .AND. ::oEditUpDown != Nil
       ::SetValue( Value )
       ::oEditUpDown:Title :=  ::Title
       ::oEditUpDown:Refresh()
   ENDIF
   RETURN ::nValue

METHOD SetValue( nValue )  CLASS HUpDown

   IF  nValue < ::nLower .OR. nValue > ::nUpper
       nValue := ::nValue
   ENDIF
   ::nValue := nValue
   ::title := Str( ::nValue )
   SetUpDown( ::hwndUpDown, ::nValue )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::nValue, Self )
   ENDIF

   RETURN ::nValue

METHOD Refresh()  CLASS HUpDown

   IF ::bSetGet != Nil //.AND. ::nValue != Nil
      ::nValue := Eval( ::bSetGet, , Self )
      IF Str(::nValue) != ::title
         //::title := Str( ::nValue )
         //SetUpDown( ::hwndUpDown, ::nValue )
         ::SetValue( ::nValue )
      ENDIF
   ELSE
      SetUpDown( ::hwndUpDown, Val(::title) )
   ENDIF
   ::oEditUpDown:Title :=  ::Title
   ::oEditUpDown:Refresh()
   IF SelfFocus( ::handle )
      InvalidateRect( ::hwndUpDown, 0 )
   ENDIF

   RETURN Nil

METHOD Valid() CLASS HUpDown
   LOCAL res

   IF  ::oEditUpDown:lNoValid
      RETURN .T.
   ENDIF

   /*
   ::title := GetEditText( ::oParent:handle, ::oEditUpDown:id )
   ::nValue := Val( Ltrim( ::title ) )
   IF ::bSetGet != Nil
      Eval( ::bSetGet, ::nValue )
   ENDIF
   */
   res :=  ::nValue <= ::nUpper .and. ::nValue >= ::nLower
   IF ! res
      ::nValue := IIF( ::nValue > ::nUpper, Min( ::nValue, ::nUpper ), Max( ::nValue, ::nLower ) )
      ::SetValue( ::nValue )
      ::oEditUpDown:Refresh()
      SendMessage( ::oEditUpDown:Handle, EM_SETSEL , 0, -1 )
      ::SetFocus()
   ENDIF
   Return res

*-----------------------------------------------------------------
CLASS HEditUpDown INHERIT HEdit

    //DATA Value

    METHOD INIT()
    METHOD Notify( lParam )
    METHOD Refresh()
    METHOD Move()  VIRTUAL

ENDCLASS

METHOD Init() CLASS HEditUpDown

   IF ! ::lInit
      IF ::bChange != Nil
         ::oParent:AddEvent( EN_CHANGE, self,{|| ::onChange()},,"onChange")
      ENDIF
   ENDIF
   RETURN Nil

METHOD Notify( lParam ) CLASS HeditUpDown
   Local nCode := GetNotifyCode( lParam )
   Local iPos := GETNOTIFYDELTAPOS( lParam, 1 )
   Local iDelta := GETNOTIFYDELTAPOS( lParam , 2 )
   Local vari, res

   //iDelta := IIF( iDelta < 0,  1, - 1) // IIF( ::oParent:oParent = Nil , - 1 ,  1 )

 	 IF ::oUpDown = Nil .OR. Hwg_BitAnd( GetWindowLong( ::handle, GWL_STYLE ), ES_READONLY ) != 0 .OR. ;
 	     GetFocus() != ::Handle .OR. ;
       ( ::oUpDown:bGetFocus != Nil .AND. ! Eval( ::oUpDown:bGetFocus, ::oUpDown:nValue, ::oUpDown ) )
	     Return 0
   ENDIF

   vari := Val( LTrim( ::UnTransform( ::title ) ) )

   IF ( vari <= ::oUpDown:nLower .AND. iDelta < 0 ) .OR. ;
       ( vari >= ::oUpDown:nUpper .AND. iDelta > 0 ) .OR. ::oUpDown:Increment = 0
       ::SetFocus()
       RETURN 0
   ENDIF
   vari :=  vari + ( ::oUpDown:Increment * idelta )
   ::Title := Transform( vari , ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
   SetDlgItemText( ::oParent:handle, ::id, ::title )
   ::oUpDown:Title := ::Title
   ::oUpDown:SetValue( vari )
   ::SetFocus()
   IF nCode = UDN_DELTAPOS .AND. ( ::oUpDown:bClickUp != Nil .OR. ::oUpDown:bClickDown != Nil )
      ::oparent:lSuspendMsgsHandling := .T.
      IF iDelta < 0 .AND. ::oUpDown:bClickDown  != Nil
         res := Eval( ::oUpDown:bClickDown, ::oUpDown, ::oUpDown:nValue, iDelta, ipos )
      ELSEIF iDelta > 0 .AND. ::oUpDown:bClickUp  != Nil
         res := Eval( ::oUpDown:bClickUp, ::oUpDown, ::oUpDown:nValue, iDelta, ipos )
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF VALTYPE( res ) = "L" .AND. !res
         RETURN 0
      ENDIF
   ENDIF
   IF nCode = UDN_FIRST

   ENDIF
   RETURN 0

   METHOD Refresh()  CLASS HeditUpDown
   LOCAL vari

   vari := ::Value
   IF  ::bSetGet != Nil  .AND. ::title != Nil
      ::Title := Transform( vari , ::cPicFunc + IIf( Empty( ::cPicFunc ), "", " " ) + ::cPicMask )
   ENDIF
   SetDlgItemText( ::oParent:handle, ::id, ::title )

   RETURN Nil

**------------------ END NEW CLASS UPDOWN

/*
CLASS HUpDown INHERIT HControl

CLASS VAR winclass   INIT "EDIT"
   DATA bSetGet
   DATA value
   DATA bValid
   DATA hUpDown, idUpDown, styleUpDown
   DATA nLower INIT 0
   DATA nUpper INIT 999
   DATA nUpDownWidth INIT 12
   DATA lChanged    INIT .F.

   METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor, nUpDWidth, nLower, nUpper )
   METHOD Activate()
   METHOD Init()
   METHOD OnEvent(msg,wParam,lParam)
   METHOD Refresh()
   METHOD Hide() INLINE ( ::lHide := .T., HideWindow( ::handle ), HideWindow( ::hwndUpDown ) )
   METHOD Show() INLINE ( ::lHide := .F., ShowWindow( ::handle ), ShowWindow( ::hwndUpDown ) )

ENDCLASS

METHOD New( oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, bcolor,   ;
            nUpDWidth, nLower, nUpper ) CLASS HUpDown

   nStyle   := Hwg_BitOr( IIf( nStyle == Nil, 0, nStyle ), WS_TABSTOP + WS_BORDER + ES_RIGHT )
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )

   ::idUpDown := ::NewId()
   IF ValType( vari ) != "N"
      vari := 0
      Eval( bSetGet, vari )
   ENDIF
   ::title := Str( vari )
   ::bSetGet := bSetGet

   ::styleUpDown := UDS_SETBUDDYINT + UDS_ALIGNRIGHT

   IF nLower != Nil ; ::nLower := nLower ; ENDIF
   IF nUpper != Nil ; ::nUpper := nUpper ; ENDIF
   IF nUpDWidth != Nil ; ::nUpDownWidth := nUpDWidth ; ENDIF

   ::Activate()

   IF bSetGet != Nil
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::bValid := bLfocus
      ::lnoValid := bGfocus != Nil
      ::oParent:AddEvent( EN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
      ::oParent:AddEvent( EN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onLostFocus" )
   ELSE
      IF bGfocus != Nil
         ::lnoValid := .T.
         ::oParent:AddEvent( EN_SETFOCUS, Self, { | o, id | __When( o:FindControl( id ) ) },, "onGotFocus" )
         //::oParent:AddEvent( EN_SETFOCUS,self,bGfocus,,"onGotFocus"  )
      ENDIF
      IF bLfocus != Nil
         // ::oParent:AddEvent( EN_KILLFOCUS,self,bLfocus,,"onLostFocus"  )
         ::oParent:AddEvent( EN_KILLFOCUS, Self, { | o, id | __Valid( o:FindControl( id ) ) },, "onLostFocus" )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate CLASS HUpDown
   IF ! Empty( ::oParent:handle )
      ::handle := CreateEdit( ::oParent:handle, ::id, ;
                              ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title )
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init()  CLASS HUpDown
   IF ! ::lInit
      Super:Init()
      ::nHolder := 1
      SetWindowObject( ::handle, Self )
      HWG_INITUpDownPROC( ::handle )
      ::hwndUpDown := CreateUpDownControl( ::oParent:handle, ::idUpDown, ;
                                        ::styleUpDown, 0, 0, ::nUpDownWidth, 0, ::handle, ::nUpper, ::nLower, Val( ::title ) )
   ENDIF
   RETURN Nil

METHOD OnEvent( msg, wParam, lParam ) CLASS HUpDown

   IF ::bOther != Nil
      IF Eval( ::bOther,Self,msg,wParam,lParam ) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_CHAR
      IF wParam = VK_TAB
          GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1) )
          RETURN 0
      ELSEIF wParam == VK_RETURN
          GetSkip( ::oParent, ::handle, , 1 )
          RETURN 0
        ENDIF

    ELSEIF msg = WM_KEYDOWN

        ProcKeyList( Self, wParam )

   ELSEIF msg == WM_VSCROLL
    ENDIF

RETURN -1

METHOD Refresh()  CLASS HUpDown

   IF ::bSetGet != Nil
      ::value := Eval( ::bSetGet )
      IF Str( ::value ) != ::title
         ::title := Str( ::value )
         SetUpDown( ::hwndUpDown, ::value )
      ENDIF
   ELSE
      SetUpDown( ::hwndUpDown, Val( ::title ) )
   ENDIF

   RETURN Nil

STATIC FUNCTION __When( oCtrl )
   LOCAL res := .t., oParent, nSkip

   IF ! CheckFocus( oCtrl, .f. )
      RETURN .t.
   ENDIF
   IF oCtrl:bGetFocus != Nil
      oCtrl:Refresh()
      oCtrl:lnoValid := .T.
      oCtrl:oParent:lSuspendMsgsHandling := .t.
      res := Eval( oCtrl:bGetFocus, Eval( oCtrl:bSetGet, , oCtrl ), oCtrl )
      oCtrl:oParent:lSuspendMsgsHandling := .f.
      oCtrl:lnoValid := ! res
      IF ! res
         oParent := ParentGetDialog( oCtrl )
         IF oCtrl == ATail( oParent:GetList )
            nSkip := - 1
         ELSEIF oCtrl == oParent:getList[ 1 ]
            nSkip := 1
         ENDIF
         GetSkip( oCtrl:oParent, oCtrl:handle, , nSkip )
      ENDIF
   ENDIF
   RETURN res

STATIC FUNCTION __Valid( oCtrl )
   LOCAL res := .t., hctrl , nSkip, oDlg
   LOCAL ltab :=  GETKEYSTATE( VK_TAB ) < 0

   IF ! CheckFocus( oCtrl, .t. )  .OR. oCtrl:lnoValid
      RETURN .T.
   ENDIF
   nSkip := IIf( GetKeyState( VK_SHIFT ) < 0 , - 1, 1 )
   oCtrl:title := GetEditText( oCtrl:oParent:handle, oCtrl:id )
   oCtrl:value := Val( LTrim( oCtrl:title ) )
   IF oCtrl:bSetGet != Nil
      Eval( oCtrl:bSetGet, oCtrl:value )
   ENDIF
   oCtrl:oparent:lSuspendMsgsHandling := .t.
   hctrl := getfocus()
   oDlg := ParentGetDialog( oCtrl )
   IF oCtrl:bLostFocus != Nil
      res := Eval( oCtrl:bLostFocus, oCtrl:value,  oCtrl )
      res := IIf( res, oCtrl:value <= oCtrl:nUpper .and. ;
                  oCtrl:value >= oCtrl:nLower , res )
      IF ! res
         SetFocus( oCtrl:handle )
         IF oDlg != Nil
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ENDIF
   IF ltab .AND. hctrl = getfocus() .AND. res
      IF oCtrl:oParent:CLASSNAME = "HTAB"
         getskip( oCtrl:oparent, oCtrl:handle,, nSkip )
      ENDIF
   ENDIF
   oCtrl:oparent:lSuspendMsgsHandling := .F.
   IF empty(GetFocus() ) //= 0
      GetSkip( octrl:oParent, octrl:handle,, octrl:nGetSkip )
   ENDIF

   RETURN res

   */