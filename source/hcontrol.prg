/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HStatus, HStatic, HButton, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su

 *
 * ButtonEx class
 *
 * Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
 * www - http://sites.uol.com.br/culikr/

*/

#translate :hBitmap       => :m_csbitmaps\[ 1 \]
#translate :dwWidth       => :m_csbitmaps\[ 2 \]
#translate :dwHeight      => :m_csbitmaps\[ 3 \]
#translate :hMask         => :m_csbitmaps\[ 4 \]
#translate :crTransparent => :m_csbitmaps\[ 5 \]

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  CONTROL_FIRST_ID   34000
#define TRANSPARENT 1
#define BTNST_COLOR_BK_IN     1            // Background color when mouse is INside
#define BTNST_COLOR_FG_IN     2            // Text color when mouse is INside
#define BTNST_COLOR_BK_OUT    3             // Background color when mouse is OUTside
#define BTNST_COLOR_FG_OUT    4             // Text color when mouse is OUTside
#define BTNST_COLOR_BK_FOCUS  5           // Background color when the button is focused
#define BTNST_COLOR_FG_FOCUS  6            // Text color when the button is focused
#define BTNST_MAX_COLORS      6
#define WM_SYSCOLORCHANGE               0x0015
#define BS_TYPEMASK SS_TYPEMASK
#define OFS_X  10 // distance from left/right side to beginning/end of text

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
   // METHOD SetColor( tcolor, bColor, lRepaint )
   METHOD NewId()
   METHOD Show( nShow ) INLINE ::Super:Show( nShow ), IIF( ::oParent:lGetSkipLostFocus,;
         PostMessage(  GetActiveWindow() , WM_NEXTDLGCTL, IIF( ::oParent:FindControl(, GetFocus() ) != NIL, 0, ::handle ), 1 ) , .T. )
   METHOD Hide() INLINE ( ::oParent:lGetSkipLostFocus := .F., ::Super:Hide() )
   // METHOD Disable()     INLINE EnableWindow( ::handle, .F. )
   METHOD Disable() INLINE ( IIF( SELFFOCUS( ::Handle ), SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, 0, 0 ) , ), EnableWindow( ::handle, .F. ) )
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
   METHOD FontBold( lTrue ) SETGET
   METHOD FontItalic( lTrue ) SETGET
   METHOD FontUnderline( lTrue ) SETGET
   METHOD END()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
      bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := IIf( oWndParent == NIL, ::oDefaultParent, oWndParent )
   ::id      := IIf( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
         WS_VISIBLE + WS_CHILD )
   ::nLeft   := IIF( nLeft = NIL ,0, nLeft )
   ::nTop    := IIF( nTop = NIL ,0, nTop )
   ::nWidth  := IIF( nWidth = NIL ,0, nWidth )
   ::nHeight := IIF( nHeight = NIL ,0, nHeight )
   ::oFont   := oFont
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::SetColor( tcolor, bColor )
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
   
   IF !EMPTY( cName ) .AND. VALTYPE( cName) == "C" .AND. ::oParent != Nil .AND. ! "[" $ cName
      IF ( nPos :=  RAt( ":", cName ) ) > 0 .OR. ( nPos :=  RAt( ">", cName ) ) > 0
         cName := SubStr( cName, nPos + 1 )
      ENDIF
      ::xName := cName
      __objAddData( ::oParent, cName )
      ::oParent: & ( cName ) := Self
   ENDIF

   RETURN NIL

METHOD INIT() CLASS HControl
   LOCAL oForm := ::GetParentForm( )

   IF ! ::lInit
      //IF ::tooltip != NIL
      //   AddToolTip( ::oParent:handle, ::handle, ::tooltip )
      //ENDIF
      ::oparent:lSuspendMsgsHandling := .T.
      IF Len( ::aControls) = 0 .AND. ::winclass != "SysTabControl32" .AND. VALTYPE( oForm ) != "N"
         AddToolTip( oForm:handle, ::handle, ::tooltip )
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF ::oFont != NIL .AND. VALTYPE( ::oFont ) != "N" .AND. ::oParent != NIL
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF oForm != NIL  .AND. VALTYPE( oForm ) != "N" .AND. oForm:oFont != NIL
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

/* moved to HCWINDOW
METHOD SetColor( tcolor, bColor, lRepaint ) CLASS HControl
   */

METHOD SetFocus( lValid ) CLASS HControl
   LOCAL lSuspend := ::oParent:lSuspendMsgsHandling

   IF ! IsWindowEnabled( ::Handle )
      ::oParent:lSuspendMsgsHandling  := .T.
      // GetSkip( ::oParent, ::handle, , 1 )
      SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, 0, 0 )
      ::oParent:lSuspendMsgsHandling  := lSuspend
   ELSE
      ::oParent:lSuspendMsgsHandling  := ! Empty( lValid )
      IF ::GetParentForm():Type < WND_DLG_RESOURCE
         SetFocus( ::handle )
      ELSE
         SendMessage( GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1 )
      ENDIF
      ::oParent:lSuspendMsgsHandling  := lSuspend
   ENDIF
   IF ::GetParentForm():Type < WND_DLG_RESOURCE
      ::GetParentForm():nFocus := ::Handle
   ENDIF

   RETURN NIL

METHOD Enable() CLASS HControl
   LOCAL lEnable := IsWindowEnabled( ::Handle ), nPos, nNext

   EnableWindow( ::handle, .T. )
   IF ::oParent:lGetSkipLostFocus .AND. ! lEnable .AND. Hwg_BitaND( HWG_GETWINDOWSTYLE( ::Handle ), WS_TABSTOP ) > 0
      nNext := Ascan( ::oParent:aControls, { | o | PtrtouLong( o:Handle ) = PtrtouLong( GetFocus() ) } )
      nPos  := Ascan( ::oParent:acontrols, { | o | PtrtouLong( o:Handle ) = PtrtouLong( ::handle ) } )
      IF nPos < nNext
         SendMessage(  GetActiveWindow() , WM_NEXTDLGCTL,::handle, 1)
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
      IF VALTYPE( oFont ) = "O"
         ::oFont := oFont:SetFontStyle()
         SetWindowFont( ::Handle, ::oFont:Handle, .T. )
      ENDIF
   ELSEIF ::oParent:oFont != NIL
      SetWindowFont( ::handle, ::oParent:oFont:handle, .T. )
   ENDIF

   RETURN ::oFont

METHOD FontBold( lTrue ) CLASS HControl
   LOCAL oFont

   IF ::oFont = NIL
      IF ::GetParentForm() != NIL .AND. ::GetParentForm():oFont != NIL
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont = NIL .AND. lTrue = NIL
         RETURN .T.
      ENDIF
      ::oFont := IIF( oFont != NIL, HFont():Add( oFont:name, oFont:Width,,,,,), HFont():Add( "", 0, , IIF( !Empty( lTrue ), FW_BOLD, FW_REGULAR ), ,,) )
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle( lTrue )
      SendMessage( ::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM( 0, 1 ) )
      RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT )
   ENDIF

   RETURN ::oFont:weight == FW_BOLD

METHOD FontItalic( lTrue ) CLASS HControl
   LOCAL oFont

   IF ::oFont = NIL
      IF ::GetParentForm() != NIL .AND. ::GetParentForm():oFont != NIL
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont = NIL .AND. lTrue = NIL
         RETURN .F.
      ENDIF
      ::oFont := IIF( oFont != NIL, HFont():Add( oFont:name, oFont:width,,,,IIF( lTrue, 1, 0 ) ), HFont():Add( "", 0 ,,,, IIF( lTrue, 1, 0 ) ) )
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle( ,, lTrue )
      SendMessage( ::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM( 0, 1 ) )
      RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT )
   ENDIF

   RETURN ::oFont:Italic = 1

METHOD FontUnderline( lTrue ) CLASS HControl
   LOCAL oFont

   IF ::oFont = NIL
      IF ::GetParentForm() != NIL .AND. ::GetParentForm():oFont != NIL
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont = NIL .AND. lTrue = NIL
         RETURN .F.
      ENDIF
      ::oFont := IIF( oFont != NIL, HFont():Add( oFont:name, oFont:width,,,,, IIF( lTrue, 1, 0 ) ), HFont():Add( "", 0, ,,,, IIF( lTrue, 1, 0) ) )
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle( ,,,lTrue )
      SendMessage( ::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM( 0, 1 ) )
      RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT )
   ENDIF

   RETURN ::oFont:Underline = 1

METHOD SetToolTip ( cToolTip ) CLASS HControl

   IF VALTYPE( cToolTip ) = "C"  .AND. cToolTip != ::ToolTip
      SETTOOLTIPTITLE( ::GetparentForm():handle, ::handle, ctooltip )
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

  IF cControlSource != NIL .AND. !EMPTY( cControlSource ) .AND. __objHasData( Self, "BSETGETFIELD")
     ::xControlSource := cControlSource
     temp := SUBSTR( cControlSource, AT( "->", cControlSource ) + 2 )
     ::bSetGetField := IIF( "->" $ cControlSource, FieldWBlock( temp, SELECT( SUBSTR( cControlSource, 1, AT( "->", cControlSource ) - 1 ))),FieldBlock( cControlSource ) )
  ENDIF

  RETURN ::xControlSource

METHOD END() CLASS HControl

   Super:END()
   IF ::tooltip != NIL
      DelToolTip( ::oParent:handle, ::handle )
      ::tooltip := NIL
   ENDIF

   RETURN NIL

METHOD onAnchor( x, y, w, h ) CLASS HControl
   LOCAL nAnchor, nXincRelative, nYincRelative, nXincAbsolute, nYincAbsolute
   LOCAL x1, y1, w1, h1, x9, y9, w9, h9
   LOCAL nCxv := IIF( HWG_BITAND( ::style, WS_VSCROLL ) != 0, GetSystemMetrics( SM_CXVSCROLL ) + 1 , 3 )
   LOCAL nCyh := IIF( HWG_BITAND( ::style, WS_HSCROLL ) != 0, GetSystemMetrics( SM_CYHSCROLL ) + 1 , 3 )

   nAnchor := ::anchor
   x9 := ::nLeft
   y9 := ::nTop
   w9 := ::nWidth  //- IIF( ::winclass = "EDIT" .AND. __ObjHasMsg( Self,"hwndUpDown" ), GetClientRect( ::hwndUpDown)[ 3 ], 0 )
   h9 := ::nHeight
   x1 := ::nLeft
   y1 := ::nTop
   w1 := ::nWidth  //- IIF( ::winclass = "EDIT" .AND. __ObjHasMsg( Self,"hwndUpDown" ), GetClientRect( ::hwndUpDown)[ 3 ], 0 )
   h1 := ::nHeight
   // *- calculo relativo
   IF x > 0
      nXincRelative := w / x
   ENDIF
   IF y > 0
      nYincRelative := h / y
   ENDIF
   // *- calculo ABSOLUTE
   nXincAbsolute := ( w - x )
   nYincAbsolute := ( h - y )
   IF nAnchor >= ANCHOR_VERTFIX
      // *- vertical fixed center
      nAnchor := nAnchor - ANCHOR_VERTFIX
      y1 := y9 + Round( ( h - y ) * ( ( y9 + h9 / 2 ) / y ), 2 )
   ENDIF
   IF nAnchor >= ANCHOR_HORFIX
      // *- horizontal fixed center
      nAnchor := nAnchor - ANCHOR_HORFIX
      x1 := x9 + Round( ( w - x ) * ( ( x9 + w9 / 2 ) / x ), 2 )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTREL
      // relative - RIGHT RELATIVE
      nAnchor := nAnchor - ANCHOR_RIGHTREL
      x1 := w - Round( ( x - x9 - w9 ) * nXincRelative, 2 ) - w9
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMREL
      // relative - BOTTOM RELATIVE
      nAnchor := nAnchor - ANCHOR_BOTTOMREL
      y1 := h - Round( ( y - y9 - h9 ) * nYincRelative, 2 ) - h9
   ENDIF
   IF nAnchor >= ANCHOR_LEFTREL
      // relative - LEFT RELATIVE
      nAnchor := nAnchor - ANCHOR_LEFTREL
      IF x1 != x9
         w1 := x1 - ( Round( x9 * nXincRelative, 2 ) ) + w9
      ENDIF
      x1 := Round( x9 * nXincRelative, 2 )
   ENDIF
   IF nAnchor >= ANCHOR_TOPREL
      // relative  - TOP RELATIVE
      nAnchor := nAnchor - ANCHOR_TOPREL
      IF y1 != y9
         h1 := y1 - ( Round( y9 * nYincRelative, 2 ) ) + h9
      ENDIF
      y1 := Round( y9 * nYincRelative, 2 )
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTABS
      // Absolute - RIGHT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_RIGHTABS
      IF HWG_BITAND( ::Anchor, ANCHOR_LEFTREL ) != 0
         w1 := INT( nxIncAbsolute ) - ( x1 - x9 ) + w9
      ELSE
         IF x1 != x9
            w1 := x1 - ( x9 +  INT( nXincAbsolute ) ) + w9
         ENDIF
         x1 := x9 +  INT( nXincAbsolute )
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMABS
      // Absolute - BOTTOM ABSOLUTE
      nAnchor := nAnchor - ANCHOR_BOTTOMABS
      IF HWG_BITAND( ::Anchor, ANCHOR_TOPREL ) != 0
         h1 := INT( nyIncAbsolute ) - ( y1 - y9 ) + h9
      ELSE
         IF y1 != y9
            h1 := y1 - ( y9 +  Int( nYincAbsolute ) ) + h9
         ENDIF
         y1 := y9 +  Int( nYincAbsolute )
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_LEFTABS
      // Absolute - LEFT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_LEFTABS
      IF x1 != x9
         w1 := x1 - x9 + w9
      ENDIF
      x1 := x9
   ENDIF
   IF nAnchor >= ANCHOR_TOPABS
      // Absolute - TOP ABSOLUTE
      // nAnchor := nAnchor - 1
      IF y1 != y9
         h1 := y1 - y9 + h9
      ENDIF
      y1 := y9
   ENDIF
   // REDRAW AND INVALIDATE SCREEN
   IF ( x1 != X9 .OR. y1 != y9 .OR. w1 != w9 .OR. h1 != h9 )
      IF isWindowVisible( ::handle )
         IF ( x1 != x9 .or. y1 != y9 ) .AND. x9 < ::oParent:nWidth
            InvalidateRect( ::oParent:handle, 1, MAX( x9 - 1, 0 ), MAX( y9 - 1, 0 ), ;
                  x9 + w9 + nCxv, y9 + h9 + nCyh )
         ELSE
            IF w1 < w9
               InvalidateRect( ::oParent:handle, 1, x1 + w1 - nCxv - 1, MAX( y1 - 2, 0 ), ;
                     x1 + w9 + 2 , y9 + h9 + nCxv + 1)
            ENDIF
            IF h1 < h9
               InvalidateRect( ::oParent:handle, 1, MAX( x1 - 5, 0 ) , y1 + h1 - nCyh - 1, ;
                     x1 + w9 + 2 , y1 + h9 + nCYh )
            ENDIF
         ENDIF
         // * ::Move( x1, y1, w1, h1,  HWG_BITAND( ::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN ) = 0 )
         IF ( ( x1 != x9 .OR. y1 != y9 ) .AND. ( ISBLOCK( ::bPaint ) .OR. ;
               x9 + w9 > ::oParent:nWidth ) ) .OR. ( ::backstyle = TRANSPARENT .AND. ;
               ( ::Title != NIL .AND. ! Empty( ::Title ) ) ) .OR. __ObjHasMsg( Self,"oImage" )
            IF __ObjHasMsg( Self, "oImage" ) .OR.  ::backstyle = TRANSPARENT //.OR. w9 != w1
               InvalidateRect( ::oParent:handle, 1, MAX( x1 - 1, 0 ), MAX( y1 - 1, 0 ), x1 + w1 + 1 , y1 + h1 + 1 )
            ELSE
               RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
            ENDIF
         ELSE
            IF LEN( ::aControls ) = 0 .AND. ::Title != NIL
               InvalidateRect( ::handle, 0 )
            ENDIF
            IF w1 > w9
               InvalidateRect( ::oParent:handle, 1 , MAX( x1 + w9 - nCxv - 1, 0 ) ,;
                     MAX( y1 , 0 ) , x1 + w1 + nCxv  , y1 + h1 + 2  )
            ENDIF
            IF h1 > h9
               InvalidateRect( ::oParent:handle, 1 , MAX( x1 , 0 ) , ;
                     MAX( y1 + h9 - nCyh - 1 , 1 ) , x1 + w1 + 2 , y1 + h1 + nCyh )
            ENDIF
         ENDIF
         // redefine new position e new size
         ::Move( x1, y1, w1, h1,  HWG_BITAND( ::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN ) = 0 )

         IF ( ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32" )
            ::Resize( nXincRelative, w1 != w9, h1 != h9 )
         ENDIF
      ELSE
         ::Move( x1, y1, w1, h1, 0 )
         IF ( ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32" )
            ::Resize( nXincRelative, w1 != w9, h1 != h9 )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

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

ENDCLASS

METHOD New( oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight ) CLASS HStatus

   bSize  := IIf( bSize != NIL, bSize, { | o, x, y | o:Move( 0, y - ::nStatusHeight, x, ::nStatusHeight ) } )
   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
         WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + WS_CLIPSIBLINGS )
   Super:New( oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint )
   //::nHeight   := nHeight
   ::nStatusHeight := IIF( nHeight = NIL, ::nStatusHeight, nHeight )
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
      /*
      IF __ObjHasMsg( ::oParent, "AOFFSET" )
         aCoors := GetWindowRect( ::handle )
         ::oParent:aOffset[ 4 ] := aCoors[ 4 ] - aCoors[ 2 ]
      ENDIF
      */
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatus

   IF ! ::lInit
      IF ! Empty( ::aParts )
         hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
      ENDIF
      Super:Init()
   ENDIF

   RETURN  NIL

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts )  CLASS hStatus

   HB_SYMBOL_UNUSED( cCaption )
   HB_SYMBOL_UNUSED( lTransp )

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint, ctooltip, tcolor, bcolor )
   HWG_InitCommonControlsEx()
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aParts := aParts

   RETURN Self

METHOD Notify( lParam ) CLASS HStatus

   LOCAL nCode := GetNotifyCode( lParam )
   LOCAL nParts := GetNotifySBParts( lParam ) - 1

   //#define NM_FIRST     ( 0- 0)
   //#define NM_CLICK     (NM_FIRST-2)    // uses NMCLICK struct
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
         SendMessage( ::handle,;           // (HWND) handle to destination control
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
            IIF( Empty( HWG_GETWINDOWTHEME( ::handle ) ), LR_LOADTRANSPARENT, 0 ) )
   ELSE
      oIcon := HIcon():addFile( cIcon, nWidth, nHeight )
   ENDIF
   IF ! EMPTY( oIcon )
      SendMessage( ::handle, SB_SETICON, nPart - 1, oIcon:handle )
   ENDIF

   RETURN NIL

METHOD Resize( xIncrSize ) CLASS HStatus
   LOCAL i

   IF ! Empty( ::aParts )
      FOR i := 1 TO LEN( ::aParts )
         ::aParts[ i ] := ROUND( ::aParts[ i ] * xIncrSize, 0 )
      NEXT
      hwg_InitStatus( ::oParent:handle, ::handle, Len( ::aParts ), ::aParts )
   ENDIF

   RETURN NIL

// - HStatic

CLASS HStatic INHERIT HControl

   CLASS VAR winclass   INIT "STATIC"
   DATA AutoSize INIT .F.
   //DATA lTransparent  INIT .F. HIDDEN
   DATA nStyleHS
   DATA bClick, bDblClick
   DATA hBrushDefault  HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
         bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
         bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Activate()
   // METHOD SetValue( value ) INLINE SetDlgItemText( ::oParent:handle, ::id, ;
   METHOD SetText( value ) INLINE ::SetValue( value )
   METHOD SetValue( cValue )
   METHOD Auto_Size( cValue )  HIDDEN
   METHOD Init()
   METHOD PAINT( lpDis )
   METHOD onClick()
   METHOD onDblClick()
   METHOD OnEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStatic


   nStyle := IIF( nStyle = Nil, 0, nStyle )
   ::nStyleHS := nStyle - Hwg_BitAND( nStyle,  WS_VISIBLE + WS_DISABLED + WS_CLIPSIBLINGS + ;
                                               WS_CLIPCHILDREN + WS_BORDER + WS_DLGFRAME + ;
                                               WS_VSCROLL + WS_HSCROLL + WS_THICKFRAME + WS_TABSTOP )
   nStyle += SS_NOTIFY + WS_CLIPCHILDREN  //- ::nStyleHS

   ::BackStyle := OPAQUE
   IF ( lTransp != NIL .AND. lTransp )
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      nStyle += SS_OWNERDRAW - ::nStyleHS
   ELSEIF ::nStyleHS > 32 .OR. ::nStyleHS = 2
      bPaint := { | o, p | o:paint( p ) }
      nStyle +=  SS_OWNERDRAW - ::nStyleHS
   ENDIF
   
   /*
   LOCAL nStyles
   // Enabling style for tooltips
   //IF ValType( cTooltip ) == "C"
   //   IF nStyle == NIL
   //      nStyle := SS_NOTIFY
   //   ELSE
   nStyles := IIF(Hwg_BitAND( nStyle, WS_BORDER ) != 0, WS_BORDER, 0 )
   nStyles += IIF(Hwg_BitAND( nStyle, WS_DLGFRAME ) != 0, WS_DLGFRAME , 0 )
   nStyles += IIF(Hwg_BitAND( nStyle, WS_DISABLED ) != 0, WS_DISABLED , 0 )
   nStyles += IIF(Hwg_BitAND( nStyle, WS_TABSTOP ) != 0, WS_TABSTOP , 0 )
   nStyle  := Hwg_BitOr( nStyle, SS_NOTIFY ) - nStyles
   //    ENDIF
   // ENDIF
   //
   ::nStyleHS := IIf( nStyle == NIL, 0, nStyle )
   ::BackStyle := OPAQUE
   IF ( lTransp != NIL .AND. lTransp ) //.OR. ::lOwnerDraw
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      nStyle := SS_OWNERDRAW + Hwg_Bitand( nStyle, SS_NOTIFY )
   ELSEIF nStyle - SS_NOTIFY > 32 .OR. ::nStyleHS - SS_NOTIFY = 2
      bPaint := { | o, p | o:paint( p ) }
      nStyle := SS_OWNERDRAW + Hwg_Bitand( nStyle, SS_NOTIFY )
   ENDIF
   */
   ::hBrushDefault := HBrush():Add( GetSysColor( COLOR_BTNFACE ) )

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
         bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   ::bOther := bOther
   ::title := cCaption

   ::Activate()

   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
      bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStatic

   IF ( lTransp != NIL .AND. lTransp )  //.OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      ::BackStyle := TRANSPARENT
   ENDIF

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   // Enabling style for tooltips
   //IF ValType( cTooltip ) == "C"
   ::Style := SS_NOTIFY
   //ENDIF
   ::bOther := bOther
   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Activate() CLASS HStatic

   IF ! Empty( ::oParent:handle )
      ::handle := CreateStatic( ::oParent:handle, ::id, ::style, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
            ::extStyle )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HStatic

   IF ! ::lInit
      Super:init()
      IF ::nHolder != 1
         ::nHolder := 1
         SetWindowObject( ::handle, Self )
         Hwg_InitStaticProc( ::handle )
      ENDIF
      IF ::classname == "HSTATIC"
         ::Auto_Size( ::Title )
      ENDIF
      IF ::title != NIL
         SetWindowText( ::handle, ::title )
      ENDIF
   ENDIF

   RETURN  NIL

METHOD OnEvent( msg, wParam, lParam ) CLASS  HStatic
   LOCAL nEval, pos

   IF ::bOther != NIL
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg = WM_KEYUP
      IF wParam = VK_DOWN
         Getskip( ::oParent, ::handle,, 1 )
      ELSEIF wParam = VK_UP
         Getskip( ::oParent, ::handle,, - 1 )
      ELSEIF wParam = VK_TAB
         GetSkip( ::oParent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1 ) )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_SYSKEYUP
      IF ( pos := At( "&", ::title ) ) > 0 .and. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         getskip( ::oparent, ::handle,, 1 )
         RETURN  0
      ENDIF
   ELSEIF msg = WM_GETDLGCODE
      RETURN DLGC_WANTARROWS + DLGC_WANTTAB // +DLGC_STATIC   //DLGC_WANTALLKEYS //DLGC_WANTARROWS  + DLGC_WANTCHARS
   ENDIF

   RETURN - 1

METHOD SetValue( cValue )  CLASS HStatic

   ::Auto_Size( cValue )
   IF ::backstyle = TRANSPARENT .AND. ::Title != cValue .AND. isWindowVisible( ::handle )
      SetDlgItemText( ::oParent:handle, ::id, cValue )
      IF ::backstyle = TRANSPARENT .AND. ::Title != cValue .AND. isWindowVisible( ::handle )
         RedrawWindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_ERASENOW + RDW_INTERNALPAINT , ::nLeft, ::nTop, ::nWidth , ::nHeight )
         *-InvalidateRect( ::oParent:Handle, 0, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
         UpdateWindow( ::oParent:Handle )
      ENDIF
   ELSEIF ::backstyle != TRANSPARENT
      SetDlgItemText( ::oParent:handle, ::id, cValue )
   ENDIF
   ::Title := cValue

   RETURN NIL

METHOD Paint( lpDis ) CLASS HStatic
   LOCAL drawInfo := GetDrawItemInfo( lpDis )
   LOCAL client_rect, szText
   LOCAL dwtext, nstyle, brBackground
   LOCAL dc := drawInfo[ 3 ]

   client_rect := CopyRect( { drawInfo[ 4 ] , drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   //client_rect := GetClientRect( ::handle )
   szText := GetWindowText( ::handle )

   // Map "Static Styles" to "Text Styles"
   nstyle := ::nStyleHS  // ::style
   IF nStyle - SS_NOTIFY < DT_SINGLELINE
      SetAStyle( @nstyle, @dwtext )
   ELSE
       dwtext := nStyle - DT_NOCLIP
   ENDIF

   // Set transparent background
   SetBkMode( dc, ::backstyle )
   IF ::BackStyle = OPAQUE
      brBackground := IIF( ! EMPTY( ::brush ), ::brush, ::hBrushDefault )
      FillRect( dc, client_rect[ 1 ], client_rect[ 2 ], client_rect[ 3 ], client_rect[ 4 ], brBackground:handle )
   ENDIF

   IF ::tcolor != NIL .AND. ::isEnabled()
      SetTextColor( dc, ::tcolor )
   ELSEIF ! ::isEnabled()
      SetTextColor( dc, 16777215 ) //GetSysColor( COLOR_WINDOW ) )
      DrawText( dc, szText, { client_rect[ 1 ] + 1, client_rect[ 2 ] + 1, client_rect[ 3 ] + 1, client_rect[ 4 ] + 1 }, dwtext )
      SetBkMode( dc, TRANSPARENT )
      SetTextColor( dc, 10526880 ) //GetSysColor( COLOR_GRAYTEXT ) )
   ENDIF
   // Draw the text
   DrawText( dc, szText, client_rect, dwtext )

   RETURN NIL

METHOD onClick()  CLASS HStatic

   IF ::bClick != NIL
      //::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

METHOD onDblClick()  CLASS HStatic

   IF ::bDblClick != NIL
      //::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bDblClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

METHOD Auto_Size( cValue ) CLASS HStatic
   LOCAL  ASize, nLeft, nAlign

   IF ::autosize  //.OR. ::lOwnerDraw
      nAlign := ::nStyleHS - SS_NOTIFY
      ASize :=  TxtRect( cValue, Self )
      // ajust VCENTER
      // ::nTop := ::nTop + Int( ( ::nHeight - ASize[ 2 ] + 2 ) / 2 )
      IF nAlign == SS_RIGHT
         nLeft := ::nLeft + ( ::nWidth - ASize[ 1 ] - 2 )
      ELSEIF nAlign == SS_CENTER
         nLeft := ::nLeft + Int( ( ::nWidth - ASize[ 1 ] - 2 ) / 2 )
      ELSEIF nAlign == SS_LEFT
         nLeft := ::nLeft
      ENDIF
      ::nWidth := ASize[ 1 ] + 2
      ::nHeight := ASize[ 2 ]
      ::nLeft := nLeft
      ::move( ::nLeft, ::nTop )
   ENDIF

   RETURN NIL

// - HButton

CLASS HButton INHERIT HControl

   CLASS VAR winclass   INIT "BUTTON"
   DATA bClick
   DATA cNote  HIDDEN
   DATA lFlat INIT .F.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
         tcolor, bColor, bGFocus )
   METHOD Activate()
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
         cTooltip, tcolor, bColor, cCaption, bGFocus )
   METHOD Init()
   // METHOD Notify( lParam )
   METHOD onClick()
   METHOD onGetFocus()
   METHOD onLostFocus()
   METHOD onEvent( msg, wParam, lParam )
   METHOD NoteCaption( cNote )  SETGET

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, bGFocus ) CLASS HButton

   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_PUSHBUTTON + BS_NOTIFY )
   ::title := cCaption
   ::bClick := bClick
   ::bGetFocus := bGFocus
   ::lFlat := Hwg_BitAND( nStyle, BS_FLAT ) != 0

   Super:New( oWndParent, nId, nStyle, nLeft, nTop, ;
         IIf( nWidth  == NIL, 90, nWidth  ), ;
         IIf( nHeight == NIL, 30, nHeight ), ;
         oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   ::Activate()
   //IF bGFocus != NIL
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_SETFOCUS, Self, { || ::onGetFocus() } )
   ::oParent:AddEvent( BN_KILLFOCUS, self, {|| ::onLostFocus()})
   //ENDIF
    /*
   IF ::oParent:oParent != NIL .and. ::oParent:ClassName == "HTAB"
      //::oParent:AddEvent( BN_KILLFOCUS, Self, { || ::Notify( WM_KEYDOWN ) } )
      IF bClick != NIL
         ::oParent:oParent:AddEvent( 0, Self, { || ::onClick() } )
      ENDIF
   ENDIF
   */
   IF ::id > IDCANCEL .OR. ::bClick != NIL
      IF ::id < IDABORT
         ::GetParentForm():AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
      IF ::GetParentForm():Classname != ::oParent:Classname  .OR. ::id > IDCANCEL
         ::oParent:AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
   ENDIF

   RETURN Self

METHOD Activate() CLASS HButton

   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
            ::title )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, bGFocus ) CLASS HButton

   Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
         bSize, bPaint, cTooltip, tcolor, bColor )

   ::title   := cCaption
   //IF bGFocus != NIL
   ::bGetFocus  := bGFocus
   ::oParent:AddEvent( BN_SETFOCUS, Self, { || ::onGetFocus() } )
   //ENDIF
   ::oParent:AddEvent( BN_KILLFOCUS, self, {|| ::onLostFocus()})
   ::bClick  := bClick
   IF ::id > IDCANCEL .OR. ::bClick != NIL
      IF ::id < IDABORT
         ::GetParentForm():AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
      IF ::GetParentForm():Classname != ::oParent:Classname  .OR. ::id > IDCANCEL
         ::oParent:AddEvent( BN_CLICKED, Self, { || ::onClick() } )
      ENDIF
   ENDIF

   RETURN Self

METHOD Init() CLASS HButton

   IF ! ::lInit
      IF !( ::GetParentForm( ):classname == ::oParent:classname .AND.;
            ::GetParentForm( ):Type >= WND_DLG_RESOURCE ) .OR. ;
            ! ::GetParentForm( ):lModal  .OR. ::nHolder = 1
         ::nHolder := 1
         SetWindowObject( ::handle, Self )
         HWG_INITBUTTONPROC( ::handle )
      ENDIF
      ::Super:init()
      /*
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
      */
   ENDIF

   RETURN  NIL

METHOD onevent( msg, wParam, lParam ) CLASS HButton

   IF msg = WM_SETFOCUS .AND. ::oParent:oParent = NIL
      // *- SENDMESSAGE( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
   ELSEIF msg = WM_KILLFOCUS
      IF ::GetParentForm():handle != ::oParent:Handle
         // *- IF ::oParent:oParent != NIL
         InvalidateRect( ::handle, 0 )
         SENDMESSAGE( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
      ENDIF
   ELSEIF msg = WM_KEYDOWN
      IF ( wParam == VK_RETURN   .OR. wParam == VK_SPACE )
         SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF
      IF ! ProcKeyList( Self, wParam )
         IF wParam = VK_TAB
            GetSkip( ::oparent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1)  )
            RETURN 0
         ELSEIF wParam = VK_LEFT .OR. wParam = VK_UP
            GetSkip( ::oparent, ::handle, , -1 )
            RETURN 0
         ELSEIF wParam = VK_RIGHT .OR. wParam = VK_DOWN
            GetSkip( ::oparent, ::handle, , 1 )
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYUP
      IF ( wParam == VK_RETURN .OR. wParam == VK_SPACE )
         SendMessage( ::handle, WM_LBUTTONUP, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF
   ELSEIF  msg = WM_GETDLGCODE .AND. ! EMPTY( lParam )
      IF wParam = VK_RETURN .OR. wParam = VK_TAB
      ELSEIF GETDLGMESSAGE( lParam ) = WM_KEYDOWN .AND.wParam != VK_ESCAPE
      ELSEIF GETDLGMESSAGE( lParam ) = WM_CHAR .OR.wParam = VK_ESCAPE
         RETURN -1
      ENDIF
      RETURN DLGC_WANTMESSAGE
   ENDIF

   RETURN -1

METHOD onClick()  CLASS HButton

   IF ::bClick != NIL
      //::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

/*
METHOD Notify( lParam ) CLASS HButton
   LOCAL ndown := getkeystate( VK_RIGHT ) + getkeystate( VK_DOWN ) + GetKeyState( VK_TAB )
   LOCAL nSkip := 0
   //
   IF PtrtoUlong( lParam ) = WM_KEYDOWN
      IF ::oParent:Classname = "HTAB"
         IF getfocus() != ::handle
            InvalidateRect( ::handle, 0 )
            SENDMESSAGE( ::handle, BM_SETSTYLE , BS_PUSHBUTTON , 1 )
         ENDIF
         IF getkeystate( VK_LEFT ) + getkeystate( VK_UP ) < 0 .OR. ;
            ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 )
            nSkip := - 1
         ELSEIF ndown < 0
            nSkip := 1
         ENDIF
         IF nSkip != 0
            ::oParent:Setfocus()
            GetSkip( ::oparent, ::handle, , nSkip )
            RETURN 0
         ENDIF
      ENDIF
   ENDIF
   RETURN - 1
*/

METHOD NoteCaption( cNote )  CLASS HButton

   //#DEFINE BCM_SETNOTE  0x00001609
   IF cNote != NIL
      IF Hwg_BitOr( ::Style, BS_COMMANDLINK ) > 0
         SENDMESSAGE( ::Handle, BCM_SETNOTE, 0, ANSITOUNICODE( cNote ) )
      ENDIF
      ::cNote := cNote
   ENDIF

   RETURN ::cNote

METHOD onGetFocus()  CLASS HButton
   LOCAL res := .t., nSkip

   IF ! CheckFocus( Self, .f. ) .OR. ::bGetFocus = NIL
      RETURN .t.
   ENDIF
   IF ::bGetFocus != NIL
      nSkip := IIf( GetKeyState( VK_UP ) < 0 .or. ( GetKeyState( VK_TAB ) < 0 .and. GetKeyState( VK_SHIFT ) < 0 ), - 1, 1 )
      ::oParent:lSuspendMsgsHandling := .t.
      res := Eval( ::bGetFocus, ::title, Self )
      ::oParent:lSuspendMsgsHandling := .f.
      IF res != NIL .AND.  EMPTY( res )
         WhenSetFocus( Self, nSkip )
         IF ::lflat
            InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
         ENDIF
      ENDIF
   ENDIF

   RETURN res

METHOD onLostFocus()  CLASS HButton

   IF ::lflat
      InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
   ENDIF
   ::lnoWhen := .F.
   IF ::bLostFocus != NIL .AND. SelfFocus( GetParent( GetFocus() ), ::getparentform():Handle )
      ::oparent:lSuspendMsgsHandling := .t.
      Eval( ::bLostFocus, ::title, Self)
      ::oparent:lSuspendMsgsHandling := .f.
   ENDIF

   RETURN NIL

// - HGroup

CLASS HButtonEX INHERIT HButton

   DATA hBitmap
   DATA hIcon
   DATA m_dcBk
   DATA m_bFirstTime INIT .T.
   DATA Themed INIT .F.
   // DATA lnoThemes  INIT .F. HIDDEN
   DATA m_crColors INIT Array( 6 )
   DATA m_crBrush INIT Array( 6 )
   DATA hTheme
   // DATA Caption
   DATA state
   DATA m_bIsDefault INIT .F.
   DATA m_nTypeStyle  init 0
   DATA m_bSent, m_bLButtonDown, m_bIsToggle
   DATA m_rectButton           // button rect in parent window coordinates
   DATA m_dcParent init hdc():new()
   DATA m_bmpParent
   DATA m_pOldParentBitmap
   DATA m_csbitmaps init {,,,, }
   DATA m_bToggled INIT .f.
   DATA PictureMargin INIT 0
   DATA m_bDrawTransparent INIT .f.
   DATA iStyle
   DATA m_bmpBk, m_pbmpOldBk
   DATA bMouseOverButton INIT .f.

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
         tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther )
   METHOD Paint( lpDis )
   METHOD SetBitmap( hBitMap )
   METHOD SetIcon( hIcon )
   METHOD Init()
   METHOD onevent( msg, wParam, lParam )
   METHOD CancelHover()
   METHOD END()
   METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
         cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus, nPictureMargin )
   METHOD PaintBk( hdc )
   METHOD SetColor( tcolor, bcolor ) INLINE ::SetDefaultColor( tcolor, bcolor ) //, ::SetDefaultColor( .T. )
   METHOD SetDefaultColor( tColor, bColor, lPaint )
   // METHOD SetDefaultColor( lRepaint )
   METHOD SetColorEx( nIndex, nColor, lPaint )
   //METHOD SetText( c ) INLINE ::title := c, ::caption := c, ;
   METHOD SetText( c ) INLINE ::title := c,  ;
         RedrawWindow( ::Handle, RDW_NOERASE + RDW_INVALIDATE ),;
         IIF( ::oParent != NIL .AND. isWindowVisible( ::Handle ) ,;
         InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  ), ), ;
         SetWindowText( ::handle, ::title )
//   METHOD SaveParentBackground()

END CLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
      cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
      tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT Transp TO .T.
   DEFAULT nPictureMargin TO 0
   DEFAULT lnoThemes  TO .F.
   ::m_bLButtonDown := .f.
   ::m_bSent := .f.
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.

   cCaption := IIF( cCaption = NIL, "", cCaption )
   ::Caption := cCaption
   ::iStyle              := iStyle
   ::hBitmap             := IIF( EMPTY( hBitmap ), NIL, hBitmap )
   ::hicon               := IIF( EMPTY( hicon ), NIL, hIcon )
   ::m_bDrawTransparent  := Transp
   ::PictureMargin       := nPictureMargin
   ::lnoThemes           := lnoThemes
   ::bOther := bOther
   bPaint := { | o, p | o:paint( p ) }

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, bClick, cTooltip, ;
         tcolor, bColor, bGFocus )

   RETURN Self

METHOD Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus, nPictureMargin ) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT nPictureMargin TO 0
   bPaint := { | o, p | o:paint( p ) }
   ::m_bLButtonDown := .f.
   ::m_bIsToggle := .f.
   ::m_bLButtonDown := .f.
   ::m_bSent := .f.
   ::title := cCaption
   ::Caption := cCaption
   ::iStyle  := iStyle
   ::hBitmap := hBitmap
   ::hIcon   := hIcon
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   ::PictureMargin                      := nPictureMargin

   ::Super:Redefine( oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ;
         cTooltip, tcolor, bColor, cCaption, hBitmap, iStyle, hIcon, bGFocus  )
   ::title := cCaption
   ::Caption := cCaption
   
   

   RETURN Self

METHOD SetBitmap( hBitMap ) CLASS HButtonEX

   DEFAULT hBitmap TO ::hBitmap
   IF ValType( hBitmap ) == "N"
      ::hBitmap := hBitmap
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_BITMAP, ::hBitmap )
      REDRAWWINDOW( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
   ENDIF

   RETURN Self

METHOD SetIcon( hIcon ) CLASS HButtonEX

   DEFAULT hIcon TO ::hIcon
   IF ValType( ::hIcon ) == "N"
      ::hIcon := hIcon
      SendMessage( ::handle, BM_SETIMAGE, IMAGE_ICON, ::hIcon )
      REDRAWWINDOW( ::Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT)
   ENDIF

   RETURN Self

METHOD END() CLASS HButtonEX

   Super:END()

   RETURN Self

METHOD INIT() CLASS HButtonEx
   LOCAL nbs

   IF ! ::lInit
      ::nHolder := 1
      //SetWindowObject( ::handle, Self )
      //HWG_INITBUTTONPROC( ::handle )
      // call in HBUTTON CLASS
      //::SetDefaultColor( ,, .F. )
      IF HB_IsNumeric( ::handle ) .and. ::handle > 0
         nbs := HWG_GETWINDOWSTYLE( ::handle )
         ::m_nTypeStyle :=  GetTheStyle( nbs , BS_TYPEMASK )

         // Check if this is a checkbox
         // Set initial default state flag
         IF ( ::m_nTypeStyle == BS_DEFPUSHBUTTON )
            // Set default state for a default button
            ::m_bIsDefault := .t.

            // Adjust style for default button
            ::m_nTypeStyle := BS_PUSHBUTTON
         ENDIF
         nbs := modstyle( nbs, BS_TYPEMASK  , BS_OWNERDRAW )
         HWG_SETWINDOWSTYLE ( ::handle, nbs )
       ENDIF

      ::Super:init()
      ::SetBitmap()
   ENDIF

   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HBUTTONEx

   LOCAL pt := {, }, rectButton, acoor
   LOCAL pos, nID, oParent, nEval

   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
            ::hTheme       := NIL
            //::m_bFirstTime := .T.
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
      RETURN 0
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == BM_SETSTYLE
      RETURN BUTTONEXONSETSTYLE( wParam, lParam, ::handle, @::m_bIsDefault )
   ELSEIF msg == WM_MOUSEMOVE
      IF wParam = MK_LBUTTON
         pt[ 1 ] := LOWORD( lParam )
         pt[ 2 ] := HIWORD( lParam )
         acoor := ClientToScreen( ::handle, pt[ 1 ], pt[ 2 ] )
         rectButton := GetWindowRect( ::handle )
         IF ( ! PtInRect( rectButton, acoor ) )
            SendMessage( ::handle, BM_SETSTATE, ::m_bToggled, 0 )
            ::bMouseOverButton := .F.
            RETURN 0
         ENDIF
      ENDIF
      IF ( ! ::bMouseOverButton )
         ::bMouseOverButton := .T.
         Invalidaterect( ::handle, .f. )
         TRACKMOUSEVENT( ::handle )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_MOUSELEAVE
      ::CancelHover()
      RETURN 0
   ENDIF
   IF ::bOther != NIL
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam )) != -1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_KEYDOWN
#ifdef __XHARBOUR__
      IF hb_BitIsSet( PtrtoUlong( lParam ), 30 )  // the key was down before ?
#else
      IF hb_BitTest( lParam, 30 )   // the key was down before ?
#endif
         RETURN 0
      ENDIF
      IF ( ( wParam == VK_SPACE ) .or. ( wParam == VK_RETURN ) )
         /*
         IF ( ::GetParentForm( Self ):Type < WND_DLG_RESOURCE )
            SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
             ELSE
            SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
         ENDIF
         */
         SendMessage( ::handle, WM_LBUTTONDOWN, 0, MAKELPARAM( 1, 1 ) )
         RETURN 0
      ENDIF
      IF wParam == VK_LEFT .OR. wParam == VK_UP
         GetSkip( ::oParent, ::handle, , - 1 )
         RETURN 0
      ELSEIF wParam == VK_RIGHT .OR. wParam == VK_DOWN
         GetSkip( ::oParent, ::handle, , 1 )
         RETURN 0
      ELSEIF  wParam = VK_TAB
         GetSkip( ::oparent, ::handle, , iif( IsCtrlShift(.f., .t.), -1, 1)  )
      ENDIF
      ProcKeyList( Self, wParam )
   ELSEIF msg == WM_SYSKEYUP .OR. ( msg == WM_KEYUP .AND.;
         ASCAN( { VK_SPACE, VK_RETURN, VK_ESCAPE }, wParam ) = 0 )
      IF CheckBit( lParam, 23 ) .AND. ( wParam > 95 .AND. wParam < 106 )
         wParam -= 48
      ENDIF
      IF ! EMPTY( ::title) .AND. ( pos := At( "&", ::title ) ) > 0 .AND. wParam == Asc( Upper( SubStr( ::title, ++ pos, 1 ) ) )
         IF ValType( ::bClick ) == "B" .OR. ::id < 3
            SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
         ENDIF
      ELSEIF ( nID := Ascan( ::oparent:acontrols, { | o | IIF( VALTYPE( o:title ) = "C", ( pos := At( "&", o:title )) > 0 .AND. ;
            wParam == Asc( Upper( SubStr( o:title, ++ pos, 1 ) )), ) } )) > 0
         IF __ObjHasMsg( ::oParent:aControls[ nID ],"BCLICK") .AND.;
               ValType( ::oParent:aControls[ nID ]:bClick ) == "B" .OR. ::oParent:aControls[ nID]:id < 3
            SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::oParent:aControls[ nID ]:id, BN_CLICKED ), ::oParent:aControls[ nID ]:handle )
         ENDIF
      ENDIF
      IF msg != WM_SYSKEYUP
         RETURN 0
      ENDIF
   ELSEIF msg == WM_KEYUP
      IF ( wParam == VK_SPACE .OR. wParam == VK_RETURN  )
         ::bMouseOverButton := .T.
         SendMessage( ::handle, WM_LBUTTONUP, 0, MAKELPARAM( 1, 1 ) )
         ::bMouseOverButton := .F.
         RETURN 0
      ENDIF
   ELSEIF msg == WM_LBUTTONUP
      ::m_bLButtonDown := .f.
      IF ( ::m_bSent )
         SendMessage( ::handle, BM_SETSTATE, 0, 0 )
         ::m_bSent := .f.
      ENDIF
      IF ::m_bIsToggle
         pt[ 1 ] := LOWORD( lParam )
         pt[ 2 ] := HIWORD( lParam )
         acoor := ClientToScreen( ::handle, pt[ 1 ], pt[ 2 ] )
         rectButton := GetWindowRect( ::handle )
         IF ( ! PtInRect( rectButton, acoor ) )
            ::m_bToggled := ! ::m_bToggled
            InvalidateRect( ::handle, 0 )
            SendMessage( ::handle, BM_SETSTATE, 0, 0 )
            ::m_bLButtonDown := .T.
         ENDIF
      ENDIF
      IF ( ! ::bMouseOverButton )
         SETFOCUS( 0 )
         ::SETFOCUS()
         RETURN 0
      ENDIF
      RETURN - 1
   ELSEIF msg == WM_LBUTTONDOWN
      ::m_bLButtonDown := .t.
      IF ( ::m_bIsToggle )
         ::m_bToggled := ! ::m_bToggled
         InvalidateRect( ::handle, 0 )
      ENDIF
      RETURN - 1
   ELSEIF msg == WM_LBUTTONDBLCLK
      IF ( ::m_bIsToggle )
         // for toggle buttons, treat doubleclick as singleclick
         SendMessage( ::handle, BM_SETSTATE, ::m_bToggled, 0 )
      ELSE
         SendMessage( ::handle, BM_SETSTATE, 1, 0 )
         ::m_bSent := TRUE
      ENDIF
      RETURN 0
   ELSEIF msg == WM_GETDLGCODE
      IF wParam = VK_ESCAPE .AND. ( GETDLGMESSAGE( lParam ) = WM_KEYDOWN .OR. GETDLGMESSAGE( lParam ) = WM_KEYUP )
         oParent := ::GetParentForm()
         IF ! ProcKeyList( Self, wParam )  .AND. ( oParent:Type < WND_DLG_RESOURCE .OR. ! oParent:lModal )
            SendMessage( oParent:handle, WM_COMMAND, makewparam( IDCANCEL, 0 ), ::handle )
         ELSEIF oParent:FindControl( IDCANCEL ) != NIL .AND. ! oParent:FindControl( IDCANCEL ):IsEnabled() .AND. oParent:lExitOnEsc
            SendMessage( oParent:handle, WM_COMMAND, makewparam( IDCANCEL, 0 ), ::handle )
            RETURN 0
         ENDIF
      ENDIF
      RETURN IIF( wParam = VK_ESCAPE, - 1, ButtonGetDlgCode( lParam ) )
   ELSEIF msg == WM_SYSCOLORCHANGE
      ::SetDefaultColors()
   ELSEIF msg == WM_CHAR
      IF wParam == VK_RETURN .or. wParam == VK_SPACE
         IF ( ::m_bIsToggle )
            ::m_bToggled := ! ::m_bToggled
            InvalidateRect( ::handle, 0 )
         ELSE
            SendMessage( ::handle, BM_SETSTATE, 1, 0 )
            //::m_bSent := .t.
         ENDIF
         // remove because repet click  2 times
         //SendMessage( ::oParent:handle, WM_COMMAND, makewparam( ::id, BN_CLICKED ), ::handle )
      ELSEIF wParam == VK_ESCAPE
         SendMessage( ::oParent:handle, WM_COMMAND, makewparam( IDCANCEL, BN_CLICKED ), ::handle )
      ENDIF
      RETURN 0
   ENDIF

   RETURN - 1

METHOD CancelHover() CLASS HBUTTONEx

   IF ( ::bMouseOverButton ) .AND. ::id != IDOK //NANDO
      ::bMouseOverButton := .F.
      IF !::lflat
         Invalidaterect( ::handle, .f. )
      ELSE
         InvalidateRect( ::oParent:Handle, 1 , ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
      ENDIF
   ENDIF

   RETURN NIL

METHOD SetDefaultColor( tColor, bColor, lPaint ) CLASS HBUTTONEx

   DEFAULT lPaint TO .f.

   IF !EMPTY( tColor )
      ::tColor := tColor
   ENDIF
   IF !EMPTY( bColor )
      ::bColor := bColor
   ENDIF
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := IIF( ::bColor = NIL, GetSysColor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := IIF( ::tColor = NIL, GetSysColor( COLOR_BTNTEXT ), ::tColor )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := IIF( ::bColor = NIL, GetSysColor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := IIF( ::tColor = NIL, GetSysColor( COLOR_BTNTEXT ), ::tColor )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := IIF( ::bColor = NIL, GetSysColor( COLOR_BTNFACE ), ::bColor )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := IIF( ::tColor = NIL, GetSysColor( COLOR_BTNTEXT ), ::tColor )
   //
   ::m_crBrush[ BTNST_COLOR_BK_IN ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_IN ] )
   ::m_crBrush[ BTNST_COLOR_BK_OUT ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_OUT ] )
   ::m_crBrush[ BTNST_COLOR_BK_FOCUS ] := HBrush():Add( ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )
   /*
   ::m_crColors[ BTNST_COLOR_BK_IN ]    := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_IN ]    := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_OUT ]   := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_OUT ]   := GetSysColor( COLOR_BTNTEXT )
   ::m_crColors[ BTNST_COLOR_BK_FOCUS ] := GetSysColor( COLOR_BTNFACE )
   ::m_crColors[ BTNST_COLOR_FG_FOCUS ] := GetSysColor( COLOR_BTNTEXT )
   */
   IF lPaint
      Invalidaterect( ::handle, .f. )
   ENDIF

   RETURN Self

METHOD SetColorEx( nIndex, nColor, lPaint ) CLASS HBUTTONEx

   DEFAULT lPaint TO .f.
   IF nIndex > BTNST_MAX_COLORS
      RETURN - 1
   ENDIF
   ::m_crColors[ nIndex ]    := nColor
   IF lPaint
      Invalidaterect( ::handle, .f. )
   ENDIF

   RETURN 0

METHOD Paint( lpDis ) CLASS HBUTTONEx
   LOCAL drawInfo := GetDrawItemInfo( lpDis )
   LOCAL dc := drawInfo[ 3 ]
   LOCAL bIsPressed     := HWG_BITAND( drawInfo[ 9 ], ODS_SELECTED ) != 0
   LOCAL bIsFocused     := HWG_BITAND( drawInfo[ 9 ], ODS_FOCUS ) != 0
   LOCAL bIsDisabled    := HWG_BITAND( drawInfo[ 9 ], ODS_DISABLED ) != 0
   LOCAL bDrawFocusRect := ! HWG_BITAND( drawInfo[ 9 ], ODS_NOFOCUSRECT ) != 0
   LOCAL focusRect
   LOCAL captionRect
   LOCAL centerRect
   LOCAL bHasTitle
   LOCAL itemRect := copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   LOCAL state
   LOCAL crColor
   LOCAL brBackground
   LOCAL br
   LOCAL brBtnShadow
   LOCAL uState
   LOCAL captionRectHeight
   LOCAL centerRectHeight
   //LOCAL captionRectWidth
   //LOCAL centerRectWidth
   LOCAL uAlign, uStyleTmp
   LOCAL aTxtSize := IIf( ! Empty( ::caption ), TxtRect( ::caption, Self ), { 0, 0 } )
   LOCAL aBmpSize := IIf( ! Empty( ::hbitmap ), GetBitmapSize( ::hbitmap ), { 0, 0 } )
   LOCAL itemRectOld, saveCaptionRect, bmpRect, itemRect1, captionRect1, fillRect
   LOCAL lMultiLine, nHeight := 0

   IF ( ::m_bFirstTime )
      ::m_bFirstTime := .F.
      IF ( ISTHEMEDLOAD() )
         IF ValType( ::hTheme ) == "P"
            HB_CLOSETHEMEDATA( ::htheme )
         ENDIF
         ::hTheme := NIL
         IF ::WindowsManifest
            ::hTheme := hb_OpenThemeData( ::handle, "BUTTON" )
         ENDIF
      ENDIF
   ENDIF
   IF ! Empty( ::hTheme ) .AND. !::lnoThemes
       ::Themed := .T.
   ENDIF
   SetBkMode( dc, TRANSPARENT )
   IF ( ::m_bDrawTransparent )
      // ::PaintBk(DC)
   ENDIF

   // Prepare draw... paint button background
   IF ::Themed
      IF bIsDisabled
         state :=  PBS_DISABLED
      ELSE
         state := IIF( bIsPressed, PBS_PRESSED, PBS_NORMAL )
      ENDIF
      IF state == PBS_NORMAL
         IF bIsFocused
            state := PBS_DEFAULTED
         ENDIF
         IF ::bMouseOverButton .OR. ::id = IDOK
            state := PBS_HOT
         ENDIF
      ENDIF
      IF ! ::lFlat
         hb_DrawThemeBackground( ::hTheme, dc, BP_PUSHBUTTON, state, itemRect, NIL )
      ELSEIF bIsDisabled
         FillRect( dc, itemRect[ 1 ] + 1, itemRect[ 2 ] + 1, itemRect[ 3 ] - 1, itemRect[ 4 ] - 1, GetSysColorBrush( GetSysColor( COLOR_BTNFACE ) ) )
      ELSEIF ::bMouseOverButton .OR. bIsFocused
         hb_DrawThemeBackground( ::hTheme, dc, BP_PUSHBUTTON  , state, itemRect, NIL ) // + PBS_DEFAULTED
      ENDIF
   ELSE
      IF bIsFocused .OR. ::id = IDOK
         br := HBRUSH():Add( RGB( 1, 1, 1 ) )
         FrameRect( dc, itemRect, br:handle )
         InflateRect( @itemRect, - 1, - 1 )
      ENDIF
      crColor := GetSysColor( COLOR_BTNFACE )
      brBackground := HBRUSH():Add( crColor )
      FillRect( dc, itemRect, brBackground:handle )
      IF ( bIsPressed )
         brBtnShadow := HBRUSH():Add( GetSysColor( COLOR_BTNSHADOW ) )
         FrameRect( dc, itemRect, brBtnShadow:handle )
      ELSE
         IF ! ::lFlat .OR. ::bMouseOverButton
            uState := HWG_BITOR( ;
                  HWG_BITOR( DFCS_BUTTONPUSH, ;
                  IIF( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
                  IIF( bIsPressed, DFCS_PUSHED, 0 ) )
            DrawFrameControl( dc, itemRect, DFC_BUTTON, uState )
         ELSEIF bIsFocused
            uState := HWG_BITOR( ;
                  HWG_BITOR( DFCS_BUTTONPUSH + DFCS_MONO ,; // DFCS_FLAT , ;
                  IIF( ::bMouseOverButton, DFCS_HOT, 0 ) ), ;
                  IIF( bIsPressed, DFCS_PUSHED, 0 ) )
            DrawFrameControl( dc, itemRect, DFC_BUTTON, uState )
         ENDIF
      ENDIF
   ENDIF

   //      if ::iStyle ==  ST_ALIGN_HORIZ
   //         uAlign := DT_RIGHT
   //      else
   //         uAlign := DT_LEFT
   //      endif
   //
   //      IF VALTYPE( ::hbitmap ) != "N"
   //         uAlign := DT_CENTER
   //      ENDIF

   uAlign := 0 //DT_LEFT
   IF ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N"
      uAlign := DT_VCENTER // + DT_CENTER
   ENDIF
   /*
   IF ValType( ::hicon ) == "N"
      uAlign := DT_CENTER
   ENDIF
   */
   IF uAlign = DT_VCENTER  //!= DT_CENTER + DT_VCENTER
      uAlign := IIF( HWG_BITAND( ::Style, BS_TOP ) != 0, DT_TOP, DT_VCENTER )
      uAlign += IIF( HWG_BITAND( ::Style, BS_BOTTOM ) != 0, DT_BOTTOM - DT_VCENTER , 0 )
      uAlign += IIF( HWG_BITAND( ::Style, BS_LEFT ) != 0, DT_LEFT, DT_CENTER )
      uAlign += IIF( HWG_BITAND( ::Style, BS_RIGHT ) != 0, DT_RIGHT - DT_CENTER, 0 )
   ELSE
      uAlign := IIF( uAlign = 0, DT_CENTER + DT_VCENTER, uAlign )
   ENDIF

   //             DT_CENTER | DT_VCENTER | DT_SINGLELINE
   //   uAlign += DT_WORDBREAK + DT_CENTER + DT_CALCRECT +  DT_VCENTER + DT_SINGLELINE  // DT_SINGLELINE + DT_VCENTER + DT_WORDBREAK
   //  uAlign += DT_VCENTER
   uStyleTmp := HWG_GETWINDOWSTYLE( ::handle )
   itemRectOld := aclone(itemRect)
   IF hb_BitAnd( uStyleTmp, BS_MULTILINE ) != 0 .AND. !EMPTY(::caption) .AND. ;
         INT( aTxtSize[ 2 ] ) !=  INT( DrawText( dc, ::caption, itemRect[ 1 ], itemRect[ 2 ],;
         itemRect[ 3 ] - IIF( ::iStyle = ST_ALIGN_VERT, 0, aBmpSize[ 1 ] + 8 ),;
         itemRect[ 4 ], DT_CALCRECT + uAlign + DT_WORDBREAK, itemRectOld ) )
      // *-INT( aTxtSize[ 2 ] ) !=  INT( DrawText( dc, ::caption, itemRect,  DT_CALCRECT + uAlign + DT_WORDBREAK ) )
      uAlign += DT_WORDBREAK
      lMultiline := .T.
      drawInfo[ 4 ] += 2
      drawInfo[ 6 ] -= 2
      itemRect[ 1 ] += 2
      itemRect[ 3 ] -= 2
      aTxtSize[ 1 ] := itemRectold[ 3 ] - itemRectOld[ 1 ] + 1
      aTxtSize[ 2 ] := itemRectold[ 4 ] - itemRectold[ 2 ] + 1
   ELSE
       uAlign += DT_SINGLELINE
       lMultiline := .F.
   ENDIF

   captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] }
   //
   IF ( ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N" ) .AND. lMultiline
      IF ::iStyle = ST_ALIGN_HORIZ
         captionRect := { drawInfo[ 4 ] + ::PictureMargin , drawInfo[ 5 ], drawInfo[ 6 ] , drawInfo[ 7 ] }
      ELSEIF ::iStyle = ST_ALIGN_HORIZ_RIGHT
         captionRect := { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ] - ::PictureMargin, drawInfo[ 7 ] }
      ELSEIF ::iStyle = ST_ALIGN_VERT
      ENDIF
   ENDIF

   itemRectOld := AClone( itemRect )

   IF !EMPTY( ::caption ) .AND. !EMPTY( ::hbitmap )  //.AND.!EMPTY( ::hicon )
      nHeight :=  aTxtSize[ 2 ] //nHeight := IIF( lMultiLine, DrawText( dc, ::caption, itemRect,  DT_CALCRECT + uAlign + DT_WORDBREAK  ), aTxtSize[ 2 ] )
      IF ::iStyle = ST_ALIGN_HORIZ
         itemRect[ 1 ] := IIF( ::PictureMargin = 0, ( ( ( ::nWidth - aTxtSize[ 1 ] - aBmpSize[ 1 ] / 2 ) / 2 ) ) / 2, ::PictureMargin )
         itemRect[ 1 ] := IIF( itemRect[ 1 ] < 0, 0, itemRect[ 1 ] )
      ELSEIF ::iStyle = ST_ALIGN_HORIZ_RIGHT
      ELSEIF ::iStyle = ST_ALIGN_VERT .OR. ::iStyle = ST_ALIGN_OVERLAP
         nHeight := IIF( lMultiLine,  DrawText( dc, ::caption, itemRect,  DT_CALCRECT + DT_WORDBREAK  ), aTxtSize[ 2 ] )
         ::iStyle := ST_ALIGN_OVERLAP
         itemRect[ 1 ] := ( ::nWidth - aBmpSize[ 1 ] ) /  2
         itemRect[ 2 ] := IIF( ::PictureMargin = 0, ( ( ( ::nHeight - ( nHeight + aBmpSize[ 2 ] + 1 ) ) / 2 ) ), ::PictureMargin )
      ENDIF
   ELSEIF ! EMPTY( ::caption )
      nHeight := aTxtSize[ 2 ] //nHeight := IIF( lMultiLine, DrawText( dc, ::caption, itemRect,  DT_CALCRECT + DT_WORDBREAK ), aTxtSize[ 2 ] )
   ENDIF

   bHasTitle := ValType( ::caption ) == "C" .and. ! Empty( ::Caption )

   //   DrawTheIcon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
   IF ValType( ::hbitmap ) == "N" .AND. ::m_bDrawTransparent .AND. ( ! bIsDisabled .OR. ::istyle = ST_ALIGN_HORIZ_RIGHT )
      bmpRect := PrepareImageRect( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, ::hIcon, ::hbitmap, ::iStyle )
      IF ::istyle = ST_ALIGN_HORIZ_RIGHT
         bmpRect[ 1 ]     -= ::PictureMargin
         captionRect[ 3 ] -= ::PictureMargin
      ENDIF
      IF ! bIsDisabled
          DrawTransparentBitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] )
      ELSE
          DrawGrayBitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] )
      ENDIF
   ELSEIF ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N"
      IF ::istyle = ST_ALIGN_HORIZ_RIGHT
         captionRect[ 3 ] -= ::PictureMargin
      ENDIF
      DrawTheIcon( ::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
   ELSE
      InflateRect( @captionRect, - 3, - 3 )
   ENDIF
   captionRect[ 1 ] += IIF( HWG_BITAND( ::Style, BS_LEFT )  != 0, Max( ::PictureMargin, 2 ), 0 )
   captionRect[ 3 ] -= IIF( HWG_BITAND( ::Style, BS_RIGHT ) != 0, Max( ::PictureMargin, 3 ), 0 )

   itemRect1    := aclone( itemRect )
   captionRect1 := aclone( captionRect )
   itemRect     := aclone( itemRectOld )

   IF ( bHasTitle )
      // If button is pressed then "press" title also
      IF bIsPressed .and. ! ::Themed
         OffsetRect( @captionRect, 1, 1 )
      ENDIF
      // Center text
      centerRect := copyrect( captionRect )
      IF ValType( ::hicon ) == "N" .OR. ValType( ::hbitmap ) == "N"
         IF ! lmultiline  .AND. ::iStyle != ST_ALIGN_OVERLAP
            // DrawText( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign + DT_CALCRECT, @captionRect )
         ELSEIF !EMPTY(::caption)
            // figura no topo texto em baixo
            IF ::iStyle = ST_ALIGN_OVERLAP //ST_ALIGN_VERT
               captionRect[ 2 ] :=  itemRect1[ 2 ] + aBmpSize[ 2 ] //+ 1
               uAlign -= ST_ALIGN_OVERLAP + 1
            ELSE
               captionRect[ 2 ] :=  ( ::nHeight - nHeight ) / 2 + 2
            ENDIF
            savecaptionRect := aclone( captionRect )
            DrawText( dc, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], uAlign , @captionRect )
         ENDIF
      ELSE
         // *- uAlign += DT_CENTER
      ENDIF

      //captionRectWidth  := captionRect[ 3 ] - captionRect[ 1 ]
      captionRectHeight := captionRect[ 4 ] - captionRect[ 2 ]
      //centerRectWidth   := centerRect[ 3 ] - centerRect[ 1 ]
      centerRectHeight  := centerRect[ 4 ] - centerRect[ 2 ]
      //ok      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
      //      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
      //      OffsetRect( @captionRect, ( centerRectWidth - captionRectWidth ) / 2, ( centerRectHeight - captionRectHeight ) / 2 )
      OffsetRect( @captionRect, 0, ( centerRectHeight - captionRectHeight ) / 2 )
      /*      SetBkMode( dc, TRANSPARENT )
      IF ( bIsDisabled )
         OffsetRect( @captionRect, 1, 1 )
         SetTextColor( DC, GetSysColor( COLOR_3DHILIGHT ) )
         DrawText( DC, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], DT_WORDBREAK + DT_CENTER, @captionRect )
         OffsetRect( @captionRect, - 1, - 1 )
         SetTextColor( DC, GetSysColor( COLOR_3DSHADOW ) )
         DrawText( DC, ::caption, captionRect[ 1 ], captionRect[ 2 ], captionRect[ 3 ], captionRect[ 4 ], DT_WORDBREAK + DT_VCENTER + DT_CENTER, @captionRect )
      ELSE
         IF ( ::bMouseOverButton .or. bIsPressed )
            SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_IN ] )
            SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_IN ] )
         ELSE
            IF ( bIsFocused )
               SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
               SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )
            ELSE
               SetTextColor( DC, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
               SetBkColor( DC, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
            ENDIF
         ENDIF
      ENDIF
      */
      IF ::Themed
         IF ( ValType( ::hicon ) == "N" .OR. ValType( ::hbitmap ) == "N" )
            IF lMultiLine  .OR. ::iStyle = ST_ALIGN_OVERLAP
               captionRect := aclone( savecaptionRect )
            ENDIF
         ELSEIF lMultiLine
            captionRect[ 2 ] := (::nHeight  - nHeight ) / 2 + 2
         ENDIF
         hb_DrawThemeText( ::hTheme, dc, BP_PUSHBUTTON, IIF( bIsDisabled, PBS_DISABLED, PBS_NORMAL ), ;
               ::caption, ;
               uAlign + DT_END_ELLIPSIS, ;
               0, captionRect )
      ELSE
         SetBkMode( dc, TRANSPARENT )
         IF ( bIsDisabled )
            OffsetRect( @captionRect, 1, 1 )
            SetTextColor( dc, GetSysColor( COLOR_3DHILIGHT ) )
            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
            OffsetRect( @captionRect, - 1, - 1 )
            SetTextColor( dc, GetSysColor( COLOR_3DSHADOW ) )
            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
            // if
         ELSE
            //          SetTextColor( dc, GetSysColor( COLOR_BTNTEXT ) )
            //            SetBkColor( dc, GetSysColor( COLOR_BTNFACE ) )
            //            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
            IF ( ::bMouseOverButton .or. bIsPressed )
               SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_IN ] )
               SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_IN ] )
               fillRect := COPYRECT( itemRect )
               IF bIsPressed
                  DrawButton( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], 6 )
               ENDIF
               InflateRect( @fillRect, - 2, - 2 )
               FillRect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_IN ]:handle )
            ELSE
               IF ( bIsFocused )
                  SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_FOCUS ] )
                  SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_FOCUS ] )
                  fillRect := COPYRECT( itemRect )
                  InflateRect( @fillRect, - 2, - 2 )
                  FillRect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_FOCUS ]:handle )
               ELSE
                  SetTextColor( dc, ::m_crColors[ BTNST_COLOR_FG_OUT ] )
                  SetBkColor( dc, ::m_crColors[ BTNST_COLOR_BK_OUT ] )
                  fillRect := COPYRECT( itemRect )
                  InflateRect( @fillRect, - 2, - 2 )
                  FillRect( dc, fillRect[ 1 ], fillRect[ 2 ], fillRect[ 3 ], fillRect[ 4 ], ::m_crBrush[ BTNST_COLOR_BK_OUT ]:handle )
               ENDIF
            ENDIF
            IF ValType( ::hbitmap ) == "N" .AND. ::m_bDrawTransparent
                DrawTransparentBitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ])
            ELSEIF ValType( ::hbitmap ) == "N" .OR. ValType( ::hicon ) == "N"
                DrawTheIcon( ::handle, dc, bHasTitle, @itemRect1, @captionRect1, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle )
            ENDIF
            IF ( ValType( ::hicon ) == "N" .OR. ValType( ::hbitmap ) == "N" )
               IF lmultiline  .OR. ::iStyle = ST_ALIGN_OVERLAP
                  captionRect := aclone( savecaptionRect )
               ENDIF
            ELSEIF lMultiLine
               captionRect[ 2 ] := (::nHeight  - nHeight ) / 2 + 2
            ENDIF
            DrawText( dc, ::caption, @captionRect[ 1 ], @captionRect[ 2 ], @captionRect[ 3 ], @captionRect[ 4 ], uAlign )
         ENDIF
      ENDIF
   ENDIF

   // Draw the focus rect
   IF bIsFocused .and. bDrawFocusRect .AND. Hwg_BitaND( ::sTyle, WS_TABSTOP ) != 0
      focusRect := COPYRECT( itemRect )
      InflateRect( @focusRect, - 3, - 3 )
      DrawFocusRect( dc, focusRect )
   ENDIF
   DeleteObject( br )
   DeleteObject( brBackground )
   DeleteObject( brBtnShadow )

   RETURN NIL

METHOD PAINTBK( hdc ) CLASS HBUTTONEx

   LOCAL clDC := HclientDc():New( ::oparent:handle )
   LOCAL rect, rect1

   rect := GetClientRect( ::handle )
   rect1 := GetWindowRect( ::handle )
   ScreenToClient( ::oparent:handle, rect1 )
   IF ValType( ::m_dcBk ) == "U"
      ::m_dcBk := hdc():New()
      ::m_dcBk:CreateCompatibleDC( clDC:m_hDC )
      ::m_bmpBk := CreateCompatibleBitmap( clDC:m_hDC, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 2 ] )
      ::m_pbmpOldBk := ::m_dcBk:SelectObject( ::m_bmpBk )
      ::m_dcBk:BitBlt( 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], clDC:m_hDc, rect1[ 1 ], rect1[ 2 ], SRCCOPY )
   ENDIF
   BitBlt( hdc, 0, 0, rect[ 3 ] - rect[ 1 ], rect[ 4 ] - rect[ 4 ], ::m_dcBk:m_hDC, 0, 0, SRCCOPY )

   RETURN Self

// CLASS HGroup

CLASS HGroup INHERIT HControl

   CLASS VAR winclass INIT "BUTTON"
   DATA oRGroup
   DATA oBrush
   DATA lTransparent HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup )
   METHOD Activate()
   METHOD Init()
   METHOD Paint( lpDis )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
      oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup ) CLASS HGroup

   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   ::title   := cCaption
   ::oRGroup := oRGroup
   Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
         oFont, bInit, bSize, bPaint,, tcolor, bColor )
   ::oBrush := IIF( bColor != NIL, ::brush,NIL )
   ::lTransparent := IIF( lTransp != NIL, lTransp, .F. )
   ::backStyle := IIF( ( lTransp != NIL .AND. lTransp ) .OR. ::bColor != NIL , TRANSPARENT, OPAQUE )
   ::Activate()
   //::setcolor( tcolor, bcolor )

   RETURN Self

METHOD Activate() CLASS HGroup

   IF ! Empty( ::oParent:handle )
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
            ::title )
      ::Init()
   ENDIF

   RETURN NIL

METHOD Init() CLASS HGroup
   LOCAL nbs

   IF ! ::lInit
      Super:Init()
      // *-IF ::backStyle = TRANSPARENT .OR. ::bColor != NIL
      IF ::oBrush != NIL .OR. ::backStyle = TRANSPARENT
         nbs := HWG_GETWINDOWSTYLE( ::handle )
         nbs := modstyle( nbs, BS_TYPEMASK , BS_OWNERDRAW + WS_DISABLED )
         HWG_SETWINDOWSTYLE ( ::handle, nbs )
         ::bPaint   := { | o, p | o:paint( p ) }
      ENDIF
      IF ::oRGroup != NIL
         ::oRGroup:Handle := ::handle
         ::oRGroup:id := ::id
         ::oFont := ::oRGroup:oFont
         ::oRGroup:lInit := .f.
         ::oRGroup:Init()
      ELSE
         IF ::oBrush != NIL
            /*
            nbs :=  AScan( ::oparent:acontrols, { | o | o:handle == ::handle } )
            FOR i := LEN( ::oparent:acontrols ) TO 1 STEP - 1
               IF nbs != i .AND.;
                  PtInRect( { ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight }, { ::oparent:acontrols[ i ]:nLeft, ::oparent:acontrols[ i ]:nTop } ) //.AND. NOUTOBJS = 0
                  SetWindowPos( ::oparent:acontrols[ i ]:handle, ::Handle, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE + SWP_FRAMECHANGED )
               ENDIF
            NEXT
            */
            SetWindowPos( ::Handle, NIL, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE )
         ELSE
            SetWindowPos( ::Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE + SWP_NOSENDCHANGING )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

METHOD PAINT( lpdis ) CLASS HGroup
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL DC := drawInfo[ 3 ]
   LOCAL ppnOldPen, pnFrmDark,   pnFrmLight, iUpDist
   LOCAL szText, aSize, dwStyle
   LOCAL rc  := copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ] - 1, drawInfo[ 7 ] - 1 } )
   LOCAL rcText

   // determine text length
   szText := ::Title
   aSize := TxtRect( IIF( Empty( szText ), "A", szText ), Self )
   // distance from window top to group rect
   iUpDist := ( aSize[ 2 ] / 2 )
   dwStyle := ::Style //HWG_GETWINDOWSTYLE( ::handle ) //GetStyle();
   rcText := { 0, rc[ 2 ] + iUpDist , 0, rc[ 2 ] + iUpDist  }
   IF Empty( szText )
   ELSEIF hb_BitAnd( dwStyle, BS_CENTER ) == BS_RIGHT // right aligned
      rcText[ 3 ] := rc[ 3 ] + 2 - OFS_X
      rcText[ 1 ] := rcText[ 3 ] - aSize[ 1 ]
   ELSEIF hb_BitAnd( dwStyle, BS_CENTER ) == BS_CENTER  // text centered
      rcText[ 1 ] := ( rc[ 3 ] - rc[ 1 ]  - aSize[ 1 ]  ) / 2
      rcText[ 3 ] := rcText[ 1 ] + aSize[ 1 ]
   ELSE //((!(dwStyle & BS_CENTER)) || ((dwStyle & BS_CENTER) == BS_LEFT))// left aligned   / default
      rcText[ 1 ] := rc[ 1 ] + OFS_X
      rcText[ 3 ] := rcText[ 1 ] + aSize[ 1 ]
   ENDIF
   SetBkMode( dc, TRANSPARENT )

   IF Hwg_BitAND( dwStyle, BS_FLAT) != 0  // "flat" frame
      //pnFrmDark  := CreatePen( PS_SOLID, 1, RGB(0, 0, 0) ) )
      pnFrmDark  := HPen():Add( PS_SOLID, 1,  RGB( 64, 64, 64 ) )
      pnFrmLight := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      ppnOldPen := SelectObject( dc, pnFrmDark:Handle )
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ]  )
      LineTo( dc, rc[ 1 ], rcText[ 2 ] )
      LineTo( dc, rc[ 1 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rcText[ 4 ] )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] )
      SelectObject( dc, pnFrmLight:handle)
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ] + 1 )
      LineTo( dc, rc[ 1 ] + 1, rcText[ 2 ] + 1)
      LineTo( dc, rc[ 1 ] + 1, rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rcText[ 4 ] + 1 )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] + 1 )
    ELSE // 3D frame
      pnFrmDark  := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DSHADOW ) )
      pnFrmLight := HPen():Add( PS_SOLID, 1, GetSysColor( COLOR_3DHILIGHT ) )
      ppnOldPen := SelectObject( dc, pnFrmDark:handle )
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ] )
      LineTo( dc, rc[ 1 ], rcText[ 2 ] )
      LineTo( dc, rc[ 1 ], rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rc[ 4 ] - 1 )
      LineTo( dc, rc[ 3 ] - 1, rcText[ 4 ] )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] )
      SelectObject( dc, pnFrmLight:handle )
      MoveTo( dc, rcText[ 1 ] - 2, rcText[ 2 ] + 1 )
      LineTo( dc, rc[ 1 ] + 1, rcText[ 2 ] + 1 )
      LineTo( dc, rc[ 1 ] + 1, rc[ 4 ] - 1 )
      MoveTo( dc, rc[ 1 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rc[ 4 ] )
      LineTo( dc, rc[ 3 ], rcText[ 4 ] - 1)
      MoveTo( dc, rc[ 3 ] - 2, rcText[ 4 ] + 1 )
      LineTo( dc, rcText[ 3 ], rcText[ 4 ] + 1 )
   ENDIF
   // draw text (if any)
   IF !Empty( szText ) && !(dwExStyle & (BS_ICON|BS_BITMAP)))
      SetBkMode( dc, TRANSPARENT )
      IF ::oBrush != NIL
         FillRect( DC, rc[ 1 ] + 2, rc[ 2 ] + iUpDist + 2 , rc[ 3 ] - 2, rc[ 4 ] - 2 , ::brush:handle )
         IF ! ::lTransparent
            FillRect( DC, rcText[ 1 ] - 2, rc[ 2 ] + 1 ,  rcText[ 3 ] + 1, rc[ 2 ] + iUpDist + 2 , ::brush:handle )
         ENDIF
      ENDIF
      DrawText( dc, szText, rcText, DT_VCENTER + DT_LEFT + DT_SINGLELINE + DT_NOCLIP )
   ENDIF
   // cleanup
   DeleteObject( pnFrmLight )
   DeleteObject( pnFrmDark )
   SelectObject( dc, ppnOldPen )

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

   Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,bInit, ;
         bSize, { | o, lp | o:Paint( lp ) } , , tcolor )

   ::title := ""
   ::lVert := IIf( lVert == NIL, .F., lVert )
   ::LineSlant := IIF( EMPTY( cSlant ) .OR. ! cSlant $ "/\", "", cSlant )
   ::nBorder := IIF( EMPTY( nBorder ), 1, nBorder )

   IF EMPTY( ::LineSlant )
      IF ::lVert
         ::nWidth  := ::nBorder + 1 //10
         ::nHeight := IIf( nLength == NIL, 20, nLength )
      ELSE
         ::nWidth  := IIf( nLength == NIL, 20, nLength )
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

   IF EMPTY( ::LineSlant )
      IF ::lVert
         // DrawEdge( hDC,x1,y1,x1+2,y2,EDGE_SUNKEN,BF_RIGHT )
         DrawLine( hDC, x1 + 1, y1, x1 + 1, y2 )
      ELSE
         // DrawEdge( hDC,x1,y1,x2,y1+2,EDGE_SUNKEN,BF_RIGHT )
         DrawLine( hDC, x1 , y1 + 1, x2, y1 + 1 )
      ENDIF
      SelectObject( hDC, ::oPenGray:handle )
      IF ::lVert
         DrawLine( hDC, x1, y1, x1, y2 )
      ELSE
         DrawLine( hDC, x1, y1, x2, y1 )
      ENDIF
   ELSE
      IF ( x2 - x1 ) <= ::nBorder //.OR. ::nWidth <= ::nBorder
         DrawLine( hDC, x1, y1, x1, y2 )
      ELSEIF ( y2 - y1 ) <= ::nBorder //.OR. ::nHeight <= ::nBorder
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
