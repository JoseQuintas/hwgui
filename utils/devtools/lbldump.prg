*
* lbldump.prg
*
* $Id$
*
* HWGUI - Harbour Win32 and Linux (GTK) GUI library
*
* Label dumper
*
* Copyright 2022 Wilfried Brunken, DF7BE 
* https://sourceforge.net/projects/cllog/
*
* License:
* GNU General Public License
* with special exceptions of HWGUI.
* See file "license.txt" for details.
*
*
* This program opens a label file
* and displays it's contents.
* For debugging purposes.
*
* Label files are read with Harbour command
* LABEL FORM ...
* and it's definitions can be send to a printer
* or a file.
* 
* For HWGUI applications it is necessary to
* send the defintions into a temporary file
* and send the contents to the printer with the
* HWINPRN class. 
*
* The following C structure presents the structure of a *.LBL-File
* ( total size fixed 1034 bytes )
*
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
*  short label_line;       (lines between labels,  horiz.Abstand)
*  short label_space;      (spaces between labels, vert. Abstand)
*  short label_across;
*  char info[INFO_COUNT][INFO_SIZE]; (16 x 60 = 960 bytes)
*  char sign2;
* } LABEL_STRUC;
*
* Compile with
* hbmk2 lbldump.prg



FUNCTION MAIN(clblfname)

* LOCAL olbldumpMain , oFontMain

* #ifdef __PLATFORM__WINDOWS
*   PREPARE FONT oFontMain NAME "MS Sans Serif" WIDTH 0 HEIGHT -14
* #else
*   PREPARE FONT oFontMain NAME "Sans" WIDTH 0 HEIGHT 12 
* #endif

LOCAL handle 
*     Index variable
*     !  Buffer
*     !  !        Number of bytes 
*     !  !        !
*     v  v        v 
LOCAL I, Puffer , anzbytes
* Puffer : the file buffer for label file
* anzbytes : byte counter
LOCAL Z1,REM,NUMZ,BR,LM,HZR,VZR,LPZ,INH,Z2
* this array stores the contents of a label, 16 elements
LOCAL MINH
* Array for return
LOCAL albl

IF PCOUNT() <> 1
 ? "Usage: lbldump <file.lbl>"
 QUIT
ENDIF 

* A label have a fixed size of 1034
* so fill buffer with spaces before reading

Puffer := SPACE(1034)

* Open label file

handle := FOPEN(clblfname,2)
IF handle == -1
 ? "Error opening label file " , clblfname
 QUIT
ENDIF

anzbytes := FREAD(handle,@Puffer,1034)  && Read complete label file
// ? "Bytes read: " + STR(anzbytes)
IF anzbytes != 1034
 ? "Error reading label file, not 1034 bytes" 
 QUIT
ENDIF

* Create empty array for label contents
MINH := {}
FOR I := 1 TO 16
 AADD(MINH,"")
NEXT
 
Z1 := SUBSTR(Puffer,1,1)           && Markierung CHR(2) / Mark CHR(2)
REM := SUBSTR(Puffer,2,60)         && Bemerkung  L=60  / Remarks length=60
NUMZ := ASC(SUBSTR(Puffer,62,2))   && Zeilenanzahl (height of label, number of lines) 1..16
BR := ASC(SUBSTR(Puffer,64,2))     && Spaltenbreite (width of label) 1..120
LM := ASC(SUBSTR(Puffer,66,2))     && Linker Rand (left margin)      0..250
HZR := ASC(SUBSTR(Puffer,68,2))    && Horiz. Abst. (lines between labels)  0..16
VZR := ASC(SUBSTR(Puffer,70,2))    && Vert. Abstand (spaces between labels ) 0 ... 120
LPZ := ASC(SUBSTR(Puffer,72,2))    && Anzahl Label/Zeile  (number of labels across) 1 .. 5
INH := SUBSTR(Puffer,74,NUMZ * 60) && Labelinhalte / Contents of label
Z2 := SUBSTR(Puffer,1034,1)        && Endemarkierung CHR(2) / Mark of end CHR(2)


* Extract the contents
* Inhalte aufteilen

FOR I := 1 TO 16
  MINH[I] := SUBSTR(INH,IIF(I == 1, ( I - 1 ) * 60,((I - 1) * 60) + 1 ), 60)
NEXT

* Printout values

? "Sign1 : ",  Z1 , " (2)"               /* CHR(2) */
? "Remarks : " , REM                    /* length=60 */
? "Height : " , NUMZ                    /* 1 .. 16 */
? "Width : " ,  BR                       /* 1 .. 120 */
? "Left margin : " , LM                  /* 0 .. 250 */
? "Lines between labels : " , HZR      /* Lines between labels,  horiz. Abstand  0 .. 16 */
? "Spaces between labels : " , VZR     /* Spaces between labels, vert. Abstand  0 .. 120 */
? "Number of labels across : " , LPZ   /* Number of labels across, Anzahl Label/Zeile 1 .. 5 */

? "Sign2 : ",  Z2 , " (2)"               /* CHR(2) */

* Display contents of label (max. 16 Lines)

IF NUMZ > 16   &&  In case of errors avoid program crash or freeze
 NUMZ := 16
ENDIF 

FOR I := 1 TO NUMZ
 ? "Line : " , I , " " , MINH[I]
NEXT
 
QUIT 

RETURN NIL

* =============================== EOF of lbldump.prg ===================================