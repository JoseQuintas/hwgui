/*
 * $Id: commond.c,v 1.1 2005-01-12 11:56:33 alkresin Exp $
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

void store_font( gpointer fontseldlg )
{
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
                             G_CALLBACK (gtk_widget_destroy),
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
   char ss[30];   

   colorsel = GTK_COLOR_SELECTION( GTK_COLOR_SELECTION_DIALOG (colorseldlg)->colorsel );
   gtk_color_selection_get_current_color (colorsel, &color);
   sprintf( ss,"%ld %ld %ld %ld \n\r",color.pixel,color.red,color.green,color.blue );
   g_print(ss);
   
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
      char ss[30];
      GdkColor color;
      color.pixel = 0;
      color.blue = hb_parnl(1) % 256;
      color.green = ( hb_parnl(1) % 65536 ) / 256;
      color.red = ( hb_parnl(1) % 16777216 ) / 65536;
      sprintf( ss,"%ld %ld %ld %ld \n\r",hb_parnl(1),color.red,color.green,color.blue );
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
