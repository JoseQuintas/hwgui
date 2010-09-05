/*
 * $Id: resource.c,v 1.20 2010-09-05 22:48:43 andijahja Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * C level resource functions
 *
 * Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/

*/

#define HB_OS_WIN_32_USED

#define _WIN32_WINNT 0x0400
// #define OEMRESOURCE
#include <windows.h>

#if defined(__MINGW32__) || defined(__WATCOMC__)
#include <prsht.h>
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "hbinit.h"
#include "hwingui.h"

HMODULE hModule;

HB_FUNC( GETRESOURCES )
{
   hb_retnl( ( LONG ) hModule );
}

HB_FUNC( LOADSTRING )
{
   TCHAR buffer[ 2048 ];
   int iBuffRet = LoadString( ( HINSTANCE ) hModule, ( UINT ) hb_parnl( 2 ),
                              buffer, 2048 );
   HB_RETSTRLEN( buffer, iBuffRet );
}

HB_FUNC( LOADRESOURCE )
{
   void * hString;
   hModule = GetModuleHandle( HB_PARSTR( 1, &hString, NULL ) );
   hb_strfree( hString );
}

void hb_resourcemodules( void * cargo )
{
   HB_SYMBOL_UNUSED( cargo );

   hModule = GetModuleHandle( NULL );
}

HB_CALL_ON_STARTUP_BEGIN( _hwgui_module_init_ )
   hb_vmAtInit( hb_resourcemodules, NULL );
HB_CALL_ON_STARTUP_END( _hwgui_module_init_ )

#if defined( HB_PRAGMA_STARTUP )
   #pragma startup _hwgui_module_init_
#elif defined( HB_DATASEG_STARTUP )
   #define HB_DATASEG_BODY    HB_DATASEG_FUNC( _hwgui_module_init_ )
   #include "hbiniseg.h"
#elif defined( HB_MSC_STARTUP )  // support for old [x]Harbour version
   #if defined( HB_OS_WIN_64 )
      #pragma section( HB_MSC_START_SEGMENT, long, read )
   #endif
   #pragma data_seg( HB_MSC_START_SEGMENT )
   static HB_$INITSYM hb_vm_auto_hwgui_module_init_ = _hwgui_module_init_;
   #pragma data_seg()
#endif

HB_FUNC( FINDRESOURCE )
{
   HRSRC hHRSRC;
   int iName = hb_parni( 2 ); // "WindowsXP.Manifest";
   int iType = hb_parni( 3 ); // RT_MANIFEST = 24
   void * hString;

   hModule = GetModuleHandle( HB_PARSTR( 1, &hString, NULL ) );
   hb_strfree( hString );

   if( IS_INTRESOURCE( iName ) )
   {
      hHRSRC = FindResource( ( HMODULE ) hModule,
                             MAKEINTRESOURCE( iName ),
                             MAKEINTRESOURCE( iType ) );
      HB_RETHANDLE( hHRSRC );
   }
   else
      HB_RETHANDLE( 0 );
}
