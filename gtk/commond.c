/*
 * $Id: commond.c,v 1.8 2005-10-21 08:50:15 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Common dialog functions
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
#include "hwgtk.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

void store_font( gpointer fontseldlg )
{
   char * szFontName = (char*) gtk_font_selection_dialog_get_font_name( (GtkFontSelectionDialog*)fontseldlg );
   PangoFontDescription * hFont = pango_font_description_from_string( szFontName );
   PHWGUI_FONT h = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );
#ifdef __XHARBOUR__
   HB_ITEM_NEW( aMetr);
   HB_ITEM_NEW( temp );
#else
   PHB_ITEM aMetr = hb_itemArrayNew( 9 ), temp;
#endif

   h->type = HWGUI_OBJECT_FONT;
   h->hFont = hFont;
#ifdef __XHARBOUR__
{
   hb_arrayNew( &aMetr, 9 );
#ifdef __GTK_USE_POINTER__   
   hb_arraySetForward( &aMetr, 1, hb_itemPutPtr( &temp, ( void *) h ) );
#else
   hb_arraySetForward( &aMetr, 1, hb_itemPutNL( &temp, (LONG)h ) );
#endif
   hb_arraySetForward( &aMetr, 2, hb_itemPutC( &temp, (char*) pango_font_description_get_family( hFont ) ) );

   hb_arraySetForward( &aMetr, 3, hb_itemPutNL( &temp, 0 ) );
   
   hb_arraySetForward( &aMetr, 4, hb_itemPutNL( &temp, (LONG) pango_font_description_get_size( hFont ) ) );

   hb_arraySetForward( &aMetr, 5, hb_itemPutNL( &temp, (LONG) pango_font_description_get_weight( hFont ) ));

   hb_arraySetForward( &aMetr, 6, hb_itemPutNI( &temp, 0 ) );
   
   hb_arraySetForward( &aMetr, 7, hb_itemPutNI( &temp, (LONG) pango_font_description_get_style( hFont ) ) );
   
   hb_arraySetForward( &aMetr, 8, hb_itemPutNI( &temp, 0 ) );
   
   hb_arraySetForward( &aMetr, 9,hb_itemPutNI( &temp, 0 ) );

   hb_itemClear( &temp );
   hb_itemForwardValue( &(HB_VM_STACK).Return, &aMetr );
}
#else
{
#ifdef __GTK_USE_POINTER__
   temp = hb_itemPutPtr( NULL, (void*) h );
#else
   temp = hb_itemPutNL( NULL, (LONG) h );
#endif
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutC( NULL, (char*) pango_font_description_get_family( hFont ) );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, 0 );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, (LONG) pango_font_description_get_size( hFont ) );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, (LONG) pango_font_description_get_weight( hFont ) );
   hb_itemArrayPut( aMetr, 5, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, 0 );
   hb_itemArrayPut( aMetr, 6, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, (LONG) pango_font_description_get_style( hFont ) );
   hb_itemArrayPut( aMetr, 7, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, 0 );
   hb_itemArrayPut( aMetr, 8, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, 0 );
   hb_itemArrayPut( aMetr, 9, temp );
   hb_itemRelease( temp );

   hb_itemReturn( aMetr );
   hb_itemRelease( aMetr );
}
#endif   
   gtk_widget_destroy( (GtkWidget*) fontseldlg );
}

HB_FUNC( SELECTFONT )
{
   GtkWidget *fontseldlg;
   GtkFontSelection *fontsel;
   char *cTitle = ( hb_pcount()>2 && ISCHAR(3) )? hb_parc(3):"Select Font";

   fontseldlg = gtk_font_selection_dialog_new( cTitle );
   fontsel = GTK_FONT_SELECTION( GTK_FONT_SELECTION_DIALOG (fontseldlg)->fontsel );

   if( hb_pcount() > 0 && !ISNIL(1) )
   {
   }
   
   g_signal_connect( G_OBJECT (fontseldlg), "destroy",
                      G_CALLBACK (gtk_main_quit), NULL);

   g_signal_connect_swapped( GTK_OBJECT (GTK_FONT_SELECTION_DIALOG (fontseldlg)->ok_button),
                     "clicked",
                     G_CALLBACK (store_font),
                     (gpointer) fontseldlg );
   
   g_signal_connect_swapped( GTK_OBJECT (GTK_FONT_SELECTION_DIALOG (fontseldlg)->cancel_button),
                             "clicked",
                             G_CALLBACK (gtk_widget_destroy),
                             (gpointer) fontseldlg );
                             
   gtk_widget_show( fontseldlg );
   gtk_main();   

}

void store_filename( gpointer file_selector )
{
   hb_retc( (char*) gtk_file_selection_get_filename( GTK_FILE_SELECTION( file_selector ) ) );
   gtk_widget_destroy( (GtkWidget*) file_selector );
}

void cancel_filedlg( gpointer file_selector )
{
   hb_ret();
   gtk_widget_destroy( (GtkWidget*) file_selector );
}

HB_FUNC( SELECTFILE )
{
   GtkWidget * file_selector;
   char * cMask = ( hb_pcount()>1 && ISCHAR(2) )? hb_parc(2):NULL;
   char *cTitle = ( hb_pcount()>3 && ISCHAR(4) )? hb_parc(4):"Select a file";
   
   file_selector = gtk_file_selection_new( cTitle );
   
   g_signal_connect (G_OBJECT (file_selector), "destroy",
                      G_CALLBACK (gtk_main_quit), NULL);

   g_signal_connect_swapped( GTK_OBJECT (GTK_FILE_SELECTION (file_selector)->ok_button),
                     "clicked",
                     G_CALLBACK (store_filename),
                     (gpointer) file_selector);
   
   g_signal_connect_swapped( GTK_OBJECT (GTK_FILE_SELECTION (file_selector)->cancel_button),
                             "clicked",
                             G_CALLBACK (cancel_filedlg),
                             (gpointer) file_selector); 
                             
   if( cMask )
      gtk_file_selection_complete( (GtkFileSelection*)file_selector, cMask );
   
   gtk_widget_show( file_selector );
   gtk_main();
}

void store_color( gpointer colorseldlg )
{
   GtkColorSelection *colorsel;
   GdkColor color;
   // char ss[30];   

   colorsel = GTK_COLOR_SELECTION( GTK_COLOR_SELECTION_DIALOG (colorseldlg)->colorsel );
   gtk_color_selection_get_current_color (colorsel, &color);
   // sprintf( ss,"%ld %ld %ld %ld \n\r",color.pixel,color.red,color.green,color.blue );
   // g_print(ss);
   
   hb_retnl( color.blue + color.green * 256 + color.red * 65536 );
   gtk_widget_destroy( (GtkWidget*) colorseldlg );
}

HB_FUNC( HWG_CHOOSECOLOR )
{
   GtkWidget *colorseldlg;
   GtkColorSelection *colorsel;
   char *cTitle = ( hb_pcount()>2 && ISCHAR(3) )? hb_parc(3):"Select color";
   
   colorseldlg = gtk_color_selection_dialog_new( cTitle );
   colorsel = GTK_COLOR_SELECTION( GTK_COLOR_SELECTION_DIALOG (colorseldlg)->colorsel );

   if( hb_pcount() > 0 && !ISNIL(1) )
   {
      char ss[30]={0};
      GdkColor color;
      color.pixel = 0;
      color.blue =  ( hb_parnl(1) % 256 ) * 256;
      color.green = ( hb_parnl(1) % 65536 );
      color.red =   ( hb_parnl(1) % 16777216 ) / 256;
      sprintf( ss,"%ld %d %d %d \n\r",hb_parnl(1),color.red,color.green,color.blue );
      g_print(ss);
      gtk_color_selection_set_previous_color( colorsel, &color );
      gtk_color_selection_set_current_color( colorsel, &color );
   }
   gtk_color_selection_set_has_palette (colorsel, TRUE);
   
   g_signal_connect( G_OBJECT (colorseldlg), "destroy",
                      G_CALLBACK (gtk_main_quit), NULL);

   g_signal_connect_swapped( GTK_OBJECT (GTK_COLOR_SELECTION_DIALOG (colorseldlg)->ok_button),
                     "clicked",
                     G_CALLBACK (store_color),
                     (gpointer) colorseldlg );
   
   g_signal_connect_swapped( GTK_OBJECT (GTK_COLOR_SELECTION_DIALOG (colorseldlg)->cancel_button),
                             "clicked",
                             G_CALLBACK (gtk_widget_destroy),
                             (gpointer) colorseldlg );
                             
   gtk_widget_show( colorseldlg );
   gtk_main();  
   
}
