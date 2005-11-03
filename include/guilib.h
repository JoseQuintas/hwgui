/*
 *$Id: guilib.h,v 1.10 2005-11-03 19:47:37 alkresin Exp $
 */

#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11

#ifndef __XHARBOUR__
  #ifdef __EXPORT__
    extern PHB_ITEM hb_stackReturn( void );
  #else
    #define	hb_stackReturn()        (&hb_stack.Return)
  #endif
#endif

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#ifdef HWG_USE_POINTER_ITEM
   #define HB_RETHANDLE( h )        hb_retptr( ( void * ) ( h ) )
   #define HB_PARHANDLE( n )        hb_parptr( n )
   #define HB_STOREHANDLE( h, n )   hb_storptr( ( void * ) ( h ), n )
   #define HB_PUTHANDLE( i, h )     hb_itemPutPtr( i, ( void * ) ( h ) )
   #define HB_GETHANDLE( i )        hb_itemGetPtr( i )
#else
   #define HB_RETHANDLE( h )        hb_retnl( ( LONG ) ( h ) )
   #define HB_PARHANDLE( n )        ( ( void * ) hb_parnl( n ) )
   #define HB_STOREHANDLE( h, n )   hb_stornl( ( LONG ) ( h ), n )
   #define HB_PUTHANDLE( i, h )     hb_itemPutNL( i, ( LONG ) ( h ) )
   #define HB_GETHANDLE( i )        ( ( void * ) hb_itemGetNL( i ) )
#endif
