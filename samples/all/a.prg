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
Private oFont := Nil, cImageDir := "..\image\"
Private nColor, oBmp2

   // hb_SetCodepage( "RU1251" )

   INIT WINDOW oMainWindow MDI TITLE "Example" ;
         MENUPOS 3 COLOR HBrush():Add(16744703):handle 

   @ 0,0 PANEL oPanel SIZE 0,32
   @ 2,3 OWNERBUTTON OF oPanel ON CLICK {||CreateChildWindow()} ;
       SIZE 32,26 FLAT ;
       BITMAP cImageDir+"new.bmp" COORDINATES 0,4,0,0 TOOLTIP "New MDI child window"

//   ADD STATUS oStatus TO oMainWindow PARTS 400

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&New" ACTION CreateChildWindow()
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
         MENUITEM "&Class HRect" ACTION RRectangle()
         SEPARATOR
         MENUITEM "&MsgGet" ;
               ACTION CopyStringToClipboard(MsgGet("Dialog Sample","Input table name"))
         MENUITEM "&Dialog from prg" ACTION DialogFromPrg()
         MENUITEM "&MdiChild from prg" ACTION MdiChildFromPrg( )
         MENUITEM "&DOS print" ACTION PrintDos()
         MENUITEM "&Windows print" ;
               ACTION Iif( OpenReport("a.rpt","Simple"),PrintReport(,,.T.),.F.)
         MENUITEM "&Print Preview" ACTION PrnTest()
         MENUITEM "&Sending e-mail using Outlook" ACTION Sendemail("test@test.com")
         MENUITEM "&Command ProgressBar" ACTION TestProgres()
         SEPARATOR
         MENUITEM "&Test No Exit" ACTION NoExit()
      ENDMENU

      MENU TITLE "&TopMost"
         MENUITEM "&Active" ACTION ActiveTopMost( oMainWindow:Handle, .T. )
         MENUITEM "&Desactive" ACTION ActiveTopMost( oMainWindow:Handle, .F. )
      ENDMENU

      MENU TITLE "&Help"
         MENUITEM "&About" ACTION OpenAbout()
         MENUITEM "&Window2Bitmap" ACTION About2()
         MENUITEM "&Version HwGUI and Compilator" ACTION MsgInfo(HwG_Version(1))
         MENUITEM "&Version HwGUI" ACTION MsgInfo(HwG_Version())
      ENDMENU
      MENU TITLE "&Windows"
         MENUITEM "&Tile"  ;
            ACTION  SendMessage(HWindow():GetMain():handle,WM_MDITILE,MDITILE_HORIZONTAL,0)
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow MAXIMIZED

return nil

Function CreateChildWindow
Local oChildWnd, oPanel, oFontBtn, oBoton1, oBoton2
Local e1 := "Dialog from prg"
Local e2 := Date()
Local e3 := 10320.54
Local e4:="11222333444455"
Local e5 := 10320.54

   PREPARE FONT oFontBtn NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

   INIT WINDOW oChildWnd MDICHILD TITLE "Child";
     STYLE WS_CHILD+ WS_OVERLAPPEDWINDOW 
     //STYLE WS_VISIBLE + WS_OVERLAPPEDWINDOW

   @ 0,0 PANEL oPanel OF oChildWnd SIZE 0,44

   @ 2,3 OWNERBUTTON oBoton1 OF oPanel ID 108 ON CLICK {||oBoton2:Enable()} ;
       SIZE 44,38 FLAT ;
       TEXT "New" FONT oFontBtn COORDINATES 0,20,0,0  ;
       BITMAP cImageDir+"new.bmp" COORDINATES 0,4,0,0 TOOLTIP "New"
   @ 46,3 OWNERBUTTON oBoton2 OF oPanel ID 109 ON CLICK {||oBoton2:disable()} ;
       SIZE 44,38 FLAT ;
       TEXT "Open" FONT oFontBtn COORDINATES 0,20,0,0 ;
       BITMAP cImageDir+"open.bmp" COORDINATES 0,4,0,0 TOOLTIP "Open" DISABLED

   @ 20,55 GET e1                       ;
        PICTURE "XXXXXXXXXXXXXXX"       ;
        SIZE 260, 25

   @ 20,80 GET e2  SIZE 260, 25

   @ 20,105 GET e3  SIZE 260, 25

   @ 20,130 GET e4                      ;
        PICTURE "@R 99.999.999/9999-99" ;
        SIZE 260, 25

   @ 20,155 GET e5                      ;
        PICTURE "@e 999,999,999.99"     ;
        SIZE 260, 25

   @ 20,190  BUTTONEX "Ok" SIZE 100, 32 ON CLICK {||( MsgInfo( e1 + chr(10) + chr(13) + ;
               Dtoc(e2) + chr(10) + chr(13) + ;
               Str(e3) + chr(10) + chr(13) +  ;
               e4 + chr(10) + chr(13) +       ;
               Str(e5) + chr(10) + chr(13)    ;
               ,"Results:" ) ,oChildWnd:Close() )}
   @ 180,190 BUTTONEX "Cancel" SIZE 100, 32 ON CLICK {||oChildWnd:Close()}

   oChildWnd:Activate()

Return Nil

Function MdiChildFromPrg( o )
Local cTitle := "MdiChild from prg", cText := "Input something"
Local oChildWnd, oFont := HFont():Add( "MS Sans Serif",0,-13 )
Local cRes, aCombo := { "First","Second" }, oEdit, vard := "Monday"
// Local aTabs := { "Monday","Tuesday","Wednesday","Thursday","Friday" }
Local oCmd1, oCmd2, oCmd3

   INIT WINDOW oChildWnd MDICHILD TITLE "Child";
   AT 210,10  SIZE 350,350                    ;
   FONT oFont                                 ;
   STYLE WS_CHILD+ WS_OVERLAPPEDWINDOW        ;
   ON EXIT {||MsgYesNo("Really exit ?")}

   @ 20,10 SAY cText SIZE 260, 22
   @ 20,35 EDITBOX oEdit CAPTION ""    ;
        STYLE WS_DLGFRAME              ;
        SIZE 260, 26 COLOR Vcolor("FF0000")
   oEdit:anchor := 11
   
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
        SIZE 120, 24

   @ 20,160 UPDOWN 10 RANGE -10,50 SIZE 50,32 STYLE WS_BORDER

   @ 160,150 TAB oTab ITEMS {} SIZE 130,66
   oTab:Anchor := 240
   BEGIN PAGE "Monday" OF oTab
      @ 20,34 GET vard SIZE 80,22 STYLE WS_BORDER
   END PAGE OF oTab
   BEGIN PAGE "Tuesday" OF oTab
      @ 20,34 EDITBOX "" SIZE 80,22 STYLE WS_BORDER
   END PAGE OF oTab

   @ 100,220 LINE LENGTH 100

   @ 20,240 BUTTONEX oCmd1 CAPTION "Ok" ID IDOK  ;
        SIZE 100, 32 COLOR Vcolor("FF0000")
   @ 140,240 BUTTONEX oCmd2 CAPTION "11"   ;
        SIZE 20, 32 ON CLICK {|o|CreateC(o)}
   @ 180,240 BUTTONEX oCmd3 CAPTION "Cancel" ID IDCANCEL  ;
        SIZE 100, 32
   oCmd1:Anchor := 4
   oCmd2:Anchor := 4
   oCmd3:Anchor := 4
   
   ACTIVATE WINDOW oChildWnd
 
Return Nil


function NoExit()
Local oDlg, oGet, vGet:="Dialog if no close in ENTER or EXIT"

   INIT DIALOG oDlg TITLE "No Exit Enter and Esc"     ;
   AT 190,10  SIZE 360,240   NOEXIT NOEXITESC
   @ 10, 10 GET oGet VAR vGET SIZE 200, 32
   @ 20,190  BUTTON "Ok" SIZE 100, 32;
   ON CLICK {|| oDlg:Close()} 
   oDlg:Activate()
Return Nil

function OpenAbout
Local oModDlg, oFontBtn, oFontDlg, oBrw
Local aSample := { {.t.,"Line 1",10}, {.t.,"Line 2",22}, {.f.,"Line 3",40} }
Local oBmp, oIcon := HIcon():AddFile("image\PIM.ICO")
Local oSay

   PREPARE FONT oFontDlg NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   PREPARE FONT oFontBtn NAME "MS Sans Serif" WIDTH 0 HEIGHT -13 ITALIC UNDERLINE

   INIT DIALOG oModDlg TITLE "About"     ;
   AT 190,10  SIZE 360,240               ;
   ICON oIcon                            ;
   ON EXIT {||oBmp2 := HBitmap():AddWindow(oBrw),.T.} ;
   FONT oFontDlg

   oModDlg:bActivate := {||MsgInfo("!!")}
      

   // @ 20,30 BITMAP "image\OPEN.BMP"
   // @ 20,20 ICON "image\PIM.ICO"
   @ 10,10 IMAGE "..\image\ASTRO.JPG" SIZE 50,50

   @ 20,60 SAY "Sample Dialog"        ;
       SIZE 130, 22 STYLE SS_CENTER  ;
        COLOR Vcolor("0000FF")

   @ 20,80 SAY "Written as a sample"  ;
        SIZE 130, 22 STYLE SS_CENTER
   @ 20,100 SAY "of Harbour GUI" ;
        SIZE 130, 22 STYLE SS_CENTER
   @ 20,120 SAY "application"    ;
        SIZE 130, 22 STYLE SS_CENTER

   @ 20,140 SAY "Hwgui Page"        ;
   LINK "http://kresin.belgorod.su/hwgui.html" ;
       SIZE 130, 22 STYLE SS_CENTER  ;
        COLOR Vcolor("0000FF") ;
        VISITCOLOR RGB(241,249,91)

   @ 20,160 SAY "Hwgui international Forum"        ;
   LINK "http://br.groups.yahoo.com/group/hwguibr" ;
       SIZE 200, 22 STYLE SS_CENTER  ;
        COLOR Vcolor("0000FF") ;
        VISITCOLOR RGB(241,249,91)


   @ 160,30 BROWSE oBrw ARRAY SIZE 180,110 ;
        STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   @ 80,180 OWNERBUTTON ON CLICK {|| EndDialog()}        ;
       SIZE 180,35 FLAT                                  ;
       TEXT "Close" COLOR Vcolor("0000FF") FONT oFontBtn ;
       BITMAP cImageDir+"door.bmp" COORDINATES 40,10,0,0
       // 

   CreateArList( oBrw,aSample )
   oBrw:bColorSel    := 12507070  // 15149157449

   oBmp := HBitmap():AddStandard( OBM_LFARROWI )
   oBrw:aColumns[1]:aBitmaps := { ;
      { {|l|l}, oBmp } ;
   }
   oBrw:aColumns[2]:length := 6
   oBrw:aColumns[3]:length := 4
   oBrw:bKeyDown := {|o,key|BrwKey(o,key)}

   ACTIVATE DIALOG oModDlg
   oIcon:Release()

Return Nil

Static Function About2()

   IF oBmp2 == Nil
      Return
   ENDIF

   INIT DIALOG oModDlg TITLE "About2"   ;
   AT 190,10  SIZE 360,240

   @ 10, 10 BITMAP oBmp2

   ACTIVATE DIALOG oModDlg

Return Nil

Static Function BrwKey( oBrw, key )
   IF key == 32
      oBrw:aArray[ oBrw:nCurrent,1 ] := !oBrw:aArray[ oBrw:nCurrent,1 ]
      oBrw:RefreshLine()
   ENDIF
Return .T.

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

Function PrnTest
Local oPrinter, oFont

   INIT PRINTER oPrinter
   IF oPrinter == Nil
      Return Nil
   ENDIF

   oFont := oPrinter:AddFont( "Times New Roman",10 )

   oPrinter:StartDoc( .T. )
   oPrinter:StartPage()
   oPrinter:SetFont( oFont )
   oPrinter:Box( 5,5,oPrinter:nWidth-5,oPrinter:nHeight-5 )
   oPrinter:SetTextColor( 2788990 )
   oPrinter:Say( "Windows printing first sample !", 50,10,165,26,DT_CENTER,oFont  )
   oPrinter:Line( 45,30,170,30 )
   oPrinter:Line( 45,5,45,30 )
   oPrinter:Line( 170,5,170,30 )
   oPrinter:Say( "----------", 50,120,150,132,DT_CENTER  )
   oPrinter:Box( 50,134,160,146 )
   oPrinter:Say( "End Of Report", 50,135,160,146,DT_CENTER  )
   oPrinter:EndPage()
   oPrinter:StartPage()
   oPrinter:SetFont( oFont )
   oPrinter:Box( 5,5,oPrinter:nWidth-5,oPrinter:nHeight-5 )
   oPrinter:SetTextColor( 2755990 )
   oPrinter:Say( "Printing second sample !", 50,10,185,26,DT_CENTER,oFont  )
   oPrinter:Line( 45,30,170,30 )
   oPrinter:Line( 45,5,45,30 )
   oPrinter:Line( 170,5,170,30 )
   oPrinter:Say( "----------", 50,120,150,132,DT_CENTER  )
   oPrinter:Box( 50,134,160,146 )
   oPrinter:Say( "End Of Report", 50,135,160,146,DT_CENTER  )
   oPrinter:EndPage()
   oPrinter:EndDoc()
   oPrinter:Preview()
   oPrinter:End()

Return Nil

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
        SIZE 120, 24

   @ 20,160 UPDOWN 10 RANGE -10,50 SIZE 50,32 STYLE WS_BORDER

   @ 160,150 TAB oTab ITEMS {} SIZE 130,66
   BEGIN PAGE "Monday" OF oTab
      @ 20,34 GET vard SIZE 80,22 STYLE WS_BORDER
   END PAGE OF oTab
   BEGIN PAGE "Tuesday" OF oTab
      @ 20,34 EDITBOX "" SIZE 80,22 STYLE WS_BORDER
   END PAGE OF oTab

   @ 100,220 LINE LENGTH 100

   @ 20,240 BUTTON "Ok" OF oModDlg ID IDOK  ;
        SIZE 100, 32 COLOR Vcolor("FF0000")
   @ 140,240 BUTTON "11" OF oModDlg  ;
        SIZE 20, 32 ON CLICK {|o|CreateC(o)}
   @ 180,240 BUTTON "Cancel" OF oModDlg ID IDCANCEL  ;
        SIZE 100, 32

   ACTIVATE DIALOG oModDlg
   oFont:Release()

Return Nil

#define DTM_SETFORMAT       4101
Static Function CreateC( oDlg )
Static lFirst := .F., o
   IF !lFirst
      @ 50,200 DATEPICKER o SIZE 80, 24
      lFirst := .T.
   ENDIF
   SendMessage( o:handle,DTM_SETFORMAT,0,"dd':'MM':'yyyy" )
Return Nil

Function Sendemail(endereco)
ShellExecute("rundll32.exe", "open", ;
            "url.dll,FileProtocolHandler " + ;
            "mailto:"+endereco+"?cc=&bcc=" + ;
            "&subject=Ref%20:" + ;
            "&body=This%20is%20test%20.", , 1)

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

FUNCTION ActiveTopMost( nHandle, lActive )
    
    if lActive
       lSucess := SetTopMost(nHandle)    // Set TopMost
    else   
       lSucess := RemoveTopMost(nHandle) // Remove TopMost
    endif
    
    RETURN lSucess


Function TestProgres()
Local oDlg,ostatus,oBar
Local cRes, aCombo := { "First","Second" }
Private oProg

INIT DIALOG oDlg TITLE "Progress Bar"    ;
   AT 190,10  SIZE 360,240               

@ 10, 10 PROGRESSBAR oProg  ;
             OF oDlg        ;
             SIZE 200,25    ;
             BARWIDTH 10    ;
             QUANTITY 1000    
ADD STATUS oStatus TO oDlg PARTS 400
oBar   := HProgressBar():New(ostatus,,0,2,200,20,200,1000 ,rgb(12,143,243),rgb(243,132,143))
oCombo := HComboBox():New(ostatus,,,,65536,0,2,200,20,aCombo,,,,,,,.F.,.F.,,,)
@ 10, 60  BUTTON "Test" SIZE 100, 32 ON CLICK {|| MudeProg(oBar) }
   
   oDlg:Activate() 

Function MudeProg(ostatus)
Local ct:=1
Do while ct<1001
   oProg:Step()
   ostatus:step()
   ++ct
EndDo
Return Nil


function RRectangle()
Local oDlg, oR1, oR2, oR3   

INIT DIALOG oDlg TITLE "Sample HRect"    ;
   AT 190,10  SIZE 600,400               
  
       @ 230, 10,400,100 RECT oR1 of oDlg PRESS
       @  10, 10,200,100 RECT oR2 of oDlg RECT_STYLE 3
       @  10,130,100,230 RECT oR3 of oDlg PRESS RECT_STYLE 2

       Rect(oDlg, 10, 250, 590, 320, , 1 )

   oDlg:Activate()

return nil

