/*
 * $Id: control.c,v 1.2 2005-01-14 06:29:14 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Widget creation functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#ifdef __EXPORT__
   #define HB_NO_DEFAULT_API_MACROS
   #define HB_NO_DEFAULT_STACK_MACROS
#endif

#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "guilib.h"
#include "gtk/gtk.h"

#define SS_CENTER                 1
#define SS_RIGHT                  2

#define BS_AUTO3STATE       6
#define BS_AUTORADIOBUTTON  9

static GtkTooltips * pTooltip = NULL;
static PHB_DYNS pSymTimerProc = NULL;

GtkFixed * getFixedBox( GObject * handle )
{
   gpointer dwNewLong = g_object_get_data( handle, "obj" );
   
   if( dwNewLong )
   {
      PHB_ITEM pObj = hb_itemNew( NULL );
      PHB_DYNS pMsg = hb_dynsymGet( "FBOX" );
      GtkFixed * box;      

      pObj->type = HB_IT_OBJECT;
      pObj->item.asArray.value = (PHB_BASEARRAY) dwNewLong;
      if( pMsg )
      {
         hb_vmPushSymbol( pMsg->pSymbol );   /* Push message symbol */
         hb_vmPush( pObj );                  /* Push object */
         hb_vmDo( 0 );
      }
      box = (GtkFixed *) hb_itemGetNL( (PHB_ITEM) hb_stackReturn() ); 
      hb_itemRelease( pObj );
      return box;
   }
   else
      return NULL;
}

/*
   CreateStatic( hParentWindow, nControlID, nStyle, x, y, nWidth, nHeight, nExtStyle, cTitle )
*/
HB_FUNC( CREATESTATIC )
{
   ULONG ulStyle = hb_parnl(3);
   char * cTitle = ( hb_pcount() > 8 )? hb_parc(9) : "";
   GtkWidget * hCtrl;

   cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );
   hCtrl = gtk_label_new( cTitle );
   g_free( cTitle );
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );  
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );
   
   if( !( ulStyle & SS_CENTER ) )
      gtk_label_set_justify( (GtkLabel*)hCtrl, ( ulStyle & SS_RIGHT )? GTK_JUSTIFY_RIGHT : GTK_JUSTIFY_LEFT );

   hb_retnl( (LONG) hCtrl );

}

HB_FUNC( HWG_STATIC_SETTEXT )
{
   char * cTitle = g_locale_to_utf8( hb_parc(2),-1,NULL,NULL,NULL );
   gtk_label_set_text( (GtkLabel*)hb_parnl(1), cTitle );
   g_free( cTitle );
}

/*
   CreateButton( hParentWindow, nButtonID, nStyle, x, y, nWidth, nHeight, 
               cCaption )
*/
HB_FUNC( CREATEBUTTON )
{
   GtkWidget * hCtrl;
   ULONG ulStyle = hb_parnl( 3 );
   char * cTitle = ( hb_pcount() > 7 )? hb_parc(8) : "";

   cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );
   if( ulStyle & BS_AUTORADIOBUTTON )
   {
      // hCtrl = gtk_radio_button_new_with_label( cTitle );
   }  
   else if( ulStyle & BS_AUTO3STATE )
      hCtrl = gtk_check_button_new_with_label( cTitle );
   else
      hCtrl = gtk_button_new_with_label( cTitle );

   g_free( cTitle );
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );  
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );

   hb_retnl( (LONG) hCtrl );

}

HB_FUNC( HWG_CHECKBUTTON )
{
   gtk_toggle_button_set_active( (GtkToggleButton*)hb_parnl(1), hb_parl(2) );
}

HB_FUNC( HWG_ISBUTTONCHECKED )
{
   hb_retl( gtk_toggle_button_get_active( (GtkToggleButton*)hb_parnl(1) ) );
}

/*
   CreateEdit( hParentWIndow, nEditControlID, nStyle, x, y, nWidth, nHeight,
               cInitialString )
*/
HB_FUNC( CREATEEDIT )
{
   GtkWidget * hCtrl = gtk_entry_new();
   char * cTitle = ( hb_pcount() > 7 )? hb_parc(8) : "";
   
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );  
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );
   
   if( *cTitle )
   {
      cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );   
      gtk_entry_set_text( (GtkEntry*)hCtrl, hb_parc(8) );
      g_free( cTitle );
   }

   hb_retnl( (LONG) hCtrl );

}

HB_FUNC( HWG_EDIT_SETTEXT )
{
   char * cTitle = g_locale_to_utf8( hb_parc(2),-1,NULL,NULL,NULL );
   gtk_entry_set_text( (GtkEntry*)hb_parnl(1), cTitle );
   g_free( cTitle );
}

HB_FUNC( HWG_EDIT_GETTEXT )
{
   char * cptr = (char*) gtk_entry_get_text( (GtkEntry*)hb_parnl(1) );
   if( *cptr )
   {
      cptr = g_locale_from_utf8( cptr,-1,NULL,NULL,NULL );
      hb_retc( cptr );
      g_free( cptr );
   }
   else
      hb_retc( "" );
}

HB_FUNC( HWG_EDIT_SETPOS )
{
   gtk_editable_set_position( (GtkEditable*)hb_parnl(1), hb_parni(2) );
}

HB_FUNC( HWG_EDIT_GETPOS )
{
   hb_retni( gtk_editable_get_position( (GtkEditable*)hb_parnl(1) ) );
}

/*
   CreateCombo( hParentWIndow, nComboID, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( CREATECOMBO )
{
   GtkWidget * hCtrl = gtk_combo_new();
   
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );  
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );
   
   hb_retnl( (LONG) hCtrl );
}

HB_FUNC( HWG_COMBOSETARRAY )
{
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   GList *glist = NULL;
   char * cItem;
   int i;

   for( i=0; i<pArr->item.asArray.value->ulLen; i++ )
   {
      cItem = g_locale_to_utf8( hb_itemGetCPtr( pArr->item.asArray.value->pItems + i ),-1,NULL,NULL,NULL );
      glist = g_list_append( glist, cItem );
      // g_free( cItem );
   }

   gtk_combo_set_popdown_strings( GTK_COMBO( hb_parnl(1) ), glist );

}

HB_FUNC( HWG_COMBOGETEDIT )
{
   hb_retnl( (LONG) (GTK_COMBO( hb_parnl(1) )->entry) );
}

/*
HB_FUNC( HWG_COMBOSETSTRING )
{
   gtk_entry_set_text( GTK_ENTRY (GTK_COMBO( hb_parnl(1) )->entry), hb_parc(2) );
}

HB_FUNC( HWG_COMBOGETSTRING )
{
   gtk_entry_get_text( GTK_ENTRY ( GTK_COMBO( hb_parnl(1) )->entry) );
}
*/

HB_FUNC( CREATEUPDOWNCONTROL )
{
   GtkObject * adj = gtk_adjustment_new( (gdouble) hb_parnl(6),  // value
                             (gdouble) hb_parnl(7),  // lower
                             (gdouble) hb_parnl(8),  // upper
                               1, 1, 1 );
   GtkWidget * hCtrl = gtk_spin_button_new( (GtkAdjustment*)adj,0.5,0 );
   
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(2), hb_parni(3) );  
   gtk_widget_set_size_request( hCtrl,hb_parni(4),hb_parni(5) );
   
   hb_retnl( (LONG) hCtrl );
			       
}

HB_FUNC( HWG_SETUPDOWN )
{
   gtk_spin_button_set_value( (GtkSpinButton*)hb_parnl(1), (gdouble)hb_parnl(2) );
}

HB_FUNC( HWG_GETUPDOWN )
{
   hb_retnl( gtk_spin_button_get_value_as_int( (GtkSpinButton*)hb_parnl(1) ) );
}

HB_FUNC( ADDTOOLTIP )
{
   if( !pTooltip )
      pTooltip = gtk_tooltips_new();
      
   gtk_tooltips_set_tip( pTooltip, (GtkWidget*)hb_parnl(2), hb_parc(3), NULL );
}

static gint cb_timer( gchar * data )
{
   LONG p1;

   sscanf( (char*)data,"%ld",&p1 );

   if( !pSymTimerProc )
      pSymTimerProc = hb_dynsymFind( "TIMERPROC" );
   if( pSymTimerProc )
   {
      hb_vmPushSymbol( pSymTimerProc->pSymbol );
      hb_vmPushNil();
      hb_vmPushLong( (LONG ) p1 );
      hb_vmDo( 1 );
   }
   return 1;
}

/*
 *  HWG_SetTimer( idTimer,i_MilliSeconds ) -> tag
 */

HB_FUNC( HWG_SETTIMER )
{
   char buf[10];
   sprintf( buf,"%ld",hb_parnl(1) );
   hb_retni( (gint) gtk_timeout_add( (guint32)hb_parnl(2), G_CALLBACK (cb_timer), g_strdup(buf) ) );
}

/*
 *  HWG_KillTimer( tag )
 */

HB_FUNC( HWG_KILLTIMER )
{
   gtk_timeout_remove( (gint) hb_parni(1) );
}

HB_FUNC( GETPARENT )
{
   hb_retnl( (LONG) ( (GtkWidget*) hb_parnl(1) )->parent );
}
