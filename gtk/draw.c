/*
 * $Id: draw.c,v 1.1 2005-01-20 08:38:26 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level painting functions
 *
 * Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "gtk/gtk.h"

typedef struct HWGUI_HDC_STRU
{
  GdkDrawable * window;
  GdkGC * gc;
} HWGUI_HDC, * PHWGUI_HDC;

#define HWGUI_OBJECT_PEN    1
#define HWGUI_OBJECT_BRUSH  2
#define HWGUI_OBJECT_FONT   3

typedef struct HWGUI_HDC_OBJECT_STRU
{
   short int type;
} HWGUI_HDC_OBJECT;

typedef struct HWGUI_PEN_STRU
{
   short int type;
   gint width;
   GdkLineStyle style;
   GdkColor color;
} HWGUI_PEN, * PHWGUI_PEN;

typedef struct HWGUI_BRUSH_STRU
{
   short int type;
   GdkColor color;
} HWGUI_BRUSH, * PHWGUI_BRUSH;

// static HWGUI_PEN default_pen = { HWGUI_OBJECT_PEN,1,GDK_LINE_SOLID, };


HB_FUNC( INVALIDATERECT )
{
   GdkRectangle rc;

   if( hb_pcount() > 2 )
   {
      rc.x = hb_parni(3);
      rc.y = hb_parni(4);
      rc.width = hb_parni(5) - rc.x + 1;
      rc.height = hb_parni(6) - rc.y + 1;
   }
   gdk_window_invalidate_rect( (GdkWindow*)hb_parnl(1),
      ( hb_pcount() > 2 )? &rc:NULL, ( ISNUM(2) )? hb_parni(2):1 );
}

HB_FUNC( RECTANGLE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );

/*   
   GdkColor color1, color2;
   gdk_color_parse( "#FF0000",&color1 );
   gdk_colormap_alloc_color(gdk_colormap_get_system(),&color1,FALSE,TRUE);

   color2.red = 0;
   color2.green = 0;
   color2.blue = 65535;
   gdk_colormap_alloc_color(gdk_colormap_get_system(),&color2,FALSE,TRUE);
   gdk_gc_set_foreground( hDC->gc, &color2 );
   gdk_gc_set_foreground( hDC->gc, &color1 );      
*/   

   gdk_draw_rectangle( hDC->window, hDC->gc, 0, x1, y1, hb_parni(4)-x1+1, hb_parni(5)-y1+1 );

}

HB_FUNC( DRAWLINE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);   
   gdk_draw_line( hDC->window, hDC->gc, hb_parni(2), hb_parni(3), hb_parni(4), hb_parni(5) );
}

HB_FUNC( PIE )
{
/*
   int res = Pie(
    (HDC) hb_parnl(1),	// handle to device context 
    hb_parni(2),	// x-coord. of bounding rectangle's upper-left corner 
    hb_parni(3),	// y-coord. of bounding rectangle's upper-left corner  
    hb_parni(4),	// x-coord. of bounding rectangle's lower-right corner  
    hb_parni(5), 	// y-coord. bounding rectangle's f lower-right corner  
    hb_parni(6),	// x-coord. of first radial's endpoint 
    hb_parni(7),	// y-coord. of first radial's endpoint 
    hb_parni(8),	// x-coord. of second radial's endpoint 
    hb_parni(9) 	// y-coord. of second radial's endpoint 
   );
   if( !res )
     hb_retnl( (LONG) GetLastError() );
   else
     hb_retnl( 0 );
*/     
}

HB_FUNC( ELLIPSE )
{
/*
   int res =  Ellipse(
    (HDC) hb_parnl(1),	// handle to device context 
    hb_parni(2),	// x-coord. of bounding rectangle's upper-left corner 
    hb_parni(3),	// y-coord. of bounding rectangle's upper-left corner  
    hb_parni(4),	// x-coord. of bounding rectangle's lower-right corner  
    hb_parni(5) 	// y-coord. bounding rectangle's f lower-right corner  
   );
   if( !res )
     hb_retnl( (LONG) GetLastError() );
   else
     hb_retnl( 0 );
*/     
}

HB_FUNC( FILLRECT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   PHWGUI_BRUSH brush = (PHWGUI_BRUSH) hb_parnl(6);
   // GdkColor color;
   GdkGCValues values;

   gdk_gc_get_values( hDC->gc, &values );
   // gdk_color_parse( brush->color,&color );
   gdk_gc_set_foreground( hDC->gc, &(brush->color) );
   gdk_draw_rectangle( hDC->window, hDC->gc, 1, x1, y1, hb_parni(4)-x1+1, hb_parni(5)-y1+1 );
   gdk_gc_set_foreground( hDC->gc, &(values.foreground) );

}

HB_FUNC( ROUNDRECT )
{
/*
   hb_parl( RoundRect(
    (HDC) hb_parnl( 1 ),   // handle of device context 
    hb_parni( 2 ),         // x-coord. of bounding rectangle's upper-left corner 
    hb_parni( 3 ),         // y-coord. of bounding rectangle's upper-left corner 
    hb_parni( 4 ),         // x-coord. of bounding rectangle's lower-right corner 
    hb_parni( 5 ),         // y-coord. of bounding rectangle's lower-right corner 
    hb_parni( 6 ),         // width of ellipse used to draw rounded corners  
    hb_parni( 7 )          // height of ellipse used to draw rounded corners  
   ) );
*/   
}

HB_FUNC( REDRAWWINDOW )
{
   GdkWindow * hwnd = (GdkWindow*) hb_parnl(1);
   GdkRectangle rc;

   if( hb_pcount() > 2 )
   {
      rc.x = 0;
      rc.y = 0;
      rc.width = ((GtkWidget*)hwnd)->allocation.width;
      rc.height = ((GtkWidget*)hwnd)->allocation.height;
   }
   gdk_window_invalidate_rect( hwnd, &rc, TRUE );
}

HB_FUNC( DRAWBUTTON )
{
/*
   RECT rc;
   HDC hDC = (HDC) hb_parnl( 1 );
   UINT iType = hb_parni( 6 );

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   if( iType == 0 )
      FillRect( hDC, &rc, (HBRUSH) (COLOR_3DFACE+1) );
   else
   {
      FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DSHADOW:COLOR_3DHILIGHT )+1) );
      rc.left ++; rc.top ++;
      FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DHILIGHT:(iType & 4)? COLOR_3DDKSHADOW:COLOR_3DSHADOW )+1) );
      rc.right --; rc.bottom --;
      if( iType & 4 )
      {
         FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DSHADOW:COLOR_3DLIGHT )+1) );
         rc.left ++; rc.top ++;
         FillRect( hDC, &rc, (HBRUSH) ( ( (iType & 2)? COLOR_3DLIGHT:COLOR_3DSHADOW )+1) );
         rc.right --; rc.bottom --;
      }
      FillRect( hDC, &rc, (HBRUSH) (COLOR_3DFACE+1) );
   }
*/   
}

/*
 * DrawEdge( hDC,x1,y1,x2,y2,nFlag,nBorder )
 */
HB_FUNC( DRAWEDGE )
{
/*
   RECT rc;
   HDC hDC = (HDC) hb_parnl( 1 );
   UINT edge = (ISNIL(6))? EDGE_RAISED : (UINT) hb_parni(6);
   UINT grfFlags = (ISNIL(7))? BF_RECT : (UINT) hb_parni(7);

   rc.left = hb_parni( 2 );
   rc.top = hb_parni( 3 );
   rc.right = hb_parni( 4 );
   rc.bottom = hb_parni( 5 );

   hb_retl( DrawEdge( hDC, &rc, edge, grfFlags ) );
*/   
}

HB_FUNC( LOADICON )
{
/*
   if( ISNUM(1) )
      hb_retnl( (LONG) LoadIcon( NULL, (LPCTSTR) hb_parnl( 1 ) ) );
   else
      hb_retnl( (LONG) LoadIcon( GetModuleHandle( NULL ), (LPCTSTR) hb_parc( 1 ) ) );
*/      
}

HB_FUNC( LOADIMAGE )
{
/*
   hb_retnl( (LONG) 
          LoadImage( (HINSTANCE)hb_parnl(1),    // handle of the instance that contains the image
                  (LPCTSTR)hb_parc(2),          // name or identifier of image
                  (UINT) hb_parni(3),           // type of image
                  hb_parni(4),                  // desired width
                  hb_parni(5),                  // desired height
                  (UINT)hb_parni(6)             // load flags
   ) );
*/   
}

HB_FUNC( LOADBITMAP )
{
/*
   if( ISNUM(1) )
      hb_retnl( (LONG) LoadBitmap( NULL, (LPCTSTR) hb_parnl( 1 ) ) );
   else
      hb_retnl( (LONG) LoadBitmap( GetModuleHandle( NULL ), (LPCTSTR) hb_parc( 1 ) ) );
*/      
}

/*
 * Window2Bitmap( hWnd )
 */
HB_FUNC( WINDOW2BITMAP )
{
}

/*
 * DrawBitmap( hDC, hBitmap, style, x, y, width, height )
 */
HB_FUNC( DRAWBITMAP )
{
}

/*
 * DrawTransparentBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( DRAWTRANSPARENTBITMAP )
{
}

/*  SpreadBitmap( hDC, hWnd, hBitmap, style )
*/
HB_FUNC( SPREADBITMAP )
{
}

HB_FUNC( GETBITMAPSIZE )
{
/*
   BITMAP  bitmap;
   PHB_ITEM aMetr = _itemArrayNew( 2 );
   PHB_ITEM temp;

   GetObject( (HBITMAP) hb_parnl( 1 ), sizeof( BITMAP ), ( LPVOID ) &bitmap );

   temp = _itemPutNL( NULL, bitmap.bmWidth );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, bitmap.bmHeight );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
*/   
}

HB_FUNC( OPENBITMAP )
{
}

HB_FUNC( DRAWICON )
{
   // DrawIcon( (HDC)hb_parnl( 1 ), hb_parni( 3 ), hb_parni( 4 ), (HICON)hb_parnl( 2 ) );
}

HB_FUNC( GETSYSCOLOR )
{
   hb_retnl( 0 );  // (LONG) GetSysColor( hb_parni( 1 ) ) );
}

#define  PS_SOLID   0

HB_FUNC( CREATEPEN )
{
   PHWGUI_PEN hpen = (PHWGUI_PEN) hb_xgrab( sizeof(HWGUI_PEN) );
   ULONG ncolor = (ULONG) hb_parnl(3);
   char color[10];
   // GdkColor color;

   hpen->type = HWGUI_OBJECT_PEN;
   hpen->style = ( hb_parni(1) == PS_SOLID )? GDK_LINE_SOLID : GDK_LINE_ON_OFF_DASH;  
   hpen->width = hb_parni(2);
   sprintf( color,"#%0*lX",6,ncolor );  
   gdk_color_parse( color,&(hpen->color) );
   gdk_colormap_alloc_color( gdk_colormap_get_system(),&(hpen->color),FALSE,TRUE );  
   
   hb_retnl( (LONG) hpen );
}

HB_FUNC( CREATESOLIDBRUSH )
{
   PHWGUI_BRUSH hbrush = (PHWGUI_BRUSH) hb_xgrab( sizeof(HWGUI_BRUSH) );
   ULONG ncolor = (ULONG) hb_parnl(1);
   char color[10];
   // GdkColor color;

   hbrush->type = HWGUI_OBJECT_BRUSH;
   sprintf( color,"#%0*lX",6,ncolor );

   gdk_color_parse( color,&(hbrush->color) );
   gdk_colormap_alloc_color( gdk_colormap_get_system(),&(hbrush->color),FALSE,TRUE );
   
   hb_retnl( (LONG) hbrush );

}

HB_FUNC( SELECTOBJECT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   HWGUI_HDC_OBJECT * obj = (HWGUI_HDC_OBJECT*) hb_parnl(2);
   GdkGCValues values;
   
   if( obj->type == HWGUI_OBJECT_PEN )
   {
      // GdkColor color;
      // gdk_color_parse( ((PHWGUI_PEN)obj)->color,&color );
      // writelog(((PHWGUI_PEN)obj)->color);
      gdk_gc_set_foreground( hDC->gc, &(((PHWGUI_PEN)obj)->color) );
      gdk_gc_get_values( hDC->gc, &values );
      gdk_gc_set_line_attributes( hDC->gc, ((PHWGUI_PEN)obj)->width, 
          ((PHWGUI_PEN)obj)->style, values.cap_style, values.join_style );
   }
   else if( obj->type == HWGUI_OBJECT_BRUSH )
   {
   }
   else if( obj->type == HWGUI_OBJECT_FONT )
   {
   }
}

HB_FUNC( DELETEOBJECT )
{
   HWGUI_HDC_OBJECT * obj = (HWGUI_HDC_OBJECT*) hb_parnl(1);
   
   if( obj->type == HWGUI_OBJECT_PEN )
   {
      hb_xfree( obj );
   }
   else if( obj->type == HWGUI_OBJECT_BRUSH )
   {
      hb_xfree( obj );
   }
   else if( obj->type == HWGUI_OBJECT_FONT )
   {
   }

}

HB_FUNC( GETDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );
   GtkWidget * widget = (GtkWidget*) hb_parnl(1);
   
   hDC->window = widget->window;
   hDC->gc = gdk_gc_new( widget->window );

   hb_retnl( (LONG) hDC );   
}

HB_FUNC( RELEASEDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(2);
   
   g_object_unref( (GObject*) hDC->gc );
   hb_xfree( hDC );
}

HB_FUNC( GETDRAWITEMINFO )
{
/*
   DRAWITEMSTRUCT * lpdis = (DRAWITEMSTRUCT*)hb_parnl(1);
   PHB_ITEM aMetr = _itemArrayNew( 7 );
   PHB_ITEM temp;

   temp = _itemPutNL( NULL, lpdis->itemID );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->itemAction );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, (LONG)lpdis->hDC );
   _itemArrayPut( aMetr, 3, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.left );
   _itemArrayPut( aMetr, 4, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.top );
   _itemArrayPut( aMetr, 5, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.right );
   _itemArrayPut( aMetr, 6, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, lpdis->rcItem.bottom );
   _itemArrayPut( aMetr, 7, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
*/   
}

/*
 * DrawGrayBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( DRAWGRAYBITMAP )
{
}

