/*
 *$Id: guilib.h,v 1.7 2004-08-02 09:28:54 lf_sfnet Exp $
 */

#define	WND_DLG_RESOURCE       10
#define	WND_DLG_NORESOURCE     11

#ifndef __XHARBOUR__
  #ifdef __EXPORT__
    extern PHB_ITEM hb_stackReturn( void );
  #else
    #define	hb_stackReturn()        (&hb_stack.Return)
  #endif
#else
  #define XHBCVS    
#endif
