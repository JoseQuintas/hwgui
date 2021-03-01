/*
 * $Id$
 *
 * HWGUI - Harbour GTK GUI library source code:
 * HList class
 *
 * Copyright 2002 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 * Listbox class and accompanying code added Feb 22nd, 2004 by
 * Vic McClung
 * Port trial to GTK by DF7BE . 
*/

/*
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 This is only a trial Version.
 The files hlistbox.prg and listbox.c are "sleeping" at the moment.
 Because of a bug in GTK, it is not possible,
 to create a port of the LISTBOX feature to GTK.
 The sample "demohlist.prg" could be compiled with
 activted files hlistbox.prg and listbox.c in the makefile, but
 the listbox is not visible.
 These files are only commited as preparation for
 the port to GTK, in the hope, that the bug is fixed
 in future GTK versions.
 
 The coding follows the sample "listbox_sample.c"
 from Eric Harlow. Some lines are commented out,
 activate them during development in the future.
 
 To actiave the port, add these two lines into the
 makefiles for GTK:
 $(LIB_DIR)/libhwgui.a : \
   $(OBJ_DIR)/commond.o \
   $(OBJ_DIR)/control.o \
...
  $(OBJ_DIR)/listbox.o \
  $(OBJ_DIR)/hlistbox.o
...  
 
*/

/* Hint for port to GTK3:
   function prefix gtk_list_*   ==> gtk_list_box_*
   
   Conditional compiling:
   #if GTK_MAJOR_VERSION -0 < 3
    ... GTK2
   #else
    ... GTK3
   #ENDIF
*/

#include <gtk/gtk.h>
#include "hwingui.h"
/*
#if defined(__MINGW32__) || defined(__MINGW64__) || defined(__WATCOMC__)
#include <prsht.h>
#endif
*/
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"


/*
 hwg_Listboxaddstring( handle, cItem)
*/ 
HB_FUNC( HWG_LISTBOXADDSTRING )
{
    void          * hString;
    GtkWidget     * item;

    HB_PARSTR( 2, &hString, NULL ) ;

    /*  Create a list item  */
    item = gtk_list_item_new_with_label (hString);

    /*  Configure the "select" event  */
/*
    gtk_signal_connect (GTK_OBJECT (item), "select",
            GTK_SIGNAL_FUNC (listitem_selected), sText);
*/

 
    /* Add item */
    gtk_container_add (GTK_CONTAINER ( HB_PARHANDLE( 1 ) ), item);

    /* Visible --- */
    gtk_widget_show (item);
 

   /*
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_ADDSTRING, 0,
                ( LPARAM ) HB_PARSTR( 2, &hString, NULL ) );
   */
   hb_strfree( hString );
}


/*
hwg_Listboxsetstring( ::handle, ::value )
*/
/*
HB_FUNC( HWG_LISTBOXSETSTRING )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_SETCURSEL,
         ( WPARAM ) hb_parni( 2 ) - 1, 0 );
}
*/

/*
   hwg_Createlistbox( hParentWIndow, nListboxID, Style, x, y, nWidth, nHeight )
*/
HB_FUNC( HWG_CREATELISTBOX )
{
    GtkWidget *hlistbox;

    hlistbox = gtk_list_new ();

/*
    gtk_signal_connect (GTK_OBJECT (listbox), "selection_changed",
            GTK_SIGNAL_FUNC (listbox_changed), "selection_changed");
...>
void listitem_selected (GtkWidget *widget, gpointer *data)
{
    g_print ("item selected - %s\n", data);
}

*/

   /* Set listbox style */
    gtk_list_set_selection_mode (GTK_LIST (hlistbox), GTK_SELECTION_BROWSE);
   /* Set position */
   
   /* Set listbox sizes */
    

    if ( hlistbox )
     gtk_fixed_put(GTK_FIXED (hlistbox) , hlistbox, hb_parni( 4 ), hb_parni( 5 ) );    /* x, y */
 
     gtk_widget_set_size_request (hlistbox, hb_parni( 6 ), hb_parni( 7 ) );  /* nWidth, nHeight */
 
//   HWND hListbox = CreateWindow( TEXT( "LISTBOX" ),     /* predefined class  */
//         TEXT( "" ),                    /*   */
//         WS_CHILD | WS_VISIBLE | hb_parnl( 3 ), /* style  */
//         hb_parni( 4 ), hb_parni( 5 ),  /* x, y       */
//         hb_parni( 6 ), hb_parni( 7 ),  /* nWidth, nHeight */
//         ( HWND ) HB_PARHANDLE( 1 ),    /* parent window    */
//         ( HMENU ) hb_parni( 2 ),       /* listbox ID      */
//         GetModuleHandle( NULL ),
//         NULL );



   HB_RETHANDLE( hlistbox );
}

/*
   See: METHOD DeleteItem():
   HWG_LISTBOXDELETESTRING(handle)
*/   

/*
HB_FUNC( HWG_LISTBOXDELETESTRING )
{
   SendMessage( ( HWND ) HB_PARHANDLE( 1 ), LB_DELETESTRING, 0, ( LPARAM ) 0 );
}
*/


/*
   hwg_ListBoxShowMain(hparent,hlistbox)
*/
HB_FUNC( HWG_LISTBOXSHOWMAIN )
{
     /* Make listbox visible */
     GtkWidget * fenster;
     fenster = HB_PARHANDLE( 1 );
     gtk_container_add (GTK_CONTAINER (fenster), HB_PARHANDLE( 2 ) ); /* par 2 = hlistbox */
     gtk_widget_show ( (GtkWidget *) fenster);
}

/*
   hwg_ListBoxShow(hlistbox)
*/
HB_FUNC( HWG_LISTBOXSHOW )
{
  gtk_widget_show ( (GtkWidget *) HB_PARHANDLE( 1 ) );
}


/* ================= EOF of listbox.c ================= */

