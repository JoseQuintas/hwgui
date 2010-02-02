/*
 *$Id: hcwindow.prg,v 1.59 2010-02-02 15:25:00 lfbasso Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HCustomWindow class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define EVENTS_MESSAGES 1
#define EVENTS_ACTIONS  2
#define RT_MANIFEST  24

STATIC aCustomEvents := { ;
       { WM_NOTIFY, WM_PAINT, WM_CTLCOLORSTATIC, WM_CTLCOLOREDIT, WM_CTLCOLORBTN, WM_CTLCOLORLISTBOX, ;
         WM_COMMAND, WM_DRAWITEM, WM_SIZE, WM_DESTROY }, ;
       { ;
         { | o, w, l | onNotify( o, w, l ) }                                 , ;
         { | o, w |   IIf( o:bPaint != NIL, Eval( o:bPaint, o, w ), - 1 ) }  , ;
         { | o, w, l | onCtlColor( o, w, l ) }                               , ;
         { | o, w, l | onCtlColor( o, w, l ) }                               , ;
         { | o, w, l | onCtlColor( o, w, l ) }                               , ;
         { | o, w, l | onCtlColor( o, w, l ) }                               , ;
         { | o, w, l | onCommand( o, w, l ) }                                , ;
         { | o, w, l | onDrawItem( o, w, l ) }                               , ;
         { | o, w, l | onSize( o, w, l ) }                                   , ;
         { | o |     onDestroy( o ) }                                          ;
       } ;
     }

CLASS HObject

   DATA aObjects     INIT { }
   METHOD AddObject( oCtrl ) INLINE AAdd( ::aObjects, oCtrl )
   METHOD DelObject( oCtrl )
   METHOD Release()  INLINE ::DelObject( Self )

ENDCLASS

METHOD DelObject( oCtrl ) CLASS HObject
LOCAL h := oCtrl:handle, id := oCtrl:id
LOCAL i := Ascan( ::aObjects, {|o| o:handle == h } )

   SendMessage( h, WM_CLOSE, 0, 0 )
   IF i != 0
      Adel( ::aObjects, i )
      Asize( ::aObjects, Len( ::aObjects ) - 1 )
   ENDIF
   RETURN NIL


CLASS HCustomWindow INHERIT HObject

CLASS VAR oDefaultParent SHARED
CLASS VAR WindowsManifest INIT !EMPTY(FindResource( , 1 , RT_MANIFEST ) ) SHARED
   
   DATA handle        INIT 0
   DATA oParent
   DATA title
   ACCESS Caption  INLINE ::title
   ASSIGN Caption( x ) INLINE ::SetTextClass( x )
   DATA Type       INIT 0
   DATA nTop, nLeft, nWidth, nHeight
   DATA minWidth   INIT - 1
   DATA maxWidth   INIT - 1
   DATA minHeight  INIT - 1
   DATA maxHeight  INIT - 1
   DATA tcolor, bcolor, brush
   DATA style
   DATA extStyle      INIT 0
   DATA lHide         INIT .F.
   DATA oFont
   DATA aEvents       INIT { }
   DATA lSuspendMsgsHandling  INIT .F.
   DATA lGetSkipLostFocus     INIT .F.
   DATA aNotify       INIT { }
   DATA aControls     INIT { }
   DATA bInit
   DATA bDestroy
   DATA bSize
   DATA bPaint
   DATA bGetFocus
   DATA bLostFocus
   DATA bScroll
   DATA bOther
   DATA bRefresh
   DATA cargo
   DATA HelpId        INIT 0
   DATA nHolder       INIT 0
   DATA nInitFocus    INIT 0  // Keeps the ID of the object to receive focus when dialog is created
                              // you can change the object that receives focus adding
                              // ON INIT {|| nInitFocus:=object:[handle] }  to the dialog definition
   DATA nCurWidth    INIT 0
   DATA nCurHeight   INIT 0
   DATA nScrollPos   INIT 0
   DATA rect
   DATA nScrollBars INIT -1
   DATA lClosable     INIT .T. //disable Menu and Button Close in WINDOW

   METHOD AddControl( oCtrl ) INLINE AAdd( ::aControls, oCtrl )
   METHOD DelControl( oCtrl )
   METHOD AddEvent( nEvent, oCtrl, bAction, lNotify, cMethName )
   METHOD FindControl( nId, nHandle )
   METHOD Hide()              INLINE ( ::lHide := .T., HideWindow( ::handle ) )
   METHOD Show()              INLINE ( ::lHide := .F., ShowWindow( ::handle ) )
   METHOD Move( x1, y1, width, height )
   METHOD onEvent( msg, wParam, lParam )
   METHOD END()
   METHOD SetColor( tcolor, bColor, lRepaint )
   METHOD RefreshCtrl( oCtrl )
   METHOD SetFocusCtrl( oCtrl )
   METHOD Refresh()
   METHOD Anchor( oCtrl, x, y, w, h )
   METHOD ScrollHV( msg, wParam, lParam )
   METHOD SetTextClass ( x ) HIDDEN
   METHOD GetParentForm( oCtrl )
   METHOD ActiveControl()  INLINE ::FindControl( , GetFocus() )
   METHOD Closable( lClosable ) SETGET
   METHOD Release()        INLINE ::DelControl( Self )
   METHOD SetAll( cProperty, Value, aControls, cClass )
   
ENDCLASS

METHOD AddEvent( nEvent, oCtrl, bAction, lNotify, cMethName ) CLASS HCustomWindow

   AAdd( IIf( lNotify == NIL .OR. ! lNotify, ::aEvents, ::aNotify ), ;
         { nEvent, IIf( ValType( oCtrl ) == "N", oCtrl, oCtrl:id ), bAction } )
   IF bAction != Nil .AND. ValType( oCtrl ) == "O"  //.AND. ValType(oCtrl) != "N"
      IF cMethName != Nil //.AND. !__objHasMethod( oCtrl, cMethName )
         __objAddInline( oCtrl, cMethName, bAction )
      ENDIF
   ENDIF
   RETURN nil

METHOD FindControl( nId, nHandle ) CLASS HCustomWindow

   LOCAL bSearch := IIf( nId != NIL, { | o | o:id == nId } , { | o | PtrtoUlong( o:handle ) == PtrtoUlong( nHandle ) } )
   LOCAL i := Len( ::aControls )
   LOCAL oCtrl

   DO WHILE i > 0
      IF Len( ::aControls[ i ]:aControls ) > 0 .and. ;
         ( oCtrl := ::aControls[ i ]:FindControl( nId, nHandle ) ) != nil
         RETURN oCtrl
      ENDIF
      IF Eval( bSearch, ::aControls[ i ] )
         RETURN ::aControls[ i ]
      ENDIF
      i --
   ENDDO
   RETURN Nil

METHOD DelControl( oCtrl ) CLASS HCustomWindow
   LOCAL h := oCtrl:handle, id := oCtrl:id
   LOCAL i := AScan( ::aControls, { | o | o:handle == h } )

   SendMessage( h, WM_CLOSE, 0, 0 )
   IF i != 0
      ADel( ::aControls, i )
      ASize( ::aControls, Len( ::aControls ) - 1 )
   ENDIF

   h := 0
   FOR i := Len( ::aEvents ) TO 1 STEP - 1
      IF ::aEvents[ i, 2 ] == id
         ADel( ::aEvents, i )
         h ++
      ENDIF
   NEXT

   IF h > 0
      ASize( ::aEvents, Len( ::aEvents ) - h )
   ENDIF

   h := 0
   FOR i := Len( ::aNotify ) TO 1 STEP - 1
      IF ::aNotify[ i, 2 ] == id
         ADel( ::aNotify, i )
         h ++
      ENDIF
   NEXT

   IF h > 0
      ASize( ::aNotify, Len( ::aNotify ) - h )
   ENDIF

   RETURN NIL

METHOD Move( x1, y1, width, height )  CLASS HCustomWindow

   IF x1 != NIL
      ::nLeft := x1
   ENDIF
   IF y1 != NIL
      ::nTop  := y1
   ENDIF
   IF width != NIL
      ::nWidth := width
   ENDIF
   IF height != NIL
      ::nHeight := height
   ENDIF
   MoveWindow( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

   RETURN NIL

METHOD onEvent( msg, wParam, lParam )  CLASS HCustomWindow
   LOCAL i

   // Writelog( "== "+::Classname()+Str(msg)+IIF(wParam!=NIL,Str(wParam),"NIL")+IIF(lParam!=NIL,Str(lParam),"NIL") )

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
   ENDIF

   IF ( i := AScan( aCustomEvents[ EVENTS_MESSAGES ], msg ) ) != 0
      RETURN Eval( aCustomEvents[ EVENTS_ACTIONS, i ], Self, wParam, lParam )

   ELSEIF ::bOther != NIL

      RETURN Eval( ::bOther, Self, msg, wParam, lParam )

   ENDIF

   RETURN - 1

METHOD END()  CLASS HCustomWindow
LOCAL aControls, i, nLen

   IF ::nHolder != 0

      ::nHolder := 0
      hwg_DecreaseHolders( ::handle ) // Self )
      aControls := ::aControls
      nLen := Len( aControls )
      FOR i := 1 TO nLen
          aControls[ i ]:End()
      NEXT
   ENDIF

   RETURN NIL

//----------------------------------------------------------------------------//

METHOD GetParentForm( oCtrl )  CLASS HCustomWindow
LOCAL oForm := IIF( EMPTY( oCtrl ), Self, oCtrl )
   DO WHILE ( oForm:oParent ) != Nil .AND. ! __ObjHasMsg( oForm, "GETLIST" )
      oForm := oForm:oParent
   ENDDO
   RETURN oForm


METHOD RefreshCtrl( oCtrl, nSeek ) CLASS HCustomWindow
   LOCAL nPos, n

   DEFAULT nSeek := 1

   IF nSeek == 1
      n := 1
   ELSE
      n := 3
   ENDIF

   nPos := AScan( ::aControls, { | x | x[ n ] == oCtrl } )

   IF nPos > 0
      ::aControls[ nPos, 2 ]:Refresh()
   ENDIF

   RETURN NIL

//----------------------------------------------------------------------------//
METHOD SetFocusCtrl( oCtrl ) CLASS HCustomWindow
   LOCAL nPos

   nPos := AScan( ::aControls, { | x | x[ 1 ] == oCtrl } )

   IF nPos > 0
      ::aControls[ nPos, 2 ]:SetFocus()
   ENDIF

   RETURN NIL


METHOD Refresh( oCtrl ) CLASS HCustomWindow
  Local nlen , i, hCtrl := GetFocus()
   oCtrl := IIF( oCtrl = Nil, self, Octrl )
   nlen := LEN( oCtrl:aControls )

  IF IsWindowVisible( ::Handle )
     FOR i = 1 to nLen
        IF ! oCtrl:aControls[ i ]:lHide
            IF __ObjHasMethod(oCtrl:aControls[ i ],"REFRESH" )
              oCtrl:aControls[ i ]:Refresh( )
              IF oCtrl:aControls[ i ]:bRefresh != Nil
                 EVAL( oCtrl:aControls[ i ]:bRefresh, oCtrl:aControls[ i ] )
              ENDIF
           ELSE
              oCtrl:aControls[ i ]:SHOW()
               ENDIF
            IF LEN( oCtrl:aControls[ i ]:aControls ) > 0
                ::Refresh( oCtrl:aControls[ i ] )
             ENDIF
        ENDIF
      NEXT
      IF ::bRefresh != Nil .AND. ::handle != hCtrl
         Eval( ::bRefresh, Self ) 
      ENDIF
   ELSEIF  ::bRefresh != Nil
      Eval( ::bRefresh, Self )
   ENDIF
   RETURN Nil


METHOD SetTextClass( x ) CLASS HCustomWindow

   IF __ObjHasMsg( Self, "SETTEXT" ) //.AND. ::classname != "HBUTTONEX"
       ::SetText( x )
    ELSEIF __ObjHasMsg( Self, "SETVALUE" )
       ::SetValue( x )
    ELSE
       ::title := x
       SENDMESSAGE( ::handle, WM_SETTEXT, 0, ::Title )
    ENDIF
    ::Refresh()

   RETURN NIL

METHOD SetColor( tcolor, bColor, lRepaint ) CLASS HCustomWindow

   IF tcolor != NIL
      ::tcolor := tcolor
      IF bColor == NIL .AND. ::bColor == NIL
         bColor := GetSysColor( COLOR_3DFACE )
      ENDIF
   ENDIF

   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add( bColor )
   ENDIF

   IF lRepaint != NIL .AND. lRepaint
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF
   RETURN Nil

METHOD Anchor( oCtrl, x, y, w, h ) CLASS HCustomWindow
   LOCAL nlen , i, x1, y1
   nlen := Len( oCtrl:aControls )
   ::lSuspendMsgsHandling  := .T.
   FOR i = 1 TO nlen
      IF __ObjHasMsg( oCtrl:aControls[ i ], "ANCHOR" ) .AND. oCtrl:aControls[ i ]:anchor > 0 .AND.;
           IsWindowVisible( ::GetParentForm():handle )
         x1 := oCtrl:aControls[ i ]:nWidth
         y1 := oCtrl:aControls[ i ]:nHeight
         oCtrl:aControls[ i ]:onAnchor( x, y, w, h )
         IF Len( oCtrl:aControls[ i ]:aControls ) > 0
            ::Anchor( oCtrl:aControls[ i ], x1, y1, oCtrl:aControls[ i ]:nWidth, oCtrl:aControls[ i ]:nHeight )
            //::Anchor( oCtrl:aControls[ i ], x, y, oCtrl:nWidth, oCtrl:nHeight )
         ENDIF
      ENDIF
   NEXT
   ::lSuspendMsgsHandling  := .F.
   RETURN .T.

METHOD  ScrollHV( oForm, msg, wParam, lParam ) CLASS HCustomWindow
   LOCAL nDelta, nMaxPos,  wmsg , nPos

   HB_SYMBOL_UNUSED( lParam )

   nDelta := 0
   wmsg := LOWORD( wParam )

   IF msg = WM_VSCROLL .OR. msg = WM_HSCROLL
      nMaxPos := IIf( msg = WM_VSCROLL, oForm:rect[ 4 ] - oForm:nCurHeight, oForm:rect[ 3 ] - oForm:nCurWidth )
      IF wmsg =  SB_LINEDOWN
         IF ( oForm:nScrollPos >= nMaxPos )
            RETURN 0
         ENDIF
         nDelta := Min( nMaxPos / 100, nMaxPos - oForm:nScrollPos )
      ELSEIF wmsg = SB_LINEUP
         IF ( oForm:nScrollPos <= 0 )
            RETURN 0
         ENDIF
         nDelta := - Min( nMaxPos / 100, oForm:nScrollPos )
      ELSEIF wmsg = SB_PAGEDOWN
         IF ( oForm:nScrollPos >= nMaxPos )
            RETURN 0
         ENDIF
         nDelta := Min( nMaxPos / 10, nMaxPos - oForm:nScrollPos )
      ELSEIF wmsg = SB_THUMBPOSITION
         nPos := HIWORD( wParam )
         nDelta := nPos - oForm:nScrollPos
      ELSEIF wmsg = SB_PAGEUP
         IF ( oForm:nScrollPos <= 0 )
            RETURN 0
         ENDIF
         nDelta := - Min( nMaxPos / 10, oForm:nScrollPos )
      ELSE
         RETURN 0
      ENDIF
      oForm:nScrollPos += nDelta
      IF msg = WM_VSCROLL
         setscrollpos( oForm:handle, SB_VERT, oForm:nScrollPos )
         ScrollWindow( oForm:handle, 0, - nDelta )
      ELSE
         setscrollpos( oForm:handle, SB_HORZ, oForm:nScrollPos )
         ScrollWindow( oForm:handle, - nDelta, 0 )
      ENDIF
      RETURN - 1

   ENDIF
   RETURN Nil

METHOD Closable( lClosable ) CLASS HCustomWindow
   Local hMenu

   IF lClosable != Nil
      IF ! lClosable
         hMenu := EnableMenuSystemItem( ::Handle, SC_CLOSE, .F. )
      ELSE
         hMenu := EnableMenuSystemItem( ::Handle, SC_CLOSE, .T. )
      ENDIF
      IF ! EMPTY( hMenu )
         ::lClosable := lClosable
      ENDIF
   ENDIF
   RETURN ::lClosable

METHOD SetAll( cProperty, Value, aControls, cClass ) CLASS HCustomWindow
// cProperty Specifies the property to be set.
// Value Specifies the new setting for the property. The data type of Value depends on the property being set.
 //aControls - property of the Control with objectos inside 
 // cClass baseclass hwgui 
   Local nLen , i, x1, y1 //, oCtrl
   
   aControls := IIF( EMPTY( aControls ), ::aControls, aControls )
   nLen := IIF( VALTYPE( aControls ) = "C", Len( ::&aControls ), LEN( aControls ) )
	 FOR i = 1 TO nLen
	    IF VALTYPE( aControls ) = "C"
	       ::&aControls[ i ]:&cProperty := Value
	    ELSEIF cClass == Nil .OR. UPPER( cClass ) == aControls[ i ]:ClassName
	       IF Value = Nil
	          __mvPrivate( "oCtrl" )
	          &( "oCtrl" ) := aControls[ i ]
	          &( "oCtrl:" + cProperty )
	       ELSE  
	          aControls[ i ]:&cProperty := Value
	       ENDIF
      ENDIF   
   NEXT
   RETURN Nil 


*---------------------------------------------------------

STATIC FUNCTION onNotify( oWnd, wParam, lParam )
   LOCAL iItem, oCtrl := oWnd:FindControl( wParam ), nCode, res
   LOCAL n

   IF oCtrl == NIL
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
         nCode := GetNotifyCode( lParam )
         IF nCode == EN_PROTECTED
            RETURN 1
         ELSEIF oWnd:aNotify != NIL .AND. ! oWnd:lSuspendMsgsHandling .AND. ;
            ( iItem := AScan( oWnd:aNotify, { | a | a[ 1 ] == nCode .AND. ;
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
      aControls[ i ]:END()
   NEXT
   nLen := Len( oWnd:aObjects )
   FOR i := 1 TO nLen
      oWnd:aObjects[ i ]:END()
   NEXT
   oWnd:END()

   RETURN 1


STATIC FUNCTION onCtlColor( oWnd, wParam, lParam )
   LOCAL oCtrl
//lParam := HANDLETOPTR( lParam)
   oCtrl := oWnd:FindControl( , lParam )

   IF oCtrl != NIL
      IF oCtrl:tcolor != NIL
         SetTextColor( wParam, oCtrl:tcolor )
      ENDIF
      IF oCtrl:bcolor != NIL  .AND. oCtrl:BackStyle = 1 // OPAQUE
         SetBkColor( wParam, oCtrl:bcolor )
         IF oCtrl:brush != Nil
            RETURN oCtrl:brush:handle
         ELSEIF oCtrl:oParent:brush != Nil
            RETURN oCtrl:oParent:brush:handle
         ENDIF
      ELSEIF oCtrl:BackStyle = 0 // TRANSPARENT
        SETTRANSPARENTMODE( wParam, .T. )
        IF ( oCtrl:classname $ "HCHECKBUTTON" .AND. (  ! oCtrl:lnoThemes .AND. ( ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest ) ) ) .OR.;
           ( oCtrl:classname $ "HGROUP*HRADIOGROUP*HRADIOBUTTON" .AND. oCtrl:lnoThemes ) 
				   RETURN GetBackColorParent( octrl, , .T. ):handle
				ENDIF 
				IF oCtrl:winclass $ "BUTTON*STATIC*EDIT" 
				   RETURN GetStockObject( NULL_BRUSH )
				ENDIF   
				RETURN GetBackColorParent( octrl, , .T. ):handle
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onDrawItem( oWnd, wParam, lParam )
   LOCAL oCtrl
   IF wParam != 0 .AND. ( oCtrl := oWnd:FindControl( wParam ) ) != NIL .AND. ;
                          oCtrl:bPaint != NIL
      Eval( oCtrl:bPaint, oCtrl, lParam )
      RETURN 1

   ENDIF

   RETURN - 1

STATIC FUNCTION onCommand( oWnd, wParam, lParam )
   LOCAL iItem, iParHigh := HIWORD( wParam ), iParLow := LOWORD( wParam )

   HB_SYMBOL_UNUSED( lParam )
   IF oWnd:aEvents != NIL .AND. ! oWnd:lSuspendMsgsHandling .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[ 1 ] == iParHigh .AND. ;
                                        a[ 2 ] == iParLow } ) ) > 0

      IF oWnd:GetParentForm():Type < WND_DLG_RESOURCE
         oWnd:GetParentForm():nFocus := GetFocus()
      ENDIF
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ENDIF

   RETURN 1

STATIC FUNCTION onSize( oWnd, wParam, lParam )
   LOCAL aControls := oWnd:aControls, nControls := Len( aControls )
   LOCAL oItem, iCont, nw1, nh1, aCoors

   HB_SYMBOL_UNUSED( wParam )

   nw1 := oWnd:nWidth
   nh1 := oWnd:nHeight
   aCoors := GetWindowRect( oWnd:handle )
   oWnd:nWidth := aCoors[ 3 ] - aCoors[ 1 ]
   oWnd:nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   IF !EMPTY( oWnd:type) .AND. oWnd:Type = WND_MDI  .AND. !EMPTY( oWnd:Screen )
     oWnd:Anchor( oWnd:Screen, nw1, nh1, oWnd:nWidth, oWnd:nHeight )
   ENDIF
   oWnd:Anchor( oWnd, nw1, nh1, oWnd:nWidth, oWnd:nHeight )

   #ifdef __XHARBOUR__

      HB_SYMBOL_UNUSED( iCont )

      FOR EACH oItem IN aControls
         IF oItem:bSize != NIL
            Eval( oItem:bSize, oItem, LOWORD( lParam ), HIWORD( lParam ) )
         ENDIF
      NEXT
   #else

      HB_SYMBOL_UNUSED( oItem )

      FOR iCont := 1 TO nControls
         IF aControls[ iCont ]:bSize != NIL
            Eval( aControls[ iCont ]:bSize, aControls[ iCont ], ;
                  LOWORD( lParam ), HIWORD( lParam ) )
         ENDIF
      NEXT
   #endif

   RETURN - 1

FUNCTION onTrackScroll( oWnd, msg, wParam, lParam )
   LOCAL oCtrl := oWnd:FindControl( , lParam )

   IF oCtrl != NIL
      msg := LOWORD( wParam )
      IF msg == TB_ENDTRACK
         IF ISBLOCK( oCtrl:bChange )
            Eval( oCtrl:bChange, oCtrl )
            RETURN 0
         ENDIF
      ELSEIF msg == TB_THUMBTRACK .OR. ;
         msg == TB_PAGEUP     .OR. ;
         msg == TB_PAGEDOWN

         IF ISBLOCK( oCtrl:bThumbDrag )
            Eval( oCtrl:bThumbDrag, oCtrl )
            RETURN 0
         ENDIF
      ENDIF
   ELSE
      IF ISBLOCK( oWnd:bScroll )
         Eval( oWnd:bScroll, oWnd, msg, wParam, lParam )
         RETURN 0
      ENDIF
   ENDIF

   RETURN - 1

PROCEDURE HB_GT_DEFAULT_NUL()
   RETURN

FUNCTION ProcKeyList( oCtrl, wParam, oMain )
LOCAL oParent, nCtrl,nPos

   IF ( wParam = VK_RETURN .OR. wParam = VK_ESCAPE ) .AND.  ProcOkCancel( oCtrl, wParam )
      RETURN .F.
   ENDIF
   IF wParam != VK_SHIFT  .AND. wParam != VK_CONTROL .AND. wParam != VK_MENU
      oParent := IIF( oMain != Nil, oMain, ParentGetDialog( oCtrl ) )
      IF oParent != Nil .AND. ! Empty( oParent:KeyList )
         nctrl := IIf( IsCtrlShift(.t., .f.), FCONTROL, iif(IsCtrlShift(.f., .t.), FSHIFT, 0 ) )
         IF ( nPos := AScan( oParent:KeyList, { | a | a[ 1 ] == nctrl.AND.a[ 2 ] == wParam } ) ) > 0
            Eval( oParent:KeyList[ nPos, 3 ], oCtrl )
            RETURN .T.
         ENDIF
      ENDIF
      IF oParent != Nil .AND. oMain = Nil .AND. HWindow():GetMain() != Nil
          ProcKeyList( oCtrl, wParam, HWindow():GetMain():aWindows[ 1 ] )
      ENDIF
   ENDIF
   RETURN .F.

FUNCTION ProcOkCancel( oCtrl, nKey )
   Local oWin := oCtrl:GetParentForm()
   Local iParHigh := IIF( nKey = VK_RETURN, IDOK, IDCANCEL )


   IF oWin:Type >= WND_DLG_RESOURCE .OR. ( nKey != VK_RETURN .AND. nKey != VK_ESCAPE )
      Return .F.
    ENDIF
   IF iParHigh == IDOK
       IF ( oCtrl := oWin:FindControl( IDOK ) ) != Nil
          oCtrl:SetFocus()
          SendMessage( oCtrl:oParent:handle, WM_COMMAND, makewparam( oCtrl:id, BN_CLICKED ), oCtrl:handle )
           IF oWin:lExitOnEnter
              oWin:close()
          ENDIF
       ENDIF
      RETURN .T.
   ELSEIF iParHigh == IDCANCEL
      IF ( oCtrl := oWin:FindControl( IDCANCEL ) ) != Nil
         oCtrl:SetFocus()
         SendMessage( oCtrl:oParent:handle, WM_COMMAND, makewparam( oCtrl:id, BN_CLICKED ), oCtrl:handle )
      ELSEIF oWin:lExitOnEsc
          oWin:close()
      ELSEIF ! oWin:lExitOnEsc
         oWin:nLastKey := 0
      ENDIF
      RETURN .T.
   ENDIF
   RETURN .F.

FUNCTION ADDPROPERTY( oObjectName, cPropertyName, eNewValue )

   IF VALTYPE( oObjectName ) = "O" .AND. ! EMPTY( cPropertyName )
      IF ! __objHasData( oObjectName, cPropertyName )
         IF EMPTY( __objAddData( oObjectName, cPropertyName ) )
              RETURN .F.
         ENDIF
      ENDIF
      IF !EMPTY( eNewValue )
         IF VALTYPE( eNewValue ) = "B"
            oObjectName: & ( cPropertyName ) := EVAL( eNewValue )
         ELSE
            oObjectName: & ( cPropertyName ) := eNewValue
         ENDIF
      ENDIF
      RETURN .T.
   ENDIF
   RETURN .F.

FUNCTION REMOVEPROPERTY( oObjectName, cPropertyName )

   IF VALTYPE( oObjectName ) = "O" .AND. ! EMPTY( cPropertyName ) .AND.;
       __objHasData( oObjectName, cPropertyName )
       RETURN EMPTY( __objDelData( oObjectName, cPropertyName ) )
   ENDIF
   RETURN .F.


FUNCTION FindAccelerator( oCtrl, lParam )
  Local nlen , i ,pos 
  
  nlen := LEN( oCtrl:aControls )
  FOR i = 1 to nLen
	   IF oCtrl:aControls[ i ]:classname = "HTAB"
	      IF ( pos := FindTabAccelerator( oCtrl:aControls[ i ], lParam ) ) > 0 .AND. ;
        	          oCtrl:aControls[ i ]:Pages[ pos ]:Enabled
	          oCtrl:aControls[ i ]:SetTab( pos )
	          RETURN oCtrl:aControls[ i ]
	      ENDIF    
	   ENDIF   
     IF LEN(oCtrl:aControls[ i ]:aControls ) > 0
         RETURN FindAccelerator( oCtrl:aControls[ i ], lParam)
	   ENDIF   
     IF __ObjHasMsg( oCtrl:aControls[ i ],"TITLE") .AND. VALTYPE( oCtrl:aControls[ i ]:title) = "C" .AND. ;
         ! oCtrl:aControls[ i ]:lHide .AND. IsWindowEnabled( oCtrl:aControls[ i ]:handle )
        IF ( pos := At( "&", oCtrl:aControls[ i ]:title ) ) > 0 .AND.  Upper( Chr( lParam)) ==  Upper( SubStr( oCtrl:aControls[ i ]:title, ++ pos, 1 ) )  
           RETURN oCtrl:aControls[ i ]
        ENDIF    
     ENDIF    
   NEXT
   RETURN Nil

FUNCTION GetBackColorParent( oCtrl, lSelf, lTransparent )
   Local bColor := GetSysColor( COLOR_BTNFACE ), hTheme
   local brush := nil
   
   DEFAULT lTransparent := .F.
   IF lSelf == Nil .OR. ! lSelf
      oCtrl := oCtrl:oParent
   ENDIF
   IF  oCtrl != Nil .AND. oCtrl:cLASSNAME = "HTAB" 
       IF Len( oCtrl:aPages ) > 0 .AND. oCtrl:Pages[ oCtrl:GETACTIVEPAGE() ]:bColor != Nil
          brush := oCtrl:Pages[ oCtrl:GetActivePage() ]:brush
       ELSEIF ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest  
          hTheme := hb_OpenThemeData( oCtrl:handle, "TAB" ) //oCtrl:oParent:WinClass ) 
          IF !EMPTY( hTheme )
             bColor := HWG_GETTHEMESYSCOLOR( hTheme, COLOR_WINDOW  )
             HB_CLOSETHEMEDATA( hTheme ) 
             brush := HBrush():Add( bColor )
          ELSE   
             brush := oCtrl:brush
          ENDIF 
       ELSE   
          brush := HBrush():Add( bColor )
       ENDIF   
    ELSEIF oCtrl:bColor != Nil  
       brush := oCtrl:brush
    ELSEIF oCtrl:brush = Nil .AND. lTransparent
        brush := HBrush():Add( bColor )   
    ENDIF
    Return brush 
