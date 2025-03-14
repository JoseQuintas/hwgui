* Ticket170.prg

* #170 ComboBox Linux Bound error: array access

#include "hwgui.ch"

Procedure Main
local oRe10, cRe10:="1"
local aFlist := {" ","1","2"}
* Fix Warning W0001  Ambiguous reference 'ODLG'
local oDlg
local oButton
INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Test" AT 0,0 size 800,400 STYLE DS_CENTER

  @ 010,010 get ComboBox oRe10 var cRe10 ITEMS aFlist TEXT size 300,25 DisplayCount 3
  
  * Need button for exit

  @ 100,100 BUTTON oButton CAPTION "Exit"   SIZE 80,32 ;
        STYLE WS_TABSTOP + BS_FLAT ;
        ON CLICK { | | oDlg:Close() }  

  oDlg:bActivate := {||cRe10:="2",oRe10:Refresh()}

oDlg:Activate()

* =================== EOF of Ticket170.prg =========================
