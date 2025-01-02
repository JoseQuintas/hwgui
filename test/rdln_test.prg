*
*
* rdln_test.prg
*
* $Id$
*
* Test program for HWGUI functions
* (as Harbour Console program):
*
* hwg_RdLn(nhandle,lrembltab)
* hwg_RmCr(xLine)
* hwg_RmBlTabs(xLine)
* hwg_Max(a,b)
* hwg_Min(a,b)
*
* Three text files for input are opened and
* the lines are displayed with line endings
* Windows/DOS, UNIX/LINUX and MacOS.
*
* Compile with
* hbmk2 rdln_test.prg
*
* By DF7BE, 2025-01-01

FUNCTION MAIN()

LOCAL handle


? "textfile_Win.txt"

handle := FOPEN("textfile_Win.txt",0)  && FO_READ: Open for read
READ_LOOP(handle)
FCLOSE(handle)

?
?
? "textfile_UNIX.txt"
handle := FOPEN("textfile_UNIX.txt",0)  && FO_READ: Open for read
READ_LOOP(handle)
FCLOSE(handle)


?
?
? "textfile_MacOS.txt"
handle := FOPEN("textfile_MacOS.txt",0)  && FO_READ: Open for read
READ_LOOP(handle)
FCLOSE(handle)

? hwg_Min(0,1)
? hwg_Min(1,0)

QUIT

RETURN NIL



FUNCTION READ_LOOP(handle,lrembltab) 
 LOCAL lEOF, cbuffer, nlines, arrrea
 
 lEOF := .F.
 nlines := 0
 arrrea := {"",.F.,0,"U"}

 * read the input file
   DO WHILE .NOT. lEOF
    arrrea := hwg_RdLn(handle,lrembltab)
    * Detect EOF
    IF arrrea[2]
      lEOF := .T.
      ? "EOF reached at line ",nlines
    ELSE
 
    * Count records
    nlines := nlines + 1
    ? "Record:" + ALLTRIM(STR(nlines)) + " EOL type=" +  arrrea[4]
//    ? "Number of bytes read: ", arrrea[3]
    * Display record
    ? ">" + arrrea[1] + "<" 
    ENDIF
   ENDDO  
   FCLOSE(handle)

RETURN nlines


FUNCTION hwg_RdLn(nhandle, lrembltab)

 LOCAL nnumbytes , nnumbytes2 , buffer , buffer2
 LOCAL lEOF , bEOL , xLine , bMacOS, xarray, ceoltype
 
 IF lrembltab == NIL
   lrembltab := .F.
 ENDIF 
 xarray := {} 
 nnumbytes := 1
 nnumbytes2 := 0
 bEOL := .F.
 xLine := ""
 bMacOS := .F.
 * Buffer may not be empty, otherwise FREAD() reads nothing !
 * Fill with SPACE(n), n is the desired size of read buffer
 * (here 1)
 buffer := " "
 buffer2 := " "
 *   lEOF == .T. also indicates a file read error 
 lEOF := .F.
 ceoltype := "U" 

    DO WHILE ( nnumbytes != 0 ) .AND. ( .NOT. bEOL )
       nnumbytes := FREAD(nhandle,@buffer,1)  && Read 1 Byte
       * If read nothing, EOF is reached
       IF nnumbytes < 1
        lEOF := .T.
        IF .NOT. EMPTY(xLine)  
        * Last line may be without line ending
          xLine := hwg_RmCr(xLine)
          * Remove SUB 0x1A = CHR(26) = EOF marker
          xLine := STRTRAN(xLine,CHR(26),"")
           IF lrembltab
             * Remove blanks or tabs at end of line
             xLine := hwg_RmBlTabs(xLine)
           ENDIF  && lrembltab
         RETURN {xLine,.T.,nnumbytes,ceoltype}
        ELSE
         RETURN {"",.T.,0,ceoltype}
        ENDIF
       ENDIF        
       * Detect MacOS: First appearance of CR alone
        IF ( .NOT. bMacOS ) .AND. ( buffer == CHR(13) )
       * End of line reached ?
         bEOL := .T.
         * Pre read (2nd read sequence)
          nnumbytes2 := FREAD(nhandle,@buffer2,1)  && Read 1 byte
         IF nnumbytes2 < 1
          * Optional last line with line ending
          IF .NOT. EMPTY(xLine)
                xLine := hwg_RmCr(xLine)
                * Remove SUB 0x1A = CHR(26)  && EOF marker
                xLine := STRTRAN(xLine,CHR(26),"")
                IF lrembltab
                   * Remove blanks or tabs at end of line
                   xLine := hwg_RmBlTabs(xLine)
                ENDIF  
                RETURN {xLine,lEOF,nnumbytes2,ceoltype}
          ELSE
                RETURN {"",.T.,0,ceoltype}
          ENDIF
         ENDIF 
         * Line ending for Windows: must be LF (continue reading)
         * Before this, CR CHR(13) is read, but ignored
          IF .NOT. ( buffer2 == CHR(10) )
            * Windows : ignore read character
            bMacOS := .T.
            ceoltype := "M" 
            * Set file pointer one byte backwards (is first character of following line)
            FSEEK (nhandle, -1 , 1 )
          ELSE
           ceoltype := "W"
          ENDIF 
       ELSE
         * UNIX / LINUX (only LF)
          IF buffer == CHR(10)
           bEOL := .T.
           ceoltype := "L"
           * Ignore EOL character
           buffer := ""
          ENDIF
       ENDIF 
        * Otherwise complete the line
        xLine := xLine + buffer

      * Successful read   
      * Prefill buffer for next read
       buffer := " "

ENDDO

    IF EMPTY(xLine)
     RETURN {"",leof,0,ceoltype}
    ENDIF

    * Remove CR line ending
    * (if the returned line ended with MacOS line ending
    * CR , so you need to handle this)
     xLine := hwg_RmCr(xLine)
     * Remove SUB 0x1A = CHR(26)  && EOF marker
     xLine := STRTRAN(xLine,CHR(26),"")

     IF lrembltab
     * Remove blanks or tabs at end of line
       xLine := hwg_RmBlTabs(xLine)
     ENDIF

* Compose final return array
   AADD(xarray, xLine)
   AADD(xarray, leof)
   AADD(xarray, hwg_Max(nnumbytes, nnumbytes2) )
   AADD(xarray, ceoltype)
RETURN xarray



FUNCTION hwg_RmCr(xLine)

LOCAL nllinelen , czl
IF xLine == NIL
 xLine := ""
ENDIF
czl := xLine
nllinelen := LEN(xLine)
IF nllinelen > 0
 IF SUBSTR( xLine , nllinelen , 1) == CHR(13)
    czl := SUBSTR(xLine , 1 , nllinelen - 1 )
 ENDIF
ENDIF
RETURN czl


FUNCTION hwg_RmBlTabs(xLine)

LOCAL npos, lendf

IF xLine == NIL
 xLine := ""
ENDIF 

* Remove blanks
 lendf := .F.
 DO WHILE .NOT. lendf
  npos := LEN(xLine)
  IF SUBSTR(xLine,npos,1) == " "
      xLine := SUBSTR(xLine,1,npos - 1)
  ELSE
   lendf := .T.
  ENDIF
 ENDDO
* Remove tabs
 lendf := .F.
 DO WHILE .NOT. lendf
   npos := LEN(xLine)
  IF SUBSTR(xLine,npos,1) == CHR(26)
   xLine := SUBSTR(xLine,1,npos - 1)
  ELSE
   lendf := .T.
  ENDIF
 ENDDO

RETURN xLine 

FUNCTION hwg_Max(a,b)
IF a >= b
 RETURN a
ENDIF
RETURN b


FUNCTION hwg_Min(a,b)
IF a <= b
 RETURN a
ENDIF
RETURN b

* =================== EOF of rdln_test.prg ======================