/*

 $Id$
 
 Test programm for GTK3: Iconification and background image
 
 
 GTK3: The icon is not visible in the task bar
 gcc -I../include `pkg-config --cflags gtk+-3.0` -o icon icon.c `pkg-config --libs gtk+-3.0`
 
 GTK2: this runs OK
 gcc -I../include `pkg-config --cflags gtk+-2.0` -o icon icon.c `pkg-config --libs gtk+-2.0`
*/

#include "gtk/gtk.h"

static GdkPixbuf *create_pixbuf(const gchar * filename)
{
   GdkPixbuf *pixbuf;
   GError *error = NULL;
   pixbuf = gdk_pixbuf_new_from_file(filename, &error);
   if(!pixbuf) {
      fprintf(stderr, "%s\n", error->message);
      g_error_free(error);
   }

   return pixbuf;
}




int main( int argc, char *argv[])
{
  GtkWidget *window;

  gtk_init(&argc, &argv);

  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(window), "icon");
  gtk_window_set_default_size(GTK_WINDOW(window), 230, 150);
  gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);
//  gtk_window_set_default_icon_list(GTK_WINDOW(window), create_pixbuf("image/hwgui_48x48.png"));
  gtk_window_set_icon(GTK_WINDOW(window), create_pixbuf("image/hwgui_48x48.png"));
  gtk_widget_show(window);

  g_signal_connect_swapped(G_OBJECT(window), "destroy",
      G_CALLBACK(gtk_main_quit), NULL);

  gtk_main();

  return 0;
}

/* ============================== EOF of icon.c ========================== */

