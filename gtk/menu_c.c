/*
 * $Id: menu_c.c,v 1.4 2005-09-15 09:33:47 lf_sfnet Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * C level menu functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 */

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "guilib.h"
#include "gtk/gtk.h"

#ifndef __XHARBOUR__
#ifdef __EXPORT__
PHB_ITEM hb_stackReturn( void );
#endif
#endif

#define  FLAG_DISABLED   1
#define  FLAG_CHECK      2

extern void cb_signal( GtkWidget *widget,gchar* data );
extern GtkFixed * getFixedBox( GObject * handle );

/*
 *  CreateMenu() --> hMenu
 */
HB_FUNC( HWG__CREATEMENU )
{
   hb_retnl( (LONG) gtk_menu_bar_new() );
}

HB_FUNC( HWG__CREATEPOPUPMENU )
{
   // hb_retnl( (LONG) CreatePopupMenu() );
}

/*
 *  AddMenuItem( hMenu,cCaption,nPos,hWnd,nId,fState,lSubMenu ) --> lResult
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
      hb_retnl( (LONG) hSubMenu );
   }
   else
   {
      char buf[20];
      sprintf( buf,"0 %ld %ld",hb_parnl(5),hb_parnl(4) );
      g_signal_connect(G_OBJECT (hMenu), "activate",
          G_CALLBACK (cb_signal), (gpointer) g_strdup (buf));
   
      hb_retnl( (LONG) hMenu );
   }
   gtk_menu_shell_append( GTK_MENU_SHELL( hb_parnl(1) ), hMenu );

   gtk_widget_show( hMenu );
}

/*
 *  SetMenu( hWnd, hMenu ) --> lResult
 */
HB_FUNC( HWG__SETMENU )
{
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
   GtkWidget * vbox = ( (GtkWidget*)box )->parent;
   gtk_box_pack_start( GTK_BOX (vbox), (GtkWidget*)hb_parnl(2), FALSE, FALSE, 2);
   /*
   if ( box )
      gtk_fixed_put( box,(GtkWidget*)hb_parnl(2),0,0 );
   */      
   hb_retl(1);
}

HB_FUNC( GETMENUHANDLE )
{
   // HWND handle = ( hb_pcount()>0 && !ISNIL(1) )? (HWND)hb_parnl(1):aWindows[0];
   // hb_retnl( (LONG) GetMenu( handle ) );
}

HB_FUNC( CHECKMENUITEM )
{
/*
   HMENU hMenu = ( hb_pcount()>0 && !ISNIL(1) )? ((HMENU)hb_parnl(1)):GetMenu(aWindows[0]);
   UINT  uCheck = ( hb_pcount() < 3 || !ISLOG( 3 ) || hb_parl( 3 ) )? MF_CHECKED:MF_UNCHECKED;

   if( !hMenu )
      MessageBox( GetActiveWindow(), "", "No Menu!", MB_OK | MB_ICONINFORMATION );
   else
   {
      CheckMenuItem(
         hMenu,	                // handle to menu 
         hb_parni( 2 ),         // menu item to check or uncheck
         MF_BYCOMMAND | uCheck  // menu item flags 
      );
   }
*/   
}

HB_FUNC( ISCHECKEDMENUITEM )
{
/*
   HMENU hMenu = ( hb_pcount()>0 && !ISNIL(1) )? ((HMENU)hb_parnl(1)):GetMenu(aWindows[0]);
   UINT  uCheck;

   if( !hMenu )
      hb_retl( 0 );
   else
   {
      uCheck = GetMenuState(
         hMenu,	                // handle to menu 
         hb_parni( 2 ),         // menu item to check or uncheck
         MF_BYCOMMAND           // menu item flags 
      );
      hb_retl( uCheck & MF_CHECKED );
   }
*/   
}

HB_FUNC( ENABLEMENUITEM )
{
/*
   HMENU hMenu = ( hb_pcount()>0 && !ISNIL(1) )? ((HMENU)hb_parnl(1)) : GetMenu(aWindows[0]);
   UINT  uEnable = ( hb_pcount() < 3 || !ISLOG( 3 ) || hb_parl( 3 ) )? MF_ENABLED:MF_GRAYED;
   UINT  uFlag = ( hb_pcount() < 4 || !ISLOG( 4 ) || hb_parl( 4 ) )? MF_BYCOMMAND:MF_BYPOSITION;

   if( !hMenu )
   {
      MessageBox( GetActiveWindow(), "", "No Menu!", MB_OK | MB_ICONINFORMATION );
      hb_retnl( -1 );
   }
   else
   {
      hb_retnl( (LONG) EnableMenuItem(
         hMenu,	                // handle to menu 
         hb_parni( 2 ),         // menu item to check or uncheck
         uFlag | uEnable // menu item flags 
      ) );
   }
*/   
}

HB_FUNC( ISENABLEDMENUITEM )
{
/*
   HMENU hMenu = ( hb_pcount()>0 && !ISNIL(1) )? ((HMENU)hb_parnl(1)):GetMenu(aWindows[0]);
   UINT  uCheck;
   UINT  uFlag = ( hb_pcount() < 3 || !ISLOG( 3 ) || hb_parl( 3 ) )? MF_BYCOMMAND:MF_BYPOSITION;

   if( !hMenu )
      hb_retl( 0 );
   else
   {
      uCheck = GetMenuState(
         hMenu,	                // handle to menu 
         hb_parni( 3 ),         // menu item to check or uncheck
         uFlag           // menu item flags 
      );
      hb_retl( !( uCheck & MF_GRAYED ) );
   }
*/   
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
