/*
 *$Id$
 *
 * HWGUI - Harbour Linux (GTK) GUI library source code: 
 * testget2.prg - GET system and Timer in dialog box sample
 *
 * Copyright 2004 Alexander S.Kresin <alex@kresin.ru>
 * www - http://www.kresin.ru
 */

#include "hwgui.ch"

Function Main
Local oMainWindow
* Private var1 := 10320.54  && DF7BE: not used

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200,0 SIZE 400,150

* DF7BE: Trouble: If main menu points have no subtite, only "Aktivieren" apprears

   MENU OF oMainWindow

*      MENUITEM "&Exit" ACTION oMainWindow:Close()
*      MENUITEM "&Get a value" ACTION DlgGet()

       MENU TITLE "&Exit"
        MENUITEM "&Exit" ACTION oMainWindow:Close()
       ENDMENU
       MENU TITLE "&Get a value"
        MENUITEM "&Get a value" ACTION DlgGet()
       ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow
Return Nil

Function DlgGet()
Local oModDlg, oTimer // , oFont := HFont():Add( "MS Sans Serif",0,-13 )
Local e1 := "Dialog from prg"
Local e2 := Date()
Local e3 := 10320.54
Local e4:="11222333444455"
Local e5 := 10320.54
Local e6 := "Max Lenght = 15"
Local e7 := "Password"

Private oSayT

   INIT DIALOG oModDlg CLIPPER NOEXIT TITLE "Get a value"  ;
   AT 210,10  SIZE 300,320 ;
   ON INIT {|| SetTimer(oModDlg,@oTimer)}   
   // FONT oFont  

   SET KEY FSHIFT,VK_F3 TO hwg_Msginfo("Shift-F3") 
   SET KEY FCONTROL,VK_F3 TO hwg_Msginfo("Ctrl-F3") 
   SET KEY 0,VK_F3 TO hwg_Msginfo("F3") 

   @ 20,10 SAY "Input something:" SIZE 260, 22

   @ 20,35 GET e1                       ;
        PICTURE "XXXXXXXXXXXXXXX"       ;
        SIZE 260, 26

   @ 20,65 GET e6                       ;
        MAXLENGTH 15                    ;
        SIZE 260, 26

   @ 20,95 GET e2  SIZE 260, 26

   @ 20,125 GET e3  SIZE 260, 26

   @ 20,155 GET e4                      ;
        PICTURE "@R 99.999.999/9999-99" ;
        SIZE 260, 26

   @ 20,185 GET e5                      ;
        PICTURE "@e 999,999,999.99"     ;
        SIZE 260, 26

   @ 20,215 GET e7                      ;
        PASSWORD                        ;
        SIZE 260, 26

   @  20,250  BUTTON "Ok" SIZE 100, 32 ON CLICK {||oModDlg:lResult:=.T.,oModDlg:Close()}
   @ 180,250 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   @ 100,295 SAY oSayT CAPTION "" SIZE 100,22 STYLE WS_BORDER + SS_CENTER ;
         COLOR 10485760 BACKCOLOR 12507070

   ReadExit( .T. )
   ACTIVATE DIALOG oModDlg

   oTimer:End()

   // hwg_WriteLog( "End" )
   IF oModDlg:lResult
      hwg_Msginfo( e1 + chr(10) + chr(13) +       ;
               e6 + chr(10) + chr(13) +       ;
               Dtoc(e2) + chr(10) + chr(13) + ;
               Str(e3) + chr(10) + chr(13) +  ;
               e4 + chr(10) + chr(13) +       ;
               Str(e5) + chr(10) + chr(13) +  ;
               e7 + chr(10) + chr(13)         ;
               ,"Results:" )
   ENDIF

Return Nil

Static Function SetTimer( oDlg,oTimer )

   SET TIMER oTimer OF oDlg VALUE 1000 ACTION {||TimerFunc()}
//   hwg_WriteLog( valtype( oTimer ) )
Return Nil

Static Function TimerFunc()

   oSayT:SetText( Time() )
Return Nil

* =========================== EOF of testget2.prg ==============================

