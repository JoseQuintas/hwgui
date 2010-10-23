/*
 * $Id: hdialog.prg,v 1.124 2010-10-23 20:34:56 giuseppem Exp $
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
       { WM_COMMAND, { | o, w, l | DlgCommand( o, w, l ) } },         ;
       { WM_SYSCOMMAND, { | o, w, l | onSysCommand( o, w, l ) } },    ;
       { WM_SIZE, { | o, w, l | onSize( o, w, l ) } },                ;
       { WM_INITDIALOG, { | o, w, l | InitModalDlg( o, w, l ) } },    ;
       { WM_ERASEBKGND, { | o, w | onEraseBk( o, w ) } },             ;
       { WM_DESTROY, { | o | onDestroy( o ) } },                      ;
       { WM_ENTERIDLE, { | o, w, l | onEnterIdle( o, w, l ) } },      ;
       { WM_ACTIVATE, { | o, w, l | onActivate( o, w, l ) } },        ;
       { WM_PSPNOTIFY, { | o, w, l | onPspNotify( o, w, l ) } },      ;
       { WM_HELP, { | o, w, l | onHelp( o, w, l ) } },                ;
       { WM_CTLCOLORDLG, {| o, w, l | onDlgColor( o, w, l ) } }       ;       
     }

STATIC FUNCTION onDestroy( oDlg )

   IF oDlg:oEmbedded != Nil
      oDlg:oEmbedded:END()
   ENDIF
   // IN CLASS INHERIT DIALOG DESTROY APLICATION
   IF oDlg:oDefaultParent:ClassName = "HDIALOG" .AND. oDlg:lModal
      oDlg:Super:onEvent( WM_DESTROY )
   ENDIF  
   oDlg:Del()

   RETURN 0

// Class HDialog

CLASS HDialog INHERIT HCustomWindow

CLASS VAR aDialogs       SHARED INIT { }
CLASS VAR aModalDialogs  SHARED INIT { }

   DATA menu
   DATA oPopup                // Context menu for a dialog
   DATA lBmpCenter INIT .F.
   DATA nBmpClr
   
   DATA lModal   INIT .T.
   DATA lResult  INIT .F.     // Becomes TRUE if the OK button is pressed
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lClipper INIT .F.     // Set it to TRUE for moving between GETs with ENTER key
   DATA GetList  INIT { }      // The array of GET items in the dialog
   DATA KeyList  INIT { }      // The array of keys ( as Clipper's SET KEY )
   DATA lExitOnEnter INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lExitOnEsc   INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lRouteCommand  INIT .F.
   DATA nLastKey INIT 0
   DATA oIcon, oBmp
   DATA bActivate
   DATA lActivated INIT .F.
   DATA xResourceID
   DATA oEmbedded
   DATA bOnActivate
   DATA nInitShow INIT 0
   DATA nScrollBars INIT - 1
   DATA bScroll

   METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
               bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId,;
               xResourceID, lExitOnEsc, bcolor, bRefresh, lNoClosable )
   METHOD Activate( lNoModal, bOnActivate, nShow )
   METHOD onEvent( msg, wParam, lParam )
   METHOD Add()      INLINE AAdd( IIf( ::lModal, ::aModalDialogs, ::aDialogs ), Self )
   METHOD Del()
   METHOD FindDialog( hWnd )
   METHOD GetActive()
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle , ::Type )
   METHOD Restore()  INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_RESTORE, 0 )
   METHOD Maximize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
   METHOD Minimize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MINIMIZE, 0 )
   METHOD Close()    INLINE EndDialog( ::handle )
   METHOD Release()  INLINE ::Close( ), Self := Nil

ENDCLASS

METHOD NEW( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
            bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId,;
            xResourceID, lExitOnEsc, bcolor, bRefresh, lNoClosable ) CLASS HDialog

   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::Type     := lType
   ::title    := cTitle
   ::style    := IIf( nStyle == Nil, DS_ABSALIGN + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU, nStyle )
   ::oBmp     := oBmp
   ::oIcon    := oIcon
   ::nTop     := IIf( y == Nil, 0, y )
   ::nLeft    := IIf( x == Nil, 0, x )
   ::nWidth   := IIf( width == Nil, 0, width )
   ::nHeight  := IIf( height == Nil, 0, height )
   ::oFont    := oFont
   ::bInit    := bInit
   ::bDestroy := bExit
   ::bSize    := bSize
   ::bPaint   := bPaint
   ::bGetFocus  := bGfocus
   ::bLostFocus := bLfocus
   ::bOther     := bOther
   ::bRefresh   := bRefresh
   ::lClipper   := IIf( lClipper == Nil, .F., lClipper )
   ::lExitOnEnter := IIf( lExitOnEnter == Nil, .T., ! lExitOnEnter )
   ::lExitOnEsc  := IIf( lExitOnEsc == Nil, .T., ! lExitOnEsc )
   ::lClosable   := Iif( lnoClosable==Nil, .T., !lnoClosable )

   IF nHelpId != nil
      ::HelpId := nHelpId
   END
   ::SetColor( , bColor )
   IF Hwg_Bitand( nStyle, WS_HSCROLL ) > 0
      ::nScrollBars ++
   ENDIF
   IF  Hwg_Bitand( nStyle, WS_VSCROLL ) > 0
      ::nScrollBars += 2
   ENDIF

   RETURN Self


METHOD Activate( lNoModal, bOnActivate, nShow ) CLASS HDialog
   LOCAL oWnd, hParent
   
   ::lActivated := .t.
   ::bOnActivate := bOnActivate
   CreateGetList( Self )
   hParent := IIf( ::oParent != Nil .AND. ;
                   __ObjHasMsg( ::oParent, "HANDLE" ) .AND. ::oParent:handle != Nil ;
                   .AND. ! Empty( ::oParent:handle ) , ::oParent:handle, ;
                   IIf( ( oWnd := HWindow():GetMain() ) != Nil,    ;
                        oWnd:handle, GetActiveWindow() ) )

   ::nInitShow := IIf( ValType( nShow ) = "N", nShow, SW_SHOWNORMAL )
   IF ::Type == WND_DLG_RESOURCE
      IF lNoModal == Nil .OR. ! lNoModal
         ::lModal := .T.
         ::Add()
         // Hwg_DialogBox( HWindow():GetMain():handle,Self )
         Hwg_DialogBox( GetActiveWindow(), Self )
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::Add()
         Hwg_CreateDialog( hParent, Self )
         /*
         IF ::oIcon != Nil
            SendMessage( ::handle,WM_SETICON,1,::oIcon:handle )
         ENDIF
         */
      ENDIF
      /*
      IF ::title != NIL
          SetWindowText( ::handle, ::title )
      ENDIF
      */

   ELSEIF ::Type == WND_DLG_NORESOURCE
      IF lNoModal == Nil .OR. ! lNoModal
         ::lModal := .T.
         ::Add()
         // Hwg_DlgBoxIndirect( HWindow():GetMain():handle,Self,::nLeft,::nTop,::nWidth,::nHeight,::style )
         Hwg_DlgBoxIndirect( GetActiveWindow(), Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::Add()
         Hwg_CreateDlgIndirect( hParent, Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style )
         
         IF  ::nInitShow > SW_HIDE
            BRINGTOTOP( ::handle )
            UPDATEWINDOW( ::handle ) 
         ENDIF   

         /*
         IF ::oIcon != Nil
            SendMessage( ::handle,WM_SETICON,1,::oIcon:handle )
         ENDIF
         */
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HDialog
   LOCAL i, oTab, nPos, aCoors

   IF msg = WM_GETMINMAXINFO
      IF ::minWidth  > - 1 .OR. ::maxWidth  > - 1 .OR. ;
         ::minHeight > - 1 .OR. ::maxHeight > - 1
         MINMAXWINDOW( ::handle, lParam, ;
                       IIf( ::minWidth  > - 1, ::minWidth, nil ), ;
                       IIf( ::minHeight > - 1, ::minHeight, nil ), ;
                       IIf( ::maxWidth  > - 1, ::maxWidth, nil ), ;
                       IIf( ::maxHeight > - 1, ::maxHeight, nil ) )
         RETURN 0
      ENDIF
   ELSEIF msg = WM_MENUCHAR
      RETURN onSysCommand( Self, SC_KEYMENU, LoWord( wParam ) )
	 ELSEIF msg = WM_MOVE //.or. msg = 0x216
      aCoors := GetWindowRect( ::handle )
      ::nLeft := aCoors[ 1 ]
			::nTop  := aCoors[ 2 ]
   ENDIF
   IF ( i := AScan( aMessModalDlg, { | a | a[ 1 ] == msg } ) ) != 0
      IF ::lRouteCommand .and. ( msg == WM_COMMAND .or. msg == WM_NOTIFY )
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
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != - 1  .AND. ::bScroll = Nil
            Super:ScrollHV( Self, msg, wParam, lParam )
         ENDIF
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN 0

METHOD Del() CLASS HDialog
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

METHOD FindDialog( hWnd ) CLASS HDialog
   LOCAL i := AScan( ::aDialogs, { | o | o:handle == hWnd } )
   RETURN IIf( i == 0, Nil, ::aDialogs[ i ] )

METHOD GetActive() CLASS HDialog
   LOCAL handle := GetFocus()
   LOCAL i := AScan( ::Getlist, { | o | o:handle == handle } )
   RETURN IIf( i == 0, Nil, ::Getlist[ i ] )

// End of class
// ------------------------------------

STATIC FUNCTION InitModalDlg( oDlg, wParam, lParam )
   LOCAL nReturn := 1 , uis

   // HB_SYMBOL_UNUSED( wParam )
   HB_SYMBOL_UNUSED( lParam )

   // oDlg:handle := hDlg
   // writelog( str(oDlg:handle)+" "+oDlg:title )
   *  .if uMsg == WM_INITDIALOG
   *-EnableThemeDialogTexture(odlg:handle,6)  //,ETDT_ENABLETAB)

   IF Valtype( oDlg:menu ) == "A"
      hwg__SetMenu( oDlg:handle, oDlg:menu[5] )
   ENDIF   
   
   oDlg:rect := GetWindowRect( odlg:handle )

   IF oDlg:nScrollBars > - 1    
      AEval( oDlg:aControls, { | o | oDlg:ncurHeight := max( o:nTop + o:nHeight + GETSYSTEMMETRICS( SM_CYCAPTION ) + GETSYSTEMMETRICS( SM_CYCAPTION ) + 12 , oDlg:ncurHeight ) } )  
      AEval( oDlg:aControls, { | o | oDlg:ncurWidth := max( o:nLeft + o:nWidth  + 24 , oDlg:ncurWidth ) } )  
      oDlg:ResetScrollbars()
      oDlg:SetupScrollbars()
   ENDIF

   IF oDlg:oIcon != Nil
      SendMessage( oDlg:handle, WM_SETICON, 1, oDlg:oIcon:handle )
   ENDIF
   IF oDlg:Title != NIL
      SetWindowText( oDlg:Handle, oDlg:Title )
   ENDIF
   IF oDlg:oFont != Nil
      SendMessage( oDlg:handle, WM_SETFONT, oDlg:oFont:handle, 0 )
   ENDIF
   IF ! oDlg:lClosable
      oDlg:Closable( .F. )
   ENDIF

   InitObjects( oDlg )
   InitControls( oDlg, .T. )
   
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
   // draw focus
   uis := SendMESSAGE( oDlg:handle , WM_QUERYUISTATE, 0, 0 )
   IF uis != 0
      POSTMESSAGE( oDlg:handle, WM_CHANGEUISTATE, makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )  
      POSTMESSAGE( oDlg:handle, WM_CHANGEUISTATE, makelong( UIS_CLEAR, UISF_HIDEFOCUS ), 0 )  
   ELSE
      POSTMESSAGE( oDlg:handle, WM_UPDATEUISTATE, makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )                            
      POSTMESSAGE( oDlg:handle, WM_UPDATEUISTATE, makelong( UIS_CLEAR, UISF_HIDEFOCUS ), 0 ) 
   ENDIF 
   
   oDlg:nInitFocus := IIF( VALTYPE( oDlg:nInitFocus ) = "O", oDlg:nInitFocus:Handle, oDlg:nInitFocus )   
   IF  ! EMPTY( oDlg:nInitFocus ) 
      SETFOCUS( oDlg:nInitFocus )
      nReturn := 0
   ENDIF
   
   // CALL DIALOG NOT VISIBLE
   IF oDlg:nInitShow = SW_HIDE .AND. ! oDlg:lModal            
      oDlg:Hide()
      oDlg:lHide := .T.
      oDlg:lResult := oDlg
      oDlg:nInitShow := SW_SHOWNORMAL
      RETURN oDlg
   ENDIF

   IF oDlg:bGetFocus != Nil
      oDlg:lSuspendMsgsHandling := .t.
      Eval( oDlg:bGetFocus, oDlg )
      oDlg:lSuspendMsgsHandling := .f.
   ENDIF
   
	 IF ! isWindowVisible( oDlg:handle )	
	    SHOWWINDOW( oDlg:Handle, SW_SHOWDEFAULT ) // Sets the show state based on the SW_ value specified in the STARTUPINFO structure passed to the CreateProcess function by the program that started the application. 
   ENDIF      
   InvalidateRect( oDlg:handle, 0 ) 
   
   IF oDlg:nInitShow = SW_SHOWMINIMIZED  //2
      oDlg:minimize()
   ELSEIF oDlg:nInitShow = SW_SHOWMAXIMIZED  //3
      oDlg:maximize()
   ENDIF
   //IF ! oDlg:lModal
   //   oDlg:show()
   //ENDIF
   
   IF ValType( oDlg:bOnActivate ) == "B"
      Eval( oDlg:bOnActivate, oDlg )
   ENDIF

   	 // adjust values of MIN and MAX size to Anchor work correctly   
   oDlg:rect  := GetWindowRect( oDlg:Handle )
   oDlg:nLeft := oDlg:rect[ 1 ]  
   oDlg:nTop  := oDlg:rect[ 2 ] 
   oDlg:rect := GetClientRect( oDlg:Handle )
   oDlg:nWidth  := oDlg:rect[ 3 ]
   oDlg:nHeight := oDlg:rect[ 4 ]

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

   HB_SYMBOL_UNUSED(lParam)
   
   SetBkMode( wParam, 1 ) // Transparent mode
   IF oDlg:bcolor != NIL  .AND. Valtype( oDlg:brush ) != "N"
       RETURN oDlg:brush:Handle
   ENDIF  
   RETURN 0 //hBrTemp:handle

STATIC FUNCTION onEraseBk( oDlg, hDC )
   LOCAL aCoors

    IF __ObjHasMsg( oDlg,"OBMP") .AND. oDlg:oBmp != Nil
       IF oDlg:lBmpCenter
          CenterBitmap( hDC, oDlg:handle, oDlg:oBmp:handle, , oDlg:nBmpClr  )               
       ELSE
          SpreadBitmap( hDC, oDlg:handle, oDlg:oBmp:handle )
       ENDIF
       Return 1
    ELSE
       aCoors := GetClientRect( oDlg:handle )
       /*
       IF oDlg:brush != Nil
          IF ValType( oDlg:brush ) != "N"
             FillRect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, oDlg:brush:handle )
          ENDIF
       ELSE
          FillRect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, COLOR_3DFACE + 1 )
       ENDIF
       RETURN 1
       */
       //FillRect( hDC, aCoors[1], aCoors[2], aCoors[1] + 1, aCoors[2] + 1 )
    ENDIF

    RETURN 0

   #define  FLAG_CHECK      2

FUNCTION DlgCommand( oDlg, wParam, lParam )
   LOCAL iParHigh := HIWORD( wParam ), iParLow := LOWORD( wParam )
   LOCAL aMenu, i, hCtrl, oCtrl, nEsc := .F.


   HB_SYMBOL_UNUSED( lParam )

   IF iParHigh == 0
      IF iParLow == IDOK
         hCtrl := GetFocus()
         oCtrl := oDlg:FindControl(, hCtrl )
         IF oCtrl == nil
            hCtrl := GetAncestor( hCtrl, GA_PARENT )
            IF ( oCtrl := oDlg:FindControl( , hCtrl ) ) != Nil
               GetSkip( oCtrl:oParent, hCtrl, , 1 )
            ENDIF
         ENDIF

         IF oCtrl != Nil .AND. oCtrl:classname = "HTAB"
            RETURN 1
         ENDIF
         IF oCtrl != Nil .AND. GetNextDlgTabItem( GetActiveWindow() , hCtrl, 1 ) == hCtrl
            *IF __ObjHasMsg(oCtrl,"BVALID") .AND. oCtrl:bValid != NIl
            IF  __ObjHasMsg( oCtrl, "BLOSTFOCUS" ) .AND. oCtrl:blostfocus != NIl .AND. !oDlg:lClipper
               oCtrl:setfocus()
               IF __ObjHasMsg( oCtrl, "BVALID" )
                  Eval( oCtrl:bValid, oCtrl )
                  oCtrl:Refresh()
               ELSE
                  Eval( oCtrl:bLostFocus, oCtrl )
               ENDIF
            ENDIF
         ENDIF
         IF oCtrl != Nil .AND. oCtrl:id == IDOK .AND.  __ObjHasMsg( oCtrl,"BCLICK" ) .AND. oCtrl:bClick = Nil
            oDlg:lResult := .T.
            EndDialog( oDlg:handle )   // VER AQUI
            RETURN 1
         ENDIF
         //
             /*
         IF !oDlg:lExitOnEnter .AND. lParam > 0 .AND. lParam != hCtrl
            IF oCtrl:oParent:oParent != Nil
                GetSkip( oCtrl:oParent, hCtrl, , 1)
            eNDIF
             RETURN 0
         ENDIF
         */
         IF oDlg:lClipper
            IF oCtrl != Nil .AND. ! GetSkip( oCtrl:oParent, hCtrl, , 1 )
               IF oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  EndDialog( oDlg:handle )
               ENDIF
               RETURN 1
            ENDIF
            //setfocus(odlg:handle)
         ENDIF
      ELSEIF iParLow == IDCANCEL
         IF ( oCtrl := oDlg:FindControl( IDCANCEL ) ) != Nil .AND. oCtrl:IsEnabled() 
            PostMessage( oDlg:handle, WM_NEXTDLGCTL, oCtrl:Handle , 1 )
         ELSEIF oCtrl != Nil .AND. ! oCtrl:IsEnabled() .AND. oDlg:lExitOnEsc
            EndDialog( oDlg:handle )
            RETURN 1
         ENDIF
         nEsc := ( getkeystate( VK_ESCAPE ) < 0 )
         oDlg:nLastKey := VK_ESCAPE
      ELSEIF iParLow == IDHELP  // HELP
         SendMessage( oDlg:Handle, WM_HELP, 0, 0 )
      ENDIF
   ENDIF

   //IF ( ValType( oDlg:nInitFocus ) = "O" .OR. oDlg:nInitFocus > 0 ) .AND. ! isWindowVisible( oDlg:handle )
   //   oDlg:nInitFocus := IIf( ValType( oDlg:nInitFocus ) = "O", oDlg:nInitFocus:Handle, oDlg:nInitFocus )
   IF oDlg:nInitFocus > 0 .AND. !isWindowVisible( oDlg:handle )         
      PostMessage( oDlg:Handle, WM_NEXTDLGCTL, oDlg:nInitFocus , 1 )
   ENDIF
   IF oDlg:aEvents != Nil .AND. ;
      ( i := AScan( oDlg:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      IF ! oDlg:lSuspendMsgsHandling 
         Eval( oDlg:aEvents[ i, 3 ], oDlg, iParLow )
      ENDIF
   ELSEIF iParHigh == 0 .AND. ! oDlg:lSuspendMsgsHandling .AND. ( ;
        ( iParLow == IDOK .AND. oDlg:FindControl( IDOK ) != nil ) .OR. ;
          iParLow == IDCANCEL )
      IF iParLow == IDOK
         oCtrl := oDlg:FindControl( IDOK ) 
         oDlg:lResult := .T.
         IF  __ObjHasMsg( oCtrl, "BCLICK" ) .AND. oCtrl:bClick != Nil
   	        RETURN 1
         ENDIF	 
      ENDIF
      //Replaced by Sandro
      IF oDlg:lExitOnEsc .OR. ! nEsc
         EndDialog( oDlg:handle )
      ELSEIF ! oDlg:lExitOnEsc
         oDlg:nLastKey := 0
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "MENU" ) .AND. ValType( oDlg:menu ) == "A" .AND. ;
      ( aMenu := Hwg_FindMenuItem( oDlg:menu, iParLow, @i ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1, i, 4 ], FLAG_CHECK ) > 0
         CheckMenuItem( , aMenu[ 1, i, 3 ], ! IsCheckedMenuItem( , aMenu[ 1, i, 3 ] ) )
      ENDIF
      IF aMenu[ 1, i, 1 ] != Nil
         Eval( aMenu[ 1, i, 1 ], i, iParlow )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "OPOPUP" ) .AND. oDlg:oPopup != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oDlg:oPopup:aMenu, wParam, @i ) ) != Nil ;
      .AND. aMenu[ 1, i, 1 ] != Nil
      Eval( aMenu[ 1, i, 1 ], i, wParam )
   ENDIF
   IF oDlg:nInitFocus > 0 
      oDlg:nInitFocus := 0
   ENDIF

   RETURN 1

FUNCTION DlgMouseMove()
   LOCAL oBtn := SetNiceBtnSelected()

   IF oBtn != Nil .AND. ! oBtn:lPress
      oBtn:state := OBTN_NORMAL
      InvalidateRect( oBtn:handle, 0 )
     * PostMessage( oBtn:handle, WM_PAINT, 0, 0 )
      SetNiceBtnSelected( Nil )
   ENDIF

   RETURN 0

STATIC FUNCTION onSize( oDlg, wParam, lParam )
   LOCAL aControls, iCont , nW1, nH1
   LOCAL nW := LOWORD( lParam ), nH := HIWORD( lParam )
   LOCAL nScrollMax

   //HB_SYMBOL_UNUSED( wParam )

   IF oDlg:oEmbedded != Nil
      oDlg:oEmbedded:Resize( LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF
   // VERIFY MIN SIZES AND MAX SIZES
   /*
   IF ( oDlg:nHeight = oDlg:minHeight .AND. nH < oDlg:minHeight ) .OR. ;
      ( oDlg:nHeight = oDlg:maxHeight .AND. nH > oDlg:maxHeight ) .OR. ;
      ( oDlg:nWidth = oDlg:minWidth .AND. nW < oDlg:minWidth ) .OR. ;
      ( oDlg:nWidth = oDlg:maxWidth .AND. nW > oDlg:maxWidth )
      RETURN 0
   ENDIF
   */
   nW1 := oDlg:nWidth
   nH1 := oDlg:nHeight
   *aControls := GetWindowRect( oDlg:handle )
   IF wParam != 1  //SIZE_MINIMIZED
      oDlg:nWidth := LOWORD( lParam )  //aControls[3]-aControls[1]
      oDlg:nHeight := HIWORD( lParam ) //aControls[4]-aControls[2]
   ENDIF   
   // SCROLL BARS code here.
	 IF oDlg:nScrollBars > - 1 .AND. oDlg:lAutoScroll
      oDlg:ResetScrollbars()
      oDlg:SetupScrollbars()
   ENDIF    
   
   IF oDlg:bSize != Nil .AND. ;
      ( oDlg:oParent == Nil .OR. ! __ObjHasMsg( oDlg:oParent, "ACONTROLS" ) )
      Eval( oDlg:bSize, oDlg, LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF
   aControls := oDlg:aControls
   IF aControls != Nil .AND. !Empty( oDlg:Rect )                    
      oDlg:Anchor( oDlg, nW1, nH1, oDlg:nWidth, oDlg:nHeight )
      FOR iCont := 1 TO Len( aControls )
         IF aControls[ iCont ]:bSize != Nil
            Eval( aControls[ iCont ]:bSize, ;
                  aControls[ iCont ], LOWORD( lParam ), HIWORD( lParam ), nW1, nH1 )
         ENDIF
      NEXT
   ENDIF
   RETURN 0

STATIC FUNCTION onActivate( oDlg, wParam, lParam )
   LOCAL iParLow := LOWORD( wParam ), iParHigh := HIWORD( wParam )

   HB_SYMBOL_UNUSED( lParam )

   IF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE ) .AND. IsWindowVisible( oDlg:handle ) //.AND. PtrtoUlong( lParam ) = 0
      IF oDlg:bGetFocus != Nil //.AND. IsWindowVisible(::handle)
         oDlg:lSuspendMsgsHandling := .t.
         IF iParHigh > 0  // MINIMIZED
            //odlg:restore()
         ENDIF
         Eval( oDlg:bGetFocus, oDlg, lParam )
         oDlg:lSuspendMsgsHandling := .f.
      ENDIF
   ELSEIF iParLow = WA_INACTIVE  .AND. oDlg:bLostFocus != Nil //.AND. PtrtoUlong( lParam ) = 0
      oDlg:lSuspendMsgsHandling := .t.
      Eval( oDlg:bLostFocus, oDlg, lParam  )
      oDlg:lSuspendMsgsHandling := .f.
      IF ! oDlg:lModal
         RETURN 1
      ENDIF
   ENDIF
   RETURN 0

FUNCTION onHelp( oDlg, wParam, lParam )
   LOCAL oCtrl, nHelpId, oParent, cDir

   HB_SYMBOL_UNUSED( wParam )

   IF ! Empty( SetHelpFileName() )
      IF "chm" $ Lower( CutPath( SetHelpFileName() ) )
         cDir := IIF( EMPTY( FilePath( SetHelpFileName() ) ), Curdir(), FilePath( SetHelpFileName() ) ) 
         nHelpId := ""
      ENDIF       
      IF ! Empty( lParam )
         oCtrl := oDlg:FindControl( Nil, GetHelpData( lParam ) )
      ENDIF   
      IF oCtrl != nil
         nHelpId := oCtrl:HelpId
         IF Empty( nHelpId )
            oParent := oCtrl:oParent
            nHelpId := IIF( Empty( oParent:HelpId ), oDlg:HelpId, oParent:HelpId )
         ENDIF
         IF "chm" $ Lower( CutPath( SetHelpFileName() ) )
            nHelpId := IIF( VALTYPE( nHelpId ) = "N", LTrim( Str( nHelpId ) ), nHelpId )
            ShellExecute( "hh.exe", "open", CutPath( SetHelpFileName() ) + "::" + nHelpId+".html", cDir ) 
         ELSE   
            WinHelp( oDlg:handle, SetHelpFileName(), IIf( Empty( nHelpId ), 3, 1 ), nHelpId )
         ENDIF  
      ELSEIF cDir != Nil
         ShellExecute( "hh.exe", "open", CutPath( SetHelpFileName() )  , cDir )         
      ELSE
         WinHelp( oDlg:handle, SetHelpFileName(), iif( Empty( oDlg:HelpId ), 3, 1), oDlg:HelpId )       
      ENDIF
   ENDIF
   RETURN 1

STATIC FUNCTION onPspNotify( oDlg, wParam, lParam )
   LOCAL nCode := GetNotifyCode( lParam ), res := .T.

   HB_SYMBOL_UNUSED( wParam )

   IF nCode == PSN_SETACTIVE //.AND. !oDlg:aEvdisable
      IF oDlg:bGetFocus != Nil
         oDlg:lSuspendMsgsHandling := .T.
         res := Eval( oDlg:bGetFocus, oDlg )
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
      // 'res' should be 0(Ok) or -1

      Hwg_SetDlgResult( oDlg:handle, IIf( res, 0, - 1 ) )
      RETURN 1
   ELSEIF nCode == PSN_KILLACTIVE //.AND. !oDlg:aEvdisable
      IF oDlg:bLostFocus != Nil
         oDlg:lSuspendMsgsHandling := .T.
         res := Eval( oDlg:bLostFocus, oDlg )
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
      // 'res' should be 0(Ok) or 1
      Hwg_SetDlgResult( oDlg:handle, IIf( res, 0, 1 ) )
      RETURN 1
   ELSEIF nCode == PSN_RESET
   ELSEIF nCode == PSN_APPLY
      IF oDlg:bDestroy != Nil
         res := Eval( oDlg:bDestroy, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or 2
      Hwg_SetDlgResult( oDlg:handle, IIf( res, 0, 2 ) )
      IF res
         oDlg:lResult := .T.
      ENDIF
      RETURN 1
   ELSE
      IF oDlg:bOther != Nil
         res := Eval( oDlg:bOther, oDlg, WM_NOTIFY, 0, lParam )
         Hwg_SetDlgResult( oDlg:handle, IIf( res, 0, 1 ) )
         RETURN 1
      ENDIF
   ENDIF
   RETURN 0

FUNCTION PropertySheet( hParentWindow, aPages, cTitle, x1, y1, width, height, ;
                        lModeless, lNoApply, lWizard )
   LOCAL hSheet, i, aHandles := Array( Len( aPages ) ), aTemplates := Array( Len( aPages ) )

   aSheet := Array( Len( aPages ) )
   FOR i := 1 TO Len( aPages )
      IF aPages[ i ]:Type == WND_DLG_RESOURCE
         aHandles[ i ] := _CreatePropertySheetPage( aPages[ i ] )
      ELSE
         aTemplates[ i ] := CreateDlgTemplate( aPages[ i ], x1, y1, width, height, WS_CHILD + WS_VISIBLE + WS_BORDER )
         aHandles[ i ] := _CreatePropertySheetPage( aPages[ i ], aTemplates[ i ] )
      ENDIF
      aSheet[ i ] := { aHandles[ i ], aPages[ i ] }
      // Writelog( "h: "+str(aHandles[i]) )
   NEXT
   hSheet := _PropertySheet( hParentWindow, aHandles, Len( aHandles ), cTitle, ;
                             lModeless, lNoApply, lWizard )
   FOR i := 1 TO Len( aPages )
      IF aPages[ i ]:Type != WND_DLG_RESOURCE
         ReleaseDlgTemplate( aTemplates[ i ] )
      ENDIF
   NEXT

   RETURN hSheet

FUNCTION GetModalDlg
   LOCAL i := Len( HDialog():aModalDialogs )
   RETURN IIf( i > 0, HDialog():aModalDialogs[ i ], 0 )

FUNCTION GetModalHandle
   LOCAL i := Len( HDialog():aModalDialogs )
   RETURN IIf( i > 0, HDialog():aModalDialogs[ i ]:handle, 0 )

FUNCTION EndDialog( handle )
   LOCAL oDlg, hFocus := GetFocus(), oCtrl  
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
   IF ! EMPTY( hFocus ) .AND. ( oCtrl := oDlg:FindControl(, hFocus ) ) != Nil .AND. oCtrl:bLostFocus != Nil
      SendMessage( hFocus, WM_KILLFOCUS, 0, 0 )
   ENDIF
   IF oDlg:bDestroy != Nil
      oDlg:lSuspendMsgsHandling := .T.
      res := Eval( oDlg:bDestroy, oDlg )
      oDlg:lSuspendMsgsHandling := .F.
      IF ! res
         oDlg:nLastKey := 0
         RETURN Nil
      ENDIF
   ENDIF
   RETURN  IIf( oDlg:lModal, Hwg_EndDialog( oDlg:handle ), DestroyWindow( oDlg:handle ) )

FUNCTION SetDlgKey( oDlg, nctrl, nkey, block )
   LOCAL i, aKeys, bOldSet

   IF oDlg == Nil ; oDlg := HCustomWindow():oDefaultParent ; ENDIF
   IF nctrl == Nil ; nctrl := 0 ; ENDIF

   IF ! __ObjHasMsg( oDlg, "KEYLIST" )
      RETURN nil
   ENDIF
   aKeys := oDlg:KeyList
   IF ( i := AScan( aKeys, { | a | a[ 1 ] == nctrl.AND.a[ 2 ] == nkey } ) ) > 0
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
   Local oCtrl
   
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
       IF ( oCtrl := FindAccelerator( oDlg, lParam ) ) != Nil
          oCtrl:SetFocus()
          SendMessage( oCtrl:handle, WM_SYSKEYUP, lParam, 0 )
          RETURN 2
      ENDIF
   ELSEIF wParam = SC_HOTKEY      
   ELSEIF wParam = SC_MENU 
   ELSEIF wParam = 61824  //button help
   ENDIF
   
   RETURN -1

   EXIT PROCEDURE Hwg_ExitProcedure
   Hwg_ExitProc()
   RETURN

