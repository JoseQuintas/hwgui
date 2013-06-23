/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HStaticLink class
 *
*/

#include "hbclass.ch"
#include "common.ch"
#include "hwgui.ch"

#define _HYPERLINK_EVENT   WM_USER + 101
#define LBL_INIT           0
#define LBL_NORMAL         1
#define LBL_VISITED        2
#define LBL_MOUSEOVER      3
#define TRANSPARENT        1
#define MENU_POPUPITEM     14
#define MPI_HOT            2

*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
*+    Class HStaticLink
*+
*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
CLASS HStaticLink FROM HSTATICEX

   DATA state
   DATA m_bFireChild INIT .F.

   DATA m_hHyperCursor INIT hwg_Loadcursor( 32649 )

   DATA m_bMouseOver INIT .F.
   DATA m_bVisited INIT .F.

   DATA m_oTextFont
   DATA m_csUrl
   DATA dc

   DATA m_sHoverColor
   DATA m_sLinkColor
   DATA m_sVisitedColor
   
   DATA allMouseOver INIT .F.
   DATA hBitmap
   DATA iStyle         INIT ST_ALIGN_HORIZ  //ST_ALIGN_HORIZ_RIGHT
   DATA lAllUnderline  INIT .T.
   DATA oFontUnder
   DATA llost INIT .F.
   DATA lOverTitle    INIT .F.
   DATA nWidthOver


CLASS VAR winclass INIT "STATIC"

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
               bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor, hbitmap, bClick )
   METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                    bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor )
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
   METHOD PAint( lpDis ) 
   METHOD OnMouseMove( nFlags, lParam )
   METHOD Resize( x, y )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
            bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor, hbitmap, bClick ) CLASS HStaticLink
   LOCAL oPrevFont
   
   nStyle := Hwg_BitOR( nStyle, SS_NOTIFY + SS_RIGHT  )
   ::lAllUnderline := IIF( EMPTY( cLink ), .F., ::lAllUnderline )
   ::title := IIF(cCaption != Nil,cCaption ,"HWGUI HomePage")
   ::hbitmap := hbitmap

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, bClick )

   DEFAULT vColor TO hwg_Rgb( 5, 34, 143 )
   DEFAULT lColor TO hwg_Rgb( 0, 0, 255 )
   DEFAULT hColor TO hwg_Rgb( 255, 0, 0 )
   ::m_csUrl := cLink
   ::m_sHoverColor   := hColor
   ::m_sLinkColor    := lColor
   ::m_sVisitedColor := vColor

   ::state := LBL_INIT
   ::title := IIf( cCaption == Nil, "", cCaption )

   // Test The Font the underline must be 1
   IF ::oFont == NIL
      IF ::oParent:oFont != NIL
         ::oFont := HFONT():Add( ::oParent:oFont:name, ::oParent:oFont:width, ::oParent:oFont:height, ;
                                 ::oParent:oFont:weight, ::oParent:oFont:charset, ::oParent:oFont:italic, 1, ::oParent:oFont:StrikeOut )
      ELSE
         ::oFont := HFONT():Add( "Arial", 0, - 12, , , , IIF( ::lAllUnderline, 1, ), )
      ENDIF
   ELSE
      IF ::oFont:Underline  == 0 .AND. ::lAllUnderline
         oPrevFont := ::oFont
         ::oFont:Release()
         ::oFont := HFONT():Add( oPrevFont:name, oPrevFont:width, oPrevFont:height, ;
                                 oPrevFont:weight, oPrevFont:charset, oPrevFont:italic, 1, oPrevFont:StrikeOut )
      ENDIF
   ENDIF
   ::oFontUnder := HFONT():Add( ::oFont:Name, 0, ::oFont:Height, , , , 1 )
   ::nWidthOver := nWidth
   IF lTransp != NIL .AND. lTransp
      //::extStyle += WS_EX_TRANSPARENT
      ::backstyle := TRANSPARENT
   ENDIF

   RETURN Self

METHOD Redefine( oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, cLink, vColor, lColor, hColor )  CLASS HStaticLink
   LOCAL oPrevFont

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor )

   DEFAULT vColor TO hwg_Rgb( 5, 34, 143 )
   DEFAULT lColor TO hwg_Rgb( 0, 0, 255 )
   DEFAULT hColor TO hwg_Rgb( 255, 0, 0 )
   ::state := LBL_INIT
   ::m_csUrl := cLink
   ::m_sHoverColor   := hColor
   ::m_sLinkColor    := lColor
   ::m_sVisitedColor := vColor

   IF ::oFont == NIL
      IF ::oParent:oFont != NIL
         ::oFont := HFONT():Add( ::oParent:oFont:name, ::oParent:oFont:width, ::oParent:oFont:height, ;
                                 ::oParent:oFont:weight, ::oParent:oFont:charset, ::oParent:oFont:italic, 1, ::oParent:oFont:StrikeOut )
      ENDIF
   ELSE
      IF ::oFont:Underline  == 0
         oPrevFont := ::oFont
         ::oFont:Release()
         ::oFont := HFONT():Add( oPrevFont:name, oPrevFont:width, oPrevFont:height, ;
                                 oPrevFont:weight, oPrevFont:charset, oPrevFont:italic, 1, oPrevFont:StrikeOut )
      ENDIF
   ENDIF

   ::title   := cCaption
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   IF lTransp != NIL .AND. lTransp
      //::extStyle += WS_EX_TRANSPARENT
      ::backstyle := TRANSPARENT
   ENDIF

   RETURN Self

METHOD INIT() CLASS HStaticLink

   IF ! ::lInit
      ::Resize( )
      ::Super:init()
      IF ::Title != NIL
         hwg_Setwindowtext( ::handle, ::title )
      ENDIF

   ENDIF

   RETURN NIL

METHOD onEvent( msg, wParam, lParam ) CLASS HStaticLink

   IF ( msg = WM_SETFOCUS .OR. msg = WM_KILLFOCUS ) .AND. Hwg_BitaND( ::sTyle, WS_TABSTOP ) != 0
      hwg_Redrawwindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT , ::nLeft, ::nTop, ::nWidth, ::nHeight )
      
   ELSEIF msg == WM_PAINT
      //::PAint( )
      
   ELSEIF msg == WM_MOUSEMOVE
      hwg_SetCursor( ::m_hHyperCursor )
     ::OnMouseMove( wParam, lParam )
   ELSEIF ( msg = WM_MOUSELEAVE .OR. msg = WM_NCMOUSELEAVE )
     ::state := LBL_NORMAL
     hwg_Invalidaterect( ::handle, 0 )
     hwg_Redrawwindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT , ::nLeft, ::nTop, ::nWidth, ::nHeight )

   ELSEIF msg =  WM_MOUSEHOVER
   ELSEIF msg == WM_SETCURSOR
      ::OnSetCursor( msg, wParam, lParam )

   ELSEIF msg == WM_LBUTTONDOWN
      hwg_SetCursor( ::m_hHyperCursor )
      ::OnClicked()
   ELSEIF msg == WM_SIZE

   ELSEIF msg = WM_KEYDOWN

      IF ( ( wParam == VK_SPACE ) .OR. ( wParam == VK_RETURN ) )
         hwg_Sendmessage( ::handle, WM_LBUTTONDOWN, 0, hwg_Makelparam( 1, 1 ) )
         RETURN 0
      ELSEIF wParam = VK_DOWN
         hwg_GetSkip( ::oparent, ::handle,, 1 )
      ELSEIF   wParam = VK_UP
         hwg_GetSkip( ::oparent, ::handle,, - 1 )
      ELSEIF wParam = VK_TAB
         hwg_GetSkip( ::oParent, ::handle, , IIF( hwg_IsCtrlShift( .F., .T.), -1, 1 ) )
      ENDIF
      RETURN 0
   ELSEIF msg == WM_KEYUP
      /*
      IF ( wParam == VK_SPACE .OR. wParam == VK_RETURN  )
       *  hwg_Sendmessage( ::handle, WM_LBUTTONUP, 0, hwg_Makelparam( 1, 1 ) )
       *  hwg_Msginfo('k')
         RETURN 0
      ENDIF
      */
   ELSEIF msg = WM_GETDLGCODE
      RETURN IIF( wParam == VK_RETURN, DLGC_WANTMESSAGE, DLGC_WANTARROWS + DLGC_WANTTAB )

   ENDIF
   RETURN - 1

METHOD GoToLinkUrl( csLink ) CLASS HStaticLink

   LOCAL hInstance := hwg_Shellexecute( csLink, "open", NIL, NIL, 2 )
   //hwg_Shellexecute(NULL              , _T("open")                             , csLink.operator LPCTSTR(), NULL                                 , NULL                                   , 2);

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

   IF ISBLOCK( ::bClick )
      ::state := LBL_NORMAL

   ELSEIF !EMPTY( ::m_csUrl)
      IF ( ::m_bFireChild )
         nCtrlID := ::id
         ::Sendmessage( ::oparent:Handle, _HYPERLINK_EVENT, nCtrlID, 0 )
      ELSE
         ::GoToLinkUrl( ::m_csUrl )
      ENDIF
      ::m_bVisited := .T.
      ::state := LBL_NORMAL
      hwg_Invalidaterect( ::handle, 0 )
      hwg_Redrawwindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT  , ::nLeft, ::nTop, ::nWidth, ::nHeight )
   ENDIF
   ::Setfocus( )

   RETURN NIL

METHOD OnSetCursor( pWnd, nHitTest, message ) CLASS HStaticLink

   HB_SYMBOL_UNUSED( pWnd )
   HB_SYMBOL_UNUSED( nHitTest )
   HB_SYMBOL_UNUSED( message )

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

   HB_SYMBOL_UNUSED( nFlags )

   IF ::state != LBL_INIT
      xPos := hwg_Loword( lParam )
      yPos := hwg_Hiword( lParam )
      IF (  ! hwg_Ptinrect( { 0, 0, ::nWidthOver , ::nHeight }, { xPos, yPos } ) ) .AND. ::state != LBL_MOUSEOVER
          res := .T.
      ELSE
        hwg_SetCursor( ::m_hHyperCursor )
        IF ( !  hwg_Ptinrect( { 4, 4, ::nWidthover - 4, ::nHeight - 4 }, { xPos, yPos } ) )
          // hwg_Releasecapture()
           res := .T.
        ENDIF
      ENDIF
      IF ( res .AND. ! ::m_bVisited ) .or. ( res .AND. ::m_bVisited )
         ::state := LBL_NORMAL
         /*
         hwg_Invalidaterect( ::handle, 0 )
         hwg_Redrawwindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT , ::nLeft, ::nTop, ::nWidth, ::nHeight )
         */
      ENDIF
      IF ( ::state == LBL_NORMAL .AND. ! res ) .or. ;
         ( ::state == LBL_NORMAL .AND. ! res .and. ::m_bVisited )
         ::state := LBL_MOUSEOVER
         hwg_Invalidaterect( ::handle, 0 )
    	    hwg_Redrawwindow( ::oParent:Handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT , ::nLeft, ::nTop, ::nWidth, ::nHeight )
         //hwg_Setcapture( ::handle )
      ENDIF
   ENDIF
   hwg_Trackmousevent( ::handle,  TME_LEAVE )
   
   RETURN NIL

METHOD PAint( lpDis ) CLASS HStaticLink
   LOCAL drawInfo := hwg_Getdrawiteminfo( lpDis )
   LOCAL dc := drawInfo[ 3 ]
   LOCAL strtext    := ::Title
//   LOCAL nOldBkMode
   LOCAL dwFlags
//   LOCAL clrOldText
   LOCAL rcClient
//   LOCAL POLDFONT
//   LOCAL DWSTYLE
   LOCAL bHasTitle
   LOCAL aBmpSize    := IIF( ! EMPTY( ::hbitmap ), hwg_Getbitmapsize( ::hbitmap ),{0,0} )
   LOCAL itemRect    := hwg_Copyrect( { drawInfo[ 4 ], drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   LOCAL captionRect := { drawInfo[ 4 ]  , drawInfo[ 5 ], drawInfo[ 6 ] , drawInfo[ 7 ]  }
   LOCAL bmpRect, focusRect, hTheme
   
   IF ::state == LBL_INIT
      ::State := LBL_NORMAL
   ENDIF
   focusrect := hwg_Copyrect( { drawInfo[ 4 ] , drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   rcClient  := hwg_Copyrect( { drawInfo[ 4 ] , drawInfo[ 5 ], drawInfo[ 6 ], drawInfo[ 7 ] } )
   
   // Draw the focus rect
   IF hwg_Selffocus( ::handle ) .AND. Hwg_BitaND( ::sTyle, WS_TABSTOP ) != 0
      hwg_Setbkmode( dc, TRANSPARENT )
      hwg_Drawfocusrect( dc, focusRect )
      IF hwg_Isthemedload() .AND. ::WindowsManifest
         hTheme := hwg_openthemedata( ::handle, "MENU" )
         hwg_drawthemebackground( hTheme, dc, MENU_POPUPITEM, MPI_HOT, focusRect, Nil )
         hwg_closethemedata( htheme )
      ENDIF
   ENDIF

   IF  ValType( ::hbitmap ) == "N"
      bHasTitle := ValType( strtext ) == "C" .and. ! Empty( strtext )
      itemRect[ 4 ] := aBmpSize[ 2 ] + 1
      bmpRect := hwg_Prepareimagerect( ::handle, dc, bHasTitle, @itemRect, @captionRect, , , ::hbitmap, ::iStyle )
      itemRect[ 4 ] := drawInfo[ 7 ]
      IF ::backstyle = TRANSPARENT
         hwg_Drawtransparentbitmap( dc, ::hbitmap, bmpRect[ 1 ], bmpRect[ 2 ] + 1 )
      ELSE
         hwg_Drawbitmap( dc, ::hbitmap, , bmpRect[ 1 ], bmpRect[ 2 ] + 1 )
      ENDIF
      rcclient[ 1 ] +=  IIF( ::iStyle = ST_ALIGN_HORIZ, aBmpSize[ 1 ] + 8, 1 )
      rcclient[ 2 ] +=  2
   ELSEIF Hwg_BitaND( ::sTyle, WS_TABSTOP ) != 0
      rcclient[ 1 ] += 3
      rcclient[ 2 ] += 1
   ENDIF
   hwg_Setbkmode( DC, ::backstyle )
   IF ::backstyle != TRANSPARENT
      hwg_Setbkcolor( DC,  IIF( ::bColor = NIL, hwg_Getsyscolor( COLOR_3DFACE ), ::bcolor ) )
      hwg_Fillrect( dc, rcclient[ 1 ], rcclient[ 2 ], rcclient[ 3 ], rcclient[ 4 ] ) //, ::brush:handle )
   ENDIF
   dwFlags    := DT_LEFT + DT_WORDBREAK
   //dwstyle    := ::style
   dwFlags  += ( DT_VCENTER + DT_END_ELLIPSIS )
   
   //::dc:Selectobject( ::oFont:handle )
   hwg_Selectobject( dc, ::oFont:handle )
   IF ::state == LBL_NORMAL
      IF ::m_bVisited
         //::dc:Settextcolor( ::m_sVisitedColor )
         hwg_Settextcolor( DC,::m_sVisitedColor )
      ELSE
         //::dc:Settextcolor( ::m_sLinkColor )
         hwg_Settextcolor( DC, ::m_sLinkColor )
      ENDIF
   ELSEIF ::state == LBL_MOUSEOVER
      //::dc:Settextcolor( ::m_sHoverColor )
      hwg_Settextcolor( DC,::m_sHoverColor )
   ENDIF

   //::dc:Drawtext( strtext, rcClient, dwFlags )
   IF ::state = LBL_MOUSEOVER .AND. ! ::lAllUnderline
      hwg_Selectobject( DC, ::oFontUnder:handle )
      hwg_Drawtext( dc, strText, rcClient, dwFlags )
      hwg_Selectobject( DC, ::oFont:handle )
   ELSE
      hwg_Drawtext( dc, strText, rcClient, dwFlags )
   ENDIF

  // ::dc:END()

  RETURN NIL


METHOD Resize( x, y ) CLASS HStaticLink
   //LOCAL aCoors := hwg_Getclientrect( ::handle )
   LOCAL aBmpSize, aTxtSize
   LOCAL nHeight := ::nHeight
   
   IF x != Nil .AND. x + y = 0
      RETURN Nil
   ENDIF

   x := iif( x == Nil, 0, x - ::nWidth + 1 )
   aBmpSize := IIF( ! EMPTY( ::hbitmap ), hwg_Getbitmapsize( ::hbitmap ), { 0,0 } )
   aBmpSize[ 1 ] += IIF( aBmpSize[ 1 ] > 0, 6, 0 )
   ::Move( , , ::nWidth + x , , 0 )
   aTxtSize := hwg_TxtRect( ::Title, Self )
   aTxtSize[ 2 ] += IIF( ::lAllUnderline, 0, 3 )
   IF aTxtSize[ 1 ] + 1  <  ::nWidth - aBmpSize[ 1 ] //tava 20
      ::nHeight := aTxtSize[ 2 ] + 2
   ELSE
      ::nHeight := aTxtSize[ 2 ] * 2 + 1
   ENDIF
   ::nWidthOver  := MIN( aTxtSize[ 1 ] + 1 + aBmpSize[ 1 ], ::nWidth )
   ::nHeight := MAX( ::nHeight, aTxtSize[ 2 ] )
   ::nHeight := MAX( ::nHeight, aBmpSize[ 2 ] + 4 )

   IF nHeight != ::nHeight
      ::Move( , , , ::nHeight , 0 )
      hwg_Invalidaterect( ::Handle, 0 )
   ENDIF

   RETURN Nil
