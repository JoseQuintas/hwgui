/*
frm_main - dialog for each data and main use of class
*/

#include "hbclass.ch"
#include "directry.ch"
#include "frm_class.ch"
#include "inkey.ch"

FUNCTION frm_main( cDBF, aAllSetup )

   LOCAL oFrm, nPos

#ifdef HBMK_HAS_GTWVG
   hb_gtReload( "WVG" )
   SetMode(30,100)
   SetColor("W/B")
   CLS
#endif

   oFrm := frm_Class():New()
   oFrm:cFileDBF   := cDBF
#ifdef HBMK_HAS_GTWVG
   oFrm:oDlg := wvgSetAppWindow()
#endif
   oFrm:cTitle     := gui_LibName() + " - " + cDBF
   oFrm:cOptions   := "IEDP"
   oFrm:lWithTab   := .t.
   oFrm:nEditStyle := 3 // from 1 to 3
   oFrm:aAllSetup  := aAllSetup
   AAdd( oFrm:aOptionList, { "Mail", { || Nil } } ) // example of aditional button

   nPos := hb_ASCan( aAllSetup, { | e | e[ 1 ] == cDBF } )

   oFrm:aEditList := aAllSetup[ nPos, 2 ]
   oFrm:Execute()

   RETURN Nil
