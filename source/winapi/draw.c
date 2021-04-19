/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level painting functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
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

#include "math.h"

#include "incomp_pointer.h"

#if defined( __BORLANDC__ ) && __BORLANDC__ == 0x0550
#ifdef __cplusplus
extern "C"
{
   STDAPI OleLoadPicture( LPSTREAM, LONG, BOOL, REFIID, PVOID * );
}
#else
//STDAPI OleLoadPicture(LPSTREAM,LONG,BOOL,REFIID,PVOID*);
#endif
#endif /* __BORLANDC__ */

#ifdef __cplusplus
#ifdef CINTERFACE
#undef CINTERFACE
#endif
#endif

typedef int ( _stdcall * TRANSPARENTBLT ) ( HDC, int, int, int, int, HDC, int,
      int, int, int, int );

static TRANSPARENTBLT s_pTransparentBlt = NULL;

#define GRADIENT_MAX_COLORS 16

#ifndef GRADIENT_FILL_RECT_H

#define GRADIENT_FILL_RECT_H 0
#define GRADIENT_FILL_RECT_V 1

#if !defined(__WATCOMC__) && !defined(__MINGW32__) && !defined(__MINGW64__)
typedef struct _GRADIENT_RECT
{
   ULONG UpperLeft;
   ULONG LowerRight;
} GRADIENT_RECT;
#endif

#if defined(__DMC__)
typedef struct _TRIVERTEX
{
   LONG x;
   LONG y;
   USHORT Red;
   USHORT Green;
   USHORT Blue;
   USHORT Alpha;
} TRIVERTEX, *PTRIVERTEX;
#endif

#endif
#ifndef M_PI
#define M_PI             3.14159265358979323846
#endif
#ifndef M_TWOPI
#define M_TWOPI         (M_PI * 2.0)
#endif
#ifndef M_PI_2
#define M_PI_2           1.57079632679489661923
#endif
#ifndef M_PI_4
#define M_PI_4           0.78539816339744830962
#endif


typedef int ( _stdcall * GRADIENTFILL ) ( HDC, PTRIVERTEX, int, PVOID, int, int );

static GRADIENTFILL FuncGradientFill = NULL;

void TransparentBmp( HDC hDC, int x, int y, int nWidthDest, int nHeightDest,
      HDC dcImage, int bmWidth, int bmHeight, int trColor )
{
   if( s_pTransparentBlt == NULL )
      s_pTransparentBlt =
            ( TRANSPARENTBLT )
            GetProcAddress( LoadLibrary( TEXT( "MSIMG32.DLL" ) ),
            "TransparentBlt" );
   s_pTransparentBlt( hDC, x, y, nWidthDest, nHeightDest, dcImage, 0, 0,
         bmWidth, bmHeight, trColor );
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

HB_FUNC( HWG_GETPPSRECT )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );

   PHB_ITEM aMetr = Rect2Array( &pps->rcPaint );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( HWG_GETPPSERASE )
{
   PAINTSTRUCT *pps = ( PAINTSTRUCT * ) HB_PARHANDLE( 1 );
   BOOL fErase = ( BOOL ) ( &pps->fErase );
   hb_retni( fErase );
}

HB_FUNC( HWG_GETUPDATERECT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   BOOL fErase;
   fErase = GetUpdateRect( hWnd, NULL, 0 );
   hb_retni( fErase );
}

HB_FUNC( HWG_INVALIDATERECT )
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

HB_FUNC( HWG_MOVETO )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   MoveToEx( hDC, x1, y1, NULL );
}

HB_FUNC( HWG_LINETO )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   LineTo( hDC, x1, y1 );
}

HB_FUNC( HWG_RECTANGLE )
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

HB_FUNC( HWG_BOX )
{
   Rectangle( ( HDC ) HB_PARHANDLE( 1 ),        // handle of device context
         hb_parni( 2 ),         // x-coord. of bounding rectangle's upper-left corner
         hb_parni( 3 ),         // y-coord. of bounding rectangle's upper-left corner
         hb_parni( 4 ),         // x-coord. of bounding rectangle's lower-right corner
         hb_parni( 5 )          // y-coord. of bounding rectangle's lower-right corner
          );
}

HB_FUNC( HWG_DRAWLINE )
{
   MoveToEx( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ), NULL );
   LineTo( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 4 ), hb_parni( 5 ) );
}

HB_FUNC( HWG_PIE )
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

HB_FUNC( HWG_ELLIPSE )
{
   int res = Ellipse( ( HDC ) HB_PARHANDLE( 1 ),        // handle to device context
         hb_parni( 2 ),         // x-coord. of bounding rectangle's upper-left corner
         hb_parni( 3 ),         // y-coord. of bounding rectangle's upper-left corner
         hb_parni( 4 ),         // x-coord. of bounding rectangle's lower-right corner
         hb_parni( 5 )          // y-coord. bounding rectangle's f lower-right corner
          );

   hb_retnl( res ? 0 : ( LONG ) GetLastError(  ) );
}

HB_FUNC( HWG_DRAWGRID )
{
   HDC hDC = (HDC) HB_PARHANDLE( 1 );
   int x1 = hb_parni(2), y1 = hb_parni(3), x2 = hb_parni(4), y2 = hb_parni(5);
   int n = ( HB_ISNIL( 6 ) ) ? 4 : hb_parni( 6 );
   COLORREF lColor = ( HB_ISNIL( 7 ) ) ? 0 : ( COLORREF ) hb_parnl( 7 );
   int i, j;

   for( i = x1+n; i < x2; i+=n )
      for( j = y1+n; j < y2; j+=n )
         SetPixel( hDC, i, j, lColor );
}

HB_FUNC( HWG_FILLRECT )
{
   RECT rc;

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   FillRect( ( HDC ) HB_PARHANDLE( 1 ), &rc,
         HB_ISPOINTER( 6 ) ? ( HBRUSH )HB_PARHANDLE( 6 ) : ( HBRUSH )hb_parnl(6) );
}

/*
 * hwg_Arc( hDC, xc, yc, radius, iAngleStart, iAngleEnd )
 * Draws an arc with a center in xc, yc, with a radius from an angle
 * iAngleStart to iAngleEnd. Angles are passed in degrees.
 * 0 corresponds to the standard X axis, drawing direction is clockwise.
 */
HB_FUNC( HWG_ARC )
{
   HDC hDC = (HDC) HB_PARHANDLE( 1 );
   int xc = hb_parni(2), yc = hb_parni(3);
   int radius = hb_parni(4);
   int iAngle1 = hb_parni(5), iAngle2 = hb_parni(6);
   int x1, y1;

   iAngle1 = iAngle2 - iAngle1;
   iAngle2 = 360 - iAngle2;

   x1 = xc + radius * cos( iAngle2 * M_PI / 180 );
   y1 = yc - radius * sin( iAngle2 * M_PI / 180 );
   MoveToEx( hDC, x1, y1, (LPPOINT) NULL );
   AngleArc( hDC, xc, yc,
      (DWORD) radius,
      (FLOAT) iAngle2,
      (FLOAT) iAngle1 );
}

/*
 * hwg_RoundRect( hDC, x1, y1, x2, y2, iRadiusH [, iRadiusV] )
 */
HB_FUNC( HWG_ROUNDRECT )
{
   int iWidth = hb_parni( 6 );
   int iHeight = ( HB_ISNIL( 7 ) ) ? iWidth : hb_parni( 7 );

   hb_parl( RoundRect( ( HDC ) HB_PARHANDLE( 1 ),       // handle of device context
               hb_parni( 2 ),   // x-coord. of bounding rectangle's upper-left corner
               hb_parni( 3 ),   // y-coord. of bounding rectangle's upper-left corner
               hb_parni( 4 ),   // x-coord. of bounding rectangle's lower-right corner
               hb_parni( 5 ),   // y-coord. of bounding rectangle's lower-right corner
               iWidth * 2,      // width of ellipse used to draw rounded corners
               iHeight * 2      // height of ellipse used to draw rounded corners
          ) );
}

HB_FUNC( HWG_REDRAWWINDOW )
{
   RECT rc;

   if( hb_pcount(  ) > 3 )
   {
      int x = ( hb_pcount(  ) > 3 && !HB_ISNIL( 3 ) ) ? hb_parni( 3 ) : 0;
      int y = ( hb_pcount(  ) >= 4 && !HB_ISNIL( 4 ) ) ? hb_parni( 4 ) : 0;
      int w = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 5 ) ) ? hb_parni( 5 ) : 0;
      int h = ( hb_pcount(  ) >= 6 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
      rc.left = x - 1;
      rc.top = y - 1;
      rc.right = x + w + 1;
      rc.bottom = y + h + 1;
   }
   RedrawWindow( ( HWND ) HB_PARHANDLE( 1 ),    // handle of window
         ( hb_pcount(  ) > 3 ) ? &rc : NULL,    // address of structure with update rectangle
         NULL,                  // handle of update region
         ( UINT ) hb_parni( 2 ) // array of redraw flags
          );
}

HB_FUNC( HWG_DRAWBUTTON )
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
HB_FUNC( HWG_DRAWEDGE )
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

HB_FUNC( HWG_LOADICON )
{
   if( HB_ISNUM( 1 ) )
      HB_RETHANDLE( LoadIcon( NULL, MAKEINTRESOURCE( hb_parni( 1 ) ) ) );
   else
   {
      void *hString;
      HB_RETHANDLE( LoadIcon( GetModuleHandle( NULL ), HB_PARSTR( 1, &hString,
                        NULL ) ) );
      hb_strfree( hString );
   }
}

HB_FUNC( HWG_LOADIMAGE )
{
   void *hString = NULL;

   HB_RETHANDLE( LoadImage( HB_ISNIL( 1 ) ? GetModuleHandle( NULL ) : ( HINSTANCE ) hb_parnl( 1 ),      // handle of the instance that contains the image
               HB_ISNUM( 2 ) ? MAKEINTRESOURCE( hb_parni( 2 ) ) : HB_PARSTR( 2, &hString, NULL ),       // name or identifier of image
               ( UINT ) hb_parni( 3 ),  // type of image
               hb_parni( 4 ),   // desired width
               hb_parni( 5 ),   // desired height
               ( UINT ) hb_parni( 6 )   // load flags
          ) );
   hb_strfree( hString );
}

HB_FUNC( HWG_LOADBITMAP )
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
      void *hString;
      HB_RETHANDLE( LoadBitmap( GetModuleHandle( NULL ), HB_PARSTR( 1,
                        &hString, NULL ) ) );
      hb_strfree( hString );
   }
}

/*
 * Window2Bitmap( hWnd )
 */
HB_FUNC( HWG_WINDOW2BITMAP )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   //BOOL lFull = ( HB_ISNIL( 2 ) ) ? 0 : ( BOOL ) hb_parl( 2 );
   //HDC hDC = ( lFull ) ? GetWindowDC( hWnd ) : GetDC( hWnd );
   HDC hDC = GetWindowDC( hWnd );
   HDC hDCmem = CreateCompatibleDC( hDC );
   HBITMAP hBitmap;
   int x1 = HB_ISNUM(2)? hb_parni(2):0, y1 = HB_ISNUM(3)? hb_parni(3):0;
   int width= HB_ISNUM(4)? hb_parni(4):0, height = HB_ISNUM(5)? hb_parni(5):0;
   RECT rc;

   if( width == 0 || height == 0 )
   {
      GetWindowRect( hWnd, &rc );
      width = rc.right - rc.left;
      height = rc.bottom - rc.top;
   }
   /*
   if( lFull )
      GetWindowRect( hWnd, &rc );
   else
      GetClientRect( hWnd, &rc );
   */


   hBitmap = CreateCompatibleBitmap( hDC, width, height );
   SelectObject( hDCmem, hBitmap );

   BitBlt( hDCmem, 0, 0, width, height, hDC, x1, y1, SRCCOPY );

   DeleteDC( hDCmem );
   DeleteDC( hDC );
   HB_RETHANDLE( hBitmap );
}

/*
 * DrawBitmap( hDC, hBitmap, style, x, y, width, height )
 */
HB_FUNC( HWG_DRAWBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   DWORD dwraster = ( HB_ISNIL( 3 ) ) ? SRCCOPY : ( DWORD ) hb_parnl( 3 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   BITMAP bitmap;
   int nWidthDest = ( hb_pcount(  ) >= 5 &&
         !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
   int nHeightDest = ( hb_pcount(  ) >= 6 &&
         !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : 0;

   SelectObject( hDCmem, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   if( nWidthDest && ( nWidthDest != bitmap.bmWidth ||
               nHeightDest != bitmap.bmHeight ) )
   {
      SetStretchBltMode( hDC, COLORONCOLOR );
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
HB_FUNC( HWG_DRAWTRANSPARENTBITMAP )
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
   int nWidthDest = ( hb_pcount(  ) >= 5 &&
         !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : 0;
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
      SetStretchBltMode( hDC, COLORONCOLOR );
      TransparentBmp( hDC, x, y, nWidthDest, nHeightDest, dcImage,
            bitmap.bmWidth, bitmap.bmHeight, trColor );

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
      TransparentBmp( hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage,
            bitmap.bmWidth, bitmap.bmHeight, trColor );
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

/*  SpreadBitmap( hDC, hBitmap [, nLeft, nTop, nRight, nBottom] )
*/
HB_FUNC( HWG_SPREADBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );
   //DWORD dwraster = ( HB_ISNIL( 3 ) ) ? SRCCOPY : ( DWORD ) hb_parnl( 3 );
   HBITMAP hBitmap = ( HBITMAP ) HB_PARHANDLE( 2 );
   BITMAP bitmap;
   RECT rc;
   int nLeft, nWidth, nHeight;

   rc.left = (HB_ISNUM(3))? hb_parni(3) : 0;
   rc.top = (HB_ISNUM(4))? hb_parni(4) : 0;
   rc.right = (HB_ISNUM(5))? hb_parni(5) : 0;
   rc.bottom = (HB_ISNUM(6))? hb_parni(6) : 0;

   SelectObject( hDCmem, hBitmap );
   GetObject( hBitmap, sizeof( BITMAP ), ( LPVOID ) & bitmap );
   if( rc.left == 0 && rc.right == 0 )
      GetClientRect( WindowFromDC( hDC ), &rc );

   nLeft = rc.left;
   while( rc.top < rc.bottom )
   {
      nHeight = (rc.bottom-rc.top >= bitmap.bmHeight)? bitmap.bmHeight : rc.bottom-rc.top;
      while( rc.left < rc.right )
      {
         nWidth = (rc.right-rc.left >= bitmap.bmWidth)? bitmap.bmWidth : rc.right-rc.left;
         BitBlt( hDC, rc.left, rc.top, nWidth, nHeight, hDCmem, 0, 0, SRCCOPY );
         rc.left += bitmap.bmWidth;
      }
      rc.left = nLeft;
      rc.top += bitmap.bmHeight;
   }

   DeleteDC( hDCmem );
}


/*  CenterBitmap( hDC, hWnd, hBitmap, style, brush )
*/

HB_FUNC( HWG_CENTERBITMAP )
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


HB_FUNC( HWG_GETBITMAPSIZE )
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

HB_FUNC( HWG_GETICONSIZE )
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

/*
  hwg_Openbitmap( cBitmap, hDC )
  cBitmap : File name of bitmap
  hDC     : Printer device handle 
*/
HB_FUNC( HWG_OPENBITMAP )
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
   void *hString;
   HANDLE hfbm;

   hfbm = CreateFile( HB_PARSTR( 1, &hString, NULL ), GENERIC_READ,
         FILE_SHARE_READ, ( LPSECURITY_ATTRIBUTES ) NULL, OPEN_EXISTING,
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


/*
 *  hwg_SaveBitMap( cfilename , hBitmap )
 */
HB_FUNC( HWG_SAVEBITMAP )
{
   HBITMAP hBitmap = (HBITMAP) HB_PARHANDLE( 2 );
   HDC hDC;
   int iBits;
   WORD wBitCount;
   DWORD dwPaletteSize = 0, dwBmBitsSize, dwDIBSize, dwWritten = 0;
   BITMAP Bitmap0;
   BITMAPFILEHEADER bmfHdr;
   BITMAPINFOHEADER bi;
   LPBITMAPINFOHEADER lpbi;
   HANDLE fh, hDib, hPal, hOldPal2 = NULL;
   void *hString;

   hDC = CreateDC( "DISPLAY", NULL, NULL, NULL );
   iBits = GetDeviceCaps( hDC, BITSPIXEL ) * GetDeviceCaps( hDC, PLANES );
   DeleteDC( hDC );
   if( iBits <= 1 )
      wBitCount = 1;
   else if( iBits <= 4 )
      wBitCount = 4;
   else if( iBits <= 8 )
      wBitCount = 8;
   else
      wBitCount = 24;
   GetObject( hBitmap, sizeof( Bitmap0 ), ( LPSTR ) & Bitmap0 );
   bi.biSize = sizeof( BITMAPINFOHEADER );
   bi.biWidth = Bitmap0.bmWidth;
   bi.biHeight = -Bitmap0.bmHeight;
   bi.biPlanes = 1;
   bi.biBitCount = wBitCount;
   bi.biCompression = BI_RGB;
   bi.biSizeImage = 0;
   bi.biXPelsPerMeter = 0;
   bi.biYPelsPerMeter = 0;
   bi.biClrImportant = 0;
   bi.biClrUsed = 256;
   dwBmBitsSize = ( ( Bitmap0.bmWidth * wBitCount + 31 ) & ~31 ) / 8
         * Bitmap0.bmHeight;
   hDib = GlobalAlloc( GHND,
         dwBmBitsSize + dwPaletteSize + sizeof( BITMAPINFOHEADER ) );
   lpbi = ( LPBITMAPINFOHEADER ) GlobalLock( hDib );
   *lpbi = bi;

   hPal = GetStockObject( DEFAULT_PALETTE );
   if( hPal )
   {
      hDC = GetDC( NULL );
      hOldPal2 = SelectPalette( hDC, ( HPALETTE ) hPal, FALSE );
      RealizePalette( hDC );
   }

   GetDIBits( hDC, hBitmap, 0, ( UINT ) Bitmap0.bmHeight,
         ( LPSTR ) lpbi + sizeof( BITMAPINFOHEADER ) + dwPaletteSize,
         ( BITMAPINFO * ) lpbi, DIB_RGB_COLORS );

   if( hOldPal2 )
   {
      SelectPalette( hDC, ( HPALETTE ) hOldPal2, TRUE );
      RealizePalette( hDC );
      ReleaseDC( NULL, hDC );
   }

   fh = CreateFile( HB_PARSTR( 1, &hString, NULL ), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
         FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL );
   hb_strfree( hString );

   if( fh == INVALID_HANDLE_VALUE )
   {
      hb_retl( 0 );
      return;
   }

   bmfHdr.bfType = 0x4D42;      // "BM"
   dwDIBSize =
         sizeof( BITMAPFILEHEADER ) + sizeof( BITMAPINFOHEADER ) +
         dwPaletteSize + dwBmBitsSize;
   bmfHdr.bfSize = dwDIBSize;
   bmfHdr.bfReserved1 = 0;
   bmfHdr.bfReserved2 = 0;
   bmfHdr.bfOffBits =
         ( DWORD ) sizeof( BITMAPFILEHEADER ) +
         ( DWORD ) sizeof( BITMAPINFOHEADER ) + dwPaletteSize;

   WriteFile( fh, ( LPSTR ) & bmfHdr, sizeof( BITMAPFILEHEADER ), &dwWritten,
         NULL );

   WriteFile( fh, ( LPSTR ) lpbi, dwDIBSize, &dwWritten, NULL );
   GlobalUnlock( hDib );
   GlobalFree( hDib );
   CloseHandle( fh );
   hb_retl( 1 );
}

HB_FUNC( HWG_DRAWICON )
{
   DrawIcon( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 3 ), hb_parni( 4 ),
         ( HICON ) HB_PARHANDLE( 2 ) );
}

HB_FUNC( HWG_GETSYSCOLOR )
{
   hb_retnl( ( LONG ) GetSysColor( hb_parni( 1 ) ) );
}

HB_FUNC( HWG_GETSYSCOLORBRUSH )
{
   HB_RETHANDLE( GetSysColorBrush( hb_parni( 1 ) ) );
}

HB_FUNC( HWG_CREATEPEN )
{
   HB_RETHANDLE( CreatePen( hb_parni( 1 ),      // pen style
               hb_parni( 2 ),   // pen width
               ( COLORREF ) hb_parnl( 3 )       // pen color
          ) );
}

HB_FUNC( HWG_CREATESOLIDBRUSH )
{
   HB_RETHANDLE( CreateSolidBrush( ( COLORREF ) hb_parnl( 1 )   // brush color
          ) );
}

HB_FUNC( HWG_CREATEHATCHBRUSH )
{
   HB_RETHANDLE( CreateHatchBrush( hb_parni( 1 ),
               ( COLORREF ) hb_parnl( 2 ) ) );
}

HB_FUNC( HWG_SELECTOBJECT )
{
   HB_RETHANDLE( SelectObject( ( HDC ) HB_PARHANDLE( 1 ),       // handle of device context
               ( HGDIOBJ ) HB_PARHANDLE( 2 )    // handle of object
          ) );
}

HB_FUNC( HWG_DELETEOBJECT )
{
   DeleteObject( ( HGDIOBJ ) HB_PARHANDLE( 1 )  // handle of object
          );
}

HB_FUNC( HWG_GETDC )
{
   HB_RETHANDLE( GetDC( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_RELEASEDC )
{
   HB_RETHANDLE( ReleaseDC( ( HWND ) HB_PARHANDLE( 1 ),
               ( HDC ) HB_PARHANDLE( 2 ) ) );
}

HB_FUNC( HWG_GETDRAWITEMINFO )
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
HB_FUNC( HWG_DRAWGRAYBITMAP )
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

HB_FUNC( HWG_OPENIMAGE )
{
   const char *cFileName = hb_parc( 1 );
   BOOL bString = ( HB_ISNIL( 2 ) ) ? 0 : hb_parl( 2 );
   int iType = ( HB_ISNIL( 3 ) ) ? IMAGE_BITMAP : hb_parni( 3 );
   int iFileSize;
   FILE *fp;
   LPPICTURE pPic;
   IStream *pStream;
   HGLOBAL hG;

   if( bString )
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
   OleLoadPicture( pStream, 0, 0, &IID_IPicture,
         ( void ** ) ( void * ) &pPic );
   pStream->lpVtbl->Release( pStream );
#endif

   GlobalFree( hG );

   if( !pPic )
   {
      HB_RETHANDLE( 0 );
      return;
   }

   if( iType == IMAGE_BITMAP )
   {
      HBITMAP hBitmap = 0;
#if defined(__cplusplus)
      pPic->get_Handle( ( OLE_HANDLE * ) & hBitmap );
#else
      pPic->lpVtbl->get_Handle( pPic, ( OLE_HANDLE * ) ( void * ) &hBitmap );
#endif

      HB_RETHANDLE( CopyImage( hBitmap, IMAGE_BITMAP, 0, 0, LR_COPYRETURNORG ) );
   }
   else if( iType == IMAGE_ICON )
   {
      HICON hIcon = 0;
#if defined(__cplusplus)
      pPic->get_Handle( ( OLE_HANDLE * ) & hIcon );
#else
      pPic->lpVtbl->get_Handle( pPic, ( OLE_HANDLE * ) ( void * ) &hIcon );
#endif

      HB_RETHANDLE( CopyImage( hIcon, IMAGE_ICON, 0, 0, 0 ) );
   }
   else
   {
      HCURSOR hCur = 0;
#if defined(__cplusplus)
      pPic->get_Handle( ( OLE_HANDLE * ) & hCur );
#else
      pPic->lpVtbl->get_Handle( pPic, ( OLE_HANDLE * ) ( void * ) &hCur );
#endif

      HB_RETHANDLE( CopyImage( hCur, IMAGE_CURSOR, 0, 0, 0 ) );
   }

#if defined(__cplusplus)
   pPic->Release(  );
#else
   pPic->lpVtbl->Release( pPic );
#endif
}

HB_FUNC( HWG_PATBLT )
{
   hb_retl( PatBlt( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
               hb_parni( 4 ), hb_parni( 5 ), hb_parnl( 6 ) ) );
}

HB_FUNC( HWG_SAVEDC )
{
   hb_retl( SaveDC( ( HDC ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_RESTOREDC )
{
   hb_retl( RestoreDC( ( HDC ) HB_PARHANDLE( 1 ), hb_parni( 2 ) ) );
}

HB_FUNC( HWG_CREATECOMPATIBLEDC )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDCmem = CreateCompatibleDC( hDC );

   HB_RETHANDLE( hDCmem );
}

HB_FUNC( HWG_SETMAPMODE )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   hb_retni( SetMapMode( hDC, hb_parni( 2 ) ) );
}

HB_FUNC( HWG_SETWINDOWORGEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetWindowOrgEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( HWG_SETWINDOWEXTEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetWindowExtEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( HWG_SETVIEWPORTORGEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetViewportOrgEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( HWG_SETVIEWPORTEXTEX )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   SetViewportExtEx( hDC, hb_parni( 2 ), hb_parni( 3 ), NULL );
   hb_stornl( 0, 4 );
}

HB_FUNC( HWG_SETARCDIRECTION )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   hb_retni( SetArcDirection( hDC, hb_parni( 2 ) ) );
}

HB_FUNC( HWG_SETROP2 )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );

   hb_retni( SetROP2( hDC, hb_parni( 2 ) ) );
}

HB_FUNC( HWG_BITBLT )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HDC hDC1 = ( HDC ) HB_PARHANDLE( 6 );

   hb_retl( BitBlt( hDC, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ),
               hb_parni( 5 ), hDC1, hb_parni( 7 ), hb_parni( 8 ),
               hb_parnl( 9 ) ) );
}

HB_FUNC( HWG_CREATECOMPATIBLEBITMAP )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   HBITMAP hBitmap;
   hBitmap = CreateCompatibleBitmap( hDC, hb_parni( 2 ), hb_parni( 3 ) );

   HB_RETHANDLE( hBitmap );
}

HB_FUNC( HWG_INFLATERECT )
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

HB_FUNC( HWG_FRAMERECT )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
   HBRUSH hbr = ( HBRUSH ) HB_PARHANDLE( 3 );
   RECT pRect;

   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );

   hb_retni( FrameRect( hdc, &pRect, hbr ) );
}

HB_FUNC( HWG_DRAWFRAMECONTROL )
{
   HDC hdc = ( HDC ) HB_PARHANDLE( 1 );
   RECT pRect;
   UINT uType = hb_parni( 3 );  // frame-control type
   UINT uState = hb_parni( 4 ); // frame-control state

   if( HB_ISARRAY( 2 ) )
      Array2Rect( hb_param( 2, HB_IT_ARRAY ), &pRect );

   hb_retl( DrawFrameControl( hdc, &pRect, uType, uState ) );
}

HB_FUNC( HWG_OFFSETRECT )
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

HB_FUNC( HWG_DRAWFOCUSRECT )
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

HB_FUNC( HWG_PTINRECT )
{
   POINT pt;
   RECT rect;

   Array2Rect( hb_param( 1, HB_IT_ARRAY ), &rect );
   Array2Point( hb_param( 2, HB_IT_ARRAY ), &pt );
   hb_retl( PtInRect( &rect, pt ) );
}

HB_FUNC( HWG_GETMEASUREITEMINFO )
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

HB_FUNC( HWG_COPYRECT )
{
   RECT p;

   Array2Rect( hb_param( 1, HB_IT_ARRAY ), &p );
   hb_itemRelease( hb_itemReturn( Rect2Array( &p ) ) );
}

HB_FUNC( HWG_GETWINDOWDC )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HDC hDC = GetWindowDC( hWnd );
   HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_MODIFYSTYLE )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   DWORD dwStyle = GetWindowLongPtr( ( HWND ) hWnd, GWL_STYLE );
   DWORD a = hb_parnl( 2 );
   DWORD b = hb_parnl( 3 );
   DWORD dwNewStyle = ( dwStyle & ~a ) | b;
   SetWindowLongPtr( hWnd, GWL_STYLE, dwNewStyle );
}

#define SECTORS_NUM 100

/*
 * hwg_drawGradient( hDC, x1, y1, x2, y2, int type, array colors, array stops, array radiuses )
 * This function draws rectangle with rounded corners and fill it with gradient pattern.
 * hDC - handle of device context;
 * x1 and y1 - coordinates of upper left corner;
 * x2 and y2 - coordinates of bottom right corner;
 * type - the type of gradient filling:
 *    1 - vertical and down;
 *    2 - vertical and up;
 *    3 - horizontal and to the right;
 *    4 - horizontal and to the left;
 *    5 - diagonal right-up;
 *    6 - diagonal left-down;
 *    7 - diagonal right-down;
 *    8 - diagonal left-up;
 *    9 - radial gradient;
 * colors - our colors (maximum - 16 colors), a color can be represented as 0xBBGGRR;
 * stops - fractions on interval [0;1] that correspond to the colors,
 * a stop determines the position where the corresponding color reaches its maximum;
 * radiuses - for our rounded corners:
 *    first  - for upper left;
 *    second - for upper right;
 *    third  - for bottom right;
 *    fourth - for bottom left;
 */
HB_FUNC( HWG_DRAWGRADIENT )
{
   HDC hDC = ( HDC ) HB_PARHANDLE( 1 );
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );
   int type = ( HB_ISNUM(6) ) ? hb_parni( 6 ) : 1;
   PHB_ITEM pArrColor = hb_param( 7, HB_IT_ARRAY );
   long int color;
   int red[GRADIENT_MAX_COLORS], green[GRADIENT_MAX_COLORS], blue[GRADIENT_MAX_COLORS], index;
   int cur_red, cur_green, cur_blue, section_len;
   double red_step, green_step, blue_step;
   PHB_ITEM pArrStop = hb_param( 8, HB_IT_ARRAY );
   double stop;
   int stop_x[GRADIENT_MAX_COLORS], stop_y[GRADIENT_MAX_COLORS], coord_stop;
   int isH = 0, isV = 0, isD = 0, is_5_6 = 0, isR = 0;
   int x_center = 0, y_center = 0, gr_radius = 0;
   PHB_ITEM pArrRadius = hb_param( 9, HB_IT_ARRAY );
   int radius[4];
   double angle, angle_step, coord_x, coord_y, min_delta, delta;
   int user_colors_num, colors_num, user_stops_num, user_radiuses_num, i, j, k;
   HDC hDC_mem = NULL;
   HBITMAP bmp = NULL;
   HPEN hPen, hPenOld;
   HBRUSH hBrush;
   TRIVERTEX vertex[(GRADIENT_MAX_COLORS-1)*2];
   GRADIENT_RECT gRect[GRADIENT_MAX_COLORS-1];
   int fill_type;
   POINT polygon[(SECTORS_NUM+1)*4], coords[SECTORS_NUM+1], candidates[4], center[4], edge[4];
   int polygon_len = 0, nearest_coord = 0, cycle_start, cycle_stop, cycle_step;
   int convert[4][2] = { {-1,1}, {1,1}, {1,-1}, {-1,-1} };
   long x, y;
   
   if ( !pArrColor || ( user_colors_num = hb_arrayLen( pArrColor ) ) == 0 )
      return;
   
   if ( user_colors_num >= 2 )
   {
      colors_num = ( user_colors_num <= GRADIENT_MAX_COLORS ) ? user_colors_num : GRADIENT_MAX_COLORS;
      user_stops_num = ( pArrStop ) ? hb_arrayLen( pArrStop ) : 0;

      type = ( type >= 1 && type <= 9 ) ? type : 1;
      if ( type == 1 || type == 2 ) isV = 1;
      if ( type == 3 || type == 4 ) isH = 1;
      if ( type >= 5 && type <= 8 ) isD = 1;
      if ( type == 9 )
      {
         isR = 1;
         x_center = (x2 - x1) / 2 + x1;
         y_center = (y2 - y1) / 2 + y1;
         gr_radius = sqrt( pow((long double)(x2-x1),2) + pow((long double)(y2-y1),2) ) / 2;
      }

      // calculate stops and colors for our gradient
      for ( i = 0; i < colors_num; i++ )
      {
         stop = ( i < user_stops_num ) ? hb_arrayGetND( pArrStop, i+1 ) : 1. / (colors_num-1) * i;
         if ( isV )
         {
            coord_stop = floor( stop * (y2-y1+1) + 0.5 );
            if ( type == 1 )
               stop_y[i] = y1 + coord_stop;
            else
               stop_y[colors_num-1-i] = y2 + 1 - coord_stop;
         }
         if ( isH )
         {
            coord_stop = floor( stop * (x2-x1+1) + 0.5 );
            if ( type == 3 )
               stop_x[i] = x1 + coord_stop;
            else
               stop_x[colors_num-1-i] = x2 + 1 - coord_stop;
         }
         if ( isD )
         {
            coord_stop = floor( stop * 2*(x2-x1+1) + 0.5 );
            if ( type == 5 || type == 7 )
               stop_x[i] = 2*x1-x2-1 + coord_stop;
            else
               stop_x[colors_num-1-i] = x2 + 1 - coord_stop;
         }
         if ( isR )
            stop_x[i] = floor( stop * gr_radius + 0.5 );

         color = hb_arrayGetNL( pArrColor, i+1 );
         index = ( type == 2 || type == 4 || type == 6 || type == 8 ) ? colors_num-1-i : i;
         red[ index ]   = color % 256;
         green[ index ] = color / 256 % 256;
         blue[ index ]  = color / 256 / 256 % 256;
      }

      // Initially we draw gradient pattern into memory device -
      // create the memory device context that compatable to our main device.
      hDC_mem = CreateCompatibleDC( hDC );

      if ( type >= 1 && type <= 4 ) // horizontal and vertical gradients
      {
     
         // We create a bitmap that compatable to our main device
         // and attach it to the memory device context.
         bmp = ( HBITMAP ) CreateCompatibleBitmap( hDC, x2+1, y2+1 );
         SelectObject( hDC_mem, bmp );
        
         // 1. Array of TRIVERTEX structures that describe
         // positional and color values for each vertex
         // (for a rectangle two vertices need to be defined: upper-left and lower-right).
         // 2. Array of GRADIENT_RECT structures that
         // reference the TRIVERTEX vertices.
         for ( i = 1; i < colors_num; i++ )
         {
            vertex[(i-1)*2].x     = ( isH ) ? stop_x[i-1] : x1;
            vertex[(i-1)*2].y     = ( isV ) ? stop_y[i-1] : y1;
            vertex[(i-1)*2].Red   = (COLOR16) (red[i-1] * 256);
            vertex[(i-1)*2].Green = (COLOR16) (green[i-1] * 256);
            vertex[(i-1)*2].Blue  = (COLOR16) (blue[i-1] * 256);
            vertex[(i-1)*2].Alpha = 0x0000;
         
            vertex[(i-1)*2+1].x     = ( isH ) ? stop_x[i] : x2 + 1;
            vertex[(i-1)*2+1].y     = ( isV ) ? stop_y[i] : y2 + 1;
            vertex[(i-1)*2+1].Red   = (COLOR16) (red[i] * 256);
            vertex[(i-1)*2+1].Green = (COLOR16) (green[i] * 256);
            vertex[(i-1)*2+1].Blue  = (COLOR16) (blue[i] * 256);
            vertex[(i-1)*2+1].Alpha = 0x0000;
            
            gRect[i-1].UpperLeft  = (i-1)*2;
            gRect[i-1].LowerRight = (i-1)*2+1;
         }
               
         if( FuncGradientFill == NULL )
            FuncGradientFill = ( GRADIENTFILL )
               GetProcAddress( LoadLibrary( TEXT( "MSIMG32.DLL" ) ),
                  "GradientFill" );

         fill_type = ( isV ) ? GRADIENT_FILL_RECT_V : GRADIENT_FILL_RECT_H;

         // drawing gradient on the bitmap in the memory device context
         FuncGradientFill( hDC_mem, vertex, (colors_num-1)*2, gRect, (colors_num-1), fill_type );

         // shifts of edges
         if( ( isV && stop_y[0] > y1 ) || ( isH && stop_x[0] > x1 ) )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[0], green[0], blue[0]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[0], green[0], blue[0]) );
            SelectObject( hDC_mem, hBrush );
            if ( isV )
               Rectangle( hDC_mem, x1, y1, x2 + 1, stop_y[0] );
            else
               Rectangle( hDC_mem, x1, y1, stop_x[0], y2 + 1 );

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            DeleteObject( hBrush );
         }
         if ( ( isV && stop_y[colors_num-1] < y2 + 1 ) || ( isH && stop_x[colors_num-1] < x2 + 1 ) )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            SelectObject( hDC_mem, hBrush );
            if ( isV )
               Rectangle( hDC_mem, x1, stop_y[colors_num-1], x2 + 1, y2 + 1 );
            else
               Rectangle( hDC_mem, stop_x[colors_num-1], y1, x2 + 1, y2 + 1 );

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            DeleteObject( hBrush );
         }
         
      } // end horizontal and vertical gradients
      else if ( type >= 5 && type <= 8 ) // diagonal gradients
      {
         // We create a bitmap that compatable to our main device
         // and attach it to the memory device context.
         bmp = ( HBITMAP ) CreateCompatibleBitmap( hDC, 2*x2-x1+2, y2+1 );
         SelectObject( hDC_mem, bmp );

         if ( type == 5 || type == 6 ) is_5_6 = 1;

         for ( i = 1; i < colors_num; i++ )
         {
            section_len = stop_x[i] - stop_x[i-1];
            red_step = (double)( red[i] - red[i-1] ) / section_len;
            green_step = (double)( green[i] - green[i-1] ) / section_len;
            blue_step = (double)( blue[i] - blue[i-1] ) / section_len;
            for ( j = stop_x[i-1], k = 0; j <= stop_x[i]; j++, k++ )
            {
               cur_red = floor( red[i-1] + k * red_step + 0.5 );
               cur_green = floor( green[i-1] + k * green_step + 0.5 );
               cur_blue = floor( blue[i-1] + k * blue_step + 0.5 );
               hPen = CreatePen( PS_SOLID, 1, RGB( cur_red, cur_green, cur_blue ) );
               hPenOld = SelectObject( hDC_mem, hPen );

               MoveToEx( hDC_mem, j, (is_5_6)?y1:y2, NULL );
               LineTo( hDC_mem, j + x2-x1+1, (is_5_6)?y2:y1 );
               // LineTo doesn't draw the last pixel
               SetPixel( hDC_mem, j + x2-x1+1, (is_5_6)?y2:y1, RGB( cur_red, cur_green, cur_blue ) );

               SelectObject( hDC_mem, hPenOld );
               DeleteObject( hPen );
            }
         }
         
         // shifts of edges
         if ( stop_x[0] > 2*x1-x2-1 ) // on the left
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[0], green[0], blue[0]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[0], green[0], blue[0]) );
            SelectObject( hDC_mem, hBrush );

            edge[0].x = x1;
            edge[0].y = ( is_5_6 ) ? y2 : y1;
            edge[1].x = stop_x[0] + x2 - x1;
            edge[1].y = ( is_5_6 ) ? y2 : y1;
            edge[2].x = stop_x[0] - 1;
            edge[2].y = ( is_5_6 ) ? y1 : y2;
            edge[3].x = 2*x1 - x2 - 1;
            edge[3].y = ( is_5_6 ) ? y1 : y2;
            
            Polygon( hDC_mem, edge, 4 );

            SelectObject( hDC_mem, hPenOld ); 
            DeleteObject( hPen );
            DeleteObject( hBrush );
         }
         if ( stop_x[colors_num-1] < x2 ) // on the right
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            SelectObject( hDC_mem, hBrush );

            edge[0].x = x2;
            edge[0].y = ( is_5_6 ) ? y1 : y2;
            edge[1].x = stop_x[colors_num-1] + 1;
            edge[1].y = ( is_5_6 ) ? y1 : y2;
            edge[2].x = stop_x[colors_num-1] + x2 - x1 + 2;
            edge[2].y = ( is_5_6 ) ? y2 : y1;
            edge[3].x = 2*x2 - x1 + 1;
            edge[3].y = ( is_5_6 ) ? y2 : y1;
            
            Polygon( hDC_mem, edge, 4 );

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            DeleteObject( hBrush );
         }
         
      } // end diagonal gradients
      else if ( type == 9 ) // radial gradients
      {
         // We create a bitmap that compatable to our main device
         // and attach it to the memory device context.
         bmp = ( HBITMAP ) CreateCompatibleBitmap( hDC, x2+1, y2+1 );
         SelectObject( hDC_mem, bmp );
      
         // shifts of edge
         if ( stop_x[colors_num-1] < gr_radius )
         {
            hPen = CreatePen( PS_SOLID, 1, RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            hPenOld = SelectObject( hDC_mem, hPen );
            hBrush = CreateSolidBrush( RGB(red[colors_num-1], green[colors_num-1], blue[colors_num-1]) );
            SelectObject( hDC_mem, hBrush );
            
            Rectangle( hDC_mem, x1, y1, x2+1, y2+1);

            SelectObject( hDC_mem, hPenOld );
            DeleteObject( hPen );
            DeleteObject( hBrush );
         }

         for ( i = colors_num-1; i > 0; i-- )
         {
            section_len = stop_x[i] - stop_x[i-1];
            red_step = (double)( red[i-1] - red[i] ) / section_len;
            green_step = (double)( green[i-1] - green[i] ) / section_len;
            blue_step = (double)( blue[i-1] - blue[i] ) / section_len;
            for ( j = stop_x[i], k = 0; j >= stop_x[i-1]; j--, k++ )
            {
               cur_red = floor( red[i] + k * red_step + 0.5 );
               cur_green = floor( green[i] + k * green_step + 0.5 );
               cur_blue = floor( blue[i] + k * blue_step + 0.5 );
               hPen = CreatePen( PS_SOLID, 1, RGB( cur_red, cur_green, cur_blue ) );
               hPenOld = SelectObject( hDC_mem, hPen );
               hBrush = CreateSolidBrush( RGB( cur_red, cur_green, cur_blue ) );
               SelectObject( hDC_mem, hBrush );

               Ellipse( hDC_mem, x_center - j, y_center - j, x_center + j+1, y_center + j+1 );

               SelectObject( hDC_mem, hPenOld ); 
               DeleteObject( hPen );
               DeleteObject( hBrush );
            }
         }
      
      } // end radial gradients

   } // user passes two colors or more

   // We draw polygon that looks like rectangle with rounded corners.
   // WinAPI allows to fill this figure with brush.
   user_radiuses_num = ( pArrRadius ) ? hb_arrayLen( pArrRadius ) : 0;
   for ( i = 0; i < 4; i++ )
   {
      radius[i] = ( i < user_radiuses_num ) ? hb_arrayGetNI( pArrRadius, i+1 ) : 0;
      radius[i] = ( radius[i] >= 0 ) ? radius[i] : 0;
   }
   
   center[0].x = x1 + radius[0];
   center[0].y = y1 + radius[0];
   center[1].x = x2 - radius[1];
   center[1].y = y1 + radius[1];
   center[2].x = x2 - radius[2];
   center[2].y = y2 - radius[2];
   center[3].x = x1 + radius[3];
   center[3].y = y2 - radius[3];

   for ( i = 0; i < 4; i++ )
   {
      if ( radius[i] == 0 )
      {
         // This is not rounded corner.
         polygon[ polygon_len ].x = center[i].x;
         polygon[ polygon_len ].y = center[i].y;
         polygon_len++;
      }
      else
      {
         if ( i == 0 || radius[i] != radius[i-1] )
         {
            // The radius is greater than zero, so we draw a quarter circle.
            // The drawing uses the principle of Bresenham's circle algorithm
            // for finding in the group of pixels the nearest pixel to a circle.
            // At first we calculate the coordinates of the pixels 
            // in the quadrant from -Pi/2 to 0. This is a handy quadrant - 
            // when the angle increases, the values on bouth X-axis and Y-axis
            // are monotonically increase.
            // Then, the coordinates are converted for the corresponding quarter
            // and for the corresponding circle center.
            coords[0].x = 0;
            coords[0].y = -radius[i];
            coords[ SECTORS_NUM ].x = radius[i];
            coords[ SECTORS_NUM ].y = 0;

            angle = -M_PI_2;
            angle_step = M_PI_2 / SECTORS_NUM;
            for( j = 1; j < SECTORS_NUM; j++ )
            {
               angle += angle_step;
               coord_x = cos( angle ) * radius[i];
               coord_y = sin( angle ) * radius[i];

               candidates[0].x = floor( coord_x );
               candidates[0].y = floor( coord_y );
               candidates[1].x = ceil( coord_x );
               candidates[1].y = floor( coord_y );
               candidates[2].x = floor( coord_x );
               candidates[2].y = ceil( coord_y );
               candidates[3].x = ceil( coord_x );
               candidates[3].y = ceil( coord_y );
               min_delta = 1000000;
               for( k = 0; k < 4; k++ )
               {
                  delta = abs( pow( (long double)(candidates[k].x), 2 ) + pow( (long double)(candidates[k].y), 2 ) -
                     pow( (long double)(radius[i]), 2 ) );
                  if ( delta < min_delta )
                  {
                     nearest_coord = k;
                     min_delta = delta;
                  }
               }
               
               coords[j].x = candidates[ nearest_coord ].x;
               coords[j].y = candidates[ nearest_coord ].y;
            }    
         }
         
         cycle_start = ( i%2 == 0 ) ? SECTORS_NUM : 0;
         cycle_stop = ( i%2 == 0 ) ? -1 : SECTORS_NUM + 1;
         cycle_step = ( i%2 == 0 ) ? -1 : 1;
         for( j = cycle_start; j != cycle_stop; j += cycle_step )
         {
            x = convert[ i ][ 0 ] * coords[ j ].x + center[ i ].x;
            y = convert[ i ][ 1 ] * coords[ j ].y + center[ i ].y;
            if ( polygon_len == 0 || x != polygon[ polygon_len-1 ].x || y != polygon[ polygon_len-1 ].y )
            {
               polygon[ polygon_len ].x = x;
               polygon[ polygon_len ].y = y;
               polygon_len++;
            }
         }
      }
   }

   // We draw polygon and fill it with brush
   if( user_colors_num >= 2 )
   {
      hPen = CreatePen( PS_NULL, 1, RGB( 0, 0, 0 ) );
      hBrush = CreatePatternBrush( bmp );
   }
   else
   {
      color = hb_arrayGetNL( pArrColor, 1 );
      hPen = CreatePen( PS_SOLID, 1, color );
      hBrush = CreateSolidBrush( color );
   }
   
   hPenOld = SelectObject( hDC, hPen );
   SelectObject( hDC, hBrush );
   Polygon( hDC, polygon, polygon_len );
   
   if( user_colors_num >= 2 )
   {
      // In WinAPI rightmost column and bottommost row of pixels are ignored while filling polygon
      // with "PS_NULL" border, so we draw additional figures to complete our glory.
      Rectangle( hDC, x2, y1+radius[1], x2+2, y2-radius[2]+2 );
      Rectangle( hDC, x1+radius[3], y2, x2-radius[2]+2, y2+2 );

      if( bmp ) 
         DeleteObject( bmp );
      if( hDC_mem )
         DeleteDC( hDC_mem );
   }

   SelectObject( hDC, hPenOld );
   DeleteObject( hPen );
   DeleteObject( hBrush );

}

/* ============================== EOF of draw.c ================================ */

