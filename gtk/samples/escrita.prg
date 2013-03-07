
request HB_CODEPAGE_PTISO,HB_CODEPAGE_PT850
#include "hwgui.ch"

Function Main()
Local oModDlg, oEditbox, onome,obar
Local meditbox := "", mnome:= space( 50 )
//hb_settermcp("PT850","PTISO")
INIT DIALOG oModDlg TITLE "Teste da Acentuação" ;
   AT 210,10  SIZE 300,300       on init {||otool:refresh(),hwg_Enablewindow(oTool:aItem[2,11],.f.)}
//hwg_Createtoolbar(omodDlg:handle,0,0,20,20)   
   @ 0,0 toolbar oTool of oModDlg size 50,100 ID 700
   TOOLBUTTON  otool ;
           ID 701 ;
           BITMAP "../../image/new.bmp";
           STYLE 0;
           STATE 4;
           TEXT "teste1"  ;
           TOOLTIP "ola" ;
           
           ON CLICK {|x,y|hwg_Msginfo("ola"),hwg_Enablewindow(oTool:aItem[2,11],.t.) ,hwg_Enablewindow(oTool:aItem[1,11],.f.)}

   TOOLBUTTON  otool ;
          ID 702 ;
           BITMAP "../../image/book.bmp";
           STYLE 0 ;
           STATE 4;
           TEXT "teste2"  ;
           TOOLTIP "ola2" ;
           ON CLICK {|x,y|hwg_Msginfo("ola1"),hwg_Enablewindow(oTool:aItem[1,11],.t.),hwg_Enablewindow(oTool:aItem[2,11],.f.)}

   TOOLBUTTON  otool ;
          ID 703 ;
           BITMAP "../../image/ok.ico";
           STYLE 0 ;
           STATE 4;
           TEXT "asdsa"  ;
           TOOLTIP "ola3" ;
           ON CLICK {|x,y|hwg_Msginfo("ola2")}
   TOOLBUTTON  otool ;
          ID 702 ;
           STYLE 1 ;
           STATE 4;
           TEXT "teste2"  ;
           TOOLTIP "ola2" ;
           ON CLICK {|x,y|hwg_Msginfo("ola3")}
   TOOLBUTTON  otool ;
          ID 702 ;
           BITMAP "../../image/tools.bmp";
           STYLE 0 ;
           STATE 4;
           TEXT "teste2"  ;
           TOOLTIP "ola2" ;
           ON CLICK {|x,y|hwg_Msginfo("ola4")}

   TOOLBUTTON  otool ;
          ID 702 ;
           BITMAP "../../image/cancel.ico";
           STYLE 0 ;
           STATE 4;
           TEXT "teste2"  ;
           TOOLTIP "ola2" ;
           ON CLICK {|x,y|hwg_Msginfo("ola5")}
	   


   @ 20,35 EDITBOX oEditbox CAPTION ""    ;
        STYLE WS_DLGFRAME              ; 
        SIZE 260,26 
        
   @ 20,75 GET onome VAR mnome SIZE 260,26 
   
   @ 20,105 progressbar obar size 260,26  barwidth 100

   ACTIVATE DIALOG oModDlg

hwg_Msginfo( meditbox )
hwg_Msginfo( OEDITBOX:TITLE )
hwg_Msginfo( mnome )


Return Nil

