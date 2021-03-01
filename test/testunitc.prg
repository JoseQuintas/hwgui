*
* testunitc.prg
*
* $Id$ 
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Test program for unit conversion functions
*
* Copyright 2021 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
 
    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes 
 
#include "hwgui.ch"

FUNCTION Main
LOCAL oFormMain

INIT WINDOW oFormMain MAIN  ;
   TITLE "Hwgui sample for test of unit conversion functions" AT 0,0 SIZE 300,200 ;
   STYLE WS_POPUP +  WS_CAPTION + WS_SYSMENU
  MENU OF oFormMain
      MENU TITLE "&Exit"
        MENUITEM "&Quit" ACTION oFormMain:Close()
      ENDMENU
      MENU TITLE "&Test"
        MENUITEM "&Teste" ACTION TESTS()
      ENDMENU
   ENDMENU    
   oFormMain:Activate()
RETURN NIL    

FUNCTION TESTS
 TESTF("hwg_TEMP_C2F (0.0)", hwg_TEMP_C2F (0.0), 32 )
 TESTF("hwg_TEMP_C2K (20.0)" , hwg_TEMP_C2K (20.0) , 293.15 )
 TESTF("hwg_TEMP_C2RA (0.0)" , hwg_TEMP_C2RA (0.0) , 491.67 )
 TESTF("hwg_TEMP_C2R (100.0)" , hwg_TEMP_C2R (100.0) , 80.0 )
 TESTF("hwg_TEMP_K2C (263.15)" , hwg_TEMP_K2C (263.15) , -10.0 )
 TESTF("hwg_TEMP_K2F (0.0)" , hwg_TEMP_K2F (0.0) , -459.67 )
 TESTF("hwg_TEMP_K2RA (373.15)" , hwg_TEMP_K2RA (373.15) , 671.67 )
 TESTF("hwg_TEMP_K2R (293.15)" , hwg_TEMP_K2R (293.15) , 16.0 )
 TESTF("hwg_TEMP_F2C (77.0)" , hwg_TEMP_F2C (77.0) , 25.0 )
 TESTF("hwg_TEMP_F2K (257.0)" , hwg_TEMP_F2K (257.0) , 398.15 )
 TESTF("hwg_TEMP_F2RA (212.0)" , hwg_TEMP_F2RA (212.0) , 671.67 )
 TESTF("hwg_TEMP_F2R (0.0)" , hwg_TEMP_F2R (0.0) , -14.22 ) 
 TESTF("hwg_TEMP_RA2C (716.67)" , hwg_TEMP_RA2C (716.67) , 125.0 )
 TESTF("hwg_TEMP_RA2F (545.67)" , hwg_TEMP_RA2F (545.67) , 86.0 )
 TESTF("hwg_TEMP_RA2K (545.67)" , hwg_TEMP_RA2K (545.67) , 303.15 )
 TESTF("hwg_TEMP_RA2R(536.67)" , hwg_TEMP_RA2R(536.67) , 20.0 )
 TESTF("hwg_TEMP_R2C (80.0)" , hwg_TEMP_R2C (80.0) , 100.0 )
 TESTF("hwg_TEMP_R2F (8.0)" , hwg_TEMP_R2F (8.0) , 50.0 )
 TESTF("hwg_TEMP_R2F (29.6)" , hwg_TEMP_R2F (29.6) , 98.6  )
 TESTF("hwg_TEMP_R2K (-218.52)" , hwg_TEMP_R2K (-218.52) , 0.0 )
 TESTF("hwg_TEMP_R2RA (29.6)" , hwg_TEMP_R2RA (29.6) , 558.27 )
 TESTF("hwg_KM2NML(1.852)" , hwg_KM2NML(1.852) , 1.0 )
 
 RETURN NIL

 FUNCTION TESTF(cFunkt, nFunkt, nExpected)
 
 hwg_MsgInfo(cFunkt + " :" + CHR(10) + ;
     "Result: " + ALLTRIM(STR(nFunkt)) + CHR(10) + ;
     "Expected: " + ALLTRIM(STR(nExpected)) ;
  ,  "Test of Unit conversion functions")
 
 RETURN NIL

* ======================= EOF of testunitc.prg =============================