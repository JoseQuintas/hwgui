/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HDialog class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define  WM_PSPNOTIFY         WM_USER+1010

STATIC aSheet := Nil
STATIC aMessModalDlg := { ;
      { WM_COMMAND, { |o,w,l|onDlgCommand( o,w,l ) } },       ;
      { WM_SIZE, { |o,w,l|hwg_onWndSize( o,w,l ) } },         ;
      { WM_ERASEBKGND, { |o,w|onEraseBk( o,w ) } },           ;
      { WM_PSPNOTIFY, { |o,w,l|onPspNotify( o,w,l ) } },      ;
      { WM_HELP, { |o,w,l|onHelp( o,w,l ) } },                ;
      { WM_ACTIVATE, { |o,w,l|onActivate( o,w,l ) } },        ;
      { WM_INITDIALOG, { |o,w,l|InitModalDlg( o,w,l ) } },    ;
      { WM_DESTROY, { |o|hwg_onDestroy( o ) } }               ;
      }

   // Class HDialog

CLASS HDialog INHERIT HWindow

   CLASS VAR aDialogs       SHARED INIT {}
   CLASS VAR aModalDialogs  SHARED INIT {}

   DATA lModal   INIT .T.
   DATA lResult  INIT .F.     // Becomes TRUE if the OK button is pressed
   DATA lExitOnEnter INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lExitOnEsc   INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lRouteCommand  INIT .F.
   DATA xResourceID
   DATA bOnActivate

   METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc )
   METHOD Activate( lNoModal, bOnActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddItem()      INLINE AAdd( iif( ::lModal,::aModalDialogs,::aDialogs ), Self )
   METHOD DelItem()
   METHOD FindDialog( hWnd )
   METHOD GetActive()
   METHOD CLOSE()    INLINE hwg_EndDialog( ::handle )

ENDCLASS

METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
      bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc ) CLASS HDialog

   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::type     := lType
   ::title    := cTitle
   ::style    := iif( nStyle == Nil, WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX, nStyle )
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
   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus
   ::bOther     := bOther
   ::lClipper   := iif( lClipper == Nil, .F. , lClipper )
   ::lExitOnEnter := iif( lExitOnEnter == Nil, .T. , !lExitOnEnter )
   ::lExitOnEsc  := iif( lExitOnEsc == Nil, .T. , !lExitOnEsc )

   IF nHelpId != nil
      ::HelpId := nHelpId
   ENDIF
   IF Hwg_Bitand( ::style,WS_HSCROLL ) > 0
      ::nScrollBars ++
   ENDIF
   IF  Hwg_Bitand( ::style,WS_VSCROLL ) > 0
      ::nScrollBars += 2
   ENDIF

   RETURN Self

METHOD Activate( lNoModal, bOnActivate ) CLASS HDialog

   LOCAL oWnd, hParent

   ::bOnActivate := bOnActivate
   hwg_CreateGetList( Self )
   hParent := Iif( ::oParent != Nil .AND. ;
      __ObjHasMsg( ::oParent, "HANDLE" ) .AND. ::oParent:handle != Nil .AND. ;
      !Empty( ::oParent:handle ), ::oParent:handle, ;
      Iif( ( oWnd := HWindow():GetMain() ) != Nil,  ;
      oWnd:handle, hwg_Getactivewindow() ) )

   IF ::type == WND_DLG_RESOURCE
      IF lNoModal == Nil .OR. !lNoModal
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

   ELSEIF ::type == WND_DLG_NORESOURCE
      IF lNoModal == Nil .OR. !lNoModal
         ::lModal := .T.
         ::AddItem()
         Hwg_DlgBoxIndirect( hwg_Getactivewindow(), Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::AddItem()
         Hwg_CreateDlgIndirect( hParent, Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HDialog

   LOCAL i
   LOCAL oTab
   LOCAL nPos

   // hwg_writelog( str(msg) + str(wParam) + str(lParam) )
   IF ( i := Ascan( aMessModalDlg, { |a|a[1] == msg } ) ) != 0
      IF ::lRouteCommand .AND. ( msg == WM_COMMAND .OR. msg == WM_NOTIFY )

         nPos := ascan( ::aControls, { |x| x:className() == "HTAB" } )
         IF nPos > 0
            oTab := ::aControls[ nPos ]
            IF Len( oTab:aPages ) > 0
               Eval( aMessModalDlg[i,2], oTab:aPages[oTab:GetActivePage(),1], wParam, lParam )
               RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
            ELSE
               RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
            ENDIF
         ENDIF
         RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
      ENDIF
      RETURN Eval( aMessModalDlg[i,2], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != - 1  .AND. ::bScroll = Nil
            hwg_ScrollHV( Self, msg, wParam, lParam )
         ENDIF
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN 0

METHOD DelItem() CLASS HDialog

   LOCAL i

   IF ::lModal
      IF ( i := Ascan( ::aModalDialogs,{ |o|o == Self } ) ) > 0
         ADel( ::aModalDialogs, i )
         ASize( ::aModalDialogs, Len( ::aModalDialogs ) - 1 )
      ENDIF
   ELSE
      IF ( i := Ascan( ::aDialogs,{ |o|o == Self } ) ) > 0
         ADel( ::aDialogs, i )
         ASize( ::aDialogs, Len( ::aDialogs ) - 1 )
      ENDIF
   ENDIF

   RETURN Nil

METHOD FindDialog( hWnd ) CLASS HDialog

   LOCAL i := Ascan( ::aDialogs, { |o|o:handle == hWnd } )

   RETURN iif( i == 0, Nil, ::aDialogs[i] )

METHOD GetActive() CLASS HDialog

   LOCAL handle := hwg_Getfocus()
   LOCAL i := Ascan( ::Getlist, { |o|o:handle == handle } )

   RETURN iif( i == 0, Nil, ::Getlist[i] )


STATIC FUNCTION InitModalDlg( oDlg, wParam, lParam )

   LOCAL nReturn := 1
   LOCAL aCoors

   IF ValType( oDlg:menu ) == "A"
      hwg__SetMenu( oDlg:handle, oDlg:menu[5] )
   ENDIF
   hwg_InitControls( oDlg, .T. )
   IF oDlg:oIcon != Nil
      hwg_Sendmessage( oDlg:handle, WM_SETICON, 1, oDlg:oIcon:handle )
   ENDIF
   IF oDlg:Title != NIL
      hwg_Setwindowtext( oDlg:Handle, oDlg:Title )
   ENDIF
   IF oDlg:oFont != Nil
      hwg_Sendmessage( oDlg:handle, WM_SETFONT, oDlg:oFont:handle, 0 )
   ENDIF

   IF oDlg:bInit != Nil
      IF ValType( nReturn := Eval( oDlg:bInit, oDlg ) ) != "N"
         nReturn := 1
      ENDIF
   ENDIF
   IF ValType( oDlg:bOnActivate ) == "B"
      Eval( oDlg:bOnActivate )
   ENDIF
   aCoors := hwg_Getwindowrect( oDlg:handle )
   oDlg:nWidth  := aCoors[3] - aCoors[1]
   oDlg:nHeight := aCoors[4] - aCoors[2]

   RETURN nReturn

STATIC FUNCTION onEraseBk( oDlg, hDC )

   LOCAL aCoors

   IF __ObjHasMsg( oDlg, "OBMP" )
      IF oDlg:oBmp != Nil
         hwg_Spreadbitmap( hDC, oDlg:handle, oDlg:oBmp:handle )
         RETURN 1
      ELSE
         aCoors := hwg_Getclientrect( oDlg:handle )
         IF oDlg:brush != Nil
            IF ValType( oDlg:brush ) != "N"
               hwg_Fillrect( hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, oDlg:brush:handle )
            ENDIF
         ELSE
            hwg_Fillrect( hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, COLOR_3DFACE + 1 )
         ENDIF
         RETURN 1
      ENDIF
   ENDIF

   RETURN 0

#define  FLAG_CHECK      2

STATIC FUNCTION onDlgCommand( oDlg, wParam, lParam )

   LOCAL iParHigh := hwg_Hiword( wParam ), iParLow := hwg_Loword( wParam )
   LOCAL aMenu, i, hCtrl

   // WriteLog( Str(iParHigh,10)+"|"+Str(iParLow,10)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF iParHigh == 0
      IF iParLow == IDOK
         hCtrl := hwg_Getfocus()
         FOR i := Len( oDlg:GetList ) TO 1 STEP - 1
            IF !oDlg:GetList[i]:lHide .AND. hwg_Iswindowenabled( oDlg:Getlist[i]:Handle )
               EXIT
            ENDIF
         NEXT
         IF i != 0 .AND. oDlg:GetList[i]:handle == hCtrl
            IF __ObjHasMsg( oDlg:GetList[i], "BVALID" )
               IF Eval( oDlg:GetList[i]:bValid, oDlg:GetList[i] ) .AND. ;
                     oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  hwg_EndDialog( oDlg:handle )
               ENDIF
               RETURN 1
            ENDIF
         ENDIF
         IF oDlg:lClipper
            IF !hwg_GetSkip( oDlg, hCtrl, 1 )
               IF oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  hwg_EndDialog( oDlg:handle )
               ENDIF
            ENDIF
            RETURN 1
         ENDIF
      ELSEIF iParLow == IDCANCEL
         oDlg:nLastKey := 27
      ENDIF
   ENDIF

   IF oDlg:aEvents != Nil .AND. ;
         ( i := Ascan( oDlg:aEvents, { |a|a[1] == iParHigh .AND. a[2] == iParLow } ) ) > 0
      Eval( oDlg:aEvents[ i,3 ], oDlg, iParLow )
   ELSEIF iParHigh == 0 .AND. ( ;
         ( iParLow == IDOK .AND. oDlg:FindControl( IDOK ) != Nil ) .OR. ;
         iParLow == IDCANCEL )
      IF iParLow == IDOK
         oDlg:lResult := .T.
      ENDIF
      //Replaced by Sandro
      IF oDlg:lExitOnEsc
         hwg_EndDialog( oDlg:handle )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "MENU" ) .AND. ValType( oDlg:menu ) == "A" .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:menu,iParLow,@i ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1,i,4 ], FLAG_CHECK ) > 0
         hwg_Checkmenuitem( , aMenu[1,i,3], !hwg_Ischeckedmenuitem( ,aMenu[1,i,3] ) )
      ENDIF
      IF aMenu[ 1,i,1 ] != Nil
         Eval( aMenu[ 1,i,1 ] )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "OPOPUP" ) .AND. oDlg:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:oPopup:aMenu,iParLow,@i ) ) != Nil ;
         .AND. aMenu[ 1,i,1 ] != Nil
      Eval( aMenu[ 1,i,1 ] )
   ENDIF

   RETURN 1

STATIC FUNCTION onActivate( oDlg, wParam, lParam )

   LOCAL iParLow := hwg_Loword( wParam )

   IF iParLow > 0 .AND. oDlg:bGetFocus != Nil
      Eval( oDlg:bGetFocus, oDlg )
   ELSEIF iParLow == 0 .AND. oDlg:bLostFocus != Nil
      Eval( oDlg:bLostFocus, oDlg )
   ENDIF

   RETURN 0

STATIC FUNCTION onHelp( oDlg, wParam, lParam )

   LOCAL oCtrl, nHelpId, oParent

   IF ! Empty( hwg_SetHelpFileName() )
      oCtrl := oDlg:FindControl( nil, hwg_Gethelpdata( lParam ) )
      IF oCtrl != nil
         nHelpId := oCtrl:HelpId
         IF Empty( nHelpId )
            oParent := oCtrl:oParent
            nHelpId := oParent:HelpId
         ENDIF

         hwg_Winhelp( oDlg:handle, hwg_SetHelpFileName(), iif( Empty(nHelpId ), 3, 1 ), nHelpId )

      ENDIF
   ENDIF

   RETURN 0

STATIC FUNCTION onPspNotify( oDlg, wParam, lParam )

   LOCAL nCode := hwg_Getnotifycode( lParam ), res := .T.

   IF nCode == PSN_SETACTIVE
      IF oDlg:bGetFocus != Nil
         res := Eval( oDlg:bGetFocus, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or -1
      Hwg_SetDlgResult( oDlg:handle, iif( res,0, - 1 ) )
      RETURN 1
   ELSEIF nCode == PSN_KILLACTIVE
      IF oDlg:bLostFocus != Nil
         res := Eval( oDlg:bLostFocus, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or 1
      Hwg_SetDlgResult( oDlg:handle, iif( res,0,1 ) )
      RETURN 1
   ELSEIF nCode == PSN_RESET
   ELSEIF nCode == PSN_APPLY
      IF oDlg:bDestroy != Nil
         res := Eval( oDlg:bDestroy, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or 2
      Hwg_SetDlgResult( oDlg:handle, iif( res,0,2 ) )
      IF res
         oDlg:lResult := .T.
      ENDIF
      RETURN 1
   ELSE
      IF oDlg:bOther != Nil
         res := Eval( oDlg:bOther, oDlg, WM_NOTIFY, 0, lParam )
         Hwg_SetDlgResult( oDlg:handle, iif( res,0,1 ) )
         RETURN 1
      ENDIF
   ENDIF

   RETURN 0

FUNCTION hwg_PropertySheet( hParentWindow, aPages, cTitle, x1, y1, width, height, ;
      lModeless, lNoApply, lWizard )

   LOCAL hSheet, i, aHandles := Array( Len( aPages ) ), aTemplates := Array( Len( aPages ) )

   aSheet := Array( Len( aPages ) )
   FOR i := 1 TO Len( aPages )
      IF aPages[i]:type == WND_DLG_RESOURCE
         aHandles[i] := hwg__createpropertysheetpage( aPages[i] )
      ELSE
         aTemplates[i] := hwg_Createdlgtemplate( aPages[i], x1, y1, width, height, WS_CHILD + WS_VISIBLE + WS_BORDER )
         aHandles[i] := hwg__createpropertysheetpage( aPages[i], aTemplates[i] )
      ENDIF
      aSheet[i] := { aHandles[i], aPages[i] }
   NEXT
   hSheet := hwg__propertysheet( hParentWindow, aHandles, Len( aHandles ), cTitle, ;
      lModeless, lNoApply, lWizard )
   FOR i := 1 TO Len( aPages )
      IF aPages[i]:type != WND_DLG_RESOURCE
         hwg_Releasedlgtemplate( aTemplates[i] )
      ENDIF
   NEXT

   RETURN hSheet

FUNCTION hwg_GetModalDlg()

   LOCAL i := Len( HDialog():aModalDialogs )

   RETURN iif( i > 0, HDialog():aModalDialogs[i], 0 )

FUNCTION hwg_GetModalHandle()

   LOCAL i := Len( HDialog():aModalDialogs )

   RETURN iif( i > 0, HDialog():aModalDialogs[i]:handle, 0 )

FUNCTION hwg_EndDialog( handle )

   LOCAL oDlg

   IF handle == Nil
      IF ( oDlg := Atail( HDialog():aModalDialogs ) ) == Nil
         RETURN Nil
      ENDIF
   ELSE
      IF ( ( oDlg := Atail( HDialog():aModalDialogs ) ) == Nil .OR. ;
            oDlg:handle != handle ) .AND. ;
            ( oDlg := HDialog():FindDialog( handle ) ) == Nil
         RETURN Nil
      ENDIF
   ENDIF
   IF oDlg:bDestroy != Nil
      IF Eval( oDlg:bDestroy, oDlg )
         RETURN iif( oDlg:lModal, Hwg__EndDialog( oDlg:handle ), hwg_Destroywindow( oDlg:handle ) )
      ELSE
         RETURN Nil
      ENDIF
   ENDIF

   RETURN  iif( oDlg:lModal, Hwg__EndDialog( oDlg:handle ), hwg_Destroywindow( oDlg:handle ) )

FUNCTION hwg_SetDlgKey( oDlg, nctrl, nkey, block )

   LOCAL i, aKeys

   IF oDlg == Nil ; oDlg := HCustomWindow():oDefaultParent ; ENDIF
   IF nctrl == Nil ; nctrl := 0 ; ENDIF

   IF !__ObjHasMsg( oDlg, "KEYLIST" )
      RETURN .F.
   ENDIF
   aKeys := oDlg:KeyList
   IF block == Nil

      IF ( i := Ascan( aKeys,{ |a|a[1] == nctrl .AND. a[2] == nkey } ) ) == 0
         RETURN .F.
      ELSE
         ADel( oDlg:KeyList, i )
         ASize( oDlg:KeyList, Len( oDlg:KeyList ) - 1 )
      ENDIF
   ELSE
      IF ( i := Ascan( aKeys,{ |a|a[1] == nctrl .AND. a[2] == nkey } ) ) == 0
         AAdd( aKeys, { nctrl, nkey, block } )
      ELSE
         aKeys[i,3] := block
      ENDIF
   ENDIF

   RETURN .T.

   EXIT PROCEDURE Hwg_ExitProcedure
   Hwg_ExitProc()

   RETURN
