/*
 * $Id: hdialog.prg,v 1.67 2008-09-22 22:31:09 fperillo Exp $
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
       { WM_SIZE, { | o, w, l | onSize( o, w, l ) } },                ;
       { WM_INITDIALOG, { | o, w, l | InitModalDlg( o, w, l ) } },    ;
       { WM_ERASEBKGND, { | o, w | onEraseBk( o, w ) } },           ;
       { WM_DESTROY, { | o | onDestroy( o ) } },                  ;
       { WM_ENTERIDLE, { | o, w, l | onEnterIdle( o, w, l ) } },      ;
       { WM_ACTIVATE, { | o, w, l | onActivate( o, w, l ) } },        ;
       { WM_PSPNOTIFY, { | o, w, l | onPspNotify( o, w, l ) } },      ;
       { WM_HELP, { | o, w, l | onHelp( o, w, l ) } }                 ;
     }

STATIC FUNCTION onDestroy( oDlg )

   IF oDlg:oEmbedded != Nil
      oDlg:oEmbedded:END()
   ENDIF

   oDlg:Super:onEvent( WM_DESTROY )
   oDlg:Del()

   RETURN 0

// Class HDialog

CLASS HDialog INHERIT HCustomWindow

CLASS VAR aDialogs       SHARED INIT { }
CLASS VAR aModalDialogs  SHARED INIT { }

   DATA menu
   DATA oPopup                // Context menu for a dialog
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
   DATA nInitFocus INIT 0  // Keeps the ID of the object to receive focus when dialog is created
                           // you can change the object that receives focus adding
                           // ON INIT {||object:SetFocus() }  to the dialog definition

   METHOD New( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
               bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc )
   METHOD Activate( lNoModal, bOnActivate )
   METHOD onEvent( msg, wParam, lParam )
   METHOD Add()      INLINE AAdd( IIf( ::lModal, ::aModalDialogs, ::aDialogs ), Self )
   METHOD Del()
   METHOD FindDialog( hWnd )
   METHOD GetActive()
   METHOD Center()   INLINE Hwg_CenterWindow( ::handle )
   METHOD Restore()  INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_RESTORE, 0 )
   METHOD Maximize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MAXIMIZE, 0 )
   METHOD Minimize() INLINE SendMessage( ::handle,  WM_SYSCOMMAND, SC_MINIMIZE, 0 )
   METHOD Close()    INLINE EndDialog( ::handle )
   //METHOD Release()  INLINE Iif( ::lModal, Hwg_EndDialog( ::handle ), DestroyWindow( ::handle ) )

ENDCLASS

METHOD NEW( lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, ;
            bPaint, bGfocus, bLfocus, bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc, bColor ) CLASS HDialog

   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::Type     := lType
   ::title    := cTitle
   ::style    := IIf( nStyle == Nil, WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX, nStyle )
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
   ::lClipper   := IIf( lClipper == Nil, .F., lClipper )
   ::lExitOnEnter := IIf( lExitOnEnter == Nil, .T., ! lExitOnEnter )
   ::lExitOnEsc  := IIf( lExitOnEsc == Nil, .T., ! lExitOnEsc )

   IF nHelpId != nil
      ::HelpId := nHelpId
   END

   IF bColor != NIL
     ::brush := HBrush():Add(bcolor)
     ::bColor := bcolor
   ENDIF

   RETURN Self

METHOD Activate( lNoModal, bOnActivate ) CLASS HDialog
   LOCAL oWnd, hParent
   ::bOnActivate := bOnActivate
   CreateGetList( Self )
   hParent := IIf( ::oParent != Nil .AND. ;
                   __ObjHasMsg( ::oParent, "HANDLE" ) .AND. ::oParent:handle != Nil ;
                   .AND. ! Empty( ::oParent:handle ) , ::oParent:handle, ;
                   IIf( ( oWnd := HWindow():GetMain() ) != Nil,    ;
                        oWnd:handle, GetActiveWindow() ) )

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
         /*
         IF ::oIcon != Nil
            SendMessage( ::handle,WM_SETICON,1,::oIcon:handle )
         ENDIF
         */
      ENDIF
   ENDIF
   RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HDialog
   LOCAL i
   LOCAL oTab
   LOCAL nPos
   // writelog( str(msg) + str(wParam) + str(lParam) )

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
      //AVE SOMENTE NO DIALOG
      IF ! ::lSuspendMsgsHandling .OR. msg == WM_ERASEBKGND .OR. msg == WM_SIZE
         RETURN Eval( aMessModalDlg[ i, 2 ], Self, wParam, lParam )
      ENDIF
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
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
   LOCAL nReturn := 1, nFocu

   HB_SYMBOL_UNUSED( wParam )
   HB_SYMBOL_UNUSED( lParam )

   // oDlg:handle := hDlg
   // writelog( str(oDlg:handle)+" "+oDlg:title )
   *  .if uMsg == WM_INITDIALOG
   *-EnableThemeDialogTexture(odlg:handle,6)  //,ETDT_ENABLETAB)
   IF ValType( oDlg:menu ) == "A"
      hwg__SetMenu( oDlg:handle, oDlg:menu[ 5 ] )
   ENDIF
   InitControls( oDlg, .T. )
   IF oDlg:oIcon != Nil
      SendMessage( oDlg:handle, WM_SETICON, 1, oDlg:oIcon:handle )
   ENDIF
   IF oDlg:Title != NIL
      SetWindowText( oDlg:Handle, oDlg:Title )
   ENDIF
   IF oDlg:oFont != Nil
      SendMessage( oDlg:handle, WM_SETFONT, oDlg:oFont:handle, 0 )
   ENDIF

   IF oDlg:bInit != Nil
      oDlg:lSuspendMsgsHandling := .t.
      IF Valtype(nReturn := Eval( oDlg:bInit, oDlg )) != "N"
         nReturn := 1
      ENDIF
      oDlg:lSuspendMsgsHandling := .F.
   ENDIF

   IF ValType( oDlg:bOnActivate ) == "B"
      Eval( oDlg:bOnActivate )
   ENDIF

   IF oDlg:bGetFocus != Nil
      oDlg:lSuspendMsgsHandling := .t.
      Eval( oDlg:bGetFocus, oDlg )
      oDlg:lSuspendMsgsHandling := .f.
   ENDIF

   SetFocus(oDlg:handle)

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

STATIC FUNCTION onEraseBk( oDlg, hDC )
   LOCAL aCoors

   IF __ObjHasMsg( oDlg, "OBMP" )
      IF oDlg:oBmp != Nil
         SpreadBitmap( hDC, oDlg:handle, oDlg:oBmp:handle )
         RETURN 1
      ELSE
         aCoors := GetClientRect( oDlg:handle )
         IF oDlg:brush != Nil
            IF ValType( oDlg:brush ) != "N"
               FillRect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, oDlg:brush:handle )
            ENDIF
         ELSE
            FillRect( hDC, aCoors[ 1 ], aCoors[ 2 ], aCoors[ 3 ] + 1, aCoors[ 4 ] + 1, COLOR_3DFACE + 1 )
         ENDIF
         RETURN 1
      ENDIF
   ENDIF
   RETURN 0

   #define  FLAG_CHECK      2

FUNCTION DlgCommand( oDlg, wParam, lParam )
   LOCAL iParHigh := HIWORD( wParam ), iParLow := LOWORD( wParam )
   LOCAL aMenu, i, hCtrl, oCtrl, nEsc := .F.

   // Hwg_WriteLog( "Enter DlgCommand: "+Str(iParHigh,10)+"|"+Str(iParLow,10)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )

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

         IF oCtrl != Nil .AND. octrl:classname = "HTAB"
           Return 1
         ENDIF

         IF oCtrl != Nil .AND. GetNextDlgTabItem( GetActiveWindow() , hCtrl, 1 ) == hCtrl
            IF __ObjHasMsg( oCtrl, "BVALID" ) .AND. oCtrl:bValid != Nil
               Eval( oCtrl:bValid, oCtrl )
            ENDIF
         ENDIF
         IF oCtrl != Nil .AND. oCtrl:id == IDOK //iParLow
            oDlg:lResult := .T.
            EndDialog( oDlg:handle )   // VER AQUI
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
            ENDIF
            //setfocus(odlg:handle)
            RETURN 1
         ENDIF
      ELSEIF iParLow == IDCANCEL
         nEsc := ( getkeystate( VK_ESCAPE ) < 0 )
         oDlg:nLastKey := 27
      ENDIF
   ENDIF
   
   IF  __ObjHasMsg(oDlg, "NINITFOCUS") .AND. oDlg:nInitFocus > 0 .AND. !isWindowVisible(oDlg:handle)
/*
     IF (oCtrl := oDlg:FindControl(,oDlg:nInitFocus)) == nil
        oCtrl := oDlg:FindControl(,GetAncestor(oDlg:nInitFocus, GA_PARENT))
        IF oCtrl != Nil
           GetSkip( oCtrl:oParent, hCtrl, , 1 )
        ENDIF
     ENDIF
     IF oCtrl != Nil .AND. oCtrl:handle == oDlg:nInitFocus .and. oDlg:nInitFocus != 0
        SETFOCUS(oCtrl:handle)
     ENDIF
*/
      SetFocus( oDlg:nInitFocus )
      RETURN 1
   ENDIF


   IF oDlg:aEvents != Nil .AND. ! oDlg:lSuspendMsgsHandling .AND. ;
      ( i := AScan( oDlg:aEvents, { | a | a[ 1 ] == iParHigh.and.a[ 2 ] == iParLow } ) ) > 0
      Eval( oDlg:aEvents[ i, 3 ], oDlg, iParLow )
   ELSEIF iParHigh == 0 .AND. !oDlg:lSuspendMsgsHandling .AND. ( ;
                                ( iParLow == IDOK .AND. oDlg:FindControl( IDOK ) != nil ) .OR. ;
                                iParLow == IDCANCEL )
      IF iParLow == IDOK
         oDlg:lResult := .T.
      ENDIF
      //Replaced by Sandro
//      hwg_writelog( "oDlg:lExitOnEsc "+iif(oDlg:lExitOnEsc, "TRUE", "FALSE" ) + "nEsc "+iif(nEsc, "TRUE", "FALSE" ) )
      IF oDlg:lExitOnEsc .OR. ! nEsc
         EndDialog( oDlg:handle )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "MENU" ) .AND. ValType( oDlg:menu ) == "A" .AND. ;
      ( aMenu := Hwg_FindMenuItem( oDlg:menu, iParLow, @i ) ) != Nil
      IF Hwg_BitAnd( aMenu[ 1, i, 4 ], FLAG_CHECK ) > 0
         CheckMenuItem( , aMenu[ 1, i, 3 ], ! IsCheckedMenuItem( , aMenu[ 1, i, 3 ] ) )
      ENDIF
      IF aMenu[ 1, i, 1 ] != Nil
         Eval( aMenu[ 1, i, 1 ] )
      ENDIF
   ELSEIF __ObjHasMsg( oDlg, "OPOPUP" ) .AND. oDlg:oPopup != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oDlg:oPopup:aMenu, wParam, @i ) ) != Nil ;
      .AND. aMenu[ 1, i, 1 ] != Nil
      Eval( aMenu[ 1, i, 1 ] )
   ENDIF

   IF  __ObjHasMsg(oDlg,"NINITFOCUS") .AND. oDlg:nInitFocus > 0
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
   LOCAL aControls, iCont

   HB_SYMBOL_UNUSED( wParam )

   IF oDlg:oEmbedded != Nil
      oDlg:oEmbedded:Resize( LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF

   aControls := GetWindowRect( oDlg:handle )
   oDlg:nWidth  := aControls[ 3 ] - aControls[ 1 ]
   oDlg:nHeight := aControls[ 4 ] - aControls[ 2 ]
   IF oDlg:bSize != Nil .AND. ;
      ( oDlg:oParent == Nil .OR. ! __ObjHasMsg( oDlg:oParent, "ACONTROLS" ) )
      Eval( oDlg:bSize, oDlg, LOWORD( lParam ), HIWORD( lParam ) )
   ENDIF
   aControls := oDlg:aControls
   IF aControls != Nil
      FOR iCont := 1 TO Len( aControls )
         IF aControls[ iCont ]:bSize != Nil
            Eval( aControls[ iCont ]:bSize, ;
                  aControls[ iCont ], LOWORD( lParam ), HIWORD( lParam ) )
         ENDIF
      NEXT
   ENDIF

   RETURN 0

STATIC FUNCTION onActivate( oDlg, wParam, lParam )
   LOCAL iParLow := LOWORD( wParam )

   HB_SYMBOL_UNUSED( lParam )

   IF iParLow > 0 .AND. oDlg:bGetFocus != Nil .AND. IsWindowVisible( oDlg:handle )
      oDlg:lSuspendMsgsHandling := .t.
      Eval( oDlg:bGetFocus, oDlg )
      oDlg:lSuspendMsgsHandling := .f.
   ELSEIF iParLow == 0 .AND. oDlg:bLostFocus != Nil
      oDlg:lSuspendMsgsHandling := .t.
      Eval( oDlg:bLostFocus, oDlg )
      oDlg:lSuspendMsgsHandling := .f.
   ENDIF
   RETURN 0

STATIC FUNCTION onHelp( oDlg, wParam, lParam )
   LOCAL oCtrl, nHelpId, oParent

   HB_SYMBOL_UNUSED( wParam )

   IF ! Empty( SetHelpFileName() )
      oCtrl := oDlg:FindControl( nil, GetHelpData( lParam ) )
      IF oCtrl != nil
         nHelpId := oCtrl:HelpId
         IF Empty( nHelpId )
            oParent := oCtrl:oParent
            nHelpId := oParent:HelpId
         ENDIF

         WinHelp( oDlg:handle, SetHelpFileName(), IIf( Empty( nHelpId ), 3, 1 ), nHelpId )

      ENDIF
   ENDIF

   RETURN 0

STATIC FUNCTION onPspNotify( oDlg, wParam, lParam )
   LOCAL nCode := GetNotifyCode( lParam ), res := .T.

   HB_SYMBOL_UNUSED( wParam )

   IF nCode == PSN_SETACTIVE //.AND. !oDlg:aEvdisable
      IF oDlg:bGetFocus != Nil
         res := Eval( oDlg:bGetFocus, oDlg )
      ENDIF
      // 'res' should be 0(Ok) or -1
      Hwg_SetDlgResult( oDlg:handle, IIf( res, 0, - 1 ) )
      RETURN 1
   ELSEIF nCode == PSN_KILLACTIVE //.AND. !oDlg:aEvdisable
      IF oDlg:bLostFocus != Nil
         res := Eval( oDlg:bLostFocus, oDlg )
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
   LOCAL oDlg
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


   EXIT PROCEDURE Hwg_ExitProcedure
   Hwg_ExitProc()
   RETURN
