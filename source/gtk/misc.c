/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Miscellaneous functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

/*
 Some troubleshootings:
  The function HB_RETSTR() is windows only !
  Use hb_retc().
*/

#define HB_MEM_NUM_LEN  8

/* Standard C libraries */
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <malloc.h>
#include <time.h>
#include <sys/stat.h>

#include "guilib.h"
#include "hbmath.h"
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbset.h"
#include "item.api"
#include "hbtypes.h"
#include "hbwinuni.h"
#include <unistd.h>
#include "gtk/gtk.h"
#include "gdk/gdkkeysyms.h"
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
#include <windows.h>
#endif
/* Avoid warnings from GCC */
#include "warnings.h"

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

HB_FUNC( HWG_BITOR_INT )
{
   hb_retni( ( hb_parni( 1 ) | hb_parni( 2 ) ) );
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

HB_FUNC( HWG_SETBITBYTE )
{
  int para3;

   if ( hb_pcount() < 3 )
    {
      /* Return previous value */
      hb_retni( hb_parni(1) );
    }

    para3 = hb_parni( 3 );
    if ( para3 < 0 || para3 > 1 )
    {
      /* Return previous value */
      hb_retni( hb_parni(1) );
    }

   if ( para3 == 1 )
   {
   /* 0 to 1 */
    hb_retni( hb_parni(1) | ( 1 << (hb_parni(2) - 1) ) );
   }
   else
   {
   /* 1 to 0 */
   hb_retni( hb_parni(1) & ~( 1 << (hb_parni(2) - 1) ) );
   }
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

HB_FUNC( HWG_RUNAPP )
{
   GError * error = NULL;
   gint rc = 0;
   g_spawn_command_line_async( hb_parc(1),  &error );
   if (error)
    {
        rc = error->code ;
        g_error_free(error);
    }
  hb_retni ( rc );
}

HB_FUNC( HWG_SHELLEXECUTE )
{
   const gchar * uri = hb_parc(1);
   hb_retl( gtk_show_uri( NULL, uri, GDK_CURRENT_TIME, NULL ) );
}

HB_FUNC( HWG_GETCENTURY )
{
  HB_BOOL centset = hb_setGetCentury();
  hb_retl(centset);
}

/* DF7BE: This functions works on GTK cross development environment */
HB_FUNC( HWG_ISWIN7 )
{
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retl( ovi.dwMajorVersion >= 6 && ovi.dwMinorVersion == 1 );
#else
   hb_retl( 1 == 2 );  /* .F.  for all other operating systems */
#endif
}

HB_FUNC( HWG_ISWIN10 )
{
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retl( ovi.dwMajorVersion >= 6 && ovi.dwMinorVersion == 2 );
#else
   hb_retl( 1 == 2 );  /* .F.  for all other operating systems */
#endif
}

HB_FUNC( HWG_GETWINMAJORVERS )
{
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retni( ovi.dwMajorVersion );
#else
   hb_retni( -1 );  /* -1  for all other operating systems */
#endif
}

HB_FUNC( HWG_GETWINMINORVERS )
{
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
   OSVERSIONINFO ovi;
   ovi.dwOSVersionInfoSize = sizeof ovi;
   ovi.dwMajorVersion = 0;
   ovi.dwMinorVersion = 0;
   GetVersionEx( &ovi );
   hb_retni( ovi.dwMinorVersion );
#else
   hb_retni( -1 );  /* -1  for all other operating systems */
#endif
}

HB_FUNC( HWG_GETTEMPDIR )
{
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetTempPath( MAX_PATH, szBuffer );
   HB_RETSTR( szBuffer );
#else
 char const * tempdirname = getenv("TMPDIR");

 if (tempdirname == NULL)
   { tempdirname = "/tmp"; }
   hb_retc(tempdirname);
#endif
}

HB_FUNC( HWG_GETWINDOWSDIR )
{
#if defined(_WIN32) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)
   TCHAR szBuffer[MAX_PATH + 1] = { 0 };

   GetWindowsDirectory( szBuffer, MAX_PATH );
   HB_RETSTR( szBuffer );
#else
   hb_retc("");
#endif
}

/* experimental state of this function */
HB_FUNC( HWG_GETKEYSTATE )
{
/*
  GdkModifierType keyboard_state;
  gdk_window_get_pointer(NULL,NULL,NULL,&keyboard_state);
   hb_retni( keyboard_state & hb_parni( 1 ) );
*/
}

HB_FUNC( HWG_SHOWSCROLLBAR )
{
}

/*
* ============================================
* FUNCTION hwg_STOD
* Extra implementation of STOD(),
* it is a Clipper tools function.
* For compatibilty purposes.
* Parameter 1: Date String
* in ANSI-Format YYYYMMDD.
* Result value is independant from
* SET DATE and SET CENTURY settings.
* Sample Call:
* ddate := hwg_STOD("20201108")
* ============================================
*/



HB_FUNC( HWG_STOD )
{
   PHB_ITEM pDateString = hb_param( 1, HB_IT_STRING );

   hb_retds( hb_itemGetCLen( pDateString ) >= 7 ? hb_itemGetCPtr( pDateString ) : NULL );
}

int hwg_hexbin(int cha)
/* converts single hex char to int, returns -1 , if not in range
   returns 0 - 15 (dec) , only a half byte */
{
    char gross;
    int o;

    gross = toupper(cha);
    switch (gross)
    {
     case 48:  /* 0 */
     o = 0;
     break;
     case 49:  /* 1 */
     o = 1;
     break;
     case 50:  /* 2 */
     o = 2;
     break;	
     case 51:  /* 3 */
     o = 3;
     break;
     case 52:  /* 4 */
     o = 4;
     break;
     case 53:  /* 5 */
     o = 5;
     break;
     case 54:  /* 6 */
     o = 6;
     break;	
     case 55:  /* 7 */
     o = 7	 ;
     break;
     case 56:  /* 8 */
     o = 8;
     break;	
     case 57:  /* 9 */
     o = 9;
     break;
     case 65:  /* A */
     o = 10;
     break;
     case 66:  /* B */
     o = 11;
     break;
     case 67:  /* C */
     o = 12;
     break;	
     case 68:  /* D */
     o = 13;
     break;
     case 69:  /* E */
     o = 14;
     break;	
     case 70:  /* F */
     o = 15;
     break;
     default:
     o = -1;
    }
    return o;
}

/*
   hwg_Bin2DC(cbin,nlen,ndec)
*/

HB_FUNC( HWG_BIN2DC )
{

    double pbyNumber;
    int i;
    unsigned char o;
    unsigned char bu[8];     /* Buffer with binary contents of double value */
    unsigned char szHex[17]; /* The hex string from parameter 1 + null byte*/


    int p;
    int c;      /* char with int value hex from hex */
    int od;     /* odd even sign / gerade - ungerade */

  /* init vars */

  pbyNumber = 0;

    szHex[0] = '\0';
    szHex[1] = '\0';
    szHex[2] = '\0';
    szHex[3] = '\0';
    szHex[4] = '\0';
    szHex[5] = '\0';
    szHex[6] = '\0';
    szHex[7] = '\0';
    szHex[8] = '\0';
    szHex[9] = '\0';
    szHex[10] = '\0';
    szHex[11] = '\0';
    szHex[12] = '\0';
    szHex[13] = '\0';
    szHex[14] = '\0';
    szHex[15] = '\0';
    szHex[16] = '\0';


    p = 0;
    c = 0;
    od = 0;

    // Internal I2BIN for Len

    HB_USHORT uiWidth = ( HB_USHORT ) hb_parni( 2 );

    // Internal I2BIN for Dec

    HB_USHORT uiDec = ( HB_USHORT ) hb_parni( 3 );


    const char *name = hb_parc( 1 );

    memcpy(&szHex,name,16);

    szHex[16] = '\0';

    // hwg_writelog(NULL,szHex);

    /* Convert hex to bin */

    for ( i = 0 ; i < 16; i++ )
     {

          c = hwg_hexbin(szHex[i]);
          /* ignore, if not in 0 ... 1, A ... F */
          if ( c  != -1 )
          {
           /* must be a pair of char,
              other values between the pairs of hex values are ignored */
            if ( od == 1 )
            {
                od = 0;
            }
            else
            {
                od = 1;
            }
            /* 1. Halbbyte zwischenspeichern / Store first half byte */
            if ( od == 1)
            {
              p = c;
            }
            else
            /* 2. Halbbyte verarbeiten, ganzes Byte ausspeichern
                / Process second half byte and store full byte */
            {
              p = ( p * 16 ) + c;
              o = (unsigned char) p;
              bu[ i / 2 ] = o;

/* Display some debug info */
//             printf("i=%d ", i);
//             printf("%d ", p);
//             printf("%s", " ");
//             printf("%c", o);
//             printf("%s", " ");
// 80  P 69  E 82  R 84  T 251  ยน 33  ! 9     64
// 50    45    52    54    FB     21    09    40

            }
          }
        }

    // hwg_writelog(NULL,szHex);

    /* Convert buffer to double */

    memcpy(&pbyNumber,bu,sizeof(pbyNumber));

    /* Return double value as type N */

    hb_retndlen( pbyNumber , uiWidth , uiDec );

}

static void GetFileMtimeU(const char * filePath)
{
/* Format: YYYYMMDD-HH:MM:SS  for example: 20211204-20:05:42 l= 17 + NULL byte */
 struct stat attrib;
 char date[18];
 stat (filePath, &attrib);

 strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", gmtime(&(attrib.st_mtime)));
 hb_retc(date);
}

static void GetFileMtime(const char * filePath)
{
/* Format: YYYYMMDD-HH:MM:SS  for example: 20211204-20:05:42 l= 17 + NULL byte */
 struct stat attrib;
 char date[18];
 stat (filePath, &attrib);
 strftime(date, sizeof(date) , "%Y%m%d-%H:%M:%S", localtime(&(attrib.st_mtime)));
 hb_retc(date);
}


HB_FUNC( HWG_FILEMODTIMEU )
{
 GetFileMtimeU( ( const char * ) hb_parc(1) );
}


HB_FUNC( HWG_FILEMODTIME )
{
 GetFileMtime( ( const char * ) hb_parc(1) );
}


/* hwg_Toggle_HalfByte_C(n) */
HB_FUNC( HWG_TOGGLE_HALFBYTE_C )
{
 int i,k,l;

 i = hb_parni( 1 );
 k = i & 15;
 l = i & 240;

 k = k << 4;
 l = l >> 4;

 hb_retni( l | k );

}

HB_FUNC( HWG_GUITYPE )
{
#if ( GTK_MAJOR_VERSION -0 < 3 )
  hb_retc( "GTK2" );
#else
  hb_retc( "GTK3" );
#endif
}

/* ========= EOF of misc.c ============ */
