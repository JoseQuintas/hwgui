#include "windows.ch"
#include "guilib.ch"

Function Main()
    Local oMain
        
    INIT WINDOW oMain MAIN TITLE "Help Demo" HELP "helpdemo.hlp";
         AT 0,0 ;
         SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

            MENU OF oMain
                    MENUITEM "&Exit"        ACTION oMain:Close()
                    MENUITEM "&Help Dialog" ACTION Test()
            ENDMENU

    ACTIVATE WINDOW oMain
Return Nil

Static Function Test()
    Local cVar := Space(30)
    Local oVar
    Local oModDlg
    Local xVar := Space(50)
    
    INIT DIALOG oModDlg TITLE "Press F1 to invoke Context Help"  ;
        AT 210,10  SIZE 300,300 HELPID 3        
        
        @ 20,10 SAY "Input something:" SIZE 260, 22 
        @ 20,35 GET oVar VAR cVar SIZE 260, 26 COLOR hwg_ColorC2N("FF0000") TOOLTIP "Set focus on this control and press help"

        @ 160,170 GET xVar SIZE 80, 20 TOOLTIP "Set focus on this control and press help"

       @  20,240 BUTTON "Ok"     ID IDOK      SIZE 100, 32
       @ 180,240 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32 

       oVar:helpid := 4
   
    ACTIVATE DIALOG oModDlg
Return Nil

