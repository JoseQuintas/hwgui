/*
 *$Id: guilib.h,v 1.19 2009-08-23 10:21:26 druzus Exp $
 */

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbdefs.h"

#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11
#define ST_ALIGN_HORIZ         0           // Icon/bitmap on the left, text on the right
#define ST_ALIGN_VERT          1           // Icon/bitmap on the top, text on the bottom
#define ST_ALIGN_HORIZ_RIGHT   2           // Icon/bitmap on the right, text on the left
#define ST_ALIGN_OVERLAP       3           // Icon/bitmap on the same space as text

#ifdef __MSC6__
   #define GetWindowLongPtr    GetWindowLong
   #define SetWindowLongPtr    SetWindowLong
   #define DWORD_PTR           DWORD
#endif

#ifdef HWG_USE_POINTER_ITEM
   #define HB_RETHANDLE( h )        hb_retptr( ( void * ) ( h ) )
   #define HB_PARHANDLE( n )        hb_parptr( n )
   #define HB_STOREHANDLE( h, n )   hb_storptr( ( void * ) ( h ), n )
   #define HB_PUTHANDLE( i, h )     hb_itemPutPtr( i, ( void * ) ( h ) )
   #define HB_GETHANDLE( i )        hb_itemGetPtr( i )
   #define HB_GETPTRHANDLE( i ,n )  hb_arrayGetPtr( i , n )
   #define HB_PUSHITEM( i )         hb_vmPushPointer( ( void * )i ) 
#else
   #define HB_RETHANDLE( h )        hb_retnl( ( LONG ) ( h ) )
   #define HB_PARHANDLE( n )        ( ( LONG ) hb_parnl( n ) )
   #define HB_STOREHANDLE( h, n )   hb_stornl( ( LONG ) ( h ), n )
   #define HB_PUTHANDLE( i, h )     hb_itemPutNL( i, ( LONG ) ( h ) )
   #define HB_GETHANDLE( i )        ( ( LONG ) hb_itemGetNL( i ) )
   #define HB_GETPTRHANDLE( i ,n )  hb_arrayGetNL( i , n )
   #define HB_PUSHITEM( i )         hb_vmPushLong( ( LONG )i ) 
#endif

#if !defined( HB_TCHAR_CPTO )
   #define HB_TCHAR_CPTO(d,s,l)        hb_strncpy(d,s,l)
   #define HB_TCHAR_SETTO(d,s,l)       memcpy(d,s,l)
   #define HB_TCHAR_GETFROM(d,s,l)     memcpy(d,s,l)
   #define HB_TCHAR_CONVTO(s)          (s)
   #define HB_TCHAR_CONVFROM(s)        (s)
   #define HB_TCHAR_CONVNTO(s,l)       (s)
   #define HB_TCHAR_CONVNFROM(s,l)     (s)
   #define HB_TCHAR_CONVNREV(d,s,l)    do { ; } while( 0 )
   #define HB_TCHAR_FREE(s)            HB_SYMBOL_UNUSED(s)
#endif

#ifdef HARBOUR_2005
   #define hb_dynsymSymbol( h )     h->pSymbol
#endif

#ifndef _POSIX_PATH_MAX
#define _POSIX_PATH_MAX 264
#endif

#if defined( __XHARBOUR__ ) || ( __HARBOUR__ - 0 < 0x020000 )
   #define hb_storvni hb_storni
#endif
