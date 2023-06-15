#include "inkey.ch"
#include "hbgtinfo.ch"

PROCEDURE Main

   hb_ThreadStart( { || menu() } )
   hb_ThreadWaitForAll()

   RETURN

FUNCTION Menu()

   LOCAL nOpc, bCode

   Altd()
   SetMode(25,80)
   CLS
   DO WHILE .T.
      @ 2, 5         PROMPT "Exit"
      @ Row() + 1, 5 PROMPT "Show gt name"
      @ Row() + 1, 5 PROMPT "this menu"
      @ Row() + 1, 5 PROMPT "Menu hwgui"
      @ Row() + 1, 5 PROMPT "Dialog with get colorized"
      @ Row() + 1, 5 PROMPT "Dialog of text view"
      @ Row() + 1, 5 PROMPT "Dialog Auto"
      @ 1, 3 TO Row() + 1, 50
      MENU TO nOpc
      bCode := Nil
      DO CASE
      CASE nOpc == 1 .OR. LastKey() == K_ESC
         EXIT
      CASE nOpc == 2
         Alert( hb_gtInfo( HB_GTI_VERSION ) )
      CASE nOpc == 3
         hb_ThreadStart( { || hb_gtReload( "WVG" ), menu() } )
      CASE nOpc == 4
         hb_ThreadStart( { || hb_gtReload( "WVG" ), Menuhwgui() } )
      CASE nOpc == 5
         hb_ThreadStart( { || hb_gtReload( "WVG" ), DlgGet(.T.) } )
      CASE nOpc == 6
         hb_ThreadStart( { || hb_gtReload( "WVG" ), DlgTextView() } )
      CASE nOpc == 7
         hb_ThreadStart( { || hb_gtReload( "WVG" ), DlgAuto() } )
      ENDCASE
   ENDDO
   CLS

   RETURN Nil

FUNCTION AppUserName(); RETURN ""
FUNCTION AppVersaoExe(); RETURN ""
FUNCTION ShellExecuteOpen( a, b ); RUN ( a + " " + b ); Return Nil
