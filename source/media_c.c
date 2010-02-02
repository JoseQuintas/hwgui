/*
 * $Id: media_c.c,v 1.15 2010-02-02 12:18:55 druzus Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level media functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#define OEMRESOURCE
#include <windows.h>
#include <commctrl.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "guilib.h"

/*
 *  PlaySound( cName, lSync, lLoop )
 */
HB_FUNC( PLAYSOUND )
{
   LPCSTR pszSound =  hb_parc( 1 );
   HMODULE hmod = NULL;
   DWORD fdwSound = SND_NODEFAULT | SND_FILENAME;

   if( hb_parl( 2 ) )
      fdwSound |= SND_SYNC;
   else
      fdwSound |= SND_ASYNC;

   if( hb_parl( 3 ) )
      fdwSound |= SND_LOOP;
   if( !pszSound )
      fdwSound |= SND_PURGE;

   hb_retl( PlaySound( pszSound, hmod, fdwSound ) );
}

HB_FUNC( MCISENDSTRING )
{
   TCHAR cBuffer[128];

   hb_retnl( ( LONG ) mciSendString( hb_parc( 1 ),
                                     cBuffer, 127,
                                     ( ISNIL( 3 ) ) ? GetActiveWindow() :
                                     ( HWND ) HB_PARHANDLE( 3 ) ) );
   if( !ISNIL( 2 ) )
      hb_storc( cBuffer, 2 );
}



/* Functions bellow for play video's and wav's*/

HB_FUNC( MCISENDCOMMAND )       // ()
{
   hb_retnl( mciSendCommand( hb_parni( 1 ),     // Device ID
               hb_parni( 2 ),   // Command Message
               hb_parnl( 3 ),   // Flags
               ( DWORD ) hb_parc( 4 ) ) );      // Parameter Block
}

//----------------------------------------------------------------------------//


HB_FUNC( MCIGETERRORSTRING )    // ()
{
   TCHAR cBuffer[200];

   hb_retl( mciGetErrorString( hb_parnl( 1 ),   // Error Code
                               cBuffer, HB_SIZEOFARRAY( cBuffer ) ) );
   hb_storc( cBuffer, 2 );
}

//----------------------------------------------------------------------------//

HB_FUNC( NMCIOPEN )
{
   MCI_OPEN_PARMS mciOpenParms;
   DWORD dwFlags = MCI_OPEN_ELEMENT;

   mciOpenParms.lpstrDeviceType = hb_parc( 1 );

   if( ISCHAR( 2 ) )
   {
      mciOpenParms.lpstrElementName = hb_parc( 2 );
      dwFlags |= MCI_OPEN_TYPE;
   }

   hb_retnl( mciSendCommand( 0, MCI_OPEN, dwFlags,
               ( DWORD ) ( LPMCI_OPEN_PARMS ) & mciOpenParms ) );


   hb_storni( mciOpenParms.wDeviceID, 3 );
}

//----------------------------------------------------------------------------//

HB_FUNC( NMCIPLAY )
{
   MCI_PLAY_PARMS mciPlayParms;
   DWORD dwFlags = 0;

   if( hb_parnl( 2 ) )
   {
      mciPlayParms.dwFrom = hb_parnl( 2 );
      dwFlags |= MCI_FROM;
   }

   if( hb_parnl( 3 ) )
   {
      mciPlayParms.dwTo = hb_parnl( 3 );
      dwFlags |= MCI_TO;
   }

   if( hb_parni( 4 ) )
   {
      mciPlayParms.dwCallback = ( DWORD ) ( LPVOID ) hb_parni( 4 );
      dwFlags |= MCI_NOTIFY;
   }

   hb_retnl( mciSendCommand( hb_parni( 1 ),     // Device ID
               MCI_PLAY, dwFlags,
               ( DWORD ) ( LPMCI_PLAY_PARMS ) & mciPlayParms ) );
}

//----------------------------------------------------------------------------//

HB_FUNC( NMCIWINDOW )
{
   MCI_ANIM_WINDOW_PARMS mciWindowParms;
   HWND hWnd = ( HWND ) HB_PARHANDLE( 2 );

   mciWindowParms.hWnd = hWnd;

   hb_retnl( mciSendCommand( hb_parni( 1 ), MCI_WINDOW,
               MCI_ANIM_WINDOW_HWND | MCI_ANIM_WINDOW_DISABLE_STRETCH,
               ( LONG ) ( LPMCI_ANIM_WINDOW_PARMS ) & mciWindowParms ) );
}
