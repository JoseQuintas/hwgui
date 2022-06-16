
  Readme.txt for "devtools"

  $Id$

   In this subdirectory "utils\devtools" you find some more helpful utilities<br>
   for programming and bugfixing of Clipper, Harbour and HWGUI programs.

   Contents:
   =========  

   1. MEM dump utility
   2. Label Dump utility
   3. DBF structure dump utililty



   1. MEM dump utility
   ===================

   A mem file is created by execution of a SAVE TO Harbour command.
   For each memory variable saved, it contains a 32 byte header followed
   by the actual contents.
   The header has the following structure:
   (1)  char mname[11]   && 10 + NIL
   (12) char mtype       && C,D,L,N with top bit set hb_bitand(n,127)
   (13) char mfiller[4]
   (17) char mlen
   (18) char mdec
   (19) char mfiller[14]
   Size of a MEM_REC is 32 Byte

   A character variable may be more than 256 bytes long, so its 
   length requires two bytes: mdec and mlen.

   This utility is very useful to use a MEM file.
   It is helpful, if you know values saved to and
   restored from MEM file.

   Files:
   memdump.prg
   memdump.hbp


   Compile with 
   hbmk2 memdump.hbp


   With Button "Open MEM file" select an existing MEM file and open it for analysis.
   If success, the contents are displayed in a BROWSE window.

   Buttons "Save as text file" and "Save as HTML file" stores the recents contents
   in files "memdump.txt" or "memdump.htm". You can insert the contents for example
   in your program documentation.
   You got a message of store destination.

   The "Clean" button cleans the display and
   removes the file test.mem.
   So the dialog is ready to open another mem file.   

   Button "Test" creates an MEM file "test.mem" and opens it. 
   It has 5 records with variables of every type.

   Other versions of this utility for Harbour (Console) and MS-DOS (with Pascal source code)
   are available on the project page of CLLOG [2]. 


   2. Label Dump utility
   =====================

   The Harbour and Clipper feature "Label" 
   is an important feature in business applications for
   example to label envelopes of letters to customers.
   In CLLOG [2] it is necessary for labelling QSL cards.
   The label feature is supported by Harbour for console
   applications and needs direct access to the printer port.

   "hwlabel" (in directory "contrib" ) is the port of this feature to
   HWGUI by using the WinPrn class,
   so it is ready for multi platform usage and independent from
   the used printer model.
   It contains a label editor for creating and editing label files
   and a sample program with a sample database. 
   

   The labels are processed by command "LABEL FORM".
   The output is directed into a temporary file and afterwards
   sent to a HWINPRN class instance for printing.

   The program "lbldump.prg" is a Harbour console program to display the
   contents of an existing label file for debugging purposes.

   Compile with
     hbmk2 lbldump.prg

   This directory contains a sample label file "test.lbl" so you
   can check the utility:

   Pass the programm with the label file to dump as the first parameter:
   
   C:\hwgui\hwgui\utils\devtools>lbldump.exe
   Usage: lbldump <file.lbl>

   Here the dump output of test.lbl on Windows 10 console:

   lbldump.exe test.lbl
   Sign1 :  ☻  (2)
   Remarks :  Label Druckertest
   Height :          16
   Width :          80
   Left margin :           1
   Lines between labels :           1
   Spaces between labels :           0
   Number of labels across :           1
   Sign2 :  ☻  (2)
   Line :           1   D_N+"Breit+0(CALL):"+d_b+D_D0E+D0("DL0BM/P")+D_D0A+"\0"+d_ba 
   Line :           2   CHR(255)+d_s
   Line :           3   "Schmalschrift"+D_sa
   Line :           4   "Normalschrift"+D_N+" NLQ NLQ "+D_NA
   Line :           5   D_F+"Fett"+D_FA
   Line :           6   D_HE+"Hochgestellt"+D_HA 
   Line :           7   D_DE+"Doppelt hoch und breit"+D_DA
   Line :           8   D_UE+"Unterstrichen 2.Wort"+D_UA+"Normal"
   Line :           9   D_N+"Wieder NLQ 0"
   Line :          10   "Umlaute ohne Umwandlung : ÄÖÜäöüß"
   Line :          11   "Umlaute :"+UML("ÄÖÜäöüß")+D_NA
   Line :          12   CHR(255)
   Line :          13   CHR(255)
   Line :          14   CHR(255) 
   Line :          15   CHR(255) 
   Line :          16   CHR(255)

   A label dumper for MS-DOS is available on the project site of
   CLLOG [2], search for file "LBLDUMP.PAS", directory "src\tools".


   3. DBF structure dump utililty
   ==============================

   This utility is helpful to copy and paste structure definitions of a DBF database
   into your application manual very easy.

   Files:
     dbfstru.prg
     MS-DOS\dbfstru.exe

   Here the output of the sample database in "samples":


 Verzeichnis von C:\hwgui\hwgui\samples

16.04.2020  12:27             6.945 sample.dbf
               1 Datei(en),          6.945 Bytes
               0 Verzeichnis(se),  5.028.786.176 Bytes frei

C:\hwgui\hwgui\samples>..\utils\devtools\dbfstru.exe sample.dbf

Copyright (c) 1999-2020 DF7BE
Under the Property of the GNU General Public Licence
with special exceptions of HWGUI.
See file  " license.txt " for details of HWGUI project at
 https://sourceforge.net/projects/hwgui/

 ** structure of database sample.dbf ***
Last update 20 03 15
Data offset 194
Record size 45
Number of records 150
Number of fields 5
NAME        TYPE LEN DEC
FLD_N       N    10
FLD_C       C    15
FLD_D       D    8
FLD_L       L    1
FLD_M       M    10
End ==> any key

  The sub directory "MS-DOS" contains an executable for MS-DOS compiled
  with Clipper Summer 1987 release.


   References
   ==========

   [1] Spence, Rick (Co-Developer of Clipper):
       Clipper Programming Guide, Second Edition Version 5.
       Microtrend Books, Slawson Communication Inc., San Marcos, CA, 1991
       ISBN 0-915391-41-4

   [2] Project CLLOG at Sourceforge:
       https://sourceforge.net/projects/cllog/ 


   ==================== EOF of Readme.txt =============================
