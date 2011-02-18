/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level text functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#define OEMRESOURCE
#include "hwingui.h"
#include <commctrl.h>
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

HB_FUNC_EXTERN( HB_OEMTOANSI );
HB_FUNC_EXTERN( HB_ANSITOOEM );


HB_FUNC( DEFINEPAINTSTRU )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) hb_xgrab( sizeof( PAINTSTRUCT ) );
   HB_RETHANDLE( pps );
}

HB_FUNC( BEGINPAINT )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 2 );
   HDC hDC = BeginPaint( ( HWND ) HB_PARHANDLE( 1 ), pps );
   HB_RETHANDLE( hDC );
}

HB_FUNC( ENDPAINT )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 2 );
   EndPaint( ( HWND ) HB_PARHANDLE( 1 ), pps );
   hb_xfree( pps );
}

HB_FUNC( DELETEDC )
{
   DeleteDC( ( HDC ) HB_PARHANDLE( 1 ) );
}

HB_FUNC( TEXTOUT )
{
   void * hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 4, &hText, &nLen );

   TextOut( ( HDC ) HB_PARHANDLE( 1 ),  // handle of device context
            hb_parni( 2 ),         // x-coordinate of starting position
            hb_parni( 3 ),         // y-coordinate of starting position
            lpText,                // address of string
            nLen                   // number of characters in string
          );
   hb_strfree( hText );
}

HB_FUNC( DRAWTEXT )
{
   void * hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 2, &hText, &nLen );
   RECT rc;
   UINT uFormat = ( hb_pcount(  ) == 4 ? hb_parni( 4 ) : hb_parni( 7 ) );
   // int uiPos = ( hb_pcount(  ) == 4 ? 3 : hb_parni( 8 ) );
   int heigh ;

   if( hb_pcount(  ) > 4 )
   {

      rc.left = hb_parni( 3 );
      rc.top = hb_parni( 4 );
      rc.right = hb_parni( 5 );
      rc.bottom = hb_parni( 6 );

   }
   else
   {
      Array2Rect( hb_param( 3, HB_IT_ARRAY ), &rc );
   }


   heigh = DrawText( ( HDC ) HB_PARHANDLE( 1 ), // handle of device context
                     lpText,    // address of string
                     nLen,      // number of characters in string
                     &rc, uFormat );
   hb_strfree( hText );

   //if( ISBYREF( uiPos ) )
   if( ISARRAY( 8 ) )
   {
      hb_storvni( rc.left, 8, 1 );
      hb_storvni( rc.top, 8, 2 );
      hb_storvni( rc.right, 8, 3 );
      hb_storvni( rc.bottom, 8, 4 );
   }
   hb_retni( heigh ) ;

}

HB_FUNC( GETTEXTMETRIC )
{
   TEXTMETRIC tm;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   GetTextMetrics( ( HDC ) HB_PARHANDLE( 1 ),   // handle of device context
         &tm                    // address of text metrics structure
          );

   temp = hb_itemPutNL( NULL, tm.tmHeight );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmAveCharWidth );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmMaxCharWidth );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, tm.tmExternalLeading );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( GETTEXTSIZE )
{

   void * hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 2, &hText, &nLen );
   SIZE sz;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   GetTextExtentPoint32( ( HDC ) HB_PARHANDLE( 1 ), lpText, nLen, &sz );
   hb_strfree( hText );

   temp = hb_itemPutNL( NULL, sz.cx );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, sz.cy );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( GETCLIENTRECT )
{
   RECT rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   GetClientRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );

   temp = hb_itemPutNL( NULL, rc.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.right );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.bottom );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( GETWINDOWRECT )
{
   RECT rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );

   temp = hb_itemPutNL( NULL, rc.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.right );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, rc.bottom );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( GETCLIENTAREA )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   temp = hb_itemPutNL( NULL, pps->rcPaint.left );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pps->rcPaint.top );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pps->rcPaint.right );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pps->rcPaint.bottom );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( SETTEXTCOLOR )
{
   COLORREF crColor = SetTextColor( ( HDC ) HB_PARHANDLE( 1 ),  // handle of device context
         ( COLORREF ) hb_parnl( 2 )     // text color
          );
   hb_retnl( ( LONG ) crColor );
}

HB_FUNC( SETBKCOLOR )
{
   COLORREF crColor = SetBkColor( ( HDC ) HB_PARHANDLE( 1 ),    // handle of device context
         ( COLORREF ) hb_parnl( 2 )     // text color
          );
   hb_retnl( ( LONG ) crColor );
}

HB_FUNC( SETTRANSPARENTMODE )
{
   int iMode = SetBkMode( ( HDC ) HB_PARHANDLE( 1 ),    // handle of device context
         ( hb_parl( 2 ) ) ? TRANSPARENT : OPAQUE );
   hb_retl( iMode == TRANSPARENT );
}

HB_FUNC( GETTEXTCOLOR )
{
   hb_retnl( ( LONG ) GetTextColor( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( GETBKCOLOR )
{
   hb_retnl( ( LONG ) GetBkColor( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/*
HB_FUNC( GETTEXTSIZE )
{

   HDC hdc = GetDC( (HWND)HB_PARHANDLE(1) );
   SIZE size;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );
   PHB_ITEM temp;
   void * hString;

   GetTextExtentPoint32( hdc, HB_PARSTR( 2, &hString, NULL ),
      lpString,         // address of text string
      strlen(cbString), // number of characters in string
      &size            // address of structure for string size
   );
   hb_strfree( hString );

   temp = hb_itemPutNI( NULL, size.cx );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, size.cy );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );

}
*/

HB_FUNC( EXTTEXTOUT )
{

   RECT rc;
   void * hText;
   HB_SIZE nLen;
   LPCTSTR lpText = HB_PARSTR( 8, &hText, &nLen );

   rc.left = hb_parni( 4 );
   rc.top = hb_parni( 5 );
   rc.right = hb_parni( 6 );
   rc.bottom = hb_parni( 7 );

   ExtTextOut( ( HDC ) HB_PARHANDLE( 1 ),       // handle to device context
         hb_parni( 2 ),         // x-coordinate of reference point
         hb_parni( 3 ),         // y-coordinate of reference point
         ETO_OPAQUE,            // text-output options
         &rc,                   // optional clipping and/or opaquing rectangle
         lpText,                // points to string
         nLen,                  // number of characters in string
         NULL                   // pointer to array of intercharacter spacing values
          );
   hb_strfree( hText );
}

HB_FUNC( WRITESTATUSWINDOW )
{
   void * hString;
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), SB_SETTEXT, hb_parni( 2 ),
                ( LPARAM ) HB_PARSTR( 3, &hString, NULL ) );
   hb_strfree( hString );
}

HB_FUNC( WINDOWFROMDC )
{
   HB_RETHANDLE( WindowFromDC( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

/* CreateFont( fontName, nWidth, hHeight [,fnWeight] [,fdwCharSet],
               [,fdwItalic] [,fdwUnderline] [,fdwStrikeOut]  )
*/
HB_FUNC( CREATEFONT )
{
   HFONT hFont;
   int fnWeight = ( ISNIL( 4 ) ) ? 0 : hb_parni( 4 );
   DWORD fdwCharSet = ( ISNIL( 5 ) ) ? 0 : hb_parni( 5 );
   DWORD fdwItalic = ( ISNIL( 6 ) ) ? 0 : hb_parni( 6 );
   DWORD fdwUnderline = ( ISNIL( 7 ) ) ? 0 : hb_parni( 7 );
   DWORD fdwStrikeOut = ( ISNIL( 8 ) ) ? 0 : hb_parni( 8 );
   void * hString;

   hFont = CreateFont( hb_parni( 3 ),   // logical height of font
         hb_parni( 2 ),         // logical average character width
         0,                     // angle of escapement
         0,                     // base-line orientation angle
         fnWeight,              // font weight
         fdwItalic,             // italic attribute flag
         fdwUnderline,          // underline attribute flag
         fdwStrikeOut,          // strikeout attribute flag
         fdwCharSet,            // character set identifier
         0,                     // output precision
         0,                     // clipping precision
         0,                     // output quality
         0,                     // pitch and family
         HB_PARSTR( 1, &hString, NULL )   // pointer to typeface name string
          );
   hb_strfree( hString );
   HB_RETHANDLE( hFont );
}

/*
 * SetCtrlFont( hWnd, ctrlId, hFont )
*/
HB_FUNC( SETCTRLFONT )
{
   SendDlgItemMessage( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), WM_SETFONT,
         ( WPARAM ) HB_PARHANDLE( 3 ), 0L );
}

HB_FUNC( OEMTOANSI )
{
   HB_FUNC_EXEC( HB_OEMTOANSI );
}

HB_FUNC( ANSITOOEM )
{
   HB_FUNC_EXEC( HB_ANSITOOEM );
}

HB_FUNC( CREATERECTRGN )
{
   HRGN reg;

   reg = CreateRectRgn( hb_parni( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ) );

   HB_RETHANDLE( reg );
}


HB_FUNC( CREATERECTRGNINDIRECT )
{
   HRGN reg;
   RECT rc;

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   reg = CreateRectRgnIndirect( &rc );
   HB_RETHANDLE( reg );
}


HB_FUNC( EXTSELECTCLIPRGN )
{
   hb_retni( ExtSelectClipRgn( ( HDC ) HB_PARHANDLE( 1 ),
               ( HRGN ) HB_PARHANDLE( 2 ), hb_parni( 3 ) ) );
}

HB_FUNC( SELECTCLIPRGN )
{
   hb_retni( SelectClipRgn( ( HDC ) HB_PARHANDLE( 1 ),
               ( HRGN ) HB_PARHANDLE( 2 ) ) );
}


HB_FUNC( CREATEFONTINDIRECT )
{
   LOGFONT lf;
   HFONT f;
   memset( &lf, 0, sizeof( LOGFONT ) );
   lf.lfQuality = hb_parni( 4 );
   lf.lfHeight = hb_parni( 3 );
   lf.lfWeight = hb_parni( 2 );
   HB_ITEMCOPYSTR( hb_param( 1, HB_IT_ANY ), lf.lfFaceName, HB_SIZEOFARRAY( lf.lfFaceName ) );
   lf.lfFaceName[ HB_SIZEOFARRAY( lf.lfFaceName ) - 1 ] = '\0';

   f = CreateFontIndirect( &lf );
   HB_RETHANDLE( f );
}
