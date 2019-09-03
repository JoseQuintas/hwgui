/*
 * Demo by HwGUI Alexander Kresin
 *  http://kresin.belgorod.su/
 *
 *
 * Paulo Flecha <pfflecha@yahoo.com>
 * 07/07/2005
 * Demo for Browse using bColorBlock
 *
 *       oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
 *       {textColor, backColor, textColorSel, backColorSel} ,;
 *       {textColor, backColor, textColorSel, backColorSel} ) }
 *
 *       bColorBlock must return an array containing four colors values
 *
 */

#define x_BLUE       16711680
#define x_DARKBLUE   10027008
#define x_WHITE      16777215
#define x_CYAN       16776960
#define x_BLACK             0
#define x_RED             255
#define x_GREEN         32768
#define x_GRAY        8421504
#define x_YELLOW        65535

#include "windows.ch"
#include "guilib.ch"

***********************
FUNCTION Main()
***********************
LOCAL oWinMain

SET(_SET_DATEFORMAT, "dd/mm/yyyy")
SET(_SET_EPOCH, 1950)

REQUEST DBFCDX                      // Causes DBFCDX RDD to be linked in
rddSetDefault( "DBFCDX" )           // Set up DBFCDX as default driver

*FERASE("TSTBRW.DBF")

IF !FILE("TSTBRW.DBF")
   CriaDbf()
ELSE
   DBUSEAREA(.T., "DBFCDX", "TSTBRW", "TSTB")
END

INIT WINDOW oWinMain MAIN  ;
     TITLE "Teste" AT 0, 0 SIZE 600,400;
    FONT HFont():Add( 'Arial',0,-13,400,,,) ;
    STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER


   MENU OF oWinMain
      MENU TITLE "&Arquivo"
          MENUITEM "&Sair"              ACTION hwg_EndWindow()
      ENDMENU
      MENU TITLE "&Browse"
         MENUITEM "&Database"           ACTION BrwDbs(.f.)
         MENUITEM "Database &EDITABLE"  ACTION BrwDbs(.t.)
         MENUITEM "Database &Zebra"     ACTION BrwDbs(.f., .T.)
         SEPARATOR
         MENUITEM "&Array"              ACTION BrwArr(.f.)
         MENUITEM "Array E&DITABLE"     ACTION BrwArr(.t.)
         MENUITEM "Array Ze&bra"        ACTION BrwArr(.f., .T.)
      ENDMENU
   ENDMENU

   oWinMain:Activate()

RETURN(NIL)

*****************************
STATIC FUNCTION BrwDbs( lEdit, lZebra )
*****************************
LOCAL oEdGoto
LOCAL oBrwDb
LOCAL o_Obtn1, o_Obtn2, o_Obtn3, o_Obtn4
LOCAL oTbar
LOCAL nRec := 1
LOCAL nLast := 0

  lZebra := IF(lZebra == NIL, .F., lZebra)
  DBSELECTAR("TSTB")
  nLast := LASTREC()
  dbGoTop()

  INIT DIALOG oDlg TITLE "Browse DataBase" ;
        AT 0,0 SIZE 600, 500 NOEXIT ;
        FONT HFont():Add( 'Arial',0,-13,400,,,) ;
        STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

  IF lEdit
   @ 10 ,10 BROWSE oBrwDb DATABASE SIZE 580, 385  ;
        STYLE  WS_VSCROLL + WS_HSCROLL ;
        AUTOEDIT ;
        APPEND ;
        ON UPDATE {|| oBrwDb:REFRESH() } ;
        ON KEYDOWN {|oBrwDb, nKey| BrowseDbKey(oBrwDb, nKey, @nLast, oLbl2, "") } ;
        ON POSCHANGE {|| BrowseMove(oBrwDb, "NIL", oEdGoto, "Dbs" ) }
  ELSE
   @ 10 ,10 BROWSE oBrwDb DATABASE SIZE 580, 385  ;
        STYLE  WS_VSCROLL + WS_HSCROLL ;
        ON UPDATE {|| oBrwDb:REFRESH() } ;
        ON KEYDOWN {|oBrwDb, nKey| BrowseDbKey(oBrwDb, nKey, @nLast, oLbl2, "") } ;
        ON POSCHANGE {|| BrowseMove(oBrwDb, "NIL", oEdGoto, "Dbs" ) }
  END

   @ 260,410 BUTTON oBtn1 CAPTION "&OK " SIZE 80,26 ;
         ON CLICK {|| hwg_EndDialog()}

   @ 0, 445 PANEL oTbar1 SIZE 600, 26

   @ 17,10 SAY oLbl1 CAPTION "Records :" OF oTbar1 SIZE 70,22

   @ 85,5 OWNERBUTTON o_Obtn1 OF oTbar1 SIZE 20,20     ;
        BITMAP "Home.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwDb, "Home", oEdGoto, "Dbs" ) };
        TOOLTIP "First Record"

   @ 105,5 OWNERBUTTON o_Obtn2 OF oTbar1 SIZE 20,20    ;
        BITMAP "Up.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwDb, "Up", oEdGoto, "Dbs" ) } ;
        TOOLTIP "Prior"

   @ 130,4 GET oEdGoto VAR nRec OF oTbar1 SIZE 80,22 ;
        MAXLENGTH 09 PICTURE "999999999" ;
        STYLE WS_BORDER + ES_LEFT ;
        VALID {||GoToRec(oBrwDb, @nRec, nLast, "Dbs")}

   @ 270,7 SAY oLbl2 CAPTION " of  " + ALLTRIM(STR(nLast)) OF oTbar1 SIZE 70,22

   @ 215,5 OWNERBUTTON o_Obtn3 OF oTbar1 SIZE 20,20   ;
        BITMAP "Down.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwDb, "Down", oEdGoto, "Dbs" ) } ;
        TOOLTIP "Next"

   @ 235,5 OWNERBUTTON o_Obtn4 OF oTbar1 SIZE 20,20   ;
        BITMAP "End.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwDb, "End", oEdGoto, "Dbs" ) } ;
        TOOLTIP "Last Record"

        oBrwDb:bcolorSel := x_DARKBLUE
        oBrwDb:alias := 'TSTB'
        oBrwDb:AddColumn( HColumn():New( "Field1" , FieldBlock(Fieldname(1)),"N", 10,02) )
        oBrwDb:AddColumn( HColumn():New( "Field2" , FieldBlock(Fieldname(2)),"C", 11,00) )
        oBrwDb:AddColumn( HColumn():New( "Field3" , FieldBlock(Fieldname(3)),"D", 10,00) )
        oBrwDb:AddColumn( HColumn():New( "Field4" , FieldBlock(Fieldname(4)),"C", 31,00) )
        oBrwDb:AddColumn( HColumn():New( "Field5" , FieldBlock(Fieldname(5)),"C", 05,00) )

        oBrwDb:aColumns[1]:nJusHead := DT_CENTER
        oBrwDb:aColumns[2]:nJusHead := DT_CENTER
        oBrwDb:aColumns[3]:nJusHead := DT_CENTER
        oBrwDb:aColumns[4]:nJusHead := DT_CENTER
        oBrwDb:aColumns[5]:nJusHead := DT_CENTER

        IF lEdit
        oBrwDb:aColumns[1]:lEditable := .T.
        oBrwDb:aColumns[2]:lEditable := .T.
        oBrwDb:aColumns[3]:lEditable := .T.
        oBrwDb:aColumns[4]:lEditable := .T.
        oBrwDb:aColumns[5]:lEditable := .T.
        END

//      {|| IF (nNumber < 0, ;
//       {tColor, bColor, tColorSel, bColorSel} ,;
//       {tColor, bColor, tColorSel, bColorSel}) }

        IF lEdit
          oBrwDb:aColumns[1]:bColorBlock := {|| IF(TSTB->FIELD1 < 0 , ;
           {x_RED, x_WHITE, x_CYAN, x_GRAY} , ;
           {x_BLUE, x_WHITE , x_BLACK, x_YELLOW })}
        ELSE
          oBrwDb:aColumns[1]:bColorBlock := {|| IF(TSTB->FIELD1 < 0 , ;
           {x_RED, x_WHITE, x_CYAN, x_DARKBLUE} , ;
           {x_BLACK, x_WHITE , x_WHITE, x_DARKBLUE })}
          IF lZebra
             FOR nI := 2 TO 5
                oBrwDB:aColumns[nI]:bColorBlock := {|| IF(MOD(oBrwDB:nPaintRow, 2) = 0,;
                      {x_BLACK, x_GRAY, x_CYAN, x_DARKBLUE} , ;
                      {x_BLACK, x_WHITE , x_WHITE, x_DARKBLUE })}
             NEXT
          ENDIF
        END
   oDlg:Activate()

RETURN(NIL)

*******************************************************
STATIC FUNCTION BrowseMove(oBrw, cPar, oEdGoto, cType )
*******************************************************
IF cPar == "Home"
  oBrw:TOP()
ELSEIF cPar == "Up"
  oBrw:LineUp()
ELSEIF cPar == "Down"
  oBrw:LineDown()
ELSEIF cPar == "End"
  oBrw:BOTTOM()
END

IF cType == "Dbs"
  oEdGoto:SetText(oBrw:recCurr)
ELSEIF cType == "Array"
  oEdGoto:SetText(oBrw:nCurrent)
END
Return Nil

*************************************************
STATIC FUNCTION GoToRec(oBrw, nRec, nLast, cType)
*************************************************
IF nRec == 0
   nRec := 1
END

IF nRec > nLast
  nRec := nlast
END

oBrw:TOP()
IF cType == "Dbs"
  dbGoto(nRec)
ELSEIF cType == "Array"
  oBrw:nCurrent := nRec
END
oBrw:Refresh()

hwg_Setfocus(oBrw:handle)

RETURN(.T.)

*************************************************************
STATIC FUNCTION BrowseDbKey(oBrwDb, nKey, nLast, oLbl2, cPar)
*************************************************************
IF nKey == 46   // DEL

ELSEIF nKey == VK_RETURN

END

Return .T.

*************************
STATIC FUNCTION CriaDbf()
*************************
LOCAL Estrutura := {}
LOCAL i := 1
LOCAL nIncrement := 10

  IF ! FILE("TSTBRW.DBF")
     AADD(Estrutura, {"FIELD1", "N", 10, 02})
     AADD(Estrutura, {"FIELD2", "C", 11, 00})
     AADD(Estrutura, {"FIELD3", "D", 08, 00})
     AADD(Estrutura, {"FIELD4", "C", 30, 00})
     AADD(Estrutura, {"FIELD5", "C", 05, 00})

     DBCREATE("TSTBRW.DBF", Estrutura)
     DBCLOSEAREA()
  ENDIF

  DBUSEAREA(.T., "DBFCDX", "TSTBRW", "TSTB")

  For i := 1 to 200
        APPEND BLANK
        IF i == nIncrement
          nIncrement += 10
          FIELD->FIELD1 := -i
        ELSE
          IF i == 1
             FIELD->FIELD1 := -i
          else
             FIELD->FIELD1 := i
          end
        END
        FIELD->FIELD2 := "Field2 " + STRZERO(i,4)
        FIELD->FIELD3 := DATE() + i
        FIELD->FIELD4 := "jgçpqy " + STRZERO(i, 23)
        FIELD->FIELD5 := STRZERO(i, 5)
  Next

RETURN(.T.)

*****************************
STATIC FUNCTION BrwArr(lEdit, lZebra)
****************************
LOCAL oEdGoto
LOCAL oBrwArr
LOCAL o_Obtn1, o_Obtn2, o_Obtn3, o_Obtn4
LOCAL oTbar
LOCAL nRec := 1
LOCAL aArrayTst := Create_Array()
LOCAL nLast := LEN(aArrayTst)
LOCAL nI

  lZebra := IF(lZebra == NIL, .F., lZebra)
  INIT DIALOG oDlg TITLE "Browse Array" ;
        AT 0,0 SIZE 600, 500 NOEXIT ;
        FONT HFont():Add( 'Arial',0,-13,400,,,) ;
        STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

  IF lEdit
   @ 10 ,10 BROWSE oBrwArr ARRAY SIZE 580, 385  ;
        STYLE  WS_VSCROLL + WS_HSCROLL ;
        AUTOEDIT ;
        APPEND ;
        ON UPDATE {|| oBrwArr:REFRESH() } ;
        ON KEYDOWN {|oBrwArr, nKey| BrowseDbKey(oBrwArr, nKey, @nLast, oLbl2, "") } ;
        ON POSCHANGE {|| BrowseMove(oBrwArr, "NIL", oEdGoto, "Array" ) }
  ELSE
   @ 10 ,10 BROWSE oBrwArr ARRAY SIZE 580, 385  ;
        STYLE  WS_VSCROLL + WS_HSCROLL ;
        ON UPDATE {|| oBrwArr:REFRESH() } ;
        ON KEYDOWN {|oBrwArr, nKey| BrowseDbKey(oBrwArr, nKey, @nLast, oLbl2, "") } ;
        ON POSCHANGE {|| BrowseMove(oBrwArr, "NIL", oEdGoto, "Array" ) }
  END

   @ 260,410 BUTTON oBtn1 CAPTION "&OK " SIZE 80,26 ;
         ON CLICK {|| hwg_EndDialog()}

   @ 0, 445 PANEL oTbar1 SIZE 600, 26

   @ 17,10 SAY oLbl1 CAPTION "Elements :" OF oTbar1 SIZE 70,22

   @ 85,5 OWNERBUTTON o_Obtn1 OF oTbar1 SIZE 20,20     ;
        BITMAP "Home.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwArr, "Home", oEdGoto, "Array" ) };
        TOOLTIP "First Record"

   @ 105,5 OWNERBUTTON o_Obtn2 OF oTbar1 SIZE 20,20    ;
        BITMAP "Up.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwArr, "Up", oEdGoto, "Array" ) } ;
        TOOLTIP "Prior"

   @ 130,4 GET oEdGoto VAR nRec OF oTbar1 SIZE 80,22 ;
        MAXLENGTH 09 PICTURE "999999999" ;
        STYLE WS_BORDER + ES_LEFT ;
        VALID {||GoToRec(oBrwArr, @nRec, nLast, "Array")}

   @ 270,7 SAY oLbl2 CAPTION " of  " + ALLTRIM(STR(nLast)) OF oTbar1 SIZE 70,22

   @ 215,5 OWNERBUTTON o_Obtn3 OF oTbar1 SIZE 20,20   ;
        BITMAP "Down.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwArr, "Down", oEdGoto, "Array" ) } ;
        TOOLTIP "Next"

   @ 235,5 OWNERBUTTON o_Obtn4 OF oTbar1 SIZE 20,20   ;
        BITMAP "End.bmp";// TRANSPARENT COORDINATES 0,2,0,0 ;
        ON CLICK {|| BrowseMove(oBrwArr, "End", oEdGoto, "Array" ) } ;
        TOOLTIP "Last Record"

       hwg_CREATEARLIST( oBrwArr, aArrayTst )

        oBrwArr:bcolorSel := x_BLUE

        oBrwArr:aColumns[1]:length := 10
        oBrwArr:aColumns[2]:length := 11
        oBrwArr:aColumns[3]:length := 10
        oBrwArr:aColumns[4]:length := 31
        oBrwArr:aColumns[5]:length := 05

        oBrwArr:aColumns[1]:heading := "Column[1]"
        oBrwArr:aColumns[2]:heading := "Column[2]"
        oBrwArr:aColumns[3]:heading := "Column[3]"
        oBrwArr:aColumns[4]:heading := "Column[4]"
        oBrwArr:aColumns[5]:heading := "Column[5]"

        oBrwArr:aColumns[1]:nJusHead := DT_CENTER
        oBrwArr:aColumns[2]:nJusHead := DT_CENTER
        oBrwArr:aColumns[3]:nJusHead := DT_CENTER
        oBrwArr:aColumns[4]:nJusHead := DT_CENTER
        oBrwArr:aColumns[5]:nJusHead := DT_CENTER

        IF lEdit
        oBrwArr:aColumns[1]:lEditable := .T.
        oBrwArr:aColumns[2]:lEditable := .T.
        oBrwArr:aColumns[3]:lEditable := .T.
        oBrwArr:aColumns[4]:lEditable := .T.
        oBrwArr:aColumns[5]:lEditable := .T.
        END

//      {|| IF (nNumber < 0, ;
//       {tColor, bColor, tColorSel, bColorSel} ,;
//       {tColor, bColor, tColorSel, bColorSel}) }
       IF lEdit
       oBrwArr:aColumns[1]:bColorBlock := {|n| IF(aArrayTst[oBrwArr:nCurrent][1] < 0 , ;
           {x_RED, x_WHITE, x_CYAN, x_BLUE} , ;
           {x_BLUE, x_WHITE , x_WHITE, x_BLUE })}
       ELSE
       oBrwArr:aColumns[1]:bColorBlock := {|n| IF(aArrayTst[oBrwArr:nCurrent][1] < 0 , ;
           {x_RED, x_WHITE, x_CYAN, x_DARKBLUE} , ;
           {x_BLUE, x_WHITE , x_WHITE, x_BLUE })}
          IF lZebra
             FOR nI := 2 TO 5
                oBrwArr:aColumns[nI]:bColorBlock := {|| IF(MOD(oBrwArr:nCurrent, 2) = 0,;
                       {x_BLACK, x_GRAY, x_CYAN, x_DARKBLUE} , ;
                       {x_BLACK, x_WHITE , x_WHITE, x_DARKBLUE })}
             NEXT
          ENDIF
       END

/*
        oBrwDb:aColumns[1]:bColorBlock := {|| IF(TSTB->FIELD1 < 0 , ;
         {x_VERMELHO, x_BRANCO, x_CYAN, x_CINZA50} , ;
         {x_AZUL, x_BRANCO , x_LARANJA, x_AMARELO })}
*/
   oDlg:Activate()

RETURN(.T.)

******************************
STATIC FUNCTION Create_Array()
******************************
LOCAL i := 1
LOCAL n := 1
LOCAL nIncrement := 10
LOCAL aArray := {}

  For i := 1 to 200
    n := i
    IF i == nIncrement
       nIncrement += 10
       n := -i
    ELSE
       IF i == 1
          n := -i
       ELSE
             n := i
       END
    END
    AADD(aArray, { n, STRZERO(i,4), DATE() + i, "jgçpqy " + STRZERO(i, 23), STRZERO(i, 5)})
  Next

RETURN(aArray)

/* -------------------------------------------------------------------------- */

#Ifdef __XHARBOUR__
 #XTRANSLATE HB_PVALUE(<var>)  => PVALUE(<var>)
#endif

FUNCTION MsgD( cV1, cV2, cV3, cV4, cV5, cV6, cV7, cV8, cV9, cV10 )
   LOCAL nI, nLen := PCOUNT(), cVar := ""
   FOR nI := 1 TO nLen
       IF HB_PVALUE(nI) == NIL
         cVar += "NIL"
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "B"
         cVar += "CODEBLOCK"
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "N"
         cVar += STR(HB_PVALUE(nI))
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "D"
         cVar += DTOS(HB_PVALUE(nI))
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "L"
         cVar += IF(HB_PVALUE(nI), ".T.", ".F.")
       ELSEIF VALTYPE(HB_PVALUE(nI)) == "C"
         cVar += HB_PVALUE(nI)
       ENDIF
       cVar += "/"
   NEXT
   hwg_Msginfo(LEFT(cVar, LEN(cVar) - 1))
RETURN NIL

