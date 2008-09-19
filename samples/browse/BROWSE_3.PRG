/*
 * Demo by HwGUI Alexander Kresin
 *
 * Copyright (c)  Sandro R R Freire <sandro@lumainformatica.com.br>
 *
 * Demo for Browse using Set Relatarion
 *
 */
 
#include "hwgui.ch"
#include "dbstruct.ch"

#define x_BLUE       16711680
#define x_RED             255


Function Main
Local oArq1:={{"COD", "C", 3, 0}}
Local oArq2:={{"COD1", "C", 3, 0},{"NOME", "C", 30, 0}}
Local oDlg, i
PRIVATE oBrowse, oSai, oConsulta
PRIVATE vConsulta

If !File("Teste.dbf")
   dBCreate("teste.dbf", oArq1)
EndIf
If !File("Teste1.dbf")
   dBCreate("teste1.dbf", oArq2)
EndIf
Use teste  Exclusiv alias TESTE  NEW
index on COD to Teste
Use teste1 Exclusiv alias TESTE1 NEW
index on COD1 to teste1
Select Teste
Append Blank
Teste->COD:="001"
Append Blank
Teste->COD:="002"
Append Blank
Teste->COD:="003"
Append Blank
Teste->COD:="004"
Select Teste1
Append Blank
Teste1->COD1:="001"; Teste1->NOME:="PRIMEIRO NOME"
Append Blank
Teste1->COD1:="002"; Teste1->NOME:="SEGUNDO NOME"
Append Blank
Teste1->COD1:="003"; Teste1->NOME:="TERCEIRO NOME"
Append Blank
Teste1->COD1:="004"; Teste1->NOME:="QUARTO NOME"

SELECT TESTE

SET Relation TO TESTE->COD into TESTE1
 
INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Teste";
        AT 218,143 SIZE 487,270 FONT HFont():Add( "Arial",0,-11)
        
   Select Teste
   
   @  9, 8 BROWSE oBrowse DATABASE SIZE 466,196 STYLE   WS_VSCROLL + WS_HSCROLL;
    ON KEYDOWN {|o,key| BrowseKey(o, key) } ;
   
   @ 393,214 BUTTON oSai CAPTION "Sair"  ON CLICK {||EndDialog()} SIZE 80,32  

   oBrowse:alias   := "Teste"
   oBrowse:aColumns := {}
   oBrowse:nFootRows:=2
   
   Teste_CreateColumn( oBrowse, "COD", "CODIGO", "TESTE", 1,"C",3,0 )
   Teste_CreateColumn( oBrowse, "NOME","NOME",   "TESTE1",1,"C",30,0 )
   oBrowse:acolumns[2]:footing:="test;test2"
   oBrowse:acolumns[2]:bColorfoot:={|| {x_BLUE,x_RED}}
   oBrowse:acolumns[2]:nJusFoot:=DT_CENTER

   oBrowse:Refresh()
 
   ACTIVATE DIALOG oDlg

   fErase("teste.dbf")

   fErase("teste1.dbf")
   
RETURN Nil

 
STATIC FUNCTION Teste_CreateColumn( oBrw, oCol, oHead, oAr, seq, oType, oLen, oDec )
Local i
Local nArea := &oAr->(select())
    
   oBrw:AddColumn( HColumn():New( oHead ,; 
                                     FieldWBlock( oCol, nArea ),  ;
                                     oType, oLen, oDec, .F. ) )
                                    //"C",   30,   2
   oBrw:Refresh()

RETURN Nil

Static Function BrowseKey( oBr, key )   
   LOCAL xFun
 
   IF key == 112 //.and. lHelp == .T.      && f1
      //D_HELP()
   ELSE
     MsgInfo(Str(key))
   ENDIF
Return .T.
