/*
 * $Id: window.c,v 1.83 2010-01-24 15:31:16 druzus Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level windows functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#define _WIN32_IE    0x0400
#define OEMRESOURCE
#include <windows.h>
#include <commctrl.h>
#if defined(__DMC__)
#include "missing.h"
#endif
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#if !defined(__XHARBOUR__)
#include "hbapicls.h"
#endif

#include <math.h>
#include <float.h>
#include <limits.h>
#include "hwingui.h"

#define  FIRST_MDICHILD_ID     501

LRESULT CALLBACK MainWndProc( HWND, UINT, WPARAM, LPARAM );
LRESULT CALLBACK FrameWndProc( HWND, UINT, WPARAM, LPARAM );
LRESULT CALLBACK MDIChildWndProc( HWND, UINT, WPARAM, LPARAM );

HWND hMytoolMenu = NULL;
static HHOOK OrigDockHookProc;
extern int iDialogs;

HWND aWindows[2] = { 0, 0 };
HACCEL hAccel = NULL;
PHB_DYNS pSym_onEvent = NULL;
PHB_DYNS pSym_onEven_Tool = NULL;
// static PHB_DYNS pSym_MDIWnd = NULL;

static LPCTSTR s_szChild = TEXT( "MDICHILD" );

static void s_doEvents( void )
{
   MSG msg;

   while( PeekMessage( &msg, ( HWND ) NULL, 0, 0, PM_REMOVE ) )
   {
      TranslateMessage( &msg );
      DispatchMessage( &msg );
   };
}

/* Consume all queued events, useful to update all the controls... I split in 2 parts because I feel
 * that s_doEvents should be called internally by some other functions...
 */
HB_FUNC( HWG_DOEVENTS )
{
   s_doEvents(  );
}

/*  Creates main application window
    InitMainWindow( szAppName, cTitle, cMenu, hIcon, nBkColor, nStyle, nLeft, nTop, nWidth, nHeight )
*/

HB_FUNC( HWG_INITMAINWINDOW )
{
   HWND hWnd;
   WNDCLASS wndclass;
   HANDLE hInstance = GetModuleHandle( NULL );
   DWORD ExStyle = 0;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   const char *szAppName = hb_parc( 2 );
   const char *cTitle = hb_parc( 3 );
   LONG nStyle = hb_parnl( 7 );
   const char *cMenu = hb_parc( 4 );
   int x = hb_parnl( 8 );
   int y = hb_parnl( 9 );
   int width = hb_parnl( 10 );
   int height = hb_parnl( 11 );

   if( aWindows[0] )
   {
      hb_retni( 0 );
      return;
   }

   wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
   wndclass.lpfnWndProc = MainWndProc;
   wndclass.cbClsExtra = 0;
   wndclass.cbWndExtra = 0;
   wndclass.hInstance = ( HINSTANCE ) hInstance;
   wndclass.hIcon = ( hb_pcount(  ) > 4 &&
         !ISNIL( 5 ) ) ? ( HICON ) HB_PARHANDLE( 5 ) : LoadIcon( ( HINSTANCE )
         hInstance, "" );
   wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
   wndclass.hbrBackground = ( ( ( hb_pcount(  ) > 5 &&
                     !ISNIL( 6 ) ) ? ( ( hb_parnl( 6 ) ==
                           -1 ) ? ( HBRUSH ) NULL : ( HBRUSH )
                     HB_PARHANDLE( 6 ) ) : ( HBRUSH ) ( COLOR_WINDOW +
                     1 ) ) );
   wndclass.lpszMenuName = cMenu;
   wndclass.lpszClassName = szAppName;

   if( !RegisterClass( &wndclass ) )
   {
      hb_retni( 0 );
      return;
   }

   hWnd = CreateWindowEx( ExStyle, szAppName, cTitle,
         WS_OVERLAPPEDWINDOW | nStyle,
         x, y,
         ( !width ) ? ( LONG ) CW_USEDEFAULT : width,
         ( !height ) ? ( LONG ) CW_USEDEFAULT : height,
         NULL, NULL, ( HINSTANCE ) hInstance, NULL );

   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );

   aWindows[0] = hWnd;
   HB_RETHANDLE( hWnd );
}

HB_FUNC( HWG_CENTERWINDOW )
{
   RECT rect;
   int w, h, x, y;

   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &rect );

   w = rect.right - rect.left;
   h = rect.bottom - rect.top;
   x = GetSystemMetrics( SM_CXSCREEN );
   y = GetSystemMetrics( SM_CYSCREEN );

   SetWindowPos( ( HWND ) HB_PARHANDLE( 1 ), HWND_TOP, ( x - w ) / 2,
         ( y - h ) / 2, 0, 0, SWP_NOSIZE );
}

void ProcessMessage( MSG msg, HACCEL hAcceler, BOOL lMdi )
{
   int i;
   HWND hwndGoto;

   for( i = 0; i < iDialogs; i++ )
   {
      hwndGoto = aDialogs[i];
      if( IsWindow( hwndGoto ) && IsDialogMessage( hwndGoto, &msg ) )
         break;
   }

   if( i == iDialogs )
   {
      if( lMdi && TranslateMDISysAccel( aWindows[1], &msg ) )
         return;

      if( !hAcceler || !TranslateAccelerator( aWindows[0], hAcceler, &msg ) )
      {
         TranslateMessage( &msg );
         DispatchMessage( &msg );
      }
   }
}

void ProcessMdiMessage( HWND hJanBase, HWND hJanClient, MSG msg,
      HACCEL hAcceler )
{
   if( !TranslateMDISysAccel( hJanClient, &msg ) &&
         !TranslateAccelerator( hJanBase, hAcceler, &msg ) )
   {
      TranslateMessage( &msg );
      DispatchMessage( &msg );
   }
}

/*
 *  HWG_ACTIVATEMAINWINDOW( lShow, hAccel, lMaximize, lMinimize )
 */
HB_FUNC( HWG_ACTIVATEMAINWINDOW )
{
   HACCEL hAcceler = ( ISNIL( 2 ) ) ? NULL : ( HACCEL ) hb_parnl( 2 );
   MSG msg;

   if( hb_parl( 1 ) )
   {
      ShowWindow( aWindows[0], ( ISLOG( 3 ) &&
                  hb_parl( 3 ) ) ? SW_SHOWMAXIMIZED : ( ( ISLOG( 4 ) &&
                        hb_parl( 4 ) ) ? SW_SHOWMINIMIZED : SW_SHOWNORMAL ) );
   }

   while( GetMessage( &msg, NULL, 0, 0 ) )
   {
      ProcessMessage( msg, hAcceler, 0 );
   }
}

HB_FUNC( HWG_PROCESSMESSAGE )
{
   MSG msg;
   BOOL lMdi = ( ISNIL( 1 ) ) ? 0 : hb_parl( 1 );
   int nSleep = ( ISNIL( 2 ) ) ? 1 : hb_parni( 2 );

   if( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE ) )
   {
      ProcessMessage( msg, 0, lMdi );
   }

   SleepEx( nSleep, TRUE );
}

/* 22/09/2005 - <maurilio.longo@libero.it>
					 It can be used to see if there are messages awaiting of a certain
					 type, but it does not retrieve them
*/
HB_FUNC( HWG_PEEKMESSAGE )
{
   MSG msg;

   hb_retl( PeekMessage( &msg, ( HWND ) HB_PARHANDLE( 1 ),      // handle of window whose message queue will be searched
               ( UINT ) hb_parni( 2 ),  // wMsgFilterMin,
               ( UINT ) hb_parni( 3 ),  // wMsgFilterMax,
               PM_NOREMOVE ) );
}

HB_FUNC( HWG_INITCHILDWINDOW )
{
   HWND hWnd;
   WNDCLASS wndclass;
   HMODULE /*HANDLE*/ hInstance = GetModuleHandle( NULL );
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   const char *szAppName = hb_parc( 2 );
   const char *cTitle = hb_parc( 3 );
   LONG nStyle = ( ISNIL( 7 ) ? 0 : hb_parnl( 7 ) );
   const char *cMenu = hb_parc( 4 );
   int x = hb_parnl( 8 );
   int y = hb_parnl( 9 );
   int width = hb_parnl( 10 );
   int height = hb_parnl( 11 );
   HWND hParent = ( HWND ) HB_PARHANDLE( 12 );
   DWORD ExStyle;

   if( !GetClassInfo( hInstance, szAppName, &wndclass ) )
   {
      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc = MainWndProc;
      wndclass.cbClsExtra = 0;
      wndclass.cbWndExtra = 0;
      wndclass.hInstance = ( HINSTANCE ) hInstance;
      wndclass.hIcon = ( hb_pcount(  ) > 4 &&
            !ISNIL( 5 ) ) ? ( HICON ) HB_PARHANDLE( 5 ) :
            LoadIcon( ( HINSTANCE ) hInstance, "" );
      wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
      wndclass.hbrBackground = ( ( ( hb_pcount(  ) > 5 && !ISNIL( 6 ) ) ?
                  ( ( hb_parnl( 6 ) ==
                              -1 ) ? ( HBRUSH ) NULL : ( HBRUSH )
                        HB_PARHANDLE( 6 ) ) : ( HBRUSH ) ( COLOR_WINDOW +
                        1 ) ) );
      /*
         wndclass.hbrBackground = ( ( (hb_pcount()>5 && !ISNIL(6))?
         ( (hb_parnl(6)==-1)? (HBRUSH)(COLOR_WINDOW+1) :
         CreateSolidBrush( hb_parnl(6) ) )
         : (HBRUSH)(COLOR_WINDOW+1) ) );
       */
      wndclass.lpszMenuName = cMenu;
      wndclass.lpszClassName = szAppName;

      //UnregisterClass( szAppName, (HINSTANCE)hInstance );
      if( !RegisterClass( &wndclass ) )
      {
         hb_retni( 0 );

#ifdef __XHARBOUR__
         MessageBox( GetActiveWindow(  ), szAppName,
               "Register Child Wnd Class", MB_OK | MB_ICONSTOP );
#endif

         return;
      }
   }

   ExStyle = WS_EX_MDICHILD;    //0;

   hWnd = CreateWindowEx( ExStyle, szAppName, cTitle,
         WS_OVERLAPPEDWINDOW | nStyle, x, y,
         ( !width ) ? ( LONG ) CW_USEDEFAULT : width,
         ( !height ) ? ( LONG ) CW_USEDEFAULT : height,
         hParent, NULL, ( HINSTANCE ) hInstance, NULL );

   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );

   HB_RETHANDLE( hWnd );
}

HB_FUNC( HWG_ACTIVATECHILDWINDOW )
{
   // ShowWindow( (HWND) HB_PARHANDLE(2), hb_parl(1) ? SW_SHOWNORMAL : SW_HIDE );
   ShowWindow( ( HWND ) HB_PARHANDLE( 2 ), ( ISLOG( 3 ) &&
               hb_parl( 3 ) ) ? SW_SHOWMAXIMIZED : ( ( ISLOG( 4 ) &&
                     hb_parl( 4 ) ) ? SW_SHOWMINIMIZED : SW_SHOWNORMAL ) );
}

/*  Creates frame MDI and client window
    InitMainWindow( cTitle, cMenu, cBitmap, hIcon, nBkColor, nStyle, nLeft, nTop, nWidth, nHeight )
*/
HB_FUNC( HWG_INITMDIWINDOW )
{
   HWND hWnd;
   WNDCLASS wndclass, wc;
   HANDLE hInstance = GetModuleHandle( NULL );
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   const char *szAppName = hb_parc( 2 );
   const char *cTitle = hb_parc( 3 );
   const char *cMenu = hb_parc( 4 );
   int x = hb_parnl( 8 );
   int y = hb_parnl( 9 );
   int width = hb_parnl( 10 );
   int height = hb_parnl( 11 );

   if( aWindows[0] )
   {
      hb_retni( -1 );
      return;
   }

   // Register frame window
   wndclass.style = 0;
   wndclass.lpfnWndProc = FrameWndProc;
   wndclass.cbClsExtra = 0;
   wndclass.cbWndExtra = 0;
   wndclass.hInstance = ( HINSTANCE ) hInstance;
   wndclass.hIcon = ( hb_pcount(  ) > 4 &&
         !ISNIL( 5 ) ) ? ( HICON ) HB_PARHANDLE( 5 ) : LoadIcon( ( HINSTANCE )
         hInstance, "" );
   wndclass.hCursor = LoadCursor( NULL, IDC_ARROW );
   wndclass.hbrBackground = ( HBRUSH ) ( COLOR_WINDOW + 1 );
   wndclass.lpszMenuName = cMenu;
   wndclass.lpszClassName = szAppName;

   if( !RegisterClass( &wndclass ) )
   {
      hb_retni( -2 );
      return;
   }

   // Register client window
   wc.lpfnWndProc = ( WNDPROC ) MDIChildWndProc;
   wc.hIcon = ( hb_pcount(  ) > 4 && !ISNIL( 5 ) ) ?
       ( HICON ) HB_PARHANDLE( 5 ) : LoadIcon( ( HINSTANCE ) hInstance, "" );
   wc.hbrBackground = ( hb_pcount(  ) > 5 && !ISNIL( 6 ) ) ?
       ( HBRUSH ) HB_PARHANDLE( 6 ) : ( HBRUSH ) ( COLOR_WINDOW + 1 );
   wc.lpszMenuName = NULL;
   wc.cbWndExtra = 0;
   wc.lpszClassName = s_szChild;
   wc.cbClsExtra = 0;
   wc.hInstance = ( HINSTANCE ) hInstance;
   wc.hCursor = LoadCursor( NULL, IDC_ARROW );
   wc.style = 0;

   if( !RegisterClass( &wc ) )
   {
      hb_retni( -3 );
      return;
   }

   // Create frame window
   hWnd = CreateWindow( szAppName, cTitle,
         WS_OVERLAPPEDWINDOW,
         x, y,
         ( !width ) ? ( LONG ) CW_USEDEFAULT : width,
         ( !height ) ? ( LONG ) CW_USEDEFAULT : height,
         NULL, NULL, ( HINSTANCE ) hInstance, NULL );
   if( !hWnd )
   {
      hb_retni( -4 );
      return;
   }

   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );

   aWindows[0] = hWnd;
   HB_RETHANDLE( hWnd );
}

HB_FUNC( HWG_INITCLIENTWINDOW )
{
   CLIENTCREATESTRUCT ccs;
   HWND hWnd;
   int nPos = ( hb_pcount(  ) > 1 && !ISNIL( 2 ) ) ? hb_parni( 2 ) : 0;
   int x = hb_parnl( 3 );
   int y = hb_parnl( 4 );
   int width = hb_parnl( 5 );
   int height = hb_parnl( 6 );

   // Create client window
   ccs.hWindowMenu = GetSubMenu( GetMenu( aWindows[0] ), nPos );
   ccs.idFirstChild = FIRST_MDICHILD_ID;

   hWnd = CreateWindow( "MDICLIENT", NULL,
         WS_CHILD | WS_CLIPCHILDREN | MDIS_ALLCHILDSTYLES,
         x, y, width, height,
         aWindows[0], NULL, GetModuleHandle( NULL ), ( LPVOID ) &ccs );

   aWindows[1] = hWnd;
   HB_RETHANDLE( hWnd );
}

HB_FUNC( HWG_ACTIVATEMDIWINDOW )
{
   HACCEL hAcceler = ( ISNIL( 2 ) ) ? NULL : ( HACCEL ) hb_parnl( 2 );
   MSG msg;

   if( hb_parl( 1 ) )
   {
      ShowWindow( aWindows[0], ( ISLOG( 3 ) &&
                  hb_parl( 3 ) ) ? SW_SHOWMAXIMIZED : ( ( ISLOG( 4 ) &&
                        hb_parl( 4 ) ) ? SW_SHOWMINIMIZED : SW_SHOWNORMAL ) );
      ShowWindow( aWindows[1], SW_SHOW );
   }

   while( GetMessage( &msg, NULL, 0, 0 ) )
   {
      // ProcessMessage( msg, hAcceler, 0 );
      ProcessMdiMessage( aWindows[0], aWindows[1], msg, hAcceler );
   }
}

/*  Creates child MDI window
    CreateMdiChildWindow( aChildWindow )
    aChildWindow = { cWindowTitle, Nil, aActions, Nil,
                    nStatusWindowID, bStatusWrite }
    aActions = { { nMenuItemID, bAction }, ... }
*/

HB_FUNC( HWG_CREATEMDICHILDWINDOW )
{
   HWND hWnd;
   PHB_ITEM pObj = hb_param( 1, HB_IT_OBJECT );
   const char *cTitle = hb_itemGetCPtr( GetObjectVar( pObj, "TITLE" ) );
   DWORD style = ( DWORD ) hb_itemGetNL( GetObjectVar( pObj, "STYLE" ) );
   int y = ( int ) hb_itemGetNL( GetObjectVar( pObj, "NTOP" ) );
   int x = ( int ) hb_itemGetNL( GetObjectVar( pObj, "NLEFT" ) );
   int width = ( int ) hb_itemGetNL( GetObjectVar( pObj, "NWIDTH" ) );
   int height = ( int ) hb_itemGetNL( GetObjectVar( pObj, "NHEIGHT" ) );

   //if( !style )
   //   style = WS_VISIBLE | WS_OVERLAPPEDWINDOW | WS_MAXIMIZE;

   if( !style )
      style = WS_CHILD | WS_OVERLAPPEDWINDOW | ( int ) hb_parnl( 2 );   //WS_VISIBLE | WS_MAXIMIZE;
   else
      style = style | ( int ) hb_parnl( 2 );

   if( !aWindows[0] )
   {
      hb_retni( 0 );
      return;
   }

   hWnd = CreateMDIWindow(
               (LPSTR) s_szChild,         // pointer to registered child class name
               (LPSTR) cTitle,            // pointer to window name
               style,                     // window style
               x,                         // horizontal position of window
               y,                         // vertical position of window
               width,                     // width of window
               height,                    // height of window
               ( HWND ) aWindows[1],      // handle to parent window (MDI client)
               GetModuleHandle( NULL ),   // handle to application instance
               ( LPARAM ) & pObj          // application-defined value
          );

   HB_RETHANDLE( hWnd );
}

HB_FUNC( SENDMESSAGE )
{
   hb_retnl( ( LONG ) SendMessage( ( HWND ) HB_PARHANDLE( 1 ),  // handle of destination window
               ( UINT ) hb_parni( 2 ),  // message to send
               ( WPARAM ) hb_parnl( 3 ),        // first message parameter
               ( ISCHAR( 4 ) ) ? ( LPARAM ) hb_parc( 4 ) : ISPOINTER( 4 ) ? ( LPARAM ) HB_PARHANDLE( 4 ) : ( LPARAM ) hb_parnl( 4 )     // second message parameter
          ) );
}

HB_FUNC( POSTMESSAGE )
{

   hb_retnl( ( LONG ) PostMessage( ( HWND ) HB_PARHANDLE( 1 ),  // handle of destination window
               ( UINT ) hb_parni( 2 ),  // message to send
               ISPOINTER( 3 ) ? ( WPARAM ) HB_PARHANDLE( 3 ) : ( WPARAM ) hb_parnl( 3 ),        // first message parameter
               ( LPARAM ) hb_parnl( 4 ) // second message parameter
          ) );

}

HB_FUNC( SETFOCUS )
{
   HB_RETHANDLE( SetFocus( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( GETFOCUS )
{
   HB_RETHANDLE( GetFocus(  ) );
}

HB_FUNC( SETWINDOWOBJECT )
{
   SetWindowObject( ( HWND ) HB_PARHANDLE( 1 ), hb_param( 2, HB_IT_OBJECT ) );
}

void SetWindowObject( HWND hWnd, PHB_ITEM pObject )
{
   SetWindowLongPtr( hWnd, GWL_USERDATA,
         pObject ? ( LPARAM ) hb_itemNew( pObject ) : 0 );
}

HB_FUNC( GETWINDOWOBJECT )
{
   hb_itemReturn( ( PHB_ITEM ) GetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ),
               GWL_USERDATA ) );
}

HB_FUNC( SETWINDOWTEXT )
{
   SetWindowText( ( HWND ) HB_PARHANDLE( 1 ), hb_parc( 2 ) );
}

HB_FUNC( GETWINDOWTEXT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   USHORT iLen = ( USHORT ) SendMessage( hWnd, WM_GETTEXTLENGTH, 0, 0 );
   char *cText = ( char * ) hb_xgrab( iLen + 2 );

   iLen = ( USHORT ) SendMessage( hWnd, WM_GETTEXT, ( WPARAM ) ( iLen + 1 ),
         ( LPARAM ) cText );

   hb_retc( ( iLen > 0 ) ? cText : "" );
   hb_xfree( cText );
}

HB_FUNC( SETWINDOWFONT )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), WM_SETFONT,
         ( WPARAM ) hb_parnl( 2 ),
         MAKELPARAM( ( ISNIL( 3 ) ) ? 0 : hb_parl( 3 ), 0 ) );
}

HB_FUNC( ENABLEWINDOW )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   BOOL lEnable = hb_parl( 2 );

   // ShowWindow( hWnd, (lEnable)? SW_SHOWNORMAL:SW_HIDE );
   EnableWindow( hWnd,          // handle to window
         lEnable                // flag for enabling or disabling input
          );
}

HB_FUNC( DESTROYWINDOW )
{
   DestroyWindow( ( HWND ) HB_PARHANDLE( 1 ) );
}

HB_FUNC( HIDEWINDOW )
{
   ShowWindow( ( HWND ) HB_PARHANDLE( 1 ), SW_HIDE );
}

HB_FUNC( SHOWWINDOW )
{
   ShowWindow( ( HWND ) HB_PARHANDLE( 1 ), SW_SHOW );
}

HB_FUNC( HWG_RESTOREWINDOW )
{
   ShowWindow( ( HWND ) HB_PARHANDLE( 1 ), SW_RESTORE );
}

HB_FUNC( HWG_ISICONIC )
{
   hb_retl( IsIconic( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( ISWINDOWENABLED )
{
   hb_retl( IsWindowEnabled( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( ISWINDOWVISIBLE )
{
   hb_retl( IsWindowVisible( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( GETACTIVEWINDOW )
{
   HB_RETHANDLE( GetActiveWindow(  ) );
}

HB_FUNC( GETINSTANCE )
{
   hb_retnl( ( LONG ) GetModuleHandle( NULL ) );
}

HB_FUNC( HWG_SETWINDOWSTYLE )
{
   hb_retnl( SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), GWL_STYLE,
               hb_parnl( 2 ) ) );
}

HB_FUNC( HWG_GETWINDOWSTYLE )
{
   hb_retnl( GetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), GWL_STYLE ) );
}

HB_FUNC( HWG_SETWINDOWEXSTYLE )
{
   hb_retnl( SetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), GWL_EXSTYLE,
               hb_parnl( 2 ) ) );
}

HB_FUNC( HWG_GETWINDOWEXSTYLE )
{
   hb_retnl( GetWindowLongPtr( ( HWND ) HB_PARHANDLE( 1 ), GWL_EXSTYLE ) );
}

HB_FUNC( HWG_FINDWINDOW )
{
   HB_RETHANDLE( FindWindow( hb_parc( 1 ), hb_parc( 2 ) ) );
}

HB_FUNC( HWG_SETFOREGROUNDWINDOW )
{
   hb_retl( SetForegroundWindow( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( HWG_BRINGWINDOWTOTOP )
{
   hb_retl( BringWindowToTop( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

//HB_FUNC( HWG_SETACTIVEWINDOW )
//{
//   hb_retnl( SetActiveWindow( (HWND) HB_PARHANDLE(1) ) );
//}

HB_FUNC( RESETWINDOWPOS )
{
   RECT rc;

   GetWindowRect( ( HWND ) HB_PARHANDLE( 1 ), &rc );
   MoveWindow( ( HWND ) HB_PARHANDLE( 1 ), rc.left, rc.top,
         rc.right - rc.left + 1, rc.bottom - rc.top, 0 );
}

/*
   MainWndProc alteradas na HWGUI. Agora as funcoes em hWindow.prg
   retornam 0 para indicar que deve ser usado o processamento default.
*/
LRESULT CALLBACK MainWndProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {

      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( DefWindowProc( hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return ( DefWindowProc( hWnd, message, wParam, lParam ) );
}

LRESULT CALLBACK FrameWndProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( DefFrameProc( hWnd, aWindows[1], message, wParam,
                     lParam ) );
      else
         return res;
   }
   else
      return ( DefFrameProc( hWnd, aWindows[1], message, wParam, lParam ) );
}

LRESULT CALLBACK MDIChildWndProc( HWND hWnd, UINT message, WPARAM wParam,
      LPARAM lParam )
{
   long int res;
   PHB_ITEM pObject;

   if( message == WM_NCCREATE )
   {
      LPMDICREATESTRUCT cs =
            ( LPMDICREATESTRUCT ) ( ( ( LPCREATESTRUCT ) lParam )->
            lpCreateParams );
      PHB_ITEM *pObj = ( PHB_ITEM * ) ( cs->lParam );
      PHB_ITEM temp;

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( *pObj, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = HB_PUTHANDLE( NULL, hWnd );
      SetObjectVar( *pObj, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hWnd, *pObj );
   }

   pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEvent ) );
      hb_vmPush( pObject );
      hb_vmPushLong( ( LONG ) message );
      hb_vmPushLong( ( LONG ) wParam );
//      hb_vmPushLong( (LONG ) lParam );
      HB_PUSHITEM( lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return ( DefMDIChildProc( hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return ( DefMDIChildProc( hWnd, message, wParam, lParam ) );

}

PHB_ITEM GetObjectVar( PHB_ITEM pObject, const char *varname )
{
   return hb_objSendMsg( pObject, varname, 0 );
}

void SetObjectVar( PHB_ITEM pObject, const char *varname, PHB_ITEM pValue )
{
   hb_objSendMsg( pObject, varname, 1, pValue );
}

#if !defined( HB_HAS_STR_FUNC )

/* these are simple wrapper functions for xHarbour and older Harbour
 * versions which do not support automatic UNICODE conversions
 */

static const char s_szConstStr[ 1 ] = { 0 };

const char * hb_strnull( const char * str )
{
   return str ? str : "";
}

const char * hb_strget( PHB_ITEM pItem, void ** phStr, HB_SIZE * pulLen )
{
   const char * pStr;

   if( HB_IS_STRING( pItem ) )
   {
      *phStr = ( void * ) s_szConstStr;
      pStr = hb_itemGetCPtr( pItem );
      if( pulLen )
         *pulLen = hb_itemGetCLen( pItem );
   }
   else
   {
      *phStr = NULL;
      pStr = NULL;
      if( pulLen )
         *pulLen = 0;
   }
   return pStr;
}

HB_SIZE hb_strcopy( PHB_ITEM pItem, char * pStr, HB_SIZE ulLen )
{
   if( HB_IS_STRING( pItem ) )
   {
      HB_SIZE size = hb_itemGetCLen( pItem );

      if( size > ulLen )
         size = ulLen;
      if( pStr && ulLen && size )
         memcpy( pStr, hb_itemGetCPtr( pItem ), size );
      if( size < ulLen )
         pStr[ size ] = '\0';

      return size;
   }
   return 0;
}

char * hb_strunshare( void ** phStr, const char * pStr, HB_SIZE ulLen )
{
   if( pStr == NULL || phStr == NULL || *phStr == NULL )
      return NULL;

   if( *phStr == ( void * ) s_szConstStr && ulLen > 0 )
   {
      char * pszDest = ( char * ) hb_xgrab( ( ulLen + 1 ) * sizeof( char ) );
      memcpy( pszDest, pStr, ulLen * sizeof( char ) );
      pszDest[ ulLen ] = 0;
      * phStr = ( void * ) pszDest;

      return pszDest;
   }

   return ( char * ) pStr;
}

void hb_strfree( void * hString )
{
   if( hString && hString != ( void * ) s_szConstStr )
      hb_xfree( hString );
}
#endif

HB_FUNC( EXITPROCESS )
{
   ExitProcess( 0 );
}

HB_FUNC( HWG_DECREASEHOLDERS )
{
/*
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT );
   #ifndef  UIHOLDERS
   if( pObject->item.asArray.value->ulHolders )
      pObject->item.asArray.value->ulHolders--;
   #else
   if( pObject->item.asArray.value->uiHolders )
      pObject->item.asArray.value->uiHolders--;
   #endif
*/
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( pObject )
   {
      hb_itemRelease( pObject );
      SetWindowLongPtr( hWnd, GWL_USERDATA, 0 );
   }
}

HB_FUNC( SETTOPMOST )
{
   BOOL i =
         SetWindowPos( ( HWND ) HB_PARHANDLE( 1 ), HWND_TOPMOST, 0, 0, 0, 0,
         SWP_NOMOVE | SWP_NOSIZE );

   hb_retl( i );
}

HB_FUNC( REMOVETOPMOST )
{
   BOOL i =
         SetWindowPos( ( HWND ) HB_PARHANDLE( 1 ), HWND_NOTOPMOST, 0, 0, 0, 0,
         SWP_NOMOVE | SWP_NOSIZE );

   hb_retl( i );
}

HB_FUNC( CHILDWINDOWFROMPOINT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HWND child;
   POINT pt;

   pt.x = hb_parnl( 2 );
   pt.y = hb_parnl( 3 );
   child = ChildWindowFromPoint( hWnd, pt );

   HB_RETHANDLE( child );
}

HB_FUNC( WINDOWFROMPOINT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   HWND child;
   POINT pt;

   pt.x = hb_parnl( 2 );
   pt.y = hb_parnl( 3 );
   ClientToScreen( hWnd, &pt );
   child = WindowFromPoint( pt );

   HB_RETHANDLE( child );
}

HB_FUNC( MAKEWPARAM )
{
   WPARAM p;

   p = MAKEWPARAM( ( WORD ) hb_parnl( 1 ), ( WORD ) hb_parnl( 2 ) );
   hb_retnl( ( LONG ) p );
}

HB_FUNC( MAKELPARAM )
{
   LPARAM p;

   p = MAKELPARAM( ( WORD ) hb_parnl( 1 ), ( WORD ) hb_parnl( 2 ) );
   HB_RETHANDLE( p );
}

HB_FUNC( SETWINDOWPOS )
{
   BOOL res;
   HWND hWnd = ( ISNUM( 1 ) ||
         ISPOINTER( 1 ) ) ? ( HWND ) HB_PARHANDLE( 1 ) : NULL;
   HWND hWndInsertAfter = ( ISNUM( 2 ) ||
         ISPOINTER( 2 ) ) ? ( HWND ) HB_PARHANDLE( 2 ) : NULL;
   int X = hb_parni( 3 );
   int Y = hb_parni( 4 );
   int cx = hb_parni( 5 );
   int cy = hb_parni( 6 );
   UINT uFlags = hb_parni( 7 );

   res = SetWindowPos( hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags );

   hb_retl( res );
}

HB_FUNC( SETASTYLE )
{
#define MAP_STYLE(src, dest) if(dwStyle & (src)) dwText |= (dest)
#define NMAP_STYLE(src, dest) if(!(dwStyle & (src))) dwText |= (dest)

   DWORD dwStyle = hb_parnl( 1 ), dwText = 0;

   MAP_STYLE( SS_RIGHT, DT_RIGHT );
   MAP_STYLE( SS_CENTER, DT_CENTER );
   MAP_STYLE( SS_CENTERIMAGE, DT_VCENTER | DT_SINGLELINE );
   MAP_STYLE( SS_NOPREFIX, DT_NOPREFIX );
   MAP_STYLE( SS_WORDELLIPSIS, DT_WORD_ELLIPSIS );
   MAP_STYLE( SS_ENDELLIPSIS, DT_END_ELLIPSIS );
   MAP_STYLE( SS_PATHELLIPSIS, DT_PATH_ELLIPSIS );

   NMAP_STYLE( SS_LEFTNOWORDWRAP |
         SS_CENTERIMAGE |
         SS_WORDELLIPSIS | SS_ENDELLIPSIS | SS_PATHELLIPSIS, DT_WORDBREAK );

   hb_stornl( dwStyle, 1 );
   hb_stornl( dwText, 2 );
}

HB_FUNC( BRINGTOTOP )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   //DWORD ForegroundThreadID;
   //DWORD    ThisThreadID;
   //DWORD      timeout;
   //BOOL Res = FALSE;
   if( IsIconic( hWnd ) )
   {
      ShowWindow( hWnd, SW_RESTORE );
      hb_retl( TRUE );
      return;
   }

   //ForegroundThreadID = GetWindowThreadProcessID(GetForegroundWindow(),NULL);
   //ThisThreadID = GetWindowThreadPRocessId(hWnd, NULL);
   //   if (AttachThreadInput(ThisThreadID, ForegroundThreadID, TRUE) )
   //    {

   BringWindowToTop( hWnd );    // IE 5.5 related hack
   SetForegroundWindow( hWnd );
   //    AttachThreadInput(ThisThreadID, ForegroundThreadID,FALSE);
   //    Res = (GetForegroundWindow() == hWnd);
   //    }
   //hb_retl(Res);
}

HB_FUNC( UPDATEWINDOW )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   UpdateWindow( hWnd );
}

LONG GetFontDialogUnits( HWND h, HFONT f )
{
   HFONT hFont;
   HFONT hFontOld;
   LONG avgWidth;
   HDC hDc;
   char *tmp = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
   SIZE sz;

   HB_SYMBOL_UNUSED( f );

   //get the hdc to the main window
   hDc = GetDC( h );

   //with the current font attributes, select the font
   //hFont = f;//GetStockObject(ANSI_VAR_FONT)   ;
   hFont = ( HFONT ) GetStockObject( ANSI_VAR_FONT );
   hFontOld = ( HFONT ) SelectObject( hDc, hFont );

   //get its length, then calculate the average character width

   GetTextExtentPoint32( hDc, tmp, 52, &sz );
   avgWidth = ( sz.cx / 52 );

   //re-select the previous font & delete the hDc
   SelectObject( hDc, hFontOld );
   DeleteObject( hFont );
   ReleaseDC( h, hDc );

   return avgWidth;
}

HB_FUNC( GETFONTDIALOGUNITS )
{
   hb_retnl( GetFontDialogUnits( ( HWND ) HB_PARHANDLE( 1 ),
               ( HFONT ) HB_PARHANDLE( 2 ) ) );
}

LRESULT CALLBACK KbdHook( int code, WPARAM wp, LPARAM lp )
{
   int nId, nBtnNo;
   UINT uId;
   BOOL bPressed;

   if( code < 0 )
      return CallNextHookEx( OrigDockHookProc, code, wp, lp );

   switch ( code )
   {
      case HC_ACTION:
         nBtnNo = SendMessage( hMytoolMenu, TB_BUTTONCOUNT, 0, 0 );
         nId = SendMessage( hMytoolMenu, TB_GETHOTITEM, 0, 0 );

         bPressed = ( HIWORD( lp ) & KF_UP ) ? FALSE : TRUE;

         if( ( wp == VK_F10 || wp == VK_MENU ) && nId == -1 && bPressed )
         {
            SendMessage( hMytoolMenu, TB_SETHOTITEM, 0, 0 );
            return -100;
         }

         if( wp == VK_LEFT && nId != -1 && nId != 0 && bPressed )
         {
            SendMessage( hMytoolMenu, TB_SETHOTITEM, ( WPARAM ) nId - 1, 0 );
            break;
         }

         if( wp == VK_RIGHT && nId != -1 && nId < nBtnNo && bPressed )
         {
            SendMessage( hMytoolMenu, TB_SETHOTITEM, ( WPARAM ) nId + 1, 0 );
            break;
         }

         if( SendMessage( hMytoolMenu, TB_MAPACCELERATOR, ( WPARAM ) wp,
                     ( LPARAM ) & uId ) != 0 && nId != -1 )
         {
            LRESULT Res = -200;
            PHB_ITEM pObject =
                  ( PHB_ITEM ) GetWindowLongPtr( hMytoolMenu, GWL_USERDATA );

            if( !pSym_onEven_Tool )
               pSym_onEven_Tool = hb_dynsymFindName( "EXECUTETOOL" );

            if( pSym_onEven_Tool && pObject )
            {
               hb_vmPushSymbol( hb_dynsymSymbol( pSym_onEven_Tool ) );
               hb_vmPush( pObject );
               hb_vmPushLong( ( LONG ) uId );

               hb_vmSend( 1 );
               Res = hb_parnl( -1 );
               if( Res == 0 )
               {
                  SendMessage( hMytoolMenu, WM_KEYUP, VK_MENU, 0 );
                  SendMessage( hMytoolMenu, WM_KEYUP, wp, 0 );
               }
            }
            return Res;
         }

      default:
         break;
   }
   return CallNextHookEx( OrigDockHookProc, code, wp, lp );
}


HB_FUNC( SETTOOLHANDLE )
{
   HWND h = ( HWND ) HB_PARHANDLE( 1 );

   hMytoolMenu = ( HWND ) h;
}

HB_FUNC( SETHOOK )
{
   OrigDockHookProc =
         SetWindowsHookEx( WH_KEYBOARD, KbdHook, GetModuleHandle( 0 ), 0 );
}


HB_FUNC( UNSETHOOK )
{
   if( OrigDockHookProc )
   {
      UnhookWindowsHookEx( OrigDockHookProc );
      OrigDockHookProc = 0;
   }
}


HB_FUNC( GETTOOLBARID )
{
   HWND hMytoolMenu = ( HWND ) HB_PARHANDLE( 1 );
   WPARAM wp = ( WPARAM ) hb_parnl( 2 );
   UINT uId;

   if( SendMessage( hMytoolMenu, TB_MAPACCELERATOR, ( WPARAM ) wp,
               ( LPARAM ) & uId ) != 0 )
      hb_retnl( uId );
   else
      hb_retnl( -1 );
}

HB_FUNC( ISWINDOW )
{
   hb_retl( IsWindow( ( HWND ) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( MINMAXWINDOW )
{
   MINMAXINFO *lpMMI = ( MINMAXINFO * ) HB_PARHANDLE( 2 );
   DWORD m_fxMin;
   DWORD m_fyMin;
   DWORD m_fxMax;
   DWORD m_fyMax;

   m_fxMin = ( ISNIL( 3 ) ) ? lpMMI->ptMinTrackSize.x : hb_parni( 3 );
   m_fyMin = ( ISNIL( 4 ) ) ? lpMMI->ptMinTrackSize.y : hb_parni( 4 );
   m_fxMax = ( ISNIL( 5 ) ) ? lpMMI->ptMaxTrackSize.x : hb_parni( 5 );
   m_fyMax = ( ISNIL( 6 ) ) ? lpMMI->ptMaxTrackSize.y : hb_parni( 6 );
   lpMMI->ptMinTrackSize.x = m_fxMin;
   lpMMI->ptMinTrackSize.y = m_fyMin;
   lpMMI->ptMaxTrackSize.x = m_fxMax;
   lpMMI->ptMaxTrackSize.y = m_fyMax;

//   SendMessage((HWND) HB_PARHANDLE( 1 ),           // handle of window
//               WM_GETMINMAXINFO, 0, (LPARAM) lpMMI)  ;
}

HB_FUNC( GETWINDOWPLACEMENT )
{
   HWND hWnd = ( HWND ) HB_PARHANDLE( 1 );
   WINDOWPLACEMENT wp ;
   
   wp.length = sizeof( WINDOWPLACEMENT );

   if ( GetWindowPlacement( hWnd, &wp ) ) 
      hb_retnl( wp.showCmd );
   else
      hb_retnl( -1 )  ;
}
