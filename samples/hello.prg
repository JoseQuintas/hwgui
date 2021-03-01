#include "windows.ch"
#include "guilib.ch"

Function Main
Local oMainWindow, oBtn, aCombo := {"First","Second" }, cTool := "Example", oFont
Local aTabs := { "A","B","C","D","E","F","G","H","I","J","K","L","M","N" }, oTab
Local acho := { {"First item",180}, {"Second item",200} }
Local oEdit, oGetTab, oTree, oItem
Private aGetsTab := { "","","","","","","","","","","","","","" }

   // PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17 CHARSET 4

   INIT WINDOW oMainWindow MAIN TITLE "Example"  ;
     SYSCOLOR COLOR_3DLIGHT+1                    ;
     AT 200,0 SIZE 420,300                       ;
     FONT oFont                                  ;
     ON EXIT {||hwg_Msgyesno("Really want to quit ?")}

   @ 20,10 RICHEDIT oEdit TEXT "Hello, world !"  SIZE 200,30

   hwg_Re_setcharformat( oEdit:handle, { { 1,6,,,,.T. }, { 8,13,255,,,,,.T. } } )

   @ 270,10 COMBOBOX aCombo  SIZE 100, 150 TOOLTIP "Combobox"

   @ 20,50 LINE LENGTH 100

   @ 20,60 TAB oTab ITEMS aTabs SIZE 140,100      ;
         STYLE TCS_FIXEDWIDTH+TCS_FORCELABELLEFT  ;
         ON CHANGE {|o,n|ChangeTab(o,oGetTab,n)}
   // @ 20,60 TAB oTab ITEMS aTabs SIZE 90,100 STYLE TCS_FIXEDWIDTH+TCS_VERTICAL+TCS_FORCELABELLEFT+WS_CLIPSIBLINGS  // +TCS_RIGHT
   hwg_Settabsize( oTab:handle,20,20 )
   @ 10,30 RICHEDIT oGetTab TEXT "" OF oTab SIZE 120,60 ;
          STYLE ES_MULTILINE

   @ 180,60 SAY "" SIZE 70,22 STYLE WS_BORDER BACKCOLOR 12507070

   @ 270,60 TREE oTree SIZE 140,100 EDITABLE

   oTree:AddNode( "First" )
   oTree:AddNode( "Second" )
   oItem := oTree:AddNode( "Third" )
   oItem:AddNode( "Third-1" )
   oTree:AddNode( "Forth" )


   @ 100,180 BUTTON "Close"  SIZE 150,30  ON CLICK {||hwg_EndWindow()} ON SIZE ANCHOR_BOTTOMABS

   MENU OF oMainWindow
      MENU TITLE "File"
         MENUITEM "Ps" ACTION Ps1(oMainWindow)
         SEPARATOR
         MENUITEM "YYYYY" ACTION hwg_MsgGet( "Example","Input anything")
      ENDMENU
      MENU TITLE "Help"
         MENUITEM "About" ACTION hwg_Msginfo("About")
         MENUITEM "Info" ACTION hwg_Msgtemp("")
      ENDMENU
      MENU TITLE "Third"
         MENUITEM "Wchoice" ACTION hwg_WChoice( acho,"Select",,,,,15132390,,hwg_ColorC2N( "008000" ) )
         MENUITEM "hwg_Selectfolder" ACTION hwg_Msginfo( hwg_Selectfolder("!!!") )
         MENU TITLE "Submenu"
            MENUITEM "hwg_Shellexecute" ACTION (hwg_Shellexecute("d:\temp\podst.doc"),hwg_Msginfo(str(oMainWindow:handle)))
            MENUITEM "S2" ACTION hwg_Msgstop("S2")
         ENDMENU
      ENDMENU
   ENDMENU

/*   
   aMenu := { ;
     { { { {||hwg_Msginfo("Xxxx")},"XXXXX",130 }, ;
         { ,,131 }, ;
         { {||hwg_Msginfo("Yyyy")},"YYYYY",132 } ;
       },"File",120 }, ;
     { {||hwg_Msginfo("Help")},"Help",121 } ;
   }
   hwg_BuildMenu( aMenu,hWnd,aMainWindow )
*/

   ACTIVATE WINDOW oMainWindow

Return nil

Static Function ChangeTab( oWnd,oGet,n )
Static lastTab := 1
   aGetsTab[lastTab] := hwg_Getedittext( oGet:oParent:handle,oGet:id )
   hwg_Setdlgitemtext( oGet:oParent:handle,oGet:id,aGetsTab[n] )
   lastTab := n
Return Nil

Function PS1( oWnd )
Local oDlg1, oDlg2

   INIT DIALOG oDlg1 TITLE "PAGE_1" STYLE WS_CHILD + WS_VISIBLE + WS_BORDER
   @ 20,15 EDITBOX "" SIZE 160, 26 STYLE WS_BORDER
   @ 10,50 LINE  LENGTH 200

   INIT DIALOG oDlg2 TITLE "PAGE_2" STYLE WS_CHILD + WS_VISIBLE + WS_BORDER
   @ 20,35 EDITBOX "" SIZE 160, 26 STYLE WS_BORDER

   hwg_PropertySheet( hwg_Getactivewindow(), { oDlg1, oDlg2 }, "Sheet Example",210,10,300,300 )

Return
