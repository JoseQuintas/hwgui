/*
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

/*
 *  PlaySound( cName, lSync, lLoop )
 */
HB_FUNC ( PLAYSOUND )
{
   LPCSTR pszSound = ( hb_pcount()>0 && ISCHAR(1) )? hb_parc(1):NULL;
   HMODULE hmod = NULL;
   DWORD fdwSound = SND_NODEFAULT | SND_FILENAME;

   if( hb_pcount()>1 && ISLOG(2) && hb_parl(2) )
      fdwSound |= SND_SYNC;
   else
      fdwSound |= SND_ASYNC;
   if( hb_pcount()>2 && ISLOG(3) && hb_parl(3) )
      fdwSound |= SND_LOOP;
   if( !pszSound )
      fdwSound |= SND_PURGE;

   hb_retl( PlaySound( pszSound, hmod, fdwSound ) );

}

HB_FUNC ( MCISENDSTRING )
{
   BYTE cBuffer[128];

   hb_retnl( (LONG) mciSendString( (LPSTR) hb_parc(1), (LPSTR) cBuffer, 127,
               ( ISNIL(3) )? GetActiveWindow() : (HWND)hb_parnl(3) ) );
   if( !ISNIL(2) )
      hb_storc( cBuffer,2 );
}
