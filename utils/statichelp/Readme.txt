 Create static help texts, that will be contained
  in your created EXE file, so no external files or
  databases containing the help text's are needed.
  
  $Id$
  
  Created 2023-01-06 by DF7BE.
  

Preface
=======

To avoid trouble with different code page's
on multi platform HWGUI applications and
you want to avoid trouble with external
help text files, this utility is helpful
to you.

  
  
Prerequisites
=============

For creating and editing the help text files,
you need a text editor supporting the UTF-8 codeset
and UNIX line endings 0x0A = CHR(10).

On Windows, we recommend Notepad++ (Open Source)
as a perfect editor for all programming work. 
On LINUX, the "on board" editors like "GEDIT"
or "KWRITE" are OK.


Instructions for use
====================

- Compile the text converter by typing
  hbmk2 stathlpconv.hbp 
- Create the text files (one for every help item)
  with UTF-8 coding, use file extension ".txt".
- Convert the text files into a HWGUI code snippet.
  So start the converter by typing
  stathlpconv.exe (LINUX: ./stathlpconv)
  and select the text file to convert.
  In the next step, the variable name must be entered
  (default preset is "cHelptext1"). 
  If done, the name of the code file created is displayed
  (with file extension ".prg" ).  
- Open the created prg file and
  copy the code snippet into your own HWGUI code file.
  Do not copy the EOF marker "SUB" = 0x1a = CHR(26).
  Please use the sample program "stathlpsample.prg"
  as a reference for your own work.
  Compile the sample program by typing:
  hbmk2 stathlpsample.hbp
 


================ EOF of Readme.txt ================