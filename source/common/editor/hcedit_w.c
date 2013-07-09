/*
 * $Id$
 */

/*
 * HWGUI - Harbour Win32 GUI library source code:
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

#define _WIN32_WINNT 0x400
#include <windows.h>
#include <tchar.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "hbvm.h"
#include "hbstack.h"
#include "guilib.h"

LRESULT CALLBACK WinCtrlProc( HWND, UINT, WPARAM, LPARAM );

typedef struct
{
   COLORREF fg;                 // foreground colour
   COLORREF bg;                 // background colour
   int iFont;                  // possible font-styling information

} TEDATTR;

typedef struct
{
   // Windows font information
   HFONT hFont;
   TEXTMETRIC tm;

   int iWidth;

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
   HWND          handle;
   TEDFONT *  pFontsScr;
   TEDFONT *  pFontsPrn;
   int       iFontsCurr;
   TEDATTR *      pattr;
   HDC           hDCScr;
   HDC           hDCPrn;
   double        dKoeff;
   int           iWidth;
   HB_BOOL        bWrap;
   COLORREF          fg;
   COLORREF          bg;
   COLORREF     fg_curr;
   COLORREF     bg_curr;
   int               x1;
   int               x2;
   int             ypos;
   int       ixCaretPos;
   int       iyCaretPos;
   int     iCaretHeight;

} TEDIT;

#define  NUMBER_OF_FONTS  16
#define  TEDATTR_MAX     256

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

TEDFONT * ted_setfont( TEDIT * pted, HFONT hFont, int iNum, HB_BOOL bPrn  )
{
   TEDFONT * pFont;
   HDC hDC = GetDC( 0 );
   HANDLE hold;
   SIZE sz;

   pFont = ( (bPrn)? pted->pFontsPrn : pted->pFontsScr ) + 
         ( (iNum>=0)? iNum : pted->iFontsCurr );
   hold = SelectObject( hDC, hFont );

   GetTextMetrics( hDC, &pFont->tm );
   GetTextExtentPoint32( hDC, "aA", 2, &sz );
   pFont->iWidth = sz.cx / 2;

   SelectObject( hDC, hold );
   ReleaseDC( 0, hDC );

   pFont->hFont = hFont;
   if( iNum < 0 )
      pted->iFontsCurr++;

   return pFont;
}

/*
 * ted_CalcSize() returns the text width in pixels, 
 * writes to the 4 parameter (iRealLen) the width in chars
 */

int ted_CalcSize( TEDIT * pted, char *szText, TEDATTR * pattr, int *iRealLen,
      int iWidth, HB_BOOL bWrap, HB_BOOL bLastInFew )
{
   int i, i1, iReal, xpos;
   SIZE sz;
   TEDFONT *font = pted->pFontsScr + pattr->iFont;

   SelectObject( pted->hDCScr, font->hFont );

   iReal = iWidth / font->iWidth;
   if( iReal > *iRealLen )
      iReal = *iRealLen;
   GetTextExtentPoint32( pted->hDCScr, szText, iReal, &sz );
   if( sz.cx > iWidth )
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
         GetTextExtentPoint32( pted->hDCScr, szText, i, &sz );
         if( sz.cx <= iWidth )
            break;
      }
      xpos = sz.cx;
      *iRealLen = i;
   }
   else
   {
      xpos = sz.cx;
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
         GetTextExtentPoint32( pted->hDCScr, szText, i, &sz );
         if( sz.cx > iWidth )
            break;

         xpos = sz.cx;
         i1 = i;
      }
      *iRealLen = i1;
   }

   return xpos;
}

int ted_TextOut( TEDIT * pted, int xpos, int ypos, int iHeight,
      int iMaxAscent, char *szText, TEDATTR * pattr, int iLen )
{
   int yoff;
   RECT rect;
   SIZE sz;
   COLORREF fg, bg;
   HDC hDC = (pted->hDCPrn)? pted->hDCPrn : pted->hDCScr;
   TEDFONT *font = ( (pted->hDCPrn)? pted->pFontsPrn : pted->pFontsScr ) + pattr->iFont;

   SelectObject( hDC, font->hFont );

   fg = ( pattr->fg == pattr->bg )? pted->fg : pattr->fg;
   bg = ( pattr->fg == pattr->bg )? pted->bg : pattr->bg;
   if( fg != pted->fg_curr )
   {
      SetTextColor( hDC, fg );
      pted->fg_curr = fg;
   }
   if( bg != pted->bg_curr )
   {
      SetBkColor( hDC, bg );
      pted->bg_curr = bg;
   }

   yoff = iMaxAscent - font->tm.tmAscent;

   // get size of text
   GetTextExtentPoint32( hDC, szText, iLen, &sz );

   SetRect( &rect, xpos, ypos, xpos + sz.cx, ypos + iHeight );
   // draw the text and erase it's background at the same time
   ExtTextOut( hDC, xpos, ypos + yoff, ETO_OPAQUE, &rect, szText, iLen, 0 );
   //wrlog( NULL, "Out: %s tcol = %u\r\n", szText, fg );

   return sz.cx;
}

int ted_LineOut( TEDIT * pted, int x1, int ypos, int x2, char *szText, int iLen, int iAlign, HB_BOOL bCalcOnly )
{
   TEDATTR *pattr = pted->pattr;
   int i, lasti, iRealLen, iPrinted = 0, iRealWidth = 0, iSegs;
   int iHeight = 0, iMaxAscent = 0;
   TEDFONT *font;

   //wrlog( NULL, "Lineout-1\r\n" );
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
         iHeight =
               max( iHeight, font->tm.tmHeight + font->tm.tmExternalLeading );
         iMaxAscent = max( iMaxAscent, font->tm.tmAscent );

         iRealLen = i - lasti;
         iRealWidth += ted_CalcSize( pted, szText + lasti, pattr + lasti, &iRealLen,
               x2 - iRealWidth - x1, pted->bWrap, i == iLen && iSegs );
         // wrlog( NULL, "iLen = %u iRealLen = %u\r\n", i-lasti, iRealLen );
         iPrinted += iRealLen;
         if( iRealLen < i - lasti )
            break;
         lasti = i;
      }
   }
   //wrlog( NULL, "Lineout-2\r\n" );

   if( iAlign )
   {
      if( iAlign == 1 )
         x1 += (x2 - x1 - iRealWidth) / 2;
      else if( iAlign == 2 )
         x1 += x2 - x1 - iRealWidth;
   }
   pted->x1 = x1;
   //pted->x2 = x1 + iRealWidth;

   if( !bCalcOnly )
   {
      RECT rect;

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
               iRealLen = i - lasti;
            else
               iRealLen = iPrinted - lasti;
            // wrlog( NULL, "x1 = %u ypos= %u len = %u \r\n", x1, ypos, iRealLen );
            x1 +=
                  ted_TextOut( pted, x1, ypos, iHeight, iMaxAscent,
                  szText + lasti, pattr + lasti, iRealLen );
            // wrlog( NULL, "x1 = %u \r\n", x1 );
            if( iRealLen != ( i - lasti ) )
               break;
            lasti = i;
         }
      }
      pted->x2 = x1;
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
   }
   pted->ypos = ypos + iHeight;
   return iPrinted;
}

void ted_ClearAttr( TEDATTR * pattr )
{
   memset( pattr, 0, sizeof( TEDATTR ) * TEDATTR_MAX );
}

void ted_init( void )
{
   static HB_BOOL bRegistered = FALSE;

   if( !bRegistered )
   {
      WNDCLASS wndclass;

      wndclass.style = CS_DBLCLKS | CS_PARENTDC;   // | CS_OWNDC | CS_VREDRAW | CS_HREDRAW;
      wndclass.lpfnWndProc = WinCtrlProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = GetModuleHandle( NULL );
      wndclass.hIcon = NULL;
      wndclass.hCursor = LoadCursor( NULL, IDC_IBEAM );
      wndclass.hbrBackground = ( HBRUSH ) 0;
      // wndclass.hbrBackground = (HBRUSH)( COLOR_WINDOW+1 );
      wndclass.lpszMenuName = NULL;
      wndclass.lpszClassName = "tedit";

      RegisterClass( &wndclass );
      bRegistered = TRUE;
   }
}

TEDIT * ted_create( HWND hwndParent, int id, DWORD dwStyle, int x, int y,
      int iWidth, int iHeight )
{
   TEDIT *pted = ( TEDIT * ) hb_xgrab( sizeof( TEDIT ) );

   memset( pted, 0, sizeof( TEDIT ) );

   pted->handle = CreateWindowEx( 
         ( dwStyle & WS_BORDER ) ? WS_EX_CLIENTEDGE : 0,
         "tedit", _T( "" ), dwStyle,
         x, y, iWidth, iHeight, hwndParent, ( HMENU ) id,
         GetModuleHandle( 0 ), 0 );

   pted->pFontsScr =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );
   pted->pFontsPrn =
         ( TEDFONT * ) hb_xgrab( sizeof( TEDFONT ) * NUMBER_OF_FONTS );

   pted->pattr = ( TEDATTR * ) hb_xgrab( sizeof( TEDATTR ) * TEDATTR_MAX );
   ted_ClearAttr( pted->pattr );

   return pted;
}

HB_FUNC( HCED_INITTEXTEDIT )
{
   ted_init(  );
}

HB_FUNC( HCED_CREATETEXTEDIT )
{
   HB_RETHANDLE( ( void * ) ted_create( ( HWND ) HB_PARHANDLE( 1 ),
               hb_parni( 2 ), ( DWORD ) hb_parnl( 3 ), hb_parni( 4 ),
               hb_parni( 5 ), hb_parni( 6 ), hb_parni( 7 ) ) );
}

HB_FUNC( HCED_GETHANDLE )
{
   HB_RETHANDLE( ( void * ) ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
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
   TEDFONT * pFont = ted_setfont( ( TEDIT * ) HB_PARHANDLE( 1 ), ( HFONT ) HB_PARHANDLE( 2 ), -1, 0 );
   hb_retni( pFont->tm.tmHeight + pFont->tm.tmExternalLeading );
}

HB_FUNC( HCED_SETFONT )
{
   int iFont = hb_parni(3);

   if( iFont > 0 ) iFont --;
   ted_setfont( ( TEDIT * ) HB_PARHANDLE( 1 ), ( HFONT ) HB_PARHANDLE( 2 ), 
         iFont, (HB_ISNIL(4))? 0 : hb_parl(4) );
}

HB_FUNC( HCED_SETCOLOR )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   if( HB_ISNUM(2) )
   {
      pted->fg = (COLORREF) hb_parnl(2);
      SetTextColor( pted->hDCScr, pted->fg );
      pted->fg_curr = pted->fg;
   }
   if( HB_ISNUM(3) )
   {
      pted->bg = (COLORREF) hb_parnl(3);
      SetBkColor( pted->hDCScr, pted->bg );
      pted->bg_curr = pted->bg;
   }
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
   COLORREF fg = (COLORREF) hb_parnl(5);
   COLORREF bg = (COLORREF) hb_parnl(6);
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
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   SCROLLINFO si;
   int iPages = hb_parni(4);

   si.cbSize = sizeof( SCROLLINFO );
   si.fMask = SIF_PAGE | SIF_POS | SIF_RANGE | SIF_DISABLENOSCROLL;

   si.nPos  = hb_parni(2);
   si.nPage = hb_parni(3);
   si.nMin  = 0;
   si.nMax  = hb_parni(3) * ( (iPages)? iPages-1:iPages );
        
   SetScrollInfo( pted->handle, SB_VERT, &si, TRUE );

}

HB_FUNC( HCED_SETPAINT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   pted->hDCScr = (HB_ISNIL(2))? NULL : (HDC) HB_PARHANDLE( 2 );
   pted->hDCPrn = (HB_ISNIL(3))? NULL : (HDC) HB_PARHANDLE( 3 );

   if( !HB_ISNIL(4) )
      pted->iWidth = hb_parni( 4 );
   if( !HB_ISNIL(5) )
      pted->bWrap = hb_parl( 5 );

   SelectObject( pted->hDCScr, pted->pFontsScr->hFont );
   SetTextColor( pted->hDCScr, pted->fg );
   SetBkColor( pted->hDCScr, pted->bg );
   pted->fg_curr = pted->fg;
   pted->bg_curr = pted->bg;
   if( pted->hDCPrn && !HB_ISNIL(6) )
   {
      pted->dKoeff = ( GetDeviceCaps( pted->hDCPrn,HORZRES ) / hb_parnd(6) ) / GetDeviceCaps( pted->hDCPrn,HORZSIZE );
      wrlog( NULL, "%f\r\n", pted->dKoeff );
   }

}

HB_FUNC( HCED_FILLRECT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   RECT rect;

   if( !pted->hDCPrn )
   {
      SetRect( &rect, (HB_ISNIL(2))? 0:hb_parni(2), hb_parni(3), 
            (HB_ISNIL(4))? pted->iWidth:hb_parni(4), hb_parni(5) );
      if( pted->bg != pted->bg_curr )
      {
         SetBkColor( pted->hDCScr, pted->bg );
         pted->bg_curr = pted->bg;
      }
      ExtTextOut( pted->hDCScr, 0, 0, ETO_OPAQUE, &rect, 0, 0, 0 );
   }
}

HB_FUNC( HCED_SHOWCARET )
{
   ShowCaret( ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
}

HB_FUNC( HCED_HIDECARET )
{
   HideCaret( ( ( TEDIT * ) HB_PARHANDLE( 1 ) )->handle );
}

HB_FUNC( HCED_INITCARET )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   CreateCaret( pted->handle, (HBITMAP)NULL, 2, pted->pFontsScr->tm.tmHeight );
   ShowCaret( pted->handle );
   SetCaretPos( 0,0 );
   pted->iCaretHeight = pted->pFontsScr->tm.tmHeight;
   InvalidateRect( pted->handle, NULL, 0 );
}

HB_FUNC( HCED_KILLCARET )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );

   HideCaret( pted->handle );
   DestroyCaret();
   InvalidateRect( pted->handle, NULL, 0 );
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
   SetCaretPos( pted->ixCaretPos, pted->iyCaretPos );
}

/*
 * hced_ExactCaretPos( ::hEdit, cLine, x1, xPos, y1, bSet )
 */
HB_FUNC( HCED_EXACTCARETPOS )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   char * szText = ( char * ) hb_parc(2);
   int x1 = hb_parni(3);
   int xpos = hb_parni(4);
   int y1 = hb_parni(5);
   HB_BOOL bSet = (HB_ISNIL(6))? 1 : hb_parl(6);
   int i, lasti, iRealLen, iPrinted = 0, iLen = hb_parclen(2);
   TEDATTR *pattr = pted->pattr;
   SIZE sz;

   if( iLen > 0 )
   {
      pted->hDCScr = GetDC( 0 );
      if( xpos < 0 )
         xpos = pted->iWidth + 1;
      if( xpos < x1 )
         xpos = x1;
      for( i = 0, lasti = 0; i <= iLen; i++ )
      {
         if( i == iLen || ( pattr + i )->iFont != ( pattr + lasti )->iFont )
         {
            iRealLen = i - lasti;
            x1 += ted_CalcSize( pted, szText + lasti, pattr + lasti, &iRealLen,
                  xpos - x1, 0, i == iLen );
            iPrinted += iRealLen;
            if( iRealLen < i - lasti )
               break;
            lasti = i;
         }
      }
      if( xpos <= pted->iWidth )
         if( *(szText+iPrinted) )
         {
            GetTextExtentPoint32( pted->hDCScr, szText+iPrinted, 1, &sz );

            if( (x1 + sz.cx - xpos) < ( xpos - x1 ) )
            {
               x1 += sz.cx;
               iPrinted ++;
            }
         }
      ReleaseDC( 0, pted->hDCScr );
   }

   iPrinted ++;
   if( bSet )
   {
      int iCaretHeight = ( pted->pFontsScr + (pattr+iPrinted-1)->iFont )->tm.tmHeight;
      if( iCaretHeight != pted->iCaretHeight )
      {
         HideCaret( pted->handle );
         DestroyCaret();
         pted->iCaretHeight = iCaretHeight;
         CreateCaret( pted->handle, (HBITMAP)NULL, 2, iCaretHeight );
         ShowCaret( pted->handle );
      }
      SetCaretPos( x1, y1 );
      pted->ixCaretPos = x1;
      pted->iyCaretPos = y1;
      // wrlog( NULL, "x = %u y = %u\r\n", x1, y1 );
   }

   hb_retni( iPrinted );

}

HB_FUNC( HCED_INVALIDATERECT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   RECT rc;

   if( hb_pcount(  ) > 2 )
   {
      rc.left = hb_parni( 3 );
      rc.top = hb_parni( 4 );
      rc.right = hb_parni( 5 );
      rc.bottom = hb_parni( 6 );
   }

   InvalidateRect( pted->handle,  // handle of window with changed update region
         ( hb_pcount(  ) > 2 ) ? &rc : NULL,    // address of rectangle coordinates
         hb_parni( 2 )          // erase-background flag
          );
}

/*
 * hced_LineOut( ::hEdit, @x1, @yPos, @x2, cLine, Len(cLine), nAlign, lPaint )
 */
HB_FUNC( HCED_LINEOUT )
{
   TEDIT *pted = ( TEDIT * ) HB_PARHANDLE( 1 );
   HB_BOOL bCalcOnly = (HB_ISNIL(8))? 0 : hb_parl(8);

   hb_retni( ted_LineOut( pted, hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ),
         ( char * )hb_parc( 5 ), hb_parni( 6 ), hb_parni(7), bCalcOnly ) );
   if( !bCalcOnly )
   {
      hb_storni( pted->x1, 2 );
      hb_storni( pted->x2, 4 );
   }
   hb_storni( pted->ypos, 3 );
}

