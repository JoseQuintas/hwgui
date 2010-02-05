/*
 * $Id: shellapi.c,v 1.17 2010-02-05 12:02:33 druzus Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Shell API wrappers
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
// #define OEMRESOURCE
#include <windows.h>
#include <shlobj.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hwingui.h"

#define  ID_NOTIFYICON   1
#define  WM_NOTIFYICON   WM_USER+1000

#ifndef BIF_USENEWUI
#ifndef BIF_NEWDIALOGSTYLE
#define BIF_NEWDIALOGSTYLE     0x0040   // Use the new dialog layout with the ability to resize
#endif
#define BIF_USENEWUI           (BIF_NEWDIALOGSTYLE | BIF_EDITBOX)
#endif
#ifndef BIF_EDITBOX
#define BIF_EDITBOX            0x0010   // Add an editbox to the dialog
#endif

/*
 *  SelectFolder( cTitle )
 */

HB_FUNC( SELECTFOLDER )
{
   BROWSEINFO bi;
   TCHAR lpBuffer[ MAX_PATH ];
   LPITEMIDLIST pidlBrowse;     // PIDL selected by user 
   void * hTitle;

   bi.hwndOwner = GetActiveWindow();
   bi.pidlRoot = NULL;
   bi.pszDisplayName = lpBuffer;
   bi.lpszTitle = HB_PARSTRDEF( 1, &hTitle, NULL );
   bi.ulFlags = BIF_USENEWUI;
   bi.lpfn = NULL;
   bi.lParam = 0;
   bi.iImage = 0;

   // Browse for a folder and return its PIDL. 
   pidlBrowse = SHBrowseForFolder( &bi );
   SHGetPathFromIDList( pidlBrowse, lpBuffer );
   HB_RETSTR( lpBuffer );
   hb_strfree( hTitle );
}

/*
 *  ShellNotifyIcon( lAdd, hWnd, hIcon, cTooltip )
 */

HB_FUNC( SHELLNOTIFYICON )
{
   NOTIFYICONDATA tnid;

   memset( ( void * ) &tnid, 0, sizeof( NOTIFYICONDATA ) );

   tnid.cbSize = sizeof( NOTIFYICONDATA );
   tnid.hWnd = ( HWND ) HB_PARHANDLE( 2 );
   tnid.uID = ID_NOTIFYICON;
   tnid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
   tnid.uCallbackMessage = WM_NOTIFYICON;
   tnid.hIcon = ( HICON ) HB_PARHANDLE( 3 );
   HB_ITEMCOPYSTR( hb_param( 4, HB_IT_ANY ), tnid.szTip, HB_SIZEOFARRAY( tnid.szTip ) );

   if( ( BOOL ) hb_parl( 1 ) )
      Shell_NotifyIcon( NIM_ADD, &tnid );
   else
      Shell_NotifyIcon( NIM_DELETE, &tnid );
}

/*
  *  ShellModifyIcon( hWnd, hIcon, cTooltip )
  */

HB_FUNC( SHELLMODIFYICON )
{
   NOTIFYICONDATA tnid;

   memset( ( void * ) &tnid, 0, sizeof( NOTIFYICONDATA ) );

   tnid.cbSize = sizeof( NOTIFYICONDATA );
   tnid.hWnd = ( HWND ) HB_PARHANDLE( 1 );
   tnid.uID = ID_NOTIFYICON;
   if( ISNUM( 2 ) || ISPOINTER( 2 ) )
   {
      tnid.uFlags |= NIF_ICON;
      tnid.hIcon = ( HICON ) HB_PARHANDLE( 2 );
   }
   if( HB_ITEMCOPYSTR( hb_param( 3, HB_IT_ANY ),
                       tnid.szTip, HB_SIZEOFARRAY( tnid.szTip ) ) > 0 )
   {
      tnid.uFlags |= NIF_TIP;
   }

   Shell_NotifyIcon( NIM_MODIFY, &tnid );
}

/*
 * ShellExecute( cFile, cOperation, cParams, cDir, nFlag )
 */
HB_FUNC( SHELLEXECUTE )
{
   void * hOperation;
   void * hFile;
   void * hParameters;
   void * hDirectory;
   LPCTSTR lpDirectory;

   lpDirectory = HB_PARSTR( 4, &hDirectory , NULL );
   if( lpDirectory == NULL )
      lpDirectory = TEXT( "C:\\" );

   hb_retnl( ( LONG ) ShellExecute( GetActiveWindow(),
                  HB_PARSTRDEF( 2, &hOperation, NULL ),
                  HB_PARSTR( 1, &hFile, NULL ),
                  HB_PARSTR( 3, &hParameters, NULL ),
                  lpDirectory,
                  ISNUM( 5 ) ? hb_parni( 5 ) : SW_SHOWNORMAL ) );

   hb_strfree( hOperation );
   hb_strfree( hFile );
   hb_strfree( hParameters );
   hb_strfree( hDirectory );
}
