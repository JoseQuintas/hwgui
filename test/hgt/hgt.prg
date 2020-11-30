/*

 $Id$

 Class HGT for combined usage of HWGUI control elements in 
 Harbour gtwvg programs.

 Delivered by José M. C. Quintas (TNX)
 
*/

#include "hbclass.ch"
#include "hbgtinfo.ch"
#include "guilib.ch"
#include "windows.ch"
#define  FIRST_MDICHILD_ID     501
#define  MAX_MDICHILD_WINDOWS   18
#define  WM_NOTIFYICON         WM_USER+1000
#define  ID_NOTIFYICON           1
#define SIZE_MINIMIZED           1
#define HB_GTI_EXTENDED                   1000
#define HB_GTI_NOTIFIERBLOCKGUI           ( HB_GTI_EXTENDED + 10 )

THREAD STATIC MainWVT

EXIT PROCEDURE KillGTChildren()

   IF HB_ISOBJECT( MainWVT ) .AND. MainWVT:ClassName() == "WVGCRT" .AND. MainWVT:isGT
      MainWVT:destroy()
      MainWVT := NIL
   ENDIF

   RETURN

FUNCTION MainGT()

   IF Empty( MainWVT )
      MainWVT := HGT():New()
      MainWVT:Handle := hb_gtInfo( HB_GTI_WINHANDLE )
      hb_gtInfo( HB_GTI_NOTIFIERBLOCKGUI, { | nEvent, ... | MainWVT:OnEvent( nEvent, ... ) } )
      //MainWVT:IsGT := .T.
   ENDIF

   RETURN MainWVT

CLASS HGT INHERIT HWindow

   CLASS VAR aMessages INIT { ;
      { WM_COMMAND, WM_ERASEBKGND, WM_MOVE, WM_SIZE, WM_SYSCOMMAND, ;
      WM_NOTIFYICON, WM_ACTIVATE, WM_ENTERIDLE, WM_ACTIVATEAPP, WM_CLOSE, WM_DESTROY, WM_ENDSESSION }, ;
      { ;
      {|o,w,l|onCommand( o, w, l ) },       ;
      {|o,w|onEraseBk( o, w ) },            ;
      {|o|onMove( o ) },                    ;
      {|o,w,l|hwg_onWndSize( o, w, l ) },   ;
      {|o,w|onSysCommand( o, w ) },         ;
      {|o,w,l|onNotifyIcon( o, w, l ) },    ;
      {|o,w,l|onActivate( o, w, l ) },      ;
      {|o,w,l|onEnterIdle( o, w, l ) },     ;
      {|o,w,l|onEnterIdle( o, w, l ) },     ;
      {|o|onCloseQuery( o ) },              ;
      {|o|hwg_onDestroy( o ) },             ;
      {|o,w|onEndSession( o, w ) }          ;
      } ;
      }
   DATA   nMenuPos
   DATA oNotifyIcon, bNotify, oNotifyMenu
   DATA lTray INIT .F.

   METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
      oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
      cAppName, oBmp, cHelp, nHelpId, bColor, nExclude )
   METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate )
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
      oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
      cAppName, oBmp, cHelp, nHelpId, bColor, nExclude ) CLASS HGT

   (nPos)
   IF nStyle != Nil .AND. nStyle < 0
      nExclude := 0
      IF hwg_Bitand( Abs(nStyle), WND_NOSYSMENU ) != 0
         nExclude := hwg_BitOr( nExclude, WS_SYSMENU )
      ENDIF
      IF hwg_Bitand( Abs(nStyle), WND_NOSIZEBOX ) != 0
         nExclude := hwg_BitOr( nExclude, WS_THICKFRAME )
      ENDIF
      IF hwg_Bitand( Abs(nStyle), Abs(WND_NOTITLE) ) != 0
         nExclude := hwg_BitOr( nExclude, WS_CAPTION )
         nStyle := WS_POPUP
      ELSE
         nStyle := 0
      ENDIF
   ENDIF

   ::Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
      bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
      cAppName, oBmp, cHelp, nHelpId, bColor )
   ::type := lType

   //hbrush := IIf( ::brush != Nil, ::brush:handle, clr )

   IF lType == WND_MAIN
      ::Handle := hb_gtInfo( HB_GTI_WINHANDLE )

      IF cHelp != NIL
         hwg_SetHelpFileName( cHelp )
      ENDIF

   ENDIF
   IF ::bInit != Nil
      Eval( ::bInit, Self )
   ENDIF

   RETURN Self

METHOD Activate( lShow, lMaximized, lMinimized, lCentered, bActivate ) CLASS HGT

   (lShow)
   (lMaximized)
   (lMinimized)
   (lCentered)
   IF bActivate != Nil
      ::bActivate := bActivate
   ENDIF

   hwg_CreateGetList( Self )

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HGT

   LOCAL i

   // hwg_writelog( str(msg) + str(wParam) + str(lParam) )
   IF ( i := Ascan( ::aMessages[1],msg ) ) != 0
      RETURN Eval( ::aMessages[2,i], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1
             hwg_ScrollHV( Self,msg,wParam,lParam )
         ENDIF
         hwg_onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      Return ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   Return - 1


STATIC FUNCTION onNotify( oWnd, wParam, lParam )
   LOCAL iItem, oCtrl, nCode, res, n

   wParam := hwg_PtrToUlong( wParam )
   IF Empty( oCtrl := oWnd:FindControl( wParam ) )
      FOR n := 1 TO Len( oWnd:aControls )
         oCtrl := oWnd:aControls[ n ]:FindControl( wParam )
         IF oCtrl != NIL
            EXIT
         ENDIF
      NEXT
   ENDIF

   IF oCtrl != NIL

      IF __ObjHasMsg( oCtrl, "NOTIFY" )
         RETURN oCtrl:Notify( lParam )
      ELSE
         nCode := hwg_Getnotifycode( lParam )
         IF nCode == EN_PROTECTED
            RETURN 1
         ELSEIF oWnd:aNotify != NIL .AND. ;
               ( iItem := Ascan( oWnd:aNotify, { |a| a[ 1 ] == nCode .AND. ;
               a[ 2 ] == wParam } ) ) > 0
            IF ( res := Eval( oWnd:aNotify[ iItem, 3 ], oWnd, wParam ) ) != NIL
               RETURN res
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onDestroy( oWnd )
   LOCAL aControls := oWnd:aControls
   LOCAL i, nLen   := Len( aControls )

   FOR i := 1 TO nLen
      aControls[ i ]:End()
   NEXT
   oWnd:End()

   RETURN 1

STATIC FUNCTION onCommand( oWnd, wParam )
   LOCAL iItem, iParHigh := hwg_Hiword( wParam ), iParLow := hwg_Loword( wParam )

   IF oWnd:aEvents != NIL .AND. ;
         ( iItem := Ascan( oWnd:aEvents, { |a| a[ 1 ] == iParHigh .AND. ;
         a[ 2 ] == iParLow } ) ) > 0

      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )

   ENDIF

   RETURN 1

STATIC FUNCTION onSize( oWnd, wParam, lParam )
   LOCAL aControls := oWnd:aControls, oItem

   FOR EACH oItem IN aControls
      IF oItem:bSize != NIL
         Eval( oItem:bSize, oItem, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
      ENDIF
   NEXT
   (wParam)

   RETURN - 1

STATIC FUNCTION onCloseQuery( o )

   IF ValType( o:bCloseQuery ) = 'B'
      IF Eval( o:bCloseQuery )
         hwg_ReleaseAllWindows( o:handle )
      end
   ELSE
      hwg_ReleaseAllWindows( o:handle )
   end

   return - 1

STATIC FUNCTION onMove( oWnd )

   LOCAL aControls := hwg_Getwindowrect( oWnd:handle )

   oWnd:nLeft := aControls[1]
   oWnd:nTop  := aControls[2]

   Return - 1

STATIC FUNCTION onEraseBk( oWnd, hDC )
   LOCAL aCoors

   IF oWnd:oBmp != Nil
      hwg_Spreadbitmap( hDC, oWnd:oBmp:handle )
      RETURN 1
   ELSEIF oWnd:brush != Nil .AND. oWnd:type != WND_MAIN
      aCoors := hwg_Getclientrect( oWnd:handle )
      hwg_Fillrect( hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, oWnd:brush:handle )
      RETURN 1
   ENDIF

   RETURN - 1

STATIC FUNCTION onSysCommand( oWnd, wParam )

   LOCAL i

   wParam := hwg_PtrToUlong( wParam )
   IF wParam == SC_CLOSE
      IF HB_ISBLOCK( oWnd:bDestroy )
         i := Eval( oWnd:bDestroy, oWnd )
         i := Iif( ValType( i ) == "L", i, .T. )
         IF !i
            RETURN 0
         ENDIF
      ENDIF
      IF __ObjHasMsg( oWnd, "ONOTIFYICON" ) .AND. oWnd:oNotifyIcon != Nil
         hwg_Shellnotifyicon( .F. , oWnd:handle, oWnd:oNotifyIcon:handle )
      ENDIF
      IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
         hwg_Destroyacceleratortable( oWnd:hAccel )
      ENDIF
   ELSEIF wParam == SC_MINIMIZE
      IF __ObjHasMsg( oWnd, "LTRAY" ) .AND. oWnd:lTray
         oWnd:Hide()
         RETURN 0
      ENDIF
   ENDIF

   Return - 1

STATIC FUNCTION onEndSession( oWnd )

   LOCAL i

   IF HB_ISBLOCK( oWnd:bDestroy )
      i := Eval( oWnd:bDestroy, oWnd )
      i := Iif( ValType( i ) == "L", i, .T. )
      IF !i
         RETURN 0
      ENDIF
   ENDIF

   Return - 1

STATIC FUNCTION onNotifyIcon( oWnd, wParam, lParam )

   LOCAL ar

   wParam := hwg_PtrToUlong( wParam )
   lParam := hwg_PtrToUlong( lParam )
   IF wParam == ID_NOTIFYICON
      IF lParam == WM_LBUTTONDOWN
         IF HB_ISBLOCK( oWnd:bNotify )
            Eval( oWnd:bNotify )
         ENDIF
      ELSEIF lParam == WM_RBUTTONDOWN
         IF oWnd:oNotifyMenu != Nil
            ar := hwg_GetCursorPos()
            oWnd:oNotifyMenu:Show( oWnd, ar[1], ar[2] )
         ENDIF
      ENDIF
   ENDIF

   Return - 1

STATIC FUNCTION onActivate( oDlg, wParam, lParam )

   LOCAL iParLow := hwg_Loword( wParam )

   IF iParLow > 0 .AND. oDlg:bGetFocus != Nil
      Eval( oDlg:bGetFocus, oDlg )
   ELSEIF iParLow == 0 .AND. oDlg:bLostFocus != Nil
      Eval( oDlg:bLostFocus, oDlg )
   ENDIF

   (lParam)
   RETURN 0

STATIC FUNCTION onEnterIdle( oDlg, wParam, lParam )
   LOCAL oItem, b
   LOCAL aCoors, aRect
   IF ( Empty( wParam ) .AND. ( oItem := Atail( HDialog():aModalDialogs ) ) != Nil ;
         .AND. hwg_Isptreq( oItem:handle, lParam ) )
      oDlg := oItem
   ENDIF
   IF __ObjHasMsg( oDlg, "BACTIVATE" )
      IF oDlg:nAdjust == 1
         oDlg:nAdjust := 2
         aCoors := hwg_Getwindowrect( oDlg:handle )
         aRect := hwg_GetClientRect( oDlg:handle )
         oDlg:Move( ,, oDlg:nWidth + (aCoors[3]-aCoors[1]-aRect[3]), oDlg:nHeight + (aCoors[4]-aCoors[2]-aRect[4]) )
      ENDIF
      IF oDlg:bActivate != Nil
         b := oDlg:bActivate
         oDlg:bActivate := Nil
         Eval( b, oDlg )
      ENDIF
   ENDIF

   RETURN 0

FUNCTION AnotationBeforeDelete()
   OnNotify()
   OnDestroy()
   OnSize()
   RETURN Nil

* ======================== EOF of hgt.prg =====================
