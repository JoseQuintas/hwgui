//ANNOUNCE HB_GT_DEFAULT_GUI
//REQUEST HB_GT_GUI
#include "windows.ch"
#include "guilib.ch"

Function Main
Local oMainWindow
HWG_INITCOMMONCONTROLSEX()
   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200,0 SIZE 400,150

   MENU of  oMainWindow
      MENUITEM "&Exit" ACTION EndWindow()
      MENUITEM "&Get a value" ACTION DlgGet()
   ENDMENU

   ACTIVATE WINDOW oMainWindow
Return Nil

Function DlgGet
Local oModDlg, oFont := HFont():Add( "MS Sans Serif",0,-13 )
Local cRes, aCombo := { "First","Second" }
Local oGet
Local e1 := "Dialog from prg", c1 := .F., c2 := .T., r1 := 2, cm := 1
Local upd := 12, d1 := Date()+1
//Local aitem :={{2,701,0x04,0x0000,0,"teste1",{|x,y|DlgGet()}},{3,702,0x04,0x0000,0,"teste2",},{-1,702,0x04,0x0000,0,"teste3",}}
Local otool
Local omenu,omenu1
Local amenu
   INIT DIALOG oModDlg TITLE "Get a value"  ;
   AT 210,10  SIZE 300,300                  ;
   FONT oFont // on init  {||CreateBar(oModDlg,@otool)}

Create menubar aMenu
MENUBARITEM  amenu CAPTION "teste" ON 904 ACTION {||MsgYesNo("Really want to quit ?")}
MENUBARITEM  amenu CAPTION "teste1" ON 905 ACTION {||.t.}
MENUBARITEM  amenu CAPTION "teste2" ON 906 ACTION {||.t.}


   @ 0,0 toolbar oTool of oModDlg size oModDlg:nWidth,40 ID 700
   TOOLBUTTON  otool ;
          ID 701 ;
           BITMAP 2;
           STYLE 0+BTNS_DROPDOWN ;
           STATE 4;
           TEXT "teste1"  ;
           TOOLTIP "ola" ;
           menu amenu;
           ON CLICK {|x,y|DlgGet()}

   TOOLBUTTON  otool ;
          ID 702 ;
           BITMAP 3;
           STYLE 0 ;
           STATE 4;
           TEXT "teste2"  ;
           TOOLTIP "ola2" ;
           ON CLICK {|x,y|DlgGet()}

   TOOLBUTTON  otool ;
          ID 703 ;
           BITMAP 2;
           STYLE 0 ;
           STATE 4;
           TEXT ""  ;
           TOOLTIP "ola3" ;
           ON CLICK {|x,y|DlgGet()}



   @ 20,50 SAY "Input something:" SIZE 260, 22
   @ 20,75 GET oGet VAR e1  ;
        STYLE WS_DLGFRAME   ;
        SIZE 260, 26 COLOR Vcolor("FF0000")

   @ 20,110 GET CHECKBOX c1 CAPTION "Check 1" SIZE 90, 20
   @ 20,135 GET CHECKBOX c2 CAPTION "Check 2" SIZE 90, 20 COLOR Vcolor("0000FF")

   @ 160,110 GROUPBOX "RadioGroup" SIZE 130, 75

   GET RADIOGROUP r1
   @ 180,130 RADIOBUTTON "Radio 1"  ;
        SIZE 90, 20 ON CLICK {||oGet:SetColor(Vcolor("0000FF"),,.T.)}
   @ 180,155 RADIOBUTTON "Radio 2" ;
        SIZE 90, 20 ON CLICK {||oGet:SetColor(Vcolor("FF0000"),,.T.)}
   END RADIOGROUP

   @ 20,160 GET COMBOBOX cm ITEMS aCombo SIZE 100, 24

   @ 20,200 GET UPDOWN upd RANGE 0,80 SIZE 50,24
   @ 160,200 GET DATEPICKER d1 SIZE 90, 24

   @ 20,240 BUTTON "Ok" ID IDOK  SIZE 100, 32
   @ 180,240 BUTTON "Cancel" ID IDCANCEL  SIZE 100, 32

   ACTIVATE DIALOG oModDlg
   oFont:Release()

   IF oModDlg:lResult
      MsgInfo( e1 + chr(10) + chr(13) +                               ;
               "Check1 - " + Iif(c1,"On","Off") + chr(10) + chr(13) + ;
               "Check2 - " + Iif(c2,"On","Off") + chr(10) + chr(13) + ;
               "Radio: " + Str(r1,1) + chr(10) + chr(13) +            ;
               "Combo: " + aCombo[cm] + chr(10) + chr(13) +           ;
               "UpDown: "+Str(upd) + chr(10) + chr(13) +              ;
               "DatePicker: "+Dtoc(d1)                                ;
               ,"Results:" )
   ENDIF
Return Nil
PROC HB_GTSYS; RETURN
PROC HB_GT_DEFAULT_GUI; RETURN
function CreateBar(oModDlg,otool)
//Local hTool
//Local aItem := {{-1,701,0x04,0x0000,0,"teste1"},{-1,702,0x04,0x0000,0,"teste2"},{-1,703,0x04,0x0000,0,"teste3"}}
Local aitem :={{2,701,0x04,0x0000,0,"teste1",{|x,y|DlgGet()},"teste"},{3,702,0x04,0x0000,0,"teste2",,"rtrt"},{-1,702,0x04,0x0000,0,"teste3",,"teste222"}}
//Local pItem
//
//  hTool := CREATETOOLBAR(oModDlg:handle,700,0,0,0,50,100)
// //  pItem :=  TOOLBARADDBUTTONS(hTool,aTool,len(aTool))
 //
//   otool:=Htoolbar():New(,,,0,0,50,100,"Input something:",,,,,,,,.F., aitem)
//   oTool:oParent:AddEvent(BN_CLICKED,701,{|x,y|DlgGet()})
/*   @ 0,0 toolbar oTool of oModDlg size 50,100 ID 700 items aItem
   
   TOOLBUTTON  otool ;
          ID 701 ;
           BITMAP 2;
           STYLE 0+BTNS_DROPDOWN ;
           STATE 4;
           TEXT "teste1"  ;
           TOOLTIP "ola" ;
           ON CLICK {|x,y|DlgGet()}

   TOOLBUTTON  otool ;
          ID 702 ;
           BITMAP 3;
           STYLE 0 ;
           STATE 4;
           TEXT "teste2"  ;
           TOOLTIP "ola2" ;
           ON CLICK {|x,y|DlgGet()}

   TOOLBUTTON  otool ;
          ID 703 ;
           BITMAP 2;
           STYLE 0 ;
           STATE 4;
           TEXT ""  ;
           TOOLTIP "ola3" ;
           ON CLICK {|x,y|DlgGet()}
*/
return nil

#include "hbclass.ch"
class mymenu
data handle
method new(c) inline ::handle :=c,self
endclass

