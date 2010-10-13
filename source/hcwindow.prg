/*
 *$Id: hcwindow.prg,v 1.70 2010-10-13 16:11:10 lfbasso Exp $
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

#define TRANSPARENT 1
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
   DATA nVScrollPos   INIT 0 
   DATA nHScrollPos   INIT 0 
   DATA rect
   DATA nScrollBars INIT -1
   DATA lAutoScroll INIT .T.
   DATA nHorzInc
   DATA nVertInc
   DATA nVscrollMax
   DATA nHscrollMax

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
   METHOD ResetScrollbars()
   METHOD SetupScrollbars()
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

METHOD Move( x1, y1, width, height, nRePaint )  CLASS HCustomWindow

   x1     := IIF( x1     = NIL, ::nLeft, x1 )
   y1     := IIF( y1     = NIL, ::nTop, y1 )
   width  := IIF( width  = NIL, ::nWidth, width )
   height := IIF( height = NIL, ::nHeight, height )
   IF nRePaint = Nil
      MoveWindow( ::handle, x1, y1, Width, Height  )
   ELSE
      MoveWindow( ::handle, x1, y1, Width, Height, nRePaint )
   ENDIF

   //IF x1 != NIL
      ::nLeft := x1
   //ENDIF
   //IF y1 != NIL
      ::nTop  := y1
   //ENDIF
   //IF width != NIL
      ::nWidth := width
   //ENDIF
   //IF height != NIL
      ::nHeight := height
   //ENDIF
   //MoveWindow( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

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


METHOD Refresh( lAll, oCtrl ) CLASS HCustomWindow
  Local nlen , i, hCtrl := GetFocus()
   oCtrl := IIF( oCtrl = Nil, Self, oCtrl )
   nlen := LEN( oCtrl:aControls )

   IF IsWindowVisible( ::Handle )
      FOR i = 1 to nLen
         IF ! oCtrl:aControls[ i ]:lHide .AND. ::handle != hCtrl
            IF  __ObjHasMethod(oCtrl:aControls[ i ], "REFRESH" )  .AND. ( ! EMPTY( lAll ) .OR. ;
                  ASCAN( ::GetList, {| o | o:Handle = oCtrl:aControls[ i ]:handle } ) > 0 )
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
   
   IF oCtrl = Nil .OR.;
       ASCAN( oCtrl:aControls, {| o | __ObjHasMsg( o,"ANCHOR") .AND. o:Anchor > 0 } ) = 0  
      RETURN .F. 
   ENDIF    

   nlen := Len( oCtrl:aControls )
   FOR i = 1 TO nlen
      IF __ObjHasMsg( oCtrl:aControls[ i ], "ANCHOR" ) .AND. oCtrl:aControls[ i ]:anchor > 0 
         x1 := oCtrl:aControls[ i ]:nWidth
         y1 := oCtrl:aControls[ i ]:nHeight
         oCtrl:aControls[ i ]:onAnchor( x, y, w, h )
         IF Len( oCtrl:aControls[ i ]:aControls ) > 0
            ::Anchor( oCtrl:aControls[ i ], x1, y1, oCtrl:aControls[ i ]:nWidth, oCtrl:aControls[ i ]:nHeight )
            //::Anchor( oCtrl:aControls[ i ], x, y, oCtrl:nWidth, oCtrl:nHeight )
         ENDIF
      ENDIF
   NEXT
   RETURN .T.

METHOD ScrollHV( oForm, msg,wParam,lParam ) CLASS HCustomWindow
   Local nDelta, nSBCode , nPos, nInc, nInc2 := 0
    
   HB_SYMBOL_UNUSED(lParam)

   nSBCode := loword(wParam)
   IF msg == WM_MOUSEWHEEL
      nSBCode = IIF( HIWORD( wParam ) > 32768, HIWORD( wParam ) - 65535, HIWORD( wParam ) )
      nSBCode = IIF( nSBCode < 0, SB_LINEDOWN, SB_LINEUP )
   ENDIF
   IF ( msg = WM_VSCROLL ) .OR.msg == WM_MOUSEWHEEL
     // Handle vertical scrollbar messages
     #ifndef __XHARBOUR__
      DO CASE 
         Case nSBCode = SB_TOP
             nInc := - oForm:nVscrollPos
         Case nSBCode = SB_BOTTOM
             nInc := oForm:nVscrollMax - oForm:nVscrollPos
         Case nSBCode = SB_LINEUP
             nInc := - Int( oForm:nVertInc * 0.05 + 0.49)
         Case nSBCode = SB_LINEDOWN
             nInc := Int( oForm:nVertInc * 0.05 + 0.49)
         Case nSBCode = SB_PAGEUP
             nInc := min( - 1, - oForm:nVertInc )
         Case nSBCode  = SB_PAGEDOWN
            nInc := max( 1, oForm:nVertInc)
         Case nSBCode  = SB_THUMBTRACK
            nPos := hiword( wParam ) 
            nInc2 := IIF( nPos > oForm:nVscrollPos, 0.125, - 0.125 )
            nInc := nPos - oForm:nVscrollPos
         OTHERWISE
            nInc := 0
       ENDCASE       
     #else
      Switch (nSBCode)
         Case SB_TOP
             nInc := - oForm:nVscrollPos; EXIT
         Case SB_BOTTOM
             nInc := oForm:nVscrollMax - oForm:nVscrollPos;  EXIT
         Case SB_LINEUP
             nInc := - Int( oForm:nVertInc * 0.05 + 0.49);    EXIT
         Case SB_LINEDOWN
             nInc := Int( oForm:nVertInc * 0.05 + 0.49); EXIT
         Case SB_PAGEUP
             nInc := min( - 1, - oForm:nVertInc );  EXIT
         Case SB_PAGEDOWN
            nInc := max( 1, oForm:nVertInc);   EXIT
         Case SB_THUMBTRACK
            nPos := hiword( wParam ) 
            nInc2 := IIF( nPos > oForm:nVscrollPos, 0.125, - 0.125 )
            nInc := nPos - oForm:nVscrollPos ; EXIT
         Default
            nInc := 0
      END       
      #endif
      nInc := max( - oForm:nVscrollPos, min( nInc, oForm:nVscrollMax - oForm:nVscrollPos))
      oForm:nVscrollPos += nInc
      nDelta := - VERT_PTS * ( nInc +  nInc2 )
      ScrollWindow( oForm:handle, 0, nDelta ) //, Nil, NIL )
      SetScrollPos( oForm:Handle, SB_VERT, oForm:nVscrollPos, .T. )

   ELSEIF ( msg = WM_HSCROLL ) //.OR. msg == WM_MOUSEWHEEL 
    // Handle vertical scrollbar messages
      #ifndef __XHARBOUR__
       DO CASE 
         Case nSBCode = SB_TOP
             nInc := - oForm:nHscrollPos
         Case nSBCode = SB_BOTTOM
             nInc := oForm:nHscrollMax - oForm:nHscrollPos
         Case nSBCode = SB_LINEUP
             nInc := -1
         Case nSBCode = SB_LINEDOWN
             nInc := 1
         Case nSBCode = SB_PAGEUP
             nInc := - HORZ_PTS
         Case nSBCode = SB_PAGEDOWN
            nInc := HORZ_PTS
         Case nSBCode = SB_THUMBTRACK
            nPos := hiword( wParam )
            nInc := nPos - oForm:nHscrollPos
         OTHERWISE
            nInc := 0
       ENDCASE       
      #else 
      Switch (nSBCode)
         Case SB_TOP
             nInc := - oForm:nHscrollPos; EXIT
         Case SB_BOTTOM
             nInc := oForm:nHscrollMax - oForm:nHscrollPos;  EXIT
         Case SB_LINEUP
             nInc := -1;    EXIT
         Case SB_LINEDOWN
             nInc := 1; EXIT
         Case SB_PAGEUP
             nInc := - HORZ_PTS;  EXIT
         Case SB_PAGEDOWN
            nInc := HORZ_PTS;   EXIT
         Case SB_THUMBTRACK
            nPos := hiword( wParam )
            nInc := nPos - oForm:nHscrollPos; EXIT
         Default
            nInc := 0
      END       
      #endif
      nInc := max( - oForm:nHscrollPos, min( nInc, oForm:nHscrollMax - oForm:nHscrollPos ) )
      oForm:nHscrollPos += nInc
      nDelta := - HORZ_PTS * nInc
      ScrollWindow( oForm:handle, nDelta, 0 ) //, Nil, NIL )
      SetScrollPos( oForm:Handle, SB_HORZ, oForm:nHscrollPos, .T. )
   ENDIF 	
   RETURN Nil


METHOD SetupScrollbars() CLASS HCustomWindow
   LOCAL tempRect, nwMax, nhMax , aMenu
   LOCAL nHorzInc := 0, nVertInc := 0
   
   tempRect := GetClientRect( ::handle )
   aMenu := IIF( __objHasData( Self, "MENU" ), ::menu, Nil )
    // Calculate how many scrolling increments for the client area
   IF ::Type = WND_MDICHILD //.AND. ::aRectSave != Nil
      nwMax := max( ::ncurWidth, tempRect[ 3 ] ) //::maxWidth
      nhMax := max( ::ncurHeight , tempRect[ 4 ] ) //::maxHeight
      ::nHorzInc := INT( ( nwMax - tempRect[ 3 ] ) / HORZ_PTS )
      ::nVertInc := INT( ( nhMax - tempRect[ 4 ] ) / VERT_PTS )
   ELSE
      nwMax := max( ::ncurWidth, ::Rect[ 3 ] )
      nhMax := max( ::ncurHeight, ::Rect[ 4 ] )
      ::nHorzInc := ( nwMax - tempRect[ 3 ] ) / HORZ_PTS - HORZ_PTS
      ::nVertInc := ( nhMax - tempRect[ 4 ] ) / VERT_PTS - ;
        IIF( amenu != Nil, GetSystemMetrics( SM_CYMENU ), 0 )  // MENU
   ENDIF
    // Set the vertical and horizontal scrolling info
   IF ::nScrollBars = 0 .OR. ::nScrollBars = 2   
      ::nHscrollMax := max( 0, ::nHorzInc )
      IF ::nHscrollMax < HORZ_PTS / 2
         ScrollWindow( ::Handle, ::nHscrollPos * HORZ_PTS, 0 ) 
      ENDIF
      ::nHscrollPos := min( ::nHscrollPos, ::nHscrollMax )
      SetScrollPos( ::handle, SB_HORZ, ::nHscrollPos, .T. )
      SetScrollInfo( ::Handle, SB_HORZ, 1, 0,  ::nHScrollMax / HORZ_PTS , ::nHscrollMax )
   ENDIF
   IF ::nScrollBars = 1 .OR. ::nScrollBars = 2
      ::nVscrollMax := max( 0, ::nVertInc ) 
      IF ::nVscrollMax < VERT_PTS / 2
         ScrollWindow( ::Handle, 0, ::nVscrollPos * VERT_PTS ) 
      ENDIF
      ::nVscrollPos := min( ::nVscrollPos, ::nVscrollMax ) 
      SetScrollPos( ::handle, SB_VERT, ::nVscrollPos, .T. )
      SetScrollInfo( ::Handle, SB_VERT, 1, 0, ::nVScrollMax / VERT_PTS , ::nVscrollMax )
   ENDIF
   RETURN Nil  

METHOD ResetScrollbars() CLASS HCustomWindow    
    // Reset our window scrolling information
   Local lMaximized := GetWindowPlacement( ::handle ) == SW_MAXIMIZE
   IF lMaximized 
      ScrollWindow( ::Handle, ::nHscrollPos * HORZ_PTS, 0 ) 
      ScrollWindow( ::Handle, 0, ::nVscrollPos * VERT_PTS ) 
      ::nHscrollPos := 0
      ::nVscrollPos := 0
   ENDIF
   
   IF ::nScrollBars = 0 .OR. ::nScrollBars = 2
      ScrollWindow( ::Handle, 0 * HORZ_PTS, 0 ) 
      SetScrollPos( ::Handle, SB_HORZ, 0, .T. )
   ENDIF   
   IF ::nScrollBars = 1 .OR. ::nScrollBars = 2
      ScrollWindow( ::Handle, 0, 0 * VERT_PTS )   
      SetScrollPos( ::Handle, SB_VERT, 0, .T. )
   ENDIF
   RETURN Nil 
/*
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
*/
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

   IF  oCtrl != Nil .AND. VALTYPE( oCtrl ) != "N"
      IF oCtrl:tcolor != NIL
         SetTextColor( wParam, oCtrl:tcolor )
      ENDIF
      SetBkMode( wParam, oCtrl:backstyle )
      IF !  oCtrl:IsEnabled() .AND. oCtrl:Disablebrush != Nil
         SetBkColor( wParam, oCtrl:DisablebColor ) 
         RETURN oCtrl:disablebrush:handle
      ELSEIF oCtrl:bcolor != NIL  .AND. oCtrl:BackStyle = OPAQUE
         SetBkColor( wParam, oCtrl:bcolor )
         IF oCtrl:brush != Nil
            RETURN oCtrl:brush:handle
         ELSEIF oCtrl:oParent:brush != Nil
            RETURN oCtrl:oParent:brush:handle
         ENDIF
      ELSEIF oCtrl:BackStyle = TRANSPARENT
         IF ( oCtrl:classname $ "HCHECKBUTTON" .AND. (  ! oCtrl:lnoThemes .AND. ( ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest ) ) ) .OR.;
            ( oCtrl:classname $ "HGROUP*HRADIOGROUP*HRADIOBUTTON" .AND. ! oCtrl:lnoThemes ) 
				    RETURN GetBackColorParent( oCtrl, , .T. ):handle
				 ENDIF 
         IF __ObjHasMsg( oCtrl, "PAINT" ) .OR. oCtrl:winclass = "BUTTON"				 
				    RETURN GetStockObject( NULL_BRUSH )
				 ENDIF   
				 RETURN GetBackColorParent( oCtrl, , .T. ):handle
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onDrawItem( oWnd, wParam, lParam )
   LOCAL oCtrl
   IF ! EMPTY( wParam ) .AND. ( oCtrl := oWnd:FindControl( wParam ) ) != NIL .AND. ;
                 VALTYPE( oCtrl ) != "N"  .AND. oCtrl:bPaint != NIL
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
         oWnd:GetParentForm():nFocus := lParam
      ENDIF
      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )
   ENDIF

   RETURN 1

STATIC FUNCTION onSize( oWnd, wParam, lParam )
   LOCAL aControls := oWnd:aControls, nControls := Len( aControls )
   LOCAL oItem, iCont, nw1, nh1, aCoors

   //HB_SYMBOL_UNUSED( wParam )

   nw1 := oWnd:nWidth
   nh1 := oWnd:nHeight
   IF wParam != 1  //SIZE_MINIMIZED
      aCoors := GetWindowRect( oWnd:handle )
      oWnd:nWidth := aCoors[ 3 ] - aCoors[ 1 ]
      oWnd:nHeight := aCoors[ 4 ] - aCoors[ 2 ]
   ENDIF
   IF oWnd:nScrollBars > - 1 .AND. oWnd:lAutoScroll
      onMove( oWnd )    
      oWnd:ResetScrollbars()
      oWnd:SetupScrollbars()
   ENDIF

   IF !EMPTY( oWnd:Type) .AND. oWnd:Type = WND_MDI  .AND. !EMPTY( oWnd:Screen )
      oWnd:Anchor( oWnd:Screen, nw1, nh1, oWnd:nWidth, oWnd:nHeight )
   ENDIF
   IF ! EMPTY( oWnd:Type)
      oWnd:Anchor( oWnd, nw1, nh1, oWnd:nWidth, oWnd:nHeight )
   ENDIF

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

FUNCTION ProcOkCancel( oCtrl, nKey, lForce )
   Local oWin := oCtrl:GetParentForm()
   Local iParHigh := IIF( nKey = VK_RETURN, IDOK, IDCANCEL )

   lForce := ! Empty( lForce )
   IF ( oWin:Type >= WND_DLG_RESOURCE .AND. ! lForce  ) .OR. ( nKey != VK_RETURN .AND. nKey != VK_ESCAPE )
      Return .F.
   ENDIF
   IF iParHigh == IDOK
      IF ( oCtrl := oWin:FindControl( IDOK ) ) != Nil .AND. oCtrl:IsEnabled()    
         oCtrl:SetFocus()
  	     oWin:lResult := .T.
  	     IF lForce
	       ELSEIF oCtrl:bClick != Nil .AND. ! lForce
	          SendMessage( oCtrl:oParent:handle, WM_COMMAND, makewparam( oCtrl:id, BN_CLICKED ), oCtrl:handle )
	       ELSEIF oWin:lExitOnEnter
            oWin:close()  
         ENDIF   
         RETURN .T.
      ENDIF
   ELSEIF iParHigh == IDCANCEL
      IF ( oCtrl := oWin:FindControl( IDCANCEL ) ) != Nil .AND. oCtrl:IsEnabled() 
         oCtrl:SetFocus()
         oWin:lResult := .F.
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
   Local brush := nil
   
   DEFAULT lTransparent := .F.
   IF lSelf == Nil .OR. ! lSelf
      oCtrl := oCtrl:oParent
   ENDIF
   IF  oCtrl != Nil .AND. oCtrl:Classname = "HTAB" 
       brush := HBrush():Add( bColor )
       IF Len( oCtrl:aPages ) > 0 .AND. oCtrl:Pages[ oCtrl:GETACTIVEPAGE() ]:bColor != Nil
          brush := oCtrl:Pages[ oCtrl:GetActivePage() ]:brush
       ELSEIF ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest  
          hTheme := hb_OpenThemeData( oCtrl:handle, "TAB" ) //oCtrl:oParent:WinClass ) 
          IF !EMPTY( hTheme )
             bColor := HWG_GETTHEMESYSCOLOR( hTheme, COLOR_WINDOW  )
             HB_CLOSETHEMEDATA( hTheme ) 
             brush := HBrush():Add( bColor )
          ENDIF 
       ENDIF   
    ELSEIF oCtrl:bColor != Nil  
       brush := oCtrl:brush
    ELSEIF oCtrl:brush = Nil .AND. lTransparent
       brush := HBrush():Add( bColor )   
    ENDIF
    Return brush 
