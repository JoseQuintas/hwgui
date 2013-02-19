/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  CONTROL_FIRST_ID   34000
#define TRANSPARENT 1

   //- HControl

CLASS HControl INHERIT HCustomWindow

   DATA   id
   DATA   tooltip
   DATA   lInit           INIT .F.
   DATA   lnoValid        INIT .F.
   DATA   lnoWhen         INIT .F.
   DATA   nGetSkip        INIT 0
   DATA   Anchor          INIT 0
   DATA   BackStyle       INIT OPAQUE
   DATA   lNoThemes       INIT .F.
   DATA   DisablebColor
   DATA   DisableBrush
   DATA   xControlSource
   DATA   xName           HIDDEN
   ACCESS Name            INLINE ::xName
   ASSIGN Name( cName )   INLINE ::AddName( cName )

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   METHOD Init()
   METHOD AddName( cName ) HIDDEN
   METHOD NewId()
   METHOD Show( nShow ) INLINE ::Super:Show( nShow ), iif( ::oParent:lGetSkipLostFocus, ;
      PostMessage(  GetActiveWindow() , WM_NEXTDLGCTL, iif( ::oParent:FindControl(, GetFocus() ) != NIL, 0, ::handle ), 1 ) , .T. )
   METHOD Hide() INLINE ( ::oParent:lGetSkipLostFocus := .F. , ::Super:Hide() )
   METHOD Disable() INLINE ( iif( SELFFOCUS( ::Handle ), SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, 0, 0 ) , ), EnableWindow( ::handle, .F. ) )
   METHOD Enable()
   METHOD IsEnabled() INLINE IsWindowEnabled( ::Handle )
   METHOD Enabled( lEnabled ) SETGET
   METHOD SetFont( oFont )
   METHOD SetFocus( lValid )
   METHOD GetText()     INLINE GetWindowText( ::handle )
   METHOD SetText( c )  INLINE SetWindowText( ::Handle, c ), ::title := c, ::Refresh()
   METHOD Refresh()     VIRTUAL
   METHOD onAnchor( x, y, w, h )
   METHOD SetToolTip( ctooltip )
   METHOD ControlSource( cControlSource ) SETGET
   METHOD DisableBackColor( DisableBColor ) SETGET
   METHOD END()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := iif( oWndParent == NIL, ::oDefaultParent, oWndParent )
   ::id      := iif( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), ;
      WS_VISIBLE + WS_CHILD )
   ::nLeft   := iif( nLeft = NIL , 0, nLeft )
   ::nTop    := iif( nTop = NIL , 0, nTop )
   ::nWidth  := iif( nWidth = NIL , 0, nWidth )
   ::nHeight := iif( nHeight = NIL , 0, nHeight )
   ::oFont   := oFont
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::Setcolor( tcolor, bColor )
   ::oParent:AddControl( Self )

   RETURN Self

METHOD NewId() CLASS HControl
   LOCAL oParent := ::oParent, i := 0, nId

   DO WHILE oParent != NIL
      nId := CONTROL_FIRST_ID + 1000 * i + Len( ::oParent:aControls )
      oParent := oParent:oParent
      i ++
   ENDDO
   IF AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. ;
            AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
         nId --
      ENDDO
   ENDIF

   RETURN nId

METHOD AddName( cName ) CLASS HControl
   LOCAL nPos

   IF !Empty( cName ) .AND. ValType( cName ) == "C" .AND. ::oParent != Nil .AND. ! "[" $ cName
      IF ( nPos :=  RAt( ":", cName ) ) > 0 .OR. ( nPos :=  RAt( ">", cName ) ) > 0
         cName := SubStr( cName, nPos + 1 )
      ENDIF
      ::xName := cName
      __objAddData( ::oParent, cName )
      ::oParent: & ( cName ) := Self
   ENDIF

   RETURN NIL

METHOD INIT() CLASS HControl
   LOCAL oForm := hwg_GetParentForm( Self )

   IF ! ::lInit
      ::oparent:lSuspendMsgsHandling := .T.
      IF Len( ::aControls ) = 0 .AND. ::winclass != "SysTabControl32" .AND. ValType( oForm ) != "N"
         AddToolTip( oForm:handle, ::handle, ::tooltip )
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF ::oFont != NIL .AND. ValType( ::oFont ) != "N" .AND. ::oParent != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF oForm != NIL  .AND. ValType( oForm ) != "N" .AND. oForm:oFont != NIL
         SetCtrlFont( ::oParent:handle, ::id, oForm:oFont:handle )
      ELSEIF ::oParent != NIL .AND. ::oParent:oFont != NIL
         SetCtrlFont( ::handle, ::id, ::oParent:oFont:handle )
      ENDIF
      IF oForm != NIL .AND. oForm:Type != WND_DLG_RESOURCE  .AND. ( ::nLeft + ::nTop + ::nWidth + ::nHeight  != 0 )
         // fix init position in FORM reduce  flickering
         SetWindowPos( ::Handle, NIL, ::nLeft, ::nTop, ::nWidth, ::nHeight, SWP_NOACTIVATE + SWP_NOSIZE + SWP_NOZORDER + SWP_NOOWNERZORDER + SWP_NOSENDCHANGING ) //+ SWP_DRAWFRAME )
      ENDIF
      IF ISBLOCK( ::bInit )
         ::oparent:lSuspendMsgsHandling := .T.
         Eval( ::bInit, Self )
         ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
      IF ::lnoThemes
         HWG_SETWINDOWTHEME( ::handle, 0 )
      ENDIF
      ::lInit := .T.
   ENDIF

   RETURN NIL

METHOD SetFocus( lValid ) CLASS HControl
   LOCAL lSuspend := ::oParent:lSuspendMsgsHandling

   IF ! IsWindowEnabled( ::Handle )
      ::oParent:lSuspendMsgsHandling  := .T.
      SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, 0, 0 )
      ::oParent:lSuspendMsgsHandling  := lSuspend
   ELSE
      ::oParent:lSuspendMsgsHandling  := ! Empty( lValid )
      IF hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
         SetFocus( ::handle )
      ELSE
         SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1 )
      ENDIF
      ::oParent:lSuspendMsgsHandling  := lSuspend
   ENDIF
   IF hwg_GetParentForm( Self ):Type < WND_DLG_RESOURCE
      hwg_GetParentForm( Self ):nFocus := ::Handle
   ENDIF

   RETURN NIL

METHOD Enable() CLASS HControl
   LOCAL lEnable := IsWindowEnabled( ::Handle ), nPos, nNext

   EnableWindow( ::handle, .T. )
   IF ::oParent:lGetSkipLostFocus .AND. ! lEnable .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( ::Handle ), WS_TABSTOP ) > 0
      nNext := Ascan( ::oParent:aControls, { | o | PtrtouLong( o:Handle ) = PtrtouLong( GetFocus() ) } )
      nPos  := Ascan( ::oParent:acontrols, { | o | PtrtouLong( o:Handle ) = PtrtouLong( ::handle ) } )
      IF nPos < nNext
         SendMessage(  GetActiveWindow() , WM_NEXTDLGCTL, ::handle, 1 )
      ENDIF
   ENDIF

   RETURN NIL

METHOD DisableBackColor( DisableBColor )

   IF DisableBColor != NIL
      ::DisableBColor := DisableBColor
      IF ::Disablebrush != NIL
         ::Disablebrush:Release()
      ENDIF
      ::Disablebrush := HBrush():Add( ::DisableBColor )
      IF ! ::IsEnabled() .AND. IsWindowVisible( ::Handle )
         InvalidateRect( ::Handle, 0 )
      ENDIF
   ENDIF

   RETURN ::DisableBColor

METHOD SetFont( oFont ) CLASS HControl

   IF oFont != NIL
      IF ValType( oFont ) = "O"
         ::oFont := oFont:SetFontStyle()
         SetWindowFont( ::Handle, ::oFont:Handle, .T. )
      ENDIF
   ELSEIF ::oParent:oFont != NIL
      SetWindowFont( ::handle, ::oParent:oFont:handle, .T. )
   ENDIF

   RETURN ::oFont

METHOD SetToolTip ( cToolTip ) CLASS HControl

   IF ValType( cToolTip ) = "C"  .AND. cToolTip != ::ToolTip
      SETTOOLTIPTITLE( hwg_GetparentForm( Self ):handle, ::handle, ctooltip )
      ::Tooltip := cToolTip
   ENDIF

   RETURN ::tooltip

METHOD Enabled( lEnabled ) CLASS HControl

   IF lEnabled != NIL
      IF lEnabled
         ::enable()
      ELSE
         ::disable()
      ENDIF
   ENDIF

   RETURN ::isEnabled()

METHOD ControlSource( cControlSource ) CLASS HControl
   LOCAL temp

   IF cControlSource != NIL .AND. !Empty( cControlSource ) .AND. __objHasData( Self, "BSETGETFIELD" )
      ::xControlSource := cControlSource
      temp := SubStr( cControlSource, At( "->", cControlSource ) + 2 )
      ::bSetGetField := iif( "->" $ cControlSource, FieldWBlock( temp, Select( SubStr( cControlSource, 1, At( "->", cControlSource ) - 1 ) ) ), FieldBlock( cControlSource ) )
   ENDIF

   RETURN ::xControlSource

METHOD END() CLASS HControl

   ::Super:END()
   IF ::tooltip != NIL
      DelToolTip( ::oParent:handle, ::handle )
      ::tooltip := NIL
   ENDIF

   RETURN NIL

METHOD onAnchor( x, y, w, h ) CLASS HControl
   LOCAL nAnchor, nXincRelative, nYincRelative, nXincAbsolute, nYincAbsolute
   LOCAL x1, y1, w1, h1, x9, y9, w9, h9
   LOCAL nCxv, nCyh

   nAnchor := ::anchor
   x9 := x1 := ::nLeft
   y9 := y1 := ::nTop
   w9 := w1 := ::nWidth
   h9 := h1 := ::nHeight
   // *- calculo relativo
   nXincRelative := Iif( x > 0, w / x, 1 ) 
   nYincRelative := Iif( y > 0, h / y, 1 )
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
      IF isWindowVisible( ::handle )
         nCxv := iif( HWG_BITAND( ::style, WS_VSCROLL ) != 0, GetSystemMetrics( SM_CXVSCROLL ) + 1 , 3 )
         nCyh := iif( HWG_BITAND( ::style, WS_HSCROLL ) != 0, GetSystemMetrics( SM_CYHSCROLL ) + 1 , 3 )
         IF ( x1 != x9 .OR. y1 != y9 ) .AND. x9 < ::oParent:nWidth
            InvalidateRect( ::oParent:handle, 1, Max( x9 - 1, 0 ), Max( y9 - 1, 0 ), ;
               x9 + w9 + nCxv, y9 + h9 + nCyh )
         ELSE
            IF w1 < w9
               InvalidateRect( ::oParent:handle, 1, x1 + w1 - nCxv - 1, Max( y1 - 2, 0 ), ;
                  x1 + w9 + 2 , y9 + h9 + nCxv + 1 )
            ENDIF
            IF h1 < h9
               InvalidateRect( ::oParent:handle, 1, Max( x1 - 5, 0 ) , y1 + h1 - nCyh - 1, ;
                  x1 + w9 + 2 , y1 + h9 + nCYh )
            ENDIF
         ENDIF
         IF ( ( x1 != x9 .OR. y1 != y9 ) .AND. ( ISBLOCK( ::bPaint ) .OR. ;
               x9 + w9 > ::oParent:nWidth ) ) .OR. ( ::backstyle = TRANSPARENT .AND. ;
               ( ::Title != NIL .AND. ! Empty( ::Title ) ) ) .OR. __ObjHasMsg( Self, "oImage" )
            IF __ObjHasMsg( Self, "oImage" ) .OR.  ::backstyle = TRANSPARENT //.OR. w9 != w1
               InvalidateRect( ::oParent:handle, 1, Max( x1 - 1, 0 ), Max( y1 - 1, 0 ), x1 + w1 + 1 , y1 + h1 + 1 )
            ELSE
               RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
            ENDIF
         ELSE
            IF Len( ::aControls ) = 0 .AND. ::Title != NIL
               InvalidateRect( ::handle, 0 )
            ENDIF
            IF w1 > w9
               InvalidateRect( ::oParent:handle, 1 , Max( x1 + w9 - nCxv - 1, 0 ) , ;
                  Max( y1 , 0 ) , x1 + w1 + nCxv  , y1 + h1 + 2  )
            ENDIF
            IF h1 > h9
               InvalidateRect( ::oParent:handle, 1 , Max( x1 , 0 ) , ;
                  Max( y1 + h9 - nCyh - 1 , 1 ) , x1 + w1 + 2 , y1 + h1 + nCyh )
            ENDIF
         ENDIF
         // redefine new position e new size
         ::Move( x1, y1, w1, h1,  HWG_BITAND( ::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN ) = 0 )
      ELSE
         ::Move( x1, y1, w1, h1, 0 )
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.

   // - HStatus

CLASS HStatus INHERIT HControl

   CLASS VAR winclass INIT "msctls_statusbar32"
   DATA aParts
   DATA nStatusHeight INIT 0
   DATA bDblClick
   DATA bRClick

   METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight )
   METHOD Activate()
   METHOD Init()
   METHOD Notify( lParam )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )
   METHOD SetTextPanel( nPart, cText, lRedraw )
   METHOD GetTextPanel( nPart )
   METHOD SetIconPanel( nPart, cIcon, nWidth, nHeight )
   METHOD StatusHeight( nHeight )
   METHOD Resize( xIncrSize )
   METHOD onAnchor( x, y, w, h )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight ) CLASS HStatus

   bSize  := iif( bSize != NIL, bSize, { | o, x, y | o:Move( 0, y - ::nStatusHeight, x, ::nStatusHeight ) } )
   nStyle := Hwg_BitOr( iif( nStyle == NIL, 0, nStyle ), ;
      WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + WS_CLIPSIBLINGS )
   ::Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint )
   ::nStatusHeight := iif( nHeight = NIL, ::nStatusHeight, nHeight )
   ::aParts    := aParts
   ::bDblClick := bDblClick
   ::bRClick   := bRClick

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HStatus

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatusWindow( ::oParent:handle, ::id )
      ::StatusHeight( ::nStatusHeight )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatus

   IF ! ::lInit
      IF ! Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
      ::Super:Init()
   ENDIF

   RETURN  NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )  CLASS hStatus

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aParts := aParts

   RETURN Self

METHOD Notify( lParam ) CLASS HStatus

   LOCAL nCode := GetNotifyCode( lParam )
   LOCAL nParts := GetNotifySBParts( lParam ) - 1

#define NM_DBLCLK    (NM_FIRST-3)
#define NM_RCLICK    (NM_FIRST-5)    // uses NMCLICK struct
#define NM_RDBLCLK   (NM_FIRST-6)

   DO CASE
   CASE nCode == NM_CLICK
   CASE nCode == NM_DBLCLK
      IF ::bdblClick != NIL
         Eval( ::bdblClick, Self, nParts )
      ENDIF
   CASE nCode == NM_RCLICK
      IF ::bRClick != NIL
         Eval( ::bRClick, Self, nParts )
      ENDIF
   ENDCASE

   RETURN NIL

METHOD StatusHeight( nHeight  ) CLASS HStatus
   LOCAL aCoors

   IF nHeight != NIL
      aCoors := GetWindowRect( ::handle )
      IF nHeight != 0
         IF ::lInit .AND. __ObjHasMsg( ::oParent, "AOFFSET" )
            ::oParent:aOffset[ 4 ] -= ( aCoors[ 4 ] - aCoors[ 2 ] )
         ENDIF
         SendMessage( ::handle, ;           // (HWND) handle to destination control
            SB_SETMINHEIGHT, nHeight, 0 )      // (UINT) message ID  // = (WPARAM)(int) minHeight;
         SendMessage( ::handle, WM_SIZE, 0, 0 )
         aCoors := GetWindowRect( ::handle )
      ENDIF
      ::nStatusHeight := ( aCoors[ 4 ] - aCoors[ 2 ] ) - 1
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         ::oParent:aOffset[ 4 ] += ( aCoors[ 4 ] - aCoors[ 2 ]  )
      ENDIF
   ENDIF

   RETURN ::nStatusHeight

METHOD GetTextPanel( nPart ) CLASS HStatus
   LOCAL ntxtLen, cText := ""

   ntxtLen := SendMessage( ::handle, SB_GETTEXTLENGTH, nPart - 1, 0 )
   cText := Replicate( Chr( 0 ), ntxtLen )
   SendMessage( ::handle, SB_GETTEXT, nPart - 1, @cText )

   RETURN cText

METHOD SetTextPanel( nPart, cText, lRedraw ) CLASS HStatus

   //WriteStatusWindow( ::handle,nPart-1,cText )
   SendMessage( ::handle, SB_SETTEXT, nPart - 1, cText )
   IF lRedraw != NIL .AND. lRedraw
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN NIL

METHOD SetIconPanel( nPart, cIcon, nWidth, nHeight ) CLASS HStatus
   LOCAL oIcon

   DEFAULT nWidth := 16
   DEFAULT nHeight := 16
   DEFAULT cIcon := ""

   IF HB_IsNumeric( cIcon ) .OR. At( ".", cIcon ) = 0
      //oIcon := HIcon():addResource( cIcon, nWidth, nHeight )
      oIcon := HIcon():addResource( cIcon, nWidth, nHeight, LR_LOADMAP3DCOLORS + ;
         iif( Empty( HWG_GETWINDOWTHEME( ::handle ) ), LR_LOADTRANSPARENT, 0 ) )
   ELSE
      oIcon := HIcon():addFile( cIcon, nWidth, nHeight )
   ENDIF
   IF ! Empty( oIcon )
      SendMessage( ::handle, SB_SETICON, nPart - 1, oIcon:handle )
   ENDIF

   RETURN NIL

METHOD Resize( xIncrSize ) CLASS HStatus
   LOCAL i

   IF ! Empty( ::aParts )
      FOR i := 1 TO Len( ::aParts )
         ::aParts[ i ] := Round( ::aParts[ i ] * xIncrSize, 0 )
      NEXT
      hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
   ENDIF

   RETURN NIL

METHOD onAnchor( x, y, w, h ) CLASS HStatus

   IF ::Super:onAnchor( x, y, w, h )
      ::Resize( Iif( x > 0, w / x, 1 ) )
   ENDIF

   RETURN .T.

   // - HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp )
   METHOD Activate()
   METHOD SetValue( value ) INLINE SetWindowText( ::handle, value )
   METHOD Init()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp ) CLASS HStatic

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

   IF lTransp != NIL .AND. lTransp
      ::BackStyle := TRANSPARENT
      ::extStyle := Hwg_BitOr( ::extStyle, WS_EX_TRANSPARENT )
   ENDIF

   ::Activate()

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp ) CLASS HStatic

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   // Enabling style for tooltips
   IF ValType( cTooltip ) == "C"
      ::style := SS_NOTIFY
   ENDIF

   IF lTransp != NIL .AND. lTransp
      ::extStyle := Hwg_BitOr( ::extStyle, WS_EX_TRANSPARENT )
   ENDIF

   RETURN Self

METHOD Activate() CLASS HStatic

   IF !Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
         ::extStyle )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatic

   IF !::lInit
      ::Super:init()
      IF ::title != NIL
         SetWindowText( ::handle, ::title )
      ENDIF
   ENDIF

   RETURN  NIL

   // - HButton

CLASS HButton INHERIT HControl

   CLASS VAR winclass INIT "BUTTON"

   DATA bClick

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
               tcolor, bColor )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
                    tcolor, bColor, cCaption )
   METHOD Init()
ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
            tcolor, bColor ) CLASS HButton

   nStyle := Hwg_BitOr( IIF( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON )

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
              IIF( nWidth  == NIL, 90, nWidth  ), ;
              IIF( nHeight == NIL, 30, nHeight ), ;
              oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   ::bClick  := bClick
   ::title   := cCaption
   ::Activate()

   IF bClick != NIL
      IF ::oParent:className == "HSTATUS"
         ::oParent:oParent:AddEvent( 0, ::id, bClick )
      ELSE
         ::oParent:AddEvent( 0, ::id, bClick )
      ENDIF
   ENDIF

RETURN Self

METHOD Activate() CLASS HButton
   IF !Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
RETURN NIL

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
                 cTooltip, tcolor, bColor, cCaption ) CLASS HButton

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title   := cCaption

   IF bClick != NIL
      ::oParent:AddEvent( 0, ::id, bClick )
   ENDIF
RETURN Self

METHOD Init() CLASS HButton

   ::super:Init()
   IF ::title != NIL
      SetWindowText( ::handle, ::title )
   ENDIF
RETURN  NIL

   // CLASS HGroup

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

   ::title := cCaption
   ::Activate()

   RETURN Self

METHOD Activate() CLASS HGroup

   IF !Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
         ::title )
      ::Init()
   ENDIF

   RETURN NIL

   // HLine

CLASS HLine INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA lVert
   DATA LineSlant
   DATA nBorder
   DATA oPenLight, oPenGray

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, bInit, tcolor, nHeight, cSlant, nBorder )
   METHOD Activate()
   METHOD Paint( lpDis )

ENDCLASS

METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, bInit, tcolor, nHeight, cSlant, nBorder ) CLASS HLine

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, , , , bInit, ;
      bSize, { | o, lp | o:Paint( lp ) } , , tcolor )

   ::title := ""
   ::lVert := iif( lVert == NIL, .F. , lVert )
   ::LineSlant := iif( Empty( cSlant ) .OR. ! cSlant $ "/\", "", cSlant )
   ::nBorder := iif( Empty( nBorder ), 1, nBorder )

   IF Empty( ::LineSlant )
      IF ::lVert
         ::nWidth  := ::nBorder + 1 //10
         ::nHeight := iif( nLength == NIL, 20, nLength )
      ELSE
         ::nWidth  := iif( nLength == NIL, 20, nLength )
         ::nHeight := ::nBorder + 1 //10
      ENDIF
      ::oPenLight := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      ::oPenGray  := HPen():Add( BS_SOLID, 1, GetSysColor( COLOR_3DSHADOW  ) )
   ELSE
      ::nWidth  := nLength
      ::nHeight := nHeight
      ::oPenLight := HPen():Add( BS_SOLID, ::nBorder, tColor )
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HLine

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
         ::nLeft, ::nTop, ::nWidth, ::nHeight )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Paint( lpdis ) CLASS HLine
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[ 3 ]
   LOCAL x1  := drawInfo[ 4 ], y1 := drawInfo[ 5 ]
   LOCAL x2  := drawInfo[ 6 ], y2 := drawInfo[ 7 ]

   SelectObject( hDC, ::oPenLight:handle )

   IF Empty( ::LineSlant )
      IF ::lVert
         DrawLine( hDC, x1 + 1, y1, x1 + 1, y2 )
      ELSE
         DrawLine( hDC, x1 , y1 + 1, x2, y1 + 1 )
      ENDIF
      SelectObject( hDC, ::oPenGray:handle )
      IF ::lVert
         DrawLine( hDC, x1, y1, x1, y2 )
      ELSE
         DrawLine( hDC, x1, y1, x2, y1 )
      ENDIF
   ELSE
      IF ( x2 - x1 ) <= ::nBorder
         DrawLine( hDC, x1, y1, x1, y2 )
      ELSEIF ( y2 - y1 ) <= ::nBorder
         DrawLine( hDC, x1, y1, x2, y1 )
      ELSEIF ::LineSlant == "/"
         DrawLine( hDC, x1  , y1 + y2 , x1 + x2 , y1  )
      ELSEIF ::LineSlant == "\"
         DrawLine( hDC, x1 , y1, x1 + x2 , y1 + y2 )
      ENDIF
   ENDIF

   RETURN NIL

   INIT PROCEDURE starttheme()
   INITTHEMELIB()

   EXIT PROCEDURE endtheme()
   ENDTHEMELIB()
