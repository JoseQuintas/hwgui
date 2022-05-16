
 Readme for HWGUI utilities
 __________________________
 
  $Id$
 
 Here you find some important utility programs for
 developers of HWGUI programs.
 
 For details for every utililty read the files Readme.txt
 in the listed subdirectory above and the
 recent HWGUI HTML documentation in main directory "doc". 


  bincnt \
  ========

  The "binary container" is a feature to avoid
  lot's of small binary files in the installation directory
  of your HWGUI application.
  Only one container file is needed to collect them all.
  This could be image files (*.ico, *.bmp, *.jpg, ...)
  and other special binary files.
  It is the best solution for multi platform applications,
  for example to avoid the usage of the Windows resource
  compiler.
  The default file extension for binary container is *.bin.

  The utility "Binary container manager" is for creating and
  editing binary container and is placed
  with source code and build scripts in directory "utils/bincnt".

  For usage instructions see the inline comments of sample program
  "samples/bincnts.prg".

  
  dbc \
  =====

  or DbcH:
  Data Base Control (Harbour)
  is an utility that allows complete
  multiuser access and indexes.
  For details read file "hwgui\utils\dbc\Readme.txt".


  debugger \
  ==========

  The HWGUI visual debugger.

  Source code and build scripts in directory "utils/debugger".
  Build and usage instructions in text file "readme.eng",
  also available in russian language as "readme.rus".  


  designer \
  ==========

  The HWGUI Designer:

  The Designer is intended to create/modify input screen forms and reports.
  For details read the HTML documentation "doc/hwgdoc_misc.html",
  chapter "7.1. Designer" and the file Readme.txt in the subdirectory.


  devtools \
  ==========

  HWGUI devloper tools:

  In the subdirectory "devtools" you find some more helpful utilities
  for programming and bugfixing of Clipper, Harbour and HWGUI programs.
  For details look into file "Readme.txt" in this directory.    


  editor \
  ========

  The HWGUI editor:

  The main goal of this project is testing of a class HCEdiExt,
  which is intended to be used for an embedded rich text editor in applications,
  written on Harbour + HwGUI.
  Read more in documentation of the editor.

  You find source code and documentation in directory
  "utils/editor".

  For introduction read file "utils/editor/Readme.txt".


  tutorial \
  ==========

   The HwGUI tutorial:

   Learn more about HWGUI:
   Compile and run the editorial in directory utils\tutorial
   Interactive - because you
   can not only read the code and comments, but execute it. Moreover,
   you can edit the code and then execute it immediately to see the
   results of your changes.  
   
   Build scripts:
   
   bldgw.bat     for MingGW on Windows 
   bld.bat       for Borland C
   bldow.bat     for OpenWatCom C on Windows
   bldgtkwin.bat for Windows with GTK+ (cross development environment), only for test purposes.
   build.sh      for LINUX with GTK+2
   hbmk.sh       alternative script using the Harbour hbmk2 utility, 
                 calls hwgrun.hbp and tutor.hbp
         

    

========================== EOF of Readme.txt ==================================
