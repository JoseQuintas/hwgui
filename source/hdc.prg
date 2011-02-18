/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HPAINTDC and HDC Classes
 *
 * Copyright 2005 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/

#include "hbclass.ch"
#include "hwgui.ch"

CLASS HPAINTDC FROM HDC

   DATA m_ps

   METHOD NEW( nWnd )
   METHOD END ()

   HIDDEN:
   DATA m_hWnd

ENDCLASS

METHOD NEW( nWnd ) CLASS HPAINTDC

   ::Super:new()
   ::m_ps   := DefinePaintStru()
   ::m_hWnd := nWnd
   ::Attach( BeginPaint( ::m_hWnd, ::m_ps ) )

   RETURN Self

METHOD END () CLASS HPAINTDC

   EndPaint( ::m_hWnd, ::m_ps )
   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

   RETURN NIL

CLASS HDC

   DATA m_hDC
   DATA m_hAttribDC

   METHOD NEW( )
   METHOD SetAttribDC( hDC )
   METHOD ATTACH( hDc )
   METHOD MOVETO( x1, y1 )
   METHOD LINETO( x1, y1 )
   METHOD fillsolidrect( lpRect, clr )
   METHOD fillrect( lpRect, clr )
   METHOD SelectClipRgn( pRgn )
   METHOD SetTextcolor( xColor )
   METHOD SetBkMode( xMode )
   METHOD SetBkColor(  clr ) INLINE    SetBkColor( ::m_hDC, clr )
   METHOD SelectObject( xMode )
   METHOD DrawText( strText, Rect, dwFlags )
   METHOD CreateCompatibleDc( x )
   METHOD patblt( a, s, d, f, g ) INLINE patblt( ::m_hDc, a, s, d, f, g )
   METHOD Savedc()
   METHOD RestoreDC( nSavedDC )
   METHOD SetMapMode( nMapMode )
   METHOD SetWindowOrg( x, y )
   METHOD SetWindowExt( x, y )
   METHOD SetViewportOrg( x, y )
   METHOD SetViewportExt( x, y )
   METHOD SetArcDirection( nArcDirection )
   METHOD GetTextMetric() INLINE GetTextMetric( ::m_hDC )
   METHOD SetROP2( nDrawMode )
   METHOD BitBlt( x,  y,  nWidth,  nHeight,  pSrcDC,  xSrc, ySrc,  dwRop ) INLINE    BitBlt( ::m_hDc, x, y, nWidth, nHeight,  pSrcDC,       xSrc,  ySrc,  dwRop )

   METHOD PIE( arect, apt1, apt2 )
   METHOD DeleteDc()
ENDCLASS

METHOD NEW( ) CLASS HDC

   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

   RETURN Self

METHOD MOVETO( x1, y1 ) CLASS HDC
   MoveTo( ::m_hDC, x1, y1 )
   RETURN Self

METHOD LINETO( x1, y1 ) CLASS HDC
   LineTo( ::m_hDC, x1, y1 )
   RETURN Self

METHOD Attach( hDC ) CLASS HDC

   IF Empty( hDC )
      RETURN .F.
   ENDIF

   ::m_hDC := hDC

   ::SetAttribDC( ::m_hDC )
   return.T.

METHOD deletedc(  ) CLASS HDC
   DeleteDc( ::m_hDC )
   ::m_hDC := nil
   ::m_hAttribDC := nil
   RETURN nil

METHOD SetAttribDC( hDC ) CLASS HDC

   ::m_hAttribDC := hDC
   RETURN NIL

METHOD SelectClipRgn( pRgn ) CLASS HDC

   LOCAL nRetVal := - 1

   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := SelectClipRgn( ::m_hDC, pRgn )
   ENDIF

   IF ! Empty( ::m_hAttribDC  )
      nRetVal := SelectClipRgn( ::m_hAttribDC, pRgn )
   ENDIF

   RETURN nRetVal

METHOD fillsolidrect( lpRect, clr ) CLASS HDC

   SetBkColor( ::m_hDC, clr )
   ExtTextOut( ::m_hDC, 0, 0, lpRect[ 1 ], lpRect[ 2 ], lpRect[ 3 ], lpRect[ 4 ], NIL )

   RETURN NIL

METHOD SetTextColor( xColor ) CLASS HDC

   RETURN SetTextColor( ::m_hDc, xColor )

METHOD SetBkMode( xMode ) CLASS HDC

   RETURN SetBkMode( ::m_hDc, xMode )

METHOD SelectObject( xMode ) CLASS HDC

   RETURN SelectObject( ::m_hDc, xMode )

METHOD DrawText( strText, Rect, dwFlags ) CLASS HDC

   DrawText( ::m_hDC, strText, Rect[ 1 ], Rect[ 2 ], Rect[ 3 ], Rect[ 4 ], dwFlags )

   RETURN NIL

METHOD fillrect( lpRect, clr ) CLASS HDC

   FillRect( ::m_hDC, lpRect[ 1 ], lpRect[ 2 ], lpRect[ 3 ], lpRect[ 4 ], clr )

   RETURN NIL


METHOD CreateCompatibleDc( x ) CLASS HDC
   RETURN ::Attach( CreateCompatibleDC( x ) )

METHOD SAVEDC() CLASS HDC
   LOCAL nRetVal := 0

   IF ( ! Empty( ::m_hAttribDC ) )
      nRetVal := SaveDC( ::m_hAttribDC )
   ENDIF
   IF ( ::m_hDC != ::m_hAttribDC .and. SaveDC( ::m_hDC ) != 0 )
      nRetVal := - 1   // -1 is the only valid restore value for complex DCs
   ENDIF
   RETURN nRetVal

METHOD RestoreDC( nSavedDC ) CLASS HDC

   // if two distinct DCs, nSavedDC can only be -1

   LOCAL bRetVal := .T.
   IF ( ::m_hDC != ::m_hAttribDC )
      bRetVal := RestoreDC( ::m_hDC, nSavedDC )
   ENDIF
   IF ( ! Empty( ::m_hAttribDC ) )
      bRetVal := ( bRetVal .and. RestoreDC( ::m_hAttribDC, nSavedDC ) )
   ENDIF
   RETURN bRetVal

METHOD SetMapMode( nMapMode ) CLASS HDC

   LOCAL nRetVal := 0

   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := ::SetMapMode( ::m_hDC, nMapMode )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      nRetVal := SetMapMode( ::m_hAttribDC, nMapMode )
   ENDIF
   RETURN nRetVal



METHOD SetWindowOrg( x, y ) CLASS HDC


   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      SetWindowOrgEx( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      SetWindowOrgEx( ::m_hAttribDC, x, y, @point )
   ENDIF
   RETURN point


METHOD SetWindowExt( x, y ) CLASS HDC


   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      SetWindowExtEx( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      SetWindowExtEx( ::m_hAttribDC, x, y, @point )
   ENDIF
   RETURN point


METHOD SetViewportOrg( x, y ) CLASS HDC


   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      SetViewportOrgEx( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      SetViewportOrgEx( ::m_hAttribDC, x, y, @point )
   ENDIF
   RETURN point


METHOD SetViewportExt( x, y ) CLASS HDC

   LOCAL point

   IF ( ::m_hDC != ::m_hAttribDC )
      SetViewportExtEx( ::m_hDC, x, y, @point )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      SetViewportExtEx( ::m_hAttribDC, x, y, @point )
   ENDIF
   RETURN point


METHOD SetArcDirection( nArcDirection )


   LOCAL nResult := 0
   IF ( ::m_hDC != ::m_hAttribDC )
      nResult = SetArcDirection( ::m_hDC, nArcDirection )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      nResult = SetArcDirection( ::m_hAttribDC, nArcDirection )
   ENDIF
   RETURN nResult


METHOD PIE( arect, apt1, apt2 )
   RETURN PIE( ::m_hdc, arect[ 1 ], arect[ 2 ], arect[ 3 ], arect[ 4 ], apt1[ 1 ], apt1[ 2 ], apt2[ 1 ], apt2[ 2 ] )

METHOD SetROP2( nDrawMode )


   LOCAL nRetVal := 0

   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := SetROP2( ::m_hDC, nDrawMode )
   ENDIF
   IF ! Empty( ::m_hAttribDC )
      nRetVal := SetROP2( ::m_hAttribDC, nDrawMode )
   ENDIF
   RETURN nRetVal



CLASS HCLIENTDC FROM HDC

   METHOD NEW( nWnd )
   METHOD END ()

   HIDDEN:
   DATA m_hWnd

ENDCLASS

METHOD NEW( nWnd ) CLASS HCLIENTDC

   ::Super:new()
   ::m_hWnd := nWnd
   ::Attach( GetDc( ::m_hWnd ) )

   RETURN Self

METHOD END () CLASS HCLIENTDC

   ReleaseDc( ::m_hWnd, ::m_hDC )
   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

   RETURN NIL
