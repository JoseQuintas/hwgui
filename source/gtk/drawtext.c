/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level text functions
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
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

#define DT_CENTER                   1
#define DT_RIGHT                    2

#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

/* Avoid warnings from GCC */
#include "warnings.h"

extern void hwg_parse_color( HB_ULONG ncolor, GdkColor * pColor );
extern void hwg_setcolor( cairo_t * cr, long int nColor );
extern GtkWidget * GetActiveWindow( void );
#if GTK_MAJOR_VERSION -0 > 2
extern void set_css_data( char *szData );
#endif

HB_FUNC( HWG_DELETEDC )
{
}

/*
 * TextOut( hDC, x, y, cText )
 */
HB_FUNC( HWG_TEXTOUT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   char * cText;

   if( hb_parclen(4) > 0 )
   {
      cText = hwg_convert_to_utf8( hb_parc(4) );
      pango_layout_set_text( hDC->layout, cText, -1 );

      hwg_setcolor( hDC->cr, (hDC->fcolor != -1)? hDC->fcolor : 0 );

      cairo_move_to( hDC->cr, (gdouble)hb_parni(2), (gdouble)hb_parni(3) );
      pango_cairo_show_layout( hDC->cr, hDC->layout );

      g_free( cText );
   }
}

HB_FUNC( HWG_DRAWTEXT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   char * cText;
   PangoRectangle rc;
   int iWidth = hb_parni(5)-hb_parni(3);
   int bElli = (HB_ISLOG(8) && hb_parl(8))? 1 : 0;

   if( hb_parclen(2) > 0 )
   {
      cText = hwg_convert_to_utf8( hb_parc(2) );
      pango_layout_set_text( hDC->layout, cText, -1 );

      pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );
      if( bElli )
         pango_layout_set_ellipsize( hDC->layout, PANGO_ELLIPSIZE_END );
      pango_layout_set_width( hDC->layout, iWidth*PANGO_SCALE );
      pango_layout_set_justify( hDC->layout, 1 );
      //pango_layout_set_width( hDC->layout, -1 );

      if( !HB_ISNIL(7) && ( hb_parni(7) & ( DT_CENTER | DT_RIGHT ) ) &&
            ( rc.width < ( iWidth-10 ) ) )
      {
         pango_layout_set_alignment( hDC->layout,
             (hb_parni(7) & DT_CENTER)? PANGO_ALIGN_CENTER : PANGO_ALIGN_RIGHT );
      }
      else
         pango_layout_set_alignment( hDC->layout, PANGO_ALIGN_LEFT );

      hwg_setcolor( hDC->cr, (hDC->fcolor != -1)? hDC->fcolor : 0 );
      cairo_move_to( hDC->cr, (gdouble)hb_parni(3), (gdouble)hb_parni(4) );
      pango_cairo_show_layout( hDC->cr, hDC->layout );
      cairo_stroke( hDC->cr );
      g_free( cText );
   }
}

HB_FUNC( HWG_GETTEXTMETRIC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   PangoContext * context;
   PangoFontMetrics * metrics;

   if( !(hDC->hFont) )
   {
      GtkStyle * style = gtk_widget_get_style( hDC->widget );
      hDC->hFont = style->font_desc;
   }
   {
      PHB_ITEM aMetr = _itemArrayNew( 3 );
      PHB_ITEM temp;
      int height, width;

      context = pango_layout_get_context( hDC->layout );
      metrics = pango_context_get_metrics( context, hDC->hFont, NULL );
      height = ( pango_font_metrics_get_ascent( metrics ) +
               pango_font_metrics_get_descent( metrics ) ) / PANGO_SCALE;
      width = pango_font_metrics_get_approximate_char_width(metrics) / PANGO_SCALE;
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
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   char * cText = hwg_convert_to_utf8( hb_parc( 2 ) );
   PangoRectangle rc;
   PHB_ITEM aMetr = hb_itemArrayNew( 2 );

   if( HB_ISCHAR(2) && hb_parclen(2) > 0 )
      pango_layout_set_text( hDC->layout, cText, -1 );
   pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );

   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 1 ), rc.width );
   hb_itemPutNL( hb_arrayGetItemPtr( aMetr, 2 ), rc.height );
   hb_itemRelease( hb_itemReturn( aMetr ) );
   g_free( cText );
}

HB_FUNC( HWG_GETTEXTWIDTH )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   char * cText = hwg_convert_to_utf8( hb_parc( 2 ) );
   PangoRectangle rc;

   if( HB_ISCHAR(2) && hb_parclen(2) > 0 )
      pango_layout_set_text( hDC->layout, cText, -1 );
   pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );

   hb_retnl( rc.width );
   g_free( cText );
}

HB_FUNC( HWG_GETFONTSLIST )
{
   GtkWidget * widget = GetActiveWindow();
   cairo_t *cr;
   PangoLayout * layout;
   PangoContext *context;
   PangoFontFamily **families;
   int n_families, i;
   PHB_ITEM aFonts;

   cr = gdk_cairo_create( gtk_widget_get_window(widget) );
   layout = pango_cairo_create_layout( cr );
   context = pango_layout_get_context( layout );
   pango_context_list_families( context, &families, &n_families );
   if( n_families <= 0 )
      return;

   aFonts = hb_itemArrayNew( n_families );
   for( i=0; i<n_families; i++ )
      hb_arraySetC( aFonts, i+1, pango_font_family_get_name( families[i] ) );

   g_object_unref( (GObject*) layout );
   cairo_destroy( cr );
   g_free( families );
   hb_itemReturnRelease( aFonts );
}

HB_FUNC( HWG_SETTEXTCOLOR )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

   hb_retnl( hDC->fcolor );
   hDC->fcolor = hb_parnl(2);

}

HB_FUNC( HWG_SETBKCOLOR )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

   hb_retnl( hDC->bcolor );
   hDC->bcolor = hb_parnl(2);

}

HB_FUNC( HWG_SETTRANSPARENTMODE )
{
}

HB_FUNC( HWG_GETTEXTCOLOR )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   hb_retnl( hDC->fcolor );
}

HB_FUNC( HWG_GETBKCOLOR )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);

   hb_retnl( hDC->bcolor );
}


HB_FUNC( HWG_EXTTEXTOUT )
{
}

/*
HB_FUNC( HWG_WRITESTATUSWINDOW )
{
   char *cText = hwg_convert_to_utf8( hb_parcx(3) );
   GtkWidget *w = (GtkWidget *) hb_parptr(1);
   int iStatus = hb_parni(2)-1;

   hb_retni( gtk_statusbar_push( GTK_STATUSBAR(w), iStatus, cText ) );
   g_free( cText );
}
*/
HB_FUNC( HWG_WINDOWFROMDC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) HB_PARHANDLE(1);
   HB_RETHANDLE( (GtkWidget *) hDC->widget );

}

/* CreateFont( fontName, nWidth, hHeight [,fnWeight] [,fdwCharSet],
               [,fdwItalic] [,fdwUnderline] [,fdwStrikeOut]  )
*/
HB_FUNC( HWG_CREATEFONT )
{
   PangoFontDescription *  hFont;
   PHWGUI_FONT h = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );
   int iUnder = ( !HB_ISNIL(7) && hb_parni(7) > 0 )? 1 : 0;
   int iStrike = ( !HB_ISNIL(8) && hb_parni(8) > 0 )? 1 : 0;

   hFont = pango_font_description_new();
   pango_font_description_set_family( hFont, hb_parc(1) );
   if( !HB_ISNIL(6) )
      pango_font_description_set_style( hFont, (hb_parni(6))? PANGO_STYLE_ITALIC : PANGO_STYLE_NORMAL );
   // pango_font_description_set_size( hFont, hb_parni(3) * PANGO_SCALE );
   pango_font_description_set_size( hFont, hb_parni(3) );
   if( !HB_ISNIL(4) )
      pango_font_description_set_weight( hFont, hb_parni(4) );

   h->type = HWGUI_OBJECT_FONT;
   h->hFont = hFont;
   if( iUnder || iStrike )
   {
      h->attrs = pango_attr_list_new();
      if( iUnder )
         pango_attr_list_insert( h->attrs, pango_attr_underline_new( PANGO_UNDERLINE_SINGLE) );
      if( iStrike )
         pango_attr_list_insert( h->attrs, pango_attr_strikethrough_new( 1 ) );
   }
   else
      h->attrs = NULL;
   HB_RETHANDLE( h );

}

/*
 * SetCtrlFont( hCtrl, hFont )
*/
#if GTK_MAJOR_VERSION -0 < 3
HB_FUNC( HWG_SETCTRLFONT )
{
   GtkWidget * hCtrl = (GtkWidget*) HB_PARHANDLE(1);
   GtkWidget * hLabel = (GtkWidget*) g_object_get_data( (GObject*) hCtrl,"label" );

   if( GTK_IS_BUTTON( hCtrl ) )
      hCtrl = gtk_bin_get_child( GTK_BIN( hCtrl ) );
   else if( GTK_IS_EVENT_BOX( hCtrl ) )
      hCtrl = gtk_bin_get_child( GTK_BIN( hCtrl ) );
   else if( hLabel )
      hCtrl = (GtkWidget*) hLabel;

   gtk_widget_modify_font( hCtrl, ( (PHWGUI_FONT) HB_PARHANDLE(3) )->hFont );
}
#else
HB_FUNC( HWG_SETCTRLFONT )
{
   GtkWidget * hCtrl = (GtkWidget*) HB_PARHANDLE(1);
   PHWGUI_FONT pFont = (PHWGUI_FONT) HB_PARHANDLE(3);
   char szData[256];
   const char *pName = gtk_widget_get_name( hCtrl );

   if( pName && strncmp(pName,"Gtk",3) != 0 )
   {
      char *szFamily = pango_font_description_get_family( pFont->hFont );
      gint iHeight = pango_font_description_get_size( pFont->hFont );
      int iIta = (pango_font_description_get_style( pFont->hFont ) == PANGO_STYLE_ITALIC)? 1 : 0;
      int iBold = (pango_font_description_get_weight( pFont->hFont ) == PANGO_WEIGHT_BOLD)? 1 : 0;

      sprintf( szData, "#%s { font-family: %s; font-size: %dpx; font-weight: %s;  font-style: %s; }",
         pName, szFamily, iHeight/PANGO_SCALE,
         (iBold)? "bold" : "normal",
         (iIta)? "italic" : "normal");
      //hwg_writelog( NULL,szData );
      set_css_data( szData );
   }

}
#endif

HB_FUNC( G_DEBUG )
{
   g_debug( "%s" , hb_parc(1));
}

/* =========================== EOF of drawtext.c ============================= */

