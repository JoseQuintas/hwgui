#include "inkey.ch"
#include "hbgtinfo.ch"

PROCEDURE Main

   hb_ThreadStart( { || menu() } )
   hb_ThreadWaitForAll()

   RETURN

FUNCTION Menu()

   LOCAL nOpc

   SetMode(25,80)
   CLS
   DO WHILE .T.
      @ 2, 5         PROMPT "Exit"
      @ Row() + 1, 5 PROMPT "Show gt name"
      @ Row() + 1, 5 PROMPT "this menu on new thread"
      @ Row() + 1, 5 PROMPT "Menu hwgui"
      @ Row() + 1, 5 PROMPT "Empty dialog"
      @ Row() + 1, 5 PROMPT "Empty dialog on new thread"
      @ Row() + 1, 5 PROMPT "Dialog with get colorized new thread"
      @ 1, 3 TO Row() + 1, 50
      MENU TO nOpc
      DO CASE
      CASE nOpc == 1 .OR. LastKey() == K_ESC
         EXIT
      CASE nOpc == 2
         Alert( hb_gtInfo( HB_GTI_VERSION ) )
      CASE nOpc == 3
         hb_ThreadStart( { || hb_gtReload( "WVG" ), menu() } )
      CASE nOpc == 4
         hb_ThreadStart( { || Menuhwgui() } )
      CASE nOpc == 5
         DlgEmpty()
      CASE nOpc == 6
         hb_ThreadStart( { || DlgEmpty() } )
      CASE nOpc == 7
         hb_ThreadStart( { || DlgGet(.T.) } )
      ENDCASE
   ENDDO
   CLS

   RETURN Nil
