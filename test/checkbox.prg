 *
 * update_tab.prg
 *
 * $Id$
 *
 * Test program HWGUI sample for checkboxes
 * based on checkbox.prg
 *
 * Ticket #56: How to update a tab ?
 * The compilation of this expression
 *  IIF(nbChecked==0, oStatus:SetText(""),.t.)
 * throws the following warning:
 *  Warning W0027  Meaningless use of expression 'Logical'
 * and the program freezes. 
 * So modify to:
 * IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) )
 *
 * Other problem:
 * Filenames may not contain "_",
 * other program does not start.
 * -oupdate_tab
 * update_tab.prg
 *
 * ==>
 * -oupdatetab
 * updatetab.prg
 *
 * Also may not longer than 8.3 !
 * 
 * So .prg and .hbp renamed to checkbox.*
 *
 * Reason for crash:
 *
 * In
 * function update_count()
 * 
 * RETURN .T.
 *  // return nil   && This crashes !!!!!!
 *
 * Now the status field for number of checked items
 * appeared in tab "Stats"
 *
 * - Added a "public" MEMVAR "osay"
 * - This memvar is initialized in tab page definition of "Stats"
 * - The SAY based not on oDlg, but on oSay
 *   @ 173,20 say oSay CAPTION cNbChecked of oTab SIZE 60,22 STYLE WS_DLGFRAME
 * - In function update_count()
 *   the value is set with call of method
 *   oSay:SetText(cNbChecked)
 *
 *
 * Copyright 2022 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
 *
 * Copyright 2020-2022 Wilfried Brunken, DF7BE 
 *


    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes


#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

MEMVAR oDlg, nbChecked, cNbChecked ,oTab, osay

* ---------------------------------------------
Function Main
* ---------------------------------------------
 LOCAL oMainWindow 

  INIT WINDOW oMainWindow MAIN TITLE "Checkboxes and tabs" ;
     AT 0,0 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMainWindow
      MENU TITLE "&Exit"
        MENUITEM "&Quit" ACTION oMainWindow:Close()
      ENDMENU
      MENU TITLE "&Test"
         MENUITEM "&Test It" ACTION _frm_checkbox()
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow
 
RETURN NIL



FUNCTION _frm_checkbox

LOCAL oButton1, oButton2, oButton3, oButton4, oButton5, oButton6 , oButton7 , oButton8
LOCAL oButton9 
// LOCAL oTab
LOCAL oStatus
LOCAL oCheckbox1, oCheckbox2, oCheckbox3 , oCheckbox4 , oCheckbox5,  oCheckbox6 
LOCAL lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6

MEMVAR oDlg, nbChecked, cNbChecked , oTab , oSay

nbChecked  := 0
cNbChecked := "0"

lCheckbox1 := .F.
lCheckbox2 := .F.
lCheckbox3 := .F.
lCheckbox4 := .F.
lCheckbox5 := .F.
lCheckbox6 := .F.

INIT DIALOG oDlg TITLE "Checkboxes and tabs" ;
     AT 390,197 SIZE 516,323 ;
     STYLE WS_SYSMENU+WS_SIZEBOX+WS_VISIBLE

   // Status Bar
    ADD STATUS oStatus TO oDlg
// ADD STATUS PANEL oStatus TO oDlg

   @ 20, 20 TAB oTab ITEMS {} SIZE 440, 250 ;
      ON SIZE ANCHOR_TOPABS + ANCHOR_LEFTABS + ANCHOR_RIGHTABS + ANCHOR_BOTTOMABS

   BEGIN PAGE "Stats" of oTab

      @ 30,20 say " Nb checked" SIZE 120,22 STYLE WS_DLGFRAME
//      @ 150,20 say cNbChecked SIZE 60,22 STYLE WS_DLGFRAME
      @ 173,20 say oSay CAPTION cNbChecked of oTab SIZE 60,22 STYLE WS_DLGFRAME


      @ 300,166 BUTTON oButton9 CAPTION "OK"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| DisplayResults(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) ; 
                             , oDlg:Close() }

   END PAGE of oTab

   BEGIN PAGE "Tab 1" of oTab

      @ 300,61  BUTTON oButton1 CAPTION "Select all"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| oCheckbox1:Value(.T.) , ;
                             oCheckbox2:Value(.T.) , ;
                             oCheckbox3:Value(.T.) , ;
                             nbChecked := count_checked(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) , ;
                             oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                             cNbChecked=ltrim(str(nbChecked)), ;
                             IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                             update_count() }

      @ 300,112 BUTTON oButton2 CAPTION "Unselect all"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| oCheckbox1:Value(.F.) , ;
                             oCheckbox2:Value(.F.) , ;
                             oCheckbox3:Value(.F.) , ;
                             nbChecked := count_checked(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) , ;
                             oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                             cNbChecked=ltrim(str(nbChecked)), ;
                             IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                             update_count() }

      @ 300,28  BUTTON oButton3 CAPTION "Invert all"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| oCheckbox1:Invert() , ;
                             oCheckbox2:Invert() , ;
                             oCheckbox3:Invert() , ;
                             nbChecked := count_checked(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) , ;
                             oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                             cNbChecked=ltrim(str(nbChecked)), ;
                             IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                             update_count() }

      @ 300,166 BUTTON oButton4 CAPTION "OK"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| DisplayResults(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) ;
                          , oDlg:Close() }

      @ 45,70   GET CHECKBOX oCheckbox1 VAR lCheckbox1 CAPTION  "Check 1" SIZE 80,22 ;
                ON CLICK {||iif(lCheckbox1,nbChecked++,nbChecked--), ;
                                oStatus:SetText(" Checked : "+ltrim(str(nbChecked)))  , ;
                              cNbChecked=ltrim(str(nbChecked)) , ;
                              IIF(nbChecked==0, oStatus:SetText(""),nothing(.t.) ) , ;
                             update_count() }

      @ 45,110  GET CHECKBOX oCheckbox2 VAR lCheckbox2 CAPTION  "Check 2" SIZE 80,22 ;
                ON CLICK {||iif(lCheckbox2,nbChecked++,nbChecked--), ;
                            oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                            cNbChecked=ltrim(str(nbChecked)), ;
                            IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                            update_count() }

      @ 45,150  GET CHECKBOX oCheckbox3 VAR lCheckbox3 CAPTION  "Check 2" SIZE 80,22 ;
                ON CLICK {||iif(lCheckbox3,nbChecked++,nbChecked--), ;
                            oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                            cNbChecked=ltrim(str(nbChecked)), ;
                            IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                            update_count() }

   END PAGE of oTab

   BEGIN PAGE "Tab 2" of oTab
   
      @ 300,61  BUTTON oButton5 CAPTION "Select all"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| oCheckbox4:Value(.T.) , ;
                             oCheckbox5:Value(.T.) , ;
                             oCheckbox6:Value(.T.) , ;
                             nbChecked := count_checked(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) , ;
                             oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                             cNbChecked=ltrim(str(nbChecked)), ;
                             IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                             update_count() }

      @ 300,112 BUTTON oButton6 CAPTION "Unselect all"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| oCheckbox4:Value(.F.) , ;
                             oCheckbox5:Value(.F.) , ;
                             oCheckbox6:Value(.F.) , ;
                             nbChecked := count_checked(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) , ;
                             oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                             cNbChecked=ltrim(str(nbChecked)), ;
                             IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                             update_count() }

      @ 300,28  BUTTON oButton7 CAPTION "Invert all"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| oCheckbox4:Invert() , ;
                             oCheckbox5:Invert() , ;
                             oCheckbox6:Invert() , ;
                             nbChecked := count_checked(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) , ;
                             oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                             cNbChecked=ltrim(str(nbChecked)), ;
                             IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                             update_count() }

      @ 300,166 BUTTON oButton8 CAPTION "OK"   SIZE 120,32 ;
                STYLE WS_TABSTOP+BS_FLAT ;
                ON CLICK {|| DisplayResults(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6) ; 
                             , oDlg:Close() }

      @ 45,70   GET CHECKBOX oCheckbox4 VAR lCheckbox4 CAPTION  "Check 4" SIZE 80,22 ;
                    ON CLICK {||iif(lCheckbox4,nbChecked++,nbChecked--), ;
                                oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                            cNbChecked=ltrim(str(nbChecked)), ;
                            IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                                update_count() }

      @ 45,110  GET CHECKBOX oCheckbox5 VAR lCheckbox5 CAPTION  "Check 5" SIZE 80,22 ;
                    ON CLICK {||iif(lCheckbox5,nbChecked++,nbChecked--), ;
                                oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                            cNbChecked=ltrim(str(nbChecked)), ;
                            IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                                update_count() }
 
      @ 45,150  GET CHECKBOX oCheckbox6 VAR lCheckbox6 CAPTION  "Check 6" SIZE 80,22 ;
                    ON CLICK {||iif(lCheckbox6,nbChecked++,nbChecked--), ;
                                oStatus:SetText(" Checked : "+ltrim(str(nbChecked))), ;
                            cNbChecked=ltrim(str(nbChecked)), ;
                            IIF(nbChecked==0,oStatus:SetText(""),nothing(.t.) ), ;
                                update_count() }

   END PAGE of oTab 

ACTIVATE DIALOG oDlg

RETURN NIL


function update_count()
LOCAL ntabs

MEMVAR  cNbChecked, nbChecked , oTab , oSay  && oDlg not used

cNbChecked=ltrim(str(nbChecked))
// hwg_Msginfo(cNbChecked)
ntabs := oTab:GetActivePage(1,3)

IF ntabs == 1 
// @ 173,20 say cNbChecked of oTab SIZE 60,22 STYLE WS_DLGFRAME  
@ 173,20 say oSay CAPTION cNbChecked of oTab SIZE 60,22 STYLE WS_DLGFRAME

ELSE
 oSay:SetText(cNbChecked) 
ENDIF

RETURN .T.
// return nil   && This crashes !!!!!!


FUNCTION DisplayResults(Checkbox1, Checkbox2, Checkbox3 , Checkbox4 , Checkbox5,  Checkbox6)
LOCAL cergstr

cergstr := "Check 1= " + bool2onoff(Checkbox1) + CHR(10) + "Check 2= " + bool2onoff(Checkbox2) + CHR(10) +  ;
           "Check 3= " + bool2onoff(Checkbox3) + CHR(10) + "Check 4= " + bool2onoff(Checkbox4) + CHR(10) +  ;
           "Check 5= " + bool2onoff(Checkbox5) + CHR(10) + "Check 6= " + bool2onoff(Checkbox6)

hwg_MsgInfo(cergstr,"Result")

RETURN NIL

FUNCTION bool2onoff(lbool)
IF lbool
 RETURN "On"
ENDIF
RETURN "Off"

FUNCTION nothing(xpara)
RETURN xpara

FUNCTION count_checked(lCheckbox1, lCheckbox2, lCheckbox3 , lCheckbox4 , lCheckbox5,  lCheckbox6)
LOCAL nchkd
  nchkd := 0

  IF lCheckbox1
     nchkd++
  ENDIF
  IF lCheckbox2
     nchkd++
  ENDIF  
  IF lCheckbox3
     nchkd++
  ENDIF  
  IF lCheckbox4
     nchkd++
  ENDIF  
  IF lCheckbox5
     nchkd++
  ENDIF  
  IF lCheckbox6
     nchkd++
  ENDIF
  
RETURN nchkd  

* ============================== EOF of checkbox.prg ========================
