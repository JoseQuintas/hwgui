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
   PHWGUI_HDC           hDCScr;
   PHWGUI_HDC           hDCPrn;
   double        dKoeff;
   int           iWidth;
   int       iInterline;
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
#define  TEDATTR_MAX     256

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
extern GtkFixed *getFixedBox( GObject * handle );

char * szDelimiters = " .,-";

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
 * ted_CalcSize() returns the text width in pixels, 
 * writes to the 4 parameter (iRealLen) the width in chars
 */

int ted_CalcSize( PangoLayout * layout, char *szText, TEDFONT *font, int *iRealLen,
      int iWidth, HB_BOOL bWrap, HB_BOOL bLastInFew )
{
   int i, i1, iReal, xpos, iTextWidth;
   PangoRectangle rc;

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
      wrlog( NULL, "iWidth = %d iHeight= %d \r\n",font->iWidth,font->iHeight );
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
            i1 = i;
            while( i > 0 && !strchr( szDelimiters,*(szText+i) ) ) i --;
            if( !i && bLastInFew )
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
         while( i && !strchr( szDelimiters,*(szText+i) ) &&
               !strchr( szDelimiters,*(szText+i-1) ) ) i --;
         if( i || bLastInFew )
            i1 = i;
      }
      for( i = iReal + 1; i <= *iRealLen; i++ )
      {
         if( bWrap )
         {
            while( i < *iRealLen && !strchr( szDelimiters,*(szText+i) ) ) i ++;
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
   pango_layout_get_pixel_extents( hDC->layout, &rc, NULL );
   iWidth = PANGO_RBEARING(rc) + font->ixAdd;
   // Wrap mode off
   pango_layout_set_width( hDC->layout, -1 );

   if( hDC->bcolor != -1 )
   {
      hwg_setcolor( hDC->cr, hDC->bcolor );
      cairo_rectangle( hDC->cr, (gdouble)xpos, (gdouble)ypos-pted->iInterline/2, 
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

int ted_LineOut( TEDIT * pted, int x1, int ypos, int x2, char *szText, int iLen, int iAlign, HB_BOOL bCalcOnly )
{
   TEDATTR *pattr = pted->pattr;
   int i, lasti, iReqLen, iRealLen, iPrinted = 0, iRealWidth = 0, iSegs;
   int iHeight = 0, iMaxAscent = 0;
   TEDFONT *font;
   char * ptr;

   //wrlog( NULL, "Lineout-1\r\n" );
   pango_layout_set_alignment( pted->hDCScr->layout, PANGO_ALIGN_LEFT );
   for( i = 0, lasti = 0, iSegs = 0; i <= iLen; i++, iSegs++ )
   {
      // if the colour or font changes, then need to output 
      if( i == iLen ||
            ( pattr + i )->fg != ( pattr + lasti )->fg ||
            ( pattr + i )->bg != ( pattr + lasti )->bg ||
            ( pattr + i )->iFont != ( pattr + lasti )->iFont )
      {
         font = ( (pted->hDCPrn)? pted->pFontsPrn : pted->pFontsScr ) + 
               ( pattr + lasti )->iFont;

         iReqLen = i - lasti;
         ptr = szText + hced_utf8bytes( szText, lasti );
         while( ptr > szText && *(g_utf8_prev_char(ptr)) == ' ' )
         {
            ptr --; iReqLen ++;
         }
         iRealLen = iReqLen;
         iRealWidth += ted_CalcSize( pted->hDCScr->layout, ptr,
               pted->pFontsScr + (pattr + lasti)->iFont, &iRealLen,
               x2 - iRealWidth - x1, pted->bWrap, i == iLen && iSegs );
         iHeight = ( iHeight > font->iHeight )? iHeight : font->iHeight;
         //iMaxAscent = max( iMaxAscent, font->tm.tmAscent );

         iPrinted += iRealLen;
         if( iRealLen < iReqLen )
            break;
         lasti = i;
      }
   }
   //wrlog( NULL, "Lineout-2\r\n" );
   if( !bCalcOnly )
   {
      if( iAlign )
      {
         if( iAlign == 1 )
            x1 += (x2 - x1 - iRealWidth) / 2;
         else if( iAlign == 2 )
            x1 += x2 - x1 - iRealWidth;
      }
      pted->x1 = x1;
      if( pted->hDCPrn )
         x1 = (int) ( x1 * pted->dKoeff );
      for( i = 0, lasti = 0; i <= iLen; i++ )
      {
         // if the colour or font changes, then need to output 
         if( i == iLen ||
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
      pted->x2 = x1;
      /*
      if( !pted->hDCPrn )
      {
         SetRect( &rect, x1, ypos, pted->iWidth, ypos + iHeight );
         if( pted->bg != pted->bg_curr )
         {
            SetBkColor( pted->hDCScr, pted->bg );
            pted->bg_curr = pted->bg;
         }
         ExtTextOut( pted->hDCScr, 0, 0, ETO_OPAQUE, &rect, 0, 0, 0 );
      }
      */
      if( pted->iyCaretPos == ypos )
      {
         cairo_move_to( pted->hDCScr->cr, (gdouble)pted->ixCaretPos, (gdouble)pted->iyCaretPos );
         cairo_line_to( pted->hDCScr->cr, (gdouble)pted->ixCaretPos, (gdouble)pted->iyCaretPos+iHeight );
         cairo_stroke( pted->hDCScr->cr );
      }
   }
   pted->ypos = ypos + iHeight + pted->iInterline;
   return iPrinted;
}

void ted_ClearAttr( TEDATTR * pattr )
{
   memset( pattr, 0, sizeof( TEDATTR ) * TEDATTR_MAX );
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
   pted->iInterline = 2;

   pted->pFontsScr =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );
   pted->pFontsPrn =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );

   pted->pattr = ( TEDATTR * ) hb_xgrab( sizeof( TEDATTR ) * TEDATTR_MAX );
   ted_ClearAttr( pted->pattr );

   HB_RETHANDLE( pted );
}

HB_FUNC( HCED_GETHANDLE )
{
   HB_RETHANDLE( ( void * ) ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->widget );
}

HB_FUNC( HCED_RELEASE )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   hb_xfree( pted->pFontsScr );
   hb_xfree( pted->pFontsPrn );
   hb_xfree( pted->pattr );
   hb_xfree( pted );
}

HB_FUNC( HCED_CLEARFONTS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->iFontsCurr = 0;
}

HB_FUNC( HCED_ADDFONT )
{
   //TEDFONT * pFont = 
   ted_setfont( ( TEDIT * ) HB_PARHANDLE( 1 ), ( PHWGUI_FONT ) HB_PARHANDLE( 2 ), -1, 0 );
   hb_retni( 16 ); // pFont->tm.tmHeight + pFont->tm.tmExternalLeading );
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
   ted_ClearAttr( ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->pattr );
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

HB_FUNC( HCED_SETCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->ixCaretPos = hb_parni(2);
   pted->iyCaretPos = hb_parni(3);
   //SetCaretPos( pted->ixCaretPos, pted->iyCaretPos );
}

/*
 * hced_ExactCaretPos( ::hEdit, cLine, x1, xPos, y1, bSet )
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
            //wrlog( NULL, "0 lasti = %u diff = %u i = %u iReal = %u ", lasti, ptr-szText, i, iReqLen );
            /*
            while( ptr > szText && *(g_utf8_prev_char(ptr)) == ' ' )
            {
               wrlog( NULL, " ++ " );
               ptr --; iReqLen ++;
            }
            */
            iRealLen = iReqLen;
            wrlog( NULL, "1 iReal = %u ", iRealLen );
            x1 += ted_CalcSize( layout, ptr, 
                  pted->pFontsScr + (pattr + lasti)->iFont, &iRealLen,
                  xpos - x1, 0, i == iLen );
            //wrlog( NULL, "2 iReal = %u \r\n", iRealLen );
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

/*
 * hced_LineOut( ::hEdit, @x1, @yPos, @x2, cLine, Len(cLine), nAlign, lPaint )
 */
HB_FUNC( HCED_LINEOUT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   HB_BOOL bCalcOnly = (HB_ISNIL(8))? 0 : hb_parl(8);

   hb_retni( ted_LineOut( pted, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ),
         (char*)hb_parc( 5 ), hb_parni( 6 ), hb_parni(7), bCalcOnly ) );
   if( !bCalcOnly )
   {
      hb_storni( pted->x1, 2 );
      hb_storni( pted->x2, 4 );
   }
   hb_storni( pted->ypos, 3 );
}
