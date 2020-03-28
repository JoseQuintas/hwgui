/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Miscellaneous functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include <math.h>
#include "guilib.h"
#include "hbmath.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include <unistd.h>
#include "gtk/gtk.h"
#include "gdk/gdkkeysyms.h"

static GtkClipboard* clipboard = NULL;

void hwg_writelog( const char * sFile, const char * sTraceMsg, ... )
{
   FILE *hFile;

   if( sFile == NULL )
   {
      hFile = hb_fopen( "ac.log", "a" );
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

HB_FUNC( HWG_SETDLGRESULT )
{
}

HB_FUNC( HWG_SETCAPTURE )
{
}

HB_FUNC( HWG_RELEASECAPTURE )
{
}

HB_FUNC( HWG_COPYSTRINGTOCLIPBOARD )
{
   if( !clipboard )
      clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);

   gtk_clipboard_set_text( clipboard, hb_parc(1), -1 );
   gtk_clipboard_store( clipboard );
}

HB_FUNC( HWG_GETCLIPBOARDTEXT )
{
   gchar * sText;
   if( !clipboard )
      clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);

   if( gtk_clipboard_wait_is_text_available( clipboard ) )
   {
      sText = gtk_clipboard_wait_for_text( clipboard );
      hb_retc( sText );
   }
   else
      hb_retc( "" );
}

HB_FUNC( HWG_GETKEYBOARDSTATE )
{
   char lpbKeyState[256];
   HB_ULONG ulState = hb_parnl( 1 );

   memset( lpbKeyState, 0, 255 );
   if( ulState & 1 )
      lpbKeyState[ 0x10 ] = 0x80;  // Shift
   if( ulState & 2 )
      lpbKeyState[ 0x11 ] = 0x80;  // Ctrl
   if( ulState & 4 )
      lpbKeyState[ 0x12 ] = 0x80;  // Alt

   hb_retclen( lpbKeyState, 255 );
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

HB_FUNC( HWG_PTRTOULONG )
{
   hb_retnl( hb_parnl( 1 ) );
}

HB_FUNC( HWG_ISPTREQ )
{
   hb_retl( HB_PARHANDLE( 1 ) == HB_PARHANDLE( 2 ) );
}

HB_FUNC( HWG_SIN )
{
   hb_retnd( sin( hb_parnd(1) ) );
}

HB_FUNC( HWG_COS )
{
   hb_retnd( cos( hb_parnd(1) ) );
}

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

/*
 * HORZRES	Width, in pixels, of the screen.
 * VERTRES	Height, in raster lines, of the screen.
 * HORZSIZE	Width, in millimeters, of the physical screen.
 * VERTSIZE	Height, in millimeters, of the physical screen.
 *
 */
HB_FUNC( HWG_GETDEVICEAREA )
{
   GdkScreen* screen = gdk_screen_get_default();

   PHB_ITEM aMetr = hb_itemArrayNew( 4 );
   PHB_ITEM temp;

   temp = hb_itemPutNL( NULL, (HB_LONG) gdk_screen_get_width( screen ) );
   hb_itemArrayPut( aMetr, 1, temp );

   hb_itemPutNL( temp, (HB_LONG) gdk_screen_get_height( screen ) );
   hb_itemArrayPut( aMetr, 2, temp );

   hb_itemPutNL( temp, (HB_LONG) gdk_screen_get_width_mm( screen ) );
   hb_itemArrayPut( aMetr, 3, temp );

   hb_itemPutNL( temp, (HB_LONG) gdk_screen_get_height_mm( screen ) );
   hb_itemArrayPut( aMetr, 4, temp );

   hb_itemRelease( temp );
   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}

HB_FUNC( HWG_COLORRGB2N )
{
   hb_retnl( hb_parni( 1 ) + hb_parni( 2 ) * 256 + hb_parni( 3 ) * 65536 );
}

HB_FUNC( HWG_SLEEP )
{
   if( hb_parinfo( 1 ) )
      usleep( hb_parnl( 1 ) * 1000 );
}

#define CHUNK_LEN 1024

HB_FUNC( HWG_RUNCONSOLEAPP )
{
    /* Ensure that output of command does interfere with stdout */
    fflush(stdin);
    FILE *cmd_file = (FILE *) popen( hb_parc(1), "r" );
    FILE *hOut;
    char buf[CHUNK_LEN];
    int bytes_read, iOutExist = 0, iExitCode;

    if( !cmd_file )
    {
        hb_retni( -1 );
        return;
    }

    if( !HB_ISNIL(2) )
    {
       hOut = fopen( hb_parc(2), "w" );
       iOutExist = 1;
    }

    do
    {
        bytes_read = fread( buf, sizeof(char), CHUNK_LEN, cmd_file );
        if( iOutExist )
           fwrite( buf, 1, bytes_read, hOut );
    } while (bytes_read == CHUNK_LEN);

    iExitCode = pclose(cmd_file);
    if( iOutExist )
       fclose( hOut );

    hb_retni( iExitCode );
}

HB_FUNC( HWG_RUNAPP )
{
   hb_retl( g_spawn_command_line_async( hb_parc(1), NULL ) );
}

HB_FUNC( HWG_SHELLEXECUTE )
{
   const gchar * uri = hb_parc(1);
   hb_retl( gtk_show_uri( NULL, uri, GDK_CURRENT_TIME, NULL ) );
}
