/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDialog class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  WM_PSPNOTIFY         WM_USER + 1010

STATIC aSheet := Nil
STATIC aMessModalDlg := { ;
      { WM_COMMAND, { |o,w,l| onDlgCommand( o, w, l ) } },       ;
      { WM_SYSCOMMAND, { |o,w,l| onSysCommand( o, w, l ) } },    ;
      { WM_SIZE, { |o,w,l| onSize( o, w, l ) } },                ;
      { WM_INITDIALOG, { |o,w,l| InitModalDlg( o, w, l ) } },    ;
      { WM_ERASEBKGND, { |o,w| onEraseBk( o, w ) } },            ;
      { WM_DESTROY, { |o| onDestroy( o ) } },                    ;
      { WM_ENTERIDLE, { |o,w,l| onEnterIdle( o, w, l ) } },      ;
      { WM_ACTIVATE, { | o, w,l| onActivate( o, w, l ) } },      ;
      { WM_PSPNOTIFY, { |o,w,l| onPspNotify( o, w, l ) } },      ;
      { WM_HELP, { |o,w,l| hwg_onHelp( o, w, l ) } },            ;
      { WM_CTLCOLORDLG, { |o,w,l| onDlgColor( o, w, l ) } }      ;
      }

STATIC FUNCTION onDestroy( oDlg )

   IF oDlg:oEmbedded != Nil
      oDlg:oEmbedded:END()
   ENDIF
   // IN CLASS INHERIT DIALOG DESTROY APLICATION
   IF oDlg:oDefaultParent:CLASSNAME = "HDIALOG"  .AND. HWindow():GetMain() == Nil
      oDlg:Super:onEvent( WM_DESTROY )
   ENDIF
   oDlg:DelItem()

   RETURN 0

   // Class HDialog

CLASS HDialog INHERIT HWindow

   CLASS VAR aDialogs       SHARED INIT { }
   CLASS VAR aModalDialogs  SHARED INIT { }

   DATA lModal   INIT .T.
   DATA lResult  INIT .F.     // Becomes TRUE if the OK button is pressed
   DATA lRouteCommand  INIT .F.
   DATA bActivate
   DATA lActivated   INIT .F.
   DATA xResourceID
   DATA bOnActivate
   DATA lOnActivated INIT .F.
   DATA WindowState  INIT 0
   DATA lContainer   INIT .F.
   DATA nInitFocus    INIT 0  // Keeps the ID of the object to receive focus when dialog is created
   // you can change the object that receives focus adding
   // ON INIT {|| nInitFocus:=object:[handle] }  to the dialog definition

   METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, ;
      xResourceID, lExitOnEsc, bcolor, bRefresh, lNoClosable )
   METHOD Activate( lNoModal, bOnActivate, nShow )
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddItem()      INLINE AAdd( iif( ::lModal, ::aModalDialogs, ::aDialogs ), Self )
   METHOD DelItem()
   METHOD FindDialog( hWndTitle, lAll )
   METHOD GetActive()
   METHOD CLOSE()    INLINE hwg_EndDialog( ::handle )
   METHOD RELEASE()  INLINE ::Close( ), Self := Nil

ENDCLASS

METHOD NEW( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, ;
      xResourceID, lExitOnEsc, bcolor, bRefresh, lNoClosable ) CLASS HDialog

   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::Type     := lType
   ::title    := cTitle
   ::style    := iif( nStyle == Nil, DS_ABSALIGN + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU, nStyle )
   ::oBmp     := oBmp
   ::oIcon    := oIcon
   ::nTop     := iif( y == Nil, 0, y )
   ::nLeft    := iif( x == Nil, 0, x )
   ::nWidth   := iif( width == Nil, 0, width )
   ::nHeight  := iif( height == Nil, 0, height )
   ::oFont    := oFont
   ::bInit    := bInit
   ::bDestroy := bExit
   ::bSize    := bSize
   ::bPaint   := bPaint
   ::bGetFocus  := bGfocus
   ::bLostFocus := bLfocus
   ::bOther     := bOther
   ::bRefresh   := bRefresh
   ::lClipper   := iif( lClipper == Nil, .F. , lClipper )
   ::lExitOnEnter := iif( lExitOnEnter == Nil, .T. , ! lExitOnEnter )
   ::lExitOnEsc  := iif( lExitOnEsc == Nil, .T. , ! lExitOnEsc )
   ::lClosable   := iif( lnoClosable == Nil, .T. , !lnoClosable )

   IF nHelpId != nil
      ::HelpId := nHelpId
   END
   ::Setcolor( , bColor )
   IF Hwg_Bitand( nStyle, WS_HSCROLL ) > 0
      ::nScrollBars ++
   ENDIF
   IF  Hwg_Bitand( nStyle, WS_VSCROLL ) > 0
      ::nScrollBars += 2
   ENDIF
   ::lContainer := Hwg_Bitand( nStyle, DS_CONTROL ) > 0

   RETURN Self

METHOD Activate( lNoModal, bOnActivate, nShow ) CLASS HDialog
   LOCAL oWnd, hParent

   ::lOnActivated := .T.
   ::bOnActivate := iif( bOnActivate != Nil, bOnActivate, ::bOnActivate )
   hwg_CreateGetList( Self )
   hParent := iif( ::oParent != Nil .AND. ;
      __ObjHasMsg( ::oParent, "HANDLE" ) .AND. ::oParent:handle != Nil ;
      .AND. ! Empty( ::oParent:handle ) , ::oParent:handle, ;
      iif( ( oWnd := HWindow():GetMain() ) != Nil,    ;
      oWnd:handle, hwg_Getactivewindow() ) )

   ::WindowState := iif( ValType( nShow ) = "N", nShow, SW_SHOWNORMAL )

   IF ::Type == WND_DLG_RESOURCE
      IF lNoModal == Nil .OR. ! lNoModal
         ::lModal := .T.
         ::AddItem()
         Hwg_DialogBox( hwg_Getactivewindow(), Self )
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::AddItem()
         Hwg_CreateDialog( hParent, Self )
      ENDIF

   ELSEIF ::Type == WND_DLG_NORESOURCE
      IF lNoModal == Nil .OR. ! lNoModal
         ::lModal := .T.
         ::AddItem()
         Hwg_DlgBoxIndirect( hwg_Getactivewindow(), Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::AddItem()
         Hwg_CreateDlgIndirect( hParent, Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
         IF  ::WindowState > SW_HIDE
            hwg_Setwindowpos( ::Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_FRAMECHANGED )
            hwg_Redrawwindow( ::handle, RDW_UPDATENOW + RDW_NOCHILDREN )
         ENDIF

      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HDialog
   LOCAL i, oTab, nPos, aCoors

   IF msg = WM_GETMINMAXINFO
      IF ::minWidth  > - 1 .OR. ::maxWidth  > - 1 .OR. ;
            ::minHeight > - 1 .OR. ::maxHeight > - 1
         hwg_Minmaxwindow( ::handle, lParam, ;
            iif( ::minWidth  > - 1, ::minWidth, nil ), ;
            iif( ::minHeight > - 1, ::minHeight, nil ), ;
            iif( ::maxWidth  > - 1, ::maxWidth, nil ), ;
            iif( ::maxHeight > - 1, ::maxHeight, nil ) )
         RETURN 0
      ENDIF
   ELSEIF msg = WM_MENUCHAR
      RETURN onSysCommand( Self, SC_KEYMENU, hwg_Loword( wParam ) )
   ELSEIF msg = WM_MOVE
      aCoors := hwg_Getwindowrect( ::handle )
      ::nLeft := aCoors[ 1 ]
      ::nTop  := aCoors[ 2 ]
   ELSEIF  msg = WM_UPDATEUISTATE .AND. hwg_Hiword( wParam ) != UISF_HIDEFOCUS
      // prevent the screen flicker
      RETURN 1
   ELSEIF ! ::lActivated .AND. msg = WM_NCPAINT
      /* triggered on activate the modal dialog is visible only when */
      ::lActivated := .T.
      IF ::lModal .AND. ValType( ::bOnActivate ) == "B"
         hwg_Postmessage( ::Handle, WM_ACTIVATE, hwg_Makewparam( WA_ACTIVE, 0 ), ::handle )
      ENDIF
   ENDIF
   IF ( i := AScan( aMessModalDlg, { | a | a[ 1 ] == msg } ) ) != 0
      IF ::lRouteCommand .AND. ( msg == WM_COMMAND .OR. msg == WM_NOTIFY )
         nPos := AScan( ::aControls, { | x | x:className() == "HTAB" } )
         IF nPos > 0
            oTab := ::aControls[ nPos ]
            IF Len( oTab:aPages ) > 0
               Eval( aMessModalDlg[ i, 2 ], oTab:aPages[ oTab:GetActivePage(), 1 ], wParam, lParam )
            ENDIF
         ENDIF
      ENDIF
      //AgE SOMENTE NO DIALOG
      IF ! ::lSuspendMsgsHandling .OR. msg = WM_ERASEBKGND .OR. msg = WM_SIZE
         //writelog( str(msg) + str(wParam) + str(lParam)+CHR(13) )
         RETURN Eval( aMessModalDlg[ i, 2 ], Self, wParam, lParam )
      ENDIF
   ELSEIF msg = WM_CLOSE
      ::close()
      RETURN 1
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != - 1  .AND. ::bScroll = Nil
            hwg_ScrollHV( Self, msg, wParam, lParam )
         ENDIF
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN 0

METHOD DelItem() CLASS HDialog
   LOCAL i

   IF ::lModal
      IF ( i := AScan( ::aModalDialogs, { | o | o == Self } ) ) > 0
         ADel( ::aModalDialogs, i )
         ASize( ::aModalDialogs, Len( ::aModalDialogs ) - 1 )
      ENDIF
   ELSE
      IF ( i := AScan( ::aDialogs, { | o | o == Self } ) ) > 0
         ADel( ::aDialogs, i )
         ASize( ::aDialogs, Len( ::aDialogs ) - 1 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD FindDialog( hWndTitle, lAll ) CLASS HDialog
   LOCAL cType := ValType( hWndTitle ), i

   IF cType != "C"
      i := AScan( ::aDialogs, { | o | hwg_Selffocus( o:handle, hWndTitle ) } )
      IF i = 0 .AND. ( lAll != Nil .AND. lAll )
         i := AScan( ::aModalDialogs, { | o | hwg_Selffocus( o:handle, hWndTitle ) } )
         RETURN iif( i == 0, Nil, ::aModalDialogs[ i ] )
      ENDIF
   ELSE
      i := AScan( ::aDialogs, { | o | ValType( o:Title ) == "C" .AND. o:Title == hWndTitle } )
      IF i = 0 .AND. ( lAll != Nil .AND. lAll )
         i := AScan( ::aModalDialogs, { | o | ValType( o:Title ) = "C" .AND. o:Title == hWndTitle } )
         RETURN iif( i == 0, Nil, ::aModalDialogs[ i ] )
      ENDIF
   ENDIF

   RETURN iif( i == 0, Nil, ::aDialogs[ i ] )

METHOD GetActive() CLASS HDialog
   LOCAL handle := hwg_Getfocus()
   LOCAL i := AScan( ::Getlist, { | o | o:handle == handle } )

   RETURN iif( i == 0, Nil, ::Getlist[ i ] )

   // End of class
   // ------------------------------------

STATIC FUNCTION InitModalDlg( oDlg, wParam, lParam )
   LOCAL nReturn := 1 , uis

   HB_SYMBOL_UNUSED( lParam )
   HB_SYMBOL_UNUSED( wParam )

   IF ValType( oDlg:menu ) == "A"
      hwg__SetMenu( oDlg:handle, oDlg:menu[5] )
   ENDIF

   oDlg:rect := hwg_Getclientrect( oDlg:handle )

   IF oDlg:oIcon != Nil
      hwg_Sendmessage( oDlg:handle, WM_SETICON, 1, oDlg:oIcon:handle )
   ENDIF
   IF oDlg:oFont != Nil
      hwg_Sendmessage( oDlg:handle, WM_SETFONT, oDlg:oFont:handle, 0 )
   ENDIF
   IF oDlg:Title != NIL
      hwg_Setwindowtext( oDlg:Handle, oDlg:Title )
   ENDIF
   IF ! oDlg:lClosable
      oDlg:Closable( .F. )
   ENDIF

   hwg_InitObjects( oDlg )
   hwg_InitControls( oDlg, .T. )


   IF oDlg:bInit != Nil
      oDlg:lSuspendMsgsHandling := .T.
      IF ValType( nReturn := Eval( oDlg:bInit, oDlg ) ) != "N"
         oDlg:lSuspendMsgsHandling := .F.
         IF ValType( nReturn ) = "L" .AND. ! nReturn
            oDlg:Close()
            RETURN 0
         ENDIF
         nReturn := 1
      ENDIF
   ENDIF
   oDlg:lSuspendMsgsHandling := .F.

   oDlg:nInitFocus := iif( ValType( oDlg:nInitFocus ) = "O", oDlg:nInitFocus:Handle, oDlg:nInitFocus )
   IF  ! Empty( oDlg:nInitFocus )
      IF  hwg_Ptrtoulong( oDlg:FindControl( , oDlg:nInitFocus ):oParent:Handle ) == hwg_Ptrtoulong( oDlg:Handle )
         hwg_Setfocus( oDlg:nInitFocus )
      ENDIF
      nReturn := 0
   ENDIF

   uis := hwg_Sendmessage( oDlg:handle , WM_QUERYUISTATE, 0, 0 )
   // draw focus
   IF  uis != 0
      // triggered to mouse
      hwg_Sendmessage( oDlg:handle, WM_CHANGEUISTATE, hwg_Makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )
   ELSE
      hwg_Sendmessage( oDlg:handle, WM_UPDATEUISTATE, hwg_Makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )
   ENDIF

   // CALL DIALOG NOT VISIBLE
   IF oDlg:WindowState = SW_HIDE .AND. ! oDlg:lModal
      oDlg:Hide()
      oDlg:lHide := .T.
      oDlg:lResult := oDlg
      RETURN oDlg
   ENDIF

   hwg_Postmessage( oDlg:handle, WM_CHANGEUISTATE, hwg_Makelong( UIS_CLEAR, UISF_HIDEFOCUS ), 0 )

   IF ! oDlg:lModal .AND. ! hwg_Iswindowvisible( oDlg:handle )
      hwg_Showwindow( oDlg:Handle, SW_SHOWDEFAULT )
   ENDIF

   IF oDlg:bGetFocus != Nil
      oDlg:lSuspendMsgsHandling := .T.
      Eval( oDlg:bGetFocus, oDlg )
      oDlg:lSuspendMsgsHandling := .F.
   ENDIF

   IF oDlg:WindowState = SW_SHOWMINIMIZED  //2
      oDlg:minimize()
   ELSEIF oDlg:WindowState = SW_SHOWMAXIMIZED  //3
      oDlg:maximize()
   ENDIF

   IF ! oDlg:lModal
      IF ValType( oDlg:bOnActivate ) == "B"
         Eval( oDlg:bOnActivate, oDlg )
      ENDIF
   ENDIF

   oDlg:rect := hwg_Getclientrect( oDlg:handle )
   IF oDlg:nScrollBars > - 1
      AEval( oDlg:aControls, { | o | oDlg:ncurHeight := Max( o:nTop + o:nHeight + VERT_PTS * 4, oDlg:ncurHeight ) } )
      AEval( oDlg:aControls, { | o | oDlg:ncurWidth := Max( o:nLeft + o:nWidth  + HORZ_PTS * 4, oDlg:ncurWidth ) } )
      oDlg:ResetScrollbars()
      oDlg:SetupScrollbars()
   ENDIF

   RETURN nReturn

STATIC FUNCTION onEnterIdle( oDlg, wParam, lParam )
   LOCAL oItem

   HB_SYMBOL_UNUSED( oDlg )

   IF wParam == 0 .AND. ( oItem := ATail( HDialog():aModalDialogs ) ) != Nil ;
         .AND. oItem:handle == lParam .AND. ! oItem:lActivated
      oItem:lActivated := .T.
      IF oItem:bActivate != Nil
         Eval( oItem:bActivate, oItem )
      ENDIF
   ENDIF

   RETURN 0

STATIC FUNCTION onDlgColor( oDlg, wParam, lParam )

   HB_SYMBOL_UNUSED( lParam )

   hwg_Setbkmode( wParam, 1 ) // Transparent mode
   IF oDlg:bcolor != NIL  .AND. ValType( oDlg:brush ) != "N"
      RETURN oDlg:brush:Handle
   ENDIF

   RETURN 0

STATIC FUNCTION onEraseBk( oDlg, hDC )

   IF __ObjHasMsg( oDlg, "OBMP" ) .AND. oDlg:oBmp != Nil
      IF oDlg:lBmpCenter
         hwg_Centerbitmap( hDC, oDlg:handle, oDlg:oBmp:handle, , oDlg:nBmpClr  )
      ELSE
         hwg_Spreadbitmap( hDC, oDlg:handle, oDlg:oBmp:handle )
      ENDIF
      RETURN 1
   ENDIF

   RETURN 0

#define  FLAG_CHECK      2

STATIC FUNCTION onDlgCommand( oDlg, wParam, lParam )

   LOCAL iParHigh := hwg_Hiword( wParam ), iParLow := hwg_Loword( wParam )
   LOCAL aMenu, i, hCtrl, oCtrl, nEsc := .F.

   HB_SYMBOL_UNUSED( lParam )

   IF iParHigh == 0
      IF iParLow == IDOK
         hCtrl := hwg_Getfocus()
         oCtrl := oDlg:FindControl( , hCtrl )
         IF oCtrl == nil .OR. ! hwg_Selffocus( oCtrl:Handle, hCtrl )
            hCtrl := hwg_Getancestor( hCtrl, GA_PARENT )
            oCtrl := oDlg:FindControl( , hCtrl )
         ENDIF

         IF oCtrl != Nil .AND. oCtrl:classname = "HTAB"
            RETURN 1
         ENDIF
         IF oCtrl != Nil .AND. ( hwg_Getnextdlgtabitem( hwg_Getactivewindow() , hCtrl, 1 ) == hCtrl .OR. hwg_Selffocus( oCtrl:Handle, hCtrl ) ) .AND. ! oDlg:lClipper
            hwg_Sendmessage( oCtrl:Handle, WM_KILLFOCUS, 0, 0 )
         ENDIF
         IF oCtrl != Nil .AND. oCtrl:id == IDOK .AND.  __ObjHasMsg( oCtrl, "BCLICK" ) .AND. oCtrl:bClick = Nil
            oDlg:lResult := .T.
            hwg_EndDialog( oDlg:handle )
            RETURN 1
         ENDIF
         IF oDlg:lClipper
            IF oCtrl != Nil .AND. ! hwg_GetSkip( oCtrl:oParent, hCtrl, , 1 )
               IF oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  hwg_EndDialog( oDlg:handle )
               ENDIF
               RETURN 1
            ENDIF
         ENDIF
      ELSEIF iParLow == IDCANCEL
         IF ( oCtrl := oDlg:FindControl( IDCANCEL ) ) != Nil .AND. ! oCtrl:IsEnabled() .AND. oDlg:lExitOnEsc
            oDlg:nLastKey := 27
            IF Empty( hwg_EndDialog( oDlg:handle ) )
               RETURN 1
            ENDIF
            oDlg:bDestroy := Nil
            hwg_Sendmessage( oCtrl:handle, WM_CLOSE, 0, 0 )
            RETURN 0
         ELSEIF oCtrl != Nil .AND. oCtrl:IsEnabled() .AND. ! hwg_Selffocus( oCtrl:Handle )
            hwg_Postmessage( oDlg:handle, WM_NEXTDLGCTL, oCtrl:Handle , 1 )
         ELSEIF oDlg:lGetSkiponEsc
            hCtrl := hwg_Getfocus()
            oCtrl := oDlg:FindControl( , hctrl )
            IF oCtrl  != Nil .AND. __ObjHasMsg( oCtrl, "OGROUP" )  .AND. oCtrl:oGroup:oHGroup != Nil
               oCtrl := oCtrl:oGroup:oHGroup
               hCtrl := oCtrl:handle
            ENDIF
            IF oCtrl  != Nil .AND. hwg_GetSkip( oCtrl:oParent, hCtrl, , - 1 )
               IF AScan( oDlg:GetList, { | o | o:handle == hCtrl } ) > 1
                  RETURN 1
               ENDIF
            ENDIF
         ENDIF
         nEsc := ( hwg_Getkeystate( VK_ESCAPE ) < 0 )
      ELSEIF iParLow == IDHELP  // HELP
         hwg_Sendmessage( oDlg:Handle, WM_HELP, 0, 0 )
      ENDIF
   ENDIF

   //IF oDlg:nInitFocus > 0 //.AND. !hwg_Iswindowvisible( oDlg:handle )
   // comentado, vc não pode testar um ponteiro como se fosse numerico
   IF __ObjHasMsg( oDlg, "NINITFOCUS" ) .AND. !Empty( oDlg:nInitFocus )
      hwg_Postmessage( oDlg:Handle, WM_NEXTDLGCTL, oDlg:nInitFocus , 1 )
      oDlg:nInitFocus := 0
   ENDIF
   IF oDlg:aEvents != Nil .AND. ;
         ( i := AScan( oDlg:aEvents, { | a | a[ 1 ] == iParHigh .AND. a[ 2 ] == iParLow } ) ) > 0
      IF ! oDlg:lSuspendMsgsHandling
         Eval( oDlg:aEvents[ i, 3 ], oDlg, iParLow )
      ENDIF
   ELSEIF iParHigh == 0 .AND. ( ;
         ( iParLow == IDOK .AND. oDlg:FindControl( IDOK ) != nil ) .OR. ;
         iParLow == IDCANCEL )
      IF iParLow == IDOK
         oDlg:lResult := .T.
         IF ( oCtrl := oDlg:FindControl( IDOK ) ) != Nil .AND. __ObjHasMsg( oCtrl, "BCLICK" ) .AND. oCtrl:bClick != Nil
            RETURN 1
         ELSEIF oDlg:lExitOnEnter  .OR. oCtrl  != Nil
            hwg_EndDialog( oDlg:handle )
         ENDIF
      ENDIF
      //Replaced by Sandro
      IF iParLow == IDCANCEL .AND. ( oDlg:lExitOnEsc .OR. ! nEsc )
         oDlg:nLastKey := 27
         hwg_EndDialog( oDlg:handle )
      ELSEIF ! oDlg:lExitOnEsc
         oDlg:nLastKey := 0
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "MENU" ) .AND. ValType( oDlg:menu ) == "A" .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:menu, iParLow, @i ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1, i, 4 ], FLAG_CHECK ) > 0
         hwg_Checkmenuitem( , aMenu[ 1, i, 3 ], ! hwg_Ischeckedmenuitem( , aMenu[ 1, i, 3 ] ) )
      ENDIF
      IF aMenu[ 1, i, 1 ] != Nil
         Eval( aMenu[ 1, i, 1 ], i, iParlow )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "OPOPUP" ) .AND. oDlg:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:oPopup:aMenu, wParam, @i ) ) != Nil ;
         .AND. aMenu[ 1, i, 1 ] != Nil
      Eval( aMenu[ 1, i, 1 ], i, wParam )
   ENDIF

   RETURN 1

FUNCTION hwg_DlgMouseMove()

   LOCAL oBtn := hwg_SetNiceBtnSelected()

   IF oBtn != Nil .AND. ! oBtn:lPress
      oBtn:state := OBTN_NORMAL
      hwg_Invalidaterect( oBtn:handle, 0 )
      // hwg_Postmessage( oBtn:handle, WM_PAINT, 0, 0 )
      hwg_SetNiceBtnSelected( Nil )
   ENDIF

   RETURN 0

STATIC FUNCTION onSize( oDlg, wParam, lParam )

   LOCAL aControls, iCont , nW1, nH1

   IF oDlg:oEmbedded != Nil
      oDlg:oEmbedded:Resize( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ENDIF
   nW1 := oDlg:nWidth
   nH1 := oDlg:nHeight
   IF wParam != 1  //SIZE_MINIMIZED
      oDlg:nWidth := hwg_Loword( lParam )
      oDlg:nHeight := hwg_Hiword( lParam )
   ENDIF
   // SCROLL BARS code here.
   IF oDlg:nScrollBars > - 1 .AND. oDlg:lAutoScroll
      oDlg:ResetScrollbars()
      oDlg:SetupScrollbars()
   ENDIF

   IF oDlg:bSize != Nil .AND. ;
         ( oDlg:oParent == Nil .OR. ! __ObjHasMsg( oDlg:oParent, "ACONTROLS" ) )
      Eval( oDlg:bSize, oDlg, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ENDIF
   aControls := oDlg:aControls
   IF aControls != Nil .AND. !Empty( oDlg:Rect )
      oDlg:Anchor( oDlg, nW1, nH1, oDlg:nWidth, oDlg:nHeight )
      FOR iCont := 1 TO Len( aControls )
         IF aControls[ iCont ]:bSize != Nil
            Eval( aControls[ iCont ]:bSize, ;
               aControls[ iCont ], hwg_Loword( lParam ), hwg_Hiword( lParam ), nW1, nH1 )
         ENDIF
      NEXT
   ENDIF

   RETURN 0

STATIC FUNCTION onActivate( oDlg, wParam, lParam )
   LOCAL iParLow := hwg_Loword( wParam ), iParHigh := hwg_Hiword( wParam )

   IF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE ) .AND. oDlg:lContainer .AND. ;
         ! hwg_Selffocus( lParam, oDlg:Handle )
      hwg_Updatewindow( oDlg:Handle )
      hwg_Sendmessage( lParam, WM_NCACTIVATE, 1, Nil )
      RETURN 0
   ENDIF
   IF  iParLow = WA_ACTIVE  .AND. hwg_Selffocus( lParam, oDlg:Handle )
      IF ValType( oDlg:bOnActivate ) == "B"
         //- oDlg:lSuspendMsgsHandling := .t.
         Eval( oDlg:bOnActivate, oDlg )
         //-oDlg:lSuspendMsgsHandling := .F.
      ENDIF

   ELSEIF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE ) .AND. hwg_Iswindowvisible( oDlg:handle ) //.AND. hwg_Ptrtoulong( lParam ) = 0
      IF oDlg:bGetFocus != Nil
         oDlg:lSuspendMsgsHandling := .T.
         IF iParHigh > 0  // MINIMIZED

         ENDIF
         Eval( oDlg:bGetFocus, oDlg, lParam )
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF iParLow = WA_INACTIVE  .AND. oDlg:bLostFocus != Nil
      oDlg:lSuspendMsgsHandling := .T.
      Eval( oDlg:bLostFocus, oDlg, lParam  )
      oDlg:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN 0

FUNCTION hwg_onHelp( oDlg, wParam, lParam )

   LOCAL oCtrl, nHelpId, oParent, cDir

   HB_SYMBOL_UNUSED( wParam )

   IF ! Empty( hwg_SetHelpFileName() )
      IF "chm" $ Lower( CutPath( hwg_SetHelpFileName() ) )
         cDir := iif( Empty( FilePath( hwg_SetHelpFileName() ) ), CurDir(), FilePath( hwg_SetHelpFileName() ) )
      ENDIF
      IF ! Empty( lParam )
         oCtrl := oDlg:FindControl( Nil, hwg_Gethelpdata( lParam ) )
      ENDIF
      IF oCtrl != nil
         nHelpId := oCtrl:HelpId
         IF Empty( nHelpId )
            oParent := oCtrl:oParent
            nHelpId := iif( Empty( oParent:HelpId ), oDlg:HelpId, oParent:HelpId )
         ENDIF
         IF "chm" $ Lower( CutPath( hwg_SetHelpFileName() ) )
            nHelpId := iif( ValType( nHelpId ) = "N", LTrim( Str( nHelpId ) ), nHelpId )
            hwg_Shellexecute( "hh.exe", "open", CutPath( hwg_SetHelpFileName() ) + "::" + nHelpId + ".html", cDir )
         ELSE
            hwg_Winhelp( oDlg:handle, hwg_SetHelpFileName(), iif( Empty( nHelpId ), 3, 1 ), nHelpId )
         ENDIF
      ELSEIF cDir != Nil
         hwg_Shellexecute( "hh.exe", "open", CutPath( hwg_SetHelpFileName() )  , cDir )
      ELSE
         hwg_Winhelp( oDlg:handle, hwg_SetHelpFileName(), iif( Empty( oDlg:HelpId ), 3, 1 ), oDlg:HelpId )
      ENDIF
   ENDIF

   RETURN 1

STATIC FUNCTION onPspNotify( oDlg, wParam, lParam )
   LOCAL nCode := hwg_Getnotifycode( lParam ), res := .T.

   HB_SYMBOL_UNUSED( wParam )

   IF nCode == PSN_SETACTIVE
      IF oDlg:bGetFocus != Nil
         oDlg:lSuspendMsgsHandling := .T.
         res := Eval( oDlg:bGetFocus, oDlg )
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
      // 'res' should be 0(Ok) or -1

      Hwg_SetDlgResult( oDlg:handle, iif( res, 0, - 1 ) )
      RETURN 1
   ELSEIF nCode == PSN_KILLACTIVE
      IF oDlg:bLostFocus != Nil
         oDlg:lSuspendMsgsHandling := .T.
         res := Eval( oDlg:bLostFocus, oDlg )
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
      // 'res' should be 0(Ok) or 1
      Hwg_SetDlgResult( oDlg:handle, iif( res, 0, 1 ) )
      RETURN 1
   ELSEIF nCode == PSN_RESET
   ELSEIF nCode == PSN_APPLY
      IF oDlg:bDestroy != Nil
         res := Eval( oDlg:bDestroy, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or 2
      Hwg_SetDlgResult( oDlg:handle, iif( res, 0, 2 ) )
      IF res
         oDlg:lResult := .T.
      ENDIF
      RETURN 1
   ELSE
      IF oDlg:bOther != Nil
         res := Eval( oDlg:bOther, oDlg, WM_NOTIFY, 0, lParam )
         Hwg_SetDlgResult( oDlg:handle, iif( res, 0, 1 ) )
         RETURN 1
      ENDIF
   ENDIF

   RETURN 0

FUNCTION hwg_PropertySheet( hParentWindow, aPages, cTitle, x1, y1, width, height, ;
      lModeless, lNoApply, lWizard )

   LOCAL hSheet, i, aHandles := Array( Len( aPages ) ), aTemplates := Array( Len( aPages ) )

   aSheet := Array( Len( aPages ) )
   FOR i := 1 TO Len( aPages )
      IF aPages[ i ]:Type == WND_DLG_RESOURCE
         aHandles[ i ] := hwg__createpropertysheetpage( aPages[ i ] )
      ELSE
         aTemplates[ i ] := hwg_Createdlgtemplate( aPages[ i ], x1, y1, width, height, WS_CHILD + WS_VISIBLE + WS_BORDER )
         aHandles[ i ] := hwg__createpropertysheetpage( aPages[ i ], aTemplates[ i ] )
      ENDIF
      aSheet[ i ] := { aHandles[ i ], aPages[ i ] }
      // Writelog( "h: "+str(aHandles[i]) )
   NEXT
   hSheet := hwg__propertysheet( hParentWindow, aHandles, Len( aHandles ), cTitle, ;
      lModeless, lNoApply, lWizard )
   FOR i := 1 TO Len( aPages )
      IF aPages[ i ]:Type != WND_DLG_RESOURCE
         hwg_Releasedlgtemplate( aTemplates[ i ] )
      ENDIF
   NEXT

   RETURN hSheet

FUNCTION hwg_GetModalDlg

   LOCAL i := Len( HDialog():aModalDialogs )

   RETURN iif( i > 0, HDialog():aModalDialogs[ i ], 0 )

FUNCTION hwg_GetModalHandle

   LOCAL i := Len( HDialog():aModalDialogs )

   RETURN iif( i > 0, HDialog():aModalDialogs[ i ]:handle, 0 )

FUNCTION hwg_EndDialog( handle )

   LOCAL oDlg, hFocus := hwg_Getfocus(), oCtrl
   LOCAL res

   IF handle == Nil
      IF ( oDlg := ATail( HDialog():aModalDialogs ) ) == Nil
         RETURN Nil
      ENDIF
   ELSE
      IF ( ( oDlg := ATail( HDialog():aModalDialogs ) ) == Nil .OR. ;
            oDlg:handle != handle ) .AND. ;
            ( oDlg := HDialog():FindDialog( handle ) ) == Nil
         RETURN Nil
      ENDIF
   ENDIF
   // force control triggered killfocus
   IF ! Empty( hFocus ) .AND. ( oCtrl := oDlg:FindControl( , hFocus ) ) != Nil .AND. ;
         oCtrl:bLostFocus != Nil .AND. oDlg:lModal
      hwg_Sendmessage( hFocus, WM_KILLFOCUS, 0, 0 )
   ENDIF
   IF oDlg:bDestroy != Nil
      //oDlg:lSuspendMsgsHandling := .T.
      res := Eval( oDlg:bDestroy, oDlg )
      //oDlg:lSuspendMsgsHandling := .F.
      IF ! res
         oDlg:nLastKey := 0
         RETURN Nil
      ENDIF
   ENDIF

   RETURN  iif( oDlg:lModal, Hwg__EndDialog( oDlg:handle ), hwg_Destroywindow( oDlg:handle ) )

FUNCTION hwg_SetDlgKey( oDlg, nctrl, nkey, block )

   LOCAL i, aKeys, bOldSet

   IF oDlg == Nil ; oDlg := HCustomWindow():oDefaultParent ; ENDIF
   IF nctrl == Nil ; nctrl := 0 ; ENDIF

   IF ! __ObjHasMsg( oDlg, "KEYLIST" )
      RETURN nil
   ENDIF
   aKeys := oDlg:KeyList
   IF ( i := AScan( aKeys, { | a | a[ 1 ] == nctrl .AND. a[ 2 ] == nkey } ) ) > 0
      bOldSet := aKeys[ i, 3 ]
   ENDIF
   IF block == Nil
      IF i > 0
         ADel( oDlg:KeyList, i )
         ASize( oDlg:KeyList, Len( oDlg:KeyList ) - 1 )
      ENDIF
   ELSE
      IF i == 0
         AAdd( aKeys, { nctrl, nkey, block } )
      ELSE
         aKeys[ i, 3 ] := block
      ENDIF
   ENDIF

   RETURN bOldSet

STATIC FUNCTION onSysCommand( oDlg, wParam, lParam )
   LOCAL oCtrl

   IF wParam == SC_CLOSE
      IF ! oDlg:Closable
         RETURN 1
      ENDIF
   ELSEIF wParam == SC_MINIMIZE
   ELSEIF wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2
   ELSEIF wParam == SC_RESTORE .OR. wParam == SC_RESTORE2
   ELSEIF wParam = SC_NEXTWINDOW .OR. wParam = SC_PREVWINDOW
   ELSEIF wParam = SC_KEYMENU
      // accelerator IN TAB/CONTAINER
      IF ( oCtrl := hwg_FindAccelerator( oDlg, lParam ) ) != Nil
         oCtrl:Setfocus()
         hwg_Sendmessage( oCtrl:handle, WM_SYSKEYUP, lParam, 0 )
         RETURN 2
      ENDIF
   ELSEIF wParam = SC_HOTKEY
   ELSEIF wParam = SC_MENU
   ELSEIF wParam = 61824  //button help
   ENDIF

   RETURN - 1

   EXIT PROCEDURE Hwg_ExitProcedure
   Hwg_ExitProc()

   RETURN
