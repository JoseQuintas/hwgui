/*
 * HWGUI using sample
 * 
 *
 * Jose Augusto M de Andrade Jr - jamaj@terra.com.br
 * 
*/

#include "windows.ch"
#include "guilib.ch"

static aChilds := {}
static Thisform

function Main()
   Local oMainWindow
   
   INIT WINDOW oMainWindow MAIN MDI TITLE "HwGui - Mdi Child Windows Example" STYLE WS_CLIPCHILDREN ;

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Create a child" ACTION CreateMdiChild()
   ENDMENU


   ACTIVATE WINDOW oMainWindow  MAXIMIZED

return (NIL)


FUNCTION CreateMdiChild(  )

  LOCAL oWin,  oStatus1, oContainer1, oContainer2, oContainer3, oContainer4, oContainer5, oGroup1 ;
        , oButtonex1, oButtonex2, oButtonex3, oButtonex4, oGroup2, oButtonex5, oButtonex6, oLabel13 ;
        , oBrowse1, oLabel6, oLabel20, oLabel66, oLabel5, oLabel10, oLabel3, oLabel11 ;
        , oLabel12, oLabel4, oCodigo, oLabel21, oContainer6, oLabel7, oLabel17 ;
        , oLabel18, oLabel8, oLabel9, oLabel14, oLabel15, oLabel16, oLabel19

 LOCAL  vCodigo := ""


  IF  !EMPTY( [PDV] )
     IF HWindow():FindWindow( [PDV] ) != Nil
        hwg_Bringtotop( HWindow():FindWindow( [PDV] ):handle )
        RETURN Nil
     ENDIF
  ENDIF

  INIT WINDOW oWin MDICHILD TITLE "PDV" ;
    AT 0, 0 SIZE 1036,560 ;
     STYLE WS_CHILD+WS_CAPTION+WS_SYSMENU+WS_MAXIMIZEBOX+WS_SIZEBOX+DS_SYSMODAL
    Thisform := oWin

   ADD STATUS oStatus1 TO oWin
   @ 232,184 CONTAINER oContainer1 SIZE 150,50 ;
        STYLE 0 ;
         BACKSTYLE 2
        oContainer1:Anchor := 161
   @ 433,184 CONTAINER oContainer2 SIZE 150,50 ;
        STYLE 0 ;
         BACKSTYLE 2
        oContainer2:Anchor := 161
   @ 643,184 CONTAINER oContainer3 SIZE 150,50 ;
        STYLE 0 ;
         BACKSTYLE 2
        oContainer3:Anchor := 161
   @ 8,85 CONTAINER oContainer4 SIZE 1003,62 ;
        STYLE 0 ;
         BACKSTYLE 2
        oContainer4:Anchor := 11
   @ 496,425 CONTAINER oContainer5 SIZE 300,66 ;
        STYLE 0 ;
         BACKSTYLE 2
        oContainer5:Anchor := 164
   @ 0,0 CONTAINER oContainer6 SIZE 1020,51 ;
        STYLE 0;
         BACKCOLOR 8421504 ;
         BACKSTYLE 2
        oContainer6:Anchor := 11
   @ 8,195 GET oCodigo VAR vCodigo SIZE 216,38    ;
        FONT HFont():Add( 'Times New Roman',0,-27,400,,,)
   @ 818,180 BUTTONEX oButtonex1 CAPTION "Cancela Cupom"   SIZE 183,38 ;
        STYLE BS_CENTER +WS_TABSTOP  NOTHEMES  ;
        ON CLICK {|This, Value| hwg_Msginfo('Cancelado') } ;
        ON GETFOCUS {|| Thisform:obuttonex1:SetColor( 255, hwg_Rgb(225,243,252), .t.) } ;
        ON INIT {|This| This:blostfocus:={|t,this| this:bcolor := NIL, this:Setcolor( 0, NIL, .t. ) } }
        oButtonex1:Anchor := 225
        oButtonex1:lNoThemes := .T.
   @ 818,229 BUTTONEX oButtonex2 CAPTION "Leitura X"   SIZE 183,38 ;
        STYLE BS_CENTER +WS_TABSTOP  NOTHEMES  ;
        ON GETFOCUS {|| Thisform:obuttonex2:SetColor( 255,hwg_Rgb(225,243,252) , .t.) } ;
        ON INIT {|This| This:blostfocus:={|t,this| this:bcolor := NIL, this:Setcolor( 0, NIL, .t. ) } }
        oButtonex2:Anchor := 240
        oButtonex2:lNoThemes := .T.
   @ 818,276 BUTTONEX oButtonex3 CAPTION "Redução Z"   SIZE 183,38 ;
        STYLE BS_CENTER +WS_TABSTOP
        oButtonex3:Anchor := 240
   @ 818,322 BUTTONEX oButtonex4 CAPTION "Leitura Memoria Fiscal"   SIZE 184,38 ;
        STYLE BS_CENTER +WS_TABSTOP
        oButtonex4:Anchor := 240

   @ 808,153 GROUPBOX oGroup1 CAPTION "Cupom Fiscal"  SIZE 203,219 ;
        STYLE BS_LEFT ;
         COLOR 8421376   ;
        FONT HFont():Add( 'Arial Narrow',0,-15,400,,,)
        oGroup1:Anchor := 225
   @ 11,26 SAY oLabel6 CAPTION "07/09/2010"  SIZE 75,19 ;
         COLOR 16777215  BACKCOLOR 8421504
   @ 816,395 BUTTONEX oButtonex5 CAPTION "Procura Produto"   SIZE 188,38 ;
        STYLE BS_CENTER +WS_TABSTOP
        oButtonex5:Anchor := 240
   @ 816,443 BUTTONEX oButtonex6 CAPTION "Finaliza Pedido"   SIZE 188,38 ;
        STYLE BS_CENTER +WS_TABSTOP   ;
        ON CLICK {| | Thisform:Close() }
        oButtonex6:Anchor := 240

   @ 808,373 GROUPBOX oGroup2 CAPTION ""  SIZE 203,122 ;
        STYLE BS_LEFT
        oGroup2:Anchor := 240
   @ 501,429 SAY oLabel13 CAPTION "R$ 11,94"  SIZE 287,57 ;
        STYLE SS_RIGHT +DT_VCENTER+DT_SINGLELINE;
         COLOR 3280604   ;
        FONT HFont():Add( 'Arial',0,-56,400,,,)
        oLabel13:Anchor := 164
   @ 359,6 SAY oLabel8 CAPTION "Prazo"  SIZE 47,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel8:Anchor := 161
   @ 8,245 BROWSE oBrowse1 ARRAY SIZE 786,180 ;
        STYLE WS_TABSTOP       ;
        ON INIT {|This| oBrowse1_onInit( This ) }

    // CREATE oBrowse1   //  SCRIPT GENARATE BY DESIGNER
    oBrowse1:aArray := {}
    oBrowse1:AddColumn( HColumn():New('Código', hwg_ColumnArBlock() ,'U',13, 0 ,.F.,1,,,,,,,,,,,))
    oBrowse1:AddColumn( HColumn():New('Descrição', hwg_ColumnArBlock() ,'U',27, 0 ,.F.,1,,,,,,,,,,,))
    oBrowse1:AddColumn( HColumn():New('Quantid.', hwg_ColumnArBlock() ,'N',9, 3 ,.F.,1,,'9,999.999',,,,,,,,,))
    oBrowse1:AddColumn( HColumn():New('UN', hwg_ColumnArBlock() ,'U',2, 0 ,.F.,1,,,,,,,,,,,))
    oBrowse1:AddColumn( HColumn():New('Valor Unit.', hwg_ColumnArBlock() ,'N',9, 2 ,.F.,1,,'@e 99,999.99',,,,,,,,,))
    oBrowse1:AddColumn( HColumn():New('Valor Item', hwg_ColumnArBlock() ,'N',10, 2 ,.F.,1,,'@E 999,999.99',,,,,,,,,))

    // END BROWSE SCRIPT  -  oBrowse1
        oBrowse1:Anchor := 135
   @ 12,88 SAY oLabel6 CAPTION "BISCOITO RECHEADO BAUNILHA"  SIZE 992,53 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( 'Arial',0,-48,400,,,)
        oLabel6:Anchor := 11
   @ 359,26 SAY oLabel9 CAPTION "A VISTA"  SIZE 80,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel9:Anchor := 161
   @ 235,189 SAY oLabel20 CAPTION "2,00"  SIZE 142,40 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( '',0,-32,400,,,)
        oLabel20:Anchor := 161
   @ 593,6 SAY oLabel14 CAPTION "Cliente"  SIZE 61,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel14:Anchor := 161
   @ 438,190 SAY oLabel66 CAPTION "12,50"  SIZE 142,40 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( '',0,-32,400,,,)
        oLabel66:Anchor := 161
   @ 593,26 SAY oLabel15 CAPTION "CONSUMIDOR FINAL"  SIZE 139,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel15:Anchor := 161
   @ 646,189 SAY oLabel6 CAPTION "25,00"  SIZE 142,40 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( '',0,-32,400,,,)
        oLabel6:Anchor := 161
   @ 957,6 SAY oLabel16 CAPTION "Venda"  SIZE 57,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel16:Anchor := 9
   @ 144,6 SAY oLabel17 CAPTION "Hora"  SIZE 43,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel17:Anchor := 161
   @ 143,26 SAY oLabel18 CAPTION "15:45:12"  SIZE 67,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel18:Anchor := 161
   @ 8,57 SAY oLabel5 CAPTION "Descrição do Produto"  SIZE 1003,27 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( 'Arial',0,-19,400,,,)
        oLabel5:Anchor := 11
   @ 235,155 SAY oLabel10 CAPTION "Quantidade"  SIZE 147,27 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( 'Arial',0,-19,400,,,)
        oLabel10:Anchor := 161
   @ 433,155 SAY oLabel3 CAPTION "Valor Unitário"  SIZE 150,27 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( 'Arial',0,-19,400,,,)
        oLabel3:Anchor := 161
   @ 643,154 SAY oLabel11 CAPTION "Total do Item"  SIZE 150,27 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( 'Arial',0,-19,400,,,)
        oLabel11:Anchor := 161
   @ 8,155 SAY oLabel21 CAPTION "Código"  SIZE 216,35 ;
        STYLE SS_CENTER +DT_VCENTER+DT_SINGLELINE+WS_DLGFRAME   ;
        FONT HFont():Add( 'Arial',0,-19,700,,,)
        oLabel21:Anchor := 161
        hwg_SetFontStyle( oLabel21,.T. )  // oLabel21:FontBold := .T.
   @ 10,429 SAY oLabel12 CAPTION "Total Geral"  SIZE 257,62   ;
        FONT HFont():Add( 'Arial',0,-47,400,,,)
        oLabel12:Anchor := 6
   @ 398,192 SAY oLabel2 CAPTION "X"  SIZE 25,36   ;
        FONT HFont():Add( 'Arial',0,-29,400,,,)
        oLabel2:Anchor := 161
   @ 593,190 SAY oLabel4 CAPTION " ="  SIZE 32,36 ;
        STYLE SS_CENTER   ;
        FONT HFont():Add( 'Arial',0,-29,400,,,)
        oLabel4:Anchor := 161
   @ 11,6 SAY oLabel7 CAPTION "Data"  SIZE 43,19 ;
         COLOR 16777215  BACKCOLOR 8421504
   @ 957,27 SAY oLabel19 CAPTION "18238"  SIZE 57,19 ;
         COLOR 16777215  BACKCOLOR 8421504
        oLabel19:Anchor := 9

   ACTIVATE WINDOW oWin CENTER


RETURN  NIL

STATIC FUNCTION oBrowse1_onInit( This )

   This:aArray := {{"7891234512345","CERVEJA STELA 330ML",6,"UN",1.99,11.94}}
   This:HighlightStyle := 0
 RETURN .T.


