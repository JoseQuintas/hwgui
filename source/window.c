/*
 * $Id: window.c,v 1.9 2004-04-02 08:50:43 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level windows functions
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
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
#define  MAX_MDICHILD_WINDOWS  18

extern HB_HANDLE hb_memvarGetVarHandle( char *szName );
extern PHB_ITEM hb_memvarGetValueByHandle( HB_HANDLE hMemvar );
extern BOOL RegisterBrowse(void);
extern BOOL RegisterPanel(void);
extern BOOL RegisterOwnBtn(void);

void writelog( char* s );

PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );

LRESULT CALLBACK MainWndProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK ChildWndProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK FrameWndProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK MDIChildWndProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK MPMDIChildWndProc (HWND, UINT, WPARAM, LPARAM) ;
BOOL CALLBACK EnumChildProc( HWND hwndChild, LPARAM lParam) ;
LRESULT APIENTRY EditSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam );
LRESULT APIENTRY TabSubclassProc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam );

extern HWND aDialogs[];
extern int iDialogs;

HWND aWindows[ MAX_MDICHILD_WINDOWS + 2 ];
int iWindows = 0;
HACCEL hAccel = NULL;
static TCHAR szChild[] = TEXT ( "MDICHILD" );
static WNDPROC wpOrigEditProc, wpOrigTabProc;

/*  Creates main application window
    InitMainWindow( szAppName, cTitle, cMenu, hIcon, nBkColor, nStyle, nLeft, nTop, nWidth, nHeight )
*/

HB_FUNC ( HWG_GETWINDOWHANDLE )
{
   hb_retnl( (LONG)aWindows[ hb_parni(1)-1 ] );
}


HB_FUNC ( HWG_GETNUMWINDOWS )
{
   hb_retni( iWindows );
}

HB_FUNC ( HWG_INITMAINWINDOW )
{
   HWND         hWnd ;
   WNDCLASS     wndclass ;
   HANDLE hInstance = GetModuleHandle( NULL );
   DWORD ExStyle = 0;
   char *szAppName = hb_parc(1);
   char *cTitle = hb_parc( 2 );
   LONG nStyle =  hb_parnl(6);
   char *cMenu = hb_parc( 3 );
   int x = hb_parnl(7);
   int y = hb_parnl(8);
   int width = hb_parnl(9);
   int height = hb_parnl(10);

   if ( iWindows > 0 )
   {
      hb_retni( 0 );
      return;
   }

   wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
   wndclass.lpfnWndProc   = MainWndProc ;
   wndclass.cbClsExtra    = 0 ;
   wndclass.cbWndExtra    = 0 ;
   wndclass.hInstance     = (HINSTANCE)hInstance ;
   wndclass.hIcon         = (hb_pcount()>3 && !ISNIL(4))? (HICON)hb_parnl(4) : LoadIcon ((HINSTANCE)hInstance,"" );
   wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
   wndclass.hbrBackground = ( ( (hb_pcount()>4 && !ISNIL(5))? ( (hb_parnl(5)==-1)? (HBRUSH)NULL:(HBRUSH)hb_parnl(5)) : (HBRUSH)(COLOR_WINDOW+1) ) );
   wndclass.lpszMenuName  = cMenu ;
   wndclass.lpszClassName = szAppName ;

   if (!RegisterClass (&wndclass))
   {
        hb_retni( 0 );
        return;
   }

   RegisterBrowse();
   RegisterPanel();
   RegisterOwnBtn();


   hWnd = CreateWindowEx( ExStyle , szAppName ,TEXT ( cTitle ),
   WS_OVERLAPPEDWINDOW  | nStyle ,
   x,y,
   (width==0)? CW_USEDEFAULT:width,
   (height==0)? CW_USEDEFAULT:height,
   NULL, NULL, (HINSTANCE)hInstance, NULL) ;

   aWindows[ iWindows++ ] = hWnd;
   hb_retnl( (LONG) hWnd );
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
 *  HWG_ACTIVATEMAINWINDOW( lShow, hAccel, lMaximize ) 
 */
HB_FUNC ( HWG_ACTIVATEMAINWINDOW )
{

   HACCEL hAcceler = ( ISNIL(2) )? NULL : (HACCEL) hb_parnl(2);
   MSG    msg;

   if( hb_parl(1) )
   {
      ShowWindow( aWindows[0],( ISLOG(3) && hb_parl(3) )? SW_SHOWMAXIMIZED : SW_SHOWNORMAL );
   }

   while (GetMessage( &msg, NULL, 0, 0) )
   {
      ProcessMessage( msg, hAcceler, 0 );
   }

}

HB_FUNC ( HWG_PROCESSMESSAGE )
{

   MSG msg;
   BOOL lMdi = (ISNIL(1))? 0 : hb_parl(1);
   if( GetMessage( &msg, NULL, 0, 0) )
      ProcessMessage( msg, 0, lMdi );

}



HB_FUNC ( HWG_INITCHILDWINDOW )
{
   HWND         hWnd ;
   WNDCLASS     wndclass ;
   HANDLE hInstance = GetModuleHandle( NULL );
   char *szAppName = hb_parc(1);
   char *cTitle = hb_parc( 2 );
   LONG nStyle =  (ISNIL(6)? 0 : hb_parnl(6));
   char *cMenu = hb_parc( 3 );
   int x = hb_parnl(7);
   int y = hb_parnl(8);
   int width = hb_parnl(9);
   int height = hb_parnl(10);
   HWND hParent = (HWND) hb_parnl(11);
   DWORD ExStyle;

   wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
   wndclass.lpfnWndProc   = MainWndProc ;
   wndclass.cbClsExtra    = 0 ;
   wndclass.cbWndExtra    = 0 ;
   wndclass.hInstance     = (HINSTANCE)hInstance ;
   wndclass.hIcon         = (hb_pcount()>3 && !ISNIL(4))? (HICON)hb_parnl(4) : LoadIcon ((HINSTANCE)hInstance,"" );
   wndclass.hCursor       = LoadCursor (NULL, IDC_ARROW) ;
   wndclass.hbrBackground = ( ( (hb_pcount()>4 && !ISNIL(5)) ?  ( (hb_parnl(5)==-1)? (HBRUSH)(COLOR_WINDOW+1) : CreateSolidBrush( hb_parnl(5) ) ) : (HBRUSH)(COLOR_WINDOW+1) ) );
   wndclass.lpszMenuName  = cMenu ;
   wndclass.lpszClassName = szAppName ;


   UnregisterClass(szAppName,hInstance);
   if (!RegisterClass (&wndclass))
   {
         hb_retni( 0 );

         #ifdef __XHARBOUR__
               MessageBox( GetActiveWindow(), szAppName, "Register Child Wnd Class", MB_OK | MB_ICONSTOP );
         #endif


        return;
   }

   ExStyle = 0;

   hWnd = CreateWindowEx( ExStyle , szAppName ,TEXT ( cTitle ),
   WS_OVERLAPPEDWINDOW  | nStyle ,
   x,y,
   (width==0)? CW_USEDEFAULT:width,
   (height==0)? CW_USEDEFAULT:height,
   hParent, NULL, (HINSTANCE)hInstance, NULL) ;

   aWindows[ iWindows++ ] = hWnd;
   hb_retnl( (LONG) hWnd );
}

HB_FUNC ( HWG_ACTIVATECHILDWINDOW )
{

	MSG Msg;
	HWND hwnd;
	hwnd = (HWND) hb_parnl (1);

   
   ShowWindow( hwnd,SW_SHOWNORMAL );

	while(GetMessage(&Msg,NULL,0,0) )
	{
		if(!IsWindow(GetActiveWindow()) || !IsDialogMessage(GetActiveWindow(),&Msg))
		{
			TranslateMessage(&Msg);
			DispatchMessage(&Msg);
		}
	}
       
	return;

}

/*  Creates frame MDI and client window
    InitMainWindow( cTitle, cMenu, cBitmap, hIcon, nBkColor, nStyle, nLeft, nTop, nWidth, nHeight )
*/

HB_FUNC ( HWG_INITMDIWINDOW )
{
   HWND         hWnd;
   WNDCLASS     wndclass, wc ;
   HANDLE hInstance = GetModuleHandle( NULL ) ;
   char *szAppName = hb_parc(1);
   char *cTitle = hb_parc( 2 );
   char *cMenu = hb_parc( 3 );
   int x = hb_parnl(7);
   int y = hb_parnl(8);
   int width = hb_parnl(9);
   int height = hb_parnl(10);

   if ( iWindows > 0 )
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
   wndclass.hIcon         = (hb_pcount()>3 && !ISNIL(4))? (HICON)hb_parnl(4) : LoadIcon ((HINSTANCE)hInstance,"" );
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
   wc.hIcon         = (hb_pcount()>3 && !ISNIL(4))? (HICON)hb_parnl(4) : LoadIcon ((HINSTANCE)hInstance,"" );
   wc.hbrBackground = (HBRUSH)( ( (hb_pcount()>4 && !ISNIL(5)) ?hb_parnl(5):(COLOR_WINDOW+1) ) );
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
   RegisterBrowse();
   RegisterPanel();
   RegisterOwnBtn();

   // Create frame window
   hWnd = CreateWindow ( szAppName, TEXT ( cTitle ),
                       WS_OVERLAPPEDWINDOW,
                       x,y,
                       (width==0)? CW_USEDEFAULT:width,
                       (height==0)? CW_USEDEFAULT:height,
                       NULL, NULL, (HINSTANCE)hInstance, NULL) ;
   if (!hWnd) 
   {
      hb_retni( -4 );
      return;
   }

   iWindows = 1;
   aWindows[ 0 ] = hWnd;


   hb_retnl( (LONG) hWnd );
}

HB_FUNC ( HWG_INITCLIENTWINDOW )
{
   CLIENTCREATESTRUCT ccs;
   HWND         hWndClient;
   int nPos = (hb_pcount()>0 && !ISNIL(1))? hb_parni(1):0;
   int x = hb_parnl(2);
   int y = hb_parnl(3);
   int width = hb_parnl(4);
   int height = hb_parnl(5);

   // Create client window
   ccs.hWindowMenu = GetSubMenu( GetMenu(aWindows[0]), nPos );
   ccs.idFirstChild = FIRST_MDICHILD_ID;

   hWndClient = CreateWindow ( "MDICLIENT", (LPCTSTR) NULL,
                       WS_CHILD | WS_CLIPCHILDREN | MDIS_ALLCHILDSTYLES,
                       x,y,width,height,
                       aWindows[0], NULL, GetModuleHandle( NULL ), (LPSTR) &ccs );

   aWindows[1] = hWndClient;
   iWindows = 2;
}

HB_FUNC ( HWG_ACTIVATEMDIWINDOW )
{

   HACCEL hAcceler = ( ISNIL(2) )? NULL : (HACCEL) hb_parnl(2);
   MSG  msg ;

   if( hb_parl(1) )
   {
      ShowWindow( aWindows[0], SW_SHOWNORMAL );
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

HB_FUNC ( HWG_CREATEMDICHILDWINDOW )
{
   HWND  hWnd;
   PHB_ITEM pObj = hb_param( 1, HB_IT_OBJECT );
   char *cTitle = hb_itemGetCPtr( GetObjectVar( pObj,"TITLE") );
   DWORD style = (DWORD) hb_itemGetNL( GetObjectVar( pObj,"STYLE") );

   if( !style )
      style = WS_VISIBLE | WS_OVERLAPPEDWINDOW | WS_MAXIMIZE;

   if( !iWindows || iWindows > MAX_MDICHILD_WINDOWS+1 )
   {
      hb_retni( 0 );
      return;
   }

    hWnd = CreateMDIWindow(
       (LPTSTR) szChild,	// pointer to registered child class name 
       (LPTSTR) cTitle,		// pointer to window name 
       style,			// window style 
       0,	// horizontal position of window 
       0,	// vertical position of window 
       300,	// width of window 
       200,	// height of window 
       (HWND) aWindows[1],	// handle to parent window (MDI client) 
       GetModuleHandle( NULL ),		// handle to application instance 
       0		 	// application-defined value 
   );

   aWindows[ iWindows++ ] = hWnd;
   hb_retnl( (LONG) hWnd );

}

HB_FUNC ( SENDMESSAGE )
{
    hb_retnl( (LONG) SendMessage(
                       (HWND) hb_parnl( 1 ),	// handle of destination window
                       (UINT) hb_parni( 2 ),	// message to send
                       (WPARAM) hb_parnl( 3 ),	// first message parameter
                       (LPARAM) hb_parnl( 4 ) 	// second message parameter
                     ) );
}

HB_FUNC ( POSTMESSAGE )
{
    hb_retnl( (LONG) PostMessage(
                       (HWND) hb_parnl( 1 ),	// handle of destination window
                       (UINT) hb_parni( 2 ),	// message to send
                       (WPARAM) hb_parnl( 3 ),	// first message parameter
                       (LPARAM) hb_parnl( 4 ) 	// second message parameter
                     ) );
}

HB_FUNC ( SETFOCUS )
{
   hb_retnl( (LONG) SetFocus( (HWND) hb_parnl( 1 ) ) );
}

HB_FUNC ( GETFOCUS )
{
   hb_retnl( (LONG) GetFocus() );
}

HB_FUNC ( SETWINDOWOBJECT )
{
   PHB_ITEM pObject = hb_param( 2, HB_IT_OBJECT );

   if( pObject )
   {
      // Must increase uiHolders as we now have additional copy of object.
      pObject->item.asArray.value->uiHolders++;
      SetWindowLong( (HWND) hb_parnl(1), GWL_USERDATA, (LPARAM) (pObject->item.asArray.value) );
   }
   else
   {
      SetWindowLong( (HWND) hb_parnl(1), GWL_USERDATA, 0 );
   }
}

HB_FUNC ( GETWINDOWOBJECT )
{
   LONG dwNewLong = GetWindowLong( (HWND) hb_parnl(1), GWL_USERDATA );

   if( dwNewLong )
   {
      PHB_ITEM pObj = hb_itemNew( NULL );

      pObj->type = HB_IT_OBJECT;
      pObj->item.asArray.value = (PHB_BASEARRAY) dwNewLong;

      // Must increase uiHolders as we will shortly release this unaccounted copy.
      pObj->item.asArray.value->uiHolders++;

      hb_itemReturn( pObj );
      hb_itemRelease( pObj );
   }
}

HB_FUNC ( ENABLEWINDOW )
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

HB_FUNC ( SETWINDOWTEXT)
{
   SetWindowText( (HWND) hb_parnl( 1 ), (LPCTSTR) hb_parc( 2 ) );
}

HB_FUNC ( GETACTIVEWINDOW )
{
   hb_retnl( (LONG) GetActiveWindow() );
}

HB_FUNC ( GETINSTANCE )
{
   hb_retnl( (LONG) GetModuleHandle( NULL ) );
}

HB_FUNC ( HWG_INITEDITPROC )
{
   wpOrigEditProc = (WNDPROC) SetWindowLong( (HWND) hb_parnl(1),
                                 GWL_WNDPROC, (LONG) EditSubclassProc );
}

HB_FUNC ( HWG_INITTABPROC )
{
   wpOrigTabProc = (WNDPROC) SetWindowLong( (HWND) hb_parnl(1),
                                 GWL_WNDPROC, (LONG) TabSubclassProc );
}

HB_FUNC ( HWG_SETWINDOWSTYLE )
{
   hb_retnl( SetWindowLong( (HWND) hb_parnl(1), GWL_STYLE, hb_parnl(2) ) );
}

HB_FUNC ( HWG_FINDWINDOW )
{
   hb_retnl( (LONG) FindWindow( hb_parc(1),hb_parc(2) ) );
}

HB_FUNC ( HWG_SETFOREGROUNDWINDOW )
{
   hb_retl( SetForegroundWindow( (HWND) hb_parnl(1) ) );
}

HB_FUNC ( RESETWINDOWPOS )
{
   RECT rc;

   GetWindowRect( (HWND) hb_parnl( 1 ),	&rc );
   MoveWindow( (HWND) hb_parnl(1),rc.left,rc.top,rc.right-rc.left+1,rc.bottom-rc.top,0 );
}

/*
   MainWndProc alteradas na HWGUI. Agora as funcoes em hWindow.prg
   retornam 0 para indicar que deve ser usado o processamento default.
*/

LRESULT CALLBACK MainWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

   PHB_DYNS pSymTest;
   long int res;

   if( ( pSymTest = hb_dynsymFind( "DEFWNDPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( pSymTest->pSymbol );
      hb_vmPushNil();
      hb_vmPushLong( (LONG ) hWnd );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmDo( 4 );
      res = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );     
      if( res == -1 )
         return( DefWindowProc( hWnd, message, wParam, lParam ));
      else
         return res;
   }
   else
      return( DefWindowProc( hWnd, message, wParam, lParam ));
}


LRESULT CALLBACK ChildWndProc (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

   PHB_DYNS pSymTest;
   long int res;

   /*
   if( message == WM_DESTROY )
   {
      PostQuitMessage (0) ;
      // return 0 ;
   }
   */

   if( ( pSymTest = hb_dynsymFind( "DEFCHILDWNDPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( pSymTest->pSymbol );
      hb_vmPushNil();
      hb_vmPushLong( (LONG ) hWnd );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmDo( 4 );
      res = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );
      if( res == 0 )
         return( DefWindowProc( hWnd, message, wParam, lParam ));
      else
         return res;
   }
   else
      return( DefWindowProc( hWnd, message, wParam, lParam ));
}

LRESULT CALLBACK FrameWndProc (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

   PHB_DYNS pSymTest;
   long int res;
    
   /*
   if( message == WM_DESTROY )
   {
      PostQuitMessage (0) ;
      // return 0 ;
   }
   */ 

   if( ( pSymTest = hb_dynsymFind( "DEFWNDPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( pSymTest->pSymbol );
      hb_vmPushNil();
      hb_vmPushLong( (LONG ) hWnd );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmDo( 4 );
      res = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );
      if( res == -1 )
         return( DefFrameProc( hWnd, aWindows[ 1 ], message, wParam, lParam ));
      else
         return res;
   }
   else
      return( DefFrameProc( hWnd, aWindows[ 1 ], message, wParam, lParam ));
}

LRESULT CALLBACK MDIChildWndProc (HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{

   int i;
   long int res;
   PHB_DYNS pSymTest;

   if( message == WM_DESTROY )
   {
      for( i=0;i<iWindows;i++ )
         if( aWindows[ i ] == hWnd )  break;
      iWindows --;
      for( ;i<iWindows;i++ )
         aWindows[ i ] = aWindows[ i+1 ];
   }

   if( ( pSymTest = hb_dynsymFind( "DEFMDICHILDPROC" ) ) != NULL )
   {
      hb_vmPushSymbol( pSymTest->pSymbol );
      hb_vmPushNil();
      hb_vmPushLong( (LONG ) hWnd );
      hb_vmPushLong( (LONG ) message );
      hb_vmPushLong( (LONG ) wParam );
      hb_vmPushLong( (LONG ) lParam );
      hb_vmDo( 4 );
      res = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );
      if( res == -1 )
         return( DefMDIChildProc( hWnd, message, wParam, lParam ));
      else
         return res;
   }
   else
      return( DefMDIChildProc( hWnd, message, wParam, lParam ));
}

LRESULT APIENTRY EditSubclassProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   if( msg == WM_KEYUP || msg == WM_KEYDOWN || msg == WM_CHAR || msg == WM_LBUTTONUP ) // || msg == WM_GETDLGCODE )
   {
      long int res;
      PHB_DYNS pSymTest;

      if( ( pSymTest = hb_dynsymFind( "DEFEDITPROC" ) ) != NULL )
      {
         hb_vmPushSymbol( pSymTest->pSymbol );
         hb_vmPushNil();
         hb_vmPushLong( (LONG ) hWnd );
         hb_vmPushLong( (LONG ) msg );
         hb_vmPushLong( (LONG ) wParam );
         hb_vmPushLong( (LONG ) lParam );
         hb_vmDo( 4 );
         res = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );
         if( res == -1 )
            return CallWindowProc( wpOrigEditProc, hWnd, msg, wParam, lParam );
         else
            return res;
      }
   }
   return CallWindowProc( wpOrigEditProc, hWnd, msg, wParam, lParam );
}

LRESULT APIENTRY TabSubclassProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   // if( msg == WM_COMMAND || msg == WM_NOTIFY )
   {
      long int res;
      PHB_DYNS pSymTest;

      if( ( pSymTest = hb_dynsymFind( "DEFTABPROC" ) ) != NULL )
      {
         hb_vmPushSymbol( pSymTest->pSymbol );
         hb_vmPushNil();
         hb_vmPushLong( (LONG ) hWnd );
         hb_vmPushLong( (LONG ) msg );
         hb_vmPushLong( (LONG ) wParam );
         hb_vmPushLong( (LONG ) lParam );
         hb_vmDo( 4 );
         res = hb_itemGetNL( (PHB_ITEM) hb_stackReturn() );
         if( res == -1 )
            return CallWindowProc( wpOrigTabProc, hWnd, msg, wParam, lParam );
         else
            return res;
      }
   }
   return CallWindowProc( wpOrigTabProc, hWnd, msg, wParam, lParam );
}

PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname )
{
   PHB_DYNS pMsg = hb_dynsymGet( varname );

   if( pMsg )
   {
      hb_vmPushSymbol( pMsg->pSymbol );   /* Push message symbol */
      hb_vmPush( pObject );               /* Push object */

      hb_vmDo( 0 );
   }
   return ( hb_stackReturn() );
}

void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue )
{
   PHB_DYNS pMsg = hb_dynsymGet( varname );

   if( pMsg )
   {
      hb_vmPushSymbol( pMsg->pSymbol );   /* Push message symbol */
      hb_vmPush( pObject );               /* Push object */
      hb_vmPush( pValue );                /* Push value */

      hb_vmDo( 1 );
   }
}

HB_FUNC ( EXITPROCESS )
{
  ExitProcess(0);
}
