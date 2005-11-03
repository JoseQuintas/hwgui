/*
 * $Id: menu_c.c,v 1.10 2005-11-03 19:47:37 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level menu functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 */

#include "guilib.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "gtk/gtk.h"

#ifndef __XHARBOUR__
#ifdef __EXPORT__
PHB_ITEM hb_stackReturn( void );
#endif
#endif
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif
#define  FLAG_DISABLED   1
#define  FLAG_CHECK      2

extern GtkWidget * aWindows[];
extern void cb_signal( GtkWidget *widget,gchar* data );
extern GtkFixed * getFixedBox( GObject * handle );

/*
 *  CreateMenu() --> hMenu
 */
HB_FUNC( HWG__CREATEMENU )
{
   HB_RETHANDLE( gtk_menu_bar_new() );
}

HB_FUNC( HWG__CREATEPOPUPMENU )
{
   // hb_retnl( (LONG) CreatePopupMenu() );
}

/*
 *  AddMenuItem( hMenu,cCaption,nPos,hWnd,nId,fState,lSubMenu ) --> hMenuItem
 */

HB_FUNC( HWG__ADDMENUITEM )
{
   GtkWidget * hMenu;
   BOOL lString = FALSE, lCheck = FALSE;
   char * lpNewItem = NULL;

   if( ISCHAR( 2 ) )
   {
      char * ptr;
      lpNewItem	 = hb_parc(2);
      ptr = lpNewItem;
      while( *ptr )
      {
         if( *ptr != ' ' && *ptr != '-' )
         {
            lString = TRUE;
            break;
         }
         ptr ++;
      }
   }
   if( !ISNIL(6) && ( hb_parni(6) & FLAG_CHECK ) )
      lCheck = TRUE;

   if( lCheck )
   {
      char * cptr = g_locale_to_utf8( lpNewItem, -1, NULL, NULL, NULL);
      hMenu = gtk_check_menu_item_new_with_mnemonic( cptr );
      g_free( cptr );
   }
   else if( lString )
   {
      char * cptr = g_locale_to_utf8( lpNewItem, -1, NULL, NULL, NULL);
      hMenu = (GtkWidget *) gtk_menu_item_new_with_mnemonic( cptr );
      g_free( cptr );
   }
   else
      hMenu = (GtkWidget *) gtk_separator_menu_item_new();

   if( hb_parl(7) )
   {
      GtkWidget * hSubMenu = gtk_menu_new();
      gtk_menu_item_set_submenu( GTK_MENU_ITEM (hMenu), hSubMenu );
      HB_RETHANDLE( hSubMenu );
   }
   else
   {
      char buf[20]={0};
      sprintf( buf,"0 %ld %ld",hb_parnl(5),( LONG ) HB_PARHANDLE(4) );
      g_signal_connect(G_OBJECT (hMenu), "activate",
          G_CALLBACK (cb_signal), (gpointer) g_strdup (buf));

      HB_RETHANDLE( hMenu );
   }
   gtk_menu_shell_append( GTK_MENU_SHELL( HB_PARHANDLE(1) ), hMenu );

   gtk_widget_show( hMenu );
}

/*
 *  SetMenu( hWnd, hMenu ) --> lResult
 */
HB_FUNC( HWG__SETMENU )
{
   GObject * handle = (GObject*) HB_PARHANDLE(1);
   GtkFixed * box = getFixedBox( handle );
   GtkWidget * vbox = ( (GtkWidget*)box )->parent;
   gtk_box_pack_start( GTK_BOX (vbox), (GtkWidget*)HB_PARHANDLE(2), FALSE, FALSE, 0);
   hb_retl(1);
}

HB_FUNC( GETMENUHANDLE )
{
   // HWND handle = ( hb_pcount()>0 && !ISNIL(1) )? (HWND)hb_parnl(1):aWindows[0];
   // hb_retnl( (LONG) GetMenu( handle ) );
}

HB_FUNC( HWG_CHECKMENUITEM )
{
   GtkCheckMenuItem * check_menu_item = (GtkCheckMenuItem *) HB_PARHANDLE(1);

   g_signal_handlers_block_matched( (gpointer)check_menu_item, G_SIGNAL_MATCH_FUNC,
       0, 0, 0, G_CALLBACK (cb_signal), 0 );
   gtk_check_menu_item_set_active( check_menu_item, (ISNIL(2))? 1 : hb_parl(2) );
   g_signal_handlers_unblock_matched( (gpointer)check_menu_item, G_SIGNAL_MATCH_FUNC,
       0, 0, 0, G_CALLBACK (cb_signal), 0 );

}

HB_FUNC( HWG_ISCHECKEDMENUITEM )
{
   GtkCheckMenuItem * check_menu_item = (GtkCheckMenuItem *) HB_PARHANDLE(1);

   hb_retl( gtk_check_menu_item_get_active( check_menu_item ) );
}

HB_FUNC( HWG_ENABLEMENUITEM )
{
   GtkMenuItem * menu_item = (GtkMenuItem *) HB_PARHANDLE(1);

   gtk_widget_set_sensitive( (GtkWidget*)menu_item, (ISNIL(2))? 1 : hb_parl(2) );
}

HB_FUNC( HWG_ISENABLEDMENUITEM )
{
   hb_retl( GTK_WIDGET_IS_SENSITIVE( (GtkMenuItem*) HB_PARHANDLE(1) ) );
}

HB_FUNC( HWG_TRACKMENU )
{
/*
    hb_retl( TrackPopupMenu(
                  (HMENU) hb_parnl(1),  // handle of shortcut menu
                  TPM_RIGHTALIGN,       // screen-position and mouse-button flags
                  hb_parni(2),          // horizontal position, in screen coordinates
                  hb_parni(3),          // vertical position, in screen coordinates
                  0,                    // reserved, must be zero
                  (HWND) hb_parnl(4),   // handle of owner window
                  NULL
    ) );
*/
}

HB_FUNC( HWG_DESTROYMENU )
{
/*
   hb_retl( DestroyMenu( (HMENU) hb_parnl(1) ) );
*/
}

/*
 * CreateAcceleratorTable( _aAccel )
 */
HB_FUNC( CREATEACCELERATORTABLE )
{
/*
   PHB_ITEM pArray = hb_param( 1, HB_IT_ARRAY ), pSubArr;
   LPACCEL lpaccl;
   int cEntries = (int) pArray->item.asArray.value->ulLen;
   int i;
   HACCEL h;

   lpaccl = (LPACCEL) hb_xgrab( sizeof(ACCEL)*cEntries );

   for( i=0; i<cEntries; i++ )
   {
      pSubArr = pArray->item.asArray.value->pItems + i;
      lpaccl[i].fVirt = (BYTE) hb_itemGetNL( pSubArr->item.asArray.value->pItems ) | FNOINVERT | FVIRTKEY;
      lpaccl[i].key = (WORD) hb_itemGetNL( pSubArr->item.asArray.value->pItems + 1 );
      lpaccl[i].cmd = (WORD) hb_itemGetNL( pSubArr->item.asArray.value->pItems + 2 );
   }
   h = CreateAcceleratorTable( lpaccl,cEntries );

   hb_xfree( lpaccl );
   hb_retnl( (LONG) h );
*/   
}

/*
 * DestroyAcceleratorTable( hAccel )
 */
HB_FUNC( DESTROYACCELERATORTABLE )
{
   // hb_retl( DestroyAcceleratorTable( (HACCEL) hb_parnl(1) ) );
}

/*
 *  SetMenuCaption( hMenu, nMenuId, cCaption )
 */
HB_FUNC( SETMENUCAPTION )
{
/*
   MENUITEMINFO mii;

   mii.cbSize = sizeof( MENUITEMINFO );
   mii.fMask = MIIM_TYPE;
   mii.fType = MFT_STRING;
   mii.dwTypeData = hb_parc( 3 );

   if( SetMenuItemInfo( ( HMENU ) hb_parnl( 1 ), hb_parni( 2 ), 0, &mii ) )
      hb_retl( 1 );
   else
      hb_retl( 0 );
*/      
}
