#include "hwgui.ch"
#include "tab.rh"
func main
Local oDlg1,oDlg2,oDlg3,oTab
Local aDlg1, aDlg2, aCombo := { "Aaaa","Bbbb" }
Local oBrw1, oBrw2
Local aSample1 := { {"Alex",17}, {"Victor",42}, {"John",31} }
Local aSample2 := { {"Line 1",10}, {"Line 2",22}, {"Line 3",40} }
Local e1 := "Xxxx"
Local e2 := "Xxxx"
Local e3 := "Xxxx"

init dialog oDlg1 from resource DIALOG_1 clipper NOEXIT NOEXITESC  on init {|| buildtabPages(oTab,{adlg1,adlg2},{"pagina1","pagina2"})}

/*
aDlg1:oParent:=oTab,aDlg2:oParent:=oTab,;
aDlg1:Activate(.t.),      aDlg2:Activate(.t.), ;
aDlg2:hide(),    oTab:StartPage( "pagina1",aDlg1 ),    oTab:EndPage(), ;
oTab:StartPage( "pagina2",aDlg2 ),    oTab:EndPage(),otab:changepage(1)

}
*/

REDEFINE TAB oTab ID IDC_1

oDlg1:lRouteCommand := .T.
   INIT DIALOG aDlg1 FROM RESOURCE  PAGE_1 CLIPPER NOEXIT NOEXITESC ON EXIT {||hwg_Msginfo("Exit"),.T.}
   REDEFINE GET e1 ID 103
   REDEFINE GET e2 ID 104
   REDEFINE GET e3 ID 105

   INIT DIALOG aDlg2 FROM RESOURCE  PAGE_2 CLIPPER NOEXIT NOEXITESC ON EXIT {||hwg_Msginfo("Exit"),.T.}
   REDEFINE COMBOBOX aCombo ID 101
   REDEFINE BROWSE oBrw1 ARRAY ID 104
   REDEFINE BROWSE oBrw2 ARRAY ID 105
 
   hwg_CREATEARLIST( oBrw1,aSample1 )
   hwg_CREATEARLIST( oBrw2,aSample2 )
  activate dialog oDlg1
return nil




function buildtabPages(oTab,aPage,aTitle)

Local n
for each n in aPage
   n:oParent := oTab
   n:activate(.t.)
   oTab:startpage(aTitle[hb_enumindex()],n)
   otab:endpage()
   n:oParent := nil
next
return .t.
