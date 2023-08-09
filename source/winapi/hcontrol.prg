/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwgui.ch"
#include "hbclass.ch"

FUNCTION hwg_SetCtrlName( oCtrl, cName )

   LOCAL nPos

   IF !Empty( cName ) .AND. ValType( cName ) == "C" .AND. ! ( "[" $ cName )
      IF ( nPos :=  RAt( ":", cName ) ) > 0 .OR. ( nPos :=  RAt( ">", cName ) ) > 0
         cName := SubStr( cName, nPos + 1 )
      ENDIF
      oCtrl:objName := Upper( cName )
   ENDIF

   RETURN Nil

   //- HControl

CLASS HControl INHERIT HCustomWindow

   DATA   id
   DATA   tooltip
   DATA   lInit      INIT .F.
   DATA   Anchor     INIT 0

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   METHOD NewId()
   METHOD Init()

   METHOD Disable()
   METHOD Enable()
   METHOD Enabled( lEnabled ) SETGET
   METHOD Setfocus()    INLINE ( hwg_Sendmessage( ::oParent:handle, WM_NEXTDLGCTL, ;
      ::handle, 1 ), hwg_Setfocus( ::handle  ) )
   METHOD GetText()     INLINE hwg_Getwindowtext( ::handle )
   METHOD SetText( c )  INLINE hwg_Setwindowtext( ::Handle, ::title := c )
   METHOD End()
   METHOD onAnchor( x, y, w, h )
   METHOD SetTooltip( cText )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := iif( oWndParent == NIL, ::oDefaultParent, oWndParent )
   ::id      := iif( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), ;
      WS_VISIBLE + WS_CHILD )
   ::oFont   := oFont
   ::nLeft   := nLeft
   ::nTop    := nTop
   ::nWidth  := nWidth
   ::nHeight := nHeight
   ::bInit   := bInit
   IF ValType( bSize ) == "N"
      ::Anchor := bSize
   ELSE
      ::bSize   := bSize
   ENDIF
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::Setcolor( tcolor, bColor )

   ::oParent:AddControl( Self )

   RETURN Self

METHOD NewId() CLASS HControl

   LOCAL nId := ::oParent:nChildId ++

   RETURN nId

METHOD INIT() CLASS HControl

   IF !::lInit
      IF ::tooltip != Nil
         hwg_Addtooltip( ::handle, ::tooltip )
      ENDIF
      IF ::oFont != Nil
         hwg_Setctrlfont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF ::oParent:oFont != Nil
         ::oFont := ::oParent:oFont
         hwg_Setctrlfont( ::oParent:handle, ::id, ::oParent:oFont:handle )
      ENDIF
      IF HB_ISBLOCK( ::bInit )
         Eval( ::bInit, Self )
      ENDIF
      ::lInit := .T.
   ENDIF

   RETURN NIL

METHOD SetTooltip( cText ) CLASS HControl

   IF cText == NIL
      ::tooltip := ""
   ELSE
      ::tooltip := cText
   ENDIF
   hwg_Deltooltip( ::handle )
   IF .NOT. EMPTY(::tooltip)
      hwg_Addtooltip( ::handle, ::tooltip )
   ENDIF

   RETURN NIL

METHOD Disable() CLASS HControl

   hwg_Enablewindow( ::handle, .F. )

   RETURN NIL

METHOD Enable() CLASS HControl

   hwg_Enablewindow( ::handle, .T. )

   RETURN NIL

METHOD Enabled( lEnabled ) CLASS HControl

   IF lEnabled != Nil
      IF lEnabled
         hwg_Enablewindow( ::handle, .T. )
         RETURN .T.
      ELSE
         hwg_Enablewindow( ::handle, .F. )
         RETURN .F.
      ENDIF
   ENDIF

   RETURN hwg_Iswindowenabled( ::handle )

METHOD End() CLASS HControl

   ::Super:End()

   IF ::tooltip != NIL
      hwg_Deltooltip( ::handle )
      ::tooltip := NIL
   ENDIF

   RETURN NIL

METHOD onAnchor( x, y, w, h ) CLASS HControl

   LOCAL nAnchor, nXincRelative, nYincRelative, nXincAbsolute, nYincAbsolute
   LOCAL x1, y1, w1, h1, x9, y9, w9, h9

   // LOCAL nCxv, nCyh   && not used variables

   // hwg_writelog( "onAnchor "+::classname()+str(x)+"/"+str(y)+"/"+str(w)+"/"+str(h) )
   nAnchor := ::anchor
   x9 := x1 := ::nLeft
   y9 := y1 := ::nTop
   w9 := w1 := ::nWidth
   h9 := h1 := ::nHeight
   // *- calculo relativo
   nXincRelative := iif( x > 0, w / x, 1 )
   nYincRelative := iif( y > 0, h / y, 1 )
   // *- calculo ABSOLUTE
   nXincAbsolute := ( w - x )
   nYincAbsolute := ( h - y )
   IF nAnchor >= ANCHOR_VERTFIX
      // *- vertical fixed center
      nAnchor -= ANCHOR_VERTFIX
      y1 := y9 + Round( ( h - y ) * ( ( y9 + h9 / 2 ) / y ), 2 )
   ENDIF
   IF nAnchor >= ANCHOR_HORFIX
      // *- horizontal fixed center
      nAnchor -= ANCHOR_HORFIX
      x1 := x9 + Round( ( w - x ) * ( ( x9 + w9 / 2 ) / x ), 2 )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTREL
      // relative - RIGHT RELATIVE
      nAnchor -= ANCHOR_RIGHTREL
      x1 := w - Round( ( x - x9 - w9 ) * nXincRelative, 2 ) - w9
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMREL
      // relative - BOTTOM RELATIVE
      nAnchor -= ANCHOR_BOTTOMREL
      y1 := h - Round( ( y - y9 - h9 ) * nYincRelative, 2 ) - h9
   ENDIF
   IF nAnchor >= ANCHOR_LEFTREL
      // relative - LEFT RELATIVE
      nAnchor -= ANCHOR_LEFTREL
      IF x1 != x9
         w1 := x1 - ( Round( x9 * nXincRelative, 2 ) ) + w9
      ENDIF
      x1 := Round( x9 * nXincRelative, 2 )
   ENDIF
   IF nAnchor >= ANCHOR_TOPREL
      // relative  - TOP RELATIVE
      nAnchor -= ANCHOR_TOPREL
      IF y1 != y9
         h1 := y1 - ( Round( y9 * nYincRelative, 2 ) ) + h9
      ENDIF
      y1 := Round( y9 * nYincRelative, 2 )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTABS
      // Absolute - RIGHT ABSOLUTE
      nAnchor -= ANCHOR_RIGHTABS
      IF HWG_BITAND( ::Anchor, ANCHOR_LEFTREL ) != 0
         w1 := Int( nxIncAbsolute ) - ( x1 - x9 ) + w9
      ELSE
         IF x1 != x9
            w1 := x1 - ( x9 +  Int( nXincAbsolute ) ) + w9
         ENDIF
         x1 := x9 +  Int( nXincAbsolute )
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMABS
      // Absolute - BOTTOM ABSOLUTE
      nAnchor -= ANCHOR_BOTTOMABS
      IF HWG_BITAND( ::Anchor, ANCHOR_TOPREL ) != 0
         h1 := Int( nyIncAbsolute ) - ( y1 - y9 ) + h9
      ELSE
         IF y1 != y9
            h1 := y1 - ( y9 +  Int( nYincAbsolute ) ) + h9
         ENDIF
         y1 := y9 +  Int( nYincAbsolute )
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_LEFTABS
      // Absolute - LEFT ABSOLUTE
      nAnchor -= ANCHOR_LEFTABS
      IF x1 != x9
         w1 := x1 - x9 + w9
      ENDIF
      x1 := x9
   ENDIF
   IF nAnchor >= ANCHOR_TOPABS
      // Absolute - TOP ABSOLUTE
      IF y1 != y9
         h1 := y1 - y9 + h9
      ENDIF
      y1 := y9
   ENDIF
   // REDRAW AND INVALIDATE SCREEN
   IF ( x1 != X9 .OR. y1 != y9 .OR. w1 != w9 .OR. h1 != h9 )
      ::Move( x1, y1, w1, h1 )
      RETURN .T.
   ENDIF

   RETURN .F.

   //- HStatus

CLASS HStatus INHERIT HControl

   CLASS VAR winclass   INIT "msctls_statusbar32"

   DATA aParts

   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint )
   METHOD Activate()
   METHOD Init()
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )
   METHOD SetText( cText, nPart ) INLINE  hwg_WriteStatus( ::oParent, nPart, cText )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint ) CLASS HStatus

   bSize  := iif( bSize != NIL, bSize, { |o, x, y| o:Move( 0, y - 20, x, 20 ) } )
   nStyle := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), ;
      WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + ;
      WS_CLIPSIBLINGS )
   ::Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint )

   ::aParts  := aParts

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HStatus

   LOCAL aCoors

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatuswindow( ::oParent:handle, ::id )
      ::Init()
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         aCoors := hwg_Getwindowrect( ::handle )
         ::oParent:aOffset[ 4 ] := aCoors[ 4 ] - aCoors[ 2 ]
      ENDIF
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatus

   IF !::lInit
      ::Super:Init()
      IF !Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
   ENDIF

   RETURN  NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )  CLASS hStatus

   // Not used variables
   ( cCaption )
   ( lTransp )

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aparts := aparts

   RETURN Self

   //- HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   DATA   nStyleDraw

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp )
   METHOD Activate()
   METHOD Init()
   METHOD Paint( lpDis )
   METHOD SetText( c )
   METHOD Refresh()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp ) CLASS HStatic

   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
      ::nStyleDraw := iif( Empty( nStyle ), 0, nStyle )
      nStyle := SS_OWNERDRAW
      bPaint := { |o, p| o:paint( p ) }
   ENDIF

   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      IF nStyle == NIL
         nStyle := SS_NOTIFY
      ELSE
         nStyle := Hwg_BitOr( nStyle, SS_NOTIFY )
      ENDIF
   ENDIF

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption

   ::Activate()

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp ) CLASS HStatic

   // Variables not used
   ( cCaption )
   ( lTransp )

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      ::Style := SS_NOTIFY
   ENDIF

   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

   RETURN Self

METHOD Activate() CLASS HStatic

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
         ::extStyle )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatic

   IF !::lInit
      ::Super:init()
      IF ::Title != NIL
         hwg_Setwindowtext( ::handle, ::title )
      ENDIF
   ENDIF

   RETURN  NIL

METHOD Paint( lpDis ) CLASS HStatic

   LOCAL drawInfo := hwg_Getdrawiteminfo( lpDis )
   LOCAL hDC := drawInfo[ 3 ], x1 := drawInfo[ 4 ], y1 := drawInfo[ 5 ], x2 := drawInfo[ 6 ], y2 := drawInfo[ 7 ]

   IF ::oFont != Nil
      hwg_Selectobject( hDC, ::oFont:handle )
   ENDIF
   IF ::tcolor != NIL
      hwg_Settextcolor( hDC, ::tcolor )
   ENDIF

   hwg_Settransparentmode( hDC, .T. )
   hwg_Drawtext( hDC, ::title, x1, y1, x2, y2, ::nStyleDraw )
   hwg_Settransparentmode( hDC, .F. )

   RETURN NIL

METHOD SetText( c ) CLASS HStatic

   ::Super:SetText( c )
   IF hwg_bitand( ::extStyle, WS_EX_TRANSPARENT ) != 0
      hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight )
      hwg_Sendmessage( ::oParent:handle, WM_PAINT, 0, 0 )
   ENDIF

   RETURN NIL

METHOD Refresh() CLASS HStatic

   IF hwg_bitand( ::extStyle, WS_EX_TRANSPARENT ) != 0
      hwg_Invalidaterect( ::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight )
      hwg_Sendmessage( ::oParent:handle, WM_PAINT, 0, 0 )
   ELSE
      ::Super:Refresh()
   ENDIF

   RETURN NIL

   //- HButton

CLASS HButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"

   DATA bClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, cCaption )
   METHOD Init()
   METHOD GetText()     INLINE hwg_Getwindowtext( ::handle )
   METHOD SetText( c )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor ) CLASS HButton

   nStyle := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON + WS_TABSTOP )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
      iif( nWidth  == NIL, 90, nWidth  ), ;
      iif( nHeight == NIL, 30, nHeight ), ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   ::bClick  := bClick
   ::title   := cCaption
   ::Activate()

   IF ::id != IDOK .AND. ::id != IDCANCEL
      IF ::oParent:className == "HSTATUS"
         ::oParent:oParent:AddEvent( 0, ::id, { |o, id| onClick( o,id ) } )
      ELSE
         ::oParent:AddEvent( 0, ::id, { |o, id| onClick( o,id ) } )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate() CLASS HButton

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
         ::title )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption ) CLASS HButton

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor )
   ::bClick  := bClick
   ::title   := cCaption

   IF bClick != NIL
      ::oParent:AddEvent( 0, ::id, { |o, id| onClick( o,id ) } )
   ENDIF

   RETURN Self

METHOD Init() CLASS HButton

   ::super:init()
   IF ::Title != NIL
      hwg_Setwindowtext( ::handle, ::title )
   ENDIF

   RETURN  NIL

 METHOD SetText( c ) CLASS HButton

   hwg_Setwindowtext( ::Handle, ::title := c )
   hwg_Redrawwindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_UPDATENOW )

 RETURN NIL

   //- HGroup

CLASS HGroup INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor )
   METHOD Activate()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, bPaint, tcolor, bColor ) CLASS HGroup

   nStyle := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, , tcolor, bColor )

   ::title   := cCaption
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HGroup

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createbutton( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
         ::title )
      ::Init()
   ENDIF

   RETURN NIL

   // HLine

CLASS HLine INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   DATA lVert
   DATA oPenLight, oPenGray

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize )
   METHOD Activate()
   METHOD Paint( lpdis )

ENDCLASS

METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize ) CLASS HLine

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, , , , , ;
      bSize, { |o, lp| o:Paint( lp ) } )

   ::title := ""
   ::lVert := iif( lVert == NIL, .F. , lVert )
   IF ::lVert
      ::nWidth  := 10
      ::nHeight := iif( nLength == NIL, 20, nLength )
   ELSE
      ::nWidth  := iif( nLength == NIL, 20, nLength )
      ::nHeight := 10
   ENDIF

   ::oPenLight := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DHILIGHT ) )
   ::oPenGray  := HPen():Add( BS_SOLID, 1, hwg_Getsyscolor( COLOR_3DSHADOW  ) )

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HLine

   IF !Empty( ::oParent:handle )
      ::handle := hwg_Createstatic( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Paint( lpdis ) CLASS HLine

   LOCAL drawInfo := hwg_Getdrawiteminfo( lpdis )
   LOCAL hDC := drawInfo[3]
   LOCAL x1  := drawInfo[4], y1 := drawInfo[5]
   LOCAL x2  := drawInfo[6], y2 := drawInfo[7]

   hwg_Selectobject( hDC, ::oPenLight:handle )
   IF ::lVert
      // hwg_Drawedge( hDC,x1,y1,x1+2,y2,EDGE_SUNKEN,BF_RIGHT )
      hwg_Drawline( hDC, x1 + 1, y1, x1 + 1, y2 )
   ELSE
      // hwg_Drawedge( hDC,x1,y1,x2,y1+2,EDGE_SUNKEN,BF_RIGHT )
      hwg_Drawline( hDC, x1 , y1 + 1, x2, y1 + 1 )
   ENDIF

   hwg_Selectobject( hDC, ::oPenGray:handle )
   IF ::lVert
      hwg_Drawline( hDC, x1, y1, x1, y2 )
   ELSE
      hwg_Drawline( hDC, x1, y1, x2, y1 )
   ENDIF

   RETURN NIL

STATIC FUNCTION onClick( oParent, id )

   LOCAL oCtrl := oParent:FindControl( id )

   IF !Empty( oCtrl ) .AND. !Empty( oCtrl:bClick )
      Eval( oCtrl:bClick, oCtrl )
   ENDIF

   RETURN .T.

#define  STATE_NORMAL    0
#define  STATE_PRESSED   1
#define  STATE_MOVER     2
#define  STATE_UNPRESS   3

CLASS HBoard INHERIT HControl

   DATA winclass    INIT "HBOARD"
   DATA lKeybEvents INIT .F.
   DATA lMouseOver  INIT .F.
   DATA oInFocus
   DATA aDrawn      INIT {}

   METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor, lKeyb )

   METHOD Activate()
   METHOD onEvent( msg, wParam, lParam )
   METHOD Init()
   METHOD Paint( hDC )

ENDCLASS

METHOD New( oWndParent, nId, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor, lKeyb ) CLASS HBoard

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor )

   IF !Empty( lKeyb )
      ::lKeybEvents := .T.
   ENDIF
   hwg_RegBoard()
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HBoard

   IF !Empty( ::oParent:handle )
      ::handle := hwg_CreateBoard( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, ::lKeybEvents )
      ::Init()
   ENDIF

   RETURN Nil

METHOD onEvent( msg, wParam, lParam )  CLASS HBoard

   LOCAL nRes, o, nPosX, nPosY

   IF ::bOther != Nil
      IF ( nRes := Eval( ::bOther, Self, msg, wParam, lParam ) ) == 0
         RETURN -1
      ELSEIF nRes == 1
         RETURN 1
      ENDIF
   ENDIF

   IF msg == WM_MOUSEMOVE
      IF !::lMouseOver .AND. hwg_TrackMouseEvent( ::handle )
         ::lMouseOver := .T.
      ENDIF
      IF ( o := HDrawn():GetByPos( nPosX := hwg_Loword( lParam ), ;
         nPosY := hwg_Hiword( lParam ), Self ) ) != Nil
         o:SetState( STATE_MOVER, nPosX, nPosY )
         o:onMouseMove( nPosX, nPosY )
      ELSE
         HDrawn():GetByState( STATE_MOVER, ::aDrawn, {|o|o:SetState(STATE_NORMAL,nPosX,nPosY)}, .T. )
      ENDIF

   ELSEIF msg == WM_PAINT
      ::Paint()

   ELSEIF msg == WM_MOUSELEAVE
      ::lMouseOver := .F.
      nPosX := hwg_Loword( lParam )
      nPosY := hwg_Hiword( lParam )
      HDrawn():GetByState( STATE_PRESSED, ::aDrawn, {|o|o:SetState(STATE_NORMAL,nPosX,nPosY)}, .T. )
      HDrawn():GetByState( STATE_MOVER, ::aDrawn, {|o|o:SetState(STATE_NORMAL,nPosX,nPosY)}, .T. )

   ELSEIF msg == WM_LBUTTONDOWN
      IF ( o := HDrawn():GetByPos( nPosX := hwg_Loword( lParam ), ;
         nPosY := hwg_Hiword( lParam ), Self ) ) != Nil
         o:SetState( STATE_PRESSED, nPosX, nPosY )
         o:onButtonDown( msg, nPosX, nPosY )
      ENDIF

   ELSEIF msg == WM_RBUTTONDOWN
      IF ( o := HDrawn():GetByPos( nPosX := hwg_Loword( lParam ), ;
         nPosY := hwg_Hiword( lParam ), Self ) ) != Nil
         o:onButtonDown( msg, nPosX, nPosY )
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      IF !Empty( o := HDrawn():GetByState( STATE_PRESSED, ::aDrawn ) )
         o:SetState( 3, hwg_Loword( lParam ), hwg_Hiword( lParam ) )
         o:onButtonUp( nPosX, nPosY )
      ENDIF

   ELSEIF msg == WM_GETDLGCODE
      IF ::lKeybEvents
         RETURN DLGC_WANTALLKEYS
      ENDIF

   ELSEIF msg == WM_KEYDOWN .OR. msg == WM_CHAR
      IF !Empty( ::oInFocus )
         ::oInFocus:onKey( msg, wParam, lParam )
      ENDIF

   ELSE
      RETURN ::Super:onEvent( msg, wParam, lParam )

   ENDIF

   RETURN -1

METHOD Init() CLASS HBoard

   IF ! ::lInit
      ::nHolder := 1
      hwg_Setwindowobject( ::handle, Self )
      ::Super:Init()
   ENDIF

   RETURN Nil

METHOD Paint( hDC ) CLASS HBoard

   LOCAL i
   LOCAL pps, l := .F.

   IF hDC == Nil
      pps := hwg_Definepaintstru()
      hDC := hwg_Beginpaint( ::handle, pps )
      l := .T.
   ENDIF

   IF !Empty( ::bPaint )
      IF Eval( ::bPaint, Self, hDC ) == 0
         RETURN Nil
      ENDIF
   ENDIF

   FOR i := 1 TO Len( ::aDrawn )
      ::aDrawn[i]:Paint( hDC )
   NEXT

   IF l
      hwg_Endpaint( ::handle, pps )
   ENDIF

   RETURN Nil
