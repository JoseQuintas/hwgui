/*
 * $Id$
 */

/*
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * The Edit control - C level
 *
 * Copyright 2013 Alexander Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "hbvm.h"
#include "hbstack.h"
#include "guilib.h"

#include <cairo.h>
#include "gtk/gtk.h"
#include "hwgtk.h"

typedef struct
{
   long fg;                 // foreground colour
   long bg;                 // background colour
   int iFont;               // possible font-styling information

} TEDATTR;

typedef struct
{
   // Font information
   PHWGUI_FONT hwg_font;
   int iWidth, iHeight, ixAdd, iSpace;

} TEDFONT;

typedef struct
{
   int  x1;
   int  x2;
   int  y1;
   int  y2;
} TEDBLOCK;

typedef struct
{
   GtkWidget *   widget;
   GtkWidget *     area;
   TEDFONT *  pFontsScr;
   TEDFONT *  pFontsPrn;
   int       iFontsCurr;
   TEDATTR *      pattr;
   int     *     pattrf;
   PHWGUI_HDC           hDCScr;
   PHWGUI_HDC           hDCPrn;
   double        dKoeff;
   int           iWidth;
   int       iInterline;
   int        iDocWidth;
   HB_BOOL        bWrap;
   long              fg;
   long              bg;
   long         fg_curr;
   long         bg_curr;
   int               x1;
   int               x2;
   int             ypos;
   int       ixCaretPos;
   int       iyCaretPos;
   int     iCaretHeight;

} TEDIT;

#define  NUMBER_OF_FONTS  16
#define  TEDATTR_MAX    1024
#define  TEDATTRF_MAX     32

#define WM_PAINT            15
#define WM_HSCROLL         276
#define WM_VSCROLL         277
#define WS_VSCROLL          2097152     // 0x00200000L
#define WS_HSCROLL          1048576     // 0x00100000L

extern void hwg_setcolor( cairo_t * cr, long int nColor );
extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
extern void SetObjectVar( PHB_ITEM pObject, char *varname, PHB_ITEM pValue );
extern void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject );
extern void set_signal( gpointer handle, char *cSignal, long int p1,
      long int p2, long int p3 );
 extern void set_event( gpointer handle, char *cSignal, long int p1,
            long int p2, long int p3 );
extern void cb_signal( GtkWidget * widget, gchar * data );
extern void all_signal_connect( gpointer hWnd );
extern gint cb_signal_size( GtkWidget *widget, GtkAllocation *allocation, gpointer data );
extern GtkFixed *getFixedBox( GObject * handle );

gchar * szDelimiters = " .,-";

void wrlog( const char * sFile, const char * sTraceMsg, ... )
{
   FILE *hFile;

   if( sFile == NULL )
   {
      hFile = hb_fopen( "trace.log", "a" );
   }
   else
   {
      hFile = hb_fopen( sFile, "a" );
   }

   if( hFile )
   {
      va_list ap;

      va_start( ap, sTraceMsg );
      vfprintf( hFile, sTraceMsg, ap );
      va_end( ap );

      fclose( hFile );
   }

}

int hced_utf8bytes( char * szText, int iLen )
{
   char * ptr = szText;

   while( iLen -- && *ptr )
      ptr = g_utf8_next_char( ptr );

   return ( ptr - szText );
}

TEDFONT * ted_setfont( TEDIT * pted, PHWGUI_FONT hwg_font, int iNum, HB_BOOL bPrn  )
{
   TEDFONT * pFont;

   pFont = ( (bPrn)? pted->pFontsPrn : pted->pFontsScr ) + 
         ( (iNum>=0)? iNum : pted->iFontsCurr );

   pFont->iWidth = 0;

   pFont->hwg_font = hwg_font;
   if( iNum < 0 )
      pted->iFontsCurr++;

   return pFont;
}

/*
 * ted_CalcItemWidth() returns the text width in pixels, 
 * writes to the 4 parameter (iRealLen) the width in chars
 */

int ted_CalcItemWidth( PangoLayout * layout, char *szText, TEDFONT *font, int *iRealLen,
      int iWidth, HB_BOOL bWrap, HB_BOOL bLastInFew )
{
   int i, i1, iReal, xpos, iTextWidth, iDLen = strlen( szDelimiters );
   PangoRectangle rc;
   gchar * ptr;

   pango_layout_set_font_description( layout, font->hwg_font->hFont );

   if( !font->iWidth )
   {
      pango_layout_set_text( layout, "aA", 2 );
      pango_layout_get_pixel_extents( layout, &rc, NULL );
      font->iWidth = rc.width / 2;
      font->iHeight = PANGO_DESCENT( rc );
      pango_layout_set_text( layout, "aa", 2 );
      pango_layout_get_pixel_extents( layout, &rc, NULL );
      font->ixAdd = rc.width;
      pango_layout_set_text( layout, "a", 1 );
      pango_layout_get_pixel_extents( layout, &rc, NULL );
      font->ixAdd -= rc.width * 2;
      pango_layout_set_text( layout, "  a", 3 );
      pango_layout_get_pixel_extents( layout, &rc, NULL );
      font->iSpace = PANGO_LBEARING(rc)/2;
      // wrlog( NULL, "iWidth = %d iHeight= %d \r\n",font->iWidth,font->iHeight );
   }

   iReal = iWidth / font->iWidth;
   if( iReal > *iRealLen )
      iReal = *iRealLen;

   pango_layout_set_text( layout, szText, hced_utf8bytes( szText, iReal ) );
   pango_layout_get_pixel_extents( layout, &rc, NULL );
   iTextWidth = PANGO_RBEARING(rc) + font->ixAdd;

   if( iTextWidth > iWidth )
   {
      for( i = iReal - 1; i > 0; i-- )
      {
         if( bWrap )
         {
            ptr = g_utf8_offset_to_pointer( szText, i );
            i1 = i;
            while( i > 0 && !g_utf8_strchr( szDelimiters, iDLen, g_utf8_get_char(ptr) ) ) {
               ptr = g_utf8_prev_char( ptr );
               i --;
            }
            if( !i && bLastInFew )
            //if( !i )
            {
               i = i1;
               break;
            }
         }
         pango_layout_set_text( layout, szText, hced_utf8bytes( szText, i ) );
         pango_layout_get_pixel_extents( layout, &rc, NULL );
         iTextWidth = PANGO_RBEARING(rc) + font->ixAdd;
         if( iTextWidth <= iWidth )
            break;
      }
      xpos = iTextWidth;
      *iRealLen = i;
   }
   else
   {
      xpos = iTextWidth;
      i1 = iReal;

      if( bWrap && iReal < *iRealLen )
      {
         i = i1;
         ptr = g_utf8_offset_to_pointer( szText, i );
         while( i && !g_utf8_strchr( szDelimiters, iDLen, g_utf8_get_char(ptr) ) &&
               !g_utf8_strchr( szDelimiters, iDLen, g_utf8_get_char(ptr = g_utf8_prev_char(ptr)) ) ) i --;
         if( i || bLastInFew )
         //if( i )
            i1 = i;
      }
      for( i = iReal + 1; i <= *iRealLen; i++ )
      {
         if( bWrap )
         {
            ptr = g_utf8_offset_to_pointer( szText, i );
            while( i < *iRealLen && !g_utf8_strchr( szDelimiters,iDLen,g_utf8_get_char(ptr) ) ) {
               i ++;
               ptr = g_utf8_next_char( ptr );
            }
         }
         pango_layout_set_text( layout, szText, hced_utf8bytes( szText, i ) );
         pango_layout_get_pixel_extents( layout, &rc, NULL );
         iTextWidth = PANGO_RBEARING(rc) + font->ixAdd;
         if( iTextWidth > iWidth )
            break;

         xpos = iTextWidth;
         i1 = i;
      }
      *iRealLen = i1;
   }

   return xpos;
}

int ted_CalcLineWidth( TEDIT * pted, char *szText, int iLen, int iWidth, int * iRealWidth, short int bWrap )
{
   TEDATTR *pattr = pted->pattr;
   int i, lasti, iReqLen, iRealLen, iPrinted = 0;
   char * ptr;

   *iRealWidth = 0;
   for( i = 0, lasti = 0; i <= iLen; i++ )
   {
      if( i == iLen || ( pattr + i )->iFont != ( pattr + lasti )->iFont )
      {
         iReqLen = i - lasti;
         ptr = szText + hced_utf8bytes( szText, lasti );
         while( ptr > szText && *(g_utf8_prev_char(ptr)) == ' ' )
         {
            ptr --; iReqLen ++;
         }
         iRealLen = iReqLen;
         *iRealWidth += ted_CalcItemWidth( pted->hDCScr->layout, ptr,
               pted->pFontsScr + (pattr + lasti)->iFont, &iRealLen,
               iWidth - *iRealWidth, pted->bWrap, lasti );

         iPrinted += iRealLen;
         if( iRealLen < iReqLen )
            break;
         lasti = i;
      }
   }

   return iPrinted;
}

int ted_TextOut( TEDIT * pted, int xpos, int ypos, int iHeight,
      int iMaxAscent, char *szText, TEDATTR * pattr, int iLen )
{
   //int i, yoff;
   PangoRectangle rc;
   long fg, bg;
   PHWGUI_HDC hDC = (pted->hDCPrn)? pted->hDCPrn : pted->hDCScr;
   TEDFONT *font = ( (pted->hDCPrn)? pted->pFontsPrn : pted->pFontsScr ) + pattr->iFont;
   int iWidth;

   hDC->hFont = font->hwg_font->hFont;
   pango_layout_set_font_description( hDC->layout, hDC->hFont );

   fg = ( pattr->fg == pattr->bg )? pted->fg : pattr->fg;
   bg = ( pattr->fg == pattr->bg )? pted->bg : pattr->bg;
   if( fg != pted->fg_curr )
   {
      hDC->fcolor = fg;
      pted->fg_curr = fg;
   }
   if( bg != pted->bg_curr )
   {
      hDC->bcolor = bg;
      pted->bg_curr = bg;
   }

   //yoff = iMaxAscent - font->tm.tmAscent;

   // get size of text
   pango_layout_set_text( hDC->layout, szText, hced_utf8bytes( szText, iLen ) );
   // Wrap mode off
   pango_layout_set_width( hDC->layout, -1 );
   pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );
   iWidth = PANGO_RBEARING(rc) + font->ixAdd;

   if( hDC->bcolor != -1 )
   {
      hwg_setcolor( hDC->cr, hDC->bcolor );
      cairo_rectangle( hDC->cr, (gdouble)xpos, (gdouble)ypos, //-pted->iInterline/2, 
            (iLen==1 && *szText==' ')? (gdouble)font->iSpace : (gdouble)iWidth, 
            (gdouble)PANGO_DESCENT(rc)+pted->iInterline );
      cairo_fill( hDC->cr );
   }

   hwg_setcolor( hDC->cr, (hDC->fcolor != -1)? hDC->fcolor : 0 );
   cairo_move_to( hDC->cr, (gdouble)xpos, (gdouble)ypos );
   pango_cairo_show_layout( hDC->cr, hDC->layout );

   //SetRect( &rect, xpos, ypos, xpos + sz.cx, ypos + iHeight );
   //ExtTextOut( hDC, xpos, ypos + yoff, ETO_OPAQUE, &rect, szText, iLen, 0 );

   return iWidth; //rc.width;
}

int ted_LineOut( TEDIT * pted, int x1, int ypos, char *szText, int iPrinted, int iHeight )
{
   TEDATTR *pattr = pted->pattr;
   int i, lasti, iReqLen, iRealLen;
   int iMaxAscent = 0;
   char * ptr;

   //wrlog( NULL, "Lineout-1\r\n" );

   if( pted->hDCPrn )
      x1 = (int) ( x1 * pted->dKoeff );

   if( iPrinted )
      for( i = 0, lasti = 0; i <= iPrinted; i++ )
      {
         // if the colour or font changes, then need to output 
         if( i == iPrinted ||
               ( pattr + i )->fg != ( pattr + lasti )->fg ||
               ( pattr + i )->bg != ( pattr + lasti )->bg ||
               ( pattr + i )->iFont != ( pattr + lasti )->iFont )
         {
            if( i < iPrinted )
               iReqLen = i - lasti;
            else
               iReqLen = iPrinted - lasti;
            //wrlog( NULL, "x1 = %u ypos= %u len = %u \r\n", x1, ypos, iReqLen );
            ptr = szText + hced_utf8bytes( szText, lasti );
            while( ptr > szText && *(g_utf8_prev_char(ptr)) == ' ' )
            {
               ptr --; iReqLen ++;
            }
            iRealLen = iReqLen;
            x1 += ted_TextOut( pted, x1, ypos, iHeight, iMaxAscent,
                        ptr, pattr + lasti, iRealLen );
            // wrlog( NULL, "x1 = %u \r\n", x1 );
            if( iRealLen != iReqLen )
               break;
            lasti = i;
         }
      }

   if( !pted->hDCPrn )
   {
      hwg_setcolor( pted->hDCScr->cr, pted->bg );
      cairo_rectangle( pted->hDCScr->cr, (gdouble)x1, (gdouble)ypos,
            (gdouble)(pted->iWidth-x1+1), (gdouble)iHeight );
      cairo_fill( pted->hDCScr->cr );
   }
   if( pted->iyCaretPos == ypos )
   {
      hwg_setcolor( pted->hDCScr->cr, (pted->hDCScr->fcolor != -1)? pted->hDCScr->fcolor : 0 );
      cairo_move_to( pted->hDCScr->cr, (gdouble)pted->ixCaretPos, (gdouble)pted->iyCaretPos );
      cairo_line_to( pted->hDCScr->cr, (gdouble)pted->ixCaretPos, (gdouble)pted->iyCaretPos+iHeight );
      cairo_stroke( pted->hDCScr->cr );
      pted->iCaretHeight = iHeight;
   }

   return x1;
}

void ted_ClearAttr( TEDIT *pted )
{
   memset( pted->pattr, 0, sizeof( TEDATTR ) * TEDATTR_MAX );
   memset( pted->pattrf, 0, sizeof( int ) * TEDATTRF_MAX );
}

HB_FUNC( HCED_INITTEXTEDIT )
{
}

HB_FUNC( HCED_CREATETEXTEDIT )
{
   TEDIT *pted = ( TEDIT * ) hb_xgrab( sizeof( TEDIT ) );
   GtkWidget *vbox, *hbox;
   GtkWidget *vscroll, *hscroll;
   GtkWidget *area;
   GtkFixed *box;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   GObject *handle;
   int nLeft = hb_itemGetNI( GetObjectVar( pObject, "NLEFT" ) );
   int nTop = hb_itemGetNI( GetObjectVar( pObject, "NTOP" ) );
   int nWidth = hb_itemGetNI( GetObjectVar( pObject, "NWIDTH" ) );
   int nHeight = hb_itemGetNI( GetObjectVar( pObject, "NHEIGHT" ) );
   unsigned long int ulStyle =
         hb_itemGetNL( GetObjectVar( pObject, "STYLE" ) );

   temp = GetObjectVar( pObject, "OPARENT" );
   handle = ( GObject * ) HB_GETHANDLE( GetObjectVar( temp, "HANDLE" ) );

   hbox = gtk_hbox_new( FALSE, 0 );
   vbox = gtk_vbox_new( FALSE, 0 );

   area = gtk_drawing_area_new();

   gtk_box_pack_start( GTK_BOX( hbox ), vbox, TRUE, TRUE, 0 );
   if( ulStyle & WS_VSCROLL )
   {
      GtkObject *adjV;
      adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      vscroll = gtk_vscrollbar_new( GTK_ADJUSTMENT( adjV ) );
      gtk_box_pack_end( GTK_BOX( hbox ), vscroll, FALSE, FALSE, 0 );

      temp = HB_PUTHANDLE( NULL, adjV );
      SetObjectVar( pObject, "_HSCROLLV", temp );
      hb_itemRelease( temp );

      SetWindowObject( ( GtkWidget * ) adjV, pObject );
      set_signal( ( gpointer ) adjV, "value_changed", WM_VSCROLL, 0, 0 );
   }

   gtk_box_pack_start( GTK_BOX( vbox ), area, TRUE, TRUE, 0 );
   if( ulStyle & WS_HSCROLL )
   {
      GtkObject *adjH;
      adjH = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      hscroll = gtk_hscrollbar_new( GTK_ADJUSTMENT( adjH ) );
      gtk_box_pack_end( GTK_BOX( vbox ), hscroll, FALSE, FALSE, 0 );

      temp = HB_PUTHANDLE( NULL, adjH );
      SetObjectVar( pObject, "_HSCROLLH", temp );
      hb_itemRelease( temp );

      SetWindowObject( ( GtkWidget * ) adjH, pObject );
      set_signal( ( gpointer ) adjH, "value_changed", WM_HSCROLL, 0, 0 );
   }

   box = getFixedBox( handle );
   if( box )
      gtk_fixed_put( box, hbox, nLeft, nTop );
   gtk_widget_set_size_request( hbox, nWidth, nHeight );

   temp = HB_PUTHANDLE( NULL, area );
   SetObjectVar( pObject, "_AREA", temp );
   hb_itemRelease( temp );

   SetWindowObject( area, pObject );
   set_event( ( gpointer ) area, "expose_event", WM_PAINT, 0, 0 );

   GTK_WIDGET_SET_FLAGS( area, GTK_CAN_FOCUS );

   gtk_widget_add_events( area, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK | GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK |
         GDK_POINTER_MOTION_MASK | GDK_SCROLL_MASK );
   g_signal_connect( area, "size-allocate", G_CALLBACK (cb_signal_size), NULL );
   set_event( ( gpointer ) area, "button_press_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "button_release_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "motion_notify_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "key_press_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "key_release_event", 0, 0, 0 );
   set_event( ( gpointer ) area, "scroll_event", 0, 0, 0 );

   // gtk_widget_show_all( hbox );
   all_signal_connect( ( gpointer ) area );

   memset( pted, 0, sizeof( TEDIT ) );

   pted->widget = hbox;
   pted->area = area;
   pted->iInterline = 3;

   pted->pFontsScr =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );
   pted->pFontsPrn =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );

   pted->pattr = ( TEDATTR * ) hb_xgrab( sizeof( TEDATTR ) * TEDATTR_MAX );
   pted->pattrf = ( int * ) hb_xgrab( sizeof( int ) * TEDATTRF_MAX );
   ted_ClearAttr( pted );

   HB_RETHANDLE( pted );
}

HB_FUNC( HCED_GETHANDLE )
{
   HB_RETHANDLE( ( void * ) ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->widget );
}

HB_FUNC( HCED_SETHANDLE )
{
}

HB_FUNC( HCED_RELEASE )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   hb_xfree( pted->pFontsScr );
   hb_xfree( pted->pFontsPrn );
   hb_xfree( pted->pattr );
   hb_xfree( pted->pattrf );
   hb_xfree( pted );
}

HB_FUNC( HCED_CLEARFONTS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->iFontsCurr = 0;
}

HB_FUNC( HCED_ADDFONT )
{
   ted_setfont( ( TEDIT * ) HB_PARHANDLE( 1 ), ( PHWGUI_FONT ) HB_PARHANDLE( 2 ), -1, 0 );
}

HB_FUNC( HCED_SETFONT )
{
   int iFont = hb_parni(3);

   if( iFont > 0 ) iFont --;
   ted_setfont( ( TEDIT * ) HB_PARHANDLE( 1 ), ( PHWGUI_FONT ) HB_PARHANDLE( 2 ), 
         iFont, (HB_ISNIL(4))? 0 : hb_parl(4) );
}

HB_FUNC( HCED_SETCOLOR )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   if( HB_ISNUM(2) )
      pted->fg = (long) hb_parnl(2);
   if( HB_ISNUM(3) )
      pted->bg = (long) hb_parnl(3);
}

HB_FUNC( HCED_CLEARATTR )
{
   ted_ClearAttr( ( ( TEDIT * ) HB_PARHANDLE( 1 ) ) );
}

/*
 * hced_setAttr( ::hEdit, nPos, nLen, nFont, tColor, bColor )
 */
HB_FUNC( HCED_SETATTR )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   int i = hb_parni(3);
   int iFont = hb_parni(4)-1;
   long fg = (long) hb_parnl(5);
   long bg = (long) hb_parnl(6);
   TEDATTR * pattr = pted->pattr + hb_parni(2) - 1;

   for( ; i; i--,pattr++ )
   {
      pattr->fg = fg;
      pattr->bg = bg;
      if( iFont >= 0 )
         pattr->iFont = iFont;
   }
}

HB_FUNC( HCED_ADDATTRFONT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   int i = 0, iFont = hb_parni(2);

   while( i < TEDATTRF_MAX && *( pted->pattrf+i ) )
   {
      if( *( pted->pattrf+i ) == iFont )
         return;
      i ++;
   }
   *( pted->pattrf+i ) = iFont;
}

/*
 * hed_setvscroll( hTEdit, nPos, nPartsInPage, nPages )
 */
HB_FUNC( HCED_SETVSCROLL )
{
   /*
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   SCROLLINFO si = { sizeof(si) };
   int iPages = hb_parni(4);

   si.fMask = SIF_PAGE | SIF_POS | SIF_RANGE | SIF_DISABLENOSCROLL;

   si.nPos  = hb_parni(2);
   si.nPage = hb_parni(3);
   si.nMin  = 0;
   si.nMax  = hb_parni(3) * ( (iPages)? iPages-1:iPages );
        
   SetScrollInfo( pted->handle, SB_VERT, &si, TRUE );
   */
}

HB_FUNC( HCED_SETPAINT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->hDCScr = (HB_ISNIL(2))? NULL : (PHWGUI_HDC) HB_PARHANDLE( 2 );
   pted->hDCPrn = (HB_ISNIL(3))? NULL : (PHWGUI_HDC) HB_PARHANDLE( 3 );

   if( !HB_ISNIL(4) )
      pted->iWidth = hb_parni( 4 );
   if( !HB_ISNIL(5) )
      pted->bWrap = hb_parl( 5 );
   if( !HB_ISNIL(7) )
      pted->iDocWidth = hb_parni( 7 );

   pted->hDCScr->fcolor = pted->fg;
   pted->hDCScr->bcolor = pted->bg;
   pted->fg_curr = pted->fg;
   pted->bg_curr = pted->bg;
   /*
   if( pted->hDCPrn && !HB_ISNIL(6) )
   {
      pted->dKoeff = ( GetDeviceCaps( pted->hDCPrn,HORZRES ) / hb_parnd(6) ) / GetDeviceCaps( pted->hDCPrn,HORZSIZE );
      wrlog( NULL, "%f\r\n", pted->dKoeff );
   }
   */

}

HB_FUNC( HCED_SETWIDTH )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   if( !HB_ISNIL(2) )
      pted->iWidth = hb_parni( 2 );
   if( !HB_ISNIL(3) )
      pted->iDocWidth = hb_parl( 3 );

}

HB_FUNC( HCED_FILLRECT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   int x1 = (HB_ISNIL(2))? 0:hb_parni(2);
   int y1 = hb_parni(3);
   int x2 = (HB_ISNIL(4))? pted->iWidth:hb_parni(4);

   if( !pted->hDCPrn )
   {

      hwg_setcolor( pted->hDCScr->cr, pted->bg );
      pted->bg_curr = pted->bg;
      cairo_rectangle( pted->hDCScr->cr, (gdouble)x1, (gdouble)y1,
            (gdouble)(x2-x1+1), (gdouble)(hb_parni(5)-y1+1) );
      cairo_fill( pted->hDCScr->cr );
   }
}

HB_FUNC( HCED_SHOWCARET )
{
   //ShowCaret( ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
}

HB_FUNC( HCED_HIDECARET )
{
   //HideCaret( ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
}

HB_FUNC( HCED_INITCARET )
{
   /*
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   CreateCaret( pted->handle, (HBITMAP)NULL, 2, pted->pFontsScr->tm.tmHeight );
   ShowCaret( pted->handle );
   SetCaretPos( 0,0 );
   pted->iCaretHeight = pted->pFontsScr->tm.tmHeight;
   InvalidateRect( pted->handle, NULL, 0 );
   */
}

HB_FUNC( HCED_KILLCARET )
{
   /*
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   HideCaret( pted->handle );
   DestroyCaret();
   InvalidateRect( pted->handle, NULL, 0 );
   */
}

HB_FUNC( HCED_GETXCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   hb_retni( pted->ixCaretPos );
}

HB_FUNC( HCED_GETYCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   hb_retni( pted->iyCaretPos );
}

HB_FUNC( HCED_GETCARETHEIGHT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   hb_retni( pted->iCaretHeight );
}

HB_FUNC( HCED_SETCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->ixCaretPos = hb_parni(2);
   pted->iyCaretPos = hb_parni(3);
   //SetCaretPos( pted->ixCaretPos, pted->iyCaretPos );
}

/*
 * hced_ExactCaretPos( ::hEdit, cLine, x1, xPos, y1, bSet, nShiftL )
 */
HB_FUNC( HCED_EXACTCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   char * szText = (char*)hb_parc(2), *ptr;
   int x1 = hb_parni(3);
   int xpos = hb_parni(4);
   int y1 = hb_parni(5);
   HB_BOOL bSet = (HB_ISNIL(6))? 1 : hb_parl(6);
   int i, j, lasti, iReqLen, iRealLen, iPrinted = 0, iTextWidth;
   int iLen = g_utf8_strlen( szText, hb_parclen(2) );
   TEDATTR *pattr = pted->pattr;
   cairo_t *cr;
   PangoLayout * layout;
   PangoRectangle rc;

   if( iLen > 0 )
   {
      cr = gdk_cairo_create( pted->area->window );
      layout = pango_cairo_create_layout( cr );

      if( xpos < 0 )
         xpos = pted->iWidth + 1;
      if( xpos < x1 )
         xpos = x1;
      //wrlog( NULL, "---" );
      for( i = 0, lasti = 0; i <= iLen; i++ )
      {
         if( i == iLen || ( pattr + i )->iFont != ( pattr + lasti )->iFont )
         {
            iReqLen = i - lasti;
            ptr = szText + hced_utf8bytes( szText, lasti );
            iRealLen = iReqLen;

            x1 += ted_CalcItemWidth( layout, ptr, 
                  pted->pFontsScr + (pattr + lasti)->iFont, &iRealLen,
                  xpos - x1, 0, lasti );

            j = iRealLen - 1;
            while( j >= 0 && *( ptr+hced_utf8bytes(ptr,j) ) == ' ' )
            {
               j --; x1 += (pted->pFontsScr + (pattr + iPrinted)->iFont)->iSpace;
            }
            iPrinted += iRealLen;
            if( iRealLen < iReqLen )
               break;
            lasti = i;
         }
      }
      if( xpos <= pted->iWidth )
         if( *(szText+iPrinted) )
         {
            ptr = szText + hced_utf8bytes( szText,iPrinted );
            pango_layout_set_text( layout, ptr, hced_utf8bytes( ptr,1 ) );
            pango_layout_get_pixel_extents( layout, &rc, NULL );
            iTextWidth = PANGO_RBEARING(rc) + (pted->pFontsScr + (pattr + iPrinted)->iFont)->ixAdd;
            if( (x1 + iTextWidth - xpos) < ( xpos - x1 ) )
            {
               x1 += iTextWidth;
               iPrinted ++;
               //wrlog( NULL, "3 \r\n" );
            }
         }
      g_object_unref( (GObject*) layout );
      cairo_destroy( cr );
   }

   iPrinted ++;
   if( bSet )
   {
      x1 -= ( HB_ISNIL(7)? 0 : hb_parni(7) );
      pted->ixCaretPos = x1;
      pted->iyCaretPos = y1;
      // wrlog( NULL, "x = %u y = %u\r\n", x1, y1 );
   }
   
   //wrlog( NULL, "End iPrinted = %u \r\n", iPrinted );
   hb_retni( iPrinted );

}

HB_FUNC( HCED_INVALIDATERECT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   GtkWidget * widget = pted->area;
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

HB_FUNC( HCED_SETFOCUS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   gtk_widget_grab_focus( (GtkWidget*) pted->area );
}


/*
 * hced_LineOut( ::hEdit, @x1, @yPos, @x2, cLine, Len(cLine), nAlign, lPaint )
 */
HB_FUNC( HCED_LINEOUT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   TEDFONT *font;
   char *szText = ( char * )hb_parc( 5 );
   HB_BOOL bCalcOnly = (HB_ISNIL(8))? 0 : hb_parl(8);
   short int bCalc = (HB_ISNIL(9))? 1 : hb_parl(9);
   int x1 = hb_parni( 2 ), ypos = hb_parni( 3 ), x2 = hb_parni( 4 ), iLen = hb_parni( 6 );
   int iPrinted, iCalculated = 0, iAlign = hb_parni( 7 );
   int iRealWidth, i, iFont;
   int iHeight = 0;

   pango_layout_set_alignment( pted->hDCScr->layout, PANGO_ALIGN_LEFT );
   if( iLen )
   {
      if( bCalc )
      {
         if( pted->iDocWidth )
         {
            iPrinted = ted_CalcLineWidth( pted, szText, iLen, pted->iDocWidth-x1, &iRealWidth, pted->bWrap );
            //hwg_writelog( NULL, "iWidth: %d iDocWidth: %d iRealWidth %d iPrinted %d \r\n", x2, pted->iDocWidth, iRealWidth, iPrinted );
            //iPrinted = ted_CalcLineWidth( pted, szText, iCalculated, x2-x1, &iRealWidth, 0 );
         }
         else
            iPrinted = ted_CalcLineWidth( pted, szText, iLen, x2-x1, &iRealWidth, pted->bWrap );
      }
      else
         iPrinted = ted_CalcLineWidth( pted, szText, iLen, 30000, &iRealWidth, 0 );
   }
   else
      iPrinted = iRealWidth = 0;

   if( iAlign )
   {
      if( iAlign == 1 )
         x1 += (x2 - x1 - iRealWidth) / 2;
      else if( iAlign == 2 )
         x1 += x2 - x1 - iRealWidth;
   }
   pted->x1 = x1;
   pted->x2 = x1 + iRealWidth;

   i = 0;
   while( i < TEDATTRF_MAX )
   {
      iFont = *( pted->pattrf + i );
      font = ( (pted->hDCPrn)? pted->pFontsPrn : pted->pFontsScr ) + 
            (iFont? iFont-1 : 0) ;
      iHeight = ( iHeight > font->iHeight )? iHeight : font->iHeight;
      if( ! *( pted->pattrf+i ) )
         break;
      i ++;
   }

   /*
   for( i = 0, lasti = 0; i <= iPrinted; i++ )
      if( i == iPrinted || ( pattr + i )->iFont != ( pattr + lasti )->iFont )
      {
         font = ( (pted->hDCPrn)? pted->pFontsPrn : pted->pFontsScr ) + 
               ( pattr + lasti )->iFont;
         iHeight = ( iHeight > font->iHeight )? iHeight : font->iHeight;
         lasti = i;
      }
   */
   //hwg_writelog( NULL, "ypos: %d iHeight: %d iLen %d iPrinted %d bCalc %d\r\n", ypos, iHeight, iLen, iPrinted, bCalc );
   if( !bCalcOnly )
   {
      pted->x2 = ted_LineOut( pted, x1, ypos, szText, iPrinted, iHeight );
   }

   hb_storni( pted->x1, 2 );
   hb_storni( pted->x2, 4 );
   pted->ypos = ypos + iHeight + pted->iInterline;
   hb_storni( pted->ypos, 3 );
   hb_retni( (iCalculated)? iCalculated : iPrinted );
}

HB_FUNC( HCED_COLOR2X )
{
   char s[8];
   int i;
   long int n = hb_parnl(1);

   sprintf(s,"#%2X%2X%2X", (unsigned int)(n%256), (unsigned int)((n/256)%256), (unsigned int)((n/65536)%256) );
   for( i=0; i<7; i++ )
      if( s[i] == ' ' )
         s[i] = '0';
   hb_retclen( s,7 );
}

HB_FUNC( HCED_X2COLOR )
{
   int i1, i2, i3;

   sscanf( hb_parc(1),"#%2X%2X%2X", &i1, &i2, &i3 );
   hb_retnl( i3*65536 + i2*256 + i1 );
}
