*
* Ticket113.prg 
*

/*
Crash HCEDIT

Reported by Alain Aupaix , 2022-09
*/

#include "hwgui.ch"

MEMVAR oMainWindow

Function main
LOCAL  oButton
PUBLIC oMainWindow

INIT WINDOW oMainWindow MAIN AT 0,0 SIZE 150, 150

   @ 30,25 BUTTON oButton CAPTION "Test"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT   ; 
         ON CLICK {|| translate() } ;
        TOOLTIP "Tooltip"

oMainWindow:Activate()

return .T.

//------------------------
function translate(cprog)
//------------------------

LOCAL oFont , oComment_EN , cInfo_EN, oComment_FR , oInfo_FR , oDlg1 , OINFO_EN , CINFO_FR
LOCAL cTitle := "Ticket 113", nLeft := 0 , nTop := 0
LOCAL cTooltip01 , cTooltip02 , cTooltip03
LOCAL cComment_EN , cComment_FR
 
MEMVAR oMainWindow
 
cTooltip01 := "Tooltip 1"
cTooltip02 := "Tooltip 2"
cTooltip03 := "Tooltip 3"

cInfo_EN    := "English info"
cComment_EN := "English comment"
cInfo_FR    := "French info"
cComment_FR := "French comment"


IF cProg == NIL
 cProg := "Ticket113"
ENDIF 

#ifdef __PLATFORM__WINDOWS
   PREPARE FONT oFont  NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
#else
   PREPARE FONT oFont  NAME "Sans" WIDTH 0 HEIGHT 12 
#endif

* _("English comment") ==> "English comment" ...

INIT DIALOG oDlg1 CLIPPER NOEXIT TITLE cTitle AT oMainWindow:nLeft+140,oMainWindow:nTop+130  SIZE 940,352 FONT oFont

 @  10,30  say cProg SIZE 220, 22 BACKCOLOR hwg_ColorC2N("#83E4CA") COLOR hwg_ColorC2N("0000FF") TOOLTIP cTooltip01

 @  10,60  SAY "English comment" SIZE 200, 20 COLOR hwg_ColorC2N("FF0000") TOOLTIP cTooltip02
 @  10,80  HCEDIT oComment_EN SIZE 450, 60 BACKCOLOR hwg_ColorC2N("FFFFFF") COLOR hwg_ColorC2N("000000") 
oComment_EN:SetText(cComment_EN,,,,)

@ 480,60  SAY "French comment" SIZE 200, 20 COLOR hwg_ColorC2N("FF0000") TOOLTIP cTooltip02
@ 480,80  HCEDIT oComment_FR SIZE 450, 60 BACKCOLOR hwg_ColorC2N("FFFFFF") COLOR hwg_ColorC2N("000000")
oComment_FR:SetText(cComment_FR,,,,)

@ 10,150  SAY "English info" SIZE 200, 20 COLOR hwg_ColorC2N("FF0000") TOOLTIP cTooltip03
@ 10,170  HCEDIT oInfo_EN SIZE 450, 60 BACKCOLOR hwg_ColorC2N("FFFFFF") COLOR hwg_ColorC2N("000000")
 oInfo_EN:SetText(cInfo_EN,,,,)   && 

// @ 10,170  HCEDIT oComment_FR SIZE 450, 60 BACKCOLOR hwg_ColorC2N("FFFFFF") COLOR hwg_ColorC2N("000000")
// oInfo_EN:SetText(cInfo_EN,,,,)

@ 480,150 SAY "French info" SIZE 200, 20 COLOR hwg_ColorC2N("FF0000") TOOLTIP cTooltip03
@ 480,170 HCEDIT oInfo_FR SIZE 450, 60 BACKCOLOR hwg_ColorC2N("FFFFFF") COLOR hwg_ColorC2N("000000")
oInfo_FR:SetText(cInfo_FR,,,,)

@ 350,300 BUTTON "Save" OF oDlg1 ID IDOK  ;
SIZE 100, 32 COLOR hwg_ColorC2N("FF0000")
@ 470,300 BUTTON "Cancel" OF oDlg1 ID IDCANCEL  ;
SIZE 100, 32 COLOR hwg_ColorC2N("FF0000")

ACTIVATE DIALOG oDlg1

RETURN NIL


/*
Error BASE/3012  Argument error: HB_UTF8STUFF
Called from HB_UTF8STUFF(0)
Called from HCED_STUFF(2764)
Called from HCEDIT:INSTEXT(2050)
Called from HCEDIT:ONKEYDOWN(1516)
Called from HCEDIT:ONEVENT(526)
Called from HWG_ACTIVATEDIALOG(0)
Called from HDIALOG:ACTIVATE(183)
Called from TRANSLATE(488)
Called from APPLICATIONS(430)
Called from (b)MAIN(903)
Called from HOWNBUTTON:MUP(329)
Called from HOWNBUTTON:ONEVENT(152)
Called from HWG_ACTIVATEMAINWINDOW(0)
Called from HMAINWINDOW:ACTIVATE(351)
Called from MAIN(2386)

I dont know if it's due to the zone where I click to enter in an hcedit function
(in the texte or in a zone which is in hcedit but out of the text,
 but it crashes (program is not closed, and I must kill it)
I don't know, but it seems due to hcedit ...

I have also sometimes another type of crash with this function,
 but in this case, it closes my program, and it is very talkative in a console.
 I will send it when it will come again.

Thanks
A+

*/

* ========================= EOF of Ticket113.prg ================================


