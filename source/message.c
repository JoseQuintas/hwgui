/*
 *$Id: message.c,v 1.17 2010-02-06 02:06:43 druzus Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level messages functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#include <windows.h>

#include "hbapi.h"
#include "hwingui.h"

static int s_msgbox( UINT uType )
{
   void * hText, * hTitle;
   int iResult;

   iResult = MessageBox( GetActiveWindow(),
                         HB_PARSTR( 1, &hText, NULL ),
                         HB_PARSTRDEF( 2, &hTitle, NULL ),
                         uType );
   hb_strfree( hText );
   hb_strfree( hTitle );

   return iResult;
}

HB_FUNC( MSGINFO )
{
   s_msgbox( MB_OK | MB_ICONINFORMATION );
}

HB_FUNC( MSGSTOP )
{
   s_msgbox( MB_OK | MB_ICONSTOP );
}

HB_FUNC( MSGOKCANCEL )
{
   hb_retni( s_msgbox( MB_OKCANCEL | MB_ICONQUESTION ) );
}

HB_FUNC( MSGYESNO )
{
   hb_retl( s_msgbox( MB_YESNO | MB_ICONQUESTION ) == IDYES );
}

HB_FUNC( MSGNOYES )
{
   hb_retl( s_msgbox( MB_YESNO | MB_ICONQUESTION | MB_DEFBUTTON2 ) == IDYES );
}

HB_FUNC( MSGYESNOCANCEL )
{
   hb_retni( s_msgbox( MB_YESNOCANCEL | MB_ICONQUESTION ) );
}

HB_FUNC( MSGEXCLAMATION )
{
   s_msgbox( MB_ICONEXCLAMATION | MB_OK | MB_SYSTEMMODAL );
}

HB_FUNC( MSGRETRYCANCEL )
{
   hb_retni( s_msgbox( MB_RETRYCANCEL | MB_ICONQUESTION | MB_ICONQUESTION ) );
}

HB_FUNC( MSGBEEP )
{
   MessageBeep( ( hb_pcount() == 0 ) ? ( LONG ) 0xFFFFFFFF : hb_parnl( 1 ) );
}


#include <commctrl.h>
#include <richedit.h>
HB_FUNC( MSGTEMP )
{
   char cres[ 60 ];
   LPCTSTR msg;

#if __HARBOUR__ - 0 >= 0x010100
   hb_snprintf( cres, sizeof( cres ), "WS_OVERLAPPEDWINDOW: %lx NM_FIRST: %d ",
                ( LONG ) WS_OVERLAPPEDWINDOW, NM_FIRST );
#else
   sprintf( cres, "WS_OVERLAPPEDWINDOW: %lx NM_FIRST: %d ",
            ( LONG ) WS_OVERLAPPEDWINDOW, NM_FIRST );
#endif
   {
#ifdef UNICODE
      TCHAR wcres[ 60 ];
      MultiByteToWideChar( CP_ACP, 0, cres, -1, wcres, HB_SIZEOFARRAY( wcres ) );
      msg = wcres;
#else
      msg = cres;
#endif
      hb_retni( MessageBox( GetActiveWindow(), msg, TEXT( "DialogBaseUnits" ),
                            MB_OKCANCEL | MB_ICONQUESTION ) );
   }
}
