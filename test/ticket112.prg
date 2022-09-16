
* ticket112.prg

/*
No open maximized window.
Test with Windows 10 OS. Hwgui SVN

Reported by Itamar M. Lins Jr. , 2022-09-15
*/

#include "hwgui.ch"
Function main
LOCAL oFormMain

INIT WINDOW oFormMain MAIN APPNAME "TEST"  ;
AT 0,0 SIZE hwg_Getdesktopwidth(),hwg_Getdesktopheight()

oFormMain:Activate()

return .T.


* =================== EOF of ticket112.prg ================================
