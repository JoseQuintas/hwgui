/*
 *$Id: guilib.h,v 1.6 2004-04-19 07:39:47 alkresin Exp $
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
