 
  Readme.txt for "devtools"
  
  $Id$
  
   In this subdirectory "utils\devtools" you find some more helpful utilities<br>
   for programming and bugfixing of Clipper, Harbour and HWGUI programs.

   
   MEM dump utility
   ================
   <under construction, will be completed as soon as possible>
   
   A mem file is created by execution of a SAVE TO command.
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
   
   References
   ==========

   [1] Spence, Rick (Co-Developer of Clipper):
       Clipper Programming Guide, Second Edition Version 5.
       Microtrend Books, Slawson Communication Inc., San Marcos, CA, 1991
       ISBN 0-915391-41-4

   [2] Project CLLOG at Sourceforge:
       https://sourceforge.net/projects/cllog/ 
   
   
   ==================== EOF of Readme.txt =============================
