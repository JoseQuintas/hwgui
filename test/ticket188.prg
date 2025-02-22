* #188 Skip control with ENTER keyboard 
* Based on TAB sample in tutorial

* Description:
* The "CLIPPER" term in INIT DIALOG switches to the original
* Clipper behavior. The ENTER KEY moves to the next input field.
* If the last field in the tab is reached, the dialog closes.
* "CLIPPER NOEXIT": At the last field ENTER does not leave the dialog,
* staying here.
*
* Reason: EDITBOX is an HWGUI extension for multi line editing.
* So ENTER means LINE FEED.
* The CLIPPER term has only effect on GET fields.
* On LINUX/GTK the behavior is a little different:
* It reacts like NOEXIT forever and at last field the following
* GTK message apeared:
* ticket188:5546): Gtk-CRITICAL **: 13:14:41.213: IA__gtk_widget_event:
* assertion 'WIDGET_REALIZED_FOR_EVENT (widget, event)' failed
* ESC does not close the dialog.
* In Project CLLOG in editmask.prg,
* there is a solution to handle the ESC key for ending dialog.
*
* If this is OK for you, use only GET commands.

#include "hwgui.ch"
Function Test()
Local oDlg, oTab
// In WinAPI version we must have an hspace for controls in a tab control, because a top of the tab
// is occupied by tabs. This hspace depend on the font size.
Local nTop := Iif( "windows" $ Lower(Os()), 24, 0 )

LOCAL oget1, oget2, oget3, oget4, oget5, oget6, oget7, oget8
LOCAL cget1, cget2, cget3, cget4, cget5, cget6, cget7, cget8

* Length for GET fields:
LOCAL nlaenge := 20

cget1 := hwg_GET_Helper("Pyotr",nlaenge)
cget2 := hwg_GET_Helper("Ilyich",nlaenge)
cget3 := hwg_GET_Helper("Tchaikovsky",nlaenge)
cget4 := hwg_GET_Helper("07/05/1840",nlaenge)
cget5 := hwg_GET_Helper("Sergei",nlaenge)
cget6 := hwg_GET_Helper("Vasilievich",nlaenge)
cget7 := hwg_GET_Helper("Rachmaninoff",nlaenge)
cget8 := hwg_GET_Helper("01/04/1873",nlaenge)

   INIT DIALOG oDlg TITLE "Tab control";
         AT 0, 0 SIZE 380, 260 CLIPPER ;
         FONT HFont():Add( "MS Sans Serif",0,-13 )

   @ 20, 20 TAB oTab ITEMS {} SIZE 340, 180 ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   BEGIN PAGE "First" of oTab

*     @ 30, nTop+16 EDITBOX "Pyotr" SIZE 200, 26
*     @ 30, nTop+46 EDITBOX "Ilyich" SIZE 200, 26
*     @ 30, nTop+76 EDITBOX "Tchaikovsky" SIZE 200, 26
*     @ 30, nTop+106 EDITBOX "07/05/1840" SIZE 100, 26

     @ 30, nTop+16  GET oget1 VAR cget1 SIZE 200, 26
     @ 30, nTop+46  GET oget2 VAR cget2 SIZE 200, 26
     @ 30, nTop+76  GET oget3 VAR cget3 SIZE 200, 26
     @ 30, nTop+106 GET oget4 VAR cget4 SIZE 100, 26


   END PAGE of oTab

   BEGIN PAGE "Second" of oTab

*     @ 30, nTop+16 EDITBOX "Sergei" SIZE 200, 26
*     @ 30, nTop+46 EDITBOX "Vasilievich" SIZE 200, 26
*     @ 30, nTop+76 EDITBOX "Rachmaninoff" SIZE 200, 26
*     @ 30, nTop+106 EDITBOX "01/04/1873" SIZE 100, 26

     @ 30, nTop+16  GET oget5 VAR cget5 SIZE 200, 26
     @ 30, nTop+46  GET oget6 VAR cget6 SIZE 200, 26
     @ 30, nTop+76  GET oget7 VAR cget6 SIZE 200, 26
     @ 30, nTop+106 GET oget8 VAR cget7 SIZE 100, 26


   END PAGE of oTab

   @ 140,220 BUTTON 'Close' SIZE 100,28 ON CLICK {|| oDlg:Close() } ;
         ON SIZE ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   ACTIVATE DIALOG oDlg

Return Nil

* ======================= EOF of ticket188.prg =====================
      
