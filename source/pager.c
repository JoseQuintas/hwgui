#define _WIN32_WINNT 0x0400
#define _WIN32_IE    0x0400

#include <windows.h>
#include <commctrl.h>

#include "hbapi.h"

#if ( defined(__DMC__) || defined(__WATCOMC__) )
	#include "missing.h"
#endif

HB_FUNC( PAGERSETCHILD )
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    HWND hWnd = ( HWND ) hb_parnl( 2 ) ;
    Pager_SetChild( m_hWnd, hWnd );
}

HB_FUNC(PAGERRECALCSIZE)
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    Pager_RecalcSize( m_hWnd );
}

HB_FUNC(PAGERFORWARDMOUSE)
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    BOOL bForward = hb_parl( 2 ) ;
    Pager_ForwardMouse( m_hWnd, bForward );
}

HB_FUNC( PAGERSETBKCOLOR)
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    COLORREF clr = (COLORREF) hb_parnl( 2 ) ;
    hb_retnl( (LONG ) Pager_SetBkColor( m_hWnd, clr) );
}

HB_FUNC( PAGERGETBKCOLOR )
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    hb_retnl( (LONG) Pager_GetBkColor( m_hWnd ) );
}

HB_FUNC( PAGERSETBORDER)
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    int iBorder = hb_parni( 2 ) ;
    hb_parni( Pager_SetBorder( m_hWnd, iBorder) );
}

HB_FUNC( PAGERGETBORDER)
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    hb_parni( Pager_GetBorder( m_hWnd ) ) ;
}

HB_FUNC( PAGERSETPOS)
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    int iPos = hb_parni( 2 ) ;
    hb_parni( Pager_SetPos( m_hWnd, iPos ) ) ;
}

HB_FUNC( PAGERGETPOS )
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    hb_parni( Pager_GetPos( m_hWnd ) ) ;
}

HB_FUNC( PAGERSETBUTTONSIZE )
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    int iSize= hb_parni( 2 ) ;
    hb_parni( Pager_SetButtonSize( m_hWnd, iSize ) ) ;
}

HB_FUNC( PAGERGETBUTTONSIZE )
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    hb_parni( Pager_GetButtonSize( m_hWnd ) ) ;
}

HB_FUNC( PAGERGETBUTTONSTATE )
{
    HWND m_hWnd = ( HWND ) hb_parnl( 1 ) ;
    int iButton = hb_parni( 1 );
    hb_parni( Pager_GetButtonState( m_hWnd, iButton ) ) ;
}

HB_FUNC( PAGERONPAGERCALCSIZE)
{
    LPNMPGCALCSIZE pNMPGCalcSize = (LPNMPGCALCSIZE ) hb_parnl( 1 );
    HWND hwndToolbar = (HWND) hb_parnl( 2 ) ;
    SIZE size;
   SendMessage(hwndToolbar, TB_GETMAXSIZE, 0,
                   (LPARAM)&size);    
	switch(pNMPGCalcSize->dwFlag)
    {
	case PGF_CALCWIDTH:
		pNMPGCalcSize->iWidth = size.cx;
		break;
		
	case PGF_CALCHEIGHT:
		pNMPGCalcSize->iHeight = size.cy;
        break;
	}
	
    hb_retnl( 0 ) ;
}

HB_FUNC( PAGERONPAGERSCROLL )
{
   LPNMPGSCROLL pNMPGScroll = (LPNMPGSCROLL) hb_parnl( 1 ) ;
	
  	switch(pNMPGScroll->iDir)
	{
	case PGF_SCROLLLEFT:
	case PGF_SCROLLRIGHT:
	case PGF_SCROLLUP:
	case PGF_SCROLLDOWN:
       pNMPGScroll->iScroll = 20;
       
        break;
	}
    hb_retnl( 0 );
}
