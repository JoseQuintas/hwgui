/*

   gtk3testvbox.c
  
   $Id$
  
   
   Compile with
   gcc -I../include `pkg-config --cflags gtk+-3.0` -o gtk3testvbox gtk3testvbox.c `pkg-config --libs gtk+-3.0`

*/

#include <gtk/gtk.h>

int main(int argc,char *argv[])
 {
     gtk_init(&argc,&argv);
     GtkWidget *win, *label, *btn, *vbox;

     win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
     g_signal_connect(win,"delete_event",gtk_main_quit,NULL); 

     label = gtk_label_new("Label 1"); 
     btn = gtk_button_new_with_label("Button 1"); 

     vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL,10); 
     gtk_box_pack_start(GTK_BOX(vbox),label,0,0,0); 
     gtk_box_pack_start(GTK_BOX(vbox),btn,0,0,0); 

     gtk_container_add(GTK_CONTAINER(win),vbox); 

     gtk_widget_show_all(win); 
     gtk_main(); 
     return 0;
 }


/* ===================== EOF of gtk3testvbox.c =============================== */

