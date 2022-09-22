
* ticket112.prg

/*
No open maximized window.
Test with Windows 10 OS. Hwgui SVN

Reported by Itamar M. Lins Jr. , 2022-09-15
*/

#include "hwgui.ch"
Function main
LOCAL oFormMain

INIT WINDOW oFormMain MAIN AT -7,0 SIZE hwg_Getdesktopwidth()+14,hwg_Getdesktopheight()+14

@ 30,30 say "hwg_Getdesktopwidth ->" + hb_ntos(hwg_Getdesktopwidth()) size 300,30
@ 30,60 say "hwg_Getdesktopheight ->" + hb_ntos(hwg_Getdesktopheight()) size 300,30

// INIT WINDOW oFormMain MAIN APPNAME "TEST"  ;
// AT 0,0 SIZE hwg_Getdesktopwidth(),hwg_Getdesktopheight()

oFormMain:Activate()

return .T.


* =================== EOF of ticket112.prg ================================
