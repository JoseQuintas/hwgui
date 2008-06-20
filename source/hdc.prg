/*
 * $Id: hdc.prg,v 1.8 2008-06-20 23:43:00 mlacecilia Exp $
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

   ::super:new()
   ::m_ps   := DefinePaintStru()
   ::m_hWnd := nWnd
   ::Attach( BeginPaint( ::m_hWnd, ::m_ps ) )

RETURN SELF

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
   METHOD fillsolidrect( lpRect, clr )
   METHOD fillrect( lpRect, clr )
   METHOD SelectClipRgn( pRgn )
   METHOD SetTextcolor( x )
   METHOD SetBkMode( xMode )
   METHOD SetBkColor(  clr ) inline    SetBkColor( ::m_hDC, clr )
   METHOD SelectObject( xObject )
   METHOD DrawText( strText, Rect, dwFlags )
   METHOD CreateCompatibleDc( x )
   method patblt(a,s,d,f,g) inline patblt( ::m_hDc, a, s, d, f, g )
   METHOD Savedc()
   method RestoreDC( nSavedDC )
   METHOD SetMapMode( nMapMode )
   METHOD SetWindowOrg( x, y )
   method SetWindowExt( x, y )
   METHOD SetViewportOrg( x, y )
   METHOD SetViewportExt( x, y )
   METHOD SetArcDirection( nArcDirection)
   METHOD GetTextMetric() inline GetTextMetric(::m_hDC)
   METHOD SetROP2( nDrawMode)
   method BitBlt( x,  y,  nWidth,  nHeight,  pSrcDC,  xSrc, ySrc,  dwRop) inline    BitBlt(::m_hDc, x, y, nWidth, nHeight,  pSrcDC,       xSrc,  ySrc,  dwRop)

   METHOD PIE(arect,apt1,apt2)
   METHOD DeleteDc()
ENDCLASS

METHOD NEW( ) CLASS HDC

   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

RETURN SELF

METHOD Attach( hDC ) CLASS HDC

   IF empty( hDC )
      RETURN .F.
   ENDIF

   ::m_hDC := hDC

   ::SetAttribDC( ::m_hDC )
   return.T.

METHOD deletedc(  ) CLASS HDC
   DeleteDc(::m_hDC)
   ::m_hDC :=nil
   ::m_hAttribDC := nil
return nil

METHOD SetAttribDC( hDC ) CLASS HDC

   ::m_hAttribDC := hDC
RETURN NIL

METHOD SelectClipRgn( pRgn ) CLASS HDC

LOCAL nRetVal := - 1

   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := SelectClipRgn( ::m_hDC, pRgn )
   ENDIF

   IF !empty( ::m_hAttribDC  )
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

   DrawText( ::m_hDC, strText, rect[ 1 ], rect[ 2 ], rect[ 3 ], rect[ 4 ], dwFlags )

RETURN NIL

METHOD fillrect( lpRect, clr ) CLASS HDC

   FillRect( ::m_hDC, lpRect[ 1 ], lpRect[ 2 ], lpRect[ 3 ], lpRect[ 4 ], clr )

RETURN NIL


METHOD CreateCompatibleDc( x ) CLASS HDC
return ::Attach( CreateCompatibleDC( x ) )

METHOD SAVEDC() class HDC
Local nRetVal := 0

   if (!empty(::m_hAttribDC ))
      nRetVal := SaveDC(::m_hAttribDC)
   endif 
   if (::m_hDC != ::m_hAttribDC .and. SaveDC(::m_hDC) != 0)
      nRetVal := -1   // -1 is the only valid restore value for complex DCs
   endif
   return nRetVal

METHOD RestoreDC( nSavedDC) CLASS HDC

	// if two distinct DCs, nSavedDC can only be -1

   Local bRetVal := .T.
   if (::m_hDC != ::m_hAttribDC)
      bRetVal := RestoreDC(::m_hDC, nSavedDC)
   endif
   if (!empty( ::m_hAttribDC ) )
      bRetVal := (bRetVal .and. RestoreDC(::m_hAttribDC, nSavedDC))
   endif
   return bRetVal

METHOD SetMapMode( nMapMode) CLASS HDC
                                   
   Local nRetVal := 0

   if (::m_hDC != ::m_hAttribDC)
      nRetVal := ::SetMapMode(::m_hDC, nMapMode)
   endif
   if !empty(::m_hAttribDC)
      nRetVal := SetMapMode(::m_hAttribDC, nMapMode)
   endif
   return nRetVal



METHOD SetWindowOrg( x, y) CLASS HDC


   Local point

   if (::m_hDC != ::m_hAttribDC)
      SetWindowOrgEx(::m_hDC, x, y, @point)
   endif
   if !empty(::m_hAttribDC)
      SetWindowOrgEx(::m_hAttribDC, x, y, @point)
   endif
   return point


METHOD SetWindowExt( x, y) CLASS HDC


   Local point

   if (::m_hDC != ::m_hAttribDC)
      SetWindowExtEx(::m_hDC, x, y, @point)
   endif
   if !empty(::m_hAttribDC)
      SetWindowExtEx(::m_hAttribDC, x, y, @point)
   endif
   return point


METHOD SetViewportOrg( x, y) CLASS HDC


   Local point

   if (::m_hDC != ::m_hAttribDC)
      SetViewportOrgEx(::m_hDC, x, y, @point)
   endif
   if !empty(::m_hAttribDC)
      SetViewportOrgEx(::m_hAttribDC, x, y, @point)
   endif
   return point


METHOD SetViewportExt( x, y) CLASS HDC

   Local point

   if (::m_hDC != ::m_hAttribDC)
      SetViewportExtEx(::m_hDC, x, y, @point)
   endif
   if !empty(::m_hAttribDC)
      SetViewportExtEx(::m_hAttribDC, x, y, @point)
   endif
   return point


METHOD SetArcDirection( nArcDirection)


   Local nResult := 0
   if (::m_hDC != ::m_hAttribDC)
      nResult = SetArcDirection(::m_hDC, nArcDirection)
   endif
   if !empty(::m_hAttribDC )
      nResult = SetArcDirection(::m_hAttribDC, nArcDirection)
   endif
   return nResult


METHOD PIE(arect,apt1,apt2)
return PIE(::m_hdc,arect[1],arect[2],arect[3],arect[4],apt1[1],apt1[2],apt2[1],apt2[2])

METHOD SetROP2( nDrawMode)


   Local nRetVal := 0

   if (::m_hDC != ::m_hAttribDC)
      nRetVal := SetROP2(::m_hDC, nDrawMode)
   endif
   if !empty(::m_hAttribDC)
      nRetVal := SetROP2(::m_hAttribDC, nDrawMode)
   endif
   return nRetVal



CLASS HCLIENTDC FROM HDC

   METHOD NEW( nWnd )
   METHOD END ()

   HIDDEN:
      DATA m_hWnd

ENDCLASS

METHOD NEW( nWnd ) CLASS HCLIENTDC

   ::super:new()
   ::m_hWnd := nWnd
   ::Attach( GetDc( ::m_hWnd ) )

RETURN SELF

METHOD END () CLASS HCLIENTDC

   ReleaseDc( ::m_hWnd, ::m_hDC )
   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

RETURN NIL
