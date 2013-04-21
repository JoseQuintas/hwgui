/*
 *$Id$
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

static aCustomEvents := { ;
      { WM_NOTIFY,WM_PAINT,WM_CTLCOLORSTATIC,WM_CTLCOLOREDIT,WM_CTLCOLORBTN, ;
        WM_COMMAND,WM_DRAWITEM,WM_SIZE,WM_DESTROY }, ;
      { ;
        {|o,w,l|onNotify(o,w,l)},                        ;
        {|o,w|Iif(o:bPaint!=Nil,Eval(o:bPaint,o,w),-1)}, ;
        {|o,w,l|onCtlColor(o,w,l)},                      ;
        {|o,w,l|onCtlColor(o,w,l)},                      ;
        {|o,w,l|onCtlColor(o,w,l)},                      ;
        {|o,w,l|onCommand(o,w)},                         ;
        {|o,w,l|onDrawItem(o,w,l)},                      ;
        {|o,w,l|onSize(o,w,l)},                          ;
        {|o|onDestroy(o)}                                ;
      } ;
                        }

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
   DATA HelpId   INIT 0  
   
   METHOD AddControl( oCtrl ) INLINE Aadd( ::aControls,oCtrl )
   METHOD DelControl( oCtrl )
   METHOD AddEvent( nEvent,nId,bAction,lNotify ) ;
      INLINE Aadd( Iif( lNotify==Nil.OR.!lNotify,::aEvents,::aNotify ),{nEvent,nId,bAction} )
   METHOD FindControl( nId,nHandle )
   METHOD Hide() INLINE (::lHide:=.T.,hwg_Hidewindow(::handle))
   METHOD Show() INLINE (::lHide:=.F.,hwg_Showwindow(::handle))
   METHOD Move( x1,y1,width,height )
   METHOD onEvent( msg, wParam, lParam )
   METHOD End()
   METHOD Anchor( oCtrl, x, y, w, h )

ENDCLASS

METHOD FindControl( nId,nHandle ) CLASS HCustomWindow
Local i := Iif( nId!=Nil,Ascan( ::aControls,{|o|o:id==nId} ), ;
                       Ascan( ::aControls,{|o|o:handle==nHandle} ) )
Return Iif( i==0,Nil,::aControls[i] )

METHOD DelControl( oCtrl ) CLASS HCustomWindow
Local id := oCtrl:id, h
Local i := Ascan( ::aControls,{|o|o==oCtrl} )

   IF oCtrl:ClassName() == "HPANEL"
      hwg_Destroypanel( oCtrl:handle )
   ELSE
      hwg_DestroyWindow( oCtrl:handle )
   ENDIF
   IF i != 0
      Adel( ::aControls,i )
      Asize( ::aControls,Len(::aControls)-1 )
   ENDIF
   h := 0
   FOR i := Len( ::aEvents ) TO 1 STEP -1
      IF ::aEvents[i,2] == id
         Adel( ::aEvents,i )
         h ++
      ENDIF
   NEXT
   IF h > 0
      Asize( ::aEvents,Len(::aEvents)-h )
   ENDIF
   h := 0
   FOR i := Len( ::aNotify ) TO 1 STEP -1
      IF ::aNotify[i,2] == id
         Adel( ::aNotify,i )
         h ++
      ENDIF
   NEXT
   IF h > 0
      Asize( ::aNotify,Len(::aNotify)-h )
   ENDIF
Return Nil

METHOD Move( x1,y1,width,height )  CLASS HCustomWindow

   IF x1 != Nil
      ::nLeft := x1
   ENDIF
   IF y1 != Nil
      ::nTop  := y1
   ENDIF
   IF width != Nil
      ::nWidth := width
   ENDIF
   IF height != Nil
      ::nHeight := height
   ENDIF
   hwg_Movewindow( ::handle,::nLeft,::nTop,::nWidth,::nHeight )

Return Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HCustomWindow
Local i

   // hwg_WriteLog( "== "+::Classname()+Str(msg)+Iif(wParam!=Nil,Str(wParam),"Nil")+Iif(lParam!=Nil,Str(lParam),"Nil") )
   IF ( i := Ascan( aCustomEvents[1],msg ) ) != 0
      Return Eval( aCustomEvents[2,i], Self, wParam, lParam )
   ELSEIF ::bOther != Nil
      Return Eval( ::bOther, Self, msg, wParam, lParam )
   ENDIF

Return 0

METHOD Anchor( oCtrl, x, y, w, h ) CLASS HCustomWindow
   LOCAL nlen , i, x1, y1
   nlen := Len( oCtrl:aControls )
   FOR i = 1 TO nlen
      IF __ObjHasMsg( oCtrl:aControls[ i ], "ANCHOR" ) .AND. oCtrl:aControls[ i ]:anchor > 0
         x1 := oCtrl:aControls[ i ]:nWidth
         y1 := oCtrl:aControls[ i ]:nHeight
         oCtrl:aControls[ i ]:onAnchor( x, y, w, h )
         IF Len( oCtrl:aControls[ i ]:aControls ) > 0
            //::Anchor( oCtrl:aControls[ i ], x1, y1, oCtrl:nWidth, oCtrl:nHeight )
            ::Anchor( oCtrl:aControls[ i ], x, y, oCtrl:nWidth, oCtrl:nHeight )
         ENDIF
      ENDIF
   NEXT
   RETURN .T.


METHOD End()  CLASS HCustomWindow
Local aControls := ::aControls
Local i, nLen := Len( aControls )

   FOR i := 1 TO nLen
       aControls[i]:End()
   NEXT

   hwg_ReleaseObject( ::handle )

Return Nil

Static Function onNotify( oWnd,wParam,lParam )
Local iItem, oCtrl := oWnd:FindControl( wParam ), nCode, res, handle, oItem

   IF oCtrl != Nil
      IF oCtrl:ClassName() == "HTAB"
         DO CASE
         CASE ( nCode := hwg_Getnotifycode( lParam ) ) == TCN_SELCHANGE
            IF oCtrl != Nil .AND. oCtrl:bChange != Nil
               Eval( oCtrl:bChange, oCtrl, hwg_Getcurrenttab( oCtrl:handle ) )
            ENDIF
         CASE ( nCode := hwg_Getnotifycode( lParam ) ) == TCN_CLICK
              if oCtrl != Nil .AND. oCtrl:bAction != nil
                 Eval( oCtrl:bAction, oCtrl, hwg_Getcurrenttab( oCtrl:handle ) )
              endif
         CASE ( nCode := hwg_Getnotifycode( lParam ) ) == TCN_SETFOCUS
              if oCtrl != Nil .AND. oCtrl:bGetFocus != nil
                 Eval( oCtrl:bGetFocus, oCtrl, hwg_Getcurrenttab( oCtrl:handle ) )
              endif
         CASE ( nCode := hwg_Getnotifycode( lParam ) ) == TCN_KILLFOCUS
              if oCtrl != Nil .AND. oCtrl:bLostFocus != nil
                 Eval( oCtrl:bLostFocus, oCtrl, hwg_Getcurrenttab( oCtrl:handle ))
              endif
        ENDCASE
      ELSEIF oCtrl:ClassName() == "HQHTM"
         Return oCtrl:Notify( oWnd,lParam )
      ELSEIF oCtrl:ClassName() == "HTREE"
         Return hwg_Treenotify( oCtrl,lParam )
      ELSEIF oCtrl:ClassName() == "HGRID"         
         Return hwg_Listviewnotify( oCtrl,lParam )               
      ELSE
         nCode := hwg_Getnotifycode( lParam )
         // hwg_WriteLog("Code: "+str(nCode))
         IF nCode == EN_PROTECTED
            Return 1
         ELSEIF oWnd:aNotify != Nil .AND. ;
            ( iItem := Ascan( oWnd:aNotify, {|a|a[1]==nCode.and.a[2]==wParam} ) ) > 0
            IF ( res := Eval( oWnd:aNotify[ iItem,3 ],oWnd,wParam ) ) != Nil
               Return res
            ENDIF
         ENDIF
      ENDIF
   ENDIF

Return 0

Static Function onDestroy( oWnd )
   oWnd:End()

Return 0

Static Function onCtlColor( oWnd,wParam,lParam )
Local oCtrl  := oWnd:FindControl(,lParam)

   IF oCtrl != Nil
      IF oCtrl:tcolor != Nil
         hwg_Settextcolor( wParam, oCtrl:tcolor )
      ENDIF
      IF oCtrl:bcolor != Nil
         hwg_Setbkcolor( wParam, oCtrl:bcolor )
         Return oCtrl:brush:handle
      ENDIF
   ENDIF

Return -1

Static Function onDrawItem( oWnd,wParam,lParam )
Local oCtrl

   IF wParam != 0 .AND. ( oCtrl := oWnd:FindControl( wParam ) ) != Nil .AND. ;
         oCtrl:bPaint != Nil
      Eval( oCtrl:bPaint, oCtrl, lParam )
      Return 1
   ENDIF

Return 0

Static Function onCommand( oWnd,wParam )
Local iItem, iParHigh := hwg_Hiword( wParam ), iParLow := hwg_Loword( wParam )

   IF oWnd:aEvents != Nil .AND. ;
      ( iItem := Ascan( oWnd:aEvents, {|a|a[1]==iParHigh.and.a[2]==iParLow} ) ) > 0
      Eval( oWnd:aEvents[ iItem,3 ],oWnd,iParLow )
   ENDIF

Return 1

Static Function onSize( oWnd,wParam,lParam )
Local aControls := oWnd:aControls, nControls := Len( aControls )
Local oItem, iCont

   #ifdef __XHARBOUR__
   FOR each oItem in aControls
       IF oItem:bSize != Nil
          Eval( oItem:bSize, ;
           oItem, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
       ENDIF
   NEXT
   #else
   FOR iCont := 1 TO nControls
       IF aControls[iCont]:bSize != Nil
          Eval( aControls[iCont]:bSize, ;
           aControls[iCont], hwg_Loword( lParam ), hwg_Hiword( lParam ) )
       ENDIF
   NEXT
   #endif

Return 0

Function hwg_onTrackScroll( oWnd,wParam,lParam )

Local oCtrl := oWnd:FindControl( , lParam ), msg

   IF oCtrl != Nil
      msg := hwg_Loword (wParam)
      IF msg == TB_ENDTRACK
         IF ISBLOCK( oCtrl:bChange )
            Eval( oCtrl:bChange,oCtrl )
            Return 0
         ENDIF
      ELSEIF msg == TB_THUMBTRACK .OR. msg == TB_PAGEUP .OR. msg == TB_PAGEDOWN
         IF ISBLOCK( oCtrl:bThumbDrag )
            Eval( oCtrl:bThumbDrag,oCtrl )
            Return 0
         ENDIF
      ENDIF
   ENDIF

Return 0

INIT PROCEDURE HWGINIT

   hwg_ErrSys()
   RETURN

