/*
 * $Id: drawtext.c,v 1.10 2005-11-01 17:48:38 lf_sfnet Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level text functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#define OEMRESOURCE
#include <windows.h>
#include <commctrl.h>

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif


#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"

HB_FUNC( DEFINEPAINTSTRU )
{
   PAINTSTRUCT *pps = (PAINTSTRUCT*) hb_xgrab( sizeof( PAINTSTRUCT ) );
   hb_retnl( (LONG) pps );
}

HB_FUNC( BEGINPAINT )
{
   PAINTSTRUCT *pps = (PAINTSTRUCT*) hb_parnl( 2 );
   HDC hDC = BeginPaint( (HWND) hb_parnl( 1 ), pps );
   hb_retnl( (LONG) hDC );
}

HB_FUNC( ENDPAINT )
{
   PAINTSTRUCT *pps = (PAINTSTRUCT*) hb_parnl( 2 );
   EndPaint( (HWND) hb_parnl( 1 ), pps );
   hb_xfree( pps );
}

HB_FUNC( DELETEDC )
{
   DeleteDC( (HDC) hb_parnl( 1 ) );
}

HB_FUNC( TEXTOUT )
{
   char *cText = hb_parc( 4 );
   TextOut(
     (HDC) hb_parnl( 1 ),	// handle of device context 
     hb_parni( 2 ),     	// x-coordinate of starting position  
     hb_parni( 3 ),	        // y-coordinate of starting position  
     (LPCTSTR) cText,	        // address of string 
     strlen( cText ) 	        // number of characters in string 
   );
}

HB_FUNC( DRAWTEXT )
{
   char *cText = hb_parc( 2 );
   RECT rc;

   rc.left = hb_parni( 3 );
   rc.top = hb_parni( 4 );
   rc.right = hb_parni( 5 );
   rc.bottom = hb_parni( 6 );

   DrawText(
     (HDC) hb_parnl( 1 ),	// handle of device context 
     (LPCTSTR) cText,	        // address of string 
     strlen( cText ), 	        // number of characters in string 
     &rc,
     hb_parni( 7 )
   );
}

HB_FUNC( GETTEXTMETRIC )
{
   TEXTMETRIC tm;
   PHB_ITEM aMetr = _itemArrayNew( 3 );
   PHB_ITEM temp;

   GetTextMetrics( 
      (HDC) hb_parnl( 1 ),	// handle of device context 
      &tm 	                // address of text metrics structure 
   );

   temp = _itemPutNL( NULL, tm.tmHeight );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, tm.tmAveCharWidth );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, tm.tmMaxCharWidth );
   _itemArrayPut( aMetr, 3, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
}

HB_FUNC( GETTEXTSIZE )
{
   char * pstr = hb_parc(2);
   SIZE sz;
   PHB_ITEM aMetr = _itemArrayNew( 2 );
   PHB_ITEM temp;

   GetTextExtentPoint32( (HDC) hb_parnl(1), pstr, strlen( pstr ), &sz );

   temp = _itemPutNL( NULL, sz.cx );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, sz.cy );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
}

HB_FUNC( GETCLIENTRECT )
{
   RECT rc;
   PHB_ITEM aMetr = _itemArrayNew( 4 );
   PHB_ITEM temp;

   GetClientRect( (HWND) hb_parnl( 1 ), &rc );

   temp = _itemPutNL( NULL, rc.left );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, rc.top );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, rc.right );
   _itemArrayPut( aMetr, 3, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, rc.bottom );
   _itemArrayPut( aMetr, 4, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
}

HB_FUNC( GETWINDOWRECT )
{
   RECT rc;
   PHB_ITEM aMetr = _itemArrayNew( 4 );
   PHB_ITEM temp;

   GetWindowRect( (HWND) hb_parnl( 1 ),	&rc );

   temp = _itemPutNL( NULL, rc.left );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, rc.top );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, rc.right );
   _itemArrayPut( aMetr, 3, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, rc.bottom );
   _itemArrayPut( aMetr, 4, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
}

HB_FUNC( GETCLIENTAREA )
{
   PAINTSTRUCT *pps = (PAINTSTRUCT*) hb_parnl( 1 );
   PHB_ITEM aMetr = _itemArrayNew( 4 );
   PHB_ITEM temp;

   temp = _itemPutNL( NULL, pps->rcPaint.left );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, pps->rcPaint.top );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, pps->rcPaint.right );
   _itemArrayPut( aMetr, 3, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, pps->rcPaint.bottom );
   _itemArrayPut( aMetr, 4, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
}

HB_FUNC( SETTEXTCOLOR )
{
   COLORREF crColor = SetTextColor(
              (HDC) hb_parnl( 1 ),	// handle of device context  
              (COLORREF) hb_parnl( 2 ) 	// text color 
            );
   hb_retnl( (LONG) crColor );
}

HB_FUNC( SETBKCOLOR )
{
   COLORREF crColor = SetBkColor(
              (HDC) hb_parnl( 1 ),	// handle of device context  
              (COLORREF) hb_parnl( 2 ) 	// text color 
            );
   hb_retnl( (LONG) crColor );
}

HB_FUNC( SETTRANSPARENTMODE )
{
   int iMode = SetBkMode(
                 (HDC) hb_parnl( 1 ),	// handle of device context  
                 ( hb_parl( 2 ) )? TRANSPARENT : OPAQUE );
   hb_retl( iMode == TRANSPARENT );
}

HB_FUNC( GETTEXTCOLOR )
{
   hb_retnl( (LONG) GetTextColor( (HDC) hb_parnl( 1 ) ) );
}

HB_FUNC( GETBKCOLOR )
{
   hb_retnl( (LONG) GetBkColor( (HDC) hb_parnl( 1 ) ) );
}

/*
HB_FUNC( GETTEXTSIZE )
{

   HDC hdc = GetDC( (HWND)hb_parnl(1) );
   LPCTSTR lpString = hb_parc(2);
   SIZE size;
   PHB_ITEM aMetr = _itemArrayNew( 2 );
   PHB_ITEM temp;

   GetTextExtentPoint32( hdc, hb_parc(2),
      lpString,         // address of text string 
      strlen(cbString), // number of characters in string 
      &size            // address of structure for string size  
   );

   temp = _itemPutNI( NULL, size.cx );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNI( NULL, size.cy );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );

}
*/

HB_FUNC( EXTTEXTOUT )
{

   RECT rc;
   char *cText =  ISCHAR(8) ? hb_parc( 8 ) : NULL;

   rc.left = hb_parni( 4 );
   rc.top = hb_parni( 5 );
   rc.right = hb_parni( 6 );
   rc.bottom = hb_parni( 7 );

   ExtTextOut(
    (HDC) hb_parnl( 1 ),	// handle to device context 
    hb_parni( 2 ),	// x-coordinate of reference point 
    hb_parni( 3 ),	// y-coordinate of reference point 
    ETO_OPAQUE,  	// text-output options 
    &rc,	        // optional clipping and/or opaquing rectangle 
    ISCHAR(8)? (LPCTSTR) cText :NULL, // points to string 
    ISCHAR(8)? strlen( cText ) : 0, // number of characters in string 
    NULL        	// pointer to array of intercharacter spacing values  
   );
}

HB_FUNC( WRITESTATUSWINDOW )
{
   SendMessage( (HWND) hb_parnl( 1 ), SB_SETTEXT, hb_parni( 2 ), (LPARAM) hb_parc( 3 ) );
}

HB_FUNC( WINDOWFROMDC )
{
   hb_retnl( (LONG) WindowFromDC( (HDC) hb_parnl( 1 ) ) );
}

/* CreateFont( fontName, nWidth, hHeight [,fnWeight] [,fdwCharSet], 
               [,fdwItalic] [,fdwUnderline] [,fdwStrikeOut]  )
*/
HB_FUNC( CREATEFONT )
{
   HFONT hFont;
   int fnWeight = ( ISNIL(4) )? 0:hb_parni(4);
   DWORD fdwCharSet = ( ISNIL(5) )? 0:hb_parni(5);
   DWORD fdwItalic = ( ISNIL(6) )? 0:hb_parni(6);
   DWORD fdwUnderline = ( ISNIL(7) )? 0:hb_parni(7);
   DWORD fdwStrikeOut = ( ISNIL(8) )? 0:hb_parni(8);

   hFont = CreateFont(
    hb_parni( 3 ),	// logical height of font 
    hb_parni( 2 ),	// logical average character width 
    0,	// angle of escapement 
    0,	// base-line orientation angle 
    fnWeight,	// font weight 
    fdwItalic,	// italic attribute flag 
    fdwUnderline,	// underline attribute flag 
    fdwStrikeOut,	// strikeout attribute flag 
    fdwCharSet,	// character set identifier 
    0,	// output precision 
    0,	// clipping precision 
    0,	// output quality 
    0,	// pitch and family 
    (LPCTSTR) hb_parc( 1 )	// pointer to typeface name string 
   );
   hb_retnl( (LONG) hFont );
}

/*
 * SetCtrlFont( hWnd, ctrlId, hFont )
*/
HB_FUNC( SETCTRLFONT )
{
   SendDlgItemMessage( (HWND) hb_parnl(1), hb_parni(2), WM_SETFONT, 
                          (WPARAM) hb_parnl(3), 0L );
}

#ifndef __XHARBOUR__

HB_FUNC( OEMTOANSI )
{
   char *buffer = hb_parc(1);
   OemToChar( buffer, buffer );
   hb_retc( buffer );
}

HB_FUNC( ANSITOOEM )
{
   char *buffer = hb_parc(1);
   CharToOem( buffer, buffer );
   hb_retc( buffer );
}
#else
HB_FUNC( OEMTOANSI )
{
   PHB_ITEM pString = hb_param( 1, HB_IT_STRING );

   if( pString )
   {
      DWORD ulLen = pString->item.asString.length;
      char * pszDst = ( char * ) hb_xgrab( ulLen + 1 );

      OemToCharBuff( ( LPCSTR ) pString->item.asString.value, ( LPSTR ) pszDst, ulLen );

      hb_retclenAdopt( pszDst, ulLen );
   }
   else
   {
      hb_retc( "" );
   }
}

HB_FUNC( ANSITOOEM )
{

   PHB_ITEM pString = hb_param( 1, HB_IT_STRING );
   if( pString )

   {
      DWORD ulLen = pString->item.asString.length;
      char * pszDst = ( char * ) hb_xgrab( ulLen + 1 );

      CharToOemBuff( ( LPCSTR ) pString->item.asString.value, ( LPSTR ) pszDst, ulLen );

      hb_retclenAdopt( pszDst, ulLen );
   }
   else
   {
      hb_retc( "" );
   }
}
#endif


HB_FUNC( CREATERECTRGNINDIRECT )
{
   HRGN reg  ;
   RECT rc;
   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   reg =CreateRectRgnIndirect(  &rc);
   hb_retnl( ( LONG)  reg);
}


HB_FUNC( EXTSELECTCLIPRGN)
{
   hb_retni(ExtSelectClipRgn((HDC)hb_parnl(1),(HRGN) hb_parnl(2),hb_parni(3)) );
}

HB_FUNC( SELECTCLIPRGN )
{
   hb_retni( SelectClipRgn( (HDC) hb_parnl( 1 ) , (HRGN) hb_parnl( 2 ) )  ) ;
}


HB_FUNC( CREATEFONTINDIRECT )
{
	LOGFONT lf;
   HFONT f;
	memset(&lf,0,sizeof(LOGFONT));
   lf.lfQuality = hb_parni( 4 );
   lf.lfHeight = hb_parni( 3 );
   lf.lfWeight = hb_parni( 2 );
   lstrcpy(lf.lfFaceName, hb_parc(1));

   f =CreateFontIndirect( &lf );
   hb_retnl( ( LONG ) f );
}

