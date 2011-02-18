/* 
   Copyright (c) Luiz Henrique lh.santos at ibest.com.br
*/
#include "hwgui.ch"

STATIC nLastRecordFilter  := 0
STATIC nFirstRecordFilter := 0


FUNCTION Main()
  PRIVATE frmTesteBrowse
  
  INIT WINDOW frmTesteBrowse MAIN TITLE "Teste HBrowse com filtro" ;
    COLOR COLOR_3DLIGHT+1 ;
  	AT 0,0 ;
  	SIZE GetDesktopWidth(), GetDesktopHeight() - 28 ;
  	FONT HFont():Add("MS Sans Serif", 0, -12)
  	
  USE MESAS NEW SHARED
  INDEX ON mesa TO indmesas
  SET INDEX TO indmesas
  
  USE ITENS NEW SHARED
  INDEX ON mesa+nomeprod TO inditens
  SET INDEX TO inditens
  
  DBSELECTAREA("MESAS")
  
  @ 010,061 BROWSE DATABASE brwMesas ;
            SIZE 353,283 ;
            STYLE WS_VSCROLL + WS_HSCROLL ;
  	        ON POSCHANGE {|| EVAL(brwItens:bFirst), brwItens:Refresh()} ;
  	        FOR { || EMPTY(fechado) }
  
  brwMesas:bColorSel := 16711680 //Cor da linha do browse
  
  ADD COLUMN {|| OrdKeyNo()} TO brwMesas ;
    HEADER "OrdKeyNo()";
    TYPE "N" LENGTH 6 DEC 0 ;
    PICTURE "@E 999999";
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_RIGHT

  ADD COLUMN {|| RECNO()} TO brwMesas ;
    HEADER "Recno()";
    TYPE "N" LENGTH 6 DEC 0 ;
    PICTURE "@E 999999";
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_RIGHT

  ADD COLUMN FIELDBLOCK("mesa") TO brwMesas ;
    HEADER "Mesa";
    TYPE "C" LENGTH 6 DEC 0 ;
    PICTURE "@E 999999";
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_LEFT
                   
  ADD COLUMN FIELDBLOCK("garcon") TO brwMesas ;
    HEADER "Garcom" ;
    PICTURE "@E 999" ;
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_LEFT 

  ADD COLUMN FIELDBLOCK("total") TO brwMesas ;
    HEADER "Total" ;
    PICTURE "@E 999,999.99" ;
    JUSTIFY HEAD DT_RIGHT ;
    JUSTIFY LINE DT_RIGHT 

  brwMesas:Refresh()
  
  DBSELECTAREA("ITENS")
  
  @ 375,061 BROWSE DATABASE brwItens ;
    SIZE 415,283 ;
  	STYLE WS_VSCROLL + WS_HSCROLL ;
  	FIRST {|| DBSEEK(mesas->mesa)} ;
  	WHILE {|| mesa == mesas->mesa} ;
  	FOR {|| EMPTY(fechado)}
            
  brwItens:bColorSel := 16711680
  
  ADD COLUMN {|| OrdKeyNo()} TO brwItens ;
    HEADER "OrdKeyNo()";
    TYPE "N" LENGTH 6 DEC 0 ;
    PICTURE "@E 999999";
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_RIGHT

  ADD COLUMN {|| RECNO()} TO brwItens ;
    HEADER "Recno()";
    TYPE "N" LENGTH 6 DEC 0 ;
    PICTURE "@E 999999";
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_RIGHT


  ADD COLUMN FIELDBLOCK("mesa") TO brwItens ;
    HEADER "Mesa";
    TYPE "C" LENGTH 6 DEC 0 ;
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_LEFT

  ADD COLUMN FIELDBLOCK("estornado") TO brwItens ;
    HEADER "Estornado";
    TYPE "C" LENGTH 1 DEC 0 ;
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_LEFT

  ADD COLUMN FIELDBLOCK("nomeprod") TO brwItens ;
    HEADER "Produto" ;
    TYPE "C" ;
    LENGTH 40 ;
    DEC 0 ;
    JUSTIFY HEAD DT_LEFT ;
    JUSTIFY LINE DT_LEFT 
                   
  ADD COLUMN FIELDBLOCK("qtd") TO brwItens ;
    HEADER "Quantidade"; 
    JUSTIFY HEAD DT_RIGHT ;
    JUSTIFY LINE DT_RIGHT 

  brwItens:Refresh()
  
  ACTIVATE WINDOW frmTesteBrowse
RETURN NIL