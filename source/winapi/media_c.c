/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level media functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
*/

#include "hwingui.h"
#include <commctrl.h>

#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

/*
 *  PlaySound( cName, lSync, lLoop )
 */
HB_FUNC( HWG_PLAYSOUND )
{
   void *hSound;
   LPCTSTR lpSound = HB_PARSTR( 1, &hSound, NULL );
   HMODULE hmod = NULL;
   DWORD fdwSound = SND_NODEFAULT | SND_FILENAME;

   if( hb_parl( 2 ) )
      fdwSound |= SND_SYNC;
   else
      fdwSound |= SND_ASYNC;

   if( hb_parl( 3 ) )
      fdwSound |= SND_LOOP;
   if( !lpSound )
      fdwSound |= SND_PURGE;

   hb_retl( PlaySound( lpSound, hmod, fdwSound ) != 0 );
   hb_strfree( hSound );
}

HB_FUNC( HWG_MCISENDSTRING )
{
   TCHAR cBuffer[256] = { 0 };
   void *hCommand;

   hb_retnl( ( LONG ) mciSendString( HB_PARSTR( 1, &hCommand, NULL ),
               cBuffer, HB_SIZEOFARRAY( cBuffer ),
               ( HB_ISNIL( 3 ) ) ? GetActiveWindow(  ) :
               ( HWND ) HB_PARHANDLE( 3 ) ) );
   if( !HB_ISNIL( 2 ) )
      HB_STORSTR( cBuffer, 2 );
   hb_strfree( hCommand );
}



/* Functions bellow for play video's and wav's*/

HB_FUNC( HWG_MCISENDCOMMAND )
{
   hb_retnl( mciSendCommand( hb_parni( 1 ),     // Device ID
               hb_parni( 2 ),   // Command Message
               hb_parnl( 3 ),   // Flags
               ( DWORD_PTR ) hb_parc( 4 ) ) );      // Parameter Block
}

//----------------------------------------------------------------------------//


HB_FUNC( HWG_MCIGETERRORSTRING )
{
   TCHAR cBuffer[256] = { 0 };

   hb_retl( mciGetErrorString( hb_parnl( 1 ),   // Error Code
               cBuffer, HB_SIZEOFARRAY( cBuffer ) ) );
   HB_STORSTR( cBuffer, 2 );
}

//----------------------------------------------------------------------------//

HB_FUNC( HWG_NMCIOPEN )
{
   MCI_OPEN_PARMS mciOpenParms;
   DWORD dwFlags = MCI_OPEN_ELEMENT;
   void *hDevice, *hName;

   memset( &mciOpenParms, 0, sizeof( mciOpenParms ) );

   mciOpenParms.lpstrDeviceType = HB_PARSTR( 1, &hDevice, NULL );
   mciOpenParms.lpstrElementName = HB_PARSTR( 2, &hName, NULL );
   if( mciOpenParms.lpstrElementName )
      dwFlags |= MCI_OPEN_TYPE;

   hb_retnl( mciSendCommand( 0, MCI_OPEN, dwFlags,
               ( DWORD_PTR ) ( LPMCI_OPEN_PARMS ) & mciOpenParms ) );

   hb_storni( mciOpenParms.wDeviceID, 3 );
   hb_strfree( hDevice );
   hb_strfree( hName );
}

//----------------------------------------------------------------------------//

HB_FUNC( HWG_NMCIPLAY )
{
   MCI_PLAY_PARMS mciPlayParms;
   DWORD dwFlags = 0;

   memset( &mciPlayParms, 0, sizeof( mciPlayParms ) );

   if( ( mciPlayParms.dwFrom = hb_parnl( 2 ) ) != 0 )
      dwFlags |= MCI_FROM;

   if( ( mciPlayParms.dwTo = hb_parnl( 3 ) ) != 0 )
      dwFlags |= MCI_TO;

   hb_retnl( mciSendCommand( hb_parni( 1 ),     // Device ID
               MCI_PLAY, dwFlags,
               ( DWORD_PTR ) ( LPMCI_PLAY_PARMS ) & mciPlayParms ) );
}

//----------------------------------------------------------------------------//

HB_FUNC( HWG_NMCIWINDOW )
{
   MCI_ANIM_WINDOW_PARMS mciWindowParms;
   HWND hWnd = ( HWND ) HB_PARHANDLE( 2 );

   mciWindowParms.hWnd = hWnd;

   hb_retnl( mciSendCommand( hb_parni( 1 ), MCI_WINDOW,
               MCI_ANIM_WINDOW_HWND | MCI_ANIM_WINDOW_DISABLE_STRETCH,
               ( DWORD_PTR ) ( LPMCI_ANIM_WINDOW_PARMS ) & mciWindowParms ) );
}
