/*
 * adddbfitem.prg
 *
 * $Id$
 *
 * HWGUI - Harbour Win32 and Linux (GTK) GUI library
 *
 * Copyright 2020 Wilfried Brunken, DF7BE 
 * https://sourceforge.net/projects/cllog/
 * 
 * Adds one binary file to an existing DBF binary container,
 * for usage in a batch.
 *
 * Parameter 1: File of DBF, without extension .dbf/.dbt
 *              The DBF must exists, otherwise create an empty one
 *              with the HWGUI DBF container manager
 * Parameter 2: File to add to the binary container DBF.
 *              The file name must have an extension, for example
 *              image.bmp
 * 
 *
 * Compile with:
 * hbmk2 adddbfitem.prg
*/
#include "hbclass.ch"
#include "fileio.ch"

FUNCTION MAIN(fname,cFileName)
LOCAL  cType , cfilefull

IF PCOUNT() <> 2
  ? "Usage : adddbfitem containerdbf_without_ext binfiletoadd"
  QUIT
ENDIF

IF .NOT. FILE(fname + ".dbf")
 ? "Database " + fname + ".dbf not existing !"
 QUIT
ENDIF 

IF .NOT. FILE(cFileName)
 ? "File " + cFileName + " not existing !"
 QUIT
ENDIF

    cfileful := cFileName
    cType := FilExten( cFileName )
     IF EMPTY(cType)
      ? "Error : File name to add must have an extension !"
      QUIT
     ENDIF
     cFileName := CutExten(CutPath(cFileName))


 * Open DBF
 USE &fname

/*
  * If you want am index file, uncomment this 
* Create index, if not existing
 IF .NOT. FILE(fname + INDEXEXT())
  INDEX ON BIN_CITEM + BIN_CTYPE TO fname
 ENDIF
 
 USE
 * Re open DBF
 USE &fname INDEX fname
 SET ORDER TO 1

*/ 

     * Check, if entry exist
 
     IF dbfcnt_exist(cFileName,cType)
       ? "File entry exists, not added"
       QUIT
     ENDIF
 
     * Now copy selected file into memo field

     APPEND BLANK
     IF DELETED()
      RECALL
     ENDIF 
     REPLACE BIN_CITEM WITH cFileName
     REPLACE BIN_CTYPE WITH cType
     REPLACE BIN_MITEM WITH bindbf_RDFILE(cfileful)

 
     ? "File added : " , cfileful

     ? "Total number of elements in container : " , ALLTrim( Str (LASTREC() ))
 
      QUIT

 
 RETURN NIL

 
* ============================================== 
FUNCTION dbfcnt_exist(cfile,ctype)
* Returns .T., if file exists
* in DBF binary container
* ==============================================
LOCAL lfound
FIELD BIN_CITEM,  BIN_CTYPE

GO TOP

IF LASTREC() == 0
// ? "This is the first record created"
 RETURN .F.
ENDIF  

 IF INDEXORD() == 0
*  Without index
  LOCATE FOR ( ALLTRIM(cfile) == ALLTRIM(BIN_CITEM)  ) .AND. ;
             ( ALLTRIM(ctype) == ALLTRIM(BIN_CTYPE)  )
 ELSE
* With  index
  SET SOFTSEEK OFF
 * Exakt seek
  SEEK PADR(cfile + ctype,LEN(cfile + ctype ))
 ENDIF

 
 IF FOUND()
  lfound := .T.
  ? "Duplicate record found" 
  ? "Record for file " + ALLTRIM(cfile) + "." + ALLTRIM(ctype) + " found, record number : "  + ;
   ALLTRIM(STR(RECNO() ))
 ELSE
  lfound := .F.
 ENDIF
  
 RETURN lfound 

 

* ==============================================
FUNCTION bindbf_RDFILE(cfilename)
* ==============================================


RETURN hwg_HEX_DUMP(MEMOREAD(cfilename), 4 ) 



* Copied from hmisc.prg

* ================================= * 
FUNCTION hwg_HEX_DUMP (cinfield, npmode, cpVarName)
* Hex dump from a C field (binary)
* into C field (Character type).
* In general,
* every byte value (2 hex digits)
* separated by a blank.
* 
* npmode:
* Selects the output format. 
* 0 : All hex values in one line,
*     without quotes and trailing EOL.
* 1 : 16 bytes per line,
*     with display of printable
*     characters,
*     not inserted in quotes,
*     but columns with printable
*     characters are separated with
*     ">> " in every line. 
* 2 : As variable definition
*     for copy and paste into prg source
*     code file, 16 bytes per line,
*     concatenated by "+ ;"
*     (Default)
* 3 : 16 bytes per line, only hex output,
*     no quotes or other characters.
* 4 : Like 0, but without blank
*     between the hex values.
*     Used by Binary Large Objects (BLOBs)
*     stored in memo fields of a DBF.
*     See program utils\bincnt\bindbf.prg
*
* cpVarName:
* Only used, if npmode = 2.
* Preset for variable name,
* Default is "cVar".
* For other modes, this parameter
* is ignored.     
*
* Sample writing hex dump to text file
* MEMOWRIT("hexdump.txt",HEX_DUMP(varbuf))
* ================================= *  
LOCAL nlength, coutfield,  nindexcnt , cccchar, nccchar, ccchex, nlinepos, cccprint, ;
   cccprline, ccchexline, nmode , cVarName
 IIF(npmode == NIL , nmode := 2 , nmode := npmode )
 IIF(cpVarName == NIL , cVarName := "cVar" , cVarName := cpVarName )
 * get length of field to be dumped
 nlength := LEN(cinfield)
 * if empty, nothing to dump
 IF nlength == 0
   RETURN ""
 ENDIF
  nlinepos := 0
  IF nmode == 2
   coutfield := cVarName + " := " + CHR(34)  && collects out line, start with variable name
  ELSE
   coutfield := ""  && collects out line
  ENDIF 
  // cccprint := ""   && collects printable char
  cccprline := ""  && collects printable chars
  ccchexline := "" && collects hex chars
  * loop over every byte in field
  FOR nindexcnt := 1 TO nlength
    nlinepos := nlinepos + 1
    * extract single character to convert
    cccchar := SUBSTR(cinfield,nindexcnt,1)
    * convert single character to number
    nccchar := ASC(cccchar)
    * is printable character below 0x80 (pure ASCII)
    IF (nccchar > 31) .AND. (nccchar < 128)
      IF nccchar == 32
      * space represented by underline
        cccprint := "_"
      ELSE
        cccprint := cccchar
      ENDIF
    ELSE 
     * other characters represented by "."
     cccprint := "."
    ENDIF
    * convert single character to hex
    ccchex  := hwg_NUMB2HEX(nccchar)
    * collect hex and printable chars in outline
    IF nmode == 4
     cccprline := cccprline + cccprint
     ccchexline := ccchexline + ccchex
    ELSE
     * Add a blank between a hex value pair
     cccprline := cccprline + cccprint + " "
     ccchexline := ccchexline + ccchex + " "
    ENDIF
    * end of line with 16 bytes reached
    IF nlinepos > 15
    * create new line
    *
    DO CASE
      CASE nmode == 0
       coutfield := coutfield + ccchexline
      CASE nmode == 1
       coutfield := coutfield + ccchexline + ">> " +  cccprline + hwg_EOLStyle()
      CASE nmode == 2
       coutfield := coutfield + ccchexline + CHR(34) + " + ;" + hwg_EOLStyle()
      CASE nmode == 3
       coutfield := coutfield + ccchexline + hwg_EOLStyle()
      CASE nmode == 4
       coutfield := coutfield + ccchexline
    ENDCASE

      * ready for new line  
      nlinepos := 0
      cccprline := ""
      IF nmode == 2
       ccchexline := CHR(34) && start new line with double quote
      ELSE  
       ccchexline := ""
      ENDIF
    ENDIF
  NEXT
  * complete as last line, if rest of recent line existing
  * HEX line 16 * 3 = 48
  * line with printable chars: 16 * 2 = 32
  IF  .NOT. EMPTY(ccchexline)  && nlinepos < 16
   DO CASE
      CASE nmode == 0
       coutfield := coutfield + ccchexline
      CASE nmode == 1
       coutfield := coutfield + PADR(ccchexline,48) + ">> " +  PADR(cccprline,32) + hwg_EOLStyle()
      CASE nmode == 2
       coutfield := coutfield + ccchexline + CHR(34) +  hwg_EOLStyle()
      CASE nmode == 3
       coutfield := coutfield + ccchexline + hwg_EOLStyle()
      CASE nmode == 4
       coutfield := coutfield + ccchexline
    ENDCASE

  ENDIF
RETURN coutfield 


* ================================= *
FUNCTION hwg_NUMB2HEX (nascchar)
* Converts 
* 0 ... 255 TO HEX 00 ... FF
* (2 Bytes String)
* ================================= *
LOCAL chexchars := ;
   {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}  
LOCAL n1, n2
  * Range 0 ... 255
  IF nascchar > 255
   RETURN "  "
  ENDIF
  IF nascchar < 0
   RETURN "  "
  ENDIF
  * split bytes 
  * MSB: n1, LSB: n2
   n1 := nascchar / 16 
   n2 := nascchar % 16
   * combine return value
RETURN chexchars[ n1 + 1 ] + chexchars[ n2 + 1 ]

* ================================= *
FUNCTION hwg_EOLStyle
* Returns the "End Of Line" (EOL) character(s)
* OS dependent.
* Windows: OD0A (CRLF)
* LINUX:   0A (LF)
* This function works also on
* GTK cross development environment.
* MacOS not supported yet.
* Must then return 0D (CR).
* ================================= *

#ifdef __PLATFORM__WINDOWS
 RETURN CHR(13) + CHR(10)  
#else
 RETURN CHR(10)
#endif

 
 * Copied from source\common\procmisc\procs7.prg

FUNCTION FilExten( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '.', fname ) ) = 0, "", SubStr( fname, i + 1 ) )

FUNCTION CutPath( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '\', fname ) ) = 0, ;
      iif( ( i := RAt( '/', fname ) ) = 0, fname, SubStr( fname, i + 1 ) ), ;
      SubStr( fname, i + 1 ) ) 
  
FUNCTION CutExten( fname )

   LOCAL i

   RETURN iif( ( i := RAt( '.', fname ) ) = 0, fname, SubStr( fname, 1, i - 1 ) )
 
 

* =================================== EOF of adddbfitem.prg =============================