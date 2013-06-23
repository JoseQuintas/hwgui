/*
 * $Id: browse_1.prg,v 1.3 2004/04/17 15:03:33 rodrigo_moreno Exp $
 */
 
#include "windows.ch"
#include "guilib.ch"

Static nCount := 0
Static oBrowse

Function Main
        Local oMain
        
        CreateDB()
        
        INIT WINDOW oMain MAIN TITLE "Browse Example - Database" ;
             AT 0,0 ;
             SIZE hwg_Getdesktopwidth(), hwg_Getdesktopheight() - 28

                MENU OF oMain
                        MENUITEM "&Exit"   ACTION oMain:Close()
                        MENUITEM "&Browse" ACTION BrowseTest()
                ENDMENU

        ACTIVATE WINDOW oMain
Return Nil

Function BrowseTest()
        Local oForm, oFont

        hwg_Settooltipballoon(.t.)

        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11
             
        INIT DIALOG oForm CLIPPER NOEXIT TITLE "Browse Database";
             FONT oFont ;
             AT 0, 0 SIZE 700, 425 ;
             STYLE DS_CENTER + WS_VISIBLE + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

@ 0,400 say oSay caption '' size 700,14

                @  5, 5 BROWSE oBrowse DATABASE OF oForm SIZE 690,375 ;
                  STYLE WS_VSCROLL + WS_HSCROLL;
                  ON PAINT {|o| browsePaint(o) };
                  ON POSCHANGE {|o| browsePaint(o) };
                  ON KEYDOWN {|o| browsePaint(o) };
                  ON CLICK {|o| browsePaint(o) }

                ADD COLUMN FieldBlock(Fieldname(1) ) TO oBrowse ;
                    HEADER 'Code';
                    TYPE 'N';
                    LENGTH 6 ;
                    DEC 0 ;
                    PICTURE "@E 999,999";
                    JUSTIFY HEAD DT_CENTER ;
                    JUSTIFY LINE DT_RIGHT

                ADD COLUMN {||'linha 1;linha 2' } TO oBrowse ;
                    HEADER 'Linha 1;Nova linha';
                    TYPE 'N';
                    LENGTH 6 ;
                    DEC 0 ;
                    PICTURE "@E 999,999";
                    JUSTIFY HEAD DT_CENTER ;
                    JUSTIFY LINE DT_RIGHT

                ADD COLUMN FieldBlock(Fieldname(2) ) TO oBrowse ;
                    HEADER 'Description' ;
                    PICTURE "@!" ;
                    JUSTIFY HEAD DT_CENTER ;
                    JUSTIFY LINE DT_LEFT 

                ADD COLUMN FieldBlock(Fieldname(3)) TO oBrowse ;
                    HEADER "List Code" ;
                    ITEMS {"Code 1", "Code 2", "Code 3"}
                    
                ADD COLUMN FieldBlock(Fieldname(4)) TO oBrowse ;
                    HEADER "Creation Date" ;

                ADD COLUMN FieldBlock(Fieldname(5)) TO oBrowse ;
                    HEADER "Bool Status" ;

                ADD COLUMN FieldBlock(Fieldname(6)) TO oBrowse ;
                    HEADER "Price" ;
                    PICTURE "@E 999,999.99"
                            
        ACTIVATE DIALOG oForm
Return Nil


Static Function CreateDB()
        if file('browse_1.dbf')
                FErase('browse_1.dbf')
        end
        
        DBCreate('browse_1', {{'code', 'N', 6, 0},;
                              {'desc', 'C', 40, 0},;
                              {'list', 'N', 1, 0},;
                              {'creation', 'D', 8, 0},;
                              {'status', 'L', 1, 0},;
                              {'price', 'N', 10, 2}})
                              
        USE browse_1 EXCLUSIVE                   

      for i:=1 to 100
        APPEND BLANK
        REPLACE Code WITH i
        REPLACE Desc WITH "Testing code "+alltrim(str(i))
        REPLACE list WITH 1
        REPLACE creation WITH Date()
        REPLACE Status WITH .T.
        REPLACE Price WITH 1.31 * i
      end
Return Nil

 
static function browsePaint(o)
  // oSay:setText(valToPrg(o:aSelected))
return .t.
