/*
 * $Id: message.c,v 1.1 2005-01-12 11:56:34 alkresin Exp $
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code:
 * Message box functions
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 */

#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include "item.api"
#include "gtk/gtk.h"

extern GtkWidget * GetActiveWindow( void );

static int MessageBox( char * cMsg, char * cTitle, int message_type, int button_type )
{
   GtkWidget * dialog;
   int result;
   char * cptr;
    
   cptr = g_locale_to_utf8( cMsg, -1, NULL, NULL, NULL);
   dialog = gtk_message_dialog_new( GTK_WINDOW( GetActiveWindow() ),
                                     GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                     message_type,
                                     button_type,
                                     cptr );
   g_free( cptr );
   if( *cTitle )
   {
      cptr = g_locale_to_utf8( cTitle, -1, NULL, NULL, NULL);
      gtk_window_set_title( GTK_WINDOW(dialog), cptr );
      g_free( cptr );
   }
   gtk_window_set_position( GTK_WINDOW(dialog), GTK_WIN_POS_CENTER );
   gtk_window_set_policy( GTK_WINDOW(dialog), TRUE, TRUE, TRUE );
    
   result = gtk_dialog_run( GTK_DIALOG(dialog) );
   gtk_widget_destroy( dialog );
   return result;
}

HB_FUNC( MSGINFO )
{
   char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_INFO, GTK_BUTTONS_OK );
}    

HB_FUNC( MSGSTOP )
{
   char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_ERROR, GTK_BUTTONS_CLOSE );        
}    

HB_FUNC( MSGOKCANCEL )
{
   char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   hb_retl( MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_QUESTION, GTK_BUTTONS_OK_CANCEL ) == GTK_RESPONSE_OK );
}    

HB_FUNC( MSGYESNO )
{
   char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   hb_retl( MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_QUESTION, GTK_BUTTONS_YES_NO ) == GTK_RESPONSE_YES );
}    

HB_FUNC( MSGEXCLAMATION )
{
   char* cTitle = ( hb_pcount() == 1 )? "":hb_parc( 2 );
   MessageBox( hb_parc(1), cTitle, GTK_MESSAGE_WARNING, GTK_BUTTONS_CLOSE );
}    

