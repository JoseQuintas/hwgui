/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Common dialog functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
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
extern void hwg_set_modal( GtkWindow * hDlg, GtkWindow * hParent );
extern void hwg_parse_color( HB_ULONG ncolor, GdkColor * pColor );

extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, const char *varname );

void store_font( gpointer fontseldlg )
{
   char * szFontName = (char*) gtk_font_selection_dialog_get_font_name( (GtkFontSelectionDialog*)fontseldlg );
   PangoFontDescription * hFont = pango_font_description_from_string( szFontName );
   PHWGUI_FONT h = (PHWGUI_FONT) hb_xgrab( sizeof(HWGUI_FONT) );
   PHB_ITEM aMetr = hb_itemArrayNew( 9 );
   PHB_ITEM temp;

   h->type = HWGUI_OBJECT_FONT;
   h->hFont = hFont;
   h->attrs = NULL;

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
   const char *cTitle = ( hb_pcount()>1 && HB_ISCHAR(2) )? hb_parc(2):"Select Font";

   fontseldlg = gtk_font_selection_dialog_new( cTitle );
   //GTK_FONT_SELECTION( GTK_FONT_SELECTION_DIALOG (fontseldlg)->fontsel );

   if( hb_pcount() > 0 && !HB_ISNIL(1) )
   {
      PHB_ITEM pObj = hb_param( 1, HB_IT_OBJECT );
      const char * ptr = hb_itemGetCPtr( GetObjectVar( pObj, "NAME" ) );
      int height = hb_itemGetNI( GetObjectVar( pObj, "HEIGHT" ) );
      int weight = hb_itemGetNI( GetObjectVar( pObj, "WEIGHT" ) );
      int italic = hb_itemGetNI( GetObjectVar( pObj, "ITALIC" ) );
      char szFont[256];

      sprintf( szFont, "%s %s %s %d", ptr, ( (weight<700)? "" : "BOLD" ), ( (italic==0)? "" : "ITALIC" ), height );

      gtk_font_selection_dialog_set_font_name( GTK_FONT_SELECTION_DIALOG(fontseldlg),
           szFont );
   }

   g_signal_connect( G_OBJECT (fontseldlg), "destroy",
                      G_CALLBACK (gtk_main_quit), NULL);

   //g_signal_connect_swapped( GTK_OBJECT (GTK_FONT_SELECTION_DIALOG (fontseldlg)->ok_button),
   g_signal_connect_swapped( G_OBJECT (gtk_font_selection_dialog_get_ok_button((GtkFontSelectionDialog *)fontseldlg)),
                     "clicked",
                     G_CALLBACK (store_font),
                     (gpointer) fontseldlg );

   //g_signal_connect_swapped( GTK_OBJECT (GTK_FONT_SELECTION_DIALOG (fontseldlg)->cancel_button),
      g_signal_connect_swapped( G_OBJECT (gtk_font_selection_dialog_get_cancel_button((GtkFontSelectionDialog *)fontseldlg)),
                             "clicked",
                             G_CALLBACK (cancel_font),
                             (gpointer) fontseldlg );

   gtk_widget_show( fontseldlg );

   hwg_set_modal( (GtkWindow *) fontseldlg, (GtkWindow *) GetActiveWindow() );

   gtk_main();

}

#if GTK_MAJOR_VERSION -0 < 3
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
   const char * cMask = ( hb_pcount()>1 && HB_ISCHAR(2) )? hb_parc(2) : NULL;
   const char *cTitle = ( hb_pcount()>3 && HB_ISCHAR(4) )? hb_parc(4) : "Select a file";
   char * cDir = ( hb_pcount()>2 && HB_ISCHAR(3) )? (char*)hb_parc(3) : NULL;

   if( cDir )
      hb_fsChDir( cDir );
   file_selector = gtk_file_selection_new( cTitle );

   g_signal_connect (G_OBJECT (file_selector), "destroy",
                      G_CALLBACK (gtk_main_quit), NULL);

   g_signal_connect_swapped( G_OBJECT (GTK_FILE_SELECTION (file_selector)->ok_button),
                     "clicked",
                     G_CALLBACK (store_filename),
                     (gpointer) file_selector);

   g_signal_connect_swapped( G_OBJECT (GTK_FILE_SELECTION (file_selector)->cancel_button),
                             "clicked",
                             G_CALLBACK (cancel_filedlg),
                             (gpointer) file_selector); 

   if( cMask )
      gtk_file_selection_complete( (GtkFileSelection*)file_selector, cMask );

   gtk_widget_show( file_selector );

   hwg_set_modal( (GtkWindow *) file_selector, (GtkWindow *) GetActiveWindow() );

   gtk_main();
}
#else
static void selefile_preview( GtkFileChooser *file_chooser, gpointer data )
{
  GtkWidget *preview;
  char *filename;
  GdkPixbuf *pixbuf;
  gboolean have_preview;

  preview = GTK_WIDGET (data);
  filename = gtk_file_chooser_get_preview_filename (file_chooser);

  pixbuf = gdk_pixbuf_new_from_file_at_size (filename, 128, 128, NULL);
  have_preview = (pixbuf != NULL);
  g_free (filename);

  gtk_image_set_from_pixbuf (GTK_IMAGE (preview), pixbuf);
  if (pixbuf)
    g_object_unref (pixbuf);

  gtk_file_chooser_set_preview_widget_active (file_chooser, have_preview);
}

HB_FUNC( HWG_SELECTFILE )
{
   GtkWidget * selector_archivo;
   gint resultado;
   GtkImage *preview;
   PHB_ITEM pArrTip = ( ( HB_ISARRAY(1) )? hb_param( 1,HB_IT_ARRAY ) : NULL );
   PHB_ITEM pArrMsk = ( ( hb_pcount()>1 && HB_ISARRAY(2) )? hb_param( 2,HB_IT_ARRAY ) : NULL );
   const char * cTip = ( HB_ISCHAR(1) )? hb_parc(1) : NULL;
   const char * cMsk = ( hb_pcount()>1 && HB_ISCHAR(2) )? hb_parc(2) : NULL;
   const char * cDir = ( hb_pcount()>2 && HB_ISCHAR(3) )? hb_parc(3) : "";
   const char *cTitle = ( hb_pcount()>3 && HB_ISCHAR(4) )? hb_parc(4):"Select a file";
   char *filename;
   int i, iLen, iLenTip;

   selector_archivo = gtk_file_chooser_dialog_new ( cTitle,
             (GtkWindow *) GetActiveWindow(),
             GTK_FILE_CHOOSER_ACTION_OPEN,
             "gtk-cancel", GTK_RESPONSE_CANCEL,
             "gtk-open", GTK_RESPONSE_ACCEPT, NULL );

   if( pArrMsk )
   {
      iLen = hb_arrayLen( pArrMsk );
      iLenTip = (pArrTip)? hb_arrayLen(pArrTip) : 0;
      for( i=1; i<=iLen; i++ )
      {
          GtkFileFilter *filtro = gtk_file_filter_new();
          gtk_file_filter_add_pattern (filtro, hb_arrayGetC( pArrMsk,i ));
          if( iLenTip >= i )
             gtk_file_filter_set_name( filtro, hb_arrayGetC( pArrTip,i ) );
          gtk_file_chooser_add_filter( (GtkFileChooser*)selector_archivo, filtro);
      }
   }
   else if( cMsk )
   {
      GtkFileFilter *filtro = gtk_file_filter_new();
      gtk_file_filter_add_pattern( filtro, cMsk );
      if( cTip )
         gtk_file_filter_set_name( filtro, cTip );
      gtk_file_chooser_add_filter( (GtkFileChooser*)selector_archivo, filtro);
   }

   gtk_file_chooser_set_current_folder ( (GtkFileChooser*)selector_archivo, cDir );

   preview = (GtkImage *)gtk_image_new();
   gtk_file_chooser_set_preview_widget( (GtkFileChooser*)selector_archivo, (GtkWidget*)preview );
   g_signal_connect(selector_archivo, "update-preview",
               G_CALLBACK(selefile_preview), preview);

   resultado = gtk_dialog_run (GTK_DIALOG (selector_archivo));
   switch (resultado)
   {
       case GTK_RESPONSE_ACCEPT:
          filename = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (selector_archivo));
          hb_retc( filename );
          g_free( filename );
          break;
       default:
          // do_nothing_since_dialog_was_cancelled ();
       break;
   }
   gtk_widget_destroy (selector_archivo);
}
#endif

void store_color( gpointer colorseldlg )
{
   GtkColorSelection *colorsel;
   GdkColor color;

   //colorsel = GTK_COLOR_SELECTION( GTK_COLOR_SELECTION_DIALOG (colorseldlg)->colorsel );
   colorsel = GTK_COLOR_SELECTION( gtk_color_selection_dialog_get_color_selection((GtkColorSelectionDialog *)colorseldlg) );
   gtk_color_selection_get_current_color (colorsel, &color);

   hb_retnl( (HB_ULONG) ( (color.red>>8) + (color.green&0xff00) + ((color.blue&0xff00)<<8) ) );
   gtk_widget_destroy( (GtkWidget*) colorseldlg );
}

HB_FUNC( HWG_CHOOSECOLOR )
{
   GtkWidget *colorseldlg;
   GtkColorSelection *colorsel;
   //GtkWidget * hParent = GetActiveWindow();
   const char *cTitle = ( hb_pcount()>2 && HB_ISCHAR(3) )? hb_parc(3):"Select color";
   GdkColor color;
   gint response;

   colorseldlg = gtk_color_selection_dialog_new( cTitle );
   colorsel = GTK_COLOR_SELECTION( gtk_color_selection_dialog_get_color_selection((GtkColorSelectionDialog *)colorseldlg) );

   if( hb_pcount() > 0 && !HB_ISNIL(1) )
   {
      HB_ULONG ulColor = (HB_ULONG) hb_parnl(1);
      GdkColor color;
      hwg_parse_color( ulColor, &color );
      gtk_color_selection_set_previous_color( colorsel, &color );
      gtk_color_selection_set_current_color( colorsel, &color );
   }
   gtk_color_selection_set_has_palette (colorsel, TRUE);
/*
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
*/
  response = gtk_dialog_run (GTK_DIALOG (colorseldlg));

  if (response == GTK_RESPONSE_OK)
    {
      gtk_color_selection_get_current_color (colorsel,
					     &color);
      hb_retnl( (HB_ULONG) ( (color.red>>8) + (color.green&0xff00) + ((color.blue&0xff00)<<8) ) );
    }
  
  gtk_widget_destroy (colorseldlg);

}

static void actualiza_preview( GtkFileChooser *file_chooser, gpointer data )
{
  GtkWidget *preview;
  char *filename;
  GdkPixbuf *pixbuf;
  gboolean have_preview;

  preview = GTK_WIDGET (data);
  filename = gtk_file_chooser_get_preview_filename (file_chooser);

  pixbuf = gdk_pixbuf_new_from_file_at_size (filename, 128, 128, NULL);
  have_preview = (pixbuf != NULL);
  g_free (filename);

  gtk_image_set_from_pixbuf (GTK_IMAGE (preview), pixbuf);
  if (pixbuf)
    g_object_unref (pixbuf);

  gtk_file_chooser_set_preview_widget_active (file_chooser, have_preview);
}

HB_FUNC( HWG_SELECTFILEEX )
{
   GtkWidget * selector_archivo;
   gint resultado;
   const char *cTitle = ( HB_ISCHAR(1) )? hb_parc(1):"Select a file";
   const char * cDir = ( hb_pcount()>1 && HB_ISCHAR(2) )? hb_parc(2) : "";
   GtkImage *preview;
   PHB_ITEM pArray = ( ( hb_pcount()>2 && HB_ISARRAY(3) )? hb_param( 3,HB_IT_ARRAY ) : NULL ), pArr1;
   int bMulti = (HB_ISLOG(4))? hb_parl(4) : 0;
   char *filename;
   int i, j, iLen, iLen1;
   //
   // ----------------------------------
   // Creacion del selector de archivos.
   // ----------------------------------
   //
   selector_archivo = gtk_file_chooser_dialog_new ( cTitle,
             (GtkWindow *) GetActiveWindow(),
             GTK_FILE_CHOOSER_ACTION_OPEN,
             "gtk-cancel", GTK_RESPONSE_CANCEL,
             "gtk-open", GTK_RESPONSE_ACCEPT, NULL );
   //
   // -----------------------
   // Opciones de los filtros
   // -----------------------
   //
   if( pArray )
   {
      iLen = hb_arrayLen( pArray );
      for( i=1; i<=iLen; i++ )
      {
          GtkFileFilter *filtro = gtk_file_filter_new();
          pArr1 = hb_arrayGetItemPtr( pArray, i );
          iLen1 = hb_arrayLen( pArr1 );
          for( j=1; j<=iLen1; j++ )
          {
             if( j == 1 )
                gtk_file_filter_set_name( filtro, hb_arrayGetC( pArr1,j ) );
             else
                gtk_file_filter_add_pattern (filtro, hb_arrayGetC( pArr1,j ));
          }
          gtk_file_chooser_add_filter( (GtkFileChooser*)selector_archivo, filtro);
      }
   }
   //
   // ---------------------
   // Opciones del selector
   // ---------------------
   //
   gtk_file_chooser_set_current_folder ( (GtkFileChooser*)selector_archivo, cDir );
   if( bMulti )
      gtk_file_chooser_set_select_multiple( (GtkFileChooser*)selector_archivo, 1);
   // ------------------------------
   // Definicion del previsualizador
   // ------------------------------
   //
   preview = (GtkImage *)gtk_image_new();
   gtk_file_chooser_set_preview_widget( (GtkFileChooser*)selector_archivo, (GtkWidget*)preview );
   g_signal_connect(selector_archivo, "update-preview",
               G_CALLBACK(actualiza_preview), preview);
   //
   // ----------------------
   // Ejecucion del selector
   // ----------------------
   //
   resultado = gtk_dialog_run (GTK_DIALOG (selector_archivo));
   switch (resultado)
     {
       case GTK_RESPONSE_ACCEPT:
         if( bMulti )
         {
            GSList * gsli = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER (selector_archivo));
            if( gsli && gsli->data )
            {
               PHB_ITEM aFiles;
               GSList * pgs = gsli;
               guint uiLen = g_slist_length(gsli);
               int i1 = 0;
               aFiles = hb_itemArrayNew( uiLen );
               while( pgs )
               {
                  hb_arraySetC( aFiles, ++i1, (char*)pgs->data );
                  pgs = pgs->next;
               }
               hb_itemReturnRelease( aFiles );
               g_slist_free( gsli );
            }
         } else
         {
            filename = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (selector_archivo));
            hb_retc( filename );
            g_free( filename );
         }
         break;
       default:
         // do_nothing_since_dialog_was_cancelled ();
       break;
     }
    gtk_widget_destroy (selector_archivo);
}

HB_FUNC( HWG_SELECTFOLDER )
{
   GtkWidget * selector_archivo;
   gint resultado;
   const char *cTitle = ( HB_ISCHAR(1) )? hb_parc(1):"Select a folder";
   char *filename;
   //
   // ----------------------------------
   // Creacion del selector de archivos.
   // ----------------------------------
   //
   selector_archivo = gtk_file_chooser_dialog_new ( cTitle,
                      (GtkWindow *) GetActiveWindow(),
                         GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
                         "gtk-cancel", GTK_RESPONSE_CANCEL,
                         "gtk-open", GTK_RESPONSE_ACCEPT,
                         NULL);
   //
   // ----------------------
   // Ejecucion del selector
   // ----------------------
   //
   resultado = gtk_dialog_run (GTK_DIALOG (selector_archivo));
   switch (resultado)
     {
       case GTK_RESPONSE_ACCEPT:
         filename = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (selector_archivo));
         hb_retc( filename );
         g_free( filename );
         break;
       default:
         // do_nothing_since_dialog_was_cancelled ();
         break;
     }
    gtk_widget_destroy (selector_archivo);
}
