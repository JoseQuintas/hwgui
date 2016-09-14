/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HWindow class
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hbclass.ch"
#include "hwgui.ch"

REQUEST HWG_ENDWINDOW

#define  FIRST_MDICHILD_ID     501
#define  MAX_MDICHILD_WINDOWS   18
#define  WM_NOTIFYICON         WM_USER+1000
#define  ID_NOTIFYICON           1

Function hwg_onWndSize( oWnd,wParam,lParam )

   // hwg_WriteLog( "OnSize: "+Str(oWnd:nWidth)+" "+Str(oWnd:nHeight)+" "+Str(hwg_Loword(lParam))+" "+Str(hwg_Hiword(lParam)) )

   IF wParam != 1
      onAnchor( oWnd, oWnd:nWidth, oWnd:nHeight, hwg_Loword(lParam), hwg_Hiword(lParam) )
   ENDIF
   oWnd:Super:onEvent( WM_SIZE,wParam,lParam )

   IF wParam != 1
      oWnd:nWidth  := hwg_Loword(lParam)
      oWnd:nHeight := hwg_Hiword(lParam)
   ENDIF

   IF HB_ISBLOCK( oWnd:bSize )
       Eval( oWnd:bSize, oWnd, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
   ENDIF

Return 0

Function hwg_onMove( oWnd, wParam, lParam )

   // hwg_WriteLog( "onMove: "+str(oWnd:nLeft)+" "+str(oWnd:nTop)+" -> "+str(hwg_Loword(lParam))+str(hwg_Hiword(lParam)) )
   oWnd:nLeft := hwg_Loword(lParam)
   oWnd:nTop  := hwg_Hiword(lParam)

Return 0

STATIC FUNCTION onAnchor( oWnd, wold, hold, wnew, hnew )
LOCAL aControls := oWnd:aControls, oItem, w, h

   FOR EACH oItem IN aControls
      IF oItem:Anchor > 0
         w := oItem:nWidth
         h := oItem:nHeight
         oItem:onAnchor( wold, hold, wnew, hnew )
         onAnchor( oItem, w, h, oItem:nWidth, oItem:nHeight )
      ENDIF
   NEXT
   RETURN Nil

Static Function onDestroy( oWnd )

   LOCAL i
   IF oWnd:bDestroy != Nil
      Eval( oWnd:bDestroy, oWnd )
      oWnd:bDestroy := Nil
   ENDIF
   IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
      hwg_Destroyacceleratortable( oWnd:hAccel )
   ENDIF

   IF ( i := Ascan( HTimer():aTimers,{|o|hwg_Isptreq( o:oParent:handle,oWnd:handle )} ) ) != 0
      HTimer():aTimers[i]:End()
   ENDIF

   oWnd:Super:onEvent( WM_DESTROY )
   HWindow():DelItem( oWnd )
   hwg_gtk_exit()  

Return 0

CLASS HWindow INHERIT HCustomWindow

   CLASS VAR aWindows   SHARED INIT {}
   CLASS VAR szAppName  SHARED INIT "HwGUI_App"
   CLASS VAR aKeysGlobal SHARED INIT {}

   DATA fbox
   DATA menu, oPopup, hAccel
   DATA oIcon, oBmp
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lClipper INIT .F.
   DATA GetList  INIT {}      // The array of GET items in the dialog
   DATA KeyList  INIT {}      // The array of keys ( as Clipper's SET KEY )
   DATA nLastKey INIT 0
   DATA bActivate
   DATA lActivated  INIT .F.
   DATA tColorinFocus  INIT -1
   DATA bColorinFocus  INIT -1

   DATA aOffset

   METHOD New( Icon,clr,nStyle,x,y,width,height,cTitle,cMenu,oFont, ;
          bInit,bExit,bSize,bPaint,bGfocus,bLfocus,bOther,cAppName,oBmp,cHelp,nHelpId )
   METHOD AddItem( oWnd )
   METHOD DelItem( oWnd )
   METHOD FindWindow( hWnd )
   METHOD GetMain()
   METHOD EvalKeyList( nKey )
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle )
   METHOD Restore()  INLINE hwg_RestoreWindow( ::handle )
   METHOD Maximize() INLINE hwg_WindowMaximize( ::handle )
   METHOD Minimize() INLINE hwg_WindowMinimize( ::handle )
   METHOD Close()    INLINE hwg_DestroyWindow( ::handle )
   METHOD SetTitle( cTitle ) INLINE hwg_Setwindowtext( ::handle, ::title := cTitle )
ENDCLASS

METHOD New( oIcon,clr,nStyle,x,y,width,height,cTitle,cMenu,oFont, ;
                  bInit,bExit,bSize,bPaint,bGfocus,bLfocus,bOther,;
                  cAppName,oBmp,cHelp,nHelpId ) CLASS HWindow

   ::oDefaultParent := Self
   ::title    := cTitle
   ::style    := Iif( nStyle==Nil,0,nStyle )
   ::oIcon    := oIcon
   ::oBmp     := oBmp
   ::nTop     := Iif( y==Nil,0,y )
   ::nLeft    := Iif( x==Nil,0,x )
   ::nWidth   := Iif( width==Nil,0,width )
   ::nHeight  := Iif( height==Nil,0,height )
   ::oFont    := oFont
   ::bInit    := bInit
   ::bDestroy := bExit
   ::bSize    := bSize
   ::bPaint   := bPaint
   ::bGetFocus  := bGFocus
   ::bLostFocus := bLFocus
   ::bOther     := bOther
   IF cAppName != Nil
      ::szAppName := cAppName
   ENDIF
   
   IF hwg_BitAnd( ::style, DS_CENTER ) > 0 
      ::nLeft := Int( ( hwg_Getdesktopwidth() - ::nWidth ) / 2 )
      ::nTop  := Int( ( hwg_Getdesktopheight() - ::nHeight ) / 2 )
   ENDIF 
   
   IF nHelpId != nil
      ::HelpId := nHelpId
   END
   
   ::aOffset := Array( 4 )
   Afill( ::aOffset,0 )

   ::AddItem( Self )

RETURN Self

METHOD AddItem( oWnd ) CLASS HWindow
   Aadd( ::aWindows, oWnd )
RETURN Nil

METHOD DelItem( oWnd ) CLASS HWindow
Local i
   IF ( i := Ascan( ::aWindows,{|o|o==oWnd} ) ) > 0
      Adel( ::aWindows,i )
      Asize( ::aWindows, Len(::aWindows)-1 )
   ENDIF
RETURN Nil

METHOD FindWindow( hWnd ) CLASS HWindow
// Local i := Ascan( ::aWindows, {|o|o:handle==hWnd} )
// Return Iif( i == 0, Nil, ::aWindows[i] )
Return hwg_Getwindowobject(hWnd)

METHOD GetMain CLASS HWindow
Return Iif(Len(::aWindows)>0,            ;
	 Iif(::aWindows[1]:type==WND_MAIN, ;
	   ::aWindows[1],                  ;
	   Iif(Len(::aWindows)>1,::aWindows[2],Nil)), Nil )

METHOD EvalKeyList( nKey, nctrl ) CLASS HWindow
   LOCAL nPos

   nctrl := Iif( nctrl==2, FCONTROL, Iif( nctrl==1, FSHIFT, Iif( nctrl==4,FALT,0 ) ) )

   //hwg_writelog( str(nKey)+"/"+str(nctrl) )
   IF !Empty( ::KeyList )
      IF ( nPos := Ascan( ::KeyList,{ |a|a[1] == nctrl .AND. a[2] == nKey } ) ) > 0
         Eval( ::KeyList[ nPos,3 ], ::FindControl( ,hwg_Getfocus() ) )
      ENDIF
   ENDIF
   IF !Empty( ::aKeysGlobal )
      IF ( nPos := Ascan( ::aKeysGlobal,{ |a|a[1] == nctrl .AND. a[2] == nKey } ) ) > 0
         Eval( ::aKeysGlobal[ nPos,3 ], ::FindControl( ,hwg_Getfocus() ) )
      ENDIF
   ENDIF

   RETURN .T.


CLASS HMainWindow INHERIT HWindow

   CLASS VAR aMessages INIT { ;
      { WM_COMMAND,WM_SETFOCUS,WM_MOVE,WM_SIZE,WM_CLOSE,WM_DESTROY }, ;
      { ;
         {|o,w,l|onCommand(o,w,l)},        ;
         {|o,w,l|onGetFocus(o,w,l)},       ;
         {|o,w,l|hwg_onMove(o,w,l)},       ;
         {|o,w,l|hwg_onWndSize(o,w,l)},    ;
         {|o|hwg_ReleaseAllWindows(o:handle)}, ;
         {|o|onDestroy(o)}                 ;
      } ;
   }
   DATA   nMenuPos
   DATA oNotifyIcon, bNotify, oNotifyMenu
   DATA lTray       INIT .F.

   METHOD New( lType,oIcon,clr,nStyle,x,y,width,height,cTitle,cMenu,nPos,   ;
                     oFont,bInit,bExit,bSize,bPaint,bGfocus,bLfocus,bOther, ;
                     cAppName,oBmp,cHelp,nHelpId )
   METHOD Activate( lShow )
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( lType,oIcon,clr,nStyle,x,y,width,height,cTitle,cMenu,nPos,   ;
                     oFont,bInit,bExit,bSize,bPaint,bGfocus,bLfocus,bOther, ;
                     cAppName,oBmp,cHelp,nHelpId ) CLASS HMainWindow

   ::Super:New( oIcon,clr,nStyle,x,y,width,height,cTitle,cMenu,oFont, ;
                  bInit,bExit,bSize,bPaint,bGfocus,bLfocus,bOther,  ;
                  cAppName,oBmp,cHelp,nHelpId )
   ::type := lType

   IF lType == WND_MDI
   ELSEIF lType == WND_MAIN

      ::handle := Hwg_InitMainWindow( Self, ::szAppName,cTitle,cMenu, ;
              Iif(oIcon!=Nil,oIcon:handle,Nil),Iif(oBmp!=Nil,-1,clr),::Style,::nLeft, ;
              ::nTop,::nWidth,::nHeight )
    
   ENDIF
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF

Return Self

METHOD Activate( lShow, lMaximize, lMinimize, lCentered, bActivate ) CLASS HMainWindow
Local oWndClient, handle

   IF ::type == WND_MAIN

      ::lActivated := .T.
      IF HB_ISBLOCK( bActivate )
         ::bActivate := bActivate
      ENDIF
      IF ::bActivate != Nil
         Eval( ::bActivate, Self )
      ENDIF

      IF !Empty( lCentered )
         ::Center()
      ENDIF
      Hwg_ActivateMainWindow( ::handle,::hAccel, lMaximize, lMinimize )

   ENDIF

Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HMainWindow
Local i

   // hwg_WriteLog( "On Event" + str(msg) + str(wParam) + str( lParam ) )
   IF ( i := Ascan( ::aMessages[1],msg ) ) != 0
      Return Eval( ::aMessages[2,i], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL
         // hwg_onTrackScroll( Self,wParam,lParam )
      ENDIF
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

Return 0

Function hwg_ReleaseAllWindows( hWnd )

Local oItem, iCont, nCont
return -1

Static Function onCommand( oWnd,wParam,lParam )
Local iItem, iCont, aMenu, iParHigh, iParLow, nHandle

   iParHigh := hwg_Hiword( wParam )
   iParLow := hwg_Loword( wParam )
   IF oWnd:aEvents != Nil .AND. ;
        ( iItem := Ascan( oWnd:aEvents, {|a|a[1]==iParHigh.and.a[2]==iParLow} ) ) > 0
        Eval( oWnd:aEvents[ iItem,3 ],oWnd,iParLow )
   ELSEIF Valtype( oWnd:menu ) == "A" .AND. ;
        ( aMenu := Hwg_FindMenuItem( oWnd:menu,iParLow,@iCont ) ) != Nil ;
        .AND. aMenu[ 1,iCont,1 ] != Nil
      Eval( aMenu[ 1,iCont,1 ] )
   ELSEIF oWnd:oPopup != Nil .AND. ;
        ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu,wParam,@iCont ) ) != Nil ;
        .AND. aMenu[ 1,iCont,1 ] != Nil
      Eval( aMenu[ 1,iCont,1 ] )
   ELSEIF oWnd:oNotifyMenu != Nil .AND. ;
        ( aMenu := Hwg_FindMenuItem( oWnd:oNotifyMenu:aMenu,wParam,@iCont ) ) != Nil ;
        .AND. aMenu[ 1,iCont,1 ] != Nil
      Eval( aMenu[ 1,iCont,1 ] )
   ENDIF

Return 0

STATIC FUNCTION onGetFocus( oDlg, w, l )

   IF oDlg:bGetFocus != Nil
      Eval( oDlg:bGetFocus, oDlg )
   ENDIF

   RETURN 0
