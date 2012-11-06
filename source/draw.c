/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level painting functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#define OEMRESOURCE
#ifdef __DMC__
#define __DRAW_C__
#endif
#include "hwingui.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "missing.h"

#if defined( __BORLANDC__ ) && __BORLANDC__ == 0x0550
#ifdef __cplusplus
extern "C" { STDAPI OleLoadPicture(LPSTREAM,LONG,BOOL,REFIID,PVOID*); }
#else
STDAPI OleLoadPicture(LPSTREAM,LONG,BOOL,REFIID,PVOID*);
#endif
#endif /* __BORLANDC__ */

#ifdef __cplusplus
#ifdef CINTERFACE
#undef CINTERFACE
#endif
#endif

typedef int ( _stdcall * TRANSPARENTBLT ) ( HDC, int, int, int, int, HDC, int, int, int, int, int );

static TRANSPARENTBLT s_pTransparentBlt = NULL;

void TransparentBmp( HDC hDC, int x, int  y, int nWidthDest, int nHeightDest, HDC dcImage, int bmWidth, int bmHeight, int trColor )
{
   if( s_pTransparentBlt == NULL )
       s_pTransparentBlt = ( TRANSPARENTBLT ) GetProcAddress( LoadLibrary( TEXT( "MSIMG32.DLL" ) ),
                             "TransparentBlt" );
   s_pTransparentBlt( hDC, x, y, nWidthDest, nHeightDest, dcImage, 0, 0, bmWidth, bmHeight, trColor );
}

BOOL Array2Rect( PHB_ITEM aRect, RECT * rc )
{
   if( HB_IS_ARRAY( aRect ) && hb_arrayLen( aRect ) == 4 )
   {
      rc->left = hb_arrayGetNL( aRect, 1 );
      rc->top = hb_arrayGetNL( aRect, 2 );
      rc->right = hb_arrayGetNL( aRect, 3 );
      rc->bottom = hb_arrayGetNL( aRect, 4 );
      return TRUE;
   }
   else
   {
      rc->left = rc->top = rc->right = rc->bottom = 0;
   }
   return FALSE;
}

PHB_ITEM Rect2Array( RECT * rc )
{
   PHB_ITEM aRect = hb_itemArrayNew( 4 );
   PHB_ITEM element = hb_itemNew( NULL );

   hb_arraySet( aRect, 1, hb_itemPutNL( element, rc->left ) );
   hb_arraySet( aRect, 2, hb_itemPutNL( element, rc->top ) );
   hb_arraySet( aRect, 3, hb_itemPutNL( element, rc->right ) );
   hb_arraySet( aRect, 4, hb_itemPutNL( element, rc->bottom ) );
   hb_itemRelease( element );
   return aRect;
}

HB_FUNC( GETPPSRECT )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );

   PHB_ITEM aMetr = Rect2Array( &pps->rcPaint );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( GETPPSERASE )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );
   BOOL fErase = &pps->fErase ;
   hb_retni( fErase );
}

HB_FUNC( GETUPDATERECT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 ) ;
   BOOL fErase ;
   fErase =  GetUpdateRect( hWnd, NULL, 0 ) ;
   hb_retni( fErase );
}

HB_FUNC( INVALIDATERECT )
{
   RECT rc;

   if( hb_pcount(  ) > 2 )
   {
      rc.left = hb_parni( 3 );
      rc.top = hb_parni( 4 );
      rc.right = hb_parni( 5 );
      rc.bottom = hb_parni( 6 );
   }

   InvalidateRect( ( HWND ) HB_PARHANDLE( 1 ),  // handle of window with changed update region
         ( hb_pcount(  ) > 2 ) ? &rc : NULL,    // address of rectangle coordinates
         hb_parni( 2 )          // erase-background flag
          );
}

HB_FUNC( MOVETO )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   MoveToEx( hDC, x1, y1, NULL );
}

HB_FUNC( LINETO )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   LineTo( hDC, x1, y1 );
}

HB_FUNC( RECTANGLE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 =
         hb_parni( 5 );
   MoveToEx( hDC, x1, y1, NULL );
   LineTo( hDC, x2, y1 );
   LineTo( hDC, x2, y2 );
   LineTo( hDC, x1, y2 );
   LineTo( hDC, x1, y1 );
}

HB_FUNC( BOX )
{
   Rectangle( ( HDC ) HB_PARHANDLE( 1 ),        // handle of device context
         hb_parni( 2 ),         // x-coord. of bounding rectangle's upper-left corner
         hb_parni( 3 ),         // y-coord. of bounding rectangle's upper-left corner
         hb_parni( 4 ),         // x-coord. of bounding rectangle's lower-right corner
         hb_parni( 5 )          // y-coord. of bounding rectangle's lower-right corner
          );
}



HB_FUNC( DRAWLINE )
{
   MoveToEx( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ), NULL );
   LineTo( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 4 ), hb_parni( 5 ) );
}

HB_FUNC( PIE )
{
   int res = Pie( ( HDC ) HB_PARHANDLE( 1 ),    // handle to device context
         hb_parni( 2 ),         // x-coord. of bounding rectangle's upper-left corner
         hb_parni( 3 ),         // y-coord. of bounding rectangle's upper-left corner
         hb_parni( 4 ),         // x-coord. of bounding rectangle's lower-right corner
         hb_parni( 5 ),         // y-coord. bounding rectangle's f lower-right corner
         hb_parni( 6 ),         // x-coord. of first radial's endpoint
         hb_parni( 7 ),         // y-coord. of first radial's endpoint
         hb_parni( 8 ),         // x-coord. of second radial's endpoint
         hb_parni( 9 )          // y-coord. of second radial's endpoint
          );

   hb_retnl( res ? 0 : ( LONG ) GetLastError(  ) );
}

HB_FUNC( ELLIPSE )
{
   int res = Ellipse( ( HDC ) HB_PARHANDLE( 1 ),        // handle to device context
         hb_parni( 2 ),         // x-coord. of bounding rectangle's upper-left corner
         hb_parni( 3 ),         // y-coord. of bounding rectangle's upper-left corner
         hb_parni( 4 ),         // x-coord. of bounding rectangle's lower-right corner
         hb_parni( 5 )          // y-coord. bounding rectangle's f lower-right corner
          );

   hb_retnl( res ? 0 : ( LONG ) GetLastError(  ) );
}

HB_FUNC( FILLRECT )
{
   RECT rc;

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   FillRect( HB_ISPOINTER( 1 ) ? ( HDC ) HB_PARHANDLE( 1 ) : ( HDC ) hb_parnl( 1 ),        // handle to device context
         &rc,                   // pointer to structure with rectangle
         ( HBRUSH ) HB_PARHANDLE( 6 )   // handle to brush
          );
}

HB_FUNC( ROUNDRECT )
{
   hb_parl( RoundRect( ( HDC ) HB_PARHANDLE( 1 ),       // handle of device context
               hb_parni( 2 ),   // x-coord. of bounding rectangle's upper-left corner
               hb_parni( 3 ),   // y-coord. of bounding rectangle's upper-left corner
               hb_parni( 4 ),   // x-coord. of bounding rectangle's lower-right corner
               hb_parni( 5 ),   // y-coord. of bounding rectangle's lower-right corner
               hb_parni( 6 ),   // width of ellipse used to draw rounded corners
               hb_parni( 7 )    // height of ellipse used to draw rounded corners
          ) );
}
/*
HB_FUNC( REDRAWWINDOW )
{
   RedrawWindow( ( HWND ) HB_PARHANDLE( 1 ),    // handle of window
         NULL,                  // address of structure with update rectangle
         NULL,                  // handle of update region
         ( UINT ) hb_parni( 2 ) // array of redraw flags
          );
}
*/
HB_FUNC( REDRAWWINDOW )
{
   RECT rc;

   if ( hb_pcount() > 3 )
   {
      int x = ( hb_pcount() >  3 && !HB_ISNIL(3) )? hb_parni(3):0;
      int y = ( hb_pcount() >= 4 && !HB_ISNIL(4) )? hb_parni(4):0;
      int w = ( hb_pcount() >= 5 && !HB_ISNIL(5) )? hb_parni(5):0;
      int h = ( hb_pcount() >= 6 && !HB_ISNIL(6) )? hb_parni(6):0;
      rc.left  = x - 1;
      rc.top   = y - 1;
      rc.right = x + w + 1;
      rc.bottom = y + h + 1 ;
   }   
   RedrawWindow(
    ( HWND ) HB_PARHANDLE( 1 ),  // handle of window
    ( hb_pcount() > 3 )? &rc:NULL,  // address of structure with update rectangle
     NULL,   // handle of update region
    ( UINT )hb_parni( 2 )     // array of redraw flags
   );
}

HB_FUNC( DRAWBUTTON )
{
   RECT rc;
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   UINT iType = hb_parni( 6 );

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   if( iType == 0 )
      FillRect( hDC, &rc, ( HBRUSH ) ( COLOR_3DFACE + 1 ) );
   else
   {
      FillRect( hDC, &rc,
            ( HBRUSH ) ( ( ( iType & 2 ) ? COLOR_3DSHADOW : COLOR_3DHILIGHT )
                  + 1 ) );
      rc.left++;
      rc.top++;
      FillRect( hDC, &rc,
            ( HBRUSH ) ( ( ( iType & 2 ) ? COLOR_3DHILIGHT : ( iType & 4 ) ?
                        COLOR_3DDKSHADOW : COLOR_3DSHADOW ) + 1 ) );
      rc.right--;
      rc.bottom--;
      if( iType & 4 )
      {
         FillRect( hDC, &rc,
               ( HBRUSH ) ( ( ( iType & 2 ) ? COLOR_3DSHADOW : COLOR_3DLIGHT )
                     + 1 ) );
         rc.left++;
         rc.top++;
         FillRect( hDC, &rc,
               ( HBRUSH ) ( ( ( iType & 2 ) ? COLOR_3DLIGHT : COLOR_3DSHADOW )
                     + 1 ) );
         rc.right--;
         rc.bottom--;
      }
      FillRect( hDC, &rc, ( HBRUSH ) ( COLOR_3DFACE + 1 ) );
   }
}

/*
 * DrawEdge( hDC,x1,y1,x2,y2,nFlag,nBorder )
 */
HB_FUNC( DRAWEDGE )
{
   RECT rc;
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   UINT edge = ( HB_ISNIL( 6 ) ) ? EDGE_RAISED : ( UINT ) hb_parni( 6 );
   UINT grfFlags = ( HB_ISNIL( 7 ) ) ? BF_RECT : ( UINT ) hb_parni( 7 );

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   hb_retl( DrawEdge( hDC, &rc, edge, grfFlags ) );
}

HB_FUNC( LOADICON )
{
   if( HB_ISNUM( 1 ) )
      HB_RETHANDLE( LoadIcon( NULL, MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
   else
   {
      void * hString;
      HB_RETHANDLE( LoadIcon( GetModuleHandle( NULL ), HB_PARSTR( 1, &hString, NULL ) ) );
      hb_strfree( hString );
   }
}

HB_FUNC( LOADIMAGE )
{
   void * hString = NULL;

   HB_RETHANDLE( LoadImage( HB_ISNIL( 1 ) ? GetModuleHandle( NULL ) : ( HINSTANCE ) hb_parnl( 1 ), // handle of the instance that contains the image
               HB_ISNUM( 2 ) ? MAKEINTRESOURCE( hb_parni( 2 ) ) : HB_PARSTR( 2, &hString, NULL ),  // name or identifier of image
               ( UINT ) hb_parni( 3 ),  // type of image
               hb_parni( 4 ),   // desired width
               hb_parni( 5 ),   // desired height
               ( UINT ) hb_parni( 6 )   // load flags
          ) );
   hb_strfree( hString );
}

HB_FUNC( LOADBITMAP )
{
   if( HB_ISNUM( 1 ) )
   {
      if( !HB_ISNIL( 2 ) && hb_parl( 2 ) )
         HB_RETHANDLE( LoadBitmap( NULL, MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
      else
         HB_RETHANDLE( LoadBitmap( GetModuleHandle( NULL ),
                                   MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
   }
   else
   {
      void * hString;
      HB_RETHANDLE( LoadBitmap( GetModuleHandle( NULL ), HB_PARSTR( 1, &hString, NULL ) ) );
      hb_strfree( hString );
   }
}

/*
 * Window2Bitmap( hWnd )
 */
HB_FUNC( WINDOW2BITMAP )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   BOOL lFull = ( HB_ISNIL( 2 ) ) ? 0 : ( BOOL ) hb_parl( 2 );
   HDC hDC = ( lFull ) ? GetWindowDC( hWnd ) : GetDC( hWnd );
   HDC hDCmem = CreateCompatibleDC( hDC );
   HBITMAP hBitmap;
   RECT rc;

   if( lFull )
      GetWindowRect( hWnd, &rc );
   else
      GetClientRect( hWnd, &rc );

   hBitmap =
         CreateCompatibleBitmap( hDC, rc.right - rc.left,
         rc.bottom - rc.top );
   SelectObject( hDCmem, hBitmap );

   BitBlt( hDCmem, 0, 0, rc.right - rc.left, rc.bottom - rc.top, hDC, 0, 0,
         SRCCOPY );

   DeleteDC( hDCmem );
   DeleteDC( hDC );
   //hb_retnl( (LONG) hBitmap );
   HB_RETHANDLE( hBitmap );
}

/*
 * DrawBitmap( hDC, hBitmap, style, x, y, width, height )
 */
HB_FUNC( DRAWBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = ( HB_ISNIL( 3 ) ) ? SRCCOPY : ( DWORD ) hb_parnl( 3 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   BITMAP bitmap;
   int nWidthDest = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
   int nHeightDest = ( hb_pcount(  ) >= 6 &&
         !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : 0;

   SelectObject( hDCmem, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   if( nWidthDest && ( nWidthDest != bitmap.bmWidth ||
               nHeightDest != bitmap.bmHeight ) )
   {
      SetStretchBltMode(  hDC, COLORONCOLOR );    
      StretchBlt( hDC, hb_parni( 4 ), hb_parni( 5 ), nWidthDest, nHeightDest,
            hDCmem, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dwraster );
   }
   else
   {
      BitBlt( hDC, hb_parni( 4 ), hb_parni( 5 ), bitmap.bmWidth,
            bitmap.bmHeight, hDCmem, 0, 0, dwraster );
   }

   DeleteDC( hDCmem );
}

/*
 * DrawTransparentBitmap( hDC, hBitmap, x, y [,trColor] )
 */
HB_FUNC( DRAWTRANSPARENTBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   COLORREF trColor =
         ( HB_ISNIL( 5 ) ) ? 0x00FFFFFF : ( COLORREF ) hb_parnl( 5 );
   COLORREF crOldBack = SetBkColor( hDC, 0x00FFFFFF );
   COLORREF crOldText = SetTextColor( hDC, 0 );
   HBITMAP bitmapTrans;
   HBITMAP pOldBitmapImage, pOldBitmapTrans;
   BITMAP bitmap;
   HDC dcImage, dcTrans;
   int x = hb_parni( 3 );
   int y = hb_parni( 4 );
   int nWidthDest = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
   int nHeightDest = ( hb_pcount(  ) >= 6 &&
         !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : 0;

   // Create two memory dcs for the image and the mask
   dcImage = CreateCompatibleDC( hDC );
   dcTrans = CreateCompatibleDC( hDC );
   // Select the image into the appropriate dc
   pOldBitmapImage = ( HBITMAP ) SelectObject( dcImage, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   // Create the mask bitmap
   bitmapTrans = CreateBitmap( bitmap.bmWidth, bitmap.bmHeight, 1, 1, NULL );
   // Select the mask bitmap into the appropriate dc
   pOldBitmapTrans = ( HBITMAP ) SelectObject( dcTrans, bitmapTrans );
   // Build mask based on transparent colour
   SetBkColor( dcImage, trColor );
   if( nWidthDest && ( nWidthDest != bitmap.bmWidth ||
               nHeightDest != bitmap.bmHeight ) )
   {
      /*
      BitBlt( dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0,
            SRCCOPY );
      SetStretchBltMode(  hDC, COLORONCOLOR );    
      StretchBlt( hDC, 0, 0, nWidthDest, nHeightDest, dcImage, 0, 0,
            bitmap.bmWidth, bitmap.bmHeight, SRCINVERT );
      StretchBlt( hDC, 0, 0, nWidthDest, nHeightDest, dcTrans, 0, 0,
            bitmap.bmWidth, bitmap.bmHeight, SRCAND );
      StretchBlt( hDC, 0, 0, nWidthDest, nHeightDest, dcImage, 0, 0,
            bitmap.bmWidth, bitmap.bmHeight, SRCINVERT );
      */
      SetStretchBltMode(  hDC, COLORONCOLOR );
      TransparentBmp( hDC, x, y, nWidthDest, nHeightDest, dcImage, bitmap.bmWidth, bitmap.bmHeight, trColor );

   }
   else
   {
      /*
      BitBlt( dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0,
            SRCCOPY );
      // Do the work - True Mask method - cool if not actual display
      BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0,
            SRCINVERT );
      BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcTrans, 0, 0,
            SRCAND );
      BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0,
            SRCINVERT );
     */
     TransparentBmp( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, bitmap.bmWidth, bitmap.bmHeight, trColor );
   }
   // Restore settings
   SelectObject( dcImage, pOldBitmapImage );
   SelectObject( dcTrans, pOldBitmapTrans );
   SetBkColor( hDC, crOldBack );
   SetTextColor( hDC, crOldText );

   DeleteObject( bitmapTrans );
   DeleteDC( dcImage );
   DeleteDC( dcTrans );
}

/*  SpreadBitmap( hDC, hWnd, hBitmap, style )
*/
HB_FUNC( SPREADBITMAP )
{
   HDC hDC =
         HB_ISPOINTER( 1 ) ? ( HDC ) HB_PARHANDLE( 1 ) : ( HDC ) hb_parnl( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = ( HB_ISNIL( 4 ) ) ? SRCCOPY : ( DWORD ) hb_parnl( 4 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 3 );
   BITMAP bitmap;
   RECT rc;

   SelectObject( hDCmem, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   GetClientRect( ( HWND ) HB_PARHANDLE( 2 ), &rc );

   while( rc.top < rc.bottom )
   {
      while( rc.left < rc.right )
      {
         BitBlt( hDC, rc.left, rc.top, bitmap.bmWidth, bitmap.bmHeight,
               hDCmem, 0, 0, dwraster );
         rc.left += bitmap.bmWidth;
      }
      rc.left = 0;
      rc.top += bitmap.bmHeight;
   }

   DeleteDC( hDCmem );
}


/*  CenterBitmap( hDC, hWnd, hBitmap, style, brush )
*/

HB_FUNC( CENTERBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = ( HB_ISNIL( 4 ) ) ? SRCCOPY : ( DWORD ) hb_parnl( 4 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 3 );
   BITMAP bitmap;
   RECT rc;
   HBRUSH hBrush =
         ( HB_ISNIL( 5 ) ) ? ( HBRUSH ) ( COLOR_WINDOW +
         1 ) : ( HBRUSH ) HB_PARHANDLE( 5 );

   SelectObject( hDCmem, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   GetClientRect( ( HWND ) HB_PARHANDLE( 2 ), &rc );

   FillRect( hDC, &rc, hBrush );
   BitBlt( hDC, ( rc.right - bitmap.bmWidth ) / 2,
         ( rc.bottom - bitmap.bmHeight ) / 2, bitmap.bmWidth, bitmap.bmHeight,
         hDCmem, 0, 0, dwraster );

   DeleteDC( hDCmem );
}


HB_FUNC( GETBITMAPSIZE )
{
   BITMAP bitmap;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;
   int nret;

   nret = GetObject( ( HBITMAP ) HB_PARHANDLE( 1 ), sizeof( BITMAP ),
         ( LPVOID ) & bitmap );

   temp = hb_itemPutNL( NULL, bitmap.bmWidth );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, bitmap.bmHeight );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, bitmap.bmBitsPixel );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, nret );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );


   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( GETICONSIZE )
{
   ICONINFO iinfo;
   PHB_ITEM aMetr = hb_itemArrayNew( 3 );
   PHB_ITEM temp;
   int nret;

   nret = GetIconInfo( ( HICON ) HB_PARHANDLE( 1 ), &iinfo );

   temp = hb_itemPutNL( NULL, iinfo.xHotspot * 2 );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, iinfo.yHotspot * 2 );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, nret );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );


   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( OPENBITMAP )
{
   BITMAPFILEHEADER bmfh;
   BITMAPINFOHEADER bmih;
   LPBITMAPINFO lpbmi;
   DWORD dwRead;
   LPVOID lpvBits;
   HGLOBAL hmem1, hmem2;
   HBITMAP hbm;
   HDC hDC = ( hb_pcount(  ) > 1 && !HB_ISNIL( 2 ) ) ?
             ( HDC ) HB_PARHANDLE( 2 ) : NULL;
   void * hString;
   HANDLE hfbm;

   hfbm = CreateFile( HB_PARSTR( 1, &hString, NULL ), GENERIC_READ, FILE_SHARE_READ,
                      ( LPSECURITY_ATTRIBUTES ) NULL, OPEN_EXISTING,
                      FILE_ATTRIBUTE_READONLY, ( HANDLE ) NULL );
   hb_strfree( hString );
   if( ( ( long int ) hfbm ) <= 0 )
   {
      HB_RETHANDLE( NULL );
      return;
   }
   /* Retrieve the BITMAPFILEHEADER structure. */
   ReadFile( hfbm, &bmfh, sizeof( BITMAPFILEHEADER ), &dwRead, NULL );

   /* Retrieve the BITMAPFILEHEADER structure. */
   ReadFile( hfbm, &bmih, sizeof( BITMAPINFOHEADER ), &dwRead, NULL );

   /* Allocate memory for the BITMAPINFO structure. */

   hmem1 = GlobalAlloc( GHND, sizeof( BITMAPINFOHEADER ) +
         ( ( 1 << bmih.biBitCount ) * sizeof( RGBQUAD ) ) );
   lpbmi = ( LPBITMAPINFO ) GlobalLock( hmem1 );

   /*  Load BITMAPINFOHEADER into the BITMAPINFO  structure. */
   lpbmi->bmiHeader.biSize = bmih.biSize;
   lpbmi->bmiHeader.biWidth = bmih.biWidth;
   lpbmi->bmiHeader.biHeight = bmih.biHeight;
   lpbmi->bmiHeader.biPlanes = bmih.biPlanes;

   lpbmi->bmiHeader.biBitCount = bmih.biBitCount;
   lpbmi->bmiHeader.biCompression = bmih.biCompression;
   lpbmi->bmiHeader.biSizeImage = bmih.biSizeImage;
   lpbmi->bmiHeader.biXPelsPerMeter = bmih.biXPelsPerMeter;
   lpbmi->bmiHeader.biYPelsPerMeter = bmih.biYPelsPerMeter;
   lpbmi->bmiHeader.biClrUsed = bmih.biClrUsed;
   lpbmi->bmiHeader.biClrImportant = bmih.biClrImportant;

   /*  Retrieve the color table.
    * 1 << bmih.biBitCount == 2 ^ bmih.biBitCount
    */
   switch ( bmih.biBitCount )
   {
      case 1:
      case 4:
      case 8:
         ReadFile( hfbm, lpbmi->bmiColors,
               ( ( 1 << bmih.biBitCount ) * sizeof( RGBQUAD ) ),
               &dwRead, ( LPOVERLAPPED ) NULL );
         break;

      case 16:
      case 32:
         if( bmih.biCompression == BI_BITFIELDS )
            ReadFile( hfbm, lpbmi->bmiColors,
                  ( 3 * sizeof( RGBQUAD ) ), &dwRead, ( LPOVERLAPPED ) NULL );
         break;

      case 24:
         break;
   }

   /* Allocate memory for the required number of  bytes. */
   hmem2 = GlobalAlloc( GHND, ( bmfh.bfSize - bmfh.bfOffBits ) );
   lpvBits = GlobalLock( hmem2 );

   /* Retrieve the bitmap data. */

   ReadFile( hfbm, lpvBits, ( bmfh.bfSize - bmfh.bfOffBits ), &dwRead, NULL );

   if( !hDC )
      hDC = GetDC( 0 );

   /* Create a bitmap from the data stored in the .BMP file.  */
   hbm = CreateDIBitmap( hDC, &bmih, CBM_INIT, lpvBits, lpbmi,
         DIB_RGB_COLORS );

   if( hb_pcount(  ) < 2 || HB_ISNIL( 2 ) )
      ReleaseDC( 0, hDC );

   /* Unlock the global memory objects and close the .BMP file. */
   GlobalUnlock( hmem1 );
   GlobalUnlock( hmem2 );
   GlobalFree( hmem1 );
   GlobalFree( hmem2 );
   CloseHandle( hfbm );

   HB_RETHANDLE( hbm );
}

HB_FUNC( DRAWICON )
{
   DrawIcon( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 3 ), hb_parni( 4 ),
         ( HICON ) HB_PARHANDLE( 2 ) );
}

HB_FUNC( GETSYSCOLOR )
{
   hb_retnl( ( LONG ) GetSysColor( hb_parni( 1 ) ) );
}

HB_FUNC( GETSYSCOLORBRUSH )
{
   HB_RETHANDLE( GetSysColorBrush(  hb_parni( 1 ) ) ) ;
}

HB_FUNC( CREATEPEN )
{
   HB_RETHANDLE( CreatePen( hb_parni( 1 ),      // pen style
               hb_parni( 2 ),   // pen width
               ( COLORREF ) hb_parnl( 3 )       // pen color
          ) );
}

HB_FUNC( CREATESOLIDBRUSH )
{
   HB_RETHANDLE( CreateSolidBrush( ( COLORREF ) hb_parnl( 1 )   // brush color
          ) );
}

HB_FUNC( CREATEHATCHBRUSH )
{
   HB_RETHANDLE( CreateHatchBrush( hb_parni( 1 ),
               ( COLORREF ) hb_parnl( 2 ) ) );
}

HB_FUNC( SELECTOBJECT )
{
   HB_RETHANDLE( SelectObject( ( HDC ) HB_PARHANDLE( 1 ),       // handle of device context
               ( HGDIOBJ ) HB_PARHANDLE( 2 )    // handle of object
          ) );
}

HB_FUNC( DELETEOBJECT )
{
   DeleteObject( ( HGDIOBJ ) HB_PARHANDLE( 1 )  // handle of object
          );
}

HB_FUNC( GETDC )
{
   HB_RETHANDLE( GetDC( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( RELEASEDC )
{
   HB_RETHANDLE( ReleaseDC( ( HWND ) HB_PARHANDLE( 1 ),
               ( HDC ) HB_PARHANDLE( 2 ) ) );
}

HB_FUNC( GETDRAWITEMINFO )
{

   DRAWITEMSTRUCT *lpdis = ( DRAWITEMSTRUCT * ) HB_PARHANDLE( 1 );      //hb_parnl( 1 );
   PHB_ITEM aMetr = hb_itemArrayNew( 9 );
   PHB_ITEM temp;

   temp = hb_itemPutNL( NULL, lpdis->itemID );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->itemAction );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = HB_PUTHANDLE( NULL, lpdis->hDC );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->rcItem.left );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->rcItem.top );
   hb_itemArrayPut( aMetr, 5, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->rcItem.right );
   hb_itemArrayPut( aMetr, 6, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->rcItem.bottom );
   hb_itemArrayPut( aMetr, 7, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, ( LONG ) lpdis->hwndItem );
   hb_itemArrayPut( aMetr, 8, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, ( LONG ) lpdis->itemState );
   hb_itemArrayPut( aMetr, 9, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

/*
 * DrawGrayBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( DRAWGRAYBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   HBITMAP bitmapgray;
   HBITMAP pOldBitmapImage, pOldbitmapgray;
   BITMAP bitmap;
   HDC dcImage, dcTrans;
   int x = hb_parni( 3 );
   int y = hb_parni( 4 );

   SetBkColor( hDC, GetSysColor( COLOR_BTNHIGHLIGHT ) );
   //SetTextColor( hDC, GetSysColor( COLOR_BTNFACE ) );
   SetTextColor( hDC, GetSysColor( COLOR_BTNSHADOW ) );
   // Create two memory dcs for the image and the mask
   dcImage = CreateCompatibleDC( hDC );
   dcTrans = CreateCompatibleDC( hDC );
   // Select the image into the appropriate dc
   pOldBitmapImage = ( HBITMAP ) SelectObject( dcImage, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   // Create the mask bitmap
   bitmapgray = CreateBitmap( bitmap.bmWidth, bitmap.bmHeight, 1, 1, NULL );
   // Select the mask bitmap into the appropriate dc
   pOldbitmapgray = ( HBITMAP ) SelectObject( dcTrans, bitmapgray );
   // Build mask based on transparent colour
   SetBkColor( dcImage, RGB( 255, 255, 255 ) );
   BitBlt( dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0,
         SRCCOPY );
   // Do the work - True Mask method - cool if not actual display
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0,
         SRCINVERT );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcTrans, 0, 0,
         SRCAND );
   BitBlt( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0,
         SRCINVERT );
   // Restore settings
   SelectObject( dcImage, pOldBitmapImage );
   SelectObject( dcTrans, pOldbitmapgray );
   SetBkColor( hDC, GetPixel( hDC, 0, 0 ) );
   SetTextColor( hDC, 0 );

   DeleteObject( bitmapgray );
   DeleteDC( dcImage );
   DeleteDC( dcTrans );
}

#include <olectl.h>
#include <ole2.h>
#include <ocidl.h>

HB_FUNC( OPENIMAGE )
{
   const char *cFileName = hb_parc( 1 );
   BOOL lString = ( HB_ISNIL( 2 ) ) ? 0 : hb_parl( 2 );
   int iFileSize;
   FILE *fp;
   // IPicture * pPic;
   LPPICTURE pPic;
   IStream *pStream;
   HGLOBAL hG;
   HBITMAP hBitmap = 0;

   if( lString )
   {
      iFileSize = hb_parclen( 1 );
      hG = GlobalAlloc( GPTR, iFileSize );
      if( !hG )
      {
         HB_RETHANDLE( 0 );
         return;
      }
      memcpy( ( void * ) hG, ( void * ) cFileName, iFileSize );
   }
   else
   {
      fp = fopen( cFileName, "rb" );
      if( !fp )
      {
         HB_RETHANDLE( 0 );
         return;
      }

      fseek( fp, 0, SEEK_END );
      iFileSize = ftell( fp );
      hG = GlobalAlloc( GPTR, iFileSize );
      if( !hG )
      {
         fclose( fp );
         HB_RETHANDLE( 0 );
         return;
      }
      fseek( fp, 0, SEEK_SET );
      fread( ( void * ) hG, 1, iFileSize, fp );
      fclose( fp );
   }

   CreateStreamOnHGlobal( hG, 0, &pStream );

   if( !pStream )
   {
      GlobalFree( hG );
      HB_RETHANDLE( 0 );
      return;
   }

#if defined(__cplusplus)
   OleLoadPicture( pStream, 0, 0, IID_IPicture, ( void ** ) &pPic );
   pStream->Release(  );
#else
   OleLoadPicture( pStream, 0, 0, &IID_IPicture, ( void ** ) ( void * ) &pPic );
   pStream->lpVtbl->Release( pStream );
#endif

   GlobalFree( hG );

   if( !pPic )
   {
      HB_RETHANDLE( 0 );
      return;
   }

#if defined(__cplusplus)
   pPic->get_Handle( ( OLE_HANDLE * ) & hBitmap );
#else
   pPic->lpVtbl->get_Handle( pPic, ( OLE_HANDLE * ) ( void * ) &hBitmap );
#endif

   HB_RETHANDLE( CopyImage( hBitmap, IMAGE_BITMAP, 0, 0, LR_COPYRETURNORG ) );

#if defined(__cplusplus)
   pPic->Release(  );
#else
   pPic->lpVtbl->Release( pPic );
#endif
}

HB_FUNC( PATBLT )
{
   hb_retl( PatBlt( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
               hb_parni( 4 ), hb_parni( 5 ), hb_parnl( 6 ) ) );
}

HB_FUNC( SAVEDC )
{
   hb_retl( SaveDC( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( RESTOREDC )
{
   hb_retl( RestoreDC( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

HB_FUNC( CREATECOMPATIBLEDC )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );

   HB_RETHANDLE( hDCmem );
}

HB_FUNC( SETMAPMODE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   hb_retni( SetMapMode( hDC, hb_parni( 2 ) ) );
}

HB_FUNC( SETWINDOWORGEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetWindowOrgEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( SETWINDOWEXTEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetWindowExtEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( SETVIEWPORTORGEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetViewportOrgEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( SETVIEWPORTEXTEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetViewportExtEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( SETARCDIRECTION )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   hb_retni( SetArcDirection( hDC, hb_parni( 2 ) ) );
}

HB_FUNC( SETROP2 )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   hb_retni( SetROP2( hDC, hb_parni( 2 ) ) );
}

HB_FUNC( BITBLT )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDC1 = ( HDC ) HB_PARHANDLE( 6 );

   hb_retl( BitBlt( hDC, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ),
               hb_parni( 5 ), hDC1, hb_parni( 7 ), hb_parni( 8 ),
               hb_parnl( 9 ) ) );
}

HB_FUNC( CREATECOMPATIBLEBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBITMAP hBitmap;
   hBitmap = CreateCompatibleBitmap( hDC, hb_parni( 2 ), hb_parni( 3 ) );

   HB_RETHANDLE( hBitmap );
}

HB_FUNC( INFLATERECT )
{
   RECT pRect;
   int x = hb_parni( 2 );
   int y = hb_parni( 3 );

   if( HB_ISARRAY( 1 ) )
      Array2Rect( hb_param( 1, HB_IT_ARRAY ), &pRect );
   hb_retl( InflateRect( &pRect, x, y ) );

   hb_storvni( pRect.left, 1, 1 );
   hb_storvni( pRect.top, 1, 2 );
   hb_storvni( pRect.right, 1, 3 );
   hb_storvni( pRect.bottom, 1, 4 );
}

HB_FUNC( FRAMERECT )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
   HBRUSH hbr = ( HBRUSH ) HB_PARHANDLE( 3 );
   RECT pRect;

   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );

   hb_retni( FrameRect( hdc, &pRect, hbr ) );
}

HB_FUNC( DRAWFRAMECONTROL )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
   RECT pRect;
   UINT uType = hb_parni( 3 );  // frame-control type
   UINT uState = hb_parni( 4 ); // frame-control state

   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );

   hb_retl( DrawFrameControl( hdc, &pRect, uType, uState ) );
}

HB_FUNC( OFFSETRECT )
{
   RECT pRect;
   int x = hb_parni( 2 );
   int y = hb_parni( 3 );

   if( HB_ISARRAY( 1 ) )
      Array2Rect( hb_param( 1, HB_IT_ARRAY ), &pRect );

   hb_retl( OffsetRect( &pRect, x, y ) );
   hb_storvni( pRect.left, 1, 1 );
   hb_storvni( pRect.top, 1, 2 );
   hb_storvni( pRect.right, 1, 3 );
   hb_storvni( pRect.bottom, 1, 4 );
}

HB_FUNC( DRAWFOCUSRECT )
{
   RECT pRect;
   HDC hc = ( HDC ) HB_PARHANDLE( 1 );
   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );
   hb_retl( DrawFocusRect( hc, &pRect ) );
}

BOOL Array2Point( PHB_ITEM aPoint, POINT * pt )
{
   if( HB_IS_ARRAY( aPoint ) && hb_arrayLen( aPoint ) == 2 )
   {
      pt->x = hb_arrayGetNL( aPoint, 1 );
      pt->y = hb_arrayGetNL( aPoint, 2 );
      return TRUE;
   }
   return FALSE;
}

HB_FUNC( PTINRECT )
{
   POINT pt;
   RECT rect;

   Array2Rect( hb_param( 1, HB_IT_ARRAY ), &rect );
   Array2Point( hb_param( 2, HB_IT_ARRAY ), &pt );
   hb_retl( PtInRect( &rect, pt ) );
}

HB_FUNC( GETMEASUREITEMINFO )
{
   MEASUREITEMSTRUCT *lpdis = ( MEASUREITEMSTRUCT * ) HB_PARHANDLE( 1 );        //hb_parnl(1);
   PHB_ITEM aMetr = hb_itemArrayNew( 5 );
   PHB_ITEM temp;

   temp = hb_itemPutNL( NULL, lpdis->CtlType );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->CtlID );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->itemID );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->itemWidth );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, lpdis->itemHeight );
   hb_itemArrayPut( aMetr, 5, temp );
   hb_itemRelease( temp );
   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( COPYRECT )
{
   RECT p;

   Array2Rect( hb_param( 1, HB_IT_ARRAY ), &p );
   hb_itemRelease( hb_itemReturn( Rect2Array( &p ) ) );
}

HB_FUNC( GETWINDOWDC )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HDC hDC = GetWindowDC( hWnd );
   HB_RETHANDLE( hDC );
}

HB_FUNC( MODIFYSTYLE )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   DWORD dwStyle = GetWindowLongPtr( ( HWND ) hWnd, GWL_STYLE );
   DWORD a = hb_parnl( 2 );
   DWORD b = hb_parnl( 3 );
   DWORD dwNewStyle = ( dwStyle & ~a ) | b;
   SetWindowLong( hWnd, GWL_STYLE, dwNewStyle );
}

/*
HB_FUNC(PTRRECT2ARRAY)
{
   RECT *rect =   (RECT *) HB_PARHANDLE( 1 ) ;
   hb_itemRelease(hb_itemReturn(Rect2Array(&rect)));
} 
*/
