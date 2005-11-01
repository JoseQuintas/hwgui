/*
 * $Id: window.c,v 1.41 2005-11-01 17:48:38 lf_sfnet Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level windows functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#define OEMRESOURCE
#include <windows.h>
#include <commctrl.h>

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "guilib.h"

#include <math.h>
#include <float.h>
#include <limits.h>

#define  FIRST_MDICHILD_ID     501

extern HB_HANDLE hb_memvarGetVarHandle( char *szName );
extern PHB_ITEM hb_memvarGetValueByHandle( HB_HANDLE hMemvar );

void writelog( char* s );
void SetWindowObject( HWND hWnd, PHB_ITEM pObject );

PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );

LRESULT CALLBACK MainWndProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK FrameWndProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK MDIChildWndProc (HWND, UINT, WPARAM, LPARAM) ;

extern HWND * aDialogs;
extern int iDialogs;

HWND aWindows[2] = { 0,0 };
HACCEL hAccel = NULL;
PHB_DYNS pSym_onEvent = NULL;
// static PHB_DYNS pSym_MDIWnd = NULL;
static TCHAR szChild[] = TEXT ( "MDICHILD" );


/*  Creates main application window
    InitMainWindow( szAppName, cTitle, cMenu, hIcon, nBkColor, nStyle, nLeft, nTop, nWidth, nHeight )
*/

HB_FUNC( HWG_INITMAINWINDOW )
{
   HWND         hWnd ;
   WNDCLASS     wndclass;
   HANDLE hInstance = GetModuleHandle( NULL );
   DWORD ExStyle = 0;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   char *szAppName = hb_parc(2);
   char *cTitle = hb_parc( 3 );
   LONG nStyle =  hb_parnl(7);
   char *cMenu = hb_parc( 4 );
   int x = hb_parnl(8);
   int y = hb_parnl(9);
   int width = hb_parnl(10);
   int height = hb_parnl(11);

   if ( aWindows[0] )
   {
      hb_retni( 0 );
      return;
   }

   wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
   wndclass.lpfnWndProc   = MainWndProc ;
   wndclass.cbClsExtra    = 0 ;
   wndclass.cbWndExtra    = 0 ;
   wndclass.hInstance     = (HINSTANCE)hInstance ;
   wndclass.hIcon         = (hb_pcount()>4 && !ISNIL(5))? (HICON)hb_parnl(5) : LoadIcon ((HINSTANCE)hInstance,"" );
   wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
   wndclass.hbrBackground = ( ( (hb_pcount()>5 && !ISNIL(6))? ( (hb_parnl(6)==-1)? (HBRUSH)NULL:(HBRUSH)hb_parnl(6)) : (HBRUSH)(COLOR_WINDOW+1) ) );
   wndclass.lpszMenuName  = cMenu ;
   wndclass.lpszClassName = szAppName ;

   if (!RegisterClass (&wndclass))
   {
        hb_retni( 0 );
        return;
   }

   hWnd = CreateWindowEx( ExStyle , szAppName ,TEXT ( cTitle ),
   WS_OVERLAPPEDWINDOW  | nStyle ,
   x,y,
   (!width)? (LONG)CW_USEDEFAULT:width,
   (!height)? (LONG)CW_USEDEFAULT:height,
   NULL, NULL, (HINSTANCE)hInstance, NULL) ;

   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );

   aWindows[0] = hWnd;
   hb_retnl( (LONG) hWnd );
}

HB_FUNC( HWG_CENTERWINDOW )
{
	RECT rect;
	int w, h, x, y;
	GetWindowRect((HWND) hb_parnl (1), &rect);
	w  = rect.right  - rect.left;
	h = rect.bottom - rect.top;
	x = GetSystemMetrics(SM_CXSCREEN);
	y = GetSystemMetrics(SM_CYSCREEN);
	SetWindowPos((HWND) hb_parnl (1), HWND_TOP, (x - w) / 2,
	(y - h) / 2, 0, 0, SWP_NOSIZE);
}


void ProcessMessage( MSG msg, HACCEL hAcceler, BOOL lMdi )
{
   int i;
   HWND   hwndGoto ;

   for( i=0;i<iDialogs;i++ )
   {
     hwndGoto = aDialogs[ i ];
     if( IsWindow(hwndGoto) && IsDialogMessage(hwndGoto, &msg) )
        break;
   }
   if( i == iDialogs )
   {
      if( lMdi && TranslateMDISysAccel( aWindows[ 1 ], &msg) )
         return;
      if( !hAcceler || !TranslateAccelerator( aWindows[0], hAcceler, &msg ) )
      {
         TranslateMessage (&msg) ;
         DispatchMessage (&msg) ;
      }
   }
}

void ProcessMdiMessage( HWND hJanBase, HWND hJanClient, MSG msg, HACCEL hAcceler )
{
   if( !TranslateMDISysAccel( hJanClient, &msg)  &&
       !TranslateAccelerator( hJanBase, hAcceler, &msg ) )
   {
      TranslateMessage (&msg) ;
      DispatchMessage (&msg) ;
   }
}

/*
 *  HWG_ACTIVATEMAINWINDOW( lShow, hAccel, lMaximize, lMinimize )
 */
HB_FUNC( HWG_ACTIVATEMAINWINDOW )
{

   HACCEL hAcceler = ( ISNIL(2) )? NULL : (HACCEL) hb_parnl(2);
   MSG    msg;

   if( hb_parl(1) )
   {
      ShowWindow( aWindows[0],( ISLOG(3) && hb_parl(3) )? SW_SHOWMAXIMIZED : ( ( ISLOG(4) && hb_parl(4) )? SW_SHOWMINIMIZED : SW_SHOWNORMAL ) );
   }

   while (GetMessage( &msg, NULL, 0, 0) )
   {
      ProcessMessage( msg, hAcceler, 0 );
   }

}

HB_FUNC( HWG_PROCESSMESSAGE )
{

   MSG msg;
   BOOL lMdi = (ISNIL(1))? 0 : hb_parl(1);
   int nSleep = (ISNIL(2))? 1 : hb_parni(2);

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

   hb_retl( PeekMessage(
    			&msg,
    			(HWND) hb_parnl( 1 ),		// handle of window whose message queue will be searched
    			(UINT) hb_parni( 2 ),		// wMsgFilterMin,
    			(UINT) hb_parni( 3 ),		// wMsgFilterMax,
    			PM_NOREMOVE ) );
}

HB_FUNC( HWG_INITCHILDWINDOW )
{
   HWND         hWnd ;
   WNDCLASS     wndclass;
   HMODULE /*HANDLE*/ hInstance = GetModuleHandle( NULL );
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   char *szAppName = hb_parc(2);
   char *cTitle = hb_parc( 3 );
   LONG nStyle =  (ISNIL(7)? 0 : hb_parnl(7));
   char *cMenu = hb_parc( 4 );
   int x = hb_parnl(8);
   int y = hb_parnl(9);
   int width = hb_parnl(10);
   int height = hb_parnl(11);
   HWND hParent = (HWND) hb_parnl(12);
   DWORD ExStyle;

   if (!GetClassInfo(hInstance, szAppName, &wndclass))
   {
      wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
      wndclass.lpfnWndProc   = MainWndProc ;
      wndclass.cbClsExtra    = 0 ;
      wndclass.cbWndExtra    = 0 ;
      wndclass.hInstance     = (HINSTANCE)hInstance ;
      wndclass.hIcon         = (hb_pcount()>4 && !ISNIL(5))? (HICON)hb_parnl(5) : LoadIcon ((HINSTANCE)hInstance,"" );
      wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
      wndclass.hbrBackground = ( ( (hb_pcount()>5 && !ISNIL(6))?
                ( (hb_parnl(6)==-1)? (HBRUSH)(COLOR_WINDOW+1) :
                                     CreateSolidBrush( hb_parnl(6) ) )
                : (HBRUSH)(COLOR_WINDOW+1) ) );
      wndclass.lpszMenuName  = cMenu ;
      wndclass.lpszClassName = szAppName ;

               //UnregisterClass( szAppName, (HINSTANCE)hInstance );
      if (!RegisterClass (&wndclass))
      {
         hb_retni( 0 );

         #ifdef __XHARBOUR__
            MessageBox( GetActiveWindow(), szAppName, "Register Child Wnd Class", MB_OK | MB_ICONSTOP );
         #endif

         return;
      }
   }

   ExStyle = 0;

   hWnd = CreateWindowEx( ExStyle , szAppName ,TEXT ( cTitle ),
              WS_OVERLAPPEDWINDOW  | nStyle , x,y,
              (!width)? (LONG)CW_USEDEFAULT:width,
              (!height)? (LONG)CW_USEDEFAULT:height,
              hParent, NULL, (HINSTANCE)hInstance, NULL) ;

   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );

   hb_retnl( (LONG) hWnd );
}

HB_FUNC( HWG_ACTIVATECHILDWINDOW )
{
   if( hb_parl(1) )
   {
      ShowWindow( (HWND) hb_parnl (2),SW_SHOWNORMAL );
   }
   else
   {
      ShowWindow( (HWND) hb_parnl (2),SW_HIDE );
   }
   return;
}


/*  Creates frame MDI and client window
    InitMainWindow( cTitle, cMenu, cBitmap, hIcon, nBkColor, nStyle, nLeft, nTop, nWidth, nHeight )
*/

HB_FUNC( HWG_INITMDIWINDOW )
{
   HWND         hWnd;
   WNDCLASS     wndclass, wc;
   HANDLE hInstance = GetModuleHandle( NULL ) ;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp;
   char *szAppName = hb_parc(2);
   char *cTitle = hb_parc(3);
   char *cMenu = hb_parc(4);
   int x = hb_parnl(8);
   int y = hb_parnl(9);
   int width = hb_parnl(10);
   int height = hb_parnl(11);

   if ( aWindows[0] )
   {
      hb_retni( -1 );
      return;
   }
   // Register frame window
   wndclass.style = 0;
   wndclass.lpfnWndProc   = FrameWndProc ;
   wndclass.cbClsExtra    = 0 ;
   wndclass.cbWndExtra    = 0 ;
   wndclass.hInstance     = (HINSTANCE)hInstance ;
   wndclass.hIcon         = (hb_pcount()>4 && !ISNIL(5))? (HICON)hb_parnl(5) : LoadIcon ((HINSTANCE)hInstance,"" );
   wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
   wndclass.hbrBackground = (HBRUSH)( COLOR_WINDOW+1 );
   wndclass.lpszMenuName  = cMenu ;
   wndclass.lpszClassName = szAppName ;

   if (!RegisterClass (&wndclass))
   {
      hb_retni( -2 );
      return;
   }

   // Register client window
   wc.lpfnWndProc   = (WNDPROC) MDIChildWndProc; 
   wc.hIcon         = (hb_pcount()>4 && !ISNIL(5))? (HICON)hb_parnl(5) : LoadIcon ((HINSTANCE)hInstance,"" );
   wc.hbrBackground = (HBRUSH)( ( (hb_pcount()>5 && !ISNIL(6)) ?hb_parnl(6):(COLOR_WINDOW+1) ) );
   wc.lpszMenuName  = (LPCTSTR) NULL; 
   wc.cbWndExtra    = 0;
   wc.lpszClassName = szChild; 


   wc.cbClsExtra    = 0 ;
   wc.hInstance     = (HINSTANCE)hInstance ;
   wc.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
   wc.style = 0;

   if (!RegisterClass(&wc)) 
   {
      hb_retni( -3 );
      return;
   }

   // Create frame window
   hWnd = CreateWindow ( szAppName, TEXT ( cTitle ),
                       WS_OVERLAPPEDWINDOW,
                       x,y,
                       (!width)? (LONG)CW_USEDEFAULT:width,
                       (!height)? (LONG)CW_USEDEFAULT:height,
                       NULL, NULL, (HINSTANCE)hInstance, NULL) ;
   if (!hWnd) 
   {
      hb_retni( -4 );
      return;
   }

   temp = hb_itemPutNL( NULL, 1 );
   SetObjectVar( pObject, "_NHOLDER", temp );
   hb_itemRelease( temp );
   SetWindowObject( hWnd, pObject );

   aWindows[0] = hWnd;
   hb_retnl( (LONG) hWnd );
}

HB_FUNC( HWG_INITCLIENTWINDOW )
{
   CLIENTCREATESTRUCT ccs;
   HWND hWnd;
   int nPos = (hb_pcount()>1 && !ISNIL(2))? hb_parni(2):0;
   int x = hb_parnl(3);
   int y = hb_parnl(4);
   int width = hb_parnl(5);
   int height = hb_parnl(6);

   // Create client window
   ccs.hWindowMenu = GetSubMenu( GetMenu(aWindows[0]), nPos );
   ccs.idFirstChild = FIRST_MDICHILD_ID;

   hWnd = CreateWindow ( "MDICLIENT", (LPCTSTR) NULL,
                       WS_CHILD | WS_CLIPCHILDREN | MDIS_ALLCHILDSTYLES,
                       x,y,width,height,
                       aWindows[0], NULL, GetModuleHandle( NULL ), (LPSTR) &ccs );

   aWindows[1] = hWnd;
   hb_retnl( (LONG) hWnd );
}

HB_FUNC( HWG_ACTIVATEMDIWINDOW )
{

   HACCEL hAcceler = ( ISNIL(2) )? NULL : (HACCEL) hb_parnl(2);
   MSG  msg ;

   if( hb_parl(1) )
   {
   	  ShowWindow( aWindows[0],( ISLOG(3) && hb_parl(3) )? SW_SHOWMAXIMIZED : ( ( ISLOG(4) && hb_parl(4) )? SW_SHOWMINIMIZED : SW_SHOWNORMAL ) );
      ShowWindow( aWindows[1], SW_SHOW );
   }

   while (GetMessage (&msg, NULL, 0, 0))
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
   HWND  hWnd;
   PHB_ITEM pObj = hb_param( 1, HB_IT_OBJECT );
   char *cTitle = hb_itemGetCPtr( GetObjectVar( pObj,"TITLE") );
   DWORD style = (DWORD) hb_itemGetNL( GetObjectVar( pObj,"STYLE") );
   int y = (int) hb_itemGetNL( GetObjectVar( pObj,"NTOP") );
   int x = (int) hb_itemGetNL( GetObjectVar( pObj,"NLEFT") );
   int width = (int) hb_itemGetNL( GetObjectVar( pObj,"NWIDTH") );
   int height = (int) hb_itemGetNL( GetObjectVar( pObj,"NHEIGHT") );

   if( !style )
      style = WS_VISIBLE | WS_OVERLAPPEDWINDOW | WS_MAXIMIZE;

   if( !aWindows[0] )
   {
      hb_retni( 0 );
      return;
   }
    
    hWnd = CreateMDIWindow(
       (LPTSTR) szChild,	// pointer to registered child class name 
       (LPTSTR) cTitle,		// pointer to window name 
       style,			// window style 
       x,	// horizontal position of window 
       y,	// vertical position of window 
       width,	// width of window 
       height,	// height of window 
       (HWND) aWindows[1],	// handle to parent window (MDI client) 
       GetModuleHandle( NULL ),		// handle to application instance 
       (LPARAM)&pObj		 	// application-defined value 
   );

   hb_retnl( (LONG) hWnd );

}

HB_FUNC( SENDMESSAGE )
{
    hb_retnl( (LONG) SendMessage(
                       (HWND) hb_parnl( 1 ),	// handle of destination window
                       (UINT) hb_parni( 2 ),	// message to send
                       (WPARAM) hb_parnl( 3 ),	// first message parameter
                       (LPARAM) hb_parnl( 4 ) 	// second message parameter
                     ) );
}

HB_FUNC( POSTMESSAGE )
{
    hb_retnl( (LONG) PostMessage(
                       (HWND) hb_parnl( 1 ),	// handle of destination window
                       (UINT) hb_parni( 2 ),	// message to send
                       (WPARAM) hb_parnl( 3 ),	// first message parameter
                       (LPARAM) hb_parnl( 4 ) 	// second message parameter
                     ) );
}

HB_FUNC( SETFOCUS )
{
   hb_retnl( (LONG) SetFocus( (HWND) hb_parnl( 1 ) ) );
}

HB_FUNC( GETFOCUS )
{
   hb_retnl( (LONG) GetFocus() );
}

HB_FUNC( SETWINDOWOBJECT )
{
   SetWindowObject( (HWND) hb_parnl(1),hb_param(2,HB_IT_OBJECT) );
}

void SetWindowObject( HWND hWnd, PHB_ITEM pObject )
{
   if( pObject )
   {
      SetWindowLongPtr( hWnd, GWL_USERDATA, (LPARAM) hb_itemNew( pObject ) );
   }
   else
   {
      SetWindowLongPtr( hWnd, GWL_USERDATA, 0 );
   }
}

HB_FUNC( GETWINDOWOBJECT )
{
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( (HWND) hb_parnl(1), GWL_USERDATA );
   hb_itemReturn( pObject );
}

HB_FUNC( SETWINDOWTEXT )
{
   SetWindowText( (HWND) hb_parnl( 1 ), (LPCTSTR) hb_parc( 2 ) );
}

HB_FUNC( GETWINDOWTEXT )
{
   HWND   hWnd = (HWND) hb_parnl( 1 );
   USHORT iLen = (USHORT)SendMessage( hWnd, WM_GETTEXTLENGTH, 0, 0 );
   char *cText = (char*) hb_xgrab( iLen+2 );

   iLen = (USHORT)SendMessage( hWnd, WM_GETTEXT, (WPARAM)(iLen+1), (LPARAM)cText );
   if( iLen > 0 )
      hb_retc( cText );
   else
      hb_retc( "" );
   hb_xfree( cText );
}

HB_FUNC( SETWINDOWFONT )
{
   SendMessage( (HWND) hb_parnl( 1 ), WM_SETFONT, (WPARAM) hb_parnl( 2 ), 
       MAKELPARAM( (ISNIL(3))? 0 : hb_parl(3), 0 ) );
}

HB_FUNC( ENABLEWINDOW )
{
   HWND hWnd = (HWND) hb_parnl( 1 );
   BOOL lEnable = hb_parl( 2 );

   // ShowWindow( hWnd, (lEnable)? SW_SHOWNORMAL:SW_HIDE );
   EnableWindow(
    hWnd,	// handle to window
    lEnable 	// flag for enabling or disabling input
   );
}

HB_FUNC( DESTROYWINDOW )
{
   DestroyWindow( (HWND) hb_parnl( 1 ) );
}

HB_FUNC( HIDEWINDOW )
{
   ShowWindow( (HWND) hb_parnl( 1 ), SW_HIDE );
}

HB_FUNC( SHOWWINDOW )
{
   ShowWindow( (HWND) hb_parnl( 1 ), SW_SHOW );
}

HB_FUNC( HWG_RESTOREWINDOW )
{
   ShowWindow( (HWND) hb_parnl( 1 ), SW_RESTORE );
}

HB_FUNC( HWG_ISICONIC )
{
   hb_retl( IsIconic( (HWND) hb_parnl( 1 ) ) );
}

HB_FUNC( ISWINDOWENABLED )
{
   hb_retl( IsWindowEnabled( (HWND) hb_parnl( 1 ) ) );
}

HB_FUNC( GETACTIVEWINDOW )
{
   hb_retnl( (LONG) GetActiveWindow() );
}

HB_FUNC( GETINSTANCE )
{
   hb_retnl( (LONG) GetModuleHandle( NULL ) );
}

HB_FUNC( HWG_SETWINDOWSTYLE )
{
   hb_retnl( SetWindowLong( (HWND) hb_parnl(1), GWL_STYLE, hb_parnl(2) ) );
}

HB_FUNC( HWG_FINDWINDOW )
{
   hb_retnl( (LONG) FindWindow( hb_parc(1),hb_parc(2) ) );
}

HB_FUNC( HWG_SETFOREGROUNDWINDOW )
{
   hb_retl( SetForegroundWindow( (HWND) hb_parnl(1) ) );
}

HB_FUNC( RESETWINDOWPOS )
{
   RECT rc;

   GetWindowRect( (HWND) hb_parnl( 1 ),	&rc );
   MoveWindow( (HWND) hb_parnl(1),rc.left,rc.top,rc.right-rc.left+1,rc.bottom-rc.top,0 );
}

/*
   MainWndProc alteradas na HWGUI. Agora as funcoes em hWindow.prg
   retornam 0 para indicar que deve ser usado o processamento default.
*/
LRESULT CALLBACK MainWndProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{

   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {

      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return( DefWindowProc( hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return( DefWindowProc( hWnd, message, wParam, lParam ) );
}

LRESULT CALLBACK FrameWndProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{

   long int res;
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return( DefFrameProc( hWnd, aWindows[ 1 ], message, wParam, lParam ) );
      else
         return res;
   }
   else
      return( DefFrameProc( hWnd, aWindows[ 1 ], message, wParam, lParam ) );
}

LRESULT CALLBACK MDIChildWndProc (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

   long int res;
   PHB_ITEM pObject;

   if( message == WM_NCCREATE )
   {
      LPMDICREATESTRUCT cs = (LPMDICREATESTRUCT)(((LPCREATESTRUCT) lParam)->lpCreateParams);
      PHB_ITEM * pObj = (PHB_ITEM*) ( cs->lParam );
      PHB_ITEM temp;

      temp = hb_itemPutNL( NULL, 1 );
      SetObjectVar( *pObj, "_NHOLDER", temp );
      hb_itemRelease( temp );

      temp = hb_itemPutNL( NULL, (LONG)hWnd );
      SetObjectVar( *pObj, "_HANDLE", temp );
      hb_itemRelease( temp );

      SetWindowObject( hWnd, *pObj );
   }
   pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );

   if( !pSym_onEvent )
      pSym_onEvent = hb_dynsymFindName( "ONEVENT" );

   if( pSym_onEvent && pObject )
   {
      hb_vmPushSymbol( pSym_onEvent->pSymbol );
      hb_vmPush( pObject );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmSend( 3 );
      res = hb_parnl( -1 );
      if( res == -1 )
         return( DefMDIChildProc( hWnd, message, wParam, lParam ) );
      else
         return res;
   }
   else
      return( DefMDIChildProc( hWnd, message, wParam, lParam ) );

}

PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname )
{
#ifdef __XHARBOUR__
   return hb_objSendMsg( pObject, varname, 0 );
#else
   hb_objSendMsg( pObject, varname, 0 );
#ifndef HARBOUR_OLD_VERSION
   return ( hb_stackReturnItem() );
#else
   return ( hb_stackReturn() );
#endif
#endif
}

void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue )
{
   hb_objSendMsg( pObject, varname, 1, pValue );
}

HB_FUNC( EXITPROCESS )
{
  ExitProcess(0);
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
   HWND hWnd = (HWND)hb_parnl(1);
   PHB_ITEM pObject = ( PHB_ITEM ) GetWindowLongPtr( hWnd, GWL_USERDATA );
   if( pObject )
   {
      hb_itemRelease( pObject );
      SetWindowLongPtr( hWnd, GWL_USERDATA, 0 );
   }
}


HB_FUNC( SETTOPMOST )
{
    BOOL i = SetWindowPos( (HWND) hb_parnl( 1 ), HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE );
    hb_retl( i );
}
 
HB_FUNC( REMOVETOPMOST )
{
    BOOL i = SetWindowPos( (HWND) hb_parnl( 1 ), HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE );
    hb_retl( i );
}

#ifndef __XHARBOUR__
#ifdef __EXPORT__
PHB_ITEM hb_stackReturn( void )
{
   HB_STACK stack = hb_GetStack();
   return &stack.Return;
}
#endif
#endif
