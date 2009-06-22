/*
 *$Id: hwindow.prg,v 1.83 2009-06-22 15:29:46 lfbasso Exp $
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

   oWnd:Super:onEvent( WM_SIZE, wParam, lParam )

   oWnd:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   oWnd:nHeight := aCoors[ 4 ] - aCoors[ 2 ]

   IF ISBLOCK( oWnd:bSize )
      Eval( oWnd:bSize, oWnd, LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF
   IF oWnd:Type == WND_MDI .AND. Len( HWindow():aWindows ) > 1
      aCoors := GetClientRect( oWnd:handle )
      MoveWindow( HWindow():aWindows[ 2 ]:handle, oWnd:aOffset[ 1 ], oWnd:aOffset[ 2 ], aCoors[ 3 ] - oWnd:aOffset[ 1 ] - oWnd:aOffset[ 3 ], aCoors[ 4 ] - oWnd:aOffset[ 2 ] - oWnd:aOffset[ 4 ] )
      aCoors := GetClientRect(HWindow():aWindows[ 2 ]:handle)
      HWindow():aWindows[ 2 ]:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
      HWindow():aWindows[ 2 ]:nHeight := aCoors[ 4 ] - aCoors[ 2 ]             
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
   DATA bCloseQuery
   Data nFocus  INIT 0
   DATA oClient
   DATA lChild INIT .F.
   DATA lDisableCtrlTab INIT .F.

   DATA aOffset
   DATA oEmbedded
   DATA bScroll

   METHOD New( Icon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
               bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, cAppName, oBmp, cHelp, ;
               nHelpId, bCloseQuery, bRefresh, lChild ) 
   METHOD AddItem( oWnd )
   METHOD DelItem( oWnd )
   METHOD FindWindow( hWnd )
   METHOD GetMain()
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle )
   METHOD Restore()  INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_RESTORE, 0 )
   METHOD Maximize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
   METHOD Minimize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MINIMIZE, 0 )
   METHOD Close()   INLINE SendMessage( ::handle, WM_SYSCOMMAND, SC_CLOSE, 0 )
ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
            bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, lChild ) CLASS HWindow

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
   ::lChild := IIF( lChild != Nil, lChild , ::lChild )

   IF clr != NIL
      ::brush := HBrush():Add( clr )
      ::bColor := clr
   ENDIF

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
   LOCAL i := AScan( ::aWindows, { | o | o:handle == hWnd } )
   RETURN IIf( i == 0, Nil, ::aWindows[ i ] )

METHOD GetMain() CLASS HWindow
   RETURN IIf( Len( ::aWindows ) > 0,              ;
               IIf( ::aWindows[ 1 ]:Type == WND_MAIN, ;
                    ::aWindows[ 1 ],                  ;
                    IIf( Len( ::aWindows ) > 1, ::aWindows[ 2 ], Nil ) ), Nil )



CLASS HMainWindow INHERIT HWindow

CLASS VAR aMessages INIT { ;
                           { WM_COMMAND, WM_ERASEBKGND, WM_MOVE, WM_SIZE, WM_SYSCOMMAND, ;
                             WM_NOTIFYICON, WM_ENTERIDLE, WM_CLOSE, WM_DESTROY, WM_ENDSESSION, WM_ACTIVATE  }, ;
                           { ;
                             { | o, w, l | onCommand( o, w, l ) },        ;
                             { | o, w | onEraseBk( o, w ) },              ;
                             { | o | onMove( o ) },                       ;
                             { | o, w, l | onSize( o, w, l ) },           ;
                             { | o, w | onSysCommand( o, w ) },           ;
                             { | o, w, l | onNotifyIcon( o, w, l ) },     ;
                             { | o, w, l | onEnterIdle( o, w, l ) },      ;
                             { | o | onCloseQuery( o ) },                 ;
                             { | o | onDestroy( o ) },                    ;
                             { | o, w | onEndSession( o, w ) },           ;
                             { | o, w, l | onActivate( o, w, l ) }        ;
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
   METHOD GetMdiActive()  INLINE ::FindWindow( SendMessage( ::GetMain():handle, WM_MDIGETACTIVE, 0, 0 ) )

ENDCLASS

METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
            oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, bMdiMenu ) CLASS HMainWindow

   Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh )
   ::Type := lType

   IF lType == WND_MDI

      ::nMenuPos := nPos
      ::bMdiMenu := bMdiMenu
      ::Style := nStyle
      ::tColor := clr
      ::oBmp := oBmp
       clr:= nil  // because error
      ::handle := Hwg_InitMdiWindow( Self, ::szAppName, cTitle, cMenu,  ;
                                     IIf( oIcon != Nil, oIcon:handle, Nil ), , ;  //clr, ;
                                     nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

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
   lCentered  := ( ! EMPTY( lCentered ) .AND. lCentered ) .OR. Hwg_BitAND( ::Style, DS_CENTER ) != 0
   DEFAULT lShow := .T.
   CreateGetList( Self )

   IF ::bInit != Nil
      lres := Eval( ::bInit, Self )
      IF ValType( lres ) = "L" .AND. ! lres
         SENDMESSAGE( ::handle, WM_DESTROY, 0, 0 )
         RETURN Nil
      ENDIF
   ENDIF

   IF ::Type == WND_MDI

      oWndClient := HWindow():New( ,,, ::style, ::title,, ::bInit, ::bDestroy, ::bSize, ;
                                   ::bPaint, ::bGetFocus, ::bLostFocus, ::bOther, ::obmp )
      //handle := Hwg_InitClientWindow( oWndClient, ::nMenuPos, ::nLeft, ::nTop + 60, ::nWidth, ::nHeight )                                   
      handle := Hwg_InitClientWindow( oWndClient, ::nMenuPos, ::nLeft, ::nTop, ::nWidth, ::nHeight )
      oWndClient:handle = handle
      
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
      
      ::oClient := HWindow():aWindows[2]
      Hwg_ActivateMdiWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ELSEIF ::Type == WND_MAIN

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

      Hwg_ActivateMainWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMainWindow
   LOCAL i

   // writelog( str(msg) + str(wParam) + str(lParam) )
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
                             { | o, w | onSysCommand( o, w ) },         ;
                             { | o, w, l | onEnterIdle( o, w, l ) },      ;
                             { | o, w, l | onMdiActivate( o, w, l ) },     ;
                             { | o | onDestroy( o ) }                 ;
                           } ;
                         }
   DATA aRectSave
   DATA oWndParent
   
   METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD SetParent( oParent ) INLINE ::oWndParent := oParent 

ENDCLASS

METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate ) CLASS HMDIChildWindow

   HB_SYMBOL_UNUSED( lShow )
   HB_SYMBOL_UNUSED( lMaximized )
   HB_SYMBOL_UNUSED( lMinimized )
   HB_SYMBOL_UNUSED( lCentered )

   DEFAULT lShow := .T.
   lMinimized := !EMPTY( lMinimized ) .AND. lMinimized
   lMaximized := !EMPTY( lMaximized ) .AND. lMaximized
   lCentered  := ( ! EMPTY( lCentered ) .AND. lCentered ) .OR. Hwg_BitAND( ::Style, DS_CENTER ) != 0
   
   CreateGetList( Self )
   // Hwg_CreateMdiChildWindow( Self )

   ::Type := WND_MDICHILD
   ::oClient := HWindow():aWindows[2]
   ::rect := GetWindowRect( ::handle )   
   IF lCentered 
      ::nLeft := ( ::oClient:nWidth - ::nWidth ) / 2 
      ::nTop  := ( ::oClient:nHeight - ::nHeight ) / 2  
   ENDIF
   ::handle := Hwg_CreateMdiChildWindow( Self, IIF( lMinimized, WS_MINIMIZE, ;
         IIF( lMaximized, WS_MAXIMIZE, 0 ) ) + IIF( !lShow, - WS_VISIBLE, WS_VISIBLE  ) )

   // is necessary for set zorder control 
   InitControls( Self )
   /*  in ONMDICREATE   
   /*
   InitObjects( Self,.T. )
   IF ::bInit != Nil
      Eval( ::bInit,Self )
   ENDIF
   */
   IF lCentered 
      ::nLeft := ( ::oClient:nWidth - ::nWidth ) / 2 - 0
      ::nTop  := ( ::oClient:nHeight - ::nHeight ) / 2  - 0
   ENDIF
   ::aRectSave := { ::nLeft, ::nTop, ::nwidth, ::nHeight } 			
   ::show()
   
   IF bActivate != NIL
      Eval( bActivate, Self )
   ENDIF

   IF ( ValType( ::nInitFocus ) = "O" .OR. ::nInitFocus > 0 )
      ::nInitFocus := IIf( ValType( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      SETFOCUS( ::nInitFocus )
      ::nFocus := ::nInitFocus
   ELSEIF GETFOCUS() = ::handle .AND. Len( ::acontrols ) > 0
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

   IF msg = WM_NCLBUTTONDBLCLK .AND. ::lChild
      Return 0
   ELSEIF msg = WM_GETMINMAXINFO //= &H24  
      IF ::minWidth  > -1 .OR. ::maxWidth  > -1 .OR. ::minHeight > -1 .OR. ::maxHeight > -1 
         MINMAXWINDOW(::handle, lParam,;
         IIF(::minWidth  > -1,::minWidth,nil), IIF(::minHeight > -1,::minHeight,nil),;
         IIF(::maxWidth  > -1,::maxWidth,nil), IIF(::maxHeight > -1,::maxHeight,nil))
         RETURN 0
      ENDIF   
   ELSEIF msg = WM_SETFOCUS .AND. ::nFocus != 0
      SETFOCUS( ::nFocus )
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
            ::nFocus := oCtrl:handle
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
   METHOD Activate( lShow, lMaximized, lMinimized,lCentered, bActivate )
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

METHOD Activate( lShow, lMaximized, lMinimized,lCentered, bActivate ) CLASS HChildWindow
   LOCAL nReturn

   DEFAULT lShow := .T.
   ::Type := WND_CHILD 

   CreateGetList( Self )
   //   InitControls( SELF,.T. )
   InitObjects( Self, .T. )
   
   ::hide()
   IF ::bInit != Nil
      IF Valtype( nReturn := Eval( ::bInit, Self ) ) != "N"
         IF VALTYPE( nReturn ) == "L" .AND. ! nReturn
            ::Close()
            RETURN Nil
         ENDIF
      ENDIF
   ENDIF

   Hwg_ActivateChildWindow( ( lShow == Nil .OR. lShow ), ::handle, lMaximized, lMinimized )

   IF !EMPTY( lCentered ) .AND. lCentered 
      IF  ! EMPTY( ::oParent )
        ::nLeft := (::oParent:nWidth - ::nWidth ) / 2 
        ::nTop  := (::oParent:nHeight - ::nHeight) / 2  
      ENDIF
   ENDIF

   IF ( bActivate  != NIL )
      Eval( bActivate, Self )
   ENDIF

   IF ( ValType( ::nInitFocus ) = "O" .OR. ::nInitFocus > 0 )
      ::nInitFocus := IIf( ValType( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      SETFOCUS( ::nInitFocus )
      ::nFocus := ::nInitFocus
   ELSEIF GETFOCUS() = ::handle .AND. Len( ::acontrols ) > 0
      ::nFocus := ASCAN( ::aControls,{|o| Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_TABSTOP ) != 0 .AND. ;
           Hwg_BitaND( HWG_GETWINDOWSTYLE( o:handle ), WS_DISABLED ) = 0 } )
      IF ::nFocus > 0        
         SETFOCUS( ::acontrols[ ::nFocus ]:handle )
         ::nFocus := GetFocus() //get::acontrols[1]:handle
      ENDIF   
   ENDIF
   RETURN Nil


METHOD onEvent( msg, wParam, lParam )  CLASS HChildWindow
   LOCAL i

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
      ENDIF
      RETURN Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

FUNCTION ReleaseAllWindows( hWnd )
   LOCAL oItem, iCont, nCont

   //  Vamos mandar destruir as filhas
   // Destroi as CHILD's desta MAIN
   #ifdef __XHARBOUR__

      HB_SYMBOL_UNUSED( iCont )
      HB_SYMBOL_UNUSED( nCont )

      FOR EACH oItem IN HWindow():aWindows
         IF oItem:oParent != Nil .AND. oItem:oParent:handle == hWnd
            SendMessage( oItem:handle, WM_CLOSE, 0, 0 )
         ENDIF
      NEXT
   #else

      HB_SYMBOL_UNUSED( oItem )

      nCont := Len( HWindow():aWindows )

      FOR iCont := nCont TO 1 STEP - 1

         IF HWindow():aWindows[ iCont ]:oParent != Nil .AND. ;
            HWindow():aWindows[ iCont ]:oParent:handle == hWnd
            SendMessage( HWindow():aWindows[ iCont ]:handle, WM_CLOSE, 0, 0 )
         ENDIF

      NEXT
   #endif

   IF HWindow():aWindows[ 1 ]:handle == hWnd
      PostQuitMessage( 0 )
   ENDIF

   RETURN - 1

   #define  FLAG_CHECK      2

STATIC FUNCTION onCommand( oWnd, wParam, lParam )
   LOCAL iItem, iCont, aMenu, iParHigh, iParLow, nHandle, oChild, i

   HB_SYMBOL_UNUSED( lParam )

   IF wParam == SC_CLOSE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         // CLOSE ONLY MDICHILD HERE
         oChild := oWnd:FindWindow( nHandle ) 
         IF oChild != Nil .AND. ISBLOCK( oChild:bDestroy )
            oChild:lSuspendMsgsHandling := .T.
            i := Eval( oChild:bDestroy, oChild )
            oChild:lSuspendMsgsHandling := .F.
            i := IIf( Valtype(i) == "L", i, .T. )
            IF ! i
               Return 0
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
      nHandle := HWindow():aWindows[ wParam - FIRST_MDICHILD_ID + 3 ]:handle
      SendMessage( HWindow():aWindows[ 2 ]:handle, WM_MDIACTIVATE, nHandle, 0 )
   ENDIF
   iParHigh := HIWORD( wParam )
   iParLow := LOWORD( wParam )
   IF oWnd:aEvents != Nil .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ELSEIF ValType( oWnd:menu ) == "A" .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:menu, iParLow, @iCont ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1, iCont, 4 ], FLAG_CHECK ) > 0
         CheckMenuItem( , aMenu[ 1, iCont, 3 ], ! IsCheckedMenuItem( , aMenu[ 1, iCont, 3 ] ) )
      ENDIF
      IF aMenu[ 1, iCont, 1 ] != Nil
         Eval( aMenu[ 1, iCont, 1 ] )
      ENDIF
   ELSEIF oWnd:oPopup != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[ 1, iCont, 1 ] != Nil
      Eval( aMenu[ 1, iCont, 1 ] )
   ELSEIF oWnd:oNotifyMenu != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oNotifyMenu:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[ 1, iCont, 1 ] != Nil
      Eval( aMenu[ 1, iCont, 1 ] )
   ELSEIF  wParam != SC_CLOSE .AND. wParam != SC_MINIMIZE .AND. wParam != SC_MAXIMIZE .AND.;
           wParam != SC_RESTORE .AND. oWnd:Type = WND_MDI .AND. oWnd:bMdiMenu != Nil    
      // menu MDICHILD
      Eval( oWnd:bMdiMenu, oWnd, wParam )
      
   ENDIF

   RETURN 0

STATIC FUNCTION onMove( oWnd )
   LOCAL aControls := GetWindowRect( oWnd:handle )

   oWnd:nLeft := aControls[ 1 ]
   oWnd:nTop  := aControls[ 2 ]
   IF oWnd:type == WND_MDICHILD 
      oWnd:aRectSave := { oWnd:nLeft - (HWindow():aWindows[ 1 ]:aOffset[ 1 ]+HWindow():aWindows[ 1 ]:aOffset[ 3 ] ),;
          oWnd:nTop - (HWindow():aWindows[ 1 ]:aOffset[ 2 ] + HWindow():aWindows[ 1 ]:aOffset[ 4 ] + 21 ),; // 21 - menu
          oWnd:nWidth,oWnd:nHeight} 
   ENDIF   

   RETURN - 1

STATIC FUNCTION onEraseBk( oWnd, wParam )
   LOCAL aCoors

   IF oWnd:oBmp != Nil .AND. oWnd:type != WND_MDI
      IF oWnd:lBmpCenter
         CenterBitmap( wParam, oWnd:handle, oWnd:oBmp:handle, , oWnd:nBmpClr )
      ELSE
         SpreadBitmap( wParam, oWnd:handle, oWnd:oBmp:handle )
      ENDIF
      RETURN 1
   ELSEIF oWnd:Type != WND_MDI
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


STATIC FUNCTION onSysCommand( oWnd, wParam )
   LOCAL i, ars

   IF wParam == SC_CLOSE
      IF ISBLOCK( oWnd:bDestroy )
         oWnd:lSuspendMsgsHandling := .T.
         i := Eval( oWnd:bDestroy, oWnd )
         oWnd:lSuspendMsgsHandling := .F.
         i := IIf( ValType( i ) == "L", i, .t. )
         IF ! i
            RETURN 0
         ENDIF
      ENDIF
      IF __ObjHasMsg( oWnd, "ONOTIFYICON" ) .AND. oWnd:oNotifyIcon != Nil
         ShellNotifyIcon( .F., oWnd:handle, oWnd:oNotifyIcon:handle )
      ENDIF
      IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
         DestroyAcceleratorTable( oWnd:hAccel )
      ENDIF
   ELSEIF wParam == SC_MINIMIZE
      IF __ObjHasMsg( oWnd, "LTRAY" ) .AND. oWnd:lTray
         oWnd:Hide()
         RETURN 0
      ENDIF
   ELSEIF wParam == SC_MAXIMIZE  .AND. oWnd:type == WND_MDICHILD .AND. oWnd:lChild
      ars := aClone( oWnd:aRectSave )
      IF oWnd:nwidth = oWnd:oclient:nWidth 
          // restore
         MoveWindow( oWnd:handle, oWnd:aRectSave[ 1 ], oWnd:aRectSave[ 2 ],oWnd:aRectSave[ 3 ], oWnd:aRectSave[ 4 ] )
      ELSE
          // maximized
         MoveWindow( oWnd:handle, oWnd:oclient:nLeft, oWnd:oclient:nTop, oWnd:oclient:nWidth, oWnd:oclient:nHeight )
      ENDIF
      oWnd:aRectSave := aClone( ars )
      RETURN 0
   ELSEIF wParam == SC_MAXIMIZE	     
   
   ELSEIF wParam == SC_RESTORE           
   
   ELSEIF wParam == 61504  // ctrl+tab   IN Mdi child
      IF ! Empty( oWnd:lDisableCtrlTab ) .AND. oWnd:lDisableCtrlTab
          RETURN 0
      ENDIF
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
      IF lParam == WM_LBUTTONDOWN
         IF ISBLOCK( oWnd:bNotify )
            Eval( oWnd:bNotify )
         ENDIF
      ELSEIF lParam == WM_RBUTTONDOWN
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

   IF ! EMPTY ( oWnd:oWndParent )
       oWnd:oParent := oWnd:oWndParent 
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
   SENDMESSAGE( oWnd:handle, WM_UPDATEUISTATE, makelong( UIS_CLEAR, UISF_HIDEFOCUS ), 0 )
   SENDMESSAGE( oWnd:handle, WM_UPDATEUISTATE, makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )
   
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
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ELSEIF __ObjHasMsg( oWnd ,"OPOPUP") .AND. oWnd:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iItem ) ) != Nil ;
         .AND. aMenu[ 1, iItem, 1 ] != Nil
          Eval( aMenu[ 1, iItem, 1 ] )
   ELSEIF iParHigh = 1  // acelerator
        
   ENDIF
   IF  oCtrl != Nil .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( oCtrl:handle ), WS_TABSTOP ) != 0
      oWnd:nFocus := oCtrl:handle
   ENDIF  
   RETURN 0

STATIC FUNCTION onMdiNcActivate( oWnd, wParam )

   IF wParam == 0  .AND. ISWINDOWVISIBLE( oWnd:Handle ) //.T. //LMODAL 
      RETURN -1
   ENDIF
   IF wParam == 1 .AND. oWnd:nFocus > 0
      SetFocus( oWnd:nFocus )
   ENDIF

   /*
   IF wParam == 1 .AND. oWnd:bGetFocus != Nil
      Eval( oWnd:bGetFocus, oWnd )
   ELSEIF wParam == 0 .AND. oWnd:bLostFocus != Nil
      Eval( oWnd:bLostFocus, oWnd )
   ENDIF
    */

   RETURN - 1

Static Function onMdiActivate( oWnd,wParam, lParam ) 
   
   IF EMPTY( lParam ) // MDI CLIENTE
      RETURN 0
   ENDIF
   // MDI CHILD  - WPARAM HANDLE
   IF oWnd:Handle = wParam //.AND. MODAL
      IF wParam == 0 .AND. oWnd:bLostFocus != Nil
         oWnd:lSuspendMsgsHandling := .t.
         Eval( oWnd:bLostFocus, oWnd )
         oWnd:lSuspendMsgsHandling := .f.
       		 ENDIF
   ELSEIF oWnd:Handle = lParam  
      IF oWnd:bGetFocus != Nil
         oWnd:lSuspendMsgsHandling := .t.
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

   IF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE ) .AND. IsWindowVisible( oWin:handle )  .AND. PtrtoUlong( lParam ) = 0  
      IF oWin:bGetFocus != Nil //.AND. IsWindowVisible(::handle)
         oWin:lSuspendMsgsHandling := .T.
         IF iParHigh > 0  // MINIMIZED
               *oWin:restore()
         ENDIF
         Eval( oWin:bGetFocus, oWin, lParam )
         oWin:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF iParLow = WA_INACTIVE .AND. PtrtoUlong( lParam ) != 0 // oDlg:bGetFocus != Nil .AND. IsWindowVisible(odlg:handle)
      IF  oWin:bLostFocus != Nil //.AND. IsWindowVisible(::handle)
         oWin:lSuspendMsgsHandling := .T.
         Eval( oWin:bLostFocus, oWin, lParam )
         oWin:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF
   RETURN 1
