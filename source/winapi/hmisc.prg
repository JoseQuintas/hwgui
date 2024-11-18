/*
 *$Id$
 *
 * HWGUI - Harbour Win32 GUI and GTK library source code:
 * Misc functions
 *
 * This is a container for several useful functions.
 * Don't forget to add the desription in the function docu, if
 * a new function is added.
 * Try to make versions for WinAPI and GTK equal.
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Copyright 2020-2024 Wilfried Brunken, DF7BE
 
 * November 2024:
 * All multi platform functions of this module are moved to
 * source/cross/hmisccross.prg
 * Add here only functions platform dependant. 
 * (DF7BE)
 
*/

#include "hwgui.ch"
#include "hbclass.ch"


* The function hwg_HdSerial for WinAPI found in guimain.prg   

#pragma BEGINDUMP

#include "hbapi.h"

HB_FUNC( HWG_HAS_WIN_EURO_SUPPORT )
{
#ifdef __XHARBOUR__
   hb_retl( 0 );
#else
#if ( HB_VER_REVID - 0 ) >= 2002101634
   hb_retl( 1 );
#else
   hb_retl( 0 );
#endif
#endif
}

#pragma ENDDUMP


* ======================= EOF of hmisc.prg ===========================
