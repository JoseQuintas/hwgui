/*
partial code from samples/testget2.prg with some changes
*/

#include "hwgui.ch"

FUNCTION DlgGet( lColorInFocus )

   LOCAL oDlg, oFont := HFont():Add( "MS Sans Serif", 0, -13 )
   LOCAL e1 := "DlgGet"
   LOCAL e2 := Date()
   LOCAL e3 := 10320.54
   LOCAL e4 := "11222333444455"
   LOCAL e5 := 10320.54
   LOCAL e6 := "Max Lenght = 15"
   LOCAL e7 := "Password"

   INIT DIALOG oDlg CLIPPER TITLE "Get with color in focus"  ;
      AT 210,10  SIZE 300,320                  ;
      FONT oFont

   SET KEY FSHIFT, VK_F3 TO hwg_Msginfo( "Shift-F3" )
   SET KEY FCONTROL, VK_F3 TO hwg_Msginfo( "Ctrl-F3" )
   SET KEY 0, VK_F3 TO hwg_Msginfo( "F3" )
   SET KEY 0, VK_RETURN TO hwg_Msginfo( "Return" )

   IF lColorInFocus <> Nil
      hwg_SetColorinFocus( lColorInFocus )
   ENDIF

   @ 20, 10  SAY "Input something:" SIZE 260, 22

   @ 20, 35  GET e1   PICTURE "XXXXXXXXXXXXXXX" SIZE 135, 26

   @ 20, 65  GET e6 MAXLENGTH 15 SIZE 135, 26

   @ 20, 95  GET e2  SIZE 72, 26

   @ 20, 125 GET e3  SIZE 117, 26

   @ 20, 155 GET e4 PICTURE "@R 99.999.999/9999-99" SIZE 162, 26

   @ 20, 185 GET e5 PICTURE "@e 999,999,999.9999" SIZE 144, 26

   @ 20, 215 GET e7 PASSWORD SIZE 72, 26

   @  20, 250 BUTTON "Ok" SIZE 100, 32 ON CLICK { || oDlg:lResult := .T., oDlg:Close() }
   @ 180, 250 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ReadExit( .T. )
   ACTIVATE DIALOG oDlg

   IF oDlg:lResult
      hwg_Msginfo( e1 + hb_Eol() +   ;
               e6 + hb_Eol() +       ;
               Dtoc( e2 ) + hb_Eol() + ;
               Str( e3 ) + hb_Eol() +  ;
               e4 + hb_Eol() +       ;
               Str( e5 ) + hb_Eol() +  ;
               e7 + hb_Eol()         ;
               ,"Results:" )
   ENDIF

RETURN Nil

