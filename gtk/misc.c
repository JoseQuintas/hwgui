/*
 * $Id: misc.c,v 1.5 2005-09-20 17:20:56 lculik Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Miscellaneous functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include <math.h>

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbmath.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "guilib.h"
#include "gtk/gtk.h"

void writelog( char* s )
{
   FHANDLE handle;

   if( hb_fsFile( (unsigned char *) "ac.log" ) )
      handle = hb_fsOpen( (unsigned char *) "ac.log", FO_WRITE );
   else
      handle = hb_fsCreate( (unsigned char *) "ac.log", 0 );

   hb_fsSeek( handle,0, SEEK_END );
   hb_fsWrite( handle, (unsigned char *) s, strlen(s) );
   hb_fsWrite( handle, (unsigned char *) "\n\r", 2 );

   hb_fsClose( handle );
}

HB_FUNC( HWG_SETDLGRESULT )
{
   // SetWindowLong( (HWND) hb_parnl(1), DWL_MSGRESULT, hb_parni(2) );
}

HB_FUNC( SETCAPTURE )
{
}

HB_FUNC( RELEASECAPTURE )
{
}

HB_FUNC( COPYSTRINGTOCLIPBOARD )
{
}

HB_FUNC( LOWORD )
{
   hb_retni( (int) ( hb_parnl( 1 ) & 0xFFFF ) );
}

HB_FUNC( HIWORD )
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

HB_FUNC( SETBIT )
{
   if( hb_pcount() < 3 || hb_parni( 3 ) )
      hb_retnl( hb_parnl(1) | ( 1 << (hb_parni(2)-1) ) );
   else
      hb_retnl( hb_parnl(1) & ~( 1 << (hb_parni(2)-1) ) );
}

HB_FUNC( CHECKBIT )
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
HB_FUNC( HB_NUMTOHEX )
{
   ULONG ulNum;
   int iCipher;
   char ret[32];
   char tmp[32];
   int len = 0, len1 = 0;

   ulNum = (ULONG) hb_parnl( 1 );

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

HB_FUNC( GETDESKTOPWIDTH )
{
    hb_retni(gdk_screen_width());
}


HB_FUNC( GETDESKTOPHEIGHT )
{
    hb_retni(gdk_screen_height());
}


HB_FUNC( HIDEWINDOW )
{

#ifdef __GTK_USE_POINTER__
    gtk_widget_hide( (GtkWidget *) hb_parptr(1) );
#else
    gtk_widget_hide( (GtkWidget *) hb_parnl(1) );
#endif
}

HB_FUNC( SHOWWINDOW )
{
#ifdef __GTK_USE_POINTER__
gtk_widget_show( (GtkWidget *) hb_parptr(1) );
#else
    gtk_widget_show( (GtkWidget *) hb_parnl(1) );
#endif
}

HB_FUNC( SENDMESSAGE )
{
}

HB_FUNC( GETNOTIFYCODE )
{
}

HB_FUNC( TREENOTIFY )
{
}

HB_FUNC( LISTVIEWNOTIFY )
{
}

