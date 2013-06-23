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
   LOCAL aCoors := hwg_Getwindowrect( oWnd:handle )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:Resize( hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ENDIF
   oWnd:Super:onEvent( WM_SIZE, wParam, lParam )

   oWnd:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
   oWnd:nHeight := aCoors[ 4 ] - aCoors[ 2 ]

   IF ISBLOCK( oWnd:bSize )
      Eval( oWnd:bSize, oWnd, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ENDIF
   IF oWnd:Type == WND_MDI .AND. Len( HWindow():aWindows ) > 1
      aCoors := hwg_Getclientrect( oWnd:handle )
      hwg_Setwindowpos( HWindow():aWindows[ 2 ]:handle, Nil, oWnd:aOffset[ 1 ], oWnd:aOffset[ 2 ], aCoors[ 3 ] - oWnd:aOffset[ 1 ] - oWnd:aOffset[ 3 ], aCoors[ 4 ] - oWnd:aOffset[ 2 ] - oWnd:aOffset[ 4 ] , SWP_NOZORDER + SWP_NOACTIVATE + SWP_NOSENDCHANGING )
      aCoors := hwg_Getwindowrect( HWindow():aWindows[ 2 ]:handle )
      HWindow():aWindows[ 2 ]:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
      HWindow():aWindows[ 2 ]:nHeight := aCoors[ 4 ] - aCoors[ 2 ]
      // ADDED                                                   =
      IF !Empty( oWnd:Screen )
          oWnd:Screen:nWidth  := aCoors[ 3 ] - aCoors[ 1 ]
          oWnd:Screen:nHeight := aCoors[ 4 ] - aCoors[ 2 ]
          hwg_Setwindowpos( oWnd:screen:handle, Nil, 0, 0, oWnd:Screen:nWidth, oWnd:Screen:nHeight, SWP_NOACTIVATE + SWP_NOSENDCHANGING + SWP_NOZORDER )
          IF hwg_Iswindowvisible( oWnd:screen:handle )
             hwg_Invalidaterect( oWnd:Screen:handle, 1 )
          ENDIF
      ENDIF
      IF ! Empty( oWnd := oWnd:GetMdiActive() ) .AND.oWnd:type = WND_MDICHILD .AND. oWnd:lMaximized .AND.;
           ( oWnd:lModal .OR. oWnd:lChild )
         oWnd:lMaximized := .F.
      ENDIF
      //
      RETURN 0
   ENDIF

   RETURN -1

FUNCTION hwg_onDestroy( oWnd )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:END()
   ENDIF
   oWnd:Super:onEvent( WM_DESTROY )
   oWnd:DelItem( oWnd )

   RETURN 0

CLASS HWindow INHERIT HCustomWindow, HScrollArea

CLASS VAR aWindows   SHARED INIT { }
CLASS VAR szAppName  SHARED INIT "HwGUI_App"

   CLASS VAR Screen SHARED

   DATA menu, oPopup, hAccel
   DATA oIcon, oBmp
   DATA lBmpCenter INIT .F.
   DATA bmpStretch INIT  1  // 1-Spread/ISOMETRIC  0-STRETCH  2-CENTER
   DATA nBmpClr
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lClipper INIT .F.
   DATA GetList  INIT { }      // The array of GET items in the dialog
   DATA KeyList  INIT { }      // The array of keys ( as Clipper's SET KEY )
   DATA nLastKey INIT 0
   DATA bActivate
   DATA lActivated INIT .F.
   DATA lExitOnEnter INIT .F.
   DATA lExitOnEsc INIT .T.
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
   DATA nInitFocus    INIT 0  // Keeps the ID of the object to receive focus when dialog is created
                              // you can change the object that receives focus adding
                              // ON INIT {|| nInitFocus:=object:[handle] }  to the dialog definition

   METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
               bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, lChild, lClipper,;
               lNoClosable, bSetForm, nBmpStretch )
   METHOD AddItem( oWnd )
   METHOD DelItem( oWnd )
   METHOD FindWindow( hWndTitle )
   METHOD GetMain()
   METHOD GetMdiMain() INLINE IIF( ::GetMain() != Nil, ::aWindows[ 1 ] , Nil )
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle, ::Type )
   METHOD Restore()  INLINE hwg_Sendmessage( ::handle,  WM_SYSCOMMAND, SC_RESTORE, 0 )
   METHOD Maximize() INLINE hwg_Sendmessage( ::handle,  WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
   METHOD Minimize() INLINE hwg_Sendmessage( ::handle,  WM_SYSCOMMAND, SC_MINIMIZE, 0 )
   METHOD Close()   INLINE hwg_Sendmessage( ::handle, WM_SYSCOMMAND, SC_CLOSE, 0 )
   METHOD Release()  INLINE ::Close( ), ::super:Release(), Self := Nil
   METHOD isMaximized() INLINE hwg_Getwindowplacement( ::handle ) == SW_SHOWMAXIMIZED
   METHOD isMinimized() INLINE hwg_Getwindowplacement( ::handle ) == SW_SHOWMINIMIZED
   METHOD isNormal() INLINE hwg_Getwindowplacement( ::handle ) == SW_SHOWNORMAL
   METHOD Paint()


ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
            bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, lChild,;
           lClipper, lNoClosable, bSetForm, nBmpStretch )  CLASS HWindow

   HB_SYMBOL_UNUSED( clr )
   HB_SYMBOL_UNUSED( cMenu )
   HB_SYMBOL_UNUSED( cHelp )

   ::oDefaultParent := Self
   ::title    := cTitle
   ::style    := IIf( nStyle == Nil, 0, nStyle )
   ::oIcon    := oIcon
   ::oBmp     := oBmp
   ::bmpStretch := IIF( nBmpStretch = NIL, ::bmpStretch, nBmpStretch )
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

   IF VALTYPE( cTitle ) != "N"
      ::AddItem( Self )
   ENDIF
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

METHOD FindWindow( hWndTitle ) CLASS HWindow
   LOCAL cType := VALTYPE( hWndTitle ), i

   IF cType != "C"
      i := AScan( ::aWindows, { | o | hwg_Ptrtoulong( o:handle ) == hwg_Ptrtoulong( hWndTitle ) } )
   ELSE
      i := AScan( ::aWindows, { | o | VALTYPE( o:Title ) = "C" .AND. o:Title == hWndTitle } )
   ENDIF
   RETURN IIf( i == 0, Nil, ::aWindows[ i ] )

METHOD GetMain() CLASS HWindow
   RETURN IIf( Len( ::aWindows ) > 0,              ;
               IIf( ::aWindows[ 1 ]:Type == WND_MAIN, ;
                    ::aWindows[ 1 ],                  ;
                    IIf( Len( ::aWindows ) > 1, ::aWindows[ 2 ], Nil ) ), Nil )

METHOD Paint() CLASS  HWindow

   IF ::bPaint = Nil .AND. ::oBmp = Nil .AND. ::type != WND_MDI .AND. hwg_Getupdaterect( ::handle ) > 0
      hwg_Paintwindow( ::handle, IIF( ::brush != Nil, ::brush:handle, Nil ) )
   ENDIF
   RETURN -1


CLASS HMainWindow INHERIT HWindow

CLASS VAR aMessages INIT { ;
      { WM_COMMAND, WM_ERASEBKGND, WM_MOVE, WM_SIZE, WM_SYSCOMMAND, ;
        WM_NOTIFYICON, WM_ENTERIDLE, WM_ACTIVATEAPP, WM_CLOSE, WM_DESTROY, WM_ENDSESSION, WM_ACTIVATE, WM_HELP }, ;
      { ;
        {|o,w,l| onCommand( o, w, l ) },        ;
        {|o,w| onEraseBk( o, w ) },             ;
        {|o| hwg_onMove( o ) },                 ;
        {|o,w,l| onSize( o, w, l ) },           ;
        {|o,w,l| onSysCommand( o, w, l ) },     ;
        {|o,w,l| onNotifyIcon( o, w, l ) },     ;
        {|o,w,l| onEnterIdle( o, w, l ) },      ;
        {|o,w,l| onEnterIdle( o, w, l ) },      ;
        {|o| onCloseQuery( o ) },               ;
        {|o| hwg_onDestroy( o ) },              ;
        {|o,w| onEndSession( o, w ) },          ;
        {|o,w,l| onActivate( o, w, l ) },       ;
        {|o,w,l| hwg_onHelp( o, w, l ) }        ;
      } ;
   }

   DATA  nMenuPos
   DATA  bMdiMenu
   DATA  oNotifyIcon, bNotify, oNotifyMenu
   DATA  lTray INIT .F.

   METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
               oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, bMdiMenu, nBmpStretch )
   METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip )
   METHOD GetMdiActive()  INLINE ::FindWindow( IIF( ::GetMain() != Nil, hwg_Sendmessage( ::GetMain():handle, WM_MDIGETACTIVE, 0, 0 ) , Nil ) )

ENDCLASS

METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
            oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, bMdiMenu, nBmpStretch ) CLASS HMainWindow

   ::Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh,,,,, nBmpStretch )
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
         hwg_SetHelpFileName( cHelp )
      ENDIF

      /* ADDED screen to backgroup to MDI MAIN */
      ::Screen := HMdiChildWindow():New(, ::tcolor, WS_CHILD + WS_MAXIMIZE + MB_USERICON + WS_DISABLED,;
                      0, 0, ::nWidth * 1, ::nheight * 1 - hwg_Getsystemmetrics( SM_CYSMCAPTION ) - hwg_Getsystemmetrics( SM_CYSMCAPTION ) , ;
                     -1 ,,,,,::bSize ,,,,,,::oBmp,,,,,, )
      ::Screen:Type    := WND_MDICHILD

      ::oDefaultParent := Self

   ELSEIF lType == WND_MAIN

      clr := nil  // because error and WINDOW IS INVISIBLE
      ::handle := Hwg_InitMainWindow( Self, ::szAppName, cTitle, cMenu, ;
                      IIf( oIcon != Nil, oIcon:handle, Nil ), ;
                      IIf( oBmp != Nil, - 1, clr ), nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

      IF cHelp != NIL
         hwg_SetHelpFileName( cHelp )
      ENDIF

   ENDIF
   ::rect := hwg_Getwindowrect( ::handle )
   RETURN Self

METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate ) CLASS HMainWindow
   LOCAL oWndClient, handle, lres

   DEFAULT lMaximized := .F.
   DEFAULT lMinimized := .F.
   lCentered  := ( ! lMaximized .AND. ! EMPTY( lCentered ) .AND. lCentered ) .OR. Hwg_BitAND( ::Style, DS_CENTER ) != 0
   DEFAULT lShow := .T.
   hwg_CreateGetList( Self )
   AEVAL( ::aControls, { | o | o:lInit := .F. } )

   IF ::Type == WND_MDI

      oWndClient := HWindow():New( ,,, ::style, ::title,, ::bInit, ::bDestroy, ::bSize, ;
                                   ::bPaint, ::bGetFocus, ::bLostFocus, ::bOther, ::obmp )

      handle := Hwg_InitClientWindow( oWndClient, ::nMenuPos, ::nLeft, ::nTop, ::nWidth, ::nHeight  )
      ::oClient := HWindow():aWindows[ 2 ]

     * hwg_Setwindowpos( ::oClient:Handle, 0, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
     *                   SWP_NOOWNERZORDER + SWP_FRAMECHANGED)

      /*
      // ADDED screen to backgroup to MDI MAIN
      ::Screen := HMdiChildWindow():New(, ::tcolor, WS_CHILD + MB_USERICON + WS_MAXIMIZE + WS_DISABLED,;
                  0, 0, ::nWidth * 1, ::nheight * 1 - hwg_Getsystemmetrics( SM_CYSMCAPTION ) - hwg_Getsystemmetrics( SM_CYSMCAPTION ) , ;
                 -1 ,,,,,,,,,,,::oBmp,,,,,, )
      */
      
      oWndClient:handle := handle
      /* recalculate area offset */
      hwg_Sendmessage( ::Handle, WM_SIZE, 0, hwg_Makelparam( ::nWidth, ::nHeight ) )

      IF ::Screen != Nil
         ::Screen:lExitOnEsc := .F.
         //::Screen:lClipper := .F.
         ::Screen:Activate( .T., .T. )
      ENDIF

      hwg_InitControls( Self )
      IF ::bInit != Nil
         lres := Eval( ::bInit, Self )
         IF ValType( lres ) = "L" .AND. ! lres
            hwg_Sendmessage( ::handle, WM_DESTROY, 0, 0 )
            RETURN Nil
         ENDIF
      ENDIF
      IF ::Screen != Nil
         ::Screen:lBmpCenter := ::lBmpCenter
         ::Screen:bmpStretch := ::BmpStretch
         /*
         ::Screen:Maximize()
         hwg_Setwindowpos( ::Screen:Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
                                                                 SWP_NOOWNERZORDER + SWP_FRAMECHANGED )
         ::Screen:Restore()
         */
      ENDIF

      IF lMaximized
         ::Maximize()
      ELSEIF lMinimized
         ::Minimize()
      ELSEIF lCentered
         ::Center()
      ENDIF

      hwg_Addtooltip( ::handle, ::handle, "" )
      IF ( bActivate  != NIL )
         Eval( bActivate, Self )
      ENDIF

      ::nInitFocus := IIF(VALTYPE( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      ::nInitFocus := IIF( Empty( ::nInitFocus ), FindInitFocus( ::aControls ), ::nInitFocus )
      IF ! Empty( ::nInitFocus )
         hwg_Setfocus( ::nInitFocus )
         ::nFocus := hwg_Getfocus()
      ENDIF

      Hwg_ActivateMdiWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ELSEIF ::Type == WND_MAIN

      IF ::bInit != Nil
         lres := Eval( ::bInit, Self )
         IF ValType( lres ) = "L" .AND. ! lres
            hwg_Sendmessage( ::handle, WM_DESTROY, 0, 0 )
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

      hwg_Addtooltip( ::handle, ::handle, "" )

      IF ( bActivate  != NIL )
         Eval( bActivate, Self )
      ENDIF
      
      ::nInitFocus := IIF(VALTYPE( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
      ::nInitFocus := IIF( Empty( ::nInitFocus ), FindInitFocus( ::aControls ), ::nInitFocus )
      IF ! Empty( ::nInitFocus )
         hwg_Setfocus( ::nInitFocus )
         ::nFocus := hwg_Getfocus()
      ENDIF
      
      Hwg_ActivateMainWindow( ( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized )

   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMainWindow
   Local i, xPos, yPos, oMdi, aCoors
   LOCAL nFocus := IIf( Hb_IsNumeric( ::nFocus ), ::nFocus, 0 )

   // writelog( str(msg) + str(wParam) + str(lParam) + chr(13) )

   IF msg = WM_MENUCHAR
      // PROCESS ACCELERATOR IN CONTROLS
      RETURN onSysCommand( Self, SC_KEYMENU, hwg_Loword( wParam ) )
   ELSEIF msg = WM_PAINT .AND. ::Type == WND_MAIN
      RETURN ::Paint( self )
   ENDIF
   // added control MDICHILD MODAL
   IF msg = WM_PARENTNOTIFY
      IF wParam = WM_LBUTTONDOWN .AND. !EMPTY( ::GetMdiActive() )
         oMdi := ::GetMdiActive()
         IF oMdi:lModal
            xPos := hwg_Loword( lParam )
            yPos := hwg_Hiword( lParam ) // + ::nTop + hwg_Getsystemmetrics( SM_CYMENU ) + hwg_Getsystemmetrics( SM_CYCAPTION )
            aCoors := hwg_Screentoclient( ::handle, hwg_Getwindowrect( oMdi:handle ) ) // acoors[1], acoors[2]  )
            IF ( ! hwg_Ptinrect( aCoors, { xPos, yPos } ) )
               hwg_Msgbeep()
               FOR i = 1 to 6
                  hwg_Flashwindow( oMdi:Handle, 1 )
                  hwg_Sleep( 60 )
               NEXT
               hwg_Setwindowpos( oMdi:Handle, HWND_TOP, 0, 0, 0, 0, ;
                             SWP_NOMOVE + SWP_NOSIZE +  SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
               ::lSuspendMsgsHandling := .T.
               RETURN 0
            ENDIF
         ENDIF
      ENDIF
   ELSEIF msg = WM_SETFOCUS .AND. !Empty( nFocus ) .AND. ! hwg_Selffocus( nFocus )
      hwg_Setfocus( nFocus )
   ENDIF
   IF ( i := Ascan( ::aMessages[1],msg ) ) != 0 .AND. ;
       ( !::lSuspendMsgsHandling .OR. msg = WM_ERASEBKGND .OR. msg = WM_SIZE )
      Return Eval( ::aMessages[2,i], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1
             hwg_ScrollHV( Self,msg,wParam,lParam )
         ENDIF
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip ) CLASS HMainWindow

   ::bNotify     := bNotify
   ::oNotifyMenu := oNotifyMenu
   ::oNotifyIcon := oNotifyIcon
   hwg_Shellnotifyicon( .T., ::handle, oNotifyIcon:handle, cTooltip )
   ::lTray := .T.

   RETURN Nil


CLASS HMDIChildWindow INHERIT HWindow

CLASS VAR aMessages INIT { ;
        { WM_CREATE, WM_COMMAND,WM_ERASEBKGND,WM_MOVE, WM_SIZE, WM_NCACTIVATE, ;
          WM_SYSCOMMAND, WM_ENTERIDLE, WM_MDIACTIVATE, WM_DESTROY }, ;
        { ;
          {|o,w,l| HB_SYMBOL_UNUSED( w ), onMdiCreate( o, l ) }, ;
          {|o,w| onMdiCommand( o, w ) },         ;
          {|o,w| onEraseBk( o, w ) },            ;
          {|o| hwg_onMove( o ) },                ;
          {|o,w,l| onSize( o, w, l ) },          ;
          {|o,w| onMdiNcActivate( o, w ) },      ;
          {|o,w,l| onSysCommand( o, w, l ) },    ;
          {|o,w,l| onEnterIdle( o, w, l ) },     ;
          {|o,w,l| onMdiActivate( o, w, l ) },   ;
          {|o| hwg_onDestroy( o ) }              ;
        } ;
   }
   DATA aRectSave
   DATA oWndParent
   DATA lMaximized  INIT .F.
   DATA lSizeBox    INIT .F.
   DATA lResult     INIT .F.
   DATA aChilds     INIT {}
   DATA hActive

   METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate, lModal)
   METHOD onEvent( msg, wParam, lParam )
   METHOD SetParent( oParent ) INLINE ::oWndParent := oParent

ENDCLASS

METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate, lModal ) CLASS HMDIChildWindow
   LOCAL l3d := .F.

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
   ::lSizeBox := Hwg_BitAnd( ::style, WS_SIZEBOX ) != 0
   ::WindowState := IIF( lMinimized, SW_SHOWMINIMIZED, IIF( lMaximized, SW_SHOWMAXIMIZED, IIF( lShow, SW_SHOWNORMAL, 0 ) ) )

   hwg_CreateGetList( Self )

   ::Type := WND_MDICHILD
   ::rect := hwg_Getwindowrect( ::handle )

   ::GETMDIMAIN():WindowState := hwg_Getwindowplacement( ::GETMDIMAIN():handle )
   ::oClient := HWindow():aWindows[ 2 ]
   IF lCentered
      ::nLeft := ( ::oClient:nWidth - ::nWidth ) / 2
      ::nTop  := ( ::oClient:nHeight - ::nHeight ) / 2
   ENDIF
   ::aRectSave := { ::nLeft, ::nTop, ::nwidth, ::nHeight }
   IF Hwg_BitAND( ::Style , DS_3DLOOK ) > 0
       *- efect  border 3d in mdichilds with no sizebox
      ::Style -=  DS_3DLOOK
      l3d := .T.
    ENDIF
   ::Style := Hwg_BitOr( ::Style , WS_VISIBLE ) - IIF( ! lshow .OR. ( lMaximized .AND. ( ::lChild .OR. ::lModal ) ) , WS_VISIBLE , 0 ) + ;
                        IIF( lMaximized .AND. ! ::lChild .AND. ! ::lModal , WS_MAXIMIZE, 0 )

   ::handle := Hwg_CreateMdiChildWindow( Self )
   
   ::nInitFocus := IIF(VALTYPE( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
   ::nInitFocus := IIF( Empty( ::nInitFocus ), FindInitFocus( ::aControls ), ::nInitFocus )
   IF ! Empty( ::nInitFocus )
       hwg_Setfocus( ::nInitFocus )
       ::nFocus := hwg_Getfocus()
    ENDIF

   IF VALTYPE( ::TITLE ) = "N" .AND. ::title = - 1   // screen
      RETURN .T.
   ENDIF
   IF lCentered
      ::nLeft := ( ::oClient:nWidth - ::nWidth ) / 2
      ::nTop  := ( ::oClient:nHeight - ::nHeight ) / 2
   ENDIF

   IF l3D
      // does not allow resizing
      ::minWidth  := ::nWidth
      ::minHeight := ::nHeight
      ::maxWidth  := ::nWidth
      ::maxHeight := ::nHeight
   ENDIF


   IF lShow
      *-hwg_onMove( Self )
      IF lMinimized  .OR. ::WindowState = SW_SHOWMINIMIZED
         ::Minimize()
      ELSEIF  ::WindowState = SW_SHOWMAXIMIZED .AND. ! ::IsMaximized()
         ::Maximize()
         hwg_Showwindow( ::Handle, SW_SHOWDEFAULT )
      ENDIF
   ELSE
      hwg_Setwindowpos( ::handle, Nil, ::nLeft, ::nTop, ::nWidth, ::nHeight, SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOZORDER )
   ENDIF

   ::RedefineScrollbars()

   IF bActivate != NIL
      Eval( bActivate, Self )
   ENDIF


   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMDIChildWindow
   LOCAL i, oCtrl
   LOCAL nFocus := IIf( Hb_IsNumeric( ::nFocus ), ::nFocus, 0 )
   //IF msg = WM_NCLBUTTONDBLCLK .AND. ::lChild
   //   Return 0

   IF msg = WM_GETMINMAXINFO //= &H24
      IF ::minWidth  > -1 .OR. ::maxWidth  > -1 .OR. ::minHeight > -1 .OR. ::maxHeight > -1
         hwg_Minmaxwindow(::handle, lParam,;
         IIF( ::minWidth  > -1, ::minWidth, Nil ),;
         IIF( ::minHeight > -1, ::minHeight, Nil ),;
         IIF( ::maxWidth  > -1, ::maxWidth, Nil ),;
         IIF( ::maxHeight > -1, ::maxHeight, Nil ) )
         RETURN 0

      ENDIF
   ELSEIF msg = WM_PAINT
      RETURN ::Paint( self )

   ELSEIF msg = WM_MOVING .AND. ::lMaximized
      ::Maximize()
   ELSEIF msg = WM_SETFOCUS .AND. !Empty( nFocus ) .AND. ! hwg_Selffocus( nFocus )
      hwg_Setfocus( nFocus )
      *-::nFocus := 0
   ELSEIF msg = WM_DESTROY .AND. ::lModal .AND. ! hwg_Selffocus( ::Screen:Handle, ::handle )
      IF ! EMPTY( ::hActive ) .AND. ! hwg_Selffocus( ::hActive, ::Screen:Handle )
         hwg_Postmessage( nFocus, WM_SETFOCUS, 0, 0 )
         hwg_Postmessage( ::hActive , WM_SETFOCUS, 0, 0 )
      ENDIF
      ::GETMDIMAIN():lSuspendMsgsHandling := .F.
   ENDIF

   IF ( i := AScan( ::aMessages[ 1 ], msg ) ) != 0
      RETURN Eval( ::aMessages[ 2, i ], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1
             hwg_ScrollHV( Self,msg,wParam,lParam )
         ENDIF
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ELSEIF msg = WM_NOTIFY .AND.!::lSuspendMsgsHandling
         IF ( oCtrl := ::FindControl( , hwg_Getfocus() ) ) != Nil .AND. oCtrl:ClassName != "HTAB"
            hwg_Sendmessage( oCtrl:handle, msg, wParam, lParam )
         ENDIF
      ENDIF
      RETURN ::Super:onEvent( msg, wParam, lParam )
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

   ::Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId,, bRefresh )
   ::oParent := HWindow():GetMain()
   ::Type := WND_CHILD
   ::rect := hwg_Getwindowrect( ::handle )
   IF ISOBJECT( ::oParent )
      ::handle := Hwg_InitChildWindow( Self, ::szAppName, cTitle, cMenu, ;
                                       IIf( oIcon != Nil, oIcon:handle, Nil ), IIf( oBmp != Nil, - 1, clr ), nStyle, ::nLeft, ;
                                       ::nTop, ::nWidth, ::nHeight, ::oParent:handle )
   ELSE
      hwg_Msgstop( "Create Main window first !", "HChildWindow():New()" )
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
   lMinimized := !EMPTY( lMinimized ) .AND. lMinimized .AND. Hwg_BitAnd( ::style, WS_MINIMIZE ) != 0
   lMaximized := !EMPTY( lMaximized ) .AND. lMaximized .AND. Hwg_BitAnd( ::style, WS_MAXIMIZE ) != 0

   ::Type := WND_CHILD

   hwg_CreateGetList( Self )
   hwg_InitControls( SELF )
   hwg_InitObjects( Self, .T. )

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
   //hwg_Sendmessage( ::Handle, WM_NCACTIVATE, 1, Nil )
   hwg_Sendmessage( ::handle, WM_UPDATEUISTATE, hwg_Makelong( UIS_CLEAR, UISF_HIDEFOCUS ), 0 )
   hwg_Sendmessage( ::handle, WM_UPDATEUISTATE, hwg_Makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )

   
   IF !EMPTY( lCentered ) .AND. lCentered
      IF  ! EMPTY( ::oParent )
        ::nLeft := (::oParent:nWidth - ::nWidth ) / 2
        ::nTop  := (::oParent:nHeight - ::nHeight) / 2
      ENDIF
   ENDIF

   hwg_Setwindowpos( ::Handle, HWND_TOP, ::nLeft, ::nTop, 0, 0,;
                  SWP_NOSIZE + SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
   IF ( bActivate  != NIL )
      Eval( bActivate, Self )
   ENDIF

   hwg_Setfocus( ::handle )

   ::nInitFocus := IIF(VALTYPE( ::nInitFocus ) = "O", ::nInitFocus:Handle, ::nInitFocus )
   ::nInitFocus := IIF( Empty( ::nInitFocus ), FindInitFocus( ::aControls ), ::nInitFocus )
   IF ! Empty( ::nInitFocus )
     hwg_Setfocus( ::nInitFocus )
     ::nFocus := hwg_Getfocus()
   ENDIF

   
   RETURN Nil


METHOD onEvent( msg, wParam, lParam )  CLASS HChildWindow
   LOCAL i, oCtrl

   IF msg = WM_PAINT
      RETURN ::Paint( self )

   ELSEIF msg == WM_DESTROY
      RETURN hwg_onDestroy( Self )
   ELSEIF msg == WM_SIZE
      RETURN onSize( Self, wParam, lParam )
   ELSEIF msg = WM_SETFOCUS .AND. !Empty( ::nFocus )
      hwg_Setfocus( ::nFocus )
   ELSEIF ( i := AScan( HMainWindow():aMessages[ 1 ], msg ) ) != 0
      RETURN Eval( HMainWindow():aMessages[ 2, i ], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ELSEIF msg = WM_NOTIFY .AND. !::lSuspendMsgsHandling
         IF ( oCtrl := ::FindControl( wParam ) ) != Nil .AND. oCtrl:className != "HTAB"
            ::nFocus := oCtrl:handle
            hwg_Sendmessage( oCtrl:handle, msg, wParam, lParam )
         ENDIF
      ENDIF
      RETURN ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1

FUNCTION hwg_ReleaseAllWindows( hWnd )

   LOCAL oItem

   FOR EACH oItem IN HWindow():aWindows
      IF oItem:oParent != Nil .AND. hwg_Ptrtoulong( oItem:oParent:handle ) == hwg_Ptrtoulong( hWnd )
         hwg_Sendmessage( oItem:handle, WM_CLOSE, 0, 0 )
      ENDIF
   NEXT
   IF hwg_Ptrtoulong( HWindow():aWindows[ 1 ]:handle ) == hwg_Ptrtoulong( hWnd )
      hwg_Postquitmessage( 0 )
   ENDIF

   RETURN - 1

   #define  FLAG_CHECK      2

STATIC FUNCTION onCommand( oWnd, wParam, lParam )
   LOCAL iItem, iCont, aMenu, iParHigh, iParLow, nHandle, oChild, i

   HB_SYMBOL_UNUSED( lParam )

   IF wParam >= FIRST_MDICHILD_ID .AND. wparam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS .AND. ! Empty( oWnd:Screen )
      IF wParam >= FIRST_MDICHILD_ID
         hwg_Setwindowpos( ownd:Screen:HANDLE, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE )
      ENDIF
      *-wParam += IIF( hwg_Iswindowenabled( oWnd:Screen:handle ), 0, 1 )
   ENDIF
   IF wParam == SC_CLOSE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
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
         hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIDESTROY, nHandle, 0 )
      ENDIF
   ELSEIF wParam == SC_RESTORE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIRESTORE, nHandle, 0 )
      ENDIF
   ELSEIF wParam == SC_MAXIMIZE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIGETACTIVE, 0, 0 ) ) > 0
         hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIMAXIMIZE, nHandle, 0 )
      ENDIF
   ELSEIF wParam > FIRST_MDICHILD_ID .AND. wParam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS
      IF oWnd:bMdiMenu != Nil
         Eval( oWnd:bMdiMenu, HWindow():aWindows[ wParam - FIRST_MDICHILD_ID + 2 ], wParam  )
      ENDIF
      nHandle := HWindow():aWindows[ wParam - FIRST_MDICHILD_ID + 2 ]:handle
      hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIACTIVATE, nHandle, 0 )
   ENDIF
   iParHigh := hwg_Hiword( wParam )
   iParLow := hwg_Loword( wParam )
   IF oWnd:aEvents != Nil .AND. !oWnd:lSuspendMsgsHandling  .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ELSEIF ValType( oWnd:menu ) == "A" .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:menu, iParLow, @iCont ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1, iCont, 4 ], FLAG_CHECK ) > 0
         hwg_Checkmenuitem( , aMenu[ 1, iCont, 3 ], ! hwg_Ischeckedmenuitem( , aMenu[ 1, iCont, 3 ] ) )
      ENDIF
      IF aMenu[ 1, iCont, 1 ] != Nil   // event from MENU
         oWnd:nFocus := 0
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
      RETURN IIF( ! Empty( oWnd:Screen ) , -1 , 0 )
   ENDIF

   RETURN 0

FUNCTION hwg_onMove( oWnd )

   LOCAL aControls := hwg_Getwindowrect( oWnd:handle )

   oWnd:nLeft := aControls[ 1 ]
   oWnd:nTop  := aControls[ 2 ]
   IF oWnd:type == WND_MDICHILD  .AND. ! oWnd:lMaximized
      //oWnd:aRectSave := { oWnd:nLeft, oWnd:nTop, oWnd:nWidth, oWnd:nHeight }
      IF oWnd:nHeight > hwg_Getsystemmetrics( SM_CYCAPTION ) + 6
          oWnd:aRectSave := { oWnd:nLeft, oWnd:nTop, oWnd:nWidth, oWnd:nHeight }
      ELSE
        oWnd:aRectSave[ 1 ] := oWnd:nLeft
        oWnd:aRectSave[ 2 ] := oWnd:nTop
      ENDIF
   ENDIF
   IF oWnd:isMinimized() .AND. !Empty( oWnd:Screen )
      hwg_Setwindowpos( oWnd:Screen:HANDLE, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
   ENDIF
   RETURN - 1

STATIC FUNCTION onEraseBk( oWnd, wParam )
   LOCAL oWndArea

   IF oWnd:oBmp != Nil .AND. oWnd:type != WND_MDI
       oWndArea := IIF( oWnd:type != WND_MAIN, oWnd:oClient, oWnd )
       IF oWnd:bmpStretch = 2 .OR. oWnd:lBmpCenter
          hwg_Centerbitmap( wParam, oWndArea:handle, oWnd:oBmp:handle, , IIF( oWnd:brush = Nil, oWnd:nBmpClr, oWnd:brush:handle ) )
       ELSEIF oWnd:bmpStretch = 1
          hwg_Spreadbitmap( wParam, oWndArea:handle, oWnd:oBmp:handle )
       ELSEIF oWnd:bmpStretch = 0
          hwg_Drawbitmap( wParam, oWnd:oBmp:handle, , 0, 0, oWndArea:nwidth, oWndArea:nheight )
       ENDIF
       Return 1
   ELSEIF oWnd:type != WND_MDI //.AND. oWnd:type != WND_MAIN
      RETURN 0
   ELSEIF oWnd:type = WND_MDI .AND. hwg_Iswindowvisible( oWnd:handle )
      // MINOR flicker in MAIND in resize window
      RETURN 0
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
         hwg_Shellnotifyicon( .F., oWnd:handle, oWnd:oNotifyIcon:handle )
      ENDIF
      IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
         hwg_Destroyacceleratortable( oWnd:hAccel )
      ENDIF
      RETURN - 1
   ENDIF

   oWnd:WindowState := hwg_Getwindowplacement( oWnd:handle )
   IF wParam == SC_MINIMIZE
      IF __ObjHasMsg( oWnd, "LTRAY" ) .AND. oWnd:lTray
         oWnd:Hide()
         RETURN 0
      ENDIF
      hwg_Setwindowpos( oWnd:Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
                                                         SWP_NOOWNERZORDER + SWP_FRAMECHANGED)

   ELSEIF ( wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2 ) .AND. ;
      oWnd:type == WND_MDICHILD .AND. ( oWnd:lChild .OR. oWnd:lModal )
      IF oWnd:WindowState == SW_SHOWMINIMIZED
          hwg_Sendmessage( oWnd:HANDLE, WM_SYSCOMMAND, SC_RESTORE, 0 )
          hwg_Sendmessage( oWnd:HANDLE, WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
          RETURN 0
      ENDIF
      ars := aClone( oWnd:aRectSave )
      IF oWnd:lMaximized
          // restore
          IF oWnd:lSizeBox
             HWG_SETWINDOWSTYLE( oWnd:handle ,HWG_GETWINDOWSTYLE( oWnd:handle ) + WS_SIZEBOX )
         ENDIF
         hwg_Movewindow(oWnd:Handle, oWnd:aRectSave[ 1 ], oWnd:aRectSave[ 2 ], oWnd:aRectSave[ 3 ], oWnd:aRectSave[ 4 ] )
         hwg_Movewindow(oWnd:Handle, oWnd:aRectSave[ 1 ] - ( oWnd:nLeft - oWnd:aRectSave[ 1 ] ), ;
                                  oWnd:aRectSave[ 2 ] - ( oWnd:nTop - oWnd:aRectSave[ 2 ] ), ;
                                  oWnd:aRectSave[ 3 ], oWnd:aRectSave[ 4 ] )
      ELSE
          // maximized
        IF oWnd:lSizeBox
           HWG_SETWINDOWSTYLE( oWnd:handle ,HWG_GETWINDOWSTYLE( oWnd:handle ) - WS_SIZEBOX )
        ENDIF
         hwg_Movewindow( oWnd:handle, oWnd:oClient:nLeft, oWnd:oClient:nTop, oWnd:oClient:nWidth, oWnd:oClient:nHeight )
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
         IF ( oCtrl := hwg_FindAccelerator( oChild, lParam ) ) != Nil
            oCtrl:Setfocus()
            hwg_Sendmessage( oCtrl:handle, WM_SYSKEYUP, lParam, 0 )
            RETURN - 2
           /*  MNC_IGNORE = 0  MNC_CLOSE = 1  MNC_EXECUTE = 2  MNC_SELECT = 3 */
         ENDIF
      ENDIF
   ELSEIF wParam = SC_HOTKEY
   //ELSEIF wParam = SC_MOUSEMENU  //0xF090
   ELSEIF wParam = SC_MENU .AND. ( oWnd:type == WND_MDICHILD .OR. ! Empty( oWnd := oWnd:GetMdiActive())) .AND. oWnd:lModal
      hwg_Msgbeep()
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
      IF hwg_Ptrtoulong(lParam) == WM_LBUTTONDOWN
         IF ISBLOCK( oWnd:bNotify )
            Eval( oWnd:bNotify )
         ENDIF
      ELSEIF hwg_Ptrtoulong(lParam) == WM_MOUSEMOVE
      ELSEIF hwg_Ptrtoulong(lParam) == WM_RBUTTONDOWN
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
   IF oWnd:oFont != Nil
      hwg_Sendmessage( oWnd:handle, WM_SETFONT, oWnd:oFont:handle, 0 )
   ENDIF
   hwg_InitControls( oWnd )
   hwg_InitObjects( oWnd, .T. )
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
   hwg_Sendmessage( oWnd:handle, WM_UPDATEUISTATE, hwg_Makelong( UIS_CLEAR, UISF_HIDEFOCUS ), 0 )
   hwg_Sendmessage( oWnd:handle, WM_UPDATEUISTATE, hwg_Makelong( UIS_CLEAR, UISF_HIDEACCEL ), 0 )
   IF oWnd:WindowState > 0
      hwg_onMove( oWnd )
   ENDIF
   RETURN - 1

STATIC FUNCTION onMdiCommand( oWnd, wParam )
   LOCAL iParHigh, iParLow, iItem, aMenu, oCtrl

   IF wParam == SC_CLOSE
      hwg_Sendmessage( HWindow():aWindows[ 2 ]:handle, WM_MDIDESTROY, oWnd:handle, 0 )
   ENDIF
   iParHigh := hwg_Hiword( wParam )
   iParLow := hwg_Loword( wParam )
   IF hwg_Iswindowvisible( oWnd:Handle )
      oCtrl := oWnd:FindControl( iParLow )
   ENDIF
   IF oWnd:aEvents != Nil .AND. !oWnd:lSuspendMsgsHandling  .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      IF hwg_Ptrtoulong( hwg_Getparent( hwg_Getfocus() ) ) = hwg_Ptrtoulong( oWnd:Handle )
         oWnd:nFocus := hwg_Getfocus()
      ENDIF
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ELSEIF __ObjHasMsg( oWnd ,"OPOPUP") .AND. oWnd:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iItem ) ) != Nil ;
         .AND. aMenu[ 1, iItem, 1 ] != Nil
          Eval( aMenu[ 1, iItem, 1 ],  wParam )
   ELSEIF iParHigh = 1  // acelerator

   ENDIF
   IF  oCtrl != Nil .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( oCtrl:handle ), WS_TABSTOP ) != 0 .AND.;
      hwg_Getfocus() == oCtrl:Handle
      oWnd:nFocus := oCtrl:handle
   ENDIF
   RETURN 0

STATIC FUNCTION onMdiNcActivate( oWnd, wParam )

   IF ! Empty( oWnd:Screen )
      IF wParam = 1 .AND. hwg_Selffocus( oWnd:Screen:handle, oWnd:handle )
         hwg_Setwindowpos( oWnd:Screen:HANDLE, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
         RETURN 1
      ENDIF
      IF wParam == 1 .AND. ! hwg_Selffocus( oWnd:Screen:Handle, oWnd:HANDLE )
         // triggered ON GETFOCUS MDI CHILD MAXIMIZED
         IF ISBLOCK( oWnd:bSetForm )
            EVAL( oWnd:bSetForm, oWnd )
         ENDIF
         IF  ! oWnd:lSuspendMsgsHandling .AND.;
            oWnd:bGetFocus != Nil .AND. ! Empty( hwg_Getfocus() ) .AND. oWnd:IsMaximized()
            oWnd:lSuspendMsgsHandling := .T.
            Eval( oWnd:bGetFocus, oWnd )
            oWnd:lSuspendMsgsHandling := .F.
          ENDIF
      ENDIF
   ENDIF
   RETURN - 1

Static Function onMdiActivate( oWnd,wParam, lParam )
   Local  lScreen := oWnd:Screen != nil, aWndMain ,oWndDeact
   Local lConf

   If ValType( wParam ) == ValType( oWnd:Handle )
      lConf := wParam = oWnd:Handle
   Else
      lConf := .F.
   EndIf
   // added

   IF !Empty( wParam )
      oWndDeact := oWnd:FindWindow( wParam )
      IF oWnd:lChild .AND. oWnd:lmaximized .AND. oWnd:IsMaximized()
         oWnd:Restore()
      ENDIF
      IF oWndDeact != Nil .AND. oWndDeact:lModal
         AADD( oWndDeact:aChilds, lParam )
         AADD( oWnd:aChilds, wParam )
         oWnd:lModal := .T.
      ELSEIF  oWndDeact != Nil .AND. ! oWndDeact:lModal
         oWnd:hActive := wParam
      ENDIF
   ENDIF

   IF  lScreen .AND. ( Empty( lParam ) .OR. ;
       hwg_Selffocus( lParam, oWnd:Screen:Handle ) ) .AND. !lConf //wParam != oWnd:Handle
      RETURN 0
   ELSEIF lConf //oWnd:Handle = wParam
      IF  ! hwg_Selffocus( oWnd:Screen:handle, wParam ) .AND. oWnd:bLostFocus != Nil //.AND.wParam == 0
         oWnd:lSuspendMsgsHandling := .t.
         Eval( oWnd:bLostFocus, oWnd )
         oWnd:lSuspendMsgsHandling := .f.
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEVAL( aWndMain,{| w | IIF( w:Type >= WND_MDICHILD .AND.;
             hwg_Ptrtoulong( w:Handle ) != hwg_Ptrtoulong( wParam ), hwg_Enablewindow( w:Handle, .T. ), ) })
      ENDIF
   ELSEIF hwg_Selffocus( oWnd:Handle, lParam ) //.AND. ownd:screen:handle != WPARAM
      IF ISBLOCK( oWnd:bSetForm )
         EVAL( oWnd:bSetForm, oWnd )
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEVAL( aWndMain,{| w | IIF( w:Type >= WND_MDICHILD .AND.;
             hwg_Ptrtoulong( w:Handle ) != hwg_Ptrtoulong( lParam ), hwg_Enablewindow( w:Handle, .F. ), ) })
         AEVAL( oWnd:aChilds,{| wH | hwg_Enablewindow( wH, .T. ) })
     ENDIF
      IF oWnd:bGetFocus != Nil .AND. ! oWnd:lSuspendMsgsHandling .AND. ! oWnd:IsMaximized()
         oWnd:lSuspendMsgsHandling := .t.
         IF EMPTY( oWnd:nFocus )
             hwg_Updatewindow( oWnd:Handle)
         ENDIF
         Eval( oWnd:bGetFocus, oWnd )
         oWnd:lSuspendMsgsHandling := .f.
      ENDIF
   ENDIF

   RETURN 0

STATIC FUNCTION onEnterIdle( oDlg, wParam, lParam )
   LOCAL oItem
   IF ( wParam == 0 .AND. ( oItem := Atail( HDialog():aModalDialogs ) ) != Nil ;
         .AND. oItem:handle == lParam )
      oDlg := oItem
   ENDIF
   IF __ObjHasMsg( oDlg, "LACTIVATED" )
      IF  !oDlg:lActivated
         oDlg:lActivated := .T.
         IF oDlg:bActivate != Nil
            Eval( oDlg:bActivate, oDlg )
         ENDIF
      ENDIF
   ENDIF
   RETURN 0

//add by sauli
STATIC FUNCTION onCloseQuery( o )
   IF ValType( o:bCloseQuery ) = 'B'
      IF Eval( o:bCloseQuery )
         hwg_ReleaseAllWindows( o:handle )
      END
   ELSE
      hwg_ReleaseAllWindows( o:handle )
   END

   RETURN - 1
// end sauli

STATIC FUNCTION onActivate( oWin, wParam, lParam )
   LOCAL iParLow := hwg_Loword( wParam ), iParHigh := hwg_Hiword( wParam )

   HB_SYMBOL_UNUSED( lParam )

   IF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE ) .AND. hwg_Iswindowvisible( oWin:handle )
      IF  ( oWin:type = WND_MDICHILD .AND. hwg_Ptrtoulong( lParam ) = 0  ) .OR.;
          ( oWin:type != WND_MDICHILD .AND. iParHigh = 0 )
         IF oWin:bGetFocus != Nil //.AND. hwg_Iswindowvisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            IF iParHigh > 0  // MINIMIZED
               *oWin:restore()
            ENDIF
            Eval( oWin:bGetFocus, oWin, lParam )
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF
   ELSEIF iParLow = WA_INACTIVE
      IF  ( oWin:type = WND_MDICHILD .AND. hwg_Ptrtoulong( lParam ) != 0 ).OR.;
          ( oWin:type != WND_MDICHILD .AND. iParHigh = 0 .AND. hwg_Ptrtoulong( lParam ) = 0 )
         IF  oWin:bLostFocus != Nil //.AND. hwg_Iswindowvisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            Eval( oWin:bLostFocus, oWin, lParam )
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF
   ENDIF
   RETURN 1

STATIC FUNCTION FindInitFocus( aControls )
   LOCAL i := 1 , nObjs := Len( aControls )

   DO WHILE i <= nObjs
      IF Hwg_BitaND( HWG_GETWINDOWSTYLE( aControls[ i ]:handle ), WS_TABSTOP ) != 0 .AND. ;
			        Hwg_BitaND( HWG_GETWINDOWSTYLE( aControls[ i ]:handle ), WS_DISABLED ) = 0 .AND. ! aControls[ i ]:lHide
         RETURN aControls[ i ]:Handle
      ENDIF
      IF Len( aControls[ i ]:aControls ) > 0 .AND. ! aControls[ i ]:lHide .AND.  ;
         Hwg_BitaND( HWG_GETWINDOWSTYLE( aControls[ i ]:handle ), WS_DISABLED ) = 0
         RETURN FindInitFocus( aControls[ i ]:aControls )
      ENDIF
      i ++
   ENDDO
   RETURN 0

