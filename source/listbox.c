/*
 * $Id: listbox.c,v 1.4 2004-09-29 05:24:52 alkresin Exp $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HList class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
 * Listbox class and accompanying code added Feb 22nd, 2004 by
 * Vic McClung
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
#include "guilib.h"



HB_FUNC( LISTBOXADDSTRING )
{
   char *cString = hb_parc( 2 );
   SendMessage( (HWND) hb_parnl( 1 ), LB_ADDSTRING, 0, (LPARAM) cString );
}

HB_FUNC( LISTBOXSETSTRING )
{
   SendMessage( (HWND) hb_parnl( 1 ), LB_SETCURSEL, (WPARAM) hb_parni(2)-1, 0);
}


/*
   CreateListbox( hParentWIndow, nListboxID, nStyle, x, y, nWidth, nHeight)
*/
HB_FUNC( CREATELISTBOX )
{
   HWND hListbox =
         CreateWindow(
                 "LISTBOX",                  /* predefined class  */
                 "",                                        /*   */
                 WS_CHILD | WS_VISIBLE | hb_parnl(3),    /* style  */
                 hb_parni(4), hb_parni(5),           /* x, y       */
                 hb_parni(6), hb_parni(7),      /* nWidth, nHeight */
                 (HWND) hb_parnl(1),           /* parent window    */
                 (HMENU) hb_parni(2),          /* listbox ID      */
                 GetModuleHandle( NULL ),
                 NULL);

   hb_retnl( (LONG) hListbox );

}

