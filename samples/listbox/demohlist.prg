#include "windows.ch" 
#include "guilib.ch"
// #include "listbox.ch"


Function Main
Local oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 0,0 SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION oMainWindow:Close()
      MENUITEM "&Teste" ACTION Teste()
   ENDMENU

   ACTIVATE WINDOW oMainWindow
Return Nil

Function Teste
Local oModDlg, oFont := HFont():Add( "MS Sans Serif",0,-13 )
Local oList, oItems:={"Item01","Item02","Item03","Item04"}

   INIT DIALOG oModDlg TITLE "Test"  ;
   AT 0,0  SIZE 450,350   ;
   FONT oFont

   @ 10,40 LISTBOX oList ITEMS oItems ;
             OF oModDlg                  ;
             INIT 1 ;
             SIZE 210, 220            ;
             ON INIT {||hwg_Msginfo("Teste")} ;
             TOOLTIP "Test ListBox"       

   @  10,280 BUTTON "Ok" ID IDOK  SIZE 50, 32
    ACTIVATE DIALOG oModDlg
    oFont:Release()

   IF oModDlg:lResult
    ENDIF
Return Nil
