/*
 * $Id: resource.c,v 1.9 2009-06-05 14:24:53 alkresin Exp $
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

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "hbinit.h"

HMODULE hModule ;

#if 0
	void hb_resourcemodules( void );
#endif

HB_FUNC( GETRESOURCES )
{
   hb_retnl( ( LONG ) hModule );
}

HB_FUNC( LOADSTRING )
{
   char Buffer[ 2048 ];
   int  BuffRet = LoadString( ( HINSTANCE ) hModule , ( UINT ) hb_parnl( 2 ), Buffer, 2048 );

   hb_retclen(Buffer, BuffRet);
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
	   hModule = GetModuleHandle( NULL ) ;
	}
#endif

HB_FUNC_INIT( HWG_INITRESOURCE )
{
   hModule = GetModuleHandle( NULL ) ;
}

#ifdef __XHARBOUR__
#define __PRG_SOURCE__ __FILE__
#ifdef HB_PCODE_VER
#  undef HB_PRG_PCODE_VER
#  define HB_PRG_PCODE_VER HB_PCODE_VER
#endif
#endif

HB_INIT_SYMBOLS_BEGIN( hwg_resource_INIT )
#ifdef __XHARBOUR__
{ "HWG_INITRESOURCE$", {HB_FS_INIT | HB_FS_LOCAL}, {HB_INIT_FUNCNAME( HWG_INITRESOURCE )}, &ModuleFakeDyn }
#else
{ "HWG_INITRESOURCE$", {HB_FS_INIT | HB_FS_LOCAL}, {HB_INIT_FUNCNAME( HWG_INITRESOURCE )}, NULL }
#endif
HB_INIT_SYMBOLS_END( hwg_resource_INIT )

#if defined(HB_PRAGMA_STARTUP)
   #pragma startup hwg_resource_INIT
#elif defined(HB_MSC_STARTUP)
#if defined( HB_OS_WIN_64 )
#pragma section( HB_MSC_START_SEGMENT, long, read )
#endif
#pragma data_seg( HB_MSC_START_SEGMENT )
   static HB_$INITSYM hb_vm_auto_SymbolInit_INIT = hwg_resource_INIT;
   #pragma data_seg()
#endif
