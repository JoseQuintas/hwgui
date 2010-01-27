/*
 *$Id: hwingui.h,v 1.5 2010-01-27 09:18:35 druzus Exp $
 */

#include <windows.h>
#include "guilib.h"

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

#if !defined( __XHARBOUR__ ) && ( __HARBOUR__ - 0 > 0x020000 )
   #include "hbwinuni.h"
   #define HB_HAS_STR_FUNC
#else
   #undef HB_HAS_STR_FUNC

   #define HB_PARSTR( n, h, len )                hwg_strget( hb_param( n, HB_IT_ANY ), h, len )
   #define HB_PARSTRDEF( n, h, len )             hwg_strnull( hwg_strget( hb_param( n, HB_IT_ANY ), h, len ) )
   #define HB_RETSTR( str )                      hb_retc( str )
   #define HB_RETSTRLEN( str, len )              hb_retclen( str, len )
   #define HB_STORSTR( str, n )                  hb_storc( str, n )
   #define HB_STORSTRLEN( str, len, n )          hb_storclen( str, len, n )
   #define HB_ARRAYGETSTR( arr, n, h, len )      hwg_strget( hb_arrayGetItemPtr( arr, n ), h, len )
   #define HB_ARRAYSETSTR( arr, n, str )         hb_arraySetC( arr, n, str )
   #define HB_ARRAYSETSTRLEN( arr, n, str, len ) hb_arraySetCL( arr, n, str, len )
   #define HB_ITEMCOPYSTR( itm, str, len )       hwg_strcopy( itm, str, len )
   #define HB_ITEMGETSTR( itm, h, len )          hwg_strget( itm, h, len )
   #define HB_ITEMPUTSTR( itm, str )             hb_itemPutC( itm, str )
   #define HB_ITEMPUTSTRLEN( itm, str, len )     hb_itemPutCL( itm, str, len )
   #define HB_STRUNSHARE( h, str, len )          hwg_strunshare( h, str, len )

   HB_EXTERN_BEGIN
   extern const char *  hwg_strnull( const char * str );
   extern const char *  hwg_strget( PHB_ITEM pItem, void ** phStr, HB_SIZE * pulLen );
   extern HB_SIZE       hwg_strcopy( PHB_ITEM pItem, char * pStr, HB_SIZE ulLen );
   extern char *        hwg_strunshare( void ** phStr, const char * pStr, HB_SIZE ulLen );
   extern void          hwg_strfree( void * hString );
   HB_EXTERN_END

   #define hb_strfree( h )    hwg_strfree( h )
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
extern int iDialogs;
extern HMODULE hModule;
extern PHB_DYNS pSym_onEvent;

HB_EXTERN_END
