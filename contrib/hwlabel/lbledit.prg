*
* lbledit.prg
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
*  $Id$
*
* Copyright 2022 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details of
* HWGUI project at
*  https://sourceforge.net/projects/hwgui/
*
*
*   Editor for label files
*   (Substitute for LABEL.EXE from
*    Clipper S'87 package and
*    RL.EXE from Clipper 5.x)
*
*
*   Harbour 3.x.x or higher
*
*   Compile with:
*    hbmk2 lbledit.prg
*
*
* The following C structure presents the structure of a *.LBL-File
* ( 1034 bytes )
* #define INFO_COUNT 16
* #define INFO_SIZE 60

* LBL file structure *
* typedef struct
* {
*  char sign1;
*  char remarks[60];
*  short height;
*  short width;
*  short left_marg;
*  short label_line;       (horiz.Abstand)
*  short label_space;      (vert.Abstand)
*  short label_across;
*  char info[INFO_COUNT][INFO_SIZE];
*  char sign2;
* } LABEL_STRUC;


#ifdef __LINUX__
* LINUX Codepage
* REQUEST HB_CODEPAGE_UTF8
REQUEST HB_CODEPAGE_UTF8EX
#endif


FUNCTION MAIN(para1)


#ifdef __PLATFORM__WINDOWS
 REQUEST HB_GT_WIN_DEFAULT
#endif 

REQUEST HB_LANG_DE
REQUEST HB_CODEPAGE_DE858


SET(_SET_CODEPAGE,"DE858")
SETMODE(25,80)



* ON sets to insert mode (e.g. at READ)
SET SCOREBOARD ON
* Exact string compare
SET EXACT ON

SET DATE GERMAN  && DD.MM.YYYY (also for russian)
SET CENTURY ON
SETCANCEL(.T.)

* For new label
PUBLIC cneueslabel


* ==== Variables =====


* Settings for Compiler
PUBLIC CLIPPER,DBFAST,FLAGSHIP,HARBOUR,CLIP


  HARBOUR = .T.
  CLIPPER = .F.

PUBLIC LINUX

* Detect operation system
LINUX = .T.
#ifdef __PLATFORM__WINDOWS
LINUX = .F.
#endif



PUBLIC Puffer,lblname,handle,anzbytes,I,;
 Z1,REM,NUMZ,BR,LM,HZR,VZR,LPZ,INH,Z2,PU_NEU,BOK,;
 dos_row,dos_col,dosfenster,blbl_neu
* Explanation for usage of variables
* Puffer : the file buffer for label file (size 1038 bytes)
* anzbytes : byte counter
* dosfenster : stores the DOS screen
* blbl_neu   : this boolean variable say true, when the user creates
*              a new label file

* this array stores the contents of a label (16 lines with 60 bytes)
DECLARE MINH[16]


* === Colours
* Pre initialisization necessary to avoid crash at MESSAGEBOX()
PUBLIC farbe_std , farbe_err , farbe_meld , farbe_help



* Inititialization


*  Save DOS screen

dos_row = ROW()
dos_col = COL()
SAVE SCREEN TO dosfenster

blbl_neu := .F.  && Marker for new label

* File buffer:
* A label have a fixed size of 1034
* so fill it with spaces before usage
Puffer := SPACE(1034)


IF ISCOLOR()
* ---------------------------------
* Default settings color 1
* ---------------------------------
 farbe_std = "W+/B,W+/G+,,,B/W"
 farbe_err = "W+/R+*"
 farbe_meld = "R+/B"
 farbe_help = "W+/R+"
ELSE
* ---------------------------------
*Default settings monochrome
* ---------------------------------
 farbe_std = "W/N,N/W,,,W/N"
 farbe_err = "W+/N"
 farbe_meld = "W+/N"
 farbe_help = "W+/N"
ENDIF
SETCOLOR(farbe_std)



* Handle UTF-8
SET KEY 195 TO DE_UTF8_KEY

* Quick program termination
SET KEY 302 TO ALT_C   && ALT + C
SET KEY -33 TO ALT_C   && ALT + F4 (Windows)
SET KEY 301 TO ALT_C   && ALT + X  (Turbo releases)

 cneueslabel := "<new label>"

* Command line parameter passed
IF PCOUNT() > 0
  IF CLIPPER .OR. DBFAST
   lblname := ALLTRIM(UPPER(para1))
  ELSE
   * LINUX/UNIX : Preserve upper and lower cases
   lblname := ALLTRIM(para1)
  ENDIF

  * Erweiterung ergaenzen, wenn nicht vorhanden
  * Add file extension ".LBL", if not exiting
  IF AT(".",lblname) == 0
*    IF CLIPPER .OR. DBFAST
    IF .NOT. LINUX
      lblname := lblname + ".LBL"
    ELSE
      * UNIX/LINUX : lower case
      lblname := lblname + ".lbl"
    ENDIF
  ENDIF
  IF .NOT. FILE(lblname)
    * file does not exist
    ? "Error: file >" + lblname + "< does not exist"
    lblname := ""
    * CLEAR SCREEN
    RESTORE SCREEN FROM dosfenster
    QUIT
  ENDIF

ELSE

* Ask for filename

 DO CLS

 @ 3,30 SAY "LBLEDIT Version 3.0.0"
 @ 4,30 SAY "Copyright (c) 2000-2022 DF7BE"
 IF CLIPPER .OR. DBFAST
 @ 5,30 SAY "Copyright (c) 1985-1993,"
 @ 6,30 SAY " Computer Associates International, Inc."
 ENDIF
 @ 7,30 SAY "Under the property of the GNU Public Licence"
 @ 10,30 SAY "Please select label file"


* Select a label File
 lblname := DATEI_AUSW("*.lbl")
 IF lblname == ""
   * nothing selected, terminate program.
   RESTORE SCREEN FROM dosfenster
   QUIT
 ENDIF

ENDIF && PCOUNT

SET KEY -8 TO

* CLEAR SCREEN
 DO CLS

* Special hanling for new label file

IF lblname == cneueslabel
blbl_neu := .T.

* Set default values for label

DO defaults



* Enter new file name
 * CLEAR SCREEN
 DO CLS

 lblname = SPACE(8)
 KEYBOARD ""

  @ 10 , 10 SAY "Please enter filename of new label"

  IF CLIPPER .OR. DBFAST
   @ 12 , 10 GET lblname  PICTURE "@! XXXXXXXX"
   @ 12 , 18 SAY ".LBL"
   ELSE
   * UNIX : Preserve lower and upper for entry
   @ 12 , 10 GET lblname  PICTURE "XXXXXXXX"
   @ 12 , 18 SAY ".lbl"
  ENDIF
   READ
   IF ( LASTKEY() == 27 ) .OR. ( EMPTY(lblname) )
    RESTORE SCREEN FROM dosfenster
    QUIT
   ENDIF
  lblname = ALLTRIM(lblname) + ".lbl"
  IF FILE(lblname)
     * CLEAR SCREEN
     DO CLS

     * New label exists

     ? "Label already exists !!!!"
     ?
     WAIT "Continue ... any key"
     RESTORE SCREEN FROM dosfenster
     QUIT
  ENDIF

  * CLEAR SCREEN
  DO CLS

ELSE

* Open file

handle := FOPEN(lblname,2)
 IF handle == -1
  * Cannot open file
   ? "Can not open file >" + lblname + "<"
  QUIT
 ENDIF

* Read the label file and take the content into variables

anzbytes=FREAD(handle,@Puffer,1034)
Z1=SUBSTR(Puffer,1,1)           && Mark CHR(2)
REM=SUBSTR(Puffer,2,60)         && Remarks length=60
NUMZ=ASC(SUBSTR(Puffer,62,2))   && Height of label, number of lines 1..16
BR=ASC(SUBSTR(Puffer,64,2))     && Width of label 1..120
LM=ASC(SUBSTR(Puffer,66,2))     && Left margin      0..250
HZR=ASC(SUBSTR(Puffer,68,2))    && Lines between labels  0..16
VZR=ASC(SUBSTR(Puffer,70,2))    && Spaces between labels 0 ... 120
LPZ=ASC(SUBSTR(Puffer,72,2))    && Number of labels across) 1 ..5
INH=SUBSTR(Puffer,74,NUMZ*60)   && Contents of label
Z2=SUBSTR(Puffer,1034,1)        && Mark of end CHR(2)

* Extract the label contents

FOR I=1 TO 16
  MINH[I]=SUBSTR(INH,IIF(I=1,(I-1)*60,((I-1)*60)+1),60)
NEXT

ENDIF


* Edit it


@ 11,0 SAY "Abort editing"
@ 12,0 SAY "with ESC key"

DO SET_TAB

 @ 0,10 SAY "Parameters for label : " + lblname

@ 1,0 SAY "Remarks : " GET REM
@ 2,0 SAY "Heigth of label                    : " GET NUMZ   PICTURE "99"  RANGE 1,16
@ 3,0 SAY "Width of label                     : " GET BR     PICTURE "999" RANGE 1,120
@ 4,0 SAY "Left margin                        : " GET LM     PICTURE "999" RANGE 0,250
@ 5,0 SAY "Lines between labels               : " GET HZR    PICTURE "99" RANGE 0,16
@ 6,0 SAY "Spaces between labels)             : " GET VZR    PICTURE "999" RANGE 0,120
@ 7,0 SAY "Number of labels    across         : " GET LPZ    PICTURE "9" RANGE 1,5
@ 9,1 SAY "Contents :"
READ
DO RESET_TAB

* ESC key pressed , abort
IF LASTKEY() == 27
 IF blbl_neu == .F.
  FCLOSE(handle)
 ENDIF
 DO QRT
 * Not saved, cause of ESC
 ? "==> ESC key pressed, label not saved <=="
 WAIT
 RESTORE SCREEN FROM dosfenster
 QUIT
ENDIF

* Edit contens lines of Label, number of lines set in variable NUMZ ("Heigth of label)

@ 14 , 0 SAY "Save with"
@ 15 , 0 SAY "Page " + CHR(25) + ","  && CHR(25) = Arrow down
@ 16 , 0 SAY "Ctrl+W or"
@ 17 , 0 SAY "enter through"
@ 18 , 0 SAY "all fields"



FOR I=1 TO NUMZ
 MINH[I] = PADRIGHT(MINH[I],60)  && if extended
   && Preset empty lines for GET
 @ 8+I-1,14 SAY STR(I,2,0) + ":" GET MINH[I]    && CLIPPER
NEXT



DO SET_TAB
READ
DO RESET_TAB

* ESC key , abort
IF LASTKEY() == 27
  IF blbl_neu == .F.
   FCLOSE(handle)
  ENDIF
  DO QRT
  * Not saved , cause of ESC key
  ? "==> ESC key pressed, label not saved <=="
  WAIT "Continue ... any key"
  RESTORE SCREEN FROM dosfenster
  QUIT
ENDIF


INH=""
FOR I := 1 TO 16
 INH=INH+MINH[I]
NEXT

* Assemble the complete file buffer
* 1034 chars

Pu_neu := Z1+REM+I2BIN(NUMZ)+I2BIN(BR)+I2BIN(LM) + ;
  I2BIN(HZR)+I2BIN(VZR)+I2BIN(LPZ) + ;
  PADRIGHT(INH,960)+Z2

IF blbl_neu

* Create new file

  handle := FCREATE(lblname,0)
  IF handle == -1
   * cannot create
   * clear screen
   DO CLS

   SET CURSOR OFF
   @ 0,0
     ? "Can not create file >" + lblname + "< !!"
   QUIT
  ENDIF
ELSE
 FSEEK(handle,0,0)
ENDIF
 * Write the file and close
 anzbytes := FWRITE(handle,Pu_neu,1034)

b_ok := FCLOSE(handle)


 ? "Label >" + lblname + "< saved"

DO QRT
RESTORE SCREEN FROM dosfenster
QUIT

*
* *** end of main ******

RETURN

* ===========================================
* Functions and Procedures
* ===========================================



* ------------------------------------------
PROCEDURE DEFAULTS
* set the default values of the variables (e.g. for init)
* ------------------------------------------
LOCAL I
 Z1=CHR(2) 
 REM=SPACE(60)      && Remarks  Length=60
 NUMZ=5             && Height of label 1..16
 BR=35              && Width of label 1..120
 LM=0               && Left margin      0..250
 HZR=1              && Lines between labels  0..16
 VZR=0              && Spaces between labels  0 ... 120
 LPZ=1              && Number of labels across 1 ..5
 Z2=CHR(2)          && Byte at EOF

 FOR I := 1 TO 16
   MINH[I] := SPACE(60)
 NEXT
RETURN


* ------------------------------------------
* Help function
* ------------------------------------------
PROCEDURE HELP
 PARAMETERS prz,zei,var
*
* Internal help text, no help database
* used
* ------------------------------------------
 LOCAL old_bs,old_col,old_x,old_y,a_text,cmainprz
 IF prz == "HELP" && Avoid HELP on HELP
   RETURN
 ENDIF
 a_text := ""
 
 * Clipper
 * cmainprz = "LBLEDIT"
 * Harbour
  cmainprz := "MAIN"
 
 SAVE SCREEN TO old_bs
 old_col := SETCOLOR()
 old_x := COL()
 old_y := ROW()


  a_text := "<under construction>"


 SET COLOR TO N/W,W/N,,,N/W  && Monochrome invers
 @ 3 , 5 CLEAR TO 23 ,70
 @ 3 , 5 TO 23 ,70 DOUBLE

  @ 4 , 10 SAY "Help information for procedure : " + prz
  @ 5 , 10 SAY "Variable : " + var + SPACE(6) + "Source line : " + STR(zei)

 @ 6 , 6  SAY REPLICATE(CHR(196),64)
 @ 21, 6  SAY REPLICATE(CHR(196),64)

***  static help texts    **** 

* Start new line with CR + LF : CHR(13) + CHR(10)


  IF prz == cmainprz .AND. var == "LBLNAME"

      a_text := "Enter here the filename of the new label file" + ;
      CHR(13) + CHR(10) + "(without extension .LBL)"

  ENDIF

  IF prz == cmainprz .AND. var == "REM"

    a_text := "Enter here short remarks." + ;
    CHR(13) + CHR(10) + "The remarks are not used in the printout. " + ;
    "You can make personal notes about this label." + CHR(13) + CHR(10) + ;
    "The remarks field my be empty. The length may not exceed " + ;
    "the value of  60 characters " + ;
    "inclusive blanks."

  ENDIF

  * Height
  IF prz == cmainprz .AND. var == "NUMZ"

    a_text :=  "Heigth of label:" + CHR(13) + CHR(10) +  ;
    "Enter the number of lines of the label." + CHR(13) + CHR(10) + ;
    "The entered number of lines is served  for edititing" + CHR(13) + CHR(10) + ;
    "in the following dialog. Range is 1 to 16."


  ENDIF

  IF prz == cmainprz .AND. var == "BR"

    a_text :=  "Width of label:" + CHR(13) + CHR(10) +  ;
    "Defines the horizontal width of the label."  + CHR(13) + CHR(10) +  ;
    "Range is 1 to 120"   
 
  ENDIF

  IF prz == cmainprz .AND. var == "LM"

    a_text := "Left margin:" + CHR(13) + CHR(10) +  ;
    "Defines the start position for the printout of " + ;
    "the first label. At print of labels, this value is " + ;
    "added to the value of SET MARGIN." + ;
     + CHR(13) + CHR(10) +  ;
     "Range is 0 to 250"   

  ENDIF

  IF prz == cmainprz .AND. var == "VZR"

      a_text := "Spaces between labels:" + ;
       + CHR(13) + CHR(10) +  ;
      "For use with a set of labels with multiple lanes :" + ;
       + CHR(13) + CHR(10) +  ;
      "This parameter defines the spaces between vertical lanes." + ;
       + CHR(13) + CHR(10) +  ;
      "This option could be used also to set left margin " + ;
       "for labels following the first label." + ;
       + CHR(13) + CHR(10) +  ;
      "Range is 0 to 16, default is 0." + ;
       + CHR(13) + CHR(10) +  ;
      "Set to 0 if using labels with only one lane."

   ENDIF

  IF prz == cmainprz .AND. var == "HZR"

     a_text :=  "Lines between labels : " + CHR(13) + CHR(10) +  ;
     "Defines the number of blank lines between horizontal series" + ;
     " of labels." + CHR(13) + CHR(10) +  ;
     "Range is 0 to 120"

   ENDIF

  IF prz == cmainprz .AND. var == "LPZ"
 
     a_text = "Number of labels across : "  + CHR(13) + CHR(10) +  ;
      "Number of lanes in parallel." + CHR(13) + CHR(10)+ ;
      "If more than one lane, the printout" + ;
      " of the last line was adjusted automatically." + ;
       + CHR(13) + CHR(10) +  ;
      "Range is 1 to 5"

  ENDIF

   * Complete condition for all contents fields
   IF prz == cmainprz .AND. ( var == "MINH" .OR. ;
      var == "MINH[1]" .OR. var == "MINH[2]" .OR. ;
      var == "MINH[3]" .OR. var == "MINH[4]" .OR. ;
      var == "MINH[5]" .OR. var == "MINH[6]" .OR. ;
      var == "MINH[7]" .OR. var == "MINH[8]" .OR. ;
      var == "MINH[9]" .OR. var == "MINH[10]" .OR. ;
      var == "MINH[11]" .OR. var == "MINH[12]" .OR. ;
      var == "MINH[13]" .OR. var == "MINH[14]" .OR. ;
      var == "MINH[15]" .OR. var == "MINH[16]" )


      a_text := "Contents:" + CHR(13) + CHR(10) + CHR(13) + CHR(10) + ;
      "Like your setting for the heigth of " + ;
      "label, here is an identical number of lines " + ;
      "lines served for editing. " + ;
     "In this area it is necessary to insert Clipper " + ;
     "expressions for creating the contents " + ;
     "of this label." + ;
     "The maximum number of lines is 16. " + ;
     "In the left columns the line number is displayed. " + ;
     "Please take care of a valid syntax. Errors in the expressions " + ;
     "causes a runtime error ! " + ;
     "The programm LBLEDIT can not check " + ;
     "the correctness of your expressions. "  ;
     + CHR(13) + CHR(10) +  ;
     "Examples : " + ;
      CHR(13) + CHR(10) +  ;
      CHR(13) + CHR(10) +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      CHR(13) + CHR(10) +  ;
      "STRASSE" + ;
      CHR(13) + CHR(10) +  ;
      "PLZ" + ;
      CHR(13) + CHR(10) +  ;
      "ORT" +;
      CHR(13) + CHR(10) +  ;
      CHR(13) + CHR(10) +  ;
      "You can use standard Clipper functions. " + ;
      "These functions are discribed in the Harbour Language Reference " + ;
      "( e.g.. TRANSFORM() or TRIM() ). Also allowed are user defined functions of the " + ;
      " program in use, if they are documentated by the developer team and  " + ;
      "implementated in the program." + ;
      CHR(13) + CHR(10) +  ;
     "Although one line have only 60 characters, " + ;
     "it is possible, that the printing output could be " + ;
     "much longer. The recent " + ;
     "maximum output length is limited by the attribute " + ;
     " >Width< (Breite), exceeded characters are omitted." + ;
      + CHR(13) + CHR(10) +  ;
     "Normally blank lines are visible on the label print. " + ;
     "Example:" + ;
     CHR(13) + CHR(10) +  ;
     CHR(13) + CHR(10) +  ;
      "TRIM(VORNAME)+" + CHR(34) + " " + CHR(34) + "+NACHNAME" + ;
      CHR(13) + CHR(10) +  ;
      "STRASSE" + ;
      CHR(13) + CHR(10) +  ;
      CHR(13) + CHR(10) +  ;
      "PLZ" + ;
      CHR(13) + CHR(10) +  ;
      "ORT" +;
      CHR(13) + CHR(10) +  ;
      CHR(13) + CHR(10) +  ;
     "In this example the line between STRASSE and PLZ is empty. " + ;
     "If an expression returns in effect an empty string, " + ;
     "( in this case expressed by " + ;
     CHR(34) + CHR(34) + " or a database field is empty), so the complete " + ;
     "line is omitted. There are " + ;
     "different methods to avoid this empty string. " + ;
     "It must be sent a non printing character, " + ;
     "at its best is CHR(255). " + ;
     "Using an IF expression the output of CHR(255) can be forced by " + ;
     "following:" + ;
      CHR(13) + CHR(10) +  ;
     "  IF(!EMPTY(<stringfield>),<stringfield>,CHR(255) )" + ;
      CHR(13) + CHR(10) +  ;
     "Sample:" + ;
      CHR(13) + CHR(10) +  ;
     "  IF(!EMPTY(ADRESSE),ADRESSE,CHR(255) )" + ;
      CHR(13) + CHR(10) +  ;
      CHR(13) + CHR(10) +  ;
     "The developer can create a user defined function (UDF) handling this case " + ;
     "very easy: " + ;
      CHR(13) + CHR(10) +  ;
     " FUNCTION NOSKIP(e)" + ;
      CHR(13) + CHR(10) +  ;
     "   RETURN IF(!EMPTY(e),e,CHR(255) )" + ;
      CHR(13) + CHR(10) +  ;
      CHR(13) + CHR(10) +  ;
     "Now call this function by: NOSKIP(ADRESSE). This saves " + ;
     "many space in the contents section." + ;
      CHR(13) + CHR(10) +  ;
     "If your modifcation of the contents section is complete, you can save the label file, " + ;
     "except you habe pressed the ESC key." + ;
      CHR(13) + CHR(10) +  ;
     "The following code snippet shows, how a label is printed. Like this snippet you find such" + ;
     " a code in every Clipper application:" + ;
      CHR(13) + CHR(10) +  ;
      "USE <database> INDEX <indexfile>" + ;
      CHR(13) + CHR(10) +  ;
      "LABEL FORM <label file> TO PRINTER" + ;
      CHR(13) + CHR(10) + CHR(13) + CHR(10)

      a_text  = a_text  + ;
      "Usage of variables in label:" + ;
     CHR(13) + CHR(10) +  ;
      "You can read variables:" + ;
     CHR(13) + CHR(10) +  CHR(13) + CHR(10) +  ;
      " - Database fields in aktive database" + ;
      CHR(13) + CHR(10) +  ;
      " - all PUBLIC variables"  + ;
      CHR(13) + CHR(10) +  ;
      " - all current valid LOCAL or PRIVATE" +  ;
      CHR(13) + CHR(10) + ;
      "   variables" + ;
      CHR(13) + CHR(10) + CHR(13) + CHR(10) + ;
      "The usable variables are described " + ;
      "in the related program documentation." ;
      + CHR(13) + CHR(10) + CHR(32)


 * Table: american label formats
 *
 * Bahnen  Zoll            mm       Breite Hoehe  l.Rand        horz.A vert.A.   < German
 * Lanes   size in inch   in mm     width  height left margin                    < English
 *           
 * 1      3 1/2 x 15/16  88,9x23,8  35     5       0               1      0
 * 2      3 1/2 x 15/16  88,9x23,8  35     5       0               1      2
 * 3      3 1/2 x 15/16  88,9x23,8  35     5       0               1      2
 * 1      4 x 17/16      101,6x26,9 40     8       0               1      0
 * 3      3 2/10 x 11/12 81,3x23,3  32     5       0               1      2 (Cheshire)

    ENDIF


  IF prz == "DATEI_AUSW"  .AND. var == ""   && old : "ACHOICE"

    a_text := "Your choice: create a new label or" + ;
    " select an existing one for edit." + ;
    CHR(13) + CHR(10) + "For selection move Cursor with Up/Down keys to " + ;
    "the desired filen name and" + ;
    " confirm with <RETURN>"

  ENDIF


*** End of static help texts ****

 IF a_text != ""

  * Show the help text

  @ 22 ,7 SAY "Close help with <ESC> key, scroll with " + CHR(24) + " " + ;
               CHR(25) + " or PgUp,PgDown"  

  * Help on Help unterdruecken
  SET KEY 28 TO

  MEMOEDIT(a_text,7,6,20,69,.F.)

  DO EMPTY_TPUF
  KEYBOARD ""
  SET KEY 28 TO HELP

 ELSE
  * no help available

   @ 12 , 10 SAY " Help information not available !"
   @ 13 , 10 SAY " Continue ==> any key"

  WAIT ""
 ENDIF
 SET COLOR TO (old_col)
 RESTORE SCREEN FROM old_bs
 MY_SETPOS(old_y,old_x)
 RELEASE old_bs,old_sel,old_col,old_x,old_y,a_text
RETURN


* ================================= *
FUNCTION PADCENTER(padc_stri,padc_laen,fzeichen)    && = PADC
* ================================= *
  LOCAL zahl,zl,zr


  IF PCOUNT() < 3
    fzeichen := " "
  ENDIF
* Avoid crash of SUBSTR()
  if ( padc_laen <= 0 )
    RETURN ""
  endif
  if  padc_stri == ""
    RETURN REPLICATE(fzeichen,padc_laen)
  endif
* Number of filler characters  in "zahl"
  zahl := padc_laen - LEN(SUBSTR(padc_stri,1,padc_laen))
  zl := INT(zahl / 2)
  zr := zahl - zl
RETURN REPLICATE(fzeichen,zl) + SUBSTR(padc_stri,1,padc_laen) + REPLICATE(fzeichen,zr)


* ================================= *
FUNCTION PADRIGHT(padr_stri,padr_laen)  && PADR
* Trim a string to a fixed length:
*  fill rest (at end) with blanks or
*  cut, if longer.
* ================================= *

* Avoid crash of SUBSTR()
  if ( padr_laen <= 0 )
    RETURN ""
  endif

  if  padr_stri == ""
    RETURN SPACE (padr_laen)
  endif
RETURN SUBSTR(padr_stri,1,padr_laen) + SPACE(padr_laen - LEN(SUBSTR(padr_stri,1,padr_laen)))


* ================================= *
FUNCTION DATEI_AUSW
 PARAMETERS maske,anzahl
* Dialog for file selection
* by wildcards (maske)
* Anzahl:
* Do not deliver this parameter
* with a value.
*
* Returns the string with the
* filename.
* For a new file you can select
* "<neues Label>", this string was
* returned also.
* Cancelled by ESC returns an
* empty string.
* ================================= *
 LOCAL   Wahl , gewaehlt
 anzahl := ADIR(maske)+1
 DECLARE t_Dateien[anzahl]

 ADIR(maske,t_Dateien)
 ASORT(t_Dateien)

  t_Dateien[anzahl] := "<new label>"

 SCR_ARR_D(@t_Dateien)
 @ 2,4 TO 14,21 DOUBLE
 Wahl := ACHOICE(3,5,13,20,t_Dateien)
 @ 2,4 CLEAR TO 14,21
 IF Wahl != 0
  gewaehlt := t_Dateien[Wahl]
 ELSE
  gewaehlt := ""
 ENDIF
 RELEASE t_Dateien
RETURN gewaehlt

*******


* ================================= *
PROCEDURE SCR_ARR_D
 PARAMETERS a
*
* Scrool array down one element
*    1 <+                       5
* !  2  !                       1
* !  3  !     SCR_ARR_D(@a) ==> 2
* v  4  !                       3
*    5 -+                       4
* ================================= *
 LOCAL i,n,temp
 n := LEN(a)
 IF n < 2
 * Length = 1 or 0 : nothing to do
  RETURN
 ENDIF
 temp := a[n]
 FOR i := n - 1 to 1 STEP -1
    a[i + 1]  = a[i]
 NEXT
 a[1] := temp
RETURN


* ================================= *
PROCEDURE SET_TAB
*
* Behavior of Windows at READ
* TAB : next entry field
* Shift+TAB : previous entry field
*
* ================================= *
  SET KEY 9 TO TAB_VOR
  SET KEY 271 TO TAB_ZURUECK
RETURN


* ================================= *
PROCEDURE RESET_TAB
*
* ================================= *
  SET KEY 9 TO
  SET KEY 271 TO
RETURN


* ================================= *
PROCEDURE TAB_VOR
* Cursor Down
* ================================= *
 KEYBOARD CHR(24)
RETURN


* ================================= *
PROCEDURE TAB_ZURUECK
* Cursor Up
* ================================= *
  KEYBOARD ""
  KEYBOARD CHR(5)
RETURN

* ================================= *
PROCEDURE MY_SETPOS   && S87
  PARAMETERS y , x    && S87
*
* ! this function only for Clipper S87
* remove this function for
* Clipper > 5.0 and Harbour
* ================================= *
  @ y , x SAY ""
RETURN

* ================================= *
PROCEDURE CLS
* CLEAR SCREEN for all compilers.
* Not understood by CA DB-FAST.
* ================================= *
   @ 0 , 0 CLEAR TO 24 , 79
RETURN


* ================================= *
PROCEDURE EMPTY_TPUF
*
* --- Clear keyboard buffer
*      before GET leeren.
*    Especially for FlagShip,
*    but can be used with
*    Clipper or Harbour.
* ================================= *
DO WHILE INKEY() != 0
  ENDDO
RETURN

* =============================================
PROCEDURE DE_UTF8_KEY
* Processes german umlaute from UTF-8 keying
* with Harbour compiler
* =============================================

LOCAL ltast, arow , acol

arow := ROW()
acol := COL()

ltast = LASTKEY()
if ltast == 195
* Get next key from UTF-8 pair
 DO WHILE INKEY() == 0
 ENDDO

 ltast = LASTKEY()
 DO CASE
   * Ae
   CASE ltast == 132
     KEYBOARD CHR(142)
   * Oe
   CASE ltast == 150
     KEYBOARD CHR(153)
   * Ue
   CASE ltast == 156
     KEYBOARD CHR(154)
   * ae
   CASE ltast == 164
     KEYBOARD CHR(132)
   * oe
   CASE ltast == 182
     KEYBOARD CHR(148)
   * ue
   CASE ltast = 188
     KEYBOARD CHR(129)
   * sz
   CASE ltast == 159
     KEYBOARD CHR(225)
 ENDCASE
ENDIF
@ arow , acol SAY ""
RETURN

* ------------------------------------------
PROCEDURE ALT_C
*
* Catch key  Alt + C 
* ------------------------------------------
 LOCAL Q_Bildschirm, alt_curs, alt_x , alt_y , Antwort , c
  c := SETCOLOR()
  alt_y := ROW()
  alt_x := COL()
  SAVE SCREEN TO Q_Bildschirm
*  Query
  SET COLOR TO (farbe_help)
  @ 10 , 10 CLEAR TO 12, 45
  @ 10 , 10 TO 12 ,45 DOUBLE
  @ 11 , 12 SAY "Quit program ? (Y/N)"
* No cascaded GETS
  Antwort := INKEY(0)
* Restore old screen
   SET COLOR TO (c)
  RESTORE SCREEN FROM Q_Bildschirm
  @ alt_y, alt_x SAY ""
  IF ( Antwort == 74 ) .OR. ( Antwort == 106 ) ;  && Jj
   .OR. ( Antwort == 59 ) .OR. ( Antwort == 121 )   && Yy
* Quit procedure
    DO QRT
    QUIT
  ENDIF
RETURN

* ------------------------------------------
PROCEDURE QRT
*
* Progran quit sequence
* ------------------------------------------
  CLOSE ALL
 DO RES_DOS_SCR
 set safety on
RETURN

* ---------------------------------
PROCEDURE RES_DOS_SCR
* Restore DOS screen
* ---------------------------------
  SET COLOR TO
  restore screen from dosfenster
  SET CURSOR ON
  @ dos_row, dos_col
RETURN

* ================== EOF of lbledit.prg ==================================
