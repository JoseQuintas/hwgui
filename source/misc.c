/*
 * $Id: misc.c,v 1.43 2008-09-01 19:00:20 mlacecilia Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Miscellaneous functions
 *
 * Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
#define OEMRESOURCE
#include <windows.h>
#include <commctrl.h>
#include <math.h>

#include "guilib.h"
#include "hbmath.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"

#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

extern BOOL Array2Rect(PHB_ITEM aRect, RECT *rc );
extern PHB_ITEM Rect2Array( RECT *rc  );
extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
extern void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );

void writelog( char* s )
{
   FHANDLE handle;

   if( hb_fsFile( (unsigned char *) "ac.log" ) )
      handle = hb_fsOpen( (unsigned char *) "ac.log", FO_WRITE );
   else
      handle = hb_fsCreate( (unsigned char *) "ac.log", 0 );

   hb_fsSeek( handle,0, SEEK_END );
   hb_fsWrite( handle, (unsigned char *) s, strlen(s) );
   hb_fsWrite( handle, (unsigned char *) "\n\r", 2 );

   hb_fsClose( handle );
}

HB_FUNC( HWG_SETDLGRESULT )
{
   SetWindowLong( (HWND) HB_PARHANDLE( 1 ), DWL_MSGRESULT, hb_parni(2) );
}

HB_FUNC( SETCAPTURE )
{
   hb_retnl( (LONG) SetCapture( (HWND) HB_PARHANDLE( 1 ) ) );
}

HB_FUNC( RELEASECAPTURE )
{
   hb_retl( ReleaseCapture() );
}

HB_FUNC( COPYSTRINGTOCLIPBOARD )
{
   HGLOBAL hglbCopy;
   char * lptstrCopy;
   char * cStr = hb_parc( 1 );
   int nLen = strlen( cStr );

   if ( !OpenClipboard( GetActiveWindow() ) )
      return;

   EmptyClipboard();

   hglbCopy = GlobalAlloc( GMEM_DDESHARE, (nLen+1) * sizeof(TCHAR) );

   if (hglbCopy == NULL)
   {
      CloseClipboard();
      return;
   }

   // Lock the handle and copy the text to the buffer.

   lptstrCopy = (char*) GlobalLock( hglbCopy );
   memcpy( lptstrCopy, cStr, nLen * sizeof(TCHAR));
   lptstrCopy[nLen] = (TCHAR) 0;    // null character
   GlobalUnlock(hglbCopy);

   // Place the handle on the clipboard.
   SetClipboardData( CF_TEXT, hglbCopy );

   CloseClipboard();
}

HB_FUNC( GETCLIPBOARDTEXT )
  {
 HWND hwnd;
 HANDLE hData;
 char* buffer;

 hwnd = (HWND) hb_parnl(1);

 if (!OpenClipboard(hwnd))
     hb_retc("");
    else
 {
  hData = GetClipboardData(CF_TEXT);
  buffer = (char*)GlobalLock(hData);

  GlobalUnlock(hData);
  CloseClipboard();
  hb_retc( buffer);
 }
}

HB_FUNC( GETSTOCKOBJECT )
{
   HB_RETHANDLE(  GetStockObject( hb_parni(1) ) );
}

HB_FUNC( LOWORD )
{

   hb_retni( (int) ( (ISPOINTER(1) ? PtrToUlong(hb_parptr(1 )) :hb_parnl( 1 )) & 0xFFFF ) );
}

HB_FUNC( HIWORD )
{
   hb_retni( (int) ( ( (ISPOINTER(1) ? PtrToUlong(hb_parptr(1 ) ): hb_parnl( 1 )) >> 16 ) & 0xFFFF ) );
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

HB_FUNC( SETBIT )
{
   if( hb_pcount() < 3 || hb_parni( 3 ) )
      hb_retnl( hb_parnl(1) | ( 1 << (hb_parni(2)-1) ) );
   else
      hb_retnl( hb_parnl(1) & ~( 1 << (hb_parni(2)-1) ) );
}

HB_FUNC( CHECKBIT )
{
   hb_retl( hb_parnl(1) & ( 1 << (hb_parni(2)-1) ) );
}

HB_FUNC( HWG_SIN )
{
   hb_retnd( sin( hb_parnd(1) ) );
}

HB_FUNC( HWG_COS )
{
   hb_retnd( cos( hb_parnd(1) ) );
}

HB_FUNC( CLIENTTOSCREEN )
{
   POINT pt;
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   pt.x = hb_parnl(2);
   pt.y = hb_parnl(3);
   ClientToScreen( (HWND) HB_PARHANDLE(1), &pt );

   temp = hb_itemPutNL( NULL, pt.x );
   hb_itemArrayPut( aPoint, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pt.y );
   hb_itemArrayPut( aPoint, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aPoint );
   hb_itemRelease( aPoint );
}

HB_FUNC( SCREENTOCLIENT )
{
   POINT pt;
   RECT R;
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   if( hb_pcount() > 2)
   {
      pt.x = hb_parnl(2);
      pt.y = hb_parnl(3);

      ScreenToClient( (HWND) HB_PARHANDLE(1), &pt );
   }
   else
   {
      Array2Rect( hb_param(2,HB_IT_ARRAY),&R);
      ScreenToClient( (HWND) HB_PARHANDLE(1), (LPPOINT)&R );
      ScreenToClient( (HWND) HB_PARHANDLE(1), ((LPPOINT)&R)+1 );
      hb_itemRelease(hb_itemReturn(Rect2Array(&R)));
      return ;

   }

   temp = hb_itemPutNL( NULL, pt.x );
   hb_itemArrayPut( aPoint, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pt.y );
   hb_itemArrayPut( aPoint, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aPoint );
   hb_itemRelease( aPoint );

}

HB_FUNC( HWG_GETCURSORPOS )
{
   POINT pt;
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   PHB_ITEM temp;

   GetCursorPos( &pt );
   temp = hb_itemPutNL( NULL, pt.x );
   hb_itemArrayPut( aPoint, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, pt.y );
   hb_itemArrayPut( aPoint, 2, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aPoint );
   hb_itemRelease( aPoint );

}

HB_FUNC( GETCURRENTDIR )
{
   BYTE pbyBuffer[ _POSIX_PATH_MAX + 1 ];

   GetCurrentDirectory( _POSIX_PATH_MAX, ( char * ) pbyBuffer );
   hb_retc( ( char *) pbyBuffer );
}

HB_FUNC( WINEXEC )
{
   hb_retni( WinExec( (LPCSTR) hb_parc(1), (UINT) hb_parni(2) ) );
}

HB_FUNC( GETKEYBOARDSTATE )
{
   BYTE lpbKeyState[256];
   GetKeyboardState( lpbKeyState );
   lpbKeyState[255] = '\0';
   hb_retclen( ( char *) lpbKeyState,255 );
}

HB_FUNC( GETKEYSTATE )
{
   hb_retni( GetKeyState( hb_parni( 1 ) ) ) ;
}

HB_FUNC( GETKEYNAMETEXT )
{
   char cText[MAX_PATH] ;
   int iRet = GetKeyNameText( hb_parnl( 1 ), cText, MAX_PATH ) ;

   if ( iRet )
     hb_retclen( cText, iRet ) ;
}

HB_FUNC( ACTIVATEKEYBOARDLAYOUT )
{
   char * cLayout = hb_parc(1);
   HKL curr = GetKeyboardLayout( 0 );
   char sBuff[KL_NAMELENGTH];
   UINT num = GetKeyboardLayoutList( 0, NULL ), i = 0;

   do
   {
      GetKeyboardLayoutName( (LPTSTR)sBuff );
      if( !strcmp( sBuff,cLayout ) )
         break;
      ActivateKeyboardLayout( 0,0 );
      i ++;
   }

   while( i < num );
   if( i >= num )
      ActivateKeyboardLayout( curr,0 );
}

/*
 * Pts2Pix( nPoints [,hDC] ) --> nPixels
 * Conversion from points to pixels, provided by Vic McClung.
 */

HB_FUNC( PTS2PIX )
{

   HDC hDC;
   BOOL lDC = 1;

   if( hb_pcount() > 1 && !ISNIL(1) )
   {
      hDC = (HDC) HB_PARHANDLE(2);
      lDC = 0;
   }
   else
      hDC = CreateDC( "DISPLAY", NULL, NULL, NULL );

   hb_retni( MulDiv( hb_parni(1), GetDeviceCaps( hDC, LOGPIXELSY ), 72 ) );
   if( lDC )
      DeleteDC( hDC );
}

/* Functions Contributed  By Luiz Rafael Culik Guimaraes( culikr@uol.com.br) */

HB_FUNC( GETWINDOWSDIR )
{
   char szBuffer[ MAX_PATH + 1 ] = {0} ;

   GetWindowsDirectory( szBuffer,MAX_PATH);
   hb_retc(szBuffer);
}

HB_FUNC( GETSYSTEMDIR )
{
   char szBuffer[ MAX_PATH + 1 ] = {0} ;

   GetSystemDirectory( szBuffer,MAX_PATH);
   hb_retc(szBuffer);
}

HB_FUNC( GETTEMPDIR )
{
   char szBuffer[ MAX_PATH + 1 ] = {0} ;
   GetTempPath(MAX_PATH, szBuffer);
   hb_retc(szBuffer);
}

#ifndef __XHARBOUR__
HB_FUNC( NUMTOHEX )
{
   int iCipher;
   char ret[32];
   char tmp[32];
   int len = 0, len1 = 0;
   ULONG ulNum = (ULONG) hb_parnl( 1 );

   while ( ulNum > 0 )
   {
      iCipher = ulNum % 16;
      if ( iCipher < 10 )
      {
         tmp[ len++ ] = '0' + iCipher;
      }
      else
      {
         tmp[ len++ ] = 'A' + (iCipher - 10 );
      }
      ulNum >>=4;
   }

   while ( len > 0 )
   {
      ret[len1++] = tmp[ --len ];
   }

   ret[len1] = '\0';

   hb_retc( ret );
}
#endif

HB_FUNC( POSTQUITMESSAGE )
{
  PostQuitMessage( hb_parni(1) );
}

/*
Contributed by Rodrigo Moreno rodrigo_moreno@yahoo.com base upon code minigui
*/

HB_FUNC( SHELLABOUT )
{
   /* ShellAbout( 0, hb_parc( 1 ), hb_parc( 2 ), (HICON) HB_PARHANDLE(3) ); */
   hb_retni( ShellAbout( (HWND) HB_PARHANDLE(1), (LPCSTR) hb_parcx(1), (LPCSTR) hb_parcx(2) , (ISNIL(3) ? NULL : (HICON) HB_PARHANDLE(3)))) ;
}


HB_FUNC( GETDESKTOPWIDTH )
{
   hb_retni ( GetSystemMetrics(SM_CXSCREEN) ) ;
}

HB_FUNC( GETDESKTOPHEIGHT )
{
   hb_retni ( GetSystemMetrics(SM_CYSCREEN) ) ;
}

HB_FUNC( GETHELPDATA )
{
   hb_retnl( (LONG) (((HELPINFO FAR *) hb_parnl(1))->hItemHandle) );
}

HB_FUNC( WINHELP )
{
   DWORD context;
   UINT style ;

   switch( hb_parni(3) )
   {
      case 0:
         style = HELP_FINDER ;
         context = 0 ;
         break;

      case 1:
         style = HELP_CONTEXT ;
         context = hb_parni(4) ;
         break;

      case 2:
         style = HELP_CONTEXTPOPUP ;
         context = hb_parni(4) ;
         break;

      default:
         style = HELP_CONTENTS ;
         context = 0 ;
   }

   hb_retni(WinHelp(( HWND )hb_parnl ( 1 ), (LPCTSTR)hb_parc( 2 ), style, context));
}

HB_FUNC( GETNEXTDLGTABITEM )
{
   HB_RETHANDLE(  GetNextDlgTabItem( (HWND) HB_PARHANDLE( 1 ), (HWND) HB_PARHANDLE( 2 ), hb_parl( 3 ) ) ) ;
}

HB_FUNC( SLEEP )
{
    if (hb_parinfo(1))
        Sleep(hb_parnl(1));
}

HB_FUNC( KEYB_EVENT )
{
   DWORD dwFlags = ( !(ISNIL(2)) && hb_parl(2) )? KEYEVENTF_EXTENDEDKEY : 0;
   int bShift = ( !(ISNIL(3)) && hb_parl(3) )? TRUE : FALSE;
   int bCtrl = ( !(ISNIL(4)) && hb_parl(4) )? TRUE : FALSE;
   int bAlt = ( !(ISNIL(5)) && hb_parl(5) )? TRUE : FALSE;

   if( bShift )
      keybd_event( VK_SHIFT, 0, 0, 0 );
   if( bCtrl )
      keybd_event( VK_CONTROL, 0, 0, 0 );
   if( bAlt )
      keybd_event( VK_MENU, 0, 0, 0 );

   keybd_event( hb_parni(1), 0, dwFlags, 0 );
   keybd_event( hb_parni(1), 0, dwFlags | KEYEVENTF_KEYUP, 0 );

   if( bShift )
      keybd_event( VK_SHIFT, 0, KEYEVENTF_KEYUP, 0 );
   if( bCtrl )
      keybd_event( VK_CONTROL, 0, KEYEVENTF_KEYUP, 0 );
   if( bAlt )
      keybd_event( VK_MENU, 0, KEYEVENTF_KEYUP, 0 );
}

/* SetScrollInfo( hWnd, nType, nRedraw, nPos, nPage )
*/
HB_FUNC( SETSCROLLINFO )
{
   SCROLLINFO si;
   UINT fMask = (hb_pcount()<4)? SIF_DISABLENOSCROLL:0;

   if( hb_pcount() > 3 && !ISNIL( 4 ) )
   {
      si.nPos = hb_parni( 4 );
      fMask |= SIF_POS;
   }

   if( hb_pcount() > 4 && !ISNIL( 5 ) )
   {
      si.nPage = hb_parni( 5 );
      fMask |= SIF_PAGE;
   }

   if( hb_pcount() > 5 && !ISNIL( 6 ) )
   {
      si.nMin = 1;
      si.nMax = hb_parni( 6 );
      fMask |= SIF_RANGE;
   }

   si.cbSize = sizeof( SCROLLINFO );
   si.fMask = fMask;

   SetScrollInfo(
    (HWND) HB_PARHANDLE( 1 ), // handle of window with scroll bar
    hb_parni( 2 ),    // scroll bar flags
    &si, hb_parni( 3 )    // redraw flag
   );
}

HB_FUNC( GETSCROLLRANGE )
{
   int MinPos, MaxPos;

   GetScrollRange(
    (HWND) HB_PARHANDLE( 1 ), // handle of window with scroll bar
    hb_parni( 2 ),  // scroll bar flags
    &MinPos,  // address of variable that receives minimum position
    &MaxPos   // address of variable that receives maximum position
   );
   hb_storni( MinPos, 3 );
   hb_storni( MaxPos, 4 );
}

HB_FUNC( SETSCROLLRANGE )
{
   hb_retl( SetScrollRange((HWND) HB_PARHANDLE(1), hb_parni(2), hb_parni(3), hb_parni(4), hb_parl(5)) );
}


HB_FUNC( GETSCROLLPOS )
{
   hb_retni( GetScrollPos(
               (HWND) HB_PARHANDLE( 1 ),  // handle of window with scroll bar
               hb_parni( 2 )  // scroll bar flags
             ) );
}

HB_FUNC( SETSCROLLPOS )
{
   SetScrollPos(
      (HWND) HB_PARHANDLE( 1 ), // handle of window with scroll bar
      hb_parni( 2 ),  // scroll bar flags
      hb_parni( 3 ),
      TRUE
   );
}

HB_FUNC( SHOWSCROLLBAR )
{
   ShowScrollBar(
      (HWND) HB_PARHANDLE( 1 ), // handle of window with scroll bar
      hb_parni( 2 ),          // scroll bar flags
      hb_parl( 3 )              // scroll bar visibility
   );
}

HB_FUNC (SCROLLWINDOW)
{
 ScrollWindow((HWND) HB_PARHANDLE(1), hb_parni(2),hb_parni(3),NULL,NULL);
}


HB_FUNC ( ISCAPSLOCKACTIVE )
{
   hb_retl ( GetKeyState( VK_CAPITAL ) ) ;
}

HB_FUNC ( ISNUMLOCKACTIVE )
{
   hb_retl ( GetKeyState( VK_NUMLOCK ) ) ;
}

HB_FUNC ( ISSCROLLLOCKACTIVE )
{
   hb_retl ( GetKeyState( VK_SCROLL ) ) ;
}

/* Added By Sandro Freire sandrorrfreire_nospam_yahoo.com.br*/

HB_FUNC ( CREATEDIRECTORY )
{
   CreateDirectory( (LPCTSTR) hb_parc(1), NULL );
}

HB_FUNC( REMOVEDIRECTORY )
{
   hb_retl( RemoveDirectory( (LPCSTR) hb_parc( 1 ) ) );
}

HB_FUNC ( SETCURRENTDIRECTORY )
{
   SetCurrentDirectory( (LPCTSTR) hb_parc(1) );
}

HB_FUNC( DELETEFILE )
{
   hb_retl( DeleteFile( (LPCSTR) hb_parc( 1 ) ) ) ;
}

HB_FUNC( GETFILEATTRIBUTES )
{
   hb_retnl( (LONG) GetFileAttributes( (LPCSTR) hb_parc( 1 ) ) ) ;
}

HB_FUNC( SETFILEATTRIBUTES )
{
   hb_retl( SetFileAttributes( (LPCSTR) hb_parc( 1 ), (DWORD) hb_parnl( 2 ) ) ) ;
}

/* Add by Richard Roesnadi (based on What32) */
// GETCOMPUTERNAME( [@nLengthChar] ) -> cComputerName
HB_FUNC( GETCOMPUTERNAME )
{
   char *cText;
   DWORD nSize = 31+1;
   cText = ( char * ) hb_xgrab( 32 );
   GetComputerNameA( cText, &nSize );
   hb_retc(cText) ;
   hb_stornl( nSize, 1 ) ;
   hb_xfree( (void *) cText );
}


// GETUSERNAME( [@nLengthChar] ) -> cUserName
HB_FUNC( GETUSERNAME )
{
   char *szUser ;
   DWORD nSize  ;
   szUser = ( char * ) hb_xgrab( 32 );
   GetUserNameA( szUser, &nSize )  ;
   hb_retc(szUser);
   hb_xfree( (void *) szUser );
   hb_stornl( nSize, 1 ) ;
}


HB_FUNC ( ISDOWNPRESSESED )
{
   hb_retl ( HIWORD(GetKeyState( VK_DOWN)) >0 ) ;
}

HB_FUNC ( ISPGDOWNPRESSESED )
{
   hb_retl ( HIWORD(GetKeyState( VK_NEXT)) >0 ) ;
}

HB_FUNC( EDIT1UPDATECTRL )
{
   HWND hChild = (HWND) HB_PARHANDLE( 1 ) ;
   HWND hParent= (HWND) HB_PARHANDLE( 2 ) ;
   RECT *rect = NULL;

   GetWindowRect(hChild,rect);
   ScreenToClient(hParent,(LPPOINT)rect);
   ScreenToClient(hParent,((LPPOINT)rect)+1);
   InflateRect(rect,-2,-2);
   InvalidateRect(hParent,rect, TRUE);
   UpdateWindow(hParent);
}

HB_FUNC( BUTTON1GETSCREENCLIENT )
{
   HWND hChild = (HWND) HB_PARHANDLE( 1 ) ;
   HWND hParent= (HWND) HB_PARHANDLE( 2 ) ;
   RECT *rect = NULL;

   GetWindowRect(hChild,rect);
   ScreenToClient(hParent,(LPPOINT)rect);
   ScreenToClient(hParent,((LPPOINT)rect)+1);
   hb_itemRelease( hb_itemReturn( Rect2Array(rect) ) );
}

HB_FUNC( HEDITEX_CTLCOLOR )
{
   HDC hdc = (HDC) HB_PARHANDLE( 1 ) ;
   //UINT h = hb_parni( 2 ) ;
   PHB_ITEM pObject = hb_param( 3, HB_IT_OBJECT );
   PHB_ITEM p,p1,p2,temp;
   LONG i;
   HBRUSH hBrush;
   COLORREF cColor;

   if (!pObject)
   {
      hb_retnl((LONG)GetStockObject(HOLLOW_BRUSH));
      SetBkMode(hdc,TRANSPARENT);
      return;
   }

   p = GetObjectVar( pObject, "M_BRUSH" );
   p2 = GetObjectVar( pObject, "M_TEXTCOLOR" );
   cColor = (COLORREF) hb_itemGetNL(p2);
   hBrush = (HBRUSH)HB_GETHANDLE(p);

   DeleteObject(hBrush );

   p1 = GetObjectVar( pObject, "M_BACKCOLOR" );
   i = hb_itemGetNL(p1);
   if ( i == -1 )
   {
     hBrush = (HBRUSH) GetStockObject(HOLLOW_BRUSH);
     SetBkMode(hdc,TRANSPARENT);
   }
   else
   {
     hBrush=CreateSolidBrush((COLORREF)i);
     SetBkColor(hdc,(COLORREF)i);
   }

   temp = HB_PUTHANDLE( NULL,hBrush  );
   SetObjectVar( pObject, "_M_BRUSH", temp );
   hb_itemRelease( temp );

   SetTextColor(hdc,cColor);
   HB_RETHANDLE(hBrush);
}

HB_FUNC( GETKEYBOARDCOUNT )
{
   LPARAM lParam = (LPARAM) hb_parnl(1);

   hb_retni((WORD)lParam);
}

HB_FUNC(GETNEXTDLGGROUPITEM)
{
 HB_RETHANDLE( GetNextDlgGroupItem( (HWND) HB_PARHANDLE( 1 ), (HWND) HB_PARHANDLE( 2 ), hb_parl( 3 ) ) ) ;
}

