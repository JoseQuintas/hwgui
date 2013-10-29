/*
 *
 * Demo for Edit using command NOEXIT
 *
 * HwGUI by Alexander Kresin
 *
 * Copyright (c) 
 * Data 01/07/2003 - Sandro Freire <sandrorrfreire@yahoo.com.br>
 *
 */

#include "windows.ch"
#include "guilib.ch"
 
*---------------------------------------------------------------------------------------
Function Main
*---------------------------------------------------------------------------------------
Local oFontBtn
Local oFont := Nil
Local nColor, oSplah
Private Form_Main

Public oDir := "\"+Curdir()+"\"

SET DELETE ON
SET DATE BRIT
SET CENT ON

   PREPARE FONT oFontBtn NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

   INIT WINDOW Form_Main MAIN TITLE "HwGUI Harbour Win32 Gui"


   MENU OF Form_Main
      MENU TITLE "&Demo"
         MENUITEM "&Demo for TAB DBF " ID 303 ACTION Cadastro()
         SEPARATOR
         MENUITEM "&Exit" ACTION {||dbCloseAll(), hwg_EndWindow()}
      ENDMENU                                                                                            


      MENU TITLE "&Help"
         MENUITEM "&As" ACTION hwg_Msginfo("HwGUI Harbour Win32 GUI","Copyright (c) Alexander Kresin")
      ENDMENU
   ENDMENU

   Form_Main:Activate()

return nil


*---------------------------------------------------------------------------------------
Function Cadastro()   
*---------------------------------------------------------------------------------------
Local Tel_Ferramentas, oPanel, oFontBtn, Titulo:="Tab Forneced"
Private Gt_Cod, Gt_Name, Gt_Adress, Gt_Fone, Gt_e_Mail
Private oCod, oName, oAdress, oFone, oe_Mail //Declaracao das variaveis de tabela
Private oOper:=1
Private oBotNew, oBotEdit,oBotRet, oBotNext, oBotSave, oBottop, oBotBott, oBotDelete, oBotClose, oBotPrint

   PREPARE FONT oFontBtn NAME "Arial" WIDTH 0 HEIGHT -12

   INIT DIALOG Tel_Ferramentas CLIPPER NOEXIT TITLE Titulo SIZE 530, 320 Font oFontBtn

   OpenDbf()

   Select TabDbf
   Set Order to 1
   Go Top
   GetVars() //Inicializa as variaveis

   CreateGets()


    @ 2,3 OWNERBUTTON oBotNew OF Tel_Ferramentas  ON CLICK {|| CreateVariable(), CloseBotons(), Gt_Cod:Setfocus()  } ;
       SIZE 44,38 FLAT ;
       TEXT "New"

   @ 46,3 OWNERBUTTON oBotEdit OF Tel_Ferramentas ON CLICK {||EditRecord()} ;
       SIZE 44,38 FLAT ;
       TEXT "Edit"

   @ 89,3 OWNERBUTTON oBotSave OF Tel_Ferramentas ON CLICK {||OpenBotons(),SaveTab()} ;
       SIZE 44,38 FLAT ;
       TEXT "Save"

   @132,3 OWNERBUTTON oBotRet OF Tel_Ferramentas  ON CLICK {||SkipTab(1)} ;
       SIZE 44,38 FLAT ;
       TEXT "<--"

   @175,3 OWNERBUTTON oBotNext OF Tel_Ferramentas  ON CLICK {||SkipTab(2)} ;
       SIZE 44,38 FLAT ;
       TEXT "-->"

   @218,3 OWNERBUTTON oBotTop OF Tel_Ferramentas  ON CLICK {||SkipTab(3)} ;
       SIZE 44,38 FLAT ;
       TEXT "<-|"

   @261,3 OWNERBUTTON oBotBott OF Tel_Ferramentas  ON CLICK {||SkipTab(4)} ;
       SIZE 44,38 FLAT ;
       TEXT "|->"

   @304,3 OWNERBUTTON oBotprint OF Tel_Ferramentas  ON CLICK {||hwg_Msginfo("In development")} ;
       SIZE 44,38 FLAT ;
       TEXT "Print"

   @347,3 OWNERBUTTON oBotDelete OF Tel_Ferramentas ON CLICK {||DeleteRecord()} ;
       SIZE 44,38 FLAT ;
       TEXT "Delete"

   @390,3 OWNERBUTTON oBotClose OF Tel_Ferramentas  ON CLICK {||hwg_EndDialog()} ;
       SIZE 44,38 FLAT ;
       TEXT "Close"

   
   Tel_Ferramentas:Activate()

Return Nil
*---------------------------------------------------------------------------------------
Function OpenBotons
*---------------------------------------------------------------------------------------
oBotNew:Enable()
oBotEdit:Enable()
oBotRet:Enable()
oBotNext:Enable()
oBotSave:Disable()
oBottop:Enable()
oBotBott:Enable()
oBotDelete:Enable()
oBotClose:Enable()
oBotPrint:Enable()
Return Nil
*---------------------------------------------------------------------------------------
Function CloseBotons
*---------------------------------------------------------------------------------------
oBotNew:Disable()
oBotEdit:Disable()
oBotRet:Disable()
oBotNext:Disable()
oBotSave:Enable()
oBottop:Disable()
oBotBott:Disable()
oBotDelete:Disable()
oBotClose:Enable()
oBotPrint:Disable()
Return Nil
*---------------------------------------------------------------------------------------
Function CreateGets()
*---------------------------------------------------------------------------------------

@ 2, 60 Say "Cod"  SIZE 40,20
@65, 60 Get Gt_Cod VAR oCod PICTURE "999" STYLE WS_DISABLED  SIZE 100, 20

@ 2,85 Say "Name" SIZE 50, 20
@65,85 Get Gt_Name VAR oName  PICTURE REPLICATE("X",50)  STYLE WS_DISABLED  SIZE 310, 20

@ 2,110 Say "Adress" SIZE 50, 20
@65,110 Get Gt_Adress VAR oAdress  PICTURE REPLICATE("X",50) STYLE WS_DISABLED SIZE 310, 20

@ 2,135 Say "Fone" SIZE 50, 20
@65,135 Get Gt_Fone VAR oFone PICTURE REPLICATE("X",50) STYLE WS_DISABLED  SIZE 310, 20

@ 2,160 Say "e_Mail" SIZE 50, 20
@65,160 Get Gt_e_Mail VAR oe_Mail PICTURE REPLICATE("X",30)  STYLE WS_DISABLED  SIZE 190, 20

Return Nil

 
*---------------------------------------------------------------------------------------
Function EditRecord()
*---------------------------------------------------------------------------------------
CloseBotons()
OpenGets()
Gt_Name:Setfocus()
Return Nil

*---------------------------------------------------------------------------------------
Function CreateVariable()
*---------------------------------------------------------------------------------------

oCod:=SPACE(5)
oName:=SPACE(50)
oAdress:=SPACE(50)
oFone:=SPACE(50)
oe_Mail:=SPACE(30)
GetRefresh()
OpenGets()
oOper:=1 //Operacao para Inclusao
Return Nil

*---------------------------------------------------------------------------------------
Function GetRefresh()
*---------------------------------------------------------------------------------------

Local oDlg:=hwg_GetModalHandle()
Gt_Cod:Refresh()
Gt_Name:Refresh()
Gt_Adress:Refresh()
Gt_Fone:Refresh()
Gt_e_Mail:Refresh()
Return Nil

*---------------------------------------------------------------------------------------
Function GetVars()
*---------------------------------------------------------------------------------------

oCod   :=TabDbf->Cod
oName    :=TabDbf->Name
oAdress :=TabDbf->Adress
oFone :=TabDbf->Fone
oe_Mail :=TabDbf->e_Mail
Return Nil

*---------------------------------------------------------------------------------------
Function SaveTab()
*---------------------------------------------------------------------------------------

if oOper=1
   Select TabDbf
   oCod:=StrZero(val(oCod),3)
   Seek oCod
   If Found()
      hwg_Msginfo("Cod."+oCod+" no valid...","Mensagem")
      Return Nil
   Endif
   Append Blank
   TabDbf->Cod:=oCod
   TabDbf->Name:=oName
   TabDbf->Adress:=oAdress
   TabDbf->Fone:=oFone
   TabDbf->e_Mail:=oe_Mail
   Unlock
Else
   RLock()
   TabDbf->Name:=oName
   TabDbf->Adress:=oAdress
   TabDbf->Fone:=oFone
   TabDbf->e_Mail:=oe_Mail
   Unlock
EndIf
CloseGets()
oOper:=1
Return Nil

 
*---------------------------------------------------------------------------------------
Function SkipTab(oSalto)
*---------------------------------------------------------------------------------------
CloseGets()
Select TabDbf
If oSalto=1
   Skip -1
Elseif oSalto=2
   Skip
Elseif oSalto=3
   Go Top
Else
   Go Bottom
Endif 
GetVars()
GetRefresh()
Return Nil

*---------------------------------------------------------------------------------------
Function DeleteRecord()
*---------------------------------------------------------------------------------------

Select TabDbf
Seek oCod
If Found()
   If hwg_Msgyesno("Delete Cod "+oCod ,"Mensagem")
      RLock()
      Delete
      Unlock
   Endif
EndIf
Go Bottom
GetVars()
GetRefresh()
Return Nil

*---------------------------------------------------------------------------------------
Function OpenDbf()
*---------------------------------------------------------------------------------------

Local vTab:={}
Local vArq:=oDir+"FORNECED.DBF"
Local vInd1:=oDir+"FORNECED.NTX"

If !File(vArq)
   AADD(vTab,{"Cod    ", "C", 3, 0 })
   AADD(vTab,{"Name     ", "C",50, 0 })
   AADD(vTab,{"Adress  ", "C",50, 0 })
   AADD(vTab,{"Fone  ", "C",50, 0 })
   AADD(vTab,{"e_Mail  ", "C",30, 0 })
   dBCreate(vArq, vTab)
EndIf
Use (vArq) Shared Alias TabDbf
If !File(vInd1)
   fLock()
   Index on Cod   to (vInd1)
   Unlock
Else
   Set Index to (vInd1)
EndIf
Return Nil

*---------------------------------------------------------------------------------------
Function OpenGets
*---------------------------------------------------------------------------------------
Gt_Cod:Enable()
Gt_Name:Enable()
Gt_Adress:Enable()
Gt_Fone:Enable()
Gt_e_Mail:Enable()
Return Nil

*---------------------------------------------------------------------------------------
Function CloseGets
*---------------------------------------------------------------------------------------
Gt_Cod:Disable()
Gt_Name:Disable()
Gt_Adress:Disable()
Gt_Fone:Disable()
Gt_e_Mail:Disable()
Return Nil
 
