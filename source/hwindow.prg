/*
 *$Id: hwindow.prg,v 1.2 2003-11-14 07:44:12 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Window class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "windows.ch"
#include "HBClass.ch"
#include "guilib.ch"

#define  FIRST_MDICHILD_ID     501
#define  MAX_MDICHILD_WINDOWS   18
#define  WM_NOTIFYICON         WM_USER+1000
#define  ID_NOTIFYICON           1

CLASS HObject
   // DATA classname
ENDCLASS

CLASS HCustomWindow INHERIT HObject

   CLASS VAR oDefaultParent SHARED
   DATA handle  INIT 0
   DATA oParent
   DATA title
   DATA type
   DATA nTop, nLeft, nWidth, nHeight
   DATA tcolor, bcolor, brush
   DATA style
   DATA extStyle  INIT 0
   DATA lHide INIT .F.
   DATA oFont
   DATA aEvents   INIT {}
   DATA aNotify   INIT {}
   DATA aControls INIT {}
   DATA bInit
   DATA bDestroy
   DATA bSize
   DATA bPaint
   DATA bGetFocus
   DATA bLostFocus
   DATA bOther
   DATA cargo

   METHOD AddControl( oCtrl ) INLINE Aadd( ::aControls,oCtrl )
   METHOD DelControl( oCtrl )
   METHOD AddEvent( nEvent,nId,bAction,lNotify ) ;
      INLINE Aadd( Iif( lNotify==Nil.OR.!lNotify,::aEvents,::aNotify ),{nEvent,nId,bAction} )
   METHOD FindControl( nId,nHandle )
   METHOD Hide() INLINE (::lHide:=.T.,HideWindow(::handle))
   METHOD Show() INLINE (::lHide:=.F.,ShowWindow(::handle))

ENDCLASS

METHOD FindControl( nId,nHandle ) CLASS HCustomWindow
Local i := Iif( nId!=Nil,Ascan( ::aControls,{|o|o:id==nId} ), ;
                       Ascan( ::aControls,{|o|o:handle==nHandle} ) )
Return Iif( i==0,Nil,::aControls[i] )

METHOD DelControl( oCtrl ) CLASS HCustomWindow
Local h := oCtrl:handle
Local i := Ascan( ::aControls,{|o|o:handle==h} )

   SendMessage( h,WM_CLOSE,0,0 )
   IF i != 0
      Adel( ::aControls,i )
      Asize( ::aControls,Len(::aControls)-1 )
   ENDIF
Return Nil

CLASS HWindow INHERIT HCustomWindow

   CLASS VAR aWindows   INIT {}
   CLASS VAR szAppName  SHARED INIT "HwGUI_App"

   DATA menu, nMenuPos, oPopup, hAccel
   DATA oIcon, oBmp
   DATA oNotifyIcon, bNotify, oNotifyMenu
   DATA lClipper
   DATA lTray INIT .F.
   DATA aOffset

   METHOD New( lType,oIcon,clr,nStyle,x,y,width,height,cTitle,cMenu,nPos,oFont, ;
          bInit,bExit,bSize,bPaint,bGfocus,bLfocus,bOther,cAppName,oBmp )
   METHOD Activate( lShow )
   METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu )
   METHOD AddItem( oWnd )
   METHOD DelItem( oWnd )
   METHOD FindWindow( hWnd )
   METHOD GetMain()
   METHOD GetMdiActive()
ENDCLASS

METHOD NEW( lType,oIcon,clr,nStyle,x,y,width,height,cTitle,cMenu,nPos,oFont, ;
                  bInit,bExit,bSize, ;
                  bPaint,bGfocus,bLfocus,bOther,cAppName,oBmp ) CLASS HWindow

   // ::classname:= "HWINDOW"
   ::oDefaultParent := Self
   ::type     := lType
   ::title    := cTitle
   ::style    := Iif( nStyle==Nil,0,nStyle )
   ::nMenuPos := nPos
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
   // ::lClipper   := Iif( lClipper==Nil,.F.,lClipper )
   ::aOffset := Array( 4 )
   Afill( ::aOffset,0 )

   ::AddItem( Self )
   IF lType == WND_MAIN

      ::handle := Hwg_InitMainWindow( ::szAppName,cTitle,cMenu,    ;
              Iif(oIcon!=Nil,oIcon:handle,Nil),Iif(oBmp!=Nil,-1,clr),nStyle,::nLeft, ;
              ::nTop,::nWidth,::nHeight )

   ELSEIF lType == WND_MDI

      Hwg_InitMdiWindow( ::szAppName,cTitle,cMenu,  ;
              Iif(oIcon!=Nil,oIcon:handle,Nil),clr, ;
              nStyle,::nLeft,::nTop,::nWidth,::nHeight )
      ::handle = hwg_GetWindowHandle(1)

   ENDIF

RETURN Self

METHOD Activate( lShow ) CLASS HWindow
Local oWndClient

   IF ::type == WND_CHILD
      Hwg_CreateMdiChildWindow( Self )
   ELSEIF ::type == WND_MDI
      Hwg_InitClientWindow( ::nMenuPos,::nLeft,::nTop+60,::nWidth,::nHeight )
      oWndClient := HWindow():New( 0,,,::style,::title,,::nMenuPos,::bInit,::bDestroy,::bSize, ;
                              ::bPaint,::bGetFocus,::bLostFocus,::bOther )
      oWndClient:handle = hwg_GetWindowHandle(2)
      // oWndClient:aControls := ::aControls
      // InitControls( Self )
      Hwg_ActivateMdiWindow( ( lShow==Nil .OR. lShow ),::hAccel )
   ELSEIF ::type == WND_MAIN
      Hwg_ActivateMainWindow( ( lShow==Nil .OR. lShow ),::hAccel )
   ENDIF

RETURN Nil

METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip ) CLASS HWindow

   ::bNotify     := bNotify
   ::oNotifyMenu := oNotifyMenu
   ::oNotifyIcon := oNotifyIcon
   ShellNotifyIcon( .T., ::handle, oNotifyIcon:handle, cTooltip )
   ::lTray := .T.

RETURN Nil

METHOD AddItem( oWnd ) CLASS HWindow
   Aadd( ::aWindows, oWnd )
RETURN Nil

METHOD DelItem( oWnd ) CLASS HWindow
Local i, h := oWnd:handle
   IF ( i := Ascan( ::aWindows,{|o|o:handle==h} ) ) > 0
      Adel( ::aWindows,i )
      Asize( ::aWindows, Len(::aWindows)-1 )
   ENDIF
RETURN Nil

METHOD FindWindow( hWnd ) CLASS HWindow
Local i := Ascan( ::aWindows, {|o|o:handle==hWnd} )
Return Iif( i == 0, Nil, ::aWindows[i] )

METHOD GetMain CLASS HWindow
Return Iif(Len(::aWindows)>0,              ;
         Iif(::aWindows[1]:type==WND_MAIN, ;
           ::aWindows[1],                  ;
           Iif(Len(::aWindows)>1,::aWindows[2],Nil)), Nil )

METHOD GetMdiActive() CLASS HWindow 
Return ::FindWindow ( SendMessage( ::GetMain():handle, WM_MDIGETACTIVE,0,0 ) )

Function DefWndProc( hWnd, msg, wParam, lParam )
Local i, iItem, nHandle, aControls, nControls, iCont, hWndC, aMenu
Local iParHigh, iParLow
Local oWnd, oBtn, oitem

   // WriteLog( "|Window: "+Str(hWnd,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   if ( oWnd := HWindow():FindWindow(hWnd) ) == Nil
      // MsgStop( "Message: wrong window handle "+Str( hWnd )+"/"+Str( msg ),"Error!" )
      if msg == WM_CREATE
         if Len( HWindow():aWindows ) != 0 .and. ;
             ( oWnd := HWindow():aWindows[ Len(HWindow():aWindows) ] ) != Nil .and. ;
             oWnd:handle == 0
             oWnd:handle := hWnd
             if oWnd:bInit != Nil
                Eval( oWnd:bInit, oWnd )
             endif
         endif
      endif
      Return -1
   endif
   if msg == WM_COMMAND
      // WriteLog( "/Window: "+Str(hWnd,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
      if wParam == SC_CLOSE
         if Len(HWindow():aWindows)>2 .AND. ( nHandle := SendMessage( HWindow():aWindows[2]:handle, WM_MDIGETACTIVE,0,0 ) ) > 0
            SendMessage( HWindow():aWindows[2]:handle, WM_MDIDESTROY, nHandle, 0 )
         endif
      elseif wParam == SC_RESTORE
         if Len(HWindow():aWindows) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[2]:handle, WM_MDIGETACTIVE,0,0 ) ) > 0
            SendMessage( HWindow():aWindows[2]:handle, WM_MDIRESTORE, nHandle, 0 )
         endif
      elseif wParam == SC_MAXIMIZE
         if Len(HWindow():aWindows) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[2]:handle, WM_MDIGETACTIVE,0,0 ) ) > 0
            SendMessage( HWindow():aWindows[2]:handle, WM_MDIMAXIMIZE, nHandle, 0 )
         endif
      elseif wParam >= FIRST_MDICHILD_ID .AND. wparam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS
         nHandle := HWindow():aWindows[wParam - FIRST_MDICHILD_ID + 3]:handle
         SendMessage( HWindow():aWindows[2]:handle, WM_MDIACTIVATE, nHandle, 0 )
      endif
      iParHigh := HiWord( wParam )
      iParLow := LoWord( wParam )
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
      return 0
   elseif msg == WM_PAINT
      if oWnd:bPaint != Nil
         Return Eval( oWnd:bPaint, oWnd )
      endif
   elseif msg == WM_MOVE
      aControls := GetWindowRect( hWnd )
      oWnd:nLeft := aControls[1]
      oWnd:nTop  := aControls[2]
   elseif msg == WM_SIZE
      aControls := oWnd:aControls
      nControls := Len( aControls )
      #ifdef __XHARBOUR__
      FOR each oItem in aControls 
         IF oItem:bSize != Nil
            Eval( oItem:bSize, ;
             oItem, LoWord( lParam ), HiWord( lParam ) )
         ENDIF
      NEXT
      #else
      FOR iCont := 1 TO nControls
         IF aControls[iCont]:bSize != Nil
            Eval( aControls[iCont]:bSize, ;
             aControls[iCont], LoWord( lParam ), HiWord( lParam ) )
         ENDIF
      NEXT
      #endif
      aControls := GetWindowRect( hWnd )
      oWnd:nWidth  := aControls[3]-aControls[1]
      oWnd:nHeight := aControls[4]-aControls[2]
      if oWnd:bSize != Nil
         Eval( oWnd:bSize, oWnd, LoWord( lParam ), HiWord( lParam ) )
      endif
      if oWnd:type == WND_MDI .AND. Len(HWindow():aWindows) > 1
         // writelog( str(hWnd)+"--"+str(aControls[1])+str(aControls[2])+str(aControls[3])+str(aControls[4]) )
         aControls := GetClientRect( hWnd )
         // writelog( str(hWnd)+"=="+str(aControls[1])+str(aControls[2])+str(aControls[3])+str(aControls[4]) )
         MoveWindow( HWindow():aWindows[2]:handle, oWnd:aOffset[1], oWnd:aOffset[2],aControls[3]-oWnd:aOffset[1]-oWnd:aOffset[3],aControls[4]-oWnd:aOffset[2]-oWnd:aOffset[4] )
         // aControls := GetClientRect( HWindow():aWindows[2]:handle )
         // writelog( str(HWindow():aWindows[2]:handle)+"::"+str(aControls[1])+str(aControls[2])+str(aControls[3])+str(aControls[4]) )
         return 0
      endif
   elseif msg == WM_CTLCOLORSTATIC .OR. msg == WM_CTLCOLOREDIT .OR. msg == WM_CTLCOLORBTN
      return DlgCtlColor( oWnd,wParam,lParam )
   elseif msg == WM_ERASEBKGND
      if oWnd:oBmp != Nil
         SpreadBitmap( wParam,oWnd:handle,oWnd:oBmp:handle )
         return 1
      endif
   elseif msg == WM_DRAWITEM
      if ( oBtn := oWnd:FindControl(wParam) ) != Nil
         if oBtn:bPaint != Nil
            Eval( oBtn:bPaint, oBtn, lParam )
         endif
      endif
   elseif msg == WM_NOTIFY
      Return DlgNotify( oWnd,wParam,lParam )
   elseif msg == WM_ENTERIDLE
      DlgEnterIdle( oWnd, wParam, lParam )
   elseif msg == WM_DESTROY
      aControls := oWnd:aControls
      nControls := Len( aControls )
     #ifdef __XHARBOUR__
      FOR EACH oItem IN aControls
         IF __ObjHasMsg( oItem,"END" )
            oItem:End()
         ENDIF
      NEXT
     #else
      FOR i := 1 TO nControls
         IF __ObjHasMsg( aControls[i],"END" )
            aControls[i]:End()
         ENDIF
      NEXT
     #endif
      HWindow():DelItem( oWnd )
      return 0
   elseif msg == WM_SYSCOMMAND
      if wParam == SC_CLOSE
         if oWnd:bDestroy != Nil
            if !Eval( oWnd:bDestroy, oWnd )
               return 0
            endif
            if oWnd:oNotifyIcon != Nil
               ShellNotifyIcon( .F., oWnd:handle, oWnd:oNotifyIcon:handle )
            endif
            if oWnd:hAccel != Nil
               DestroyAcceleratorTable( oWnd:hAccel )
            endif
         endif
      elseif wParam == SC_MINIMIZE
         if oWnd:lTray
            oWnd:Hide()
            return 0
         endif
      endif
   elseif msg == WM_NOTIFYICON
      if wParam == ID_NOTIFYICON
         if lParam == WM_LBUTTONDOWN
            if oWnd:bNotify != Nil
               Eval( oWnd:bNotify )
            endif
         elseif lParam == WM_RBUTTONDOWN
            if oWnd:oNotifyMenu != Nil
               i := hwg_GetCursorPos()
               oWnd:oNotifyMenu:Show( oWnd,i[1],i[2] )
            endif
         endif
      endif
   else
      if msg == WM_MOUSEMOVE
         DlgMouseMove()
      endif
      if oWnd:bOther != Nil
         Eval( oWnd:bOther, oWnd, msg, wParam, lParam )
      endif
   endif

Return -1

Function DefMdiChildProc( hWnd, msg, wParam, lParam )
Local i, iItem, nHandle, aControls, nControls, iCont
Local iParHigh, iParLow, oWnd, oBtn, oitem

   // WriteLog( "|WndChild"+Str(hWnd,10)+"|"+Str(msg,6)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   if msg == WM_CREATE
      if (i := Ascan( HWindow():aWindows, {|o|o:handle==0} ) ) == 0
         MsgStop( "WM_INITCHILD: wrong window handle "+Str( hWnd ),"Error!" )
         QUIT
      endif
      oWnd := HWindow():aWindows[ i ]
      oWnd:handle := hWnd
      InitControls( oWnd )
      IF oWnd:bInit != Nil
         Eval( oWnd:bInit,oWnd )
      ENDIF
      Return -1
   endif
   if ( oWnd := HWindow():FindWindow(hWnd) ) == Nil
      // MsgStop( "MDI child: wrong window handle "+Str( hWnd ),"Error!" )
      Return -1
   endif
   if msg == WM_COMMAND
      if wParam == SC_CLOSE
         if Len(HWindow():aWindows) > 2 .AND. ( nHandle := SendMessage( HWindow():aWindows[2]:handle, WM_MDIGETACTIVE,0,0 ) ) > 0
            SendMessage( HWindow():aWindows[2]:handle, WM_MDIDESTROY, nHandle, 0 )
         endif
      endif
      iParHigh := HiWord( wParam )
      iParLow := LoWord( wParam )
      IF oWnd:aEvents != Nil .AND. ;
         ( iItem := Ascan( oWnd:aEvents, {|a|a[1]==iParHigh.and.a[2]==iParLow} ) ) > 0
         Eval( oWnd:aEvents[ iItem,3 ] )
      ENDIF
      return 0
   elseif msg == WM_MOUSEMOVE
      oBtn := SetOwnBtnSelected()
      if oBtn != Nil
         oBtn:state := OBTN_NORMAL
         InvalidateRect( oBtn:handle, 0 )
         PostMessage( oBtn:handle, WM_PAINT, 0, 0 )
         SetOwnBtnSelected( Nil )
      endif
   elseif msg == WM_PAINT
      if oWnd:bPaint != Nil
         Eval( oWnd:bPaint, oWnd )
      endif
   elseif msg == WM_SIZE
      aControls := oWnd:aControls
      nControls := Len( aControls )
      #ifdef __XHARBOUR__
      FOR EACH oItem in aControls
         IF oItem:bSize != Nil
            Eval( oItem:bSize, ;
             oItem, LoWord( lParam ), HiWord( lParam ) )
         ENDIF
      NEXT
      #else
      FOR iCont := 1 TO nControls
         IF aControls[iCont]:bSize != Nil
            Eval( aControls[iCont]:bSize, ;
             aControls[iCont], LoWord( lParam ), HiWord( lParam ) )
         ENDIF
      NEXT
      #endif
   elseif msg == WM_NCACTIVATE
      if wParam == 1 .AND. oWnd:bGetFocus != Nil
         Eval( oWnd:bGetFocus, oWnd )
      elseif wParam == 0 .AND. oWnd:bLostFocus != Nil
         Eval( oWnd:bLostFocus, oWnd )
      endif
      return -1
   elseif msg == WM_CTLCOLORSTATIC .OR. msg == WM_CTLCOLOREDIT .OR. msg == WM_CTLCOLORBTN
      return DlgCtlColor( oWnd,wParam,lParam )
      /*
      if ( oBtn := oWnd:FindControl(,lParam) ) != Nil
         if oBtn:tcolor != Nil
            SetTextColor( wParam, oBtn:tcolor )
         endif
         if oBtn:bcolor != Nil
            SetBkColor( wParam, oBtn:bcolor )
            Return oBtn:brush:handle
         endif
         Return -1
      endif
      */
   elseif msg == WM_DRAWITEM
      if ( oBtn := oWnd:FindControl(wParam) ) != Nil
         if oBtn:bPaint != Nil
            Eval( oBtn:bPaint, oBtn, wParam, lParam )
         endif
      endif
   elseif msg == WM_DESTROY
      if oWnd:bDestroy != Nil
         Eval( oWnd:bDestroy, oWnd )
      endif
      aControls := oWnd:aControls
      nControls := Len( aControls )
      #ifdef __XHARBOUR__
      FOR each oItem in aControls
         IF __ObjHasMsg( oItem,"END" )
            oItem:End()
         ENDIF
      NEXT
      #else
      FOR i := 1 TO nControls
         IF __ObjHasMsg( aControls[i],"END" )
            aControls[i]:End()
         ENDIF
      NEXT
      #endif
      HWindow():DelItem( oWnd )
      return 1
   else
      if oWnd:bOther != Nil
         Eval( oWnd:bOther, oWnd, msg, wParam, lParam )
      endif
   endif
Return -1

Function GetChildWindowsNumber
Return Len( HWindow():aWindows ) - 2

