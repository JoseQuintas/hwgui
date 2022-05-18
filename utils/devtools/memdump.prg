*
* memdump.prg
*
* $Id$ 
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Developers utility:
* Dump contents of a Clipper(Harbour) MEM file
*
* Copyright 2022 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details.
*

    * Status:
    *  WinAPI   :  Yes
    *  GTK/Linux:  Yes
    *  GTK/Win  :  Yes 

* ================================================================================
* A mem file is created by execution of a SAVE TO command.
* For each memory variable saved, it contains a 32 byte header followed
* by the actual contents (one record).
* The header has the following structure:
* (1)  char mname[11]   && 10 + NIL
* (12) char mtype       && C,D,L,N with top bit set hb_bitand(n,127)
* (13) char mfiller[4]
* (17) char mlen
* (18) char mdec
* (19) char mfiller[14]
* Size of a MEM_REC is 32 Byte
* 
* A character variable may be more than 256 bytes long, so its 
* length requires two bytes: mdec and mlen.
*
* This utility is very useful to use a MEM file.
* It is helpful, if you know values saved to and
* restored from MEM file.
*
* Button "Test":
* Creates a MEM file "test.mem" and displays its contents.
* It contains variables of every type, also a negative N value.
*
* ================================================================================

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif


STATIC cStMEMFILE, nreccount, oLabel2  ,  oFont
STATIC oBrwArr , amemdarr , aumemdarr

* amemdarr  : Array with contents and item name
* aumemdarr : Array only with contents

FUNCTION MAIN()
LOCAL oWinMain

INIT WINDOW oWinMain MAIN  ;
     TITLE "Utility Dump a MEM file" AT 0, 0 SIZE 600,400;
     STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

   MENU OF oWinMain
      MENU TITLE "&File"
          MENUITEM "&Exit"              ACTION hwg_EndWindow()
     ENDMENU
      MENU TITLE "&Memdump"
         MENUITEM "&Start"     ACTION _frm_memdump()
      ENDMENU
      MENU TITLE "&?"
         MENUITEM "&About"     ACTION dlgAbout()
      ENDMENU
   ENDMENU

   oWinMain:Activate()


RETURN NIL 


FUNCTION _frm_memdump()


LOCAL oDlg 
LOCAL oLabel1, oButton1, oButton2, oButton3, oButton4, oButton5 , oButton6 , oButton7

MEMVAR cStMEMFILE, nreccount, oLabel2, oBrowse1 , oFont 
MEMVAR oBrwArr, amemdarr , aumemdarr

SET CENTURY ON

#ifdef __PLATFORM__WINDOWS
 PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
 PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif 

cStMEMFILE := "<NONE>"
nreccount  := 0

// Test
// aumemdarr := { {"1","2","3","4","5","6"} , {"1","2","3","4", "5","6"} }

amemdarr  := aARR_EMPTY()
aumemdarr := aARR_EMPTY()

  INIT DIALOG frm_memdump TITLE "Dump a MEM file" ;
    AT 220,23 SIZE 1136,563 ;
    STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

//     STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE +  DS_CENTER


   @ 36,25 SAY oLabel1 CAPTION "Dump of file :"  SIZE 153,22
   @ 217,25 SAY oLabel2 CAPTION cStMEMFILE  SIZE 638,22 


     @ 38,94 BROWSE oBrwArr ARRAY ;
             STYLE WS_VSCROLL + WS_HSCROLL  SIZE 1044,306 ;
             FONT oFont &&   SIZE 341,170
 
 
      UPDATE_BRW()



   @ 40,430 BUTTON oButton1 CAPTION "Open MEM file"   SIZE 155,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| dlgOpenMem() }       
   @ 223,430 BUTTON oButton2 CAPTION "Exit"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| frm_memdump:Close() }
   @ 331,430 BUTTON oButton3 CAPTION "Save as text file"   SIZE 235,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| dlgTextout() }
   @ 594,430 BUTTON oButton4 CAPTION "Save as HTML file"   SIZE 235,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| dlgHTMLout() }
   @ 864,430 BUTTON oButton5 CAPTION "Help"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| Show_Help() }  
   @ 997,430 BUTTON oButton6 CAPTION "Test"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ; 
         ON CLICK {|| Testdialog() }

   @ 997,470 BUTTON oButton7 CAPTION "Clear"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ; 
         ON CLICK {|| CLEAR_ALL(), DEL_TESTFI() }

      frm_memdump:Activate()
//   ACTIVATE WINDOW frm_memdump
* RETURN frm_memdump:lresult
RETURN NIL

* ~~~~~~~~~
* Functions
* ~~~~~~~~~

* =================================
FUNCTION UPDATE_BRW()
* Updates the browse window
* after reading a mem dump
* =================================

 MEMVAR oBrwArr , amemdarr , aumemdarr

      hwg_CREATEARLIST(oBrwArr,aumemdarr)
      oBrwArr:acolumns[1]:heading := "Record Nr."  // Header string
      oBrwArr:acolumns[2]:heading :="Name"
      oBrwArr:acolumns[3]:heading :="Type"
      oBrwArr:acolumns[4]:heading :="Len"
      oBrwArr:acolumns[5]:heading :="Dec"
      oBrwArr:acolumns[6]:heading :="Contents"
//      oBrwArr:acolumns[1]:length := 50
      oBrwArr:bcolorSel := hwg_ColorC2N( "800080" )
      oBrwArr:Refresh()

RETURN NIL


* =================================
FUNCTION dlgOpenMem()
* Dialog for Button "Open MEM file":
* Ask for MEM file to open and
* process it.
* =================================
LOCAL  aret,aret2,cmemfinam
MEMVAR cStMEMFILE, oLabel2, aumemdarr , amemdarr
cmemfinam := Open_Mem()
* Cancel ?
IF EMPTY(cmemfinam)
 RETURN NIL
ENDIF
* Process it
aret := Process_MEM(cmemfinam)
IF hwg_ARRAY_LEN(aret) == 0
 hwg_MsgStop("Error reading memfile" + cmemfinam)
 CLEAR_ALL()
 RETURN NIL
ENDIF 
SET_FINAME(cmemfinam)
aret2 := FormArrText(aret)
* TO_TEXTFI(aret)
* Show with BROWSE
 aumemdarr := aret2 
 amemdarr  := aret
 UPDATE_BRW()
RETURN NIL

* =================================
FUNCTION dlgTextout()
* Dialog for Button 
* "Save as text file"
* =================================
LOCAL aret, cfi
MEMVAR cStMEMFILE , amemdarr
* Check, if valid data available
IF cStMEMFILE == "<NONE>" 
 hwg_MsgStop("No MEM file selected")
 RETURN NIL
ENDIF
 aret  :=  amemdarr
IF hwg_ARRAY_LEN(aret) == 0
 hwg_MsgStop("No valid data available")
 RETURN NIL
ENDIF 
* Write contents to text file
  cfi := hwg_CurDir() + hwg_GetDirSep() +  "memdump.txt" 
  TO_TEXTFI(aret,cfi)
RETURN NIL

* =================================
FUNCTION dlgHTMLout()
* Dialog for Button 
* "Save as HTML file"
* =================================
LOCAL aret, aret2 , cfi
MEMVAR cStMEMFILE , amemdarr , aumemdarr
* Check, if valid data available
IF cStMEMFILE == "<NONE>" 
 hwg_MsgStop("No MEM file selected")
 RETURN NIL
ENDIF
 aret  :=  amemdarr
 aret2 :=  aumemdarr   
IF hwg_ARRAY_LEN(aret2) == 0
 hwg_MsgStop("No valid data available")
 RETURN NIL
ENDIF 
* Write contents to HTML file
  cfi := hwg_CurDir() + hwg_GetDirSep() +  "memdump.htm"
  TO_HTMLFI(aret2,cfi)
RETURN NIL

* =================================
FUNCTION dlgAbout()
* =================================
hwg_MsgInfo( ;
"HWGUI - Harbour Win32 and Linux (GTK) GUI library" + CHR(10) + CHR(10) + ;
"Developers utility:" + CHR(10) + ;
"Dump contents of a Clipper(Harbour) MEM file" + CHR(10) + ;
CHR(10) + ;
"Copyright 2022 Wilfried Brunken, DF7BE" + CHR(10) + ; 
"https://sourceforge.net/projects/cllog/" + CHR(10) + ;
"https://sourceforge.net/projects/hwgui/" + CHR(10) + ; 
CHR(10) + ;
"License:" + CHR(10) + ;
"GNU General Public License" + CHR(10) + ;
"with special exceptions of HWGUI." + CHR(10) + ;
"See file " + CHR(34) + "license.txt" + CHR(34) + " for details." ;
 ,"About memdump.prg")
 RETURN NIL

* =================================
FUNCTION Open_Mem()
* Returns "",
* if error or cancel
* =================================
LOCAL cmemfname , cstartvz
MEMVAR cStMEMFILE, oLabel2
cstartvz := Curdir() 
cmemfname := hwg_Selectfile("Open a MEM file for dump" , "*.mem", cstartvz )
IF EMPTY(cmemfname)
 cStMEMFILE := "<NONE>"
 oLabel2:SetText("<NONE>")
 nreccount := 0
 * Clear BROWSE
 RETURN ""
ENDIF
cStMEMFILE := cmemfname
oLabel2:SetText(cmemfname)
RETURN cmemfname

* =================================
FUNCTION Testdialog()
* Creates "test.mem"
* and shows its contents
* =================================
LOCAL aret,aret2,cmfiname
MEMVAR cStMEMFILE, oLabel2, aumemdarr , amemdarr

cmfiname := "test.mem"
IF ( cStMEMFILE <> cmfiname ) .AND. ( cStMEMFILE <> "<NONE>" )
 hwg_MsgStop("Press Clear button before test")
 RETURN NIL 
ENDIF
MAKE_TESTMEM(cmfiname)
aret := Process_MEM(cmfiname)
IF hwg_ARRAY_LEN(aret) == 0
 hwg_MsgStop("Error reading memfile")
 CLEAR_ALL()
 RETURN NIL
ENDIF 
SET_FINAME(cmfiname)
aret2 := FormArrText(aret)
TO_TEXTFI(aret,"test.txt")
* Show with BROWSE
 aumemdarr := aret2 
 amemdarr  := aret
 UPDATE_BRW()
RETURN NIL

* =================================
FUNCTION DEL_TESTFI()
* Delete MEM from created by
* "Test" button.
* =================================
DELETE FILE test.mem
RETURN NIL

* =================================
FUNCTION CLEAR_ALL()
* Resets all
* =================================
MEMVAR cStMEMFILE , oLabel2 , nreccount , aumemdarr , amemdarr

 cStMEMFILE := "<NONE>"
 oLabel2:SetText("<NONE>")
 nreccount := 0
 amemdarr  := aARR_EMPTY()
 aumemdarr := aARR_EMPTY()
 UPDATE_BRW()
RETURN NIL

* =================================
FUNCTION SET_FINAME(cfname)
* Sets the MEM filename in display
* =================================
MEMVAR cStMEMFILE , oLabel2
 cStMEMFILE := cfname
 oLabel2:SetText(cfname)
RETURN NIL 

* =================================
FUNCTION Process_MEM(cmemfname)
* Open mem file cmemfname
* and reads it values.
* The values are returned in an
* 2 dimensional array for display with
* BROWSE.
* If a file error appears,
* an empty array is returned.
* Elements of array 1:
* (Contents of one record)
* 1 : Record number
* 2 : Name
* 3 : Type
* 4 : Len
* 5 : Dec
* 6 : Contents
* 
* All items contains a leading description text, so
* use function FormArrText(ainput)
* to remove the leading description text
* and so it is ready for display with 
* BROWSE.
* =================================
LOCAL leof, Puffer, anzbytes , anzbyte2 , handle , cTyp , ncsize , ncdec , ctsize , ctemp, lstop , i
LOCAL Puffd , Puffl , Puffn , cDateA , cVarName
LOCAL aOutput , aMainA

aOutput := {}  && Stores one record
aMainA  := {}  && 2nd dimension array stores the complete MEM info 
nreccount := 0   && Count records
coutput := ""  && Only for test

* Max buffer size ( 256 x 256 ) + 256 = 65792
Puffer := SPACE(65792)
* Buffer for date
Puffd := SPACE(8)
* Buffor for logical
Puffl := " "
* Buffer for numeric
Puffn := SPACE(8)

leof := .F.

handle := FOPEN(cmemfname,2)
 IF handle == -1
  * cannot open file
   hwg_MsgStop("Can not open file >" + cmemfname + "<" )
   RETURN {}
 ENDIF
 
* Read loop
anzbytes := 32
DO WHILE ( anzbytes == 32 ) .AND. ( .NOT. leof )
* Read MEM_REC 
anzbytes := FREAD(handle,@Puffer,32)
* EOF reached ?
IF HB_FEOF(handle)
 leof := .T.
ENDIF

IF .NOT. leof
 
aOutput := {} 
 
cVarName := STRTRAN(SUBSTR(Puffer,1,10) , CHR(0) , "" )  && Buffer contains NULL bytes
cTyp   := CHR(hb_bitand(ASC(SUBSTR(Puffer,12,1)),127))    &&  & 256
ncsize := BIN2I(SUBSTR(Puffer,17,1) + CHR(0) )
ncdec  := BIN2I(SUBSTR(Puffer,18,1) + CHR(0) )

AADD(aOutput, "Record Nr.: " + ALLTRIM(STR(nreccount + 1 )) )
AADD(aOutput, "Name : " + cVarName )
* Only for Test
// AADD(aOutput, "Name : >" + cVarName +  "<" ) 
AADD(aOutput, "Type : " + cTyp )
AADD(aOutput, "Len  : " + ALLTRIM(STR(ncsize)) )
AADD(aOutput, "Dec  : " + ALLTRIM(STR(ncdec))  )

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* In Clipper and Harbour there is no function available,
* to convert the double value of type N (or D) to
* memvar type N.
*
* This the solution of this topic:
*
* The double value is converted to a hex string in one line without blanks:
* 1---+----1----+-
* 50455254FB210940  = Pi (for example),
* so size = 16 Bytes
*
* The function hwg_BIN2D() converts the hexstring
* into double and then into a memvar of type N
* For type N : it could be displayed with ? ... or processed afterwards.
* For type D : double value represents the julian day
* and is converted to a date string by 
* function hwg_JulianDay2Date(), returned format is YYYYMMDD.
* Finally, the function STOD() converts
* the date string into D value.
* If the function STOD() is not available,
* then hwg_STOD() is a substitue.
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


DO CASE
  CASE cTyp == "C"
   ctsize := ncsize + ncdec * 256
   anzbyte2 := FREAD(handle,@Puffer,ctsize)
   IF anzbyte2 <> ctsize
     FILE_ERROR(anzbyte2)
     RETURN {}
   ENDIF 
   lstop := .F.
   ctemp := SUBSTR(Puffer,1,ctsize)
   * Need to cut after NULL byte   
   FOR i := 1 TO LEN(ctemp)  && ctsize
     IF .NOT. lstop
      IF SUBSTR(ctemp,i,1) == CHR(0)
       ctemp :=  SUBSTR(ctemp,1,i - 1)
       lstop := .T.
      ENDIF
     ENDIF
   NEXT

   // hwg_WriteLog(ctemp)

   * Limit of contents line: ===================v
   AADD(aOutput,"Contents  : " + SUBSTR(ctemp,1,50 ) )

  CASE cTyp == "D"
   anzbyte2 := FREAD(handle,@Puffd,8)
  IF anzbyte2 <> 8
      FILE_ERROR(anzbyte2)
      RETURN {}
   ENDIF
   cDateA := hwg_JulianDay2Date(hwg_Bin2D(hwg_HEX_DUMP(Puffd,0))  ) 

   AADD(aOutput, "Contents  : " + cDateA )
   
   * Only for Test:
   // AADD(aOutput, "Contents  : " + cDateA + ;
   // " As type D : " + DTOC(STOD(cDateA)) ) && or hwg_STOD()

   CASE cTyp == "L"

   anzbyte2 := FREAD(handle,@Puffl,1)
  IF anzbyte2 <> 1
     FILE_ERROR(anzbyte2)
     RETURN {}
  ENDIF
   AADD(aOutput, "Contents  : " + IIF( BIN2I(Puffl + CHR(0) ) == 0 , ".F." , ".T." ) )

  CASE cTyp == "N"
   anzbyte2 = FREAD(handle,@Puffn,8)
   IF anzbyte2 <> 8
      FILE_ERROR(anzbyte2)
      RETURN {}
   ENDIF
//   hwg_MsgInfo(STRTRAN(SUBSTR(hwg_HEX_DUMP(Puffn,0),1,23)," ","") )
   AADD(aOutput, ALLTRIM(STR(hwg_Bin2D(hwg_HEX_DUMP(Puffn,0),ncsize,ncdec) )) )
 ENDCASE  

 nreccount := nreccount + 1
 
 * Store MEM record
  AADD(aMainA , aOutput)
 
ENDIF   && leof

ENDDO

FCLOSE(handle)

RETURN aMainA

* =================================
FUNCTION FILE_ERROR(nbytes)
* =================================
IF nbytes == NIL
     hwg_MsgStop("File Read Error")
ELSE
     hwg_MsgStop("File Read Error at byte : " + ALLTRIM(STR(nbytes)) )
ENDIF
RETURN NIL

* =================================
FUNCTION MAKE_TESTMEM(memdatei)
* Creates a mem file for test
* =================================
 
PRIVATE VARI_C , VARI_D , VARI_L , VARI_N

* Variable of every type

VARI_C  = "Teststring"
VARI_D  = DATE()        && System date (today)
VARI_L  = .T.
VARI_N  = 3.141592654   && Pi: 50 45 52 54 FB 21 09 40
VARI_NM = -9999999.999  && negative value

SAVE TO &memdatei ALL LIKE VARI*

RETURN NIL

* =================================
FUNCTION FormArrText(ainput)
* Removes the leading description text
* delivered by Process_MEM()
* =================================
LOCAL aOutput , i , lstop , ctemp , areco
LOCAL nal, nalr , iind , iindr

aOutput := {}
nal := hwg_ARRAY_LEN(ainput)

IF nal == 0
 RETURN {{}}
ENDIF 

FOR iind := 1 TO nal && loop records

 areco := {}
 
 nalr := hwg_ARRAY_LEN(ainput[iind])
 
 FOR iindr := 1 TO nalr   && loop memrec

  ctemp := ainput [iind,iindr]
  lstop := .F.
   FOR i := 1 TO LEN(ctemp)
     IF .NOT. lstop
      IF SUBSTR(ctemp,i,2) == ": "
       ctemp :=  SUBSTR(ctemp,i + 2)
       lstop := .T.
      ENDIF
     ENDIF
   NEXT
   
   * Remove " As type D : "
   
   AADD(areco,ctemp)
   
  NEXT && memrec

    AADD(aOutput , areco)
  
 NEXT && records  

RETURN aOutput

* =================================
FUNCTION TO_TEXTFI(aerg,cttxtfi)
* Writes the Contents to text file
* aerg: Array with elements of
* type C, 2 dimensions.
* cttxtfi : Name and of text file
*           of output.
*           Default is
*           "memdump.txt".
* =================================
LOCAL handle_a, dateiname, nal, nalr , iind , iindr

nal := hwg_ARRAY_LEN(aerg)

IF nal == 0
 RETURN NIL
ENDIF

IF cttxtfi == NIL 
 dateiname := "memdump.txt"
ELSE
 dateiname := cttxtfi 
ENDIF

* Delete, if exists
DELETE FILE (dateiname)

* Open text file for output
 IF .NOT. FILE(dateiname)
   handle_a = FCREATE(dateiname,0)  && FC_NORMAL
 ELSE
   handle_a = FOPEN(dateiname,2)
 ENDIF
 IF handle_a == -1
   hwg_MsgStop("Open Error :" + dateiname)
   RETURN NIL
 ENDIF

 FOR iind := 1 TO nal && loop records
 
 nalr := hwg_ARRAY_LEN(aerg[iind])
 
 FOR iindr := 1 TO nalr   && loop memrec
  
 IF .NOT. WRITE_TEXT(handle_a, ;
    aerg [iind,iindr] )
    hwg_MsgStop("Write ERROR: " + dateiname, "File write Error") 
    RETURN NIL
 ENDIF
 
 NEXT && memrec

 * Blank line
 IF .NOT. WRITE_TEXT(handle_a, ;
    " " )
    hwg_MsgStop("Write ERROR: " + dateiname, "File write Error") 
    RETURN NIL
 ENDIF
 
 NEXT && records
 
 FCLOSE(handle_a)
 
 hwg_MsgInfo("Memdump written to file " + dateiname)
 
 RETURN NIL
 
 
 * =================================
FUNCTION TO_HTMLFI(aerg,cttxtfi)
* Writes the Contents to HTML file
* aerg: Array with elements of
* type C, 2 dimensions.
* cttxtfi : Name and of text file
*           of output.
*           Default is
*           "memdump.htm".
* =================================
LOCAL handle_a, dateiname, nal, nalr , iind  && , iindr

MEMVAR cStMEMFILE

nal := hwg_ARRAY_LEN(aerg)

IF nal == 0
 RETURN NIL
ENDIF

IF cttxtfi == NIL 
 dateiname := "memdump.htm"
ELSE
 dateiname := cttxtfi 
ENDIF

* Delete, if exists
DELETE FILE (dateiname)

* Open text file for output
 IF .NOT. FILE(dateiname)
   handle_a = FCREATE(dateiname,0)  && FC_NORMAL
 ELSE
   handle_a = FOPEN(dateiname,2)
 ENDIF
 IF handle_a == -1
   hwg_MsgStop("Open Error :" + dateiname)
   RETURN NIL
 ENDIF
 
 * Write HTML header
 WRITE_LINE(handle_a,dateiname, "<html>")
 WRITE_LINE(handle_a,dateiname, "<head>")
 WRITE_LINE(handle_a,dateiname, "<title> MEM Dump of " + cStMEMFILE + "</title>")
 WRITE_LINE(handle_a,dateiname, "</head>")
 WRITE_LINE(handle_a,dateiname, "<body bgcolor=#FFFFFF>")
 WRITE_LINE(handle_a,dateiname, "<h2> MEM Dump of " + cStMEMFILE + "</h2>")
// WRITE_LINE(handle_a,dateiname, "<pre>")
// WRITE_LINE(handle_a,dateiname, "</pre>")

* Start table
 WRITE_LINE(handle_a,dateiname, "<table border=6 cellspacing=3 cellpadding=10 >")
 WRITE_LINE(handle_a,dateiname, "<tr>")
 WRITE_LINE(handle_a,dateiname, "<th align=left>Record Nr.</th><th>Name</th><th>Type</th><th>Len</th><th>Dec</th><th>Contents</th>")
 WRITE_LINE(handle_a,dateiname, "</tr>")


 FOR iind := 1 TO nal && loop records
 
 nalr := hwg_ARRAY_LEN(aerg[iind])
 
 // FOR iindr := 1 TO nalr   && loop memrec
 
 * Write table item
 WRITE_LINE(handle_a,dateiname, "<tr>")
 WRITE_LINE(handle_a,dateiname, "<td align=left>" + aerg [iind,1] + "</td><td>" + aerg [iind,2] + "</td><td>" + aerg [iind,3] + "</td><td>" + aerg [iind,4] + "</td><td>" + aerg [iind,5] + "</td><td>" + aerg [iind,6] + "</td>" )
 WRITE_LINE(handle_a,dateiname, "</tr>")
 
// NEXT && memrec

 * Blank line
 IF .NOT. WRITE_TEXT(handle_a, ;
    " " )
    hwg_MsgStop("Write ERROR: " + dateiname, "File write Error") 
    RETURN NIL
 ENDIF
 
 NEXT && records
 
 * Write HTML footer
 
 WRITE_LINE(handle_a,dateiname, "</table>")
 WRITE_LINE(handle_a,dateiname, "</body>")
 WRITE_LINE(handle_a,dateiname, "</html>")
 
 
 FCLOSE(handle_a)
 
 hwg_MsgInfo("Memdump written to file " + dateiname)
 
 RETURN NIL
 
* ================================= *
FUNCTION WRITE_TEXT(dat_handle,dat_text)
* Writes a line into a text file.
* Returns .T., if success.
* ================================= *
*
LOCAl Puffer,Laenge
 Puffer := dat_text + CHR(13) + CHR(10)
 Laenge := LEN(Puffer)
 IF FWRITE(dat_handle,Puffer, Laenge) == Laenge
  RETURN .T.
 ENDIF
RETURN .F.

* ================================= *
FUNCTION WRITE_LINE(handle_a,dateiname, dat_text)
* Writes a text line int a text file,
* Fires error message, if not
* successful.
* Returns .T., if success.
* ================================= *
IF dateiname == NIL
 dateiname := "<unknown>"
ENDIF 
IF .NOT. WRITE_TEXT(handle_a, ;
    dat_text )
    hwg_MsgStop("Write ERROR: " + dateiname, "File write Error") 
    RETURN .F.
 ENDIF
 RETURN .T.

* ================================= *
FUNCTION aARR_EMPTY()
* Returns empty array for BROWSE
* ================================= *
RETURN { {"","","","","",""} }

* ================================= *
FUNCTION Show_Help()
* ================================= *
LOCAL cHelptxt,cTitle
cTitle   := "Help of utility for dump contents of a Clipper(Harbour) MEM file"

cHelptxt := "MEM dump utility" + CHR(13) + CHR(10)
cHelptxt := cHelptxt + ADD_HELPLINE("================")
cHelptxt := cHelptxt + ADD_HELPLINE("A mem file is created by execution of a SAVE TO command.")
cHelptxt := cHelptxt + ADD_HELPLINE("For each memory variable saved, it contains a 32 byte header followed")
cHelptxt := cHelptxt + ADD_HELPLINE("by the actual contents.")
cHelptxt := cHelptxt + ADD_HELPLINE("The header has the following structure:")
cHelptxt := cHelptxt + ADD_HELPLINE(" (1)  char mname[11] && 10 + NIL")
cHelptxt := cHelptxt + ADD_HELPLINE(" (12) char mtype && C,D,L,N with top bit set hb_bitand(n,127)")
cHelptxt := cHelptxt + ADD_HELPLINE(" (13) char mfiller[4]")
cHelptxt := cHelptxt + ADD_HELPLINE(" (17) char mlen")
cHelptxt := cHelptxt + ADD_HELPLINE(" (18) char mdec")
cHelptxt := cHelptxt + ADD_HELPLINE(" (19) char mfiller[14]")
cHelptxt := cHelptxt + ADD_HELPLINE("Size of a MEM_REC is 32 Byte.")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("A character variable may be more than 256 bytes long, so its") 
cHelptxt := cHelptxt + ADD_HELPLINE("length requires two bytes: mdec and mlen.")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("This utility is very useful to use a MEM file.")
cHelptxt := cHelptxt + ADD_HELPLINE("It is helpful, if you know values saved to and")
cHelptxt := cHelptxt + ADD_HELPLINE("restored from MEM file.")
cHelptxt := cHelptxt + ADD_HELPLINE("")   
cHelptxt := cHelptxt + ADD_HELPLINE("Files:")
cHelptxt := cHelptxt + ADD_HELPLINE(" memdump.prg")
cHelptxt := cHelptxt + ADD_HELPLINE(" memdump.hbp")
cHelptxt := cHelptxt + ADD_HELPLINE("")      
cHelptxt := cHelptxt + ADD_HELPLINE("")   
cHelptxt := cHelptxt + ADD_HELPLINE("Compile with") 
cHelptxt := cHelptxt + ADD_HELPLINE("hbmk2 memdump.hbp")
cHelptxt := cHelptxt + ADD_HELPLINE("")  
cHelptxt := cHelptxt + ADD_HELPLINE("")  
cHelptxt := cHelptxt + ADD_HELPLINE("With Button " + CHR(34) + "Open MEM file" + CHR(34) + " select")
cHelptxt := cHelptxt + ADD_HELPLINE("an existing MEM file and open it for analysis.")
cHelptxt := cHelptxt + ADD_HELPLINE("If success, the contents are displayed in a BROWSE window.")
cHelptxt := cHelptxt + ADD_HELPLINE("")   
cHelptxt := cHelptxt + ADD_HELPLINE("Buttons " + CHR(34)+ "Save as text file" + CHR(34) + " and " + CHR(34) + "Save as HTML file" + CHR(34))
cHelptxt := cHelptxt + ADD_HELPLINE("stores the recents contents")
cHelptxt := cHelptxt + ADD_HELPLINE("in files " + CHR(34) + "memdump.txt" + CHR(34) + " or " + CHR(34) + "memdump.htm" + CHR(34) + ".")
cHelptxt := cHelptxt + ADD_HELPLINE("You can insert the contents for example")
cHelptxt := cHelptxt + ADD_HELPLINE("in your program documentation.")
cHelptxt := cHelptxt + ADD_HELPLINE("You got a message of store destination.")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("The " + CHR(34) + "Clean" + CHR(34) + " button cleans the display and")
cHelptxt := cHelptxt + ADD_HELPLINE("removes the file test.mem.")
cHelptxt := cHelptxt + ADD_HELPLINE("So the dialog is ready to open another")
cHelptxt := cHelptxt + ADD_HELPLINE("mem file.")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("Button " + CHR(34) + "Test" + CHR(34) + "creates an MEM file " + CHR(34) +"test.mem" + CHR(34) + " and opens it.") 
cHelptxt := cHelptxt + ADD_HELPLINE("It has 5 records with variables of every type.")
cHelptxt := cHelptxt + ADD_HELPLINE("The contents are also stored in a text file.")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("Other versions of this utility for")
cHelptxt := cHelptxt + ADD_HELPLINE("Harbour (Console) and MS-DOS")
cHelptxt := cHelptxt + ADD_HELPLINE("(with Pascal source code)")
cHelptxt := cHelptxt + ADD_HELPLINE("are available on the project page of CLLOG [2].")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("References")
cHelptxt := cHelptxt + ADD_HELPLINE("__________")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("  [1] Spence, Rick (Co-Developer of Clipper):")
cHelptxt := cHelptxt + ADD_HELPLINE("       Clipper Programming Guide, Second Edition Version 5.")
cHelptxt := cHelptxt + ADD_HELPLINE("       Microtrend Books, Slawson Communication Inc., San Marcos, CA, 1991")
cHelptxt := cHelptxt + ADD_HELPLINE("      ISBN 0-915391-41-4")
cHelptxt := cHelptxt + ADD_HELPLINE("")
cHelptxt := cHelptxt + ADD_HELPLINE("  [2] Project CLLOG at Sourceforge:")
cHelptxt := cHelptxt + ADD_HELPLINE("      https://sourceforge.net/projects/cllog/") 
* .... End of help text ....

 
hwg_ShowHelp(cHelptxt,cTitle)
* complete every line with CHR(13) + CHR(10)
RETURN NIL

FUNCTION ADD_HELPLINE(chtext)
RETURN chtext + CHR(13) + CHR(10) 

* =================================== EOF of memdump.prg ========================================
