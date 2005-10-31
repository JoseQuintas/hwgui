/*
 * $Id: misc.c,v 1.23 2005-10-31 15:00:30 lculik Exp $
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

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbmath.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "guilib.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

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
   SetWindowLong( (HWND) hb_parnl(1), DWL_MSGRESULT, hb_parni(2) );
}

HB_FUNC( SETCAPTURE )
{
   hb_retnl( (LONG) SetCapture( (HWND) hb_parnl(1) ) );
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

HB_FUNC( GETSTOCKOBJECT )
{
   hb_retnl( (LONG) GetStockObject( hb_parni(1) ) );
}

HB_FUNC( LOWORD )
{
   hb_retni( (int) ( hb_parnl( 1 ) & 0xFFFF ) );
}

HB_FUNC( HIWORD )
{
   hb_retni( (int) ( ( hb_parnl( 1 ) >> 16 ) & 0xFFFF ) );
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
   POINT pt = { 0 };
   
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   #ifdef __XHARBOUR__
   PHB_ITEM temp = hb_itemNew( NULL );
   #else
   PHB_ITEM temp;
   #endif

   pt.x = hb_parnl(2);
   pt.y = hb_parnl(3);
   ClientToScreen( (HWND) hb_parnl(1), &pt );

   #ifdef __XHARBOUR__
   {   
   hb_arraySetForward( aPoint, 1, hb_itemPutNL( temp, pt.x ) );      
   hb_arraySetForward( aPoint, 2, hb_itemPutNL( temp, pt.y ) );   

   hb_itemRelease( temp );   
   hb_itemForwardValue( hb_stackReturnItem(), aPoint );
   hb_itemRelease(  aPoint );             
   }
   #else
   {
   temp = _itemPutNL( NULL, pt.x );
   _itemArrayPut( aPoint, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, pt.y );
   _itemArrayPut( aPoint, 2, temp );
   _itemRelease( temp );

   _itemReturn( aPoint );
   _itemRelease( aPoint );
   }
   #endif
}

HB_FUNC( SCREENTOCLIENT )
{
   POINT pt = { 0 };
   
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   #ifdef __XHARBOUR__
   PHB_ITEM temp = hb_itemNew( NULL );
   #else
   PHB_ITEM temp;
   #endif
   pt.x = hb_parnl(2);
   pt.y = hb_parnl(3);
   ScreenToClient( (HWND) hb_parnl(1), &pt );

   #ifdef __XHARBOUR__
   {   
   hb_arraySetForward( aPoint, 1, hb_itemPutNL( temp, pt.x ) );   
   hb_arraySetForward( aPoint, 2, hb_itemPutNL( temp, pt.y ) );   

   hb_itemRelease( temp );
   hb_itemForwardValue( hb_stackReturnItem(), aPoint );
   hb_itemRelease(  aPoint );             
   }
   #else
   {
   temp = _itemPutNL( NULL, pt.x );
   _itemArrayPut( aPoint, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, pt.y );
   _itemArrayPut( aPoint, 2, temp );
   _itemRelease( temp );

   _itemReturn( aPoint );
   _itemRelease( aPoint );
   }
   #endif

}

HB_FUNC( HWG_GETCURSORPOS )
{
   POINT pt= { 0 };
   PHB_ITEM aPoint = hb_itemArrayNew( 2 );
   #ifdef __XHARBOUR__
   PHB_ITEM temp = hb_itemNew( NULL );
   #else
   PHB_ITEM temp;
   #endif
   GetCursorPos( &pt );
   #ifdef __XHARBOUR__
   {
   
   hb_arraySetForward( aPoint, 1, hb_itemPutNL( temp, pt.x ) );    
   hb_arraySetForward( aPoint, 2, hb_itemPutNL( temp, pt.y ) );
 
   hb_itemRelease( temp );
   hb_itemForwardValue( hb_stackReturnItem(), aPoint );
   hb_itemRelease(  aPoint );             
   }
   #else
   {
   temp = _itemPutNL( NULL, pt.x );
   _itemArrayPut( aPoint, 1, temp );
   _itemRelease( temp );

   temp = _itemPutNL( NULL, pt.y );
   _itemArrayPut( aPoint, 2, temp );
   _itemRelease( temp );

   _itemReturn( aPoint );
   _itemRelease( aPoint );
   }
   #endif

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
      hDC = (HDC) hb_parnl(2);
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
HB_FUNC( HB_NUMTOHEX )
{
   ULONG ulNum;
   int iCipher;
   char ret[32];
   char tmp[32];
   int len = 0, len1 = 0;

   ulNum = (ULONG) hb_parnl( 1 );

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

/* Contributed by Rodrigo Moreno rodrigo_moreno@yahoo.com base upon code minigui */

HB_FUNC( SHELLABOUT )
{
   ShellAbout( 0, hb_parc( 1 ), hb_parc( 2 ), (HICON) hb_parnl(3) );
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

    int x = hb_parni(3);

    switch( x )
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
   /*
   nextHandle := GetNextDlgTabITem ( GetActiveWindow() , GetFocus() , .t. )
   
   HWND GetNextDlgTabItem(HWND hDlg, HWND hCtl, BOOL bPrevious )
   
   hDlg - Handle to the dialog box to be searched. 
   hCtl - Handle to the control to be used as the starting point for the search. If this parameter is NULL, the function uses the last (or first) control in the dialog box as the starting point for the search. 
   bPrevious - Specifies how the function is to search the dialog box. If this parameter is TRUE, the function searches for the previous control in the dialog box. If this parameter is FALSE, the function searches for the next control in the dialog box. 
   */
   
   hb_retnl( (LONG) GetNextDlgTabItem( (HWND) hb_parnl( 1 ), (HWND) hb_parnl( 2 ), hb_parl( 3 ) ) ) ;
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

   if( bShift )
      keybd_event( VK_SHIFT, 0, 0, 0 );
   keybd_event( hb_parni(1), 0, dwFlags, 0 );
   keybd_event( hb_parni(1), 0, dwFlags | KEYEVENTF_KEYUP, 0 );
   if( bShift )
      keybd_event( VK_SHIFT, 0, KEYEVENTF_KEYUP, 0 );

}

/* SetScrollInfo( hWnd, nType, nRedraw, nPos, nPage )
*/
HB_FUNC( SETSCROLLINFO )
{
   SCROLLINFO si = { 0 };
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
    (HWND) hb_parnl( 1 ), // handle of window with scroll bar
    hb_parni( 2 ),	  // scroll bar flags
    &si, hb_parni( 3 )    // redraw flag
   );
}

HB_FUNC( GETSCROLLRANGE )
{

   int MinPos, MaxPos;

   GetScrollRange(
    (HWND) hb_parnl( 1 ),	// handle of window with scroll bar
    hb_parni( 2 ),	// scroll bar flags
    &MinPos,	// address of variable that receives minimum position
    &MaxPos 	// address of variable that receives maximum position
   );
   hb_storni( MinPos, 3 );
   hb_storni( MaxPos, 4 );
}

HB_FUNC( GETSCROLLPOS )
{

   hb_retni( GetScrollPos(
               (HWND) hb_parnl( 1 ),	// handle of window with scroll bar
               hb_parni( 2 )	// scroll bar flags
             ) );
}

HB_FUNC( SETSCROLLPOS )
{

   SetScrollPos(
      (HWND) hb_parnl( 1 ),	// handle of window with scroll bar
      hb_parni( 2 ),	// scroll bar flags
      hb_parni( 3 ),
      TRUE
   );
}

HB_FUNC( SHOWSCROLLBAR )
{
   ShowScrollBar(
      (HWND) hb_parnl( 1 ),	// handle of window with scroll bar
      hb_parni( 2 ),	        // scroll bar flags
      hb_parl( 3 )              // scroll bar visibility
   );
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

