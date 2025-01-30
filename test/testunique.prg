*
* testunique.prg
*
* $Id$
*
* Simple testprogram for function hwg_BMPuniquename
*
#include "hwgui.ch"


FUNCTION Main()

   LOCAL oMainWindow, oButton1, oButton2

   INIT WINDOW oMainWindow MAIN TITLE "Creating unique names for bitmaps" AT 168,50 SIZE 250,150

 

   @ 20,50 BUTTON oButton1 CAPTION "Test" ;
      ON CLICK { || Testen() } ;
      SIZE 80,32

   @ 120,50 BUTTON oButton2 CAPTION "Quit";
      ON CLICK { || oMainWindow:Close } ;
      SIZE 80,32

   ACTIVATE WINDOW oMainWindow
   
 
RETURN Nil


FUNCTION Testen()

hwg_MsgInfo("Start the function 5 times")
hwg_MsgInfo(hwg_BMPuniquename("bitmap"))
hwg_MsgInfo(hwg_BMPuniquename("bitmap"))
hwg_MsgInfo(hwg_BMPuniquename("bitmap"))
hwg_MsgInfo(hwg_BMPuniquename("bitmap"))
hwg_MsgInfo(hwg_BMPuniquename("bitmap"))

RETURN NIL



* ================ EOF of testunique.prg ======================