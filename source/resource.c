/*
 * $Id: resource.c,v 1.16 2009-12-17 12:29:21 andijahja Exp $
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
#include "guilib.h"

HMODULE hModule;

#if 0
void hb_resourcemodules( void );
#endif

HB_FUNC( GETRESOURCES )
{
   hb_retnl( ( LONG ) hModule );
}

HB_FUNC( LOADSTRING )
{
   char Buffer[2048];
   int BuffRet =
         LoadString( ( HINSTANCE ) hModule, ( UINT ) hb_parnl( 2 ), Buffer,
         2048 );

   hb_retclen( Buffer, BuffRet );
}

HB_FUNC( LOADRESOURCE )
{
   hModule = GetModuleHandle( ISCHAR( 1 ) ? hb_parc( 1 ) : NULL );
}

#if 0
#if (! defined(__GNUC__) && ! defined(__DMC__) )
#pragma startup hb_resourcemodules
#endif

void hb_resourcemodules( void )
{
   hModule = GetModuleHandle( NULL );
}
#endif

HB_FUNC_INIT( HWG_INITRESOURCE )
{
   hModule = GetModuleHandle( NULL );
}

#ifdef __XHARBOUR__
#define __PRG_SOURCE__ __FILE__
#ifdef HB_PCODE_VER
#  undef HB_PRG_PCODE_VER
#  define HB_PRG_PCODE_VER HB_PCODE_VER
#endif
#define __HB_MUDULE__   &ModuleFakeDyn
#else
#define __HB_MUDULE__   NULL
#endif

HB_INIT_SYMBOLS_BEGIN( hwg_resource_INIT )
{ "HWG_INITRESOURCE$", {HB_FS_INIT | HB_FS_LOCAL}, {HB_INIT_FUNCNAME( HWG_INITRESOURCE )}, __HB_MUDULE__ }
HB_INIT_SYMBOLS_END( hwg_resource_INIT )
#if defined( HB_PRAGMA_STARTUP )
#  pragma startup hwg_resource_INIT
#elif defined( HB_DATASEG_STARTUP )
   #define HB_DATASEG_BODY    HB_DATASEG_FUNC( hwg_resource_INIT )
   #include "hbiniseg.h"
#endif

HB_FUNC( FINDRESOURCE )
{
   HRSRC hHRSRC;
   int lpName = hb_parni( 2 ) ; //"WindowsXP.Manifest";
   int lpType = hb_parni( 3 ) ; // RT_MANIFEST = 24

   hModule = GetModuleHandle( ISCHAR( 1 ) ? hb_parc( 1 ) : NULL );

   if( IS_INTRESOURCE( lpName ) )
   {
     hHRSRC = FindResource( ( HMODULE ) hModule,
      ( LPCTSTR ) lpName ,
      ( LPCTSTR ) lpType ) ;

      HB_RETHANDLE( hHRSRC );
   }
   else
      HB_RETHANDLE( 0 );
}
