/*
 *$Id: guilib.h,v 1.9 2004-10-04 12:15:11 alkresin Exp $
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
