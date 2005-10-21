/*
 * $Id: control.c,v 1.17 2005-10-21 08:50:15 alkresin Exp $
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
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

#define SS_CENTER                 1
#define SS_RIGHT                  2

#define ES_MULTILINE        4
#define ES_READONLY      2048

#define BS_AUTO3STATE       6
#define BS_GROUPBOX         7
#define BS_AUTORADIOBUTTON  9

#define SS_OWNERDRAW        13    // 0x0000000DL

#define WM_PAINT            15
#define WM_HSCROLL         276
#define WM_VSCROLL         277

extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, char* varname );
extern void SetObjectVar( PHB_ITEM pObject, char* varname, PHB_ITEM pValue );
extern void SetWindowObject( GtkWidget * hWnd, PHB_ITEM pObject );
extern void set_signal( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 );
extern void set_event( gpointer handle, char * cSignal, long int p1, long int p2, long int p3 );
extern void cb_signal( GtkWidget *widget,gchar* data );
extern GtkWidget * GetActiveWindow( void );

static GtkTooltips * pTooltip = NULL;
static PHB_DYNS pSymTimerProc = NULL;

GtkFixed * getFixedBox( GObject * handle )
{
   return (GtkFixed *) g_object_get_data( handle, "fbox" );
/*
   gpointer dwNewLong = g_object_get_data( handle, "obj" );
   
   if( dwNewLong )
   {
      PHB_ITEM pObj = hb_itemNew( NULL );
      PHB_DYNS pMsg = hb_dynsymGet( "FBOX" );
      GtkFixed * box;      

      pObj->type = HB_IT_OBJECT;
      pObj->item.asArray.value = (PHB_BASEARRAY) dwNewLong;
      #ifndef UIHOLDERS
      pObj->item.asArray.value->ulHolders++;
      #else
      pObj->item.asArray.value->uiHolders++;
      #endif
 
      if( pMsg )
      {
         hb_vmPushSymbol( pMsg->pSymbol );
         hb_vmPush( pObj );
         hb_vmDo( 0 );
      }
      box = (GtkFixed *) hb_itemGetNL( (PHB_ITEM) hb_stackReturn() ); 
      hb_itemRelease( pObj );
      return box;
   }
   else
      return NULL;
*/
}

/*
   CreateStatic( hParentWindow, nControlID, nStyle, x, y, nWidth, nHeight, nExtStyle, cTitle )
*/
HB_FUNC( CREATESTATIC )
{
   ULONG ulStyle = hb_parnl(3);
   char * cTitle = ( hb_pcount() > 8 )? hb_parc(9) : "";
   GtkWidget * hCtrl, * hLabel;
   GtkFixed * box;

   if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
      hCtrl = gtk_drawing_area_new();
   else
   {
      hCtrl = gtk_event_box_new();
      cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );
      hLabel = gtk_label_new( cTitle );
      g_free( cTitle );
      gtk_container_add( GTK_CONTAINER(hCtrl), hLabel );
      g_object_set_data( (GObject*) hCtrl, "label", (gpointer) hLabel );
      if( !( ulStyle & SS_CENTER ) )
         gtk_misc_set_alignment( GTK_MISC(hLabel), ( ulStyle & SS_RIGHT )? 1 : 0, 0 );
   }
   #ifdef __GTK_USE_POINTER__
   box = getFixedBox( (GObject*) hb_parptr(1) );
   #else
   box = getFixedBox( (GObject*) hb_parnl(1) );
   #endif
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );

   if( ( ulStyle & SS_OWNERDRAW ) == SS_OWNERDRAW )
   {
      set_event( (gpointer)hCtrl, "expose_event", WM_PAINT, 0, 0 );
   }
   #ifdef __GTK_USE_POINTER__
   hb_retptr( ( void * ) hCtrl );
   #else
   hb_retnl( (LONG) hCtrl );
   #endif


}

HB_FUNC( HWG_STATIC_SETTEXT )
{
   char * cTitle = g_locale_to_utf8( hb_parc(2),-1,NULL,NULL,NULL );
   #ifdef __GTK_USE_POINTER__
   GtkLabel * hLabel = (GtkLabel*) g_object_get_data( (GObject*) hb_parptr(1),"label" );
   #else
   GtkLabel * hLabel = (GtkLabel*) g_object_get_data( (GObject*) hb_parnl(1),"label" );
   #endif
   gtk_label_set_text( hLabel, cTitle );
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
   GtkFixed * box;

   cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );
   if( ( ulStyle & 0xf ) == BS_AUTORADIOBUTTON )
   {
   #ifdef __GTK_USE_POINTER__
      GSList * group = (GSList*)hb_parptr(2);
   #else
      GSList * group = (GSList*)hb_parnl(2);
   #endif
      hCtrl = gtk_radio_button_new_with_label( group,cTitle );
      group = gtk_radio_button_get_group( (GtkRadioButton*)hCtrl );
   #ifdef __GTK_USE_POINTER__
      hb_storptr( (void*)group,2 );
   #else
      hb_stornl( (LONG)group,2 );
   #endif
   }
   else if( ( ulStyle & 0xf ) == BS_AUTO3STATE )
      hCtrl = gtk_check_button_new_with_label( cTitle );
   else if( ( ulStyle & 0xf ) == BS_GROUPBOX )
      hCtrl = gtk_frame_new( cTitle );
   else
      hCtrl = gtk_button_new_with_label( cTitle );

   g_free( cTitle );
   #ifdef __GTK_USE_POINTER__
   box = getFixedBox( (GObject*) hb_parptr(1) );
   #else
   box = getFixedBox( (GObject*) hb_parnl(1) );
   #endif
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );

   #ifdef __GTK_USE_POINTER__
   hb_retptr( (void*) hCtrl );
   #else
   hb_retnl( (LONG) hCtrl );
   #endif

}

HB_FUNC( HWG_CHECKBUTTON )
{
   #ifdef __GTK_USE_POINTER__
   gtk_toggle_button_set_active( (GtkToggleButton*)hb_parptr(1), hb_parl(2) );
   #else
   gtk_toggle_button_set_active( (GtkToggleButton*)hb_parnl(1), hb_parl(2) );
   #endif
}

HB_FUNC( HWG_ISBUTTONCHECKED )
{
   #ifdef __GTK_USE_POINTER__
   hb_retl( gtk_toggle_button_get_active( (GtkToggleButton*)hb_parptr(1) ) );
   #else
   hb_retl( gtk_toggle_button_get_active( (GtkToggleButton*)hb_parnl(1) ) );
   #endif
}

/*
   CreateEdit( hParentWIndow, nEditControlID, nStyle, x, y, nWidth, nHeight,
               cInitialString )
*/
HB_FUNC( CREATEEDIT )
{
   GtkWidget * hCtrl;
   char * cTitle = ( hb_pcount() > 7 )? hb_parc(8) : "";
   unsigned long ulStyle = (ISNIL(3))? 0 : hb_parnl(3);

   if( ulStyle & ES_MULTILINE )
   {
      hCtrl = gtk_text_view_new();
      g_object_set_data( (GObject*) hCtrl, "multi", (gpointer) 1 );
      if( ulStyle & ES_READONLY )
         gtk_text_view_set_editable( (GtkTextView*)hCtrl, 0 );
   }
   else
      hCtrl = gtk_entry_new();

   #ifdef __GTK_USE_POINTER__
   GtkFixed * box = getFixedBox( (GObject*) hb_parptr(1) );
   #else
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
   #endif
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );

   if( *cTitle )
   {
      cTitle = g_locale_to_utf8( cTitle,-1,NULL,NULL,NULL );
      if( ulStyle & ES_MULTILINE )
      {
         GtkTextBuffer *buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (hCtrl));
         gtk_text_buffer_set_text( buffer, cTitle, -1 );
      }
      else
         gtk_entry_set_text( (GtkEntry*)hCtrl, cTitle );
      g_free( cTitle );
   }

   #ifdef __GTK_USE_POINTER__
   hb_retptr( ( void *) hCtrl );
   #else
   hb_retnl( (LONG) hCtrl );
   #endif

}

HB_FUNC( HWG_EDIT_SETTEXT )
{
   #ifdef __GTK_USE_POINTER__
   GtkWidget * hCtrl = (GtkWidget *)hb_parptr(1);
   #else
   GtkWidget * hCtrl = (GtkWidget *)hb_parnl(1);
   #endif
   char * cTitle = g_locale_to_utf8( hb_parc(2),-1,NULL,NULL,NULL );

   if( g_object_get_data( (GObject *)hCtrl, "multi" ) )
   {
      GtkTextBuffer *buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (hCtrl));
      gtk_text_buffer_set_text( buffer, cTitle, -1 );
   }
   else
      gtk_entry_set_text( (GtkEntry*)hCtrl, cTitle );
   g_free( cTitle );
}

HB_FUNC( HWG_EDIT_GETTEXT )
{
   #ifdef __GTK_USE_POINTER__
   GtkWidget * hCtrl = (GtkWidget *)hb_parptr(1);
   #else
   GtkWidget * hCtrl = (GtkWidget *)hb_parnl(1);
   #endif
   char * cptr;

   if( g_object_get_data( (GObject *)hCtrl, "multi" ) )
   {
      GtkTextBuffer *buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (hCtrl));
      GtkTextIter * iterStart = NULL, * iterEnd = NULL;

      gtk_text_buffer_get_start_iter( buffer, iterStart );
      gtk_text_buffer_get_end_iter( buffer, iterEnd );
      cptr = gtk_text_buffer_get_text( buffer, iterStart, iterEnd, 1 );
   }
   else
      cptr = (char*) gtk_entry_get_text( (GtkEntry*)hCtrl );

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
#ifdef __GTK_USE_POINTER__
   gtk_editable_set_position( (GtkEditable*)hb_parptr(1), hb_parni(2) );
#else
   gtk_editable_set_position( (GtkEditable*)hb_parnl(1), hb_parni(2) );
#endif
}

HB_FUNC( HWG_EDIT_GETPOS )
{
#ifdef __GTK_USE_POINTER__
   hb_retni( gtk_editable_get_position( (GtkEditable*)hb_parptr(1) ) );
#else
   hb_retni( gtk_editable_get_position( (GtkEditable*)hb_parnl(1) ) );
#endif
}

/*
   CreateCombo( hParentWIndow, nComboID, nStyle, x, y, nWidth, nHeight )
*/
HB_FUNC( CREATECOMBO )
{
   GtkWidget * hCtrl = gtk_combo_new();
#ifdef __GTK_USE_POINTER__
   GtkFixed * box = getFixedBox( (GObject*) hb_parptr(1) );
#else
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
#endif
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );

#ifdef __GTK_USE_POINTER__
   hb_retptr( (void *) hCtrl );
#else
   hb_retnl( (LONG) hCtrl );
#endif
}

HB_FUNC( HWG_COMBOSETARRAY )
{
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   GList *glist = NULL;
   char * cItem;
   int i;

   for( i=0; (ULONG)i<pArr->item.asArray.value->ulLen; i++ )
   {
      cItem = g_locale_to_utf8( hb_itemGetCPtr( pArr->item.asArray.value->pItems + i ),-1,NULL,NULL,NULL );
      glist = g_list_append( glist, cItem );
      // g_free( cItem );
   }

#ifdef __GTK_USE_POINTER__
   gtk_combo_set_popdown_strings( GTK_COMBO( hb_parptr(1) ), glist );
#else
   gtk_combo_set_popdown_strings( GTK_COMBO( hb_parnl(1) ), glist );
#endif

}

HB_FUNC( HWG_COMBOGETEDIT )
{
#ifdef __GTK_USE_POINTER__
   hb_retptr( (void *) (GTK_COMBO( hb_parptr(1) )->entry) );
#else
   hb_retnl( (LONG) (GTK_COMBO( hb_parnl(1) )->entry) );
#endif
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

#ifdef __GTK_USE_POINTER__
   GtkFixed * box = getFixedBox( (GObject*) hb_parptr(1) );
#else
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
#endif
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(2), hb_parni(3) );
   gtk_widget_set_size_request( hCtrl,hb_parni(4),hb_parni(5) );

#ifdef __GTK_USE_POINTER__
   hb_retptr( (void *) hCtrl );
#else
   hb_retnl( (LONG) hCtrl );
#endif

}

HB_FUNC( HWG_SETUPDOWN )
{
#ifdef __GTK_USE_POINTER__
   gtk_spin_button_set_value( (GtkSpinButton*)hb_parptr(1), (gdouble)hb_parnl(2) );
#else
   gtk_spin_button_set_value( (GtkSpinButton*)hb_parnl(1), (gdouble)hb_parnl(2) );
#endif
}

HB_FUNC( HWG_GETUPDOWN )
{
#ifdef __GTK_USE_POINTER__
   hb_retnl( gtk_spin_button_get_value_as_int( (GtkSpinButton*)hb_parptr(1) ) );
#else
   hb_retnl( gtk_spin_button_get_value_as_int( (GtkSpinButton*)hb_parnl(1) ) );
#endif
}

#define WS_VSCROLL          2097152    // 0x00200000L
#define WS_HSCROLL          1048576    // 0x00100000L

HB_FUNC( CREATEBROWSE )
{
   GtkWidget *vbox, *hbox;
   GtkWidget *vscroll, *hscroll;
   GtkWidget *area;
   GtkFixed * box;
   PHB_ITEM pObject = hb_param( 1, HB_IT_OBJECT ), temp; 
   GObject * handle;
   int nLeft = hb_itemGetNI( GetObjectVar( pObject, "NLEFT" ) );
   int nTop = hb_itemGetNI( GetObjectVar( pObject, "NTOP" ) );
   int nWidth = hb_itemGetNI( GetObjectVar( pObject, "NWIDTH" ) );
   int nHeight = hb_itemGetNI( GetObjectVar( pObject, "NHEIGHT" ) );
   unsigned long int ulStyle = hb_itemGetNL( GetObjectVar( pObject, "STYLE" ) );
   
   temp = GetObjectVar( pObject, "OPARENT" );
   #ifdef __GTK_USE_POINTER__
   handle = (GObject*) hb_itemGetPtr( GetObjectVar( temp, "HANDLE" ) );
   #else
   handle = (GObject*) hb_itemGetNL( GetObjectVar( temp, "HANDLE" ) );
   #endif

   hbox = gtk_hbox_new( FALSE, 0 );
   vbox = gtk_vbox_new( FALSE, 0 );
   
   area    = gtk_drawing_area_new();

   gtk_box_pack_start( GTK_BOX( hbox ), vbox, TRUE, TRUE, 0 );
   if( ulStyle & WS_VSCROLL )
   {
      GtkObject *adjV;
      adjV = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      vscroll = gtk_vscrollbar_new( GTK_ADJUSTMENT (adjV) );
      gtk_box_pack_end( GTK_BOX( hbox ), vscroll, FALSE, FALSE, 0 );

      #ifdef __GTK_USE_POINTER__
      temp = hb_itemPutPtr( NULL, (void*)adjV );
      #else
      temp = hb_itemPutNL( NULL, (ULONG)adjV );
      #endif
      SetObjectVar( pObject, "_HSCROLLV", temp );
      hb_itemRelease( temp );

      SetWindowObject( (GtkWidget*)adjV, pObject );
      set_signal( (gpointer)adjV, "value_changed", WM_VSCROLL, 0, 0 );
   }

   gtk_box_pack_start( GTK_BOX( vbox ), area, TRUE, TRUE, 0 );
   if( ulStyle & WS_HSCROLL )
   {
      GtkObject *adjH;
      adjH = gtk_adjustment_new( 0.0, 0.0, 101.0, 1.0, 10.0, 10.0 );
      hscroll = gtk_hscrollbar_new( GTK_ADJUSTMENT (adjH) );
      gtk_box_pack_end( GTK_BOX( vbox ), hscroll, FALSE, FALSE, 0 );

      #ifdef __GTK_USE_POINTER__
      temp = hb_itemPutPtr( NULL, (void*)adjH );
      #else
      temp = hb_itemPutNL( NULL, (ULONG)adjH );
      #endif
      SetObjectVar( pObject, "_HSCROLLH", temp );
      hb_itemRelease( temp );

      SetWindowObject( (GtkWidget*)adjH, pObject );
      set_signal( (gpointer)adjH, "value_changed", WM_HSCROLL, 0, 0 );
   }

   box = getFixedBox( handle );
   if ( box )
      gtk_fixed_put( box, hbox, nLeft, nTop );
   gtk_widget_set_size_request( hbox, nWidth, nHeight );

   #ifdef __GTK_USE_POINTER__
   temp = hb_itemPutPtr( NULL, (void *)area );
   #else
   temp = hb_itemPutNL( NULL, (ULONG)area );
   #endif
   SetObjectVar( pObject, "_AREA", temp );
   hb_itemRelease( temp );

   SetWindowObject( area, pObject );
   set_event( (gpointer)area, "expose_event", WM_PAINT, 0, 0 );

   GTK_WIDGET_SET_FLAGS( area,GTK_CAN_FOCUS );
   
   gtk_widget_add_events( area, GDK_BUTTON_PRESS_MASK | 
        GDK_BUTTON_RELEASE_MASK | GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK |
	GDK_MOTION_NOTIFY );
   set_event( (gpointer)area, "button_press_event", 0, 0, 0 );
   set_event( (gpointer)area, "button_release_event", 0, 0, 0 );
   set_event( (gpointer)area, "motion_notify_event", 0, 0, 0 );
   set_event( (gpointer)area, "key_press_event", 0, 0, 0 );
   set_event( (gpointer)area, "key_release_event", 0, 0, 0 );

#ifdef __GTK_USE_POINTER__
   hb_retptr( ( void * ) hbox );
#else
   hb_retnl( (LONG) hbox );
#endif
}

HB_FUNC( HWG_GETADJVALUE )
{
#ifdef __GTK_USE_POINTER__
   GtkAdjustment *adj = (GtkAdjustment *) hb_parptr(1);
#else
   GtkAdjustment *adj = (GtkAdjustment *) hb_parnl(1);
#endif
   int iOption = (ISNIL(2))? 0 : hb_parni(2);

   if( iOption == 0 )
      hb_retnl( (LONG) adj->value );
   else if( iOption == 1 )
      hb_retnl( (LONG) adj->upper );
   else if( iOption == 2 )
      hb_retnl( (LONG) adj->step_increment );
   else if( iOption == 3 )
      hb_retnl( (LONG) adj->page_increment );
   else if( iOption == 4 )
      hb_retnl( (LONG) adj->page_size );
   else
      hb_retnl( 0 );
}

/*
 * hwg_SetAdjOptions( hAdj, value, maxpos, step, pagestep, pagesize )
 */
HB_FUNC( HWG_SETADJOPTIONS )
{
#ifdef __GTK_USE_POINTER__
   GtkAdjustment *adj = (GtkAdjustment *) hb_parptr(1);
#else
   GtkAdjustment *adj = (GtkAdjustment *) hb_parnl(1);
#endif
   gdouble value;
   int lChanged = 0;
   
   if( !ISNIL(2) && ( value = (gdouble)hb_parnl(2) ) != adj->value )
   {
      adj->value = value;
      lChanged = 1;
   }
   if( !ISNIL(3) && ( value = (gdouble)hb_parnl(3) ) != adj->upper )
   {
      adj->upper = value;
      lChanged = 1;
   }
   if( !ISNIL(4) && ( value = (gdouble)hb_parnl(4) ) != adj->step_increment )
   {
      adj->step_increment = value;
      lChanged = 1;
   }
   if( !ISNIL(5) && ( value = (gdouble)hb_parnl(5) ) != adj->page_increment )
   {
      adj->page_increment = value;
      lChanged = 1;
   }
   if( !ISNIL(6) && ( value = (gdouble)hb_parnl(6) ) != adj->page_size )
   {
      adj->page_size = value;
      lChanged = 1;
   }
   if( lChanged )
      gtk_adjustment_changed( adj );
}

HB_FUNC( CREATETABCONTROL )
{
   GtkWidget * hCtrl = gtk_notebook_new();

#ifdef __GTK_USE_POINTER__
   GtkFixed * box = getFixedBox( (GObject*) hb_parptr(1) );
#else
   GtkFixed * box = getFixedBox( (GObject*) hb_parnl(1) );
#endif
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(4), hb_parni(5) );
   gtk_widget_set_size_request( hCtrl,hb_parni(6),hb_parni(7) );

#ifdef __GTK_USE_POINTER__
   hb_retptr( (void*) hCtrl );
#else
   hb_retnl( (LONG) hCtrl );
#endif

}

HB_FUNC( ADDTAB )
{
#ifdef __GTK_USE_POINTER__
   GtkNotebook * nb = (GtkNotebook*) hb_parptr(1);
#else
   GtkNotebook * nb = (GtkNotebook*) hb_parnl(1);
#endif
   GtkWidget * box = gtk_fixed_new();
   GtkWidget * hLabel;
   char * cLabel = g_locale_to_utf8( hb_parc(2),-1,NULL,NULL,NULL );

   hLabel = gtk_label_new( cLabel );
   g_free( cLabel );

   gtk_notebook_append_page( nb, box, hLabel );

   g_object_set_data( (GObject*) nb, "fbox", (gpointer) box );

#ifdef __GTK_USE_POINTER__
   hb_retptr( (void*) nb );
#else
   hb_retnl( (LONG) nb );
#endif
}

HB_FUNC( GETCURRENTTAB )
{
#ifdef __GTK_USE_POINTER__
   hb_retni( gtk_notebook_get_current_page( (GtkNotebook*)hb_parptr(1) ) + 1 );
#else
   hb_retni( gtk_notebook_get_current_page( (GtkNotebook*)hb_parnl(1) ) + 1 );
#endif
}

HB_FUNC( HWG_CREATESEP )
{
   BOOL lVert = hb_parl(2);
   GtkWidget * hCtrl;
   GtkFixed * box;

   if( lVert )
      hCtrl = gtk_vseparator_new();
   else
      hCtrl = gtk_hseparator_new();
#ifdef __GTK_USE_POINTER__
   box = getFixedBox( (GObject*) hb_parptr(1) );
#else
   box = getFixedBox( (GObject*) hb_parnl(1) );
#endif
   if ( box )
      gtk_fixed_put( box, hCtrl, hb_parni(3), hb_parni(4) );
   gtk_widget_set_size_request( hCtrl,hb_parni(5),hb_parni(6) );

#ifdef __GTK_USE_POINTER__
   hb_retptr( (void*) hCtrl );
#else
   hb_retnl( (LONG) hCtrl );
#endif
}


HB_FUNC( ADDTOOLTIP )
{
   if( !pTooltip )
      pTooltip = gtk_tooltips_new();
#ifdef __GTK_USE_POINTER__
   gtk_tooltips_set_tip( pTooltip, (GtkWidget*)hb_parptr(2), hb_parc(3), NULL );
#else
   gtk_tooltips_set_tip( pTooltip, (GtkWidget*)hb_parnl(2), hb_parc(3), NULL );
#endif
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
   char buf[10]={0};
   sprintf( buf,"%ld",hb_parnl(1) );
   hb_retni( (gint) gtk_timeout_add( (guint32)hb_parnl(2), (GtkFunction)cb_timer, g_strdup(buf) ) );
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
#ifdef __GTK_USE_POINTER__
   hb_retptr( (void*) ( (GtkWidget*) hb_parptr(1) )->parent );
#else
   hb_retnl( (LONG) ( (GtkWidget*) hb_parnl(1) )->parent );
#endif
}

HB_FUNC( LOADCURSOR )
{
   if( ISCHAR(1) )
   {
      // hb_retnl( (LONG) LoadCursor( GetModuleHandle( NULL ), hb_parc( 1 )  ) );
   }
   else
#ifdef __GTK_USE_POINTER__
      hb_retptr( (void*) gdk_cursor_new( (GdkCursorType) hb_parptr(1) ) );
#else
      hb_retnl( (LONG) gdk_cursor_new( (GdkCursorType) hb_parnl(1) ) );
#endif
}

HB_FUNC( HWG_SETCURSOR )
{
#ifdef __GTK_USE_POINTER__
   GtkWidget * widget = (ISPOINTER(2))? (GtkWidget*) hb_parptr(2) : GetActiveWindow();
   gdk_window_set_cursor( widget->window, (GdkCursor*) hb_parptr(1) );
#else
   GtkWidget * widget = (ISNUM(2))? (GtkWidget*) hb_parnl(2) : GetActiveWindow();
   gdk_window_set_cursor( widget->window, (GdkCursor*) hb_parnl(1) );
#endif
}

HB_FUNC( HWG_MOVEWIDGET )
{
#ifdef __GTK_USE_POINTER__
   GtkWidget * widget = (GtkWidget*) hb_parptr(1);
#else
   GtkWidget * widget = (GtkWidget*) hb_parnl(1);
#endif

   if( !ISNIL(2) && !ISNIL(3) )
   {
      gtk_fixed_move( (GtkFixed*) (widget->parent), widget, (gint)hb_parni(2), (gint)hb_parni(3) );
   }
   if( !ISNIL(4) || !ISNIL(5) )
   {
      gint w, h, w1, h1;

      gtk_widget_get_size_request( widget, &w, &h );
      w1 = ( ISNIL(4) )? w : hb_parni(4);
      h1 = ( ISNIL(5) )? h : hb_parni(5);
      if( w != w1 || h != h1 )
         gtk_widget_set_size_request( widget, w1, h1 );
   }
}
