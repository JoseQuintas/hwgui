/*
 * $Id: hdc.prg,v 1.2 2005-10-24 11:17:01 alkresin Exp $
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
   METHOD SelectObject( xObject )
   METHOD DrawText( strText, Rect, dwFlags )
ENDCLASS

METHOD NEW( nWnd ) CLASS HDC

   ::m_hDC       := NIL
   ::m_hAttribDC := NIL

RETURN SELF

METHOD Attach( hDC ) CLASS HDC

   IF ( hDC == 0 )
      RETURN .F.
   ENDIF

   ::m_hDC := hDC

   ::SetAttribDC( ::m_hDC )
   return.T.

METHOD SetAttribDC( hDC ) CLASS HDC

   ::m_hAttribDC := hDC
RETURN NIL

METHOD SelectClipRgn( pRgn ) CLASS HDC

LOCAL nRetVal := - 1

   IF ( ::m_hDC != ::m_hAttribDC )
      nRetVal := SelectClipRgn( ::m_hDC, pRgn )
   ENDIF

   IF ( ::m_hAttribDC > 0 )
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


