/*
 *$Id: hcwindow.prg,v 1.15 2008-02-16 02:30:57 mlacecilia Exp $
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

#define EVENTS_MESSAGES 1
#define EVENTS_ACTIONS  2

STATIC aCustomEvents := { ;
  { WM_NOTIFY, WM_PAINT, WM_CTLCOLORSTATIC, WM_CTLCOLOREDIT, WM_CTLCOLORBTN, ;
    WM_COMMAND, WM_DRAWITEM, WM_SIZE, WM_DESTROY }, ;
  { ;
    {|o,w,l| onNotify( o, w, l ) }                                 ,;
    {|o,w|   IIF( o:bPaint != NIL, Eval( o:bPaint, o, w ), -1 ) }  ,;
    {|o,w,l| onCtlColor( o, w, l ) }                               ,;
    {|o,w,l| onCtlColor( o, w, l ) }                               ,;
    {|o,w,l| onCtlColor( o, w, l ) }                               ,;
    {|o,w,l| onCommand( o, w ) }                                   ,;
    {|o,w,l| onDrawItem( o, w, l ) }                               ,;
    {|o,w,l| onSize( o, w, l ) }                                   ,;
    {|o|     onDestroy( o ) }                                       ;
  } ;
                        }

CLASS HObject
   // DATA classname
ENDCLASS

CLASS HCustomWindow INHERIT HObject

   CLASS VAR oDefaultParent SHARED

   DATA handle        INIT 0
   DATA oParent
   DATA title
   DATA type
   DATA nTop, nLeft, nWidth, nHeight
   DATA tcolor, bcolor, brush
   DATA style
   DATA extStyle      INIT 0
   DATA lHide         INIT .F.
   DATA oFont
   DATA aEvents       INIT {}
   DATA aNotify       INIT {}
   DATA aControls     INIT {}
   DATA bInit
   DATA bDestroy
   DATA bSize
   DATA bPaint
   DATA bGetFocus
   DATA bLostFocus
   DATA bScroll
   DATA bOther
   DATA cargo
   DATA HelpId        INIT 0
   DATA nHolder       INIT 0

   METHOD AddControl( oCtrl ) INLINE Aadd( ::aControls, oCtrl )
   METHOD DelControl( oCtrl )
   METHOD AddEvent( nEvent, nId, bAction, lNotify ) ;
                              INLINE Aadd( IIF( lNotify == NIL .OR. !lNotify, ;
                                                ::aEvents, ::aNotify ), ;
                                           { nEvent, nId, bAction } )
   METHOD FindControl( nId, nHandle )
   METHOD Hide()              INLINE (::lHide := .T., HideWindow( ::handle ) )
   METHOD Show()              INLINE (::lHide := .F., ShowWindow( ::handle ) )
   METHOD Move( x1, y1, width, height )
   METHOD onEvent( msg, wParam, lParam )
   METHOD End()
   METHOD RefreshCTRL( oControle )
   METHOD SetFocusCTRL( oControle )

ENDCLASS

METHOD FindControl( nId, nHandle ) CLASS HCustomWindow
LOCAL i := IIF( nId != NIL, Ascan( ::aControls, {|o| o:id == nId } ), ;
                            Ascan( ::aControls, {|o| o:handle == nHandle } ) )
RETURN IIF( i == 0, NIL, ::aControls[ i ] )

METHOD DelControl( oCtrl ) CLASS HCustomWindow
LOCAL h := oCtrl:handle, id := oCtrl:id
LOCAL i := Ascan( ::aControls, {|o| o:handle == h } )

   SendMessage( h, WM_CLOSE, 0, 0 )
   IF i != 0
      Adel( ::aControls, i )
      Asize( ::aControls, Len( ::aControls ) - 1 )
   ENDIF

   h := 0
   FOR i := Len( ::aEvents ) TO 1 STEP -1
       IF ::aEvents[ i, 2 ] == id
          Adel( ::aEvents, i )
          h ++
       ENDIF
   NEXT

   IF h > 0
      Asize( ::aEvents, Len( ::aEvents ) - h )
   ENDIF

   h := 0
   FOR i := Len( ::aNotify ) TO 1 STEP -1
       IF ::aNotify[ i, 2 ] == id
          Adel( ::aNotify, i )
          h ++
       ENDIF
   NEXT

   IF h > 0
      Asize( ::aNotify, Len( ::aNotify ) - h )
   ENDIF

RETURN NIL

METHOD Move( x1, y1, width, height )  CLASS HCustomWindow

   IF x1     != NIL
      ::nLeft   := x1
   ENDIF
   IF y1     != NIL
      ::nTop    := y1
   ENDIF
   IF width  != NIL
      ::nWidth  := width
   ENDIF
   IF height != NIL
      ::nHeight := height
   ENDIF
   MoveWindow( ::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight )

RETURN NIL

METHOD onEvent( msg, wParam, lParam )  CLASS HCustomWindow
LOCAL i

   // Writelog( "== "+::Classname()+Str(msg)+IIF(wParam!=NIL,Str(wParam),"NIL")+IIF(lParam!=NIL,Str(lParam),"NIL") )
    
   IF ( i := Ascan( aCustomEvents[ EVENTS_MESSAGES ], msg ) ) != 0      
      RETURN Eval( aCustomEvents[ EVENTS_ACTIONS, i ], Self, wParam, lParam )

   ELSEIF ::bOther != NIL

      RETURN Eval( ::bOther, Self, msg, wParam, lParam )

   ENDIF

RETURN -1

METHOD End()  CLASS HCustomWindow

   IF ::nHolder != 0

      ::nHolder := 0
      hwg_DecreaseHolders( ::handle ) // Self )

   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD RefreshCTRL( oControle, nSeek ) CLASS HCustomWindow
LOCAL nPos, n

   DEFAULT nSeek := 1

   IF nSeek == 1
      n := 1
   ELSE
      n := 3
   ENDIF

   nPos := Ascan( ::aControls, {|x| x[ n ] == oControle } )

   IF nPos >0
     ::aControls[ nPos, 2 ]:Refresh()
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
METHOD SetFocusCTRL( oControle ) CLASS HCustomWindow
LOCAL nPos

   nPos := Ascan( ::aControls, {|x| x[ 1 ] == oControle } )

   IF nPos >0
     ::aControls[ nPos, 2 ]:SetFocus()
   ENDIF

RETURN NIL

STATIC FUNCTION onNotify( oWnd, wParam, lParam )
LOCAL iItem, oCtrl := oWnd:FindControl( wParam ), nCode, res
Local n

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
         Return oCtrl:Notify( lParam )
      ELSE
         nCode := GetNotifyCode( lParam )
         IF nCode == EN_PROTECTED
            RETURN 1
         ELSEIF oWnd:aNotify != NIL .AND. ;
            ( iItem := Ascan( oWnd:aNotify, {|a| a[ 1 ] == nCode .AND. ;
                                                 a[ 2 ] == wParam } ) ) > 0
            IF ( res := Eval( oWnd:aNotify[ iItem, 3 ], oWnd, wParam ) ) != NIL
               RETURN res
            ENDIF
         ENDIF
      ENDIF
   ENDIF

RETURN -1

STATIC FUNCTION onDestroy( oWnd )
LOCAL aControls := oWnd:aControls
LOCAL i, nLen   := Len( aControls )

   FOR i := 1 TO nLen
       aControls[ i ]:End()
   NEXT
   oWnd:End()

RETURN 1

STATIC FUNCTION onCtlColor( oWnd, wParam, lParam )
LOCAL oCtrl := oWnd:FindControl( , lParam )

   IF oCtrl != NIL
      IF oCtrl:tcolor != NIL
         SetTextColor( wParam, oCtrl:tcolor )
      ENDIF

      IF oCtrl:bcolor != NIL
         SetBkColor( wParam, oCtrl:bcolor )
         RETURN oCtrl:brush:handle
      ENDIF
   ENDIF

RETURN -1

STATIC FUNCTION onDrawItem( oWnd, wParam, lParam )
LOCAL oCtrl

   IF wParam != 0 .AND. ( oCtrl := oWnd:FindControl( wParam ) ) != NIL .AND. ;
      oCtrl:bPaint != NIL

      Eval( oCtrl:bPaint, oCtrl, lParam )
      RETURN 1

   ENDIF

RETURN -1

STATIC FUNCTION onCommand( oWnd, wParam )
LOCAL iItem, iParHigh := HiWord( wParam ), iParLow := LoWord( wParam )

   IF oWnd:aEvents != NIL .AND. ;
      ( iItem := Ascan( oWnd:aEvents, {|a| a[ 1 ] == iParHigh .AND. ;
                                           a[ 2 ] == iParLow } ) ) > 0

      Eval( oWnd:aEvents[ iItem, 3 ], oWnd, iParLow )

   ENDIF

RETURN 1

STATIC FUNCTION onSize( oWnd,wParam,lParam )
LOCAL aControls := oWnd:aControls, nControls := Len( aControls )
LOCAL oItem, iCont

   #ifdef __XHARBOUR__
   FOR EACH oItem IN aControls
       IF oItem:bSize != NIL
          Eval( oItem:bSize, oItem, LoWord( lParam ), HiWord( lParam ) )
       ENDIF
   NEXT
   #else
   FOR iCont := 1 TO nControls
       IF aControls[ iCont ]:bSize != NIL
          Eval( aControls[ iCont ]:bSize, aControls[ iCont ], ;
                LoWord( lParam ), HiWord( lParam ) )
       ENDIF
   NEXT
   #endif

RETURN -1

FUNCTION onTrackScroll( oWnd, wParam, lParam )
LOCAL oCtrl := oWnd:FindControl( , lParam ), msg

   IF oCtrl != NIL
      msg := LoWord( wParam )
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
         Eval( oWnd:bScroll, oWnd, wParam, lParam )
         RETURN 0
      ENDIF
   ENDIF

RETURN -1

PROCEDURE HB_GT_DEFAULT_NUL()
RETURN
