/*
 *$Id: guilib.h,v 1.22 2010-01-19 15:45:42 druzus Exp $
 */

#include <windows.h>
#include "hbdefs.h"


#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11
#define ST_ALIGN_HORIZ         0           // Icon/bitmap on the left, text on the right
#define ST_ALIGN_VERT          1           // Icon/bitmap on the top, text on the bottom
#define ST_ALIGN_HORIZ_RIGHT   2           // Icon/bitmap on the right, text on the left
#define ST_ALIGN_OVERLAP       3           // Icon/bitmap on the same space as text

#if ((defined(_MSC_VER)&&(_MSC_VER<1300)&&!defined(__POCC__)) || defined(__WATCOMC__)|| defined(__DMC__))
   #define IS_INTRESOURCE(_r) ((((ULONG_PTR)(_r)) >> 16) == 0)
   #if (defined(_MSC_VER)&&(_MSC_VER<1300)||defined(__DMC__))
      #define GetWindowLongPtr    GetWindowLong
      #define SetWindowLongPtr    SetWindowLong
      #define DWORD_PTR           DWORD
      #define LONG_PTR            LONG
      #define ULONG_PTR           ULONG
      #define GWLP_WNDPROC        GWL_WNDPROC
   #endif
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
   #define hb_dynsymSymbol( h )     ( ( h )->pSymbol )
#endif

#ifndef _POSIX_PATH_MAX
#  define _POSIX_PATH_MAX 264
#endif

#if !defined( __XHARBOUR__ ) && ( __HARBOUR__ - 0 >= 0x020000 )
   #include "hbwinuni.h"
#else
   #ifdef __XHARBOUR__
      #include "hbfast.h"
   #endif

   #define hb_storvni hb_storni

   #if !defined( __XHARBOUR__ ) && ( __HARBOUR__ - 0 < 0x020000 )
      typedef FHANDLE HB_FHANDLE;
   #endif
   typedef ULONG HB_SIZE;

   #define HB_NO_STR_FUNC

   #define HB_PARSTR( n, h, len )                hb_strget( hb_param( n, HB_IT_ANY ), h, len )
   #define HB_PARSTRDEF( n, h, len )             hb_strnull( hb_strget( hb_param( n, HB_IT_ANY ), h, len ) )
   #define HB_RETSTR( str )                      hb_retc( str )
   #define HB_RETSTRLEN( str, len )              hb_retclen( str, len )
   #define HB_STORSTR( str, n )                  hb_storc( str, n )
   #define HB_STORSTRLEN( str, len, n )          hb_storclen( str, len, n )
   #define HB_ARRAYGETSTR( arr, n, h, len )      hb_strget( hb_arrayGetItemPtr( arr, n ), h, len )
   #define HB_ARRAYSETSTR( arr, n, str )         hb_arraySetC( arr, n, str )
   #define HB_ARRAYSETSTRLEN( arr, n, str, len ) hb_arraySetCL( arr, n, str, len )
   #define HB_ITEMCOPYSTR( itm, str, len )       hb_strcopy( itm, str, len )
   #define HB_ITEMGETSTR( itm, h, len )          hb_strget( itm, h, len )
   #define HB_ITEMPUTSTR( itm, str )             hb_itemPutC( itm, str )
   #define HB_ITEMPUTSTRLEN( itm, str, len )     hb_itemPutCL( itm, str, len )
   #define HB_STRUNSHARE( h, str, len )          hb_strunshare( h, str, len )

   #ifndef HB_SIZEOFARRAY
      #define HB_SIZEOFARRAY( var )     ( sizeof( var ) / sizeof( *var ) )
   #endif

   HB_EXTERN_BEGIN
   extern const char * hb_strnull( const char * str );
   extern const char * hb_strget( PHB_ITEM pItem, void ** phStr, HB_SIZE * pulLen );
   extern HB_SIZE hb_strcopy( PHB_ITEM pItem, char * pStr, HB_SIZE ulLen );
   extern char * hb_strunshare( void ** phStr, const char * pStr, HB_SIZE ulLen );
   extern void hb_strfree( void * hString );
   HB_EXTERN_END

#endif

HB_EXTERN_BEGIN

extern void writelog( char* s );

extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, const char *varname );
extern void SetObjectVar( PHB_ITEM pObject, const char *varname, PHB_ITEM pValue );
extern void SetWindowObject( HWND hWnd, PHB_ITEM pObject );
extern PHB_ITEM Rect2Array( RECT * rc );
extern BOOL Array2Rect( PHB_ITEM aRect, RECT * rc );

extern HWND aWindows[];
extern HWND *aDialogs;
extern HMODULE hModule;
extern PHB_DYNS pSym_onEvent;

HB_EXTERN_END
