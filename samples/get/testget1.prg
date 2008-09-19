#include "windows.ch"
#include "guilib.ch"

Function Main
Local oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200,0 SIZE 600,150

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION EndWindow()
      MENUITEM "&Get a value" ACTION DlgGet()
   ENDMENU

   ACTIVATE WINDOW oMainWindow
Return Nil

Function DlgGet
Local oModDlg, oFont := HFont():Add( "MS Sans Serif",0,-13 )
Local cRes, aCombo := { "First","Second","laranja","banana","pera","uva" }
Local oGet
Local e1 := "Dialog from prg", c1 := .F., c2 := .T., r1 := 2, cm := 1,o,o1,o2
Local upd := 12, d1 := Date()+1
Local h  := hbitmap():addFile("..\image\open.bmp")
Local h1 := hbitmap():addFile("..\image\exit.bmp")



   INIT DIALOG oModDlg TITLE "Get a value"  ;
   AT 210,10  SIZE 500,300                  ;
   FONT oFont on init  {||o:setfocus()}

   @ 20,10 SAY "Input something:" SIZE 260, 22
   @ 20,35 GET oGet VAR e1  ;
        STYLE WS_DLGFRAME   ;
        SIZE 260, 26 COLOR Vcolor("FF0000")

   @ 20,70 GET CHECKBOX c1 CAPTION "Check 1" SIZE 90, 20
   @ 20,95 GET CHECKBOX c2 CAPTION "Check 2" SIZE 90, 20 COLOR Vcolor("0000FF")

   @ 160,70 GROUPBOX "RadioGroup" SIZE 130, 75

   GET RADIOGROUP r1
   @ 180,90 RADIOBUTTON "Radio 1"  ;
        SIZE 90, 20 ON CLICK {||oGet:SetColor(Vcolor("0000FF"),,.T.)}
   @ 180,115 RADIOBUTTON "Radio 2" ;
        SIZE 90, 20 ON CLICK {||oGet:SetColor(Vcolor("FF0000"),,.T.)}
   END RADIOGROUP

   @ 20,120 GET COMBOBOXEX cm ITEMS aCombo SIZE 100, 150 CHECK {1,3,5}

   @ 20,170 GET UPDOWN upd RANGE 0,80 SIZE 50,30
   @ 160,170 GET DATEPICKER d1 SIZE 80, 20

   @ 20,200 OWNERBUTTON ;
       SIZE 32,26 FLAT ;
       BITMAP "..\image\new.bmp" COORDINATES 0,4,0,0 TOOLTIP "New MDI child window"

   @ 20,240 BUTTONEX o1 caption "Cancel" ID IDCANCEL  SIZE 100, 32     bitmap h:handle  style WS_TABSTOP

   @ 180,240 BUTTONEX o  caption "TESt" ID IDCANCEL+10  SIZE 100, 32 ICON h1:handle style WS_TABSTOP BSTYLE ST_ALIGN_HORIZ
   @ 340,240 BUTTONEX o2 caption "Ok"     ID IDOK  SIZE 100, 32        bitmap h:handle  style WS_TABSTOP BSTYLE ST_ALIGN_HORIZ_RIGHT

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

function bother(ob,m,w,l,o,o1)
if m == WM_MOUSEMOVE
   o:cancelhover()
   o1:cancelhover()
  return 0
endif
return -1

