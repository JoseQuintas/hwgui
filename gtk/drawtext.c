/*
 * $Id: drawtext.c,v 1.1 2005-03-10 11:32:48 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level text functions
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
#include "hwgtk.h"

void hwg_parse_color( ULONG ncolor, GdkColor * pColor );

HB_FUNC( DEFINEPAINTSTRU )
{
   hb_retnl( (LONG) 0 );
}

HB_FUNC( BEGINPAINT )
{
   // HDC hDC = BeginPaint( (HWND) hb_parnl( 1 ), pps );
   hb_retnl( (LONG) 0 );
}

HB_FUNC( ENDPAINT )
{
/*
   PAINTSTRUCT *pps = (PAINTSTRUCT*) hb_parnl( 2 );
   EndPaint( (HWND) hb_parnl( 1 ), pps );
   hb_xfree( pps );
*/   
}

HB_FUNC( DELETEDC )
{
   // DeleteDC( (HDC) hb_parnl( 1 ) );
}

/*
 * TextOut( hDC, x, y, cText )
 */
HB_FUNC( TEXTOUT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   char * cText = g_locale_to_utf8( hb_parc(4),-1,NULL,NULL,NULL );
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
                 hb_parni(2), hb_parni(3), hDC->layout,
		 (hDC->fcolor != -1)? &fcolor : NULL,
		 (hDC->bcolor != -1)? &bcolor : NULL );
   g_free( cText );
}

HB_FUNC( DRAWTEXT )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   char * cText = g_locale_to_utf8( hb_parc(2),-1,NULL,NULL,NULL );
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
                 hb_parni(3), hb_parni(4), hDC->layout,
		 (hDC->fcolor != -1)? &fcolor : NULL,
		 (hDC->bcolor != -1)? &bcolor : NULL );
   
   g_free( cText );

/*
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
*/   
}

HB_FUNC( GETTEXTMETRIC )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
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
      height = PANGO_PIXELS( pango_font_metrics_get_ascent  (metrics) ) +
               PANGO_PIXELS( pango_font_metrics_get_descent  (metrics) );
      width = PANGO_PIXELS( pango_font_metrics_get_approximate_char_width(metrics) );
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

HB_FUNC( GETTEXTSIZE )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   PangoRectangle rc;
   PHB_ITEM aMetr = _itemArrayNew( 2 );
   PHB_ITEM temp;

   if( ISCHAR(2) )
      pango_layout_set_text( hDC->layout, hb_parc(2), -1 );
   pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );

   temp = _itemPutNL( NULL, rc.width );
   _itemArrayPut( aMetr, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, rc.height );
   _itemArrayPut( aMetr, 2, temp );
   _itemRelease( temp );

   _itemReturn( aMetr );
   _itemRelease( aMetr );
   
}

HB_FUNC( GETCLIENTAREA )
{
/*
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
*/   
}

HB_FUNC( SETTEXTCOLOR )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   
   hb_retnl( hDC->fcolor );
   hDC->fcolor = hb_parnl(2);

}

HB_FUNC( SETBKCOLOR )
{
   PHWGUI_HDC hDC = (PHWGUI_HDC) hb_parnl(1);
   
   hb_retnl( hDC->bcolor );
   hDC->bcolor = hb_parnl(2);

}

HB_FUNC( SETTRANSPARENTMODE )
{
/*
   int iMode = SetBkMode(
                 (HDC) hb_parnl( 1 ),	// handle of device context  
                 ( hb_parl( 2 ) )? TRANSPARENT : OPAQUE );
   hb_retl( iMode == TRANSPARENT );
*/   
}

HB_FUNC( GETTEXTCOLOR )
{
   // hb_retnl( (LONG) GetTextColor( (HDC) hb_parnl( 1 ) ) );
}

HB_FUNC( GETBKCOLOR )
{
   // hb_retnl( (LONG) GetBkColor( (HDC) hb_parnl( 1 ) ) );
}


HB_FUNC( EXTTEXTOUT )
{
/*
   RECT rc;
   char *cText = hb_parc( 8 );

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
    (LPCTSTR) cText,	// points to string 
    strlen( cText ),	// number of characters in string 
    NULL        	// pointer to array of intercharacter spacing values  
   );
*/   
}

HB_FUNC( WRITESTATUSWINDOW )
{
   // SendMessage( (HWND) hb_parnl( 1 ), SB_SETTEXT, hb_parni( 2 ), (LPARAM) hb_parc( 3 ) );
}

HB_FUNC( WINDOWFROMDC )
{
   // hb_retnl( (LONG) WindowFromDC( (HDC) hb_parnl( 1 ) ) );
}

/* CreateFont( fontName, nWidth, hHeight [,fnWeight] [,fdwCharSet], 
               [,fdwItalic] [,fdwUnderline] [,fdwStrikeOut]  )
*/
HB_FUNC( CREATEFONT )
{
   PangoFontDescription *  hFont;
   PHWGUI_FONT h = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );

   hFont = pango_font_description_new();
   pango_font_description_set_family( hFont, hb_parc(1) );
   if( !ISNIL(6) )
      pango_font_description_set_style( hFont, (hb_parni(6))? PANGO_STYLE_ITALIC : PANGO_STYLE_NORMAL );
   pango_font_description_set_size( hFont, hb_parni(3) );
   if( !ISNIL(4) )
      pango_font_description_set_weight( hFont, hb_parni(4) );
      
   h->type = HWGUI_OBJECT_FONT;
   h->hFont = hFont;
   
   hb_retnl( (LONG) h );
   
}

/*
 * SetCtrlFont( hCtrl, hFont )
*/
HB_FUNC( HWG_SETCTRLFONT )
{
   GtkWidget * hCtrl = (GtkWidget*) hb_parnl(1);
   GtkStyle * style = gtk_style_copy( gtk_widget_get_style( hCtrl ) );
  
   style->font_desc = ( (PHWGUI_FONT) hb_parnl(2) )->hFont;
   gtk_widget_set_style( hCtrl, style );
	      	         
}

/*
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
*/
