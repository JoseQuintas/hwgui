/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Common dialog functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "guilib.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "item.api"
#include "gtk/gtk.h"
#include "hwgtk.h"
#ifdef __XHARBOUR__
#include "hbfast.h"
#endif

extern GtkWidget * GetActiveWindow( void );
extern void hwg_parse_color( HB_ULONG ncolor, GdkColor * pColor );

void store_font( gpointer fontseldlg )
{
   char * szFontName = (char*) gtk_font_selection_dialog_get_font_name( (GtkFontSelectionDialog*)fontseldlg );
   PangoFontDescription * hFont = pango_font_description_from_string( szFontName );
   PHWGUI_FONT h = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );
   PHB_ITEM aMetr = hb_itemArrayNew( 9 );
   PHB_ITEM temp;

   h->type = HWGUI_OBJECT_FONT;
   h->hFont = hFont;

   temp = HB_PUTHANDLE( NULL, h );
   hb_itemArrayPut( aMetr, 1, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutC( NULL, (char*) pango_font_description_get_family( hFont ) );
   hb_itemArrayPut( aMetr, 2, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, 0 );
   hb_itemArrayPut( aMetr, 3, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, (HB_LONG) pango_font_description_get_size( hFont ) );
   hb_itemArrayPut( aMetr, 4, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNL( NULL, (HB_LONG) pango_font_description_get_weight( hFont ) );
   hb_itemArrayPut( aMetr, 5, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, 0 );
   hb_itemArrayPut( aMetr, 6, temp );
   hb_itemRelease( temp );

   temp = hb_itemPutNI( NULL, (HB_LONG) pango_font_description_get_style( hFont ) );
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

   gtk_widget_destroy( (GtkWidget*) fontseldlg );
}

void cancel_font( gpointer fontseldlg )
{
   gtk_widget_destroy( (GtkWidget *) fontseldlg );
   hb_ret();
}

HB_FUNC( HWG_SELECTFONT )
{
   GtkWidget *fontseldlg;
   GtkFontSelection *fontsel;
   const char *cTitle = ( hb_pcount()>2 && HB_ISCHAR(3) )? hb_parc(3):"Select Font";

   fontseldlg = gtk_font_selection_dialog_new( cTitle );
   fontsel = GTK_FONT_SELECTION( GTK_FONT_SELECTION_DIALOG (fontseldlg)->fontsel );

   if( hb_pcount() > 0 && !HB_ISNIL(1) )
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
                             G_CALLBACK (cancel_font),
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

HB_FUNC( HWG_SELECTFILE )
{
   GtkWidget * file_selector;
   const char * cMask = ( hb_pcount()>1 && HB_ISCHAR(2) )? hb_parc(2):NULL;
   const char *cTitle = ( hb_pcount()>3 && HB_ISCHAR(4) )? hb_parc(4):"Select a file";

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
   // char ss[50];   

   colorsel = GTK_COLOR_SELECTION( GTK_COLOR_SELECTION_DIALOG (colorseldlg)->colorsel );
   gtk_color_selection_get_current_color (colorsel, &color);
   // sprintf( ss,"%ld %ld %ld %ld \n\r",color.pixel,color.red,color.green,color.blue );
   // g_print(ss);

   hb_retnl( (HB_ULONG) ( (color.red>>8) + (color.green&0xff00) + ((color.blue&0xff00)<<8) ) );
   gtk_widget_destroy( (GtkWidget*) colorseldlg );
}

HB_FUNC( HWG_CHOOSECOLOR )
{
   GtkWidget *colorseldlg;
   GtkColorSelection *colorsel;
   GtkWidget * hParent = GetActiveWindow();
   const char *cTitle = ( hb_pcount()>2 && HB_ISCHAR(3) )? hb_parc(3):"Select color";

   colorseldlg = gtk_color_selection_dialog_new( cTitle );
   colorsel = GTK_COLOR_SELECTION( GTK_COLOR_SELECTION_DIALOG (colorseldlg)->colorsel );

   if( hb_pcount() > 0 && !HB_ISNIL(1) )
   {
      // char ss[30]={0};
      HB_ULONG ulColor = (HB_ULONG) hb_parnl(1);
      GdkColor color;
      hwg_parse_color( ulColor, &color );
      /*
      color.pixel = 0;
      color.blue =  ( ulColor % 256 ) * 256;
      color.green = ( ulColor % 65536 );
      color.red =   ( ulColor % 16777216 ) / 256;
      */
      /*
      color.red = ulColor % 256;
      color.green = ( ( ulColor-color.red ) % 65536 ) / 256;
      color.blue = ( ulColor-color.green*256-color.red ) / 65536;
      */
      // sprintf( ss,"%ld %d %d %d \n\r",hb_parnl(1),color.red,color.green,color.blue );
      // g_print(ss);
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

   gtk_window_set_modal( (GtkWindow *) colorseldlg, 1 );
   gtk_window_set_transient_for( (GtkWindow *) colorseldlg, (GtkWindow *) hParent );

   gtk_widget_show( colorseldlg );
   gtk_main();
}

