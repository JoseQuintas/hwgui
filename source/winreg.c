// Registry interface

#include "hwingui.h"
#include <shlobj.h>
//#include <commctrl.h>

#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"
#include "winreg.h"

#if defined(__DMC__)
__inline long PtrToLong( const void *p )
{
   return ( ( long ) p );
}
#endif

/*
 * Harbour Project source code:
 * Registry functions for Harbour
 *
 * Copyright 2001-2002 Luiz Rafael Culik<culikr@uol.com.br>
 * www - http://www.harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

HB_FUNC( REGCLOSEKEY )
{
   HKEY hwHandle = ( HKEY ) hb_parnl( 1 );

   if( RegCloseKey( hwHandle ) == ERROR_SUCCESS )
   {
      hb_retnl( ERROR_SUCCESS );
   }
   else
   {
      hb_retnl( -1 );
   }
}

HB_FUNC( REGOPENKEYEX )
{
   HKEY hwKey = ( ( HKEY ) hb_parnl( 1 ) );
   void * hValue;
   LPCTSTR lpValue = HB_PARSTRDEF( 2, &hValue, NULL );
   LONG lError;
   HKEY phwHandle;

   lError = RegOpenKeyEx( ( HKEY ) hwKey, lpValue, 0, KEY_ALL_ACCESS,
                          &phwHandle );
   if( lError > 0 )
   {
      hb_retni( -1 );
   }
   else
   {
      hb_stornl( PtrToLong( phwHandle ), 5 );
      hb_retni( 0 );
   }
   hb_strfree( hValue );
}

HB_FUNC( REGQUERYVALUEEX )
{
   HKEY hwKey = ( ( HKEY ) hb_parnl( 1 ) );
   LONG lError;
   DWORD lpType = hb_parnl( 4 );
   DWORD lpcbData = 0;
   void * hValue;
   LPCTSTR lpValue = HB_PARSTRDEF( 2, &hValue, NULL );

   lError = RegQueryValueEx( hwKey, lpValue, NULL, &lpType, NULL, &lpcbData );
   if( lError == ERROR_SUCCESS )
   {
      BYTE *lpData = ( BYTE * )
                     memset( hb_xgrab( lpcbData + 1 ), 0, lpcbData + 1 );
      lError = RegQueryValueEx( hwKey, lpValue, NULL, &lpType,
                                lpData, &lpcbData );
      if( lError > 0 )
      {
         hb_retni( -1 );
      }
      else
      {
         hb_storc( ( char * ) lpData, 5 );
         hb_retni( 0 );
      }

      hb_xfree( lpData );
   }
   hb_strfree( hValue );
}


HB_FUNC( REGENUMKEYEX )
{
   FILETIME ft;
   long nErr;
   TCHAR Buffer[255];
   DWORD dwBuffSize = 255;
   TCHAR Class[255];
   DWORD dwClass = 255;

   nErr = RegEnumKeyEx( ( HKEY ) hb_parnl( 1 ), hb_parnl( 2 ), Buffer,
                        &dwBuffSize, NULL, Class, &dwClass, &ft );

   if( nErr == ERROR_SUCCESS )
   {
      HB_STORSTR( Buffer, 3 );
      hb_stornl( ( long ) dwBuffSize, 4 );
      HB_STORSTR( Class, 6 );
      hb_stornl( ( long ) dwClass, 7 );
   }
   hb_retnl( nErr );
}


HB_FUNC( REGSETVALUEEX )
{
   void * hValue;

   hb_retnl( RegSetValueEx( ( HKEY ) hb_parnl( 1 ),
                            HB_PARSTRDEF( 2, &hValue, NULL ), 0,
                            hb_parnl( 4 ), ( const BYTE * ) hb_parcx( 5 ),
                            hb_parclen( 5 ) + 1 ) );
   hb_strfree( hValue );
}

HB_FUNC( REGCREATEKEY )
{
   HKEY hKey;
   LONG nErr;
   void * hValue;

   nErr = RegCreateKey( ( HKEY ) hb_parnl( 1 ),
                        HB_PARSTRDEF( 2, &hValue, NULL ), &hKey );
   if( nErr == ERROR_SUCCESS )
   {
      hb_stornl( PtrToLong( hKey ), 3 );
   }
   hb_retnl( nErr );
   hb_strfree( hValue );
}

//-------------------------------------------------------
/*
LONG RegCreateKeyEx(
  HKEY hKey,                // handle to an open key
  LPCTSTR lpSubKey,         // address of subkey name
  DWORD Reserved,           // reserved
  LPTSTR lpClass,           // address of class string
  DWORD dwOptions,          // special options flag
  REGSAM samDesired,        // desired security access
  LPSECURITY_ATTRIBUTES lpSecurityAttributes,
                            // address of key security structure
  PHKEY phkResult,          // address of buffer for opened handle
  LPDWORD lpdwDisposition   // address of disposition value buffer
);

*/

HB_FUNC( REGCREATEKEYEX )
{
   HKEY hkResult;
   DWORD dwDisposition;
   LONG nErr;
   SECURITY_ATTRIBUTES *sa = NULL;
   void * hValue, * hClass;

   if( HB_ISCHAR( 7 ) )
      sa = ( SECURITY_ATTRIBUTES * ) hb_parc( 7 );

   nErr = RegCreateKeyEx( ( HKEY ) hb_parnl( 1 ),
                          HB_PARSTRDEF( 2, &hValue, NULL ),
                          ( DWORD ) 0,
                          ( LPTSTR ) HB_PARSTRDEF( 4, &hClass, NULL ),
                          ( DWORD ) hb_parnl( 5 ),
                          ( DWORD ) hb_parnl( 6 ),
                          sa, &hkResult, &dwDisposition );

   if( nErr == ERROR_SUCCESS )
   {
      hb_stornl( ( LONG ) hkResult, 8 );
      hb_stornl( ( LONG ) dwDisposition, 9 );
   }
   hb_retnl( nErr );
   hb_strfree( hValue );
   hb_strfree( hClass );
}


HB_FUNC( REGDELETEKEY )
{
   void * hValue;

   hb_retni( RegDeleteKey( ( HKEY ) hb_parnl( 1 ),
               HB_PARSTRDEF( 2, &hValue, NULL ) ) == ERROR_SUCCESS ? 0 : -1 );
   hb_strfree( hValue );
}

//  For strange reasons this function is not working properly
//  May be I am missing something. Pritpal Bedi.

HB_FUNC( REGDELETEVALUE )
{
   void * hValue;

   hb_retni( RegDeleteValue( ( HKEY ) hb_parnl( 1 ),
               HB_PARSTRDEF( 2, &hValue, NULL ) ) == ERROR_SUCCESS ? 0 : -1 );
   hb_strfree( hValue );
}
