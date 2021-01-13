/*
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 * Sample program allow colors in qout()
 *
 * Copyright 2005 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 *
 * Copyright 2015-2021 Alain Aupeix
 *
 */
    * Status:
    *  WinAPI   :  No
    *  GTK/Linux:  Yes
    *  GTK/Win  :  No


/*
  === LINUX only ===
  On windows, the QOUT output's are supressed by the WinAPI.
  Do not use this feature on multi platform applications.  
*/



#include "hwgui.ch"
#include "qcolor.ch"


function main()
local ofont, omakedlg

PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12
   
INIT DIALOG oMakeDlg TITLE "Colored qout() test" AT 100,100 SIZE 350,110  font oFont

@ 10,10 say "Warning, this test must be launched from within a terminal ..." SIZE 330, 22 COLOR hwg_ColorC2N("FF0000")
@ 10,40 say "We'll send colored strings to qout() in the terminal" SIZE 285, 22 COLOR hwg_ColorC2N("0000FF")

@ 100, 80 BUTTON "Continue" SIZE 100,25 ID IDOK

ACTIVATE DIALOG oMakeDlg
oFont:Release()
hwg_EndWindow()

qout("Normal foreground colors")
qout()

qout(fRed+bBla+"red/black"+noColor+" "+;
     fGre+bBla+"green/black"+noColor+" "+;
     fYel+bBla+"yellow/black"+noColor+" "+;
     fBlu+bBla+"blue/black"+noColor+" "+;
     fMag+bBla+"magenta/black"+noColor+" "+;
     fCya+bBla+"cyan/black"+noColor+" "+;
     fWhi+bBla+"white/black"+noColor)

qout(fBla+bRed+"black/red"+noColor+" "+;
     fGre+bRed+"green/red"+noColor+" "+;
     fYel+bRed+"yellow/red"+noColor+" "+;
     fBlu+bRed+"blue/red"+noColor+" "+;
     fMag+bRed+"magenta/red"+noColor+" "+;
     fCya+bRed+"cyan/red"+noColor+" "+;
     fWhi+bRed+"white/red"+noColor)

qout(fBla+bGre+"black/green"+noColor+" "+;
     fRed+bGre+"red/green"+noColor+" "+;
     fYel+bGre+"yellow/green"+noColor+" "+;
     fBlu+bGre+"blue/green"+noColor+" "+;
     fMag+bGre+"magenta/green"+noColor+" "+;
     fCya+bGre+"cyan/green"+noColor+" "+;
     fWhi+bGre+"white/green"+noColor)

qout(fBla+bYel+"black/yellow"+noColor+" "+;
     fRed+bYel+"red/yellow"+noColor+" "+;
     fGre+bYel+"green/yellow"+noColor+" "+;
     fBlu+bYel+"blue/yellow"+noColor+" "+;
     fMag+bYel+"magenta/yellow"+noColor+" "+;
     fCya+bYel+"cyan/yellow"+noColor+" "+;
     fWhi+bYel+"white/yellow"+noColor)

qout(fBla+bBlu+"black/blue"+noColor+" "+;
     fRed+bBlu+"red/blue"+noColor+" "+;
     fGre+bBlu+"green/blue"+noColor+" "+;
     fYel+bBlu+"yellow/blue"+noColor+" "+;
     fMag+bBlu+"magenta/blue"+noColor+" "+;
     fCya+bBlu+"cyan/blue"+noColor+" "+;
     fWhi+bBlu+"white/blue"+noColor)

qout(fBla+bMag+"black/magenta"+noColor+" "+;
     fRed+bMag+"red/magenta"+noColor+" "+;
     fGre+bMag+"green/magenta"+noColor+" "+;
     fYel+bMag+"yellow/magenta"+noColor+" "+;
     fBlu+bMag+"blue/magenta"+noColor+" "+;
     fCya+bMag+"cyan/magenta"+noColor+" "+;
     fWhi+bMag+"white/magenta"+noColor)

qout(fBla+bCya+"black/cyan"+noColor+" "+;
     fRed+bCya+"red/cyan"+noColor+" "+;
     fGre+bCya+"green/cyan"+noColor+" "+;
     fYel+bCya+"yellow/cyan"+noColor+" "+;
     fBlu+bCya+"blue/cyan"+noColor+" "+;
     fMag+bCya+"magenta/cyan"+noColor+" "+;
     fWhi+bCya+"white/cyan"+noColor)

qout(fBla+bWhi+"black/white"+noColor+" "+;
     fRed+bWhi+"red/white"+noColor+" "+;
     fGre+bWhi+"green/white"+noColor+" "+;
     fYel+bWhi+"yellow/white"+noColor+" "+;
     fBlu+bWhi+"blue/white"+noColor+" "+;
     fMag+bWhi+"magenta/white"+noColor+" "+;
     fCya+bWhi+"cyan/white"+noColor)
qout()

qout("Sur-intensity foreground colors")
qout()

qout(gRed+bBla+"red/black"+noColor+" "+;
     gGre+bBla+"green/black"+noColor+" "+;
     gYel+bBla+"yellow/black"+noColor+" "+;
     gBlu+bBla+"blue/black"+noColor+" "+;
     gMag+bBla+"magenta/black"+noColor+" "+;
     gCya+bBla+"cyan/black"+noColor+" "+;
     gWhi+bBla+"white/black"+noColor+" ")

qout(gBla+bRed+"black/red"+noColor+" "+;
     gGre+bRed+"green/red"+noColor+" "+;
     gYel+bRed+"yellow/red"+noColor+" "+;
     gBlu+bRed+"blue/red"+noColor+" "+;
     gMag+bRed+"magenta/red"+noColor+" "+;
     gCya+bRed+"cyan/red"+noColor+" "+;
     gWhi+bRed+"white/red"+noColor+" ")

qout(gBla+bGre+"black/green"+noColor+" "+;
     gRed+bGre+"red/green"+noColor+" "+;
     gYel+bGre+"yellow/green"+noColor+" "+;
     gBlu+bGre+"blue/green"+noColor+" "+;
     gMag+bGre+"magenta/green"+noColor+" "+;
     gCya+bGre+"cyan/green"+noColor+" "+;
     gWhi+bGre+"white/green"+noColor+" ")

qout(gBla+bYel+"black/yellow"+noColor+" "+;
     gRed+bYel+"red/yellow"+noColor+" "+;
     gGre+bYel+"green/yellow"+noColor+" "+;
     gBlu+bYel+"blue/yellow"+noColor+" "+;
     gMag+bYel+"magenta/yellow"+noColor+" "+;
     gCya+bYel+"cyan/yellow"+noColor+" "+;
     gWhi+bYel+"white/yellow"+noColor+" ")

qout(gBla+bBlu+"black/blue"+noColor+" "+;
     gRed+bBlu+"red/blue"+noColor+" "+;
     gGre+bBlu+"green/blue"+noColor+" "+;
     gYel+bBlu+"yellow/blue"+noColor+" "+;
     gMag+bBlu+"magenta/blue"+noColor+" "+;
     gCya+bBlu+"cyan/blue"+noColor+" "+;
     gWhi+bBlu+"white/blue"+noColor+" ")

qout(gBla+bMag+"black/magenta"+noColor+" "+;
     gRed+bMag+"red/magenta"+noColor+" "+;
     gGre+bMag+"green/magenta"+noColor+" "+;
     gYel+bMag+"yellow/magenta"+noColor+" "+;
     gBlu+bMag+"blue/magenta"+noColor+" "+;
     gCya+bMag+"cyan/magenta"+noColor+" "+;
     gWhi+bMag+"white/magenta"+noColor+" ")

qout(gBla+bCya+"black/cyan"+noColor+" "+;
     gRed+bCya+"red/cyan"+noColor+" "+;
     gGre+bCya+"green/cyan"+noColor+" "+;
     gYel+bCya+"yellow/cyan"+noColor+" "+;
     gBlu+bCya+"blue/cyan"+noColor+" "+;
     gMag+bCya+"magenta/cyan"+noColor+" "+;
     gWhi+bCya+"white/cyan"+noColor+" ")

qout(gBla+bWhi+"black/white"+noColor+" "+;
     gRed+bWhi+"red/white"+noColor+" "+;
     gGre+bWhi+"green/white"+noColor+" "+;
     gYel+bWhi+"yellow/white"+noColor+" "+;
     gBlu+bWhi+"blue/white"+noColor+" "+;
     gMag+bWhi+"magenta/white"+noColor+" "+;
     gCya+bWhi+"cyan/white"+noColor+" ")
qout()
qout()

return nil

* ---------------------- EOF of qoutcolor.prg ---------------------
