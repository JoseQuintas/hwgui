/*
 *$Id: hdialog.prg,v 1.9 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * HDialog class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

REQUEST ENDWINDOW

Static aMessModalDlg := { ;
         { WM_COMMAND,{|o,w,l|DlgCommand(o,w,l)} },         ;
         { WM_SIZE,{|o,w,l|onSize(o,w,l)} },                ;
         { WM_INITDIALOG,{|o,w,l|InitModalDlg(o,w,l)} },    ;
         { WM_ERASEBKGND,{|o,w|onEraseBk(o,w)} },           ;
         { WM_DESTROY,{|o|onDestroy(o)} },                  ;
         { WM_ENTERIDLE,{|o,w,l|onEnterIdle(o,w,l)} },      ;
         { WM_ACTIVATE,{|o,w,l|onActivate(o,w,l)} }         ;
      }

Static Function onDestroy( oDlg )

   oDlg:Super:onEvent( WM_DESTROY )
   HDialog():DelItem( oDlg,.T. )
   IF oDlg:lModal
      hwg_gtk_exit()
   ENDIF

Return 0

// Class HDialog

CLASS HDialog INHERIT HCustomWindow

   CLASS VAR aDialogs       SHARED INIT {}
   CLASS VAR aModalDialogs  SHARED INIT {}

   DATA fbox
   DATA menu
   DATA oPopup                // Context menu for a dialog
   DATA lResult  INIT .F.     // Becomes TRUE if the OK button is pressed
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lClipper INIT .F.     // Set it to TRUE for moving between GETs with ENTER key
   DATA GetList  INIT {}      // The array of GET items in the dialog
   DATA KeyList  INIT {}      // The array of keys ( as Clipper's SET KEY )
   DATA lExitOnEnter INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
                              // Added by Sandro Freire 
   DATA lExitOnEsc   INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
                              // Added by Sandro Freire 
   DATA nLastKey INIT 0
   DATA oIcon, oBmp
   DATA bActivate
   DATA lActivated INIT .F.
   DATA xResourceID
   DATA lModal

   METHOD New( lType,nStyle,x,y,width,height,cTitle,oFont,bInit,bExit,bSize, ;
                  bPaint,bGfocus,bLfocus,bOther,lClipper,oBmp,oIcon,lExitOnEnter,nHelpId,xResourceID, lExitOnEsc )
   METHOD Activate( lNoModal )
   METHOD onEvent( msg, wParam, lParam )
   METHOD AddItem( oWnd,lModal )
   METHOD DelItem( oWnd,lModal )
   METHOD FindDialog( hWnd )
   METHOD GetActive()
   METHOD Center()   INLINE Hwg_CenterWindow( Self )
   METHOD Restore()  INLINE hwg_WindowRestore( ::handle )
   METHOD Maximize() INLINE hwg_WindowMaximize( ::handle )
   METHOD Minimize() INLINE hwg_WindowMinimize( ::handle )
   METHOD Close()    INLINE EndDialog( ::handle )
ENDCLASS

METHOD NEW( lType,nStyle,x,y,width,height,cTitle,oFont,bInit,bExit,bSize, ;
                  bPaint,bGfocus,bLfocus,bOther,lClipper,oBmp,oIcon,lExitOnEnter,nHelpId, xResourceID, lExitOnEsc ) CLASS HDialog

   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::type     := lType
   ::title    := cTitle
   ::style    := Iif( nStyle==Nil,WS_POPUP+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX,nStyle )
   ::oBmp     := oBmp
   ::oIcon    := oIcon
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
   ::lClipper   := Iif( lClipper==Nil,.F.,lClipper )
   ::lExitOnEnter:=Iif( lExitOnEnter==Nil,.T.,!lExitOnEnter )
   ::lExitOnEsc  :=Iif( lExitOnEsc==Nil,.T.,!lExitOnEsc )

   IF hwg_BitAnd( ::style, DS_CENTER ) > 0
      ::nLeft := Int( ( GetDesktopWidth() - ::nWidth ) / 2 )
      ::nTop  := Int( ( GetDesktopHeight() - ::nHeight ) / 2 )
   ENDIF
   ::handle := Hwg_CreateDlg( Self )

RETURN Self

METHOD Activate( lNoModal ) CLASS HDialog
Local hParent,oWnd

   CreateGetList( Self )

   IF lNoModal==Nil ; lNoModal:=.F. ; ENDIF
   ::lModal := !lNoModal
   ::lResult := .F.
   ::AddItem( Self,!lNoModal )
   IF !lNoModal
      hParent := Iif( ::oParent!=Nil .AND. ;
             __ObjHasMsg( ::oParent,"HANDLE") .AND. ::oParent:handle != NIL ;
             .AND. !Empty(::oParent:handle ), ::oParent:handle, ;
             Iif( ( oWnd:=HWindow():GetMain() ) != Nil,    ;
             oWnd:handle,GetActiveWindow() ) )
      hwg_Set_Modal( ::handle, hParent )
   ENDIF
   InitModalDlg( Self )
   hwg_ActivateDialog( ::handle,lNoModal  )

RETURN Nil

METHOD onEvent( msg, wParam, lParam ) CLASS HDialog
Local i

   // writelog( str(msg) + str(wParam) + str(lParam) )
   IF ( i := Ascan( aMessModalDlg, {|a|a[1]==msg} ) ) != 0
      Return Eval( aMessModalDlg[i,2], Self, wParam, lParam )
   ELSE
      Return Super:onEvent( msg, wParam, lParam )
   ENDIF

RETURN 0

METHOD AddItem( oWnd,lModal ) CLASS HDialog
   Aadd( Iif( lModal,::aModalDialogs,::aDialogs ), oWnd )
RETURN Nil

METHOD DelItem( oWnd,lModal ) CLASS HDialog
Local i, h := oWnd:handle
   IF lModal
      IF ( i := Ascan( ::aModalDialogs,{|o|o:handle==h} ) ) > 0
         Adel( ::aModalDialogs,i )
         Asize( ::aModalDialogs, Len(::aModalDialogs)-1 )
      ENDIF
   ELSE
      IF ( i := Ascan( ::aDialogs,{|o|o:handle==h} ) ) > 0
         Adel( ::aDialogs,i )
         Asize( ::aDialogs, Len(::aDialogs)-1 )
      ENDIF
   ENDIF
RETURN Nil

METHOD FindDialog( hWnd ) CLASS HDialog
/*
Local i := Ascan( ::aDialogs, {|o|o:handle==hWnd} )
Return Iif( i == 0, Nil, ::aDialogs[i] )
*/
Return GetWindowObject(hWnd)

METHOD GetActive() CLASS HDialog
Local handle := GetFocus()
Local i := Ascan( ::Getlist,{|o|o:handle==handle} )
Return Iif( i == 0, Nil, ::Getlist[i] )

// End of class
// ------------------------------------

Static Function InitModalDlg( oDlg )
Local iCont

   // writelog( str(oDlg:handle)+" "+oDlg:title )
   IF Valtype( oDlg:menu ) == "A"
      hwg__SetMenu( oDlg:handle, oDlg:menu[5] )
   ENDIF
   /*
   IF oDlg:oIcon != Nil
      SendMessage( oDlg:handle,WM_SETICON,1,oDlg:oIcon:handle )
   ENDIF
   */
   IF oDlg:Title != NIL
      SetWindowText(oDlg:Handle,oDlg:Title)
   ENDIF
   /*
   IF oDlg:oFont != Nil
      SendMessage( oDlg:handle, WM_SETFONT, oDlg:oFont:handle, 0 )
   ENDIF
   */
   IF oDlg:bInit != Nil
      Eval( oDlg:bInit, oDlg )
   ENDIF

Return 1

Static Function onEnterIdle( oDlg, wParam, lParam )
Local oItem

   IF wParam == 0 .AND. ( oItem := Atail( HDialog():aModalDialogs ) ) != Nil ;
         .AND. oItem:handle == lParam .AND. !oItem:lActivated
      oItem:lActivated := .T.
      IF oItem:bActivate != Nil
         Eval( oItem:bActivate, oItem )
      ENDIF
   ENDIF
Return 0

Static Function onEraseBk( oDlg,hDC )
Local aCoors
/*
   IF __ObjHasMsg( oDlg,"OBMP") 
      IF oDlg:oBmp != Nil
         SpreadBitmap( hDC, oDlg:handle, oDlg:oBmp:handle )
         Return 1
      ELSE
        aCoors := GetClientRect( oDlg:handle )
        IF oDlg:brush != Nil
           IF Valtype( oDlg:brush ) != "N"
              FillRect( hDC, aCoors[1],aCoors[2],aCoors[3]+1,aCoors[4]+1,oDlg:brush:handle )
           ENDIF
        ELSE
           FillRect( hDC, aCoors[1],aCoors[2],aCoors[3]+1,aCoors[4]+1,COLOR_3DFACE+1 )
        ENDIF
        Return 1
      ENDIF
   ENDIF
*/   
Return 0

Function DlgCommand( oDlg,wParam,lParam )
Local iParHigh := HiWord( wParam ), iParLow := LoWord( wParam )
Local aMenu, i, hCtrl

   // WriteLog( Str(iParHigh,10)+"|"+Str(iParLow,10)+"|"+Str(wParam,10)+"|"+Str(lParam,10) )
   IF iParHigh == 0
      IF iParLow == IDOK
         hCtrl := GetFocus()
         FOR i := Len(oDlg:GetList) TO 1 STEP -1
            IF !oDlg:GetList[i]:lHide .AND. IsWindowEnabled( oDlg:Getlist[i]:Handle )
               EXIT
            ENDIF
         NEXT
         IF i != 0 .AND. oDlg:GetList[i]:handle == hCtrl
            IF __ObjHasMsg(oDlg:GetList[i],"BVALID")
               IF Eval( oDlg:GetList[i]:bValid,oDlg:GetList[i] ) .AND. ;
                      oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  EndDialog( oDlg:handle )
               ENDIF
               Return 1
            ENDIF
         ENDIF
         IF oDlg:lClipper
            IF !GetSkip( oDlg,hCtrl,1 )
               IF oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  EndDialog( oDlg:handle )
               ENDIF
            ENDIF
            Return 1
         ENDIF
      ELSEIF iParLow == IDCANCEL
         oDlg:nLastKey := 27
      ENDIF
   ENDIF

   IF oDlg:aEvents != Nil .AND. ;
      ( i := Ascan( oDlg:aEvents, {|a|a[1]==iParHigh.and.a[2]==iParLow} ) ) > 0
      Eval( oDlg:aEvents[ i,3 ],oDlg,iParLow )
   ELSEIF iParHigh == 0 .AND. ( ;
        ( iParLow == IDOK .AND. oDlg:FindControl(IDOK) != Nil ) .OR. ;
          iParLow == IDCANCEL )
      IF iParLow == IDOK
         oDlg:lResult := .T.
      ENDIF
      //Replaced by Sandro
      IF oDlg:lExitOnEsc
         EndDialog( oDlg:handle )
      ENDIF
   ELSEIF __ObjHasMsg(oDlg,"MENU") .AND. Valtype( oDlg:menu ) == "A" .AND. ;
        ( aMenu := Hwg_FindMenuItem( oDlg:menu,iParLow,@i ) ) != Nil ;
        .AND. aMenu[ 1,i,1 ] != Nil
      Eval( aMenu[ 1,i,1 ] )
   ELSEIF __ObjHasMsg(oDlg,"OPOPUP") .AND. oDlg:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oDlg:oPopup:aMenu,wParam,@i ) ) != Nil ;
         .AND. aMenu[ 1,i,1 ] != Nil
         Eval( aMenu[ 1,i,1 ] )
   ENDIF

Return 1

Static Function onSize( oDlg,wParam,lParam )
Local aControls, iCont

   IF oDlg:bSize != Nil .AND. ;
       ( oDlg:oParent == Nil .OR. !__ObjHasMsg( oDlg:oParent,"ACONTROLS" ) )
      Eval( oDlg:bSize, oDlg, LoWord( lParam ), HiWord( lParam ) )
   ENDIF
   aControls := oDlg:aControls
   IF aControls != Nil
      FOR iCont := 1 TO Len( aControls )
         IF aControls[iCont]:bSize != Nil
            Eval( aControls[iCont]:bSize, ;
             aControls[iCont], LoWord( lParam ), HiWord( lParam ) )
         ENDIF
      NEXT
   ENDIF

Return 0

Static Function onActivate( oDlg,wParam,lParam )
Local iParLow := LoWord( wParam )

   if iParLow > 0 .AND. oDlg:bGetFocus != Nil
      Eval( oDlg:bGetFocus, oDlg )
   elseif iParLow == 0 .AND. oDlg:bLostFocus != Nil
      Eval( oDlg:bLostFocus, oDlg )
   endif

Return 0

Function GetModalDlg
Local i := Len( HDialog():aModalDialogs )
Return Iif( i>0, HDialog():aModalDialogs[i], 0 )

Function GetModalHandle
Local i := Len( HDialog():aModalDialogs )
Return Iif( i>0, HDialog():aModalDialogs[i]:handle, 0 )

Function EndDialog( handle )
Local oDlg
   // writelog("EndDialog-0 "+Valtype(handle)+" "+str(pCount()))
   IF handle == Nil
      IF ( oDlg := Atail( HDialog():aModalDialogs ) ) == Nil
         // writelog("EndDialog-1")
         Return Nil
      ENDIF
   ELSE
      /*
      IF ( ( oDlg := Atail( HDialog():aModalDialogs ) ) == Nil .OR. ;
            oDlg:handle != handle ) .AND. ;
         ( oDlg := HDialog():FindDialog(handle) ) == Nil
         // writelog("EndDialog-2")
         Return Nil
      ENDIF
      */
      oDlg := GetWindowObject( handle )
   ENDIF
   IF oDlg:bDestroy != Nil .AND. !Eval( oDlg:bDestroy, oDlg )
      // writelog("EndDialog-3")
      Return Nil
   ENDIF
   // writelog("EndDialog-10")
Return  hwg_DestroyWindow( oDlg:handle )

Function SetDlgKey( oDlg, nctrl, nkey, block )
Local i, aKeys

   IF oDlg == Nil ; oDlg := HCustomWindow():oDefaultParent ; ENDIF
   IF nctrl == Nil ; nctrl := 0 ; ENDIF

   IF !__ObjHasMsg( oDlg,"KEYLIST" )
      Return .F.
   ENDIF
   aKeys := oDlg:KeyList
   IF block == Nil

      IF ( i := Ascan( aKeys,{|a|a[1]==nctrl.AND.a[2]==nkey} ) ) == 0
         Return .F.
      ELSE
         Adel( oDlg:KeyList, i )
         Asize( oDlg:KeyList, Len(oDlg:KeyList)-1 )
      ENDIF
   ELSE
      IF ( i := Ascan( aKeys,{|a|a[1]==nctrl.AND.a[2]==nkey} ) ) == 0
         Aadd( aKeys, { nctrl,nkey,block } )
      ELSE
         aKeys[i,3] := block
      ENDIF
   ENDIF

Return .T.
