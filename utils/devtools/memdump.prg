*
* memdump.prg
*
* $Id$ 
*
* <under construction>
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
* by the actual contents.
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
* 
* It contains variables of every type, also a negative N value.

#include "hwgui.ch"
#include "common.ch"
#ifdef __XHARBOUR__
   #include "ttable.ch"
#endif

STATIC cStMEMFILE, nreccount, oLabel2

FUNCTION _frm_memdump
LOCAL frm_memdump

LOCAL oLabel1, oBrowse1, oButton1, oButton2, oButton3, oButton4, oButton5 , oButton6
LOCAL oFont

MEMVAR cStMEMFILE, nreccount, oLabel2

#ifdef __PLATFORM__WINDOWS
 PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13
#else
 PREPARE FONT oFont NAME "Sans" WIDTH 0 HEIGHT 12 && vorher 13
#endif 

cStMEMFILE := "<NONE>"
nreccount  := 0

  INIT WINDOW frm_memdump MAIN TITLE "Dump a MEM file" ;
    AT 220,23 SIZE 1136,563 ;
    STYLE WS_DLGFRAME + WS_SYSMENU + DS_CENTER

//     STYLE WS_SYSMENU + WS_SIZEBOX + WS_VISIBLE +  DS_CENTER


   @ 36,25 SAY oLabel1 CAPTION "Dump of file :"  SIZE 153,22   
   @ 217,25 SAY oLabel2 CAPTION cStMEMFILE  SIZE 638,22 
 
/* 
   @ 38,94 BROWSE oBrowse1 ARRAY  SIZE 1044,306         
     STYLE WS_VSCROLL + WS_HSCROLL   SIZE 341,170

      hwg_CREATEARLIST(oBrwArr,al_DOKs)
      oBrowse1:acolumns[1]:heading := "DOKs"  // Header string
      oBrowse1:acolumns[1]:length := 50
      oBrowse1:bcolorSel := hwg_ColorC2N( "800080" )
      * FONT setting is mandatory, otherwise crashes with "Not exported method PROPS2ARR" 
      oBrowse1:ofont := oFont 

*/
//    oBrowse1:aColumns := {}
//    oBrowse1:aArray := {}
//    oBrowse1:AddColumn( HColumn():New( ,{|v,o|Iif(v!=Nil,o:aArray[o:nCurrent]:=v,o:aArray[o:nCurrent])},'C',100,0))

   @ 40,430 BUTTON oButton1 CAPTION "Open MEM file"   SIZE 155,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| Open_Mem() }       
   @ 223,430 BUTTON oButton2 CAPTION "Exit"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ;
        ON CLICK {|| frm_memdump:Close() }
*   @ 331,430 BUTTON oButton3 CAPTION "Save as text file"   SIZE 235,32 ;
*        STYLE WS_TABSTOP+BS_FLAT   
*   @ 594,430 BUTTON oButton4 CAPTION "Save as HTML file"   SIZE 235,32 ;
*        STYLE WS_TABSTOP+BS_FLAT   
*   @ 864,430 BUTTON oButton5 CAPTION "Help"   SIZE 80,32 ;
*        STYLE WS_TABSTOP+BS_FLAT   
   @ 997,430 BUTTON oButton6 CAPTION "Test"   SIZE 80,32 ;
        STYLE WS_TABSTOP+BS_FLAT ; 
         ON CLICK {|| Testdialog() }

      frm_memdump:Activate()
//   ACTIVATE WINDOW frm_memdump
* RETURN frm_memdump:lresult
RETURN NIL

* ~~~~~~~~~
* Functions
* ~~~~~~~~~

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
LOCAL aret
MAKE_TESTMEM("test.mem")
aret := Process_MEM("test.mem")
TO_TEXTFI(aret)
RETURN NIL


* =================================
FUNCTION Process_MEM(cmemfname)
* Open mem file cmemfname
* and reads it values.
* The values are returned in an
* array for display with
* BROWSE.
* If a file error appears,
* an empty array is returned.
* Elements of array:
* 1 : Record number
* 2 : Name
* 3 : Type
* 4 : Len
* 5 : Dec
* 6 : Contents 
* =================================
LOCAL leof, Puffer, anzbytes , anzbyte2 , handle , cTyp , ncsize , ncdec , ctsize , ctemp, lstop , i
LOCAL Puffd , Puffl , Puffn , cDateA , cVarName
LOCAL aOutput 

aOutput := {}
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
 
cVarName := STRTRAN(SUBSTR(Puffer,1,10) , CHR(0) , "" )  && Buffer contains NULL bytes
cTyp   := CHR(hb_bitand(ASC(SUBSTR(Puffer,12,1)),127))    &&  & 256
ncsize := BIN2I(SUBSTR(Puffer,17,1) + CHR(0) )
ncdec  := BIN2I(SUBSTR(Puffer,18,1) + CHR(0) )

AADD(aOutput, "Record Nr.: " + ALLTRIM(STR(nreccount + 1 )) )
AADD(aOutput, "Name : >" + cVarName +  "<" ) 
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
     FILE_ERROR()
     RETURN {}
   ENDIF 
   lstop := .T.
   ctemp := SUBSTR(Puffer,1,ctsize)
   * Need to cut after NULL byte   
   FOR i := 1 TO ctsize
     IF .NOT. lstop
      IF SUBSTR(ctemp,i,1) == CHR(0)
       ctemp :=  SUBSTR(ctemp,1,i - 1)
       lstop := .T.
      ENDIF
     ENDIF
   NEXT
   hwg_msginfo(ctemp)
   * Limit of contents line: ===================v
   AADD(aOutput,"Contents  : " + SUBSTR(ctemp,1,50 ) )

  CASE cTyp == "D"
   anzbyte2 := FREAD(handle,@Puffd,8)
  IF anzbyte2 <> 8
      FILE_ERROR()
      RETURN {}
   ENDIF
   cDateA := hwg_JulianDay2Date(hwg_Bin2D(hwg_HEX_DUMP(Puffd,0))  ) 
   AADD(aOutput, "Contents  : " + cDateA + ;
   " As type D : " + DTOC(STOD(cDateA)) ) && or hwg_STOD()

   CASE cTyp == "L"

   anzbyte2 := FREAD(handle,@Puffl,1)
  IF anzbyte2 <> 1
     FILE_ERROR()
     RETURN {}
  ENDIF
   AADD(aOutput, "Contents  : " + IIF( BIN2I(Puffl + CHR(0) ) == 0 , ".F." , ".T." ) )

  CASE cTyp == "N"
   anzbyte2 = FREAD(handle,@Puffn,8)
   IF anzbyte2 <> 8
      FILE_ERROR()
      RETURN {}
   ENDIF
//   hwg_MsgInfo(STRTRAN(SUBSTR(hwg_HEX_DUMP(Puffn,0),1,23)," ","") )
   AADD(aOutput, ALLTRIM(STR(hwg_Bin2D(hwg_HEX_DUMP(Puffn,0),ncsize,ncdec) )) )
 ENDCASE  

 nreccount := nreccount + 1
 
ENDIF   && leof

ENDDO

FCLOSE(handle)

RETURN aOutput

* =================================
FUNCTION FILE_ERROR()
* =================================
     hwg_MsgStop("File Read Error")
RETURN NIL

* =================================
FUNCTION MAKE_TESTMEM(memdatei)
* Creates a mem file for test
* =================================
 
PRIVATE VARI_C , VARI_D , VARI_L , VARI_N

* Variable of every type

VARI_C  = "Teststring"
VARI_D  = DATE()
VARI_L  = .T.
VARI_N  = 3.141592654   && Pi: 50 45 52 54 FB 21 09 40
VARI_NM = -9999999.999  && negative value

SAVE TO &memdatei ALL LIKE VARI*

RETURN NIL

* =================================
FUNCTION TO_TEXTFI(aerg)
* Writes the Contents to text file
* aerg: Array with elements of
* type C.
*
* =================================
LOCAL handle_a, dateiname, nal, iind

nal := hwg_ARRAY_LEN(aerg)

IF nal == 0
 RETURN NIL
ENDIF 

dateiname := "memdump.txt"

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

 FOR iind := 1 TO nal
  
 IF .NOT. WRITE_TEXT(handle_a, ;
    aerg[iind] )
    hwg_MsgStop("Write ERROR: " + dateiname, "File write Error") 
    RETURN NIL
 ENDIF
 
 NEXT
 
 FCLOSE(handle_a)
 
 hwg_MsgInfo("Memdump written to file " + dateiname)
 
 RETURN NIL
 
 * ================================= *
FUNCTION WRITE_TEXT(dat_handle,dat_text)
* Writes a line into a text file.
* Return .T., if success.
* ================================= *
*
LOCAl Puffer,Laenge
 Puffer := dat_text + CHR(13) + CHR(10)
 Laenge := LEN(Puffer)
 IF FWRITE(dat_handle,Puffer, Laenge) == Laenge
  RETURN .T.
 ENDIF
RETURN .F.

* =================================== EOF of memdump.prg ========================================
