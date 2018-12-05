#include "windows.ch"
#include "guilib.ch"

Function Main
Local oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200,0 SIZE 400,150

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Dialog" ACTION DlgGet()
   ENDMENU

   ACTIVATE WINDOW oMainWindow
Return Nil

Function DlgGet
Local oModDlg, oBrw1, oBrw2
Local aSample1 := { {"Alex",17,2500}, {"Victor",42,2200}, {"John",31,1800}, ;
   {"Sebastian",35,2000}, {"Mike",54,2600}, {"Sardanapal",22,2350}, {"Sergey",30,2800}, {"Petr",42,2450} }
Local aSample2 := { {.t.,"Line 1",10}, {.t.,"Line 2",22}, {.f.,"Line 3",40} }

   INIT DIALOG oModDlg TITLE "About" AT 190,10 SIZE 600,320

   @ 20,16 BROWSE oBrw1 ARRAY SIZE 280,220 ;
        STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   @ 310,16 BROWSE oBrw2 ARRAY SIZE 280,220 ;
        STYLE WS_BORDER + WS_VSCROLL + WS_HSCROLL

   oBrw1:aArray := aSample1
   oBrw1:AddColumn( HColumn():New( "Name",{|v,o|o:aArray[o:nCurrent,1]},"C",12,0,.F.,DT_CENTER ) )
   oBrw1:AddColumn( HColumn():New( "Age",{|v,o|o:aArray[o:nCurrent,2]},"N",6,0,.T.,DT_CENTER,DT_RIGHT ) )
   oBrw1:AddColumn( HColumn():New( "Koef",{|v,o|o:aArray[o:nCurrent,3]},"N",6,0,.F.,DT_CENTER,DT_RIGHT ) )
   oBrw1:aColumns[2]:footing := "Age"
   oBrw1:aColumns[2]:lResizable := .F.

   hwg_CREATEARLIST( oBrw2,aSample2 )
   oBmp := HBitmap():AddStandard( OBM_CHECK )
   oBrw2:aColumns[1]:aBitmaps := { { {|l|l}, oBmp } }
   oBrw2:aColumns[2]:length := 6
   oBrw2:aColumns[3]:length := 4
   oBrw2:bKeyDown := {|o,key|BrwKey(o,key)}
   oBrw2:bcolorSel := oBrw2:htbColor := 0xeeeeee
   oBrw2:tcolorSel := 0xff0000

   @ 210,260 OWNERBUTTON ON CLICK {|| hwg_EndDialog()} ;
       SIZE 180,36 FLAT                                ;
       TEXT "Close" COLOR hwg_ColorC2N("0000FF")

   ACTIVATE DIALOG oModDlg
Return Nil

Static Function BrwKey( oBrw, key )
   IF key == 32
      oBrw:aArray[ oBrw:nCurrent,1 ] := !oBrw:aArray[ oBrw:nCurrent,1 ]
      oBrw:RefreshLine()
   ENDIF
Return .T.
