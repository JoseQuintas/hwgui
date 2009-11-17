#define _WIN32_IE      0x0500
#define HB_OS_WIN_32_USED
#define _WIN32_WINNT   0x0400

#include <windows.h>
#include <commctrl.h>
#include "hbapi.h"
#include "guilib.h"

HB_FUNC( ANIMATE_CREATE )
{
   HWND hwnd;

   hwnd = Animate_Create( ( HWND ) HB_PARHANDLE( 1 ), ( LONG ) hb_parnl( 2 ),
         ( LONG ) hb_parnl( 3 ), GetModuleHandle( NULL ) );
   MoveWindow( hwnd, hb_parnl( 4 ), hb_parnl( 5 ), hb_parnl( 6 ),
         hb_parnl( 7 ), TRUE );
   HB_RETHANDLE( hwnd );
}

HB_FUNC( ANIMATE_OPEN )
{
   Animate_Open( ( HWND ) HB_PARHANDLE( 1 ), hb_parc( 2 ) );
}

HB_FUNC( ANIMATE_PLAY )
{
   Animate_Play( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ), hb_parni( 3 ),
         hb_parni( 4 ) );
}

HB_FUNC( ANIMATE_SEEK )
{
   Animate_Seek( ( HWND ) HB_PARHANDLE( 1 ), hb_parni( 2 ) );
}

HB_FUNC( ANIMATE_STOP )
{
   Animate_Stop( ( HWND ) HB_PARHANDLE( 1 ) );
}

HB_FUNC( ANIMATE_CLOSE )
{
   Animate_Close( ( HWND ) HB_PARHANDLE( 1 ) );
}

HB_FUNC( ANIMATE_DESTROY )
{
   DestroyWindow( ( HWND ) HB_PARHANDLE( 1 ) );
}

HB_FUNC( ANIMATE_OPENEX )
{
   ISNIL( 2 ) ?
   Animate_OpenEx( ( HWND ) HB_PARHANDLE( 1 ),
                   NULL ,
                   ISNUM( 3 ) ? ( LPCTSTR ) MAKEINTRESOURCE( hb_parnl( 3 ) ) : ( LPCTSTR ) hb_parc( 3 ) ) :
   Animate_OpenEx( ( HWND ) HB_PARHANDLE( 1 ),
                   ( HINSTANCE ) hb_parnl( 2 ),
                   ISNUM( 3 ) ? ( LPCTSTR ) MAKEINTRESOURCE( hb_parnl( 3 ) ) : ( LPCTSTR ) hb_parc( 3 ) ) ;
}
