/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HWindow class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  FIRST_MDICHILD_ID     501
#define  MAX_MDICHILD_WINDOWS   18
#define  WM_NOTIFYICON         WM_USER + 1000
#define  ID_NOTIFYICON           1

STATIC FUNCTION onSize( oWnd, wParam, lParam )
   LOCAL aCoors := GetWindowRect( oWnd:handle )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:Resize( LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF
   //InvalidateRect( oWnd:handle, 0 )
   oWnd:Super:onEvent( WM_SIZE, wParam, lParam )

   oWnd:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   oWnd:nHeight := aCoors[ 4 ] - aCoors[ 2 ]

   IF ISBLOCK( oWnd:bSize )
      Eval( oWnd:bSize, oWnd, LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF
   IF oWnd:Type == WND_MDI .AND. Len( HWindow():aWindows ) > 1
      aCoors := GetClientRect( oWnd:handle )
      //MoveWindow( HWindow():aWindows[ 2 ]:handle, oWnd:aOffset[ 1 ], oWnd:aOffset[ 2 ], aCoors[ 3 ] - oWnd:aOffset[ 1 ] - oWnd:aOffset[ 3 ], aCoors[ 4 ] - oWnd:aOffset[ 2 ] - oWnd:aOffset[ 4 ] )
      //aCoors := GetClientRect(HWindow():aWindows[ 2 ]:handle )
      SetWindowPos( HWindow():aWindows[ 2 ]:handle, Nil, oWnd:aOffset[ 1 ], oWnd:aOffset[ 2 ], aCoors[ 3 ] - oWnd:aOffset[ 1 ] - oWnd:aOffset[ 3 ], aCoors[ 4 ] - oWnd:aOffset[ 2 ] - oWnd:aOffset[ 4 ], SWP_NOZORDER)
      aCoors := GetWindowRect( HWindow():aWindows[ 2 ]:handle )
      HWindow():aWindows[ 2 ]:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
      HWindow():aWindows[ 2 ]:nHeight := aCoors[ 4 ] - aCoors[ 2 ]
      // ADDED
      IF !Empty( oWnd:Screen )
          oWnd:Screen:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
          oWnd:Screen:nHeight := aCoors[ 4 ] - aCoors[ 2 ]
          InvalidateRect( oWnd:screen:handle, 0 )
          SetWindowPos( oWnd:screen:handle, Nil, 0, 0, oWnd:Screen:nWidth, oWnd:Screen:nHeight, SWP_NOACTIVATE + SWP_NOZORDER)
      ENDIF
      IF ! Empty( oWnd := oWnd:GetMdiActive() ) .AND.oWnd:Type = WND_MDICHILD .AND. oWnd:lmaximized .AND.;
                                                 ( oWnd:lModal .OR. oWnd:lChild )
         oWnd:lmaximized := .F.
         SENDMESSAGE( oWnd:handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
      ENDIF
      //
      RETURN 0
   ENDIF

   RETURN - 1

STATIC FUNCTION onDestroy( oWnd )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:END()
   ENDIF
   oWnd:Super:onEvent( WM_DESTROY )
   HWindow():DelItem( oWnd )

   RETURN 0

CLASS HWindow INHERIT HCustomWindow

CLASS VAR aWindows   SHARED INIT { }
CLASS VAR szAppName  SHARED INIT "HwGUI_App"

   CLASS VAR Screen SHARED

   DATA menu, oPopup, hAccel
   DATA oIcon, oBmp
   DATA lBmpCenter INIT .F.
   DATA nBmpClr
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lClipper INIT .F.
   DATA GetList  INIT { }      // The array of GET items in the dialog
   DATA KeyList  INIT { }      // The array of keys ( as Clipper's SET KEY )
   DATA nLastKey INIT 0
   DATA lExitOnEnter INIT .F.
   DATA lExitOnEsc INIT .F.
   DATA lGetSkiponEsc INIT .F.
   DATA bCloseQuery
   Data nFocus  INIT 0
   DATA WindowState  INIT 0
   DATA oClient
   DATA lChild INIT .F.
   DATA lDisableCtrlTab INIT .F.
   DATA lModal INIT .F.
   DATA aOffset
   DATA oEmbedded
   DATA bScroll
   DATA bSetForm

   METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
               bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, lChild, lClipper, lNoClosable, bSetForm )
   METHOD AddItem( oWnd )
   METHOD DelItem( oWnd )
   METHOD FindWindow( hWnd )
   METHOD GetMain()
   METHOD GetMdiMain() INLINE IIF( ::GetMain() != Nil, ::aWindows[ 1 ] , Nil )
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle, ::Type )
   METHOD Restore()  INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_RESTORE, 0 )
   METHOD Maximize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
   METHOD Minimize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MINIMIZE, 0 )
   METHOD Close()   INLINE SendMessage( ::handle, WM_SYSCOMMAND, SC_CLOSE, 0 )
   METHOD Release()  INLINE ::Close( ), super:Release(), Self := Nil
   METHOD isMaximized() INLINE GetWindowPlacement( ::handle ) == SW_SHOWMAXIMIZED
   METHOD isMinimized() INLINE GetWindowPlacement( ::handle ) == SW_SHOWMINIMIZED
   METHOD isNormal() INLINE GetWindowPlacement( ::handle ) == SW_SHOWNORMAL


ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
            bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, lChild, lClipper, lNoClosable, bSetForm )  CLASS HWindow

   HB_SYMBOL_UNUSED( clr )
   HB_SYMBOL_UNUSED( cMenu )
   HB_SYMBOL_UNUSED( cHelp )

   ::oDefaultParent := Self
   ::title    := cTitle
   ::style    := IIf( nStyle == Nil, 0, nStyle )
   ::oIcon    := oIcon
   ::oBmp     := oBmp
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
   ::bCloseQuery := bCloseQuery
   ::bRefresh   := bRefresh
   ::lChild    := IIF( EMPTY( lChild ), ::lChild,  lChild  )
   ::lClipper  := IIF( EMPTY( lClipper ), ::lClipper ,  lClipper )
   ::lClosable := Iif( EMPTY( lnoClosable ), .T., ! lnoClosable )

   /*
   IF clr != NIL
      ::brush := HBrush():Add( clr )
      ::bColor := clr
   ENDIF
   */
   ::SetColor( , clr )

   IF cAppName != Nil
      ::szAppName := cAppName
   ENDIF

   IF nHelpId != nil
      ::HelpId := nHelpId
   END

   ::aOffset := Array( 4 )
   AFill( ::aOffset, 0 )

   ::AddItem( Self )

   IF Hwg_Bitand( nStyle,WS_HSCROLL ) > 0
      ::nScrollBars ++
   ENDIF
   IF  Hwg_Bitand( nStyle,WS_VSCROLL ) > 0
      ::nScrollBars += 2
   ENDIF
   ::bSetForm := bSetForm

   RETURN Self

METHOD AddItem( oWnd ) CLASS HWindow
   AAdd( ::aWindows, oWnd )
   RETURN Nil

METHOD DelItem( oWnd ) CLASS HWindow
   LOCAL i, h := oWnd:handle
   IF ( i := AScan( ::aWindows, { | o | o:handle == h } ) ) > 0
      ADel( ::aWindows, i )
      ASize( ::aWindows, Len( ::aWindows ) - 1 )
   ENDIF
   RETURN Nil

METHOD FindWindow( hWnd ) CLASS HWindow
   LOCAL i := AScan( ::aWindows, { | o | PtrtoUlong(o:handle) == PtrtoUlong(hWnd) } )
   RETURN IIf( i == 0, Nil, ::aWindows[ i ] )

METHOD GetMain() CLASS HWindow
   RETURN IIf( Len( ::aWindows ) > 0,              ;
               IIf( ::aWindows[ 1 ]:Type == WND_MAIN, ;
                    ::aWindows[ 1 ],                  ;
                    IIf( Len( ::aWindows ) > 1, ::aWindows[ 2 ], Nil ) ), Nil )



CLASS HMainWindow INHERIT HWindow

CLASS VAR aMessages INIT { ;
                           { WM_COMMAND, WM_ERASEBKGND, WM_MOVE, WM_SIZE, WM_SYSCOMMAND, ;
                             WM_NOTIFYICON, WM_ENTERIDLE, WM_CLOSE, WM_DESTROY, WM_ENDSESSION, WM_ACTIVATE, WM_HELP }, ;
                           { ;
                             { | o, w, l | onCommand( o, w, l ) },        ;
                             { | o, w | onEraseBk( o, w ) },              ;
                             { | o | onMove( o ) },                       ;
                             { | o, w, l | onSize( o, w, l ) },           ;
                             { | o, w, l | onSysCommand( o, w, l ) },     ;
                             { | o, w, l | onNotifyIcon( o, w, l ) },     ;
                             { | o, w, l | onEnterIdle( o, w, l ) },      ;
                             { | o | onCloseQuery( o ) },                 ;
                             { | o | onDestroy( o ) },                    ;
                             { | o, w | onEndSession( o, w ) },           ;
                             { | o, w, l | onActivate( o, w, l ) },       ;
                             { | o, w, l | onHelp( o, w, l ) }            ;
                           } ;
                         }

   DATA  nMenuPos
   DATA  bMdiMenu
   DATA  oNotifyIcon, bNotify, oNotifyMenu
   DATA  lTray INIT .F.

   METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
               oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, bMdiMenu )
   METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip )
   METHOD GetMdiActive()  INLINE ::FindWindow( IIF( ::GetMain() != Nil, SendMessage( ::GetMain():handle, WM_MDIGETACTIVE, 0, 0 ) , Nil ) )

ENDCLASS

METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
            oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, bMdiMenu ) CLASS HMainWindow

   Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh )
   ::Type := lType

   IF lType == WND_MDI

      //::nMenuPos := nPos
      ::nMenuPos := IIF( nPos = Nil, -1, nPos )     //don't show menu
      ::bMdiMenu := bMdiMenu
      ::Style := nStyle
      ::tColor := clr
      ::oBmp := oBmp
       clr:= nil  // because error
      ::handle := Hwg_InitMdiWindow( Self, ::szAppName, cTitle, cMenu,  ;
                                     IIf( oIcon != Nil, oIcon:handle, Nil ), , ;  //clr, ;
                                     nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

      IF cHelp != NIL
         SetHelpFileName( cHelp )
      ENDIF

   ELSEIF lType == WND_MAIN

      clr := nil  // because error and WINDOW IS INVISIBLE
      ::handle := Hwg_InitMainWindow( Self, ::szAppName, cTitle, cMenu, ;
                      IIf( oIcon != Nil, oIcon:handle, Nil ), ;
                      IIf( oBmp != Nil, - 1, clr ), nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

      IF cHelp != NIL
         SetHelpFileName( cHelp )
      ENDIF

   ENDIF
   ::rect := GetWindowRect( ::handle )
   /*
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF
    */
   RETURN Self

METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate ) CLASS HMainWindow
   LOCAL oWndClient, handle, lres

   DEFAULT lMaximized := .F.
   DEFAULT lMinimized := .F.
   lCentered  := ( ! lMaximized .AND. ! EMPTY( lCentered ) .AND. lCentered ) .OR. Hwg_BitAND( ::Style, DS_CENTER ) != 0
   DEFAULT lShow := .T.
   CreateGetList( Self )

   IF ::Type == WND_MDI

      oWndClient := HWindow():New( ,,, ::style, ::title,, ::bInit, ::bDestroy, ::bSize, ;
                                   ::bPaint, ::bGetFocus, ::bLostFocus, ::bOther, ::obmp )
      //handle := Hwg_InitClientWindow( oWndClient, ::nMenuPos, ::nLeft, ::nTop + 60, ::nWidth, ::nHeight )
      handle := Hwg_InitClientWindow( oWndClient, ::nMenuPos, ::nLeft, ::nTop, ::nWidth, ::nHeight )

      *-oWndClient:handle = handle
      
      ::oClient := HWindow():aWindows[ 2 ]
      SetWindowPos( ::oClient:Handle, 0, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
                        SWP_NOOWNERZORDER + SWP_FRAMECHANGED)

      // ADDED screen to backgroup to MDI MAIN
      ::Screen := HMdiChildWindow():New(, ::tcolor, WS_CHILD + MB_USERICON + WS_MAXIMIZE + WS_DISABLED,;
                0,0, ::nWidth * 2, ::nheight * 2, -1,,,,,,,,,,,::oBmp,,,,,)
      ::Screen:Activate( .T., .T. )
      // END
      oWndClient:handle := handle
      
      IF ::bInit != Nil
         lres := Eval( ::bInit, Self )
         IF ValType( lres ) = "L" .AND. ! lres
            SENDMESSAGE( ::handle, WM_DESTROY, 0, 0 )
            RETURN Nil
         ENDIF
      ENDIF
      
      ::Screen:lBmpCenter := ::lBmpCenter
      *-EnableWindow( ::Screen:Handle, .T. )
      SetWindowPos( ::Screen:Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
                                                              SWP_NOOWNERZORDER + SWP_FRAMECHANGED )
      ::Screen:Restore()
      
      IF lMaximized
         ::maximize()
      ELSEIF lMinimized
         ::minimize()
      ELSEIF lCentered
         ::center()
      ENDIF

      IF ( bActivate  != NIL )
         Eval( bActivate, Self )
      ENDIF

      Hwg_ActivateMdiWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ELSEIF ::Type == WND_MAIN

      IF ::bInit != Nil
         lres := Eval( ::bInit, Self )
         IF ValType( lres ) = "L" .AND. ! lres
            SENDMESSAGE( ::handle, WM_DESTROY, 0, 0 )
            RETURN Nil
         ENDIF
      ENDIF
      IF lMaximized
         ::maximize()
      ELSEIF lMinimized
         ::minimize()
      ELSEIF lCentered
         ::center()
      ENDIF

      IF ( bActivate  != NIL )
         Eval( bActivate, Self )
      ENDIF

      AddToolTip( ::handle, ::handle, "" )
      Hwg_ActivateMainWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMainWindow
   Local i, xPos, yPos, oMdi, aCoors

   // writelog( str(msg) + str(wParam) + str(lParam) )

   IF msg = WM_MENUCHAR
      // PROCESS ACCELERATOR IN CONTROLS
      RETURN onSysCommand( Self, SC_KEYMENU, LoWord( wParam ) )
   ENDIF
   // added control MDICHILD MODAL
   IF msg = WM_PARENTNOTIFY
      IF wParam = WM_LBUTTONDOWN .AND. !EMPTY( ::GetMdiActive() )
         oMdi := ::GetMdiActive()
         IF oMdi:lModal
            xPos := LoWord( lParam )
            yPos := HiWord( lParam ) // + ::nTop + GetSystemMetrics( SM_CYMENU ) + GETSYSTEMMETRICS( SM_CYCAPTION )
            aCoors := ScreenToClient( ::handle, GetWindowRect( oMdi:handle ) ) // acoors[1], acoors[2]  )
            IF ( ! PtInRect( aCoors, { xPos, yPos } ) )
               MSGBEEP()
               FOR i = 1 to 6
                  FlashWindow( oMdi:Handle, 1 )
                  Sleep( 60 )
               NEXT
               SetWindowPos( oMdi:Handle, HWND_TOP, 0, 0, 0, 0, ;
                             SWP_NOMOVE + SWP_NOSIZE +  SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
               RETURN 0
            ENDIF
         ENDIF
      ENDIF
   ENDIF
   //
   IF ( i := Ascan( ::aMessages[1],msg ) ) != 0 .AND. ;
       ( !::lSuspendMsgsHandling .OR. msg = WM_ERASEBKGND .OR. msg = WM_SIZE ) //.OR. msg = WM_ACTIVATE)
      Return Eval( ::aMessages[2,i], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1
             ::ScrollHV( Self,msg,wParam,lParam )
         ENDIF
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip ) CLASS HMainWindow

   ::bNotify     := bNotify
   ::oNotifyMenu := oNotifyMenu
   ::oNotifyIcon := oNotifyIcon
   ShellNotifyIcon( .T., ::handle, oNotifyIcon:handle, cTooltip )
   ::lTray := .T.

   RETURN Nil


CLASS HMDIChildWindow INHERIT HWindow

CLASS VAR aMessages INIT { ;
                           { WM_CREATE, WM_COMMAND,WM_ERASEBKGND,WM_MOVE, WM_SIZE, WM_NCACTIVATE, ;
                             WM_SYSCOMMAND, WM_ENTERIDLE, WM_MDIACTIVATE, WM_DESTROY }, ;
                           { ;
                             { | o, w, l | HB_SYMBOL_UNUSED( w ), onMdiCreate( o, l ) },        ;
                             { | o, w | onMdiCommand( o, w ) },         ;
                             { | o, w | onEraseBk( o, w ) },            ;
                             { | o | onMove( o ) },                   ;
                             { | o, w, l | onSize( o, w, l ) },           ;
                             { | o, w | onMdiNcActivate( o, w ) },      ;
                             { | o, w, l | onSysCommand( o, w, l ) },         ;
                             { | o, w, l | onEnterIdle( o, w, l ) },      ;
                             { | o, w, l | onMdiActivate( o, w, l ) },     ;
                             { | o | onDestroy( o ) }                 ;
                           } ;
                         }
   DATA aRectSave
   DATA oWndParent
   DATA lMaximized  INIT .F.
   DATA lResult  INIT .F.	

   METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate, lModal)
   METHOD onEvent( msg, wParam, lParam )
   METHOD SetParent( oParent ) INLINE ::oWndParent := oParent

ENDCLASS

METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate, lModal ) CLASS HMDIChildWindow

   HB_SYMBOL_UNUSED( lShow )
   HB_SYMBOL_UNUSED( lMaximized )
   HB_SYMBOL_UNUSED( lMinimized )
   HB_SYMBOL_UNUSED( lCentered )

   DEFAULT lShow := .T.
   lMinimized := !EMPTY( lMinimized ) .AND. lMinimized .AND. Hwg_BitAnd( ::style, WS_MINIMIZE ) != 0
   lMaximized := !EMPTY( lMaximized ) .AND. lMaximized .AND. ;
                 ( Hwg_BitAnd( ::style, WS_MAXIMIZE ) != 0 .OR.  Hwg_BitAnd( ::style, WS_SIZEBOX ) != 0 )
   lCentered  := ( ! lMaximized .AND. ! EMPTY( lCentered ) .AND. lCentered ) .OR. Hwg_BitAND( ::Style, DS_CENTER ) != 0                 
   ::lModal   := ! EMPTY( lModal ) .AND. lModal
   ::lChild   := ::lModal .OR. ::lChild .OR. ::minWidth  > -1 .OR. ::maxWidth  > -1 .OR. ::minHeight > -1 .OR. ::maxHeight > -1
   ::WindowState := IIF( lMinimized, SW_SHOWMINIMIZED, IIF( lMaximized, SW_SHOWMAXIMIZED, IIF( lShow, SW_SHOWNORMAL, 0 ) ) )
   CreateGetList( Self )
   // Hwg_CreateMdiChildWindow( Self )

   ::Type := WND_MDICHILD
   ::oClient := HWindow():aWindows[ 2 ]
   ::GETMDIMAIN():WindowState := GetWindowPlacement( ::GETMDIMAIN():handle )
   ::rect := GetWindowRect( ::handle )
   IF lCentered
      ::nLeft := ( ::oClient:nWidth - ::nWidth ) / 2
      ::nTop  := ( ::oClient:nHeight - ::nHeight ) / 2
   ENDIF
   ::aRectSave := { ::nLeft, ::nTop, ::nwidth, ::nHeight }

   ::Style := Hwg_BitOr( ::Style , WS_VISIBLE ) - IIF( ! lshow , WS_VISIBLE , 0 ) + IIF( lMaximized, WS_MAXIMIZE, 0 )   			
   ::handle := Hwg_CreateMdiChildWindow( Self )

   IF lCentered
      ::nLeft := ( ::oClient:nWidth - ::nWidth ) / 2
      ::nTop  := ( ::oClient:nHeight - ::nHeight ) / 2
   ENDIF
   IF VALTYPE( ::TITLE ) = "N" .AND. ::title = - 1   // screen
      RETURN .T.
   ENDIF
	
   // is necessary for set zorder control
   //InitControls( Self )  ??? maybe

   /*  in ONMDICREATE
   /*
   InitObjects( Self,.T. )
   IF ::bInit != Nil
      Eval( ::bInit,Self )
   ENDIF
   */

   IF lShow
      *-onMove( Self )
      IF lMinimized  .OR. ::WindowState = SW_SHOWMINIMIZED
         ::Minimize()
      ELSEIF  ::WindowState = SW_SHOWMAXIMIZED .AND. ! ::IsMaximized()
         ::maximize()
      ENDIF
      //::show()
      *-upDateWindow( ::handle )
   ELSE
      SetWindowPos( ::handle, Nil, ::nLeft, ::nTop, ::nWidth, ::nHeight, SWP_NOACTIVATE + SWP_NOZORDER )
   ENDIF

   // SCROLLSBARS
   IF ::nScrollBars > - 1
      AEval( ::aControls, { | o | ::ncurHeight := max( o:nTop + o:nHeight + GetSystemMetrics( SM_CYMENU ) + GETSYSTEMMETRICS( SM_CYCAPTION ) + 12 , ::ncurHeight ) } )
      AEval( ::aControls, { | o | ::ncurWidth := max( o:nLeft + o:nWidth  + 24 , ::ncurWidth ) } )
      ::ResetScrollbars()
      ::SetupScrollbars()
   ENDIF

   IF bActivate != NIL
      Eval( bActivate, Self )
   ENDIF

   IF ( ValType( ::nInitFocus ) = "O" .OR. ::nInitFocus > 0 )
      ::nInitFocus := IIf( ValType( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      SETFOCUS( ::nInitFocus )
      ::nFocus := ::nInitFocus
   ELSEIF PtrtoUlong( GETFOCUS() ) = PtrtoUlong( ::handle ) .AND. Len( ::acontrols ) > 0
      ::nFocus := ASCAN( ::aControls,{|o| Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_TABSTOP ) != 0 .AND. ;
                 Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_DISABLED ) = 0 } )
         IF ::nFocus > 0
         SETFOCUS( ::acontrols[ ::nFocus ]:handle )
         ::nFocus := GetFocus() //get::acontrols[1]:handle
      ENDIF
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMDIChildWindow
   LOCAL i, oCtrl
   LOCAL nFocus

   nFocus := If( Hb_IsNumeric( ::nFocus ), ::nFocus, 0 )
   //IF msg = WM_NCLBUTTONDBLCLK .AND. ::lChild
   //   Return 0

   IF msg = WM_GETMINMAXINFO //= &H24
      IF ::minWidth  > -1 .OR. ::maxWidth  > -1 .OR. ::minHeight > -1 .OR. ::maxHeight > -1
         MINMAXWINDOW(::handle, lParam,;
         IIF( ::minWidth  > -1, ::minWidth, Nil ),;
         IIF( ::minHeight > -1, ::minHeight, Nil ),;
         IIF( ::maxWidth  > -1, ::maxWidth, Nil ),;
         IIF( ::maxHeight > -1, ::maxHeight, Nil ) )
         RETURN 0

      ENDIF
   ELSEIF msg = WM_SETFOCUS .AND. nFocus != 0
      SETFOCUS( nFocus )
      *-::nFocus := 0
   ENDIF

   IF ( i := AScan( ::aMessages[ 1 ], msg ) ) != 0
      RETURN Eval( ::aMessages[ 2, i ], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1
             ::ScrollHV( Self,msg,wParam,lParam )
         ENDIF
         onTrackScroll( Self, msg, wParam, lParam )
      ELSEIF msg = WM_NOTIFY .AND.!::lSuspendMsgsHandling
         IF ( oCtrl := ::FindControl( , GetFocus() ) ) != Nil .AND. oCtrl:ClassName != "HTAB"
            SendMessage( oCtrl:handle, msg, wParam, lParam )
         ENDIF
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1


CLASS HChildWindow INHERIT HWindow

   DATA oNotifyMenu

   METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
               bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bRefresh )
   METHOD Activate( lShow, lMaximized, lMinimized,lCentered, bActivate, lModal)
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
            bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bRefresh ) CLASS HChildWindow

   Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId,, bRefresh )
   ::oParent := HWindow():GetMain()
   ::Type := WND_CHILD
   ::rect := GetWindowRect( ::handle )
   IF ISOBJECT( ::oParent )
      ::handle := Hwg_InitChildWindow( Self, ::szAppName, cTitle, cMenu, ;
                                       IIf( oIcon != Nil, oIcon:handle, Nil ), IIf( oBmp != Nil, - 1, clr ), nStyle, ::nLeft, ;
                                       ::nTop, ::nWidth, ::nHeight, ::oParent:handle )
   ELSE
      MsgStop( "Create Main window first !", "HChildWindow():New()" )
      RETURN Nil
   ENDIF
   /*
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF
    */
   RETURN Self

METHOD Activate( lShow, lMaximized, lMinimized,lCentered, bActivate, lModal ) CLASS HChildWindow
   LOCAL nReturn

   HB_SYMBOL_UNUSED( lModal )

   DEFAULT lShow := .T.
   ::Type := WND_CHILD

   CreateGetList( Self )
   InitControls( SELF,.T. )
   InitObjects( Self, .T. )
   SENDMESSAGE( ::handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR,UISF_HIDEFOCUS), 0)
   IF ::bInit != Nil
      //::hide()
      IF Valtype( nReturn := Eval( ::bInit, Self ) ) != "N"
         IF VALTYPE( nReturn ) == "L" .AND. ! nReturn
            ::Close()
            RETURN Nil
         ENDIF
      ENDIF
   ENDIF

   Hwg_ActivateChildWindow( lShow, ::handle, lMaximized, lMinimized )

   IF !EMPTY( lCentered ) .AND. lCentered
      IF  ! EMPTY( ::oParent )
        ::nLeft := (::oParent:nWidth - ::nWidth ) / 2
        ::nTop  := (::oParent:nHeight - ::nHeight) / 2
      ENDIF
   ENDIF
   SetWindowPos( ::Handle, HWND_TOP, ::nLeft, ::nTop, 0, 0,;
                  SWP_NOSIZE + SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
   IF ( bActivate  != NIL )
      Eval( bActivate, Self )
   ENDIF

   IF ( ValType( ::nInitFocus ) = "O" .OR. ::nInitFocus > 0 )
      ::nInitFocus := IIf( ValType( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      SETFOCUS( ::nInitFocus )
      ::nFocus := ::nInitFocus
   ELSEIF PtrtoUlong( GETFOCUS() ) = PtrtoUlong( ::handle ) .AND. Len( ::acontrols ) > 0
      ::nFocus := ASCAN( ::aControls,{|o| Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_TABSTOP ) != 0 .AND. ;
           Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_DISABLED ) = 0 } )
      IF ::nFocus > 0
         SETFOCUS( ::acontrols[ ::nFocus ]:handle )
         ::nFocus := GetFocus() //get::acontrols[1]:handle
      ENDIF
   ENDIF
   RETURN Nil


METHOD onEvent( msg, wParam, lParam )  CLASS HChildWindow
   LOCAL i, oCtrl

   IF msg == WM_DESTROY
      RETURN onDestroy( Self )
   ELSEIF msg == WM_SIZE
      RETURN onSize( Self, wParam, lParam )
   ELSEIF msg = WM_SETFOCUS .AND. ::nFocus != 0
      SETFOCUS( ::nFocus )
   ELSEIF ( i := AScan( HMainWindow():aMessages[ 1 ], msg ) ) != 0
      RETURN Eval( HMainWindow():aMessages[ 2, i ], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         onTrackScroll( Self, msg, wParam, lParam )
      ELSEIF msg = WM_NOTIFY .AND. !::lSuspendMsgsHandling
         IF ( oCtrl := ::FindControl( wParam ) ) != Nil .AND. oCtrl:className != "HTAB"
            ::nFocus := oCtrl:handle
            SendMessage( oCtrl:handle, msg, wParam, lParam )
         ENDIF
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

FUNCTION ReleaseAllWindows( hWnd )
   LOCAL oItem

   FOR EACH oItem IN HWindow():aWindows
      IF oItem:oParent != Nil .AND. PtrToUlong( oItem:oParent:handle ) == PtrToUlong( hWnd )
         SendMessage( oItem:handle, WM_CLOSE, 0, 0 )
      ENDIF
   NEXT
   IF PtrToUlong( HWindow():aWindows[ 1 ]:handle ) == PtrToUlong( hWnd )
      PostQuitMessage( 0 )
   ENDIF

   RETURN - 1

   #define  FLAG_CHECK      2

STATIC FUNCTION onCommand( oWnd, wParam, lParam )
   LOCAL iItem, iCont, aMenu, iParHigh, iParLow, nHandle, oChild, i

   HB_SYMBOL_UNUSED( lParam )

   IF wParam >= FIRST_MDICHILD_ID .AND. wparam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS .AND. ! Empty( oWnd:Screen ) 
      IF wParam >= FIRST_MDICHILD_ID
         SetWindowPos( ownd:Screen:HANDLE, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE )
      ENDIF
      wParam += IIF( IsWindowEnabled( oWnd:Screen:handle ), 0, 1 )     
   ENDIF
   IF wParam == SC_CLOSE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         // CLOSE ONLY MDICHILD HERE
         oChild := oWnd:FindWindow( nHandle )
         IF oChild != Nil
            IF ! oChild:Closable
               RETURN 0
            ELSEIF  ISBLOCK( oChild:bDestroy )
               oChild:lSuspendMsgsHandling := .T.
               i := Eval( oChild:bDestroy, oChild )
               oChild:lSuspendMsgsHandling := .F.
               i := IIf( Valtype(i) == "L", i, .T. )
               IF ! i
                  Return 0
               ENDIF
            ENDIF
         ENDIF
         SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIDESTROY, nHandle, 0 )
      ENDIF
   ELSEIF wParam == SC_RESTORE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIRESTORE, nHandle, 0 )
      ENDIF
   ELSEIF wParam == SC_MAXIMIZE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIMAXIMIZE, nHandle, 0 )
      ENDIF
   ELSEIF wParam >= FIRST_MDICHILD_ID .AND. wParam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS
      IF oWnd:bMdiMenu != Nil 
         Eval( oWnd:bMdiMenu, HWindow():aWindows[ wParam - FIRST_MDICHILD_ID + 3 ], wParam - 1  )
      ENDIF
      nHandle := HWindow():aWindows[ wParam - FIRST_MDICHILD_ID + 3 ]:handle
      SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIACTIVATE, nHandle, 0 )
   ENDIF
   iParHigh := HIWORD( wParam )
   iParLow := LOWORD( wParam )
   IF oWnd:aEvents != Nil .AND. !oWnd:lSuspendMsgsHandling  .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ELSEIF ValType( oWnd:menu ) == "A" .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:menu, iParLow, @iCont ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1, iCont, 4 ], FLAG_CHECK ) > 0
         CheckMenuItem( , aMenu[ 1, iCont, 3 ], ! IsCheckedMenuItem( , aMenu[ 1, iCont, 3 ] ) )
      ENDIF
      IF aMenu[ 1, iCont, 1 ] != Nil
         Eval( aMenu[ 1, iCont, 1 ], iCont, iParLow )
      ENDIF
   ELSEIF oWnd:oPopup != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[ 1, iCont, 1 ] != Nil
      Eval( aMenu[ 1, iCont, 1 ], iCont, wParam )
   ELSEIF oWnd:oNotifyMenu != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oNotifyMenu:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[ 1, iCont, 1 ] != Nil
      Eval( aMenu[ 1, iCont, 1 ], iCont, wParam )
   ELSEIF  wParam != SC_CLOSE .AND. wParam != SC_MINIMIZE .AND. wParam != SC_MAXIMIZE .AND.;
           wParam != SC_RESTORE .AND. oWnd:Type = WND_MDI //.AND. oWnd:bMdiMenu != Nil
      /*     
      // ADDED
      IF ! Empty( oWnd:Screen )
         IF wParam = FIRST_MDICHILD_ID  // first menu
            IF IsWindowEnabled( oWnd:Screen:Handle )
               SetWindowPos( oWnd:Screen:HANDLE, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER + ;
                                                                          SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
            ENDIF
            RETURN -1
         ENDIF
      ENDIF
      // menu MDICHILD
 			IF oWnd:bMdiMenu != Nil
         Eval( oWnd:bMdiMenu, oWnd:GetMdiActive(), wParam  )
      ENDIF
      */
      RETURN IIF( ! Empty( oWnd:Screen ) , -1 , 0 )
      // end added
   ENDIF

   RETURN 0

FUNCTION onMove( oWnd )
   LOCAL aControls := GetWindowRect( oWnd:handle )

   oWnd:nLeft := aControls[ 1 ]
   oWnd:nTop  := aControls[ 2 ]
   IF oWnd:type == WND_MDICHILD  .AND. ! oWnd:lMaximized
      //oWnd:aRectSave := { oWnd:nLeft, oWnd:nTop, oWnd:nWidth, oWnd:nHeight }
			IF oWnd:nHeight > GETSYSTEMMETRICS( SM_CYCAPTION ) + 6
	       oWnd:aRectSave := { oWnd:nLeft, oWnd:nTop, oWnd:nWidth, oWnd:nHeight }
      ELSE
        oWnd:aRectSave[ 1 ] := oWnd:nLeft
        oWnd:aRectSave[ 2 ] := oWnd:nTop
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onEraseBk( oWnd, wParam )
LOCAL aCoors,  oWndArea

  IF oWnd:oBmp != Nil .AND. oWnd:type != WND_MDI
       oWndArea := IIF( oWnd:type != WND_MAIN, oWnd:oClient, oWnd )
       IF oWnd:lBmpCenter
          CenterBitmap( wParam, oWndArea:handle, oWnd:oBmp:handle, , oWnd:nBmpClr )
       ELSE
          SpreadBitmap( wParam, oWndArea:handle, oWnd:oBmp:handle )
       ENDIF
       Return 1
  ELSEIF oWnd:type != WND_MDI //.AND. oWnd:type != WND_MAIN
      aCoors := GetClientRect( oWnd:handle )
      IF oWnd:brush != Nil
         IF ValType( oWnd:brush ) != "N"
            FillRect( wParam, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, oWnd:brush:handle )
            RETURN 1
         ENDIF
      ELSEIF oWnd:Type != WND_MAIN
         FillRect( wParam, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, COLOR_3DFACE + 1 )
         RETURN 1
      ENDIF
   ENDIF
   RETURN - 1


STATIC FUNCTION onSysCommand( oWnd, wParam, lParam )
   Local i, ars, oChild, oCtrl

   IF wParam == SC_CLOSE
      IF ISBLOCK( oWnd:bDestroy )
         oWnd:lSuspendMsgsHandling := .T.
         i := Eval( oWnd:bDestroy, oWnd )
         oWnd:lSuspendMsgsHandling := .F.
         i := IIf( ValType( i ) == "L", i, .t. )
         IF ! i
            RETURN 0
         ENDIF
         oWnd:bDestroy := Nil
      ENDIF
      IF __ObjHasMsg( oWnd, "ONOTIFYICON" ) .AND. oWnd:oNotifyIcon != Nil
         ShellNotifyIcon( .F., oWnd:handle, oWnd:oNotifyIcon:handle )
      ENDIF
      IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
         DestroyAcceleratorTable( oWnd:hAccel )
      ENDIF
      RETURN - 1
   ENDIF   
   
   oWnd:WindowState := GetWindowPlacement( oWnd:handle )	      
   IF wParam == SC_MINIMIZE
      IF __ObjHasMsg( oWnd, "LTRAY" ) .AND. oWnd:lTray
         oWnd:Hide()
         RETURN 0
      ENDIF
   ELSEIF ( wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2 ) .AND. ;
      oWnd:type == WND_MDICHILD .AND. ( oWnd:lChild .OR. oWnd:lModal )
      IF oWnd:WindowState == SW_SHOWMINIMIZED
          SendMessage( oWnd:HANDLE, WM_SYSCOMMAND, SC_RESTORE, 0 )
          SendMessage( oWnd:HANDLE, WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
          RETURN 0
      ENDIF
      ars := aClone( oWnd:aRectSave )
      IF oWnd:lMaximized
          // restore
         MoveWindow(oWnd:Handle, oWnd:aRectSave[ 1 ], oWnd:aRectSave[ 2 ], oWnd:aRectSave[ 3 ], oWnd:aRectSave[ 4 ] )
         MoveWindow(oWnd:Handle, oWnd:aRectSave[ 1 ] - ( oWnd:nLeft - oWnd:aRectSave[ 1 ] ), ;
                                  oWnd:aRectSave[ 2 ] - ( oWnd:nTop - oWnd:aRectSave[ 2 ] ), ;
                                  oWnd:aRectSave[ 3 ], oWnd:aRectSave[ 4 ] )
      ELSE
          // maximized
         MoveWindow( oWnd:handle, oWnd:oClient:nLeft, oWnd:oClient:nTop, oWnd:oClient:nWidth, oWnd:oClient:nHeight )
      ENDIF
      oWnd:aRectSave := aClone( ars )
      oWnd:lMaximized := ! oWnd:lMaximized
      RETURN 0
   ELSEIF  (wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2 ) //.AND. oWnd:type != WND_MDICHILD

   ELSEIF wParam == SC_RESTORE .OR. wParam == SC_RESTORE2

   ELSEIF wParam = SC_NEXTWINDOW .OR. wParam = SC_PREVWINDOW
      // ctrl+tab   IN Mdi child
      IF ! Empty( oWnd:lDisableCtrlTab ) .AND. oWnd:lDisableCtrlTab
          RETURN 0
      ENDIF
   ELSEIF wParam = SC_KEYMENU
      // accelerator MDICHILD
      IF Len( HWindow():aWindows) > 2 .AND. ( ( oChild:=oWnd ):Type = WND_MDICHILD .OR. !EMPTY( oChild := oWnd:GetMdiActive() ) )
         IF ( oCtrl := FindAccelerator( oChild, lParam ) ) != Nil
            oCtrl:SetFocus()
            sendMessage( oCtrl:handle, WM_SYSKEYUP, lParam, 0 )
            RETURN - 2
           /*  MNC_IGNORE = 0  MNC_CLOSE = 1  MNC_EXECUTE = 2  MNC_SELECT = 3 */
         ENDIF
      ENDIF
   ELSEIF wParam = SC_HOTKEY
   //ELSEIF wParam = SC_MOUSEMENU  //0xF090
   ELSEIF wParam = SC_MENU .AND. ( oWnd:type == WND_MDICHILD .OR. ! Empty( oWnd := oWnd:GetMdiActive())) .AND. oWnd:lModal
      MSGBEEP()
      RETURN 0
   ENDIF

   RETURN - 1

STATIC FUNCTION onEndSession( oWnd, wParam )

   LOCAL i

   HB_SYMBOL_UNUSED( wParam )

   IF ISBLOCK( oWnd:bDestroy )
      i := Eval( oWnd:bDestroy, oWnd )
      i := IIf( ValType( i ) == "L", i, .t. )
      IF ! i
         RETURN 0
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onNotifyIcon( oWnd, wParam, lParam )
   LOCAL ar

   IF wParam == ID_NOTIFYICON
      IF PtrtoUlong(lParam) == WM_LBUTTONDOWN
         IF ISBLOCK( oWnd:bNotify )
            Eval( oWnd:bNotify )
         ENDIF
      ELSEIF PtrtoUlong(lParam) == WM_RBUTTONDOWN
         IF oWnd:oNotifyMenu != Nil
            ar := hwg_GetCursorPos()
            oWnd:oNotifyMenu:Show( oWnd, ar[ 1 ], ar[ 2 ] )
         ENDIF
      ENDIF
   ENDIF
   RETURN - 1

STATIC FUNCTION onMdiCreate( oWnd, lParam )
   LOCAL nReturn
   HB_SYMBOL_UNUSED( lParam )

   IF ISBLOCK( oWnd:bSetForm )
      EVAL( oWnd:bSetForm, oWnd )
   ENDIF
   IF ! EMPTY ( oWnd:oWndParent )
       oWnd:oParent := oWnd:oWndParent
   ENDIF
   IF ! oWnd:lClosable
      oWnd:Closable( .F. )
   ENDIF
   InitControls( oWnd )
   InitObjects( oWnd, .T. )
   IF oWnd:bInit != Nil
      IF Valtype( nReturn := Eval( oWnd:bInit, oWnd ) ) != "N"
         IF VALTYPE( nReturn ) == "L" .AND. ! nReturn
            oWnd:Close()
            RETURN Nil
         ENDIF
      ENDIF
   ENDIF
   //draw rect focus
   oWnd:nInitFocus := IIF(VALTYPE( oWnd:nInitFocus ) = "O", oWnd:nInitFocus:Handle, oWnd:nInitFocus )   
   SENDMESSAGE( oWnd:handle, WM_UPDATEUISTATE, makelong( UIS_CLEAR, UISF_HIDEFOCUS ), 0 )
   SENDMESSAGE( oWnd:handle, WM_UPDATEUISTATE, makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )
   IF oWnd:WindowState > 0
      onMove( oWnd )  
   ENDIF 
   RETURN - 1

STATIC FUNCTION onMdiCommand( oWnd, wParam )
   LOCAL iParHigh, iParLow, iItem, aMenu, oCtrl

   IF wParam == SC_CLOSE
      SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIDESTROY, oWnd:handle, 0 )
   ENDIF
   iParHigh := HIWORD( wParam )
   iParLow := LOWORD( wParam )
   IF ISWINDOWVISIBLE( oWnd:Handle )
      oCtrl := oWnd:FindControl( iParLow )
   ENDIF
   IF oWnd:aEvents != Nil .AND. !oWnd:lSuspendMsgsHandling  .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      IF PtrtouLong( GetParent( GetFocus() ) ) = PtrtouLong( oWnd:Handle )
         oWnd:nFocus := GetFocus()
      ENDIF   
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ELSEIF __ObjHasMsg( oWnd ,"OPOPUP") .AND. oWnd:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iItem ) ) != Nil ;
         .AND. aMenu[ 1, iItem, 1 ] != Nil
          Eval( aMenu[ 1, iItem, 1 ],  wParam )
   ELSEIF iParHigh = 1  // acelerator

   ENDIF
   IF  oCtrl != Nil .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( oCtrl:handle ), WS_TABSTOP ) != 0 .AND.;
      GetFocus() == oCtrl:Handle
      oWnd:nFocus := oCtrl:handle
   ENDIF
   RETURN 0

STATIC FUNCTION onMdiNcActivate( oWnd, wParam )

   IF ! Empty( oWnd:Screen )
      IF wParam = 1 .AND. oWnd:Screen:handle == oWnd:handle
         SetWindowPos( oWnd:Screen:HANDLE, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
         RETURN 1
      ENDIF
      IF wParam == 1 .AND. oWnd:Screen:Handle != oWnd:HANDLE 
         // triggered ON GETFOCUS MDI CHILD MAXIMIZED
         IF ISBLOCK( oWnd:bSetForm )
            EVAL( oWnd:bSetForm, oWnd )
         ENDIF   
         IF  ! oWnd:lSuspendMsgsHandling .AND.;
            oWnd:bGetFocus != Nil .AND. ! Empty( GetFocus() ) .AND. oWnd:IsMaximized()
            oWnd:lSuspendMsgsHandling := .T.
            Eval( oWnd:bGetFocus, oWnd )
            oWnd:lSuspendMsgsHandling := .F.
          ENDIF
      ENDIF
   ENDIF
   RETURN - 1

Static Function onMdiActivate( oWnd,wParam, lParam )
   Local  lScreen := oWnd:Screen != nil, aWndMain
   Local lConf
   
   If ValType( wParam ) == ValType( oWnd:Handle )
      lConf := wParam = oWnd:Handle
   Else
      lConf := .F.
   EndIf
   // added
   IF  lScreen .AND. ( Empty( lParam ) .OR. ;
       lParam = oWnd:Screen:Handle ) .AND. !lConf //wParam != oWnd:Handle
      *-SetWindowPos( oWnd:Screen:Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
      RETURN 0
   ELSEIF lConf //oWnd:Handle = wParam
      IF  oWnd:Screen:handle != wParam .AND. oWnd:bLostFocus != Nil //.AND.wParam == 0
         oWnd:lSuspendMsgsHandling := .t.
         //IF oWnd:Screen:handle = lParam
         //   SetWindowPos( oWnd:Screen:Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
         //ENDIF
         Eval( oWnd:bLostFocus, oWnd )
         oWnd:lSuspendMsgsHandling := .f.
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEVAL( aWndMain,{| w | IIF( w:Type >= WND_MDICHILD .AND.;
             PtrtoUlong( w:Handle ) != PtrtoUlong( wParam ), EnableWindow( w:Handle, .T. ), ) })
      ENDIF
   ELSEIF oWnd:Handle = lParam  //.AND. ownd:screen:handle != WPARAM
      IF ISBLOCK( oWnd:bSetForm )
         EVAL( oWnd:bSetForm, oWnd )
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEVAL( aWndMain,{| w | IIF( w:Type >= WND_MDICHILD .AND.;
             PtrtoUlong( w:Handle ) != PtrtoUlong( lParam ), EnableWindow( w:Handle, .F. ), ) })
     ENDIF
      IF oWnd:bGetFocus != Nil .AND. ! oWnd:lSuspendMsgsHandling .AND. ! oWnd:IsMaximized()
         oWnd:lSuspendMsgsHandling := .t.
         IF EMPTY( oWnd:nFocus )
             UpdateWindow( oWnd:Handle)
         ENDIF
         Eval( oWnd:bGetFocus, oWnd )
         oWnd:lSuspendMsgsHandling := .f.
      ENDIF
   ENDIF

   RETURN 0

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

//add by sauli
STATIC FUNCTION onCloseQuery( o )
   IF ValType( o:bCloseQuery ) = 'B'
      IF Eval( o:bCloseQuery )
         ReleaseAllWindows( o:handle )
      END
   ELSE
      ReleaseAllWindows( o:handle )
   END

   RETURN - 1
// end sauli

STATIC FUNCTION onActivate( oWin, wParam, lParam )
   LOCAL iParLow := LOWORD( wParam ), iParHigh := HIWORD( wParam )

   HB_SYMBOL_UNUSED( lParam )

   IF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE ) .AND. IsWindowVisible( oWin:handle )
      IF  ( oWin:type = WND_MDICHILD .AND. PtrtoUlong( lParam ) = 0  ) .OR.;
          ( oWin:type != WND_MDICHILD .AND. iParHigh = 0 ) 
         IF oWin:bGetFocus != Nil //.AND. IsWindowVisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            IF iParHigh > 0  // MINIMIZED
               *oWin:restore()
            ENDIF
            Eval( oWin:bGetFocus, oWin, lParam )
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF   
   ELSEIF iParLow = WA_INACTIVE 
      IF  ( oWin:type = WND_MDICHILD .AND. PtrtoUlong( lParam ) != 0 ).OR.;
          ( oWin:type != WND_MDICHILD .AND. iParHigh = 0 .AND. PtrtoUlong( lParam ) = 0 ) 
         IF  oWin:bLostFocus != Nil //.AND. IsWindowVisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            Eval( oWin:bLostFocus, oWin, lParam )
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF   
   ENDIF
   RETURN 1
