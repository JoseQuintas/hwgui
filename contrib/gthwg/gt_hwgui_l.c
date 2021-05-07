/*
 * $Id$
 * GTHWGUI, Video subsystem, based on HwGUI ( GTK Linux version )
 *
 * Copyright 2021 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "hbgtcore.h"
#include "hbinit.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbdate.h"
#include "guilib.h"

#include "gt_hwg.ch"

#include <cairo.h>
#include "gtk/gtk.h"
#include "gdk/gdkkeysyms.h"
#include "hwgtk.h"

#include "windows.ch"

typedef unsigned long       DWORD;
typedef int                 BOOL;
typedef unsigned char       BYTE;
typedef unsigned short      WORD;
typedef unsigned int        UINT;

extern gint cb_signal_size( GtkWidget *widget, GtkAllocation *allocation, gpointer data );
extern void hwg_doEvents( void );
extern void hwg_setcolor( cairo_t * cr, long int nColor );

#define UNICODE

#define HWND          GtkWidget*
#define HFONT         PHWGUI_FONT
#define TCHAR         char
#define COLORREF      long int
#define LONG          long int
#define OEM_CHARSET   255

#define RGB(r,g,b)    ((COLORREF)(((BYTE)(r)|((WORD)((BYTE)(g))<<8))|(((DWORD)(BYTE)(b))<<16)))

typedef struct tagRECT
{
    gint    left;
    gint    top;
    gint    right;
    gint    bottom;
} RECT, *PRECT, *LPRECT;

typedef struct tagPOINT
{
    gint    x;
    gint    y;
} POINT;

extern GtkFixed *getFixedBox( GObject * handle );

#define HWG_DEFAULT_FONT_NAME  "Liberation Mono"
#define HB_GT_NAME            HWGUI
#define HWG_DEFAULT_ROWS         25
#define HWG_DEFAULT_COLS         80
#define HWG_DEFAULT_FONT_HEIGHT  20
#define HWG_DEFAULT_FONT_WIDTH   10
#define HWG_DEFAULT_FONT_ATTR     0

#define BLACK            RGB( 0x00, 0x00, 0x00 )
#define BLUE             RGB( 0x00, 0x00, 0xAA )
#define GREEN            RGB( 0x00, 0xAA, 0x00 )
#define CYAN             RGB( 0x00, 0xAA, 0xAA )
#define RED              RGB( 0xAA, 0x00, 0x00 )
#define MAGENTA          RGB( 0xAA, 0x00, 0xAA )
#define BROWN            RGB( 0xAA, 0x55, 0x00 )
#define LIGHT_GRAY       RGB( 0xAA, 0xAA, 0xAA )
#define GRAY             RGB( 0x55, 0x55, 0x55 )
#define BRIGHT_BLUE      RGB( 0x55, 0x55, 0xFF )
#define BRIGHT_GREEN     RGB( 0x55, 0xFF, 0x55 )
#define BRIGHT_CYAN      RGB( 0x55, 0xFF, 0xFF )
#define BRIGHT_RED       RGB( 0xFF, 0x55, 0x55 )
#define BRIGHT_MAGENTA   RGB( 0xFF, 0x55, 0xFF )
#define YELLOW           RGB( 0xFF, 0xFF, 0x55 )
#define WHITE            RGB( 0xFF, 0xFF, 0xFF )

#define AKEYS_LEN            128

typedef struct
{
   PHB_GT   pGT;            /* core GT pointer */
   HWND     hWnd;

   int      fontHeight;     /* requested font height */
   int      fontWidth;      /* requested font width */
   int      fontWeight;     /* Bold level */
   int      fontQuality;    /* requested font quality */
   int      fontAttribute;  /* font attribute: HB_GTI_FONTA_* */
   TCHAR    fontFace[ 48 ]; /* requested font face name LF_FACESIZE #defined in wingdi.h */
   HFONT    hFont;

   POINT    PTEXTSIZE;      /* size of the fixed width font */
   HB_BOOL  FixedFont;      /* HB_TRUE if current font is a fixed font */
   int      MarginTop;
   int      MarginLeft;

   int      Keys[ 128 ];    /* Array to hold the characters & events */
   int      keyPointerIn;   /* Offset into key array for character to be placed */
   int      keyPointerOut;  /* Offset into key array of next character to read */
   int      keyLastPos;     /* last inkey code position in buffer */
   int      keyFlags;       /* keyboard modifiers */

   int      ROWS;           /* number of displayable rows in window */
   int      COLS;           /* number of displayable columns in window */
   char *   TextLine;
   COLORREF COLORS[ 16 ];   /* colors */

   HB_BOOL  CaretExist;     /* HB_TRUE if a caret has been created */
   HB_BOOL  CaretHidden;    /* HB_TRUE if a caret has been hiden */
   int      CaretSize;      /* Height of solid caret */
   int      CaretWidth;     /* Width of solid caret */
   int      CaretRow, CaretCol;

   POINT    MousePos;       /* the last mouse position */

   int      CodePage;       /* Code page to use for display characters */

   int      CloseMode;
   HB_BOOL  IgnoreWM_SYSCHAR;

} HB_GTHWG, * PHB_GTHWG;

extern void hwg_writelog( const char * sFile, const char * sTraceMsg, ... );

static PHB_GTHWG pHWGMain = NULL;
static HWND hWndMain = NULL;
static HWND hPaneMain = NULL;
static HFONT hFontMain = NULL;

static int iNewPosX = -1, iNewPosY = -1;
static HB_MAXUINT iCaretMs = 0;
static int bCaretShow = 0;

static int s_GtId;
static HB_GT_FUNCS SuperTable;

#define HB_GTSUPER   ( &SuperTable )
#define HB_GTID_PTR  ( &s_GtId )

static PHB_DYNS pSym_onEvent = NULL;

static HB_LONG prevp2 = -1;

static void gthwg_GetWindowRect( GtkWidget* hWnd, LPRECT lpRect )
{
   GtkAllocation alloc;
   gtk_widget_get_allocation( hWnd, &alloc );
   lpRect->left = alloc.x;
   lpRect->top = alloc.y;
   lpRect->right = alloc.width;
   lpRect->bottom = alloc.height;
}

static void gthwg_GetClientRect( GtkWidget* hWnd, LPRECT lpRect )
{
   GtkAllocation alloc;

   if( getFixedBox( (GObject *) hWnd ) )
      gtk_widget_get_allocation( (GtkWidget*) getFixedBox( (GObject *) hWnd ), &alloc );
   else
      gtk_widget_get_allocation( hWnd, &alloc );

   lpRect->left = alloc.x;
   lpRect->top = alloc.y;
   lpRect->right = alloc.width;
   lpRect->bottom = alloc.height;
}

static void gthwg_SetWindowPos( GtkWidget* hWnd, int left, int top, int width, int height, unsigned int uiFlags )
{
   //gtk_window_move( GTK_WINDOW(hWnd), left, top );
   if( !(uiFlags & SWP_NOSIZE) )
   {
      RECT rc;
      gthwg_GetWindowRect( hPaneMain, &rc );

      if( rc.right > width )
      {
         gtk_widget_set_size_request( hPaneMain, width, rc.bottom );
         gtk_window_resize( GTK_WINDOW( hWndMain ), width+2, rc.bottom + 2 );
      }
      else if( width > rc.right )
      {
         gtk_window_resize( GTK_WINDOW( hWndMain ), width+2, rc.bottom + 2 );
         gtk_widget_set_size_request( hPaneMain, width, rc.bottom );
      }
      if( rc.bottom > height )
      {
         gtk_widget_set_size_request( hPaneMain, width, height );
         gtk_window_resize( GTK_WINDOW( hWndMain ), width+2, height + 2 );
      }
      else if( height > rc.bottom )
      {
         gtk_window_resize( GTK_WINDOW( hWndMain ), width+2, height + 2 );
         gtk_widget_set_size_request( hPaneMain, width, height );
      }
      //gtk_window_resize( GTK_WINDOW( hWndMain ), width+8, height+20 );
      //gtk_widget_set_size_request( hPaneMain, width, height );
      //hwg_writelog( NULL, "SetwindowPos %d %d %d %d %d %d\r\n", width, height, rc.left, rc.top, rc.right, rc.bottom );
   }
}

static int gthwg_GetDesktopWidth( void )
{
   return gdk_screen_width();
}

static int gthwg_GetDesktopHeight( void )
{
   return gdk_screen_height();
}

static void gthwg_InvalidateRect( GtkWidget* hWnd, LPRECT lpRect, int b )
{
   gtk_widget_queue_draw_area( hWnd, lpRect->left, lpRect->top,
      lpRect->right - lpRect->left + 1, lpRect->bottom - lpRect->top + 1 );
}

static void gthwg_CalcFontSize( PHWGUI_HDC hdc, PangoFontDescription * hFont, int * pWidth, int * pHeight, int bm )
{
   if( !hdc->cr )
   {
      *pWidth = *pHeight = -1;
      return;
   }
   if( bm )
   {
      PangoContext * context;
      PangoFontMetrics * metrics;

      context = pango_layout_get_context( hdc->layout );
      metrics = pango_context_get_metrics( context, hFont, NULL );

      *pHeight = ( pango_font_metrics_get_ascent( metrics ) +
         pango_font_metrics_get_descent( metrics ) ) / PANGO_SCALE;
      *pWidth = pango_font_metrics_get_approximate_char_width(metrics) / PANGO_SCALE;

      pango_font_metrics_unref( metrics );
   }
   else
   {
      PangoRectangle rc;

      pango_layout_set_font_description( hdc->layout, hFont );
      pango_layout_set_text( hdc->layout, "gA", 2 );
      pango_layout_get_pixel_extents( hdc->layout, &rc, NULL );
      *pWidth = rc.width/2;
      *pHeight = PANGO_DESCENT( rc );
   }
}

static HFONT gthwg_GetFont( char * lpFace, int iHeight, int iWidth, int iWeight, int iQuality, int iCodePage )
{
   PangoFontDescription *  hFont;
   PHWGUI_FONT h;
   HWGUI_HDC hdc;
   int width, height, ih = iHeight;

   ih -= 2;
   hdc.window = gtk_widget_get_window( hPaneMain );
   hdc.cr = gdk_cairo_create( hdc.window );
   if( !hdc.cr )
      return NULL;
   hdc.layout = pango_cairo_create_layout( hdc.cr );

   hFont = pango_font_description_new();
   pango_font_description_set_family( hFont, lpFace );
   do {
      ih -= 1;
      pango_font_description_set_size( hFont, ih*1024 );
      gthwg_CalcFontSize( &hdc, hFont, &width, &height, 0 );
   } while( ih > 3 && (height > iHeight || width > iWidth) );

   g_object_unref( hdc.layout );
   cairo_destroy( hdc.cr );

   //pango_font_description_set_stretch( hFont, PANGO_STRETCH_CONDENSED );
   //if( iWeight )
   //   pango_font_description_set_weight( hFont, iWeight );

   h = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );
   h->type = HWGUI_OBJECT_FONT;
   h->hFont = hFont;
   h->attrs = NULL;

   return h;
}

static HB_BOOL gthwg_SetMousePos( PHB_GTHWG pHWG, int iRow, int iCol )
{
   if( pHWG->MousePos.y != iRow || pHWG->MousePos.x != iCol )
   {
      pHWG->MousePos.y = iRow;
      pHWG->MousePos.x = iCol;
      return HB_TRUE;
   }
   else
      return HB_FALSE;
}

static void gthwg_ResetWindowSize( PHB_GTHWG pHWG )
{
   RECT  wi, ci;
   int   height = -1, width = -1;

   if( pHWG->hFont )
   {
      HWGUI_HDC hdc;
      hdc.window = gtk_widget_get_window( hPaneMain );
      hdc.cr = gdk_cairo_create( hdc.window );
      hdc.layout = pango_cairo_create_layout( hdc.cr );

      gthwg_CalcFontSize( &hdc, pHWG->hFont->hFont, &width, &height, 0 );
      pHWG->PTEXTSIZE.x = width;
      pHWG->PTEXTSIZE.y = height;

      g_object_unref( hdc.layout );
      cairo_destroy( hdc.cr );
   }
   //hwg_writelog( NULL, "ResetSize-1 %d %d\r\n", width, height );

   pHWG->FixedFont =  1;

   gthwg_GetWindowRect( pHWG->hWnd, &wi );
   //gthwg_GetClientRect( pHWG->hWnd, &ci );

   height = ( int ) ( pHWG->PTEXTSIZE.y * pHWG->ROWS );
   width  = ( int ) ( pHWG->PTEXTSIZE.x * pHWG->COLS );

   //width  += ( int ) ( wi.right - wi.left - ci.right );
   //height += ( int ) ( wi.bottom - wi.top - ci.bottom );

   //hwg_writelog( NULL, "_resetsize-2 %d %d %d %d\r\n", pHWG->fontHeight, pHWG->PTEXTSIZE.y, pHWG->PTEXTSIZE.x, height );
   /* Will resize window without moving left/top origin */
   gthwg_SetWindowPos( pHWG->hWnd, wi.left, wi.top, width, height, SWP_NOZORDER );
   //hwg_writelog( NULL, "ResetSize-10\r\n" );
}

static HB_BOOL gthwg_SetWindowSize( PHB_GTHWG pHWG, int iRows, int iCols )
{
   if( HB_GTSELF_RESIZE( pHWG->pGT, iRows, iCols ) )
   {
      if( pHWG->COLS != iCols )
      {
         pHWG->TextLine = ( char* ) hb_xrealloc( pHWG->TextLine,
                                                   iCols * sizeof( char ) );
      }

      pHWG->ROWS = iRows;
      pHWG->COLS = iCols;
      //hwg_writelog( NULL, "SetwindowSize %d %d\r\n", iCols, iRows );
      return HB_TRUE;
   }

   return HB_FALSE;
}

static void gthwg_AddCharToInputQueue( PHB_GTHWG pHWG, int iKey )
{
   int iPos = pHWG->keyPointerIn;

   if( pHWG->keyPointerIn != pHWG->keyPointerOut &&
       HB_INKEY_ISMOUSEPOS( iKey ) )
   {
      int iLastKey = pHWG->Keys[ pHWG->keyLastPos ];
      if( HB_INKEY_ISMOUSEPOS( iLastKey ) )
      {
         pHWG->Keys[ pHWG->keyLastPos ] = iKey;
         return;
      }
   }

   /*
    * When the buffer is full new event overwrite the last one
    * in the buffer - it's Clipper behavior, [druzus]
    */
   pHWG->Keys[ pHWG->keyLastPos = iPos ] = iKey;
   if( ++iPos >= AKEYS_LEN )
      iPos = 0;
   if( iPos != pHWG->keyPointerOut )
      pHWG->keyPointerIn = iPos;
}

static HB_BOOL gthwg_GetCharFromInputQueue( PHB_GTHWG pHWG, int * iKey )
{
   if( pHWG->keyPointerOut != pHWG->keyPointerIn )
   {
      *iKey = pHWG->Keys[ pHWG->keyPointerOut ];
      if( ++pHWG->keyPointerOut >= AKEYS_LEN )
         pHWG->keyPointerOut = 0;

      return HB_TRUE;
   }

   *iKey = 0;
   return HB_FALSE;
}

static POINT gthwg_GetXYFromColRow( PHB_GTHWG pHWG, int col, int row )
{
   POINT xy;

   xy.x = col * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
   xy.y = row * pHWG->PTEXTSIZE.y + pHWG->MarginTop;

   return xy;
}

static RECT gthwg_GetXYFromColRowRect( PHB_GTHWG pHWG, RECT colrow )
{
   RECT xy;

   xy.left   = colrow.left * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
   xy.top    = colrow.top  * pHWG->PTEXTSIZE.y + pHWG->MarginTop;
   xy.right  = ( colrow.right  + 1 ) * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
   xy.bottom = ( colrow.bottom + 1 ) * pHWG->PTEXTSIZE.y + pHWG->MarginTop;

   return xy;
}

/*
 * get the row and column from xy pixel client coordinates
 * This works because we are using the FIXED system font
 */
static POINT gthwg_GetColRowFromXY( PHB_GTHWG pHWG, LONG x, LONG y )
{
   POINT colrow;

   colrow.x = ( x - pHWG->MarginLeft ) / pHWG->PTEXTSIZE.x;
   colrow.y = ( y - pHWG->MarginTop ) / pHWG->PTEXTSIZE.y;

   return colrow;
}

static void cb_signal( GtkWidget *widget,gchar* data )
{
   gpointer gObject;
   HB_LONG p1, p2, p3;

   sscanf( (char*)data,"%ld %ld %ld",&p1,&p2,&p3 );
   if( !p1 )
   {
      p1 = 273;
      if( p3 )
         widget = (GtkWidget*) p3;
      else
         widget = hWndMain;
      p3 = 0;
   }

   gObject = g_object_get_data( (GObject*) widget, "obj" );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && gObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( ( PHB_ITEM ) gObject );
      hb_vmPushLong( p1 );
      hb_vmPushLong( p2 );
      hb_vmPushLong( (HB_LONG) p3 );
      hb_vmSend( 3 );
   }
}

static void gthwg_set_signal( gpointer hWnd, char * cSignal, int p1 )
{
   char buf[20]={0};

   sprintf( buf,"%d 0 0", p1 );
   g_signal_connect( hWnd, cSignal, G_CALLBACK (cb_signal), g_strdup(buf) );
}

static void gthwg_TextOut( PHB_GTHWG pHWG, PHWGUI_HDC hdc, int col, int row, int iColor,  char * szText, UINT uiLen, int bCursor )
{
   UINT  x1, y1, x2, y2;

   //hwg_writelog( NULL, "_TextOut-1\r\n" );

   x1 = col * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
   y1 = row * pHWG->PTEXTSIZE.y + pHWG->MarginTop;
   x2 = x1 + uiLen * pHWG->PTEXTSIZE.x;
   y2 = y1 + pHWG->PTEXTSIZE.y;

   //hwg_writelog( NULL, "TextOut-1 %c%c%c%c %d\r\n", szText[0],szText[1],szText[2],szText[3], uiLen );
   if( !(uiLen == 1) || *szText != ' ' )
   {
      pango_layout_set_text( hdc->layout, szText, -1 ); //uiLen );
      pango_layout_set_width( hdc->layout, (x2-x1)*PANGO_SCALE );
      pango_layout_set_justify( hdc->layout, 1 );
   }

   /* set background color */
   hwg_setcolor( hdc->cr, pHWG->COLORS[ ( iColor >> 4 ) & 0x0F ] );
   cairo_rectangle( hdc->cr, (gdouble)x1, (gdouble)y1, (gdouble)(x2-x1+1), (gdouble)(y2-y1) );
   cairo_fill( hdc->cr );

   /* set foreground color */
   hwg_setcolor( hdc->cr, pHWG->COLORS[ iColor & 0x0F ] );
   if( !(uiLen == 1) || *szText != ' ' )
   {
      cairo_move_to( hdc->cr, (gdouble)x1, (gdouble)y1 );
      pango_cairo_show_layout( hdc->cr, hdc->layout );
   }
   if( bCursor >= 0 )
   {
      if( bCaretShow )
      {
         x1 = bCursor * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
         x2 = x1 + pHWG->PTEXTSIZE.x;
         //hwg_writelog( NULL, "TextOut-draw cursor %lu\r\n", iCaretMs );
         if( HB_GTSELF_GETCURSORSTYLE( pHWG->pGT ) != SC_NONE )
         {
            cairo_rectangle( hdc->cr, (gdouble)x1+1, (gdouble)y2-2, (gdouble)(x2-x1-1), (gdouble)2 );
            cairo_stroke( hdc->cr );
         }
      }
   }
}

/*
static void gthwg_PaintText( PHB_GTHWG pHWG, GdkRectangle *pArea )
{
   HWGUI_HDC   hdc;
   int         iRow;
   int         iColor, iOldColor = 0;
   int iRowCurs, iColCurs, iStyle, bCursor = -1;
   GdkRectangle area;
   HB_BYTE     bAttr;
   GtkAllocation alloc;
   PHB_CODEPAGE cdp = hb_vmCDP();

   memset( &hdc, 0, sizeof(HWGUI_HDC) );
   hdc.widget = hPaneMain;
   hdc.window = gtk_widget_get_window( hPaneMain );
   hdc.cr = gdk_cairo_create( hdc.window );
   hdc.layout = pango_cairo_create_layout( hdc.cr );
   hdc.fcolor = hdc.bcolor = -1;

   gtk_widget_get_allocation( hPaneMain, &alloc );
   area.x = pArea->x / pHWG->PTEXTSIZE.x;
   area.y = pArea->y / pHWG->PTEXTSIZE.y;
   area.width = pArea->width / pHWG->PTEXTSIZE.x;
   area.height = pArea->height / pHWG->PTEXTSIZE.y;

   //hwg_writelog( NULL, "_PaintText-1 %d %d %d %s\r\n",(pHWG->hFont)? 1 : 0, alloc.width, alloc.height, hb_cdpID() );

   if( pHWG->hFont )
   {
      hdc.hFont = ((PHWGUI_FONT)(pHWG->hFont))->hFont;
      pango_layout_set_font_description( hdc.layout, hdc.hFont );
   }

   HB_GTSELF_GETSCRCURSOR( pHWG->pGT, &iRowCurs, &iColCurs, &iStyle );
   for( iRow = area.y; iRow <= area.y+area.height; ++iRow )
   {
      int iCol, startCol, len;

      iCol = startCol = area.x;
      len = 0;

      while( iCol < area.x+area.width )
      {
         HB_UCHAR uc;
         if( ! HB_GTSELF_GETSCRUC( pHWG->pGT, iRow, iCol, &iColor, &bAttr, &uc, HB_TRUE ) )
            break;
         if( len == 0 )
         {
            iOldColor = iColor;
         }
         else //if( iColor != iOldColor )
         {
            gthwg_TextOut( pHWG, &hdc, startCol, iRow, iOldColor, pHWG->TextLine, ( UINT ) len, bCursor );
            bCursor = -1;
            iOldColor = iColor;
            startCol = iCol;
            len = 0;
         }
         hb_cdpStrToUTF8( cdp, &uc, 1, pHWG->TextLine, 5 );
         len ++;
         //pHWG->TextLine[ len++ ] = ( TCHAR ) uc;
         if( iCol == iColCurs && iRow == iRowCurs )
            bCursor = iCol;
         iCol++;
      }
      if( len > 0 )
         gthwg_TextOut( pHWG, &hdc, startCol, iRow, iOldColor, pHWG->TextLine, ( UINT ) len, bCursor );
   }

   if( hdc.layout )
      g_object_unref( (GObject*) hdc.layout );

   if( hdc.surface )
      cairo_surface_destroy( hdc.surface );
   cairo_destroy( hdc.cr );
   //hwg_writelog( NULL, "_PaintText-10\r\n" );
}
*/

static void gthwg_PaintText( PHB_GTHWG pHWG, GdkRectangle *pArea )
{
   int iRow;
   int iCursorColor, iColor, iOldColor = 0;
   int iRowCurs, iColCurs, iStyle, bCursor = -1;
   GdkRectangle area;
   HB_BYTE     bAttr;
   GtkAllocation alloc;
   PHB_CODEPAGE cdp = hb_vmCDP();
   cairo_t * cr;
   PangoLayout * layout;

   cr = gdk_cairo_create( gtk_widget_get_window( hPaneMain ) );
   if( !cr )
      return;
   layout = pango_cairo_create_layout( cr );

   gtk_widget_get_allocation( hPaneMain, &alloc );
   area.x = pArea->x / pHWG->PTEXTSIZE.x;
   area.y = pArea->y / pHWG->PTEXTSIZE.y;
   area.width = pArea->width / pHWG->PTEXTSIZE.x;
   area.height = pArea->height / pHWG->PTEXTSIZE.y;

   //hwg_writelog( NULL, "_PaintText-1 %d %d %d %s\r\n",(pHWG->hFont)? 1 : 0, alloc.width, alloc.height, hb_cdpID() );

   if( pHWG->hFont )
      pango_layout_set_font_description( layout, ((PHWGUI_FONT)(pHWG->hFont))->hFont );

   HB_GTSELF_GETSCRCURSOR( pHWG->pGT, &iRowCurs, &iColCurs, &iStyle );
   for( iRow = area.y; iRow <= area.y+area.height; ++iRow )
   {
      int iCol, startCol, iLastCol, len;
      UINT  x1, y1, x2, y2;

      y1 = iRow * pHWG->PTEXTSIZE.y + pHWG->MarginTop;
      y2 = y1 + pHWG->PTEXTSIZE.y;

      iCol = startCol = area.x;
      iLastCol = iCol + area.width;
      len = 0;

      while( 1 )
      {
         HB_UCHAR uc;
         char buf[8];
         int i, iCharLen;

         if( iCol < iLastCol )
            if( ! HB_GTSELF_GETSCRUC( pHWG->pGT, iRow, iCol, &iColor, &bAttr, &uc, HB_TRUE ) )
               break;
         if( len == 0 )
            iOldColor = iColor;
         else if( iColor != iOldColor || iCol == iLastCol )
         {
            x1 = startCol * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
            x2 = x1 + (iCol-startCol) * pHWG->PTEXTSIZE.x;
            // draw background
            hwg_setcolor( cr, pHWG->COLORS[ ( iOldColor >> 4 ) & 0x0F ] );
            cairo_rectangle( cr, (gdouble)x1, (gdouble)y1, (gdouble)(x2-x1+1), (gdouble)(y2-y1) );
            cairo_fill( cr );

            // draw text
            hwg_setcolor( cr, pHWG->COLORS[ iOldColor & 0x0F ] );
            pango_layout_set_width( layout, pHWG->PTEXTSIZE.x*PANGO_SCALE );
            pango_layout_set_justify( layout, 1 );
            for( i = 0; i < len; i++ )
            {
               if( *(pHWG->TextLine+i) != ' ' )
               {
                  x1 = (startCol+i) * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
                  iCharLen = hb_cdpStrToUTF8( cdp, (pHWG->TextLine+i), 1, buf, 5 );
                  pango_layout_set_text( layout, buf, iCharLen );
                  cairo_move_to( cr, (gdouble)x1, (gdouble)y1 );
                  pango_cairo_show_layout( cr, layout );
               }
            }
            //hwg_writelog( NULL, "PaintText-2 %d %d %d %d %d\r\n", iRow, startCol, iCol, x1, x2 );
            iOldColor = iColor;
            startCol = iCol;
            len = 0;
         }
         if( iCol == iLastCol )
            break;
         pHWG->TextLine[ len++ ] = ( char ) uc;
         if( iCol == iColCurs && iRow == iRowCurs )
         {
            bCursor = iCol;
            iCursorColor = iColor;
         }
         iCol++;
      }
      if( bCursor >= 0 )
      {
         if( bCaretShow )
         {
            x1 = bCursor * pHWG->PTEXTSIZE.x + pHWG->MarginLeft;
            x2 = x1 + pHWG->PTEXTSIZE.x;
            //hwg_writelog( NULL, "TextOut-draw cursor %lu\r\n", iCaretMs );
            if( HB_GTSELF_GETCURSORSTYLE( pHWG->pGT ) != SC_NONE )
            {
               hwg_setcolor( cr, pHWG->COLORS[ iCursorColor & 0x0F ] );
               cairo_rectangle( cr, (gdouble)x1+1, (gdouble)y2-2, (gdouble)(x2-x1-1), (gdouble)2 );
               cairo_stroke( cr );
            }
         }
         bCursor = -1;
      }
   }

   if( layout )
      g_object_unref( (GObject*) layout );
   cairo_destroy( cr );
   //hwg_writelog( NULL, "_PaintText-10\r\n" );
}

static void gthwg_MouseEvent( int msg, int x, int y )
{
   POINT colrow = gthwg_GetColRowFromXY( pHWGMain, (LONG)x, (LONG)y );

   gthwg_SetMousePos( pHWGMain, colrow.y, colrow.x );

   if( msg == WM_LBUTTONDOWN )
      gthwg_AddCharToInputQueue( pHWGMain, 0x440003ea );
   else if( msg == WM_LBUTTONUP )
      gthwg_AddCharToInputQueue( pHWGMain, 0x440003eb );
   else if( msg == WM_RBUTTONDOWN )
      gthwg_AddCharToInputQueue( pHWGMain, 0x440003ec );
   else if( msg == WM_RBUTTONUP )
      gthwg_AddCharToInputQueue( pHWGMain, 0x440003ed );
   else if( msg == WM_LBUTTONDBLCLK )
      gthwg_AddCharToInputQueue( pHWGMain, 0x440003ee );
}

static HB_LONG ToKey( HB_LONG a,HB_LONG b )
{

   if ( a == GDK_KEY_asciitilde || a == GDK_KEY_dead_tilde)
   {
      if ( b== GDK_KEY_A)
         return (HB_LONG)GDK_KEY_Atilde;
      else if ( b == GDK_KEY_a )
         return (HB_LONG)GDK_KEY_atilde;
      else if ( b== GDK_KEY_N)
         return (HB_LONG)GDK_KEY_Ntilde;
      else if ( b == GDK_KEY_n )
         return (HB_LONG)GDK_KEY_ntilde;
      else if ( b== GDK_KEY_O)
         return (HB_LONG)GDK_KEY_Otilde;
      else if ( b == GDK_KEY_o )
         return (HB_LONG)GDK_KEY_otilde;
   }
   if  ( a == GDK_KEY_asciicircum || a ==GDK_KEY_dead_circumflex)
   {
      if ( b== GDK_KEY_A)
         return (HB_LONG)GDK_KEY_Acircumflex;
      else if ( b == GDK_KEY_a )
         return (HB_LONG)GDK_KEY_acircumflex;
      else if ( b== GDK_KEY_E)
         return (HB_LONG)GDK_KEY_Ecircumflex;
      else if ( b == GDK_KEY_e )
         return (HB_LONG)GDK_KEY_ecircumflex;
      else if ( b== GDK_KEY_I)
         return (HB_LONG)GDK_KEY_Icircumflex;
      else if ( b == GDK_KEY_i )
         return (HB_LONG)GDK_KEY_icircumflex;
      else if ( b== GDK_KEY_O)
         return (HB_LONG)GDK_KEY_Ocircumflex;
      else if ( b == GDK_KEY_o )
         return (HB_LONG)GDK_KEY_ocircumflex;
      else if ( b== GDK_KEY_U)
         return (HB_LONG)GDK_KEY_Ucircumflex;
      else if ( b == GDK_KEY_u )
         return (HB_LONG)GDK_KEY_ucircumflex;
      else if ( b== GDK_KEY_C)
         return (HB_LONG)GDK_KEY_Ccircumflex;
      else if ( b== GDK_KEY_H)
         return (HB_LONG)GDK_KEY_Hcircumflex;
      else if ( b == GDK_KEY_h )
         return (HB_LONG)GDK_KEY_hcircumflex;
      else if ( b== GDK_KEY_J)
         return (HB_LONG)GDK_KEY_Jcircumflex;
      else if ( b == GDK_KEY_j )
         return (HB_LONG)GDK_KEY_jcircumflex;
      else if ( b== GDK_KEY_G)
         return (HB_LONG)GDK_KEY_Gcircumflex;
      else if ( b == GDK_KEY_g )
         return (HB_LONG)GDK_KEY_gcircumflex;
      else if ( b== GDK_KEY_S)
         return (HB_LONG)GDK_KEY_Scircumflex;
      else if ( b == GDK_KEY_s )
         return (HB_LONG)GDK_KEY_scircumflex;
   }

   if ( a == GDK_KEY_grave  || a==GDK_KEY_dead_grave )
   {
      if ( b== GDK_KEY_A)
         return (HB_LONG)GDK_KEY_Agrave;
      else if ( b == GDK_KEY_a )
         return (HB_LONG)GDK_KEY_agrave;
      else if ( b== GDK_KEY_E)
         return (HB_LONG)GDK_KEY_Egrave;
      else if ( b == GDK_KEY_e )
         return (HB_LONG)GDK_KEY_egrave;
      else if ( b== GDK_KEY_I)
         return (HB_LONG)GDK_KEY_Igrave;
      else if ( b == GDK_KEY_i )
         return (HB_LONG)GDK_KEY_igrave;
      else if ( b== GDK_KEY_O)
         return (HB_LONG)GDK_KEY_Ograve;
      else if ( b == GDK_KEY_o )
         return (HB_LONG)GDK_KEY_ograve;
      else if ( b== GDK_KEY_U)
         return (HB_LONG)GDK_KEY_Ugrave;
      else if ( b == GDK_KEY_u )
         return (HB_LONG)GDK_KEY_ugrave;
      else if ( b== GDK_KEY_C)
         return (HB_LONG)GDK_KEY_Ccedilla;
      else if ( b == GDK_KEY_c )
         return (HB_LONG)GDK_KEY_ccedilla ;

   }

   if ( a == GDK_KEY_acute  ||  a == GDK_KEY_dead_acute)
   {
     if ( b== GDK_KEY_A)
         return (HB_LONG)GDK_KEY_Aacute;
      else if ( b == GDK_KEY_a )
         return (HB_LONG)GDK_KEY_aacute;
      else if ( b== GDK_KEY_E)
         return (HB_LONG)GDK_KEY_Eacute;
      else if ( b == GDK_KEY_e )
         return (HB_LONG)GDK_KEY_eacute;
      else if ( b== GDK_KEY_I)
         return (HB_LONG)GDK_KEY_Iacute;
      else if ( b == GDK_KEY_i )
         return (HB_LONG)GDK_KEY_iacute;
      else if ( b== GDK_KEY_O)
         return (HB_LONG)GDK_KEY_Oacute;
      else if ( b == GDK_KEY_o )
         return (HB_LONG)GDK_KEY_oacute;
      else if ( b== GDK_KEY_U)
         return (HB_LONG)GDK_KEY_Uacute;
      else if ( b == GDK_KEY_u )
         return (HB_LONG)GDK_KEY_uacute;
      else if ( b== GDK_KEY_Y)
         return (HB_LONG)GDK_KEY_Yacute;
      else if ( b == GDK_KEY_y )
         return (HB_LONG)GDK_KEY_yacute;
      else if ( b== GDK_KEY_C)
         return (HB_LONG)GDK_KEY_Cacute;
      else if ( b == GDK_KEY_c )
         return (HB_LONG)GDK_KEY_cacute;
      else if ( b== GDK_KEY_L)
         return (HB_LONG)GDK_KEY_Lacute;
      else if ( b == GDK_KEY_l )
         return (HB_LONG)GDK_KEY_lacute;
      else if ( b== GDK_KEY_N)
         return (HB_LONG)GDK_KEY_Nacute;
      else if ( b == GDK_KEY_n )
         return (HB_LONG)GDK_KEY_nacute;
      else if ( b== GDK_KEY_R)
         return (HB_LONG)GDK_KEY_Racute;
      else if ( b == GDK_KEY_r )
         return (HB_LONG)GDK_KEY_racute;
      else if ( b== GDK_KEY_S)
         return (HB_LONG)GDK_KEY_Sacute;
      else if ( b == GDK_KEY_s )
         return (HB_LONG)GDK_KEY_sacute;
      else if ( b== GDK_KEY_Z)
         return (HB_LONG)GDK_KEY_Zacute;
      else if ( b == GDK_KEY_z )
         return (HB_LONG)GDK_KEY_zacute;
   }
   if ( a == GDK_KEY_diaeresis|| a==GDK_KEY_dead_diaeresis)	
   {
     if ( b== GDK_KEY_A)
         return (HB_LONG)GDK_KEY_Adiaeresis;
      else if ( b == GDK_KEY_a )
         return (HB_LONG)GDK_KEY_adiaeresis;
      else if ( b== GDK_KEY_E)
         return (HB_LONG)GDK_KEY_Ediaeresis;
      else if ( b == GDK_KEY_e )
         return (HB_LONG)GDK_KEY_ediaeresis;
      else if ( b== GDK_KEY_I)
         return (HB_LONG)GDK_KEY_Idiaeresis;
      else if ( b == GDK_KEY_i )
         return (HB_LONG)GDK_KEY_idiaeresis;
      else if ( b== GDK_KEY_O)
         return (HB_LONG)GDK_KEY_Odiaeresis;
      else if ( b == GDK_KEY_o )
         return (HB_LONG)GDK_KEY_odiaeresis;
      else if ( b== GDK_KEY_U)
         return (HB_LONG)GDK_KEY_Udiaeresis;
      else if ( b == GDK_KEY_u )
         return (HB_LONG)GDK_KEY_udiaeresis;
      else if ( b== GDK_KEY_Y)
         return (HB_LONG)GDK_KEY_Ydiaeresis;
      else if ( b == GDK_KEY_y )
         return (HB_LONG)GDK_KEY_ydiaeresis;

   }
   return b;
}

static HB_LONG gthwg_KeyConvert( HB_LONG ulKeyRaw, HB_LONG ulFlags )
{

   HB_LONG ulKey = 0;

   switch( ulKeyRaw )
   {
      case GDK_Return:
         ulKey = HB_KX_ENTER;
         break;
      case GDK_Escape:
         ulKey = HB_KX_ESC;
         break;
      case GDK_Right:
         ulKey = HB_KX_RIGHT;
         break;
      case GDK_Left:
         ulKey = HB_KX_LEFT;
         break;
      case GDK_Up:
         ulKey = HB_KX_UP;
         break;
      case GDK_Down:
         ulKey = HB_KX_DOWN;
         break;
      case GDK_Home:
         ulKey = HB_KX_HOME;
         break;
      case GDK_End:
         ulKey = HB_KX_END;
         break;
      case GDK_Prior:
         ulKey = HB_KX_PGUP;
         break;
      case GDK_Next:
         ulKey = HB_KX_PGDN;
         break;
      case GDK_BackSpace:
         ulKey = HB_KX_BS;
         break;
      case GDK_Tab:
      case GDK_ISO_Left_Tab:
         ulKey = HB_KX_TAB;
         break;
      case GDK_Insert:
         ulKey = HB_KX_INS;
         break;
      case GDK_Delete:
         ulKey = HB_KX_DEL;
         break;
      case GDK_Clear:
         ulKey = HB_KX_CENTER;
         break;
      case GDK_Pause:
         ulKey = HB_KX_PAUSE;
         break;
      case GDK_F1:
         ulKey = HB_KX_F1;
         break;
      case GDK_F2:
         ulKey = HB_KX_F2;
         break;
      case GDK_F3:
         ulKey = HB_KX_F3;
         break;
      case GDK_F4:
         ulKey = HB_KX_F4;
         break;
      case GDK_F5:
         ulKey = HB_KX_F5;
         break;
      case GDK_F6:
         ulKey = HB_KX_F6;
         break;
      case GDK_F7:
         ulKey = HB_KX_F7;
         break;
      case GDK_F8:
         ulKey = HB_KX_F8;
         break;
      case GDK_F9:
         ulKey = HB_KX_F9;
         break;
      case GDK_F10:
         ulKey = HB_KX_F10;
         break;
      case GDK_F11:
         ulKey = HB_KX_F11;
         break;
      case GDK_F12:
         ulKey = HB_KX_F12;
         break;
      case GDK_KP_0:
      case GDK_KP_1:
      case GDK_KP_2:
      case GDK_KP_3:
      case GDK_KP_4:
      case GDK_KP_5:
      case GDK_KP_6:
      case GDK_KP_7:
      case GDK_KP_8:
      case GDK_KP_9:
         ulKey = 48 + ulKeyRaw - GDK_KP_0;
         ulFlags |= HB_KF_KEYPAD;
         break;
   }
   if( ulKey != 0 )
      ulKey = HB_INKEY_NEW_KEY( ulKey, ulFlags );
   else if( ulKeyRaw <= 127 )
      if( ulFlags & (HB_KF_CTRL | HB_KF_ALT) && ulKeyRaw >= 97 && ulKeyRaw <= 122 )
         ulKey = HB_INKEY_NEW_KEY( ulKeyRaw-32, ulFlags );
      else
         ulKey = HB_INKEY_NEW_KEY( ulKeyRaw, ulFlags );
   else if( ulKeyRaw < 0xFE00 )
   {
      char utf8char[8];
      char cdpchar[4];
      int iLen;

      iLen = g_unichar_to_utf8( gdk_keyval_to_unicode( ulKeyRaw ), utf8char );
      utf8char[iLen] = '\0';
      hb_cdpUTF8ToStr( hb_vmCDP(), utf8char, iLen, cdpchar, 3 );
      cdpchar[1] = '\0';
      ulKey = HB_INKEY_NEW_KEY( ((unsigned int) *cdpchar) & 0xff, ulFlags ); // & 0xffff00ff;
   }
   //hwg_writelog( NULL, "Convert: %x %x\r\n",ulKeyRaw, ulKey );
   return ulKey;
}

static gint cb_event( GtkWidget *widget, GdkEvent * event, gchar* data )
{
   HB_LONG lRes;

   HB_LONG p1, p2, p3;

   //hwg_writelog( NULL, "cb_event-1 %d\r\n", event->type );
   if( event->type == GDK_EXPOSE )
   {
      gthwg_PaintText( pHWGMain, &((GdkEventExpose*)event)->area );
      gtk_widget_grab_focus( widget );
      return 0;
   }
   else if( event->type == GDK_KEY_PRESS )
   {
      p1 = WM_KEYDOWN;
      p2 = ((GdkEventKey*)event)->keyval;
      if ( p2 == GDK_KEY_asciitilde  ||  p2 == GDK_KEY_asciicircum  ||  p2 == GDK_KEY_grave ||  p2 == GDK_KEY_acute ||  p2 == GDK_KEY_diaeresis || p2 == GDK_KEY_dead_acute ||	 p2 ==GDK_KEY_dead_tilde || p2==GDK_KEY_dead_circumflex || p2==GDK_KEY_dead_grave || p2 == GDK_KEY_dead_diaeresis)	
      {
         prevp2 = p2 ;
         p2=-1;
      }
      else if( prevp2 != -1 )
      {
         p2 = ToKey(prevp2,(HB_LONG)p2);
         prevp2=-1;
      }
      p3 = ( ( ((GdkEventKey*)event)->state & GDK_SHIFT_MASK )? HB_KF_SHIFT : 0 ) |
           ( ( ((GdkEventKey*)event)->state & GDK_CONTROL_MASK )? HB_KF_CTRL : 0 ) |
           ( ( ((GdkEventKey*)event)->state & GDK_MOD1_MASK )? HB_KF_ALT : 0 );
      //hwg_writelog( NULL, "KeyDown %lu %lu\r\n", p2, p3 );
      if( p2 != -1 )
         gthwg_AddCharToInputQueue( pHWGMain, gthwg_KeyConvert( p2, p3 ) );
      return 0;
   }
   else if( event->type == GDK_SCROLL )
   {
      p1 = WM_KEYDOWN;
      p2 = ( ( (GdkEventScroll*)event )->direction == GDK_SCROLL_DOWN )? 0xFF54 : 0xFF52;
      p3 = 0;
   }
   else if( event->type == GDK_BUTTON_PRESS ||
            event->type == GDK_2BUTTON_PRESS ||
            event->type == GDK_BUTTON_RELEASE )
   {
      if( ((GdkEventButton*)event)->button == 3 )
         p1 = (event->type==GDK_BUTTON_PRESS)? WM_RBUTTONDOWN :
              ( (event->type==GDK_BUTTON_RELEASE)? WM_RBUTTONUP : WM_LBUTTONDBLCLK );
      else
         p1 = (event->type==GDK_BUTTON_PRESS)? WM_LBUTTONDOWN :
              ( (event->type==GDK_BUTTON_RELEASE)? WM_LBUTTONUP : WM_LBUTTONDBLCLK );
      //p2 = 0;
      //p3 = ( ((HB_ULONG)(((GdkEventButton*)event)->x)) & 0xFFFF ) | ( ( ((HB_ULONG)(((GdkEventButton*)event)->y)) << 16 ) & 0xFFFF0000 );
      gthwg_MouseEvent( (int)p1, (int)(((GdkEventButton*)event)->x), (int)(((GdkEventButton*)event)->y) );
   }
   else if( event->type == GDK_MOTION_NOTIFY )
   {
      p1 = WM_MOUSEMOVE;
      p2 = ( ((GdkEventMotion*)event)->state & GDK_BUTTON1_MASK )? 1:0;
      p3 = ( ((HB_ULONG)(((GdkEventMotion*)event)->x)) & 0xFFFF ) | ( ( ((HB_ULONG)(((GdkEventMotion*)event)->y)) << 16 ) & 0xFFFF0000 );
   }
   else if( event->type == GDK_CONFIGURE )
   {
      GtkAllocation alloc;
      gtk_widget_get_allocation( widget, &alloc );
      p2 = 0;
      if( alloc.width != ((GdkEventConfigure*)event)->width ||
          alloc.height!= ((GdkEventConfigure*)event)->height )
      {
         return 0;
      }
      else
      {
         p1 = WM_MOVE;
         p3 = ( ((GdkEventConfigure*)event)->x & 0xFFFF ) |
              ( ( ((GdkEventConfigure*)event)->y << 16 ) & 0xFFFF0000 );
      }
   }
   else if( event->type == GDK_ENTER_NOTIFY || event->type == GDK_LEAVE_NOTIFY )
   {
      p1 = WM_MOUSEMOVE;
      p2 = ( ((GdkEventCrossing*)event)->state & GDK_BUTTON1_MASK )? 1:0 |
           ( event->type == GDK_ENTER_NOTIFY )? 0x10:0;
      p3 = ( ((HB_ULONG)(((GdkEventCrossing*)event)->x)) & 0xFFFF ) | ( ( ((HB_ULONG)(((GdkEventMotion*)event)->y)) << 16 ) & 0xFFFF0000 );
   }
   else if( event->type == GDK_FOCUS_CHANGE )
   {
      p1 = ( ((GdkEventFocus*)event)->in )? WM_SETFOCUS : WM_KILLFOCUS;
      p2 = p3 = 0;
   }
   else
      sscanf( (char*)data,"%ld %ld %ld",&p1,&p2,&p3 );

   return 0;
}

static void gthwg_set_event( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 )
{
   char buf[25]={0};

   sprintf( buf, "%ld %ld %ld", p1, p2, p3 );
   g_signal_connect( handle, cSignal, G_CALLBACK (cb_event), g_strdup(buf) );
}

/* *********************************************************************** */

static GtkWidget * gthwg_CreatePane( PHB_GTHWG pHWG, int iLeft, int iTop, int iWidth, int iHeight )
{
   GtkWidget *hCtrl;
   GtkFixed *box;

   hCtrl = gtk_drawing_area_new();
   g_object_set_data( ( GObject * ) hCtrl, "draw", ( gpointer ) hCtrl );

   box = getFixedBox( ( GObject * ) hWndMain );
   if( box )
   {
      gtk_fixed_put( box, hCtrl, iLeft, iTop );
      gtk_widget_set_size_request( hCtrl, iWidth, iHeight );
      //hwg_writelog( NULL, "_CreatePane-1 %d %d\r\n", iWidth, iHeight );
   }
#if GTK_MAJOR_VERSION -0 < 3
   gthwg_set_event( ( gpointer ) hCtrl, "expose_event", WM_PAINT, 0, 0 );
#else
   gthwg_set_event( ( gpointer ) hCtrl, "draw", WM_PAINT, 0, 0 );
#endif
   gtk_widget_set_can_focus(hCtrl,1);

   gtk_widget_add_events( hCtrl, GDK_BUTTON_PRESS_MASK |
         GDK_BUTTON_RELEASE_MASK | GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK |
         GDK_POINTER_MOTION_MASK | GDK_FOCUS_CHANGE_MASK );

   g_signal_connect( hCtrl, "size-allocate", G_CALLBACK (cb_signal_size), NULL );
   gthwg_set_event( ( gpointer ) hCtrl, "focus_in_event", 0, 0, 0 );
   gthwg_set_event( ( gpointer ) hCtrl, "focus_out_event", 0, 0, 0 );
   gthwg_set_event( ( gpointer ) hCtrl, "button_press_event", 0, 0, 0 );
   gthwg_set_event( ( gpointer ) hCtrl, "button_release_event", 0, 0, 0 );
   gthwg_set_event( ( gpointer ) hCtrl, "motion_notify_event", 0, 0, 0 );
   gthwg_set_event( ( gpointer ) hCtrl, "key_press_event", 0, 0, 0 );
   gthwg_set_event( ( gpointer ) hCtrl, "key_release_event", 0, 0, 0 );

   gthwg_set_signal( ( gpointer ) hCtrl, "destroy", 2 );
   hPaneMain = hCtrl;

   return hCtrl;
}

/* *********************************************************************** */

HB_FUNC( GTHWG_CREATEPANEL )
{

   hWndMain = hb_parptr( 1 );
   HB_RETHANDLE( gthwg_CreatePane( pHWGMain, hb_parni(2), hb_parni(3), hb_parni(4), hb_parni(5) ) );
}

HB_FUNC( GTHWG_SETWINDOW )
{
   GtkAllocation alloc;

   hWndMain = hb_parptr( 1 );
   gtk_widget_get_allocation( hWndMain, &alloc );

   //gthwg_CreatePane( pHWGMain, 0, 0, alloc.width, alloc.height );
   gthwg_CreatePane( pHWGMain, 0, 0, 400, 200 );

   //hwg_writelog( NULL, "_setwindow-1 %d\r\n", ((hWndMain)? 1:0) );
   gtk_widget_show_all( hWndMain );

   hwg_doEvents();

   if( HB_ISNIL( 2 ) )
   {
      if( pHWGMain )
         hFontMain = gthwg_GetFont( pHWGMain->fontFace, pHWGMain->fontHeight, pHWGMain->fontWidth, pHWGMain->fontWeight, pHWGMain->fontQuality, pHWGMain->CodePage );
   }
   else
      hFontMain = hb_parptr( 2 );

   if( iNewPosX != -1 )
   {
      RECT wi = { 0, 0, 0, 0 };

      gthwg_GetWindowRect( hWndMain , &wi );
      gthwg_SetWindowPos( hWndMain, iNewPosX, iNewPosY,
         wi.right - wi.left, wi.bottom - wi.top, SWP_NOSIZE | SWP_NOZORDER );
      //hwg_writelog( NULL, "_setwindow-1a %d %d\r\n", iNewPosX,iNewPosY );
      iNewPosX = iNewPosY = -1;
   }
   gthwg_SetWindowSize( pHWGMain, pHWGMain->ROWS, pHWGMain->COLS );

   //hwg_writelog( NULL, "_setwindow-2 %d\r\n", ((hWndMain)? 1:0) );
   //gtk_main();
}

HB_FUNC( GTHWG_SETPANEL )
{
}

HB_FUNC( GTHWG_CLOSEWINDOW )
{
   hWndMain = NULL;
   //hwg_writelog( NULL, "_closewindow\r\n" );
}

/* *********************************************************************** */

static HB_BOOL hb_gt_hwg_mouse_IsPresent( PHB_GT pGT )
{

   HB_SYMBOL_UNUSED( pGT );

   return HB_TRUE;
}

static void hb_gt_hwg_mouse_GetPos( PHB_GT pGT, int * piRow, int * piCol )
{

   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

   *piRow = pHWG->MousePos.y;
   *piCol = pHWG->MousePos.x;
}

static void hb_gt_hwg_mouse_SetPos( PHB_GT pGT, int iRow, int iCol )
{

   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

   HB_SYMBOL_UNUSED( pGT );
   gthwg_SetMousePos( pHWG, iRow, iCol );
}

static HB_BOOL hb_gt_hwg_mouse_ButtonState( PHB_GT pGT, int iButton )
{

   HB_SYMBOL_UNUSED( pGT );

   HB_SYMBOL_UNUSED( pGT );
   HB_SYMBOL_UNUSED( iButton );
#if !defined( HB_OS_UNIX )
   switch( iButton )
   {
      case 0:
         return ( GetKeyState( VK_LBUTTON ) & 0x8000 ) != 0;
      case 1:
         return ( GetKeyState( VK_RBUTTON ) & 0x8000 ) != 0;
      case 2:
         return ( GetKeyState( VK_MBUTTON ) & 0x8000 ) != 0;
   }
#endif
   return HB_FALSE;
}

static void hb_gt_hwg_Init( PHB_GT pGT, HB_FHANDLE hFilenoStdin, HB_FHANDLE hFilenoStdout, HB_FHANDLE hFilenoStderr )
{

   PHB_GTHWG pHWG = (PHB_GTHWG) hb_xgrab( sizeof( HB_GTHWG ) );
   memset( pHWG, 0, sizeof(HB_GTHWG) );

   pHWG->pGT = pGT;
   pHWGMain = pHWG;

   pHWG->PTEXTSIZE.x       = HWG_DEFAULT_FONT_WIDTH;
   pHWG->PTEXTSIZE.y       = HWG_DEFAULT_FONT_HEIGHT;
   pHWG->fontWidth         = HWG_DEFAULT_FONT_WIDTH;
   pHWG->fontHeight        = HWG_DEFAULT_FONT_HEIGHT;
   pHWG->fontWeight        = FW_NORMAL;
   pHWG->fontQuality       = DEFAULT_QUALITY;
   pHWG->fontAttribute     = HWG_DEFAULT_FONT_ATTR;

   strcpy( pHWG->fontFace, HWG_DEFAULT_FONT_NAME );

   pHWG->MarginTop         = 0;
   pHWG->MarginLeft        = 0;

   pHWG->ROWS = HWG_DEFAULT_ROWS;
   pHWG->COLS = HWG_DEFAULT_COLS;

   pHWG->TextLine = ( char * ) hb_xgrab( pHWG->COLS * sizeof( char ) );

   pHWG->COLORS[ 0 ]       = BLACK;
   pHWG->COLORS[ 1 ]       = BLUE;
   pHWG->COLORS[ 2 ]       = GREEN;
   pHWG->COLORS[ 3 ]       = CYAN;
   pHWG->COLORS[ 4 ]       = RED;
   pHWG->COLORS[ 5 ]       = MAGENTA;
   pHWG->COLORS[ 6 ]       = BROWN;
   pHWG->COLORS[ 7 ]       = LIGHT_GRAY;
   pHWG->COLORS[ 8 ]       = GRAY;
   pHWG->COLORS[ 9 ]       = BRIGHT_BLUE;
   pHWG->COLORS[ 10 ]      = BRIGHT_GREEN;
   pHWG->COLORS[ 11 ]      = BRIGHT_CYAN;
   pHWG->COLORS[ 12 ]      = BRIGHT_RED;
   pHWG->COLORS[ 13 ]      = BRIGHT_MAGENTA;
   pHWG->COLORS[ 14 ]      = YELLOW;
   pHWG->COLORS[ 15 ]      = WHITE;

   pHWG->keyPointerIn      = 0;
   pHWG->keyPointerOut     = 0;
   pHWG->keyLastPos        = 0;

   pHWG->IgnoreWM_SYSCHAR  = HB_FALSE;

   pHWG->CaretExist        = HB_FALSE;
   pHWG->CaretHidden       = HB_TRUE;
   pHWG->CaretSize         = 0;
   pHWG->CaretWidth        = 0;
   pHWG->CaretRow = pHWG->CaretCol = 0;

   pHWG->CodePage          = OEM_CHARSET;     /* GetACP(); - set code page to default system */

   //hwg_writelog( NULL, "_init\r\n" );

   HB_GTLOCAL( pGT ) = ( void * ) pHWG;
   HB_GTSUPER_INIT( pGT, hFilenoStdin, hFilenoStdout, hFilenoStderr );
}

static void hb_gt_hwg_Exit( PHB_GT pGT )
{

   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

   //hwg_writelog( NULL, "_exit\r\n" );

   if( pHWG )
   {
      if( pHWG->TextLine )
         hb_xfree( pHWG->TextLine );

      hb_xfree( pHWG );
   }
   HB_GTSUPER_EXIT( pGT );

   /* TODO: */
}

static int hb_gt_hwg_ReadKey( PHB_GT pGT, int iEventMask )
{

   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );
   int c = 0;
   HB_BOOL fKey;
   HB_BOOL bCursorNone;
   int iRow, iCol, iStyle;
   RECT rect;

   HB_SYMBOL_UNUSED( iEventMask );

   //hwg_writelog( NULL, "ReadKey-1\r\n" );
   if( pHWG->hWnd )
   {
      bCursorNone = ( HB_GTSELF_GETCURSORSTYLE( pGT ) == SC_NONE );
      HB_GTSELF_GETSCRCURSOR( pGT, &iRow, &iCol, &iStyle );
      if( !bCursorNone && ( iRow != pHWG->CaretRow || iCol != pHWG->CaretCol ) )
      {
         rect.top = rect.bottom = pHWG->CaretRow;
         rect.left = pHWG->CaretCol;
         rect.right = pHWG->CaretCol + 1;
         rect = gthwg_GetXYFromColRowRect( pHWG, rect );
         gthwg_InvalidateRect( pHWG->hWnd, &rect, FALSE );
         pHWG->CaretRow = iRow;
         pHWG->CaretCol = iCol;

         rect.top = rect.bottom = iRow;
         rect.left = iCol;
         rect.right = iCol + 1;
         rect = gthwg_GetXYFromColRowRect( pHWG, rect );
         bCaretShow = 1;
         iCaretMs = hb_dateMilliSeconds();
         //hwg_writelog( NULL, "refresh-updCursor-1 %d %d\r\n", iRow, iCol );
         gthwg_InvalidateRect( pHWG->hWnd, &rect, FALSE );
      }
      else
      {
         HB_MAXUINT iMilli = hb_dateMilliSeconds();
         if( (iMilli - iCaretMs > 600) || (bCursorNone && bCaretShow) )
         {
            bCaretShow = (bCaretShow)? 0 : 1;
            iCaretMs = iMilli;
            rect.top = rect.bottom = pHWG->CaretRow;
            rect.left = pHWG->CaretCol;
            rect.right = pHWG->CaretCol + 1;
            rect = gthwg_GetXYFromColRowRect( pHWG, rect );
            //hwg_writelog( NULL, "refresh-updCursor-2 %d %d %d %d\r\n", iRow, iCol, pHWG->CaretRow, pHWG->CaretCol );
            gthwg_InvalidateRect( pHWG->hWnd, &rect, FALSE );
         }
      }

      hwg_doEvents();
      fKey = gthwg_GetCharFromInputQueue( pHWG, &c );
      //if( fKey )
      //   hwg_writelog( NULL, "_readkey-2 %d\r\n",c );
      return fKey ? c : 0;
   }

   return 0;
}

static void hb_gt_hwg_Refresh( PHB_GT pGT )
{

   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

   //hwg_writelog( NULL, "_refresh\r\n" );
   HB_GTSUPER_REFRESH( pGT );

   if( pHWG )
   {
      if( !pHWG->hWnd )
      {
         //hwg_writelog( NULL, "_refresh-1\r\n" );
         if( hPaneMain )
         {
            //hwg_writelog( NULL, "_refresh-1a\r\n" );
            pHWG->hWnd = hPaneMain;
            pHWG->hFont = hFontMain;
            gthwg_ResetWindowSize( pHWG );
         }
         else if( hWndMain )
         {
            //hwg_writelog( NULL, "_refresh-1a\r\n" );
            pHWG->hWnd = hWndMain;
            pHWG->hFont = hFontMain;
            gthwg_ResetWindowSize( pHWG );
         }
      }
      if( pHWG->hWnd )
      {
         if( hPaneMain || hWndMain )
         {
            //hwg_writelog( NULL, "_refresh-2a\r\n" );
            hwg_doEvents();
         }
         else
         {
            //hwg_writelog( NULL, "_refresh-2b\r\n" );
            pHWG->hWnd = NULL;
         }
      }
   }

}

static const char * hb_gt_hwg_Version( PHB_GT pGT, int iType )
{

   HB_SYMBOL_UNUSED( pGT );

   if( iType == 0 )
      return HB_GT_DRVNAME( HB_GT_NAME );

   return "Terminal: (template)";
}

static HB_BOOL hb_gt_hwg_SetMode( PHB_GT pGT, int iRows, int iCols )
{

   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );
   HB_BOOL fResult;

   //hwg_writelog( NULL, "Setmode-1\r\n" );
   if( pHWG->hWnd )
   {
      fResult = gthwg_SetWindowSize( pHWG, iRows, iCols );
      gthwg_ResetWindowSize( pHWG );
      HB_GTSELF_REFRESH( pGT );
   }
   else
   {
      fResult = gthwg_SetWindowSize( pHWG, iRows, iCols );
      HB_GTSELF_SEMICOLD( pGT );
   }

   return fResult;
}

static void hb_gt_hwg_Redraw( PHB_GT pGT, int iRow, int iCol, int iSize )
{
   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );

   //hwg_writelog( NULL, "_redraw\r\n" );
   if( pHWG )
   {
      if( pHWG->hWnd )
      {
         RECT rect;

         rect.top = rect.bottom = iRow;
         rect.left = iCol;
         rect.right = iCol + iSize - 1;

         rect = gthwg_GetXYFromColRowRect( pHWG, rect );

         //hwg_writelog( NULL, "_redraw-2\r\n" );
         gthwg_InvalidateRect( pHWG->hWnd, &rect, FALSE );
         //hwg_writelog( NULL, "_redraw-3 %d %d %d %d\r\n", rect.top, rect.left, rect.bottom, rect.right );
      }
   }
   //hwg_writelog( NULL, "_redraw10\r\n" );
}

static HB_BOOL hb_gt_hwg_Info( PHB_GT pGT, int iType, PHB_GT_INFO pInfo )
{
   PHB_GTHWG pHWG = (PHB_GTHWG) HB_GTLOCAL( pGT );
   int iVal;

   switch( iType )
   {
      case HB_GTI_ISUNICODE:
#if defined( UNICODE )
         pInfo->pResult = hb_itemPutL( pInfo->pResult, HB_TRUE );
#else
         pInfo->pResult = hb_itemPutL( pInfo->pResult, HB_FALSE );
#endif
         break;

      case HB_GTI_FONTSIZE:
         pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->PTEXTSIZE.y );
         iVal = hb_itemGetNI( pInfo->pNewVal );
         if( iVal > 0 )
         {
            HFONT hFont = gthwg_GetFont( pHWG->fontFace, iVal, pHWG->fontWidth, pHWG->fontWeight, pHWG->fontQuality, pHWG->CodePage );
            //hwg_writelog( NULL, "_gti_fontsize-1 %d %d\r\n", pHWG->fontHeight, iVal );
            if( hFont )
            {
               //gthwg_SetFont( hWndMain, hFont );
               //hwg_writelog( NULL, "_gti_fontsize-2\r\n" );
               pHWG->fontHeight = iVal;
               pHWG->hFont = hFont;
               hFontMain = hFont;
               if( pHWG->hWnd )
               {
                  //hwg_writelog( NULL, "_gti_fontsize-3\r\n" );
                  gthwg_ResetWindowSize( pHWG );
                  HB_GTSELF_REFRESH( pGT );
               }
            }
         }
         break;

         case HB_GTI_FONTWIDTH:
            pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->fontWidth );
            iVal = hb_itemGetNI( pInfo->pNewVal );
            if( iVal > 0 )
            {
               //hwg_writelog( NULL, "_gti_fontwidth-1 %d %d\r\n", pHWG->fontWidth,iVal );
               pHWG->fontWidth = iVal;  /* store font status for next operation on fontsize */
            }
            break;

         case HB_GTI_FONTNAME:
            pInfo->pResult = hb_itemPutC( pInfo->pResult, (const char *) pHWG->fontFace );
            if( hb_itemType( pInfo->pNewVal ) & HB_IT_STRING )
            {
               strcpy( pHWG->fontFace, hb_itemGetC( pInfo->pNewVal ) );
            }
            break;

      case HB_GTI_SCREENHEIGHT:
         pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->PTEXTSIZE.y * pHWG->ROWS );
         iVal = hb_itemGetNI( pInfo->pNewVal );
         if( iVal > 0 && pHWG->hWnd ) //&& ! pHWG->bMaximized && ! pHWG->bFullScreen  )  /* Don't allow if Maximized or FullScreen */
         {
            /* Now conforms to pHWG->ResizeMode setting, resize by FONT or ROWS as applicable [HVB] */
            RECT ci;
            gthwg_GetClientRect( pHWG->hWnd, &ci );
            if( ci.bottom != iVal )
            {
               RECT wi;
               gthwg_GetWindowRect( pHWG->hWnd, &wi );
               iVal += wi.bottom - wi.top - ci.bottom;
               gthwg_SetWindowPos( pHWG->hWnd, wi.left, wi.top, wi.right - wi.left, iVal, SWP_NOZORDER );
            }
         }
         break;

      case HB_GTI_SCREENWIDTH:
         pInfo->pResult = hb_itemPutNI( pInfo->pResult, pHWG->PTEXTSIZE.x * pHWG->COLS );
         iVal = hb_itemGetNI( pInfo->pNewVal );
         if( iVal > 0 && pHWG->hWnd ) //&& ! pHWG->bMaximized && ! pHWG->bFullScreen )  /* Don't allow if Maximized or FullScreen */
         {
            /* Now conforms to pHWG->ResizeMode setting, resize by FONT or ROWS as applicable [HVB] */
            RECT ci;
            gthwg_GetClientRect( pHWG->hWnd, &ci );
            if( ci.right != iVal )
            {
               RECT wi;
               gthwg_GetWindowRect( pHWG->hWnd, &wi );
               iVal += wi.right - wi.left - ci.right;
               gthwg_SetWindowPos( pHWG->hWnd, wi.left, wi.top, iVal, wi.bottom - wi.top, SWP_NOZORDER );
            }
         }
         break;

      case HB_GTI_DESKTOPWIDTH:
      {
         pInfo->pResult = hb_itemPutNI( pInfo->pResult, gthwg_GetDesktopWidth() );
         break;
      }
      case HB_GTI_DESKTOPHEIGHT:
      {
         pInfo->pResult = hb_itemPutNI( pInfo->pResult, gthwg_GetDesktopHeight() );
         break;
      }
      case HB_GTI_DESKTOPCOLS:
      {
         pInfo->pResult = hb_itemPutNI( pInfo->pResult,
                              gthwg_GetDesktopWidth() / pHWG->PTEXTSIZE.x );
         break;
      }
      case HB_GTI_DESKTOPROWS:
      {
         pInfo->pResult = hb_itemPutNI( pInfo->pResult,
                              gthwg_GetDesktopHeight() / pHWG->PTEXTSIZE.y );
         break;
      }

#if !defined(HB_OS_UNIX)
      case HB_GTI_CLIPBOARDDATA:
         if( hb_itemType( pInfo->pNewVal ) & HB_IT_STRING )
#if defined( UNICODE )
            hb_gt_winapi_setClipboard( CF_UNICODETEXT, pInfo->pNewVal );
#else
            hb_gt_winapi_setClipboard( pHWG->CodePage == OEM_CHARSET ?
                                       CF_OEMTEXT : CF_TEXT, pInfo->pNewVal );
#endif
         else
         {
            if( pInfo->pResult == NULL )
               pInfo->pResult = hb_itemNew( NULL );
#if defined( UNICODE )
            hb_gt_winapi_getClipboard( CF_UNICODETEXT, pInfo->pResult );
#else
            hb_gt_winapi_getClipboard( pHWG->CodePage == OEM_CHARSET ?
                                       CF_OEMTEXT : CF_TEXT, pInfo->pResult );
#endif
         }
         break;
#endif
      case HB_GTI_PALETTE:
         if( hb_itemType( pInfo->pNewVal ) & HB_IT_NUMERIC )
         {
            int iIndex = hb_itemGetNI( pInfo->pNewVal );

            if( iIndex >= 0 && iIndex < 16 )
            {
               pInfo->pResult = hb_itemPutNL( pInfo->pResult, pHWG->COLORS[ iIndex ] );

               if( hb_itemType( pInfo->pNewVal2 ) & HB_IT_NUMERIC )
               {
                  pHWG->COLORS[ iIndex ] = hb_itemGetNL( pInfo->pNewVal2 );

                  if( pHWG->hWnd )
                     HB_GTSELF_EXPOSEAREA( pHWG->pGT, 0, 0, pHWG->ROWS, pHWG->COLS );
               }
            }
         }
         else
         {
            int i;
            if( ! pInfo->pResult )
               pInfo->pResult = hb_itemNew( NULL );
            hb_arrayNew( pInfo->pResult, 16 );
            for( i = 0; i < 16; i++ )
               hb_arraySetNL( pInfo->pResult, i + 1, pHWG->COLORS[ i ] );

            if( hb_itemType( pInfo->pNewVal ) & HB_IT_ARRAY )
            {
               if( hb_arrayLen( pInfo->pNewVal ) == 16 )
               {
                  for( i = 0; i < 16; i++ )
                     pHWG->COLORS[ i ] = hb_arrayGetNL( pInfo->pNewVal, i + 1 );

                  if( pHWG->hWnd )
                     HB_GTSELF_EXPOSEAREA( pHWG->pGT, 0, 0, pHWG->ROWS, pHWG->COLS );
               }
            }
         }
         break;

      case HB_GTI_SETPOS_XY:
      case HB_GTI_SETPOS_ROWCOL:
      {
         RECT wi = { 0, 0, 0, 0 };
         int x = 0, y = 0;

         if( pHWG->hWnd )
         {
            gthwg_GetWindowRect( pHWG->hWnd, &wi );
            if( iType == HB_GTI_SETPOS_ROWCOL )
            {
               y = wi.left / pHWG->PTEXTSIZE.x;
               x = wi.top / pHWG->PTEXTSIZE.y;
            }
            else
            {
               x = wi.left;
               y = wi.top;
            }
         }

         if( ! pInfo->pResult )
            pInfo->pResult = hb_itemNew( NULL );
         hb_arrayNew( pInfo->pResult, 2 );

         hb_arraySetNI( pInfo->pResult, 1, x );
         hb_arraySetNI( pInfo->pResult, 2, y );

         if( ( hb_itemType( pInfo->pNewVal ) & HB_IT_NUMERIC ) &&
             ( hb_itemType( pInfo->pNewVal2 ) & HB_IT_NUMERIC ) )
         {
            x = hb_itemGetNI( pInfo->pNewVal );
            y = hb_itemGetNI( pInfo->pNewVal2 );
         }
         else if( ( hb_itemType( pInfo->pNewVal ) & HB_IT_ARRAY ) &&
                  hb_arrayLen( pInfo->pNewVal ) == 2 )
         {
            x = hb_arrayGetNI( pInfo->pNewVal, 1 );
            y = hb_arrayGetNI( pInfo->pNewVal, 2 );
         }
         else
            break;

         if( iType == HB_GTI_SETPOS_ROWCOL )
         {
            int c = y;
            y = x * pHWG->PTEXTSIZE.y;
            x = c * pHWG->PTEXTSIZE.x;
         }
         if( pHWG->hWnd )
         {
            gthwg_SetWindowPos( pHWG->hWnd, x, y, wi.right - wi.left, wi.bottom - wi.top,
               SWP_NOSIZE | SWP_NOZORDER );
         }
         else
         {
            iNewPosX = x;
            iNewPosY = y;
         }
         break;
      }

      case HB_GTI_WINHANDLE:
         pInfo->pResult = hb_itemPutPtr( pInfo->pResult, hWndMain );
         break;

      default:
         return HB_GTSUPER_INFO( pGT, iType, pInfo );

   }
   return HB_TRUE;
}

/* *********************************************************************** */

static HB_BOOL hb_gt_FuncInit( PHB_GT_FUNCS pFuncTable )
{

   pFuncTable->Init    = hb_gt_hwg_Init;
   pFuncTable->Exit    = hb_gt_hwg_Exit;
   pFuncTable->ReadKey = hb_gt_hwg_ReadKey;
   pFuncTable->Version = hb_gt_hwg_Version;
   pFuncTable->SetMode = hb_gt_hwg_SetMode;
   pFuncTable->Redraw  = hb_gt_hwg_Redraw;
   pFuncTable->Refresh = hb_gt_hwg_Refresh;
   pFuncTable->Info    = hb_gt_hwg_Info;

   pFuncTable->MouseIsPresent    = hb_gt_hwg_mouse_IsPresent;
   pFuncTable->MouseGetPos       = hb_gt_hwg_mouse_GetPos;
   pFuncTable->MouseSetPos       = hb_gt_hwg_mouse_SetPos;
   pFuncTable->MouseButtonState  = hb_gt_hwg_mouse_ButtonState;

   return HB_TRUE;
}

#include "hbgtreg.h"
