/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level text functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include "gtk/gtk.h"
#include "hwgtk.h"

#define DT_CENTER                   1
#define DT_RIGHT                    2

#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

void hwg_parse_color( HB_ULONG ncolor, GdkColor * pColor );

HB_FUNC( HWG_DELETEDC )
{
}

/*
 * TextOut( hDC, x, y, cText )
 */
HB_FUNC( HWG_TEXTOUT )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   char *cText = hwg_convert_to_utf8( hb_parc( 4 ) );
   GdkColor fcolor, bcolor;

   if( hDC->fcolor != -1 )
   {
      hwg_parse_color( hDC->fcolor, &fcolor );
   }
   if( hDC->bcolor != -1 )
   {
      hwg_parse_color( hDC->bcolor, &bcolor );
   }

   pango_layout_set_text( hDC->layout, cText, -1 );
   gdk_draw_layout_with_colors( hDC->window, hDC->gc,
         hb_parni( 2 ), hb_parni( 3 ), hDC->layout,
         ( hDC->fcolor != -1 ) ? &fcolor : NULL,
         ( hDC->bcolor != -1 ) ? &bcolor : NULL );
   g_free( cText );
}

HB_FUNC( HWG_DRAWTEXT )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   char *cText = hwg_convert_to_utf8( hb_parc( 2 ) );
   GdkColor fcolor, bcolor;
   PangoRectangle rc;
   int iWidth = hb_parni( 5 ) - hb_parni( 3 );

   if( hDC->fcolor != -1 )
   {
      hwg_parse_color( hDC->fcolor, &fcolor );
   }
   if( hDC->bcolor != -1 )
   {
      hwg_parse_color( hDC->bcolor, &bcolor );
   }

   pango_layout_set_text( hDC->layout, cText, -1 );

   pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );
   pango_layout_set_width( hDC->layout, -1 );

   if( !HB_ISNIL( 7 ) && ( hb_parni( 7 ) & ( DT_CENTER | DT_RIGHT ) ) &&
         ( rc.width < ( iWidth - 10 ) ) )
   {
      pango_layout_set_width( hDC->layout, iWidth * PANGO_SCALE );
      // pango_layout_set_wrap( hDC->layout, PANGO_WRAP_CHAR );
      pango_layout_set_alignment( hDC->layout,
            ( hb_parni( 7 ) & DT_CENTER ) ? PANGO_ALIGN_CENTER :
            PANGO_ALIGN_RIGHT );
   }
   gdk_draw_layout_with_colors( hDC->window, hDC->gc,
         hb_parni( 3 ), hb_parni( 4 ), hDC->layout,
         ( hDC->fcolor != -1 ) ? &fcolor : NULL,
         ( hDC->bcolor != -1 ) ? &bcolor : NULL );

   g_free( cText );

}

HB_FUNC( HWG_GETTEXTMETRIC )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   PangoContext *context;
   PangoFontMetrics *metrics;

   if( !( hDC->hFont ) )
   {
      GtkStyle *style = gtk_widget_get_style( hDC->widget );
      hDC->hFont = style->font_desc;
   }
   {
      PHB_ITEM aMetr = _itemArrayNew( 3 );
      PHB_ITEM temp;
      int height, width;

      context = pango_layout_get_context( hDC->layout );
      metrics = pango_context_get_metrics( context, hDC->hFont, NULL );
      height = PANGO_PIXELS( pango_font_metrics_get_ascent( metrics ) ) +
            PANGO_PIXELS( pango_font_metrics_get_descent( metrics ) );
      width =
            PANGO_PIXELS( pango_font_metrics_get_approximate_char_width
            ( metrics ) );
      pango_font_metrics_unref( metrics );

      temp = _itemPutNL( NULL, height );
      _itemArrayPut( aMetr, 1, temp );
      _itemRelease( temp );

      temp = _itemPutNL( NULL, width );
      _itemArrayPut( aMetr, 2, temp );
      _itemRelease( temp );

      temp = _itemPutNL( NULL, width );
      _itemArrayPut( aMetr, 3, temp );
      _itemRelease( temp );

      _itemReturn( aMetr );
      _itemRelease( aMetr );
   }

}

HB_FUNC( HWG_GETTEXTSIZE )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );
   char *cText = hwg_convert_to_utf8( hb_parc( 2 ) );
   PangoRectangle rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );

   if( HB_ISCHAR( 2 ) )
      pango_layout_set_text( hDC->layout, cText, -1 );
   pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );

   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), rc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), rc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
   g_free( cText );
}

HB_FUNC( HWG_GETCLIENTAREA )
{
}

HB_FUNC( HWG_SETTEXTCOLOR )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );

   hb_retnl( hDC->fcolor );
   hDC->fcolor = hb_parnl( 2 );

}

HB_FUNC( HWG_SETBKCOLOR )
{
   PHWGUI_HDC hDC = ( PHWGUI_HDC ) HB_PARHANDLE( 1 );

   hb_retnl( hDC->bcolor );
   hDC->bcolor = hb_parnl( 2 );

}

HB_FUNC( HWG_SETTRANSPARENTMODE )
{
}

HB_FUNC( HWG_GETTEXTCOLOR )
{
}

HB_FUNC( HWG_GETBKCOLOR )
{
}

/* CreateFont( fontName, nWidth, hHeight [,fnWeight] [,fdwCharSet], 
               [,fdwItalic] [,fdwUnderline] [,fdwStrikeOut]  )
*/
HB_FUNC( HWG_CREATEFONT )
{
   PangoFontDescription *hFont;
   PHWGUI_FONT h = ( PHWGUI_FONT ) hb_xgrab( sizeof( HWGUI_FONT ) );

   hFont = pango_font_description_new(  );
   pango_font_description_set_family( hFont, hb_parc( 1 ) );
   if( !HB_ISNIL( 6 ) )
      pango_font_description_set_style( hFont,
            ( hb_parni( 6 ) ) ? PANGO_STYLE_ITALIC : PANGO_STYLE_NORMAL );
   pango_font_description_set_size( hFont, hb_parni( 3 ) );
   if( !HB_ISNIL( 4 ) )
      pango_font_description_set_weight( hFont, hb_parni( 4 ) );

   h->type = HWGUI_OBJECT_FONT;
   h->hFont = hFont;

   HB_RETHANDLE( h );

}

/*
 * SetCtrlFont( hCtrl, hFont )
*/
HB_FUNC( HWG_SETCTRLFONT )
{
   GtkWidget *hCtrl = ( GtkWidget * ) HB_PARHANDLE( 1 );
   GtkLabel *hLabel =
         ( GtkLabel * ) g_object_get_data( ( GObject * ) hCtrl, "label" );
   GtkStyle *style;

   if( hLabel )
      hCtrl = ( GtkWidget * ) hLabel;

   style = gtk_style_copy( gtk_widget_get_style( hCtrl ) );

   style->font_desc = ( ( PHWGUI_FONT ) HB_PARHANDLE( 2 ) )->hFont;
   gtk_widget_set_style( hCtrl, style );

}
