/*
 * $Id: hhyper.prg,v 1.3 2005-10-26 07:43:26 omm Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HStaticLink class
 *
*/

#include "hbclass.ch"
#include "common.ch"
#include "hwgui.ch"

#define _HYPERLINK_EVENT WM_USER + 101
#define LBL_INIT    0
#define LBL_NORMAL  1
#define LBL_VISITED 2
#define LBL_MOUSEOVER 3

*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
*+    Class HStaticLink
*+
*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
CLASS HStaticLink FROM HSTATIC

   DATA state
   DATA m_bFireChild INIT .F.

   DATA m_hHyperCursor INIT LoadCursor( 32649 )

   DATA m_bMouseOver INIT .F.
   DATA m_bVisited INIT .F.

   DATA m_oTextFont
   DATA m_csUrl
   DATA dc

   DATA m_sHoverColor
   DATA m_sLinkColor
   DATA m_sVisitedColor

   CLASS VAR winclass INIT "STATIC"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor )
   METHOD Redefine( oWndParent,nId,oFont,bInit, ;
              bSize,bPaint,ctooltip,tcolor,bcolor,lTransp, cLink, vColor, lColor, hColor )
   METHOD INIT()
   METHOD onEvent( msg, wParam, lParam )
   METHOD GoToLinkUrl( csLink )
   METHOD GetLinkText()
   METHOD SetLinkUrl( csUrl )
   METHOD GetLinkUrl()
   METHOD SetVisitedColor( sVisitedColor )
   METHOD SetHoverColor( cHoverColor )
   METHOD SetFireChild( lFlag )  INLINE ::m_bFireChild := lFlag
   METHOD OnClicked()
   METHOD OnSetCursor( pWnd, nHitTest, message )
   METHOD SetLinkText( csLinkText )
   METHOD SetLinkColor( sLinkColor )
   METHOD PAINT()
   METHOD OnMouseMove( nFlags, point )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
               bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor ) CLASS HStaticLink
Local oPrevFont

   super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor, lTransp )

   DEFAULT vcolor TO RGB( 5, 34, 143 )
   DEFAULT lcolor TO RGB( 0, 0, 255 )
   DEFAULT hcolor TO RGB( 255, 0, 0 )
   ::m_csUrl := cLink
   ::m_sHoverColor   := hColor
   ::m_sLinkColor    := lColor
   ::m_sVisitedColor := vColor

   ::state := LBL_INIT
   ::title := cCaption

   // Test The Font the underline must be 1
   IF ::oFont == NIL
      IF ::oParent:oFont != NIL
         ::OFont := HFONT():Add( ::oParent:oFont:name, ::oParent:oFont:width, ::oParent:oFont:height,;
         ::oParent:oFont:weight, ::oParent:oFont:charset, ::oParent:oFont:italic, 1, ::oParent:oFont:StrikeOut )
      ENDIF
   ELSE
      IF ::oFont:Underline  == 0
         oPrevFont := ::oFont
         ::oFont:Release()
         ::OFont := HFONT():Add( oPrevFont:name, oPrevFont:width, oPrevFont:height,;
         oPrevFont:weight, oPrevFont:charset, oPrevFont:italic, 1, oPrevFont:StrikeOut )
      ENDIF
   ENDIF

   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

   ::Activate()

RETURN Self

METHOD Redefine( oWndParent,nId,cCaption,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor,lTransp, cLink, vColor, lColor, hColor )  CLASS HStaticLink
Local oPrevFont
   Super:New( oWndParent,nId,0,0,0,0,0,oFont,bInit, ;
                  bSize,bPaint,ctooltip,tcolor,bcolor )

   DEFAULT vcolor TO RGB( 5, 34, 143 )
   DEFAULT lcolor TO RGB( 0, 0, 255 )
   DEFAULT hcolor TO RGB( 255, 0, 0 )
   ::state := LBL_INIT
   ::m_csUrl := cLink
   ::m_sHoverColor   := hColor
   ::m_sLinkColor    := lColor
   ::m_sVisitedColor := vColor

   IF ::oFont == NIL
       IF ::oParent:oFont != NIL
         ::OFont := HFONT():Add( ::oParent:oFont:name, ::oParent:oFont:width, ::oParent:oFont:height,;
         ::oParent:oFont:weight, ::oParent:oFont:charset, ::oParent:oFont:italic, 1, ::oParent:oFont:StrikeOut )
      ENDIF
   ELSE
      IF ::oFont:Underline  == 0
         oPrevFont := ::oFont
         ::oFont:Release()
         ::OFont := HFONT():Add( oPrevFont:name, oPrevFont:width, oPrevFont:height,;
         oPrevFont:weight, oPrevFont:charset, oPrevFont:italic, 1, oPrevFont:StrikeOut )
      ENDIF
   ENDIF

   ::title   := cCaption
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   IF lTransp != NIL .AND. lTransp
      ::extStyle += WS_EX_TRANSPARENT
   ENDIF

Return Self

METHOD INIT CLASS HStaticLink

   IF !::lInit
      Super:init()
      IF ::Title != NIL
         SETWINDOWTEXT( ::handle, ::title )
      ENDIF
   ENDIF
   SetWindowObject( ::handle, Self )
   Hwg_InitWinCtrl( ::handle )

RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HStaticLink


   IF msg == WM_PAINT
      ::PAint()
   ELSEIF msg == WM_MOUSEMOVE
      hwg_SetCursor( ::m_hHyperCursor )
      ::OnMouseMove( wParam, lParam )
   ELSEIF msg == WM_SETCURSOR
      ::OnSetCursor( msg, wParam, lParam )
   ELSEIF msg == WM_LBUTTONDOWN
      hwg_SetCursor( ::m_hHyperCursor )
      ::OnClicked()
   ENDIF

RETURN - 1

METHOD GoToLinkUrl( csLink ) CLASS HStaticLink

LOCAL hInstance := SHELLEXECUTE( csLink, "open", NIL, NIL, 2 )
   //ShellExecute(NULL              , _T("open")                             , csLink.operator LPCTSTR(), NULL                                 , NULL                                   , 2);

   IF hInstance < 33
      RETURN .f.
   ENDIF

RETURN .t.

METHOD GetLinkText() CLASS HStaticLink

   IF ( Empty( ::Title ) )
      RETURN ""
   ENDIF

RETURN ::Title

METHOD SetLinkUrl( csUrl ) CLASS HStaticLink

   ::m_csUrl := csUrl

RETURN NIL

METHOD GetLinkUrl() CLASS HStaticLink

RETURN ::m_csUrl

METHOD SetVisitedColor( sVisitedColor ) CLASS HStaticLink

   ::m_sVisitedColor := sVisitedColor
RETURN NIL

METHOD SetHoverColor( cHoverColor ) CLASS HStaticLink

   ::m_sHoverColor := cHoverColor

RETURN NIL

METHOD OnClicked() CLASS HStaticLink
LOCAL nCtrlID

   IF ( ::m_bFireChild )
      nCtrlID := ::id
      ::SendMessage( ::oparent:Handle, _HYPERLINK_EVENT, nCtrlID, 0 )
      //::PostMessage(pParent->m_hWnd, __EVENT_ID_, (WPARAM)nCtrlID, 0)
   ELSE
      ::GoToLinkUrl( ::m_csUrl )
   ENDIF

   ::m_bVisited := .T.

   ::state := LBL_NORMAL
   InvalidateRect( ::handle, 0 )
   SetFocus( ::handle )
   PostMessage( ::handle, WM_PAINT, 0, 0 )

RETURN NIL

METHOD OnSetCursor( pWnd, nHitTest, message ) CLASS HStaticLink

   hwg_SetCursor( ::m_hHyperCursor )

RETURN .t.

METHOD SetLinkText( csLinkText ) CLASS HStaticLink

   ::Title := csLinkText
   ::SetText( csLinkText )

RETURN NIL

METHOD SetLinkColor( sLinkColor ) CLASS HStaticLink

   ::m_sLinkColor := sLinkColor

RETURN NIL

METHOD OnMouseMove( nFlags, lParam ) CLASS HStaticLink

LOCAL xPos
LOCAL yPos
LOCAL res  := .f.

   IF ::state != LBL_INIT
      xPos := LoWord( lParam )
      yPos := HiWord( lParam )
      IF xPos > ::nWidth .OR. yPos > ::nHeight
         ReleaseCapture()
         res := .T.
      ENDIF

      IF (res .AND. !::m_bVisited) .or. (res .AND. ::m_bVisited)

         ::state := LBL_NORMAL
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
      ENDIF
      IF (::state == LBL_NORMAL .AND. !res) .or. ;
              (::state == LBL_NORMAL .AND. !res .and. ::m_bVisited )
         ::state := LBL_MOUSEOVER
         InvalidateRect( ::handle, 0 )
         PostMessage( ::handle, WM_PAINT, 0, 0 )
         SetCapture( ::handle )
      ENDIF

   ENDIF
RETURN NIL

METHOD PAint() CLASS HStaticLink

LOCAL pps
LOCAL hDC
LOCAL aCoors
LOCAL aMetr
LOCAL oPen
LOCAL oldBkColor
LOCAL x1
LOCAL y1
LOCAL x2
LOCAL y2
LOCAL strtext    := ::Title
LOCAL nOldBkMode
LOCAL dwFlags
LOCAL Brush
LOCAL f
LOCAL clrOldText
LOCAL rcClient
LOCAL rgn
LOCAL rc
LOCAL POLDFONT
LOCAL DWSTYLE
LOCAL hRect

   ::dc := HPAINTDC():new( ::handle )
   IF ::state == LBL_INIT
      ::State := LBL_NORMAL
   ENDIF

   rcClient   := GetClientRect( ::handle )
   nOldBkMode :=::dc:SetBkMode( TRANSPARENT )
   dwFlags    := 0
   dwstyle    := ::style

#ifdef __XHARBOUR__
   SWITCH( dwstyle & SS_TYPEMASK )
   CASE SS_RIGHT
      dwFlags := DT_RIGHT | DT_WORDBREAK
      EXIT
   CASE SS_CENTER
      dwFlags := SS_CENTER | DT_WORDBREAK
      EXIT
   CASE SS_LEFTNOWORDWRAP
      dwFlags := DT_LEFT
      EXIT
      DEFAULT
      dwFlags := DT_LEFT | DT_WORDBREAK
      EXIT
   END
#endif
   dwFlags  += ( DT_VCENTER + DT_END_ELLIPSIS )

   pOldFont :=::dc:SelectObject( ::oFont:handle )
   IF ::state == LBL_NORMAL
      IF ::m_bVisited
          clrOldText :=::dc:SetTextColor( ::m_sVisitedColor )
      ELSE
          clrOldText :=::dc:SetTextColor( ::m_sLinkColor )
      ENDIF
   ELSEIF ::state == LBL_MOUSEOVER
      clrOldText :=::dc:SetTextColor( ::m_sHoverColor )
   ENDIF

   ::dc:DrawText( strText, rcClient, dwFlags )
   ::dc:end()

RETURN NIL

