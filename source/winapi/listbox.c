/*
 * $Id$
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HList class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Listbox class and accompanying code added Feb 22nd, 2004 by
 * Vic McClung
*/

#include "hwingui.h"
#if defined(__MINGW32__) || defined(__WATCOMC__)
#include <prsht.h>
#endif
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"

HB_FUNC( HWG_LISTBOXADDSTRING )
{
   void * hString;

   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_ADDSTRING, 0,
                ( LPARAM ) HB_PARSTR( 2, &hString, NULL ) );
   hb_strfree( hString );
}

HB_FUNC( HWG_LISTBOXSETSTRING )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_SETCURSEL,
         ( WPARAM ) hb_parni( 2 ) - 1, 0 );
}

/*
   CreateListbox( hParentWIndow, nListboxID, nStyle, x, y, nWidth, nHeight)
*/
HB_FUNC( HWG_CREATELISTBOX )
{
   HWND hListbox = CreateWindow( TEXT( "LISTBOX" ),     /* predefined class  */
         TEXT( "" ),                    /*   */
         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ), /* style  */
         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
         ( HMENU ) hb_parni( 2 ),       /* listbox ID      */
         GetModuleHandle( NULL ),
         NULL );

   HB_RETHANDLE( hListbox );
}

HB_FUNC( HWG_LISTBOXDELETESTRING )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_DELETESTRING, 0, ( LPARAM ) 0 );
}
