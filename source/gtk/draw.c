/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level painting functions
 *
 * Copyright 2013 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"

#include <cairo.h>
#include "gtk/gtk.h"

#include "hwgtk.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#include <math.h>

/* Avoid warnings from GCC */
#include "warnings.h"

extern GtkWidget * hMainWindow;
extern GtkFixed *getFixedBox( GObject * handle );

void hwg_parse_color( HB_ULONG ncolor, GdkColor * pColor )
{
   char color[10]={0};

   sprintf( color,"#%0*lX",6,ncolor );
   color[8] = color[1]; color[9] = color[2];
   color[1] = color[5]; color[2] = color[6];
   color[5] = color[8]; color[6] = color[9];
   color[7] = '\0';
   gdk_color_parse( color,pColor );
}

HB_ULONG hwg_gdk_color( GdkColor * pColor )
{
   return (HB_ULONG) ( (pColor->red>>8) + (pColor->green&0xff00) + ((pColor->blue&0xff00)<<8) );
}

void hwg_setcolor( cairo_t * cr, long int nColor )
{
   short int r, g, b;

   nColor %= ( 65536 * 256 );
   r = nColor % 256;
   g = ( ( nColor - r ) % 65536 ) / 256;
   b = ( nColor - g - r ) / 65536;

   cairo_set_source_rgb( cr, ( ( double ) r ) / 255.,
          ( ( double ) g ) / 255., ( ( double ) b ) / 255. );

}

GdkPixbuf * alpha2pixbuf( GdkPixbuf * hPixIn, long int nColor )
{
   short int r, g, b;

   r = nColor % 256;
   g = ( ( nColor - r ) % 65536 ) / 256;
   b = ( nColor - g - r ) / 65536;
   return gdk_pixbuf_add_alpha( hPixIn, 1,
            (guchar) r, (guchar) g, (guchar) b );
}

/*
 * hwg_Alpha2Pixbuf( hBitmap, nColor )
 */
HB_FUNC( HWG_ALPHA2PIXBUF )
{
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(1);
   GdkPixbuf * handle;
   long int nColor = hb_parnl(2);

   if( obj && obj->handle && obj->trcolor != nColor )
   {
      handle = alpha2pixbuf( obj->handle, nColor );
      g_object_unref( (GObject*) obj->handle );
      obj->handle = handle;
      obj->trcolor = nColor;
   }
   
}

HB_FUNC( HWG_INVALIDATERECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   int x1, y1, x2, y2;

   if( hb_pcount() > 2 )
   {
      x1 = hb_parni(3);
      y1 = hb_parni(4);
      x2 = hb_parni(5);
      y2 = hb_parni(6);
   }
   else
   {
      GtkAllocation alloc;
      gtk_widget_get_allocation( widget, &alloc );

      x1 = y1 = 0;
      x2 = alloc.width;
      y2 = alloc.height;      
   }
   gtk_widget_queue_draw_area( widget, x1, y1,
        x2 - x1 + 1, y2 - y1 + 1 );
   
}

HB_FUNC( HWG_RECTANGLE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );

   cairo_rectangle( hDC->cr, (gdouble)x1, (gdouble)y1, 
        (gdouble)(hb_parni(4)-x1+1), (gdouble)(hb_parni(5)-y1+1) );
   cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_MOVETO )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   cairo_move_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );

}

HB_FUNC( HWG_LINETO )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

   cairo_line_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );
   cairo_stroke( hDC->cr );

}

HB_FUNC( HWG_DRAWLINE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

   cairo_move_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );
   cairo_line_to( hDC->cr, (gdouble)hb_parni(4), (gdouble)hb_parni(5) );
   cairo_stroke( hDC->cr );

}

HB_FUNC( HWG_PIE )
{
}

HB_FUNC( HWG_ELLIPSE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 ), x2 = hb_parni( 4 ), y2 = hb_parni( 5 );

   cairo_arc( hDC->cr, (double)x1+(x2-x1)/2, (double)y1+(y2-y1)/2, (double) (x2-x1)/2, 0, 6.28 );
   cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_DRAWGRID )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int x1 = hb_parni(2), y1 = hb_parni(3), x2 = hb_parni(4), y2 = hb_parni(5);
   int n = ( HB_ISNIL( 6 ) ) ? 4 : hb_parni( 6 );
   unsigned int uiColor = ( HB_ISNIL( 7 ) ) ? 0 : ( unsigned int ) hb_parnl( 7 );
   int i, j;

   hwg_setcolor( hDC->cr, uiColor );
   for( i = x1+n; i < x2; i+=n )
      for( j = y1+n; j < y2; j+=n )
         cairo_rectangle( hDC->cr, (gdouble)i, (gdouble)j, 1, 1 );
   cairo_fill( hDC->cr );
}

HB_FUNC( HWG_FILLRECT )
{
   int x1 = hb_parni( 2 ), y1 = hb_parni( 3 );
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_BRUSH brush = (PHWGUI_BRUSH) HB_PARHANDLE(6);

   hwg_setcolor( hDC->cr, brush->color );
   cairo_rectangle( hDC->cr, (gdouble)x1, (gdouble)y1, 
         (gdouble)(hb_parni(4)-x1+1), (gdouble)(hb_parni(5)-y1+1) );
   cairo_fill( hDC->cr );
}

/*
 * hwg_Arc( hDC, xc, yc, radius, iAngleStart, iAngleEnd )
 * Draws an arc with a center in xc, yc, with a radius from an angle
 * iAngleStart to iAngleEnd. Angles are passed in degrees.
 * 0 corresponds to the standard X axis, drawing direction is clockwise.
 */
HB_FUNC( HWG_ARC )
{

   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 );
   gdouble radius = hb_parnd( 4 );
   int iAngle1 = hb_parni(5), iAngle2 = hb_parni(6);

   cairo_new_sub_path( hDC->cr );
   cairo_arc( hDC->cr, x1, y1, radius, iAngle1 * M_PI / 180., iAngle2 * M_PI / 180. );
   //cairo_close_path(hDC->cr);
   cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_ROUNDRECT )
{

   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 ), x2 = hb_parnd( 4 ), y2 = hb_parnd( 5 );
   gdouble radius = hb_parnd( 6 );

   cairo_arc( hDC->cr, x1+radius, y1+radius, radius, M_PI, 3*M_PI/2 );
   cairo_arc( hDC->cr, x2-radius, y1+radius, radius, 3*M_PI/2, 0 );
   cairo_arc( hDC->cr, x2-radius, y2-radius, radius, 0, M_PI/2 );
   cairo_arc( hDC->cr, x1+radius, y2-radius, radius, M_PI/2, M_PI );
   cairo_close_path(hDC->cr);
   cairo_stroke( hDC->cr );
}

HB_FUNC( HWG_REDRAWWINDOW )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   GtkAllocation alloc;

   gtk_widget_get_allocation( widget, &alloc );
   gtk_widget_queue_draw_area( widget, 0, 0,
        alloc.width, alloc.height );
}

HB_FUNC( HWG_DRAWBUTTON )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int left = hb_parni( 2 );
   int top = hb_parni( 3 );
   int right = hb_parni( 4 );
   int bottom = hb_parni( 5 );
   unsigned int iType = hb_parni( 6 );
   GtkStyle * style = gtk_widget_get_style( hDC->widget );

   if( iType == 0 )
   {
      hwg_setcolor( hDC->cr, hwg_gdk_color( style->bg ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );
   }
   else
   {
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );

      left ++; top ++;
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : ( (iType & 4)? style->dark : style->mid ) ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );

      right --; bottom --;
      right --; bottom --;
      if( iType & 4 )
      {
         hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
         cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
              (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
         cairo_fill( hDC->cr );

         left ++; top ++;
         hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : style->mid ) );
         cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
              (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
         cairo_fill( hDC->cr );

         right --; bottom --;
      }
      hwg_setcolor( hDC->cr, hwg_gdk_color( style->bg ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_fill( hDC->cr );
   }
}

void hwg_gtk_drawedge( PHWGUI_HDC hDC, int left, int top, int right, int bottom, unsigned int iType )
{

   GtkStyle * style = gtk_widget_get_style( hDC->widget );

   hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
   cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
        (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
   cairo_stroke( hDC->cr );

   left ++; top ++;
   hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : ( (iType & 4)? style->dark : style->mid ) ) );
   cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
        (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
   cairo_stroke( hDC->cr );

   right --; bottom --;
   right --; bottom --;
   if( iType & 4 )
   {
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->mid : style->light ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_stroke( hDC->cr );

      left ++; top ++;
      hwg_setcolor( hDC->cr, hwg_gdk_color( (iType & 2)? style->light : style->mid ) );
      cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
           (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
      cairo_stroke( hDC->cr );

      right --; bottom --;
   }
   hwg_setcolor( hDC->cr, hwg_gdk_color( style->bg ) );
   cairo_rectangle( hDC->cr, (gdouble)left, (gdouble)top, 
        (gdouble)(right-left+1), (gdouble)(bottom-top+1) );
   cairo_stroke( hDC->cr );

}
/*
 * DrawEdge( hDC,x1,y1,x2,y2,nFlag )
 */
HB_FUNC( HWG_GTK_DRAWEDGE )
{

   hwg_gtk_drawedge( (PHWGUI_HDC) HB_PARHANDLE(1), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ) );
}

HB_FUNC( HWG_LOADICON )
{
}

HB_FUNC( HWG_LOADIMAGE )
{
}

HB_FUNC( HWG_LOADBITMAP )
{
}

/*
 * Window2Bitmap( hWnd )
 */
HB_FUNC( HWG_WINDOW2BITMAP )
{
   GtkWidget *hCtrl = (GtkWidget*) HB_PARHANDLE(1);
   GdkPixbuf *pixbuf = gdk_pixbuf_new( GDK_COLORSPACE_RGB, 0, 8, hb_parni(4), hb_parni(5) );

#if GTK_MAJOR_VERSION -0 < 3
   pixbuf = gdk_pixbuf_get_from_drawable( pixbuf, gtk_widget_get_window(hCtrl),
      NULL, hb_parni(2), hb_parni(3), 0, 0, hb_parni(4), hb_parni(5) );
#else
   pixbuf = gdk_pixbuf_get_from_window( gtk_widget_get_window(hCtrl),
      hb_parni(2), hb_parni(3), hb_parni(4), hb_parni(5) );
#endif

   if( pixbuf )
   {
      PHWGUI_PIXBUF hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = pixbuf;
      hpix->trcolor = -1;
      HB_RETHANDLE( hpix );
   }
}

/*
 * DrawBitmap( hDC, hBitmap, style, x, y, width, height )
 */
HB_FUNC( HWG_DRAWBITMAP )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   GdkPixbuf * pixbuf;
   gint x =  hb_parni(4);
   gint y =  hb_parni(5);
   gint srcWidth = gdk_pixbuf_get_width( obj->handle );
   gint srcHeight = gdk_pixbuf_get_height( obj->handle );
   gint destWidth = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : srcWidth;
   gint destHeight = ( hb_pcount(  ) >= 6 && !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : srcHeight;

   if( srcWidth == destWidth && srcHeight == destHeight ) {
      gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
      cairo_paint( hDC->cr );
   }
   else {
      pixbuf = gdk_pixbuf_scale_simple( obj->handle, destWidth, destHeight, GDK_INTERP_HYPER );
      gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, x, y );
      cairo_paint( hDC->cr );
      g_object_unref( (GObject*) pixbuf );
   }

}

/*
 * DrawTransparentBitmap( hDC, hBitmap, x, y, trcolor, width, height )
 */
HB_FUNC( HWG_DRAWTRANSPARENTBITMAP )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   GdkPixbuf * pixbuf;
   gint x =  hb_parni(3);
   gint y =  hb_parni(4);
   long int nColor = hb_parnl(5);
   gint srcWidth = gdk_pixbuf_get_width( obj->handle );
   gint srcHeight = gdk_pixbuf_get_height( obj->handle );
   gint destWidth = ( hb_pcount(  ) >= 5 && !HB_ISNIL( 6 ) ) ? hb_parni( 6 ) : srcWidth;
   gint destHeight = ( hb_pcount(  ) >= 6 && !HB_ISNIL( 7 ) ) ? hb_parni( 7 ) : srcHeight;

   if( obj->trcolor != nColor )
   {
      pixbuf = alpha2pixbuf( obj->handle, nColor );
      g_object_unref( (GObject*) obj->handle );
      obj->handle = pixbuf;
      obj->trcolor = nColor;
   }

   if( srcWidth == destWidth && srcHeight == destHeight ) {
      gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
      cairo_paint( hDC->cr );
   }
   else {
      pixbuf = gdk_pixbuf_scale_simple( obj->handle, destWidth, destHeight, GDK_INTERP_HYPER );
      gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, x, y );
      cairo_paint( hDC->cr );
      g_object_unref( (GObject*) pixbuf );
   }
}

HB_FUNC( HWG_SPREADBITMAP )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   GtkWidget * widget = hDC->widget;
   GdkPixbuf * pixbuf;
   int nWidth, nHeight, x1, x2, y1, y2, nw, nh;
   int nLeft = (HB_ISNUM(3))? hb_parni(3) : 0;
   int nTop = (HB_ISNUM(4))? hb_parni(4) : 0;
   int nRight = (HB_ISNUM(5))? hb_parni(5) : 0;
   int nBottom = (HB_ISNUM(6))? hb_parni(6) : 0;

   if( nLeft == 0 && nRight == 0 )
   {
      GtkAllocation alloc;
      gtk_widget_get_allocation( widget, &alloc );

      nLeft = nTop = 0;
      nRight = alloc.width;
      nBottom = alloc.height;
   }

   x1 = y1 = 0;
   x2 = nRight - nLeft + 1;
   y2 = nBottom - nTop + 1;

   pixbuf = gdk_pixbuf_new( GDK_COLORSPACE_RGB, 0,
      gdk_pixbuf_get_bits_per_sample( obj->handle ), x2-x1+1, y2-y1+1 );

   nWidth = gdk_pixbuf_get_width( obj->handle );
   nHeight = gdk_pixbuf_get_height( obj->handle );
   while( y1 < y2 )
   {
      nh = (y2-y1 >= nHeight)? nHeight : y2-y1;
      while( x1 < x2 )
      {
         nw = (x2-x1 >= nWidth)? nWidth : x2-x1;
         gdk_pixbuf_copy_area( (const GdkPixbuf *)obj->handle, 0, 0, nw, nh, pixbuf, x1, y1);
         x1 += nWidth;
      }
      x1 = 0;
      y1 += nHeight;
   }

   gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, nLeft, nTop );
   cairo_paint( hDC->cr );
   g_object_unref( (GObject*) pixbuf );

}

HB_FUNC( HWG_GETBITMAPSIZE )
{
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(1);
   PHB_ITEM aMetr = _itemArrayNew( 2 );
   PHB_ITEM temp;

   temp = _itemPutNL( NULL, gdk_pixbuf_get_width ( obj->handle) );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, gdk_pixbuf_get_height ( obj->handle) );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
   
}


/*
  hwg_Openbitmap( cBitmap )
  cBitmap : File name of bitmap
  returns handle to pixbuffer
*/
HB_FUNC( HWG_OPENBITMAP )
{
   PHWGUI_PIXBUF hpix;
   GdkPixbuf * handle = gdk_pixbuf_new_from_file( hb_parc(1), NULL );
   
   if( handle )
   {
      hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = handle;
      hpix->trcolor = -1;
      HB_RETHANDLE( hpix );
   }
}

/* hwg_SaveBitMap( cfilename , hpixbuf , ctype )
 * ctype default: "bmp"
 */
HB_FUNC( HWG_SAVEBITMAP )
{
   PHWGUI_PIXBUF hpix = HB_PARHANDLE(2);
   const char * szType = (HB_ISCHAR(3))? hb_parc(3) : "bmp";
 
   hb_retl( gdk_pixbuf_save( hpix->handle, hb_parc(1), szType, NULL, NULL ) );
} 

/* hwg_Openimage( name , ltype )
  ltype : .F. : from image file
          .T. : from GDK pixbuffer
  returns handle to pixbuffer  
  */
HB_FUNC( HWG_OPENIMAGE )
{
   PHWGUI_PIXBUF hpix;
   short int iString = ( HB_ISNIL( 2 ) ) ? 0 : hb_parl( 2 );
   GdkPixbuf * handle;

   if( iString )
   {
   /* Load image from GDK pixbuffer */ 
      guint8 *buf = (guint8 *) hb_parc(1);
      GdkPixbufLoader *loader = gdk_pixbuf_loader_new();

      gdk_pixbuf_loader_write( loader, buf, hb_parclen(1), NULL );
      handle = gdk_pixbuf_loader_get_pixbuf( loader );
   }
   else
   /* Load image from file */
      handle = gdk_pixbuf_new_from_file( hb_parc(1), NULL );
   
   if( handle )
   {
      hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = handle;
      hpix->trcolor = -1;
      HB_RETHANDLE( hpix );
   }
}

HB_FUNC( HWG_DRAWICON )
{
}

HB_FUNC( HWG_GETSYSCOLOR )
{
   if( hMainWindow )
   {
      GdkColor color = gtk_widget_get_style(hMainWindow)->bg[GTK_STATE_NORMAL];
      hb_retnl( hwg_gdk_color( &color ) );
   }
   else
      hb_retnl( 0 );
}

#define  PS_SOLID   0

HB_FUNC( HWG_CREATEPEN )
{
   PHWGUI_PEN hpen = (PHWGUI_PEN) hb_xgrab( sizeof(HWGUI_PEN) );

   hpen->type = HWGUI_OBJECT_PEN;
   hpen->style = hb_parni(1);
   hpen->width = hb_parnd(2);
   hpen->color = hb_parnl(3);

   HB_RETHANDLE( hpen );
}

HB_FUNC( HWG_CREATESOLIDBRUSH )
{
   PHWGUI_BRUSH hbrush = (PHWGUI_BRUSH) hb_xgrab( sizeof(HWGUI_BRUSH) );

   hbrush->type = HWGUI_OBJECT_BRUSH;
   hbrush->color = hb_parnl(1);
   
   HB_RETHANDLE( hbrush );
}

HB_FUNC( HWG_SELECTOBJECT )
{
   HWGUI_HDC_OBJECT * obj = (HWGUI_HDC_OBJECT*) HB_PARHANDLE(2);

   if( obj )
   {
      PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

      if( obj->type == HWGUI_OBJECT_PEN )
      {
         hwg_setcolor( hDC->cr, ((PHWGUI_PEN)obj)->color );
         cairo_set_line_width( hDC->cr, ((PHWGUI_PEN)obj)->width );
         if( ((PHWGUI_PEN)obj)->style != PS_SOLID )
         {
            static const double dashed[] = {2.0, 2.0};
            cairo_set_dash( hDC->cr, dashed, 2, 0 );
         }
      }
      else if( obj->type == HWGUI_OBJECT_BRUSH )
      {
         hwg_setcolor( hDC->cr, ((PHWGUI_BRUSH)obj)->color );
      }
      else if( obj->type == HWGUI_OBJECT_FONT )
      {
         hDC->hFont = ((PHWGUI_FONT)obj)->hFont;
         pango_layout_set_font_description( hDC->layout, hDC->hFont );
         if( ((PHWGUI_FONT)obj)->attrs )
         {
            pango_layout_set_attributes( hDC->layout, ((PHWGUI_FONT)obj)->attrs );
         }
      }
   }
   HB_RETHANDLE( NULL );
}

HB_FUNC( HWG_DELETEOBJECT )
{
   HWGUI_HDC_OBJECT * obj = (HWGUI_HDC_OBJECT*) HB_PARHANDLE(1);

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
      pango_font_description_free( ( (PHWGUI_FONT)obj )->hFont );
      pango_attr_list_unref( ( (PHWGUI_FONT)obj )->attrs );
      hb_xfree( obj );
   }
   else if( obj->type == HWGUI_OBJECT_PIXBUF )
   {
      g_object_unref( (GObject*) ( (PHWGUI_PIXBUF)obj )->handle );
      hb_xfree( obj );
   }

}

HB_FUNC( HWG_DEFINEPAINTSTRU )
{
   PHWGUI_PPS pps = (PHWGUI_PPS) hb_xgrab( sizeof(HWGUI_PPS) );
   
   pps->hDC = NULL;
   HB_RETHANDLE( pps );
}

HB_FUNC( HWG_BEGINPAINT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHWGUI_PPS pps = (PHWGUI_PPS) HB_PARHANDLE(2);
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );   
   
   memset( hDC, 0, sizeof(HWGUI_HDC) );
   hDC->widget = widget;

   hDC->window = gtk_widget_get_window( widget );
   hDC->cr = gdk_cairo_create( hDC->window );

   hDC->layout = pango_cairo_create_layout( hDC->cr );
   hDC->fcolor = hDC->bcolor = -1;
   
   pps->hDC = hDC;

   HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_ENDPAINT )
{
   PHWGUI_PPS pps = (PHWGUI_PPS) HB_PARHANDLE(2);
   PHWGUI_HDC hDC = pps->hDC;

   if( hDC->layout )
      g_object_unref( (GObject*) hDC->layout );
   hb_xfree( hDC );
   hb_xfree( pps );
}

HB_FUNC( HWG_GETDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);

   memset( hDC, 0, sizeof(HWGUI_HDC) );
   hDC->widget = widget;

   hDC->window = gtk_widget_get_window( widget );
   hDC->cr = gdk_cairo_create( hDC->window );

   hDC->layout = pango_cairo_create_layout( hDC->cr );
   hDC->fcolor = hDC->bcolor = -1;

   HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_RELEASEDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(2);

   if( hDC->layout )
      g_object_unref( (GObject*) hDC->layout );

   if( hDC->surface )
      cairo_surface_destroy( hDC->surface );
   cairo_destroy( hDC->cr );
   hb_xfree( hDC );
}

HB_FUNC( HWG_CREATECOMPATIBLEDC )
{
   PHWGUI_HDC hDCdest = (PHWGUI_HDC) hb_xgrab( sizeof(HWGUI_HDC) );
   PHWGUI_HDC hDCsource = (PHWGUI_HDC) HB_PARHANDLE(1);

   memset( hDCdest, 0, sizeof(HWGUI_HDC) );
   hDCdest->widget = hDCsource->widget;
   hDCdest->window = hDCsource->window;

   hDCdest->surface = cairo_surface_create_similar(cairo_get_target( hDCsource->cr ),
         CAIRO_CONTENT_COLOR_ALPHA, hb_parni(2), hb_parni(3) );
   hDCdest->cr = cairo_create( hDCdest->surface );

   hDCdest->layout = pango_cairo_create_layout( hDCdest->cr );
   hDCdest->fcolor = hDCdest->bcolor = -1;

   HB_RETHANDLE( hDCdest );
}

HB_FUNC( HWG_BITBLT )
{
   PHWGUI_HDC hDCdest = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   PHWGUI_HDC hDCsource = ( PHWGUI_HDC ) HB_PARHANDLE( 6 );

   cairo_set_source_surface( hDCdest->cr, hDCsource->surface, hb_parni( 2 ), hb_parni( 3 ) );
   cairo_paint( hDCdest->cr );
}

HB_FUNC( HWG_CAIRO_TRANSLATE )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   cairo_translate( hDC->cr, hb_parni(2), hb_parni(3) );
}

HB_FUNC( HWG_GETDRAWITEMINFO )
{
}

/*
 * DrawGrayBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( HWG_DRAWGRAYBITMAP )
{
/*
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   gint x =  hb_parni(3);
   gint y =  hb_parni(4);

   gdk_cairo_set_source_pixbuf( hDC->cr, obj->handle, x, y );
   cairo_paint( hDC->cr );
   cairo_set_source_rgb( hDC->cr, 1, 1, 1 );
   cairo_set_operator( hDC->cr, CAIRO_OPERATOR_HSL_COLOR );
   cairo_paint( hDC->cr );
*/
}

HB_FUNC( HWG_GETCLIENTAREA )
{
   PHWGUI_PPS pps = ( PHWGUI_PPS ) HB_PARHANDLE( 1 );
   GtkWidget * widget = pps->hDC->widget;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );    
   GtkAllocation alloc;

   if( getFixedBox( (GObject *) widget ) )
      widget = (GtkWidget*) getFixedBox( (GObject *) widget );

   gtk_widget_get_allocation( widget, &alloc );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), alloc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), alloc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETCLIENTRECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   GtkAllocation alloc;

   if( getFixedBox( (GObject *) widget ) )
      widget = (GtkWidget*) getFixedBox( (GObject *) widget );

   gtk_widget_get_allocation( widget, &alloc );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), alloc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), alloc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETWINDOWRECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   GtkAllocation alloc;
   gtk_widget_get_allocation( widget, &alloc );

   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), alloc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), alloc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

void hwg_prepare_cairo_colors( long int nColor, gdouble *r, gdouble *g, gdouble *b )
{
   short int int_r, int_g, int_b;
  
   nColor %= ( 65536 * 256 );
   int_r = nColor % 256;
   int_g = ( ( nColor - int_r ) % 65536 ) / 256;
   int_b = ( nColor - int_r - int_g ) / 65536;

   *r = (gdouble)int_r / 255.;
   *g = (gdouble)int_g / 255.;
   *b = (gdouble)int_b / 255.;
}

/*
 * hwg_drawGradient( hDC, x1, y1, x2, y2, int type, array colors, array stops, array radiuses )
 */
HB_FUNC( HWG_DRAWGRADIENT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = hb_parnd( 2 ), y1 = hb_parnd( 3 ), x2 = hb_parnd( 4 ), y2 = hb_parnd( 5 );
   gint type = ( HB_ISNUM(6) ) ? hb_parni( 6 ) : 1;
   PHB_ITEM pArrColor = hb_param( 7, HB_IT_ARRAY );
   long int color;
   PHB_ITEM pArrStop = hb_param( 8, HB_IT_ARRAY );
   gdouble stop;
   gint user_colors_num, colors_num, user_stops_num, i;
   cairo_pattern_t *pat = NULL;
   gdouble x_center, y_center, gr_radius;
   gdouble r, g, b;
   PHB_ITEM pArrRadius = hb_param( 9, HB_IT_ARRAY );
   gint radius[4], max_r;
   gint user_radiuses_num;

   if( !pArrColor || ( user_colors_num = hb_arrayLen( pArrColor ) ) == 0 )
      return;

   if( user_colors_num == 1 )
      hwg_setcolor( hDC->cr, hb_arrayGetNL( pArrColor, 1 ) );
   else
   {
      // type of gradient
      type = ( type >= 1 && type <= 9 ) ? type : 1;
      switch( type ) 
      {
         case 1:
            // vertical and down
            pat = cairo_pattern_create_linear( x1, y1, x1, y2 );
            break;
         case 2:
            // vertical and up
            pat = cairo_pattern_create_linear( x1, y2, x1, y1 );
            break;
         case 3:
            // horizontal and to the right
            pat = cairo_pattern_create_linear( x1, y1, x2, y1 );
            break;
         case 4:
            // horizontal and to the left
            pat = cairo_pattern_create_linear( x2, y1, x1, y1 );
            break;
         case 5:
            // diagonal right-up
            pat = cairo_pattern_create_linear( x1, y2, x2, y1 );
            break;
         case 6:
            // diagonal left-down
            pat = cairo_pattern_create_linear( x2, y1, x1, y2 );
            break;
         case 7:
            // diagonal right-down
            pat = cairo_pattern_create_linear( x1, y1, x2, y2 );
            break;
         case 8:
            // diagonal left-up
            pat = cairo_pattern_create_linear( x2, y2, x1, y1 );
            break;
         case 9:
            // radial gradient
            x_center = (x2 - x1) / 2 + x1;
            y_center = (y2 - y1) / 2 + y1;
            gr_radius = sqrt( pow(x2-x1,2) + pow(y2-y1,2) ) / 2;
            pat = cairo_pattern_create_radial(x_center, y_center, 0, x_center, y_center, gr_radius);
            break;
      }

      colors_num = user_colors_num;
      user_stops_num = ( pArrStop ) ? hb_arrayLen( pArrStop ) : 0;

      for ( i = 0; i < colors_num; i++ )
      {
         color = ( i < user_colors_num ) ? hb_arrayGetNL( pArrColor, i+1 ) : 0xFFFFFF * i;
         hwg_prepare_cairo_colors( color, &r, &g, &b );
         stop = ( i < user_stops_num ) ? hb_arrayGetND( pArrStop, i+1 ) : 1. / (gdouble)(colors_num-1) * (gdouble)i;
         cairo_pattern_add_color_stop_rgb( pat, stop, r, g, b );
      }
   }

   if( pArrRadius ) {
      user_radiuses_num =  hb_arrayLen( pArrRadius );
      max_r = ( x2-x1+1 > y2-y1+1 ) ? y2-y1+1 : x2-x1+1;
      max_r /= 2;

      for ( i = 0; i < 4; i++ )
      {
         radius[i] = ( i < user_radiuses_num ) ? hb_arrayGetNI( pArrRadius, i+1 ) : 0;
         radius[i] = ( radius[i] >= 0 ) ? radius[i] : 0;
         radius[i] = ( radius[i] <= max_r ) ? radius[i] : max_r;
      }

      cairo_arc( hDC->cr, x1+radius[0], y1+radius[0], radius[0], M_PI, 3*M_PI/2 );
      cairo_arc( hDC->cr, x2-radius[1], y1+radius[1], radius[1], 3*M_PI/2, 0 );
      cairo_arc( hDC->cr, x2-radius[2], y2-radius[2], radius[2], 0, M_PI/2 );
      cairo_arc( hDC->cr, x1+radius[3], y2-radius[3], radius[3], M_PI/2, M_PI );
      cairo_close_path(hDC->cr);
   }
   else
      cairo_rectangle( hDC->cr, x1, y1, x2-x1+1, y2-y1+1 );

   if( user_colors_num > 1 )
      cairo_set_source( hDC->cr, pat );
   cairo_fill( hDC->cr );

   if( user_colors_num > 1 )
      cairo_pattern_destroy( pat );
}

HB_FUNC( HWG__DRAWCOMBO )
{
#if GTK_MAJOR_VERSION -0 < 3
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = (gdouble)hb_parni( 2 ), y1 = (gdouble)hb_parni( 3 ),
           x2 = (gdouble)hb_parni( 4 ), y2 = (gdouble)hb_parni( 5 ),
           nWidth = x2-x1+1, nHeight = y2-y1+1;

   hwg_setcolor( hDC->cr, 0xffffff );
   cairo_rectangle( hDC->cr, x1, y1, nWidth, nHeight );
   cairo_fill( hDC->cr );

   hwg_setcolor( hDC->cr, 0 );
   cairo_set_line_width( hDC->cr, 0.5 );

   cairo_rectangle( hDC->cr, x1, y1, nWidth, nHeight );

   cairo_move_to( hDC->cr, x1+6, y1+nHeight/2-3 );
   cairo_line_to( hDC->cr, x1+nWidth/2, y1+nHeight/2+3 );
   cairo_line_to( hDC->cr, x2-6, y1+nHeight/2-3 );

   cairo_stroke( hDC->cr );
#endif
}

HB_FUNC( HWG__DRAWCHECKBTN )
{
#if GTK_MAJOR_VERSION -0 < 3
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = (gdouble)hb_parni( 2 ), y1 = (gdouble)hb_parni( 3 ),
           y2 = (gdouble)hb_parni( 5 ),
           nHeight = y2-y1-6;
   int iSet = hb_parl(6);
   const char *cTitle = ( hb_pcount(  ) > 6 ) ? hb_parc( 7 ) : NULL;
   gchar *gcTitle;

   x1 += 2;
   y1 += 3;
   hwg_setcolor( hDC->cr, 0xffffff );
   cairo_rectangle( hDC->cr, x1, y1, nHeight, nHeight );
   cairo_fill( hDC->cr );

   hwg_setcolor( hDC->cr, 0 );
   cairo_set_line_width( hDC->cr, 1 );

   cairo_rectangle( hDC->cr, x1, y1, nHeight, nHeight );

   if( iSet )
   {
      cairo_move_to( hDC->cr, x1+2, y1+nHeight/2 );
      cairo_line_to( hDC->cr, x1+nHeight/2, y1+nHeight-2 );
      cairo_line_to( hDC->cr, x1+nHeight-1, y1 );
   }

   cairo_stroke( hDC->cr );

   if( cTitle )
   {
      gcTitle = hwg_convert_to_utf8( cTitle );
      pango_layout_set_text( hDC->layout, gcTitle, -1 );
      cairo_move_to( hDC->cr, x1 + nHeight + 4, y1-2 );
      pango_cairo_show_layout( hDC->cr, hDC->layout );
      g_free( gcTitle );
   }
#endif
}

HB_FUNC( HWG__DRAWRADIOBTN )
{
#if GTK_MAJOR_VERSION -0 < 3
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   gdouble x1 = (gdouble)hb_parni( 2 ), y1 = (gdouble)hb_parni( 3 ),
           y2 = (gdouble)hb_parni( 5 ),
           nHeight = y2-y1-4;
   int iSet = hb_parl(6);
   const char *cTitle = ( hb_pcount(  ) > 6 ) ? hb_parc( 7 ) : NULL;
   gchar *gcTitle;

   x1 += 2;
   y1 += 2;
   hwg_setcolor( hDC->cr, 0xffffff );
   cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2, 0, 6.28 );
   cairo_fill( hDC->cr );

   hwg_setcolor( hDC->cr, 0 );
   cairo_set_line_width( hDC->cr, 1 );

   cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2, 0, 6.28 );
   cairo_stroke( hDC->cr );

   if( iSet )
   {
      cairo_arc( hDC->cr, x1+nHeight/2, y1+nHeight/2, nHeight/2-3, 0, 6.28 );
      cairo_fill( hDC->cr );
   }

   if( cTitle )
   {
      gcTitle = hwg_convert_to_utf8( cTitle );
      pango_layout_set_text( hDC->layout, gcTitle, -1 );
      cairo_move_to( hDC->cr, x1 + nHeight + 4, y1-2 );
      pango_cairo_show_layout( hDC->cr, hDC->layout );
      g_free( gcTitle );
   }
#endif
}

/* ================== EOF of draw.c ========================== */

