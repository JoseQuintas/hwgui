/*
 * HWGUI using sample
 * 
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "windows.ch"
#include "guilib.ch"

// REQUEST HB_CODEPAGE_RU866
// REQUEST HB_CODEPAGE_RU1251

function Main
Private oMainWindow, oPanel
Private oFont := Nil, cImageDir := "\"+Curdir()+"\..\image\"
Private nColor, oBmp2

   // hb_SetCodepage( "RU1251" )

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200,0 SIZE 400,150

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&Open" ACTION FileOpen()
         SEPARATOR
         MENUITEM "&Font" ACTION oFont:=HFont():Select(oFont)
         MENUITEM "&Color" ACTION (nColor:=Hwg_ChooseColor(nColor,.F.), ;
                     MsgInfo(Iif(nColor!=Nil,str(nColor),"--"),"Color value"))
         SEPARATOR
         MENUITEM "&Move Main Window" ACTION oMainWindow:Move(50, 60, 200, 300)
         MENUITEM "&Exit" ACTION EndWindow()
      ENDMENU
      MENU TITLE "&Samples"
         MENUITEM "&Checked" ID 1001 ;
               ACTION CheckMenuItem( ,1001, !IsCheckedMenuItem( ,1001 ) )
         SEPARATOR
         MENUITEM "&Test Tab" ACTION TestTab()
         SEPARATOR
         MENUITEM "&MsgGet" ;
               ACTION CopyStringToClipboard(MsgGet("Dialog Sample","Input table name"))
         MENUITEM "&Dialog from prg" ACTION DialogFromPrg()
         SEPARATOR
      ENDMENU

   ENDMENU

   ACTIVATE WINDOW oMainWindow MAXIMIZED

return nil

Function FileOpen
Local oModDlg, oBrw
Local mypath := "\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
Local fname := SelectFile( "xBase files( *.dbf )", "*.dbf", mypath )
Local nId

   IF !Empty( fname )
      mypath := "\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
      // use &fname new codepage RU866
      use &fname new
      nId := 111

      INIT DIALOG oModDlg TITLE "1"                    ;
            AT 210,10  SIZE 500,300                    ;
            ON INIT {|o|SetWindowText(o:handle,fname)} ;
            ON EXIT {|o|Fileclose(o)}

      MENU OF oModDlg
         MENUITEM "&Font" ACTION ( oBrw:oFont:=HFont():Select(oFont),oBrw:Refresh() )
         MENUITEM "&Exit" ACTION EndDialog( oModDlg:handle )
      ENDMENU

      @ 0,0 BROWSE oBrw DATABASE OF oModDlg ID nId ;
            SIZE 500,300                           ;
            STYLE WS_VSCROLL + WS_HSCROLL          ;
            ON SIZE {|o,x,y|MoveWindow(o:handle,0,0,x,y)} ;
            ON GETFOCUS {|o|dbSelectArea(o:alias)}
      CreateList( oBrw,.T. )
      oBrw:bScrollPos := {|o,n,lEof,nPos|VScrollPos(o,n,lEof,nPos)}
      IF oFont != Nil
         oBrw:ofont := oFont
      ENDIF
      AEval(oBrw:aColumns, {|o| o:bHeadClick := {|oB, n| MsgInfo("Column number "+Str(n))}})

      ACTIVATE DIALOG oModDlg NOMODAL
   ENDIF
Return Nil

Function FileClose( oDlg )
   Local oBrw := oDlg:FindControl( 111 )
   dbSelectArea( oBrw:alias )
   dbCloseArea()
Return .T.

function printdos
Local han := fcreate( "LPT1",0 )
  if han != -1
     fwrite( han, Chr(10)+Chr(13)+"Example of dos printing ..."+Chr(10)+Chr(13) )
     fwrite( han, "Line 2 ..."+Chr(10)+Chr(13) )
     fwrite( han, "---------------------------"+Chr(10)+Chr(13)+Chr(12) )
     fclose( han )
  else
     MsgStop("Can't open printer port!")
  endif
return nil

Function DialogFromPrg( o )
Local cTitle := "Dialog from prg", cText := "Input something"
Local oModDlg, oFont := HFont():Add( "MS Sans Serif",0,-13 )
Local cRes, aCombo := { "First","Second" }, oEdit, vard := "Monday"
// Local aTabs := { "Monday","Tuesday","Wednesday","Thursday","Friday" }

   // o:bGetFocus := Nil
   INIT DIALOG oModDlg TITLE cTitle           ;
   AT 210,10  SIZE 300,300                    ;
   FONT oFont                                 ;
   ON EXIT {||MsgYesNo("Really exit ?")}

   @ 20,10 SAY cText SIZE 260, 22
   @ 20,35 EDITBOX oEdit CAPTION ""    ;
        STYLE WS_DLGFRAME              ;
        SIZE 260, 26 COLOR Vcolor("FF0000")

   @ 20,70 CHECKBOX "Check 1" SIZE 90, 20
   @ 20,95 CHECKBOX "Check 2"  ;
        SIZE 90, 20 COLOR Iif( nColor==Nil,Vcolor("0000FF"),nColor )

   @ 160,70 GROUPBOX "RadioGroup"  SIZE 130, 75

   RADIOGROUP
   @ 180,90 RADIOBUTTON "Radio 1"  ;
        SIZE 90, 20 ON CLICK {||oEdit:SetColor(Vcolor("0000FF"),,.T.)}
   @ 180,115 RADIOBUTTON "Radio 2" ;
        SIZE 90, 20 ON CLICK {||oEdit:SetColor(Vcolor("FF0000"),,.T.)}
   END RADIOGROUP SELECTED 2

   @ 20,120 COMBOBOX aCombo STYLE WS_TABSTOP ;
        SIZE 100, 150

   @ 20,160 UPDOWN 10 RANGE -10,50 SIZE 50,32 STYLE WS_BORDER

   @ 160,160 TAB oTab ITEMS {} SIZE 130,56
   BEGIN PAGE "Monday" OF oTab
      @ 20,28 GET vard SIZE 80,22 STYLE WS_BORDER
   END PAGE OF oTab
   BEGIN PAGE "Tuesday" OF oTab
      @ 20,28 EDITBOX "" SIZE 80,22 STYLE WS_BORDER
   END PAGE OF oTab

   @ 100,220 LINE LENGTH 100

   @ 20,240 BUTTON "Ok" OF oModDlg ID IDOK  ;
        SIZE 100, 32 COLOR Vcolor("FF0000")
   @ 180,240 BUTTON "Cancel" OF oModDlg ID IDCANCEL  ;
        SIZE 100, 32

   ACTIVATE DIALOG oModDlg
   oFont:Release()

Return Nil

Function TestTab()

Local oDlg, oTAB
Local oGet1, oGet2, oVar1:="1", oVar2:="2"
Local oGet3, oGet4, oVar3:="3", oVar4:="4", oGet5, oVar5 := "5"

INIT DIALOG oDlg CLIPPER NOEXIT AT 0, 0 SIZE 200, 200

@ 10, 10 TAB oTab ITEMS {} SIZE 180, 180 ;
   ON LOSTFOCUS {||MsgInfo("Lost Focus")};
   ON INIT  {||SetFocus(oDlg:getlist[1]:handle)}

BEGIN PAGE "Page 01" of oTab

  @ 30, 60 Get oGet1 VAR oVar1 SIZE 100, 26
  @ 30, 90 Get oGet2 VAR oVar2 SIZE 100, 26
  @ 30,120 Get oGet3 VAR oVar3 SIZE 100, 26
  @ 30,150 Get oGet4 VAR oVar4 SIZE 100, 26

END PAGE of oTab

BEGIN PAGE "Page 02" of oTab

  @ 30, 60 Get oGet5 VAR oVar5 SIZE 100, 26

END PAGE of oTab

ACTIVATE DIALOG oDlg

return nil
