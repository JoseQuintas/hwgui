/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Miscellaneous functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include <math.h>
#include "guilib.h"
#include "hbmath.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include "gtk/gtk.h"

void hwg_writelog( char* s )
{
#ifdef __XHARBOUR__
   FHANDLE handle;
#else
   HB_FHANDLE handle;
#endif

   if( hb_fsFile( "ac.log" ) )
      handle = hb_fsOpen( "ac.log", FO_WRITE );
   else
      handle = hb_fsCreate( "ac.log", 0 );

   hb_fsSeek( handle,0, SEEK_END );
   hb_fsWrite( handle, (unsigned char *) s, strlen(s) );
   hb_fsWrite( handle, (unsigned char *) "\n\r", 2 );

   hb_fsClose( handle );
}

HB_FUNC( HWG_SETDLGRESULT )
{
   // SetWindowLong( (HWND) hb_parnl(1), DWL_MSGRESULT, hb_parni(2) );
}

HB_FUNC( HWG_SETCAPTURE )
{
}

HB_FUNC( HWG_RELEASECAPTURE )
{
}

HB_FUNC( HWG_COPYSTRINGTOCLIPBOARD )
{
}

HB_FUNC( HWG_LOWORD )
{
   hb_retni( (int) ( hb_parnl( 1 ) & 0xFFFF ) );
}

HB_FUNC( HWG_HIWORD )
{
   hb_retni( (int) ( ( hb_parnl( 1 ) >> 16 ) & 0xFFFF ) );
}


HB_FUNC( HWG_BITOR )
{
   hb_retnl( hb_parnl(1) | hb_parnl(2) );
}

HB_FUNC( HWG_BITAND )
{
   hb_retnl( hb_parnl(1) & hb_parnl(2) );
}

HB_FUNC( HWG_BITANDINVERSE )
{
   hb_retnl( hb_parnl(1) & (~hb_parnl(2)) );
}

HB_FUNC( HWG_SETBIT )
{
   if( hb_pcount() < 3 || hb_parni( 3 ) )
      hb_retnl( hb_parnl(1) | ( 1 << (hb_parni(2)-1) ) );
   else
      hb_retnl( hb_parnl(1) & ~( 1 << (hb_parni(2)-1) ) );
}

HB_FUNC( HWG_CHECKBIT )
{
   hb_retl( hb_parnl(1) & ( 1 << (hb_parni(2)-1) ) );
}

HB_FUNC( HWG_SIN )
{
   hb_retnd( sin( hb_parnd(1) ) );
}

HB_FUNC( HWG_COS )
{
   hb_retnd( cos( hb_parnd(1) ) );
}

#ifndef __XHARBOUR__
HB_FUNC( HWG_NUMTOHEX )
{
   HB_ULONG ulNum;
   int iCipher;
   char ret[32];
   char tmp[32];
   int len = 0, len1 = 0;

   ulNum = (HB_ULONG) hb_parnl( 1 );

   while ( ulNum > 0 )
   {
      iCipher = ulNum % 16;
      if ( iCipher < 10 )
      {
         tmp[ len++ ] = '0' + iCipher;
      }
      else
      {
         tmp[ len++ ] = 'A' + (iCipher - 10 );
      }
      ulNum >>=4;

   }

   while ( len > 0 )
   {
      ret[len1++] = tmp[ --len ];
   }
   ret[len1] = '\0';

   hb_retc( ret );
}
#endif

HB_FUNC( HWG_GETDESKTOPWIDTH )
{
    hb_retni(gdk_screen_width());
}


HB_FUNC( HWG_GETDESKTOPHEIGHT )
{
    hb_retni(gdk_screen_height());
}


HB_FUNC( HWG_HIDEWINDOW )
{
    gtk_widget_hide( (GtkWidget *) HB_PARHANDLE(1) );
}

HB_FUNC( HWG_SHOWWINDOW )
{
   gtk_widget_show( (GtkWidget *) HB_PARHANDLE(1) );
}

HB_FUNC( HWG_SHOWALL )
{
   gtk_widget_show_all( (GtkWidget *) HB_PARHANDLE(1) );
}

HB_FUNC( HWG_SENDMESSAGE )
{
}

HB_FUNC( HWG_GETNOTIFYCODE )
{
}

HB_FUNC( HWG_TREENOTIFY )
{
}

HB_FUNC( HWG_LISTVIEWNOTIFY )
{
}


