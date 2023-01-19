#include "hwgui.ch"

FUNCTION DlgEmpty()

   LOCAL oDlg

   INIT DIALOG oDlg TITLE "test" ;
      AT 190, 10 SIZE 360, 300

   ACTIVATE DIALOG oDlg

   RETURN Nil
