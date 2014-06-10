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
      x1 = y1 = 0;
      x2 = widget->allocation.width;
      y2 = widget->allocation.height;      
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

HB_FUNC( HWG_ROUNDRECT )
{
}

HB_FUNC( HWG_REDRAWWINDOW )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   gtk_widget_queue_draw_area( widget, 0, 0,
        widget->allocation.width, widget->allocation.height );
}

HB_FUNC( HWG_DRAWBUTTON )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   int left = hb_parni( 2 );
   int top = hb_parni( 3 );
   int right = hb_parni( 4 );
   int bottom = hb_parni( 5 );
   unsigned int iType = hb_parni( 6 );
   GtkStyle * style = hDC->widget->style;

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

/*
 * DrawEdge( hDC,x1,y1,x2,y2,nFlag,nBorder )
 */
HB_FUNC( HWG_GTK_DRAWEDGE )
{
PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
int left = hb_parni( 2 );
int top = hb_parni( 3 );
int right = hb_parni( 4 );
int bottom = hb_parni( 5 );
unsigned int iType = hb_parni( 6 );
GtkStyle * style = hDC->widget->style;

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
}

/*
 * DrawBitmap( hDC, hBitmap, style, x, y, width, height )
 */
HB_FUNC( HWG_DRAWBITMAP )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PHWGUI_PIXBUF obj = (PHWGUI_PIXBUF) HB_PARHANDLE(2);
   gint x =  hb_parni(4);
   gint y =  hb_parni(5);
   gint width = hb_parni(6);
   gint height = hb_parni(7);
   GdkPixbuf * pixbuf = gdk_pixbuf_scale_simple( obj->handle, width, height, GDK_INTERP_HYPER );
   
   gdk_cairo_set_source_pixbuf( hDC->cr, pixbuf, x, y );
   cairo_paint( hDC->cr );
   gdk_pixbuf_unref( pixbuf );

}

/*
 * DrawTransparentBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( HWG_DRAWTRANSPARENTBITMAP )
{
}

HB_FUNC( HWG_SPREADBITMAP )
{
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

HB_FUNC( HWG_OPENBITMAP )
{
   PHWGUI_PIXBUF hpix;
   GdkPixbuf * handle = gdk_pixbuf_new_from_file( hb_parc(1), NULL );
   
   if( handle )
   {
      hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = handle;
      HB_RETHANDLE( hpix );
   }
}

HB_FUNC( HWG_OPENIMAGE )
{
   PHWGUI_PIXBUF hpix;
   BOOL lString = ( HB_ISNIL( 2 ) ) ? 0 : hb_parl( 2 );
   GdkPixbuf * handle = (lString)? gdk_pixbuf_new_from_inline ( -1, hb_parc(1), FALSE, NULL ) : gdk_pixbuf_new_from_file( hb_parc(1), NULL );
   
   if( handle )
   {
      hpix = (PHWGUI_PIXBUF) hb_xgrab( sizeof(HWGUI_PIXBUF) );
      hpix->type = HWGUI_OBJECT_PIXBUF;
      hpix->handle = handle;
      HB_RETHANDLE( hpix );
   }
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

   if( obj && obj->handle )
   {
      handle = alpha2pixbuf( obj->handle, hb_parnl(2) );
      gdk_pixbuf_unref( obj->handle );
      obj->handle = handle;
   }
   
}

HB_FUNC( HWG_DRAWICON )
{
}

HB_FUNC( HWG_GETSYSCOLOR )
{
   hb_retnl( 0 );
}

#define  PS_SOLID   0

HB_FUNC( HWG_CREATEPEN )
{
   PHWGUI_PEN hpen = (PHWGUI_PEN) hb_xgrab( sizeof(HWGUI_PEN) );

   hpen->type = HWGUI_OBJECT_PEN;
   hpen->style = ( hb_parni(1) == PS_SOLID )? GDK_LINE_SOLID : GDK_LINE_ON_OFF_DASH;
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
      }
      else if( obj->type == HWGUI_OBJECT_BRUSH )
      {
         hwg_setcolor( hDC->cr, ((PHWGUI_BRUSH)obj)->color );
      }
      else if( obj->type == HWGUI_OBJECT_FONT )
      {
         hDC->hFont = ((PHWGUI_FONT)obj)->hFont;
         pango_layout_set_font_description( hDC->layout, hDC->hFont );
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
      hb_xfree( obj );
   }
   else if( obj->type == HWGUI_OBJECT_PIXBUF )
   {
      gdk_pixbuf_unref( ( (PHWGUI_PIXBUF)obj )->handle );
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

   hDC->window = widget->window;
   hDC->cr = gdk_cairo_create( widget->window );

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

   hDC->window = widget->window;
   hDC->cr = gdk_cairo_create( widget->window );

   hDC->layout = pango_cairo_create_layout( hDC->cr );
   hDC->fcolor = hDC->bcolor = -1;

   HB_RETHANDLE( hDC );
}

HB_FUNC( HWG_RELEASEDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(2);

   if( hDC->layout )
      g_object_unref( (GObject*) hDC->layout );

   cairo_destroy( hDC->cr );
   hb_xfree( hDC );
}

HB_FUNC( HWG_GETDRAWITEMINFO )
{
}

/*
 * DrawGrayBitmap( hDC, hBitmap, x, y )
 */
HB_FUNC( HWG_DRAWGRAYBITMAP )
{
}

HB_FUNC( HWG_GETCLIENTAREA )
{
   PHWGUI_PPS pps = ( PHWGUI_PPS ) HB_PARHANDLE( 1 );
   GtkWidget * widget = pps->hDC->widget;
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );    

   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), widget->allocation.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), widget->allocation.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETCLIENTRECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );    

   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), widget->allocation.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), widget->allocation.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

HB_FUNC( HWG_GETWINDOWRECT )
{
   GtkWidget * widget = (GtkWidget*) HB_PARHANDLE(1);
   PHB_ITEM aMetr = hb_itemArrayNew( 4 );    

   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), 0 );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 3 ), widget->allocation.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 4 ), widget->allocation.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
}

