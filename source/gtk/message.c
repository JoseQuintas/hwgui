/*
 * $Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Message box functions
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

extern GtkWidget * GetActiveWindow( void );

static int MessageBox( const char * cMsg, const char * cTitle, int message_type, int button_type )
{
   GtkWidget * dialog;
   int result;
   gchar * gcptr;

   gcptr = hwg_convert_to_utf8( cMsg );
   dialog = gtk_message_dialog_new( GTK_WINDOW( GetActiveWindow() ),
                                     GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                     message_type,
                                     button_type, "%s" ,
                                     gcptr );
   g_free( gcptr );
   if( *cTitle )
   {
      gcptr = hwg_convert_to_utf8( cTitle );
      gtk_window_set_title( GTK_WINDOW(dialog), gcptr );
      g_free( gcptr );
   }
   gtk_window_set_position( GTK_WINDOW(dialog), GTK_WIN_POS_CENTER );
   //gtk_window_set_policy( GTK_WINDOW(dialog), TRUE, TRUE, TRUE );
   gtk_window_set_resizable( GTK_WINDOW(dialog), TRUE);

   result = gtk_dialog_run( GTK_DIALOG(dialog) );
   gtk_widget_destroy( dialog );
   return result;
}

HB_FUNC( HWG_MSGINFO )
{
   const char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_INFO, GTK_BUTTONS_OK );
}

HB_FUNC( HWG_MSGSTOP )
{
   const char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_ERROR, GTK_BUTTONS_CLOSE );
}

HB_FUNC( HWG_MSGOKCANCEL )
{
   const char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   hb_retl( MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_QUESTION, GTK_BUTTONS_OK_CANCEL ) == GTK_RESPONSE_OK );
}

HB_FUNC( HWG_MSGYESNO )
{
   const char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   hb_retl( MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_QUESTION, GTK_BUTTONS_YES_NO ) == GTK_RESPONSE_YES );
}

HB_FUNC( HWG_MSGEXCLAMATION )
{
   const char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_WARNING, GTK_BUTTONS_CLOSE );
}

#define IDCANCEL            2
#define IDYES               6
#define IDNO                7

HB_FUNC( HWG_MSGYESNOCANCEL )
{
   const char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   GtkWidget * dialog;
   int result;
   gchar * gcptr;

   gcptr = hwg_convert_to_utf8( hb_parc(1) );
   dialog = gtk_message_dialog_new( GTK_WINDOW( GetActiveWindow() ),
                                     GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                     GTK_MESSAGE_QUESTION,
                                     GTK_BUTTONS_NONE, "%s" ,
                                     gcptr );
   g_free( gcptr );
   if( *cTitle )
   {
      gcptr = hwg_convert_to_utf8( cTitle );
      gtk_window_set_title( GTK_WINDOW(dialog), gcptr );
      g_free( gcptr );
   }
   gtk_dialog_add_button( GTK_DIALOG(dialog), "Yes", GTK_RESPONSE_YES );
   gtk_dialog_add_button( GTK_DIALOG(dialog), "No", GTK_RESPONSE_NO );
   gtk_dialog_add_button( GTK_DIALOG(dialog), "Cancel", GTK_RESPONSE_CANCEL );

   gtk_window_set_position( GTK_WINDOW(dialog), GTK_WIN_POS_CENTER );
   //gtk_window_set_policy( GTK_WINDOW(dialog), TRUE, TRUE, TRUE );
   gtk_window_set_resizable( GTK_WINDOW(dialog), TRUE);

   result = gtk_dialog_run( GTK_DIALOG(dialog) );
   gtk_widget_destroy( dialog );
   hb_retni( (result==GTK_RESPONSE_YES)? IDYES : ( (result==GTK_RESPONSE_NO)? IDNO : IDCANCEL ) );
}

/* ================= EOF of message.c ======================== */

