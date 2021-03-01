*
* Bug Ticket #70 Test reported by Alain Aupaix.
*
* $Id$
*

#include "hwgui.ch"


memvar oMain, oStatus, rg, oFont

//----------------------
function main()
//----------------------
public oMain, oStatus, oNew, oFont
PUBLIC oNewLang , oTimer , rg , outstring

#ifdef __GTK__
hwg_SetApplocale( "UTF8" )
hb_cdpSelect( "UTF8" )
#endif

PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

INIT WINDOW oMain TITLE "Trying to update status bar" AT 200,200 SIZE 100,100

   add status oStatus to oMain

   oStatus:SetText(" Trying to update status bar")
//   hwg_WriteStatus( oStatus,,"Trying to update status bar",.t.)

   @ 100,20 say "Click New to continue ..." SIZE 300,25

   @  50,50 OWNERBUTTON oNew TEXT "New" SIZE 100,25 ON CLICK {||newlang()} TOOLTIP "New lang"
   @ 200,50 OWNERBUTTON oQuit TEXT "Close" SIZE 100,25 ON CLICK {||oMain:close()} TOOLTIP "Quit"

ACTIVATE WINDOW oMain

return nil

//----------------------
function newlang()
//----------------------
// local oTimer
// LOCAL oNewLang

qout("newlang")

INIT DIALOG oNewLang TITLE "Add or update a language" AT oMain:nLeft+200,oMain:nTop-50 SIZE 400,100


   oStatus:SetText(" from NewLang()...")
//   hwg_WriteStatus( oStatus,,"from NewLang()...",.t.)

   @ 10,20 say "Click Create to continue ... and compare qout() value and status texte" SIZE 400,25

   @  50,50 OWNERBUTTON TEXT "Create" SIZE 70, 32 ON CLICK {||Createlang()}
   @ 200,50 OWNERBUTTON TEXT "Close"  SIZE 70, 32 ON CLICK {||hwg_endDialog()}

ACTIVATE DIALOG oNewLang

return nil

//----------------------
function CreateLang()
//----------------------
// local array:={"one", "two", "three", "four"}, && rg
rg := 1

qout("Createlang")
Settimer(oNewLang,@oTimer)
/*

  It seems, that the FOR ... NEXT loop
  freezes the activity of the parent dialog,
  so it is not ready to receive the
  SetText order. After leaving the loop,
  the last "four" is displayed. 

for rg=1 to len(array)
    qout(array[rg])
      oStatus:SetText(" From CreateLang()..."+array[rg])
//     hwg_WriteStatus( oStatus,," bla bla ..."+array[rg] , .t. )
    hwg_sleep(2000)
next
*/


return nil
//----------------------


* From testget2.prg and modified

//-------------------------------
Static Function Settimer(oTimer)
//-------------------------------
   SET TIMER oTimer OF oNewLang VALUE 2000 ACTION {|| IIF(rg < 5 , TimerFunc() , oTimer:End() ) }
Return Nil

//-------------------------
Static Function TimerFunc()
//-------------------------
local array:={"one", "two", "three", "four"}
   qout(array[rg])
   oStatus:SetText(" From CreateLang()..." + array[rg])
   rg := rg + 1
/*
   Crashes here with "not exported method"
   IF rg > 4
      oTimer:End()
   ENDIF
*/
Return Nil

* ======================== EOF of status.prg ==============================

